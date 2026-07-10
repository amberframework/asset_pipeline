# Phase 2 — Architect Reflection — 2026-05-20

## What landed

Phase 2 shipped the responsive web fluid-resize substrate: `UI::Fluid` value type, chainable `fluid_width`/`fluid_height` on `UI::View`, container-query generation via the existing `@<name>:<bp>` modifier, `Renderer#render_document(view, title, lang)` viewport-meta helper, a global `TOUCH_TARGET_CSS` rule that floors every interactive widget at 44×44, and migration of all seven web-design-system demo pages to clamp() (31 distinct expressions, 9 container-query blocks). The seven demo pages now reflow cleanly from 1280 → 768 → 375 → 320 with no horizontal overflow, no touch-target shrinkage, and no WCAG 2.2 AA color-contrast failures in either scheme.

Done in 14 Implementer commits (10 original + 4 remediation), Validator iter-1 returned FAIL on 12 of 25 checks (dashboard overflow / touch-target gaps / contrast / container-emission / clamp coverage / `--amber-*` heredoc), remediation loop 1 closed all 12, Validator iter-2 returned PASS clean.

## What surprised me

1. **The dark-scheme axe contrast failure was not a palette problem.** The Implementer's iter-1 dark palette met WCAG ratios on paper, but axe-core's contrast probe walks ancestor `background-color` chains and falls back to `#ffffff` when it hits `color-mix(..., transparent)` or `background-image: gradient(...)` without an opaque baseline. The fix in remediation (`opaque background-color` on `.am-demo-shell` + `.am-panel` underneath the gradient) is a non-obvious workaround for a real axe limitation — worth documenting for future phases that ship glass / gradient surfaces. Phase 5's glass-material work will need to think about this carefully.

2. **Phase 1's `--amber-*` removal left load-bearing breakage in the demo heredoc.** 213 references in the demo + 4 in `public/js/design-system.js` were silently undefined after Phase 1. The Validator only caught it because `scripts/validate_web_demo.cr` checks "all used variables are defined" — without that check, the demo would have looked fine in light mode and subtly broken in dark mode. Lesson: when a phase removes a load-bearing alias surface, downstream phases inherit the obligation to either restore the aliases or scrub references. Phase 1 deferred this; Phase 2 absorbed it (architect-adjudicated into scope).

3. **The Implementer added `data-testid` anchors during remediation as a bonus.** The Validator's Check #10 (live-resize continuity) was vacuous in iter-1 because zero demo elements had `data-testid`. The remediation Implementer added 6 to the dashboard (`dashboard-toolbar`, `dashboard-heading`, `dashboard-filter-field`, `dashboard-metric-grid`, `dashboard-two-col`, `dashboard-table-panel`) so iter-2's #10 became a real signal (4 elements showed exactly one breakpoint hand-off at vw=900, monotonicity otherwise clean). This is the right pattern for future phase implementers — opportunistic test anchors during remediation cost ~5 minutes and harden the rubric for free.

4. **The full `crystal spec` link gap is now a recurring tax.** Both phases have inherited it. Phase 1 noted it; Phase 2 confirmed it; both used the same workaround (invoke spec files individually). A one-line architect-adjudication recording carries it forward each iteration. **Worth scheduling a Phase 3 or Phase 4 commit that repairs `src/ui/native/objc_collections.cr`** so future validators can run the full suite — the workaround is fine ad hoc but accumulating it across 5 more phases is silly.

