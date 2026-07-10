# Phase Notes

## Phase 0 - Canonical Repo And Baseline

Changed files:

- `src/components.cr`
- `src/components/elements/base/html_element.cr`

Tests run:

- Initial focused baseline failed because `Components::Page` called a missing
  `lang`/`html` DSL path and `UI::Web::Renderer` referenced an unrequired
  `Iframe` element.
- After small compile fixes:
  `crystal spec spec/components/css spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`

Result:

- 232 examples, 0 failures.

Why acceptable:

- The fixes were minimal baseline blockers required to run any relevant web
  proof specs. Unrelated dirty Apple/Android validation files were not touched.

## Phase 1-3 - Tokens, Cascade, Variants

Changed files:

- `src/components/css/tokens/amber_theme.cr`
- `src/components/css/config/css_config.cr`
- `src/components/css/engine/css_generator.cr`
- `src/components/css/engine/css_parser.cr`
- `src/components/variants/component_variant.cr`
- `src/ui/theme.cr`
- `src/ui/renderers/web_renderer.cr`
- `src/components/base/component.cr`

Tests run:

- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`

Result:

- 252 examples, 0 failures.

Why acceptable:

- Light/dark Amber variables emit through the token layer.
- Semantic utility classes resolve to token variables.
- Web buttons/cards emit `am-*` classes and state attributes.
- Common web-renderer text roles, controls, panels, dialogs, sheets, popovers,
  menus, and form surfaces now prefer Amber CSS variables instead of legacy
  fixed color literals.
- `data-testid` behavior remains covered by existing renderer tests.

Deferred:

- Native renderer cascade is documented only; implementation is future work.

## Phase 4-6 - Components, Motion, Fonts, Charts

Changed files:

- `src/components/examples/button_component.cr`
- `src/components/examples/card_component.cr`
- `src/components/examples/data_table_component.cr`
- `src/components/examples/simple_chart_component.cr`
- `src/components/examples/counter_component.cr`
- `src/components/examples/form_component.cr`
- `src/components/examples/chat_component.cr`
- `src/components/examples/live_search_component.cr`
- `src/components/assets/font_asset.cr`
- `public/js/amber-design-system.js`

Tests run:

- Same focused spec command as above.

Result:

- 252 examples, 0 failures.

Why acceptable:

- Button/card examples no longer emit Bootstrap-shaped canonical classes.
- Counter/form/chat/live-search examples have been moved onto token-backed
  design-system compatibility classes so they no longer present Bootstrap-like
  classes as the public API.
- Data table row states use strong indicators, subtle backgrounds, richer hover,
  smooth transitions, and accessible labels.
- Motion helpers are vanilla JS and check reduced-motion preferences.
- Font API covers CDN and self-hosted delivery.
- Simple chart proof is first-party SVG and declares its adapter boundary.

Deferred:

- Full dialog/toggle/slider Crystal wrappers remain future catalog work; the
  demo proves native web controls styled by the token system.

## Phase 7 - Demo And Screenshot Validation

Changed files:

- `examples/amber_design_system_demo.cr`
- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `output/amber-design-system-demo.html`
- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/*.png`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`

Artifacts:

- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/desktop-light.png`
- `test-results/amber-design-system/desktop-dark.png`
- `test-results/amber-design-system/mobile-light.png`
- `test-results/amber-design-system/mobile-dark.png`

What passes:

- No-Node static audit verifies the required demo sections, representative
  portfolio components, vanilla theme-control contract, absence of canonical
  Bootstrap classes, absence of Stimulus/Chart.js/Node runtime terms in the
  Amber demo and helper JS, and neutral letter-spacing in the generated demo.
- Crystal browser audit uses Chrome/Chromium DevTools protocol to click
  `data-amber-theme-toggle`, verify the root theme, label, and `aria-pressed`
  state update, check overflow/canonical-class regressions, and capture
  desktop/mobile light/dark screenshots.
- Manual review confirmed legible desktop/mobile light and dark screens after
  fixing neutral/soft button contrast, desktop amount-column truncation, and
  mobile table overflow.
- Companion critique covered screenshots, component APIs, generated CSS, docs,
  and accessibility behavior. Follow-up fixes added table selected/invalid
  semantics, interactive card semantics, chart descriptions, idempotent vanilla
  JS helpers, CDN font preconnect, and stricter screenshot overflow audits.
- A later polish pass simplified portfolio-facing copy, changed the theme
  toggle label to describe the next action, improved mobile nav scanning,
  increased dark-mode microtext contrast, made loading skeletons visible, and
  removed an undefined surface variable reference from generated CSS.
- A higher-bar visual pass replaced the plain hero metric panel with a composed
  product-preview showcase, removed generic radial-glow decoration, tightened
  card/panel radii, and added a static audit check that the showcase remains in
  the generated demo.
- The latest functional demo pass split the proof into overview, foundations,
  inputs, data, page-style, and interactions HTML pages. It added vanilla
  visual-only behavior for counter, chat submit, live search, and form
  validation. The Crystal browser audit now types/clicks those flows in Chrome,
  alongside the theme toggle, table filter, dialog, overflow, and screenshot
  checks.
- The brand pass moved toward a warm SaaS studio direction: stronger
  warm-action/cyan/indigo theme colors, a subtle diagonal composition
  treatment, and a dedicated input dashboard showing default, active, success,
  invalid, disabled, selection, range, and messaging states.

Why acceptable:

- The demo now shows a multi-page design-system catalog: overview, foundations,
  input-state dashboard, explicit theme controls, component matrices, badges,
  alerts, CRUD data, chart, native controls, dashboard/settings/detail/command
  page styles, working visual-only form wrapper, live search, chat, counter,
  empty state, loading skeleton, timeline, toast, and motion.
- The canonical validation path is Crystal/static HTML/browser only. The prior
  Node/Playwright screenshot helper was replaced with a Crystal browser audit
  so the web proof remains no-build vanilla JavaScript.

## Phase 8 - Docs And Catalog

Changed files:

- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/migration.md`
- `docs/web-design-system/native-cascade-contract.md`
- `docs/web-design-system/phase-notes.md`
- `examples/README.md`
- `README.md`

Why acceptable:

- A future agent can find the theme API, component state contract, migration
  path, validation commands, screenshot artifacts, and native cascade boundary
  without rereading the original transcript.
- Pre-existing Stimulus/import-map/Bootstrap-shaped examples are explicitly
  marked historical; `examples/amber_design_system_demo.cr` is the canonical
  Milestone 1 example.

## Phase 9 - Frontloader Studio Breadth And Accessibility Pass

Changed files:

- `examples/amber_design_system_demo.cr`
- `public/js/amber-design-system.js`
- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `src/components/css/engine/css_generator.cr`
- `src/components/examples/data_table_component.cr`
- `src/ui/renderers/web_renderer.cr`
- `spec/components/css/amber_design_system_spec.cr`
- `spec/ui/renderers/web_renderer_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `examples/README.md`
- `README.md`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`

Artifacts:

- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/desktop-light.png`
- `test-results/amber-design-system/desktop-dark.png`
- `test-results/amber-design-system/mobile-light.png`
- `test-results/amber-design-system/mobile-dark.png`
- `test-results/amber-design-system/pricing-desktop-light.png`
- `test-results/amber-design-system/pricing-mobile-light.png`
- `test-results/amber-design-system/forms-desktop-light.png`
- `test-results/amber-design-system/forms-mobile-light.png`
- `test-results/amber-design-system/dashboard-desktop-light.png`
- `test-results/amber-design-system/dashboard-mobile-light.png`
- `test-results/amber-design-system/timeline-desktop-light.png`
- `test-results/amber-design-system/collaboration-desktop-light.png`
- `test-results/amber-design-system/collaboration-mobile-light.png`
- `test-results/amber-design-system/patterns-desktop-light.png`
- `test-results/amber-design-system/patterns-mobile-light.png`
- `test-results/amber-design-system/overview-reduced-motion.png`

What passes:

- Focused web proof specs: 252 examples, 0 failures.
- Static audit verifies the Frontloader Studio page manifest, landmarks, one
  `h1` per page, unique ids, labelled controls, semantic form/payment
  attributes, live regions, no inline handlers, no Bootstrap-shaped canonical
  classes, defined Amber variables, and no Node/Stimulus/Chart.js terms.
- Browser audit uses Chrome DevTools Protocol to verify computed light/dark
  theme changes, focus styling, accessibility-tree names, reduced-motion sticky
  hover behavior, pricing totals, payment validation, auth/password matching,
  dashboard filtering and command palette focus return, timeline reveal,
  collaboration search/chat, tabs, carousel, disclosure, native dialog,
  overflow, and screenshots.

Design choices:

- The demo is now a fictional Frontloader Studio AI launch-ops SaaS rather than
  a framework-branded catalog. The palette uses a warm action color, ink for
  work surfaces, teal for operational intelligence, and semantic tones for
  status.
- Forms use native HTML5 semantics first. JavaScript adds quality-of-life
  validation, formatting, password matching, and live status updates.
- Explicit light mode now emits `[data-amber-theme="light"]` variables so it
  overrides a dark OS/browser preference.
- Visual assets remain deterministic CSS/SVG-first instead of remote stock or a
  generated bitmap dependency.

Weak or deferred:

- The new page-level patterns are still demo markup, not all promoted Crystal
  wrappers. Form fields, page sections, tabs, carousel, command palette, and
  payment helpers are good candidates for future wrapper extraction.
- The accessibility audit is a strong automated smoke test, not a WCAG
  certification. It samples semantics, focus, computed style, reduced motion,
  validity, and layout; manual screen-reader review remains useful before a
  release.

## Phase 10 - Component Promotion And Audit Hardening

Changed files:

- `src/components.cr`
- `src/components/css/tokens/amber_theme.cr`
- `src/components/examples/button_component.cr`
- `src/components/examples/command_palette_component.cr`
- `src/components/examples/carousel_component.cr`
- `src/components/examples/dialog_component.cr`
- `src/components/examples/schedule_heatmap_component.cr`
- `src/components/examples/tabs_component.cr`
- `src/components/examples/timeline_component.cr`
- `examples/amber_design_system_demo.cr`
- `public/js/amber-design-system.js`
- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`

Artifacts:

- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- 36 browser screenshots in `test-results/amber-design-system/`, including
  desktop/mobile light/dark captures for all seven pages plus invalid form,
  command palette, tabs/carousel, dialog, and reduced-motion states.

What passes:

- Focused specs: 258 examples, 0 failures.
- Static audit verifies promoted component markers for command palette,
  schedule heatmap, timeline, tabs, carousel, and dialog.
- Browser audit verifies the expanded screenshot matrix, state captures,
  accessibility-tree names, sampled contrast ratios, reduced-motion behavior,
  command-palette keyboard behavior, tabs Home/End behavior, carousel keyboard
  behavior, native dialog focus wrap/return, and all prior pricing/forms/chat
  flows.

Design choices:

- The high-value page-local interactions are now reusable `StatelessComponent`
  wrappers, which keeps the demo aligned with the actual component system.
- The light-mode amber primary token was deepened so primary action text has
  stronger contrast while preserving the amber identity.
- Brand badges now use primary text over subtle brand fills so they read in
  both themes.
- The browser audit navigates after emulating media preferences so reduced
  motion is applied before JavaScript initializes.

Weak or deferred:

- Payment form and auth field wrappers are still page-level markup with shared
  vanilla helpers. They should be promoted next if the project continues toward
  a larger form package.
- The contrast sweep samples representative component text/background pairs.
  It is stronger evidence than string checks, but it is still not a full WCAG
  certification for every possible composition.

## Phase 11 - Form Promotion And Evidence Reports

Changed files:

- `src/components.cr`
- `src/components/examples/auth_form_component.cr`
- `src/components/examples/payment_form_component.cr`
- `src/components/examples/schedule_heatmap_component.cr`
- `examples/amber_design_system_demo.cr`
- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `scripts/axe_amber_demo_audit.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`
- `examples/README.md`
- `README.md`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`
- `crystal run scripts/axe_amber_demo_audit.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`

Artifacts:

- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/contrast-report.json`
- `test-results/amber-design-system/contrast-report.csv`
- `test-results/amber-design-system/axe-audit.json`
- 40 browser screenshots in `test-results/amber-design-system/`, including
  reduced-motion command-palette and dialog-open states.

What passes:

- Focused specs: 261 examples, 0 failures.
- Static audit verifies payment/auth components and the heatmap table fallback.
- Browser audit verifies 267 sampled contrast pairs with no contrast failures.
- Browser audit captures reduced-motion overlay states for command palette and
  dialog in addition to the prior page matrix.
- Axe-core audit runs through Crystal + Chrome DevTools Protocol, covers every
  demo page in light and dark themes, and fails on serious/critical WCAG-tagged
  violations.

Design choices:

- Payment and auth are now component proofs because they are the highest-state
  form surfaces in the demo.
- The heatmap keeps its compact visual representation, but now ships a
  visually-hidden table fallback so assistive technology can consume exact
  hour/activity pairs.
- Contrast evidence is written as JSON and CSV so a future reviewer can inspect
  the sampled pair matrix without trusting only a `failures=[]` line.

Weak or deferred:

- The contrast report is broad evidence, not an exhaustive generated proof for
  every possible token composition.
- A manual screen-reader walkthrough is still recommended before a release
  claim stronger than automated smoke-test coverage.

## Phase 12 - Independent A11y And Motion Evidence

Changed files:

- `src/components/css/tokens/amber_theme.cr`
- `src/components/examples/simple_chart_component.cr`
- `src/components/examples/timeline_component.cr`
- `examples/amber_design_system_demo.cr`
- `scripts/axe_amber_demo_audit.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `scripts/validate_amber_demo.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`
- `README.md`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`
- `crystal run scripts/axe_amber_demo_audit.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`

Artifacts:

- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/reduced-motion-report.json`
- `test-results/amber-design-system/contrast-report.json`
- `test-results/amber-design-system/contrast-report.csv`

What passes:

- Axe-core audit passes across all seven pages in light and dark themes with no
  serious or critical WCAG-tagged violations.
- Browser audit writes a reduced-motion report and fails if animated elements
  keep transition or animation durations above 10ms under reduced motion.
- Form error checks now assert invalid fields receive `aria-invalid` and
  described visible error text.
- `SimpleChartComponent` now includes a hidden source-data table fallback.

Design choices:

- Axe found real issues in the previous pass, so the primary amber action token
  was deepened again, timeline reveal starts from readable content, and the
  upload progress indicator now uses `role="progressbar"`.
- The chart follows the same accessibility pattern as the heatmap: keep the
  visual proof, add machine-readable tabular source data.

Weak or deferred:

- Manual screen-reader transcripts are still required before making a stronger
  accessibility claim than automated audit coverage.
- Keyboard traversal order and reflow/zoom screenshot artifacts remain good next
  additions.

## Phase 13 - Keyboard, Touch, Reflow, And Chart Fallback

Changed files:

- `src/components/examples/simple_chart_component.cr`
- `examples/amber_design_system_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `scripts/validate_amber_demo.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`
- `crystal run scripts/axe_amber_demo_audit.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`

Artifacts:

- `test-results/amber-design-system/keyboard-traversal.json`
- `test-results/amber-design-system/touch-targets.json`
- `test-results/amber-design-system/reduced-motion-report.json`
- `test-results/amber-design-system/contrast-report.json`
- 54 screenshots, including 320px reflow captures for every page in light and
  dark mode.

What passes:

- Browser audit passes with keyboard evidence for 51 cases, including 46 real
  synthetic Tab traversal cases and open command-palette/dialog focus-wrap
  checks, touch-target evidence for 47 cases, 385 sampled contrast pairs, and
  54 screenshots.
- Touch target audit fails controls below 24px; the pricing range input now has
  a 24px target height.
- Chart fallback is checked by static audit and component spec.

Weak or deferred:

- The keyboard report now records actual CDP `Tab` / `Shift+Tab` traversal and
  compares expected focusables as an ordered subsequence so native composite
  controls can expose internal stops without being misreported.
- Manual AT transcripts remain outside this automated pass.

## Phase 14 - Stateless Composition And Second A11y Engine

Changed files:

- `src/components/examples/button_component.cr`
- `src/components/examples/auth_form_component.cr`
- `src/components/examples/carousel_component.cr`
- `src/components/examples/form_field_component.cr`
- `src/components/examples/pricing_card_component.cr`
- `src/components/examples/theme_switcher_component.cr`
- `src/components.cr`
- `examples/amber_design_system_demo.cr`
- `scripts/validate_amber_demo.cr`
- `scripts/ibm_amber_demo_audit.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`
- `examples/README.md`
- `README.md`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`
- `crystal run scripts/axe_amber_demo_audit.cr`
- `crystal run scripts/ibm_amber_demo_audit.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`

Artifacts:

- `test-results/amber-design-system/ibm-equal-access-audit.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/keyboard-traversal.json`
- `test-results/amber-design-system/touch-targets.json`
- `test-results/amber-design-system/reduced-motion-report.json`
- `test-results/amber-design-system/contrast-report.json`
- 54 screenshots in `test-results/amber-design-system/`

What passes:

- Focused Crystal spec pass: 268 examples, 0 failures.
- Static audit passes across all seven generated pages.
- Browser evidence passes with 54 screenshots, 385 contrast samples, 51
  keyboard cases, 47 touch-target cases, and five reduced-motion cases.
- Axe-core passes all 14 page/theme cases.
- IBM Equal Access passes all 14 page/theme cases with zero violation/fail
  results.

Design choices:

- The demo now uses reusable stateless wrappers for theme switching, form
  fields, and pricing cards rather than hand-rolled canonical controls.
- `ButtonComponent` accepts safe `aria-*` and `data-*` passthrough attributes so
  interactive helpers can compose through the component layer without losing
  accessibility state.
- IBM Equal Access found issues that axe missed: unlabeled complementary
  landmarks, duplicate unnamed form landmarks, invalid `aria-label` use on
  generic divs, invalid email autocomplete, and carousel role/tabstop mistakes.
  Those were fixed in markup and components instead of suppressing the audit.

Weak or deferred:

- A manual screen-reader transcript is still the main remaining accessibility
  evidence gap.
