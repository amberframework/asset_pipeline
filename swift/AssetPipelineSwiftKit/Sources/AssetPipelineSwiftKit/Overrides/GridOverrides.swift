// GridOverrides — per-Grid overrides above ViewOverrides.
//
// Field semantics:
//   rowSpacing     : NSNumber pt. nil = SwiftUI default.
//   columnSpacing  : NSNumber pt. nil = SwiftUI default.
//   alignment      : "leading" | "center" | "trailing" | "top" | "bottom".
//                    nil = .center per SwiftUI.
//   rowCellCounts  : NSArray<NSNumber *> — number of child views per row.
//                    The flat child-views array is sliced into GridRow
//                    chunks using these counts. Total must match
//                    child count.

import Foundation

@objc(APSKGridOverrides)
public class GridOverrides: ViewOverrides {
    @objc public var rowSpacing: NSNumber? = nil
    @objc public var columnSpacing: NSNumber? = nil
    @objc public var alignment: String? = nil
    @objc public var rowCellCounts: [NSNumber] = []

    @objc public override init() { super.init() }
}
