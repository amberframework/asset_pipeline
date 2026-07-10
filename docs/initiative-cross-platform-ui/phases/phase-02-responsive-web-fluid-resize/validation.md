
# Phase 2 — Validator Rubric: Responsive Web Fluid Resize

**Audience:** the validator agent spawned for Phase 2.
**Read first:** `README.md` (this folder), `../../rubric/validation_criteria.md`, `../../rubric/gate_report_schema.md`, then this file.
**Output:** a `GATE_REPORT.json` returned to the team lead, evidence under `handoff/phase-02-evidence-{YYYY-MM-DD}/`.

---

## 1. Validator scope reminder

You read, run, inspect, and record. You do **not** modify code, tests, configuration, or docs (except temporary inspection edits that you revert before returning). Every check below has a stable `check_id` — your `GATE_REPORT.json` must contain one entry per check in this exact order. Use `passed: false; blocked: true` if the environment prevents you from running a check; do not silently skip.

---

## 2. Pre-reading checklist

- [ ] `README.md` (this folder).
- [ ] `../../rubric/validation_criteria.md` — running checks, evidence layout, GATE_REPORT format.
- [ ] `../../rubric/gate_report_schema.md` — schema constraints.
- [ ] The implementer's handoff message — read it **only after** you have read the rubric and formed your expectations. Cross-reference commit hashes against the `implementer_commits` field of your report.
- [ ] Do **not** read `implementation.md` cover-to-cover. Skim the "Definition of done" section if needed, but you validate against this rubric, not against the implementer's plan.

---

## 3. Evidence directory

Create on first run:

```
handoff/phase-02-evidence-{YYYY-MM-DD}/
  README.md
  test_output/
  screenshots/
  audits/
  inspections/
```

Filename convention for screenshots: `{check_id}-{page}-{viewport}-{scheme}.png`. Example: `fluid.demo-overview-resize-overview-1280-dark.png`.

---

## 4. Checks

Each check below is required unless explicitly marked optional. `check_id` is stable across iterations.

### Behavioral checks (rendered output, screenshots, audits)

#### Check 1 — `fluid.viewport-meta-present` (required)

- **What:** every generated `output/web-design-system-*.html` page contains `<meta name="viewport" content="width=device-width, initial-scale=1">` (or equivalent with `1.0`).
- **How:** `grep -c 'name="viewport"' output/web-design-system-*.html`. Each must be ≥ 1.
- **Pass criterion:** all seven pages return ≥ 1.
- **Evidence:** `inspections/fluid.viewport-meta-present.log` (grep output).

#### Check 2 — `fluid.screenshot-1280-light` (required)

- **What:** all seven demo pages render without horizontal overflow at 1280 × 800, light scheme.
- **How:** drive Chrome via CDP per `../../rubric/behavior-simulation-toolkit.md` §3 — `Emulation.setDeviceMetricsOverride` to 1280×800, `Emulation.setEmulatedMedia` with `prefers-color-scheme: light`, `Page.navigate` to each `file://` URL, `Page.captureScreenshot`; via `Runtime.evaluate` verify `document.documentElement.scrollWidth <= 1280`.
- **Pass criterion:** seven screenshots captured; no horizontal scrollbar visible; reported `scrollWidth` ≤ viewport.
- **Evidence:** seven screenshots `screenshots/fluid.screenshot-1280-light-{page}-1280-light.png`; one `test_output/fluid.screenshot-1280-light-overflow.log` with per-page scrollWidth.

#### Check 3 — `fluid.screenshot-1280-dark` (required)

- **What:** same as Check 2, dark scheme.
- **How:** identical to Check 2 with `prefers-color-scheme: dark` emulation enabled.
- **Pass criterion:** seven screenshots, no overflow.
- **Evidence:** screenshots and log analogous to Check 2.

#### Check 4 — `fluid.screenshot-768-light` (required)

- **What:** seven demo pages at 768 × 1024, light scheme. No horizontal overflow.
- **How / Pass / Evidence:** mirrors Check 2 at the 768 viewport.

#### Check 5 — `fluid.screenshot-768-dark` (required)

- **What/How/Pass/Evidence:** mirrors Check 3 at 768.

#### Check 6 — `fluid.screenshot-375-light` (required)

- **What:** seven demo pages at 375 × 667, light. No horizontal overflow. All interactive elements visible (not clipped off-screen).
- **How:** as above + via console: `document.querySelectorAll('button, [role="button"], input, select, a.am-button').forEach(el => { const r = el.getBoundingClientRect(); console.log(el.tagName, r.left, r.right, r.width, r.height); })`. Any negative `left` or `right > viewport.width` is a clip.
- **Pass criterion:** no clips; no overflow.
- **Evidence:** screenshots + `test_output/fluid.screenshot-375-light-clip-audit.log`.

#### Check 7 — `fluid.screenshot-375-dark` (required)

- Mirrors Check 6, dark.

