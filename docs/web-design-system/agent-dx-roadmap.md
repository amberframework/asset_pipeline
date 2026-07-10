# Agent DX Implementation Roadmap

This roadmap turns the gap analysis into implementation phases for the next
collaborative effort.

The naming target is intentionally generic. This work lives in a framework
ecosystem, but the product surface should be Button, Card, FormField, Dialog,
Tabs, Table, Chart, and other known component names. That keeps the design
system suitable for cheap, easy, high-quality interfaces across web, desktop,
mobile, and future native compile targets.

## Cross-Phase Rule - Visual Equivalence While Demo Code Shrinks

Every extraction phase must follow
`docs/web-design-system/refactor-accountability.md`.
Start comparisons from `docs/web-design-system/phase-1-baseline.md`.

The expected outcome is not a new-looking demo. The expected outcome is that
`examples/web_design_system_demo.cr` and page-local JavaScript/CSS shrink while
the regenerated pages remain visually equivalent. A phase is not complete until
it captures before/after screenshots, compares the relevant states, records line
count movement, and explains any accepted drift.

## Phase 1 - Installable Agent Contract

Goal: make the current rules clear enough that a downstream agent can produce a
good page before the API migration is complete.

Deliverables:

- Root `AGENTS.md` for this repo.
- `templates/design-system/AGENTS.md` for consuming apps.
- `templates/design-system/CLAUDE.md` for consuming apps that use Claude Code.
- `docs/web-design-system/agent-playbook.md`.
- `docs/web-design-system/accessibility-contract.md`.
- `docs/web-design-system/generated-view-conventions.md`.
- `docs/web-design-system/refactor-accountability.md`.
- `docs/web-design-system/phase-1-baseline.md`.
- `docs/web-design-system/forbidden-patterns.md`.
- Compiler command matrix clarifying when to use `crystal` vs `crystal-alpha`.
- Update `CLAUDE.md` to remove the web guidance conflict: design-system web
  helpers are vanilla JavaScript, not Stimulus.

Acceptance:

- A fresh agent can find the canonical docs in one minute.
- The instructions explicitly forbid Bootstrap-shaped classes, inline handlers,
  Node build paths, hard chart dependencies, and Stimulus for design-system helpers.
- The validation ladder is documented from fast static checks to full browser
  evidence.

## Phase 2 - Stable Design-System API Namespace

Goal: stop presenting production primitives as examples.

Deliverables:

- Add `src/components/design_system/`.
- Add `src/asset_pipeline/design_system.cr` require shim.
- Move or alias promoted components into `Components::DesignSystem::*`.
- Keep `Components::Examples::*` compatibility wrappers during alpha.
- Add typed props/enums for tone, emphasis, size, state, orientation, and
  behavior variants.
- Keep reusable form id-prefixing for auth/payment field groups covered by
  specs; the first generic-id pass has landed and should be preserved during
  later form extraction.

Acceptance:

- Quickstart examples use `Components::DesignSystem::*`, not `Components::Examples::*`.
- Multiple auth/payment forms can coexist without duplicate ids.
- Invalid variants fail through typed constructors or explicit render errors.

## Phase 2B - Page And Feedback Primitive Extraction

Goal: move repeated generic page and feedback markup out of the demo generator
without changing the demo's visual result.

Deliverables:

- Extract page primitives: `PageShell`, `Section`, and `Panel`.
- Extract feedback/form primitives: `Badge`, `Alert`, `Toast`, `EmptyState`,
  `Skeleton`, `Progress`, `Disclosure`, and `ValidatedForm`.
- Keep current CSS selectors and compatibility hooks where needed, but expose
  the public Crystal API through `Components::DesignSystem::*`.
- Preserve the current page anatomy: skip link, one `h1`, labelled navigation,
  landmarks, status/live regions, theme attributes, focus states, and 320px
  reflow behavior.
- Regenerate all demo pages and record line-count movement for
  `examples/web_design_system_demo.cr`.

Acceptance:

