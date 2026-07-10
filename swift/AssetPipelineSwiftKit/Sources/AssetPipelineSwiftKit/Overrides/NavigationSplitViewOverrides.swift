// NavigationSplitViewOverrides — per-NavigationSplitView overrides above
// ViewOverrides.
//
// Field semantics:
//   sidebarWidth     : preferred sidebar column width in points. nil = SwiftUI
//                      default (~270pt on macOS, automatic on iOS).
//   columnVisibility : "all" | "doubleColumn" | "detailOnly".
//                      nil = SwiftUI default (.automatic).
//   materialSemantic : Phase 5 v2. Crystal-side AppleSemantic key
//                      (snake_case). nil → use the per-widget HIG default
//                      ("sidebar"); "system_resolved" → no .background()
//                      modifier (let Apple defaults apply).

import Foundation

@objc(APSKNavigationSplitViewOverrides)
public class NavigationSplitViewOverrides: ViewOverrides {
    @objc public var sidebarWidth: NSNumber? = nil
    @objc public var columnVisibility: String? = nil
    @objc public var materialSemantic: String? = nil

    @objc public override init() { super.init() }
}
