# Phase 2 — Responsive Web Fluid Resize

**Tier:** 1 + 2 (Brand + Platform Default)
**Depends on:** Phase 1 (Design Token Foundation) — needs breakpoint tokens and the spacing scale
**Blocks:** Phase 6 (Demo App) for the desktop↔mobile resize story
**Estimated remediation budget:** 1 loop

---

## Why this phase exists

Today the web renderer emits views with **absolute pixel constraints**. Examples from `src/ui/renderers/web_renderer.cr`:

- Dialogs: `min-width: 270px; max-width: 400px`
- Many views call `minimum_width`/`maximum_width` directly and emit literal pixel values.
- No viewport meta tag in generated HTML.
- Container queries (declared in `src/components/css/config/css_config.cr`) are config stubs — the generator is not implemented.

The user-visible consequence: resizing the browser window between desktop and mobile widths does not smoothly reflow. Mobile widths overflow or clip. The "same demo on desktop and mobile should fluidly transition" experience does not exist.

This phase rebuilds the web responsiveness story on three pillars:

1. **Replace fixed pixel constraints with `clamp(min, ideal, max)`** for every dimension that should scale with viewport.
2. **Implement container query generation** so card/panel layouts adapt to their parent, not just the viewport.
3. **Mobile-first defaults** — base styles target the smallest viewport; breakpoint utilities layer desktop enhancements on top.

## Scope summary

In scope:

- `web_renderer.cr` and supporting files: replace hard-coded sizing with token-driven `clamp()` / `min()` / `max()` CSS functions where appropriate.
- Implement the container query generator. The stub in `src/components/css/config/css_config.cr` becomes a real generator emitting `@container (min-width: ...) { ... }` blocks.
- Emit `<meta name="viewport" content="width=device-width, initial-scale=1">` and any other required `<head>` elements for responsive HTML.
- Enforce 44×44 minimum touch target at all viewports for interactive widgets (Button, IconButton, MenuButton, Toggle, Checkbox, Slider thumb, Stepper, etc.). The token system from phase 1 provides the minimum-size value; the web renderer reads it.
- Add a "responsive primitive" helper to the View API: `fluid(min: ..., ideal: ..., max: ...)` that the renderer translates to `clamp()`. Use this in new code; leave existing code that uses raw pixel values intact unless touched.
- Migrate the existing `examples/web_design_system_demo.cr` and `output/` HTML to use the new sizing approach so the demo itself reflows correctly.
- Specs for: clamp emission, container query emission, viewport meta presence, touch target enforcement.

Out of scope:

- Native responsive (covered in phase 3 indirectly — SwiftUI handles size classes natively).
- The four-up demo app (phase 6).
- Changing the visual design language. Reflow ≠ redesign.
- Removing breakpoint media queries entirely. They coexist with container queries; container queries handle component-internal layout, media queries handle page-level structure.

## Acceptance summary

Phase 2 is done when:

- Loading the existing web design system demo at viewports 1280 / 768 / 375 / 320 produces no horizontal overflow, no clipped touch targets, and a visually continuous transition when the browser is resized live.
- Container query output is present in the generated CSS for at least three components (Card, Form, NavigationSplitView counterpart).
- All interactive widgets meet 44×44 touch target at all tested viewports.
- The full spec suite passes.

Detailed checks in `validation.md`.

## Risk notes

- The web design system demo (`output/*.html`) is multi-page and already has accessibility audits in place (axe + IBM Equal Access). Changing sizing must not regress accessibility scores.
- Replacing hard-coded pixel values is mechanical but easy to do wrong — e.g., `clamp(0, ideal, max)` collapses on small viewports. Validator screenshots will catch this.
- Container queries require `container-type: inline-size` on the parent. The implementer must wire this consistently or the queries fire on the wrong element.

## Briefing documents

- Implementer: `implementation.md`
- Validator: `validation.md`
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
