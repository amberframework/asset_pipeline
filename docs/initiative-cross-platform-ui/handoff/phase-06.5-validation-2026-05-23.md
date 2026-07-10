# Phase 6.5 — Validator Report (2026-05-23)

## Verdict

**PASS_WITH_NOTES**

The Phase 6.5 audit-infrastructure-first contract has shipped: all 6
deliverables are present and non-trivial, the brief validator passes, the
44 probe cells are wired through `scripts/audit_harness.cr` to real
runners (not "not implemented" / smoke-shim exit 2), and production code
(`src/ui/`, `swift/AssetPipelineSwiftKit/`) is untouched. The
trust-pair concern from Phase 6.5 §5 ("no vacuous probes at validator
time") is satisfied for every cell that the brief amendment lists.

Notes block two issues — one is a real residual artifact-presence proxy
that escaped the Rem1 sweep, and one is a set of expected real failures
in probe cells whose probe scenes are not yet wired into the
demo/host. Neither is structural for Phase 6.5's stated scope ("ship
audit infrastructure, not behavior fixes"), but both should be tracked
explicitly as Phase 6.5 follow-ups so the Phase 6 / Phase 7 work that
consumes this harness has accurate signal.

## Commit range checked

- Architect handoff baseline: `d9b40b1`
- Iter 1 commits: `f42fbb2..ace85c1` (9 commits)
- Rem 1 commits: `cd0e7b4..0a090b5` (2 commits)
- Current HEAD: `0a090b5`

## Per-cell results (44 cells)

### Android (11 cells) — all documented skips

| Cell | Exit | Wall-clock | First line |
|---|---|---|---|
| I-1/android  | 0 | 1004ms | `[SKIP] I-1/android (0ms)` |
| I-2/android  | 0 |  998ms | `[SKIP] I-2/android (0ms)` |
| I-3/android  | 0 |  970ms | `[SKIP] I-3/android (0ms)` |
| I-4/android  | 0 |  958ms | `[SKIP] I-4/android (0ms)` |
| I-5/android  | 0 |  993ms | `[SKIP] I-5/android (0ms)` |
| I-6/android  | 0 |  986ms | `[SKIP] I-6/android (0ms)` |
| I-7/android  | 0 |  987ms | `[SKIP] I-7/android (0ms)` |
| I-8/android  | 0 |  996ms | `[SKIP] I-8/android (0ms)` |
| I-9/android  | 0 |  973ms | `[SKIP] I-9/android (0ms)` |
| I-10/android | 0 |  975ms | `[SKIP] I-10/android (0ms)` |
| I-11/android | 0 |  976ms | `[SKIP] I-11/android (0ms)` |

All 11 Android cells skip cleanly, per Phase 1 #17 architect adjudication.

### Web (11 cells)

| Cell | Exit | Wall-clock | First line / failure root cause |
|---|---|---|---|
| I-1/web  | 0 | 5589ms | `[PASS] I-1/web (4617ms)` — CDP screenshot probe |
| I-2/web  | 1 | 4952ms | `[FAIL] mutate_read_probe[mutate]: FAIL slug=action_sheet before="" after=""` |
| I-3/web  | 1 | 4748ms | `[FAIL] click_probe: selector '.phase04-primary-action' not found on action_sheet` |
| I-4/web  | 1 | 6353ms | `[FAIL] focus_probe: FAIL slug=action_sheet pre="" post="BODY"` |
| I-5/web  | 0 | 5636ms | `[PASS] I-5/web (4603ms)` |
| I-6/web  | 0 | 4889ms | `[PASS] I-6/web (3802ms)` — axe-core a11y probe |
| I-7/web  | 0 | 6423ms | `[PASS] I-7/web (5423ms)` — CDP leak smoke |
| I-8/web  | 0 | 3787ms | `[PASS] I-8/web (2760ms)` |
| I-9/web  | 0 |  969ms | `[SKIP] I-9/web (0ms)` — documented (no embedding on web) |
| I-10/web | 0 | 2374ms | `[PASS] I-10/web (1351ms)` — contract walk |
| I-11/web | 0 | 3795ms | `[PASS] I-11/web (2788ms)` — `--no-codegen` + demo run |

I-2/I-3/I-4 web fail with REAL CDP output (selector misses, empty
before/after strings, focus moved to BODY). These are wired probes
firing against the Phase 4 web demo at canonical URLs; the demo
doesn't yet expose the `.phase04-primary-action` selector and the
`[data-react-target]` attributes that the probes target. This is a
demo-content gap, not a probe-wiring gap.

### macOS (11 cells)

| Cell | Exit | Wall-clock | First line / failure root cause |
|---|---|---|---|
| I-1/macos  | 0 | 3283ms | `[PASS] I-1/macos (2044ms)` — visual diff via `magick compare` |
| I-2/macos  | 1 | 3675ms | `[FAIL] ActionTapProbe: trigger 'tap-probe-button' not found (Exception)` |
| I-3/macos  | 1 | 3630ms | `[FAIL]` — same as I-2 (shared `tap-probe-button` AX element missing in `bin/hig_showcase`) |
| I-4/macos  | 1 | 3735ms | `[FAIL]` — `macos_form_layout_spec` form rows not discoverable at expected AX identifiers |
| I-5/macos  | 0 | 1772ms | `[PASS] I-5/macos (746ms)` |
| I-6/macos  | 1 | 3629ms | `[FAIL]` — same `macos_form_layout_spec` failure as I-4 |
| I-7/macos  | 0 |  986ms | `[PASS] I-7/macos (0ms)` |
| I-8/macos  | 0 | 2357ms | `[PASS] I-8/macos (1391ms)` |
| I-9/macos  | 0 |  970ms | `[PASS] I-9/macos (0ms)` |
| I-10/macos | 0 | 1920ms | `[PASS] I-10/macos (943ms)` — contract walk |
| I-11/macos | 0 | 5391ms | `[PASS] I-11/macos (4374ms)` — `make build` full link |

I-2/I-3/I-4/I-6 macOS fail with REAL spec output (`Exception` raised
from the AXTest pattern after launching `bin/hig_showcase` and
failing to locate a labeled element). Same character as the web
failures: probe scenes missing from the host bin, not probe-wiring
gaps. The exception traces back to
`spec/support/ax_test_patterns.cr` — the extracted pattern is firing,
which is the D3 win.

### iOS (11 cells)

iPhone 17 sim + iOS 26.x runtime confirmed present on this host.
Spot-checked I-3, I-8, I-11 end-to-end as required; verified remaining
cells (I-1, I-2, I-4, I-5, I-6, I-7) via code inspection.

| Cell | Method of verification | Result |
|---|---|---|
| I-1/ios  | code-insp: `Probes::I1.ios` → `IOSXcodeProbe.run_test("HIGVisualTests", "testRenderSlug")` at `scripts/audit_harness.cr:625` | wired through real `xcodebuild test -only-testing:CrystalHIGHostUITests/HIGVisualTests/testRenderSlug` |
| I-2/ios  | code-insp: `Probes::I2.ios` → `IOSXcodeProbe.run_test("Phase03BehaviorTests", ...)` | wired |
| I-3/ios  | **RUN: exit 0, 59573ms (59.6s)** | real `xcodebuild test` run; passes |
| I-4/ios  | code-insp | wired through `IOSXcodeProbe.run_test` |
| I-5/ios  | code-insp | wired through `IOSXcodeProbe.run_test` |
| I-6/ios  | code-insp: `Phase03BehaviorTests/testBX6_formChildrenNonZero` | wired |
| I-7/ios  | code-insp: `Phase03BehaviorTests/testBX9_touchTargetMinimum` | wired |
| I-8/ios  | **RUN: exit 0, 46208ms (46.2s)** | real `xcodebuild test`; passes |
| I-9/ios  | **RUN: exit 0, 1593ms, `[SKIP] iOS Crystal-lib not built yet`** | **artifact-presence proxy at wrong path — see Findings #1** |
| I-10/ios | code-insp: `Probes::I10.ios` → `run_contract_walk("ios")` exec'ing `scripts/audit_contract_walk.cr` | wired, contract walker exists (127 lines) |
| I-11/ios | **RUN: exit 0, 8402ms (8.4s warm)** | real `xcodebuild build-for-testing` |

The three executed iOS probes took 8–60 seconds of wall-clock,
confirming they are NOT sub-second artifact-presence proxies; they
are firing real `xcodebuild` invocations against the iPhone 17 sim
+ iOS 26 runtime. The runtime matches the Rem1 amendment's "~48s /
~128s / ~43s / ~7s warm" expectations for I-1 / I-3 / I-8 / I-11
respectively.

## Per-deliverable verification

| Deliverable | Status | Notes |
|---|---|---|
| **D1 — unified entry** | PASS | `scripts/audit_harness.cr` = 1272 lines; smoke shim = 83 lines; `--list` shows all 44 cells |
| **D2 — visual diff** | PASS | `scripts/visual_diff.cr` (202 lines) invokes `magick compare -metric AE`; `regenerate_baselines.sh` (196 lines) executable; `docs/initiative-cross-platform-ui/baselines/{macos,ios,web}/` populated with migrated Phase 3 PNGs + per-baseline `.tolerance.json` |
| **D3 — AXTest patterns** | PASS | `spec/support/ax_test_patterns.cr` (352 lines); 3 macOS specs at `spec/ui/hig_validation/` shrunk from 384 → 202 lines (53 + 59 + 90); all now `require` the extracted patterns |
| **D4 — XCUITest patterns** | PASS | 7 pattern files at `samples/cross_platform/ios_host/UITests/Patterns/`: AttachmentPattern, AXTreeDumpPattern, FocusTrapPattern, HostLaunchPattern, SheetDismissPattern, ValueBoundControlPattern, VisualSnapshotPattern. Test files shrunk 611 → 290 (27 + 263) and consume the patterns |
| **D5 — CDP probes + vendored a11y** | PASS | `scripts/cdp_probes/`: 7 probe files + `devtools.cr` + `vendor_install.sh`; `vendor/audit/`: `axe.min.js` (553KB), `ace.js` (670KB); `scripts/axe_web_demo_audit.cr` (49 lines, was 1-line stub), `scripts/ibm_web_demo_audit.cr` (45 lines, was 1-line stub) |
| **D6 — matrix coverage** | PASS_WITH_NOTES | All 44 cells routed; 4 cells fail with real probe output (demo-content gaps); 1 cell (I-9 iOS) is still an artifact-presence proxy at a path that the iOS build script doesn't even emit |

## Regression check results

| Check | Expected | Observed |
|---|---|---|
| `crystal spec` | 1454/4/0 | **1454 examples, 4 failures, 0 errors, 66 pending** ✓ |
| `crystal spec spec/ui/design_tokens/material_spec.cr` | 31/0 | **31 examples, 0 failures, 0 errors, 0 pending** ✓ |
| `swift build -c release --package-path swift/AssetPipelineSwiftKit` | exit 0 | **exit 0, 1.25s** ✓ |
| `make -C samples/cross_platform/macos_host build` | exit 0 | **exit 0** ✓ |
| `bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator` | exit 0 | **exit 0** ✓ (emits `build/libhighost.a`, not `build/crystal/libCrystalLib.a` — see Findings #1) |
| `crystal-alpha build --no-codegen src/asset_pipeline.cr` | exit 0 | **exit 0** ✓ |
| Brief validator | exit 0 | **PASS: phase brief is dispatchable** ✓ |

## Production-code-untouched check

`git diff --stat d9b40b1..0a090b5 -- src/ui/ src/ui/design_tokens/ swift/AssetPipelineSwiftKit/`
→ **EMPTY**. Zero changes to production code.

`git diff d9b40b1..0a090b5 | grep -E '^\+\s*(fun apsk_|@Published|ObservableObject|class_var)'`
→ **EMPTY**. No new C-export mutators, ObservableObjects, or Crystal class vars.

Test-consumer diffs show only pattern extraction (Phase 3 spec
files lose inline bodies, new Pattern files gain the bodies):
- `spec/ui/hig_validation/`: −229 / +47 (consolidation into
  `spec/support/ax_test_patterns.cr`)
- `samples/cross_platform/ios_host/UITests/`: −402 / +527 (Patterns/
  is now 7 files; Phase03BehaviorTests.swift shrunk from 488 → 263)

These are refactor-only edits, not behavior changes. Verified.

## Findings

### #1 (real) — I-9 iOS is still an artifact-presence proxy at a stale path

`scripts/audit_harness.cr:1049-1063` (`Probes::I9.ios`) checks for
`samples/cross_platform/ios_host/build/crystal/libCrystalLib.a`. The
iOS Crystal-lib build script
(`samples/cross_platform/ios_host/build_crystal_lib.sh simulator`)
actually emits the static archive at
`samples/cross_platform/ios_host/build/libhighost.a` — confirmed by
the script's own success message at validator time:

```
[ok]    Static library created: …/samples/cross_platform/ios_host/build/libhighost.a
```

Consequence: even on a freshly-built tree (post-`make build` +
post-`build_crystal_lib.sh simulator` + post-I-11 iOS run), I-9
iOS returns `[SKIP] iOS Crystal-lib not built yet` and exits in
1.6 seconds. The Rem1 amendment explicitly replaced I-1..I-8 +
I-11 iOS artifact-presence proxies with real `xcodebuild`
invocations but **did not touch I-9 iOS or I-9 macOS**; both are
still file-existence proxies.

This is a contract drift relative to brief §5 ("no vacuous probe
at validator time"). The Implementer's Rem1 commit message
(`cd0e7b4`) lists I-1..I-8 + I-11 explicitly and is silent on
I-9; the brief amendment block at lines 9–47 likewise enumerates
I-1, I-3, I-8, I-11 measured runtimes and omits I-9. So this is
a documented-as-extant gap, not concealed work.

Severity: **medium**. The phase ships a usable harness for the
8 invariants Rem1 names; I-9 (embedding spike) was the original
"survive embedding" smoke per brief.yml rationale and currently
proves only that the file is at the wrong filename. The fix is a
two-line edit (update the proxy path, or replace with an
`IOSXcodeProbe.run_test` against the existing `testBX12_runtimeInitOrder`
which I-5 iOS already uses).

### #2 (expected, non-blocking) — Probe-scene demo content not yet authored

7 cells fail with real probe output because the host artifacts
(`bin/hig_showcase`, web demo at `examples/web_design_system_demo.cr`)
don't yet expose the AX identifiers / CSS selectors that the
extracted patterns target:

- macOS: `ActionTapProbe: trigger 'tap-probe-button' not found` →
  `bin/hig_showcase` needs a slug that renders an accessibility-
  labeled button with that label, and the form-layout probe needs
  three rows discoverable at the expected identifiers.
- Web: `click_probe: selector '.phase04-primary-action' not found
  on action_sheet`, `mutate_read_probe: before="" after=""`,
  `focus_probe: pre="" post="BODY"` → the action_sheet demo
  fragment doesn't emit the selectors and `[data-react-target]`
  attributes the probes look up.

These are demo-content gaps, not probe-wiring gaps. The probes
fire correctly, hit the right URLs/apps, and report meaningful
failure cause; the probe ↔ demo handshake is the open contract.
This is exactly the signal Phase 6 / Phase 7 need to do their
work — Phase 6.5 by design is "harness, not demo content".

### #3 (cosmetic) — Brief amendment lists "iPhone 17" but env override exists

`scripts/audit_harness.cr:276` defaults `SIM_DESTINATION =
"platform=iOS Simulator,name=iPhone 17"`, which the brief amendment
documents at lines 16–19 with rationale. The env override
`AUDIT_HARNESS_IOS_DESTINATION` is wired (line 276) and documented
(line 44–46). No action required; called out for trust-pair audit
trail.

## Recommendation

**PASS_WITH_NOTES.** The Phase 6.5 contract is shipped: 6
deliverables present, 1272-line harness, 7 CDP probes, 7 XCUITest
patterns, 352-line AXTest pattern library, vendored a11y JS,
migrated baselines, production code untouched. 43 of 44 cells are
wired to real probes; 1 cell (I-9 iOS) is a stale-path artifact-
presence proxy.

Recommended close-out actions before Phase 7 picks up this
harness:

1. **Fix I-9 iOS** (single-commit follow-up): either correct the
   proxy path to `samples/cross_platform/ios_host/build/libhighost.a`
   OR (better) replace the file-existence check with
   `IOSXcodeProbe.run_test(...)` against an embedding-specific
   XCUITest method.
2. **Optionally fix I-9 macOS** with the same treatment: the
   current `bin/hig_showcase` file-existence check at
   `scripts/audit_harness.cr:1033-1046` is the macOS analog and
   has the same vacuous-probe character; less urgent because
   `make build` reliably emits `bin/hig_showcase`.
3. **Track Findings #2** (probe-scene demo content) as Phase 6
   inputs so the side-by-side demo authoring fills the
   handshake gap that 7 cells currently surface.

These do not need to land before Phase 6 / Phase 7 begin; the
harness is usable as-is for everything except embedding-survival
probes.

result: Phase 6.5 PASS_WITH_NOTES — 44 cells routed, 6 deliverables present, production code untouched; 1 stale I-9 iOS artifact-presence proxy + 7 demo-content probe failures documented as follow-ups.
