# Component Catalog

## Button

Intent: primary actions, secondary actions, destructive retries, and loading
work.

Public component: `Button`. Current compatibility selector: `am-button`.

Variants:

- Tone: `brand`, `neutral`, `success`, `warning`, `danger`, `info`
- Emphasis: `solid`, `soft`, `outline`, `ghost`
- Size: `sm`, `md`, `lg`
- State: `default`, `active`, `selected`, `disabled`, `loading`

Accessibility:

- Disabled buttons emit `disabled` and `aria-disabled="true"`.
- Loading buttons emit `aria-busy="true"` and a CSS spinner.
- Selected buttons emit `aria-pressed`.
- Focus emits an explicit visible ring that survives solid, outline, soft, and
  ghost variants.

Anti-pattern: do not use `.btn`, `.btn-primary`, or size classes such as
`.btn-lg` for new canonical examples.

## Card

Intent: grouped content with a clear surface, optional selected/destructive
state, and responsive anatomy.

Public component: `Card`. Current compatibility selector: `am-card`.

Anatomy:

- `am-card__media`
- `am-card__body`
- `am-card__eyebrow`
- `am-card__title`
- `am-card__subtitle`
- `am-card__content`

States:

- `am-card--selected`
- `am-card--danger`
- `am-card--interactive`
- `am-card--outline`

Token dependencies: surface, border, radius, elevation, text, brand, danger,
and motion tokens.

## Data Table

Intent: CRUD index screens where stateful rows must be scannable.

Public component: `DataTable`. Current compatibility wrapper:
`am-table-wrap`.

Current compatibility table selector: `am-table`.

Row state contract:

- Rows use `data-state`.
- State rows include a strong left indicator.
- State rows use subtle backgrounds by default.
- Stateful row body text uses the primary text token so subtle fills do not
  wash out dense data.
- Hover state gets a richer background.
- Transitions use motion tokens and respect reduced motion.
- Rows carry an `aria-label` that includes record title and status.

Supported row states in the proof: `success`, `warning`, `danger`, `selected`,
and `empty`.

## Simple Chart

Intent: small metric visualizations without forcing a chart dependency.

Public component: `SimpleChart`. Current compatibility selector: `am-chart`.

Adapter markers: `data-chart-adapter="first-party-svg"` and
`data-chart-adapter="external"`

Behavior:

- Renders SVG bars with token-backed colors.
- Uses `data-chart-part="bar"` so future SVG part animation can target pieces.
- Animates bar growth only when motion is allowed.
- Includes a visually-hidden source-data table and `aria-describedby` so chart
  values are available without relying on SVG perception.
- External adapters mount inside `data-chart-external-root` and keep the same
  semantic figure, caption, token shell, and table fallback.
- Unknown adapter names raise instead of silently introducing a dependency.

Use a future adapter for complex charts, but keep the wrapper semantic and the
dependency isolated.

## Metric

Intent: compact numeric or short-value summaries inside dashboard, proof, and
overview grids.

Public component: `Metric`. Current compatibility selector: `am-metric`.

Anatomy:

- label text in the current subtle text selector
- value text in `<strong>`
- body/copy text in the trailing `<span>`

Compatibility HTML:

```html
<div class="am-metric"><span class="am-demo-subtle">Label</span><strong>Value</strong><span>Copy</span></div>
```

Authoring contract:

- Use `label`, `value`, and `body` for new code; `copy` is accepted as a body
  alias.
- Default output stays exactly compatible with the repeated demo metric markup.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  hooks or accessible names.

## Layout Grid

Intent: repeated static layout wrappers for two-column, three-column,
four-column, metric, and generic grid compositions.

Public component: `LayoutGrid`. Current compatibility selectors: `am-grid`,
`am-two-col`, `am-three-col`, `am-four-col`, and `am-metric-grid`.

Anatomy:

- root wrapper in the selected compatibility class
- optional `data-component="layout-grid"` and `data-layout-kind` metadata in
  default output
- raw or escaped child content in the wrapper

Compatibility HTML:

```html
<div class="am-two-col">...</div>
```

Authoring contract:

- Use `kind: "grid"`, `"two"`, `"three"`, `"four"`, or `"metric"`.
- Use `compatibility_markup: "demo"` when extracting current demo wrappers
  without adding metadata.
- Default output is suitable for new views that want stable component metadata.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  hooks or accessible grouping.
- Do not use LayoutGrid as the accessible name owner; the surrounding section,
  panel, or landmark should carry the heading or label.

