// StepperOverrides — per-Stepper overrides above ViewOverrides.

import Foundation

@objc(APSKStepperOverrides)
public class StepperOverrides: ViewOverrides {
    @objc public var step: NSNumber? = nil
    @objc public var wraps: NSNumber? = nil

    @objc public override init() { super.init() }
}
