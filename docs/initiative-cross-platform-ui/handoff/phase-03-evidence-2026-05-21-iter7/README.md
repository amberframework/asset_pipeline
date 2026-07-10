# Phase 3 — Validator iter 7 evidence

- Date: 2026-05-21
- Branch: phase-03-swiftui-native-bridge
- HEAD: bfd129d ([Phase 3 Remediation 10] Add post-fix Codex critique + R10 evidence README)
- Verdict: PASS (49/49 required checks)

## Headline numbers

- Build (B1-B9): 9/9 PASS
- Inspection (I1-I12 required, I13 optional): 12/12 required PASS
- Behavior (BX1-BX12): 12/12 PASS — including the load-bearing reactive
  invariants BX1 (button-tap iOS), BX2 (button-tap macOS), BX3 (toggle iOS),
  BX5 (override-rerender iOS), BX8 (sheet dismiss-returns-focus iOS).
- Visual (V1-V8 + V10 required, V9 optional): 9/9 required PASS
- Spec (S1-S7): 7/7 PASS

## Key reactive empirical results

- BX1 iOS button-tap counter transitions: ["0", "1", "2", "3"]
- BX2 macOS button-tap counter: 1 example, 0 failures, AXPress drove "0" -> "1" -> "2" -> "3"
- BX3 iOS toggle (R10 UISwitch UIViewRepresentable): switch+probe transitions
  `[("0","false"),("1","true"),("0","false")]`
- BX5 iOS override-rerender: before_state "transparent" -> after_state "red"
  via reactive bridge mutation
- BX8 iOS sheet dismiss: 3 paths each pass — primary/cancel/swipe — each
  records correct dismiss-reason ("primary"/"cancel"/"swipe") via reactive
  Sheet bridge added in R10 commits 8349809 + 376343a.

## Carryovers (architect-binding from prior iters)

- I4 typed-fun primitive supersedes raw objc_send (iter 2/3/4/5)
- I10 renderer-internal install supersedes per-sample (iter 2/3/4/5)
- S2 toggle coverage in group1_overrides_spec (iter 4)
- S3 default-detection across per-widget specs (iter 4)
- S5 OverridesPropagationTests per-widget structure (iter 4)
- I12 default-nil propagation via populator guards (iter 2/3/4/5)
- B9 Android cross-compile fail on darwin per Phase 1 #17 precedent

## Directory layout

- build_logs/      B1-B5, B8, B9 build outputs
- test_output/     B6, B7, BX2, BX7, BX11, BX12, S1-S7, Phase03BehaviorTests-full.log
- inspections/     I1-I13 grep outputs, BX1/BX3/BX4/BX5/BX6/BX8/BX9 transition JSON, BX10 ΔE log, S6 baseline inventory
- screenshots/     iOS V1 (light/dark) + BX1/BX3/BX4/BX5/BX6/BX8/BX9 attached captures; macOS V2-V8 light/dark
- xcresult-export/ raw xcresulttool exports (attachments + manifest.json)
