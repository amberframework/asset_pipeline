// Explicit macOS surface overrides shared by the SwiftUI facades.

import SwiftUI

#if os(macOS)
import AppKit
import CoreGraphics

@_silgen_name("ap_surface_noise_texture_tile_create")
private func apSurfaceNoiseTextureTileCreate(
    _ baseFrequency: Double,
    _ octaveCount: Int32,
    _ seed: Int32,
    _ tileSize: Int32,
    _ backingScale: Double
) -> UnsafeRawPointer?

enum SurfaceCraftModifiers {
    private static let textureCache = NSCache<NSString, CGImage>()

    static func hasSurfaceFill(_ spec: String?) -> Bool {
        dictionary(from: spec)["fill"] is String
    }

    static func apply(
        _ view: AnyView,
        spec: String?,
        keycapStyle: String?,
        cornerRadius: NSNumber?,
        previewState: String?
    ) -> AnyView {
        var current = view
        let values = dictionary(from: spec)
        let radius = CGFloat(cornerRadius?.doubleValue ?? 0)
        let shape = RoundedRectangle(cornerRadius: radius)

        let fill = values["fill"] as? String
        var didApplyGradient = false
        if let gradient = values["gradient"] as? [String: Any],
           let stops = gradient["stops"] as? [[String: Any]], stops.count >= 2 {
            let colors = stops.compactMap { stop -> Gradient.Stop? in
                guard let value = stop["color"] as? String,
                      let position = stop["position"] as? Double else { return nil }
                return Gradient.Stop(color: color(from: value), location: position)
            }
            if colors.count >= 2 {
                let angle = (gradient["angle"] as? Double ?? 0) * .pi / 180
                let dx = sin(angle)
                let dy = -cos(angle)
                let start = UnitPoint(x: 0.5 - dx / 2, y: 0.5 - dy / 2)
                let end = UnitPoint(x: 0.5 + dx / 2, y: 0.5 + dy / 2)
                let linearGradient = LinearGradient(
                    gradient: Gradient(stops: colors), startPoint: start, endPoint: end
                )
                current = AnyView(current.background {
                    ZStack {
                        if let fill { color(from: fill) }
                        linearGradient
                    }
                })
                didApplyGradient = true
            }
        }
        if !didApplyGradient, let fill {
            current = AnyView(current.background(color(from: fill)))
        }
        if let texture = values["texture"] as? [String: Any],
           let kind = texture["kind"] as? String,
           let opacity = (texture["opacity"] as? NSNumber)?.doubleValue {
            if kind == "noise" {
                let baseFrequency = (texture["baseFrequency"] as? NSNumber)?.doubleValue ?? 0.72
                let octaveCount = (texture["octaveCount"] as? NSNumber)?.int32Value ?? 3
                let seed = (texture["seed"] as? NSNumber)?.int32Value ?? 4
                let tileSize = (texture["tileSize"] as? NSNumber)?.int32Value ?? 160
                if baseFrequency.isFinite, (0.0...16.0).contains(baseFrequency),
                   (1...8).contains(octaveCount), (1...1024).contains(tileSize) {
                    current = AnyView(current.overlay {
                        SurfaceCraftNoiseTextureOverlay(
                            baseFrequency: baseFrequency,
                            octaveCount: octaveCount,
                            seed: seed,
                            tileSize: tileSize,
                            opacity: opacity,
                            shape: shape
                        )
                    })
                }
            } else if let image = textureImage(kind: kind) {
                current = AnyView(current.overlay {
                    Image(decorative: image, scale: 1)
                        .resizable(resizingMode: .tile)
                        .opacity(opacity)
                        .allowsHitTesting(false)
                        .clipShape(shape)
                })
            }
        }

        if let shadows = values["dropShadows"] as? [[String: Any]] {
            for shadow in shadows {
                guard let value = shadow["color"] as? String else { continue }
                current = AnyView(current.shadow(
                    color: color(from: value),
                    radius: CGFloat(shadow["blur"] as? Double ?? 0),
                    x: CGFloat(shadow["x"] as? Double ?? 0),
                    y: CGFloat(shadow["y"] as? Double ?? 0)
                ))
            }
        }
        if let shadows = values["innerShadows"] as? [[String: Any]], !shadows.isEmpty {
            current = AnyView(current.overlay {
                ZStack {
                    ForEach(shadows.indices, id: \.self) { index in
                        let shadow = shadows[index]
                        if let value = shadow["color"] as? String {
                            shape
                                .stroke(color(from: value), lineWidth: max(1, CGFloat((shadow["blur"] as? Double ?? 0) * 2)))
                                .blur(radius: CGFloat(shadow["blur"] as? Double ?? 0))
                                .offset(
                                    x: CGFloat(shadow["x"] as? Double ?? 0),
                                    y: CGFloat(shadow["y"] as? Double ?? 0)
                                )
                        }
                    }
                }
                .mask(shape)
                .allowsHitTesting(false)
            })
        }

        if let style = keycapStyle {
            current = applyKeycap(current, style: style, shape: shape)
        }
        let feedback = values["feedback"] as? String
        if feedback != nil || previewState != nil {
            current = AnyView(current.modifier(SurfaceCraftFeedbackModifier(
                style: feedback,
                previewState: previewState,
                cornerRadius: radius
            )))
        }
        return current
    }

