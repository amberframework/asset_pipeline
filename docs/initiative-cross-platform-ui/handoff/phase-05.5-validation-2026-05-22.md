# Phase 5.5 — Validator Report (2026-05-22)

## Verdict

**PASS**

All 9 README acceptance items pass. Brief validator passes (exit 0). The
Implementer's single commit `b6875b9` is deletion-only (0 insertions, 1465
deletions) and confined to the two renderer files named in scope. Phase 5 v2
surfaces (`swift/`, `src/ui/design_tokens/`, `src/ui/views/`) are completely
untouched. The full `crystal spec` run lands exactly on the Phase 5 v2
close-out baseline (1454 examples, 4 failures, 0 errors) and the four failure
sites match the allowlist verbatim. No regression detected.

## Commit range checked

- Baseline (architect handoff): `10ae763`
- Implementer commit (atomic deletion): `b6875b9` — "[Phase 5.5] Delete 12 _legacy_* dead-code methods from both renderers"
- Brief amendment (facts → post-impl state): `be04dae` — "[Phase 5.5] Brief amendment: facts capture post-cleanup state at b6875b9"
- Current HEAD: `be04dae`
- Branch: `phase-05.5-appkit-legacy-cleanup`

## 9 acceptance items

| # | Command | Expected | Actual | Verdict |
|---|---------|----------|--------|---------|
| 1 | `grep -cE '_legacy_(tab_view\|alert\|navigation_split_view\|toolbar\|sheet\|popover)' src/ui/renderers/appkit_renderer.cr` | `0` | `0` | PASS |
| 2 | `grep -cE '_legacy_(tab_view\|alert\|navigation_split_view\|toolbar\|sheet\|popover)' src/ui/renderers/uikit_renderer.cr` | `0` | `0` | PASS |
| 3 | `grep -cE 'apsk_make_(tab_view\|alert\|navigation_split_view\|toolbar\|sheet\|popover)' src/ui/renderers/appkit_renderer.cr` | `6` | `6` | PASS |
| 4 | `grep -cE 'apsk_make_(tab_view\|alert\|navigation_split_view\|toolbar\|sheet_reactive\|popover)' src/ui/renderers/uikit_renderer.cr` | `6` | `6` | PASS |
| 5 | `make -C samples/cross_platform/macos_host build` | exit 0 | exit 0 (signed `bin/hig_showcase`) | PASS |
| 6 | `bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator` | exit 0 | exit 0 (`libhighost.a` produced) | PASS |
| 7 | `crystal-alpha build --no-codegen src/asset_pipeline.cr` | exit 0 | exit 0 | PASS |
| 8 | `crystal spec` | 1454 examples / 4 failures / 0 errors at allowlisted sites | 1454 examples / 4 failures / 0 errors at exactly `views_spec.cr:3273`, `phase2_verification_spec.cr:52`, `:116`, `:129` | PASS |
| 9 | `crystal spec spec/ui/design_tokens/material_spec.cr` | 31 examples / 0 failures | `31 examples, 0 failures, 0 errors, 0 pending` | PASS |

Notes:
- Acceptance #5 succeeded without needing the documented Swift-package
  pre-build workaround; the macOS host's Makefile already invokes
  `swift build -c release` as its first step.
- Acceptance #8 took 9.73 s wall and reported `66 pending` (non-blocking).
- The 4 acceptance #8 failures match the Phase 5 v2 close-out allowlist:
  - `crystal spec spec/ui/views_spec.cr:3273` — UI::Theme web renderer inject_theme_css returns empty string with no theme.
  - `crystal spec spec/components/phase2_verification_spec.cr:52` — demonstrates component composition.
  - `crystal spec spec/components/phase2_verification_spec.cr:116` — components can be nested within components.
  - `crystal spec spec/components/phase2_verification_spec.cr:129` — achieves the component system goals.

## Brief validator output

