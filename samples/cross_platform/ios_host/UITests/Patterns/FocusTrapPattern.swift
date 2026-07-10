// Phase 6.5 D4 — Focus trap probe pattern.
//
// Snapshots the current "active" element on iOS (the element that is
// hittable + considered the focused responder), runs an action, then
// snapshots again. Tests assert the post-snapshot returns to the
// pre-snapshot's identifier (focus restoration on dismiss).

import XCTest

enum FocusTrapPattern {
    struct FocusSnapshot: Equatable {
        let identifier: String
        let elementType: XCUIElement.ElementType
    }

    /// Capture the "currently focused" element. iOS doesn't directly
    /// expose firstResponder, but a "hittable + has-keyboard-focus" element
    /// approximates it. We sample by walking app.descendants(matching: .any)
    /// for the first hasFocus-true match.
    ///
    /// Falls back to the trigger element when no explicit focus is set
    /// (the rubric uses "the invoking element is still reachable" as the
    /// pass predicate).
    static func capture(app: XCUIApplication, fallbackId: String) -> FocusSnapshot {
        let candidates = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasKeyboardFocus == true"))
        if candidates.count > 0 {
            let elem = candidates.firstMatch
            return FocusSnapshot(
                identifier: elem.identifier,
                elementType: elem.elementType,
            )
        }
        let fallback = app.descendants(matching: .any).matching(identifier: fallbackId).firstMatch
        return FocusSnapshot(
            identifier: fallback.exists ? fallback.identifier : "",
            elementType: fallback.exists ? fallback.elementType : .any,
        )
    }

    /// Wrap a focus-changing block, returning pre+post snapshots.
    @discardableResult
    static func around(
        app: XCUIApplication,
        fallbackId: String,
        _ block: () -> Void
    ) -> (pre: FocusSnapshot, post: FocusSnapshot) {
        let pre = capture(app: app, fallbackId: fallbackId)
        block()
        let post = capture(app: app, fallbackId: fallbackId)
        return (pre: pre, post: post)
    }
}
