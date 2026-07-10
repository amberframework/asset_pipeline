---
title: Preview composition
topic: validation
hig_pages:
  - layout.md
  - visual-design.md
  - materials.md
---

# Preview composition

## What this solves

A validation capture is a component study, not a fake product screenshot. Its
job is to prove that the component reads like an Apple-native control or
surface in light and dark mode. Brand, app chrome, sample content, and backdrop
texture are support acts. If any of them compete with the component, the
preview is failing even when the component code is technically correct.

Use this contract before editing a host factory, writing a validation report,
or asking the design critic to grade a capture. Then choose the concrete screen
shape from `preview-screen-recipes.md`; composition defines the rules, recipes
define the plate to build.

## Stage modes

Pick exactly one stage mode per slug and write it in the validation report.
Default to `isolation`.

| Mode | Use when | Context allowed | Fail if |
|------|----------|-----------------|---------|
| `isolation` | The component can be judged on its own: buttons, labels, controls, text fields, alerts, sheets, activity views, progress, cards. | Neutral backdrop, one focal surface, one quiet support object if glass needs visible bleed-through. | The screenshot reads as a pretend app, tutorial, dashboard, or brand ad. |
| `relationship` | The component needs an anchor, selected source item, source rect, or nearby control to explain its state: popovers, menus, context menus, disclosure, segmented controls. | One anchor object plus the open component. Optional dimming or selection state. | Extra navigation, sidebars, search fields, avatars, chart cards, or unrelated content appear. |
| `app_scene` | The HIG behavior cannot be judged without app structure: sidebars, split views, toolbars, tab bars, navigation bars, lists/tables. | Only the minimum app chrome needed to make the structure legible. | The invented app, brand, or content hierarchy becomes more memorable than the component under review. |

If you choose `relationship` or `app_scene`, document why `isolation` would not
prove the HIG behavior.

## Default taste contract

Every preview is evidence for the default taste of the library. It should look
like an opinionated UI system, not a one-off sample built around the current
slug. Before editing a host factory, decide these five things:

1. Component: what exact HIG component is being proved?
2. State: what meaningful state is shown? Default, selected, expanded, editing,
   destructive, disabled, loading, or mixed-state.
3. Palette roles: which colors represent primary, destructive, success,
   warning, neutral text, separator, surface, and backdrop?
4. Alignment rails: what leading/trailing/center lines govern the title, body,
   icons, rows, and actions?
5. Anatomy: what title, body, controls, icons, separators, and actions are
   required for this component to feel complete?

If those five decisions are not visible in the screenshot, the preview is not
ready for critique.

## Composition numbers

Use the existing platform capture sizes, but compose in points:

- macOS validation frame: 1200 x 900 pt, captured at 2400 x 1800 px.
- iPhone validation frame: use the simulator's point size; keep content inside
  safe areas and at least 16 pt from the horizontal screen edge.
- macOS outer stage margin: 64 pt unless the HIG reference needs an edge-bound
  component.
- iOS horizontal margin: 16-20 pt for phone, 24 pt for regular width.
- Focal component width: 320-560 pt for compact overlays; 560-760 pt for wide
  panels; never stretch a small control just to fill the frame.
- Focal vertical placement: optical center, usually 44-56% down the frame.
  Overlays may sit slightly above center so their lower affordances are visible.
- Focal visual weight: 55-80% of what the eye notices in `isolation`, 45-70%
  in `relationship`, 35-60% in `app_scene`.
- Supporting context: no more than two objects or regions, both lower contrast
  than the focal component.

Use the Apple 8 pt layout grid:

| Token | Use |
|-------|-----|
| 4 pt | Icon/text optical correction, dense inline gaps. |
| 8 pt | Default stack gap, control-internal micro spacing. |
| 12 pt | Compact row gap, popover/menu item rhythm. |
| 16 pt | iOS horizontal padding, compact card padding. |
| 20 pt | macOS default content margin, regular card padding. |
| 24 pt | iPad/regular padding, modal inner padding. |
| 32 pt | Section separation, large group breathing room. |
| 40 pt | Major vertical scene separation. |

