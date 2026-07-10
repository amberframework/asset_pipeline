// CheckboxOverrides — per-Checkbox overrides above ViewOverrides.
// SwiftUI collapses Checkbox onto Toggle().toggleStyle(.checkbox); the
// facade emits that pairing automatically so we keep this carrier
// minimal.

import Foundation

@objc(APSKCheckboxOverrides)
public class CheckboxOverrides: ViewOverrides {
    @objc public override init() { super.init() }
}
