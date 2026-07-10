// ToggleOverrides — per-Toggle overrides above ViewOverrides.
//
// toggleStyle : "switch" | "button" | "checkbox" — maps to SwiftUI's
//               `.toggleStyle(.switch / .button / .checkbox)`. nil =
//               `.switch` (the system default on iOS; macOS picks
//               `.checkbox` automatically inside Forms).
// disabled    : NSNumber bool. nil = enabled.

import Foundation

@objc(APSKToggleOverrides)
public class ToggleOverrides: ViewOverrides {
    @objc public var toggleStyle: String? = nil
    @objc public var disabled: NSNumber? = nil

    @objc public override init() { super.init() }
}
