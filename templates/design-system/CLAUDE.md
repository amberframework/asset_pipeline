# Design-System Web Instructions

Use these instructions when generating web views with Asset Pipeline's design
system. They mirror `AGENTS.md` for Claude-oriented workspaces.

## Scope

- Web only for the current milestone.
- No build step, Node, npm, bundler, or transpiler for canonical views.
- Vanilla JavaScript only for design-system helpers.
- Semantic HTML and token-backed CSS first.
- WCAG AA-oriented defaults.
- Modern browsers.

## Public Naming

Use generic public component names:

- `Components::DesignSystem::Button`
- `Components::DesignSystem::Card`
- `Components::DesignSystem::FormField`
- `Components::DesignSystem::Fieldset`
- `Components::DesignSystem::Dialog`
- `Components::DesignSystem::Tabs`
- `Components::DesignSystem::DataTable`
- `Components::DesignSystem::Chart`
- `Components::DesignSystem::Timeline`
- `Components::DesignSystem::Section`
- `Components::DesignSystem::Panel`

Do not introduce new public APIs, templates, or demo concepts named after the
host framework. Use neutral `--ap-*` CSS variables and `data-ap-*` hooks in new
work. Current `--amber-*`, `am-*`, `data-amber-*`, `AmberDesignSystem`, and
`amber-design-system-*` names are compatibility details during alpha migration.

## Required Docs

Read these before generating a nontrivial view:

- `lib/asset_pipeline/docs/web-design-system/README.md`
- `lib/asset_pipeline/docs/web-design-system/visual-language.md`
- `lib/asset_pipeline/docs/web-design-system/accessibility-contract.md`
- `lib/asset_pipeline/docs/web-design-system/component-api.md`
- `lib/asset_pipeline/docs/web-design-system/component-catalog.md`
- `lib/asset_pipeline/docs/web-design-system/generated-view-conventions.md`
- `lib/asset_pipeline/docs/web-design-system/forbidden-patterns.md`

## Accessibility Defaults

Accessibility is part of the component API, not caller cleanup.

- Use native controls and landmarks.
- Every control needs a label or accessible name.
- Prefer HTML5 validation attributes before JavaScript.
- Errors need visible text, stable ids, `aria-invalid`, and
  `aria-describedby`.
- Dynamic status needs `role="status"` or `aria-live="polite"`.
- Dialogs, tabs, carousels, disclosure, search, and command surfaces need
  documented keyboard behavior.
- Motion must respect `prefers-reduced-motion`.
- Charts and heatmaps need text or table equivalents.

## Forbidden Patterns

Do not use:

- `.btn`, `.btn-primary`, `.card-body`, `.form-control`, `.list-group`
- Inline event handlers such as `onclick`
- Stimulus for design-system helpers
- Node/npm/bundler/transpiler assumptions
- Hard default chart dependencies
- Unlabelled controls
- Positive `tabindex`
- Raw HTML for interactive components unless the accessibility obligations are
  documented and tested

## Validation

Run fast checks first:

```bash
crystal spec spec/support/accessibility_matchers_spec.cr
crystal spec spec/components/examples/example_components_spec.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/validate_design_system_manifest.cr path/to/design-system.routes.yml
git diff --check
```

Run browser evidence after meaningful UI, behavior, or accessibility changes:

```bash
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

For refactors, capture before evidence and compare generated HTML/screenshots.
The default expectation is that view code shrinks while the rendered interface
stays visually equivalent unless intentional drift is documented.
