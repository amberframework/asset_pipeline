# Phase 2 — Failing GATE_REPORT (iteration 1) — 2026-05-20

**Verdict:** FAIL
**Validator run date:** 2026-05-20
**Implementer commits (10):** `e17f7b6 b8709ac a82ad02 a710f6b a6ebee4 93205f4 c185f01 44d003f 5a5b52c 36f74f9`
**Evidence directory:** `docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20/`

---

## Architect adjudication

13 of 25 required checks pass. The 12 failures cluster into three groups:

### Genuine Phase 2 remediation targets (Implementer must fix)

- **Checks #4–9 (viewport screenshots 768 / 375 / 320, light + dark)** — Dashboard demo page horizontally overflows at every viewport below 1280. Concrete: scrollWidth = 962 at viewport 768; layout viewport expands to ~924–943 at device-width 320/375. Other 6 pages clean. **The dashboard CSS does not collapse below ~939 px.** Remediation likely needs container-query rules for the dashboard shell that reflow it into a single column.
- **Checks #11–13 (touch-target floor at 1280 / 375 / 320)** — Multiple violations: h=32 buttons on dashboard + forms, h=40 submit buttons on forms, 13×13 checkbox inputs, h=42.78 select on forms. The `enforce_touch_target` helper exists but doesn't reach these widgets. Apply it (or its CSS equivalent on `min-block-size`) to: native `<button>` without `am-button` class, `<input type="submit">`, `<input type="checkbox">` / `<input type="radio">`, and `<select>` — all the rubric's selector set.
- **Checks #14–15 (axe color-contrast on overview, 1280 + 375)** — Dark-scheme serious violation: `span[data-amber-theme-label]`, `.am-button--outline`, and an external-link anchor. Light scheme clean. Tighten the dark-palette colors so the WCAG AA 4.5:1 (normal) / 3:1 (large) bars are met.
- **Check #20 (render-output container-type/name)** — `UI::Web::Renderer.new.render(UI::Card.new)` returns HTML with NO `container-type: inline-size` or `container-name:` declarations. They live only in registered class CSS (`container_query_components.cr`), which the rubric's `render(view)` procedure does not capture. **Remediation:** emit `container-type: inline-size; container-name: card;` (and equivalents for `am-form`, `am-split-view`) inline on the root element via `apply_common_styles`, OR explicitly route through `container_query_name` when set. The operational behavior IS met in full-document output, but the rubric tests per-element render output.
- **Check #22 (clamp coverage)** — Distinct `clamp()` count across the 7 demo pages = 11; rubric requires ≥ 20. Remediation: widen the clamp migration to more sizing call sites (currently many `gap:`, `padding:`, `margin:` etc. literals remain as fixed pixels). The Implementer's claim of "22 clamp() expressions in the overview alone" counts raw occurrences, not distinct — `sort -u` collapses them to 11.

### Architect-adjudicated as NOT remediation targets (pre-existing)

- **Check #23 (`fluid.crystal-spec-green`)** — Pre-existing `crystal spec`-from-repo-root link gap (`undefined nsmutablearray_*`), inherited from before Phase 1. The 5 Phase 2 spec files run cleanly when invoked directly: 51 examples, 0 failures, 0 errors. **Not a Phase 2 regression; Implementer should NOT attempt to fix.**
- **Check #24 (`fluid.web-demo-validator-green`)** — `scripts/validate_web_demo.cr` fails on the `--amber-*` CSS variables check (42 undefined). This is Phase 1 collateral: Phase 1 removed the `--amber-*` aliases but the demo heredoc still references them. **Phase 2's three new assertions all pass implicitly.** Architect adjudication: the cleanest fix is to scrub the `--amber-*` references from the demo heredoc — but that's a 5-minute follow-up commit, not a Phase 2 design issue. Since the goal is cleared and the architect-adjudication is bounded, **the Implementer may fix this in the remediation as a follow-up to Phase 1, OR leave it for a dedicated cleanup commit.** Owner's call when remediation is dispatched.

### Soft signals worth tightening (not failures)

- **Check #10 (`fluid.live-resize-continuity`)** — Vacuous pass: the demo pages have ZERO `data-testid` attributes, so the per-element monotonicity assertions trivially hold. The check captured 24 screenshots cleanly and the sidebar finding (dashboard scrollWidth=1201 at 1024, 971 at 900, 962 at 768, 950 at 640) reinforces the Check #4–9 dashboard failure. If the Implementer is fixing #4–9 anyway, adding `data-testid` to a handful of dashboard cards/buttons would make #10 a real signal in iter-2.

---

## Full validator report

```json
[See validator's GATE_REPORT in the iter-2 dispatch handoff; archived inline in evidence-2026-05-20/README.md when it lands]
```

The validator returned the 25-check array in full, with detailed evidence paths for all 80+ screenshots and 25+ inspection/test_output/audit artifacts under `handoff/phase-02-evidence-2026-05-20/`.
