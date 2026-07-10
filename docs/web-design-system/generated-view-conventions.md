# Generated View Conventions

These are the default conventions for agent-generated design-system web views. They are
derived from the current demo validators and should become reusable validation
rules rather than demo-specific grep checks. For the full accessibility
contract behind these conventions, read
`docs/web-design-system/accessibility-contract.md`.

## Required Page Shell

Every generated page should render:

```html
<html lang="en" data-ap-theme="light">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Page title</title>
  </head>
  <body>
    <a class="am-skip-link" href="#main">Skip to content</a>
    <nav aria-label="Primary">...</nav>
    <main id="main" tabindex="-1">
      <h1>Page heading</h1>
      ...
    </main>
  </body>
</html>
```

Rules:

- Exactly one `h1`.
- A real `main` landmark.
- Unique ids.
- Labelled navigation landmarks.
- A skip link when the page has repeated navigation.
- No horizontal overflow at 390px or 320px.
- Use neutral `data-ap-theme` and `--ap-*` tokens as the public contract.
  Current `am-*` shell classes and `--amber-*` variables are compatibility
  output while the class API migrates.

## Required Control Semantics

Every `input`, `select`, and `textarea` must have one of:

- A wrapping `label`.
- A `label[for=id]` relationship.
- `aria-label`.
- `aria-labelledby`.

Every dynamic error must have:

- Visible text.
- Stable id.
- `aria-invalid="true"` on the invalid control.
- `aria-describedby` on the control referencing the error id.

Every dynamic status must use:

- `role="status"` or `aria-live="polite"`.
- Human-readable text after updates.

## Required Theme Contract

Generated pages should expose either:

- `data-ap-theme-toggle`, or
- explicit `data-ap-theme-set="light"` / `data-ap-theme-set="dark"` controls.

During the alpha migration, co-emit the current `data-amber-*` aliases when a
component is meant to work with older generated pages. The neutral `data-ap-*`
hook is the public design-system contract.

The runtime must update:

- `<html data-ap-theme>`
- `<html data-amber-theme>` while compatibility aliases are enabled
- `color-scheme`
- `aria-pressed` on theme buttons
- visible status text when provided

## Required Behavior Hook Contract

Use stable hooks rather than inline handlers. New component output should use
the neutral `data-ap-*` hook and may co-emit the current compatibility alias
until the migration is complete.

| Behavior | Neutral Hook | Compatibility Alias |
| --- | --- | --- |
| Dialog open | `data-ap-dialog-open` | `data-amber-dialog-open` |
| Dialog close | `data-ap-dialog-close` | `data-amber-dialog-close` |
| Disclosure | `data-ap-disclosure` | `data-amber-disclosure` |
| Form validation | `data-ap-validate` | `data-amber-validate` |
| Password policy | `data-ap-password` | `data-amber-password` |
| Password confirmation | `data-ap-password-confirm` | `data-amber-password-confirm` |
| Card number formatting | `data-ap-card-number` | `data-amber-card-number` |
| Card expiry formatting | `data-ap-card-expiry` | `data-amber-card-expiry` |
| Card CVC formatting | `data-ap-card-cvc` | `data-amber-card-cvc` |
| Live search | `data-ap-live-search` | `data-amber-live-search` |
| Table filter | `data-ap-filter` | `data-amber-filter` |
| Command palette open | `data-ap-command-open` | `data-amber-command-open` |
| Command palette panel | `data-ap-command-panel` | `data-amber-command-panel` |
| Tabs | `data-ap-tabs` | `data-amber-tabs` |
| Carousel | `data-ap-carousel` | `data-amber-carousel` |
| Timeline reveal | `data-ap-reveal` | `data-amber-reveal` |
| Sticky hover | `data-ap-sticky-hover` | `data-amber-sticky-hover` |

## Forbidden Output

Canonical design-system output must not include:

- `.btn`
- `.btn-primary`
- `.card-body`
- `.form-control`
- `.list-group`
- Inline `onclick`, `oninput`, or similar handlers
- Stimulus controllers for design-system helpers
- `Chart.js` as a default chart path
- Node/npm build assumptions
- Undefined semantic CSS variables

## Required Evidence For New Pages

For every new canonical page or template:

- Static semantic audit passes.
- Canonical-surface audit passes.
- Light and dark theme behavior is verified.
- 390px and 320px responsive states are checked.
- Keyboard traversal is checked for interactive surfaces.
- Reduced-motion behavior is checked for animated surfaces.
- Axe and IBM Equal Access are run before handoff.
