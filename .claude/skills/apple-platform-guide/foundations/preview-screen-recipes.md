---
title: Preview screen recipes
topic: validation
hig_pages:
  - layout.md
  - visual-design.md
  - components.md
---

# Preview screen recipes

## Purpose

These recipes define the screens builders must make for HIG validation. Do not
invent a fresh pseudo-app for each slug. Pick the recipe that matches the HIG
component, fill its required anatomy, and capture the same recipe in light and
dark on every supported target platform.

The preview is the product sample for asset_pipeline's default taste. It should
show what a developer gets before adding their own brand. If the screenshot
doesn't make the component obvious, polished, and on-palette in two seconds,
the preview is not done.

## Skip policy

`skipped` is allowed only for:

- Foundations, patterns, platform guides, or collections that are not concrete
  components.
- Components that are not available on any current target platform in this
  project.
- Window-chrome features that cannot be represented in the `UI::View` tree,
  such as true NSWindow/NSPanel controls, unless the host implements a real
  window-level capture for them.

Do not skip an implemented component because its preview is hard. Do not mark a
missing target-platform component as validated. For macOS-only components, make
macOS light/dark captures and use standardized iOS N/A cards only if the
current evidence system requires four files. The report must say
`platform_n_a`, not pretend the iOS card validates the component.

If the HIG page points to a native class on a target platform, the slug is a
real implementation gap until asset_pipeline either implements that native
class or explicitly rejects support. Example: column views map to `NSBrowser`,
so they are macOS-only implementation work, not a successful skip.

## Universal plate rules

All recipes inherit these rules:

- Use the stage contract in `preview-composition.md`.
- Use Amber role colors from `brand/amber.md`, not raw system blue/red, unless
  a native-control exception is named in the report.
- Use the Apple 8 pt grid: 4, 8, 12, 16, 20, 24, 32, 40.
- Name the displayed state in the report.
- Keep one primary leading rail per group. Icons get a fixed icon column;
  labels get a fixed text column; actions get a fixed action rail.
- Show the HIG-interesting state, not an inert empty stub.
- Match the HIG reference silhouette first, then apply Amber taste.
- Do not put visible debug labels like `HIG: <slug>` in captures.

## Recipe A: HIG mirror plate

Use for components whose HIG reference is a simple, specific structure:
action sheets, alerts, sheets, text fields, search fields, labels, progress
indicators, page controls, rating indicators, sliders, steppers, toggles.

Screen:

- `isolation` stage.
- Neutral/glass-test backdrop, no app chrome.
- One component group centered optically.
- Component max width: 320-420 pt on iOS; 360-540 pt on macOS.
- Outer margin: at least 16 pt iOS, 64 pt macOS.

Required anatomy:

- Title or label if the HIG reference has one.
- Body/value/placeholder if the HIG reference has one.
- Visible control state: selected, focused, destructive, disabled, loading, or
  progress where relevant.
- One primary alignment rail.

Example requirements:

- Action sheets: bottom sheet silhouette on iOS; title on one line; destructive
  action first in Plum; one or two regular actions; detached Cancel at bottom;
  dimmed backdrop; no dashboard.
- Text fields: labeled form field with placeholder/value; equal width fields if
  multiple; clear button or trailing affordance where platform expects it;
  visible focus/error/disabled variant only if shown as a small state gallery.
- Page controls: centered dots on a quiet surface; one active dot in Amber gold;
  fixed dot spacing; no unrelated carousel mockup unless needed to show scale.

## Recipe B: Relationship overlay plate

Use for components that need a source object, anchor, selection, or open state:
popovers, menus, context menus, edit menus, pull-down buttons, pop-up buttons,
activity views, disclosure controls.

Screen:

- `relationship` stage.
- One quiet source object plus the open component.
- Source object sits behind or beside the overlay, visually subordinate.
- Overlay/source spacing on 8 pt grid.

Required anatomy:

- Anchor/source object with the selected or invoked state visible.
- Open overlay/menu/sheet state.
- Fixed icon column and label column for menu rows.
- Clear selected/destructive/disabled row treatment if the component supports
  those states.

Example requirements:

- Activity views: one selected source item card, then the activity surface with
  preview/title, destination row, action row, and cancel/dismiss affordance.
  Amber gold marks active/primary affordances; Plum marks destructive actions.
- Context menus: one selected item plus open menu; 4-6 menu items maximum; one
  shared icon column; optional separator between command groups; destructive
  item in Plum.
- Pop-up and pull-down buttons: button remains visible and aligned to the menu;
  menu width is at least the button width; selected/checkmarked item is obvious.

## Recipe C: State gallery plate

Use when the component must prove multiple variants: buttons, toggles,
segmented controls, pickers, sliders, steppers, progress indicators, rating
indicators, color wells.

Screen:

- `isolation` stage.
- A single, polished gallery table/card with 3-6 rows.
- All rows share label rail, control rail, height, and spacing.
- No more than one role color family per row.

Required anatomy:

- Row label, component instance, and optional one-sentence value/status only if
  needed.
