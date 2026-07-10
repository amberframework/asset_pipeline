---
slug: lists-and-tables
ui_view: UI::ListView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/lists-and-tables.md
validation_report: ../validation/reports/lists-and-tables.md
---

# UI::ListView

> A scrollable vertical list of rows -- rendered as NSStackView on macOS and
> UIStackView on iOS -- presenting text, accessories, and section structure
> with hairline dividers and optional rounded inset-grouped card framing.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

`UI::ListView` is the primary vehicle for text-first hierarchical data on all
Apple platforms. It is not a grid (use `layout: UI::ListLayout::Grid` and see
`collections.md` for that); it is a vertical column of rows where each row
conveys one item in a larger set. Use it when your data is textual, when items
share a common structure, or when you need people to scan a list and select or
navigate into an item.

The HIG shapes for lists-and-tables range from a flat plain list (hairline
dividers, no grouping) to an inset-grouped card (rounded 10pt-radius card with
a slightly elevated background, matching iOS Settings). Choose the shape that
matches your content's information architecture:

- `ListStyle::Plain` for flat streams of homogeneous items.
- `ListStyle::InsetGrouped` for settings-style grouped sections, each section
  presented as a rounded card.
- `ListStyle::Grouped` for sectioned data without the rounded-card treatment.
- `ListStyle::Sidebar` for macOS sidebar navigation lists.

