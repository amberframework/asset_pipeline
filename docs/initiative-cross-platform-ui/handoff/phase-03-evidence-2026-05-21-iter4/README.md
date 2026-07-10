# Phase 3 — Validator iter 4 evidence — 2026-05-21

**Iteration:** 4 (re-run after owner provisioned env per decision II)
**Verdict:** FAIL (29 of 49 required checks pass)
**Branch:** `phase-03-swiftui-native-bridge` at HEAD `1c43f94`

## Environment verification
- `crystal-alpha --version` → Crystal 1.20.0-dev (2026-02-18) at `/opt/homebrew/bin/crystal-alpha` (symlink to acrystal). Confirmed.
- iOS 26.3 iPhone 17 Pro simulator (UDID `A517D070-5008-4577-B7B0-B6914D11B391`) — booted, app installed and launched.
- macOS sample `bin/hig_showcase` — built (5.7MB, code-signed), runs and produces screenshots.

## Headline counts
- **Build:** 9/9 required pass (incl. B9 architect-precedent PASS per Phase 1 #17)
- **Inspection:** 12/12 required pass (incl. 4 carry-forward architect adjudications)
- **Behavior (BX):** 2/12 required pass (BX11 spec-runnable + structural; BX12 partially observed via clean launches but marked blocked on strict log-stream criterion)
- **Visual (V):** 0/9 required pass
- **Spec (S):** 7/7 required pass

Optional: I13 pass, V9 blocked.

## Root cause of 22 FAILs

**All 22 FAILs share a single root cause: the rubric requires named slugs that do not exist in the sample sources.**

The Phase 3 validation rubric drives BX1-BX12 and V1-V8 (V9, V10) by launching the iOS/macOS sample binaries with HIG_SLUG values like `phase-03-action-tap-probe`, `phase-03-button-default`, `phase-03-toggle-value-probe`, etc. — twelve distinct probe slug names listed in `inspections/BX-V-probe-gap.log`.

A `grep -rEn 'phase-03-(action-tap-probe|...)' samples/ src/ spec/` returns zero matches. The implementer never authored the probe scenes, the matching XCUITest target on the iOS side, or the AXTest specs on the macOS side. The Swift package's in-process snapshot tests (`SnapshotTests.swift`) DO cover the equivalent button/toggle/glass scenarios and all 5 baselines are committed — but the live-sample capture path is unimplemented.

Per orchestrator directive, the validator does not author code under `src/`, `swift/`, or `samples/`, so the validator cannot close this gap by adding the probe slugs.

## Env-provisioning successfully closed iter-3 build blocks

The 3 iter-3 build blocks (B4, B5, B9) split as follows in iter 4:
- **B4** (iOS sample) — closed by env provisioning; iOS app built and launched.
- **B5** (macOS sample) — closed by env provisioning; macOS binary built, signed, and runs.
- **B9** (Android crystal build) — still blocked by Linux-only `c/sys/epoll` header on darwin; this is a Crystal toolchain limitation, not a Phase 3 regression. PASS per Phase 1 #17 architect-precedent adjudication.

## Architect-attention items

1. **The substance gap is real.** Iter-3's framing of the BX/V failures as purely env-blocking was incomplete; the env-block was true but it masked the deeper issue: the probe slugs were never authored. With env now present, the substance gap is the binding constraint.

2. **Two viable architect paths:**
   - **(a) Remediation dispatch** — task an implementer to author the 12 probe slugs in the iOS host + macOS hig_showcase + corresponding XCUITest target + AXTest specs. Visual baselines come along with them.
   - **(b) Phase 7 deferral** — adopt iter-3's architect recommendation: treat the 38 Swift tests + 104 Crystal swiftkit specs + structural inspection + per-widget overrides spec coverage as sufficient evidence for Phase 3, and defer live-sample behavior probes to Phase 7 (visual-regression automation). This is consistent with Phase 1 #19/#20 and Phase 2 #19/#20 precedents.

3. **Empirical signal that the bridge actually works:** both sample binaries launch without crashes (no `EXC_BAD_ACCESS`, no `dyld: missing symbol`) and produce rendered output. macOS hig_showcase renders 5 distinct existing slugs successfully; iOS CrystalHIGHost.app launches on UDID A517D070. The trampoline-install-order invariant (BX12's underlying concern) is empirically validated even though the rubric's strict os_log assertion can't run.

## Evidence layout
- `gate-report.json` — full structured report (51 check objects)
- `build_logs/` — B1-B5, B8, B9 logs + B4 deps log
- `test_output/` — B6 (Crystal spec), B7 (Swift test), S1-S7, BX11
- `inspections/` — I1-I13 + the BX/V probe-gap analysis
- `samples/` — launched-binary screenshots (macOS 5 slugs + iOS launch) + macos-launch.log
- `behavior/` — empty (no probe slugs to drive against)
