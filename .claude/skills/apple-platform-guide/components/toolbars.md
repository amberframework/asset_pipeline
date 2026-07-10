---
slug: toolbars
ui_view: UI::Toolbar
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/toolbars.md
validation_report: ../validation/reports/toolbars.md
---

# UI::Toolbar

> A horizontal strip of icon-action items that provides convenient access to frequently used
> commands, navigation, and search; backed by a Liquid Glass NSVisualEffectView (macOS 26) or
> UIGlassEffect / UIBlurEffect.systemChromeMaterial (iOS 26) surface by default.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A toolbar lives at the top of a macOS window (NSToolbar zone, below or integrated with the title
bar) or near the bottom of an iOS screen (UIToolbar). Its purpose is fast access to the commands
people use most in the current context -- not navigation between top-level app areas (that is
Tab bars) and not per-item actions in a list (those belong in context menus or swipe actions).

Reach for UI::Toolbar when the view has a consistent set of 3-7 actions that operate on the
content of that view -- composing, archiving, sharing, filtering, searching. Do NOT put global
navigation (app-level back/forward) in a toolbar unless the platform pattern explicitly calls for
it (macOS document browser, iOS navigation bar accessory).

(HIG: "Choose items deliberately to avoid overcrowding. People need to be able to distinguish and
activate each item, so you don't want to put too many items in the toolbar." -- Toolbars / Best
practices.)

## Quickstart

```crystal
# Document app toolbar -- macOS style
toolbar = UI::Toolbar.new("Document")
toolbar.shows_title = true
toolbar.accessibility_label = "Document toolbar"

# Group 1: Sidebar toggle
toolbar.add_item("sidebar-toggle", "Toggle Sidebar", "sidebar.leading")
toolbar.add_item("sep1", "---", nil)  # visual separator between groups

# Group 2: Navigation
toolbar.add_item("back",    "Back",    "chevron.backward")
toolbar.add_item("forward", "Forward", "chevron.forward")
toolbar.add_item("sep2",    "---",     nil)

# Group 3: Actions
toolbar.add_item("share",  "Share",  "square.and.arrow.up")
toolbar.add_item("search", "Search", "magnifyingglass")
toolbar.add_item("more",   "More",   "ellipsis.circle")
```

```crystal
# iOS bottom toolbar -- Mail-style action bar
ios_toolbar = UI::Toolbar.new
ios_toolbar.accessibility_label = "Mail action toolbar"

ios_toolbar.add_item("compose", "Compose", "square.and.pencil")
ios_toolbar.add_item("archive", "Archive", "archivebox")
ios_toolbar.add_item("sep1",    "---",     nil)
ios_toolbar.add_item("flag",    "Flag",    "flag")
ios_toolbar.add_item("trash",   "Delete",  "trash")
ios_toolbar.add_item("reply",   "Reply",   "arrowshape.turn.up.left")
```

Renders: on macOS, an NSVisualEffectView (material: NSVisualEffectMaterialMenu = 10, tracks
appearance) containing a horizontal NSStackView of borderless NSButtons with SF Symbol images;
on iOS 26, a UIVisualEffectView (UIGlassEffect / UIBlurEffect.systemChromeMaterial) containing
a horizontal UIStackView of UIButtons with SF Symbol images and 44x44pt hit targets.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `title` | `String?` | `nil` | Title text shown at the leading edge when `shows_title` is true; also sets the accessibility label if `accessibility_label` is not set. |
| `shows_title` | `Bool` | `true` | Whether the `title` string is rendered as a leading NSTextField/UILabel. Set to `false` when the title would be redundant with a window/navigation bar title. |
| `items` | `Array(ToolbarItem)` | `[]` | The ordered list of action items. Use `add_item(id, label, icon)` to append. Items with `id == "---"` render as visual separators between groups. |
| `accessibility_label` | `String?` | `nil` (inherits from `UI::View`) | Accessibility label for the toolbar container; announced by VoiceOver when focus enters the toolbar region. |

`ToolbarItem` fields:

| Field | Type | Effect |
|-------|------|--------|
| `id` | `String` | Identifier for the item; use `"---"` to emit a group separator. |
| `label` | `String` | Accessibility label for the button; shown as button title when no `icon` is provided. |
| `icon` | `String?` | SF Symbol name (e.g. `"square.and.pencil"`). Preferred over text labels per HIG. |
| `action` | `Proc(Nil)?` | Optional callback (supply via `add_item` block form). |

**Theming**: `UI::Theme.primary` (system blue) drives the icon tint color when an explicit
`tint_color` is not set. `UI::Theme.font_family` and `UI::Theme.font_size_caption` drive the
fallback text label rendering. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

The Liquid Glass surface is the key appearance-sensitive element in UI::Toolbar.

**macOS light appearance:**
NSVisualEffectMaterial.menu (material 10) on a white/light window background produces a subtly
frosted glass strip. The material is appearance-tracking: in light mode it yields a
slightly-cooler-than-white frosted fill (~0.93 RGB) with a glass-edge highlight at the pill
boundary. SF Symbol icons use NSColor.labelColor which resolves to near-black (~0.07 RGB) in
light, providing ~15:1 contrast on the frosted surface. Title text (13pt Bold) also uses
NSColor.labelColor. No explicit color token is set on the icons -- the NSButton image tint
defaults to the control tint (system blue for interactive icons, or labelColor for neutral icons).

**macOS dark appearance:**
Same NSVisualEffectMaterial.menu tracks DarkAqua appearance automatically. The frosted glass
strip reads as ~0.22 RGB (significantly lighter than the DarkAqua window at ~0.12 RGB),
unambiguously showing translucency. NSColor.labelColor dark variant (~0.95 RGB near-white)
maintains high contrast on the darker frosted surface (~15:1). No manual dark-mode color logic
is required; the material handles it.

**iOS light appearance:**
UIGlassEffect (iOS 26) / UIBlurEffectStyleSystemChromeMaterial (11, iOS 15+ fallback) produces
a lightly frosted white glass pill. Icon buttons use UIColor.systemBlue (~0.0/0.478/1.0 in
light) which is the correct tint color for toolbar items. Each UIButton's SF Symbol image
inherits the button tint color automatically.

**iOS dark appearance:**
UIGlassEffect dark-frosted material produces a ~0.18 RGB dark pill over the black UIViewController
background -- clearly distinct from the background, confirming backdrop bleed-through.
UIColor.systemBlue dark variant (~0.039/0.518/1.0) provides adequate contrast against the darker
glass surface. The material variant is chosen automatically by UIVisualEffectView when the
window's `overrideUserInterfaceStyle` (or the system appearance) is `.dark`.

**SF Symbol rendering:**
Icons are loaded via `NSImage.imageWithSystemSymbolName:accessibilityDescription:` (macOS) and
`UIImage.systemImageNamed:` (iOS). Both load the default outline variant. The HIG recommends
filled symbols for items that have a selected state; use `icon_name + ".fill"` in the item's
icon string when you want the filled variant (e.g. `"flag.fill"` for a flagged-active state).

**Contrast caveat:**
If `UI::Theme.primary` is overridden to a very light color (near-white or pale yellow), the
icon tint may become low-contrast against the light frosted glass surface in light mode. Keep
the primary token at a luminance that satisfies 3:1 against the frosted glass background color.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's legibility,
hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override the global accent that drives the icon tint.
# The toolbar's glass material stays HIG-default; only the icon color changes.
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.91, g: 0.26, b: 0.21)  # brand red