(HIG: "Prefer displaying text in a list or table. A table can include any
type of content, but the row-based format is especially well suited to making
text easy to scan and read." -- Lists and tables / Best practices.)

`UI::ListView` is NOT for image-heavy grids (use `layout: :grid`), for purely
decorative presentations, or for single-item displays.

## Quickstart

```crystal
# -- Plain list with hairline dividers --
plain_row = ->(title : String) do
  row = UI::HStack.new(spacing: 12.0)
  row << UI::Label.new(title)
  row << UI::Spacer.new
  row.as(UI::View)
end

plain_items = [
  plain_row.call("Mail"),
  plain_row.call("Messages"),
  plain_row.call("Notes"),
  plain_row.call("Reminders"),
] of UI::View

section = UI::ListView::Section.new(items: plain_items)
list = UI::ListView.new(sections: [section], style: UI::ListStyle::Plain)
list.shows_separators = true

# -- Inset-grouped card (iOS Settings style) --
settings_row = ->(title : String, trailing : String) do
  row = UI::HStack.new(spacing: 12.0)
  row << UI::Label.new(title)
  row << UI::Spacer.new
  tl = UI::Label.new(trailing)
  tl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
  row << tl.as(UI::View)
  row.as(UI::View)
end

grouped_items = [
  settings_row.call("General", "\u276F"),
  settings_row.call("Appearance", "\u276F"),
  settings_row.call("Sounds & Haptics", "\u276F"),
] of UI::View

grouped_section = UI::ListView::Section.new(
  header: "Settings",
  items: grouped_items
)
grouped_list = UI::ListView.new(
  sections: [grouped_section],
  style: UI::ListStyle::InsetGrouped
)
grouped_list.shows_separators = true
```

Renders: On macOS the outer container is an NSStackView
(NSUserInterfaceLayoutOrientationVertical=1). Hairline dividers are NSBox
instances (boxType=NSBoxSeparator=2). The InsetGrouped card is a layer-backed
NSStackView with cornerRadius=10pt, a 0.5pt border, and an elevated background
(RGBA 0.97 light / 0.20 dark). On iOS the container is a UIStackView
(UILayoutConstraintAxisVertical=1). Separators are 0.5pt UIViews with
UIColor.separatorColor. The InsetGrouped card is a UIView with cornerRadius=10pt
and UIColor.secondarySystemGroupedBackground fill. No Liquid Glass material --
plain list content does not use glass.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `sections` | `Array(Section)` | `[]` | List of sections; each section has an optional `header`, `footer`, and array of `UI::View` row items. Use a single section for a flat list. |
| `style` | `ListStyle` | `Plain` | Visual shape: `Plain` (no grouping), `InsetGrouped` (rounded card per section), `Grouped` (sectioned without card), `Sidebar` (macOS sidebar nav), `Inset` (inset with padding). |
| `layout` | `ListLayout` | `List` | `List` for vertical rows (this component); `Grid` for multi-column grid (see `collections.md`). |
| `columns` | `Int32` | `3` | Number of columns in Grid layout mode. Ignored in List mode. |
| `item_spacing` | `Float64` | `8.0` | NSStackView / UIStackView spacing between arranged subviews in points. Use 0.0 for flush rows (separators provide visual gap). |
| `shows_separators` | `Bool` | `true` | When true, NSBox (macOS) or 0.5pt UIView (iOS) separator lines are inserted between each pair of items within a section. |
| `on_item_tap` | `Proc(Int32, Int32, Nil)?` | `nil` | Callback fired when a row is tapped, receiving section index and item index. Wiring is not yet implemented in the AppKit / UIKit renderers. |

**Theming**: No `UI::Theme` tokens currently drive list row background, separator color, or section header styling. The renderer uses system-derived values directly: `NSColor.separatorColor` / `UIColor.separatorColor` for dividers; `UIColor.secondarySystemGroupedBackground` for the InsetGrouped card fill on iOS; baked RGBA 0.97 / 0.20 for the card fill on macOS. See `foundations/color-and-theming.md`. The `text_color_role` on each row's `UI::Label` children defaults to `LabelRole::Primary` (NSColor.labelColor / UIColor.labelColor).

## Light / dark appearance notes

**macOS light:** NSStackView outer container on white NSColor.windowBackgroundColor.
Row text in NSColor.labelColor (Primary) resolves to near-black (~0.0 RGB). NSBox
separators appear as ~0.78 gray hairlines -- visible but not dominant. Inset-grouped
card RGBA 0.97/0.97/0.97 is barely distinguished from white (0.03 delta), visible
enough to imply card elevation. Trailing accessory labels use baked RGBA 0.55/0.55/0.55
(medium gray, ~4:1 on white). This baked color does NOT adapt to appearance changes;
it is acceptable in light mode.

**macOS dark:** NSStackView outer container on baked RGBA 0.11/0.11/0.11 (HIG_APPEARANCE
env var keyed). NSTextFields inside resolve via `performAsCurrentDrawingAppearance:` so
NSColor.labelColor (Primary) resolves to near-white (~0.92). NSBox separators appear as
subtle lighter lines on DarkAqua -- distinguishable. Inset-grouped card baked RGBA
0.20/0.20/0.20 is visually elevated from 0.11 charcoal (0.09 delta); card border RGBA
0.35/0.35/0.35 clearly outlines the card. Trailing label baked 0.55 gray is legible
against both 0.11 window (~4.5:1) and 0.20 card (~4:1) backgrounds. PASS in dark.

Note: the baked RGBA 0.11 background is a validation-environment workaround (same as
collections, gaps.md iter-21). Production use with a live NSWindow will use NSColor
dynamic system colors which adapt automatically.

**iOS light:** UIColor.systemBackground (white). UILabel text uses UIColor.labelColor
(near-black). UIColor.separatorColor for separator UIViews (0.5pt). UIColor.secondary
SystemGroupedBackground for the InsetGrouped card fill (~RGBA 0.95 in light). The
appearance-adaptive system colors update automatically when the user changes appearance
without requiring re-render.

**iOS dark:** UIColor.systemBackground (near-black ~0.0). UIColor.labelColor resolves
to near-white. UIColor.separatorColor resolves to a visible lighter gray (~0.33 RGBA)
on dark backgrounds. UIColor.secondarySystemGroupedBackground resolves to a slightly
elevated surface (~0.11 RGBA). These all adapt without code changes.

Contrast caveat: the trailing label baked RGBA 0.55/0.55/0.55 is not appearance-adaptive
on iOS. In dark mode it renders as medium gray on near-black, giving ~4:1 contrast.
Acceptable for secondary metadata text, but a brand override that uses a darker brand
gray could fall below 3:1. Prefer using `text_color_role = LabelRole::Secondary` on
trailing labels once the LabelRole path is wired to the trailing label in the row
factory (currently the trailing label must set `text_color_role = nil` and use `text_color`
for the baked RGBA).

**SF Symbol variants:** not currently used. The disclosure chevron (U+276F glyph) is
plain Unicode, not an SF Symbol. When `UI::Image` gains `symbol_name` support (gaps.md
iter-29), the trailing element should use `UI::Image.new(symbol_name: "chevron.right")`
with UIColor.tertiaryLabelColor fill for the HIG-faithful disclosure indicator.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# The primary row labels default to LabelRole::Primary (UIColor.labelColor /
# NSColor.labelColor). This is the correct HIG default and should not change.
# Trailing accessory labels use explicit text_color RGBA. Override to a brand
# secondary color (ensure 4.5:1 contrast on both light and dark backgrounds).
trailing_label = UI::Label.new(trailing_text)
trailing_label.text_color_role = nil  # opt out of adaptive role
trailing_label.text_color = UI::Color.new(r: 0.4, g: 0.5, b: 0.9)  # brand tint
# WARNING: verify contrast on both white and near-black backgrounds before shipping.
```

**Replace the glass material with a flat brand surface.**
```crystal
# UI::ListView does not use Liquid Glass by default -- it uses an opaque
# slightly-elevated card for InsetGrouped and no surface for Plain.
# To use a fully flat brand surface for InsetGrouped, use ListStyle::Plain
# and add your own background via a ZStack or a custom UI::Card wrapper.
# There is no glass to remove on this component.
card_section = UI::ListView::Section.new(items: brand_items)
flat_list = UI::ListView.new(
  sections: [card_section],
  style: UI::ListStyle::Plain  # no card wrapping; flat flush list
)
flat_list.shows_separators = true
```

**Override typography while keeping HIG spacing.**
```crystal
# Row primary labels default to system font 17pt regular (UIFont.systemFont(ofSize: 17)).
# To use a brand font, set the font knob on each UI::Label in the row factory.
# Preserve the HIG-mandated 17pt minimum size for body rows.
row = UI::HStack.new(spacing: 12.0)
title_label = UI::Label.new("General")
title_label.font = UI::Font.new(size: 17.0, weight: :regular, name: "YourBrandFont-Regular")
# name: triggers nsfont_named / UIFont(name:size:) in the renderers.
# Keep size >= 17pt for body text per HIG Dynamic Type Large baseline.
row << title_label.as(UI::View)
row << UI::Spacer.new
```

## Feel recipes
Short examples that map design intent to code.

**"I want a settings-style grouped list like iOS Settings > General"**
Build one `UI::ListView::Section` per HIG group. Set `style: UI::ListStyle::InsetGrouped`
and `shows_separators: true`. Use U+276F in the trailing label for navigation rows,
the current value string for value-display rows. The rendered card is the HIG Settings
inset-grouped shape.

**"I want a plain email-client message list with separators"**
Use `style: UI::ListStyle::Plain`, `shows_separators: true`, `item_spacing: 0.0` (NSBox
separators provide visual rhythm without extra spacing). Each row is a `UI::HStack` with
a subject `UI::Label` and a timestamp `UI::Label` trailing.

## What happens on each platform
- **iOS 26**: UIStackView (UILayoutConstraintAxisVertical=1) outer container. Hairline
  separators are 0.5pt UIViews colored UIColor.separatorColor. InsetGrouped wraps each
  section in a UIView with cornerRadius=10pt and UIColor.secondarySystemGroupedBackground
  fill. No UITableView is emitted -- the validation renderer uses UIStackView throughout.
  Note: HStack rows as arranged UIStackView subviews collapse on iOS in the current
  renderer (deviation 1, iter-31 NEEDS_WORK). Fix pending.
- **iPadOS 26**: Same UIStackView renderer as iOS. On iPad the wider canvas means the
  InsetGrouped card typically insets from the edges (HIG-standard 20pt lateral insets)
  -- the current renderer does not apply lateral insets automatically.
- **macOS 26**: NSStackView (NSUserInterfaceLayoutOrientationVertical=1) outer container.
  NSBox separators (boxType=NSBoxSeparator=2). InsetGrouped wraps each section in a layer-
  backed NSStackView with cornerRadius=10pt and a baked RGBA elevated background. All
  three gallery shapes (plain, inset-grouped, accessory) render correctly on macOS.

## HIG citations (validated)
- Lists and tables -- Best practices: "Prefer displaying text in a list or table.
  A table can include any type of content, but the row-based format is especially
  well suited to making text easy to scan and read."
- Lists and tables -- Style: "Choose a table or list style that coordinates with your
  data and platform. Some styles use visual details to help communicate grouping and
  hierarchy or to provide specific experiences."
- Lists and tables -- Content: "Keep item text succinct so row content is comfortable
  to read. Short, succinct text can help minimize truncation and wrapping, making text
  easier to read and scan."
- Lists and tables -- Platform considerations -- iOS, iPadOS: "Use an info button only
  to reveal more information about a row's content. An info button -- called a detail
  disclosure button when it appears in a list row -- doesn't support navigation through
  a hierarchical table or list. If you need to let people drill into a list or table
  row's subviews, use a disclosure indicator accessory control."
- Lists and tables -- Platform considerations -- macOS: "When it provides value, let
  people click a column heading to sort a table view based on that column."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/lists-and-tables.md](../validation/reports/lists-and-tables.md)

## Related
- `UI::ListView` (grid mode) -- `collections.md` covers `layout: UI::ListLayout::Grid`
  for photo grids and multi-column presentations.
- `recipes/settings-screen.md` -- multi-section InsetGrouped list with navigation
  links and value rows; canonical iOS Settings pattern.
