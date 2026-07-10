# Phase 6.10 — Remediation 2 Brief

**Date opened:** 2026-05-23
**Authored by:** Architect (Seth-approved scope)
**Branch:** `phase-06.10-navigable-crud-demo` (continue from `28073d7`)
**Codex protocol:** Per-iteration critique on EVERY iteration. No self-assessment. If Codex times out, retry up to twice; if it still times out, STOP and escalate to architect.
**Closing gate:** Owner hands-on verification on iOS Sim AND macOS bin (unchanged from Rem 1)

---

## Why this remediation exists

Rem 1 (commits up to `28073d7`) landed real framework work (VStack/HStack
default spacing, simplified VoyagerHost pattern matching Cascade) that
fixed the Sign-in screen's visual layout — but it left three items unproven
or unilaterally narrowed:

- **Item 1 (interaction)** reported PROGRESS with "verification pending
  owner hand-test." Translation: nobody verified taps actually fire.
  The owner's literal complaint ("when I click Sign in, nothing
  happens") has not been disproven.
- **Item 2 (AX tree)** narrowed by the Implementer: "XCUITest still
  cannot traverse through SwiftUI UIViewRepresentable boundary — that's
  a deeper SwiftUI issue, out of scope." Re-scoping unilaterally is
  not permitted. The brief said must-fix. Re-open.
- **Item 4 (Voyager screens)** half-done. Todos / Settings / Editor
  have HStack-with-Spacer layout collapse on iOS — Settings button
  missing, Edit/Delete buttons clipped. Same root cause class as
  the Sign-in collapse Rem 1 just fixed.

Rem 1's framework fix is preserved. Rem 2 closes the gaps.

---

## Scope — 3 items, all must close

### 1. PROVE interaction works (not "matches Cascade pattern")

**Why it's still open:** Rem 1 claims the Sign-in button's tap chain
works because it mirrors Cascade. But Cascade's buttons render in a
catalog context where they're never actually tapped through an
end-to-end navigation flow. The fact that Cascade compiles is not
proof Voyager's tap → Crystal Proc → coordinator.push → SwiftUI
@State update → re-render chain works.

**Required proof artifacts:**

