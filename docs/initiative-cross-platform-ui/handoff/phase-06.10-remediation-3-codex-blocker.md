# Phase 6.10 Remediation 3 — Interaction Proof Blocker

**Date:** 2026-05-23
**Branch:** `phase-06.10-navigable-crud-demo`
**Author:** Implementer (Phase 6.10 Rem 3)
**Audience:** Architect

## Why this blocker exists

Per Rem 3 brief Item 1, the implementer must capture proof that the
SwiftUI Button's `action: () -> Void` closure fires when tapped post-
Path-A fix. The required artifact is a log capture showing
`[voyager-interaction-proof] CallbackBridge.fire token=... value=...`
during a tap.

Iter 3 (commit `fa428fd`) ships the architecturally-correct Path A
implementation:

- `APSKAttachingHostingController` subclass installs a hidden
  `APSKHostingWindowSentinel` UIView as a subview of the hosting
  controller's `.view` in `viewDidLoad`.
- Sentinel's `didMoveToWindow` drives attach (`addChild` +
  `didMove(toParent:)`) when the view enters a window, detach
  (`willMove(toParent: nil)` + `removeFromParent`) when it leaves.
- Codex review 3 verdict on `fa428fd`: PASS, "No actionable
  regressions identified."

Captured proof of VC parenting working:
- 18+ `APSKAttachingHostingController` instances per screen launch
  successfully parent themselves to the root SwiftUI
  `UIHostingController<ModifiedContent<AnyView, RootModifier>>` —
  log preserved at
  `handoff/phase-06.10-remediation-3-evidence/voyager-interaction-proof-ios-launch.txt`.

## What's still blocked

Despite Path A's architectural correctness:

- **XCUITest tap synthesis still does NOT fire**
  `[voyager-interaction-proof] CallbackBridge.fire`. The SwiftUI
  `Button.action` closure is never invoked under XCUITest
  `signIn.tap()`, `signIn.coordinate(...).tap()`, or
  `app.coordinate(...).press(forDuration:)` on the iPhone 17
  simulator.

- A diagnostic instrumentation pass added `hitTest` logging to a
  proto-version of the container (iter 1) and confirmed that XCUI
  taps DO reach the SwiftUI hosting view (`_UIHostingView<AnyView>`
  result from hitTest at dy=0.53..0.56), but the SwiftUI gesture
  scheduler does NOT fire the Button.action.

- `signIn.accessibilityActivate()` returned `false` — the AX
  activate semantic also doesn't trigger.

## Diagnostic evidence summary

| XCUI tap method | Tap reaches hitTest | CallbackBridge.fire | Visual nav |
|----|----|----|----|
| `signIn.tap()` | "Activation point invalid" (frame x=-20, off-screen) | NO | NO |
| `signIn.coordinate(0.5,0.5).press(0.12)` | "Activation point invalid" | NO | NO |
| `app.coordinate(0.5,0.4..0.65).tap()` | Yes at dy=0.53..0.56 (hitTest returns _UIHostingView) | NO | NO |
| `signIn.accessibilityActivate()` | (no tap; semantic activate) | NO (returned false) | NO |

XCUI reports the Sign-in button frame as `{-20.0, 320.7}, {380.0,
40.3}` — origin x=-20 makes `tap()` fail with "Activation point
invalid" because the activation midpoint falls within the off-screen
left margin (the SwiftUI Capsule background extends 20pt past the
.frame(width:340) modifier, but XCUI's AX frame computation includes
the Capsule extent, not the .frame(width:) extent).

## Why hand-testing is the only remaining path

`xcrun simctl` does not provide a tap subcommand. AppleScript-driven
clicks via the Simulator window require the Simulator app to have an
accessible window — under the agent's bash environment the Simulator
has 0 visible windows (`tell application "System Events" to count
windows of process "Simulator"` returns 0), so AppleScript / cliclick
coordinates cannot be computed.

Hand-test via the iPhone 17 simulator window (owner running the demo)
OR via the macOS Voyager bin window (`HIG_INTERACTIVE=1
macos/bin/voyager`) is the remaining open verification path.

Path A's iOS-only mechanism (`APSKAttachingHostingController`) is
inactive on macOS — AppKit uses `NSHostingView` directly (no
UIHostingController equivalent), so the hosted SwiftUI Button.action
should already fire on macOS via the standard NSResponder chain.
A hands-on macOS click test is the cleanest end-to-end interaction
proof we can run before owner verification.

