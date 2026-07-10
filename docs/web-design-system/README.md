# Web Design System

Milestone 1 is a web-first proof that Asset Pipeline can ship an opinionated
design system instead of a generic utility or Bootstrap-shaped component demo.
The current project files still carry some Amber names because this work lives
inside the Amber ecosystem, but the component/API direction should stay generic:
Button, Card, FormField, Dialog, Tabs, Table, Chart, and other known interface
primitives.

Neutral `--ap-*` CSS variables, `data-ap-*` behavior hooks, and
`Components::DesignSystem::*` Crystal components are the public direction.
Current `--amber-*` variables, `am-*` classes, `data-amber-*` hooks,
`AmberDesignSystem` runtime names, and `amber-design-system-*` artifact paths
are alpha compatibility identifiers. The canonical runtime file is
`public/js/design-system.js`; `public/js/amber-design-system.js` is a
compatibility copy while generated artifact paths still move toward unbranded
names. Treat branded names below as current compatibility output, not the
long-term contract.

## What Ships

- Semantic token model: `Components::CSS::Tokens::Theme`
- Default theme with light and dark `--ap-*` CSS variables plus `--amber-*`
  compatibility aliases
- Token-aware utility colors such as `bg-danger-subtle`, `border-danger-strong`,
  `text-muted`, `ring-focus`, and `bg-surface-elevated`
- Component variant contract: family, tone, emphasis, size, and state
- Canonical Button, Card, FormField, ThemeSwitcher, PricingCard, DataTable,
  SimpleChart, PaymentForm, AuthForm, CommandPalette, Tabs, Carousel, Dialog,
  ScheduleHeatmap, Timeline, Counter, Form, Chat, and LiveSearch components,
  exposed through `Components::DesignSystem::*` while keeping
  `Components::Examples::*Component` compatibility classes and current `am-*`
  output during migration
- Vanilla JavaScript helpers in `public/js/design-system.js`, exposing
  `AssetPipelineDesignSystem` with the current `AmberDesignSystem`
  compatibility alias through `public/js/amber-design-system.js`
- Font delivery API for CDN and self-hosted strategies
- Static demo generator: `crystal run examples/web_design_system_demo.cr`
- Static no-Node demo audit: `crystal run scripts/validate_web_demo.cr`
- Manifest-driven static audit:
  `crystal run scripts/validate_design_system_manifest.cr`
- Browser screenshot audit: `crystal run scripts/capture_web_demo_screenshots.cr`
- Independent axe-core browser audit, run through Crystal + CDP:
  `crystal run scripts/axe_web_demo_audit.cr`
- Independent IBM Equal Access browser audit, run through Crystal + CDP:
  `crystal run scripts/ibm_web_demo_audit.cr`
- Multi-page static demo output:
  `output/web-design-system-demo.html`,
  `output/web-design-system-pricing.html`,
  `output/web-design-system-forms.html`,
  `output/web-design-system-dashboard.html`,
  `output/web-design-system-timeline.html`,
  `output/web-design-system-collaboration.html`, and
  `output/web-design-system-patterns.html`.
  Compatibility copies are still written to the old `amber-design-system-*`
  filenames during the migration.
- Expanded demo coverage for a fictional Frontloader Studio SaaS: home,
  pricing/payment, auth/forms, dashboard/data, Crystal timeline,
  collaboration/search/chat, page patterns, and explicit light/dark controls

