---
slug: status-bars
ui_view: UI::StatusBars
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/status-bars.md
validation_report: ../validation/reports/status-bars.md
---

# UI::StatusBars

> System-owned status-bar policy for iPhone and iPad, plus a small macOS
> status-item helper for shell utilities. The visible chrome still belongs to
> the OS; asset_pipeline now exposes the app's preference instead of faking a
> rendered status bar.

## Feel of the flow

On iPhone and iPad, the status bar is system-controlled. What the app owns is
its preference for light or dark content and whether the bar should hide during
an immersive task. On macOS, lightweight shell state often lives in a status
item rather than in the content tree, so the shard also exposes `UI::StatusBar`
for that case.

## Quickstart

```crystal
appearance = UI::StatusBarAppearance.new(
  style: UI::StatusBarContentStyle::LightContent,
  hidden: false
)

UI::StatusBars.apply(appearance)
```

```crystal
status_item = UI::StatusBar.new(
  identifier: "sync",
  title: "Sync",
  icon: "arrow.triangle.2.circlepath",
  tooltip: "Sync status"
)

status_item.with_menu do |menu|
  menu.add_item("Pause Sync")
  menu.add_item("Open Activity")
end

status_item.install
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `StatusBarAppearance#style` | `UI::StatusBarContentStyle` | `Default` | App preference for light/dark status-bar content on iOS/iPadOS. |
| `StatusBarAppearance#hidden` | `Bool` | `false` | Whether the top system bar should be hidden. |
| `StatusBarAppearance#animated` | `Bool` | `true` | Whether the host should animate the visibility transition. |
| `StatusBar#identifier` | `String` | `"status-item"` | Stable identifier for a macOS status item. |
| `StatusBar#title` / `#icon` | `String?` | `nil` | Optional label or SF Symbol name for the macOS status item. |
| `StatusBar#tooltip` | `String?` | `nil` | Optional hover text for the macOS status item. |
| `StatusBar#menu` | `UI::ContextMenu?` | `nil` | Optional attached shell menu for the macOS item. |

## What happens on each platform

- **iOS / iPadOS**: `UI::StatusBars.apply` updates the host controller's
  status-bar preference. The bar itself remains system-owned.
- **macOS**: `UI::StatusBar#install` now wires a shell item into
  `NSStatusBar.systemStatusBar`, with an attached `NSMenu` when a menu is
  present.
- **Validation**: Skipped for screenshots because the status item belongs to
  the OS shell, not the in-app view tree.

## HIG citations (validated)

- Let the system own the visible status bar chrome.
- Keep status-item surfaces compact and focused.
