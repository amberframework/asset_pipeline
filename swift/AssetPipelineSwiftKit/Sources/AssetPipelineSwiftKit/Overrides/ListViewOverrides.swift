// ListViewOverrides — per-ListView overrides above ViewOverrides.
//
// `UI::ListView` is a sectioned list (`Array(Section)`) where each
// section carries an optional header, an optional footer, and an array
// of item child views. The Crystal Populator flattens all section items
// into a single `childViews` array; the facade slices them back into
// sections using `sectionItemCounts`.
//
// Field semantics:
//   listStyle        : "plain" | "grouped" | "inset" | "insetGrouped"
//                      | "sidebar". Maps to SwiftUI `.listStyle(...)`.
//                      nil → SwiftUI default (`.automatic`).
//   sectionHeaders   : NSArray<NSString *> of per-section headers (empty
//                      string = no header for that section).
//   sectionFooters   : NSArray<NSString *> of per-section footers.
//   sectionItemCounts: NSArray<NSNumber *> giving the number of item
//                      child views per section. The facade slices the
//                      flat childViews using these counts.
//   showsSeparators  : NSNumber? (bool-as-int). nil = use the SwiftUI
//                      default for the chosen list style. Crystal's
//                      `UI::ListView.shows_separators` default is `true`
//                      (matches SwiftUI default); the populator only
//                      emits this when the developer turned separators
//                      off, so the facade only sees `false` here.

import Foundation

@objc(APSKListViewOverrides)
public class ListViewOverrides: ViewOverrides {
    @objc public var listStyle: String? = nil
    @objc public var sectionHeaders: [String] = []
    @objc public var sectionFooters: [String] = []
    @objc public var sectionItemCounts: [NSNumber] = []
    @objc public var showsSeparators: NSNumber? = nil

    @objc public override init() { super.init() }
}
