# Component API

This is the current agent-facing component surface for generated web views.
Use generic component names and `Components::DesignSystem::*` in new code.
Neutral `--ap-*` variables and `data-ap-*` hooks are the public token/behavior
direction. `Components::Examples::*Component`, `--amber-*`, `am-*`,
`data-amber-*`, and `amber-design-system-*` names are alpha compatibility
details.

Accessibility requirements are part of this API. Read
`docs/web-design-system/accessibility-contract.md` before adding or promoting a
component; do not leave labels, ids, ARIA relationships, keyboard behavior, or
validation state as undocumented caller work.

## Require

```crystal
require "asset_pipeline/design_system"
```

When working inside this repository before packaging, use:

```crystal
require "../src/asset_pipeline/design_system"
```

## Naming Rules

- Use `Components::DesignSystem::Button`, not `ButtonComponent`, in generated
  app code.
- Use `data-ap-*` behavior hooks first. Co-emit `data-amber-*` only when
  compatibility with the current alpha runtime is required.
- Do not name components after the host framework. Generic primitives should
  read as Button, Card, Dialog, Tabs, DataTable, FormField, Chart, Timeline,
  and similar known interface patterns.
- Do not make view authors recreate labels, ids, live regions, or keyboard
  hooks when a design-system component can own them.

## Common Components

The generic names below are the canonical authoring surface. Several currently
alias existing alpha implementation classes under `Components::Examples`, but
generated views should not use those compatibility names.

### LandingHero

```crystal
Components::DesignSystem::LandingHero.new(
  kicker: "No-build JavaScript",
  title: "Beautiful launch ops by default.",
  body: "A concise product proof statement.",
  actions: [
    Components::DesignSystem::LandingHero::Action.new("Open pricing"),
    Components::DesignSystem::LandingHero::Action.new(
      "External project",
      href: "https://crystal-lang.org",
      tone: "neutral",
      emphasis: "ghost",
      external: true
    ),
  ],
  toolbar_html: theme_switcher_html,
  aside_html: preview_html
).render
```

Compatibility anatomy:

```html
<header class="am-demo-hero">
  <div>
    <div class="am-kicker">...</div>
    <h1 class="am-demo-title">...</h1>
    <p class="am-demo-copy">...</p>
    <div class="am-demo-actions">...</div>
    <div class="am-demo-toolbar" role="group" aria-label="Theme preview">...</div>
  </div>
  <!-- optional labelled aside/raw preview HTML -->
</header>
```

Accessibility contract:

- Owns the visible landing `h1` with the current `am-demo-title` selector.
- `title` is required and must be non-empty.
- Text fields and structured action labels/hrefs are escaped.
- Button actions render native `<button type="button">` by default and should
  be used for in-place behavior with explicit runtime hooks. Use link actions
  for navigation.
- Link actions render anchors; `external: true` adds `target="_blank"` and
  `rel="noopener noreferrer"`.
- The toolbar wrapper is a labelled group. The supplied toolbar HTML must own
  its inner control semantics, such as ThemeSwitcher pressed states.
- `aside_html` is a vetted raw migration slot. Callers must supply labelled,
  non-duplicative preview/aside content.
- Default output emits `data-component="landing-hero"`. Use
  `compatibility_markup: "demo"` when extracting existing demo markup without
  changing generated HTML.

### PageHero

```crystal
Components::DesignSystem::PageHero.new(
  kicker: "Frontloader Studio",
  title: "Ship clearer work",
  body: "A calm command center for launch teams."
).build do |hero|
  hero << Components::Elements::RawHTML.new(hero_aside_html)
end.render
```

Compatibility anatomy:

```html
<header class="am-page-hero">
  <div>
    <div class="am-kicker">...</div>
    <h1 class="am-page-title">...</h1>
    <p class="am-demo-copy">...</p>
  </div>
  <!-- optional aside/raw child HTML -->
</header>
```

Accessibility contract:

- Emits the current demo-compatible `am-page-hero`, `am-kicker`,
  `am-page-title`, and `am-demo-copy` selectors exactly.
- Accepts `body` or `copy` for the lead paragraph.
- Child content renders after the text block and is intended for the optional
  hero aside.
- `id`, extra `class`, and `label`/`aria_label` are passthrough attributes when
  a page needs an explicit hook or accessible name.

### OrderSummary

```crystal
Components::DesignSystem::OrderSummary.new(
  label: "Interactive order summary",
  seat_id: "pricing-seats",
  seat_min: "3",
  seat_max: "40",
  seat_value: "12",
  seat_price: "99",
  billing: "annual",
  annual_factor: "0.82",
  period: "/mo",
  add_ons: [
    Components::DesignSystem::OrderSummary::AddOn.new(
      "Accessibility audit add-on",
      "180",
      true
    ),
  ],
  total_label: "Billing",
  total: "$1,188/mo",
  note: "Annual billing saves 18%."
).render
```

Compatibility anatomy:

```html
<aside class="am-summary" data-ap-pricing aria-label="Interactive order summary">...</aside>
```

Accessibility contract:

- Names the summary region with `label`.
- Owns the labelled native range input for seats.
- Emits neutral `data-ap-pricing*` hooks on fields by default.
- Emits the root `data-ap-pricing` runtime hook only when `seat_price` is
  supplied. Pricing formulas are explicit component configuration, not
  hard-coded public runtime behavior.
- In demo compatibility mode, co-emits the current `data-amber-pricing*`
  aliases so the existing runtime can update seats, add-ons, total, and note.
- Add-ons are native checkboxes inside visible labels.
- The total uses `aria-live="polite"`/`aria-atomic="true"` in default output,
  and the runtime adds the same attributes for compatibility summaries.
- The note uses `aria-live="polite"` because pricing text can change after
  input.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks for stable targeting or accessible relationships.

### PageLinkCard

```crystal
Components::DesignSystem::PageLinkCard.new(
  href: "dashboard.html",
  title: "Dashboard",
  summary: "Metrics, filters, tables, charts, and command palette."
).render
```

Compatibility anatomy:

```html
<a class="am-page-card" href="dashboard.html"><strong>Dashboard</strong><span>Metrics, filters, tables, charts, and command palette.</span><small>Open dashboard</small></a>
```

Accessibility contract:

- Emits the current overview page-card anatomy exactly by default.
- Accepts `summary`, `body`, or `copy` for the descriptive text.
- `action_label` is optional and defaults to `Open #{title.downcase}`.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks when a generated view needs stable targeting or an
  accessible name.

### PageLinkCardGrid

```crystal
Components::DesignSystem::PageLinkCardGrid.new.build do |grid|
  grid << Components::Elements::RawHTML.new(page_link_card_html)
end.render
```

Compatibility anatomy:

```html
<div class="am-page-card-grid">...</div>
```

Accessibility contract:

- Wraps overview `PageLinkCard` navigation groups without owning the accessible
  name; the surrounding section should provide the heading or label.
- Default output includes `data-component="page-link-card-grid"` for new
  views.
- `compatibility_markup: "demo"` suppresses the metadata so existing overview
  proof markup can be extracted without changing generated HTML anatomy.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks for stable targeting or accessible grouping.

### Divider

```crystal
Components::DesignSystem::Divider.new(
  label: "Interactions"
).render
```

Compatibility anatomy:

```html
<div class="am-divider"><span>Interactions</span></div>
```

Accessibility contract:

- Emits the current divider anatomy exactly by default.
- Use `label` for the visible divider text.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks when a generated view needs stable targeting or an
  accessible name.
- Divider is static HTML only and does not add runtime hooks or JavaScript
  behavior.

### VisualBand

```crystal
Components::DesignSystem::VisualBand.new(
  title: "Motion without runtime",
  body: "SVG and token-backed CSS carry the composition."
).build do |band|
  band << Components::Elements::RawHTML.new(svg_html)
end.render
```