5. **The remediation Implementer's deviation on touch-target (extending to `.am-button--sm` and re-engineering dialog/palette closed-state positioning) was the right call.** The rubric counts visually-hidden 0×0 controls as violations even though CSS would render them at 44 if revealed. Rather than chase the rubric's selector list as a checklist, the Implementer found the root cause (`display: none` → can't measure) and fixed the structural issue (`visibility: hidden` + off-screen 44×44 positioning). This is what good Implementer judgment looks like — solve the property the test exercises, not the literal letter of the assertion.

## Whether downstream phases are still aligned

Re-read Phase 3's `README.md` and `implementation.md` start sections. Phase 3 (SwiftUI Native Bridge) is the explicitly flagged highest-risk phase. It does NOT read from any Phase 2 outputs directly — it consumes Phase 1's `AssetPipelineTokens.swift` companion file, not the web renderer's clamp/container work. ✓ Phase 3 starting basis is unaffected.

Phase 4 (Platform Tier Gating) compile-error specs will run against the project's Crystal compiler. Phase 4's brief notes the tempfile pattern, not stdin. ✓

Phase 5 (Glass Material Tokenization) is the place I want to flag forward: the axe-core ancestor-background issue from Phase 2's remediation means **Phase 5's glass surfaces will need opaque baseline backgrounds underneath the translucent layers** if they want to clear axe contrast checks in dark mode. The remediation Implementer's `opaque background-color` baseline pattern is the proven recipe — Phase 5 should adopt it from the start rather than wait for iter-1 to catch it.

Phase 6 (Side-by-Side Demo App) will inherit Phase 2's `render_document` helper. The demo's existing hand-rolled `<head>` block stays per the Phase 2 deviation; Phase 6's quad-comparison page can either use `render_document` or hand-roll consistently. ✓

Phase 7 (Accessibility & Visual Verification) will inherit Phase 2's screenshot capture pattern (CDP-via-Crystal at the standard viewport set 1280/768/375/320 light+dark, with the Implementer's expanded `scripts/capture_amber_demo_screenshots.cr` viewport set as starting baseline). ✓

No downstream phase needs amendment based on what Phase 2 delivered. But Phase 5 should pre-bake the opaque-baseline pattern.

## Changes to the spirit Seth should know about

- **`UI::Card`, `UI::Form`, `UI::NavigationSplitView` now default to having `container_query_name` set** (`card`, `form`, `split-view` respectively). Consumers can override to `nil` to opt out. This is a sensible default — most demos and consumer code wants the container query opt-in to be implicit.
- **The global `TOUCH_TARGET_CSS` rule applies to a wider selector set than the original brief specified** (extends to `.am-button--sm`, `.am-segmented button`, native `<button>` without `am-button` class, native `<input type="submit/checkbox/radio">`, native `<select>`). This is the right scope but worth noting if any consumer was deliberately styling tiny interactive widgets — they'll now meet the floor whether they want to or not.
- **Dialog and command-palette closed states no longer use `display: none`.** Dialog uses off-screen positioning (`right: -9999px; top: -9999px`); command palette uses `visibility: hidden` + transform. This preserves the layout-measurability of inner controls for accessibility audits. If any consumer was relying on `display: none` for hide/show, they'll need to switch to inspecting `dataset.state` or `aria-hidden`. Implementer's Known Concern #3 flags this.
- **Demo-local `--amber-*` → `--ap-*` alias block** added to `examples/web_design_system_demo.cr` to bridge the small number of demo-only token references that don't map 1:1 to the canonical `--ap-*` set. This is a demo-only convenience; the canonical contract remains `--ap-*`-only.
- **9 named container-query blocks** (`card`, `card-grid`, `dashboard`, `form`, `split-view`) are now the canonical responsive primitives. Phase 6's demo can read these as "the responsive surface vocabulary"; Phase 5's glass tokens can layer on top of them.

## Next move

Checkpoint with Seth on Phase 3 dispatch. Phase 3 is the explicitly highest-risk phase (SwiftUI Native Bridge, 1259-line implementation.md, audit budgeted "at least one remediation loop"). The dispatch should include:

- A pre-Phase-3 architect amendment carrying forward the `objc_collections.cr` link-gap repair note (now urgent: Phase 3's bridge work will substantially expand the native bridge surface; ideal time to repair the link gap is alongside Phase 3's commits).
- A reminder to Phase 5's eventual Implementer about the opaque-background-baseline axe pattern from Phase 2 remediation.
- The remediation Implementer's pre-existing Implementer-flagged concerns from the Phase 2 handoff: `.am-panel` gradient regression risk if downstream themes use `background:` shorthand, and the dialog `.showModal()` not yet exercised in interactive test.

Phase 2 deliverables are merged ff into `feature/utility-first-css-asset-pipeline` (HEAD `37a8b63`), tagged `phase-02-passed-2026-05-20`, branch deleted. Ledger should now mark Phase 2 PASSED.
