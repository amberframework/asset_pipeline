// SliderOverrides — per-Slider overrides above ViewOverrides.

import Foundation

@objc(APSKSliderOverrides)
public class SliderOverrides: ViewOverrides {
    @objc public var step: NSNumber? = nil

    @objc public override init() { super.init() }
}
