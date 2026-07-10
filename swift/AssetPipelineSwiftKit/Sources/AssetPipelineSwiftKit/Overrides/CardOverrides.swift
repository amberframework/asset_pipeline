// CardOverrides — per-Card overrides above ViewOverrides.
//
// Field semantics:
//   title        : optional headline displayed above the content.
//   isOutlined   : NSNumber bool. nil = filled card (default).
//   elevation    : NSNumber pt — shadow depth. nil = 1.0 default.
//   material     : "secondary" | "tertiary" | "regular" | "thin" |
//                  "thick" | "ultra_thin". nil = "secondary"
//                  (.regularMaterial fallback).

import Foundation

@objc(APSKCardOverrides)
public class CardOverrides: ViewOverrides {
    @objc public var title: String? = nil
    @objc public var isOutlined: NSNumber? = nil
    @objc public var elevation: NSNumber? = nil
    @objc public var material: String? = nil

    @objc public override init() { super.init() }
}