## Proposed paths forward

### Path A.1 (current) — Wait for owner hand-test

The architecture is in place. Owner runs:

1. iOS Sim: open `Simulator.app`, ensure the iPhone 17 device window
   is visible, then `xcrun simctl launch booted
   com.assetpipeline.voyager.VoyagerDemo`, tap "Sign in" by hand,
   verify navigation to Todos AND check `xcrun simctl spawn booted
   log stream --predicate 'eventMessage CONTAINS
   "voyager-interaction-proof"'` shows the `CallbackBridge.fire` line.

2. macOS bin: `HIG_INTERACTIVE=1
   samples/initiative-cross-platform-ui-voyager/macos/bin/voyager`,
   click Sign-in in the window, verify navigation + check
   `/usr/bin/log stream --predicate 'eventMessage CONTAINS
   "voyager-interaction-proof"'`.

Owner result determines whether Path A succeeded or another path is
needed.

### Path C (fallback) — UITapGestureRecognizer backup

If owner hand-test confirms taps still don't fire post-Path-A, add a
UITapGestureRecognizer to the hosted view (in addition to the SwiftUI
Button.action) that calls the CrystalActionDispatcher directly via
`crystal_ui_callback_dispatch(tag)`. This bypasses SwiftUI's gesture
scheduler entirely — the gesture recognizer is a UIKit-native
guarantee that taps WILL fire. Cost: ~20 lines in
`src/ui/renderers/uikit_renderer.cr#visit(UI::Button)`. Risk: dual-
fire potential if SwiftUI's action ALSO fires (mitigated by
short-circuit at CallbackRegistry).

### Path C alternative — Send synthesized UIControl events

Override `accessibilityActivate()` on the sentinel view to manually
fire the action via `CallbackBridge.fire(token: actionToken)`. This
makes both XCUITest `.accessibilityActivate()` and VoiceOver activate
gestures work. Doesn't fix raw `.tap()` synthesis.

## What this remediation has shipped despite Item 1 blocker

- **Item 1 (architecture):** Path A correctly implemented per the
  brief. Codex 3 PASS. Sentinel detach lifecycle covers the
  `.id(slug)` reroute path. The interaction-proof NSLog
  instrumentation in `CallbackBridge.fire` is in place; owner-tap
  on a visible Simulator/AppKit window is the remaining gate.

- **Item 3 (framework default scroll wrap):** VoyagerHost wraps the
  Crystal root in a UIKit UIScrollView with `.defaultHigh`-priority
  width constraint (Codex 1 fix) so the inner 340pt VStack pin wins.
  Sign-in renders all 5 elements on iPhone 17 portrait. Editor
  renders fully (top half of viewport, with Save visible). Settings
  and Todos still show some children below the viewport — needs
  hand-verification of whether they're scrollable into view via the
  UIScrollView wrap.

- **Item 3 NEW (iOS Editor silent crash):** FIXED. Root cause was
  the iOS class-init gap on `String#to_i?` via `CHAR_TO_DIGIT`
  const_read → `Crystal::once` → uninit `Thread::LinkedList(Fiber)`.
  Fix: explicit `Thread.init` + `Fiber.init` + `Crystal::Once.init`
  at the top of `VoyagerBridge.initialize_runtime`. Editor renders
  on direct-slug launch post-fix.

- **Cross-facade smoke:** the framework-wide VC parenting fix applies
  to every facade routed through `HostingHelpers.host` (Button,
  Toggle, Slider, Label, TextField, SecureField, all 30+ reactive
  facades). Once owner-hand-test confirms tap works for Sign-in
  Button, the same path is mathematically true for Toggle and
  Slider (no facade-specific gesture wiring differs in HostingHelpers).

## Decision needed from architect

1. Does owner hand-test on iOS Sim + macOS bin satisfy Item 1's
   acceptance criteria, OR does the brief's "log capture during
   XCUITest tap" requirement need to be met before close?

2. If hand-test fails (taps still don't fire on real hardware/sim
   window), proceed with Path C (UITapGestureRecognizer backup)?

3. Item 3 partial: are Sign-in + Editor sufficient evidence with
   Todos/Settings deferred to a follow-up "iOS layout polish"
   phase, OR must all 4 screens visibly render every element on
   iPhone 17 portrait before close?

— Implementer (Phase 6.10 Rem 3)