Avoid arbitrary 10, 13, 17, 21, 34 pt spacing unless it comes from a native
control or a measured HIG reference. The grid is the default law; optical
corrections need a reason.

## Palette ownership

Use one color system per preview. The default validation color system is:

- Apple semantic neutrals for text, separators, disabled states, focus rings,
  and system materials: `labelColor`, `secondaryLabelColor`, `separatorColor`,
  `systemBackground`, `NSVisualEffectView` / `UIVisualEffectView` materials.
- Amber role colors for visible brand/action semantics:
  - Primary, link, selection, active state: Amber gold `#FFAD33` light /
    `#FFB84D` dark.
  - Destructive and strong emphasis: Plum `#5B3A94` light / `#7D59B8` dark.
  - Success: Sage `#6EAD77` light / `#7EBD87` dark.
  - Warning: Peach `#FF8C5A` light / `#FF9E73` dark.
  - Stage/backdrop base: Cream `#FAF6F0` light / Deep ember `#2A1A08` dark.
- Liquid Glass surfaces use native material first. Brand tint is subtle support,
  never an opaque card fill pretending to be glass.

Raw system blue and raw system red are not acceptable visible action colors in
Amber validation captures. If a native control cannot be themed and exposes one
of those colors, the report must name the exception and the preview must avoid
placing other saturated brand hues beside it. Do not mix blue links, red
destructive buttons, orange primary buttons, and peach warnings in the same
capture.

Palette budget:

- In `isolation`, use one brand accent plus neutral/material colors.
- In `relationship`, use one brand accent and at most one role color.
- In `app_scene`, use one brand accent, one role color, and quiet neutrals.
- Backdrops may have hue variation for glass, but should stay lower saturation
  than interactive controls.
- Dark mode is not an inverted light screenshot. Use the dark role token and
  verify contrast against the actual material/backdrop.

## Text and corners

- Text inside a rounded container must have enough inset that cap height and
  ascenders never appear to touch the curve. Use at least 16 pt horizontal
  padding and 12 pt vertical padding for small cards; 20-24 pt for modal
  surfaces.
- macOS body/control text generally reads at 13 pt; iOS body text generally
  reads at 17 pt. Titles can step up, but should not become marketing hero
  text inside a validation capture.
- Line height should feel native: roughly 1.20-1.35x font size.
- Common radii: 8 pt for small tiles, 10-12 pt for popovers and controls,
  14-16 pt for modal sheets/cards, pill radius for capsule buttons.
- Do not let text sit at top-left default origin inside any rounded or glass
  surface. If you see that, the layout is unfinished.

## Alignment and continuity

Clean previews have a small number of visible rails. Messy previews usually
have too many independent origins.

- Pick one primary leading rail for title, body text, and primary actions.
- Align icons to a fixed icon column; align labels to a text column after the
  icon, not to each icon's optical edge.
- Align separators, row backgrounds, and group insets to the content rail they
  belong to.
- Center modal/sheet/popover groups as a whole. Do not center individual
  children while their text and actions use unrelated rails.
- Use equal row heights inside a group unless the row intentionally contains
  multiline text.
- Use equal tile/card sizes for a state gallery. If one tile needs more text,
  adjust the copy or layout rather than letting the grid stagger.
- Keep adjacent radii from the same family. A 16 pt sheet can contain 8-10 pt
  rows, but avoid random 7/11/18 pt radii in the same composition.
- Controls that perform similar actions should share height, padding, icon
  size, and label weight across macOS and iOS unless the platform native
  control defines a different default.

Alignment is part of taste. If a screenshot feels "sloppy," first look for
unowned rails: text starting at multiple x positions, icons with different
cell sizes, action buttons that do not share a baseline, or cards that almost
but do not quite line up.

## Component anatomy and state

The preview should show the component in its most explanatory default state.
Do not show an empty or inert stub unless the HIG page is specifically about
empty states.

- Name the state: default, selected, expanded, editing, destructive, disabled,
  loading, progress, or mixed.
- Show the state the HIG illustration cares about. Menus/popovers should be
  open; segmented controls should show a selected segment; sheets/alerts should
  show title, body, and action structure.