- Before/after screenshots remain visually equivalent across the existing
  desktop, mobile, dark-mode, reduced-motion, and 320px reflow matrix unless
  intentional drift is documented in `phase-notes.md`.
- Static/browser/a11y audits keep passing.
- The generic demo generator shrinks because shell, section, panel, badge,
  alert, toast, empty, skeleton, progress, and disclosure markup is no longer
  hand-rolled per page.
- The phase note names any compatibility aliases retained and any demo-local
  markup that remains after extraction.

## Phase 3 - Behavior And Accessibility Runtime

Goal: make the JavaScript helper a stable, configurable library runtime.

Deliverables:

- Split `public/js/design-system.js` into `assets/js/design-system/*`, leaving
  `public/js/amber-design-system.js` as a compatibility copy until the
  migration is complete.
- Add `assets/js/design-system/index.js` as the mounted entrypoint.
- Add behavior descriptors for dialog, disclosure, form validation, live search,
  command palette, tabs, carousel, table filter, theme switching, and motion.
- Remove demo-specific data/copy from runtime; pass data through component
  config.
- Add `Components::DesignSystem::BehaviorRegistry`.
- Add integration helper to include the runtime in pages.
- Complete neutral `data-ap-*` behavior hook coverage while keeping current
  `data-amber-*` aliases during the alpha migration. Initial runtime support and
  promoted component co-emission landed in Phase 2.
- Add shared accessibility primitives: focus trap, roving focus, live region,
  visually hidden, source-data table, field error.
- Hook behavior re-initialization into the reactive component lifecycle.

Acceptance:

- Components emit their required behavior config.
- Calling the runtime initializer after DOM replacement is safe and idempotent.
- Runtime docs describe every supported hook and required markup relationship.

## Phase 4 - Renderer And Contract Validation

Goal: make renderer-generated UI inherit the same accessibility and state
contracts as component-generated UI.

Deliverables:

- Map `UI::Web::Renderer` output through canonical primitives where practical.
- Add strict-mode render guards for missing accessible names, invalid ARIA
  references, duplicate ids, positive tabindex, and unlabelled controls.
- Expand the initial `spec/support/accessibility_matchers.cr` helper set into a
  packageable downstream test-support API.
- Add component contract metadata or a parseable manifest.
- Generate component audit fixtures from the manifest.

Acceptance:

- Renderer specs assert accessible names, roles, focus states, and token-backed
  classes.
- Component specs can check accessibility without launching a browser.
- The same contract metadata can drive docs and validation.

## Phase 5 - Reusable CLI And Fast Feedback

Goal: turn the demo scripts into reusable tools for consuming apps and CI.

Deliverables:

- Extract shared CDP harness from screenshot, axe, and IBM scripts.
- Add `design-system.routes.yml.example` and continue expanding the existing
  `docs/web-design-system/web-demo.routes.yml` fixture.
- Add `asset_pipeline validate --fast`.
- Add `asset_pipeline validate --static`, building on
  `scripts/validate_design_system_manifest.cr`.
- Add `asset_pipeline validate --browser`.
- Add `asset_pipeline validate --a11y`.
- Add `asset_pipeline validate --full`.
- Add `asset_pipeline capture`.
- Add output isolation: `--out`, `--baseline`, `--update`, per-run folders.
- Vendor or cache pinned axe and IBM engine bundles with hashes, plus an
  `--update-engine` path.
- Add a CI workflow for compile, focused specs, static audit, and a small
  browser smoke pass.

Acceptance:

- A consuming app validates its own routes from a manifest without editing
  Asset Pipeline scripts.
- Fast validation completes without the full screenshot matrix.
- Full validation reproduces accessibility, contrast, keyboard, reduced-motion,
  AX tree, axe, IBM, and screenshot evidence.

## First Week Recommendation

Do Phase 1 first. It is the smallest change that prevents the next agent from
copying the wrong patterns. It also forces the team to write down the contract
that Phases 2 through 5 will enforce in code.
