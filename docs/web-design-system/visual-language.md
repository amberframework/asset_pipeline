# Visual Language

This is the aesthetic contract for the design-system web proof. It gives
future agents a taste target, not just a list of components.

## Position

The default visual system should feel like a serious product system for Crystal and Asset Pipeline teams:
fast, precise, warm, and operational. It should not read as a generic Bootstrap
skin, a utility-class demo, or an orange-black brand exercise.

The demo uses Frontloader Studio as the product frame because SaaS workflows
force the system to show dense tables, forms, command surfaces, chat, pricing,
payment, timelines, and page sections in context.

## Palette

The warm amber accent is part of the default theme, not the component identity.

- Warm accent color carries identity, primary action, selected states, and important
  connective details.
- Ink and paper surfaces carry the product chrome so the interface stays calm
  under repeated use.
- Teal and cyan signal operational intelligence, analysis, and live system
  behavior.
- Semantic status colors are coordinated token groups, not one-off red, green,
  or yellow utilities.
- Dark mode keeps the same hierarchy as light mode instead of inverting the
  page into a novelty theme.

## Typography

The proof pairs a readable sans face with an editorial display face.

- The sans stack owns controls, tables, forms, metadata, and dense product UI.
- The display face is reserved for hero and section-level moments where the
  product needs voice.
- Letter spacing stays at `0` so the system does not use tracking as decoration.
- Type scales are bounded by component context; buttons, tables, and panels do
  not inherit hero-scale type.

## Layout

Pages should feel designed around work, not around marketing blocks.

- Repeated items can be cards, but sections should be full-width layouts or
  unframed compositions.
- Dense surfaces such as dashboards use scan-friendly grouping, aligned edges,
  and stable dimensions.
- Page sections use dividers, bands, timelines, heatmaps, and parallax-style
  layers to make structure visible without turning every section into a card.
- Mobile layouts preserve the same content hierarchy and avoid hiding the proof
  behind a narrow "mobile simplified" version.

## Motion

Motion should communicate cause and continuity.

- Sticky hover feels physical: entry bumps in the direction of travel, movement
  follows the cursor, and exit tugs after the cursor before settling.
- Timeline and SVG sequencing imply time passing without blocking reading.
- Tables, charts, tabs, carousel, dialog, and validation feedback animate only
  where the state change benefits from continuity.
- `prefers-reduced-motion` is a first-class state. The proof removes dependency
  on transitions and sequencing while preserving the resulting state.

## Accessibility As Taste

Accessibility is not only compliance. It is part of the polish.

- Native HTML semantics come before JavaScript behavior.
- Every control has an accessible name.
- Errors are visible, connected with `aria-describedby`, and reflected with
  `aria-invalid`.
- Dialog, command palette, carousel, tabs, chat, tables, and charts keep
  semantic roles and fallback data paths.
- Automated evidence uses static checks, Chrome accessibility-tree snapshots,
  axe-core, IBM Equal Access, keyboard traversal, touch-target, contrast, and
  reduced-motion reports.

## Component Expression

Components expose semantic variants and token-backed compatibility selectors.

- Buttons express tone, emphasis, size, disabled, loading, and selected states.
- Cards express content hierarchy and selected/raised states without exposing
  `.card-body` as the API.
- Tables use row indicators, subtle status backgrounds, richer hover, smooth
  state transitions, and accessible row semantics.
- Forms use browser-native validation attributes first, then vanilla helpers for
  password matching, payment formatting, Luhn validation, expiry checks, promo
  status, and visible error messaging.
- Charts are first-party SVG for simple cases and keep a table as the accessible
  source of truth.

## Non-Goals

- No Node build pipeline for the demo.
- No Stimulus as the Milestone 1 interaction model.
- No hard chart dependency in the canonical path.
- No Bootstrap-shaped `.btn`, `.btn-primary`, `.card`, `.card-body`, or
  `.form-control` classes as the canonical design-system direction.