- Use one primary state per capture. Show a gallery only when the HIG page or
  validation rule requires variants.
- Gallery variants must share the same stage, same width, same alignment rail,
  and same palette budget.
- Use realistic copy lengths that test wrapping and truncation without making
  the preview feel like filler text.
- Button/action order must match platform expectation. Primary and destructive
  roles must be visually distinguishable without introducing off-palette raw
  system colors.
- If a component has a source object, selected item, or anchor, it must be
  visually quieter than the component it explains.

## Backdrops for Liquid Glass

Glass needs something behind it, but that something should be simple enough to
read as a test fixture:

- Prefer broad color fields, a soft gradient, and one or two low-detail shapes.
- Put visible hue/value variation behind glass surfaces so translucency can be
  proven.
- Keep backdrop detail below the component's contrast and saturation.
- Do not add fake product navigation, profile avatars, dashboards, or brand
  lore unless the slug being validated requires those structures.
- Dimming overlays must not bury the backdrop so deeply that glass has nothing
  to sample.

## Brand discipline

Amber is the default accent and content voice, not a mandate to build an Amber
app around every component. In validation captures:

- One quiet brand token is enough: accent color, one label, one source item, or
  one backdrop hue.
- Component semantics come before brand lore.
- Brand color must be semantic. Orange is primary/action, plum is destructive
  or emphasis, sage is success, peach is warning. Do not use color decoratively
  just to make the screenshot feel lively.
- Avoid visible placeholder names, API names, tutorial copy, and invented
  navigation that has no relationship to the HIG component.
- If the first two-second read is "this is an Amber dashboard" instead of
  "this is an activity view", the capture fails.

## Preview preflight

Before capture, answer these out loud in the report or implementation notes:

- Focal: what should the viewer name in two seconds?
- State: what interaction state is shown?
- Palette: which role tokens are visible, and are any raw system colors
  visible?
- Rails: where is the primary leading rail, and what aligns to it?
- Density: does the component feel seated with 8pt-grid padding, or cramped /
  floaty?
- Context: which support objects are present, and what would break if each was
  removed?
- Platform: which differences are native platform differences rather than
  accidental inconsistency?

## Taste loop

For each visual iteration, record the small move and the observed effect:

1. Before: name the visible defect in concrete terms.
2. Target: name the human expectation, such as "text should feel seated inside
   the card" or "glass should show warm backdrop variation through the sheet".
3. Change: list the exact token, file, or native material changed.
4. After: describe the screenshot difference in points, contrast, or hierarchy.
5. Decision: keep, adjust, or revert.

This builds a reusable taste memory. Do not describe the change as "made it
better" without saying what became easier to see, read, or understand.

## Slug examples

- Activity views: `isolation` or `relationship`. Show one quiet source item and
  the share/action surface. Use Amber gold for active/primary affordances and
  plum for destructive action. Do not use a full dashboard behind it.
- Alerts and sheets: `isolation`. Use a backdrop with enough tonal variation
  for glass; the alert/sheet should be the only authored UI. Title, body, and
  actions share a clear text/action rail.
- Popovers and menus: `relationship`. Show one anchor button plus the open
  surface. Keep every other object silent. Menu item icons use one icon column;
  labels use one text column.
- Toolbars, tab bars, sidebars, split views: `app_scene`. The scene exists only
  to prove placement, sizing, hierarchy, and translucency of that structural
  component.
- Buttons, toggles, sliders, steppers, pickers: `isolation`, with 3-5 state
  variants only when the HIG page illustrates state differences.

## Immediate reject conditions

- The supporting environment is more interesting than the component.
- The capture looks like a tutorial, sample app, or unfinished dashboard.
- A rounded/glass surface has text glued to the corner or top-left origin.
- The component could be replaced by another slug and the screenshot would
  still read the same.
- There are more than two unrelated support regions.
- Raw system blue or raw system red appears beside Amber gold/plum without a
  documented native-control exception.
- Multiple saturated hues compete for action semantics.
- Titles, body text, icons, and actions do not share visible alignment rails.
- Brand copy or chrome explains itself more loudly than the HIG behavior.
- The report does not name the stage mode or justify required context.
