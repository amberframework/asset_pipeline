// ColorPickerOverrides — per-ColorPicker overrides above ViewOverrides.

import Foundation

@objc(APSKColorPickerOverrides)
public class ColorPickerOverrides: ViewOverrides {
    @objc public var supportsOpacity: NSNumber? = nil

    @objc public override init() { super.init() }
}