    static func color(from value: String) -> Color {
        if value.hasPrefix("rgba("), value.hasSuffix(")") {
            let parts = value.dropFirst(5).dropLast().split(separator: ",").compactMap { Double($0) }
            if parts.count == 4 {
                return Color(.sRGB, red: parts[0] / 255, green: parts[1] / 255,
                            blue: parts[2] / 255, opacity: parts[3])
            }
        }
        guard value.hasPrefix("role:") else { return .clear }
        switch value.dropFirst(5) {
        case "brand-primary": return Color.accentColor
        case "brand-accent": return Color(nsColor: .systemTeal)
        case "surface-canvas": return Color(nsColor: .windowBackgroundColor)
        case "surface-elevated": return Color(nsColor: .controlBackgroundColor)
        case "surface-panel": return Color(nsColor: .underPageBackgroundColor)
        case "surface-sunken": return Color(nsColor: .textBackgroundColor)
        case "surface-inverse": return Color(nsColor: .textColor)
        case "text-primary": return Color(nsColor: .labelColor)
        case "text-inverse": return Color(nsColor: .windowBackgroundColor)
        case "warning": return Color(nsColor: .systemOrange)
        default: return .clear
        }
    }

    private static func dictionary(from value: String?) -> [String: Any] {
        guard let value, let data = value.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return result
    }

    private static func textureImage(kind: String) -> CGImage? {
        guard kind == "brushed" else { return nil }
        let key = kind as NSString
        if let cached = textureCache.object(forKey: key) { return cached }
        let dimension = 64
        guard let context = CGContext(
            data: nil,
            width: dimension,
            height: dimension,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        for y in 0..<dimension {
            for x in 0..<dimension {
                let gray = brushedGrain(x: x, y: y, dimension: dimension)
                context.setFillColor(CGColor(gray: gray, alpha: 1))
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
        guard let image = context.makeImage() else { return nil }
        textureCache.setObject(image, forKey: key)
        return image
    }

    private static func brushedGrain(x: Int, y: Int, dimension: Int) -> Double {
        let u = Double(x) / Double(dimension)
        let v = Double(y) / Double(dimension)
        let lengthwise = sin(2 * .pi * (16 * u + 0.08 * v) + 0.7)
        let variation = cos(2 * .pi * (32 * u - 0.12 * v) + 2.1)
        let banding = sin(2 * .pi * (2 * v + 0.03 * u) + 1.2)
        return min(1, max(0, 0.5 + lengthwise * 0.12 + variation * 0.07 + banding * 0.04))
    }

    private static func applyKeycap(_ view: AnyView, style: String, shape: RoundedRectangle) -> AnyView {
        switch style {
        case "outlined":
            return AnyView(view.padding(.horizontal, 5).padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor), in: shape)
                .overlay(shape.stroke(Color(nsColor: .separatorColor), lineWidth: 1)))
        case "sculpted":
            return AnyView(view.padding(.horizontal, 5).padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor), in: shape)
                .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.7)).frame(height: 1).clipShape(shape) }
                .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.3)).frame(height: 2).clipShape(shape) }
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1))
        case "inset":
            return AnyView(view.padding(.horizontal, 5).padding(.vertical, 2)
                .background(Color(nsColor: .textBackgroundColor), in: shape)
                .overlay {
                    shape.stroke(Color.black.opacity(0.2), lineWidth: 2)
                        .blur(radius: 2)
                        .offset(y: 1)
                        .mask(shape)
                })
        default:
            return view
        }
    }
}

