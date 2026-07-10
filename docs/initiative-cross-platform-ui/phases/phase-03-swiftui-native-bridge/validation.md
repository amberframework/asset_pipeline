
# Phase 3 — Validator Rubric: SwiftUI Native Bridge

**Audience:** the validator agent spawned after the implementer's handoff.
**Read first:** `README.md` (this folder), then `../../rubric/validation_criteria.md`, then `../../rubric/gate_report_schema.md`.
**Branch under verification:** `phase-03-swiftui-native-bridge` (the phase branch the Architect created before dispatch) at the implementer's commit head.
**Output:** a single `GATE_REPORT.json` matching `rubric/gate_report_schema.md`. Verdict is PASS iff every `required: true` check has `passed: true`.

---

## Validator scope reminder

You are a cold-eyed reviewer. You read code, run builds, inspect rendered output and snapshot diffs, and record findings. You do not modify code, tests, configuration, or documentation, except for narrowly scoped temporary edits required by a check (which you revert and document, per `validation_criteria.md` §Temporary edits for verification).

This is the highest-risk phase. Be especially rigorous on:

1. The "nil-when-default" propagation invariant (does the Crystal renderer correctly leave overrides nil when the author has not set a property?).
2. The visual fidelity invariant (does an unstyled `UI::Button` look like a SwiftUI Button on both iOS and macOS, including iOS 26+ Liquid Glass on glass surfaces?).
3. The composition invariant (do Tier 2 widgets render identically as TabView children vs standalone?).
4. The build invariant (do iOS and macOS samples link the Swift companion cleanly across simulator-arm64, device-arm64, and macOS-arm64 slices?).

---

## Pre-reading checklist

Before running checks, read:

