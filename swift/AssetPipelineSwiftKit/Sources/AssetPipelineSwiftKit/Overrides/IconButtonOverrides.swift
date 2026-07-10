// IconButtonOverrides — per-IconButton overrides above ViewOverrides.

import Foundation

@objc(APSKIconButtonOverrides)
public class IconButtonOverrides: ViewOverrides {
    @objc public var iconSize: NSNumber? = nil
    @objc public var disabled: NSNumber? = nil
    @objc public var label: String? = nil

    @objc public override init() { super.init() }
}