private struct SurfaceCraftFeedbackModifier: ViewModifier {
    private enum DisplayedPhase: String {
        case idle
        case hover
        case pressed
        case focus
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var isPressed = false
    let style: String?
    let previewState: String?
    let cornerRadius: CGFloat

    private var displayedPhase: DisplayedPhase {
        if let previewState {
            switch previewState {
            case "hover": return .hover
            case "pressed": return .pressed
            case "focus": return .focus
            default: break
            }
        }
        if isPressed { return .pressed }
        return isHovering ? .hover : .idle
    }

    private var usesSurfaceCraftFocusStyle: Bool {
        displayedPhase == .focus && style == "edge"
    }

    private var focusRingRadius: CGFloat {
        cornerRadius > 0 ? cornerRadius : 5
    }

    private var feedbackOffset: CGFloat {
        switch style {
        case "sink": return displayedPhase == .pressed ? 1 : 0
        case "lift":
            if displayedPhase == .hover { return -2 }
            return previewState == "pressed" && displayedPhase == .pressed ? 1 : 0
        case "edge": return previewState == "pressed" && displayedPhase == .pressed ? 1 : 0
        default: return 0
        }
    }

    private var liftShadowOpacity: Double {
        guard style == "lift" else { return 0 }
        if displayedPhase == .hover { return 0.16 }
        return previewState == "pressed" && displayedPhase == .pressed ? 0.16 : 0
    }

    private var liftShadowRadius: CGFloat {
        guard style == "lift" else { return 0 }
        if displayedPhase == .hover { return 7 }
        return previewState == "pressed" && displayedPhase == .pressed ? 5 : 0
    }

    private var liftShadowOffsetY: CGFloat {
        guard style == "lift" else { return 0 }
        if displayedPhase == .hover { return 3 }
        return previewState == "pressed" && displayedPhase == .pressed ? 1 : 0
    }

    #if DEBUG
    private var accessibilityPhase: String {
        switch displayedPhase {
        case .focus: return usesSurfaceCraftFocusStyle ? "focus:edge" : "focus:system-ring"
        case .idle, .hover, .pressed: return displayedPhase.rawValue
        }
    }
    #endif

    func body(content: Content) -> some View {
        content
            .background(displayedPhase == .hover ? Color.primary.opacity(0.035) : Color.clear)
            .overlay(alignment: .leading) {
                if style == "edge" && (displayedPhase == .hover || (previewState == "pressed" && displayedPhase == .pressed) || usesSurfaceCraftFocusStyle) {
                    Capsule().fill(Color.accentColor).frame(width: 2).padding(.vertical, 4)
                }
            }
            .overlay {
                if displayedPhase == .focus && !usesSurfaceCraftFocusStyle {
                    RoundedRectangle(cornerRadius: focusRingRadius)
                        .stroke(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
                        .padding(-3)
                        .allowsHitTesting(false)
                }
            }
            .offset(y: reduceMotion ? 0 : feedbackOffset)
            .shadow(color: .black.opacity(liftShadowOpacity),
                    radius: liftShadowRadius, x: 0, y: liftShadowOffsetY)
            .onHover { isHovering = $0 }
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false })
            #if DEBUG
            .accessibilityValue(Text(accessibilityPhase))
            #endif
    }
}

private struct SurfaceCraftNoiseTextureOverlay: View {
    @Environment(\.displayScale) private var displayScale

    let baseFrequency: Double
    let octaveCount: Int32
    let seed: Int32
    let tileSize: Int32
    let opacity: Double
    let shape: RoundedRectangle

    var body: some View {
        if let image = textureTile {
            Image(decorative: image, scale: displayScale)
                .resizable(resizingMode: .tile)
                .interpolation(.none)
                .opacity(opacity)
                .allowsHitTesting(false)
                .clipShape(shape)
        }
    }

    private var textureTile: CGImage? {
        guard displayScale.isFinite, displayScale > 0,
              let pointer = apSurfaceNoiseTextureTileCreate(
                baseFrequency,
                octaveCount,
                seed,
                tileSize,
                Double(displayScale)
              ) else { return nil }
        return Unmanaged<CGImage>.fromOpaque(pointer).takeRetainedValue()
    }
}
#endif

#if !os(macOS)
enum SurfaceCraftModifiers {
    static func hasSurfaceFill(_ spec: String?) -> Bool {
        false
    }

    static func apply(
        _ view: AnyView,
        spec: String?,
        keycapStyle: String?,
        cornerRadius: NSNumber?,
        previewState: String?
    ) -> AnyView {
        view
    }
}
#endif
