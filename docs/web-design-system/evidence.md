# Evidence Matrix

This file summarizes the current automated evidence for the design-system web
proof. The canonical source artifacts live in `test-results/web-design-system/`.
Compatibility copies are mirrored to `test-results/amber-design-system/` during
the alpha migration.

## Canonical Surface Audit

`crystal run scripts/validate_web_demo.cr` writes:

- `static-audit.json`
- `canonical-surface-audit.json`

The canonical audit scans the seven generated demo pages after runtime scripts
and styles are stripped. It fails if new canonical output contains these
Bootstrap-shaped class families:

- `.btn`
- `.btn-primary`
- `.card-body`
- `.form-control`
- `.list-group`

Legacy files such as `src/generators/brand_kit.cr`,
`examples/interactive_app.cr`, and `docs/FRAMEWORK_INTEGRATION.md` are
documented as historical integration material, not the new design-system
direction. Migration examples live in `docs/web-design-system/migration.md`.

## Screenshot Matrix

`crystal run scripts/capture_web_demo_screenshots.cr` writes
`browser-audit.json` and 57 PNG screenshots.

| Coverage | Count | Purpose |
| --- | ---: | --- |
| Desktop light/dark at 1440px | 14 | Seven pages in both themes |
| Mobile light/dark at 390px | 14 | Seven pages in both themes |
| Reflow light/dark at 320px | 14 | WCAG reflow stress pass |
| Reduced-motion screenshots | 10 | Eight reduced-motion cases plus open-state captures |
| Interactive state screenshots | 7 | Invalid forms, command palette, tabs/carousel, dialogs |

The browser audit also writes `viewport_summary` so this matrix can be checked
without counting files manually.

## Reduced Motion Matrix

`reduced-motion-report.json` currently passes eight cases and records the
surface counts per case.

| Case | Surfaces |
| --- | --- |
| `overview-reduced-motion` | sticky hover (1), theme switcher (3) |
| `pricing-reduced-motion` | theme switcher (1), forms (1) |
| `forms-reduced-motion` | theme switcher (1), forms (4) |
| `dashboard-command-reduced-motion` | chart bars (4), table rows (4), theme switcher (1) |
| `timeline-reduced-motion` | timeline reveal (6), SVG sequence (5), theme switcher (1) |
| `collaboration-reduced-motion` | theme switcher (1) |
| `patterns-reduced-motion` | SVG sequence (5), carousel (1), dialog (1), tabs (1), theme switcher (1) |
| `patterns-dialog-reduced-motion` | SVG sequence (5), carousel (1), dialog (1), tabs (1), theme switcher (1) |

The named motion surface contract is:

- sticky hover
- timeline reveal
- SVG sequence
- chart bars
- table rows
- carousel
- dialog
- tabs
- theme switcher
- forms

## Accessibility Evidence

The current automated accessibility path uses no screen-reader automation.

- `axe-audit.json`: axe-core passes the seven pages in light and dark themes.
- `ibm-equal-access-audit.json`: IBM Equal Access passes the same page/theme
  matrix with zero violation/fail results.
- `accessibility-tree-report.json`: Chrome DevTools Protocol
  `Accessibility.getFullAXTree` captures 50 cases, 12,647 accessibility nodes,
  role/name/value snapshots, and zero failures.
- `keyboard-traversal.json`: real CDP `Tab` and `Shift+Tab` traversal checks.
- `touch-targets.json`: interactive target sizing checks.
- `contrast-report.json` and `contrast-report.csv`: sampled text/background
  contrast checks with per-sample provenance.

## Font Strategy

Fonts are configurable assets, not a hidden demo dependency.

- `Components::Assets::FontAsset.cdn` emits preconnect plus stylesheet links for
  hosted providers such as Google Fonts.
- `Components::Assets::FontAsset.self_hosted` emits font preload links plus
  `@font-face` CSS with `font-display: swap`.
- `Components::Assets::FontManifest` combines both strategies so apps can use a
  CDN for prototypes and self-hosted `woff2` files for production or offline
  deployments.
- The generated demo uses Inter for product UI, Newsreader for display moments,
  and system fallbacks through token variables.
- `spec/components/assets/font_asset_spec.cr` validates CDN links,
  self-hosted preload tags, `@font-face`, and mixed manifests.

## Chart Strategy

`SimpleChartComponent` is first-party by default.

- `adapter="first-party-svg"` emits token-backed SVG bars and keeps the source
  table as the accessible data path.
- `adapter="external"` emits an isolated `data-chart-external-root` and
  serialized data attributes so a future chart dependency can mount without
  becoming part of the default runtime.
- Unknown adapters raise `ArgumentError`.

## Passing Commands

```bash
crystal spec spec/components/css spec/components/assets/font_asset_spec.cr \
  spec/components/examples/example_components_spec.cr \
  spec/ui/renderers/web_renderer_spec.cr
crystal run examples/web_design_system_demo.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/validate_design_system_manifest.cr
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
git diff --check
```

`validate_design_system_manifest.cr` reads
`docs/web-design-system/web-demo.routes.yml` by default and writes
`test-results/web-design-system/static-manifest-audit.json`. It is currently a
static manifest audit only; browser, axe, IBM, keyboard, contrast, and
reduced-motion evidence still come from the dedicated scripts above.