#### Check 8 — `fluid.screenshot-320-light` (required)

- **What:** seven demo pages at 320 × 568 (mobile-min). No horizontal overflow. No content clipping.
- **How / Pass / Evidence:** as above at 320.

#### Check 9 — `fluid.screenshot-320-dark` (required)

- Mirrors Check 8, dark.

#### Check 10 — `fluid.live-resize-continuity` (required)

- **Bar:** conformance — measured from rendered bounding boxes at each width, not from subjective visual review.
- **What:** dragging the viewport from 1280 → 320 px on the overview, dashboard, and forms pages produces a continuous transition. "Continuous" means: for each tracked element, its width is a monotonically non-increasing function of viewport width (or transitions across at most one breakpoint hand-off per page), and no tracked element's height drops to zero or below the touch-target minimum at any intermediate width.
- **How:** for each of three pages, `Page.navigate` to the `file://` URL via CDP per `../../rubric/behavior-simulation-toolkit.md` §3.7, then at each of the eight widths (1280, 1024, 900, 768, 640, 480, 375, 320), call `Emulation.setDeviceMetricsOverride` and:
  1. Capture screenshot via `Page.captureScreenshot`.
  2. Via `Runtime.evaluate`:
     ```js
     const tracked = document.querySelectorAll('[data-testid]');
     Array.from(tracked).map(el => ({
       testid: el.dataset.testid,
       rect: el.getBoundingClientRect()
     }))
     ```
  3. Write the result to `inspections/fluid.live-resize-continuity-{page}-{width}.json`.
- **Pass criterion:**
  - 24 screenshots present (3 pages × 8 widths).
  - For each tracked element on each page, sort the eight rect samples by viewport width; assert width values are non-increasing (allow ±2 px tolerance for rounding). Identify at most one breakpoint hand-off per element where the width jumps non-monotonically — record which width pair this hand-off occurs at.
  - No tracked element's height drops below `tokens.touch_target_minimum_px` (44) at any width if it was ≥ 44 at any larger width.
  - No tracked element has `width === 0` at any width.
- **Evidence:** 24 screenshots, 24 JSON files (one per page × width), plus a summary `inspections/fluid.live-resize-continuity-summary.json` listing the per-element monotonicity result and any breakpoint hand-offs identified.

#### Check 11 — `fluid.touch-target-1280` (required)

- **What:** every interactive element on the dashboard and forms pages has a computed bounding box ≥ 44 × 44 CSS px at 1280 viewport.
- **How:** via browser console, query: `Array.from(document.querySelectorAll('button, [role="button"], input:not([type="hidden"]), select, textarea, [type="checkbox"], [type="radio"], a.am-button, [role="tab"], [role="menuitem"]')).map(el => { const r = el.getBoundingClientRect(); return { tag: el.tagName, testId: el.dataset.testid, w: r.width, h: r.height }; })`. Filter for `w < 44 || h < 44`. The result array must be empty.
- **Pass criterion:** zero entries below 44 × 44.
- **Evidence:** `test_output/fluid.touch-target-1280.log` with the raw query output and an explicit "0 violations" line.

#### Check 12 — `fluid.touch-target-375` (required)

- Mirrors Check 11 at 375 viewport. Same pages.
- **Pass criterion:** zero violations.

#### Check 13 — `fluid.touch-target-320` (required)

- Mirrors Check 11 at 320 viewport. Same pages.
- **Pass criterion:** zero violations.

#### Check 14 — `fluid.axe-overview-1280` (required)

- **What:** axe-core reports zero serious or critical violations on the overview page at 1280, light + dark.
- **How:** `crystal run scripts/axe_web_demo_audit.cr` (or `scripts/axe_amber_demo_audit.cr` until renamed). Capture JSON for both schemes.
- **Pass criterion:** `violations.filter(v => ['serious','critical'].includes(v.impact)).length === 0` for both schemes on overview.
- **Evidence:** `audits/fluid.axe-overview-1280-light.json`, `audits/fluid.axe-overview-1280-dark.json`.

#### Check 15 — `fluid.axe-overview-375` (required)

- Mirrors Check 14 at 375.

#### Check 16 — `fluid.ibm-overview-1280` (required)

- **What:** IBM Equal Access reports zero "violation" severity issues on the overview page at 1280.
- **How:** `crystal run scripts/ibm_web_demo_audit.cr`. Capture JSON.
- **Pass criterion:** zero violations (warnings allowed; note them).
- **Evidence:** `audits/fluid.ibm-overview-1280.json`.

### Inspection checks (source code, generated CSS, file presence)

#### Check 17 — `fluid.no-hard-coded-min-max-px` (required)

