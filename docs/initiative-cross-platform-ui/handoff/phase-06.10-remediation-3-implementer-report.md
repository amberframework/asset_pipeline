# Phase 6.10 — Remediation 3 Implementer Report

**Date:** 2026-05-23
**Branch:** `phase-06.10-navigable-crud-demo`
**Commit range:** `fddb3f1` → HEAD (3 iteration commits + 1 docs commit)
**Reporter:** Implementer (Claude Opus 4.7)

## TL;DR

Per-item:

- **Item 1 (Path A — UIHostingController VC parenting):** Architecture
  shipped, Codex review 3 PASS. VC parenting verified via NSLog
  (18+ controllers attach to root SwiftUI hosting controller per screen
  launch). The architectural fix the brief specified is in place and
  symmetric across all 30+ SwiftKit facades that route through
  `HostingHelpers.host`. **Owner hand-test required for final
  interaction proof** — XCUITest tap synthesis cannot drive a tap
  that fires SwiftUI Button.action under the current iPhone 17 sim
  hosting model (frames extend off-screen by 20pt, XCUI returns
  "Activation point invalid"). Captured diagnostic chain documents
  this in `handoff/phase-06.10-remediation-3-codex-blocker.md`.

- **Item 3 (framework default UIScrollView wrap + explicit override):**
  Layer A (framework default) shipped in `VoyagerHost.makeUIView`
  via `ios/Sources/ContentView.swift`; Crystal root wrapped in a
  UIKit UIScrollView with `.defaultHigh` priority width constraint so
  the inner 340pt VStack pin always wins (Codex 1 P2 fix). Layer B
  (explicit `UI::ScrollView` in screen authoring) was attempted but
  caused a layout regression — reverted; the framework-default wrap
  is the canonical path.

- **Item 3 NEW (iOS Editor silent crash):** FIXED. Root cause: iOS
  embedding hides `_main`, so Crystal's `init_runtime` never fires;
  `String#to_i?` → `CHAR_TO_DIGIT:const_read` → `Crystal::once` → 
  uninitialised `Thread::LinkedList(Fiber)` SIGSEGV. Fix: call
  `Thread.init` + `Fiber.init` + `Crystal::Once.init` at the top of
  `VoyagerBridge.initialize_runtime` in
  `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr`. Editor
  renders fully on direct-slug launch post-fix.

Regression check: `crystal spec` baseline 1490 / 4 / 0 / 66 preserved
across all 3 iterations.

## Per-item status

### Item 1 — Path A VC parenting — ARCHITECTURE SHIPPED, INTERACTION PROOF PENDING

**What was shipped (iter 3, commit `fa428fd`):**

- New `APSKAttachingHostingController` subclass of
  `UIHostingController<AnyView>` in
  `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift`.
- Installs a hidden `APSKHostingWindowSentinel` UIView as a 0pt × 0pt
  subview in `viewDidLoad`.
- Sentinel's `didMoveToWindow` callback drives:
  - **Attach** (when window != nil): walks the responder chain from
    `view.next` up to find a parent UIViewController, calls
    `parent.addChild(self)` + `didMove(toParent: parent)`.
  - **Detach** (when window == nil): calls `willMove(toParent: nil)` +
    `removeFromParent()`.
- This is the symmetric attach/detach lifecycle Codex review 2
  insisted on after rejecting deinit + viewWillDisappear fallbacks.

**Captured proof of architecture:**

- `handoff/phase-06.10-remediation-3-interaction-proof-ios.txt`:
  18+ instances of `[voyager-interaction-proof] HostingHelpers
  parent=UIHostingController<ModifiedContent<AnyView, RootModifier>>
  controller=APSKAttachingHostingController` per Sign-in / Todos /
  Settings / Editor launch — confirming each Crystal-rendered hosting
  controller successfully registers as a child of the SwiftUI root
  scene's hosting controller.

**Open / pending architect decision** — captured in
`handoff/phase-06.10-remediation-3-codex-blocker.md`:

- XCUITest tap synthesis does NOT fire `CallbackBridge.fire` even
  though the architectural Path A is in place. XCUI's `signIn.tap()`
  fails with "Activation point invalid" (Sign-in button frame
  `{-20, 320.7, 380, 40.3}` extends past the screen origin); `app.coordinate(...).tap()` reaches the SwiftUI hosting view via
  `hitTest` but the SwiftUI Button.action never fires.
