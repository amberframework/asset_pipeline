// NavigationLinkOverrides — per-NavigationLink overrides above ViewOverrides.
//
// Field semantics:
//   icon              : SF Symbol leading-glyph name. nil = label-only.
//   showsDisclosure   : NSNumber bool. nil = SwiftUI default (chevron shown
//                       inside Lists, suppressed elsewhere).

import Foundation

@objc(APSKNavigationLinkOverrides)
public class NavigationLinkOverrides: ViewOverrides {
    @objc public var icon: String? = nil
    @objc public var showsDisclosure: NSNumber? = nil

    @objc public override init() { super.init() }
}