- **What:** `src/ui/renderers/web_renderer.cr` has no remaining literal `min-width: \d{2,4}px` or `max-width: \d{2,4}px` outside of `clamp(...)` expressions in sizing contexts.
- **How:** `grep -nE 'min-width:\s*[0-9]+px|max-width:\s*[0-9]+px' src/ui/renderers/web_renderer.cr | grep -v 'clamp('`. Confirm any remaining matches are inside character-width inputs (e.g., `min-width: 40px` on a numeric value field is acceptable if validated by the implementer's handoff; otherwise flag).
- **Pass criterion:** zero unjustified matches. Acceptable retentions are listed in the implementer's handoff "Deviations"; cross-reference.
- **Evidence:** `inspections/fluid.no-hard-coded-min-max-px.log`.

#### Check 18 — `fluid.fluid-type-exists` (required)

- **What:** `UI::Fluid` type is defined with `min`, `ideal`, `max` fields, and `to_css` returns `clamp(min, ideal, max)`.
- **How:** read `src/ui/fluid.cr`. Run `crystal spec spec/ui/fluid_spec.cr`.
- **Pass criterion:** file exists, type matches; spec passes 0 failures.
- **Evidence:** `test_output/fluid.fluid-type-exists.log`.

#### Check 19 — `fluid.container-query-syntax-valid` (required)

- **What:** every `@container` block in generated CSS uses valid CSS Container Queries Level 1 syntax: `@container <name>? (min-width: <length>) { ... }`.
- **How:** extract all `@container` blocks from a regenerated page's `<style>`. For each, regex-match `@container\s+([a-z][a-z0-9_-]*)?\s*\(\s*(min|max)-(width|inline-size):\s*[0-9.]+(px|rem|em|cqi|cqw)\s*\)\s*\{`. Run the extracted CSS through a CSS parser (Crystal has `css-parser`, or use a Node one-shot if simpler) to confirm it parses.
- **Pass criterion:** every block matches; CSS parses without errors.
- **Evidence:** `inspections/fluid.container-query-syntax-valid.log` listing each block and the validation result.

#### Check 20 — `fluid.container-type-emitted` (required)

- **What:** the Card, Form, and NavigationSplitView components emit `container-type: inline-size` and a `container-name` declaration in their rendered styles.
- **How:** render a sample of each via Crystal: `puts UI::Web::Renderer.new.render(UI::Card.new)`. Inspect for both declarations.
- **Pass criterion:** all three widgets emit both.
- **Evidence:** `inspections/fluid.container-type-emitted.log`.

#### Check 21 — `fluid.viewport-meta-from-renderer` (required)

- **What:** `UI::Web::Renderer#render_document(view, title)` exists and emits viewport meta.
- **How:** read `src/ui/renderers/web_renderer.cr` for the method. Run `crystal spec spec/ui/renderers/document_mode_spec.cr`.
- **Pass criterion:** method present; spec passes.
- **Evidence:** `test_output/fluid.viewport-meta-from-renderer.log`.

#### Check 22 — `fluid.clamp-coverage-in-generated-css` (required)

- **What:** the concatenated generated CSS across all seven demo pages contains at least 20 distinct `clamp(...)` expressions and at least three `@container` blocks.
- **How:** `cat output/web-design-system-*.html | grep -oE 'clamp\([^)]+\)' | sort -u | wc -l` and `cat output/web-design-system-*.html | grep -c '@container '`.
- **Pass criterion:** clamp count ≥ 20, container count ≥ 3.
- **Evidence:** `inspections/fluid.clamp-coverage-in-generated-css.log`.

### Spec / build checks

#### Check 23 — `fluid.crystal-spec-green` (required)

- **What:** `crystal spec` from repo root completes with `0 errors, 0 failures, 0 pending` (pending acceptable but noted).
- **How:** `cd <repo> && crystal spec 2>&1 | tee handoff/phase-02-evidence-{DATE}/test_output/fluid.crystal-spec-green.log`.
- **Pass criterion:** exit code 0; final line shows zero errors and zero failures.
- **Evidence:** `test_output/fluid.crystal-spec-green.log`.

#### Check 24 — `fluid.web-demo-validator-green` (required)

- **What:** `crystal run scripts/validate_web_demo.cr` exits 0.
- **How:** run it; capture output.
- **Pass criterion:** exit code 0; printed summary shows no failures.
- **Evidence:** `test_output/fluid.web-demo-validator-green.log`.

#### Check 25 — `fluid.build-clean` (required)

- **What:** `crystal build --no-codegen src/asset_pipeline.cr` completes without warnings related to the new code.
- **How:** run it; tee output.
- **Pass criterion:** exit code 0; no warnings mentioning `fluid.cr`, `view.cr` new code paths, or `web_renderer.cr`.
- **Evidence:** `test_output/fluid.build-clean.log`.

---

## 5. Verdict computation

`verdict = PASS` if and only if every required check above has `passed: true`. Any required check with `passed: false` or `blocked: true` → `verdict = FAIL`.

Return the report per `../../rubric/gate_report_schema.md`. The `checks` array must contain 25 entries, in the order listed above, with the `check_id` values exactly as written.
