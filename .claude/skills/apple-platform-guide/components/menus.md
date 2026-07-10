---
slug: menus
ui_view: UI::MenuButton
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/menus.md
validation_report: ../validation/reports/menus.md
---

# UI::MenuButton

> A menu button reveals a list of commands or selectable options when activated,
> rendering with the system menu glass material (`NSVisualEffectMaterial.menu` on
> macOS 26, `UIGlassContainerEffect` / `UIBlurEffect(style: .systemChromeMaterial)`
> on iOS 26) and supporting pull-down, pop-up, and submenu shapes per HIG.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Menus are one of the oldest and most familiar interaction patterns across Apple
platforms. A menu button presents its label or title in the ambient UI, and when
activated it reveals a floating glass surface containing one or more groups of
labeled items. Items may carry SF Symbols (one per group introduction, not per
every item), keyboard shortcuts (macOS only), checkmarks for toggled state, or
a trailing chevron to indicate a submenu. The menu is a space-efficient way to
expose commands without cluttering the primary interface.

Use `UI::MenuButton` when you need a persistent trigger that reveals a contextual
or hierarchical set of options -- for example, a "File" pull-down in a toolbar,
a "Sort By" pop-up anchored to a control, or an "Options" button revealing
configuration choices. Do NOT use it as a substitute for a full action sheet
(`UI::Sheet`) when a destructive confirmation is required, or as a substitute for
a context menu (`UI::ContextMenu`, triggered by secondary click / long-press) -- the
HIG distinguishes these interaction patterns explicitly.

