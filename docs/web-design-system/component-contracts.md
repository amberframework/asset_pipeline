# Component Contracts

These contracts are the agent-readable source of truth for the promoted design-system
web components. They are intentionally small and portable: a component should
render the same semantic surface in a second app without depending on the
Frontloader Studio demo copy.

## Shared Contract

- Component wrappers emit `data-component` with the canonical component name.
- Public styling is token-backed and variant-driven. Current `am-*` selectors
  are compatibility implementation details during the alpha migration.
- Public variants are semantic inputs such as tone, emphasis, size, state,
  label, title, id, and data/ARIA hooks.
- Components do not emit Bootstrap-shaped canonical classes.
- Native HTML semantics come first; JavaScript only enhances behavior.
- Every field, control group, dialog, chart, table, carousel, and command
  surface keeps an accessible name or fallback data path.

## Button

Reusable inputs:

- `label`
- `tone`: `brand`, `neutral`, `success`, `warning`, `danger`, `info`
- `emphasis`: `solid`, `soft`, `outline`, `ghost`
- `size`: `sm`, `md`, `lg`
- `state`, `disabled`, `loading`, `selected`
- safe `aria-*` and `data-*` passthrough attributes

Evidence:

- Specs assert variant classes, disabled/loading/selected semantics, icon
  hiding, and safe ARIA/data passthrough.
- Web renderer specs assert UI buttons map into token-backed design-system classes.

## Card

Reusable inputs:

- `eyebrow`, `title`, and caller-supplied body content
- `tone`: neutral, brand, success, warning, danger, or info
- `selected`, `raised`, and `interactive` state flags

Accessibility contract:

- Uses `data-component="card"` and `am-card*` classes.
- Does not expose `.card`, `.card-body`, or `.card-title` as canonical API.
- Keeps heading structure controlled by the caller context rather than forcing
  a page-level heading.

Evidence:

- Specs assert token-backed classes and absence of Bootstrap-shaped card output.
- The canonical-surface audit fails if generated demo output emits `.card-body`.

## Fieldset

Reusable inputs:

- `legend` or `label`
- optional `described_by`
- optional `id`, `class`, `disabled`, `legend_class`, and `hidden_legend`

Accessibility contract:

- Emits a native `<fieldset>` boundary for related controls.
- Emits a `<legend>` for the group label; it is visually hidden by default with
  `am-visually-hidden`.
- Maps `described_by` to `aria-describedby` so shared form status or help text
  can describe the group.
- Does not place submit buttons, reset links, or unrelated actions inside the
  group.

Evidence:

- Primitive specs assert hidden legend output, shared description wiring, and
  child ordering.
- Auth and payment specs assert their fieldset counts and legends.

## FormField

Reusable inputs:

- `label`, `id`, `name`, `type`
- native validation attributes: `required`, `autocomplete`, `min`, `max`,
  `minlength`, `maxlength`, `pattern`, `inputmode`, `step`
- `hint`, `hint_html`, `error`
- data and ARIA passthrough hashes
- select `options`

Accessibility contract:

- Emits a wrapping `<label for="...">`.
- Emits browser-native `input`, `select`, or `textarea`.
- Emits `aria-invalid` and `aria-describedby` when an error is supplied.
- Keeps caller-supplied data hooks so vanilla helpers can attach without
  bypassing the component layer.

Evidence:

- Specs assert email validation attributes, search/live-region hint markup,
  select options, and non-demo-specific reuse with caller-supplied data/ARIA.

## AuthForm

Reusable inputs:

- `mode`: sign in or sign up
- `title`, `copy`, `submit_label`, and optional helper text

Accessibility contract:

- Email fields use `type="email"`, `autocomplete="email"`, and `required`.
- Password fields use `autocomplete="current-password"` for sign in and
  `new-password` for sign up.
- Sign-up and sign-in controls are grouped with the `Fieldset` primitive so
  assistive technology gets a form-section label without adding visible chrome.
- Sign-up mode includes password-confirmation hooks and password requirement
  feedback wired to visible status text.
- The form never depends on inline handlers.

Evidence:

- Static audit asserts auth form promotion, email semantics, password hooks, and
  no inline handlers.
- Browser audit asserts invalid and valid auth states through the shared
  vanilla form helper.

## ThemeSwitcher

Reusable modes:

- `mode="toggle"` emits the compact global theme toggle plus status text.
- `mode="segmented"` emits explicit light and dark controls.

