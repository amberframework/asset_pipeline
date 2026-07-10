# Forbidden Patterns

This file is the quick negative/positive contract for generated
design-system web output. It is intentionally concrete so agents can copy the
right shape instead of rediscovering the rules.

The current Phase 1 web proof uses `am-*` classes and `data-amber-*` behavior
hooks as compatibility output. Future public APIs should move toward neutral
Asset Pipeline names such as `Components::DesignSystem::*`, `data-ap-*`, and
`asset_pipeline validate`.

## Bootstrap-Shaped Classes

Forbidden:

```html
<button class="btn btn-primary">Save changes</button>
<div class="card">
  <div class="card-body">...</div>
</div>
<input class="form-control" id="email">
<ul class="list-group">...</ul>
```

Correct:

```html
<button class="am-button am-button--primary">Save changes</button>
<section class="am-card" aria-labelledby="profile-heading">
  <h2 id="profile-heading">Profile</h2>
  ...
</section>
<label class="am-field">
  <span class="am-field__label">Email</span>
  <input class="am-input" id="email" name="email" type="email" autocomplete="email">
</label>
```

Use canonical design-system components when they exist. If a primitive is
missing, use semantic HTML plus current token-backed compatibility selectors
and record the gap for promotion.

## Inline Event Handlers

Forbidden:

```html
<button onclick="openDialog()">Open dialog</button>
<input oninput="validateEmail(this)">
```

Correct:

```html
<button
  type="button"
  data-ap-dialog-open="settings-dialog"
  data-amber-dialog-open="settings-dialog"
>
  Open dialog
</button>
<form data-ap-validate data-amber-validate>
  <label for="email">Email</label>
  <input
    id="email"
    name="email"
    type="email"
    autocomplete="email"
    required
  >
</form>
```

Behavior belongs in the vanilla design-system runtime, mounted through stable
data hooks. Do not embed JavaScript inside generated markup.

## Stimulus For Design-System Helpers

Forbidden:

```html
<div data-controller="dialog" data-dialog-open-value="settings">
  ...
</div>
```

Correct:

```html
<dialog
  id="settings-dialog"
  class="am-dialog"
  aria-labelledby="settings-title"
>
  <h2 id="settings-title">Settings</h2>
  ...
  <button type="button" data-ap-dialog-close data-amber-dialog-close>
    Close
  </button>
</dialog>
```

Legacy `AssetPipeline::FrontLoader` can still document import maps and Stimulus
integration. New design-system helpers are vanilla JavaScript only.

## Node, Bundlers, Transpilers, And JS Test Runners

Forbidden:

```bash
npm install
npm run build
npx vite build
npx webpack
npx playwright test
```

Correct:

```bash
crystal run examples/web_design_system_demo.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

The canonical web proof is Crystal, static HTML/CSS, vanilla JavaScript, and
Chrome DevTools Protocol through Crystal scripts. Do not add a Node build path
to make generated design-system pages work.

## Hard Chart Dependencies

Forbidden:

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<canvas id="revenue-chart"></canvas>
```

Correct:

```html
<figure class="am-chart" data-chart-adapter="first-party-svg">
  <figcaption id="revenue-caption">Revenue by month</figcaption>
  <svg aria-labelledby="revenue-caption" role="img">...</svg>
  <table class="am-source-table">
    <caption>Revenue source data</caption>
    ...
  </table>
</figure>
```

External charting libraries may be isolated behind an adapter, but they must not
become a default runtime dependency. The source-data table remains the
accessible data path.

## Unlabelled Controls

Forbidden:

```html
<input id="search">
<button type="button"><span class="am-icon-search"></span></button>
<select id="plan"></select>
```

Correct:

```html
<label for="search">Search customers</label>
<input id="search" name="search" type="search" aria-controls="customer-table">

<button type="button" aria-label="Search">
  <span class="am-icon-search" aria-hidden="true"></span>
</button>

<label class="am-field">
  <span class="am-field__label">Plan</span>
  <select id="plan" name="plan">...</select>
</label>
```

Every `input`, `select`, `textarea`, icon-only button, dialog, navigation
landmark, and dynamic region needs an accessible name.

## Positive Tabindex

Forbidden:

```html
<button tabindex="3">Save</button>
<a href="/settings" tabindex="10">Settings</a>
```

Correct:

```html
<button type="button">Save</button>
<a href="/settings">Settings</a>
<main id="main" tabindex="-1">...</main>
```

Use DOM order for normal focus movement. `tabindex="-1"` is allowed for
programmatic focus targets such as skip-link destinations, dialogs, and managed
roving-focus containers.

## Missing Reduced Motion

Forbidden:

```css
.am-timeline-item {
  animation: reveal 500ms ease forwards;
}
```

Correct:

```css
@media (prefers-reduced-motion: no-preference) {
  .am-timeline-item {
    animation: reveal 500ms ease forwards;
  }
}

@media (prefers-reduced-motion: reduce) {
  .am-timeline-item {
    animation: none;
    transition: none;
    opacity: 1;
    transform: none;
  }
}
```

Animations, transitions, reveal effects, carousel movement, dialog overlays,
chart sequencing, table-row updates, and sticky-hover effects must have an
explicit reduced-motion path.

## Branded Future API Naming

Forbidden for new future-facing APIs:

```crystal
Components::AmberDesignSystem::Button.new("Save")
Components::Amber::Dialog.new(title: "Settings")
```

```html
<button data-amber-v2-dialog-open="settings-dialog">Open</button>
```

```bash
amber_design_system validate --full
```

Correct target naming:

```crystal
Components::DesignSystem::Button.new("Save")
Components::DesignSystem::Dialog.new(title: "Settings")
```

```html
<button data-ap-dialog-open="settings-dialog" data-amber-dialog-open="settings-dialog">
  Open
</button>
```

```bash
asset_pipeline validate --full
```

The existing `am-*` CSS classes and `data-amber-*` hooks are current alpha
compatibility contracts. Do not create additional Amber-branded names for the
future stable API; add neutral aliases and preserve old hooks until migration is
proven by screenshot and behavior evidence.
