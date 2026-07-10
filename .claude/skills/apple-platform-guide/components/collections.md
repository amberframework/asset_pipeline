---
slug: collections
ui_view: UI::ListView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/collections.md
validation_report: ../validation/reports/collections.md
---

# UI::ListView (collections)

> A collection manages an ordered set of content in a customizable, highly
> visual layout -- typically an image grid or document tile grid. On iOS 26
> and macOS 26, UI::ListView in grid mode approximates NSCollectionView /
> UICollectionView via a row-of-rows NSStackView / UIStackView. No Liquid
> Glass material is applied to the grid surface itself; items render on the
> plain window background.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Collections are the right primitive when you have a set of visually uniform
content items -- photos, document tiles, app icons, song cards -- that
benefit from a 2D grid layout rather than a linear list. The grid layout
emphasizes visual scanning over linear reading: the eye moves across rows
looking for a shape or thumbnail, not reading top-to-bottom through text.

Do not use a collection for primarily textual content. The HIG is explicit:
"Consider using a table instead of a collection for text. It's generally
simpler and more efficient to view and digest textual information when it's
displayed in a scrollable list." For text, reach for UI::ListView in its
default list layout (or the dedicated `lists-and-tables` slug). For
image-dominant browsing, use `layout: UI::ListLayout::Grid` with an
appropriate column count.