`examples/README.md` marks the pre-existing Stimulus/import-map/Bootstrap-shaped
examples as historical. New design-system examples should use
`examples/web_design_system_demo.cr` as the starting point.
`docs/web-design-system/component-contracts.md` defines the reusable wrapper
contracts and the evidence expected for promoted components.
`docs/web-design-system/accessibility-contract.md` turns the accessibility work
proven in the demo into agent-facing rules for page shells, forms,
interactions, data visualization, automated evidence, and no-drift refactors.
`docs/web-design-system/component-api.md` lists the current agent-facing
component entrypoints, behavior hooks, and accessibility obligations.
`docs/web-design-system/visual-language.md` defines the taste target for
palette, typography, layout, motion, and accessibility. `docs/web-design-system/evidence.md`
summarizes the canonical-surface audit, screenshot matrix, reduced-motion
matrix, accessibility artifacts, font strategy, and chart strategy.
`docs/web-design-system/agent-dx-gap-analysis.md` and
`docs/web-design-system/agent-dx-roadmap.md` describe the remaining gap
between the accessible proof and an installable agent-friendly library API.
`docs/web-design-system/agent-playbook.md` and
`docs/web-design-system/generated-view-conventions.md` are the working
instructions for agents generating new design-system web views.
`docs/web-design-system/forbidden-patterns.md` gives concrete examples of
blocked output and the correct design-system shape.
`docs/web-design-system/compiler-command-matrix.md` separates the current web
proof commands from native `crystal-alpha` builds.
`docs/web-design-system/refactor-accountability.md` defines the extraction
loop: demo code should shrink, regenerated pages should remain visually
equivalent, and before/after screenshots should be compared for every
meaningful component extraction.
`docs/web-design-system/phase-1-baseline.md` pins the current screenshot matrix,
line counts, and key screenshot hashes for Phase 2 comparisons.

## Design Choices

The default visual voice is warm but not brand-locked. The current proof uses a
Frontloader Studio direction: a warm action color for primary intent, ink for
quiet SaaS surfaces, teal/cyan for operational intelligence, and restrained
semantic color for status. The result is product-like instead of an
orange-black theme or a framework-branded skin.

Tokens are semantic before they are visual. A danger row, for example, does not
ask for a red utility directly; it gets coordinated `indicator`, `bg`,
`bg-hover`, `border`, `text`, and `focus-ring` values from the danger group.

Motion is useful but optional. Row filtering, section reveal, chart growth,
sticky hover, and SVG sequencing all respect `prefers-reduced-motion`.

Theme switching is owned by the shared vanilla helper. The neutral contract is
`data-ap-theme-toggle` plus explicit `data-ap-theme-set="dark"` /
`data-ap-theme-set="light"` controls, co-emitted with the current
`data-amber-*` aliases during migration. The current alpha implementation uses
the equivalent compatibility hooks, sets both `data-ap-theme` and
`data-amber-theme` on `<html>`, updates pressed states, updates the visible
label to the next available mode when a theme label hook is present, and stores
the preference in `localStorage`. Explicit light mode emits matching light token
variables so it wins even when the browser or OS preference is dark.

Forms are semantic first. Demo forms use native HTML attributes such as
`type="email"`, `autocomplete`, `required`, `minlength`, `pattern`, and
`inputmode`; vanilla JavaScript adds password-rule feedback, password
confirmation, payment field formatting, promo-code feedback, and live-region
status updates.

Charts are first-party for the proof. `SimpleChartComponent` renders token-backed
SVG and declares `data-chart-adapter="first-party-svg"`. External libraries must
mount through the isolated `adapter="external"` root and preserve the figure,
caption, token shell, and source-data table; they should not become a hard
default dependency.

## Theme API

New code should use the neutral theme constructor, config method, `--ap-*`
variables, and `data-ap-theme` attributes. Amber-era method names, `--amber-*`
variables, and `data-amber-theme` attributes remain as compatibility aliases.

```crystal
theme = Components::CSS::Tokens::Theme.design_system_default
theme.override_token(
  "brand-primary",
  "oklch(0.7 0.2 60)",
  "oklch(0.78 0.18 60)"
)

config = Components::CSS::Config.new.use_design_system_theme(theme)
css = Components::CSS::Engine::Generator.new(config).generate
```

