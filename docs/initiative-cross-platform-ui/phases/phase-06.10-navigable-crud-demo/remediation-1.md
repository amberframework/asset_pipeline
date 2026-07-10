# Phase 6.10 — Remediation 1 Brief

**Date opened:** 2026-05-23
**Authored by:** Architect (Seth-approved scope)
**Branch:** `phase-06.10-navigable-crud-demo` (continue from `df14ee7`)
**Codex protocol:** Per-iteration critique enabled (Rem 4 pattern from Phase 6.9)
**Closing gate:** Owner hands-on verification on iOS Sim AND macOS bin

---

## Why this remediation exists

The owner ran VoyagerDemo.app on iPhone 17 simulator and surfaced a
non-functional UIKit experience. Full findings preserved verbatim in
`handoff/phase-06.10-owner-hands-on-findings-2026-05-23.md`. The earlier
`handoff/phase-06.10-cont-blocker-2026-05-23.md` (which scoped only the
XCUITest AX tree gap) is now superseded by the wider scope below.

The bugs cluster in `src/ui/renderers/uikit_renderer.cr` and the iOS
host glue at `samples/initiative-cross-platform-ui-voyager/ios/`, and
the analogous macOS code in `src/ui/renderers/appkit_renderer.cr` +
`samples/initiative-cross-platform-ui-voyager/macos/host.cr` is
unverified — likely carrying the same defect pattern. Both surfaces
must close together.

---

## Scope — all five items, single dispatch

### 1. UIKit interaction layer (must-fix)

**Symptom:** Taps don't fire button callbacks; text fields don't show
focus state when tapped.

**Audit checklist for the Implementer:**

- In `uikit_renderer.cr`'s `visit_button`: confirm `addTarget:action:forControlEvents:UIControlEventTouchUpInside`
  actually lands on the `UIButton` instance, not on a parent wrapper
  `UIView` that the visitor returns. Verify the action selector resolves
  to a Swift/ObjC trampoline that invokes the Crystal callback through
  `CallbackRegistry`.
