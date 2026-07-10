---
slug: path-controls
ui_view: UI::PathControl
priority: P2
platforms: [macOS]
hig_page: ../../../apple-hig/pages/path-controls.md
validation_report: ../validation/reports/path-controls.md
---

# UI::PathControl

> A compact file-system breadcrumb that shows where the current document or
> folder lives. On macOS it should read like Finder's path bar: quiet, precise,
> and clearly secondary to the primary content.

## Feel of the flow

Use `UI::PathControl` when location in the file system matters. It belongs in
the window body near document content, inspectors, or file-browser context. It
is not general app navigation, and it should not pretend to be a toolbar.

The HIG treats this as a restrained utility control. The best version feels
effortless: icon-and-name segments, short labels, clear hierarchy, and enough
breathing room that the path can be scanned in one glance.

## Quickstart

```crystal
path = UI::PathControl.new
path.add_component("Projects", icon: "folder")
path.add_component("asset_pipeline", icon: "folder")
path.add_component("README.md", icon: "doc")
path.accessibility_label = "Current file path"
```

Renders as `NSPathControl` on macOS. On iOS and iPadOS, where Apple does not
offer a native equivalent, the library currently falls back to a composed
breadcrumb presentation for previews and portability.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `components` | `Array(UI::PathControl::Component)` | `[]` | Ordered path segments from root to destination. |
| `style` | `UI::PathControlStyle` | `Standard` | `Standard` shows the full breadcrumb; `PopUp` compresses the hierarchy into a menu-style control. |
| `is_editable` | `Bool` | `false` | Reserved for future native affordances such as choose / drag-and-drop behavior. |
| `accessibility_label` | `String?` | `nil` | Spoken summary of the full location path. |

## Light / dark appearance notes

`UI::PathControl` should stay visually calm. Segment labels and icons should
track semantic system colors, separators should stay secondary, and the final
segment can carry slightly more emphasis than the parents. This is not a glass
surface, so the surrounding composition should use ordinary content spacing
rather than overlay treatment.

## What happens on each platform

- **macOS 26**: Native `NSPathControl` rendering path, suitable for document and
  file-browser context in the window body.
- **iOS 26 / iPadOS 26**: No native platform equivalent; the current library
  presents a documented breadcrumb fallback so the hierarchy remains legible in
  shared studies and cross-platform compositions.

## HIG citations (validated)

- Path controls: "A path control shows the file system path of a selected file
  or folder."
- Path controls / Best practices: "Use a path control in the window body, not
  the window frame."
- Path controls / Platform considerations: "Not supported in iOS, iPadOS, tvOS,
  visionOS, or watchOS."

Validation report:
[validation/reports/path-controls.md](../validation/reports/path-controls.md)

## Related

- `UI::OutlineView` for hierarchical file or project trees.
- `UI::NavigationSplitView` for app navigation chrome.
- `UI::PathView` for vector path drawing, which is a different component.