- Hand-test verification via a visible Simulator window (owner) is the
  remaining open path. The macOS bin uses NSHostingView directly (no
  UIHostingController equivalent), so the AppKit equivalent should
  already work via the standard NSResponder chain — hand-click on the
  macOS bin is the cleanest end-to-end interaction proof we can run.

### Item 3 — Framework default UIScrollView + screen authoring — PARTIAL

**Layer A (framework default) — SHIPPED:**

- `samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift`
  `VoyagerHost.makeUIView` wraps the Crystal-rendered root in a UIKit
  `UIScrollView` when the rendered root isn't already a UIScrollView.
- Pin uses `.defaultHigh` priority (Codex 1 P2 fix) so the inner
  340pt `min_w == max_w` constraint always wins. Prior version
  pinned at required priority, creating an Auto Layout conflict that
  caused random child-collapse on iPhone 17 portrait.
- The wrap preserves the Item 2 (Rem 2) AX-traversal win — UIKit
  UIScrollView is fully AX-traversable, unlike SwiftUI ScrollView
  which collapsed the subtree.

**Layer B (explicit UI::ScrollView screen wrap) — REVERTED:**

- Initial wrap of Todos / Settings / Editor root VStacks in a
  `UI::ScrollView` triggered a layout regression where root-VStack
  children (Settings back button; Todos list / Settings link / Add
  Todo; Editor Cancel button) collapsed to invisible. Root cause was
  the same constraint conflict Codex flagged later; with Layer A's
  `.defaultHigh` fix in place, Layer B is redundant on iPhone 17
  portrait — the framework default handles the same overflow case.
  Reverted to keep the explicit-override path available without
  shipping a known regression.

**iPhone 17 capture status:**

- Sign-in: ALL 5 elements (Voyager wordmark, subtitle, Email
  TextField, Password SecureField, Sign-in button) render correctly
  on first frame. See
  `handoff/phase-06.10-remediation-3-evidence/voyager-ios-signin-rendered.png`.
- Editor: title + Title field + Note field + Completed toggle + Save
  button render. Cancel button rendered but appears partially clipped
  on the left edge (positioning issue in the actions HStack — outside
  Rem 3 scope, pre-existing layout). See
  `voyager-ios-editor-direct-launch.png`.
- Todos: title + Open/Done chart row render. List + Settings link +
  Add Todo button are positioned BELOW the visible viewport — should
  be scrollable via the UIScrollView wrap. See
  `voyager-ios-todos-direct-launch.png`.
- Settings: title + explainer + Hide-completed toggle render. Back-
  to-todos button positioned below the visible viewport — should be
  scrollable via the UIScrollView wrap. See
  `voyager-ios-settings-direct-launch.png`.

The brief's acceptance allows "visible OR scrollable into view" —
Todos/Settings/Editor below-the-fold elements need owner hand-
verification that the UIScrollView wrap actually exposes them via
swipe-up gesture (XCUI synthesis cannot reliably drive
`press(forDuration:thenDragTo:)` gestures in this agent environment).

### Item 3 NEW — iOS Editor silent crash — FIXED

**Diagnosis (captured in iter 1 commit message + crash report at
`~/Library/Logs/DiagnosticReports/VoyagerDemo-2026-05-23-155642.ips`):**

The Editor route's `Voyager.build_route` calls
`(route.params[:id]? || "0").to_i?` which lazily loads
`String::CHAR_TO_DIGIT` via `Crystal::once`. Under iOS embedding
`_main` is hidden via `ld -r -unexported_symbol _main`, so Crystal's
upstream `init_runtime` (which calls `Thread.init` + `Fiber.init` +
`Crystal::Once.init`) never fires. Result: `Crystal::once` walks an
uninitialised `Thread::LinkedList(Fiber)` and SIGSEGVs at
`Thread::LinkedList(Fiber)#push` (KERN_INVALID_ADDRESS at 0x18).

Crash trace from the .ips:

```
VoyagerHost.makeUIView (ContentView.swift:125) ->
VoyagerBridge.render(slug:) -> voyager_render ->
VoyagerBridge::render_slug -> Voyager::build_route ->
String#to_i? -> CHAR_TO_DIGIT:const_read -> Crystal::once ->
Crystal::System::Thread::current_thread -> Thread::new ->
Thread::LinkedList(Fiber)#push -> CRASH
```

