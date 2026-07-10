// SearchFieldOverrides — per-SearchField overrides above ViewOverrides.
//
// SwiftUI's `.searchable` is attached to a containing view; the facade
// emulates a stand-alone search field via TextField + a leading
// magnifying-glass system image so the same Crystal abstraction works on
// macOS and iOS.

import Foundation

@objc(APSKSearchFieldOverrides)
public class SearchFieldOverrides: ViewOverrides {
    @objc public var showsCancelButton: NSNumber? = nil

    @objc public override init() { super.init() }
}