Compatibility anatomy:

```html
<div class="am-parallax-band"><strong>Motion without runtime</strong><p>SVG and token-backed CSS carry the composition.</p><!-- optional raw child/SVG HTML --></div>
```

Accessibility contract:

- Emits the current parallax-style composition band anatomy exactly by default.
- Use `title` for the `<strong>` text and `body` for the paragraph; `copy` is
  accepted as a body alias.
- Child content renders after the paragraph and is intended for raw decorative
  or semantic SVG/HTML already authored with the correct accessibility
  attributes.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks when a generated view needs stable targeting or accessible
  relationships.
- VisualBand is static HTML only and does not add runtime hooks or JavaScript
  behavior.

### Metric

```crystal
Components::DesignSystem::Metric.new(
  label: "Ready",
  value: "82%",
  body: "Up 12% after form audit."
).render
```

Compatibility anatomy:

```html
<div class="am-metric"><span class="am-demo-subtle">...</span><strong>...</strong><span>...</span></div>
```

Accessibility contract:

- Emits the current repeated metric anatomy exactly by default.
- Accepts `body` or `copy` for the descriptive text.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks when a generated view needs stable targeting or an
  accessible name.
- Metric groups should still provide their surrounding section or panel with a
  useful heading or accessible name.

### LayoutGrid

```crystal
Components::DesignSystem::LayoutGrid.new(kind: "two").build do |grid|
  grid << Components::Elements::RawHTML.new(left_panel)
  grid << Components::Elements::RawHTML.new(right_panel)
end.render
```

Compatibility anatomy:

```html
<div class="am-two-col">...</div>
<div class="am-three-col">...</div>
<div class="am-four-col">...</div>
<div class="am-metric-grid">...</div>
```

Accessibility contract:

- Use `kind: "grid"`, `"two"`, `"three"`, `"four"`, or `"metric"` for the
  current layout wrappers.
- Default output includes `data-component="layout-grid"` and
  `data-layout-kind`.
- `compatibility_markup: "demo"` suppresses the metadata so existing proof
  markup can be extracted without changing generated HTML anatomy.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks for stable targeting or accessible grouping.
- LayoutGrid is static structure only. Its parent section, panel, or landmark
  must provide the accessible name.

### TerminalPreview

```crystal
Components::DesignSystem::TerminalPreview.new(
  commands: [
    "$ crystal run examples/web_design_system_demo.cr",
    "Generated output/web-design-system-demo.html",
  ]
).render
```

Compatibility anatomy:

```html
<div class="am-terminal" role="region" aria-label="Static generation terminal preview"><div class="am-terminal-line">cmd</div></div>
```

Accessibility contract:

- Emits the current overview terminal anatomy exactly by default.
- `label` names the region and defaults to `Static generation terminal preview`.
- Accepts `commands` or `lines` as `Array(String)`; each item renders as one
  escaped `am-terminal-line`.
- `id`, extra `class`, and explicit `data-*`/`aria-*` attributes are
  passthrough hooks when a generated view needs stable targeting or additional
  accessible relationships.
- TerminalPreview is static HTML only and does not add runtime hooks or
  JavaScript behavior.

### ShowcasePreview

```crystal
Components::DesignSystem::ShowcasePreview.new(
  label: "Product interface preview",
  window_title: "Launch command",
  rail_items: ["Plan", "Ship", "Learn"],
  active_rail_item: "Plan",
  eyebrow: "Launch health",
  headline: "Ready in 18h",
  badge_html: status_badge_html,
  list_label: "Launch readiness workflow",
  steps: [
    Components::DesignSystem::ShowcasePreview::Step.new(
      "Assets compiled",
      "CSS variables, SVG charts, and font strategies ready.",
      step_badge_html
    ),
  ]
).render
```

Compatibility anatomy:

```html
<aside class="am-hero-showcase" data-amber-sticky-hover data-ap-sticky-hover aria-label="Product interface preview">...</aside>
```

Accessibility contract:

- Names the whole static preview with `label` or `aria_label`.
- Renders the rail as a labelled static list in default output; the active item
  carries `aria-current="true"`. Use Tabs or links for real interaction.
- `list_label` names the workflow/list area.
- Text fields are escaped by the primitive.
- `badge_html` and per-step badge HTML are vetted raw slots for status badges.
  They are for non-interactive status content only. Callers must escape any
  dynamic text before turning it into raw HTML, keep status meaning visible or
  screen-reader-only, and not rely on tone/color alone.
- Default output emits `data-component="showcase-preview"` and neutral
  `data-ap-sticky-hover`. `compatibility_markup: "demo"` preserves the current
  demo-only `<nav>` anatomy and compatibility hooks for byte-stable extraction.

### Button

```crystal
Components::DesignSystem::Button.new(
  label: "Save changes",
  tone: "brand",
  emphasis: "solid",
  size: "md"
).render
```

Accessibility contract:

- Renders a real `<button>` by default.
- Disabled state emits `disabled`, `aria-disabled="true"`, and
  `data-state="disabled"`.
- Loading state emits `aria-busy="true"` and stable `data-state="loading"`.
- Icon text must be decorative unless the label itself is visible.

### Card

```crystal
card = Components::DesignSystem::Card.new(
  title: "Launch readiness",
  subtitle: "Operational snapshot"
)
card << "<p>All critical checks are passing.</p>"
card.render
```

Accessibility contract:

- Cards are static content unless explicitly marked interactive.
- Interactive cards must expose role, state, keyboard focus, and a visible
  selected/focus style.

### Fieldset

```crystal
Components::DesignSystem::Fieldset.new(
  legend: "Card details",
  described_by: "checkout-status"
).build do |fieldset|
  fieldset << Components::Elements::RawHTML.new(card_fields)
end.render
```

Accessibility contract:

- Always emits a native `<fieldset>` and `<legend>`.
- The legend is visually hidden by default with `am-visually-hidden` so grouped
  controls have an assistive-technology label without visible chrome.
- `described_by` maps to `aria-describedby` when the group needs shared status
  or help text.

### FormField

```crystal
Components::DesignSystem::FormField.new(
  label: "Work email",
  id: "work-email",
  type: "email",
  autocomplete: "email",
  required: "true"
).render
```

Accessibility contract:

- Every control has a stable label relationship.
- Browser-native validation attributes should be present whenever possible:
  `type`, `autocomplete`, `required`, `minlength`, `maxlength`, `pattern`,
  `inputmode`, and appropriate `name`.
- Error text must have a stable id, and invalid controls must reference it with
  `aria-describedby`.

### AuthForm

```crystal
Components::DesignSystem::AuthForm.new(id: "workspace-auth").render
Components::DesignSystem::AuthForm.new(id: "team-signin", mode: "signin").render
```

Accessibility contract:

- Caller-supplied `id` prefixes field ids and status ids so multiple forms can
  coexist on one page.
- Form controls are grouped with native `fieldset` and visually-hidden
  `legend` text.
- Signup mode owns password guidance, password confirmation, browser
  validation attributes, and a live status region.
- Signin mode uses email/password semantics and current-password autocomplete.
- Password confirmation hooks point to the prefixed password field id.

Behavior hooks:

- `data-ap-validate`
- `data-ap-auth-form`
- `data-ap-password`
- `data-ap-password-confirm`
- `data-ap-password-rules`
- `data-ap-form-status`

### PaymentForm

```crystal
Components::DesignSystem::PaymentForm.new(id: "checkout").render
```

Accessibility contract:

- Caller-supplied `id` prefixes field ids and status ids.
- Payment controls are grouped with native `fieldset` and visually-hidden
  legends for `Receipt contact`, `Card details`, and `Promotion code`.