**Fix (iter 1, commit `5c13aee`):**

In `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr`,
the `VoyagerBridge.initialize_runtime` method now explicitly calls:

```crystal
Thread.init
Fiber.init
Crystal::Once.init
```

right after `GC.init`. This mirrors what
`src/crystal/main.cr#init_runtime` does in normal Crystal programs.
The comment block in bridge.cr documents the iOS class-init gap and
references the project memory item
`project_crystal_ios_class_init_gap`.

**Acceptance verified:**

- `SIMCTL_CHILD_VOYAGER_ROOT_SLUG=voyager-todo-editor xcrun simctl
  launch booted com.assetpipeline.voyager.VoyagerDemo` now launches
  the Editor screen successfully (screenshot at
  `voyager-ios-editor-direct-launch.png`). No crash, no .ips file
  generated post-fix.
- Sign-in launch unaffected; navigation flow Sign-in → Todos →
  Settings → Editor would presumably work end-to-end once Item 1's
  interaction proof closes.

## Iteration / Codex trail

| Iter | SHA       | Codex verdict | Notes |
|------|-----------|---------------|-------|
| 1    | `5c13aee` | NEEDS_WORK (2 × P2) | Path A + Editor fix + UIScrollView wrap shipped. Codex flagged required-priority width constraint conflict + deinit-based detach lifecycle. |
| 2    | `56d971f` | NEEDS_WORK (1 × P2) | Constraint priority fixed to .defaultHigh; tried viewWillDisappear + deinit fallback. Codex flagged retained-children paradox: deinit cannot run while controller is parented. |
| 3    | `fa428fd` | PASS | Sentinel-driven didMoveToWindow attach/detach. Codex: "No actionable regressions identified." |

Codex reviews preserved at:
- `handoff/phase-06.10-remediation-3-codex-1.md`
- `handoff/phase-06.10-remediation-3-codex-2.md`
- `handoff/phase-06.10-remediation-3-codex-3.md`
- `handoff/phase-06.10-remediation-3-codex-blocker.md` — Item 1
  interaction proof escalation to architect.

## Regression check

```
$ crystal spec
1490 examples, 4 failures, 0 errors, 66 pending
```

Pre-existing 4 failures unrelated to Rem 3:
- `spec/ui/views_spec.cr:3279`
- `spec/components/phase2_verification_spec.cr:52`
- `spec/components/phase2_verification_spec.cr:116`
- `spec/components/phase2_verification_spec.cr:129`

## Build artifacts

- `samples/initiative-cross-platform-ui-voyager/macos/bin/voyager` —
  built 2026-05-23 17:13, runs offscreen + interactive.
- `~/Library/Developer/Xcode/DerivedData/VoyagerDemo-*/Build/Products/Debug-iphonesimulator/VoyagerDemo.app` — 
  built 2026-05-23 17:13, installed on iPhone 17 sim.

## Files touched (Rem 3 commit range)

```
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift
  — VoyagerHost UIScrollView wrap with .defaultHigh-priority width constraint.
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift
  — Updated navigation flow to sweep coordinate taps + log frame for diagnosis.
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr
  — Thread.init + Fiber.init + Crystal::Once.init in initialize_runtime
    (iOS class-init gap workaround).
samples/initiative-cross-platform-ui-voyager/screens/{todos,settings,todo_editor}.cr
  — Reverted Layer B UI::ScrollView wrap; comments explain why.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift
  — New APSKAttachingHostingController subclass + APSKHostingWindowSentinel
    + Path A VC parenting via sentinel didMoveToWindow.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift
  — Migrated NSLog from variadic to string-interpolation (iOS SDK 26
    deprecated variadic NSLog).
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-3-*.md
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-3-evidence/
  — Codex reviews, blocker, proof artifacts, this report.
```

## Proof artifact paths (brief's canonical names)

- `handoff/phase-06.10-remediation-3-interaction-proof-ios.txt` —
  iOS log capture showing 18+ VC parenting events on launch.
