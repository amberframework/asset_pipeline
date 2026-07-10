# Phase 8D.3b — 14-Row Capture Matrix Evidence

**Branch:** `phase-08d.3b-capture-matrix`
**Brief:** `docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/brief-8d.3b.md` (v2 — DISPATCH-READY)
**Captured:** 2026-05-25

## What this is

A deterministic visual-state capture of Voyager (the cross-platform sample app)
walked into each of the 14 contract states from the brief, on both iOS and
macOS, in both light and dark appearance. **56 PNGs total** (14 × 2 platforms ×
2 appearances).

The captures are produced by:

- **Crystal scenarios** in `samples/initiative-cross-platform-ui-voyager/capture_scenarios.cr`
  that mutate `Voyager::State`, `UI::NavigationCoordinator`, and
  `UI::ActionDispatcher` into the desired final visual state.
- **iOS:** XCUITest method `testCaptureMatrix` in
  `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift`.
  Loops scenarios × appearances, launches the app with `VOYAGER_CAPTURE_SCENARIO`
  + `VOYAGER_ROOT_SLUG` + `VOYAGER_APPEARANCE` via `app.launchEnvironment`,
  polls for a scenario-specific AX element, screenshots via `XCUIScreen`, writes
  to `VOYAGER_CAPTURE_EVIDENCE_DIR`.
- **macOS:** Shell loop `samples/initiative-cross-platform-ui-voyager/bin/capture_voyager_macos.sh`
  re-invokes the offscreen-capture binary with `VOYAGER_CAPTURE_SCENARIO` +
  `VOYAGER_APPEARANCE` + `HIG_APPEARANCE` + `VOYAGER_SCREENSHOT_PATH` set per
  row/appearance.

## What this is NOT

**These captures are visual state proof, not interaction proof.** Each capture
shows that Voyager renders the expected final state when its model is
positioned to that state by a scenario walk. The captures do **not** prove
that user gestures (taps, swipes, typing) produce those transitions in a
running app. Interaction proof is the deferred Phase 8 collective hand-test
gate per `[[complete-phase-arc-before-review]]`.

## Row 7 iOS caveat (gesture-only state)

The current `UI::SwipeActionRow` UIKit rendering has no force-revealed
"trailing actions exposed" setter — the revealed state is produced only by an
in-flight horizontal pan gesture. The iOS row-7 PNG therefore ships with the
row **at rest** (closed). The macOS row-7 PNG captures the natural AppKit
inline trailing buttons that the AppKit renderer materializes in-line
(`src/ui/renderers/appkit_renderer.cr:3801`), so the macOS artifact does
reflect "trailing actions visible".

## Row 14 distinct-artifact note

Row 14 ("Todos unfiltered") walks into a visual state that is identical to
row 02 ("After Sign-in → Todos"): default seeded list, no completion, no
filtering. The scenarios are nonetheless distinct contract checkpoints
(row 02 = launch path; row 14 = back-from-settings-after-untoggle) and ship
as separate artifacts so the contract matrix is one-to-one with the brief.
Visual identity of row 02 ↔ row 14 is expected, not a regression.

## 14-row mapping table

All paths are relative to repo root. iOS files live under `./ios/`; macOS files
live under `./macos/`.

