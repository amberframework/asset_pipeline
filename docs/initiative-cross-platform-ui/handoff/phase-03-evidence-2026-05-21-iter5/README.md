# Phase 3 Validator iter 5 evidence

Date: 2026-05-21
Branch: phase-03-swiftui-native-bridge
HEAD: 2a431e5

## Directory layout
- build_logs/ — B1-B5/B7/B8/B9 build outputs + cross-deps-ios.log + macos-visual-capture.log
- test_output/ — B6 (Crystal spec), B7 (Swift test), S1-S7, BX2, BX7, BX11, ios_xcuitest.log
- inspections/ — I1-I12, baseline content audit, visual diff log, BX2 label transitions
- screenshots/ — V1-V8 + V10 captures (macOS); BX2-final.png
- scripts/ — pixel_diff.py, sample_and_dE.py (helpers for the run)
- gate-report.json — the verdict

## Headline findings
- macOS bridge reactive end-to-end EMPIRICALLY PASSES via BX2 (3 taps → label "0"→"1"→"2"→"3").
- BX7 macOS form-layout PASSES.
- iOS XCUITest BLOCKED: Xcode project missing -lswiftkit_simulator + libssl/crypto/z links;
  Remediation 4's new apsk_button_set_* symbols are unresolved at iOS app link time.
- macOS visual baselines (committed Remediation 3) and the new iter-5 captures both produce
  uniform-color blank PNGs for 14 of 24 slugs due to the offscreen capture fallback
  (Screen Recording TCC not granted to terminal). Pixel-diff against the baseline passes
  at 0% but is substantively meaningless for these slugs. The 6 NON-blank captures
  (background-override, card-default, form-default light+dark, slider-value-probe
  light+dark) DO match the baseline at 0% delta.
