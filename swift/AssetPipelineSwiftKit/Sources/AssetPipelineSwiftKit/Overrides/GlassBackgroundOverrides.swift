// GlassBackgroundOverrides — override carrier for the GlassBackground
// widget, the "headline visual differentiator" the Phase 3 README names
// (Liquid Glass on default Card/Sheet). The facade reads the `material`
// key to pick a Material family on pre-iOS 26 OSes and an `if
// #available(iOS 26.0, macOS 26.0, *) { .glassBackgroundEffect() }`
// branch on iOS 26+ — that's where the actual Liquid Glass material
// kicks in.
//
// Phase 5 extension surface: when Phase 5 ships the full glass material
// parameter set (intensity, tint, corner curve) those fields will be
// appended here as additional @objc-exposed nullable properties. The
// Phase 3 shape leaves them as pure extension — no rework. Specifically,
// Phase 5 will add:
//
//   @objc public var materialIntensity: NSNumber?   // 0..1
//   @objc public var tintColor: APSKPlatformColor?  // brand-aware tint
//   @objc public var cornerCurve: String?           // "circular" | "continuous"
//
// and the facade will pass these into the iOS 26 modifier chain.

import Foundation

@objc(APSKGlassBackgroundOverrides)
public final class GlassBackgroundOverrides: ViewOverrides {
    /// One of "regular" | "thin" | "thick" | "ultraThin" | "ultraThick".
    /// `nil` selects the SwiftUI default (`.regularMaterial` / Liquid Glass
    /// "regular" on iOS 26).
    @objc public var material: String?

    // Phase 5 will extend this carrier with material parameters
    // (materialIntensity, tintColor, cornerCurve). The Phase 3 shape
    // leaves those Phase 5 additions as pure extension — no rework.

    @objc public override init() { super.init() }
}
