# Design-System Agent Playbook

This playbook is for coding agents generating design-system web views with
Asset Pipeline. It assumes Milestone 1 web scope: no build step, vanilla
JavaScript, semantic HTML, token-backed styling, and automated accessibility
evidence.

## Start Here

Read these in order:

1. `docs/web-design-system/visual-language.md`
2. `docs/web-design-system/accessibility-contract.md`
3. `docs/web-design-system/component-contracts.md`
4. `docs/web-design-system/component-catalog.md`
5. `docs/web-design-system/agent-dx-gap-analysis.md`
6. `docs/web-design-system/evidence.md`

## Non-Negotiables

- Use canonical design-system components or documented canonical primitives for
  interactive UI. Do not hand-roll controls unless the needed primitive is
  missing and the gap is documented.
- Use generic component APIs and neutral `--ap-*` semantic tokens. Current
  `am-*` classes are compatibility selectors; do not mint new `am-*` classes
  for app-local wrappers. Co-emit neutral `data-ap-*` behavior hooks with
  current `data-amber-*` compatibility hooks during migration.
- Use native HTML semantics first: labels, fieldsets, real buttons, real links,
  real forms, real tables, native dialogs where practical.
- Treat accessibility as part of the component API. Do not leave labels,
  ids, ARIA relationships, keyboard behavior, live regions, or validation
  states as undocumented caller work.
- Use vanilla JavaScript behavior hooks only.
- Do not use Stimulus for design-system helpers.
- Do not use Node, npm, bundlers, transpilers, or Playwright for the canonical
  web proof.
- Do not use Bootstrap-shaped canonical classes: `.btn`, `.btn-primary`,
  `.card`, `.card-body`, `.form-control`, `.list-group`.
- Do not use inline event handlers such as `onclick`.
- Do not add a hard chart dependency. Use first-party SVG with a source-data
  table or isolate the dependency behind an adapter.
- Respect `prefers-reduced-motion`.
- Keep light and dark modes explicit and testable.

## Page Conventions

Every generated page should include:

- `<html lang="en">`
- `<meta name="viewport" content="width=device-width, initial-scale=1">`
- A meaningful `<title>`
- A skip link to `main`
- Exactly one `<h1>`
- `main#main`
- Labelled navigation when navigation exists
- Unique IDs
- Labelled form controls
- Visible focus states
- Status/live regions for dynamic updates
- No horizontal overflow at 390px and 320px

## Component Rules

### Buttons

Use a Button component with tone, emphasis, size, and state. Loading buttons
must expose `aria-busy`. Selected toggle-like buttons must expose
`aria-pressed`.

### Forms

Use native attributes before JavaScript:

- Email: `type="email"`, `autocomplete="email"`, `required` when needed.
- Password: `autocomplete="current-password"` or `new-password`.
- Numbers/card fields: `inputmode`, `autocomplete`, `pattern`, and visible
  pattern messages.
- Errors: visible text, `aria-invalid="true"`, and `aria-describedby`.
- Submit status: `role="status"` or a polite live region.

### Tables

Use real `<table>` markup with captions, column headers, and row state
semantics. Row status should include an indicator, subtle background, hover
state, and accessible state text. Invalid rows should expose `aria-invalid`
where appropriate.

### Dialogs And Command Surfaces

Use the shared dialog/overlay pattern:

- Accessible name through `aria-labelledby` or `aria-label`.
- Focus moves inside on open.
- Focus stays inside while modal.
- Escape closes where appropriate.
- Focus returns to the opener.

### Tabs And Carousel

Use roving focus and explicit relationships:

- Tabs: `role="tablist"`, `role="tab"`, `role="tabpanel"`,
  `aria-selected`, `aria-controls`, `aria-labelledby`.
- Carousel: real previous/next buttons, no auto-rotation by default, current
  slide status in a polite live region.

### Charts And Heatmaps

Use visual summaries plus a source-data table. The SVG or heatmap cells can be
decorative, but the data must remain available to assistive technology.

## Recipe: Settings Page

Use this composition:

1. Page shell with skip link, labelled nav, `main#main`, and one `h1`.
2. Section headings for profile, preferences, and danger zone.
3. `FormField` for text/email/search/select fields.
4. Native checkboxes/radios wrapped in labelled controls.
5. `role="status"` for saved/validation state.
6. Button variants for primary save, secondary reset, and destructive action.
7. Validate static semantics and one browser smoke capture.

## Recipe: Checkout Or Payment Page

Use this composition:

1. Pricing or order summary as an `aside` with an accessible label.
2. Email field with native email semantics.
3. Payment field set with card name, number, expiry, and CVC.
4. `inputmode`, `autocomplete`, `pattern`, and pattern messages.
5. Luhn and expiry validation through the shared validation helper.
6. Promo/status text in a polite status region.
7. No real network submission in demos.

## Recipe: Dashboard With Data And Dialog

Use this composition:

1. Labelled dashboard nav.
2. Search/filter field with `aria-controls` and a live result count.
3. Data table with caption, headers, row ids, row states, and table fallback.
4. Command palette or dialog trigger as a real button.
5. Dialog with labelled title/description, focus trap, escape, and focus return.
6. Reduced-motion check for row updates and overlays.

## Fast Validation Ladder

Use the fastest useful check first:

```bash
crystal spec spec/support/accessibility_matchers_spec.cr
crystal spec spec/components/examples/example_components_spec.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/validate_design_system_manifest.cr
git diff --check
```

Then run browser evidence when the view is meaningfully changed:

```bash
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

Future target:

```bash
asset_pipeline validate --fast
asset_pipeline validate --browser
asset_pipeline validate --a11y
asset_pipeline validate --full
```

## When You Must Hand-Roll

If the needed component does not exist:

1. Use native HTML semantics.
2. Use neutral `--ap-*` semantic tokens and a generic app-local class name.
   Use existing `am-*` compatibility classes only when matching a documented
   promoted component anatomy.
3. Add `data-component="new-component-name"`.
4. Add stable behavior hooks. The neutral hook contract is
   `data-ap-<behavior>`; co-emit the current `data-amber-<behavior>` aliases
   because they map 1:1 during migration.
5. Add labels, descriptions, live regions, and keyboard behavior.
6. Add a component contract section.
7. Add a spec and validation coverage.
8. Record the gap so the hand-rolled surface can be promoted later.
