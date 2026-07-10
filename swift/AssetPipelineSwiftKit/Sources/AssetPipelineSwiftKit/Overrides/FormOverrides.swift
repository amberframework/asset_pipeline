// FormOverrides — per-Form overrides above ViewOverrides.
//
// Field semantics:
//   sectionHeaders : NSArray<NSString *> of per-section headers (empty
//                    string = no header for that section).
//   sectionFooters : NSArray<NSString *> of per-section footers.
//   sectionFieldCounts : NSArray<NSNumber *> giving the number of field
//                    child views per section. Children are flattened into
//                    a single child-views array; the facade slices them
//                    per section using these counts.
//   sectionFieldLabels : NSArray<NSString *> of per-field labels, flat
//                    across all sections (length == sum of field counts).

import Foundation

@objc(APSKFormOverrides)
public class FormOverrides: ViewOverrides {
    @objc public var sectionHeaders: [String] = []
    @objc public var sectionFooters: [String] = []
    @objc public var sectionFieldCounts: [NSNumber] = []
    @objc public var sectionFieldLabels: [String] = []

    @objc public override init() { super.init() }
}
