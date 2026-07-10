// PopoverOverrides — per-Popover overrides above ViewOverrides.
//
// Field semantics:
//   isPresented       : NSNumber bool. nil = false.
//   arrowEdge         : "top" | "bottom" | "leading" | "trailing".
//                       nil = SwiftUI default (system chooses).
//   preferredWidth    : NSNumber pt. nil = content-driven.
//   preferredHeight   : NSNumber pt. nil = content-driven.

import Foundation

@objc(APSKPopoverOverrides)
public class PopoverOverrides: ViewOverrides {
    @objc public var isPresented: NSNumber? = nil
    @objc public var arrowEdge: String? = nil
    @objc public var preferredWidth: NSNumber? = nil
    @objc public var preferredHeight: NSNumber? = nil
    // Phase 5 v2 — Apple semantic material key. nil → use the per-widget
    // HIG default ("popover"); "system_resolved" → no .presentationBackground.
    @objc public var materialSemantic: String? = nil

    @objc public override init() { super.init() }
}
