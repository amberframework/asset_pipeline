# Asset Pipeline Agent Instructions

These root instructions apply to the whole repository unless a nested
`AGENTS.md` gives narrower guidance. Do not revert or clean up unrelated
worktree changes made by other agents or users.

## Start Here

For web design-system work, use the generic design-system direction documented
under the current `docs/web-design-system/` path:

- `docs/web-design-system/README.md`
- `docs/web-design-system/visual-language.md`
- `docs/web-design-system/accessibility-contract.md`
- `docs/web-design-system/component-contracts.md`
- `docs/web-design-system/component-api.md`
- `docs/web-design-system/component-catalog.md`
- `docs/web-design-system/agent-playbook.md`
- `docs/web-design-system/generated-view-conventions.md`
- `docs/web-design-system/refactor-accountability.md`
- `docs/web-design-system/phase-1-baseline.md`
- `docs/web-design-system/forbidden-patterns.md`
- `docs/web-design-system/compiler-command-matrix.md`

Some current implementation identifiers still carry Amber-era names, but the
agent-facing API and documentation should stay generic Asset Pipeline
design-system surface area.

## Web Milestone Scope

Milestone 1 is vanilla web only:

- no build step
- no Node, npm, bundlers, or transpilers for canonical demos
- vanilla JavaScript helpers only
- semantic HTML and token-backed CSS first
- accessibility is part of each component contract, not caller cleanup
- light, dark, reduced-motion, keyboard, and accessibility states must remain
  testable

Do not use Stimulus or Bootstrap-shaped canonical classes for new design-system
work.

## Naming Direction

Current `am-*` classes remain alpha compatibility styling. Runtime behavior
hooks should co-emit neutral `data-ap-*` names with current `data-amber-*`
aliases while the migration is in progress.

Prefer generic component names and contracts: Button, Card, FormField, Dialog,
Tabs, DataTable, Chart, Timeline, and similar known interface primitives. Use
`Components::DesignSystem::*` for promoted Crystal components and record missing
primitives as gaps.

Do not present new public APIs, templates, docs, or demo concepts as
Amber-branded. The design system lives in the Amber ecosystem, but the component
language should stay generic enough to map to web, desktop, mobile, and future
native renderers.

## Fast Validation Ladder

Run the fastest useful checks first:

```bash
crystal spec spec/components/examples/example_components_spec.cr
crystal run scripts/validate_web_demo.cr
git diff --check
```

After meaningful UI, behavior, token, or component extraction changes, add
browser and accessibility evidence:

```bash
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

For broader shared changes, include the focused component/css specs named in
`docs/web-design-system/README.md`.

## Refactor Accountability

When extracting demo markup, styling, or behavior into reusable components,
follow `docs/web-design-system/refactor-accountability.md`.

Required proof:

- capture a before baseline for generated pages and screenshots
- keep generated output visually equivalent unless intentional drift is
  documented
- compare before/after screenshots and relevant audit artifacts
- show that `examples/web_design_system_demo.cr` shrinks, or explain why it
  grew
- record compatibility aliases and remaining demo-local code in the phase note

Treat unexplained visual drift, lost dark-mode/reduced-motion behavior, missing
focus states, text overflow, or horizontal scroll regressions as failures.
