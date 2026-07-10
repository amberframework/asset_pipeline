// MenuButtonOverrides — per-MenuButton overrides above ViewOverrides.
//
// Field semantics:
//   icon           : optional SF Symbol on the button face.
//   isPullDown     : NSNumber bool. nil = false (pop-up mode).
//   buttonStyle    : "default" | "prominent". nil = "default".
//   selectedIndex  : NSNumber Int. nil = 0.
//   itemLabels     : NSArray<NSString *> of menu-item labels.
//   itemIcons      : NSArray<NSString *> of SF Symbol names (parallel to
//                    itemLabels; empty string = no icon).
//   itemIsDestructive : NSArray<NSNumber *> bool flags parallel to
//                    itemLabels.
//   itemTokens     : NSArray<NSNumber *> of UInt64 action tokens.

import Foundation

@objc(APSKMenuButtonOverrides)
public class MenuButtonOverrides: ViewOverrides {
    @objc public var icon: String? = nil
    @objc public var isPullDown: NSNumber? = nil
    @objc public var buttonStyle: String? = nil
    @objc public var selectedIndex: NSNumber? = nil
    @objc public var itemLabels: [String] = []
    @objc public var itemIcons: [String] = []
    @objc public var itemIsDestructive: [NSNumber] = []
    @objc public var itemTokens: [NSNumber] = []

    @objc public override init() { super.init() }
}
