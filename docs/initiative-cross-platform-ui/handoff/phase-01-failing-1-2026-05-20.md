# Phase 1 — Failing GATE_REPORT (iteration 1) — 2026-05-20

**Verdict:** FAIL
**Validator run date:** 2026-05-20
**Implementer commits validated:** `5b6483b 40e396d 0e3b943 575613a 8ecd37d 006dc70 3874a4e 8b68717` (all 8 present on `phase-01-design-token-foundation`)
**Evidence directory:** `docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/`

---

## Architect adjudication of the verdict

The Validator returned FAIL with 2 outright failures, 4 blocked, and 16 passes. The Architect's reading of the report:

### Genuine remediation targets (Phase 1 Implementer must fix)

- **#12 `renderer.appkit-no-hardcoded`** — FAIL. Real Phase 1 omission. Implementer's own Deviation #4 / Known concern #1 acknowledged this scrub was incomplete.
- **#13 `renderer.uikit-no-hardcoded`** — FAIL. Same shape as #12; UIKit also has 17 `setCornerRadius:` literal floats the rubric explicitly requires to route through `token_radius(...)`.
- **#19 `cascade.macos-changes-on-brand-override`** — BLOCKED (no macOS harness shipped). Architect treats this as a real Phase 1 gap. The phase's Definition of Done explicitly requires "sentinel-magenta brand override visibly cascades to a rendered widget … on at least one Apple target (macOS or iOS)". Either #19 OR #20 must pass — not both blocked.
- **#20 `cascade.ios-changes-on-brand-override`** — BLOCKED (no iOS harness shipped). Same shape as #19. Implementer chooses whichever Apple target is easier to ship and passes that one; the other can stay blocked under the rubric's environment-unavailability clause without failing the verdict.

### Architect-adjudicated as NOT remediation targets (pre-existing environment gaps)

These were verified by the Validator at basis commit `5427a5d` (pre-Phase-1) and are NOT Phase 1 regressions. The team-lead role (collapsed into Architect per `architect-dispatch-collapse-2026-05-20.md`) explicitly adjudicates them out of scope per `rubric/validation_criteria.md` §"GATE_REPORT format" — "the team lead may decide to unblock the environment and re-run rather than send back to implementer."

- **#15 `specs.suite-green`** — BLOCKED. `crystal spec` fails to link on this darwin host because `src/ui/native/objc_collections.cr` references C-bridge symbols (`nsmutablearray_*`) that the default link doesn't include. Pre-existing. The 4 Phase 1 spec files themselves run cleanly when invoked directly (48 examples / 0 failures / 0 errors). The Implementer's claim of 3 pre-existing failures in `spec/components/phase2_verification_spec.cr:52,116,129` (legacy class-name assertions) is verified accurate; not Phase 1's responsibility. **Implementer should NOT attempt to fix this.**
- **#17 `build.platform-samples-compile`** — BLOCKED. Android sample fails on darwin (`c/sys/epoll` Linux-only header). Pre-existing. macOS and iOS sample builds both succeed `--no-codegen`. **Implementer should NOT attempt to fix the Android sample build on darwin.**

### Verdict commentary

Honest scoping: the Implementer landed the core token system (model + conversion + brand + 2 generators + UI::Theme adapter + web renderer migration + web cascade end-to-end) cleanly. The web cascade #18 passes with sentinel-magenta rendering at ΔE 3.0 — that is the load-bearing proof. The native renderer scrub is incomplete, which the Implementer self-disclosed; that's exactly the kind of remediation the trust pair protocol budgets one loop for.

---

## Full validator report