Accessibility contract:

- Toggle uses `aria-pressed` and `data-ap-theme-toggle`, with
  `data-amber-theme-toggle` retained as a compatibility alias.
- Segmented controls use `role="group"` and per-option `aria-pressed`.
- The vanilla helper updates `<html data-ap-theme>`, the current
  `<html data-amber-theme>` compatibility attribute, button pressed states,
  visible status text, browser `colorScheme`, and local storage.

Evidence:

- Specs assert both modes and caller-supplied copy.
- Browser audit asserts computed light/dark token and color-scheme changes.

## PricingCard

Reusable inputs:

- `name`, `badge`, `badge_tone`, `price`, `period`, `copy`
- `featured`
- `action`, `action_tone`, `action_emphasis`

Contract:

- Emits `data-component="pricing-card"`.
- Composes `Button` for its action.
- Featured state is a data attribute, not demo-only CSS.

Evidence:

- Specs assert featured state, custom price/period/copy/action variants, and
  absence of hard-coded Studio action copy in reusable cases.

## DataTable

Reusable inputs:

- `caption`
- column definitions with labels and optional alignment
- row data with optional `state`, `selected`, `disabled`, and action content

Accessibility contract:

- Emits real `<table>`, `<caption>`, `<thead>`, `<tbody>`, `<th scope="col">`,
  and row state attributes.
- Row states include a strong leading indicator, subtle background, richer
  hover state, smooth transition, and semantic state text.
- Dangerous or invalid rows expose `aria-invalid` where appropriate.
- Filtering uses external controls and does not remove the table fallback.

Evidence:

- Static audit asserts dashboard row state output and `aria-invalid`.
- Browser audit asserts dashboard filter behavior, keyboard traversal, contrast,
  touch targets, and reduced-motion row behavior.

## PaymentForm

Native validation:

- Receipt email uses `type="email"` and `autocomplete="email"`.
- Card name uses `autocomplete="cc-name"`.
- Card number uses `autocomplete="cc-number"`, `inputmode="numeric"`, a 16 digit
  grouping pattern, and an explicit pattern message.
- Expiry uses `autocomplete="cc-exp"`, `inputmode="numeric"`, `MM/YY` pattern,
  and a future-expiry helper.
- CVC uses `autocomplete="cc-csc"`, `inputmode="numeric"`, a 3 or 4 digit
  pattern, and an explicit pattern message.
- Payment controls compose the `Fieldset` primitive for `Receipt contact`,
  `Card details`, and `Promotion code`.

Vanilla helper validation:

- `luhnValid` rejects invalid card numbers after formatting.
- `expiryValid` rejects invalid or expired dates.
- Submit-time validation marks invalid fields with `aria-invalid`, creates a
  visible `.am-field__error`, and adds the error id to `aria-describedby`.
- Promo feedback updates a polite status hint without submitting.

Evidence:

- Specs assert native attributes and helper validation hooks.
- Browser audit asserts empty invalid submission, Luhn failure, expired-card
  failure, valid payment success, promo accepted status, and visible described
  errors.

## SimpleChart

Adapters:

- `adapter="first-party-svg"` is the default and emits token-backed SVG bars.
- `adapter="external"` emits an isolated `data-chart-external-root` with
  serialized labels/values and no hard dependency.
- Unknown adapters raise `ArgumentError`.

Accessibility contract:

- Both adapters keep figure/caption semantics.
- Both adapters keep the visually-hidden source-data table.
- SVG is `aria-hidden` so the table is the source of accessible values.

Evidence:

- Specs assert first-party SVG, external adapter isolation, hidden table
  fallback, no `Chart.js` string, and unknown adapter rejection.

## ScheduleHeatmap

Reusable inputs:

- `label`
- hour or slot values
- intensity scale from empty to high activity

Accessibility contract:

- Visual cells are decorative summaries.
- A hidden table preserves hour labels and values.
- Color intensity is backed by tokens and never the only data path.

Evidence:

- Static audit asserts the dashboard heatmap has a table fallback with hour
  column headings.
- Browser contrast and reflow captures cover the dashboard page in both themes.

## Timeline

Reusable inputs:

- ordered milestones with date, title, copy, and optional side
- optional SVG/sequence decoration data

Accessibility contract:

- Uses ordered semantic milestone content.
- Scroll reveal only enhances visibility; reduced motion makes items visible
  immediately.
