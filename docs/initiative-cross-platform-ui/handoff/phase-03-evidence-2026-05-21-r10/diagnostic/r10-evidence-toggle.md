# R10 Part 1 — Toggle hosting-topology evidence

Date: 2026-05-21
Branch: phase-03-swiftui-native-bridge, HEAD a2e56bb
Simulator: iPhone 17 Pro (UDID 92DA97A0-5FEC-46BD-A525-8AFE2A4FDC21, iOS 26.5)

## Baseline reproduction

### testBX3_toggleValueCallback — FAIL (reproduces R9 finding)

xcrun simctl boot UDID; xcodebuild test ... -only-testing CrystalHIGHostUITests/Phase03BehaviorTests/testBX3_toggleValueCallback

Test transcript (key lines):
```
t = 4.97s Checking existence of "toggle-probe-toggle" Switch         ← FOUND
t = 6.04s Checking existence of "toggle-probe-value" StaticText      ← FOUND
t = 6.23s Added attachment 'BX3-toggle-initial.png'
t = 6.23s Tap "toggle-probe-toggle" Switch
t = 6.27s     Synthesize event
t = 6.56s     Wait for com.assetpipeline.hig.CrystalHIGHost to idle
t = 6.82s Find the "toggle-probe-toggle" Switch
t = 6.84s Find the "toggle-probe-value" StaticText
Phase03BehaviorTests.swift:154: error: XCTAssertEqual failed:
  ("Optional("0")") is not equal to ("Optional("1")") - BX3: after tap 1 switch must read "1"
```

Interpretation:
- The switch element is **discoverable** (XCUITest finds it as a `.switches[...]`).
- The mirror StaticText is **present** (Crystal-side text label exists).
- `XCUIElement.tap()` returns without error (no synthesis failure).
- After 250 ms quiescence, switch `.value` reads `"0"` (unchanged from initial).
- The mirror probe label reads `"false"` (unchanged from initial).

**Both** the SwiftUI Toggle's `isOn` AND the Crystal-side `BoolStorage.value`
remained at false. CallbackBridge.fire was never invoked. The R9 evidence
already established this is XCUITest-tap-specific: the same Toggle facade
flips correctly under coordinate taps but not under the
`XCUIElement.tap()`-synthesized accessibility-activate path.

### testBX4_sliderValueCallback — PASS (under .adjust(toNormalizedSliderPosition:))

For contrast: same hosting topology (SwiftUI Slider in
UIViewRepresentable-mounted UIHostingController via SliderDoubleHost), and
the slider DOES update under `XCUIElement.adjust(toNormalizedSliderPosition:)`.

```
slider-probe-value transitions: ≤0.05, ~0.5, ≥0.95 — monotonic, in-band.
TEST SUCCEEDED.
```

This is the key contrast that proves the failure is interaction-routing
specific:
- `.adjust(toNormalizedSliderPosition:)` synthesizes a drag gesture
  (touch-down → touch-move → touch-up). SwiftUI Slider's internal
  DragGesture picks this up correctly.
- `.tap()` on a switch element routes through
  `UIAccessibilityAction.activate`. SwiftUI Toggle(isOn:) hosted via
  UIViewRepresentable doesn't translate the AX-activate into an isOn flip.
  The element is reported as a switch by SwiftUI's AX layer, but the
  activate side-effect doesn't reach the binding.

## Working-vs-failing diff

| Path | Element type | XCUITest call | Result |
|------|--------------|---------------|--------|
| SwiftUI Slider via UIViewRepresentable | `.sliders[…]` | `.adjust(toNormalizedSliderPosition:)` | PASS — fires CallbackBridge, updates probe |
| SwiftUI Toggle via UIViewRepresentable | `.switches[…]` | `.tap()` | FAIL — switch.value stays "0", no callback |
| Same Toggle (R9 evidence, coord-tap)  | n/a — coordinate.tap | coord-based touch | PASS — fires CallbackBridge, flips Crystal state |

## Root cause hypothesis (Codex-reviewable)

The combined evidence proves:
1. The Crystal/Swift callback chain is intact (R9 proved coord taps flip
   isOn end-to-end; BX4 proves drag-style XCUITest events route through
   the SwiftUI binding).
2. The Toggle facade IS exposed as an accessibility switch element (XCUITest
   finds it via `.switches[…]`).
3. `XCUIElement.tap()` on that switch triggers an accessibility-activate
   path, NOT a synthesized touch-down/up. SwiftUI Toggle(isOn:) hosted via
   UIViewRepresentable doesn't translate AX-activate → isOn flip.

The fix the brief proposes (replace ToggleFacade's SwiftUI Toggle with a
UIViewRepresentable wrapping a UIKit `UISwitch`) targets exactly this:
`UISwitch` is the canonical Apple value-bound control with first-class
XCUITest interop. `UISwitch.accessibilityActivate` translates directly to
`setOn:!isOn animated:` and fires `UIControlEventValueChanged` — the
documented Apple behavior XCUITest depends on.

The brief also asks for SliderFacade migration to UISlider. The data above
shows BX4 PASSES today under `.adjust(toNormalizedSliderPosition:)`, so the
Slider migration is parity-with-Toggle / robustness work, not strictly
required to pass an existing test. It will be applied per the brief but the
evidence here shows it is not load-bearing for any failing test today.

## Scope boundary check

- iOS-only change. macOS uses AppKit-side rendering through different
  facades; not in scope.
- BoolStorage / DoubleStorage / CallbackBridge / Crystal-side reactive
  setters all work today (R9 evidence + BX4 evidence).
- Discrete-action controls (Button) work under current hosting; not in
  scope (BX1 passes today).