## Landing Hero

Intent: first-viewport product or portfolio hero composition with a visible
title, supporting copy, structured actions, optional toolbar controls, and an
optional labelled preview aside.

Public component: `LandingHero`. Current compatibility selectors:
`am-demo-hero`, `am-demo-title`, `am-demo-actions`, and `am-demo-toolbar`.

Anatomy:

- root hero wrapper
- text block with kicker, `h1`, and lead copy
- optional structured action row
- optional labelled toolbar group
- optional raw preview/aside slot

Compatibility HTML:

```html
<header class="am-demo-hero">...</header>
```

Authoring contract:

- `title` is required and must be non-empty because LandingHero owns the page
  hero `h1`.
- Use `LandingHero::Action` for buttons and links instead of raw action HTML.
- Button actions are for in-place behavior with explicit runtime hooks; use
  link actions for navigation.
- External link actions use `external: true` so target and rel are safe by
  default.
- The toolbar wrapper owns the group label; inner toolbar HTML must own its own
  control semantics.
- `aside_html` is a raw migration slot for labelled preview content.
- Default output includes `data-component="landing-hero"`; demo compatibility
  suppresses metadata for byte-stable extraction.

## Order Summary

Intent: interactive checkout/pricing summary with a labelled seat range,
native add-on checkboxes, live total hooks, and a polite status note.

Public component: `OrderSummary`. Current compatibility selector:
`am-summary`.

Anatomy:

- labelled summary aside
- visible title
- native range field for seat count
- optional add-on checkbox group
- optional total row
- optional live note

Compatibility HTML:

```html
<aside class="am-summary" data-ap-pricing aria-label="Interactive order summary">...</aside>
```

Authoring contract:

- Use `OrderSummary::AddOn` for add-on checkbox rows.
- Default output emits neutral `data-ap-pricing*` field hooks.
- Default output emits the root `data-ap-pricing` runtime hook only when
  `seat_price` is supplied, so public pricing behavior is configured rather
  than inherited from the demo formula.
- Demo compatibility co-emits current `data-amber-pricing*` aliases for
  byte-stable migration.
- The live total uses `aria-live="polite"` and `aria-atomic="true"` in default
  output; the runtime adds those attributes for compatibility summaries.
- The live note uses `aria-live="polite"` because it can change with pricing
  inputs.
- Keep the summary label specific to the surrounding purchase or pricing task.

## Terminal Preview

Intent: static command/output previews for generated proof pages and overview
screens.

Public component: `TerminalPreview`. Current compatibility selector:
`am-terminal`.

Anatomy:

- root region in `am-terminal`
- one `am-terminal-line` child per command or line

Compatibility HTML:

```html
<div class="am-terminal" role="region" aria-label="Static generation terminal preview"><div class="am-terminal-line">cmd</div></div>
```

Authoring contract:

- Use `commands` for command-oriented previews; `lines` is accepted for generic
  terminal copy.
- `label` names the region and defaults to
  `Static generation terminal preview`.
- Default output stays exactly compatible with the current overview terminal
  proof anatomy.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  hooks or accessible relationships.
- Do not add JavaScript behavior or runtime hooks; this primitive is static.

## Showcase Preview

Intent: static interface preview windows for heroes, proofs, and portfolio
sections. It gives generated pages a reusable app-window composition without
making a one-off business-specific hero component.

Public component: `ShowcasePreview`. Current compatibility selectors:
`am-hero-showcase`, `am-window-chrome`, `am-showcase-rail`,
`am-showcase-pill`, `am-showcase-headline`, `am-journey-map`, and
`am-journey-step`.

Anatomy:

- root preview surface with an accessible label
- window chrome/title
- labelled static rail list for preview context
- headline/status area
- labelled list of workflow steps

Compatibility HTML:

```html
<aside class="am-hero-showcase" data-amber-sticky-hover data-ap-sticky-hover aria-label="Product interface preview">...</aside>
```

Authoring contract:

- Use `label` or `aria_label` for the accessible name.
- Use `rail_items` only for static preview context; default output renders a
  labelled static list and marks the active item with `aria-current="true"`.
  Real panels need Tabs or links with keyboard behavior.
- Use `ShowcasePreview::Step` for each workflow/status row.
- The primitive escapes all text fields.
- `badge_html` and step badge HTML are raw migration slots for non-interactive
  status content. Callers must escape dynamic text before making raw HTML and
  keep status meaning visible or screen-reader-only, not color alone.
