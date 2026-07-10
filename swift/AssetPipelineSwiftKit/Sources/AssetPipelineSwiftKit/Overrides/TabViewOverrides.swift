// TabViewOverrides — per-TabView overrides above ViewOverrides.
//
// Field semantics:
//   selectedTintColor : tint applied to selected tab icon + label. nil =
//                       inherit the brand cascade tint or system accent.
//   tabBarPosition    : "top" | "bottom". nil = SwiftUI default (bottom on
//                       iOS, integrated chrome on macOS).
//   glassBar          : NSNumber bool. nil = SwiftUI default (true on iOS 26
//                       per HIG Liquid Glass).
//   tabLabels         : NSArray<NSString *> of tab titles in tab order.
//   tabIcons          : NSArray<NSString *> of SF Symbol names (parallel to
//                       tabLabels). An empty string in this array signals
//                       "no icon for this tab."

import Foundation

@objc(APSKTabViewOverrides)
public class TabViewOverrides: ViewOverrides {
    @objc public var selectedTintColor: APSKPlatformColor? = nil
    @objc public var tabBarPosition: String? = nil
    @objc public var glassBar: NSNumber? = nil
    @objc public var tabLabels: [String] = []
    @objc public var tabIcons: [String] = []
    @objc public var selectedIndex: Int = 0
    // Phase 5 v2 — Apple semantic material key. nil → use the per-widget
    // HIG default ("system_resolved" — SwiftUI bar chrome handles it).
    @objc public var materialSemantic: String? = nil

    @objc public override init() { super.init() }
}
