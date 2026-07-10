---
slug: edit-menus
ui_view: UI::MenuButton
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/edit-menus.md
validation_report: ../validation/reports/edit-menus.md
---

# UI::MenuButton (edit menus)

> An edit menu is a floating glass surface that presents text-editing commands
> -- Cut, Copy, Paste, Select All, Find, Look Up, Translate, Share -- revealed
> by selection gestures (touch-and-hold / double-tap on iOS) or secondary-click
> (macOS), rendered with `NSVisualEffectMaterial.menu` on macOS 26 and
> `UIVisualEffectView` + `UIBlurEffect` on iOS 26.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

An edit menu gives people a contextual shortcut to the most common operations
on whatever content they have selected. It should feel like the system is
reading their intent: they touched a word; the menu appears exactly above it
offering the actions that make sense for text. The edit menu is NOT a general
action surface -- it is scoped to the selected content and the editing state.
Custom items should appear near relevant system-provided ones, not replace them.

The system automatically populates many items from `UIResponderStandardEditActions`
(iOS) and the app's `NSMenu "Edit"` (macOS). Your role as a developer is to
remove irrelevant items (nothing selected: hide Cut / Copy; nothing in pasteboard:
hide Paste), add context-specific items near their related standard items, and
wire undo/redo so people can recover from mistakes without a confirmation dialog.

(HIG: "Prefer the system-provided edit menu. People are familiar with the
contents and behavior of the system-provided component, so creating a custom menu
that presents the same commands is redundant and likely to be confusing." -- Edit
menus / Best practices.)

## Quickstart

```crystal
# Construct the edit menu item list as a MenuButton.
# The validation host renders this inline (not as a dismissed trigger)
# to capture the glass surface itself.
menu = UI::MenuButton.new("Edit")
menu.add_item("Cut",        icon: "scissors")
menu.add_item("Copy",       icon: "doc.on.doc")
menu.add_item("Paste",      icon: "doc.on.clipboard")
# Separator is represented by adding a Divider in the surrounding
# VStack when rendering the surface inline (see host factory for
# the full four-group pattern).
menu.add_item("Select All", icon: "selection.pin.in.out")
menu.add_item("Find",       icon: "magnifyingglass")
menu.add_item("Look Up",    icon: "book")
menu.add_item("Translate",  icon: "character.bubble")
menu.add_item("Share",      icon: "square.and.arrow.up")
```

Renders: on macOS 26, `UI::MenuButton` produces an `NSButton` trigger that
reveals an `NSMenu` with `NSMenuItem` instances via `NSVisualEffectMaterial.menu`
(glass material value 10, BehindWindow blending). On iOS 26, it produces a
`UIButton` that connects to `UIEditMenuInteraction` / `UIContextMenuConfiguration`
with `UIGlassEffect` / `UIBlurEffect` backing. For validation, the inline
`UI::Sheet` surface wrapping a VStack of `UI::Button` instances exercises the
glass chrome.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | required | The trigger button label (e.g. "Edit"); not shown in the floating surface itself. |
| `icon` | `String?` | `nil` | SF Symbol name prepended to the trigger button. |
| `items` | `Array(MenuItem)` | `[]` | The ordered list of command items. Each item carries `label`, `icon` (SF Symbol name), `is_destructive`, and an optional `action` proc. |
| `MenuItem#label` | `String` | `""` | Command label. HIG: use verbs or short verb phrases. |
| `MenuItem#icon` | `String?` | `nil` | SF Symbol name for the item. HIG requires familiar icons for common actions (Copy = doc.on.doc, Share = square.and.arrow.up, Delete = trash). |
| `MenuItem#is_destructive` | `Bool` | `false` | When true, the renderer applies system red to the item label and attributes. Standard edit menu actions are never destructive. |
| `MenuItem#action` | `Proc(Nil)?` | `nil` | Called when the item is activated. If nil, the item is inert (useful for static display in validation). |

**Theming**: `UI::Theme.primary` (baked blue 0.0/0.478/1.0 -- drives label
foreground in current implementation; planned to resolve to `LabelRole.Primary`
which maps to `NSColor.labelColor` / `UIColor.label`). `UI::Theme.error` (system
red for `is_destructive` items). `UI::Theme.corner_radius_medium` (8pt; the
glass card uses 12pt set by the Sheet renderer). See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** The `UI::Sheet` grouped_card path calls
`NSVisualEffectView.setMaterial:10` (NSVisualEffectMaterialMenu),
`setBlendingMode:0` (BehindWindow), `setState:1` (Active). The result is a
light-frosted glass card with a ~12pt corner radius. Item labels resolve to
`UI::Theme.primary` baked blue (0.0/0.478/1.0 RGBA) -- legible at ~4.5:1
on the light-frosted surface. SF Symbols are template images; they inherit
the foreground color and render in the same blue. Keyboard shortcut labels
(macOS only) are `UI::Label` at 13pt regular with `text_color` 0.55 gray --
legible at ~3.5:1 on the light glass. Separators are `UI::Divider :horizontal`
at ~0.5pt, NSColor.separatorColor, visible. No destructive items in the
standard edit menu.