- Default output includes `data-component="showcase-preview"` and neutral
  `data-ap-sticky-hover`; demo compatibility preserves the byte-stable alpha
  `<nav>` anatomy and hooks.

## Page Link Card

Intent: overview navigation cards that link to generated proof pages with a
title, short summary, and action hint.

Public component: `PageLinkCard`. Current compatibility selector:
`am-page-card`.

Anatomy:

- root link in `am-page-card`
- page title in `<strong>`
- summary/body/copy text in the middle `<span>`
- action hint in `<small>`

Compatibility HTML:

```html
<a class="am-page-card" href="dashboard.html"><strong>Dashboard</strong><span>Metrics, filters, tables, charts, and command palette.</span><small>Open dashboard</small></a>
```

Authoring contract:

- Use `href`, `title`, and `summary` for new code; `body` and `copy` are
  accepted as summary aliases.
- `action_label` is optional and defaults to `Open #{title.downcase}`.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  hooks or accessible names.
- Keep PageLinkCard content concise enough for overview scanning; longer
  explanations belong in the destination page section.

## Page Link Card Grid

Intent: overview navigation wrapper for groups of `PageLinkCard` links.

Public component: `PageLinkCardGrid`. Current compatibility selector:
`am-page-card-grid`.

Anatomy:

- root wrapper in `am-page-card-grid`
- optional `data-component="page-link-card-grid"` metadata in default output
- `PageLinkCard` children or raw/escaped child content in the wrapper

Compatibility HTML:

```html
<div class="am-page-card-grid">...</div>
```

Authoring contract:

- Use this wrapper for overview page-card navigation groups.
- Use `compatibility_markup: "demo"` when extracting the current overview demo
  wrapper without adding metadata.
- Default output is suitable for new views that want stable component metadata.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  hooks or accessible grouping.
- Do not use PageLinkCardGrid as the accessible name owner; the surrounding
  section or landmark should carry the heading or label.

## Divider

Intent: labelled visual separators for static proof and pattern pages.

Public component: `Divider`. Current compatibility selector: `am-divider`.

Anatomy:

- root divider wrapper in `am-divider`
- visible label text in the child `<span>`

Compatibility HTML:

```html
<div class="am-divider"><span>Label</span></div>
```

Authoring contract:

- Use `label` for the visible divider text.
- Default output stays exactly compatible with the current pattern divider
  markup.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  hooks or accessible names.
- Do not add JavaScript behavior or runtime hooks; this primitive is static.

## Visual Band

Intent: static page composition bands that pair a compact title/body statement
with raw decorative or semantic child HTML such as SVG.

Public component: `VisualBand`. Current compatibility selector:
`am-parallax-band`.

Anatomy:

- root composition band in `am-parallax-band`
- title text in `<strong>`
- body/copy text in `<p>`
- optional raw child/SVG HTML after the paragraph

Compatibility HTML:

```html
<div class="am-parallax-band"><strong>Title</strong><p>Body</p><!-- optional raw child/SVG HTML --></div>
```

Authoring contract:

- Use `title` and `body` for new code; `copy` is accepted as a body alias.
- Child content renders after the paragraph and is intended for already-vetted
  raw HTML/SVG.
- Default output stays exactly compatible with the current parallax-style page
  composition band markup.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  hooks or accessible relationships.
- Do not add JavaScript behavior or runtime hooks; this primitive is static.

## Dashboard Shell

Intent: dashboard page anatomy with a sidebar navigation region and primary
dashboard content region, extracted narrowly for byte-stable migration.

Public component: `DashboardShell`. Current compatibility selectors:
`am-section`, `am-dashboard-shell`, `am-sidebar`, and `am-dashboard-main`.

Anatomy:

- root section in `am-section`
- dashboard wrapper in `am-dashboard-shell`
- sidebar slot in `<aside class="am-sidebar">`
- main slot in `<div class="am-dashboard-main">`

Compatibility HTML:

```html
<section class="am-section" aria-labelledby="dashboard-title"><div class="am-dashboard-shell"><aside class="am-sidebar" aria-label="Dashboard sections">...</aside><div class="am-dashboard-main">...</div></div></section>
```

Authoring contract:

- Use `sidebar_html` for the existing sidebar/nav markup.
- Use `body_html` for the main dashboard content; `main_html` is accepted as an
  alias.
- `title_id` defaults to `dashboard-title` and owns the root
  `aria-labelledby` relationship.
- `sidebar_label` defaults to `Dashboard sections`.
- Use optional `id`, `class`, and `data-*`/`aria-*` passthrough only for stable
  root hooks or accessible descriptions.