```json
{
  "phase": 1,
  "phase_name": "Design Token Foundation",
  "validator_run_date": "2026-05-20",
  "iteration": 1,
  "implementer_commits": ["5b6483b", "40e396d", "0e3b943", "575613a", "8ecd37d", "006dc70", "3874a4e", "8b68717"],
  "verdict": "FAIL",
  "checks": [
    {
      "check_id": "tokens.types-defined",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/tokens.types-defined.log"],
      "notes": "All 11 types declared in src/ui/design_tokens.cr (Color struct, ColorPalette/SpacingScale/TypeStep/TypeScale/RadiusScale/ShadowLevel/ShadowScale/MotionScale/Breakpoints records, Tokens class). touch_target_minimum_px : Float64 getter present on Tokens (line 481), defaulted to 44.0 in Tokens.default (line 660)."
    },
    {
      "check_id": "tokens.color-roundtrip",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["test_output/tokens.color-roundtrip.log"],
      "notes": "spec/ui/design_tokens_conversion_spec.cr: 8 examples, 0 failures, 0 errors, 0 pending."
    },
    {
      "check_id": "tokens.default-matches-amber",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/tokens.default-matches-amber.diff"],
      "notes": "OKLCH source values in Defaults.light_palette are byte-identical to the legacy strings recovered from git show 5427a5d:src/components/css/tokens/amber_theme.cr for all five canonical roles (brand-primary, surface-canvas, text-primary, border-default, danger). Since L/c/h match exactly through the shared Conversion.oklch_to_srgb pipeline, ΔE2000 = 0.000 for each — well within the visual-grade ≤ 1.0 tolerance."
    },
    {
      "check_id": "tokens.brand-override-merge",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["test_output/tokens.brand-override-merge.log"],
      "notes": "spec/ui/design_tokens_brand_spec.cr: 8 examples, 0 failures."
    },
    {
      "check_id": "generator.web-deterministic",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/generator.web-deterministic.diff"],
      "notes": "WebGenerator.generate(Tokens.default) byte-stable across runs; matches src/ui/design_tokens/dist/web_tokens.css exactly. (Rubric's `--stdout-web` flag not implemented; used direct in-process call as equivalent.)"
    },
    {
      "check_id": "generator.web-content",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/generator.web-content.log"],
      "notes": "All seven probed variables present. Light and dark blocks both present. Zero --amber-* aliases — total prefix rename to --ap-* confirmed."
    },
    {
      "check_id": "generator.apple-deterministic",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/generator.apple-deterministic.diff"],
      "notes": "AppleGenerator byte-stable; matches dist/AssetPipelineTokens.swift exactly."
    },
    {
      "check_id": "generator.apple-content",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/generator.apple-content.log"],
      "notes": "Required symbols present; sampled 5 colors all within 0/255 of Tokens.default — well inside the 1/255 tolerance."
    },
    {
      "check_id": "generator.android-deterministic",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": [],
      "notes": "Deferred per architect handoff. Absence of src/ui/design_tokens/dist/android/ and android_generator.cr confirmed."
    },
    {
      "check_id": "generator.android-well-formed",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": [],
      "notes": "Deferred. Absence confirmed under #9."
    },
    {
      "check_id": "renderer.web-no-hardcoded",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/renderer.web-no-hardcoded.log"],
      "notes": "One hit at line 1580 (Capsule visit) — rgba channels from user-supplied UI::Color (allowed clause a); 9999px is the canonical structural definition of a Capsule. Broader scalar literals (font-size: 17px etc.) flagged as out-of-scope observations; do not fail this check per its written procedure."
    },
    {
      "check_id": "renderer.appkit-no-hardcoded",
      "required": true,
      "passed": false,
      "blocked": false,
      "evidence": ["inspections/renderer.appkit-no-hardcoded.log"],
      "notes": "FAIL. Two brand-decision color literals in visit methods bypass token shim: (a) line 258 ember_dark = nscolor_rgba(0.165, 0.102, 0.031, 1.0); (b) line 3800 amber_gold = nscolor_rgba(1.0, 0.678, 0.2, 1.0) hardcodes the legacy amber gold, bypassing the amber_brand_gold shim at line 4601 that exists specifically to route through token_nscolor(:brand_primary). Plus ~15 unannotated nsfont_system literals and ~10 nscolor_rgba literals in visit methods lacking '# Tier 2' annotation."
    },
    {
      "check_id": "renderer.uikit-no-hardcoded",
      "required": true,
      "passed": false,
      "blocked": false,
      "evidence": ["inspections/renderer.uikit-no-hardcoded.log"],
      "notes": "FAIL. Same anti-pattern as AppKit: line 284 ember_dark and line 4183 amber_gold literals bypassing the shim at line 4983. SEVENTEEN setCornerRadius: hardcoded float literals at lines 1498, 1669, 1900, 2659, 2819, 2970, 3334, 3853, 3888, 3920, 3997, 4097, 4203, 4256, 4318, 4361, 4446 — zero route through token_radius. Two unannotated systemFontOfSize literals at lines 1374 (10.0) and 1681 (17.0)."
    },
    {
      "check_id": "renderer.android-no-hardcoded",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": [],
      "notes": "Deferred. `git diff phase-01-design-token-foundation~ -- src/ui/renderers/android_renderer.cr` empty — no edits, as required by the deferral."
    },
    {
      "check_id": "specs.suite-green",
      "required": true,
      "passed": false,
      "blocked": true,
      "evidence": ["test_output/specs.suite-green.log"],
      "notes": "BLOCKED (pre-existing). `crystal spec` link failure (undefined nsmutablearray_* symbols from src/ui/native/objc_collections.cr) verified at basis commit 5427a5d (pre-Phase-1). The 4 Phase 1 spec files run cleanly when invoked directly: 48 examples / 0 failures / 0 errors. 3 phase2_verification_spec failures are pre-existing legacy class-name assertions. ARCHITECT ADJUDICATION: not a Phase 1 regression; Implementer not asked to fix."
    },
    {
      "check_id": "build.web-cleanly",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["test_output/build.web-cleanly.log"],
      "notes": "Exit 0, no warnings."
    },
    {
      "check_id": "build.platform-samples-compile",
      "required": true,
      "passed": false,
      "blocked": true,
      "evidence": ["test_output/build.platform-samples-compile-macos.log", "test_output/build.platform-samples-compile-ios.log", "test_output/build.platform-samples-compile-android.log"],
      "notes": "macOS exit 0, iOS exit 0. Android fails (`can't find file 'c/sys/epoll'`, Linux-only header) — verified pre-existing at basis 5427a5d. ARCHITECT ADJUDICATION: pre-existing darwin-host gap; Implementer not asked to fix."
    },
    {
      "check_id": "cascade.web-changes-on-brand-override",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["screenshots/cascade.web-changes-on-brand-override.png", "inspections/cascade.web-changes-on-brand-override-computed-style.json", "inspections/cascade.web-changes-on-brand-override-pixel-sample.log"],
      "notes": "PASS. Sentinel-magenta brand override propagates from Crystal Brand subclass to rendered pixel within ΔE 3.0 of (255,0,255). Tree clean after run (no temp edits needed; BRAND_PRIMARY_HEX was already magenta in the demo)."
    },
    {
      "check_id": "cascade.macos-changes-on-brand-override",
      "required": true,
      "passed": false,
      "blocked": true,
      "evidence": [],
      "notes": "BLOCKED. No macOS cascade harness shipped in Phase 1. ARCHITECT ADJUDICATION: real Phase 1 gap (DoD requires cascade on at least one Apple target); remediate by shipping EITHER #19 OR #20."
    },
    {
      "check_id": "cascade.ios-changes-on-brand-override",
      "required": true,
      "passed": false,
      "blocked": true,
      "evidence": [],
      "notes": "BLOCKED. No iOS cascade harness shipped in Phase 1. ARCHITECT ADJUDICATION: real Phase 1 gap; remediate by shipping EITHER #19 OR #20 (Implementer's choice based on what's easier on this host)."
    },
    {
      "check_id": "docs.regen-script-runs",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["test_output/docs.regen-script-runs.log", "inspections/docs.regen-script-runs-diff.log"],
      "notes": "Exit 0; git diff --stat src/ui/design_tokens/dist/ empty (no drift)."
    },
    {
      "check_id": "docs.public-api-documented",
      "required": false,
      "passed": true,
      "blocked": false,
      "evidence": ["inspections/docs.public-api-documented.log"],
      "notes": "Tokens / Brand / WebGenerator / AppleGenerator all have doc comments. AndroidGenerator absent per deferral."
    }
  ],
  "summary": "16 of 21 required checks pass, 2 fail outright (#12 AppKit, #13 UIKit), 3 blocked. Token model, conversion math, generators, and web renderer migration are solid. Native renderer literal scrub is incomplete: AppKit and UIKit contain brand-decision RGB literals in visit methods (ember_dark / second amber_gold) that bypass the token shims; UIKit additionally has 17 setCornerRadius literals the rubric requires to route through token_radius. Web cascade #18 passes (ΔE 3.0)."
}
```
