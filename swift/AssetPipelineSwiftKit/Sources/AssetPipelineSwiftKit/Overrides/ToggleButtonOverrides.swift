// ToggleButtonOverrides — per-ToggleButton overrides above ViewOverrides.
//
// Field semantics:
//   icon        : optional SF Symbol leading the label.
//   isSelected  : NSNumber bool. nil = false.

import Foundation

@objc(APSKToggleButtonOverrides)
public class ToggleButtonOverrides: ViewOverrides {
    @objc public var icon: String? = nil
    @objc public var isSelected: NSNumber? = nil

    @objc public override init() { super.init() }
}
