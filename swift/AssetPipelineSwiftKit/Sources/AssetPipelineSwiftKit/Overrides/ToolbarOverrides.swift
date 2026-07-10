// ToolbarOverrides — per-Toolbar overrides above ViewOverrides.
//
// Field semantics:
//   title         : optional toolbar title displayed at the leading edge.
//   showsTitle    : NSNumber bool. nil = SwiftUI default (true if title set).
//   itemLabels    : NSArray<NSString *> of toolbar-item labels (used for
//                   accessibility + SwiftUI Label).
//   itemIcons     : NSArray<NSString *> of SF Symbol names (parallel to
//                   itemLabels). Empty string = label-only.
//   itemTokens    : NSArray<NSNumber *> of UInt64 action tokens.
//   itemPlacements: NSArray<NSString *> — "primary" | "secondary" |
//                   "navigation" | "principal" | "cancellation". nil
//                   entries → primary.

import Foundation

@objc(APSKToolbarOverrides)
public class ToolbarOverrides: ViewOverrides {
    @objc public var title: String? = nil
    @objc public var showsTitle: NSNumber? = nil
    @objc public var itemLabels: [String] = []
    @objc public var itemIcons: [String] = []
    @objc public var itemTokens: [NSNumber] = []
    @objc public var itemPlacements: [String] = []
    // Phase 5 v2 — Apple semantic material key. nil → use the per-widget
    // HIG default ("system_resolved" — SwiftUI bar chrome handles it).
    @objc public var materialSemantic: String? = nil

    @objc public override init() { super.init() }
}
