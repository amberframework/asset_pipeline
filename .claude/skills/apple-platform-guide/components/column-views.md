---
slug: column-views
ui_view: UI::ColumnView
priority: P2
platforms: [macOS, iOS, iPadOS]
hig_page: ../../../apple-hig/pages/column-views.md
validation_report: ../validation/reports/column-views.md
---

# UI::ColumnView

> A Finder-like browser for drilling through nested folders, collections, or
> project structure one column at a time. The default taste should feel calm,
> spatial, and unmistakably directional.

## Feel of the flow

Use `UI::ColumnView` when people are moving through a hierarchy and benefit
from seeing both where they are and what is beside it. This is not a generic
three-pane admin layout. The columns themselves are the navigation model, so
selection, disclosure rhythm, and visible depth all matter.

The best version feels like Finder: measured widths, short labels, obvious
selection, and enough breathing room that the next branch feels inviting rather
than crammed.

## Quickstart

```crystal
library = UI::ColumnView::Item.new("Library", "books.vertical")
library.add_child(UI::ColumnView::Item.new("Design", "paintpalette"))
library.add_child(UI::ColumnView::Item.new("Specs", "doc.text"))

projects = UI::ColumnView::Item.new("Projects", "folder")
amber = UI::ColumnView::Item.new("Amber", "sparkles")
amber.add_child(UI::ColumnView::Item.new("Screenshots", "photo.on.rectangle"))
projects.add_child(amber)

browser = UI::ColumnView.new([library, projects])
browser.selected_indexes = [1, 0]
browser.column_widths = [180.0, 210.0, 220.0]
browser.accessibility_label = "Project browser"
```

Today this renders through a shared composed fallback, which gives us a useful
cross-platform primitive now while leaving room for a future native `NSBrowser`
bridge on macOS.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `items` | `Array(UI::ColumnView::Item)` | `[]` | Top-level items in the browser. |
| `selected_indexes` | `Array(Int32)` | `[]` | One selected index per visible depth. |
| `default_column_width` | `Float64` | `220.0` | Width used when `column_widths` does not specify a depth. |
| `column_widths` | `Array(Float64)` | `[]` | Explicit widths for visible columns. |
| `column_spacing` | `Float64` | `12.0` | Gap between visible columns. |
| `row_spacing` | `Float64` | `4.0` | Vertical rhythm inside a column. |
| `row_padding` | `UI::EdgeInsets` | `6/10/6/10` | Interior padding for each row. |
| `viewport_width` | `Float64` | `0.0` | Preferred visible width for the scrollable browser. |
| `viewport_height` | `Float64` | `320.0` | Preferred visible height for the browser. |
| `shows_disclosure_glyphs` | `Bool` | `true` | Whether rows show a trailing chevron when children exist. |

## Light / dark appearance notes

The browser should stay readable before it becomes expressive. Selection needs
to register at a glance without turning into a loud accent slab, dividers
between columns should remain visible in both appearances, and empty space
around the browser is part of the component's clarity. Dark mode especially
should preserve depth instead of collapsing into one flat charcoal panel.

## Customization / brand override

Keep the interaction model native even when the palette shifts. Brand work
should usually happen in the surrounding composition: quieter backdrops,
slightly warmer neutrals, and curated icons. If you tint the selected row or
change the column fills, keep the hierarchy obvious and the contrast stable in
both appearances. Wide columns and noisy copy make this component feel clumsy
faster than almost anything else.

## What happens on each platform

- **macOS 26**: Currently rendered through the shared composed browser while a
  future native `NSBrowser` bridge remains open.
- **iOS 26 / iPadOS 26**: Rendered through the same composed fallback as a
  structured drill-down study rather than pretending Apple ships a direct iOS
  equivalent.

## HIG citations (validated)

- Column views display hierarchical content in adjacent columns.
- The visible path through the hierarchy should remain easy to scan and easy to
  continue.

Validation report:
[validation/reports/column-views.md](../validation/reports/column-views.md)

## Related

- `UI::OutlineView` for a single-column tree.
- `UI::PathControl` for current-location breadcrumbs.
- `UI::NavigationSplitView` for layouts where navigation and detail sit in
  stable panes.
