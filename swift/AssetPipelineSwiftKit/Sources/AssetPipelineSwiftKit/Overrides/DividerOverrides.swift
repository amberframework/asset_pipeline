// DividerOverrides — per-Divider overrides above ViewOverrides.

import Foundation

@objc(APSKDividerOverrides)
public class DividerOverrides: ViewOverrides {
    @objc public var thickness: NSNumber? = nil
    @objc public var orientation: String? = nil

    @objc public override init() { super.init() }
}
