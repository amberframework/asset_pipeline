// DatePickerOverrides — per-DatePicker overrides above ViewOverrides.

import Foundation

@objc(APSKDatePickerOverrides)
public class DatePickerOverrides: ViewOverrides {
    @objc public var datePickerMode: String? = nil

    @objc public override init() { super.init() }
}