**macOS dark:** The same `NSVisualEffectMaterial.menu` material tracks Dark
Aqua automatically, producing a dark charcoal frosted surface (~0.13 RGBA).
Item labels in system blue dark variant (~0.25/0.56/1.0 RGBA) contrast at
~5:1 on charcoal -- legible. Shortcut labels in 0.55 gray: ~3.5:1 on charcoal
-- legible (above 3:1 large-text threshold). Separators visible as medium-gray
hairlines on charcoal. Typography weight is unchanged (17pt regular; AppKit
does not auto-thin NSButton titles in dark mode -- no legibility regression).
SF Symbols in the same blue dark variant (template images inherit foreground).

**iOS light:** `UIVisualEffectView` + `UIBlurEffect(style:.systemMaterial)` via
the `visit(UI::Sheet)` grouped_card path in `uikit_renderer.cr`. Light-frosted
card on white `UIColor.systemBackground`. Item labels in `UIColor.systemBlue`
(~4.5:1 on white glass). SF Symbols in near-black (template images inherit
`UIColor.label` dark on white iOS). Separators via `UI::Divider` at
`UIColor.separator`. No keyboard shortcut labels (touch platform -- correct
per HIG Platform considerations: shortcuts are a macOS-only affordance).

**iOS dark:** Dark frosted card on near-black `UIColor.systemBackground`.
Item labels in `UIColor.systemBlue` dark variant (~5:1 on near-black card).
SF Symbols in near-white (template images inherit white `UIColor.label` in
dark). Separators as `UIColor.separator` dark variant -- visible. Typography
unchanged (UIButton title weight does not auto-thin in dark).

**SF Symbol variants used:**
- scissors (Cut) -- outline, monochrome, tracks foreground color.
- doc.on.doc (Copy) -- outline, monochrome.
- doc.on.clipboard (Paste) -- outline, monochrome.
- selection.pin.in.out (Select All) -- outline, monochrome.
- magnifyingglass (Find) -- outline, monochrome.
- book (Look Up) -- outline, monochrome.
- character.bubble (Translate) -- outline, monochrome.
- square.and.arrow.up (Share) -- outline, monochrome.

All eight are SF Symbol names available in the SF Symbols 5+ catalog (iOS 17+,
macOS 14+). All use template image rendering so they inherit the button
foreground color in both appearances.

