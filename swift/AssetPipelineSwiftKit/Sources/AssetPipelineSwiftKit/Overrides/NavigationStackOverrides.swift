// NavigationStackOverrides — per-NavigationStack overrides above the common
// ViewOverrides set.
//
// Field semantics:
//   title       : optional navigation-bar title. nil = no title.
//   largeTitle  : NSNumber bool. nil = SwiftUI default (true on iOS 26).
//   showsNavigationBar : NSNumber bool. nil = SwiftUI default (true).

import Foundation

@objc(APSKNavigationStackOverrides)
public class NavigationStackOverrides: ViewOverrides {
    @objc public var title: String? = nil
    @objc public var largeTitle: NSNumber? = nil
    @objc public var showsNavigationBar: NSNumber? = nil

    @objc public override init() { super.init() }
}