# What to keep HIG-default: hit targets (44pt iOS, 28pt macOS), spacing,
# glass material, SF Symbols without borders.
# What can change: tint color on icon buttons.
toolbar = UI::Toolbar.new("Inbox")
toolbar.add_item("compose", "Compose", "square.and.pencil")
```

**Replace the glass material with a flat brand surface.**
```crystal
# There is no surface_style knob on UI::Toolbar in the current implementation.
# To render a flat toolbar (no glass), subclass UI::Toolbar and override the
# AppKit renderer visit method to use a plain NSView with a solid fill instead
# of NSVisualEffectView. WARNING: removing Liquid Glass eliminates the system-
# provided translucency and may make the toolbar visually jarring against
# content, especially at scroll edge. HIG Best practices warn: "Any custom
# backgrounds and appearances you use might overlay or interfere with background
# effects that the system provides." Use solid fills only when your brand
# identity explicitly requires an opaque toolbar (e.g. a brand-colored band).
#
# Simplest approach: set a tinted background using GlassBackground with a
# custom color rather than disabling glass entirely.
glass_bg = UI::GlassBackground.new
glass_bg.tint_color = UI::Color.new(r: 0.91, g: 0.26, b: 0.21, a: 0.3)  # brand-tinted glass
```

**Override typography while keeping HIG spacing.**
```crystal
# Override the toolbar title font size only. The 13pt Bold default
# matches macOS HIG toolbar title sizing; change it in the showcase arm
# by constructing a Label with the desired font and not using shows_title.
#
# For the title:
toolbar = UI::Toolbar.new
toolbar.shows_title = false  # suppress the built-in title NSTextField

title_label = UI::Label.new("Inbox")
title_label.font = UI::Font.new(size: 15.0, weight: :semibold)  # brand typography
title_label.accessibility_label = "Inbox toolbar title"
# Place title_label in a parent VStack/HStack that wraps the toolbar if needed.
#
# Keep HIG-mandated sizes: 28pt button height on macOS, 44pt on iOS.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a writing-app toolbar with Bold / Italic / Underline text-format buttons"**
-> `toolbar.add_item("bold", "Bold", "bold")` -- SF Symbol names match common format actions.
-> `toolbar.add_item("italic", "Italic", "italic")`.
-> `toolbar.add_item("underline", "Underline", "underline")`.
-> Omit `shows_title = true` if the window title bar already names the document.

**"I want to separate navigation from action items with a visible group break"**
-> Insert `toolbar.add_item("sep1", "---", nil)` between the navigation group and action group.
-> The renderer emits an NSBox separator (macOS) or UIView hairline (iOS) at that position.
-> HIG: "Group toolbar items logically by function and frequency of use."

## What happens on each platform
- **iOS 26**: UIVisualEffectView with UIGlassEffect (or UIBlurEffect.systemChromeMaterial
  fallback). Item buttons are UIButtons with SF Symbol images, 44x44pt hit targets, no border.
  Bottom-of-screen placement mirrors UIToolbar behavior.
- **iPadOS 26**: Same UIVisualEffectView glass as iPhone. HIG notes toolbars can combine with
  the tab bar in the same horizontal strip at the top of the view on iPad.
- **macOS 26**: NSVisualEffectView with NSVisualEffectMaterialMenu (10, tracks appearance).
  Item buttons are borderless NSButtons with SF Symbol images, 44x28pt hit targets. The glass
  strip floats above window content matching the NSToolbar region behavior.

## HIG citations (validated)
- Toolbars -> Best practices: "Choose items deliberately to avoid overcrowding. People need to
  be able to distinguish and activate each item, so you don't want to put too many items in
  the toolbar."
- Toolbars -> Best practices: "Prefer system-provided symbols without borders. System-provided
  symbols are familiar, automatically receive appropriate coloring and vibrancy, and respond
  consistently to user interactions."
- Toolbars -> Best practices: "Reduce the use of toolbar backgrounds and tinted controls. Any
  custom backgrounds and appearances you use might overlay or interfere with background effects
  that the system provides."
- Toolbars -> Platform considerations -> iOS: "Prioritize only the most important items for
  inclusion in the main toolbar area. Because space is so limited, carefully consider which
  actions are essential to your app and include those first."
- Toolbars -> Actions: "Make sure the meaning of each control is clear. Don't make people
  guess or experiment to figure out what a toolbar item does. Prefer simple, recognizable
  symbols for items instead of text."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/toolbars.md](../validation/reports/toolbars.md)

## Related
- `UI::TabView` -- when to use instead: navigation between top-level app areas, not per-view
  actions. HIG: "In contrast to a toolbar, a tab bar is specifically for navigating between
  areas of an app."
- `UI::NavigationStack` -- when to use instead: hierarchical drill-down navigation with a
  back button; the navigation bar portion of NavigationStack is a toolbar variant.
- `recipes/document-app.md` -- multi-component pattern combining a toolbar, sidebar, and
  content pane in a three-column macOS layout.
