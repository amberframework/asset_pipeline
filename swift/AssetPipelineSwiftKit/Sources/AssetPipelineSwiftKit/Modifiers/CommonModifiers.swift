// CommonModifiers — the helper every facade calls at the end of its
// pipeline to apply the `ViewOverrides` fields conditionally. A `nil`
// field means the developer left the Crystal property at its type
// default; the corresponding modifier is skipped so SwiftUI's own
// default treatment shows through.
//
// Modifier ordering is deliberate (see implementation.md §5.4):
//   1. background (color)
//   2. foreground (color / style)
//   3. cornerRadius / clip
//   4. padding (insets)
//   5. border overlay
//   6. shadow
//   7. opacity
//   8. hidden
//   9. frame (min/max width/height)
//   10. accessibility identifier
//   11. accessibility label
//
// Each step wraps the prior `AnyView` so the cascade stays composable.

import SwiftUI

enum CommonModifiers {
    static func apply<V: View>(_ view: V, overrides: ViewOverrides) -> AnyView {
        var current = AnyView(view)

        if let bg = overrides.backgroundColor {
            current = AnyView(current.background(swiftColor(bg)))
        }
        if let fg = overrides.foregroundColor {
            current = AnyView(current.foregroundStyle(swiftColor(fg)))
        }
        if let r = overrides.cornerRadius {
            current = AnyView(current.clipShape(
                RoundedRectangle(cornerRadius: CGFloat(r.doubleValue))
            ))
        }
        if overrides.paddingTop != nil || overrides.paddingLeading != nil
            || overrides.paddingBottom != nil || overrides.paddingTrailing != nil {
            let insets = EdgeInsets(
                top: overrides.paddingTop.map { CGFloat($0.doubleValue) } ?? 0,
                leading: overrides.paddingLeading.map { CGFloat($0.doubleValue) } ?? 0,
                bottom: overrides.paddingBottom.map { CGFloat($0.doubleValue) } ?? 0,
                trailing: overrides.paddingTrailing.map { CGFloat($0.doubleValue) } ?? 0
            )
            current = AnyView(current.padding(insets))
        }
        if let bw = overrides.borderWidth, let bc = overrides.borderColor {
            current = AnyView(current.overlay(
                RoundedRectangle(cornerRadius: CGFloat(overrides.cornerRadius?.doubleValue ?? 0))
                    .stroke(swiftColor(bc), lineWidth: CGFloat(bw.doubleValue))
            ))
        }
        if let sr = overrides.shadowRadius {
            let sc = overrides.shadowColor.map { swiftColor($0) } ?? Color.black.opacity(0.25)
            let sx = overrides.shadowOffsetX.map { CGFloat($0.doubleValue) } ?? 0
            let sy = overrides.shadowOffsetY.map { CGFloat($0.doubleValue) } ?? 0
            current = AnyView(current.shadow(color: sc, radius: CGFloat(sr.doubleValue), x: sx, y: sy))
        }
        if let o = overrides.opacity {
            current = AnyView(current.opacity(o.doubleValue))
        }
        if let h = overrides.hidden, h.boolValue {
            current = AnyView(current.hidden())
        }
        if overrides.minWidth != nil || overrides.minHeight != nil
            || overrides.maxWidth != nil || overrides.maxHeight != nil {
            // SwiftUI's `frame(minHeight:)` alone does not enlarge the
            // rendered view's size — it only constrains the layout
            // proposal. UIHostingController.sizingOptions reads the
            // rendered size, so `Button {} .frame(minHeight: 44)` still
            // hands UIKit the Button's natural ~25pt body-text height
            // and BX6 / BX9 fail. We need the rendered Button to actually
            // be 44pt tall.
            //
            // Strategy:
            //   - If min == max → exact `frame(height:)` / `frame(width:)`
            //   - If only `minHeight` set → wrap in a `VStack` with the
            //     view centered, then pin the VStack to the minimum
            //     height. This forces a containing frame of at least
            //     `minHeight` tall while preserving the child's intrinsic
            //     width. The accessibility tree still surfaces the inner
            //     control as the addressable element (its accessibility
            //     identifier was applied earlier in the cascade).
            let minW = overrides.minWidth.map { CGFloat($0.doubleValue) }
            let maxW = overrides.maxWidth.map { CGFloat($0.doubleValue) }
            let minH = overrides.minHeight.map { CGFloat($0.doubleValue) }
            let maxH = overrides.maxHeight.map { CGFloat($0.doubleValue) }

            // Height: SwiftUI's `frame(minHeight:)` only resizes the
            // CONTAINER, not the child view. XCUITest reads the inner
            // element's frame, so the inner view must actually be at
            // least minHeight tall. When the developer set only a
            // minimum and no maximum, we treat the minimum as an exact
            // pin (`frame(height: mh)`) so the rendered Button / Toggle
            // / etc. actually grows to that size.
            if let mh = minH, let mxh = maxH, mh == mxh {
                current = AnyView(current.frame(height: mh))
            } else if let mh = minH, maxH == nil {
                // Only minHeight: treat as exact for the touch-target use
                // case. If the caller wants a flexible floor with no
                // ceiling they should set maxHeight = .infinity (or any
                // explicit max) explicitly on the Crystal side.
                current = AnyView(current.frame(height: mh))
            } else if let mh = minH, let mxh = maxH {
                current = AnyView(current.frame(minHeight: mh, maxHeight: mxh))
            } else if let mxh = maxH {
                current = AnyView(current.frame(maxHeight: mxh))
            }

            // Width: same logic.
            if let mw = minW, let mxw = maxW, mw == mxw {
                current = AnyView(current.frame(width: mw))
            } else if let mw = minW, maxW == nil {
                current = AnyView(current.frame(width: mw))
            } else if let mw = minW, let mxw = maxW {
                current = AnyView(current.frame(minWidth: mw, maxWidth: mxw))
            } else if let mxw = maxW {
                current = AnyView(current.frame(maxWidth: mxw))
            }
        }
        if let id = overrides.accessibilityIdentifier {
            current = AnyView(current.accessibilityIdentifier(id))
        }
        if let lbl = overrides.apskAccessibilityLabel {
            current = AnyView(current.accessibilityLabel(Text(lbl)))
        }
        return current
    }

    /// Cross-platform `Color` constructor. SwiftUI's `Color(uiColor:)` and
    /// `Color(nsColor:)` are platform-specific; we route through a single
    /// helper so facade code stays platform-agnostic.
    @inline(__always)
    private static func swiftColor(_ c: APSKPlatformColor) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: c)
        #else
        return Color(nsColor: c)
        #endif
    }
}