(HIG: "Use the standard row or grid layout whenever possible. Collections
display content by default in a horizontal row or a grid, which are simple,
effective appearances that people expect." -- Collections / Best practices.)

## Quickstart

```crystal
# Build a 3-column photo tile grid.
# Each tile is a VStack with a thumbnail placeholder and a caption.
make_tile = ->(caption : String) do
  tile = UI::VStack.new(spacing: 4.0)
  thumb = UI::Label.new("[photo]")
  thumb.font = UI::Font.new(size: 28.0, weight: :regular)
  thumb.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
  cap = UI::Label.new(caption)
  cap.font = UI::Font.new(size: 11.0, weight: :regular)
  cap.text_color = UI::Color.new(r: 0.45, g: 0.45, b: 0.45)
  tile << thumb.as(UI::View)
  tile << cap.as(UI::View)
  tile.as(UI::View)
end

tiles = [
  make_tile.call("Big Sur"), make_tile.call("Morning"), make_tile.call("Trail"),
  make_tile.call("Coffee"),  make_tile.call("Sunset"),  make_tile.call("Coast"),
  make_tile.call("Forest"),  make_tile.call("Lake"),    make_tile.call("City"),
]

section = UI::ListView::Section.new(header: "Photos", items: tiles)
list = UI::ListView.new(
  sections: [section],
  style: UI::ListStyle::Plain,
  layout: UI::ListLayout::Grid,
  columns: 3,
)
list.item_spacing = 10.0
list.shows_separators = false
```

Renders: on macOS, a vertical NSStackView containing horizontal row
NSStackViews with NSStackViewDistributionFillEqually (equal-width columns).
On iOS, a vertical UIStackView containing horizontal row UIStackViews with
UIStackViewDistributionFillEqually. Both produce a 3-column grid with 10pt
cell spacing. No Liquid Glass material is applied.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `sections` | `Array(UI::ListView::Section)` | `[]` | Ordered sections; each contributes an optional header label then its items in order. |
| `style` | `UI::ListStyle` | `ListStyle::Plain` | Reserved for future chrome selection (grouped, inset, sidebar); currently advisory -- renderers emit a plain stack regardless. |
| `layout` | `UI::ListLayout` | `ListLayout::List` | `List` for vertical rows; `Grid` for multi-column row-of-rows. Set to `Grid` for collections. |
| `columns` | `Int32` | `3` | Number of columns in grid mode. Ignored in list mode. Typical HIG photo grids use 2-4 columns. |
| `item_spacing` | `Float64` | `8.0` | Gap in points between grid cells (both horizontal and vertical). Ignored in list mode. |
| `shows_separators` | `Bool` | `true` | Advisory; renderers do not yet draw hairlines between rows (planned). |
| `on_item_tap` | `Proc(Int32, Int32, Nil)?` | `nil` | Callback with (section_index, item_index) when a row is tapped. |
| `Section#header` | `String?` | `nil` | Section header text; emitted as UILabel / NSTextField above the section items. |
| `Section#items` | `Array(UI::View)` | `[]` | The tile/row views. Any UI::View is legal -- typically VStack for grid tiles. |
| `Section#footer` | `String?` | `nil` | Reserved -- renderers do not yet emit footer labels. |

**Theming**: the outer NSStackView / UIStackView receives an explicit
layer background in macOS dark mode keyed off `HIG_APPEARANCE` (baked RGBA
0.11/0.11/0.11 dark, 1.0/1.0/1.0 light). In production the list background
typically comes from the parent window or scroll view. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

`UI::ListView` in grid mode is a content component, not a surface component.
It carries no Liquid Glass material. Light and dark behavior:

**macOS light:** outer NSStackView has layer.backgroundColor = RGBA
1.0/1.0/1.0 (white). NSTextField tile labels use NSColor.labelColor which
resolves to near-black (~0.0 RGB) in light via performAsCurrentDrawingAppearance:
in window_helper.m. Tile placeholder label and caption label both legible.

**macOS dark:** outer NSStackView has layer.backgroundColor = RGBA
0.11/0.11/0.11 (charcoal), baked from HIG_APPEARANCE env var at render time
(gaps.md iteration-21 pattern). NSTextField tile labels resolve NSColor.labelColor
to white via performAsCurrentDrawingAppearance:, giving ~21:1 contrast against
the charcoal background. Section header also white. All tiles legible. Caution:
caption labels set with explicit baked RGBA (r:0.45 g:0.45 b:0.45) do not
adapt in dark -- they render near-white rather than UIColor.secondaryLabel
equivalent. If brand captions feel too bright in dark, wire the label through
`text_color_role: UI::LabelRole::Secondary` instead of an explicit RGBA.

**iOS light:** UIStackView with UIColor.systemBackground window (white). UILabel
tile text uses UIColor.label (near-black). Caption labels use explicit RGBA
which is mid-gray (~4:1 contrast in light). Grid legible.

**iOS dark:** UIStackView tracks UIColor.systemBackground (near-black in dark).
UILabel tile text resolves UIColor.label to white (~21:1 contrast). Caption
labels set with explicit RGBA render near-white in dark (same issue as macOS).
Grid fully legible; caption contrast slightly high for secondary-text intent.

**SF Symbols:** Not used by this component in the default configuration.
If tiles embed an icon (e.g. UI::Image with an SF Symbol name), the icon
inherits the tile label's text color. Use the `.hierarchical` rendering mode
for multi-color icons in grid tiles.

**Contrast caveat:** tile caption labels set with explicit `text_color` RGBA
do not automatically adapt between light and dark. Always test caption
contrast in both appearances. For appearance-adaptive secondary text, leave
`text_color` unset and assign `text_color_role: UI::LabelRole::Secondary`
which routes through NSColor.secondaryLabelColor / UIColor.secondaryLabel.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.05, g: 0.42, b: 0.72)  # brand blue
# Affects selection highlight and any tinted controls inside tiles.
# Hit targets (44pt on iOS), grid spacing, and typography should stay HIG-default.
```

**Replace the grid background with a flat brand surface.**
```crystal
# UI::ListView is not a glass-backed surface, so "replace glass" means
# controlling the parent container's background. Place the list inside a
# UI::Card with a custom fill color to create a branded tile container:
#
# card = UI::Card.new(grid_list.as(UI::View))
# card.background_color = UI::Color.new(r: 0.95, g: 0.93, b: 0.98)  # brand tint
#
# This replaces the plain window background but retains HIG grid spacing
# and column distribution. Warn: removing the window background entirely
# (setting a dark tile surface in light mode) will require manually baking
# text colors to maintain legibility -- do not mix opaque brand surfaces
# with adaptive system label colors without testing both appearances.
```

**Override typography while keeping HIG spacing.**
```crystal
# Set tile label font via UI::Font.new -- the system font family is "system".
# Keep 11pt for captions (HIG minimum readable size for labels) and
# 17pt for primary text. Spacing between tiles is driven by item_spacing,
# not font metrics, so changing font size does not break the grid geometry.
thumb_label.font = UI::Font.new(family: "YourBrand-Display", size: 28.0, weight: :regular)
cap_label.font   = UI::Font.new(family: "YourBrand-Text",    size: 11.0, weight: :regular)
```

## Feel recipes
Short examples that map design intent to code.

**"I want a 2-column document tile grid instead of 3 columns"**
-> Set `columns: 2` on the UI::ListView constructor and `item_spacing: 12.0`
   to give each tile more horizontal breathing room. HIG: "Use adequate
   padding around images to keep focus or hover effects easy to see."

**"I want a flat list of labeled items, not a grid"**
-> Set `layout: UI::ListLayout::List` (the default) and build each item as
   a UI::HStack with a primary label + UI::Spacer + secondary label.
   See the `lists-and-tables` component doc for that pattern.

## What happens on each platform
- **iOS 26**: vertical UIStackView containing horizontal UIStackViews
  (UIStackViewDistributionFillEqually) for each grid row. item_spacing
  maps to UIStackView.spacing on both axes. In production, this should
  be replaced by UICollectionView with UICollectionViewFlowLayout for
  proper scroll virtualization and cell reuse.
- **iPadOS 26**: same as iOS 26. Consider increasing `columns` to 4-5
  on iPad to use the wider canvas, matching HIG illustration's 4-column
  layout.
- **macOS 26**: vertical NSStackView containing horizontal NSStackViews
  (NSStackViewDistributionFillEqually=2) with wantsLayer=YES and baked
  background fill. In production, this should be replaced by
  NSCollectionView with NSCollectionViewFlowLayout.

## HIG citations (validated)
- Collections -> Best practices: "Use the standard row or grid layout
  whenever possible. Collections display content by default in a horizontal
  row or a grid, which are simple, effective appearances that people expect.
  Avoid creating a custom layout that might confuse people or draw undue
  attention to itself."
- Collections -> Best practices: "Consider using a table instead of a
  collection for text. It's generally simpler and more efficient to view
  and digest textual information when it's displayed in a scrollable list."
- Collections -> Best practices: "Make it easy to choose an item. If it's
  too difficult to get to an item in your collection, people will get
  frustrated and lose interest before reaching the content they want. Use
  adequate padding around images to keep focus or hover effects easy to see
  and prevent content from overlapping."
- Collections -> Best practices: "Consider using animations to provide
  feedback when people insert, delete, or reorder items. Collections
  support standard animations for these actions, and you can also use
  custom animations."
- Collections -> Platform considerations -> iOS, iPadOS: "Use caution when
  making dynamic layout changes. The layout of a collection can change
  dynamically. Be sure any changes make sense and are easy to track. If
  possible, try to avoid changing the layout while people are viewing and
  interacting with it, unless it's in response to an explicit action."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/collections.md](../validation/reports/collections.md)

## Related
- `UI::Card` -- reach for a Card when you want a single grouped surface
  with a title, not an ordered set of peer tiles.
- `UI::VStack` -- reach for a VStack when the items are heterogeneous and
  not conceptually an ordered set; UI::ListView signals "these items belong
  to the same category."
- `lists-and-tables` -- use UI::ListView in default List layout for
  text-dominant rows (settings, recent items, search results).
