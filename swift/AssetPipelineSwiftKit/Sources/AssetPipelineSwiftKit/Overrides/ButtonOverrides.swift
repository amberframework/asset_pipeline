// ButtonOverrides — per-Button overrides above the common ViewOverrides set.
//
// Field semantics:
//
//   role          : "default" | "destructive" | "cancel". nil = "default".
//                   "destructive" maps to SwiftUI's ButtonRole.destructive
//                   (red emphasis); "cancel" maps to a semibold label per HIG.
//   style         : "automatic" (nil) | "prominent" | "tinted" | "bordered" |
//                   "borderless". The Swift facade applies the corresponding
//                   buttonStyle modifier; nil lets SwiftUI pick per context.
//   fontWeight    : raw Font.Weight intvalue (regular = 0, ultraLight = -3,
//                   bold = 4, heavy = 5, black = 6). nil = .regular.
//   disabled      : NSNumber bool. nil = enabled (SwiftUI default).
//   symbolName    : SF Symbol leading-glyph name; nil = no symbol.

import Foundation

@objc(APSKButtonOverrides)
public class ButtonOverrides: ViewOverrides {
    @objc public var fontWeight: NSNumber? = nil
    @objc public var role: String? = nil
    @objc public var style: String? = nil
    @objc public var disabled: NSNumber? = nil
    @objc public var symbolName: String? = nil

    @objc public override init() { super.init() }
}