- The IBM script fetches the browser engine at validation time, matching the
  existing axe pattern. Pinning a vendored copy can be considered if fully
  offline validation becomes required.

## Phase 15 - Component Contracts And Validation Depth

Changed files:

- `public/js/amber-design-system.js`
- `src/components/examples/payment_form_component.cr`
- `src/components/examples/simple_chart_component.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `scripts/validate_amber_demo.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/evidence.md`
- `docs/web-design-system/visual-language.md`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`
- `README.md`

Commands run:

- `crystal spec spec/components/examples/example_components_spec.cr`
- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`
- `crystal run scripts/axe_amber_demo_audit.cr`
- `crystal run scripts/ibm_amber_demo_audit.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`

Artifacts:

- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/evidence.md`
- `docs/web-design-system/visual-language.md`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/canonical-surface-audit.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/ibm-equal-access-audit.json`
- `test-results/amber-design-system/contrast-report.json`
- `test-results/amber-design-system/keyboard-traversal.json`
- `test-results/amber-design-system/touch-targets.json`
- `test-results/amber-design-system/accessibility-tree-report.json`
- 57 screenshots in `test-results/amber-design-system/`

What this phase adds:

- `FormFieldComponent`, `ThemeSwitcherComponent`, and `PricingCardComponent`
  now have explicit reuse specs proving caller-supplied copy, variants, data
  hooks, and ARIA hooks instead of only demo-specific output.
- Payment helper validation now includes Luhn card-number validation and
  future-expiry validation in addition to browser patterns.
- Browser audit now verifies Luhn failure, expired-card failure, valid payment
  success, promo status, and visible described errors.
- Static audit now writes an explicit canonical-surface report proving the seven
  generated pages do not emit Bootstrap-shaped `.btn`, `.btn-primary`,
  `.card-body`, `.form-control`, or `.list-group` classes.
- `SimpleChartComponent` now has an explicit `external` adapter boundary with
  an isolated mount root and preserved table fallback. Unknown adapters raise.
- Browser audit now writes a CDP `Accessibility.getFullAXTree` report with 50
  cases, 12,647 sampled accessibility nodes, role/name/value snapshots, and 0
  unnamed-control failures.
- Browser audit now records a viewport summary for 14 desktop light/dark, 14
  mobile light/dark, 14 320px reflow, 10 reduced-motion, and 7 interactive
  state screenshots.
- Reduced-motion evidence now records eight every-page plus command/dialog
  state cases and enumerates sticky hover, timeline reveal, SVG sequencing,
  chart bars, table rows, carousel, dialog, tabs, theme switcher, and form
  surfaces.
- Visual-language and evidence docs now spell out the palette, typography,
  layout, motion, accessibility, font-delivery, chart-adapter, screenshot, and
  reduced-motion decisions instead of leaving the taste target implicit.
- Final focused component spec pass: 44 examples, 0 failures.
- Final broader web proof spec pass: 274 examples, 0 failures.
- Static, browser, axe, and IBM Equal Access audits all pass.

Weak or deferred:

- Manual screen-reader transcript evidence is not included. That manual path
  was not used after the user asked to stop it.

## Phase 16 - Adversarial Closeout

Changed files:

- `docs/web-design-system/evidence.md`
- `docs/web-design-system/visual-language.md`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/README.md`
- `docs/web-design-system/phase-notes.md`
- `README.md`
- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`

Commands run:

- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_amber_demo.cr`
- `crystal run scripts/capture_amber_demo_screenshots.cr`
- `crystal run scripts/axe_amber_demo_audit.cr`
- `crystal run scripts/ibm_amber_demo_audit.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr`
- `git diff --check`
- `claude --tools '' --no-session-persistence --max-budget-usd 0.75 -p ...`

Artifacts:

- `test-results/amber-design-system/canonical-surface-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/accessibility-tree-report.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/ibm-equal-access-audit.json`
- `test-results/amber-design-system/reduced-motion-report.json`
- `test-results/amber-design-system/contrast-report.json`
- `test-results/amber-design-system/keyboard-traversal.json`
- `test-results/amber-design-system/touch-targets.json`
- 57 screenshots in `test-results/amber-design-system/`

What passes:

- Canonical-surface audit passes with 0 hits for `.btn`, `.btn-primary`,
  `.card-body`, `.form-control`, and `.list-group` across the seven generated
  demo pages.
- Browser audit passes with 14 desktop light/dark screenshots, 14 mobile
  light/dark screenshots, 14 320px reflow screenshots, 10 reduced-motion
  screenshots, and 7 interactive state screenshots.
- Accessibility-tree evidence passes with 50 cases, 12,647 sampled nodes, and 0
  failures.
- Axe-core and IBM Equal Access pass across the seven pages in light and dark
  themes.
- Broader focused proof specs pass: 274 examples, 0 failures.
- External adversarial Claude review grades the current state `95/100`.

Weak or deferred:

- Legacy Bootstrap-shaped examples still exist in historical source/output
  files and are quarantined by documentation rather than moved to a dedicated
  legacy directory.
- The reduced-motion contract has ten named surfaces covered through eight
  cases because several cases intentionally cover multiple surfaces.
- Agent-readable contracts are Markdown, not a machine-readable YAML or JSON
  catalog.

## Phase 17 - Agent DX Accessibility Gap Analysis

Changed files:

- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `docs/web-design-system/agent-playbook.md`
- `docs/web-design-system/generated-view-conventions.md`
- `docs/web-design-system/refactor-accountability.md`
- `docs/web-design-system/phase-1-baseline.md`
- `docs/web-design-system/forbidden-patterns.md`
- `docs/web-design-system/compiler-command-matrix.md`
- `AGENTS.md`
- `docs/web-design-system/README.md`
- `README.md`
- `CLAUDE.md`
- `templates/design-system/AGENTS.md`
- `templates/design-system/design-system.routes.yml`
- `templates/design-system/page.cr`
- `templates/design-system/component.cr`
- `templates/design-system/component_spec.cr`
- `examples/web_design_system_demo.cr`
- `scripts/validate_web_demo.cr`
- `scripts/capture_web_demo_screenshots.cr`
- `scripts/axe_web_demo_audit.cr`
- `scripts/ibm_web_demo_audit.cr`

Inputs:

- Local inspection of the current demo components, JavaScript helpers,
  validation scripts, renderer behavior, docs, and generated evidence.
- Companion audits for accessibility gaps, component/API gaps, agent onboarding,
  and validation/fast-feedback gaps.
- External Claude adversarial planning review.

What this phase adds:

- Documents the gap between an accessible proof and a library that makes
  accessibility cheap for future agents.
- Separates library API work from docs/templates and reusable validation CLI
  work.
- Defines an agent playbook for generated design-system pages: native semantics,
  `am-*` classes, vanilla hooks, light/dark behavior, reduced motion, forbidden
  patterns, and validation ladder.
- Adds a refactor accountability loop requiring before/after screenshots,
  demo-code shrink metrics, regenerated output, and documented visual drift for
  each extraction.
- Captures the Phase 1 baseline line counts and screenshot hashes that Phase 2
  extractions should compare against.
- Adds root and downstream agent instructions, forbidden-pattern examples, and a
  compiler matrix that keeps web proof commands on `crystal` while reserving
  `crystal-alpha` for native platform builds.
- Moves the canonical agent-facing docs path to `docs/web-design-system/` and
  adds generic web demo/audit wrapper commands so agents do not start from
  Amber-branded filenames.
- Reconciles the root Claude guidance so legacy FrontLoader Stimulus support no
  longer contradicts the vanilla-JavaScript design-system web milestone.
- Adds generated-view conventions derived from the current static and browser
  audits.
- Adds starter downstream templates for `AGENTS.md`, a future
  `design-system.routes.yml`, page shell, component skeleton, and component spec.

Weak or deferred:

- The templates still reflect the current alpha state where canonical
  components live under `Components::Examples`; the roadmap calls for promoting
  them to `Components::DesignSystem`.
- No reusable `asset_pipeline validate` CLI or stable
  `asset_pipeline/design_system` require shim exists yet.
- Validation scripts remain demo-specific until the roadmap's CLI phase.

## Phase 18 - Generic Namespace And Hook Aliases

Changed files:

- `src/components/design_system/components.cr`
- `src/asset_pipeline/design_system.cr`
- `src/components.cr`
- `spec/components/design_system/design_system_namespace_spec.cr`
- `spec/components/design_system/runtime_alias_spec.cr`
- `src/components/examples/auth_form_component.cr`
- `src/components/examples/carousel_component.cr`
- `src/components/examples/command_palette_component.cr`
- `src/components/examples/data_table_component.cr`
- `src/components/examples/dialog_component.cr`
- `src/components/examples/payment_form_component.cr`
- `src/components/examples/tabs_component.cr`
- `src/components/examples/theme_switcher_component.cr`
- `src/components/examples/timeline_component.cr`
- `spec/components/examples/example_components_spec.cr`
- `public/js/amber-design-system.js`
- `templates/design-system/AGENTS.md`
- `templates/design-system/page.cr`
- `templates/design-system/component.cr`
- `templates/design-system/component_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/agent-playbook.md`
- `docs/web-design-system/generated-view-conventions.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `docs/web-design-system/migration.md`
- `AGENTS.md`

Commands run:

- `crystal spec spec/components/design_system/design_system_namespace_spec.cr`
- `crystal spec templates/design-system/component_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr`
- `crystal build --no-codegen src/asset_pipeline/design_system.cr`
- `crystal spec spec/components/examples/example_components_spec.cr spec/components/design_system/design_system_namespace_spec.cr`
- `crystal spec spec/components/design_system/design_system_namespace_spec.cr spec/components/design_system/runtime_alias_spec.cr spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `git diff --check`

Artifacts:

- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/amber-design-system/`

What passes:

- `Components::DesignSystem::*` now exposes promoted generic component names:
  Button, Card, FormField, ThemeSwitcher, PricingCard, DataTable, SimpleChart,
  PaymentForm, AuthForm, CommandPalette, Tabs, Carousel, Dialog,
  ScheduleHeatmap, Timeline, Counter, Form, Chat, and LiveSearch.
- `require "asset_pipeline/design_system"` works through
  `src/asset_pipeline/design_system.cr`.
- `Components::Examples::*Component` remains compatible.
- Focused namespace/runtime/component specs pass: 53 examples, 0 failures.
- Broader focused web proof specs pass: 283 examples, 0 failures.
- Static audit passes after regenerating all seven demo pages.
- Browser capture passes with the 57-screenshot matrix.
- Axe and IBM Equal Access both pass across the generated pages.

Design choices:

- The new namespace uses Crystal aliases rather than copying component
  implementation. This keeps current render output visually identical while
  giving agents the generic API surface requested for future work.
- The vanilla runtime now accepts both neutral `data-ap-*` hooks and current
  `data-amber-*` compatibility hooks through shared hook selector helpers.
- Promoted interactive components co-emit representative `data-ap-*` and
  `data-amber-*` hooks for theme switching, auth/payment validation, command
  palette, tabs, carousel, dialog, and timeline reveal behavior.
- `DataTableComponent` keeps its fixed-layout responsive table non-scrollable
  instead of adding a questionable tabbable scroll region. This resolved a
  conflict where axe wanted keyboard access for an overflow container while IBM
  rejected the tabbable non-widget region.

Weak or deferred:

- The runtime file was still `public/js/amber-design-system.js` at this phase;
  the generic runtime entrypoint lands later in Phase 21.
- Output files and evidence folders still use `amber-design-system-*`
  compatibility names.
- Most page shell, badge, alert, panel, toast, empty state, and section
  primitives still live in the demo generator rather than reusable components.
- Auth/payment id-prefixing landed in the follow-up neutral API pass below.

## Phase 19 - Neutral API Language And Reusable Form IDs

Changed files:

- `AGENTS.md`
- `README.md`
- `examples/README.md`
- `examples/amber_design_system_demo.cr`
- `src/components/examples/auth_form_component.cr`
- `src/components/examples/dialog_component.cr`
- `src/components/examples/payment_form_component.cr`
- `spec/components/examples/example_components_spec.cr`
- `spec/components/design_system/runtime_alias_spec.cr`
- `public/js/amber-design-system.js`
- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `scripts/axe_amber_demo_audit.cr`
- `scripts/ibm_amber_demo_audit.cr`
- `templates/design-system/AGENTS.md`
- `docs/web-design-system/README.md`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/generated-view-conventions.md`
- `docs/web-design-system/refactor-accountability.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/examples/example_components_spec.cr spec/components/design_system`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr`
- `crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `git diff --check`

Artifacts:

- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/amber-design-system/`

What passes:

- Focused examples/design-system specs pass: 56 examples, 0 failures.
- Broader focused web proof specs pass: 286 examples, 0 failures.
- Template compile/spec checks pass.
- Static audit passes after regenerating all seven demo pages.
- Browser screenshot capture passes with the 57-screenshot matrix.
- Axe and IBM Equal Access both pass across the generated pages.

What this phase adds:

- New agent-facing `docs/web-design-system/component-api.md` defines the
  generic `Components::DesignSystem::*` surface, neutral `data-ap-*` behavior
  hooks, accessibility obligations, and validation ladder.
- Demo and docs now describe the public design-system surface generically.
  Amber-named classes, hooks, globals, file names, and artifact folders are
  explicitly compatibility debt, not the target naming.
- Demo-local interactions now co-emit neutral `data-ap-*` hooks for pricing,
  billing, filtering, chat, live search, disclosure, sticky hover, validation,
  and form status behavior.
- The runtime exposes `AssetPipelineDesignSystem` as the neutral global while
  keeping `AmberDesignSystem` as a compatibility alias.
- Runtime theme persistence now uses `ap-theme` first and mirrors to the legacy
  key for compatibility.
- Auth and payment forms accept caller-supplied ids that prefix field ids,
  status ids, and cross-field references so multiple instances can coexist.
- The demo-visible promo/example language no longer uses framework-branded
  names such as the old promo code or hero copy.
- Refactor accountability now tracks the generic wrapper and the current alpha
  generator separately, so extraction phases can prove the real generator is
  shrinking while screenshots remain stable.

Adversarial review:

- `wild_cloud -p ...` is not installed or on `PATH` in this shell.
- `claude -p ...` exists and was tried as a fallback, but produced no output
  after several minutes and was killed. Treat this as an external-review gap for
  this phase; the automated Crystal/browser/a11y validation did complete.

Weak or deferred:

- The generator implementation, compatibility output copies, and browser
  artifact directory still contain some `amber-design-system` compatibility
  naming.
- CSS variables and `.am-*` classes are still current styling compatibility
  identifiers.
- PageShell, Section, Panel, Badge, Alert, Toast, EmptyState, Skeleton,
  Progress, and Disclosure landed as reusable primitives in Phase 20. Deeper
  demo adoption plus `ValidatedForm` remain.
- The validation scripts still have compatibility filenames and hard-coded
  output paths; the manifest-driven CLI remains a later phase.

## Phase 20 - Page And Feedback Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `src/components/design_system/components.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/amber_design_system_demo.cr`
- `src/components/examples/payment_form_component.cr`
- `public/js/amber-design-system.js`
- `spec/components/design_system/runtime_alias_spec.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `docs/web-design-system/phase-notes.md`
- `templates/design-system/AGENTS.md`

Commands run:

- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal spec spec/components/design_system`
- `crystal spec spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr spec/components/design_system/design_system_namespace_spec.cr spec/components/design_system/runtime_alias_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr`
- `crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `git diff --check`

Artifacts:

- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/amber-design-system/`

What passes:

- Design-system specs pass: 20 examples, 0 failures.
- Broader focused web proof specs pass: 296 examples, 0 failures.
- Template compile/spec checks pass.
- Static audit passes after regenerating all seven demo pages.
- Browser screenshot capture passes with the 57-screenshot matrix.
- Axe and IBM Equal Access both pass across the generated pages.

What this phase adds:

- `Components::DesignSystem::PageShell`, `Section`, `Panel`, `Badge`,
  `Alert`, `EmptyState`, `Skeleton`, `Toast`, `Progress`, `Disclosure`, and
  `ValidatedForm` now exist as generic primitives.
- The primitive specs assert semantic landmarks/regions, heading relationships,
  live-region roles, native progress semantics, disclosure ownership,
  validated-form status wiring, `data-ap-*` hooks where behavior applies, and
  absence of Bootstrap-shaped classes.
- Toast dismiss buttons now have vanilla runtime behavior through
  `data-ap-toast-dismiss`, with the current compatibility alias retained.
- The reset and preferences forms now use the generic `ValidatedForm` primitive
  for shared validation/status wiring.
- The disclosure warning panel now uses the generic `Alert` primitive, and the
  patterns-page toast now uses the generic `Toast` primitive with an action
  button.
- The toast adoption initially produced an axe contrast failure on
  `.am-toast__body`; the demo now preserves the old inverse-toast contrast with
  a local `color: inherit` override and axe passes again.
- The demo now uses the generic `Badge` primitive for representative badge
  surfaces while preserving the existing visual selectors through `data-tone`.
- `examples/amber_design_system_demo.cr` shrank from 1721 to 1712 lines. The
  repeated demo-surface marker count dropped from 134 to 123.
- The component API, catalog, roadmap, and consuming-project agent template now
  point agents at the page/feedback primitive targets and require visual
  equivalence during extraction.

Adversarial review:

- Worker A implemented primitives/specs and reported focused Crystal/static
  validation passing.
- Worker B updated docs/templates and reported diff/trailing-whitespace scans
  passing.
- `claude -p ...` was retried with a 120 second timeout for adversarial review
  and exited with code 124 without output. `wild_cloud` remains unavailable on
  `PATH`.

Why acceptable:

- The reusable API surface now covers the page and feedback primitives the demo
  had been hand-rolling.
- The rendered demo remains validated by the full static/browser/a11y evidence
  ladder after adopting the first primitive-backed badge surfaces.
- The generator moved in the intended direction without a redesign or visible
  behavior change.

Weak or deferred:

- PageShell, Section, Panel, EmptyState, Skeleton, Progress, and
  Disclosure are implemented but only partially adopted by the demo; future
  phases should replace more repeated markup and continue line-count reduction.
- `ValidatedForm` is only adopted by the reset and preferences forms; signup,
  signin, and payment still use their specialized wrappers.
- Primitive component CSS is registered for consuming apps, but the current demo
  still clears the component CSS registry and relies on page-local CSS for most
  visual equivalence. A later extraction should stop clearing or selectively
  include primitive CSS once screenshot comparison proves no drift.

## Phase 21 - Generic Runtime Entrypoint

Changed files:

- `public/js/design-system.js`
- `public/js/amber-design-system.js`
- `examples/amber_design_system_demo.cr`
- `scripts/validate_amber_demo.cr`
- `spec/components/design_system/runtime_alias_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `docs/web-design-system/refactor-accountability.md`
- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `wc -l public/js/design-system.js public/js/amber-design-system.js`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr`
- `crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`

Artifacts:

- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/amber-design-system/`