```
$ crystal run scripts/validate_phase_brief.cr -- \
    docs/initiative-cross-platform-ui/phases/phase-05.5-appkit-legacy-cleanup/brief.yml
...
OK: top-level keys all recognized
OK: phase section structure valid
OK: invariant_matrix structure valid (11 rows, all platforms cells present, no placeholders)
Re-running query for fact 'AppKit `_legacy_*` Category B method count (post-cleanup; pre-cleanup was 6)': ok (0)
Re-running query for fact 'UIKit `_legacy_*` Category B method count (post-cleanup; pre-cleanup was 6)': ok (0)
Re-running query for fact 'AppKit Category B facade call-site count (must remain 6 across cleanup — no facade regression)': ok (6)
Re-running query for fact 'UIKit Category B facade call-site count (must remain 6 across cleanup; UIKit uses sheet_reactive)': ok (6)
Re-running query for fact 'Total cross-platform `_legacy_*` Category B method count across both renderers (post-cleanup; pre-cleanup was 12)': ok (0)
OK: repo_derived_facts all match captured values (5 facts)
Running verification for A1: ok
Running verification for A2: ok
Running verification for A3: ok
Running verification for A4: ok
Running verification for A5: ok
Running verification for A6: ok
OK: lower_layer_assumptions all verified (6 assumptions)
OK: adapter_cardinality valid (0 rows; all required fields present; MISMATCH rows have degradation + approval)
OK: pre_dispatch_validation script_path IS this validator — recursive self-run skipped intentionally; we've already verified the brief if we got here.

PASS: phase brief is dispatchable.
EXIT=0
```

The two `File.executable?` deprecation warnings are pre-existing noise in
`scripts/validate_phase_brief.cr` (lines 374 and 378) and are not in scope
for Phase 5.5.

## Diff scope check

Deletion-only on the two renderer files; nothing else touched:

```
$ git diff --shortstat 10ae763 b6875b9 -- src/ui/renderers/
 2 files changed, 1465 deletions(-)

$ git diff --stat 10ae763 b6875b9
 src/ui/renderers/appkit_renderer.cr | 724 ----------------------------------
 src/ui/renderers/uikit_renderer.cr  | 741 ----------------------------------
 2 files changed, 1465 deletions(-)
```

Zero insertions on either renderer — confirms the Implementer made no
collateral edits to satisfy the build closure invariant (I-11). The two
files shrink by exactly the volume needed to remove 12 `private def`
methods with their bodies.

Phase 5 v2 surfaces are completely untouched in the validation range:

```
$ git diff --stat 10ae763 b6875b9 -- swift/AssetPipelineSwiftKit/
(empty)
$ git diff --stat 10ae763 b6875b9 -- src/ui/design_tokens/
(empty)
$ git diff --stat 10ae763 b6875b9 -- src/ui/views/
(empty)
```

This satisfies the "Phase 5 v2 regressions not present" spot-check.

Parser sanity:

```
$ crystal build --no-codegen src/ui.cr
EXIT=0
```

End-block balance is intact across both edited files.

## Findings

None blocking. Two observations worth recording:

1. **Brief amendment is faithful.** `be04dae` only updated `repo_derived_facts`
   to capture the post-cleanup state (counts of 0 / 0 / 6 / 6 / 0) and added
   a clarifying comment. It does not relax any invariant or acceptance check.
   The validator re-runs every fact's query against the working tree, so
   these values were verified independently at HEAD.

2. **iOS build emits 3 `keyWindow` deprecation warnings** from
   `src/ui/native/objc_bridge.m:2409`. Pre-existing (not introduced by
   `b6875b9`, which does not touch `objc_bridge.m`) and not a Phase 5.5
   concern. Mentioned only so it does not get mis-attributed in future
   audits.

## Recommendation

Mark Phase 5.5 closed and tag `phase-05.5-pass-2026-05-22` at `be04dae`.
Phases 6 and 6.5 are unblocked to proceed in parallel per the brief's
parallelism note.

Report path: `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-05.5-validation-2026-05-22.md`
