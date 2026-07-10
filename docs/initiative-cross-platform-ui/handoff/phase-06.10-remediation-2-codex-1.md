# Phase 6.10 Remediation 2 — Codex Review 1

**Date:** 2026-05-23
**Commit reviewed:** `b596cd7`
**Prompt:** Review iter 1 vs `docs/initiative-cross-platform-ui/phases/phase-06.10-navigable-crud-demo/remediation-2.md`.

## Verdict: REGRESSION

## Findings (verbatim from Codex)

> Acceptance item broken: **Item 2, AX tree full scope**. The required XCUITest was supposed to run the existing 4-step navigation flow and find/tap labeled buttons. The diff removes the host assertion and Sign-in assertion, replaces the tap with a hard-coded app coordinate, and then returns before Settings/back navigation. That makes the test no longer prove AX traversal or the 4-step flow.

### On the focus points

- The width-pin pattern is directionally sound: `todos.cr` pins root/header/list/row with `min_w == max_w`, which matches the renderer's exact-width semantics. It is progress, but not PASS without committed iOS screenshot proof.
- Dropping the outer `ScrollView` is a regression risk. The diff removes it and replaces it with an assumption that all Voyager screens fit iPhone 17 portrait. The repo has no Voyager `UI::ScrollView`; the only `UI::ScrollView` mention is this new comment.
- The NSLog placement is mostly correct: Crystal-side `on_tap` logs prove Proc execution, and `CallbackBridge.fire` logs before dispatch prove whether SwiftUI `Button.action` fired.
- The interaction diagnosis is plausible but not proven by this diff. If the `CallbackBridge.fire` line never appears, then the SwiftUI button action did not fire. But the diff's test does not prove the tap lands on the visible button cap: the comment says element coordinate, while the code uses `app.coordinate(...)` globally.

### Net

Meaningful progress on layout and diagnostics, but the commit regresses the acceptance test itself.

## Implementer response

Rem 2 iter 2 must:
1. Restore the XCUITest 4-step navigation flow assertions. Even if the navigation taps don't currently fire on_tap (per the interaction proof finding), the AX traversal checks themselves (host wait, button.exists, accessibilityLabel discoverability) are independent of whether tap actually fires.
2. Either prove the tap lands on the visible button cap (rectangle-based hit point computed from the AX frame), or document explicitly that the coordinate is offset from the visible cap.
3. Decide whether the outer SwiftUI ScrollView should be restored. The acceptance is "iOS sign-in renders + Sign-in button visible" — without ScrollView, very-tall screens (Todos with many rows) would clip on iPhone 17 portrait. Decision: restore ScrollView unless we ALSO confirm via offscreen that all 4 screens fit naturally.
4. Codex blocker doc captures the architectural touch-routing finding so the architect can decide on the UIButton-bypass vs SwiftUI-fix path.

— Implementer (Phase 6.10 Rem 2)