- [ ] This file (top to bottom; pick up the check IDs you'll be reporting).
- [ ] `README.md` (this folder) — architecture and acceptance summary.
- [ ] `../../rubric/validation_criteria.md` — universal validator standards.
- [ ] `../../rubric/gate_report_schema.md` — the JSON shape you'll be producing.
- [ ] `../../rubric/behavior-simulation-toolkit.md` — concrete how-to for every Group BX action (button taps, toggle/slider value drives, runtime-override mutation, sheet dismiss + focus restoration, AX-tree walks). Group BX assumes you have read this.
- [ ] The implementer's handoff message (the team lead forwards it; if you cannot find one, request it before running checks).

Do **not** read `implementation.md` cover to cover. Skim it once for orientation, then return to it only when a check explicitly references it. Forming your expectations from the README + this rubric (not the implementer's brief) keeps your judgment independent.

---

## Evidence directory

Create at the start of the run:

```
handoff/phase-03-evidence-{YYYY-MM-DD}/
  README.md
  test_output/
  screenshots/
  inspections/
  build_logs/
```

Every check below specifies what to capture and where to put it.

---

## Checks

Checks are organized into four groups: **Build (B)**, **Inspection (I)**, **Visual (V)**, and **Spec (S)**. The order is the order they appear in your `GATE_REPORT.json#checks` array.

### Group B — Build verification

#### B1. `swiftkit.build-ios-simulator`
- **required:** true
- **Verify:** the Swift companion builds for iOS arm64 simulator.
- **How:**
  ```
  cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit
  swift build -c release \
    --triple arm64-apple-ios16.0-simulator \
    --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" 2>&1 \
    | tee ../../handoff/phase-03-evidence-DATE/build_logs/B1.log
  ```
- **Pass:** exit 0, and `.build/arm64-apple-ios16.0-simulator/release/libAssetPipelineSwiftKit.a` exists and is non-empty.
- **Evidence:** `build_logs/B1.log` plus `ls -la .build/.../libAssetPipelineSwiftKit.a` output captured.

#### B2. `swiftkit.build-ios-device`
- **required:** true
- **Verify:** Swift companion builds for iOS arm64 device slice.
- **How:** `swift build -c release --triple arm64-apple-ios16.0 --sdk "$(xcrun --sdk iphoneos --show-sdk-path)"`.
- **Pass:** exit 0, `.build/arm64-apple-ios16.0/release/libAssetPipelineSwiftKit.a` exists.
- **Evidence:** `build_logs/B2.log`.

#### B3. `swiftkit.build-macos`
- **required:** true
- **Verify:** Swift companion builds for macOS arm64.
- **How:** `swift build -c release --triple arm64-apple-macosx13.0 --sdk "$(xcrun --sdk macosx --show-sdk-path)"`.
- **Pass:** exit 0, `.build/arm64-apple-macosx13.0/release/libAssetPipelineSwiftKit.a` exists.
- **Evidence:** `build_logs/B3.log`.

#### B4. `sample.ios-builds-clean`
- **required:** true
- **Verify:** the iOS sample build script completes end-to-end with the Swift companion linked.
- **How:**
  ```
  cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline
  ./samples/cross_platform/ios_host/build_crystal_lib.sh simulator 2>&1 \
    | tee handoff/phase-03-evidence-DATE/build_logs/B4.log
  ```
- **Pass:** exit 0; the produced `libhighost.a` exists; the build log contains a line confirming `AssetPipelineSwiftKit built: ...libAssetPipelineSwiftKit.a`. Verify with `grep "AssetPipelineSwiftKit built" build_logs/B4.log`.
- **Evidence:** `build_logs/B4.log`, plus output of `nm samples/cross_platform/ios_host/build/libhighost.a 2>&1 | grep -E "APSKButtonFacade|APSKRuntime" | head -20` written to `inspections/B4-symbols.log`.

#### B5. `sample.macos-builds-clean`
- **required:** true
- **Verify:** the macOS sample builds with the Swift companion linked.
- **How:** `cd samples/cross_platform/macos_host && make build 2>&1 | tee ../../../handoff/phase-03-evidence-DATE/build_logs/B5.log`.
- **Pass:** exit 0; `bin/hig_showcase` exists; `otool -L bin/hig_showcase | grep -E "SwiftUI|Combine"` shows SwiftUI is linked.
- **Evidence:** `build_logs/B5.log`, `inspections/B5-otool.log`.

#### B6. `crystal.spec-suite-green`
- **required:** true
- **Verify:** the full Crystal spec suite passes.
- **How:** `cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline && crystal spec 2>&1 | tee handoff/phase-03-evidence-DATE/test_output/B6.log`.
- **Pass:** `Finished in ...` line shows `0 errors, 0 failures`. Pending tests are noted in `notes` but do not fail the check.
- **Evidence:** `test_output/B6.log`.

#### B7. `swift.test-suite-green`
- **required:** true
- **Verify:** the Swift companion's test suite passes (unit + overrides propagation + snapshot tests).
- **How:** `cd swift/AssetPipelineSwiftKit && swift test 2>&1 | tee ../../handoff/phase-03-evidence-DATE/test_output/B7.log`.
- **Pass:** all tests pass; zero `XCTFail` outputs.
- **Evidence:** `test_output/B7.log`.

#### B8. `crystal.web-build-clean`
- **required:** true
- **Verify:** the default web build still compiles (the renderer refactor must not break web).
- **How:** `crystal build --no-codegen src/asset_pipeline.cr 2>&1 | tee handoff/phase-03-evidence-DATE/build_logs/B8.log`.
- **Pass:** exit 0, no warnings referencing files under `src/ui/renderers/`.
- **Evidence:** `build_logs/B8.log`.

#### B9. `crystal.android-build-clean`
- **required:** true
- **Verify:** Android renderer still compiles (the SwiftKit changes must not have leaked into the Android path).
- **How:** `crystal build --no-codegen samples/cross_platform/android_host/<host>.cr -Dandroid 2>&1 | tee handoff/phase-03-evidence-DATE/build_logs/B9.log` (use whichever sample-android host file exists; if none exists, fall back to `crystal build --no-codegen src/asset_pipeline.cr -Dandroid`).
- **Pass:** exit 0.
- **Evidence:** `build_logs/B9.log`.

---

### Group I — Code inspection

#### I1. `bridge.no-raw-uikit-for-migrated-widgets`
- **required:** true
- **Verify:** every visit method in `src/ui/renderers/uikit_renderer.cr` for a widget listed in `implementation.md` §6 no longer constructs a raw `UIButton` / `UISwitch` / `UIStackView` / `UISlider` / `UIStepper` / `UISegmentedControl` / `UITextField` / `UIDatePicker` / `UIProgressView` / `UIActivityIndicatorView` / `UITabBarController` / `UINavigationController` etc. Instead, it calls `LibObjCBridge.objc_getClass("APSK...Facade")` and invokes the facade.
- **How:** For each widget in §6 of `implementation.md` (Button through Card), find the line range of its `visit` method (the index at the top of the section gives starting line numbers; the method ends at the next `def visit`). Within that range, run:
  ```
  grep -nE 'objc_getClass\("UI(Button|Switch|StackView|Slider|Stepper|SegmentedControl|TextField|DatePicker|ProgressView|ActivityIndicatorView|TabBarController|NavigationController)"' src/ui/renderers/uikit_renderer.cr
  ```
- **Pass:** zero matches inside any migrated widget's `visit` range. Matches inside non-migrated widgets (Alert, TokenField, Grid, TextArea, etc.) are allowed. Save each widget's `visit` range scan as `inspections/I1-<widget>.log`.
- **Evidence:** one file per widget in `inspections/`.

#### I2. `bridge.no-raw-appkit-for-migrated-widgets`
- **required:** true
- **Verify:** same as I1 for `src/ui/renderers/appkit_renderer.cr`, scanning for `NSButton`, `NSPopUpButton`, `NSStackView`, `NSSlider`, `NSStepper`, `NSSegmentedControl`, `NSTextField`, `NSDatePicker`, `NSProgressIndicator`, `NSSplitViewController`, `NSTabViewController`.
- **How:** equivalent grep across the same widget ranges in `appkit_renderer.cr`.
- **Pass:** zero matches in migrated widget `visit` ranges.
- **Evidence:** one file per widget in `inspections/`.

#### I3. `bridge.facades-called-for-each-widget`
- **required:** true
- **Verify:** for every widget in §6, there is exactly one `objc_getClass("APSK<Widget>Facade")` call in **each** of the two renderer files.
- **How:** for each widget name in §6, run `grep -nE 'objc_getClass\("APSK<Widget>Facade"\)' src/ui/renderers/uikit_renderer.cr` and `... appkit_renderer.cr`.
- **Pass:** exactly one match per widget per renderer (or two if the widget has a documented secondary call path; the implementer's handoff must mention it).
- **Evidence:** `inspections/I3-facade-call-matrix.log` — a CSV of widget × renderer × match-count.

#### I4. `bridge.objc-msg-send-conventions`
- **required:** true
- **Verify:** the new ObjC bridge function `objc_send_ulong_ret_id` (added in implementation step 1) is present in both `src/ui/native/objc_bridge.m` and the `lib LibObjCBridge` block in both renderer files.
- **How:**
  ```
  grep -n "objc_send_ulong_ret_id" src/ui/native/objc_bridge.m
  grep -n "objc_send_ulong_ret_id" src/ui/renderers/uikit_renderer.cr
  grep -n "objc_send_ulong_ret_id" src/ui/renderers/appkit_renderer.cr
  ```
- **Pass:** at least one match in each file (the `.m` defines it; the `.cr` declares the `fun` binding and uses it).
- **Evidence:** `inspections/I4.log`.

#### I5. `callback.registry-exports-trampoline`
- **required:** true
- **Verify:** `src/ui/native/callback_registry.cr` exposes `register_action`, `register_action_with_value`, `invoke`, and the top-level `fun ap_swiftkit_invoke_action(token : UInt64, value : Float64)`.
- **How:** `grep -n "fun ap_swiftkit_invoke_action\|def self.register_action\|def self.invoke" src/ui/native/callback_registry.cr`.
- **Pass:** all four symbols found.
- **Evidence:** `inspections/I5.log`.

#### I6. `swiftkit.overrides-class-per-widget`
- **required:** true
- **Verify:** every widget in `implementation.md` §6 has an `Overrides` class file under `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/` that inherits from `ViewOverrides` and declares the documented per-widget fields.
- **How:**
  ```
  ls swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/
  ```
  Cross-check against §6.
- **Pass:** every widget in §6 has a matching `*Overrides.swift` file (except where §6 explicitly says "none beyond ViewOverrides" — Divider is the only such case, and it may omit a per-widget overrides class).
- **Evidence:** `inspections/I6.log`.

#### I7. `swiftkit.facade-class-per-widget`
- **required:** true
- **Verify:** every widget in §6 has a `*Facade.swift` file under `Sources/AssetPipelineSwiftKit/Facades/` that exposes at least one `@objc public static func make*(...)` method.
- **How:** `ls swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/`, then for each file `grep -E '^\s*@objc public static func make' <file>`.
- **Pass:** every widget has a facade with at least one `@objc public static func make...` method.
- **Evidence:** `inspections/I7-facade-inventory.log`.

#### I8. `swiftkit.common-modifiers-helper-applied`
- **required:** true
- **Verify:** every facade's `make*` method calls `CommonModifiers.apply(...)` before invoking `HostingHelpers.host(...)`.
- **How:** for each facade file, `grep -E "CommonModifiers\.apply|HostingHelpers\.host" <file>`.
- **Pass:** every facade has both calls, and `apply` precedes `host` in the file (textual order is an acceptable proxy for call order).
- **Evidence:** `inspections/I8.log`.

#### I9. `swiftkit.glass-uses-glass-effect`
- **required:** true
- **Verify:** `GlassBackgroundFacade.swift` invokes `.glassBackgroundEffect()` inside an `if #available(iOS 26.0, macOS 26.0, *)` branch and falls back to `.background(.regularMaterial)` (or equivalent material) for older OSes.
- **How:** `grep -nE "glassBackgroundEffect|regularMaterial|thinMaterial|thickMaterial|#available" swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift`.
- **Pass:** both branches present; the `if #available` guard wraps the `glassBackgroundEffect` call.
- **Evidence:** `inspections/I9.log`.

#### I10. `swiftkit.runtime-init-call-site`
- **required:** true
- **Verify:** the action trampoline is registered exactly once in each sample's startup path. Locate the calls:
  ```
  grep -nE "APSKRuntime|install_swiftkit_action_trampoline|ap_swiftkit_invoke_action" \
    samples/cross_platform/ios_host/hig_bridge.cr \
    samples/cross_platform/macos_host/hig_showcase.cr
  ```
- **Pass:** at least one match in each sample file; the call happens after `GC.init` (verify by reading the surrounding code).
- **Evidence:** `inspections/I10.log`.

#### I11. `swiftkit.no-leak-of-hosting-controller`
- **required:** true
- **Verify:** `HostingHelpers.host(...)` associates the hosting controller with the returned view via `objc_setAssociatedObject` (so ARC keeps the controller alive as long as the view).
- **How:** `grep -nE "objc_setAssociatedObject|associatedObject" swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift`.
- **Pass:** the call is present with `.OBJC_ASSOCIATION_RETAIN_NONATOMIC` (or `.OBJC_ASSOCIATION_RETAIN`).
- **Evidence:** `inspections/I11.log`.

#### I12. `bridge.default-nil-propagation`
- **required:** true
- **Verify:** when a Crystal `UI::View` has a property at its type default (e.g., `corner_radius == 0.0`, `opacity == 1.0`, `padding == EdgeInsets.new`), the renderer's `visit` method does NOT call the corresponding ObjC setter on the Overrides object. Inspect at least three migrated visit methods (Button, Toggle, Label) and confirm the guard pattern (`view.corner_radius == 0.0 ? nil : ...`) is in place. Cross-reference §7.2 of `implementation.md`.
- **How:** read the three visit methods. Run a small targeted grep:
  ```
  grep -nE "view\.corner_radius == 0\.0 \? nil|view\.opacity == 1\.0 \? nil|view\.hidden == false \? nil" \
    src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr | head -50
  ```
- **Pass:** the guard pattern appears for each documented "default-to-nil" property in each migrated visit method.
- **Evidence:** `inspections/I12.log`.

#### I13. `bridge.no-todo-fixme-in-migrated-code`
- **required:** false (optional cleanup check)
- **Verify:** the implementer did not leave `TODO`/`FIXME` markers in `swift/AssetPipelineSwiftKit/Sources/` or in the migrated visit ranges.
- **How:** `grep -rnE "TODO|FIXME|XXX" swift/AssetPipelineSwiftKit/Sources/ src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr | head -30`.
- **Pass:** zero matches (or any matches reference a tracked GitHub issue per `implementation_criteria.md`).
- **Evidence:** `inspections/I13.log`.

---

### Group BX — Behavior and conformance (end-to-end through the bridge)

Group BX exists because every other group in this phase falls one bar short of proving the bridge works at runtime. Build (B) proves the artifacts compile. Inspection (I) proves the source structurally aligns with the brief. Visual (V) proves a still frame looks right. **None of those prove that a button tap fires the bound action, that a runtime override actually re-paints, or that a Form composes children at non-zero sizes.** Group BX is the behavior + conformance bar for Phase 3 and is the source of truth for whether the bridge actually works.

These checks require a booted iOS simulator and a launched macOS sample. If neither is available on the validator host, mark each BX check `blocked: true` with the specific environmental gap and let the team lead reassign. **Do not collapse a BX check into a presence-grep check because the simulator is slow to boot.**

Every BX check in this group drives the running app via either `UI::AXTest` (macOS) or XCUITest (iOS). The toolkit reference for both — which Carbon actions to invoke for press / toggle / value-set / focus / dismiss; how to traverse the AX tree; how to capture per-element geometry and ΔE samples; which AXTest extensions are not yet wired and which gaps require marking a check `blocked` — is `../../rubric/behavior-simulation-toolkit.md` sections 1 (macOS), 2 (iOS), and 5 (recipes). Read it once; cross-reference it as you implement each BX check.

#### BX1. `action.button-tap-fires-handler-ios`
- **required:** true
- **Bar:** behavior.
- **Verify:** a `UI::Button` rendered into the iOS host with an `on_tap` proc fires the bound Crystal proc when the rendered SwiftUI Button is tapped in the simulator. End-to-end: rendered-pixel tap (synthetic touch via XCUITest, **not** a JS-side method call into the bridge) → SwiftUI action → CallbackBridge → `ap_swiftkit_invoke_action` → CallbackRegistry → Crystal proc → counter mutation → next render visibly reflects the new counter value.
- **How:** add a temporary slug `phase-03-action-tap-probe` to the iOS HIG host that builds a Button (`accessibilityIdentifier = "tap-probe-button"`) whose `on_tap` mutates a Crystal-side `TapProbe` singleton's counter and re-renders an adjacent `UI::Label` (`accessibilityIdentifier = "tap-probe-counter"`) with the new count. Boot the iOS 26.2 simulator (`xcrun simctl boot "iPhone 17 Pro"`), install and launch the host with `HIG_SLUG=phase-03-action-tap-probe`. Drive via XCUITest using the patterns in `../../rubric/behavior-simulation-toolkit.md` §2.3:
  ```swift
  let app = XCUIApplication()
  app.launchEnvironment["HIG_SLUG"] = "phase-03-action-tap-probe"
  app.launch()
  let btn = app.buttons["tap-probe-button"]
  XCTAssertTrue(btn.waitForExistence(timeout: 5))
  XCTAssertEqual(app.staticTexts["tap-probe-counter"].label, "0")
  btn.tap()
  XCTAssertEqual(app.staticTexts["tap-probe-counter"].label, "1")
  btn.tap(); btn.tap()
  XCTAssertEqual(app.staticTexts["tap-probe-counter"].label, "3")
  ```
  Run:
  ```
  xcodebuild test -project samples/cross_platform/ios_host/CrystalHIGHost.xcodeproj \
    -scheme CrystalHIGHost -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
    -only-testing CrystalHIGHostUITests/HIGActionTapProbeTests/testTapIncrementsCounter
  ```
- **Pass:** all four assertions hold. Specifically: the counter starts at `"0"`, reads `"1"` after the first `.tap()`, and reads `"3"` after three taps. XCUITest exits 0. The probe label transition between renders proves the bound state mutated (not just that the action fired into a no-op).
- **Evidence:** `test_output/BX1.log`, `screenshots/BX1-counter-0.png` (pre-tap), `screenshots/BX1-counter-3.png` (post-three-taps), `inspections/BX1-label-transitions.json` (the four label values recorded before each assertion).
- **Revert:** remove the temporary slug + probe singleton; verify `git status --short` is clean.

#### BX2. `action.button-tap-fires-handler-macos`
- **required:** true
- **Bar:** behavior.
- **Verify:** same as BX1 on macOS via the existing `UI::AXTest` framework. The macOS host already runs under the AX harness in `spec/ui/hig_validation/macos_visual_spec.cr`. The press is invoked through `AXUIElementPerformAction(button, kAXPressAction)` — a real synthetic accessibility press, **not** a direct method call into the Crystal-side handler. The counter label must transition `"0" → "1" → "2" → "3"` across three presses, proving the bridge fired the bound proc each time.
- **How:** add a temporary AX behavior spec at `spec/ui/hig_validation/macos_action_tap_probe_spec.cr` modeled on `macos_visual_spec.cr`. The spec launches `bin/hig_showcase` with `HIG_SLUG=phase-03-action-tap-probe`, attaches via `UI::AXTest::App.connect(pid)`, then drives the button by `AXIdentifier`. Reference the patterns in `../../rubric/behavior-simulation-toolkit.md` §1.5 (perform_action helper) and §1.11 (full probe scaffold). Pseudocode:
  ```crystal
  app = UI::AXTest::App.connect(showcase_pid)
  btn = app.find(role: "AXButton", label: "tap-probe-button").not_nil!  # or via AXIdentifier (toolkit §1.4)
  counter = app.find(role: "AXStaticText", label: "tap-probe-counter").not_nil!
  counter.value.should eq("0")
  3.times do |i|
    perform_action(btn, "AXPress")  # toolkit §1.5
    sleep(0.15)                      # let the callback flush + relayout
    counter.value.should eq((i + 1).to_s)
  end
  ```
  Run:
  ```
  crystal spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr \
    -Dmacos 2>&1 | tee handoff/phase-03-evidence-DATE/test_output/BX2.log
  ```
- **Pass:** spec passes; counter label reads `"1"`, `"2"`, `"3"` in sequence after each AXPress; no AppKit crash log written; no AX timeout errors logged.
- **Evidence:** `test_output/BX2.log`, `screenshots/BX2-counter-{0,1,2,3}.png` (captured via `app.screenshot(path, window_title: "HIG: phase-03-action-tap-probe")` after each press), `inspections/BX2-label-transitions.json`.
- **Revert:** remove the temporary slug and the temporary spec file. Verify clean tree.

#### BX3. `bridge.value-callback-toggle-ios`
- **required:** true
- **Bar:** behavior.
- **Verify:** a `UI::Toggle` with `on_change` proc receives the new boolean when toggled in the iOS simulator. Confirms `register_action_with_value` end-to-end. **Both** the visible switch state AND the bound `ToggleProbe.last_value` (mirrored into a separate label) must transition in lockstep — verifying that the callback fired with the correct payload, not just that the switch animated.
- **How:** temporary slug `phase-03-toggle-value-probe`. The Toggle's `on_change` writes the new boolean into a Crystal `ToggleProbe.last_value`; the next render mirrors that value into a separate `UI::Label` (`accessibilityIdentifier = "toggle-probe-value"`). Drive via XCUITest, per `../../rubric/behavior-simulation-toolkit.md` §5.2:
  ```swift
  let toggle = app.switches["toggle-probe-toggle"]
  let probe  = app.staticTexts["toggle-probe-value"]
  XCTAssertEqual(toggle.value as? String, "0")
  XCTAssertEqual(probe.label, "false")
  toggle.tap()
  XCTAssertEqual(toggle.value as? String, "1")
  XCTAssertEqual(probe.label, "true")
  toggle.tap()
  XCTAssertEqual(toggle.value as? String, "0")
  XCTAssertEqual(probe.label, "false")
  ```
- **Pass:** four assertions hold; switch visual state and probe label transition together; no callback fires when `on_change` is not bound to a value mutation.
- **Evidence:** `test_output/BX3.log`, `screenshots/BX3-state-{0,1,0}.png`, `inspections/BX3-transitions.json`.

#### BX4. `bridge.value-callback-slider-ios`
- **required:** true
- **Bar:** behavior.
- **Verify:** a `UI::Slider` with `on_change` fires with the new value when dragged, and the bound value progresses monotonically with the drag. The check actually drives `XCUIElement.adjust(toNormalizedSliderPosition:)` at three positions, not just asserts that the slider responds to taps.
- **How:** temporary slug `phase-03-slider-value-probe`. Slider's `on_change` writes the new value into `SliderProbe.last_value`; the next render mirrors that as the formatted text in a `UI::Label` (`accessibilityIdentifier = "slider-probe-value"`). Drive via XCUITest per `../../rubric/behavior-simulation-toolkit.md` §5.3:
  ```swift
  let s = app.sliders["slider-probe-slider"]
  let p = app.staticTexts["slider-probe-value"]
  s.adjust(toNormalizedSliderPosition: 0.0)
  Thread.sleep(forTimeInterval: 0.3)
  let v0 = Double(p.label) ?? -1
  s.adjust(toNormalizedSliderPosition: 0.5)
  Thread.sleep(forTimeInterval: 0.3)
  let v1 = Double(p.label) ?? -1
  s.adjust(toNormalizedSliderPosition: 1.0)
  Thread.sleep(forTimeInterval: 0.3)
  let v2 = Double(p.label) ?? -1
  XCTAssertTrue(v0 <= 0.05)
  XCTAssertTrue(v1 >= 0.45 && v1 <= 0.55)
  XCTAssertTrue(v2 >= 0.95)
  XCTAssertTrue(v0 < v1 && v1 < v2, "Slider drag must produce monotonically increasing values")
  ```
- **Pass:** all four assertions hold. The probe label lands in the expected band after each adjustment AND the bound values are monotonic. A failure here means either the bridge dropped intermediate values or the on_change is firing with stale state.
- **Evidence:** `test_output/BX4.log`, `screenshots/BX4-slider-{0,mid,end}.png`, `inspections/BX4-drag-sequence.json` (the three `(position, label, parsed_value)` triples).

#### BX5. `bridge.override-rerender-runtime`
- **required:** true
- **Bar:** behavior + conformance.
- **Verify:** mutating an override after the initial render causes the hosted SwiftUI view to re-paint with the new modifier. This is the test that catches static-snapshot bugs where the overrides are read once and never re-applied. The mutation is driven by a real synthetic tap on a sibling "Make Red" Button — **not** by directly calling the Crystal-side mutation from the spec process — so the full Crystal action → SwiftUI re-render path is exercised.
- **Implementer dependency:** the demo slug must expose the "Make Red" affordance natively. If `phase-03-runtime-override-probe` does not already exist or does not include a sibling Button bound to the override mutation, mark this check `blocked: true` with note `"Demo missing runtime-override mutation affordance — see toolkit §4.4."` Do not freelance the affordance.
- **How:** temporary slug `phase-03-runtime-override-probe`. The slug builds a target Button (`accessibilityIdentifier = "override-target"`) whose `background` starts as transparent; an adjacent Button (`accessibilityIdentifier = "make-red-trigger"`) mutates `override-target.background_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)` and triggers a re-render of the parent. Use the XCUITest + screenshot pattern from `../../rubric/behavior-simulation-toolkit.md` §4.4:
  ```swift
  let target = app.buttons["override-target"]
  XCTAssertTrue(target.waitForExistence(timeout: 3))
  let beforeShot = target.screenshot()  // element-only crop
  let beforeAtt  = XCTAttachment(screenshot: beforeShot); beforeAtt.name = "BX5-before.png"; beforeAtt.lifetime = .keepAlways; add(beforeAtt)
  app.buttons["make-red-trigger"].tap()
  Thread.sleep(forTimeInterval: 0.35)  // motion duration + one frame
  let afterShot = target.screenshot()
  let afterAtt  = XCTAttachment(screenshot: afterShot); afterAtt.name = "BX5-after.png"; afterAtt.lifetime = .keepAlways; add(afterAtt)
  ```
  Sample the geometric center pixel of each capture and compute ΔE76 against pure red `(255, 0, 0)`.
- **Pass:** ΔE(before, red) > 20 AND ΔE(after, red) ≤ 10. The first inequality proves the mutation actually changed the rendered output (not a false-pass where the Button was already red); the second proves the new override took effect within the documented motion duration.
- **Evidence:** `screenshots/BX5-before.png`, `screenshots/BX5-after.png`, `inspections/BX5-color-sample.json` containing `{before_rgb, after_rgb, before_lab, after_lab, delta_e_before_to_red, delta_e_after_to_red, thresholds, passed}`.

#### BX6. `bridge.hosted-form-children-nonzero`
- **required:** true
- **Bar:** conformance.
- **Verify:** a `UI::Form` containing three `UI::Button` rows in the iOS sample renders each child at non-zero size, with no two children's bounding boxes overlapping, AND each row remains tappable. This is the test that catches the nested-`UIHostingController` measurement pathology called out in the brief's known-risks list. The validator additionally drives a synthetic tap on the middle row and asserts the row's bound action fires (proving the row is not just non-zero in size but actually receives touch).
- **How:** temporary slug `phase-03-form-nested-buttons`. Build a Form with three Buttons (identifiers `form-row-1`, `form-row-2`, `form-row-3`); row 2's `on_tap` increments a probe label `form-row-2-counter`. Launch in the iOS 26.2 simulator. Use XCUITest to query each Button's `.frame` via `XCUIElement.frame` (toolkit §2.7) and write the three CGRects to a JSON log.
  ```
  // In XCUITest:
  let row1 = app.buttons["form-row-1"].frame
  let row2 = app.buttons["form-row-2"].frame
  let row3 = app.buttons["form-row-3"].frame
  // Write to file via XCTAttachment
  ```
- **Pass:** (a) every `frame.size.width > 0` and `frame.size.height >= 44` (touch-target minimum); (b) `row1.maxY <= row2.minY + 1`, `row2.maxY <= row3.minY + 1` (no overlap, allowing 1 pt for separator rounding); (c) after `app.buttons["form-row-2"].tap()`, `app.staticTexts["form-row-2-counter"].label == "1"` (the row is genuinely tappable, not just non-zero).
- **Evidence:** `inspections/BX6-frames.json`, `inspections/BX6-tap-result.json`, `screenshots/BX6-form-rendered.png`.

#### BX7. `bridge.hosted-form-children-nonzero-macos`
- **required:** true
- **Bar:** conformance.
- **Verify:** same composition guarantee on macOS via the `UI::AXTest` framework. Each row's `AXFrame` (read via `kAXPositionAttribute` + `kAXSizeAttribute` per toolkit §1.4 / §A2) must report non-zero width/height and order top-to-bottom without overlap. Additionally drive `AXUIElementPerformAction(row_2, kAXPressAction)` and assert the bound counter incremented (parity with BX6 (c)).
- **How:** AX spec at `spec/ui/hig_validation/macos_form_layout_spec.cr`. Launch `bin/hig_showcase` with `HIG_SLUG=phase-03-form-nested-buttons`, walk the AX tree, read each button's `kAXPositionAttribute` + `kAXSizeAttribute` (note: this requires AXTest extension A2 for unpacking `AXValueRef`; if extension is not yet wired, mark `blocked: true` with note `"AXTest gap A2 — AXValueRef unpacker not yet exposed."`). After geometry assertions, `perform_action(row_2, "AXPress")` and assert `form-row-2-counter` reads `"1"`.
- **Pass:** same three predicates as BX6, evaluated against AX-tree geometry.
- **Evidence:** `test_output/BX7.log`, `inspections/BX7-ax-frames.json`, `inspections/BX7-tap-result.json`.

#### BX8. `bridge.dismiss-returns-focus`
- **required:** true
- **Bar:** behavior.
- **Verify:** when a SwiftUI `.sheet` presented through `UI::Sheet` is dismissed via **every documented dismiss path**, the sheet is removed from the AX tree AND focus returns to the originating trigger. Dismiss paths on iOS: primary action button, Cancel button, swipe-down gesture, backdrop tap (where the sheet style allows it). On macOS via AXTest: primary action AXPress, Cancel AXPress, Escape key (CGEvent — see toolkit §A6). Apply the modal contract from `../../rubric/behavior-simulation-toolkit.md` §4.2: AX-absent + focus-restored + dismiss-reason-correct, asserted independently per path.
- **How:** temporary slug `phase-03-sheet-focus-return`. The sheet exposes three internal controls (`accessibilityIdentifier = "sheet-content"`, `"sheet-primary"`, `"sheet-cancel"`) and the launching button uses identifier `"sheet-trigger"`. Run each dismiss path in turn, re-opening between paths.

  **iOS XCUITest (per path; loop wraps these three assertions per path):**
  ```swift
  app.buttons["sheet-trigger"].tap()
  XCTAssertTrue(app.otherElements["sheet-content"].waitForExistence(timeout: 2))
  // ...drive the dismiss for this path (tap primary | tap cancel | swipe down | tap backdrop)...
  XCTAssertFalse(app.otherElements["sheet-content"].exists)          // AX-absent
  XCTAssertTrue(app.buttons["sheet-trigger"].isHittable)              // trigger again interactive
  // dismiss-reason recorded by the Crystal-side DismissProbe.last_reason, mirrored into a label:
  XCTAssertEqual(app.staticTexts["dismiss-reason"].label, expectedReason)
  ```

  **macOS AXTest:**
  ```crystal
  trigger = app.find(role: "AXButton", label: "sheet-trigger").not_nil!
  trigger.click  # AXPress opens sheet
  sleep(0.4)
  app.find(role: "AXGroup", label: "sheet-content").should_not be_nil
  # ...drive the dismiss (perform_action AXPress on sheet-primary or sheet-cancel, or Keys.press(Keys::ESCAPE) per toolkit §A6)...
  app.find(role: "AXGroup", label: "sheet-content").should be_nil
  focused_element(app).try(&.label).should eq("sheet-trigger")        # toolkit §1.8
  app.find(role: "AXStaticText", label: "dismiss-reason").not_nil!.value.should eq(expected_reason)
  ```
- **Pass:** for every dismiss path on both platforms — (a) sheet-content absent from the AX tree, (b) trigger is the active/focused element again, (c) dismiss-reason label matches the path identifier. Three booleans × four paths × two platforms = 24 assertions; any single failure fails the check.
- **Evidence:** `test_output/BX8.log`, per-path screenshot pairs `screenshots/BX8-{path}-{presented,dismissed}.png`, `inspections/BX8-dismiss-matrix.json` (the 24-assertion grid with pass/fail per cell).

#### BX9. `bridge.touch-target-minimum-measured`
- **required:** true
- **Bar:** conformance.
- **Verify:** every default-styled `UI::Button` on iOS measures ≥ 44×44 pt from the rendered XCUIElement frame. This is measured from rendered output, not declared in source.
- **How:** reuse the V1 capture's host slug. Add an XCUITest assertion that queries `app.buttons["save"].frame` and writes the CGRect to `inspections/BX9-frame.json`. Assert width and height both ≥ 44.
- **Pass:** width ≥ 44.0 AND height ≥ 44.0 on the iPhone 17 Pro simulator in portrait.
- **Evidence:** `inspections/BX9-frame.json`.

#### BX10. `bridge.dark-mode-tint-shifts-measured`
- **required:** true
- **Bar:** conformance.
- **Verify:** when the iOS simulator switches from light to dark mode, the default Button's tint shifts. V10 currently asserts "any non-zero delta" which is too permissive (anti-aliasing alone produces non-zero delta). Strengthen: sample the Button's center pixel in both light and dark captures and confirm the Lab distance is **≥ ΔE 8** (genuine tint shift, not noise).
- **How:** use V1 light and V1 dark captures. Sample center pixel via `magick convert` + `pngtopnm` pipeline (or use the Swift snapshot tool's color-sampling helper).
  ```
  # Sample center pixel of the button region (bounding box known from BX9)
  python3 scripts/sample_pixel.py screenshots/V1-default-button-ios-light.png 100 30 > inspections/BX10-light-rgb.txt
  python3 scripts/sample_pixel.py screenshots/V1-default-button-ios-dark.png  100 30 > inspections/BX10-dark-rgb.txt
  ```
  (If `scripts/sample_pixel.py` does not exist, write a one-shot helper into `handoff/phase-03-evidence-DATE/scripts/` and clean it up after the run.)
- **Pass:** ΔE 2000 between light and dark sample ≥ 8.0.
- **Evidence:** `inspections/BX10-{light,dark}-rgb.txt`, `inspections/BX10-delta-e.log`.

#### BX11. `bridge.action-token-collision-no-op`
- **required:** true
- **Bar:** behavior.
- **Verify:** invoking `ap_swiftkit_invoke_action` with an unknown token (e.g., token never registered, or token registered then freed) is a no-op — no crash, no exception, no Crystal-side proc invoked. This is the safety check that prevents a Swift-side use-after-free from taking down the process.
- **How:** add a Crystal spec at `spec/ui/native/callback_registry_spec.cr` (extend existing file) that calls `LibCallbackRegistry.ap_swiftkit_invoke_action(0xDEADBEEF_u64, 0.0_f64)` and asserts no exception is raised, no registered proc was invoked, and the registry size is unchanged.
- **Pass:** spec passes; `crystal spec spec/ui/native/callback_registry_spec.cr --verbose` shows the new example with status `ok`.
- **Evidence:** `test_output/BX11.log`.

#### BX12. `bridge.runtime-init-order-enforced`
- **required:** true
- **Bar:** behavior.
- **Verify:** the documented Crystal-runtime-then-Swift-trampoline-install order (§10.4) is enforced in the running samples. Reordering would crash; absence of crash on launch + first Crystal→Swift call is the positive signal.
- **How:** the iOS BX1 and macOS BX2 captures both depend on the order being correct. Additionally: instrument the sample's `hig_bridge.cr` / `hig_showcase.cr` with a `Log.info { "trampoline-installed: #{ts}" }` line, launch the sample, capture the `os_log` stream from the simulator (or syslog from the macOS host), confirm the trampoline-installed log line precedes the first SwiftKit facade call log line.
- **Pass:** order is correct in both samples; no `EXC_BAD_ACCESS` or `dyld: missing symbol` recorded on launch.
- **Evidence:** `test_output/BX12-{ios,macos}-launch-log.txt`.

---

### Group V — Visual verification

The visual checks compare the rendered output of selected widgets against committed baseline screenshots in `swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/`. Baselines are PNGs at known dimensions captured via Point-Free's [`swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing) at pinned minor version `1.17.x` (see `implementation.md` §10.2 item 3 for the pin and `Package.swift` dependency form).

For each visual check, capture a fresh screenshot of the named scene and diff against the baseline. **Acceptable pixel delta thresholds (aligned with Phase 7):**

- **Web (rendered HTML in headless Chrome):** ≤ 1.0% of pixels may differ by more than 3 in any RGB channel (3/255 channel delta).
- **Native (iOS / macOS via the snapshot library):** ≤ 0.5% of pixels may differ by more than 3 in any RGB channel.

These are the same thresholds Phase 7 enforces on its full-screen baselines; using a tighter bar than Phase 7 here would risk Phase 3 passing on a baseline that Phase 7 then rejects. The native bar is tighter (0.5%) because deterministic native rendering at fixed dimensions exhibits less anti-aliasing variance than a web headless browser.

To capture iOS screenshots, launch the iOS sample in the simulator (`xcrun simctl boot "iPhone 17 Pro"` then `xcrun simctl install booted <app>` and `xcrun simctl launch booted ...`), set the relevant slug via the existing HIG host harness, and run `xcrun simctl io booted screenshot <path>.png`. For macOS, the existing visual regression harness in `samples/cross_platform/macos_host/` produces PNGs — set `HIG_SCREENSHOT_PATH` and `HIG_SLUG` and execute `./bin/hig_showcase`.

#### V1. `swiftui.button-default-renders-ios`
- **required:** true
- **Verify:** an unstyled `UI::Button.new("Save")` on iOS renders as a SwiftUI Button — system blue tint, system font weight (.body / regular), default insets, accessibility traits intact.
- **How:** add a test scene to the iOS HIG harness if one does not already exist (slug `phase-03-button-default`); capture screenshot at 320×120 in light scheme; compare against `swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/default_button_ios.png`.
- **Pass:** native pixel delta ≤ 0.5% by more than 3/255 per channel; visual inspection confirms system blue text color and rounded-rect tap target.
- **Evidence:** `screenshots/V1-default-button-ios-light.png`, `screenshots/V1-default-button-ios-dark.png`, `inspections/V1-pixel-delta.log`.

#### V2. `swiftui.button-default-renders-macos`
- **required:** true
- **Verify:** same as V1 on macOS.
- **How:** capture via the macOS HIG harness at 320×120 light and dark.
- **Pass:** matches `default_button_macos.png` baseline within the native threshold (≤ 0.5% by more than 3/255 per channel).
- **Evidence:** `screenshots/V2-default-button-macos-{light,dark}.png`.

#### V3. `swiftui.button-background-override`
- **required:** true
- **Verify:** setting `view.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)` on a Button produces a red-background button while preserving SwiftUI typography, default radius, and default insets.
- **How:** test scene `phase-03-button-background-override`. Capture iOS + macOS at 320×120 light.
- **Pass:** background is unambiguously red; title text retains system font weight (visually checkable) and uses default text color treatment (white or near-white on red); corner radius matches the default Button corner radius.
- **Evidence:** `screenshots/V3-background-override-{ios,macos}.png`.

#### V4. `swiftui.button-corner-radius-zero`
- **required:** true
- **Verify:** setting `view.corner_radius = 0.0` produces a square-cornered button without changing other defaults (color, font, insets, animation).
- **How:** test scene `phase-03-button-square`. Capture iOS + macOS.
- **Pass:** corners are visibly square (no rounding); all other styling matches the V1/V2 defaults.
- **Evidence:** `screenshots/V4-square-button-{ios,macos}.png`.

#### V5. `swiftui.toggle-default-renders`
- **required:** true
- **Verify:** an unstyled `UI::Toggle.new(label: "Notify", is_on: true)` renders as a SwiftUI Toggle — system green track on iOS, system accent on macOS.
- **How:** test scene `phase-03-toggle-default`; capture both platforms in light + dark.
- **Pass:** track is system green (iOS) / system accent (macOS); label uses system font; thumb has the SwiftUI default shadow.
- **Evidence:** four screenshots in `screenshots/V5-*`.

#### V6. `swiftui.glass-cascade-ios26`
- **required:** true
- **Verify:** on iOS 26+, a `UI::Card` (which wraps `GlassBackground` per §6) renders Liquid Glass automatically; on iOS 16-25, falls back to `.regularMaterial`.
- **How:** boot an iOS 26 simulator (`xcrun simctl create "iPhone 17 Pro" "iPhone 17 Pro" "com.apple.CoreSimulator.SimRuntime.iOS-26-2"` if not present), capture `phase-03-card-default` slug. Also capture against an iOS 17 or 18 simulator if available. Diff against `glass_default_ios26.png` and `glass_default_ios18.png` baselines.
- **Pass:** on iOS 26 the rendered output exhibits the Liquid Glass refractive look (translucent, light-bending edges); on iOS ≤25 it exhibits flat `.regularMaterial` translucency. If only one simulator is available, mark the missing OS variant `blocked: true` with a note explaining.
- **Evidence:** `screenshots/V6-card-ios26.png`, `screenshots/V6-card-ios18.png` (if captured), `inspections/V6-pixel-delta.log`.

#### V7. `swiftui.tabview-child-rendering`
- **required:** true
- **Verify:** a Tier 2 widget renders identically as a standalone widget vs as a child of a TabView (i.e., per-widget hosting + nested hosting do not change the visual output of the child).
- **How:** capture screenshot of a default `UI::Button.new("Save")` standalone (the V1 capture). Then build a TabView whose first child is the same Button, capture the same Button as it appears inside the tab. Crop both to the Button's frame and compare.
- **Pass:** native threshold (≤ 0.5% by more than 3/255 per channel). Any larger delta is a regression (likely indicates a nested hosting controller resizing differently).
- **Evidence:** `screenshots/V7-button-standalone-ios.png`, `screenshots/V7-button-in-tab-ios.png`, `inspections/V7-crop-diff.log`.

#### V8. `swiftui.form-default-renders`
- **required:** true
- **Verify:** an unstyled `UI::Form` containing a Toggle, a TextField, and a Picker renders with SwiftUI grouped form styling on iOS and column form styling on macOS.
- **How:** test scene `phase-03-form-default`. Capture both platforms light.
- **Pass:** iOS shows grouped sections with the standard inset; macOS shows the column layout with labels right-aligned (SwiftUI's `.formStyle(.automatic)` resolution).
- **Evidence:** `screenshots/V8-form-{ios,macos}.png`.

#### V9. `swiftui.dynamic-type-respected`
- **required:** false (optional check; included for completeness)
- **Verify:** changing the iOS simulator's text size category causes the default Button label to scale (proves SwiftUI's dynamic type behavior is preserved).
- **How:** capture V1 screenshot at `accessibilityXXXL`. Compare to the standard V1 capture.
- **Pass:** the label is visibly larger at the XXXL category.
- **Evidence:** `screenshots/V9-button-default-ios-xxxl.png`.

#### V10. `swiftui.dark-mode-tracking`
- **required:** true
- **Verify:** the default Button on iOS adapts its tint color when the system switches to dark mode (SwiftUI default behavior).
- **How:** V1 light and dark captures already provide this. Diff the two images and confirm tint color shifts.
- **Pass:** the rendered tint differs between light and dark schemes (any non-zero delta in the tinted region is sufficient).
- **Evidence:** `inspections/V10-light-dark-diff.log`.

---

### Group S — Spec verification

#### S1. `spec.overrides-population-button`
- **required:** true
- **Verify:** `spec/ui/renderers/swiftkit/button_overrides_spec.cr` exists, asserts the documented overrides-population behavior, and passes.
- **How:** `crystal spec spec/ui/renderers/swiftkit/button_overrides_spec.cr 2>&1 | tee handoff/phase-03-evidence-DATE/test_output/S1.log`.
- **Pass:** all examples in the file pass; the spec file contains assertions for default-detection of every property in `UI::View` base plus `UI::Button` specifics.
- **Evidence:** `test_output/S1.log`.

#### S2. `spec.overrides-population-toggle`
- **required:** true
- **Verify:** `spec/ui/renderers/swiftkit/toggle_overrides_spec.cr` passes.
- **How:** `crystal spec spec/ui/renderers/swiftkit/toggle_overrides_spec.cr`.
- **Evidence:** `test_output/S2.log`.

#### S3. `spec.default-detection-invariant`
- **required:** true
- **Verify:** `spec/ui/renderers/swiftkit/default_detection_spec.cr` exists and exhaustively tests that creating a `UI::<Widget>` with no properties set results in zero overrides being applied (every ObjC setter call is a no-op except the identity-establishing ones). This is THE invariant of phase 3.
- **How:** `crystal spec spec/ui/renderers/swiftkit/default_detection_spec.cr -v 2>&1 | tee handoff/phase-03-evidence-DATE/test_output/S3.log`.
- **Pass:** every spec in the file passes; the file covers at least Button, Toggle, Label, VStack, Card, GlassBackground.
- **Evidence:** `test_output/S3.log`.

#### S4. `spec.callback-registry`
- **required:** true
- **Verify:** `spec/ui/native/callback_registry_spec.cr` covers the new `register_action`, `register_action_with_value`, and `invoke` methods, including the "unknown token is a no-op" case.
- **How:** `crystal spec spec/ui/native/callback_registry_spec.cr`.
- **Pass:** all examples pass; the file contains at least one example for each new method and one for the unknown-token case.
- **Evidence:** `test_output/S4.log`.

#### S5. `spec.swift-overrides-propagation`
- **required:** true
- **Verify:** the Swift-side `OverridesPropagationTests.swift` covers every `ViewOverrides` field — setting each field individually causes the corresponding modifier to appear in the rendered hierarchy, and leaving it nil omits the modifier.
- **How:** `swift test --filter OverridesPropagationTests 2>&1 | tee handoff/phase-03-evidence-DATE/test_output/S5.log` from `swift/AssetPipelineSwiftKit/`.
- **Pass:** every field in `ViewOverrides` (per `implementation.md` §5.2) has at least one assertion in the suite; all assertions pass.
- **Evidence:** `test_output/S5.log`.

#### S6. `spec.swift-snapshot-tests`
- **required:** true
- **Verify:** the Swift snapshot test suite passes and includes the baselines named in `implementation.md` §10.2 item 3.
- **How:** `swift test --filter SnapshotTests`.
- **Pass:** zero `XCTFail`. The committed PNGs in `Tests/AssetPipelineSwiftKitTests/SnapshotTests/` include at minimum `default_button_ios.png`, `default_button_macos.png`, `background_override_ios.png`, `corner_radius_zero_ios.png`, `glass_default_ios26.png`.
- **Evidence:** `test_output/S6.log` + a directory listing in `inspections/S6-baseline-inventory.log`.

#### S7. `spec.runtime-bridge`
- **required:** true
- **Verify:** `RuntimeBridgeTests.swift` confirms `APSKRuntime.initialize(actionTrampoline:)` accepts and stores a function pointer and that `CallbackBridge.fire` invokes it.
- **How:** `swift test --filter RuntimeBridgeTests`.
- **Pass:** all examples pass.
- **Evidence:** `test_output/S7.log`.

---

## Verdict computation

```
verdict = "PASS"  if  every check where required == true has passed == true
verdict = "FAIL"  otherwise
```

`blocked: true` is treated as `passed: false` for verdict purposes. Optional checks (`required: false` — I13, V9) never affect the verdict.

**Group BX is the make-or-break group.** A Phase 3 run that passes B, I, V, S but fails any required check in BX has not actually proven the bridge works at runtime — only that it compiles and that still frames look correct. Do not let a green B/I/V/S report mask a red BX result.

---

## Summary requirements

The `summary` field at the bottom of the GATE_REPORT must be 2-4 sentences and include:

1. The total count of required checks passing vs total required.
2. A one-sentence orientation: build, inspection, visual, and spec groups all green vs which one(s) failed.
3. If any check failed: a one-sentence pointer to where the implementer needs to look (e.g., "default-detection invariant failing for `padding` field in `visit(view : UI::Button)` — overrides setter is called even when padding is `EdgeInsets.new`").
4. If everything passed: a single sentence confirming the Swift companion and refactored renderers are ready for phase 4.

---

## Notes for the validator

- **Order matters.** Run build checks (Group B) first. If B1-B5 fail, every visual check is blocked and you should mark them so rather than attempting to capture screenshots from an un-built sample.
- **Be wary of false greens on visual checks.** Native checks here use the 0.5% / 3-per-channel threshold (matching Phase 7); if a screenshot diff is suspiciously perfect (0% delta), confirm the baseline was not regenerated against the new output. The baselines committed under `SnapshotTests/` must predate the implementer's commits — verify with `git log <baseline>.png`.
- **Default-detection is the make-or-break invariant.** Reading the visit methods to confirm the `?? nil` / `== default ? nil` pattern is more reliable than the specs alone, because a spec can be wrong. Spend extra inspection time here (check I12).
- **Liquid Glass V6 may be partly unverifiable** if you do not have an iOS 26 simulator. If so, mark the iOS 26 sub-check `blocked: true` with a clear note; the team lead may dispatch a re-run from a host that has the simulator. Do not skip the check entirely.
- **Do not consult previous gate reports for this phase.** Independence rule per `validation_criteria.md`.
- **If a check is ambiguous, fail closed.** Mark `passed: false` with a note explaining the ambiguity. The team lead will adjudicate.