- `handoff/phase-06.10-remediation-3-interaction-proof-macos.txt` —
  macOS offscreen render trace (interaction-proof NSLog requires
  hand-click on a visible NSWindow; agent environment cannot drive
  this).
- `handoff/phase-06.10-remediation-3-nav-proof-ios-{before,after}.png` —
  Sign-in screen + Editor screen post-fix (proxy for navigation
  proof; XCUI tap doesn't drive nav per blocker doc).
- `handoff/phase-06.10-remediation-3-nav-proof-macos-{before,after}.png` —
  macOS Sign-in + Todos offscreen captures.
- `handoff/phase-06.10-remediation-3-evidence/voyager-{ios,macos}-*.png` —
  all 4 screens captured per platform.

## Hand-test commands

### iOS Sim hands-on (interaction proof gate)

```bash
# Boot + open Simulator window
xcrun simctl boot 'iPhone 17' 2>/dev/null || true
open -a Simulator
# (Ensure the iPhone 17 device window is visible in the Simulator app)

# Install + launch
make -C /Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager ios
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/VoyagerDemo-*/Build/Products/Debug-iphonesimulator/VoyagerDemo.app
xcrun simctl launch booted com.assetpipeline.voyager.VoyagerDemo

# In another shell — start the interaction proof log capture:
xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "voyager-interaction-proof"'

# Tap Sign-in by hand. Expected:
# - The log stream shows `[voyager-interaction-proof] HostingHelpers
#   parent=...` lines on launch (VC parenting working).
# - When you tap Sign-in, the log should ALSO show
#   `[voyager-interaction-proof] CallbackBridge.fire token=... value=...`
#   — that's the Item 1 acceptance signal.
# - The screen should navigate to Todos.

# Repeat for Settings, Editor, Settings hide-toggle to confirm
# Toggle facade also fires (cross-facade smoke).

# After confirming, remove the temporary NSLog markers per the brief.
```

### macOS bin hands-on

```bash
# Build
make -C /Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager macos

# Run interactively
HIG_INTERACTIVE=1 /Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/macos/bin/voyager

# In another shell:
/usr/bin/log stream --predicate 'eventMessage CONTAINS "voyager-interaction-proof"'

# Click Sign-in. Expected: CallbackBridge.fire line + window navigates.
# AppKit uses NSHostingView (not UIHostingController) so Path A's
# iOS-only sentinel mechanism is inactive — macOS should already work
# via the standard NSResponder chain.
```

## Risks + known limitations

1. **Item 1 interaction proof requires owner hand-test** (XCUITest tap
   synthesis cannot drive a SwiftUI Button.action under
   UIHostingController on iPhone 17 sim). Architecture is in place;
   architect needs to decide whether hand-test satisfies the brief's
   "log capture during tap" requirement, OR if Path C
   (UITapGestureRecognizer backup) needs to ship in a follow-up
   iteration.

2. **Item 3 partial:** Sign-in renders all elements; Editor renders
   most elements; Todos/Settings render top half. The below-the-fold
   elements should be scrollable via the UIScrollView wrap but agent
   environment can't reliably drive swipe gestures — owner hand-
   verification needed.

3. **Diagnostic NSLog still in tree.** The architect's brief said
   "Remove temporary NSLog after capture; keep artifacts." Since
   Item 1's interaction-proof gate is still open (waiting on owner
   hand-test), I kept the NSLogs in `CallbackBridge.fire` and
   `APSKAttachingHostingController.attachIfNeeded` so the owner's
   hand-tap can capture the proof line. They are grep-able by
   `voyager-interaction-proof` and clearly commented as TEMP; removal
   is the first action of whoever closes Item 1.

## What the architect needs to decide

1. **Path A acceptance:** Does owner hand-test on iOS Sim + macOS bin
   satisfy Item 1's acceptance, OR is XCUITest-driven `CallbackBridge.fire`
   capture a hard requirement?

2. **If hand-test confirms taps still don't fire**, dispatch Path C
   (UITapGestureRecognizer backup) as Rem 4?

3. **Item 3 partial:** are Sign-in (full) + Editor (mostly visible)
   sufficient evidence with Todos/Settings deferred to a follow-up
   "iOS layout polish" phase, OR must all 4 screens visibly render
   every element on iPhone 17 portrait before Phase 6.10 closes?

— Implementer (Phase 6.10 Rem 3)
