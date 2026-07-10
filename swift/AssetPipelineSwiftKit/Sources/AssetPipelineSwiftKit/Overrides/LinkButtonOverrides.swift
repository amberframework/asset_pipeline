// LinkButtonOverrides — per-LinkButton overrides above ViewOverrides.
// SwiftUI's `Link(_:destination:)` already handles tap, focus, accent
// colour, and pressed state via `.tint()`. No widget-specific knobs today.

import Foundation

@objc(APSKLinkButtonOverrides)
public class LinkButtonOverrides: ViewOverrides {
    @objc public override init() { super.init() }
}
