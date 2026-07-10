// PickerOverrides — per-Picker overrides above ViewOverrides.
//
// pickerStyle : "menu" | "wheel" | "segmented" | "inline" | "navigationlink"
//                — maps to the matching SwiftUI `.pickerStyle(...)` value.
//                nil = `.menu` (SwiftUI's contextual default).

import Foundation

@objc(APSKPickerOverrides)
public class PickerOverrides: ViewOverrides {
    @objc public var pickerStyle: String? = nil

    @objc public override init() { super.init() }
}