- Do not add JavaScript behavior or runtime hooks; this primitive is static.

## Promoted Interactive Components

The first page-pattern promotion pass turns the strongest demo-only patterns
into reusable wrappers exposed through generic `Components::DesignSystem::*`
names:

- `CommandPalette`: emits an opener, dialog-style fixed panel,
  labelled search field, close button, command buttons, and
  `data-ap-command-*` hooks with current compatibility aliases.
- `Tabs`: emits `role="tablist"`, roving `tabindex`, tab/panel id
  links, selected state, and hidden inactive panels.
- `Carousel`: emits carousel/slide roledescription, live status,
  previous/next controls, active state, and `aria-hidden` slide state.
- `Dialog`: emits a native `<dialog>`, labelled opener,
  `aria-labelledby`, `aria-describedby`, and close hook.
- `ScheduleHeatmap`: emits 24 accessible hourly cells with list/listitem
  semantics, labels, visible heat pills, `aria-describedby`, and a
  visually-hidden table fallback.
- `Timeline`: emits the center-rail milestone layout with
  `data-ap-reveal` hooks and responsive mobile collapse.
- `PaymentForm`: emits semantic receipt, card, expiry, CVC, and promo
  fields with native validation attributes, specific fieldset grouping, and
  design-system formatting/status hooks.
- `AuthForm`: emits sign-up and sign-in variants with email,
  autocomplete, password-rule, password-confirmation, and required-field
  semantics, grouped by native fieldsets with hidden legends.
- `FormField`: emits a labelled browser-native `input`, `select`, or
  `textarea` with design-system field anatomy, validation attributes, data hooks,
  hints, and error wiring.
- `ThemeSwitcher`: emits the global theme toggle and explicit
  light/dark segmented controls against the generated theme cascade.
- `PricingCard`: emits reusable pricing cards composed from Badge,
  token-backed price typography, featured state, and `Button`.
- `ChatPanel`: emits the collaboration chat shell, labelled title chrome,
  `role="log" aria-live="polite"` message region, native form, and
  `data-ap-chat-*` hooks with current compatibility aliases.
- `LiveSearchPanel`: emits the collaboration live-search panel, labelled title,
  raw native search-field slot, and `role="status" aria-live="polite"` results
  region with neutral and compatibility hooks.
- `UploadQueue`: emits the labelled upload queue shell around supplied item and
  progress HTML so the current queue can migrate without visual drift.

These components are included through `src/components/design_system/components.cr`
via promoted aliases and primitive wrappers, then re-exported by
`src/components.cr`. They are covered by the focused design-system namespace,
primitive, and compatibility specs. Generated app code should use the generic
`Components::DesignSystem::*` names; the `Components::Examples::*Component`
class names are retained only for alpha compatibility.

## Dialog, Inputs, Toggle, Slider

The demo also uses native web controls styled by design-system page/component CSS:

- `<dialog>` for modal behavior
- token-backed text input focus, invalid states, hints, and errors
- native checkbox toggle with `accent-color`
- range input with `accent-color`
- `type="email"`, `autocomplete`, `required`, `minlength`, `pattern`, and
  `inputmode` for semantic browser validation

These remain intentionally vanilla for Milestone 1 where a native control is the
right abstraction. More Crystal wrappers can be added using the same token/state
contract.

## Forms, Pricing, And Payment

The Frontloader Studio proof includes full-page form contexts and promoted form
wrappers:

- sign-in, sign-up, reset, and preferences forms
- password-rule feedback and password confirmation
- pricing seat slider, billing toggle, add-ons, and live total
- payment form with card number, expiry, CVC, promo code, invalid fields, and
  success status
- `role="status"` live regions for form, pricing, search, and chat updates

## Foundation Showcases

The demo includes non-component foundations because future agents need
to see how the visual language behaves before creating new primitives:

- Frontloader Studio home page with hero, product preview, terminal proof, and
  page cards
- warm action + ink + teal palette behavior in light and dark mode
- explicit light/dark segmented controls and a global theme toggle
- CSS/SVG-first visuals instead of remote stock imagery

## Page Layouts

The demo includes page-level examples, not only isolated components:

- dashboard shell with sidebar, metrics, filters, table rows, chart, heatmap,
  and command palette
- Crystal timeline with a desktop center rail and mobile single-column layout
- collaboration page with chat, live search, upload queue, activity, empty, and
  loading states
- patterns page with divider, parallax-style CSS/SVG band, tabs, carousel,
  disclosure, native dialog, and toast

