// SpacerOverrides — per-Spacer overrides above ViewOverrides.

import Foundation

@objc(APSKSpacerOverrides)
public class SpacerOverrides: ViewOverrides {
    @objc public var minLength: NSNumber? = nil

    @objc public override init() { super.init() }
}