- **Instrumented log proof.** Add a temporary `STDERR.puts "[voyager] sign-in button tapped"`
  (or similar through Crystal's logger) inside the Sign-in button's
  `on_tap` Proc. Boot the iOS sim, install + launch the app, drive
  a coordinate-based tap on the Sign-in button (use `xcrun simctl io`,
  `idb`, or AppleScript-driven sim interaction — pick whichever
  works), then read the sim's process log via
  `xcrun simctl spawn booted log stream --predicate 'process == "VoyagerDemo"'`
  and confirm the line appears. Capture the log snippet to
  `handoff/phase-06.10-remediation-2-interaction-proof-ios.txt`.
- **Screenshot proof of navigation.** Capture iOS sim screenshot
  before tap (Sign-in screen) and after tap (Todos screen). They
  must differ — the post-tap screenshot must show the Todos screen
  chrome, not the Sign-in screen. Save both to
  `handoff/phase-06.10-remediation-2-nav-proof-ios-{before,after}.png`.
- **Same proof on macOS.** Build the macOS bin, launch with
  `VOYAGER_ROOT_SLUG=voyager-sign-in`, drive a click on the Sign-in
  button (AppleScript via System Events, `cliclick`, or AXTest's
  press helper), confirm the same log line + screenshot delta. Save
  to `handoff/phase-06.10-remediation-2-{interaction-proof,nav-proof}-macos*`.

**Remove the temporary log statement before the final commit** but
preserve the captured log + screenshots as the proof trail.

**Stop conditions:** If the tap doesn't fire the log, do NOT keep
iterating on the layout. The interaction bug is in
`uikit_renderer.cr` / `appkit_renderer.cr` / the iOS host's
UIViewRepresentable. Audit:

- UIButton target/action: is `addTarget:action:forControlEvents:UIControlEventTouchUpInside`
  actually called on the UIButton itself? Or on a wrapping UIView?
- VoyagerHost UIViewRepresentable: is the embedded Crystal UIView
  receiving touches? Check `userInteractionEnabled` on every wrapper
  in the chain.
- CallbackRegistry: is the Crystal Proc retained when the SwiftUI
  re-render rebuilds the tree?

### 2. AX tree — full scope (reopened)

**Re-scoping note:** The Implementer declared the SwiftUI
UIViewRepresentable boundary "out of scope." It is not. The brief
required XCUITest to traverse the AX tree of the embedded Crystal
UIKit subtree. SwiftUI does NOT inherently strip UIView children
from accessibility — the UIViewRepresentable host can expose them
with the right configuration. Try:

- **`accessibilityElement(children: .contain)`** on the SwiftUI
  `VoyagerHost` view in `ContentView.swift`. This explicitly tells
  SwiftUI to include the UIView's accessibility children.
- **`accessibilityRepresentation`** modifier — alternative path.
- **On the UIView side:** set `isAccessibilityElement = NO` on the
  root UIStackView the representable returns (it likely defaults
  to NO already, but verify).

**Acceptance:** XCUITest at
`samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift`
runs the existing 4-step navigation flow and finds the labeled
buttons. The test that was failing in Rem 1 — find Sign-in by
label + tap + confirm screen advance — must now pass.

If after a genuine investigation (NOT a 30-second declaration) the
SwiftUI boundary truly cannot be made traversable, document the
specific SwiftUI/UIKit limitation with citations from Apple docs +
demonstration code that the recommended modifiers don't work in
this scenario. Then escalate to architect — do not silently defer.

### 3. Todos / Settings / Editor screen layout collapse

**Symptom (per Rem 1 implementer caveat):** "HStack-with-Spacer
layout collapse on iOS — Settings button missing, Edit/Delete buttons
clipped. macOS renders correctly."

**Root cause class:** Same as the Sign-in collapse that Rem 1 fixed.
HStack with Spacer expects parent width constraints; when none are
provided, the layout collapses to intrinsic sizes.

**Required fixes:**

- `SwipeActionRow` UIKit visit must pin row width to the parent's
  available width. Investigate whether the row's outer HStack needs
  explicit `width` constraint or `preferredMaxLayoutWidth`
  propagation.
- The Todos screen header HStack (title + Settings link) needs the
  same width-pinning.
- After framework fix lands, all four screens render correctly on
  iOS + macOS. Verify with offscreen screenshot capture.

**Acceptance:** iOS Sim screenshot of Todos screen shows: list of
todos with trailing Edit + Delete buttons visible (not clipped),
Settings button visible in the header, chart visible. macOS bin
screenshot: same layout (with click-revealed trailing buttons per
HIG, not swipe).

---

## Codex protocol (no exceptions)

Every iteration that touches code must have a Codex review committed
to `handoff/phase-06.10-remediation-2-codex-N.md`. Self-assessment is
NOT acceptable.

If Codex hits a timeout: retry. If it times out twice in a row on the
same iteration: STOP iterating, write a note to
`handoff/phase-06.10-remediation-2-codex-blocker.md` describing the
timeout pattern, and return to architect for guidance. Do NOT proceed
with uncritiqued iterations.

---

## Hands-on gate (unchanged from Rem 1)

After ALL three items pass + Codex reviews are complete, the owner
runs the 12-step iOS Sim flow + 4-step macOS flow from
`remediation-1.md` § "Hands-on verification gate". Only the owner's
green signal closes the phase.

---

## What's explicitly NOT in scope

- Cascade demo modifications.
- Audit-harness routing for `voyager-*` slugs.
- SwiftUI native `.swipeActions(edge:)` facade.
- Android renderer changes.
- URL routing / deep links.
- Adding new widgets.

---

## Reporting

Write `handoff/phase-06.10-remediation-2-implementer-report.md` covering:

- Per-item status (1-3): commit SHAs, file paths, line counts.
- Codex iteration trail.
- Proof artifacts (log snippets + screenshots) for item 1.
- The exact hand-test commands the owner should run (preserve the
  format from Rem 1's report).
- Regression numbers (`crystal spec`).

Then return to architect with: branch HEAD SHA, commit count, item
status, hand-test commands. Do NOT declare the phase passed — that's
the architect's call after the owner runs the gate.

— Architect