Some page-level patterns are now final wrapper proofs. Larger layout sections
remain design direction and markup contracts for future wrappers.

Extracted page primitive surface:

- `LandingHero`: overview/marketing hero with a visible `h1`, structured
  actions, optional labelled toolbar group, and optional labelled aside/raw
  preview slot.
- `OrderSummary`: pricing/checkout summary with native seat range input,
  add-on checkboxes, live total hooks, and polite note text.
- `PageHero`: current demo-compatible page hero header with `am-page-hero`,
  `am-kicker`, `am-page-title`, `am-demo-copy`, and an optional aside/raw child
  slot.
- `PageLinkCard`: current overview page-card anchor with `am-page-card`,
  title, summary/body/copy, and action hint text.
- `PageLinkCardGrid`: overview navigation wrapper for `PageLinkCard` groups
  with `am-page-card-grid` and optional default metadata.
- `PageShell`: document/head/page scaffold, skip link, theme attributes,
  landmarks, global navigation, and one page `h1`.
- `DashboardShell`: current dashboard page body shell with sidebar and main
  slots, preserving `aria-labelledby` and sidebar labelling for migration.
- `Section`: heading/id wiring, eyebrow, description, action slot, and spacing
  rhythm for full-width page bands.
- `Panel`: bounded work surfaces for dense dashboard, form, and settings
  content without nested-card styling.

Acceptance for page primitive adoption:

- The generated demo pages remain visually equivalent in desktop, mobile,
  dark-mode, reduced-motion, and 320px reflow screenshots unless the phase note
  documents intentional drift.
- The current generator implementation, `examples/web_design_system_demo.cr`,
  shrinks because repeated shell, section, and panel markup moves into reusable
  primitives. `examples/amber_design_system_demo.cr` remains only as a legacy
  compatibility wrapper.
- Existing landmarks, heading order, focus states, theme switching, and
  no-horizontal-overflow checks remain intact.

## Feedback And Communication

Additional feedback and communication targets:

- `Badge` for compact status labels.
- `Alert` for success, warning, danger, and info messages.
- `EmptyState` for empty states with a next action.
- `Skeleton` for loading previews.
- `Timeline` for event history.
- `Toast` for transient feedback.
- `ChatPanel`, `LiveSearchPanel`, and `UploadQueue` for the current
  collaboration page anatomy.

The current selectors remain `am-badge`, `am-alert`, `am-empty`,
`am-skeleton`, `am-timeline`, `am-toast`, `am-chat-panel`, `am-chat-log`,
`am-chat-form`, `am-live-search`, `am-search-results`, and `am-upload-queue`
until the selector migration is complete.

Next extraction target:

- `Badge`: compact status labels using the shared tone vocabulary.
- `Alert`: persistent success, warning, danger, and info messages with
  appropriate role semantics.
- `Toast`: transient status messaging with live-region behavior and focus-safe
  dismissal.
- `EmptyState`: no-data panels with title, description, and next action.
- `Skeleton`: loading previews with accessible loading text and reduced-motion
  behavior.
- `Progress`: determinate and indeterminate progress using native
  `role="progressbar"` semantics where needed.
- `Disclosure`: expandable content with `aria-expanded`, owned panel ids, and
  neutral `data-ap-*` hooks.
- `Fieldset`: native grouped-control boundaries with hidden legends and
  optional shared status/help wiring.
- `ValidatedForm`: shared `data-ap-validate`, status/live-region, and
  `aria-describedby` wiring for forms that still own their field composition.
- `ChatPanel`, `LiveSearchPanel`, and `UploadQueue`: collaboration wrappers
  with narrow raw slots for message, field, action, item, and progress HTML.

Extraction should preserve the current visual language. Do not redesign badges,
alerts, empty states, skeletons, progress indicators, toasts, disclosures, chat,
search, or upload queues while moving them into components; make the generator
smaller first, then record any separate visual change as a later phase.

## Vanilla Helper Contract

The current runtime file owns progressive enhancement for the demo:

- theme switching and explicit browser `colorScheme`
- sticky hover bump/follow/tug behavior
- dialog focus return
- table filtering
- pricing calculator
- form validation and payment formatting
- deterministic live search
- chat append
- command palette
- tabs with arrow/Home/End keys
- carousel with buttons and arrow/Home/End keys
- native dialog focus wrap and return
- timeline reveal and SVG sequencing

Each helper is idempotent and respects `prefers-reduced-motion` where motion is
involved.