What passes:

- Focused examples/design-system specs pass: 67 examples, 0 failures.
- Broader focused web proof specs pass: 297 examples, 0 failures.
- Template compile/spec checks pass.
- Static audit passes after regenerating all seven demo pages from
  `public/js/design-system.js`.
- Browser screenshot capture passes with the 57-screenshot matrix.
- Axe and IBM Equal Access both pass across the generated pages.

What this phase adds:

- `public/js/design-system.js` is now the canonical runtime file consumed by
  the generated demo and static validator.
- `public/js/amber-design-system.js` remains as a byte-for-byte compatibility
  copy for existing alpha output.
- Runtime specs now read the generic file and assert that the compatibility copy
  stays synchronized.
- Docs now describe the generic runtime path first, while recording the old path
  as compatibility debt.

Weak or deferred:

- Browser artifact folders still use `amber-design-system` compatibility names.
- The runtime still needs a later split into smaller behavior modules under an
  `assets/js/design-system/*` layout.

## Phase 22 - Generic Demo Output Filenames

Changed files:

- `examples/amber_design_system_demo.cr`
- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `scripts/axe_amber_demo_audit.cr`
- `scripts/ibm_amber_demo_audit.cr`
- `docs/web-design-system/README.md`
- `examples/README.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr`
- `crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `cmp -s output/web-design-system-demo.html output/amber-design-system-demo.html`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `git diff --check`

Artifacts:

- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- `test-results/amber-design-system/static-audit.json`
- `test-results/amber-design-system/browser-audit.json`
- `test-results/amber-design-system/axe-audit.json`
- `test-results/amber-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/amber-design-system/`

What passes:

- Focused examples/design-system specs pass: 67 examples, 0 failures.
- Broader focused web proof specs pass: 297 examples, 0 failures.
- Template compile/spec checks pass.
- Static, browser screenshot, axe, and IBM audits now read the generic
  `output/web-design-system-*.html` page set.
- Legacy output pages are byte-for-byte copies of the generic pages.

What this phase adds:

- The generated demo now writes canonical generic page filenames:
  `web-design-system-demo.html`, `web-design-system-pricing.html`,
  `web-design-system-forms.html`, `web-design-system-dashboard.html`,
  `web-design-system-timeline.html`, `web-design-system-collaboration.html`,
  and `web-design-system-patterns.html`.
- Existing `amber-design-system-*` HTML files remain as compatibility copies.
- Navigation links and page-card links point to the generic filenames.
- Validation scripts use the generic output page set.

Weak or deferred:

- The generator implementation file is still `examples/amber_design_system_demo.cr`.
- Browser evidence now has a generic target in Phase 23, but this phase still
  used `test-results/amber-design-system/`.

## Phase 23 - Neutral Evidence And Agent Accountability

Changed files:

- `scripts/validate_amber_demo.cr`
- `scripts/capture_amber_demo_screenshots.cr`
- `scripts/axe_amber_demo_audit.cr`
- `scripts/ibm_amber_demo_audit.cr`
- `docs/web-design-system/refactor-accountability.md`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/visual-language.md`
- `docs/web-design-system/forbidden-patterns.md`
- `docs/web-design-system/README.md`
- `docs/web-design-system/evidence.md`
- `docs/web-design-system/compiler-command-matrix.md`
- `docs/web-design-system/phase-1-baseline.md`
- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/phase-notes.md`
- `src/components/examples/button_component.cr`
- `src/components/examples/card_component.cr`
- `src/components/examples/tabs_component.cr`
- `spec/components/examples/example_components_spec.cr`

Commands run:

- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/amber_design_system_demo.cr | wc -l`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `git diff --check`
- `gtimeout 90 claude -p "...adversarially reviewing..."`

Artifacts:

- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/web-design-system/`

What passes:

- Focused examples/design-system specs pass: 67 examples, 0 failures.
- Broader focused web proof specs pass: 297 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Legacy output pages remain byte-for-byte copies of the generic pages.
- Runtime files remain byte-for-byte synchronized.
- Canonical and compatibility evidence directories both contain 57 screenshots.
- `git diff --check` passes.

What this phase adds:

- Static, browser, axe, and IBM scripts now write canonical artifacts under
  `test-results/web-design-system/` and mirror compatibility copies to
  `test-results/amber-design-system/`.
- Public docs now lead with generic component names and neutral
  `data-ap-*`/theme contracts instead of describing Amber-named selectors as
  canonical public API.
- The refactor accountability guide now requires before/after HTML snapshots,
  before/after static/browser/a11y evidence, focused specs, line-count metrics,
  screenshot comparison, and a fixed phase-note template.
- Source comments and spec names no longer describe generic button/card/tabs,
  chat, or live-search components as Amber-branded public components.

Visual/accountability result:

- Demo line count after this phase: `examples/web_design_system_demo.cr` 1 line,
  `examples/amber_design_system_demo.cr` 1714 lines.
- Runtime line count after this phase: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count after this phase: 123 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers.
- HTML drift: generic and compatibility output pages are byte-for-byte equal.
- Screenshot drift: not a visual extraction phase; the 57-screenshot matrix was
  regenerated successfully under the generic artifact path.

Adversarial review:

- Two explorer agents audited the plan. One identified the missing concrete
  HTML/screenshot comparison details; the refactor accountability guide now
  includes those commands and a template. The other identified public docs and
  comments that still treated Amber-named selectors as canonical; those
  high-priority wording issues were neutralized.
- `claude -p` exists locally but produced no output before `gtimeout 90`
  terminated it with exit code 124. No external Claude findings were available
  for this phase.

Weak or deferred:

- The generator implementation file remains
  `examples/amber_design_system_demo.cr`; only the wrapper/output names are
  generic so far.
- Current CSS selectors still use `am-*` and design-token variable names still
  use `--amber-*` as compatibility implementation details.
- The validation script filenames still carry compatibility names internally,
  with generic wrapper scripts requiring them.
- The next extraction phases still need to move more Section/Panel/Form/Dialog/
  Tabs/Carousel/Table runtime and markup out of the demo while proving visual
  parity with the new accountability loop.

## Phase 24 - Neutral Theme API Alias

Changed files:

- `src/components/css/tokens/amber_theme.cr`
- `src/components/css/tokens/design_system_theme.cr`
- `src/components/css/config/css_config.cr`
- `src/components/css/engine/css_generator.cr`
- `src/components.cr`
- `src/ui/theme.cr`
- `src/ui/renderers/web_renderer.cr`
- `spec/components/css/amber_design_system_spec.cr`
- `spec/ui/renderers/web_renderer_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/css/amber_design_system_spec.cr`
- `crystal spec spec/ui/renderers/web_renderer_spec.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js src/components/css/tokens/amber_theme.cr src/components/css/tokens/design_system_theme.cr`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/amber_design_system_demo.cr | wc -l`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `gtimeout 45 claude -p "...Adversarially review only this latest Asset Pipeline change..."`

Artifacts:

- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/web-design-system/`

What passes:

- Token/theme specs pass: 9 examples, 0 failures.
- Web renderer specs pass: 76 examples, 0 failures.
- Focused examples/design-system specs pass: 67 examples, 0 failures.
- Broader focused web proof specs pass: 299 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Generic and legacy output pages remain byte-for-byte equal.
- Runtime files remain byte-for-byte synchronized.
- Canonical and compatibility evidence directories both contain 57 screenshots.

What this phase adds:

- `Components::CSS::Tokens::Theme.design_system_default` is now the neutral
  constructor, with `amber_default` retained as a compatibility alias.
- `Components::CSS::Config#use_design_system_theme`,
  `#design_system_theme`, and `#design_system_theme=` are now the neutral config
  API, with `use_amber_theme` and `amber_theme` retained for compatibility.
- `src/components/css/tokens/design_system_theme.cr` is a neutral require shim.
- Generated token CSS now emits `[data-ap-theme="light"]` and
  `[data-ap-theme="dark"]` overrides in addition to the compatibility
  `[data-amber-theme]` selectors.
- `UI::Theme.design_system_default` and `UI::Theme.design_system_tokens` are
  neutral aliases, and the web renderer uses them by default.
- README theme examples now show the neutral constructor and config method.

Visual/accountability result:

- Demo line count after this phase: `examples/web_design_system_demo.cr` 1 line,
  `examples/amber_design_system_demo.cr` 1714 lines.
- Runtime line count after this phase: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count after this phase: 123 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers.
- HTML drift: generic and compatibility output pages are byte-for-byte equal.
- Screenshot drift: the 57-screenshot matrix was regenerated successfully after
  adding neutral theme selectors.

Adversarial review:

- Explorer review recommended section extraction next, but specifically warned
  that direct `Section` adoption would drift because the primitive emits
  `.am-section__*` anatomy while the demo CSS currently targets
  `.am-section-header`. That should be handled with a compatibility section
  mode or adapter before markup migration.
- `claude -p` produced no output before `gtimeout 45` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- The token implementation file remains `amber_theme.cr`; the neutral file is
  currently a require shim. A later compatibility-breaking phase can move the
  implementation once downstream requires are mapped.
- CSS custom properties still use `--amber-*` names as compatibility token
  variables.
- Broader generator shrinkage is unchanged in this phase; the next extraction
  should target the repeated `am-section`/`am-section-header` scaffolding with
  visual parity checks.

## Phase 25 - Section Compatibility Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/amber_design_system_demo.cr`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/amber_design_system_demo.cr | wc -l`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `git diff --check`
- `gtimeout 45 claude -p "...Adversarially review only this latest Asset Pipeline section extraction..."`

Artifacts:

- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/web-design-system/`

What passes:

- Section primitive specs pass: 11 examples, 0 failures.
- Broader focused web proof specs pass: 300 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Generic and legacy output pages remain byte-for-byte equal.
- Runtime files remain byte-for-byte synchronized.
- Canonical and compatibility evidence directories both contain 57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `Components::DesignSystem::Section` now has an explicit
  `compatibility_markup: "demo"` mode that preserves the existing
  `am-section` / `am-section-header` anatomy while letting the generator call
  a real design-system primitive.
- The demo generator gained a `section_block` helper and migrated repeated
  header-style sections on overview, pricing, forms, collaboration, and
  patterns pages.
- Direct demo-local section/header scaffolding now remains only for the
  dashboard shell, which has a different structure and should be handled in a
  later layout extraction.

Visual/accountability result:

- Demo line count after this phase: `examples/web_design_system_demo.cr` 1 line,
  `examples/amber_design_system_demo.cr` 1702 lines. The previous recorded
  generator count was 1714 lines.
- Runtime line count after this phase: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count after this phase: 105 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers. The previous recorded marker
  count was 123.
- HTML drift: generic and compatibility output pages are byte-for-byte equal.
- Screenshot drift: the 57-screenshot matrix was regenerated successfully after
  the extraction.

Adversarial review:

- Explorer review recommended this exact section extraction path and warned
  against direct `Section` adoption because the existing primitive emitted
  `.am-section__*` anatomy. This phase followed that recommendation by adding
  a compatibility mode first.
- `claude -p` produced no output before `gtimeout 45` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- `compatibility_markup: "demo"` intentionally preserves old anatomy; future
  phases can move the CSS to the cleaner `.am-section__*` anatomy only with
  screenshot-backed visual acceptance.
- The dashboard section shell still has custom layout and was not migrated.
- Panel, EmptyState, Progress, Disclosure, Auth/Payment fieldsets, Tabs,
  Carousel, Dialog, Table, Chart, and runtime modules remain the larger
  extraction units.

## Phase 26 - Panel Compatibility Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/amber_design_system_demo.cr`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/amber_design_system_demo.cr | wc -l`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `git diff --check`
- `gtimeout 45 claude -p "...Adversarially review only this latest Asset Pipeline panel extraction..."`

Artifacts:

- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/web-design-system/`

What passes:

- Primitive specs pass: 12 examples, 0 failures.
- Broader focused web proof specs pass: 301 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Generic and legacy output pages remain byte-for-byte equal.
- Runtime files remain byte-for-byte synchronized.
- Canonical and compatibility evidence directories both contain 57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `Components::DesignSystem::Panel` now has an explicit
  `compatibility_markup: "demo"` mode that preserves the current simple
  `am-panel` wrapper shape without adding `data-component`, `role`, generated
  ids, or `.am-panel__body` wrappers.
- The demo generator gained a `panel_block` helper and migrated the safer
  static panels identified by explorer review: overview contract, pricing
  payment-state summary, dashboard visual evidence, collaboration chat, live
  search, and upload queue.
- Disclosure and dialog/toast panels were intentionally left demo-local because
  they are more tightly coupled to behavior-specific extraction decisions.

Visual/accountability result:

- Demo line count after this phase: `examples/web_design_system_demo.cr` 1 line,
  `examples/amber_design_system_demo.cr` 1688 lines. The previous recorded
  generator count was 1702 lines.
- Runtime line count after this phase: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count after this phase: 89 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers. The previous recorded marker
  count was 105.
- HTML drift: generic and compatibility output pages are byte-for-byte equal.
- Screenshot drift: the 57-screenshot matrix was regenerated successfully after
  the extraction.

Adversarial review:

- Explorer review identified the safe panel targets and warned that default
  `Panel` output would add wrapper anatomy and ARIA/data attributes. This phase
  followed that recommendation by adding a compatibility mode first and leaving
  disclosure/dialog panels alone.
- `claude -p` produced no output before `gtimeout 45` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- `compatibility_markup: "demo"` intentionally preserves old panel anatomy;
  future phases can move to canonical `.am-panel__*` anatomy only with
  screenshot-backed acceptance.
- The disclosure and dialog/toast panels remain demo-local.
- EmptyState and Progress are handled in Phase 27. Disclosure, Auth/Payment
  fieldsets, Tabs, Carousel, Dialog, Table, Chart, and runtime modules remain
  larger extraction units.

## Phase 27 - Empty And Progress Compatibility Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/amber_design_system_demo.cr`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/amber_design_system_demo.cr | wc -l`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `git diff --check`
- `gtimeout 45 claude -p "...Adversarially review only this latest Asset Pipeline EmptyState/Progress compatibility extraction..."`

Artifacts:

- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/web-design-system/`

What passes:

- Primitive specs pass: 14 examples, 0 failures.
- Broader focused web proof specs pass: 303 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Generic and legacy output pages remain byte-for-byte equal.
- Runtime files remain byte-for-byte synchronized.
- Canonical and compatibility evidence directories both contain 57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `Components::DesignSystem::EmptyState` now has a
  `compatibility_markup: "demo"` mode that preserves the current
  `am-empty` anatomy for the demo while keeping canonical `am-empty-state`
  output available for new code.
- `Components::DesignSystem::Progress` now has a
  `compatibility_markup: "demo"` mode that preserves the current custom
  `div.am-progress` progressbar anatomy while keeping native `<progress>`
  output available for new code.
- The collaboration page now renders its empty state and upload progress
  through the design-system primitives.

Visual/accountability result:

- Demo line count after this phase: `examples/web_design_system_demo.cr` 1 line,
  `examples/amber_design_system_demo.cr` 1686 lines. The previous recorded
  generator count was 1688 lines.
- Runtime line count after this phase: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count after this phase: 87 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers. The previous recorded marker
  count was 89.
- HTML drift: generic and compatibility output pages are byte-for-byte equal.
- Screenshot drift: the 57-screenshot matrix was regenerated successfully after
  the extraction.

Adversarial review:

- Explorer review confirmed EmptyState and Progress were safe to extract with
  the new compatibility modes, and noted the remaining risk that compatibility
  output intentionally does not emit the canonical `data-component` and
  labelled-section/native-progress anatomy. This phase keeps that limitation
  explicit.
- `claude -p` produced no output before `gtimeout 45` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- Compatibility modes preserve old demo anatomy and should not be treated as
  the long-term canonical output.
- The upload progress still uses custom progressbar markup in compatibility
  mode; canonical native `<progress>` adoption needs visual acceptance.
- Disclosure, Auth/Payment fieldsets, Tabs, Carousel, Dialog, Table, Chart, and
  runtime modules remain larger extraction units.

## Phase 28 - Disclosure Compatibility Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/amber_design_system_demo.cr`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal run examples/web_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/amber_design_system_demo.cr | wc -l`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `git diff --check`
- `gtimeout 45 claude -p "...Adversarially review only this latest Asset Pipeline Disclosure compatibility extraction..."`

Artifacts:

- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`
- 57 screenshots in `test-results/web-design-system/`

What passes:

- Primitive specs pass: 15 examples, 0 failures.
- Broader focused web proof specs pass: 304 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Generic and legacy output pages remain byte-for-byte equal.
- Runtime files remain byte-for-byte synchronized.
- Canonical and compatibility evidence directories both contain 57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `Components::DesignSystem::Disclosure` now has a
  `compatibility_markup: "demo"` mode that preserves the current button-only
  demo anatomy while keeping canonical `.am-disclosure` output available for
  new code.
- The patterns page disclosure control now renders through the design-system
  primitive and still controls the hidden warning alert with `aria-controls`.
- The runtime disclosure behavior remains shared across `[data-ap-disclosure]`
  and `[data-amber-disclosure]` selectors.

Visual/accountability result:

- Demo line count after this phase: `examples/web_design_system_demo.cr` 1 line,
  `examples/amber_design_system_demo.cr` 1685 lines. The previous recorded
  generator count was 1686 lines.
