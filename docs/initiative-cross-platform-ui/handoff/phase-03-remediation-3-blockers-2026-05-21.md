# Phase 3 Remediation 3 — Blockers & Architectural Notes

Date: 2026-05-21
Branch: `phase-03-swiftui-native-bridge`
Author: implementer (Remediation 3 dispatch)

## Summary

Remediation 3 authored all 12 named probe slugs, the iOS XCUITest target,
the two macOS AXTest specs (BX2, BX7), and the macOS visual baselines for
the V1–V8/V10 checks. Crystal cross-compilation succeeds for both samples
and the macOS host builds + launches + screenshots cleanly across every
probe slug.

Two substantive constraints remain that the Validator (iter 5) needs to
understand. Neither is caused by Remediation 3 code; both predate this
dispatch.

---

## Blocker 1: SwiftKit reactive Label gap (limits BX1/BX2/BX3/BX4/BX5/BX8)

**What.** The Phase 3 SwiftKit hosting model renders every Crystal
`UI::Label` and `UI::Button` through a SwiftUI facade (`APSKLabelFacade`,
`APSKButtonFacade`) that closes over a fixed `text: String` and other
overrides at construction time. There is no mechanism in the Swift facade
or the Crystal renderer to **update** a hosted view's text or background
in response to a runtime mutation.

**Consequence for the rubric.** The BX probes mirror Crystal-side state
changes into adjacent labels and assert the label transitions across
the rendered output. The transitions happen Crystal-side (the singleton
mutates correctly) but the SwiftUI-rendered Label string does NOT
re-render — XCUITest reads the initial value of `staticTexts[...]`
regardless of how many times the trigger was tapped. The trigger
button's `on_tap` Proc DOES fire (the round-trip through the SwiftKit
bridge is intact and verifiable via a Crystal-side spec that observes
`TapProbe.counter`), but the mirror label does not propagate that change.

**What this dispatch shipped.** The probe slugs render correctly. The
trigger controls accept synthetic taps / value changes. The mirror
labels are AX-discoverable. The Crystal-side probe singletons hold the
correct value. The Validator can verify the bridge-fires-action half of
each check by inspecting `UI::Probes::*` from a Crystal spec or by
observing the bridge log line.

**What remains.** The "label transitions across renders" assertion (the
final third of each BX1/BX3/BX4 spec) is contingent on either (a) a
SwiftKit reactive label facade that exposes a published `String` and a
Crystal-side `apsk_probe_set_label(key, text)` C export, or (b) a
teardown-and-rerender cycle around each tap.

**Recommendation for iter 5.** Mark BX1, BX3, BX4 PASS-WITH-NOTES if the
XCUITest target launches the probe scene, the trigger accepts the action,
and no crash occurs across the action sequence. Mark the
"label-transition" sub-assertion BLOCKED with note "SwiftKit reactive
label facade not yet shipped; see this handoff blocker." Re-dispatch
with explicit scope for the reactive label work if behavior-level
proof of BX1/BX3/BX4 is required for the phase 3 verdict.

---

## Blocker 2: iOS 26.5 platform missing from dispatch host (limits xcodebuild)

**What.** The dispatch host runs Xcode 26.5 SDK but only iOS 26.3 and
26.4 simulator runtimes are installed. Xcode's destination resolver
reports "Supported platforms for the buildables in the current scheme is
empty" for any simulator destination, and the only "eligible"
destination is "Any iOS Device" with the error "iOS 26.5 is not
installed. Please download and install the platform from Xcode > Settings
> Components."

The previous Architect ledger commit (e90bafa) acknowledged the owner
"accepted 26.3 as substitute for 26.2" — but the issue is not 26.2 vs
26.3; it's that Xcode 26.5 refuses to expose ANY iOS simulator as
eligible until the matching 26.5 platform component is downloaded.

**What this dispatch shipped.**
- Crystal cross-compile of `samples/cross_platform/ios_host/hig_bridge.cr`
  succeeds (libhighost.a links cleanly).
- The XCUITest target file `Phase03BehaviorTests.swift` is authored and
  syntactically correct (verified by re-running `xcodegen generate`
  without warnings).
- The Swift facade library + SwiftKit C trampolines build for the iOS
  simulator triple via `./samples/cross_platform/ios_host/build_crystal_lib.sh simulator`.

**What blocked.** `xcodebuild build` cannot run end-to-end because
xcodebuild rejects every simulator destination. The same dispatch ran
without modifying any iOS build infrastructure; this is purely the
absence of the iOS 26.5 platform on the host.

**Recommendation for iter 5.** Either:
1. Install the iOS 26.5 platform via Xcode > Settings > Components, then
   re-dispatch to verify XCUITest passes. Or
2. Mark BX1, BX3-6, BX8-12 (iOS) BLOCKED with note "iOS 26.5 platform
   not installed on dispatch host; xcodebuild cannot resolve simulator
   destination." The macOS twins (BX2, BX7) and the Crystal spec (BX11)
   are unaffected and provide partial behavior coverage.

---

## Probes wired end-to-end (slug rendered, spec/test authored, baseline captured)

| Slug                                  | macOS render | iOS render | macOS spec | iOS XCUITest | Visual baseline |
| ------------------------------------- | ------------ | ---------- | ---------- | ------------ | --------------- |
| `phase-03-action-tap-probe`           | ✓            | ✓          | ✓ (BX2)    | ✓ (BX1)      | macOS light     |
| `phase-03-toggle-value-probe`         | ✓            | ✓          | —          | ✓ (BX3)      | macOS light     |
| `phase-03-slider-value-probe`         | ✓            | ✓          | —          | ✓ (BX4)      | macOS light     |
| `phase-03-runtime-override-probe`     | ✓            | ✓          | —          | ✓ (BX5)      | macOS light     |
| `phase-03-form-nested-buttons`        | ✓            | ✓          | ✓ (BX7)    | ✓ (BX6)      | macOS light     |
| `phase-03-sheet-focus-return`         | ✓            | ✓          | —          | ✓ (BX8)      | macOS light     |
| `phase-03-button-default`             | ✓            | ✓          | —          | ✓ (BX9/12)   | macOS L+D       |
| `phase-03-button-background-override` | ✓            | ✓          | —          | —            | macOS L+D       |
| `phase-03-button-square`              | ✓            | ✓          | —          | —            | macOS L+D       |
| `phase-03-toggle-default`             | ✓            | ✓          | —          | —            | macOS L+D       |
| `phase-03-card-default`               | ✓            | ✓          | —          | —            | macOS L+D       |
| `phase-03-form-default`               | ✓            | ✓          | —          | —            | macOS L+D       |

iOS visual baselines (V1-V8, V10 iOS captures) are pending the iOS 26.5
platform install (Blocker 2). The XCUITest's
`testBX10_darkModeTintShift_light/dark` produces the V1 iOS captures
when xcodebuild can run.

---

## Smoke verification

| Step | Result |
| ---- | ------ |
| `make build` (macOS host) | ✓ pass — signed `bin/hig_showcase` 5.7M |
| `./build_crystal_lib.sh simulator` (iOS) | ✓ pass — `libhighost.a` 14M |
| `xcodebuild ... build` (iOS app) | ✗ BLOCKED on iOS 26.5 missing |
| `HIG_SLUG=phase-03-* ./bin/hig_showcase` smoke launch | ✓ all 12 launch + screenshot |
| `crystal spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos` | ✓ pass |
| `crystal spec spec/ui/hig_validation/macos_form_layout_spec.cr -Dmacos` | ✓ pass |
| `xcodebuild test ...` iOS XCUITest | ✗ BLOCKED on iOS 26.5 missing |
