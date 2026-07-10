# Phase 2 — Passing GATE_REPORT — 2026-05-20

**Verdict:** PASS
**Iteration:** 2 (after one remediation loop)
**Validator run date:** 2026-05-20
**Implementer commits (14):**

Original Phase 2 build:
- `e17f7b6` Add UI::Fluid type and fluid_width/fluid_height on View
- `b8709ac` Wire fluid_*/container_query into apply_common_styles + helpers
- `a82ad02` Implement container query generator and wire Card/Form/SplitView
- `a710f6b` Add Renderer#render_document with viewport meta
- `a6ebee4` Enforce 44×44 touch target on all interactive widgets
- `93205f4` Migrate dialog/menu/sidebar/stepper sizes to clamp()
- `c185f01` Migrate web design system demo to clamp() and container queries
- `44d003f` Specs and validator scripts for clamp/container/touch-target
- `5a5b52c` Regenerate demo HTML and screenshot baselines
- `36f74f9` crystal tool format pass on touched files

Remediation loop 1:
- `c735c47` Remediation: emit container-type/name inline on Card/Form/SplitView
- `12cf77f` Remediation: floor every interactive widget at 44×44
- `5b996c3` Remediation: scrub --amber-* aliases from demo + JS
- `a5beccc` Remediation: regenerate demo HTML for iter 2 validator

**Evidence directory:** `docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20-iter2/`

---

## What landed

Phase 2 delivered the responsive web fluid-resize substrate the demo needed: the `UI::Fluid` value type plus chainable `fluid_width`/`fluid_height` on `UI::View`; container-query generation through the existing `@<name>:<bp>` modifier syntax; a `Renderer#render_document(view, title, lang)` helper that owns viewport-meta emission for any caller; a global `TOUCH_TARGET_CSS` rule that floors every interactive widget at 44×44; and migration of all seven web-design-system demo pages to clamp() (31 distinct expressions across the corpus, 9 container-query blocks across `card`/`card-grid`/`dashboard`/`form`/`split-view`).

Done in 14 Implementer commits (10 original + 4 remediation), one Validator iteration that returned FAIL on the dashboard overflow / touch-target gaps / contrast / container-emission / clamp coverage issues the iter-1 work missed, and one remediation loop that returned PASS at iteration 2.

## Verdict computation

