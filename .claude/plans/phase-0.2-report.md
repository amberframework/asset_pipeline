# Phase 0.2 Report -- iOS Live Simulator Capture Path

**Date:** 2026-04-14
**Iteration:** 61 (Phase 0.2)

## What changed

### `samples/cross_platform/ios_host/Sources/ContentView.swift`

Removed the `.background(Color(UIColor.systemBackground))` SwiftUI modifier from `ContentView`. That modifier was the iOS equivalent of the macOS `cacheDisplayInRect:` problem: it gave UIVisualEffectView a solid opaque parent, so the blur kernel had no content to composite against and collapsed to the material's nominal flat color.

Added `HIGBackdropController` -- a static enum with an `install(in:)` method. It reads `HIG_BACKDROP_PATH` from `ProcessInfo.processInfo.environment`:
- If set and the image loads: installs a `UIImageView` pinned to the full root view bounds at index 0 of the root view controller's view, with `contentMode = .scaleAspectFill`.
- If unset or image fails: installs a `CAGradientLayer` fallback using the Amber palette (cream `#FAF6F0` to cosmic navy `#141122`, direction flipped in dark mode).

### `samples/cross_platform/ios_host/Sources/CrystalHIGHostApp.swift`

`HIGSceneDelegate.applyAppearance(to:)` now performs two deferred dispatches:
1. At +0.05s: set `w.overrideUserInterfaceStyle` AND `w.backgroundColor = .clear`. The clear window background is the key enabler -- without it, UIKit's default opaque white/black window background sits below the blur kernel's sampling region, collapsing glass.
2. At +0.10s (another +0.05s after step 1): call `HIGBackdropController.install(in:)`. The second dispatch ensures `rootViewController.view` is fully laid out before the backdrop subview is inserted at index 0.

Removed `.preferredColorScheme` from `CrystalHIGHostApp.body` -- appearance is now controlled exclusively via `overrideUserInterfaceStyle` on the window (the authoritative knob for UIVisualEffectView material resolution) rather than the SwiftUI environment trait.

### `samples/cross_platform/ios_host/UITests/HIGVisualTests.swift`

Forwarding: reads `HIG_BACKDROP_PATH` from the test-process environment (xcodebuild strips `TEST_RUNNER_` prefix) and injects it into `app.launchEnvironment["HIG_BACKDROP_PATH"]`.

Settling delay increased: 0.8s -> 1.2s. UIVisualEffectView blur is processed by `backboardd` (render server, out-of-process). It needs at least one off-screen compositing pass after layout before the XCUIScreen framebuffer read reflects the blurred material. 0.8s was marginal on the iPhone 17 Pro simulator; 1.2s was verified sufficient.

The `XCUIScreen.main.screenshot()` call is already the out-of-process framebuffer path -- no change needed. This is the correct path and it was already in place. The fix was entirely on the app side (backdrop + clear window background).

### `scripts/run_ios_hig_tests.sh`

Added `BACKDROP_ENV` variable: if `HIG_BACKDROP_PATH` is set in the invoking shell, prepends `TEST_RUNNER_HIG_BACKDROP_PATH=$HIG_BACKDROP_PATH` to the xcodebuild invocation. xcodebuild's `TEST_RUNNER_` stripping mechanism then exposes it as `HIG_BACKDROP_PATH` in the test process.

## What was verified

Two fresh captures for slug `sheets` on iPhone 17 Pro simulator (iOS 26.4):

- `validation/screenshots/sheets-ios-light-DEMO.png` -- 1.0MB, frosted light-gray UIVisualEffectView material with Amber cream gradient visibly blurred beneath.
- `validation/screenshots/sheets-ios-dark-DEMO.png` -- 1.0MB, dark-frosted UIVisualEffectView material with Amber cosmic-navy gradient visibly blurred beneath.

Both captures show the backdrop gradient bleeding through the sheet surface. The blur kernel is running against real image content, not a solid fill. The `UIGraphicsImageRenderer` in-process rasterization path that would flatten glass is not used.

Crystal lib build: succeeded (same as Phase 0.1 toolchain, no changes to `build_crystal_lib.sh`).
Swift compilation: succeeded with no errors or warnings on the three modified Swift files.
Test run: `** TEST SUCCEEDED **` for both light and dark appearances.

## Gotchas

**`window.backgroundColor = .clear` is load-bearing.** UIKit windows default to opaque. Without clearing the window background, even with a UIImageView inserted at index 0 of the root view, the UIVisualEffectView blur kernel samples the window's background color (white in light mode, black in dark) rather than the image content. This is the same fundamental issue as the macOS backdrop window needing to be at a lower z-order than the capture window -- the compositor must have non-opaque content visible beneath the blur surface.

**Two-step deferred dispatch timing.** A single `asyncAfter(0.05s)` that both sets `backgroundColor = .clear` AND calls `HIGBackdropController.install(in:)` races with UIKit's window attachment. The root view controller's view is not guaranteed to be in the hierarchy at +0.05s from `willConnectTo`. The second +0.05s pass gives UIKit one more runloop cycle to complete the scene connection.

**xcodebuild `TEST_RUNNER_` prefix stripping.** xcodebuild strips the `TEST_RUNNER_` prefix from env vars before passing them to the test process, NOT to the app-under-test. The test process must explicitly forward variables to `app.launchEnvironment` for the app to read them. This is why the chain is: invoker shell -> `TEST_RUNNER_HIG_BACKDROP_PATH` -> xcodebuild -> test process reads `HIG_BACKDROP_PATH` -> `app.launchEnvironment["HIG_BACKDROP_PATH"]` -> app reads `HIG_BACKDROP_PATH`.

**Settling at 1.2s on iPhone 17 Pro simulator.** The simulator's `backboardd` is slower than device. On a physical iPhone 17 Pro the 0.8s delay was likely sufficient; on the simulator, the render server needs the extra time. If a future slug shows the material not yet blurred in captures, increase to 1.5s.

## Next iterations

- Iter 0.3: Backdrop library (6 initial backdrops), per-slug selection in worklist.json, `triage.py` + `build_index.py` updates. USER REVIEW GATE: approve backdrops before Phase 2.
