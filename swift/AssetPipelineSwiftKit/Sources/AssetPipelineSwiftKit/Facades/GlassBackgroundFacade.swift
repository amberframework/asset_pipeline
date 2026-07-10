// GlassBackgroundFacade — SwiftUI bridge for UI::GlassBackground, the
// Phase 3 "headline visual differentiator" the README names. On iOS 26 /
// macOS 26 (the Liquid Glass SDKs) the facade routes through
// `.glassBackgroundEffect()`; on the pre-26 OSes (iOS 16..25 / macOS
// 13..25) it falls back to the matching static Material so the surface
// still tracks appearance correctly.
//
// Phase 5 will extend this facade with the full material parameter set
// (intensity, tint, corner curve). The Phase 3 wiring is the platform
// floor: a developer who writes `UI::GlassBackground.new(content)` gets
// real Liquid Glass on iOS 26 today, with no extra knobs.
//
// Brand identity: `GlassBackground` deliberately does NOT apply the
// brand tint (Apple convention — glass surfaces accept system accent
// only). The `.tint()` cascade in `HostingHelpers.host(_:)` propagates
// the brand colour to interactive descendants inside the glass surface;
// the glass material itself stays neutral.

import SwiftUI
import Foundation

@objc(APSKGlassBackgroundFacade)
public final class GlassBackgroundFacade: NSObject {
    /// Build the glass-backed platform view. `childView` is the already-
    /// hosted Crystal child (the content placed behind the glass). When
    /// `nil`, the facade renders an empty glass card.
    @objc public static func makeGlassBackground(
        overrides: GlassBackgroundOverrides,
        childView: APSKPlatformView?
    ) -> APSKPlatformView {
        // Embed the Crystal child via APSKHostedChild so it participates
        // in SwiftUI layout. When no child is supplied we render a clear
        // expanding rectangle so the glass surface has something to back.
        let materialKey = overrides.material ?? "regular"

        // PHASE 5 — Apple-platform material selection.
        //
        // Per brief.yml adapter_cardinality row 1, the SwiftUI Material
        // enum is the public-API <-> Apple-platform adapter. Brand
        // intensity QUANTIZES through a 5-step table, and the pre-26
        // `.background(<Material>)` path honors the resolved step
        // directly. The iOS 26 / macOS 26+ `.glassEffect()` path is the
        // canonical Apple HIG Liquid Glass treatment — it intentionally
        // does NOT vary by Crystal-side step because Liquid Glass is the
        // system-canonical behavior Apple wants every glass surface to
        // adopt on that OS version. Per the brief: "intensity 1.3
        // quantizes to .regularMaterial on Apple (visually IDENTICAL to
        // default intensity 1.0)" — and the same is true across all 5
        // declared steps on iOS 26+ because Liquid Glass treats them
        // uniformly. Brands wanting a step-differentiated Apple look on
        // pre-26 SDKs do see the difference via the .background fallback
        // below; on iOS 26+ the difference is intentionally absent.
        let material: Material = {
            switch materialKey {
            case "thin":       return .thinMaterial
            case "thick":      return .thickMaterial
            case "ultraThin":  return .ultraThinMaterial
            case "ultraThick": return .ultraThickMaterial
            default:           return .regularMaterial
            }
        }()

        let backed: AnyView
        if #available(iOS 26.0, macOS 26.0, *) {
            // Liquid Glass — system-canonical, step-agnostic by design.
            _ = material  // pre-26 only; unused on the Liquid Glass path
            backed = AnyView(
                hostedChild(childView)
                    .glassEffect()
            )
        } else {
            // Pre-26 fallback. `Material` tracks appearance + step.
            backed = AnyView(
                hostedChild(childView)
                    .background(material)
            )
        }

        let composed = CommonModifiers.apply(backed, overrides: overrides)
        return HostingHelpers.host(composed)
    }

    /// Wrap the platform-view child in `APSKHostedChild` (or an empty
    /// rectangle when absent). Returning an `AnyView` keeps the iOS 26 /
    /// fallback branches both type-erased to the same shape.
    @ViewBuilder
    private static func hostedChild(_ child: APSKPlatformView?) -> some View {
        if let child = child {
            APSKHostedChild(view: child)
        } else {
            Rectangle().fill(Color.clear)
        }
    }
}
