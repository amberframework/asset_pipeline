# Phase 3 — Validator iter 6 evidence

Branch: phase-03-swiftui-native-bridge @ 90a2d54
Date: 2026-05-21
Verdict: FAIL (see gate-report.json)

## Headline numbers

- 49 required checks: 42 passed / 7 failed (5 iOS BX + 0 macOS BX + 0 structural)
- The 3 load-bearing reactive invariants BX1 / BX2 / BX5: **all PASS**.
- The 5 iOS BX failures (BX3, BX4, BX6, BX8, BX9) are integration-level bugs in SwiftUI-hosting-frame layout (BX6/BX9), UIHostingController hit-test propagation (BX3), Crystal probe formatting (BX4 crash), and NULL-string-pointer reaching apsk_nsstring (BX8 crash).

## Layout

- build_logs/     — B1-B5, B8-B9 build outputs; V-macos-captures.log
- test_output/    — B6, B7, S1-S7, BX1-BX12, xcuitest-full.log, xcuitest-summary.log
- inspections/    — I1-I13, I3-facade-call-matrix, BX1/BX5/BX10 metrics, BX6/BX9 frames
- screenshots/    — iOS V1 light/dark, BX1 counter, BX5 before/after, macOS V baselines (degenerate due to TCC), xcuitest-attachments/ raw export
- crash_logs/     — BX4 + BX8 crash IPS bundles + CRASH_SUMMARY.md
- behavior/       — (unused this iter)

## Critical observations

1. **BX4 root cause is mischaracterised in the implementer's claim.** The implementer reported BX4 as "same UIHostingController hit-test gap as BX3." It is not. BX4 crashes in `Float::Printer::RyuPrintf::d2fixed_buffered_n` before any tap is dispatched — a Crystal-side sprintf failure inside `UI::Probes::SliderProbe::formatted`. See crash_logs/BX4-slider-crash.ips and crash_logs/CRASH_SUMMARY.md.

2. **BX8 crash root cause is `apsk_nsstring` strlen on NULL.** A NULL C string pointer reaches `apsk_nsstring` when rendering one of the Labels in `phase-03-sheet-focus-return`. Integration bug in the Crystal -> ObjC string conversion path. See crash_logs/BX8-sheet-crash.ips.

3. **macOS V baselines are degenerate (all-black PNGs at 2400x1800).** Per the task brief, this is the Screen Recording TCC issue (Terminal lacks Screen Recording entitlement). Not a Phase 3 substance failure — the Swift Snapshot Tests (S6) cover these baselines authoritatively.

4. **BX1, BX2, BX5 are the headline reactive-bridge invariants and all PASS empirically.** The trampoline + reactive label mutator chain works end-to-end on iOS (BX1: "0"->"1"->"2"->"3") and macOS (BX2: "0"->"1"->"2"->"3"), and a runtime background-color override propagates to SwiftUI with a visible color shift (BX5: before transparent/brown -> after red, label transitions "transparent"->"red").
