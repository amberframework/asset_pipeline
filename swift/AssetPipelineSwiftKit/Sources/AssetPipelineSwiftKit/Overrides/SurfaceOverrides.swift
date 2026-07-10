// SurfaceOverrides — per-Surface overrides above ViewOverrides.
//
// Field semantics:
//   elevation       : NSNumber pt — shadow depth. nil = 0 (flat).
//   tonalElevation  : NSNumber pt — Material-style tonal shift. nil = 0.
//   shape           : "rectangle" | "rounded" | "circle". nil = "rectangle".

import Foundation

@objc(APSKSurfaceOverrides)
public class SurfaceOverrides: ViewOverrides {
    @objc public var elevation: NSNumber? = nil
    @objc public var tonalElevation: NSNumber? = nil
    @objc public var shape: String? = nil

    @objc public override init() { super.init() }
}