- Email uses `type="email"` and `autocomplete="email"`.
- Card fields use `autocomplete="cc-name"`, `cc-number`, `cc-exp`, and
  `cc-csc` where appropriate.
- Formatting helpers must not replace native validation; they add quality of
  life masking and clearer status copy.

Behavior hooks:

- `data-ap-validate`
- `data-ap-payment-form`
- `data-ap-card-number`
- `data-ap-card-expiry`
- `data-ap-card-cvc`
- `data-ap-promo-code`
- `data-ap-promo-status`
- `data-ap-form-status`

### ThemeSwitcher

```crystal
Components::DesignSystem::ThemeSwitcher.new.render
Components::DesignSystem::ThemeSwitcher.new(mode: "segmented").render
```

Accessibility contract:

- Toggle controls expose pressed state.
- Explicit light/dark controls are grouped.
- Status text uses a live region when present.
- Runtime updates both neutral `data-ap-theme` and alpha compatibility theme
  attributes on `<html>`.

Behavior hooks:

- `data-ap-theme-toggle`
- `data-ap-theme-set`
- `data-ap-theme-label`
- `data-ap-theme-status`

### ChatPanel

```crystal
Components::DesignSystem::ChatPanel.new(
  title: "Review chat",
  title_id: "chat-title",
  messages_html: message_list_html,
  field_html: message_field_html,
  action_html: send_button_html
).build do |panel|
  panel << Components::DesignSystem::Badge.new(label: "Live", tone: "success")
end.render
```

Compatibility anatomy:

```html
<section class="am-panel am-chat-panel" aria-labelledby="chat-title">
  <div class="am-window-chrome"><strong id="chat-title">Review chat</strong>...</div>
  <div class="am-chat-log" data-amber-chat-log data-ap-chat-log role="log" aria-live="polite">...</div>
  <form class="am-chat-form" data-amber-chat-form data-ap-chat-form>...</form>
</section>
```

Accessibility contract:

- The panel is labelled by its visible title unless `label` is supplied.
- The message log is a polite `role="log"` live region.
- The composer remains a native `<form>`.
- `messages_html`, `field_html`, and `action_html` are narrow raw slots for
  byte-stable migration from the current collaboration page helpers.
- Runtime hooks co-emit neutral `data-ap-chat-form`/`data-ap-chat-log` and
  alpha `data-amber-*` aliases.

### LiveSearchPanel

```crystal
Components::DesignSystem::LiveSearchPanel.new(
  title: "Live search",
  title_id: "search-title",
  field_html: search_field_html
).render
```

Accessibility contract:

- The panel is labelled by its visible title unless `label` is supplied.
- The supplied search field must keep a native label/control relationship.
- Results render in `role="status" aria-live="polite"`.
- The field should carry `data-ap-live-search` with the
  `data-amber-live-search` compatibility alias.
- Results co-emit `data-ap-search-results` and `data-amber-search-results`.

### UploadQueue

```crystal
Components::DesignSystem::UploadQueue.new(
  title: "Upload queue",
  title_id: "upload-title",
  item_html: uploaded_item_html,
  progress_html: progress_html
).build do |queue|
  queue << Components::Elements::RawHTML.new(pending_item_html)
end.render
```

Accessibility contract:

- The panel is labelled by its visible title unless `label` is supplied.
- Queue row and progress semantics are supplied by the item/progress slots so
  existing `Badge` and `Progress` output can migrate byte-stably.
- Use native progress semantics for in-flight uploads.

### DataTable

```crystal
Components::DesignSystem::DataTable.new(id: "launch-table").render
```

Accessibility contract:

- Use real table semantics for tabular data.
- Row states require a strong indicator, subtle background, hover state, and
  accessible status text.
- Responsive tables must not create unlabelled focusable scroll regions.
- Filters should announce result counts through a live status region.

### Dialog

```crystal
Components::DesignSystem::Dialog.new(id: "confirm-plan").render
```

Accessibility contract:

- Use the browser `<dialog>` element for modal behavior.
- Dialogs require an accessible name and close control.
- Runtime behavior must support open buttons, close buttons, Escape, backdrop
  close where appropriate, focus return, and idempotent initialization.

Behavior hooks:

- `data-ap-dialog-open`
- `data-ap-dialog-close`

### Tabs

```crystal
Components::DesignSystem::Tabs.new(id: "settings-tabs").render
```

Accessibility contract:

- Render `tablist`, `tab`, and `tabpanel` relationships.
- Current tab state must be reflected with `aria-selected`.
- Runtime behavior must support keyboard movement and visible focus.

Behavior hooks:

- `data-ap-tabs`
- `data-ap-tab`

### Carousel

```crystal
Components::DesignSystem::Carousel.new(id: "pattern-carousel").render
```

Accessibility contract:

- Controls must be real buttons with accessible names.
- Active slide state must be represented without removing source content from
  assistive technology unexpectedly.
- Motion must respect `prefers-reduced-motion`.

Behavior hooks:

- `data-ap-carousel`
- `data-ap-carousel-prev`
- `data-ap-carousel-next`
- `data-ap-carousel-status`

### CommandPalette

```crystal
Components::DesignSystem::CommandPalette.new(id: "global-command").render
```

Accessibility contract:

- The open control must identify its target.
- Search input must be labelled.
- Results need keyboard focus behavior, empty state text, and status updates.

Behavior hooks:

- `data-ap-command-open`
- `data-ap-command-panel`
- `data-ap-command-search`
- `data-ap-command-item`

### SimpleChart

```crystal
Components::DesignSystem::SimpleChart.new.render
```

Accessibility contract:

- First-party SVG chart output must keep a figure/caption and a source-data
  table.
- External chart libraries must mount behind an adapter root and may not become
  a hard dependency.

### ScheduleHeatmap

```crystal
Components::DesignSystem::ScheduleHeatmap.new.render
```

Accessibility contract:

- Visual density cells need an accessible data equivalent.
- Color cannot be the only signal for important status.
- The component must maintain contrast in light and dark themes.

### Timeline

```crystal
Components::DesignSystem::Timeline.new.render
```

Accessibility contract:

- The timeline should be meaningful as static HTML before animation.
- Reveal animation must be progressive enhancement.
- Motion must respect `prefers-reduced-motion`.

Behavior hooks:

- `data-ap-reveal`

## Page And Feedback Primitives

These generic page and feedback primitives are available through
`Components::DesignSystem::*`. Several still preserve demo-compatible anatomy or
raw slots so the current visual proof can shrink without output drift. Current
`am-*` selectors are compatibility styling details until the class API is
renamed; new token references should prefer neutral `--ap-*` variables with
compatibility fallbacks only where needed.

### PageShell

```crystal
Components::DesignSystem::PageShell.new(
  id: "settings-shell",
  title: "Settings",
  subtitle: "Manage workspace preferences."
).render
```

Contract:

- Owns an in-page shell wrapper, skip link, optional header, and labelled
  `main` region.
- Does not currently own the full document envelope (`html[lang]`, viewport
  meta, theme attributes, script tags, or primary navigation). The demo
  generator still owns that outer document contract until a future full
  document primitive lands.
- Accepts child content for the main region.
- Keeps focus behavior on `main` through `tabindex="-1"`.

### DashboardShell

```crystal
Components::DesignSystem::DashboardShell.new(
  sidebar_html: %(<nav><a href="#overview">Overview</a></nav>),
  body_html: %(<h1 id="dashboard-title">Dashboard</h1>)
).render
```

Contract:

- Emits the current dashboard shell anatomy for byte-stable migration:
  `am-section` section, `am-dashboard-shell`, `am-sidebar`, and
  `am-dashboard-main`.
- Uses generic public inputs: `title_id` defaults to `dashboard-title`,
  `sidebar_label` defaults to `Dashboard sections`, `sidebar_html` supplies the
  sidebar slot, and `body_html` or `main_html` supplies the main slot.
