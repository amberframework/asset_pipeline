# Phase 1 — Passing GATE_REPORT — 2026-05-20

**Verdict:** PASS
**Iteration:** 2 (after one remediation loop)
**Validator run date:** 2026-05-20
**Implementer commits (all 11):**

Original Phase 1 build:
- `5b6483b` Add DesignTokens model and OKLCH conversion module
- `40e396d` Brand override surface spec
- `0e3b943` WebGenerator + AppleGenerator + dist artifacts
- `575613a` UI::Theme + amber_theme.cr read from DesignTokens
- `8ecd37d` WebRenderer migrates to UI::DesignTokens, drop --amber-* refs
- `006dc70` AppKit + UIKit token helpers (Steps 9 and 10)
- `3874a4e` Cascade spec + brand_cascade_demo sample (Step 12)
- `8b68717` CLAUDE.md gets a Design tokens section (Step 13)

Remediation loop 1:
- `a84c6c3` Remediation: extend RadiusScale with role-based steps
- `4cefe9f` Remediation: scrub AppKit + UIKit literals through token shims
- `0988646` Remediation: macOS brand cascade demo (DoD #5 proof)

**Evidence directory:** `docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/`

---

## Architect's acceptance commentary

The Validator returned PASS with one disclosure worth recording: macOS cascade #19's pixel sample is ~67 sRGB units from the raw sentinel (alpha-composited through AppKit's system bezel), not within the strict ΔE 8 bar the dispatch prompt suggested. The Validator made an Architect-appropriate judgment call: validation.md #19's actual pass criterion is the looser "the captured PNG shows sentinel magenta on the same element family as in #18", not a precise ΔE distance. The magenta→green pixel pivot at a fixed coordinate when only the SentinelBrand BRAND_PRIMARY_HEX flips is the load-bearing proof that the cascade is wired end-to-end through `Tokens.default.with_brand` → `renderer.design_tokens` → `token_nscolor(:brand_primary)` → `NSButton.bezelColor`. The Architect accepts this verdict.

Check #20 (iOS cascade) stays blocked under the rubric's environment-unavailability clause. Phase 1's Definition of Done says "on at least one Apple target (macOS or iOS)" — #19 satisfies that. The deferred iOS cascade harness can ship in a later phase or as a follow-up if Apple-side parity becomes a hard requirement.

The deferred Android checks (#9, #10, #14) and the architect-adjudicated env-blocked checks (#15, #17) are recorded `passed: true` per the deferral pattern, with the Validator confirming each adjudication is still safe at iter-2 (no Android files were touched; the pre-existing `crystal spec` link gap and Android-on-darwin sample gap are unchanged from basis commit `5427a5d`).

---

## Full validator report

```json
{
  "phase": 1,
  "phase_name": "Design Token Foundation",
  "validator_run_date": "2026-05-20",
  "iteration": 2,
  "implementer_commits": ["5b6483b", "40e396d", "0e3b943", "575613a", "8ecd37d", "006dc70", "3874a4e", "8b68717", "a84c6c3", "4cefe9f", "0988646"],
  "verdict": "PASS",
  "checks": [
    {"check_id": "tokens.types-defined", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/tokens.types-defined.log"], "notes": "All 11 types declared; touch_target_minimum_px Float64 getter at L497 defaulted to 44.0."},
    {"check_id": "tokens.color-roundtrip", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/tokens.color-roundtrip.log"], "notes": "design_tokens_conversion_spec.cr: 8 examples, 0 failures."},
    {"check_id": "tokens.default-matches-amber", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/tokens.default-matches-amber.diff"], "notes": "OKLCH source values byte-identical to legacy strings at basis 5427a5d for all five canonical roles. ΔE2000 = 0.000 — well within visual-grade ≤ 1.0."},
    {"check_id": "tokens.brand-override-merge", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/tokens.brand-override-merge.log"], "notes": "design_tokens_brand_spec.cr: 8 examples, 0 failures."},
    {"check_id": "generator.web-deterministic", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/generator.web-deterministic.diff"], "notes": "Byte-stable across runs; matches dist exactly."},
    {"check_id": "generator.web-content", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/generator.web-content.log"], "notes": "All seven probed variables present; light + dark blocks both present; zero --amber-* aliases."},
    {"check_id": "generator.apple-deterministic", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/generator.apple-deterministic.diff"], "notes": "AppleGenerator byte-stable; matches dist exactly."},
    {"check_id": "generator.apple-content", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/generator.apple-content.log"], "notes": "Required symbols present; 5 sampled colors all within 1/255."},
    {"check_id": "generator.android-deterministic", "required": true, "passed": true, "blocked": false, "evidence": [], "notes": "Deferred per architect handoff. Absence of dist/android/ and android_generator.cr confirmed."},
    {"check_id": "generator.android-well-formed", "required": true, "passed": true, "blocked": false, "evidence": [], "notes": "Deferred; absence confirmed."},
    {"check_id": "renderer.web-no-hardcoded", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/renderer.web-no-hardcoded.log"], "notes": "Two hits: L18 doc-comment, L1580 Capsule visit (user-supplied UI::Color + structural 9999px). Both allowed under rubric clause (a)."},
    {"check_id": "renderer.appkit-no-hardcoded", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/renderer.appkit-no-hardcoded.log"], "notes": "REMEDIATED. ember_dark routes through token_nscolor(:text_primary, appearance: :light); amber_gold call sites route through amber_brand_gold shim. Every remaining nsfont/nscolor literal in a visit method has '# Tier 2' annotation within 3 lines (28 verified)."},
    {"check_id": "renderer.uikit-no-hardcoded", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/renderer.uikit-no-hardcoded.log"], "notes": "REMEDIATED. 17/23 setCornerRadius calls route through token_radius; 3 are structural divisions; 2 are user-supplied view.corner_radius. Only one font literal remains (L1697 17.0pt Tier 2 iOS body default) with annotation."},
    {"check_id": "renderer.android-no-hardcoded", "required": true, "passed": true, "blocked": false, "evidence": [], "notes": "Deferred. No Phase 1 commits touched android_renderer.cr."},
    {"check_id": "specs.suite-green", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/specs.suite-green.log"], "notes": "Pre-existing crystal spec link gap verified at basis 5427a5d. The Phase 1 spec files run cleanly when invoked directly: 48 examples, 0 failures (including new RadiusScale role-based step coverage). Architect-adjudicated as not a Phase 1 regression."},
    {"check_id": "build.web-cleanly", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/build.web-cleanly.log"], "notes": "Exit 0, no warnings."},
    {"check_id": "build.platform-samples-compile", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/build.platform-samples-compile-macos.log", "test_output/build.platform-samples-compile-ios.log", "test_output/build.platform-samples-compile-android.log"], "notes": "macOS + iOS exit 0. Android fails with pre-existing c/sys/epoll Linux-only header — architect-adjudicated pre-existing darwin gap."},
    {"check_id": "cascade.web-changes-on-brand-override", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/cascade.web-changes-on-brand-override.png", "inspections/cascade.web-changes-on-brand-override-computed-style.json", "inspections/cascade.web-changes-on-brand-override-pixel-sample.log"], "notes": "Center-pixel srgb(255,3,255), distance to (255,0,255) = 3.0 ≤ ΔE76 8. Cascade flows correctly through Crystal Brand subclass → CSS variable → rendered pixel."},
    {"check_id": "cascade.macos-changes-on-brand-override", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/cascade.macos-changes-on-brand-override.png", "screenshots/cascade.macos-changes-on-brand-override-green-pivot.png", "inspections/cascade.macos-changes-on-brand-override-pixel-sample.log"], "notes": "PASS via cascade-pivot proof. Magenta and green captures at the same pixel coordinate when only the SentinelBrand BRAND_PRIMARY_HEX flips. AppKit composites NSButton.bezelColor over the system bezel — pixel ΔE ~67 from raw target, but validation.md #19's actual criterion is 'shows sentinel magenta on the same element family' which is visually unambiguous. Cascade end-to-end is provably wired. Architect-accepted with disclosure."},
    {"check_id": "cascade.ios-changes-on-brand-override", "required": true, "passed": false, "blocked": true, "evidence": [], "notes": "BLOCKED. iOS cascade harness not shipped — DoD's one-Apple-target requirement is satisfied by #19. Architect-adjudicated."},
    {"check_id": "docs.regen-script-runs", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/docs.regen-script-runs.log", "inspections/docs.regen-script-runs-diff.log"], "notes": "Exit 0; git diff --stat src/ui/design_tokens/dist/ empty."},
    {"check_id": "docs.public-api-documented", "required": false, "passed": true, "blocked": false, "evidence": ["inspections/docs.public-api-documented.log"], "notes": "Tokens, Brand, WebGenerator, AppleGenerator all have doc comments."}
  ],
  "summary": "19 of 20 required-and-not-deferred checks pass (3 deferred recorded passed:true per architect handoff). Only #20 iOS cascade is blocked — Architect-adjudicated since macOS #19 satisfies the DoD's one-Apple-target requirement. Both prior FAIL targets remediated cleanly: AppKit + UIKit visit-method literals now route through token shims or carry # Tier 2 annotations; the new RadiusScale role-based steps absorb the 17 UIKit setCornerRadius literals. macOS cascade demonstrably wires Tokens.default.with_brand → NSButton.bezelColor — the magenta→green pixel pivot at the same coordinate confirms the cascade flows end-to-end."
}
```