| # | State to capture | iOS slug | iOS light | iOS dark | macOS light | macOS dark |
|---|---|---|---|---|---|---|
| 1 | Just-launched Sign-in screen | `voyager-sign-in` | `ios/voyager-row-01-sign-in-light.png` | `ios/voyager-row-01-sign-in-dark.png` | `macos/voyager-row-01-sign-in-light.png` | `macos/voyager-row-01-sign-in-dark.png` |
| 2 | After Sign-in → Todos (5 seeded rows) | `voyager-todos` | `ios/voyager-row-02-todos-launch-light.png` | `ios/voyager-row-02-todos-launch-dark.png` | `macos/voyager-row-02-todos-launch-light.png` | `macos/voyager-row-02-todos-launch-dark.png` |
| 3 | Editor empty (Add Todo, Save disabled) | `voyager-todo-editor` | `ios/voyager-row-03-editor-empty-light.png` | `ios/voyager-row-03-editor-empty-dark.png` | `macos/voyager-row-03-editor-empty-light.png` | `macos/voyager-row-03-editor-empty-dark.png` |
| 4 | Editor prefilled with "Rem 6.11 test" (Save enabled) | `voyager-todo-editor` | `ios/voyager-row-04-editor-prefilled-light.png` | `ios/voyager-row-04-editor-prefilled-dark.png` | `macos/voyager-row-04-editor-prefilled-light.png` | `macos/voyager-row-04-editor-prefilled-dark.png` |
| 5 | After Save — Todos with that row visible | `voyager-todos` | `ios/voyager-row-05-todos-after-save-light.png` | `ios/voyager-row-05-todos-after-save-dark.png` | `macos/voyager-row-05-todos-after-save-light.png` | `macos/voyager-row-05-todos-after-save-dark.png` |
| 6 | Row completed (strikethrough + chart shifted) | `voyager-todos` | `ios/voyager-row-06-todos-row-completed-light.png` | `ios/voyager-row-06-todos-row-completed-dark.png` | `macos/voyager-row-06-todos-row-completed-light.png` | `macos/voyager-row-06-todos-row-completed-dark.png` |
| 7 | Swipe revealed (Edit + Delete actions) — iOS ships at rest (see caveat above); macOS shows inline trailing buttons | `voyager-todos` | `ios/voyager-row-07-todos-swipe-row-light.png` | `ios/voyager-row-07-todos-swipe-row-dark.png` | `macos/voyager-row-07-todos-swipe-row-light.png` | `macos/voyager-row-07-todos-swipe-row-dark.png` |
| 8 | Editor prefilled from swipe-Edit | `voyager-todo-editor` | `ios/voyager-row-08-editor-edit-prefilled-light.png` | `ios/voyager-row-08-editor-edit-prefilled-dark.png` | `macos/voyager-row-08-editor-edit-prefilled-light.png` | `macos/voyager-row-08-editor-edit-prefilled-dark.png` |
| 9 | After Edit Save — row updated | `voyager-todos` | `ios/voyager-row-09-todos-after-edit-light.png` | `ios/voyager-row-09-todos-after-edit-dark.png` | `macos/voyager-row-09-todos-after-edit-light.png` | `macos/voyager-row-09-todos-after-edit-dark.png` |
| 10 | After Delete — row removed | `voyager-todos` | `ios/voyager-row-10-todos-after-delete-light.png` | `ios/voyager-row-10-todos-after-delete-dark.png` | `macos/voyager-row-10-todos-after-delete-light.png` | `macos/voyager-row-10-todos-after-delete-dark.png` |
| 11 | Settings default (Hide-completed off) | `voyager-settings` | `ios/voyager-row-11-settings-default-light.png` | `ios/voyager-row-11-settings-default-dark.png` | `macos/voyager-row-11-settings-default-light.png` | `macos/voyager-row-11-settings-default-dark.png` |
| 12 | Settings toggled (Hide-completed on) | `voyager-settings` | `ios/voyager-row-12-settings-toggled-light.png` | `ios/voyager-row-12-settings-toggled-dark.png` | `macos/voyager-row-12-settings-toggled-light.png` | `macos/voyager-row-12-settings-toggled-dark.png` |
| 13 | Todos filtered (back from Settings) | `voyager-todos` | `ios/voyager-row-13-todos-filtered-light.png` | `ios/voyager-row-13-todos-filtered-dark.png` | `macos/voyager-row-13-todos-filtered-light.png` | `macos/voyager-row-13-todos-filtered-dark.png` |
| 14 | Todos unfiltered (re-toggle + back) — visually identical to row 02 (see note above) | `voyager-todos` | `ios/voyager-row-14-todos-unfiltered-light.png` | `ios/voyager-row-14-todos-unfiltered-dark.png` | `macos/voyager-row-14-todos-unfiltered-light.png` | `macos/voyager-row-14-todos-unfiltered-dark.png` |

## Reproducing the captures

### macOS

```bash
samples/initiative-cross-platform-ui-voyager/bin/capture_voyager_macos.sh
```

The script builds the macOS host (`make -C samples/initiative-cross-platform-ui-voyager macos`)
then loops 14 scenarios × 2 appearances, writing 28 PNGs to
`docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/macos/`.

### iOS

```bash
cd samples/initiative-cross-platform-ui-voyager/ios
./build_crystal_lib.sh simulator
xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

VOYAGER_CAPTURE_EVIDENCE_DIR="$(pwd)/../../../docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/ios" \
  xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    test -only-testing:VoyagerDemoUITests/VoyagerVisualTests/testCaptureMatrix
```

The XCUITest method writes 28 PNGs to `VOYAGER_CAPTURE_EVIDENCE_DIR` and
asserts each is > 10KB.

## Acceptance

- 56 PNGs committed (28 iOS + 28 macOS), all > 10KB.
- iOS and macOS builds succeed.
- `crystal spec` baseline unchanged (scenarios are sample-local; no framework
  API changes).
- See `../phase-08d.3b-codex-1.md` for the per-iteration Codex review.