- Alternating desktop layout collapses to a readable single column on mobile.

Evidence:

- Static audit asserts Crystal milestone content.
- Browser audit asserts reveal behavior, reduced-motion timeline behavior, and
  desktop/mobile screenshots.

## CommandPalette

Reusable inputs:

- trigger label
- command groups and command items
- empty-state copy

Accessibility contract:

- Trigger is a real button.
- Panel exposes dialog/listbox-style semantics through labelled controls.
- Search uses an accessible label and live result feedback.
- Keyboard behavior supports open, search, item movement, escape, and focus
  return without inline handlers.

Evidence:

- Static audit asserts command palette promotion and helper presence.
- Browser audit asserts command search, keyboard state, focus behavior, and
  reduced-motion command-open capture.

## Tabs

Reusable inputs:

- tab id, label, selected state, and panel content

Accessibility contract:

- Emits `role="tablist"`, `role="tab"`, and `role="tabpanel"` relationships.
- Maintains `aria-selected`, roving focus, hidden panels, and keyboard
  selection.
- Keeps panels in the DOM for accessible reading and state restoration.

Evidence:

- Static audit asserts tabs promotion and helper presence.
- Browser audit asserts tab keyboard behavior, state screenshot, and
  reduced-motion pattern cases.

## Carousel

Reusable inputs:

- slides with label, title, copy, and optional metadata
- previous/next control labels

Accessibility contract:

- Uses real buttons for navigation.
- Exposes current slide status through a polite status node.
- Supports arrow-key navigation.
- Does not auto-rotate in the canonical proof.

Evidence:

- Static audit asserts carousel promotion and helper presence.
- Browser audit asserts next/arrow-key behavior, status text, and reduced-motion
  pattern cases.

## Dialog

Reusable inputs:

- id, title, body, primary action, secondary action

Accessibility contract:

- Emits a native `<dialog>`.
- Uses `aria-labelledby` and visible title text.
- Opens and closes through vanilla helpers.
- Supports escape/close behavior and focus containment checks.

Evidence:

- Static audit asserts accessible dialog naming.
- Browser audit asserts dialog open state, keyboard behavior, and reduced-motion
  dialog-open capture.

## Legacy Chat Example

Reusable inputs:

- message list
- composer label and placeholder
- optional status or assistant metadata

Accessibility contract:

- Message history uses `role="log"` and `aria-live="polite"`.
- Composer is a real form with labelled input.
- Sent-message feedback updates without replacing the log semantics.

Current status:

- The accessible collaboration page uses demo-local vanilla markup and
  `data-ap-chat-*` hooks today.
- The older reactive `ChatComponent` remains an example implementation and is
  not promoted through `Components::DesignSystem` until it has a vanilla
  no-build wrapper.

## Legacy LiveSearch Example

Reusable inputs:

- labelled search field
- result items
- empty-state copy

Accessibility contract:

- Search uses a native input with an accessible label.
- Result count or empty state is announced with polite live feedback.
- Filtering never injects duplicate stale results.

Current status:

- The accessible collaboration page uses demo-local vanilla markup and
  deterministic `data-ap-live-search` hooks today.
- The older reactive `LiveSearchComponent` remains an example implementation and
  is not promoted through `Components::DesignSystem` until it has a vanilla
  no-build wrapper.

## Legacy Form Example

Reusable inputs:

- action/method
- field groups
- submit label
- optional status content

Accessibility contract:

- Composes native controls and labels.
- Uses browser validation before JavaScript enhancement.
- Keeps submit/status behavior compatible with no-build vanilla helpers.

Current status:

- Static audit checks labelled controls, native email attributes, and no inline
  handlers across generated pages.
- The older stateful `FormComponent` remains an example implementation. New
  generated views should use `ValidatedForm`, `Fieldset`, and `FormField`.

## Legacy Counter Example

Reusable inputs:

- initial value
- min/max/step
- decrement, increment, and reset labels

Accessibility contract:

- Uses real buttons and a status value.
- Disabled state is reflected semantically when bounds are reached.
- The component remains a small example, not the primary design direction.

Current status:

- Component specs keep the legacy small example compatible while the design
  proof promotes the broader design-system component surface.
- The older stateful `CounterComponent` is intentionally not promoted through
  `Components::DesignSystem`.

## Verification Commands

```bash
crystal spec spec/components/examples/example_components_spec.cr
crystal run examples/web_design_system_demo.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```
