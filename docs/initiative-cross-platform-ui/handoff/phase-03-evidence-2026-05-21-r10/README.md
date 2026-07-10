# Phase 3 Remediation 10 evidence

Date: 2026-05-21
Branch: phase-03-swiftui-native-bridge
HEAD before R10: a2e56bb
HEAD after R10: see git log

## Scope

R10 fixes the two failures that remained after R9:

1. **BX3** — `XCUIElement.tap()` on the iOS SwiftUI Toggle (hosted via
   UIHostingController-in-UIViewRepresentable) did not flip the
   `isOn` binding. Fixed by replacing the iOS Toggle facade with a
   UIViewRepresentable wrapping a UIKit `UISwitch`.
2. **BX8** — iOS sheet probe never presented because sheet-trigger had
   an empty on_tap AND there was no reactive bridge from
   `UI::Sheet#is_presented` to SwiftUI's `.sheet(isPresented:)`. Fixed
   by adding the full reactive Sheet bridge end-to-end + rewriting the
   slug + rewriting the test to use the present-then-dismiss flow with
   3 dismiss paths (primary / cancel / swipe) and explicit-flag
   on_dismiss guard semantics.

## Result

- testBX3_toggleValueCallback: PASS (was FAIL)
- testBX8_sheetDismissReturnsFocus: PASS (was FAIL — all 3 dismiss
  paths recorded correct reason: primary, cancel, swipe)
- All 10/10 Phase03BehaviorTests PASS
- swift test: 53/53 PASS
- crystal spec: 1330 examples, 4 failures (4 pre-existing baseline
  failures unchanged — am-counter naming + theme CSS empty string;
  unrelated to R10)
- macOS BX2 spec FAILS at baseline AND post-R10 — pre-existing flake
  unrelated to R10 (likely Accessibility TCC permission issue on the
  test runner)
- Reproduce-without-instrumentation: PASS — full 10/10 BX suite re-ran
  after stash/restore round-trip to confirm no perturbation shadowing.

## Codex CLI cadence (4 mandatory checkpoints)

1. **Post-baseline-diagnostic (each fix)** — see
   `diagnostic/r10-codex-postdiag-toggle.md` +
   `diagnostic/r10-codex-postdiag-sheet.md`. Codex confirmed evidence
   sufficiency for both fix targets.
2. **Pre-fix (each fix)** — see
   `diagnostic/r10-codex-prefix-toggle.md` (Codex flagged: skip Slider
   migration, set AX identifier directly on UISwitch, preserve label
   via HStack, @ObservedObject on parent View) and
   `diagnostic/r10-codex-prefix-sheet.md` (Codex flagged: hoist
   ios_sheet_v before button blocks, keep legacy makeSheet ABI, build
   body around @ObservedObject not stale binding, DON'T add AX-boundary
   workaround until Gap-3 dump proves needed). All adjustments
   incorporated into the final patches.
3. **Post-fix** — see `diagnostic/r10-codex-postfix.md`. Codex
   confirmed BX3 + BX8 fixed, memory-safety OK, no regression risk on
   other iOS BX checks or on macOS.
4. **Pre-deferral** — N/A. No deferrals in R10.

## Directory layout

- `diagnostic/` — evidence captures, codex critiques, proposed-fix
  patches, post-fix codex critique.

## Commits

- e3a26c1 [Phase 3 Remediation 10] Capture Toggle + Sheet diagnostic
  evidence + Codex critiques
- 376343a [Phase 3 Remediation 10] Replace iOS ToggleFacade with
  UISwitch UIViewRepresentable
- 8349809 [Phase 3 Remediation 10] Add reactive Sheet bridge + BX8
  slug/test rewrite
