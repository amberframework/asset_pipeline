// LabelOverrides — per-Label overrides above the common ViewOverrides set.
//
// Field semantics (all nil = SwiftUI default):
//
//   labelRole       : "primary" | "secondary" | "tertiary" | "quaternary" — maps
//                     to SwiftUI semantic colours (`.primary`, `.secondary`,
//                     etc.). Mutually exclusive with the `foregroundColor`
//                     RGBA override on ViewOverrides — when both are set,
//                     foregroundColor wins.
//   textAlignment   : "leading" | "center" | "trailing" | "fill" — SwiftUI
//                     `multilineTextAlignment` modifier.
//   numberOfLines   : line cap (0 = unlimited / SwiftUI default).
//   fontSize        : point size for `.font(.system(size:weight:))`. nil = use
//                     SwiftUI body default. The Crystal `UI::Font.size`
//                     property is forwarded through here so a brand wordmark
//                     can render at h1-bold display size while still tracking
//                     Dynamic Type.
//   fontWeight      : raw `Font.Weight` int rawValue (regular = 0, ultraLight
//                     = -3, bold = 3, heavy = 4, black = 5). nil = .regular.
//                     Matches the convention ButtonOverrides already uses.

import Foundation

@objc(APSKLabelOverrides)
public class LabelOverrides: ViewOverrides {
    @objc public var labelRole: String? = nil
    @objc public var textAlignment: String? = nil
    @objc public var numberOfLines: NSNumber? = nil
    @objc public var fontSize: NSNumber? = nil
    @objc public var fontWeight: NSNumber? = nil
    // Phase 6.11 — strikethrough toggle. nil = SwiftUI default (no
    // strikethrough); `true` applies `.strikethrough(true)` so completed
    // todo rows render with a HIG-correct line through the title.
    @objc public var strikethrough: NSNumber? = nil

    @objc public override init() { super.init() }
}
