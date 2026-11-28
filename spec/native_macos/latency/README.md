# Tap-latency lane (macOS)

`make test-latency-macos` checks that a tap on an asset_pipeline native
control feels native: the pressed look is committed within 16 ms of the click
reaching the app, and the main thread never runs a pass longer than 16 ms. It
prints the measurements table, then the gate table, and exits nonzero when a
gate is crossed.

It needs a Mac with a logged-in GUI session (AppKit opens a real window).

## Files

| File | What it is |
|---|---|
| `tap_latency_probe.cr` | The probe app: renders a `UI::Button`, a label and N rows of (Label, Button, Toggle) through `UI::AppKit::Renderer`, rebuilding the whole tree on each tap the way the sample hosts do. |
| `tap_latency_probe_helper.m` | Records every timestamp on one monotonic clock: run-loop pass start and end (ordered after Core Animation's commit), display-link ticks, synthetic mouse-down and mouse-up (posted from a background thread at fixed times with 0 to 17 ms of jitter) and their dispatch, pressed pixels. |
| `tap_latency_analysis.rb` | Derives per-tap latencies, stalls over 16 ms split by cause (collection, render, synchronous action work, other), collection pauses and dropped frames. |
| `run_tap_latency_lane.rb` | Runs each row of `thresholds.yml` once under a deadline (a hung probe is sampled, then killed), prints both tables and applies the gates. |
| `thresholds.yml` | The gates, the per-row probe settings, the known-failure marks and the regression tolerances. |
| `baseline.json` | Today's values on the reference mini, with the machine, compiler and date. |
| `baseline-github-macos-26.json` | The same, recorded on GitHub's hosted `macos-26` runner, used by CI. |

## Rows

| Row | Probe |
|---|---|
| `press` | handler does nothing, 40-row screen, 100 taps every 300 ms |
| `rerender` | each tap rebuilds the 40-row screen, 30 taps every 600 ms |
| `rerender_rapid` | the same, 40 taps every 300 ms: each press lands while the previous rebuild may still hold the main thread |
| `slow` | the action makes a 1 s blocking call on the main thread, then rebuilds, 8 taps every 2 s |
| `gc` | no rebuild; 230 MB retained and a background thread allocating, 100 taps every 300 ms |

## What "pressed within 16 ms" measures

As in PLAN phase 1, the pressed time runs from the click reaching the app (the
`NSEvent` local monitor, just before AppKit dispatches it) to the end of the
main-thread pass that handled it, when Core Animation commits the pressed
look. The wait before the click reaches the app is printed in its own column
("Click waits for the app"): it includes a harness floor of 1 to 18 ms on an
idle main thread, and it grows when the main thread is busy, which the stall
gates catch.

The busy row taps every 300 ms. A 200 ms interval was tried and dropped from
the gate: with a 230 ms rebuild per tap the app falls further behind on every
tap, and two runs differed threefold (pressed p50 187 ms and 987 ms).

## Gates and known failures

Every row has four gates: `pressed_within_16ms_percent >= 100`,
`stall_count <= 0`, `stall_p95_ms <= 16` and `collection_pause_p95_ms <= 16`. Today's code crosses most of
them (the full rebuild, the synchronous action, stop-the-world collection), so
those gates are listed under the row's `known_failures`. A known failure keeps
the lane green while the measured value is no worse than the row's baseline
plus the tolerance in `thresholds.yml`; past that, the lane turns red and
names the gate. A gate that is not a known failure turns the lane red as soon
as it is crossed. When a known failure starts passing, the lane prints a
notice; remove the mark in the same change that fixed it.

## Commands

```
make test-latency-macos                 # gate against baseline.json
make record-latency-baseline-macos      # rewrite baseline.json from a fresh run
make test-latency-macos LATENCY_BASELINE=spec/native_macos/latency/baseline-github-macos-26.json
/usr/bin/ruby spec/native_macos/latency/tap_latency_analysis.rb build/latency-macos/runs/<stamp>/<row>
```

Each run writes `rows.txt`, `summary.json`, `taps.json`, `stalls.json` and
`stderr.txt` per row, plus `lane_summary.json` and `candidate_baseline.json`,
under `build/latency-macos/runs/<stamp>/`.

## iOS Simulator and Android emulator lanes

`make test-latency-ios` and `make test-latency-android` are placeholders that
exit 2. What each lane needs:

- **iOS Simulator** (UIKit renderer, the same click plan). The probe has to
  run inside a simulator app: cross-compile the probe as a static library the
  way `samples/initiative-cross-platform-ui-demo/ios/build_crystal_lib.sh`
  builds `libcascade.a` (`--cross-compile --target arm64-apple-ios-simulator`),
  with Boehm cross-built for the simulator SDK (the single-binary
  `crystal-alpha spec -Dios` path links the macOS `libgc` and fails), and a
  SwiftKit simulator slice. Port the helper's recording to UIKit:
  `CFRunLoopObserver` on the main run loop is unchanged, `CADisplayLink`
  replaces the `NSWindow` display link, and the touch-down and touch-up
  arrival marks come from a `UIWindow` `sendEvent:` override instead of an
  `NSEvent` local monitor. Drive the click plan from an XCUITest
  (`XCUICoordinate.press(forDuration:)` for down, hold and up at fixed
  times); `xcrun simctl io` records the screen but posts no touches, so
  XCUITest is the driver.
  The app dumps `rows.txt` into its container; the lane copies it out with
  `xcrun simctl get_app_container` and reuses `tap_latency_analysis.rb`
  unchanged (the row kinds are the same).
- **Android emulator** (`adb shell input tap`, `dumpsys gfxinfo`). Blocked on
  a Linux-targeted Crystal for Android (`-Dandroid` fails on
  `c/sys/epoll` with the host stdlib) plus the NDK toolchain. Once a probe APK
  builds: reset frame stats with `adb shell dumpsys gfxinfo <package> reset`,
  post the click plan with `adb shell input motionevent DOWN|UP x y` at fixed
  times (`input tap` cannot hold 80 ms), have the host log touch arrival and
  `Choreographer` frame callbacks to logcat with `SystemClock.uptimeNanos`, and
  read per-frame timings from `dumpsys gfxinfo <package> framestats` for the
  stall and dropped-frame columns.
