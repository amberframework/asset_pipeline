// ImageOverrides — per-Image overrides above ViewOverrides.
//
// Fields:
//   contentMode : "fit" | "fill" | "stretch" — maps to SwiftUI `.resizable()`
//                 + `.aspectRatio(contentMode:)`. nil = SwiftUI default (no
//                 resizing).

import Foundation

@objc(APSKImageOverrides)
public class ImageOverrides: ViewOverrides {
    @objc public var contentMode: String? = nil

    @objc public override init() { super.init() }
}
