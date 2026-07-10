# Accessibility Contract

This document is the agent-facing accessibility contract for generated
design-system web views. It captures the work that made the current proof pass
browser, axe, IBM Equal Access, keyboard, contrast, reduced-motion, and
accessibility-tree checks, then turns that work into reusable rules.

The goal is cheap, easy, high-quality interfaces. Cheap does not mean skipping
accessibility. Cheap means the component owns the markup, state wiring, default
attributes, keyboard behavior, and validation hooks so a view author does not
have to rediscover them for every screen.

## Naming Boundary

Use generic public names: Button, Card, FormField, Fieldset, Dialog, Tabs,
Carousel, DataTable, Chart, Timeline, Section, Panel, Alert, Toast, and similar
known interface patterns.

Amber-era names are compatibility details only:

- `am-*` CSS classes
- `data-amber-*` behavior aliases
- `AmberDesignSystem` runtime alias
- `amber-design-system-*` generated compatibility files

New docs, templates, and examples should describe the public contract as Asset
Pipeline design-system behavior and `Components::DesignSystem::*` components.

## Component Responsibilities

A promoted component is responsible for its accessibility contract by default.
The caller should provide content and intent, not low-level wiring.

Every promoted component must define:

- Native element or role choice.
- Accessible name source.
- Required ids and relationships.
- Disabled, loading, selected, expanded, invalid, and busy states when relevant.
- Keyboard behavior when the component is interactive.
- Focus behavior on open, close, filter, validation, and DOM replacement.
- Light, dark, hover, focus, active, invalid, and reduced-motion states.
- What visible text, live-region text, or source-data fallback communicates the
  same information as color, iconography, animation, or chart geometry.
- Neutral `data-ap-*` hooks, with `data-amber-*` aliases only while the alpha
  compatibility migration requires them.

Raw HTML slots are allowed only for narrow migration paths. When a raw slot is
used, the component documentation must state which accessibility obligations
remain with the caller.

## Component Matrix

Use this matrix when deciding whether a view can use an existing primitive or
needs a new one.

| Component | Owns By Default | Caller Must Still Provide |
| --- | --- | --- |
| PageShell | Skip link, optional visible `h1`, labelled `main`, focus target | Full document envelope, primary navigation, script tags until a document primitive lands |
| LandingHero | Visible landing `h1`, escaped text, structured button/link actions, labelled toolbar wrapper | Inner toolbar control semantics and labelled raw aside/preview content |
| PageHero | Visible title/body anatomy and optional aside position | Accessible raw aside content when using the child slot |
| OrderSummary | Labelled summary region, native seat range field, add-on checkboxes, total hooks, polite note | Product-specific totals, pricing rules, and runtime calculation behavior |
| Section / Panel | Heading/id relationship and labelled region semantics | Meaningful heading text and vetted raw body HTML |
| Button | Native button element, disabled/loading/selected state attributes | Visible label or explicit accessible label for icon-only buttons |
| FormField | Label/control relationship, native attributes, error wiring when supplied | Correct field intent, validation rules, and status copy |
| Fieldset | Native group boundary and legend | Related controls only; no unrelated actions inside the group |
| ValidatedForm | Submit/status wrapper, validation hooks, live region | Fields with native validation attributes and stable ids |
| AuthForm / PaymentForm | Id prefixes, grouped controls, native autocomplete, status hooks | Product-specific copy and any real network submission |
| Dialog | Native dialog anatomy, name, close hooks | Opener button relationship and action content |
| Tabs / Carousel | ARIA relationships, controls, status hooks | Meaningful tab/slide content and no hidden critical data |
| DataTable | Table semantics, caption/header pattern, row state vocabulary | Accurate source data and state labels |
| Chart / Heatmap | Token-backed visual plus accessible fallback pattern | Data values, captions, and non-color-only meaning |
| Toast / Alert | Role/live-region defaults and dismiss hooks where relevant | Human-readable status copy and appropriate tone |
| VisualBand | Static band anatomy and escaped text | Vetted accessible SVG/HTML when using the raw visual slot |
| ShowcasePreview | Labelled static preview frame, escaped text, static rail/list anatomy with current item state | Vetted non-interactive raw badge/status HTML and visible or screen-reader-only non-color status copy |

## Page Baseline

Every generated page must include:

- `<html lang="en">`
- `<meta name="viewport" content="width=device-width, initial-scale=1">`
- A meaningful `<title>`
- A skip link when repeated navigation exists
- Exactly one `<h1>`
- `main#main`
- Labelled navigation landmarks when navigation exists
- Unique ids
- Visible focus states
- No horizontal overflow at 390px or 320px
- Explicit light and dark theme controls or a documented inherited theme
  contract

## Form Baseline

Use browser-native semantics first, then layer vanilla JavaScript for quality of
life validation and status copy.

Fields must have:

- A `label[for]`, wrapping label, `aria-label`, or `aria-labelledby`.
- Stable ids.
- Appropriate `name` attributes for real forms.
- `aria-describedby` for help text, errors, and shared status.
- Visible error text with stable ids.
- `aria-invalid="true"` while invalid.
- `role="status"` or `aria-live="polite"` for submit or validation status.

Use HTML5 attributes before JavaScript:

