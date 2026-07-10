// RadioGroupOverrides — per-RadioGroup overrides above ViewOverrides.
// SwiftUI emits Picker(...).pickerStyle(.radioGroup) on macOS and Picker
// on iOS.

import Foundation

@objc(APSKRadioGroupOverrides)
public class RadioGroupOverrides: ViewOverrides {
    @objc public override init() { super.init() }
}
