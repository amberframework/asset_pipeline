# Refactor Accountability

The current demo is the visual baseline. Refactors that move behavior, markup,
or styling from the demo into reusable components must keep the page looking and
behaving the same unless the change intentionally improves the design and the
reason is documented.

The current Phase 1 baseline is recorded in
`docs/web-design-system/phase-1-baseline.md`.

## Principle

The demo generator should shrink as the library improves.

The current shrink target is `examples/web_design_system_demo.cr`.
`examples/amber_design_system_demo.cr` is only a compatibility wrapper for the
old alpha command name. If either file grows during a component extraction, the
phase note must explain why. The expected shape is:

- Less page-local CSS.
- Less repeated string-built markup.
- Fewer page-local behavior hooks.
- More reusable components, contracts, specs, and validation manifests.
- Equivalent generated pages and screenshots.

New public component names should be generic design-system concepts, not
Amber-branded product names. Existing `amber-*`, `data-amber-*`,
`AmberDesignSystem`, and `amber-design-system-*` names are compatibility aliases
for the alpha migration unless a phase note explicitly promotes one as public
API.

For delegated extraction work, the expected outcome is:

- A small, owned component or behavior family moves into `Components::DesignSystem`.
- The demo uses that component or behavior with less local markup or JavaScript.
- Generated HTML is identical unless the phase is intentionally improving the
  design or accessibility.
- The screenshot matrix is identical or has documented, reviewed drift.
- Specs and docs describe the reusable API so another agent can use it without
  reverse engineering the demo.

## Required Loop For Each Extraction

1. Capture a complete baseline:

   ```bash
   crystal run examples/web_design_system_demo.cr
   rm -rf test-results/web-design-system-before output/web-design-system-before
   mkdir -p output/web-design-system-before
   cp output/web-design-system-*.html output/web-design-system-before/
   crystal run scripts/validate_web_demo.cr
   crystal run scripts/capture_web_demo_screenshots.cr
   crystal run scripts/axe_web_demo_audit.cr
   crystal run scripts/ibm_web_demo_audit.cr
   cp -R test-results/web-design-system test-results/web-design-system-before
   wc -l examples/web_design_system_demo.cr examples/amber_design_system_demo.cr public/js/design-system.js public/js/amber-design-system.js
   ```

   Track both `examples/web_design_system_demo.cr` and
   `examples/amber_design_system_demo.cr`; the first file is where extraction
   should shrink repeated page-local markup, and the second should remain a
   tiny compatibility wrapper.

2. Make the smallest extraction:

   - Move one component family or behavior family.
   - Keep public output equivalent.
   - Add or update focused specs.
   - Record any compatibility alias.

3. Regenerate and validate:

   ```bash
   crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr
   crystal run examples/web_design_system_demo.cr
   crystal run scripts/validate_web_demo.cr
   crystal run scripts/capture_web_demo_screenshots.cr
   crystal run scripts/axe_web_demo_audit.cr
   crystal run scripts/ibm_web_demo_audit.cr
   git diff --check
   ```

4. Compare evidence:

   - Compare screenshot counts and viewport summary.
   - Compare key PNGs before and after.
   - Compare generated HTML structure for the extracted surface.
   - Compare line counts for the demo generator and runtime helper.
   - Check that accessibility reports still pass.

   Use these commands as the default comparison. Exact HTML equality is
   expected when the extraction only moves markup without changing output.

   ```bash
   diff -ru output/web-design-system-before output \
     --exclude='amber-design-system-*' \
     --exclude='brand-kit.html'
   diff -ru test-results/web-design-system-before test-results/web-design-system \
     --exclude='*.png'
   find test-results/web-design-system -maxdepth 1 -name '*.png' | wc -l
   find test-results/web-design-system-before -maxdepth 1 -name '*.png' | wc -l
   ```

   PNG byte equality is useful but not required; browser screenshots can vary
   slightly by Chrome version and font rasterization. When PNGs differ, inspect
   the affected before/after screenshots and document whether the drift is a
   deliberate design improvement, an acceptable rasterization difference, or a
   regression to fix before continuing.

5. Write a phase note:

   - What moved out of the demo.
   - Which files shrank or grew.
   - Which screenshots were compared.
   - Whether the visual output is intentionally identical.
   - Any accepted visual drift and why.
   - What remains demo-local.

   Use this template:

   ```md
   ## Phase N - Short Title

   Changed files:

   - `path`

   Commands run:

   - `command`

   Artifacts:

   - `output/web-design-system-*.html`
   - `test-results/web-design-system/`

   What passes:

   - ...

   What this phase adds:

   - ...

   Visual/accountability result:

   - Demo line count before/after:
   - Marker count before/after:
   - HTML drift:
   - Screenshot drift:

   Weak or deferred:

   - ...
   ```

## Visual Drift Policy

Treat visual drift as a failure by default.

Allowed drift:

- A documented design improvement.
- A bug fix that makes the output more accessible or more consistent.
- A required change from replacing duplicate demo markup with a canonical
  component, if the difference is captured and accepted.

Not allowed:

- Layout shift from missing component CSS.
- Lost dark-mode styling.
- Lost hover/focus/active states.
- Lost reduced-motion behavior.
- Text overflow, clipped content, or horizontal scroll regression.
- Different spacing or color caused only by incomplete extraction.

## Suggested Delegation Units

Each unit should be small enough for one agent to own without touching the
others.

| Unit | Owns | Must Prove |
| --- | --- | --- |
| Button/Card/Badge/Alert | Static primitives and variants | Same screenshots, no forbidden classes |
| FormField/ValidatedForm | Labels, errors, status, validation rules | Same form screenshots, same invalid/valid audit behavior |
| Payment/Auth Fieldsets | Id-prefixing, autocomplete, password/payment rules | No duplicate IDs, payment/auth browser audit passes |
| Dialog/Command/Disclosure | Overlay/focus primitives | Focus trap, escape, return focus, keyboard reports pass |
| Tabs/Carousel | Roving focus and status | Keyboard behavior and reduced-motion pattern captures pass |
| Table/Filter/Heatmap/Chart | Data semantics and source fallbacks | Table states, chart/heatmap fallbacks, contrast pass |
| PageShell/Section/Panel | Layout primitives | Demo generator shrinks and page screenshots remain equivalent |
| Runtime Split | JS module extraction | Helper behavior remains idempotent and all browser audits pass |
| Validation CLI | Manifest-driven audit | Existing demo can be represented as a manifest with same pass/fail result |

## Shrink Metrics

Record these in phase notes:

```bash
wc -l examples/web_design_system_demo.cr
wc -l examples/amber_design_system_demo.cr
wc -l public/js/design-system.js
wc -l public/js/amber-design-system.js
rg -n "class=\\\"am-|data-(ap|amber)-|<section|<form|<dialog" examples/web_design_system_demo.cr | wc -l
```

The exact numbers are not the goal. The trend is the signal: repeated demo code
should move into reusable components while the rendered output stays stable.
