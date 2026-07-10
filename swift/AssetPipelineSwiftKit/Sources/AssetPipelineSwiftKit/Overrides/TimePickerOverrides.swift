// TimePickerOverrides — per-TimePicker overrides above ViewOverrides.

import Foundation

@objc(APSKTimePickerOverrides)
public class TimePickerOverrides: ViewOverrides {
    @objc public var shows24Hour: NSNumber? = nil
    @objc public var minuteInterval: NSNumber? = nil

    @objc public override init() { super.init() }
}
