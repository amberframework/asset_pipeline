---
slug: windows
ui_view: UI::Windows
priority: P2
platforms: [macOS, iPadOS, iOS]
hig_page: ../../../apple-hig/pages/windows.md
validation_report: ../validation/reports/windows.md
---

# UI::Windows

> A practical top-level window configuration service for host apps. It keeps
> the title, subtitle, sizing, and titlebar style intent in one place and can
> now apply that configuration to the current host window on Apple platforms
> without pretending that the shard owns the OS shell itself.

## Feel of the flow

Apple's HIG windows are the shell around an app, not an in-app component.
That means the shard should offer a clear configuration object that host apps
can use immediately while the actual `NSWindow` / `UIWindow` bridge remains
system-owned.

`UI::Windows` is that seam in the public API. It is useful today because it
lets macOS and iOS host code express window intent consistently:

- what the top-level window should be called
- whether it needs a supporting subtitle
- how large it wants to be
- which titlebar presentation it expects on macOS

The service is intentionally small and honest. It does not try to fake the
window chrome as an in-app card. It keeps the window intent close to the
scene or document code that owns it and applies that intent through the native
bridge where the host can support it.

## Quickstart

```crystal
window = UI::Windows.configure(
  title: "Asset Pipeline",
  subtitle: "Preview shell",
  preferred_width: 1280.0,
  preferred_height: 860.0,
  minimum_width: 960.0,
  minimum_height: 720.0,
  titlebar_style: UI::WindowTitlebarStyle::UnifiedCompact,
  shows_toolbar: false
)

window.display_title      # "Asset Pipeline — Preview shell"
window.size_summary       # "1280.0 x 860.0"
window.titlebar_style     # UI::WindowTitlebarStyle::UnifiedCompact
window.apply              # true on supported Apple hosts
```

## Customization / brand override

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `title` | `String` | required | Primary window title shown in the titlebar or app shell. |
| `subtitle` | `String?` | `nil` | Optional secondary line for document or window context. |
| `preferred_width` / `preferred_height` | `Float64?` | `nil` | Suggested starting size for the top-level window. |
| `minimum_width` / `minimum_height` | `Float64?` | `nil` | Lower bounds for window sizing. |
| `maximum_width` / `maximum_height` | `Float64?` | `nil` | Upper bounds for window sizing. |
| `titlebar_style` | `UI::WindowTitlebarStyle` | `Standard` | Describes the intended titlebar chrome on macOS. |
| `shows_titlebar` | `Bool` | `true` | Whether the window should expose a visible titlebar. |
| `shows_toolbar` | `Bool` | `true` | Whether the shell expects a toolbar region. |
| `allows_full_screen` | `Bool` | `true` | Whether the shell should allow full-screen behavior. |
| `resizable` | `Bool` | `true` | Whether the window should be user-resizable. |

## Light / dark appearance notes

The configuration itself does not render, so there is no color treatment to
validate here. The important taste constraint is structural: use short titles,
keep subtitles secondary, and keep the requested size honest so the host shell
does not balloon into something that feels accidental.

## What happens on each platform

- **macOS 26**: The bridge applies title, subtitle, size constraints,
  title-visibility hints, and toolbar/full-screen behavior to the current
  `NSWindow`.
- **iPadOS 26 / iOS 26**: The bridge can still apply top-level title intent
  and preferred content size to the active controller scene, even though the
  visible shell remains system-owned.

## HIG citations (validated)

- Windows are the shell around the app.
- The title should be clear and concise.
- Window sizing should support the task instead of fighting it.

Validation report:
[validation/reports/windows.md](../validation/reports/windows.md)

## Related

- `UI::Panel` for auxiliary inspector-style surfaces.
- `UI::Sheet` for modal secondary tasks.
- `UI::Windows.configure` for host-level window intent.