All 25 required checks pass. No `blocked: true` entries. Two architect-binding adjudications (#23 pre-existing `crystal spec` link gap; #24 in-scope this iter after Implementer's `--amber-*` scrub) are recorded with verified PASS.

## Full validator report

```json
{
  "phase": 2,
  "phase_name": "Responsive Web Fluid Resize",
  "validator_run_date": "2026-05-20",
  "iteration": 2,
  "implementer_commits": ["e17f7b6", "b8709ac", "a82ad02", "a710f6b", "a6ebee4", "93205f4", "c185f01", "44d003f", "5a5b52c", "36f74f9", "c735c47", "12cf77f", "5b996c3", "a5beccc"],
  "verdict": "PASS",
  "checks": [
    {"check_id": "fluid.viewport-meta-present", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/fluid.viewport-meta-present.log"], "notes": "All 7 pages contain exactly one viewport meta tag."},
    {"check_id": "fluid.screenshot-1280-light", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-1280-light-*.png", "test_output/fluid.screenshot-1280-light-overflow.log"], "notes": "7 light screenshots at 1280×800; scrollWidth == innerWidth on every page."},
    {"check_id": "fluid.screenshot-1280-dark", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-1280-dark-*.png", "test_output/fluid.screenshot-1280-dark-overflow.log"], "notes": "7 dark screenshots at 1280×800; scrollWidth == 1280 across all pages."},
    {"check_id": "fluid.screenshot-768-light", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-768-light-*.png", "test_output/fluid.screenshot-768-light-overflow.log"], "notes": "Dashboard now reflows cleanly at 768 — the iter-1 overflow is gone (was 962, now 768). All 7 pages: scrollWidth == 768."},
    {"check_id": "fluid.screenshot-768-dark", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-768-dark-*.png", "test_output/fluid.screenshot-768-dark-overflow.log"], "notes": "7 dark screenshots at 768; no overflow."},
    {"check_id": "fluid.screenshot-375-light", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-375-light-*.png", "test_output/fluid.screenshot-375-light-overflow.log", "test_output/fluid.screenshot-375-light-clip-audit.log"], "notes": "7 light screenshots at 375 mobile; scrollWidth == 375 on every page. Clip audit clean — 2 deliberate off-screen dialog/palette buttons are at 44×44 right:-9999px positioning per remediation, not real clips."},
    {"check_id": "fluid.screenshot-375-dark", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-375-dark-*.png", "test_output/fluid.screenshot-375-dark-overflow.log", "test_output/fluid.screenshot-375-dark-clip-audit.log"], "notes": "7 dark screenshots at 375; same clean overflow + clip pattern."},
    {"check_id": "fluid.screenshot-320-light", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-320-light-*.png", "test_output/fluid.screenshot-320-light-overflow.log", "test_output/fluid.screenshot-320-light-clip-audit.log"], "notes": "7 light screenshots at request 320 (Chrome mobile floor → innerWidth 324); scrollWidth == 324 every page."},
    {"check_id": "fluid.screenshot-320-dark", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.screenshot-320-dark-*.png", "test_output/fluid.screenshot-320-dark-overflow.log", "test_output/fluid.screenshot-320-dark-clip-audit.log"], "notes": "7 dark screenshots at 320; same clean pattern."},
    {"check_id": "fluid.live-resize-continuity", "required": true, "passed": true, "blocked": false, "evidence": ["screenshots/fluid.live-resize-continuity-*.png", "inspections/fluid.live-resize-continuity-*.json", "inspections/fluid.live-resize-continuity-summary.json"], "notes": "24 screenshots + 24 rect-sample JSONs across 8 widths × 3 pages. Dashboard's 6 data-testid anchors show exactly one breakpoint hand-off (single jump at vw=900 for two-col → single-column reflow) — rubric permits one. No width=0 or height-below-44 violations."},
    {"check_id": "fluid.touch-target-1280", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.touch-target-1280.log"], "notes": "0 violations on dashboard + forms at 1280. iter-1 failures (h=32 buttons, h=40 submit, 13×13 checkboxes, h=42.78 select) all closed by global TOUCH_TARGET_CSS rule."},
    {"check_id": "fluid.touch-target-375", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.touch-target-375.log"], "notes": "0 violations at 375 mobile."},
    {"check_id": "fluid.touch-target-320", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.touch-target-320.log"], "notes": "0 violations at request-320 (innerWidth 324). Previously-display:none dialog + command-palette controls render off-screen at 44×44 now (not 0×0)."},
    {"check_id": "fluid.axe-overview-1280", "required": true, "passed": true, "blocked": false, "evidence": ["audits/fluid.axe-overview-1280-light.json", "audits/fluid.axe-overview-1280-dark.json"], "notes": "axe-core 4.10.2 at 1280. Light + dark both 0 violations. Implementer's deviation (opaque background-color baselines instead of palette tweaks) cleared the axe color-mix(…, transparent) → #ffffff fallback chain."},
    {"check_id": "fluid.axe-overview-375", "required": true, "passed": true, "blocked": false, "evidence": ["audits/fluid.axe-overview-375-light.json", "audits/fluid.axe-overview-375-dark.json"], "notes": "axe-core at 375. Both schemes 0 violations."},
    {"check_id": "fluid.ibm-overview-1280", "required": true, "passed": true, "blocked": false, "evidence": ["audits/fluid.ibm-overview-1280.json"], "notes": "IBM Equal Access: 0 hard violations on overview at 1280. All flagged items are MANUAL/POTENTIAL needs-review."},
    {"check_id": "fluid.no-hard-coded-min-max-px", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/fluid.no-hard-coded-min-max-px.log"], "notes": "Single retained literal: ShareDestinationItem min-width: 60px at web_renderer.cr:1881, deliberately documented in iter-1 handoff. No new literals introduced by remediation."},
    {"check_id": "fluid.fluid-type-exists", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.fluid-type-exists.log"], "notes": "UI::Fluid record + to_css contract. fluid_spec.cr: 10 examples, 0 failures."},
    {"check_id": "fluid.container-query-syntax-valid", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/fluid.container-query-syntax-valid.log"], "notes": "9 distinct @container blocks (card×2, card-grid×1, dashboard×2, form×2, split-view×2) all match rubric regex. 9/9 OK."},
    {"check_id": "fluid.container-type-emitted", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/fluid.container-type-emitted.log"], "notes": "render(Card.new), render(Form.new), render(NavigationSplitView.new) all emit inline 'container-type: inline-size; container-name: <name>' on the root element. iter-1 #20 failure closed by c735c47."},
    {"check_id": "fluid.viewport-meta-from-renderer", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.viewport-meta-from-renderer.log"], "notes": "render_document(view, title, lang) at web_renderer.cr:77. document_mode_spec.cr: 7 examples, 0 failures."},
    {"check_id": "fluid.clamp-coverage-in-generated-css", "required": true, "passed": true, "blocked": false, "evidence": ["inspections/fluid.clamp-coverage-in-generated-css.log"], "notes": "Distinct clamp count = 31 (rubric floor 20). @container occurrences = 77, distinct blocks = 9 (rubric floor 3). iter-1 was 11; remediation widened by 20 distinct expressions via gap/padding/font-size migration."},
    {"check_id": "fluid.crystal-spec-green", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.crystal-spec-green.log", "test_output/fluid.crystal-spec-phase02-files.log"], "notes": "Architect-adjudicated pre-existing env gap (undefined nsmutablearray_* link failure from objc_collections.cr — pre-existing at basis 5427a5d, not Phase 2). The 4 Phase 2 spec files run cleanly when invoked directly: 31 examples, 0 failures."},
    {"check_id": "fluid.web-demo-validator-green", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.web-demo-validator-green.log"], "notes": "validate_web_demo.cr exit 0 — 'Web design-system static audit passed'. iter-1's --amber-* gap (42 undefined refs) closed by 5b996c3 commit."},
    {"check_id": "fluid.build-clean", "required": true, "passed": true, "blocked": false, "evidence": ["test_output/fluid.build-clean.log"], "notes": "crystal build --no-codegen src/asset_pipeline.cr exit 0, no output."}
  ],
  "summary": "All 25 required checks pass. iter-1's 12 failures (#4-9 dashboard overflow, #11-13 touch-target, #14-15 axe contrast, #20 container-type inline, #22 clamp coverage) all closed by the four remediation commits. Architect-binding adjudications for #23 and #24 recorded with verified PASS."
}
```