**Contrast caveats for brand override:** If you replace `UI::Theme.primary`
with a brand accent lighter than 0.5 value (e.g. a pale yellow), legibility
on the light-frosted glass surface will drop below 4.5:1. Always verify brand
accent contrast against the light-frosted glass background before shipping.
In dark mode, a very light accent (HSB value > 0.85) will also fail against
the dark-frosted glass. Use the iOS Accessibility Inspector or macOS Color
Well to check contrast before replacing the default blue.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override UI::Theme.primary to your brand accent. All UI::Button instances
# (including menu items assembled via UI::MenuButton) will inherit this color.
# Keep hit targets (44pt on iOS), spacing, and SF Symbols as-is -- only the
# foreground accent changes. Verify contrast > 4.5:1 on the light-frosted
# glass and > 4.5:1 on the dark-frosted glass before shipping.
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.2, g: 0.5, b: 0.9)  # brand blue
UI::Theme.current = theme
```

**Replace the glass material with a flat brand surface.**
```crystal
# Use surface_style: :plain on UI::Sheet to replace the Liquid Glass material
# with a flat opaque fill. This removes NSVisualEffectMaterial.menu on macOS
# and UIBlurEffect on iOS -- you lose the translucency and glass-edge highlight.
# Set a contrasting background so item labels remain legible in both appearances.
# Warning: this deviates from HIG "Menus" surface expectations and may feel
# out of place alongside system UI. Only do this if your brand style guide
# explicitly calls for flat surfaces over system chrome.
flat_sheet = UI::Sheet.new(menu_content, surface_style: :plain)
# Pair with an explicit background label / theme token to avoid invisible text:
flat_sheet.background_color = UI::Color.new(r: 0.12, g: 0.12, b: 0.14)  # dark brand bg
```

**Override typography while keeping HIG spacing.**
```crystal
# Set a custom font on each UI::Button item. Keep size >= 17pt for menu items
# (HIG body size) and maintain the spacing: 4pt between items, 8pt inset.
# Do NOT drop below 13pt -- that risks contrast on the light-frosted surface.
menu_item_btn = UI::Button.new("Copy", symbol: "doc.on.doc")
menu_item_btn.font = UI::Font.new(family: "Georgia", size: 17.0, weight: :regular)
# Shortcut labels (macOS): set the same font family at 13pt to stay cohesive.
shortcut_label = UI::Label.new("\u2318C")
shortcut_label.font = UI::Font.new(family: "Georgia", size: 13.0, weight: :regular)
shortcut_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
```

## Feel recipes
Short examples that map design intent to code.

**"I want an edit menu that shows only the commands relevant to my custom
selection type (map location, not text)."**
-> Add only the items that apply: `menu.add_item("Copy Address", icon: "doc.on.doc")`,
   `menu.add_item("Get Directions", icon: "map")`,
   `menu.add_item("Share", icon: "square.and.arrow.up")`.
-> Do NOT add Cut, Paste, or Select All -- they do not apply to a map location.
   HIG: "Offer commands that are relevant in the current context, removing or
   dimming commands that don't apply."

**"I want a Cut item that confirms before deleting, unlike the system Cut."**
-> This is a destructive variation: set `is_destructive: true` on the Cut item
   and show a `UI::Alert` in its action proc before performing the delete.
-> However, note that HIG distinguishes Cut (moves to pasteboard) from Delete
   (no pasteboard copy): "a Delete menu item behaves the same as pressing a
   Delete key, but a Cut menu item copies the selected content to the system
   pasteboard before deleting it." Confirmation dialogs on Cut are unusual --
   consider whether a confirmation is actually warranted for your data type.

## What happens on each platform
- **iOS 26**: `UIButton` trigger connected to `UIEditMenuInteraction`. The
  interaction presents either a compact horizontal bar (Multi-Touch gestures:
  Cut | Copy | Paste | > chevron) or a full vertical context menu (keyboard /
  pointer input). Glass backing: `UIGlassEffect` on iOS 26 / `UIBlurEffect
  (style:.systemChromeMaterial)` on earlier SDKs.
- **iPadOS 26**: Compact horizontal bar for touch input; full `UIContextMenuConfiguration`
  vertical presentation for keyboard and trackpad. Same `UIGlassEffect` backing.
  HIG: "Ensure your edit menu works well in both styles."
- **macOS 26**: `NSMenu` presented by `NSMenuItem` instances. The menu bar
  "Edit" menu is populated from `NSResponder` chain standard actions. Contextual
  edit menus appear via `NSTextView`'s right-click responder. Glass backing:
  `NSVisualEffectMaterial.menu` (value 10), BehindWindow blending, Active state.
  Keyboard shortcuts (\u2318X, \u2318C, \u2318V, \u2318A, \u2318F) shown
  right-aligned in the menu row by `NSMenuItem.keyEquivalent` and
  `NSMenuItem.keyEquivalentModifierMask`.

## HIG citations (validated)
- Edit menus -> Best practices: "Prefer the system-provided edit menu. People
  are familiar with the contents and behavior of the system-provided component,
  so creating a custom menu that presents the same commands is redundant and
  likely to be confusing."
- Edit menus -> Best practices: "Let people reveal an edit menu using the
  system-defined interactions they already know. For example, people expect to
  touch and hold on a touchscreen, pinch and hold in visionOS, or use a
  secondary click with an attached trackpad or keyboard."
- Edit menus -> Best practices: "Offer commands that are relevant in the current
  context, removing or dimming commands that don't apply. For example, if nothing
  is selected, avoid showing options that require a selection, such as Copy or Cut."
- Edit menus -> Best practices: "Support undo and redo when possible. Like all
  menus, an edit menu doesn't require confirmation before performing its actions,
  so people can easily use undo and redo to recover a previous state."
- Edit menus -> Platform considerations -> iOS, iPadOS: "Ensure your edit menu
  works well in both styles. The system displays the compact, horizontal style
  when people use Multi-Touch gestures to reveal the edit menu, and the vertical
  style when people use a keyboard or pointing device to reveal it."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/edit-menus.md](../validation/reports/edit-menus.md)

## Related
- `UI::MenuButton` -- the trigger-button view type that this component doc covers;
  when you need a general-purpose contextual menu (not text editing), prefer
  `context-menus` patterns instead.
- `recipes/text-editing-surface.md` -- full text field + edit menu + undo stack
  multi-component pattern.