- Confirm `userInteractionEnabled` is `YES` (default, but verify nothing
  in the visit chain flips it off — VStack-mapped UIView, root container,
  iOS host's content view).
- Confirm CallbackRegistry retains the Crystal `Proc` for the lifetime
  of the UIButton. If the registry is keyed by view identity, confirm
  the registry isn't reaped on coordinator re-render.
- For `visit_text_field` + `visit_secure_field`: confirm the UITextField
  is a leaf with `userInteractionEnabled=YES`, and confirm tap-to-focus
  works (no parent gesture recognizer eats the tap, no overlapping
  invisible view sits above it).
- Repeat for the macOS counterparts in `appkit_renderer.cr`:
  `visit_button` (NSButton's `target` + `action`) and `visit_text_field`
  (NSTextField's `delegate` + first-responder activation).

**Acceptance:** Owner can tap an input and see a focus ring/cursor.
Owner can tap Sign-in and see the screen advance to Todos.

### 2. UIKit (and AppKit) AX tree propagation (must-fix)

**Symptom:** XCUITest cannot find Crystal-rendered Buttons; the AX
hierarchy stops at ScrollView with no children visible.

**Audit checklist:**

- In `uikit_renderer.cr`: every leaf interactive view (`UIButton`,
  `UITextField`, `UISwitch`, `UISlider`, `UISecureField`) must have
  `isAccessibilityElement = YES` and `accessibilityLabel = <Crystal
  accessibility_label || derived label>`.
- Every container view (VStack/HStack/ZStack-mapped `UIView`, root
  containers, scroll contents) must have `isAccessibilityElement = NO`
  so its descendants are visible to AX traversal. The default is `NO`
  for `UIView` subclasses, `YES` for `UIControl`, so confirm none of
  the container paths inadvertently flip it to `YES`.
- For label-bearing non-control text (e.g. `Label`-mapped `UILabel`),
  set `isAccessibilityElement = YES` + `accessibilityLabel = text`
  (UILabel defaults to YES, but verify it's not suppressed by a parent
  group element).
- Same audit for `appkit_renderer.cr`: NSButton, NSTextField, NSSlider,
  NSSegmentedControl. `accessibilityElement` + `accessibilityLabel` via
  the NSAccessibility protocol (`setAccessibilityLabel:` /
  `accessibilityLabel=`).

**Acceptance:** XCUITest at `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift`
can find each labeled element and the navigation flow advances. macOS
AXTest equivalent confirms the same on the AppKit side.

### 3. Framework iOS form layout defaults (must-fix — framework work)

**Symptom:** Black bars top/bottom (safe area not extended), no
gutters, overlapping form fields (no vertical rhythm), sign-in
button placed where authored rather than at a sensible default.

**Scope:** This is library-level, not demo-level. The library promises
beautiful-by-default per CLAUDE.md; iOS forms today don't deliver.

**Audit checklist:**

- **Safe area + full-screen.** iOS host's root view in
  `samples/.../ios/Sources/ContentView.swift` should consume the full
  window. If the SwiftUI host wraps Crystal's UIView in a way that
  leaves black bars (e.g. fixed frame, ignoring safe-area
  modifiers), fix in the host. If the Crystal-rendered root UIView
  itself is sized to a sub-rect, fix in the renderer's root-view
  sizing pass.
- **Default vertical rhythm for VStack.** The current default spacing
  (per `UI::VStack.new(spacing: …)` default) when authoring a Voyager
  screen produced overlapping fields. Pick one of:
   (a) Raise the VStack default spacing on iOS to a HIG-conformant
       value (likely 12–16 pt).
   (b) Add a form-context wrapper that applies its own spacing default.
   (c) Document explicitly that authors MUST pass `spacing:` on every
       VStack — but this contradicts beautiful-by-default and is the
       wrong choice.
  Recommendation: (a) with a constant `UI::VStack::DEFAULT_SPACING_PT = 12.0`
  if a value isn't already explicit. Apply consistently across renderers
  (web + UIKit + AppKit).
- **Default root horizontal gutters.** The root content view inside a
  navigation host should have horizontal padding on iOS (likely 16 pt,
  matching Apple's default `layoutMargins`). Either ship this as a
  renderer-applied default on the root or via a `UI::Screen` wrapper.
  Pick whichever is least disruptive to existing demos (Cascade,
  HIG showcase).
- **Form field min-height + intrinsic content.** Confirm UITextField /
  UISecureField have HIG-minimum tap targets (44 pt) and don't collapse
  to text-only intrinsic size when placed in a VStack with no
  height constraint.

**Acceptance:** Newly built Voyager Sign-in screen shows the email +
password fields with visible spacing between them, edge-to-edge fill
to the top + bottom of the device window (no black bars), and 16 pt
horizontal gutters. Same on macOS (the macOS host's NSWindow content
view fills the window, NSStackView spacing honored).

### 4. Voyager demo screen authoring corrections (must-fix)

**Symptom:** Sign-in button is at the top of the screen rather than
below the inputs or at the bottom; chart on Todos screen position
unverified.

**Audit checklist:**

- Re-read `samples/initiative-cross-platform-ui-voyager/screens/sign_in.cr`.
  The button must sit BELOW the email + password fields. If the
  Voyager authoring already declared it that way and the iOS render
  inverted the order, the bug is in the renderer (VStack child
  ordering). If the authoring put the button first, fix the authoring.
- Re-read all four screens (`sign_in.cr`, `todos.cr`, `todo_editor.cr`,
  `settings.cr`) and verify the layout intent matches HIG expectations
  for an Apple-platform form. Use `Spacer` only where the layout
  legitimately calls for one (e.g. push a primary action to the bottom).
- After framework form defaults from item 3 land, re-author screens to
  rely on those defaults rather than ad-hoc spacing.

**Acceptance:** Sign-in screen: title at top, email field below title,
password field below email field with visible spacing, "Sign in"
button below password field. Todos screen: list fills the available
space, chart visible at the top or bottom (consistent with HIG
patterns), Settings link reachable. Editor + Settings: form fields
follow the same vertical rhythm + gutters established in item 3.

### 5. Hands-on verification gate (closes the phase)

**This is the only legitimate close criterion for Phase 6.10.** Audit
harness + XCUITest are necessary but not sufficient; owner taps must
work.

**Gate procedure (Implementer reports as PROGRESS until ALL pass):**

iOS Sim (iPhone 17, iOS 26):
1. Sign-in screen renders with no black bars, 16 pt gutters, visible
   spacing between fields.
2. Tap email field → focus ring/cursor visible, keyboard appears.
3. Type invalid email → format validation feedback appears.
4. Tap password field → focus ring/cursor visible, secure entry
   confirmed (•••• not the typed chars).
5. Tap Sign in → screen advances to Todos.
6. Todos screen renders with chart + list + Settings link.
7. Tap Settings link → Settings screen appears.
8. Tap Hide-completed toggle → toggle flips state.
9. Tap back → Todos screen re-renders with completed items filtered
   AND chart counts updated.
10. Tap a swipe row's trailing Edit button → Todo Editor opens with
    the row's data prefilled.
11. Edit + Save → Todos updates + chart updates.
12. Back without Save → no change.

macOS bin (built via `make macos`):
1. Window opens, content fills to window edges (no black bars).
2. Sign-in flow: same as iOS items 1–5 but with mouse click + macOS
   focus ring on text fields.
3. Todos → Settings → toggle → back: same state propagation.
4. Trailing buttons (not swipe — HIG correct for macOS) work for
   Edit/Delete.

If ANY step fails, the Implementer iterates and the Codex review for
that iteration must call out which step regressed.

---

## Codex per-iteration protocol

Mirror Phase 6.9 Remediation 4 cadence:

1. Implementer ships a logical chunk (one bug class or one screen).
2. Implementer invokes `codex review` on the diff with the prompt:
   "Review this iteration against `docs/initiative-cross-platform-ui/phases/phase-06.10-navigable-crud-demo/remediation-1.md`.
   Report verdict: REGRESSION / PROGRESS / PASS. Cite specific lines.
   If REGRESSION, identify which acceptance item the diff broke."
3. Save Codex output to `handoff/phase-06.10-remediation-1-codex-N.md`
   (N = iteration number).
4. If REGRESSION: Implementer reverts the iteration and tries a
   different approach. Do NOT layer more code over a regressing diff.
5. If PROGRESS: Implementer continues to the next item.
6. If PASS on all five items + Codex confirms the diff series is
   architecturally coherent: hand off to owner for hands-on gate (item 5).

---

## Deferred / out of scope (must NOT expand)

- Cascade demo modifications (preserve as-is).
- Audit-harness routing for `voyager-*` slugs (mechanical follow-up).
- SwiftUI `.swipeActions(edge:)` native facade (inline HStack buttons
  are acceptable interim per implementer report).
- Android renderer changes.
- New widgets beyond the 3 shipped in Phase 6.10 initial dispatch.
- URL routing / deep links.

---

## Verification artifacts the Implementer must produce

- `handoff/phase-06.10-remediation-1-implementer-report.md` — what
  shipped, commit range, per-item status (1-5).
- `handoff/phase-06.10-remediation-1-codex-N.md` — one per iteration.
- Updated `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift`
  confirming the AX tree exposes navigable elements (this passes
  because of item 2, but the test itself is the proof).
- `crystal spec` regression check: still 1490 examples / 4 failures
  / 0 errors baseline.
- Screenshot captures of the iOS sim + macOS bin after each major
  layout change (offscreen capture is fine; the owner hands-on test
  is the final gate).