- Runtime line count after this phase: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count after this phase: 86 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers. The previous recorded marker
  count was 87.
- HTML drift: generic and compatibility output pages are byte-for-byte equal.
- Screenshot drift: the 57-screenshot matrix was regenerated successfully after
  the extraction.

Adversarial review:

- Explorer review recommended this exact compatibility-mode migration and
  warned that the canonical disclosure wrapper would create visible spacing and
  possibly toggle the wrong hidden element in the current demo.
- `claude -p` produced no output before `gtimeout 45` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- The compatibility renderer duplicates the ButtonComponent-like button anatomy
  intentionally; future ButtonComponent changes may need a synchronized update
  here.
- Compatibility disclosure output does not emit the canonical
  `.am-disclosure` wrapper or `.am-disclosure__panel`; canonical adoption needs
  visual acceptance.
- Auth/Payment fieldsets, Tabs, Carousel, Dialog, Table, Chart, and runtime
  modules remain larger extraction units.

## Phase 29 - Auth And Payment Fieldset Semantics

Changed files:

- `src/components/examples/auth_form_component.cr`
- `src/components/examples/payment_form_component.cr`
- `src/components/examples/form_field_component.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `mkdir -p output/web-design-system-before-phase29 test-results/web-design-system-before-phase29 && cp output/web-design-system-*.html output/web-design-system-before-phase29/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase29/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase29/`
- `crystal spec spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr && crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-phase29-diff -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `git diff --check`
- `gtimeout 45 claude -p "...Adversarially review only this latest Asset Pipeline AuthForm/PaymentForm fieldset accessibility phase..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase29/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase29/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- Targeted diff images in `test-results/web-design-system-phase29-diff/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Example component specs pass: 46 examples, 0 failures.
- Broader focused web proof specs pass: 304 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Generic and legacy output pages remain byte-for-byte equal after regeneration.
- Runtime files remain byte-for-byte synchronized.
- Canonical and compatibility evidence directories both contain 57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `AuthFormComponent` now groups sign-up controls in a native fieldset with a
  visually-hidden `Create workspace account details` legend.
- `AuthFormComponent` now groups sign-in controls in a native fieldset with a
  visually-hidden `Workspace sign-in details` legend.
- `PaymentFormComponent` now groups the payment controls in a native fieldset
  with a visually-hidden `Payment details` legend.
- `FormFieldComponent` now contributes the fieldset reset and visually-hidden
  utility needed by these reusable form components.
- The docs now make fieldset/legend grouping part of the auth and payment
  accessibility contract.

Visual/accountability result:

- Demo line count remains: `examples/web_design_system_demo.cr` 1 line,
  `examples/amber_design_system_demo.cr` 1685 lines.
- Runtime line count remains: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count remains 86 demo-local `am-*`, `data-ap-*`, `data-amber-*`,
  section/form/dialog markers.
- HTML drift is intentional for the affected forms: fieldset and legend markup
  now appears in pricing/forms output.
- Targeted screenshot diffs were captured for forms/pricing normal and invalid
  states. `pricing-desktop-light.png` is RMSE `0`; `pricing-invalid-state.png`
  is RMSE `83.3075 (0.00127119)`. `forms-desktop-light.png` is RMSE
  `5026.13 (0.0766938)` and `forms-invalid-state.png` is RMSE
  `8313.8 (0.12686)`. Manual review of the before/after forms screenshots
  found the normal visible layout equivalent; the invalid-state full-page
  capture is taller after fieldset grouping and should be watched in the next
  visual pass.

Adversarial review:

- Explorer review recommended native fieldsets with visually-hidden legends,
  keeping submit buttons and reset links outside auth fieldsets. That guidance
  was adopted.
- Explorer review recommended a narrower payment-card fieldset. This phase used
  a broader `Payment details` fieldset to preserve current field order and avoid
  a larger visible layout change. A future phase can split receipt, card, and
  promo groups with screenshot-backed acceptance.
- `claude -p` produced no output before `gtimeout 45` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- Payment grouping is still broad. More precise `Receipt contact`, `Card
  details`, and `Promotion code` groups are a better long-term contract if the
  visual drift can be held.
- Auth and payment forms are still mostly string-built components rather than
  composed from a reusable Fieldset/FormGroup primitive.
- The normal screenshot matrix passes, but the forms invalid-state full-page
  capture grew taller. Treat that as a follow-up visual acceptance item before
  expanding the same pattern to more form surfaces.
- Tabs, Carousel, Dialog, Table, Chart, and runtime modules remain larger
  extraction units.

## Phase 30 - Canonical Demo Generator Rename

Changed files:

- `examples/web_design_system_demo.cr`
- `examples/amber_design_system_demo.cr`
- `examples/README.md`
- `docs/web-design-system/refactor-accountability.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-1-baseline.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `mkdir -p output/web-design-system-before-phase30 test-results/web-design-system-before-phase30 && cp output/web-design-system-*.html output/web-design-system-before-phase30/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase30/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase30/`
- `crystal run examples/web_design_system_demo.cr`
- `crystal run examples/amber_design_system_demo.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/examples/example_components_spec.cr spec/components/design_system/runtime_alias_spec.cr`
- `crystal build --no-codegen examples/web_design_system_demo.cr && crystal build --no-codegen examples/amber_design_system_demo.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase30 -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `cmp -s public/js/design-system.js public/js/amber-design-system.js`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase30/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase30/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- The canonical command passes: `crystal run examples/web_design_system_demo.cr`.
- The legacy command still passes:
  `crystal run examples/amber_design_system_demo.cr`.
- Example/runtime specs pass: 51 examples, 0 failures.
- Both demo entrypoints compile with `--no-codegen`.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Generic and legacy output pages remain byte-for-byte equal after regeneration.
- Runtime files remain byte-for-byte synchronized.
- Before, canonical, and compatibility evidence directories all contain
  57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `examples/web_design_system_demo.cr` is now the real canonical demo generator
  implementation.
- `examples/amber_design_system_demo.cr` is now a tiny compatibility wrapper for
  the old alpha command name.
- The demo module was renamed from `AmberDesignSystemDemo` to
  `WebDesignSystemDemo`.
- Current docs now identify `examples/web_design_system_demo.cr` as the shrink
  target and the Amber-named file as compatibility debt.

Visual/accountability result:

- Demo line count after this phase: `examples/web_design_system_demo.cr`
  1685 lines, `examples/amber_design_system_demo.cr` 3 lines.
- Runtime line count remains: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- Marker count moved with the implementation: 86 in
  `examples/web_design_system_demo.cr`, 0 in
  `examples/amber_design_system_demo.cr`.
- HTML before/after comparison is not byte-stable because several existing
  components generate volatile ids (`am-chart-*`, `am-heatmap-*`, timeline
  ids, toast ids). Same-run canonical/legacy page copies are byte-identical.
- Targeted screenshot comparison against the Phase 30 before snapshot showed no
  meaningful visible drift: pricing/forms/timeline/patterns desktop-light were
  RMSE `0`; dashboard was RMSE `461.224 (0.00703782)`; collaboration was RMSE
  `9.69895 (0.000147997)`; overview was RMSE `118.046 (0.00180126)`.

Adversarial review:

- Explorer review identified the exact required rename points and stale current
  docs. Those points were addressed in this phase.
- `wild_cloud` is not installed in this environment.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- Historical phase notes still contain dated `AmberDesignSystemDemo` and
  `examples/amber_design_system_demo.cr` references by design.
- Several generated components still use volatile ids, which weakens exact
  before/after HTML comparison. A later stability phase should make demo ids
  deterministic so refactor drift checks become stricter.
- `public/js/amber-design-system.js` remains as a compatibility copy while the
  canonical runtime is `public/js/design-system.js`.
- Tabs, Carousel, Dialog, Table, Chart, and runtime modules remain larger
  extraction units.

## Phase 31 - Deterministic Demo Ids

Changed files:

- `src/components/examples/simple_chart_component.cr`
- `spec/components/examples/example_components_spec.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `mkdir -p output/web-design-system-before-phase31 test-results/web-design-system-before-phase31 && cp output/web-design-system-*.html output/web-design-system-before-phase31/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase31/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase31/`
- `crystal spec spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr && rm -rf output/web-design-system-phase31-first && mkdir -p output/web-design-system-phase31-first && cp output/web-design-system-*.html output/web-design-system-phase31-first/ && crystal run examples/web_design_system_demo.cr && diff -ru output/web-design-system-phase31-first output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first'`
- `rg -n 'am-chart-[0-9]+|am-heatmap-[0-9]+|am-timeline-[0-9]+|component-[0-9]+-[0-9]+' output/web-design-system-*.html`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr && crystal run scripts/validate_web_demo.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase31 -maxdepth 1 -name '*.png' | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase31/`
- First deterministic-generation snapshot in
  `output/web-design-system-phase31-first/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase31/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Example component specs pass: 49 examples, 0 failures.
- Primitive specs pass: 16 examples, 0 failures.
- Broader focused web proof specs pass: 308 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Two consecutive canonical demo generations now compare cleanly for the
  `web-design-system-*` pages.
- The volatile-id search for `am-chart-[0-9]+`, `am-heatmap-[0-9]+`,
  `am-timeline-[0-9]+`, and `component-[0-9]+-[0-9]+` returns no matches in
  `output/web-design-system-*.html`.
- Generic and legacy output pages remain byte-for-byte equal after regeneration.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `SimpleChartComponent` now honors caller-supplied `id` for both first-party
  SVG and external-adapter output.
- The dashboard chart and heatmap, timeline, and patterns toast now pass stable
  ids in the canonical demo generator.
- Specs now assert deterministic explicit-id rendering for chart, heatmap,
  timeline, and toast surfaces.
- Future extraction phases can rely on stricter generated-HTML drift checks for
  the current demo pages.

Visual/accountability result:

- Demo line count remains: `examples/web_design_system_demo.cr` 1685 lines,
  `examples/amber_design_system_demo.cr` 3 lines.
- Runtime line count remains: `public/js/design-system.js` 878 lines,
  `public/js/amber-design-system.js` 878 lines.
- `src/components/examples/simple_chart_component.cr` is now 161 lines.
- This phase changes only id and ARIA reference strings for deterministic
  output. Screenshots regenerate successfully with the 57-screenshot matrix.

Adversarial review:

- Explorer review identified the exact nondeterministic sources and recommended
  avoiding global `Component#component_id` changes. This phase followed that
  guidance.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- Global `Component#component_id` remains intentionally volatile. Components
  outside the canonical demo can still emit volatile fallback ids unless callers
  supply explicit ids.
- Historical output folders in `output/` (`about.html`, `gallery.html`,
  `index.html`, `shop.html`) still appear in broad directory diffs and should
  be excluded or cleaned up separately if the repo decides generated output
  should be tracked more tightly.
- Tabs, Carousel, Dialog, Table, Chart, and runtime modules remain larger
  extraction units.

## Phase 32 - Specific Payment Fieldset Groups

Changed files:

- `src/components/examples/payment_form_component.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `mkdir -p output/web-design-system-before-phase32 test-results/web-design-system-before-phase32 && cp output/web-design-system-*.html output/web-design-system-before-phase32/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase32/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase32/`
- `crystal spec spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr && crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `compare -metric RMSE ...`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase32 -maxdepth 1 -name '*.png' | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase32/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase32/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Example component specs pass: 49 examples, 0 failures.
- Broader focused web proof specs pass: 308 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Browser-driven payment validation remains green through the screenshot
  capture script.
- Generic and legacy output pages remain byte-for-byte equal after regeneration.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- `git diff --check` passes.

What this phase adds:

- `PaymentFormComponent` now uses three native fieldset groups with
  visually-hidden legends: `Receipt contact`, `Card details`, and
  `Promotion code`.
- `Receipt email` moved before card credentials, matching the new receipt
  contact group.
- `Name on card`, card number, expiry, and CVC remain in `Card details`.
- Promo code remains its own optional group after card details.
- Specs and docs now assert the specific three-group contract instead of the
  broad Phase 29 `Payment details` group.

Visual/accountability result:

- `src/components/examples/payment_form_component.cr` is now 48 lines.
- Pricing screenshot dimensions are unchanged for the checked desktop and
  invalid-state captures.
- Targeted pricing screenshot comparison against Phase 32 before snapshots:
  desktop light RMSE `1304.32 (0.0199026)`, desktop dark `1262.93
  (0.0192712)`, mobile light `1854.03 (0.0282907)`, mobile dark `1754.9
  (0.026778)`, reflow light `1966.79 (0.0300113)`, reflow dark `2048.96
  (0.0312651)`, invalid state `1272.42 (0.0194159)`.
- Manual review of `pricing-desktop-light.png` found the new field order and
  grouping visually acceptable: height is unchanged, labels remain visible, and
  hidden legends do not add chrome.

Adversarial review:

- Explorer review recommended the exact split used here and identified spacing,
  field order, docs, and JS hook preservation as the main risks.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- Splitting the groups improves assistive-technology structure but still uses
  string-built form markup. A reusable Fieldset/FormGroup primitive remains the
  better long-term developer experience.
- The field order intentionally changed so receipt email comes first. This is
  accepted drift and should not be hidden as a no-op refactor.
- Tabs, Carousel, Dialog, Table, Chart, and runtime modules remain larger
  extraction units.

## Phase 33 - Fieldset Primitive Extraction

Changed files:

- `src/components/design_system/fieldset.cr`
- `src/components/design_system/components.cr`
- `src/components/design_system/primitives.cr`
- `src/components/examples/form_field_component.cr`
- `src/components/examples/auth_form_component.cr`
- `src/components/examples/payment_form_component.cr`
- `spec/components/design_system/primitives_spec.cr`
- `spec/components/design_system/design_system_namespace_spec.cr`
- `spec/components/examples/example_components_spec.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/refactor-accountability.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/design_system/primitives_spec.cr spec/components/design_system/design_system_namespace_spec.cr`
- `crystal spec spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr && crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `compare -metric RMSE ...`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase33 -maxdepth 1 -name '*.png' | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase33/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase33/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Direct fieldset and design-system namespace specs pass: 24 examples,
  0 failures.
- Example component specs pass: 49 examples, 0 failures.
- Broader focused web proof specs pass: 310 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- `Components::DesignSystem::Fieldset` now owns native grouped-control markup
  for reusable form sections.
- Fieldset emits a native `<fieldset>` and `<legend>`, supports hidden or
  visible legends, optional `id`, optional `aria-describedby`, optional
  `disabled`, and caller-supplied classes.
- `.am-form-fieldset` and `.am-visually-hidden` CSS moved out of
  `FormFieldComponent` and into the new Fieldset primitive.
- `AuthFormComponent` and `PaymentFormComponent` now compose Fieldset instead
  of hand-owning the fieldset CSS contract.
- Docs now describe Fieldset as a generic design-system primitive. Amber-named
  files, hooks, and CSS variables remain compatibility details, not the naming
  model for new components.
- The refactor accountability checklist now spells out the delegated extraction
  contract: generic names, less demo-local code, equivalent HTML by default,
  screenshot drift review, and enough specs/docs for another agent to use the
  new API directly.

Visual/accountability result:

- `examples/web_design_system_demo.cr` remains 1685 lines. This phase extracted
  shared accessibility structure from component files, not page-local demo
  markup, so the demo generator did not shrink yet.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- Component line counts after extraction: `fieldset.cr` 75,
  `primitives.cr` 1009, `form_field_component.cr` 171,
  `auth_form_component.cr` 56, `payment_form_component.cr` 44.
- Fieldset HTML anatomy for auth and payment remains stable. The generated
  forms/pricing diff is limited to CSS ownership/order: `.am-form-fieldset`
  now appears before `.am-field` because Fieldset contributes the reset before
  FormField contributes field styles.
- Targeted screenshot comparison against Phase 33 before snapshots:
  `forms-desktop-light.png` RMSE `0 (0)`,
  `forms-invalid-state.png` `127.031 (0.00193837)`,
  `forms-mobile-light.png` `0 (0)`,
  `forms-reflow-320-light.png` `0 (0)`,
  `pricing-desktop-light.png` `0 (0)`,
  `pricing-invalid-state.png` `770.861 (0.0117626)`,
  `pricing-mobile-light.png` `944.753 (0.014416)`,
  `pricing-reflow-320-light.png` `2.00862 (3.06496e-05)`.
- Checked desktop dimensions remain unchanged:
  forms desktop `1440x1680` before/current and pricing desktop `1440x1747`
  before/current.

Adversarial review:

- Companion review recommended extracting a generic
  `Components::DesignSystem::Fieldset`, preserving submit buttons outside auth
  fieldsets, and moving CSS ownership out of `FormFieldComponent`.
- This phase followed that guidance while keeping Fieldset in its own file
  instead of importing every primitive into auth/payment.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.
- The previous companion agent id was no longer open when cleanup was attempted,
  so there was no active delegated task left to close.

Weak or deferred:

- Auth and payment forms still string-build their inner fields and use
  `RawHTML`. Fieldset removes one accessibility gap but does not yet provide a
  full `ValidatedForm`, `PaymentFields`, or `PasswordPolicy` API.
- `.am-visually-hidden` is still the compatibility class name. A future neutral
  class or tokenized helper should keep the same visual behavior while moving
  public docs to generic terminology.
- The next extraction should target page-local demo markup so
  `examples/web_design_system_demo.cr` visibly shrinks while the before/after
  screenshot matrix stays identical.
- Tabs, Carousel, Dialog, Table, Chart, and runtime modules remain larger
  extraction units.

## Phase 34 - Canonical Demo Namespace Pass

Changed files:

- `src/components/design_system/promoted_components.cr`
- `src/components/design_system/components.cr`
- `examples/web_design_system_demo.cr`
- `spec/components/design_system/design_system_namespace_spec.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `rm -rf output/web-design-system-before-phase34 test-results/web-design-system-before-phase34 && crystal run examples/web_design_system_demo.cr && mkdir -p output/web-design-system-before-phase34 && cp output/web-design-system-*.html output/web-design-system-before-phase34/ && crystal run scripts/validate_web_demo.cr && crystal run scripts/capture_web_demo_screenshots.cr && mkdir -p test-results/web-design-system-before-phase34 && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase34/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase34/`
- `crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr && cp test-results/web-design-system/axe-audit.json test-results/web-design-system-before-phase34/ && cp test-results/web-design-system/ibm-equal-access-audit.json test-results/web-design-system-before-phase34/`
- `crystal spec spec/components/design_system/design_system_namespace_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase34 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `rg -n "Components::Examples::" examples/web_design_system_demo.cr || true`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase34 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js src/components/design_system/promoted_components.cr`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase34/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase34/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Design-system namespace specs pass: 8 examples, 0 failures.
- Namespace plus example component specs pass: 57 examples, 0 failures.
- Broader focused web proof specs pass: 311 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `src/components/design_system/promoted_components.cr` as the generic
  namespace bridge for the current vanilla-compatible proof components:
  `AuthForm`, `Button`, `Card`, `Carousel`, `CommandPalette`, `DataTable`,
  `Dialog`, `FormField`, `PaymentForm`, `PricingCard`, `ScheduleHeatmap`,
  `SimpleChart`, `Tabs`, `ThemeSwitcher`, and `Timeline`.
