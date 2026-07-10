---
slug: outline-views
ui_view: UI::OutlineView
priority: P2
platforms: [macOS, iOS, iPadOS]
hig_page: ../../../apple-hig/pages/outline-views.md
validation_report: ../validation/reports/outline-views.md
---

# UI::OutlineView

> A hierarchical browser for grouped content, settings, or project structure.
> The default taste should feel like a calm sidebar tree: obvious depth,
> disciplined indentation, and a clear current selection.

## Feel of the flow

Reach for `UI::OutlineView` when people need to move through a nested structure
without losing context. Good outline views behave like Finder, Mail, or System
Settings sidebars: the hierarchy is always readable, expansion is predictable,
and the selected row anchors the eye.

This is not a generic list with a few arrows sprinkled in. The hierarchy itself
is the experience, so indentation, disclosure rhythm, and row spacing matter.

## Quickstart

```crystal
outline = UI::OutlineView.new
drafts = UI::OutlineView::Node.new("Drafts", "doc.text", "3", true, [] of UI::OutlineView::Node, true)
drafts.add_child(UI::OutlineView::Node.new("Landing page", "square.and.pencil"))
drafts.add_child(UI::OutlineView::Node.new("Release notes", "note.text"))

outline.add_root(UI::OutlineView::Node.new("Inbox", "tray", "12"))
outline.add_root(drafts)
outline.accessibility_label = "Project outline"
```

Today the library renders this through a composed cross-platform fallback tree.
That gives us a real hierarchical primitive now, while leaving room for a
future native `NSOutlineView` bridge on macOS.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `roots` | `Array(UI::OutlineView::Node)` | `[]` | Top-level branches in the tree. |
| `row_spacing` | `Float64` | `4.0` | Vertical rhythm between visible rows. |
| `indent_width` | `Float64` | `18.0` | Additional leading inset per tree depth. |
| `row_padding` | `UI::EdgeInsets` | `6/10/6/10` | Interior padding for each visible row. |
| `viewport_width` | `Float64` | `0.0` | Preferred visible width for the scrollable tree. |
| `viewport_height` | `Float64` | `320.0` | Preferred visible height for the tree viewport. |
| `shows_disclosure_glyphs` | `Bool` | `true` | Whether branch rows render disclosure glyphs. |

## Light / dark appearance notes

The hierarchy needs to stay legible before it looks decorative. Selected rows
should feel obvious but not loud, disclosure glyphs should remain visible at a
glance, and secondary metadata should recede without disappearing. Dark mode in
particular should preserve depth and selection without turning into a flat slab
of identical rows.

## What happens on each platform

- **macOS 26**: Currently rendered through the composed fallback tree while the
  future native `NSOutlineView` bridge remains open.
- **iOS 26 / iPadOS 26**: Rendered through the same composed fallback, which
  gives the shard a portable hierarchical browser without inventing a fake
  Apple control that does not exist.

## HIG citations (validated)

- Outline views: use them to "display hierarchical data."
- The hierarchy should remain easy to scan, expand, and navigate without losing
  context about the current branch.

Validation report:
[validation/reports/outline-views.md](../validation/reports/outline-views.md)

## Related

- `UI::ListView` for flat collections.
- `UI::PathControl` for current-location breadcrumbs.
- `UI::NavigationSplitView` for layouts that pair hierarchy with detail content.