- States should be HIG-meaningful: default, primary, selected, disabled,
  destructive, loading, indeterminate.
- Equal row heights unless multiline text is the point of the test.

Example requirements:

- Buttons: default, primary, tinted/secondary, destructive, disabled, icon +
  label. Primary uses Amber gold; destructive uses Plum; no raw blue/red.
- Segmented controls: 3 segments, one selected; same width segments; selected
  state visibly connected to the control, not a loose pill.
- Sliders/steppers: label rail, value rail, control rail; value text aligns
  across rows.

## Recipe D: Form plate

Use for data-entry controls: text fields, secure fields, search fields, combo
boxes, date/time pickers, color pickers, numeric fields, text views.

Screen:

- `isolation` for a standalone form or `app_scene` only if the HIG component is
  a structural form view.
- One grouped form surface, 360-520 pt wide.
- Labels and fields align to predictable rails.
- Vertical row rhythm: 12 pt row gap, 20-24 pt group padding.

Required anatomy:

- Field label outside the field unless the HIG page allows placeholder-only.
- Placeholder or value that demonstrates expected data length.
- Focused or validation state if the component's HIG page discusses it.
- Help/error/status copy uses secondary label color, not decorative accent.

Example requirements:

- Text fields: name/email/password/numeric examples only when needed; equal
  widths for related fields; clear button on iOS where expected; secure field
  obscures text.
- Search fields: search icon, descriptive placeholder, clear/dictation/trailing
  affordance where platform expects it; optional scope chips only when being
  validated.
- Text views: multiline body area with enough text to prove wrapping, padding,
  insertion/focus state, and scroll affordance.

## Recipe E: Structural app plate

Use for components whose HIG behavior is the app structure: sidebars, split
views, navigation stacks, tab bars, tab views, toolbars, lists/tables, outline
views, column views.

Screen:

- `app_scene` stage.
- Minimal app shell only: content exists to prove structure.
- The structural component gets the visual emphasis, not the fake app brand.
- Use a restrained two- or three-region layout with shared rails.

Required anatomy:

- Sidebar/list/column rows with selected state.
- Detail or preview region that proves hierarchy.
- Toolbar/tab/navigation item only if it is the component being validated or
  required to understand placement.
- Resizable/scrollable affordance where HIG calls for it.

Example requirements:

- Column views: macOS-only `NSBrowser`-style plate. Three vertical columns,
  equal column widths, rows with disclosure triangles in parent columns, one
  selected parent, child column populated, final preview/details column for the
  selected leaf. iOS/iPadOS/visionOS/tvOS/watchOS are N/A unless a split-view
  fallback is explicitly being documented.
- Lists and tables: one selected row, headers if table, consistent row height,
  aligned icon/text/value columns, visible scroll context only if needed.
- Toolbars: actual toolbar placement and item groups; primary toolbar action in
  Amber gold only if it is an action, not decoration.

## Recipe F: Content/data plate

Use for components that display content or visualization: collections, image
views, image wells, charts, gauges, web views, maps, video players.

Screen:

- `isolation` or `app_scene` depending on whether the component needs container
  context.
- One content frame with stable aspect ratio.
- Realistic but quiet sample content.
- No fake dashboard unless dashboard structure is the component.

Required anatomy:

- Content title/label only if HIG reference includes it.
- Data labels align to axes/legend/value rails.
- Loading/empty/error state only if it is the state being validated.
- Media/content edges should line up with the container radius and padding.

Example requirements:

- Charts: one chart card; title, axis labels, bars/line, selected value if
  shown; no clipped final data point; Amber gold highlights selected data only.
- Collections: regular grid with equal cell size, consistent gutters, selected
  or focused item if relevant.
- Image views/wells: image respects aspect fit/fill rule; border/radius and
  drag/drop or selected affordance only if HIG calls for it.

## Recipe G: Window/chrome plate

Use only if the validation harness captures real platform chrome: windows,
panels, popovers presented as real windows, document windows, inspectors.

Screen:

- Real NSWindow/NSPanel/UIWindow scene, not a custom card pretending to be
  window chrome.
- Light/dark captures must show platform window controls, shadow/elevation,
  titlebar/toolbar relationship, and active/inactive state when relevant.

Required anatomy:

- Window title/toolbar if HIG reference includes it.
- Active window and optional quieter background window for layering.
- Content inside the window should be minimal and aligned.

If the harness cannot create and capture real window chrome, do not mark the
slug validated. Mark it as a window-level implementation gap and add a
remediation plan.

## What to tell the builder for common failures

- "Make a HIG mirror plate, not an Amber dashboard."
- "Show the HIG-interesting state: open, selected, focused, destructive, or
  filled. Empty controls do not prove taste."
- "Use the same rails across rows; do not let each row invent its own x origin."
- "Replace raw system blue/red with Amber gold/Plum or document the native
  exception and remove competing hues."
- "If the component is platform-inapplicable, create a standardized N/A card
  only for that platform. Do not call it a visual pass."
- "If the component maps to a native class on macOS/iOS, implement that class
  or leave the row pending. Do not skip it as taste-complete."