(HIG: "A menu reveals its options when people interact with it, making it a
space-efficient way to present commands in your app or game." -- Menus / Abstract.)

## Quickstart

```crystal
# Pull-down menu (File-style): groups separated by dividers, submenu chevron.
file_menu = UI::MenuButton.new("File")
file_menu.add_item("New",       icon: "doc")
file_menu.add_item("Open...",   icon: "folder.open")
file_menu.add_item("Close",     icon: "xmark")
# Dividers are implicit between add_item groups when surface_style: :grouped_card
# is used on the host sheet. See host factory for the explicit Divider pattern.

# Pop-up menu (Sort By-style): checkmark on the currently selected item.
sort_menu = UI::MenuButton.new("Sort By")
sort_menu.add_item("Name", icon: "character")
sort_menu.add_item("Date", icon: "calendar")   # mark selected externally via Label + checkmark
sort_menu.add_item("Size", icon: "arrow.up.arrow.down")

# Submenu indicator: construct an HStack row with a trailing chevron Label.
# HIG "Submenus": "A menu item indicates the presence of a submenu by displaying
# a symbol -- like a chevron -- after its label."
export_row = UI::HStack.new(spacing: 8.0)
export_row << UI::Button.new("Export", symbol: "square.and.arrow.up")
export_row << UI::Spacer.new
chevron = UI::Label.new("\u203a")
chevron.font = UI::Font.new(size: 15.0, weight: :regular)
chevron.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
export_row << chevron.as(UI::View)
```

Renders: on macOS 26 the trigger renders as `NSButton` (bezel style rounded) and
the revealed surface uses `NSVisualEffectMaterial.menu` (value 10) with
`NSVisualEffectBlendingMode.behindWindow`; on iOS 26 the trigger renders as
`UIButton` (configuration `.gray()`) and the revealed surface uses
`UIGlassContainerEffect` / `UIBlurEffect(style: .systemChromeMaterial)`.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | (required) | The trigger button's visible title; also used as `accessibility_label` on the native control. |
| `icon` | `String?` | `nil` | SF Symbol name prepended to the trigger label when set (e.g. `"ellipsis.circle"`). |
| `items` | `Array(MenuItem)` | `[]` | The list of items revealed when the menu opens. Each `MenuItem` has `label`, `icon`, `is_destructive`, and an optional `action` proc. |
| `MenuItem.label` | `String` | `""` | The visible text of a menu row. HIG: use title-case, verb phrases, no articles. |
| `MenuItem.icon` | `String?` | `nil` | SF Symbol name for the row. HIG: use a single icon to introduce a group; do not icon every row. |
| `MenuItem.is_destructive` | `Bool` | `false` | When `true`, the renderer applies the destructive role color (system red) to the item. HIG: list destructive items last and identify them with `is_destructive: true`. |
| `MenuItem.action` | `Proc(Nil)?` | `nil` | Optional Crystal proc invoked when the item is selected (registered via `CallbackRegistry` to prevent GC). |

**Theming**: `UI::Theme.primary` drives button accent color; `UI::Theme.corner_radius_medium`
drives the glass card corner radius (default 12pt on apple_default). See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

The menu button trigger and the glass surface it reveals each resolve differently
in light and dark appearance.

**Light appearance:**
- Trigger button: NSButton / UIButton with `NSColor.controlAccentColor` /
  `UIColor.tintColor` label in light (system blue, approximately 0.0/0.478/1.0 RGBA).
  The baked-blue gap (gaps.md iter-12) means `UI::Button` currently uses a fixed
  ThemeColor rather than a semantic `LabelRole.Primary` token. When the semantic fix
  lands, label color in light will be `NSColor.labelColor` (near-black) matching
  native NSMenu row behavior.
- Glass surface: `NSVisualEffectMaterial.menu` in light resolves to a white-frosted
  translucent card. `UIBlurEffect(style: .systemChromeMaterial)` on iOS resolves to
  a similar light-frosted surface that tracks UITraitCollection appearance.
- Keyboard shortcut labels (macOS only): ~13pt regular, approximately 0.55 gray
  on white glass -- ~3.5:1 ratio, above the 3:1 large-text threshold.
- Checkmark for selected state: rendered as a `UI::Label` with "v" character in
  near-black `NSColor.labelColor` / `UIColor.label`. In light this is approximately
  0.0/0.0/0.0 RGBA, clearly distinguishable from the system-blue button labels.
- Submenu chevron (">"): ~15pt regular, 0.55 gray -- legible against both light
  and dark glass.
- Dividers: ~0.5pt hairline gray lines (NSView / UIView with 0.5pt height). Visible
  against light frosted glass at approximately 3:1.

**Dark appearance:**
- Glass surface: `NSVisualEffectMaterial.menu` in dark resolves to a charcoal
  frosted card (approximately 0.13/0.13/0.15 RGBA). `UIBlurEffect(style:
  .systemChromeMaterial)` on iOS dark resolves to near-black frosted.
- Trigger and item labels: system blue dark variant (approximately 0.25/0.56/1.0
  RGBA) -- ~5:1 contrast against charcoal glass, legible.
- Checkmark: `UI::Label` inherits `NSColor.labelColor` / `UIColor.label` which in
  dark resolves to near-white (approximately 1.0/1.0/1.0). This correctly
  distinguishes the checkmark from system-blue item labels in dark mode.
- Keyboard shortcut labels: ~0.55 gray on charcoal, approximately 3.5:1 -- legible
  at the secondary-text threshold.
- Dividers: visible as medium-gray hairlines on charcoal.
- Typography weight: unchanged from light -- neither NSMenu nor UIButton auto-thins
  in dark mode. 17pt regular for items, 13pt regular for shortcuts and chevrons,
  11pt semibold for section headers.

**Contrast caveats for brand overrides:**
- If you replace the glass material with a flat dark surface (`surface_style: :plain`,
  custom background), ensure keyboard shortcut labels and dividers maintain at least
  3:1 contrast against the new background. Gray-on-dark-gray combinations fail easily.
- If you replace the item accent color (system blue) with a brand color, verify the
  contrast in BOTH appearances. A brand color that is legible in light may disappear
  against the charcoal dark glass if it is too dark or desaturated.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the trigger button accent to your brand primary.**
```crystal
# Override the theme's primary token. All UI::Button instances (including
# MenuButton trigger) will pick up the new color. Hit targets (minimum 44pt
# on iOS, NSButton default on macOS), corner radius, and spacing are
# unaffected. Confirm legibility in both light and dark appearances.
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.42, g: 0.18, b: 0.72)  # brand purple

menu = UI::MenuButton.new("Options")
menu.add_item("Rename", icon: "pencil")
menu.add_item("Archive", icon: "archivebox")
```

**Replace the glass material with a flat brand surface.**
```crystal
# Use surface_style: :plain on the wrapping UI::Sheet to disable
# NSVisualEffectMaterial / UIVisualEffectView. Then set a flat background
# color via UI::Color. WARNING: this removes Liquid Glass. The surface will
# no longer be translucent or have a glass-edge highlight. Ensure your flat
# background color provides at least 4.5:1 contrast against item labels in
# both light and dark appearances.
flat_content = UI::VStack.new(spacing: 4.0)
flat_content << UI::Button.new("Rename", symbol: "pencil")
flat_content << UI::Button.new("Archive", symbol: "archivebox")

flat_surface = UI::Sheet.new(flat_content.as(UI::View), surface_style: :plain)
flat_surface.background_color = UI::Color.new(r: 0.95, g: 0.93, b: 1.0)  # brand tint
```

**Override typography while keeping HIG spacing.**
```crystal
# Substitute a brand font via UI::Font.custom, preserving HIG-mandated
# sizes (17pt body for items, 13pt for shortcuts, 11pt for section headers)
# and the 4pt VStack spacing between rows.
item_font = UI::Font.custom("BrandFont-Regular", size: 17.0)

btn = UI::Button.new("Rename")
btn.font = item_font
# Shortcut labels use 13pt -- keep that size even with brand font to stay
# within the NSMenu row height budget.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a File menu with New / Open... / Close and keyboard shortcuts."**
For macOS: construct an HStack for each row, left-side UI::Button, UI::Spacer,
right-side UI::Label with the Cmd-shortcut glyph at 13pt regular 0.55 gray.
Wrap all rows in a UI::VStack(spacing: 4.0), wrap in a UI::Sheet(surface_style:
:grouped_card). On iOS omit the shortcut labels (no-op on touch).

**"I want a pop-up with a checkmark on the currently selected sort option."**
Render the selected row as an HStack: leading UI::Label with "\u2713" (checkmark)
at 13pt semibold, followed by the item UI::Button. Render unselected rows with a
placeholder UI::Label("  ") for alignment. HIG "Toggled items": "Consider using
a checkmark to show that an attribute is currently in effect."

## What happens on each platform
- **iOS 26**: `UIButton` trigger (configuration `.gray()`) + `UIGlassContainerEffect`
  / `UIBlurEffect(style: .systemChromeMaterial)` floating surface. Menus do not
  display keyboard shortcuts (touch platform). Default layout is Large (list).
  The system also supports Small and Medium layouts (`preferredElementSize`) for
  icon-only or icon+short-label compact rows.
- **iPadOS 26**: Same as iOS 26. Pointer/keyboard attachment enables keyboard
  shortcuts display in native `UIMenu`. The HIG notes iPadOS supports the same
  three menu layouts as iOS.
- **macOS 26**: `NSButton` trigger (bezel style rounded) + `NSVisualEffectMaterial.menu`
  (value 10) floating surface via `NSMenu` / `NSPopUpButton`. Keyboard shortcuts
  rendered as right-aligned secondary labels in each row. `NSMenuItem` full-width
  highlight strips (native; the current validation host approximates via pill bezels).

## HIG citations (validated)
- Menus / Abstract: "A menu reveals its options when people interact with it,
  making it a space-efficient way to present commands in your app or game."
- Menus / Organization: "Consider grouping logically related items. To help
  people visually distinguish such groups, use a separator."
- Menus / Submenus: "A menu item indicates the presence of a submenu by displaying
  a symbol -- like a chevron -- after its label."
- Menus / Toggled items: "Consider using a checkmark to show that an attribute is
  currently in effect. It's easy for people to scan for checkmarks in a list of
  attributes to find the ones that are selected."
- Menus / Labels: "For each menu item, write a label that clearly and succinctly
  describes it. In general, label a menu item that initiates an action using a
  verb or verb phrase that describes the action, such as View, Close, or Select."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/menus.md](../validation/reports/menus.md)

## Related
- `UI::Sheet` -- use for action sheets and confirmation surfaces that require
  a destructive/cancel role pair rather than a list of commands.
- `UI::ContextMenu` (planned) -- for secondary-click / long-press contextual menus
  anchored to specific content items rather than a persistent toolbar trigger.
- `UI::Alert` -- use when the action requires a modal confirmation before proceeding.
- `recipes/file-menu.md` (planned) -- multi-component pattern combining a Toolbar,
  MenuButton triggers, and keyboard shortcut wiring.

## Relationship to context-menus, edit-menus, and dock-menus
This slug (`menus`) covers the general menu surface shape: pull-down menus
(File / Edit / View-style menu-bar menus on macOS) and pop-up menus (anchored
to a button trigger on both platforms), including the submenu chevron idiom and
the checkmark selected-state idiom.

Distinct slugs covered separately:
- `edit-menus` -- text-editing specific actions (Cut / Copy / Paste / Select All /
  Look Up / Translate), triggered by secondary-click on a text selection.
- `context-menus` -- task-specific commands triggered by secondary-click / long-press
  on any content item (files, photos, list rows), not anchored to a persistent button.
- `dock-menus` -- macOS-only menu revealed by secondary-clicking an app icon in
  the Dock. Not supported on iOS / iPadOS / tvOS / watchOS.
