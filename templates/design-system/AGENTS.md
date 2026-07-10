# Design-System Web Agent Instructions

Use these instructions when generating web views with Asset Pipeline's design system.

## Scope

- Web only.
- No build step.
- Vanilla JavaScript only for design-system helpers.
- Modern browsers.
- Semantic HTML first.
- WCAG AA-oriented defaults.

## Required Reading

Start in the installed shard:

- `lib/asset_pipeline/docs/web-design-system/README.md`
- `lib/asset_pipeline/docs/web-design-system/visual-language.md`
- `lib/asset_pipeline/docs/web-design-system/accessibility-contract.md`
- `lib/asset_pipeline/docs/web-design-system/component-contracts.md`
- `lib/asset_pipeline/docs/web-design-system/component-api.md`
- `lib/asset_pipeline/docs/web-design-system/component-catalog.md`
- `lib/asset_pipeline/docs/web-design-system/agent-playbook.md`
- `lib/asset_pipeline/docs/web-design-system/generated-view-conventions.md`
- `lib/asset_pipeline/docs/web-design-system/forbidden-patterns.md`
- `lib/asset_pipeline/docs/web-design-system/compiler-command-matrix.md`
- `lib/asset_pipeline/docs/web-design-system/refactor-accountability.md`

## Build Rules

- Prefer `Components::DesignSystem::*` for promoted Crystal components.
- Use generic component names in public code and docs. Do not name new
  components, pages, or templates after the host framework.
- Use documented local wrappers only when a needed primitive is still missing,
  and record the gap.
- Use generic component APIs and neutral `--ap-*` semantic tokens. Current
  `am-*` classes are compatibility selectors for promoted components; do not
  mint new `am-*` classes for app-local wrappers. Co-emit neutral `data-ap-*`
  behavior hooks with current `data-amber-*` compatibility hooks.
- Use native controls: `<button>`, `<a>`, `<label>`, `<input>`, `<select>`,
  `<textarea>`, `<table>`, `<dialog>`, landmarks, and headings.
- Include labels, descriptions, status text, and keyboard behavior.
- Treat HTML5 validation attributes, ARIA relationships, focus behavior, and
  live regions as component responsibilities wherever a design-system component
  exists.
- Respect `prefers-reduced-motion`.
- Keep light and dark modes explicit and testable.

## Extraction Rules

When moving repeated page or feedback markup into reusable primitives:

- Preserve visual equivalence first; do not redesign while extracting.
- Prefer generic names such as `PageShell`, `Section`, `Panel`, `Badge`,
  `Alert`, `Toast`, `EmptyState`, `Skeleton`, `Progress`, and `Disclosure`.
- Keep the generated page smaller by replacing repeated shell, section, panel,
  status, loading, and disclosure markup with documented components.
- Record before/after evidence, line-count movement, compatibility aliases, and
  any intentional visual drift.

## Forbidden Patterns

Do not use:

- `.btn`, `.btn-primary`, `.card-body`, `.form-control`, `.list-group`
- Inline handlers such as `onclick`
- Stimulus for design-system helpers
- Node/npm/bundler/transpiler assumptions
- Hard default chart dependencies
- Unlabelled controls
- Positive `tabindex`
- Unverified raw HTML for interactive components

## Page Checklist

Each generated page needs:

- `html[lang]`
- `<title>`
- viewport meta
- skip link
- one `h1`
- `main#main`
- labelled navigation if navigation exists
- unique ids
- labelled controls
- visible focus states
- status/live regions for dynamic updates
- no horizontal overflow at 390px or 320px

## Validation Ladder

Run fast checks first:

```bash
crystal spec spec/support/accessibility_matchers_spec.cr
crystal spec spec/components/examples/example_components_spec.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/validate_design_system_manifest.cr path/to/design-system.routes.yml
git diff --check
```

Run browser evidence after meaningful UI changes:

```bash
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

For refactors, capture before evidence and compare generated HTML/screenshots
before accepting the change. The default expectation is that extraction shrinks
view code while the rendered page remains visually equivalent.

Future installed-project target:

```bash
asset_pipeline validate --fast
asset_pipeline validate --full
```

## If A Component Is Missing

Build the narrowest semantic wrapper, then document the gap:

- `data-component="name"`
- Stable behavior hooks. Emit neutral `data-ap-*` hooks and current
  `data-amber-*` aliases during migration.
- Native role/element where possible
- Accessible name
- Described errors/statuses
- Keyboard behavior
- Reduced-motion behavior
- Light/dark token styling
- Spec or validation coverage