Light tokens are emitted as `--ap-*` variables in `:root`,
`[data-ap-theme="light"]`, and `[data-amber-theme="light"]`. Dark tokens are
emitted for `@media (prefers-color-scheme: dark)`, `[data-ap-theme="dark"]`,
and `[data-amber-theme="dark"]`. Matching `--amber-*` aliases point at the
neutral variables so compatibility selectors keep working without making Amber
the public token contract.

## Fonts

Use `Components::Assets::FontAsset.cdn` for stylesheet-based delivery and
`Components::Assets::FontAsset.self_hosted` for preload plus `@font-face`.
The default demo uses hosted Inter and Newsreader for convenience, but the API
does not require an external provider. Production apps can switch to self-hosted
`woff2` files while keeping the same token variables and fallback stacks.

```crystal
manifest = Components::Assets::FontManifest.new
manifest << Components::Assets::FontAsset.cdn("Newsreader", "https://example.test/newsreader.css")
manifest << Components::Assets::FontAsset.self_hosted("Inter", "/assets/inter-var.woff2", weight: "100 900")

head_links = manifest.link_tags
font_css = manifest.font_face_css
```

## Validation

Run the focused web proof checks:

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
```

The static audit writes `test-results/web-design-system/static-audit.json` and
checks the multi-page output manifest, landmarks, unique ids, labelled controls,
required semantic form attributes, live regions, no inline handlers, and no
Bootstrap-shaped canonical classes. It also writes
`canonical-surface-audit.json` with the scanned page set, forbidden class
families, historical legacy files, and migration note. The browser audit uses Chrome/Chromium
through DevTools protocol to verify computed light/dark theme changes, focus and
accessibility-tree names, sampled contrast ratios, reduced-motion behavior,
pricing/payment validation, auth validation, dashboard filters and command
palette keyboard behavior, timeline reveal, collaboration search/chat,
tabs/carousel/disclosure/dialog keyboard behavior, overflow, state screenshots,
and a desktop/mobile/reflow light/dark screenshot matrix. It also writes
`contrast-report.json`, `contrast-report.csv`, and
`reduced-motion-report.json` with sampled text/background pairs and computed
reduced-motion duration checks, plus a `viewport_summary` in
`browser-audit.json`. It also writes `keyboard-traversal.json`,
`touch-targets.json`, and 320px reflow screenshots for every page/theme.
Keyboard traversal is captured with real CDP `Tab` / `Shift+Tab` key events,
including open command-palette and dialog focus-wrap checks.
It also writes `accessibility-tree-report.json`, captured from Chrome DevTools
Protocol `Accessibility.getFullAXTree`, with role/name/value snapshots and
unnamed-control checks for every browser-audit case.
The manifest-driven static audit reads
`docs/web-design-system/web-demo.routes.yml` by default, or a caller-supplied
manifest path, then writes
`test-results/web-design-system/static-manifest-audit.json`. It checks page
existence, page shell semantics, unique ids, labelled controls, ARIA
relationship targets, forbidden classes/terms, inline handlers, required
components, required hooks, and required text without hard-coding the seven demo
pages in the script.
Artifacts are written to `test-results/web-design-system/`. Compatibility
copies are mirrored to `test-results/amber-design-system/` during the alpha
migration.
The axe audit writes `test-results/web-design-system/axe-audit.json` and
fails on serious or critical WCAG-tagged violations across the seven demo pages
in both light and dark themes. It fetches axe-core at validation time and does
not add runtime JavaScript or build tooling to the demo.
The IBM Equal Access audit writes
`test-results/web-design-system/ibm-equal-access-audit.json` and fails on
IBM Accessibility violation/fail results across the same seven pages in both
themes. It fetches the browser bundle at validation time and uses the same
Crystal + Chrome DevTools path, giving the proof a second independent
automated accessibility engine without Node.
The design-system web proof does not require Node, npm, bundling, transpilation,
Stimulus, Playwright, or a JavaScript test runner.