- Intentionally did not promote the older reactive `Chat`, `Counter`, `Form`,
  or `LiveSearch` examples because they still expose stateful/reactive or
  `data-action` behavior that conflicts with the no-build vanilla Milestone 1
  direction.
- The canonical demo now uses `Components::DesignSystem::*` names instead of
  direct `Components::Examples::*` calls.
- Docs now describe the generic namespace as the public authoring surface and
  treat `Components::Examples::*Component` classes as alpha compatibility
  implementation details.

Visual/accountability result:

- `examples/web_design_system_demo.cr` remains 1685 lines. This phase was a
  namespace/API correction with byte-stable output, not a markup extraction.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- `src/components/design_system/promoted_components.cr` is 35 lines.
- Marker count remains 86 demo-local `am-*`, `data-ap-*`, `data-amber-*`,
  section/form/dialog markers.
- `rg -n "Components::Examples::" examples/web_design_system_demo.cr` returns
  no matches.
- Generated HTML diff against `output/web-design-system-before-phase34/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 34 before snapshots:
  `desktop-light.png` RMSE `258.126 (0.00393874)`,
  `desktop-dark.png` `3.56822 (5.44476e-05)`,
  `pricing-desktop-light.png` `0 (0)`,
  `forms-desktop-light.png` `0 (0)`,
  `dashboard-desktop-light.png` `422.535 (0.00644747)`,
  `collaboration-desktop-light.png` `20.6 (0.000314336)`,
  `patterns-desktop-light.png` `0 (0)`.
- Because generated HTML is byte-identical, the nonzero PNG values are treated
  as browser capture, timing, or animation variance rather than accepted design
  drift.

Adversarial review:

- Worker agent implemented the first alias bridge and focused specs.
- Explorer agent recommended this chunk as the immediate next step and warned
  not to promote the older reactive chat/live-search examples as canonical
  vanilla components.
- This phase narrowed the worker patch accordingly and kept those reactive
  examples out of `Components::DesignSystem`.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- This is intentionally alias-only. Several generic names still point to
  implementation classes in `src/components/examples/*`.
- The demo did not shrink in this phase; it now models the public namespace so
  the next extraction can shrink markup without reinforcing example-class names.
- The recommended next chunk is `PageHero`: add a generic primitive that emits
  the current `am-page-hero` compatibility anatomy exactly, replace the
  page-local helper, and prove byte-identical HTML plus screenshot stability.
- Vanilla `ChatPanel`, `LiveSearchPanel`, and `UploadQueue` wrappers remain
  future work; do not promote the old reactive examples as substitutes.

## Phase 35 - PageHero Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `rm -rf output/web-design-system-before-phase35 test-results/web-design-system-before-phase35 && crystal run examples/web_design_system_demo.cr && mkdir -p output/web-design-system-before-phase35 && cp output/web-design-system-*.html output/web-design-system-before-phase35/ && crystal run scripts/validate_web_demo.cr && crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr && mkdir -p test-results/web-design-system-before-phase35 && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase35/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase35/`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase35 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase35 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr src/components/design_system/primitives.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase35/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase35/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 20 examples, 0 failures.
- Design-system plus example component specs pass: 82 examples, 0 failures.
- Broader focused web proof specs pass: 314 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::PageHero` as a generic page-level primitive
  for hero headers.
- The compact default output supports `kicker`, `title`, `body`/`copy`, child
  aside content, and low-risk `id`, extra `class`, and `label`/`aria_label`
  passthrough.
- Added `compatibility_markup: "demo"` output that preserves the existing
  `am-page-hero`, `am-kicker`, `am-page-title`, `am-demo-copy` anatomy and
  whitespace exactly for the current demo.
- The demo-local `page_hero` helper now delegates to `PageHero` instead of
  owning the markup directly.
- Component API/catalog docs now list `PageHero` as an extracted page primitive.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1685 to 1683 lines.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- `src/components/design_system/primitives.cr` grew to 1052 lines because it now
  owns the hero primitive and compatibility renderer.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- Marker count dropped from 86 to 82 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers.
- Generated HTML diff against `output/web-design-system-before-phase35/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 35 before snapshots:
  `desktop-light.png` RMSE `8.78166 (0.000134)`,
  `desktop-dark.png` `221.561 (0.00338081)`,
  `pricing-desktop-light.png` `0 (0)`,
  `forms-desktop-light.png` `0 (0)`,
  `dashboard-desktop-light.png` `246.438 (0.00376041)`,
  `timeline-desktop-light.png` `0 (0)`,
  `collaboration-desktop-light.png` `3.36145 (5.12924e-05)`,
  `patterns-desktop-light.png` `0 (0)`.
- Because generated HTML is byte-identical, the nonzero PNG values are treated
  as browser capture, timing, or animation variance rather than accepted design
  drift.

Adversarial review:

- Worker agent added the primitive, specs, and docs under a narrow ownership
  slice.
- Main pass found the worker's compact renderer would cause avoidable generated
  HTML whitespace drift, so this phase added a demo compatibility renderer and
  an exact whitespace spec before migrating the demo helper.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- `PageHero` deliberately preserves the current `am-*` class names because
  selector migration is separate compatibility work.
- The primitive owns only the page-level hero shell. The overview homepage
  `am-demo-hero` product hero remains custom and should be extracted separately
  if it becomes a reusable pattern.
- More page-local code remains in page cards, metrics, terminal previews,
  dashboard shell, collaboration panels, and patterns composition bands.

## Phase 36 - Metric Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `rm -rf output/web-design-system-before-phase36 test-results/web-design-system-before-phase36 && crystal run examples/web_design_system_demo.cr && mkdir -p output/web-design-system-before-phase36 && cp output/web-design-system-*.html output/web-design-system-before-phase36/ && crystal run scripts/validate_web_demo.cr && crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr && mkdir -p test-results/web-design-system-before-phase36 && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase36/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase36/`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase36 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase36 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr src/components/design_system/primitives.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `rg -n '<div class="am-metric"' examples/web_design_system_demo.cr || true`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase36/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase36/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 22 examples, 0 failures.
- Design-system plus example component specs pass: 84 examples, 0 failures.
- Broader focused web proof specs pass: 316 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::Metric` as a generic primitive for compact
  dashboard/proof summaries.
- Metric renders the current repeated anatomy exactly:
  `<div class="am-metric"><span class="am-demo-subtle">Label</span><strong>Value</strong><span>Copy</span></div>`.
- Metric supports `body`/`copy`, optional `id`, extra `class`, and explicit
  `data-*`/`aria-*` passthrough.
- The overview proof grid and dashboard metric grid now render through the
  Metric primitive instead of raw repeated HTML snippets.
- Component API/catalog docs now list `Metric` as an extracted primitive.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1683 to 1679 lines during
  this phase.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- `src/components/design_system/primitives.cr` grew to 1091 lines because it now
  owns Metric.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- Marker count dropped from 82 to 74 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers.
- `rg -n '<div class="am-metric"' examples/web_design_system_demo.cr` returns
  no matches.
- Generated HTML diff against `output/web-design-system-before-phase36/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 36 before snapshots:
  `desktop-light.png` RMSE `101.128 (0.00154312)`,
  `desktop-dark.png` `9.98859 (0.000152416)`,
  `dashboard-desktop-light.png` `252.748 (0.00385668)`,
  `pricing-desktop-light.png` `0 (0)`,
  `forms-desktop-light.png` `0 (0)`,
  `collaboration-desktop-light.png` `20.4203 (0.000311594)`.
- Because generated HTML is byte-identical, the nonzero PNG values are treated
  as browser capture, timing, or animation variance rather than accepted design
  drift.

Adversarial review:

- Worker agent added the primitive, specs, and docs under a narrow ownership
  slice.
- Main pass migrated the demo and tightened the helper after an initial version
  preserved HTML but grew the demo by four lines.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- `Metric` deliberately preserves the current `am-metric` and
  `am-demo-subtle` compatibility selectors.
- The current source uses compact array joins in the two metric grids to keep
  the demo shrinking while preserving byte-identical generated indentation.
- Page cards, terminal previews, dashboard shell, collaboration panels, and
  patterns composition bands remain page-local extraction targets.

## Phase 37 - Vanilla Collaboration Wrapper Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `rm -rf output/web-design-system-before-phase37 test-results/web-design-system-before-phase37 && crystal run examples/web_design_system_demo.cr && mkdir -p output/web-design-system-before-phase37 && cp output/web-design-system-*.html output/web-design-system-before-phase37/ && crystal run scripts/validate_web_demo.cr && crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr && mkdir -p test-results/web-design-system-before-phase37 && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase37/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase37/`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase37 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase37 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr src/components/design_system/primitives.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase37/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase37/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 25 examples, 0 failures.
- Design-system plus example component specs pass: 87 examples, 0 failures.
- Broader focused web proof specs pass: 319 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::ChatPanel`,
  `Components::DesignSystem::LiveSearchPanel`, and
  `Components::DesignSystem::UploadQueue` as generic vanilla collaboration
  wrappers.
- `ChatPanel` owns the labelled chrome, `role="log" aria-live="polite"` message
  region, native composer form, and neutral `data-ap-chat-*` hooks with current
  `data-amber-*` compatibility aliases.
- `LiveSearchPanel` owns the labelled panel shell and `role="status"
  aria-live="polite"` result region with neutral and compatibility hooks.
- `UploadQueue` owns the labelled upload queue shell while keeping supplied item
  and progress HTML byte-stable.
- The collaboration page now uses these wrappers instead of page-local panel
  body strings. It still uses the existing field, badge, button, progress, and
  empty-state primitives inside the wrappers.
- The old reactive `ChatComponent` and `LiveSearchComponent` remain unpromoted
  examples and are not treated as Milestone 1 canonical components.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1679 to 1677 lines during
  this phase.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- `src/components/design_system/primitives.cr` grew to 1179 lines because it now
  owns the three collaboration wrappers.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- Marker count stayed at 74 demo-local `am-*`, `data-ap-*`, `data-amber-*`,
  section/form/dialog markers.
- Generated HTML diff against `output/web-design-system-before-phase37/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 37 before snapshots:
  `collaboration-desktop-light.png` RMSE `651.493 (0.00994115)`,
  `collaboration-mobile-light.png` `45.6866 (0.000697133)`,
  `desktop-light.png` `274.94 (0.00419531)`,
  `dashboard-desktop-light.png` `246.438 (0.00376041)`.
- Because generated HTML is byte-identical, the nonzero PNG values are treated
  as browser capture, timing, or animation variance rather than accepted design
  drift.

Adversarial review:

- Worker agent added the wrappers, exact-output specs, and docs under a narrow
  ownership slice.
- Main pass migrated the collaboration page and tightened the upload wrapper
  call so the phase shrank the demo while preserving byte-identical output.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- The wrappers intentionally keep narrow raw HTML slots so migration remains
  byte-stable. Inner field/item/progress composition is still caller-owned.
- A future richer `ChatPanel`/`LiveSearchPanel` API should accept structured
  messages, result rows, and upload items, then render the same accessible
  anatomy without raw slots.
- The runtime remains a single helper file; modular vanilla behavior extraction
  is still open.

## Phase 38 - PageLinkCard Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `rm -rf output/web-design-system-before-phase38 test-results/web-design-system-before-phase38 && crystal run examples/web_design_system_demo.cr && mkdir -p output/web-design-system-before-phase38 && cp output/web-design-system-*.html output/web-design-system-before-phase38/ && crystal run scripts/validate_web_demo.cr && crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr && mkdir -p test-results/web-design-system-before-phase38 && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase38/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase38/`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase38 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase38 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr src/components/design_system/primitives.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `rg -n 'am-page-card"' examples/web_design_system_demo.cr`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase38/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase38/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 27 examples, 0 failures.
- Design-system plus example component specs pass: 89 examples, 0 failures.
- Broader focused web proof specs pass: 321 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::PageLinkCard` for the overview page
  navigation-card pattern.
- PageLinkCard renders the current anatomy exactly:
  `<a class="am-page-card" href="..."><strong>Title</strong><span>Summary</span><small>Open title</small></a>`.
- PageLinkCard supports `summary`/`body`/`copy`, optional `action_label`, and
  conservative `id`, extra `class`, `data-*`, and `aria-*` passthrough.
- The overview page-card map now calls `PageLinkCard` instead of embedding raw
  anchor/card markup.
- Component API/catalog docs now list `PageLinkCard` as an extracted page
  primitive.

Visual/accountability result:

- `examples/web_design_system_demo.cr` remains 1677 lines. The phase did not
  grow the demo, and it removed the raw page-card marker from the source.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- `src/components/design_system/primitives.cr` grew to 1201 lines because it now
  owns PageLinkCard.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- Marker count dropped from 74 to 73 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers.
- `rg -n 'am-page-card"' examples/web_design_system_demo.cr` returns no
  matches.
- Generated HTML diff against `output/web-design-system-before-phase38/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 38 before snapshots:
  `desktop-light.png` RMSE `371.066 (0.0056621)`,
  `desktop-dark.png` `152.8 (0.00233157)`,
  `mobile-light.png` `9.5297 (0.000145414)`,
  `dashboard-desktop-light.png` `246.438 (0.00376041)`.
- Because generated HTML is byte-identical, the nonzero PNG values are treated
  as browser capture, timing, or animation variance rather than accepted design
  drift.

Adversarial review:

- Worker agent added the primitive, exact-output specs, and docs under a narrow
  ownership slice.
- Main pass migrated the overview page-card map and tightened the call site so
  the phase did not grow the demo while preserving byte-identical output.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- PageLinkCard deliberately preserves the current `am-page-card` compatibility
  selector.
- The surrounding `am-page-card-grid` remains page-local. A future grid/list
  wrapper can own that container if it appears outside the overview page.
- More page-local code remains in terminal previews, dashboard shell, and
  patterns composition bands.

## Phase 39 - TerminalPreview Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `rm -rf output/web-design-system-before-phase39 test-results/web-design-system-before-phase39 && crystal run examples/web_design_system_demo.cr && mkdir -p output/web-design-system-before-phase39 && cp output/web-design-system-*.html output/web-design-system-before-phase39/ && crystal run scripts/validate_web_demo.cr && crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr && mkdir -p test-results/web-design-system-before-phase39 && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase39/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase39/`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase39 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase39 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr src/components/design_system/primitives.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `rg -n 'am-terminal' examples/web_design_system_demo.cr`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase39/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase39/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 30 examples, 0 failures.
- Design-system plus example component specs pass: 92 examples, 0 failures.
- Broader focused web proof specs pass: 324 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::TerminalPreview` for static command/output
  previews.
- TerminalPreview renders the current `am-terminal` and `am-terminal-line`
  anatomy, names the region with `aria-label`, and accepts `commands` or
  `lines` arrays.
- Added `compatibility_markup: "demo"` output to preserve existing overview
  terminal whitespace exactly during migration.
- The overview proof terminal now uses TerminalPreview instead of raw terminal
  markup.
- Component API/catalog docs now list `TerminalPreview` as an extracted page
  primitive.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1677 to 1673 lines during
  this phase.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- `src/components/design_system/primitives.cr` grew to 1262 lines because it now
  owns TerminalPreview and its compatibility renderer.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- Marker count dropped from 73 to 69 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers.
- `rg -n 'am-terminal' examples/web_design_system_demo.cr` returns only CSS
  selector definitions, not body markup.
- Generated HTML diff against `output/web-design-system-before-phase39/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 39 before snapshots:
  `desktop-light.png` RMSE `149.32 (0.00227847)`,
  `desktop-dark.png` `353.054 (0.00538726)`,
  `mobile-light.png` `591.597 (0.00902719)`,
  `dashboard-desktop-light.png` `246.438 (0.00376041)`.
- Because generated HTML is byte-identical, the nonzero PNG values are treated
  as browser capture, timing, or animation variance rather than accepted design
  drift.

Adversarial review:

- Worker agent added the primitive, exact-output specs, and docs under a narrow
  ownership slice.
- Main pass found the compact renderer would cause avoidable generated HTML
  whitespace drift, so this phase added a demo compatibility renderer and an
  exact whitespace spec before accepting the migration.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- TerminalPreview deliberately preserves the current `am-terminal` and
  `am-terminal-line` compatibility selectors.
- It is static HTML only and does not attempt to implement an interactive
  terminal emulator.
- More page-local code remains in the dashboard shell and patterns composition
  bands.

## Phase 40 - DashboardShell Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `rm -rf output/web-design-system-before-phase40 test-results/web-design-system-before-phase40 && crystal run examples/web_design_system_demo.cr && mkdir -p output/web-design-system-before-phase40 && cp output/web-design-system-*.html output/web-design-system-before-phase40/ && crystal run scripts/validate_web_demo.cr && crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr && mkdir -p test-results/web-design-system-before-phase40 && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase40/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase40/`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase40 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr && crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase40 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr src/components/design_system/primitives.cr public/js/design-system.js public/js/amber-design-system.js`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `rg -n 'am-dashboard-shell|am-sidebar|am-dashboard-main' examples/web_design_system_demo.cr`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase40/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase40/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 33 examples, 0 failures.
- Design-system plus example component specs pass: 95 examples, 0 failures.
- Broader focused web proof specs pass: 327 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::DashboardShell` for the dashboard page shell
  with sidebar and main content slots.
- DashboardShell owns the root `am-section`, `am-dashboard-shell`,
  `am-sidebar`, and `am-dashboard-main` anatomy, with `aria-labelledby` on the
  section and `aria-label` on the sidebar.
- Added `compatibility_markup: "demo"` output to preserve existing dashboard
  shell whitespace exactly during migration.
- The dashboard page now delegates the shell/sidebar/main wrappers to
  DashboardShell instead of owning the wrapper markup directly.
- Component API/catalog docs now list `DashboardShell` as an extracted page
  primitive.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1673 to 1671 lines during
  this phase.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- `src/components/design_system/primitives.cr` grew to 1329 lines because it now
  owns DashboardShell and its compatibility renderer.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- Marker count dropped from 69 to 65 demo-local `am-*`, `data-ap-*`,
  `data-amber-*`, section/form/dialog markers.
- `rg -n 'am-dashboard-shell|am-sidebar|am-dashboard-main'
  examples/web_design_system_demo.cr` returns only CSS selector definitions,
  not body markup.
- Generated HTML diff against `output/web-design-system-before-phase40/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 40 before snapshots:
  `dashboard-desktop-light.png` RMSE `246.438 (0.00376041)`,
  `dashboard-mobile-light.png` `0 (0)`,
  `desktop-light.png` `148.922 (0.00227241)`,
  `desktop-dark.png` `377.932 (0.00576688)`.
- Because generated HTML is byte-identical, the nonzero PNG values are treated
  as browser capture, timing, or animation variance rather than accepted design
  drift.

Adversarial review:

- Worker agent added the primitive, exact-output specs, and docs under a narrow
  ownership slice.
- Main pass added a demo compatibility renderer and migrated the dashboard page
  only after confirming generated HTML remained byte-identical.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- DashboardShell intentionally keeps raw `sidebar_html` and `body_html` slots
  for byte-stable migration. A future richer API should accept structured
  sidebar links, toolbar content, metric groups, and content slots.
- DashboardShell preserves current `am-*` compatibility selectors.
- More page-local code remains in the patterns composition bands and some
  overview/product-hero-specific layout.

## Phase 41 - Divider and VisualBand Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run examples/web_design_system_demo.cr`
- `diff -ru output/web-design-system-before-phase41 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase41 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `wc -l examples/web_design_system_demo.cr src/components/design_system/primitives.cr`
- `rg -n 'am-divider|am-parallax-band' examples/web_design_system_demo.cr`
- `rg -c 'am-[a-z0-9-]+' examples/web_design_system_demo.cr`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase41/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase41/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 38 examples, 0 failures.
- Design-system plus example component specs pass: 100 examples, 0 failures.
- Broader focused web proof specs pass: 332 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::Divider` for labeled section dividers.
- Added `Components::DesignSystem::VisualBand` for large CSS/SVG-first visual
  bands with escaped title/body text and an intentionally raw child slot.
- Migrated the patterns page launch-composition divider and parallax-style band
  to the new primitives.
- Added `compatibility_markup: "demo"` output for VisualBand so the current demo
  can shrink without changing generated HTML whitespace.
- Component API/catalog docs now list Divider and VisualBand under generic
  design-system primitives.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1671 to 1668 lines during
  this phase.
- `src/components/design_system/primitives.cr` grew to 1383 lines because it now
  owns Divider and VisualBand.
- `rg -n 'am-divider|am-parallax-band' examples/web_design_system_demo.cr`
  returns only CSS selector definitions, not body markup.
- Demo-local `am-*` marker count is 279.
- Generated HTML diff against `output/web-design-system-before-phase41/` is
  empty after excluding unrelated historical output files.
- Targeted screenshot comparison against Phase 41 before snapshots:
  `patterns-desktop-light.png` RMSE `0 (0)`,
  `patterns-mobile-light.png` `0.377155 (5.75502e-06)`,
  `patterns-desktop-dark.png` `6.10598 (9.31713e-05)`,
  `desktop-light.png` `155.361 (0.00237066)`,
  `mobile-light.png` `225.537 (0.00344147)`.
- Because generated HTML is byte-identical and the targeted patterns desktop
  light screenshot is exact, the nonzero PNG values are treated as browser
  capture, timing, or animation variance rather than accepted design drift.

Adversarial review:

- Worker agent implemented Divider/VisualBand, specs, and docs under a narrow
  ownership slice, and called out the raw child-slot risk.
- Main pass fixed the compatibility spec to assert the exact current demo
  whitespace and confirmed generated HTML remained byte-identical.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- VisualBand intentionally accepts raw child content for existing SVG markup.
  Future APIs should add typed SVG/image slots or named visual treatments so
  agents do not have to hand-author accessibility-sensitive raw HTML.
- Divider and VisualBand preserve current `am-*` compatibility selectors.
- Broader public language should continue moving toward generic component and
  primitive names, with Amber terminology limited to compatibility wrappers and
  historical migration notes.

## Phase 42 - Agent Accessibility and Generic Naming Contract

Changed files:

- `AGENTS.md`
- `README.md`
- `docs/web-design-system/README.md`
- `docs/web-design-system/accessibility-contract.md`
- `docs/web-design-system/agent-playbook.md`
- `docs/web-design-system/generated-view-conventions.md`
- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/forbidden-patterns.md`
- `docs/web-design-system/visual-language.md`
- `templates/design-system/AGENTS.md`
- `templates/design-system/CLAUDE.md`
- `templates/design-system/design-system.routes.yml`
- `examples/web_design_system_demo.cr`
- `src/generators/brand_kit.cr`
- `src/components/css/config/css_config.cr`
- `output/brand-kit.html`
- `output/web-design-system-demo.html`
- `test-results/web-design-system/`
- `output/web-design-system-before-phase42/`
- `test-results/web-design-system-before-phase42/`

Commands run:

- `rm -rf output/web-design-system-before-phase42 test-results/web-design-system-before-phase42 && mkdir -p output/web-design-system-before-phase42 test-results/web-design-system-before-phase42 && cp output/web-design-system-*.html output/web-design-system-before-phase42/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase42/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase42/`
- `crystal run examples/web_design_system_demo.cr && diff -ru output/web-design-system-before-phase42 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal build --no-codegen src/generators/brand_kit.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `crystal run src/generators/brand_kit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase42 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- Targeted `rg` check for stale Amber/naming/API phrases:
  `Amber V2`, `amber_agent_check`, `amberframework.org`,
  `Toast.new(message:)`, and stale PageShell full-document ownership text.
- `wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js docs/web-design-system/accessibility-contract.md templates/design-system/AGENTS.md templates/design-system/CLAUDE.md`
- `rg -n 'class="am-|data-(ap|amber)-|<section|<form|<dialog' examples/web_design_system_demo.cr | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase42/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase42/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Updated brand-kit output in `output/brand-kit.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Primitive specs pass: 38 examples, 0 failures.
- Design-system plus example component specs pass: 100 examples, 0 failures.
- Broader focused web proof specs pass: 332 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Brand-kit generator compiles and regenerates.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.
- Targeted grep checks find no remaining `Amber V2`, `amber_agent_check`,
  `amberframework.org`, stale `Toast.new(message:)`, or stale PageShell
  full-document ownership text in the public docs/source touched by this phase.

What this phase adds:

- Added `docs/web-design-system/accessibility-contract.md` as the agent-facing
  WCAG AA-oriented contract for page shells, forms, interactions, data
  visualization, automated evidence, drift gates, and component promotion.
- Added a component accessibility matrix that names which semantics each
  primitive owns and which duties still remain with callers, especially raw
  slots.
- Added `templates/design-system/CLAUDE.md` so Claude-oriented consuming apps
  receive the same no-build, generic-naming, accessibility, and validation
  guidance as `AGENTS.md`.
- Updated root/downstream docs to make accessibility part of the component API,
  not caller cleanup.
- Changed the future validation manifest artifact path from
  `test-results/amber` to `test-results/design-system`.
- Reconciled stale API docs: PageShell is now documented as an in-page shell,
  implemented feedback primitives are no longer under "Next Extraction API
  Targets", and Toast examples use `body:`.
- Removed public Amber-specific language found by the naming audit from
  brand-kit copy, the web demo overview link/copy, and the agent-DX roadmap.

Visual/accountability result:

- A Phase 42 before snapshot was captured before editing visible demo copy.
- Generated HTML drift is intentionally limited to two overview-page changes:
  external link target `https://amberframework.org` to
  `https://crystal-lang.org`, and component-contract copy changing from
  public `am-*` language to generic component APIs plus token-backed
  compatibility selectors.
- `examples/web_design_system_demo.cr` remains 1668 lines.
- `examples/amber_design_system_demo.cr` remains a 3-line compatibility wrapper.
- Runtime files remain 878 lines each and byte-for-byte synchronized.
- `docs/web-design-system/accessibility-contract.md` is 241 lines,
  `templates/design-system/AGENTS.md` is 132 lines, and
  `templates/design-system/CLAUDE.md` is 96 lines.
- Marker count for demo-local `am-*`, `data-ap-*`, `data-amber-*`,
  section/form/dialog markers is 63.
- Targeted screenshot comparison against Phase 42 before snapshots:
  `desktop-light.png` RMSE `1936.78 (0.0295534)`,
  `mobile-light.png` `2494.33 (0.0380611)`,
  `desktop-dark.png` `1943.16 (0.0296507)`,
  `mobile-dark.png` `2583.47 (0.0394212)`.
- Browser-audit JSON drift is limited to overview mobile/reflow page height
  increasing by 28px due the copy length. Accessibility-tree drift is limited
  to one additional overview inline text node in light/dark captures. IBM
  snippets reflect only the external link URL change.

Adversarial review:

- Naming explorer found concrete blocking naming issues. This phase addressed
  the in-scope items: brand-kit `Amber V2` copy, downstream manifest artifact
  path, public demo `am-*` copy, `amber_agent_check`, visible
  `amberframework.org` link, and a config comment.
- Accessibility/DX explorer found the proof stronger than the installable
  contract. This phase added the accessibility contract and matrix, fixed
  stale PageShell/Toast docs, and recorded the remaining larger gaps.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- Runtime accessibility behavior still lives mainly in
  `public/js/design-system.js`; it should become documented behavior modules
  and config rather than implementation knowledge.
- Validation remains demo-locked. The next durable step is a manifest-driven
  validator that can run against consuming apps.
- Browser-audit pass/fail criteria are richer than the docs; they should be
  formalized in a validation manifest and reusable reporting contract.
- Raw HTML slots remain necessary for byte-stable migration and need typed
  alternatives over time.
- Spec helper APIs such as `expect_accessible_control`,
  `expect_no_duplicate_ids`, `expect_error_wiring`, and `expect_live_region`
  remain to be built.

## Phase 43 - Reusable Accessibility Spec Helpers

Changed files:

- `spec/support/accessibility_matchers.cr`
- `spec/support/accessibility_matchers_spec.cr`
- `spec/spec_helper.cr`
- `spec/components/design_system/primitives_spec.cr`
- `spec/components/examples/example_components_spec.cr`
- `src/components/examples/theme_switcher_component.cr`
- `docs/web-design-system/accessibility-contract.md`
- `docs/web-design-system/agent-playbook.md`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `templates/design-system/AGENTS.md`
- `templates/design-system/CLAUDE.md`
- `output/web-design-system-*.html`
- `test-results/web-design-system/`
- `output/web-design-system-before-phase43/`
- `test-results/web-design-system-before-phase43/`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal spec spec/support/accessibility_matchers_spec.cr spec/components/design_system/primitives_spec.cr spec/components/examples/example_components_spec.cr`
- `crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr`
- `rm -rf output/web-design-system-before-phase43 test-results/web-design-system-before-phase43 && mkdir -p output/web-design-system-before-phase43 test-results/web-design-system-before-phase43 && cp output/web-design-system-*.html output/web-design-system-before-phase43/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase43/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase43/`
- `crystal run examples/web_design_system_demo.cr && diff -ru output/web-design-system-before-phase43 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr spec/support/accessibility_matchers_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/validate_web_demo.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/web-design-system-before-phase43 -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `compare -metric RMSE ...`
- `diff -ru test-results/web-design-system-before-phase43 test-results/web-design-system --exclude='*.png'`
- `wc -l spec/support/accessibility_matchers.cr spec/support/accessibility_matchers_spec.cr spec/spec_helper.cr spec/components/design_system/primitives_spec.cr spec/components/examples/example_components_spec.cr src/components/examples/theme_switcher_component.cr docs/web-design-system/accessibility-contract.md`
- `rg -n 'expect_accessible_control|expect_no_duplicate_ids|expect_error_wiring|expect_live_region|expect_relationship_targets_exist|expect_behavior_hook_pair|expect_source_data_table' spec docs/web-design-system templates/design-system | wc -l`
- `git diff --check`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase43/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase43/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`
- `test-results/web-design-system/static-audit.json`
- `test-results/web-design-system/browser-audit.json`
- `test-results/web-design-system/axe-audit.json`
- `test-results/web-design-system/ibm-equal-access-audit.json`

What passes:

- Helper, primitive, and example component specs pass: 91 examples, 0 failures.
- Design-system plus example component specs pass: 100 examples, 0 failures.
- Broader focused web proof specs pass: 336 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static, browser screenshot, axe, and IBM audits pass against the generic
  `output/web-design-system-*.html` page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- `git diff --check` passes.

What this phase adds:

- Added shared snippet-level accessibility assertions in
  `spec/support/accessibility_matchers.cr`.
- `spec/spec_helper.cr` now requires and includes those helpers for all specs.
- Helper coverage includes forbidden Bootstrap-shaped classes, duplicate ids,
  labelled controls, error wiring, live-region semantics, relationship target
  checks, neutral/legacy behavior hook pairs, fieldset legends, source-data
  tables, inline event handlers, positive tabindex, and invalid tabindex.
- Added negative tests proving the helpers fail on common regressions:
  duplicate ids, missing labels, broken `aria-describedby`, empty
  `aria-labelledby`, `aria-live="off"`, positive tabindex, invalid tabindex,
  inline handlers, and Bootstrap-shaped classes.
- Updated focused component specs to consume the helpers across forms, payment,
  auth, dialogs, command palette, carousel, charts, heatmaps, PageShell,
  Fieldset, and ValidatedForm.
- Updated docs/templates so future agents know the fast snippet helpers exist
  and that they complement, not replace, browser/axe/IBM evidence.
- Improved `ThemeSwitcherComponent` toggle mode so visible theme status is a
  polite live region.

Visual/accountability result:

- A Phase 43 before snapshot was captured from the current Phase 42 generated
  output before regenerating the pages.
- Generated HTML drift is intentionally limited to the global theme-status
  element on all seven pages. It now adds `role="status" aria-live="polite"` to
  the existing `span.am-theme-status`.
- `spec/support/accessibility_matchers.cr` is 199 lines and
  `spec/support/accessibility_matchers_spec.cr` is 66 lines.
- `docs/web-design-system/accessibility-contract.md` grew to 259 lines.
- There are 67 helper references across specs/docs/templates after this phase.
- Targeted screenshot comparison against Phase 43 before snapshots:
  `desktop-light.png` RMSE `283.751 (0.00432977)`,
  `mobile-light.png` `233.093 (0.00355676)`,
  `desktop-dark.png` `306.918 (0.00468327)`,
  `mobile-dark.png` `1072.16 (0.0163602)`.
- Browser accessibility-tree drift is the expected status-role improvement:
  each page gains a `status` role and loses one `none` role for the theme
  status node. No audit failures were introduced.

Adversarial review:

- Explorer agent reviewed the helper draft and identified stricter requirements:
  reject `aria-live="off"`, accept visible button/link text as names, verify
  relationship target existence/text, fail invalid tabindex, add behavior-hook
  pairs, and add negative tests. This phase incorporated those recommendations.
- Explorer also flagged a bad `advanced-panel-control` assertion in the draft;
  the main pass removed it instead of changing compatibility output.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- Helpers intentionally use lightweight regex parsing for fast snippet checks.
  They are not a full HTML parser and do not replace the existing static,
  browser, axe, IBM, keyboard, contrast, or accessibility-tree audits.
- The helpers live in repo `spec/support`; they are not yet packaged as a
  downstream test-support API for consuming apps.
- Manifest-driven validation and runtime behavior modules remain the next
  larger gaps.

## Phase 44 - Manifest-Driven Static Validator

Changed files:

- `scripts/validate_design_system_manifest.cr`
- `docs/web-design-system/web-demo.routes.yml`
- `templates/design-system/design-system.routes.yml`
- `spec/scripts/validate_design_system_manifest_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/evidence.md`
- `docs/web-design-system/agent-playbook.md`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/compiler-command-matrix.md`
- `docs/web-design-system/agent-dx-gap-analysis.md`
- `docs/web-design-system/agent-dx-roadmap.md`
- `templates/design-system/AGENTS.md`
- `templates/design-system/CLAUDE.md`
- `test-results/web-design-system/static-manifest-audit.json`
- `output/web-design-system-before-phase44/`
- `test-results/web-design-system-before-phase44/`
- `docs/web-design-system/phase-notes.md`

Commands run:

- `crystal build --no-codegen scripts/validate_design_system_manifest.cr`
- `crystal run scripts/validate_design_system_manifest.cr`
- `crystal spec spec/scripts/validate_design_system_manifest_spec.cr`
- `crystal spec spec/scripts/validate_design_system_manifest_spec.cr spec/support/accessibility_matchers_spec.cr spec/components/design_system/primitives_spec.cr spec/components/examples/example_components_spec.cr`
- `crystal run examples/web_design_system_demo.cr && crystal run scripts/validate_web_demo.cr && crystal run scripts/validate_design_system_manifest.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr spec/support/accessibility_matchers_spec.cr spec/scripts/validate_design_system_manifest_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `jq '.passed, (.failures | length), (.pages | length), .root, .runtime_files' test-results/web-design-system/static-manifest-audit.json`
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l`
- `find test-results/amber-design-system -maxdepth 1 -name '*.png' | wc -l`
- `gtimeout 90 claude -p "...Adversarial review, no edits..."`
- `rm -rf output/web-design-system-before-phase44 test-results/web-design-system-before-phase44 && mkdir -p output/web-design-system-before-phase44 test-results/web-design-system-before-phase44 && cp output/web-design-system-*.html output/web-design-system-before-phase44/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase44/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase44/ && crystal run examples/web_design_system_demo.cr && diff -ru output/web-design-system-before-phase44 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `git diff --check`

Artifacts:

- Manifest fixture in `docs/web-design-system/web-demo.routes.yml`
- Downstream starter manifest in `templates/design-system/design-system.routes.yml`
- Manifest audit output in `test-results/web-design-system/static-manifest-audit.json`
- Before HTML snapshot in `output/web-design-system-before-phase44/`
- Before screenshot and audit snapshot in `test-results/web-design-system-before-phase44/`
- Canonical generated pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Canonical evidence in `test-results/web-design-system/`
- Compatibility evidence mirror in `test-results/amber-design-system/`

What passes:

- Manifest validator compiles.
- Manifest validator audit passes: 7 pages scanned, 0 failures,
  `passed: true`.
- Manifest regression specs pass: 5 examples, 0 failures.
- Helper, primitive, example component, and manifest specs pass:
  96 examples, 0 failures.
- Broader focused web proof specs pass: 341 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Existing static audit, manifest static audit, browser screenshot capture,
  axe, and IBM audits pass against the generic `output/web-design-system-*.html`
  page set.
- Canonical, compatibility, and before evidence directories all contain
  57 screenshots.
- Generic and compatibility output pages remain byte-for-byte equal after
  regeneration.
- Phase 44's same-phase HTML drift check is empty.
- `git diff --check` passes.

What this phase adds:

- Added `scripts/validate_design_system_manifest.cr`, the first reusable
  static validator driven by a YAML route/component manifest instead of
  hard-coded page constants.
- Added `docs/web-design-system/web-demo.routes.yml` as the current seven-page
  demo fixture.
- Updated the downstream `templates/design-system/design-system.routes.yml`
  shape to use `required_hooks`, `runtime_files`, and broader forbidden runtime
  terms.
- The validator checks page existence, document basics, one `h1`, unique ids,
  labelled controls, ARIA relationship targets, positive/invalid tabindex,
  required `data-component` entries, required `data-ap-*` hooks, required text,
  forbidden classes, forbidden runtime terms in full page/runtime files, and
  inline handlers.
- The validator writes `static-manifest-audit.json` to the manifest-selected
  artifacts directory.
- Added process-level specs proving custom manifest path resolution, explicit
  `false` booleans, missing pages, missing page paths, and forbidden runtime
  terms in runtime files.
- Updated docs and templates so future agents can run the manifest static audit
  and understand that it is static-only.

Visual/accountability result:

- This phase does not intentionally change generated UI.
- A same-phase Phase 44 snapshot was captured after the validator/docs work,
  then the demo was regenerated and diffed against it. The HTML diff was empty.
- Screenshot counts remain 57 in canonical, compatibility, and Phase 44 before
  evidence directories.
- The manifest audit reports root
  `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/output` and
  runtime file
  `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/public/js/design-system.js`.

Adversarial review:

- Explorer agent found blocking issues in the first manifest-validator pass:
  relative paths were resolved against the repo instead of the manifest,
  explicit `false` was ignored, runtime terms were checked only against stripped
  HTML, missing schemas could pass or crash, the manifest fixture overstated
  equivalence with the old static audit, and required hooks/components were
  raw string checks.
- This phase incorporated those findings: relative paths now resolve from the
  manifest directory, explicit `false` is honored, missing pages/paths fail
  cleanly, runtime files are manifest-scanned, required hooks/components use
  attribute-aware checks, ARIA scans handle single and double quotes, and docs
  now call the script static-only.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- The validator still uses lightweight regex-based HTML checks. It is intended
  as a fast static gate, not a browser or full parser replacement.
- It does not yet consume browser/axe/IBM/keyboard/contrast/reduced-motion
  fields from the manifest; those remain handled by the dedicated demo scripts.
- It is not wired into a public `asset_pipeline validate --static` CLI yet.
- The manifest schema is documented by example, not yet formalized as a typed
  Crystal data model or generated schema.

## Phase 45 - Neutral Token Alias Contract

Changed files:

- `src/components/css/tokens/amber_theme.cr`
- `src/components/css/config/css_config.cr`
- `src/components/css/engine/css_parser.cr`
- `src/components/css/engine/css_generator.cr`
- `public/js/design-system.js`
- `public/js/amber-design-system.js`
- `templates/design-system/component.cr`
- `templates/design-system/component_spec.cr`
- `templates/design-system/page.cr`
- `templates/design-system/AGENTS.md`
- `templates/design-system/CLAUDE.md`
- `spec/components/css/amber_design_system_spec.cr`
- `docs/web-design-system/README.md`
- `docs/web-design-system/agent-playbook.md`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/generated-view-conventions.md`
- `docs/web-design-system/phase-notes.md`
- `output/web-design-system-before-phase45/`
- `test-results/web-design-system-before-phase45/`
- Regenerated `output/web-design-system-*.html` and
  `output/amber-design-system-*.html`
- Refreshed `test-results/web-design-system/`

Commands run:

- `rm -rf output/web-design-system-before-phase45 test-results/web-design-system-before-phase45 && mkdir -p output/web-design-system-before-phase45 test-results/web-design-system-before-phase45 && cp output/web-design-system-*.html output/web-design-system-before-phase45/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase45/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase45/`
- `crystal tool format src/components/css/tokens/amber_theme.cr src/components/css/config/css_config.cr src/components/css/engine/css_parser.cr src/components/css/engine/css_generator.cr templates/design-system/component.cr templates/design-system/component_spec.cr templates/design-system/page.cr spec/components/css/amber_design_system_spec.cr`
- `crystal spec spec/components/css/amber_design_system_spec.cr spec/components/design_system/runtime_alias_spec.cr templates/design-system/component_spec.cr`
- `crystal build --no-codegen examples/web_design_system_demo.cr && crystal build --no-codegen templates/design-system/page.cr`
- `crystal run examples/web_design_system_demo.cr && crystal run scripts/validate_web_demo.cr && crystal run scripts/validate_design_system_manifest.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr spec/support/accessibility_matchers_spec.cr spec/scripts/validate_design_system_manifest_spec.cr && crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `diff -q <(sed -e '/<style>/,/<\\/style>/d' -e '/<script>/,/<\\/script>/d' before) <(sed -e '/<style>/,/<\\/style>/d' -e '/<script>/,/<\\/script>/d' after)` for all seven pages
- `compare -metric RMSE ...` on representative before/after screenshots
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `jq '.passed, (.failures | length), (.pages | length)' test-results/web-design-system/static-audit.json test-results/web-design-system/static-manifest-audit.json test-results/web-design-system/axe-audit.json test-results/web-design-system/ibm-equal-access-audit.json`
- Targeted `rg` check for stale explicit screen-reader product-name references
- `gtimeout 90 claude -p "...Adversarial review only, no edits..."`
- `git diff --check`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase45/`
- Before screenshot/audit snapshot in `test-results/web-design-system-before-phase45/`
- Current generated demo pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Current screenshots and audits in `test-results/web-design-system/`

What passes:

- Focused token/runtime/template specs pass: 16 examples, 0 failures.
- Broader web proof specs pass: 341 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static demo audit passes: 7 pages, 0 failures.
- Manifest static audit passes: 7 pages, 0 failures.
- Screenshot capture passes and writes 57 screenshots.
- Axe audit passes: 7 pages, 0 failures.
- IBM Equal Access audit passes: 7 pages, 0 failures.
- Generic and compatibility generated pages remain byte-for-byte equal.
- The seven generated pages have no non-style/non-script markup drift after
  stripping `<style>` and `<script>` blocks.
- `git diff --check` passes.
- The old explicit screen-reader product-name references are no longer present
  in `src`, `docs`, `examples`, `templates`, `scripts`, `public`, or `spec`.

What this phase adds:

- `Components::CSS::Tokens::Theme` now emits neutral `--ap-*` variables as the
  primary token contract.
- Matching `--amber-*` variables are still emitted, but now as aliases pointing
  at the neutral variables.
- Config semantic colors and fonts now prefer `--ap-*` variables with
  `--amber-*` fallbacks.
- Utility parser output now uses neutral token fallbacks for gradients, motion
  durations, easing, and row/section animation utilities.
- Base CSS now uses neutral token fallbacks for body, paragraph, link, and
  focus defaults.
- Generic `ap-row-enter`, `ap-row-exit`, and `ap-section-reveal` keyframes were
  added while keeping current `amber-*` keyframes for compatibility component
  CSS.
- The vanilla runtime row filter now applies `ap-row-*` animations while keeping
  the compatibility runtime file synchronized.
- The downstream component template no longer teaches new `am-*` local classes;
  it now uses `.ap-example-widget`, `--ap-*` tokens, and compatibility
  fallbacks.
- The page template now orders `data-ap-theme` before the compatibility
  `data-amber-theme` attribute.
- Agent-facing docs and installed-template instructions now say neutral
  `--ap-*` tokens and `data-ap-*` hooks are the public direction, while
  `--amber-*`, `am-*`, `data-amber-*`, and `AmberDesignSystem` are alpha
  compatibility details.

Visual/accountability result:

- This phase intentionally changes generated CSS and inline runtime script
  text, not page/component markup.
- Stripping `<style>` and `<script>` from all seven before/after pages yields
  no diff.
- Representative screenshot comparisons stayed low or zero despite recapture
  variance: `desktop-light.png` RMSE `263.879 (0.00402653)`,
  `mobile-light.png` RMSE `259.822 (0.00396463)`,
  `desktop-dark.png` RMSE `636.681 (0.00971513)`,
  `mobile-dark.png` RMSE `276.004 (0.00421154)`,
  `pricing-desktop-light.png` RMSE `0 (0)`,
  `forms-desktop-light.png` RMSE `0 (0)`,
  `dashboard-desktop-light.png` RMSE `38.5787 (0.000588673)`, and
  `patterns-desktop-light.png` RMSE `0 (0)`.
- The demo code line count did not shrink in this phase; this was a public
  naming/token contract slice. The next extraction candidate should be judged
  against the same before/after drift gate.

Adversarial review:

- Explorer agent `Feynman` identified Amber-first tokens, utility mappings,
  runtime exposure, docs, and the downstream template as the safest next public
  naming slice. This phase implements the token/template/docs portion while
  preserving compatibility aliases.
- Explorer agent `Hume` recommended a separate `LayoutGrid` primitive as the
  next lowest-risk demo-shrinking extraction. That recommendation is deferred
  to the next phase because the naming audit exposed a more foundational public
  API gap.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- The public class API is still `am-*` for existing promoted components and
  demo CSS. This phase only stops new template-local wrappers from minting
  `am-*`.
- Most promoted component CSS still references `--amber-*`; the aliases make
  this safe, but the next naming pass should migrate component CSS to `--ap-*`
  fallbacks gradually.
- Runtime private idempotency markers still use `amberBound*`. They are not
  authoring hooks, but they remain visible in live DOM after initialization.
- `public/js/amber-design-system.js` remains a synchronized compatibility copy.
- The demo did not shrink; `LayoutGrid` is the current best next extraction
  candidate for shrinking repeated layout wrappers without visual drift.

## Phase 46 - LayoutGrid Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`
- `output/web-design-system-before-phase46/`
- `test-results/web-design-system-before-phase46/`
- Regenerated `output/web-design-system-*.html` and
  `output/amber-design-system-*.html`
- Refreshed `test-results/web-design-system/`

Commands run:

- `rm -rf output/web-design-system-before-phase46 test-results/web-design-system-before-phase46 && mkdir -p output/web-design-system-before-phase46 test-results/web-design-system-before-phase46 && cp output/web-design-system-*.html output/web-design-system-before-phase46/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase46/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase46/`
- `crystal tool format src/components/design_system/primitives.cr spec/components/design_system/primitives_spec.cr examples/web_design_system_demo.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr spec/components/examples/example_components_spec.cr && crystal build --no-codegen examples/web_design_system_demo.cr`
- `crystal run examples/web_design_system_demo.cr && crystal run scripts/validate_web_demo.cr && crystal run scripts/validate_design_system_manifest.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr spec/support/accessibility_matchers_spec.cr spec/scripts/validate_design_system_manifest_spec.cr && crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `diff -ru output/web-design-system-before-phase46 output --exclude='amber-design-system-*' --exclude='brand-kit.html' --exclude='web-design-system-before-phase*' --exclude='web-design-system-phase31-first' --exclude='about.html' --exclude='gallery.html' --exclude='index.html' --exclude='shop.html'`
- `compare -metric RMSE ...` on representative before/after screenshots
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `jq '.passed, (.failures | length), (.pages | length)' test-results/web-design-system/static-audit.json test-results/web-design-system/static-manifest-audit.json test-results/web-design-system/axe-audit.json test-results/web-design-system/ibm-equal-access-audit.json`
- `gtimeout 90 claude -p "...Adversarial review only, no edits..."`
- `git diff --check`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase46/`
- Before screenshot/audit snapshot in `test-results/web-design-system-before-phase46/`
- Current generated demo pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Current screenshots and audits in `test-results/web-design-system/`

What passes:

- Focused primitive/example checks pass: 90 examples, 0 failures.
- Broader web proof specs pass: 344 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static demo audit passes: 7 pages, 0 failures.
- Manifest static audit passes: 7 pages, 0 failures.
- Screenshot capture passes and writes 57 screenshots.
- Axe audit passes: 7 pages, 0 failures.
- IBM Equal Access audit passes: 7 pages, 0 failures.
- Generic and compatibility generated pages remain byte-for-byte equal.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::LayoutGrid`.
- Supported `kind: "grid"`, `"two"`, `"three"`, `"four"`, and `"metric"`.
- Default LayoutGrid output emits `data-component="layout-grid"` and
  `data-layout-kind` for new generated views.
- `compatibility_markup: "demo"` suppresses extra metadata so current demo
  wrappers can be extracted without changing component anatomy.
- Added passthrough support for root `id`, extra `class`, and `data-*`/`aria-*`
  attributes.
- Added primitive specs for generic metadata output, demo compatibility output,
  and unknown-kind failure.
- Replaced repeated demo `am-two-col`, `am-three-col`, `am-four-col`, and
  `am-metric-grid` wrapper heredocs with a LayoutGrid helper.
- Documented LayoutGrid in the component API and catalog.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1668 lines at the Phase 46
  baseline to 1652 lines after extraction.
- Direct two/three/four/metric grid wrapper heredocs no longer appear in the
  demo body; `rg '<div class="am-(two-col|three-col|four-col|metric-grid)"'
  examples/web_design_system_demo.cr` returns no matches.
- Generated HTML drift is limited to whitespace/indentation around the
  extracted wrappers. Wrapper tags, classes, child order, behavior hooks, and
  accessibility attributes are preserved.
- Representative screenshot comparisons stayed low or zero despite recapture
  variance: `desktop-light.png` RMSE `274.883 (0.00419445)`,
  `mobile-light.png` RMSE `400.726 (0.00611468)`,
  `desktop-dark.png` RMSE `4.84057 (7.38623e-05)`,
  `mobile-dark.png` RMSE `256.388 (0.00391223)`,
  `pricing-desktop-light.png` RMSE `0 (0)`,
  `forms-desktop-light.png` RMSE `0 (0)`,
  `dashboard-desktop-light.png` RMSE `242.682 (0.00370308)`,
  `collaboration-desktop-light.png` RMSE `166.15 (0.00253529)`, and
  `patterns-desktop-light.png` RMSE `0 (0)`.

Adversarial review:

- Explorer agent `Hume` recommended LayoutGrid as the next lowest-risk
  extraction because it is static, behavior-free, already styled, and used
  across multiple pages. This phase implements that recommendation.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- LayoutGrid still maps to current `am-*` compatibility classes because the
  visual CSS surface has not been renamed yet.
- The extraction improved demo source size modestly; larger shrinkage still
  depends on extracting product hero/showcase, page-card grid, and other
  page-local composition patterns.
- Current compatibility mode omits `data-component="layout-grid"` by design, so
  the manifest audit cannot yet assert LayoutGrid usage on the demo pages.

## Phase 47 - PageLinkCardGrid Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/phase-notes.md`
- `output/web-design-system-before-phase47/`
- `test-results/web-design-system-before-phase47/`
- Regenerated `output/web-design-system-*.html` and
  `output/amber-design-system-*.html`
- Refreshed `test-results/web-design-system/`

Commands run:

- `rm -rf output/web-design-system-before-phase47 test-results/web-design-system-before-phase47 && mkdir -p output/web-design-system-before-phase47 test-results/web-design-system-before-phase47 && cp output/web-design-system-*.html output/web-design-system-before-phase47/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase47/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase47/`
- Worker: `crystal spec spec/components/design_system/primitives_spec.cr`
- Worker: `crystal build examples/web_design_system_demo.cr -o /tmp/web_design_system_demo_check`
- Worker: `git diff --check -- src/components/design_system/primitives.cr spec/components/design_system/primitives_spec.cr examples/web_design_system_demo.cr docs/web-design-system/component-api.md docs/web-design-system/component-catalog.md`
- `crystal tool format examples/web_design_system_demo.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr spec/components/examples/example_components_spec.cr && crystal build --no-codegen examples/web_design_system_demo.cr && crystal run examples/web_design_system_demo.cr && crystal run scripts/validate_web_demo.cr && crystal run scripts/validate_design_system_manifest.cr`
- `crystal run examples/web_design_system_demo.cr && for f in web-design-system-demo.html web-design-system-pricing.html web-design-system-forms.html web-design-system-dashboard.html web-design-system-timeline.html web-design-system-collaboration.html web-design-system-patterns.html; do diff -q "output/web-design-system-before-phase47/$f" "output/$f" >/dev/null || echo "html-drift:$f"; done`
- `crystal run scripts/validate_web_demo.cr && crystal run scripts/validate_design_system_manifest.cr && crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr spec/support/accessibility_matchers_spec.cr spec/scripts/validate_design_system_manifest_spec.cr && crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr && crystal run scripts/ibm_web_demo_audit.cr`
- `compare -metric RMSE ...` on representative before/after screenshots
- `for f in demo pricing forms dashboard timeline collaboration patterns; do cmp -s output/web-design-system-$f.html output/amber-design-system-$f.html || echo mismatch:$f; done`
- `for f in web-design-system-demo.html web-design-system-pricing.html web-design-system-forms.html web-design-system-dashboard.html web-design-system-timeline.html web-design-system-collaboration.html web-design-system-patterns.html; do cmp -s "output/web-design-system-before-phase47/$f" "output/$f" || echo "html-drift:$f"; done`
- `jq '.passed, (.failures | length), (.pages | length)' test-results/web-design-system/static-audit.json test-results/web-design-system/static-manifest-audit.json test-results/web-design-system/axe-audit.json test-results/web-design-system/ibm-equal-access-audit.json`
- `gtimeout 90 claude -p "...Adversarial review only, no edits..."`
- `git diff --check`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase47/`
- Before screenshot/audit snapshot in `test-results/web-design-system-before-phase47/`
- Current generated demo pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Current screenshots and audits in `test-results/web-design-system/`

What passes:

- Focused primitive/example checks pass: 92 examples, 0 failures.
- Broader web proof specs pass: 346 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static demo audit passes: 7 pages, 0 failures.
- Manifest static audit passes: 7 pages, 0 failures.
- Screenshot capture passes and writes 57 screenshots.
- Axe audit passes: 7 pages, 0 failures.
- IBM Equal Access audit passes: 7 pages, 0 failures.
- Generic and compatibility generated pages remain byte-for-byte equal.
- All seven regenerated `output/web-design-system-*.html` pages match the
  Phase 47 before snapshot byte-for-byte.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::PageLinkCardGrid`.
- Default output emits `data-component="page-link-card-grid"` for new generated
  views.
- `compatibility_markup: "demo"` suppresses metadata so the current overview
  page-card wrapper can be extracted without changing generated HTML.
- Added root `id`, extra `class`, and `data-*`/`aria-*` passthrough support.
- Added primitive specs for default metadata output and demo compatibility
  output.
- Replaced the direct overview `am-page-card-grid` wrapper with
  `PageLinkCardGrid`.
- Documented PageLinkCardGrid in the component API and catalog.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1652 lines at the Phase 47
  baseline to 1648 lines after tightening the worker patch.
- Regenerated HTML is byte-for-byte identical to
  `output/web-design-system-before-phase47/` across all seven generated pages.
- Representative screenshot comparisons stayed low or zero despite recapture
  variance: `desktop-light.png` RMSE `8.87212 (0.00013538)`,
  `mobile-light.png` RMSE `224.284 (0.00342235)`,
  `desktop-dark.png` RMSE `6.35851 (9.70246e-05)`,
  `mobile-dark.png` RMSE `0 (0)`,
  `pricing-desktop-light.png` RMSE `0 (0)`,
  `forms-desktop-light.png` RMSE `0 (0)`,
  `dashboard-desktop-light.png` RMSE `246.438 (0.00376041)`,
  `collaboration-desktop-light.png` RMSE `166.094 (0.00253444)`, and
  `patterns-desktop-light.png` RMSE `0 (0)`.

Adversarial review:

- Worker agent `Harvey` implemented the initial extraction and ran focused
  primitive specs, a demo compile, and path-limited `git diff --check`.
- Local review found the first worker patch increased the demo source by five
  lines, so the demo call site was tightened before acceptance. The final demo
  file is smaller than the Phase 47 baseline.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124. No external Claude findings were available for this phase.

Weak or deferred:

- PageLinkCardGrid still maps to the current `am-page-card-grid`
  compatibility class because the visual CSS class surface has not been
  renamed.
- The final overview call site is dense because preserving exact HTML while
  shrinking the demo required keeping the card assembly inline. A future helper
  could improve readability if it also shrinks or preserves line count through
  broader extraction.
- Compatibility mode omits `data-component="page-link-card-grid"` by design, so
  the manifest audit cannot assert PageLinkCardGrid usage on the demo page yet.

## Phase 48 - ShowcasePreview Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/accessibility-contract.md`
- `docs/web-design-system/phase-notes.md`
- `output/web-design-system-before-phase48/`
- `test-results/web-design-system-before-phase48/`
- Regenerated `output/web-design-system-*.html` and
  `output/amber-design-system-*.html`
- Refreshed `test-results/web-design-system/`

Commands run:

- `rm -rf output/web-design-system-before-phase48 test-results/web-design-system-before-phase48 && mkdir -p output/web-design-system-before-phase48 test-results/web-design-system-before-phase48 && cp output/web-design-system-*.html output/web-design-system-before-phase48/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase48/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase48/`
- `crystal tool format src/components/design_system/primitives.cr spec/components/design_system/primitives_spec.cr examples/web_design_system_demo.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr spec/components/examples/example_components_spec.cr`
- `crystal build --no-codegen examples/web_design_system_demo.cr`
- `crystal run examples/web_design_system_demo.cr`
- `for f in web-design-system-demo.html web-design-system-pricing.html web-design-system-forms.html web-design-system-dashboard.html web-design-system-timeline.html web-design-system-collaboration.html web-design-system-patterns.html; do cmp -s "output/web-design-system-before-phase48/$f" "output/$f" || echo "html-drift:$f"; done`
- `crystal run scripts/validate_web_demo.cr`
- `crystal run scripts/validate_design_system_manifest.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr spec/support/accessibility_matchers_spec.cr spec/scripts/validate_design_system_manifest_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `compare -metric RMSE ...` on representative before/after screenshots
- `for key in demo pricing forms dashboard timeline collaboration patterns; do cmp -s "output/web-design-system-$key.html" "output/amber-design-system-$key.html" || echo "compat-drift:$key"; done`
- `jq '.passed, (.failures | length), (.pages | length)' test-results/web-design-system/static-audit.json test-results/web-design-system/static-manifest-audit.json test-results/web-design-system/axe-audit.json test-results/web-design-system/ibm-equal-access-audit.json`
- `diff -ru test-results/web-design-system-before-phase48 test-results/web-design-system --exclude='*.png' || true`
- `gtimeout 90 claude -p "...Adversarial review Phase 48..."`
- `git diff --check`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase48/`
- Before screenshot/audit snapshot in `test-results/web-design-system-before-phase48/`
- Current generated demo pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Current screenshots and audits in `test-results/web-design-system/`

What passes:

- Focused primitive/example checks pass: 95 examples, 0 failures.
- Broader web proof specs pass: 349 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static demo audit passes: 7 pages, 0 failures.
- Manifest static audit passes: 7 pages, 0 failures.
- Screenshot capture passes and writes 57 screenshots.
- Axe audit passes: 7 pages, 0 failures.
- IBM Equal Access audit passes: 7 pages, 0 failures.
- Generic and compatibility generated pages remain byte-for-byte equal.
- All seven regenerated `output/web-design-system-*.html` pages match the
  Phase 48 before snapshot byte-for-byte.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::ShowcasePreview`.
- Added `Components::DesignSystem::ShowcasePreview::Step` for static workflow
  rows inside preview windows.
- Default output emits generic `data-component="showcase-preview"` and neutral
  `data-ap-sticky-hover`.
- Default rail output is a labelled static list with `role="list"`,
  `role="listitem"`, and `aria-current="true"` on the active item.
- Empty default rails and empty default step lists are omitted so the component
  does not create empty labelled structures.
- `compatibility_markup: "demo"` preserves the current demo-only
  `am-hero-showcase` anatomy, including `data-amber-sticky-hover`,
  `data-ap-sticky-hover`, and the existing `<nav>` rail, for byte-stable
  extraction.
- Replaced the direct overview hero showcase block with `ShowcasePreview`.
- Documented ShowcasePreview in the component API, component catalog, and
  accessibility matrix, including raw status-slot obligations.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1648 lines at the Phase 48
  baseline to 1642 lines.
- Regenerated HTML is byte-for-byte identical to
  `output/web-design-system-before-phase48/` across all seven generated pages.
- Representative screenshot comparisons stayed low or zero despite browser
  recapture variance: `desktop-light.png` RMSE `438.053 (0.00668426)`,
  `mobile-light.png` RMSE `799.331 (0.012197)`, `desktop-dark.png` RMSE
  `144.105 (0.0021989)`, `mobile-dark.png` RMSE `256.146 (0.00390854)`,
  `pricing-desktop-light.png` RMSE `0 (0)`, `forms-desktop-light.png` RMSE
  `0 (0)`, `dashboard-desktop-light.png` RMSE `79.743 (0.0012168)`,
  `collaboration-desktop-light.png` RMSE `12.5963 (0.000192208)`, and
  `patterns-desktop-light.png` RMSE `0 (0)`.
- Non-PNG artifact diff only reports `contrast-report.csv` newly present in
  the current audit directory after the IBM run.

Adversarial review:

- Explorer agent `Hypatia` recommended a generic static interface-preview
  primitive as the next extraction target and warned against turning the static
  rail into an interactive navigation contract.
- Explorer agent `Volta` found a blocker in the first pass: the public/default
  output used `<nav>` for a static rail made of spans. This was fixed before
  acceptance by keeping `<nav>` only in demo compatibility mode and using
  static list semantics in default output. Specs now cover the corrected rail
  semantics and empty rail/step behavior.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124, both before and after the Volta fix. No external Claude findings
  were available for this phase.

Weak or deferred:

- ShowcasePreview still maps to current `am-*` compatibility classes because
  the visual CSS class surface has not been renamed yet.
- Raw `badge_html` slots remain as migration slots. Docs now require
  non-interactive status content, escaped dynamic text, and visible or
  screen-reader-only status meaning, but a future structured status API would
  be safer.
- Compatibility mode omits `data-component="showcase-preview"` by design, so
  the manifest audit cannot assert ShowcasePreview usage on the demo page yet.
- The demo shrink is modest because preserving exact hero showcase output keeps
  the overview call site declarative but still data-heavy.

## Phase 49 - LandingHero Primitive Extraction

Changed files:

- `src/components/design_system/primitives.cr`
- `spec/components/design_system/primitives_spec.cr`
- `examples/web_design_system_demo.cr`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/accessibility-contract.md`
- `docs/web-design-system/phase-notes.md`
- `output/web-design-system-before-phase49/`
- `test-results/web-design-system-before-phase49/`
- Regenerated `output/web-design-system-*.html` and
  `output/amber-design-system-*.html`
- Refreshed `test-results/web-design-system/`

Commands run:

- `rm -rf output/web-design-system-before-phase49 test-results/web-design-system-before-phase49 && mkdir -p output/web-design-system-before-phase49 test-results/web-design-system-before-phase49 && cp output/web-design-system-*.html output/web-design-system-before-phase49/ && cp test-results/web-design-system/*.png test-results/web-design-system-before-phase49/ && cp test-results/web-design-system/*.json test-results/web-design-system-before-phase49/ && cp test-results/web-design-system/*.csv test-results/web-design-system-before-phase49/`
- `crystal tool format src/components/design_system/primitives.cr spec/components/design_system/primitives_spec.cr examples/web_design_system_demo.cr`
- `crystal spec spec/components/design_system/primitives_spec.cr spec/components/examples/example_components_spec.cr`
- `crystal build --no-codegen examples/web_design_system_demo.cr`
- `crystal run examples/web_design_system_demo.cr`
- `for f in web-design-system-demo.html web-design-system-pricing.html web-design-system-forms.html web-design-system-dashboard.html web-design-system-timeline.html web-design-system-collaboration.html web-design-system-patterns.html; do cmp -s "output/web-design-system-before-phase49/$f" "output/$f" || echo "html-drift:$f"; done`
- `crystal run scripts/validate_web_demo.cr`
- `crystal run scripts/validate_design_system_manifest.cr`
- `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/components/design_system spec/ui/renderers/web_renderer_spec.cr spec/support/accessibility_matchers_spec.cr spec/scripts/validate_design_system_manifest_spec.cr`
- `crystal build --no-codegen templates/design-system/page.cr && crystal spec templates/design-system/component_spec.cr`
- `crystal run scripts/capture_web_demo_screenshots.cr`
- `crystal run scripts/axe_web_demo_audit.cr`
- `crystal run scripts/ibm_web_demo_audit.cr`
- `compare -metric RMSE ...` on representative before/after screenshots
- `for key in demo pricing forms dashboard timeline collaboration patterns; do cmp -s "output/web-design-system-$key.html" "output/amber-design-system-$key.html" || echo "compat-drift:$key"; done`
- `jq '.passed, (.failures | length), (.pages | length)' test-results/web-design-system/static-audit.json test-results/web-design-system/static-manifest-audit.json test-results/web-design-system/axe-audit.json test-results/web-design-system/ibm-equal-access-audit.json`
- `diff -ru test-results/web-design-system-before-phase49 test-results/web-design-system --exclude='*.png' || true`
- `gtimeout 90 claude -p "...Adversarial re-review Phase 49 after fixes..."`
- `git diff --check`

Artifacts:

- Before HTML snapshot in `output/web-design-system-before-phase49/`
- Before screenshot/audit snapshot in `test-results/web-design-system-before-phase49/`
- Current generated demo pages in `output/web-design-system-*.html`
- Compatibility generated pages in `output/amber-design-system-*.html`
- Current screenshots and audits in `test-results/web-design-system/`

What passes:

- Focused primitive/example checks pass: 100 examples, 0 failures.
- Broader web proof specs pass: 354 examples, 0 failures.
- Template compile/spec checks pass: 2 examples, 0 failures.
- Static demo audit passes: 7 pages, 0 failures.
- Manifest static audit passes: 7 pages, 0 failures.
- Screenshot capture passes and writes 57 screenshots.
- Axe audit passes: 7 pages, 0 failures.
- IBM Equal Access audit passes: 7 pages, 0 failures.
- Generic and compatibility generated pages remain byte-for-byte equal.
- All seven regenerated `output/web-design-system-*.html` pages match the
  Phase 49 before snapshot byte-for-byte.
- `git diff --check` passes.

What this phase adds:

- Added `Components::DesignSystem::LandingHero`.
- Added `Components::DesignSystem::LandingHero::Action` for structured button
  and link actions.
- Default output emits generic `data-component="landing-hero"`.
- `LandingHero` owns the visible landing-page `h1` and now raises
  `ArgumentError` for blank titles.
- Text fields and structured action labels/hrefs are escaped.
- External link actions can use `external: true` to emit `target="_blank"` and
  `rel="noopener noreferrer"`.
- Optional toolbar HTML is wrapped in a labelled `role="group"`.
- `aside_html` remains a documented raw migration slot for labelled preview
  content.
- `compatibility_markup: "demo"` preserves the current overview
  `am-demo-hero` anatomy and suppresses metadata for byte-stable extraction.
- Replaced the direct overview product hero shell with `LandingHero`.
- Documented LandingHero in the component API, component catalog, and
  accessibility matrix.

Visual/accountability result:

- `examples/web_design_system_demo.cr` shrank from 1642 lines at the Phase 49
  baseline to 1639 lines.
- Regenerated HTML is byte-for-byte identical to
  `output/web-design-system-before-phase49/` across all seven generated pages.
- Representative screenshot comparisons stayed low or zero despite browser
  recapture variance: `desktop-light.png` RMSE `277.716 (0.00423767)`,
  `mobile-light.png` RMSE `45.5897 (0.000695655)`, `desktop-dark.png` RMSE
  `128.617 (0.00196257)`, `mobile-dark.png` RMSE `890.274 (0.0135847)`,
  `pricing-desktop-light.png` RMSE `0 (0)`, `forms-desktop-light.png` RMSE
  `0 (0)`, `dashboard-desktop-light.png` RMSE `321.038 (0.00489873)`,
  `collaboration-desktop-light.png` RMSE `12.9324 (0.000197335)`, and
  `patterns-desktop-light.png` RMSE `0 (0)`.
- Non-PNG artifact diff is empty against the Phase 49 snapshot.

Adversarial review:

- Explorer agent `Boole` recommended LandingHero as the next isolated,
  generic extraction because it wraps the Phase 48 ShowcasePreview in the
  remaining overview product hero shell.
- Explorer agent `Singer` found a blocker in the first pass: `LandingHero`
  claimed to own a visible `h1` but allowed a blank title. This phase fixed the
  invariant by requiring `title` and raising for blank values, then added a
  regression spec and docs.
- Explorer agent `Pascal` re-reviewed after the fix and found no remaining
  blockers. Pascal reran focused specs, broader specs, template specs, static
  audits, drift checks, and `git diff --check`.
- `claude -p` produced no output before `gtimeout 90` terminated it with exit
  code 124, both before and after the title-invariant fix. No external Claude
  findings were available for this phase.

Weak or deferred:

- LandingHero still maps to current `am-*` compatibility classes because the
  visual CSS class surface has not been renamed yet.
- `LandingHero::Action` button output has no per-action `data-ap-*` passthrough
  yet. This is acceptable for byte-stable extraction, but real in-place hero
  behavior should either route through `Components::DesignSystem::Button` or
  add explicit action attrs/hooks.
- The overview uses button-shaped CTAs for byte stability. Docs now say button
  actions are for in-place behavior and link actions are for navigation; a
  future intentional-HTML-drift phase can convert navigation CTAs to links.
- `toolbar_html` and `aside_html` remain raw migration slots. Docs put inner
  semantics and labelling responsibility on callers, but typed toolbar/preview
  slots would be more enforceable.
- Compatibility mode omits `data-component="landing-hero"` by design, so the
  manifest audit cannot assert LandingHero usage on the generated overview yet.