| Field Type | Required Defaults |
| --- | --- |
| Email | `type="email"`, `autocomplete="email"`, `inputmode="email"` when useful |
| Password sign-in | `type="password"`, `autocomplete="current-password"` |
| Password creation | `type="password"`, `autocomplete="new-password"`, `minlength`, visible policy |
| Password confirmation | `aria-describedby`, JS match check, status text |
| Search | `type="search"`, labelled field, result count live region |
| Telephone | `type="tel"`, `autocomplete="tel"`, `inputmode="tel"` |
| Numeric quantity | `type="number"` or `inputmode="numeric"` plus min/max/step when known |
| Card number | `autocomplete="cc-number"`, `inputmode="numeric"`, pattern or JS rule text |
| Card expiry | `autocomplete="cc-exp"`, `inputmode="numeric"`, future-date rule text |
| Card CVC | `autocomplete="cc-csc"`, `inputmode="numeric"`, length rule text |

Validation helpers must not replace native validation attributes. They enhance
the experience with clearer feedback, formatting, password matching, Luhn
checks, and expiry checks.

## Interaction Baseline

Interactive components must be operable by keyboard and pointer.

- Buttons are real `<button>` elements unless navigation requires `<a>`.
- Links navigate and buttons act; do not swap their semantics for styling.
- Dialogs use `<dialog>` where practical, move focus inside on open, trap focus
  while modal, close with Escape where appropriate, and return focus to the
  opener.
- Disclosure controls use `aria-expanded` and an owned panel relationship.
- Tabs use `tablist`, `tab`, `tabpanel`, `aria-selected`, `aria-controls`, and
  roving focus.
- Carousels use real previous/next buttons, no default auto-rotation, and a
  polite status region for slide changes.
- Filters and searches announce result counts.
- Toasts and async updates expose status through a live region and do not rely
  on animation alone.

## Data Visualization Baseline

Charts, heatmaps, timelines, and SVG visuals must have a text or table
equivalent.

- Simple charts should render first-party SVG plus a source-data table.
- Heatmaps must expose the underlying values in text/table form.
- Color cannot be the only signal for status or intensity.
- Decorative SVG should be `aria-hidden="true"`.
- Semantic SVG should have `role="img"` and an accessible name.
- Motion must be progressive enhancement and respect
  `prefers-reduced-motion`.

## Automated Evidence

Automated checks are required, but they are not the entire accessibility review.
They prove that common regressions did not slip in; they do not prove that the
content is meaningful or that every interaction is pleasant.

Run the fast ladder first:

```bash
crystal spec spec/components/examples/example_components_spec.cr
crystal run scripts/validate_web_demo.cr
git diff --check
```

For meaningful UI, behavior, or accessibility changes, run:

```bash
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

The reusable target is:

```bash
asset_pipeline validate --fast
asset_pipeline validate --browser
asset_pipeline validate --a11y
asset_pipeline validate --full
```

Until that CLI exists, use the current Crystal scripts as the source of truth.

For fast snippet-level feedback, require `spec/spec_helper` and use the shared
matchers in `spec/support/accessibility_matchers.cr`:

```crystal
expect_no_bootstrap_shaped_classes(html)
expect_no_duplicate_ids(html)
expect_accessible_control(html, "email")
expect_error_wiring(html, "email", "email-error")
expect_live_region(html, "form-status")
expect_describedby_targets_exist(html)
expect_no_inline_event_handlers(html)
expect_no_positive_tabindex(html)
```

These helpers are intentionally not a browser replacement. They catch common
agent mistakes in rendered snippets before the full static/browser/axe/IBM
matrix runs.

## Drift Gate For Refactors

When extracting demo markup or JavaScript into reusable components, the default
expected output is no design drift.

Before editing:

```bash
crystal run examples/web_design_system_demo.cr
rm -rf output/web-design-system-before test-results/web-design-system-before
mkdir -p output/web-design-system-before
cp output/web-design-system-*.html output/web-design-system-before/
crystal run scripts/validate_web_demo.cr
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
cp -R test-results/web-design-system test-results/web-design-system-before
```

After editing:

```bash
crystal run examples/web_design_system_demo.cr
diff -ru output/web-design-system-before output \
  --exclude='amber-design-system-*' \
  --exclude='brand-kit.html'
crystal run scripts/validate_web_demo.cr
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

The demo generator should shrink during extraction. If generated HTML,
screenshots, or line counts drift, the phase note must say whether the drift is
intentional, accessibility-improving, rasterization noise, or a regression that
must be fixed before continuing.

## Promotion Checklist

Before a demo pattern becomes public API:

- It has a generic `Components::DesignSystem::*` name.
- It renders semantic HTML with stable ids and labels.
- It owns native attributes and ARIA relationships that callers would otherwise
  have to remember.
- It emits neutral `data-ap-*` hooks for runtime behavior.
- It documents any compatibility aliases.
- It has focused specs for anatomy, escaping, variants, states, and ids.
- It appears in `component-api.md` and `component-catalog.md`.
- It passes static validation, browser smoke, axe, and IBM audits when used in
  the demo or a fixture.
- It does not require Node, Stimulus, inline handlers, or a hard chart
  dependency.