- Preserves accessibility wiring with `aria-labelledby` on the section and
  `aria-label` on the sidebar.
- Accepts optional root `id`, `class`, and `data-*`/`aria-*` passthrough for
  stable hooks and accessible descriptions.
- Does not add runtime hooks or host-framework-branded public API.

### PageHero, Section, And Panel

```crystal
Components::DesignSystem::PageHero.new(title: "Launch dashboard").render
Components::DesignSystem::PageLinkCard.new(href: "dashboard.html", title: "Dashboard", summary: "Operational overview").render
Components::DesignSystem::Section.new(title: "Readiness").render
Components::DesignSystem::Panel.new(title: "Queue health").render
```

Contract:

- PageHero preserves the current demo hero anatomy while exposing generic
  `kicker`, `title`, `body`/`copy`, and optional aside child slots.
- PageLinkCard preserves the current overview page-card anchor anatomy while
  exposing generic `href`, `title`, `summary`/`body`/`copy`, and
  `action_label` inputs.
- Section and Panel emit stable heading/id relationships.
- Supports eyebrow, description, actions, and constrained content slots without
  requiring view authors to rebuild heading markup.
- Preserves token-backed spacing, light/dark behavior, reduced-motion behavior,
  and 320px reflow from the current generated pages.

### Feedback Primitives

```crystal
Components::DesignSystem::Badge.new(label: "Ready", tone: "success").render
Components::DesignSystem::Alert.new(tone: "warning", title: "Needs review").render
Components::DesignSystem::Toast.new(body: "Saved").render
Components::DesignSystem::EmptyState.new(title: "No launches yet").render
Components::DesignSystem::Skeleton.new(label: "Loading queue").render
Components::DesignSystem::Progress.new(label: "Upload progress", value: 72).render
```

Contract:

- Status and alert surfaces expose the correct role or live-region behavior for
  their persistence level.
- Empty/loading/progress states have accessible names and do not rely on color,
  animation, or placeholder shapes alone.
- Variants use the same tone vocabulary as buttons, cards, and table states.
- Toast dismiss buttons use `data-ap-toast-dismiss` and are wired by the
  vanilla runtime.

### ValidatedForm

```crystal
form = Components::DesignSystem::ValidatedForm.new(
  id: "reset-form",
  label: "Password reset",
  status: "Enter your account email."
)
form << Components::Elements::RawHTML.new(
  Components::DesignSystem::FormField.new(
    id: "reset-email",
    label: "Account email",
    type: "email",
    autocomplete: "email",
    required: "true"
  ).render
)
form.render
```

Contract:

- Emits `data-ap-validate`, `novalidate`, a stable status region, and
  `aria-describedby` wiring by default.
- Keeps browser-native validation on the controls; the wrapper owns the shared
  status/live-region contract.
- Co-emits the current compatibility hooks until the alpha runtime migration is
  complete.

### Disclosure

```crystal
Components::DesignSystem::Disclosure.new(id: "details", label: "View details").render
```

Contract:

- Uses a real button with `aria-expanded` and an owned panel relationship.
- Runtime hooks use `data-ap-disclosure` first while co-emitting the current
  compatibility alias during migration.
- Keyboard, focus, and reduced-motion behavior match the current demo proof.

## Validation For Component Changes

Run the focused API checks before broad browser validation:

```bash
crystal spec spec/support/accessibility_matchers_spec.cr
crystal spec spec/components/design_system spec/components/examples/example_components_spec.cr
crystal run examples/web_design_system_demo.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/validate_design_system_manifest.cr
git diff --check
```

After visual, behavior, or accessibility changes, also run:

```bash
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
```

For extraction work, follow `docs/web-design-system/refactor-accountability.md`:
capture before evidence, make one contained extraction, regenerate, compare
screenshots, record line-count movement, and write a phase note.
