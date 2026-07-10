---
slug: pull-down-buttons
ui_view: UI::MenuButton
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/pull-down-buttons.md
validation_report: ../validation/reports/pull-down-buttons.md
---

# UI::MenuButton (pull-down mode)

> A pull-down button displays a labeled verb button (e.g., "Add", "Export") or
> ellipsis icon with a single downward chevron; when tapped, it opens a menu of
> related actions using NSVisualEffectMaterial.menu (macOS) or UIGlassEffect
> (iOS 26) -- without tracking any selected value.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A pull-down button is a mini toolbar menu attached to a single verb. Reach for it
when you have a primary action that naturally branches into related sub-actions (an
"Add" button that can add a folder, a document, or import from somewhere else), or
when you need to surface secondary actions without cluttering the toolbar with
individual buttons. The key semantic distinction from a pop-up button: a pull-down
presents a list of commands that the user performs once; it does NOT track which
option was last chosen. The button face always shows the same verb or icon,
regardless of what the user picked in the menu.

Pull-down buttons are NOT the right choice when your list items are mutually
exclusive settings (use UI::MenuButton with is_pull_down: false for that), when
you have only one or two actions (use individual buttons instead), or when the
actions belong to a different context than the button's label implies.

(HIG: "Use a pull-down button to present commands or items that are directly
related to the button's action." -- Pull-down buttons / Best practices.)

## Quickstart

```crystal
# Labeled pull-down -- content-creation actions
add_btn = UI::MenuButton.new("Add")
add_btn.is_pull_down = true
add_btn.add_item("New Folder")
add_btn.add_item("New Document")
add_btn.add_item("New Template")
add_btn.add_item("Import\u2026")
add_btn.accessibility_label = "Add, pull-down button"

# Ellipsis (more-actions) pull-down
more_btn = UI::MenuButton.new("\u2026")
more_btn.is_pull_down = true
more_btn.add_item("Duplicate")
more_btn.add_item("Rename")
more_btn.add_item("Move\u2026")
more_btn.add_item("Delete", is_destructive: true)
more_btn.accessibility_label = "More actions, pull-down button"

# Prominent (toolbar-primary) pull-down
export_btn = UI::MenuButton.new("Export")
export_btn.is_pull_down = true
export_btn.button_style = :prominent
export_btn.add_item("PDF")
export_btn.add_item("CSV")
export_btn.add_item("HTML")
export_btn.add_item("Markdown")
export_btn.accessibility_label = "Export, pull-down button"
```

Renders: on macOS, NSPopUpButton with pullsDown: YES -- button face shows the verb
label and a single trailing chevron.down with no selection tracking. On iOS 26,
UIButton with UIButtonConfiguration (grayButtonConfiguration for default style,
filledButtonConfiguration for :prominent) and showsMenuAsPrimaryAction: YES -- the
chevron.down SF Symbol appears with the verb label. In both cases, the open menu
surface uses NSVisualEffectMaterial.menu (macOS) or UIGlassEffect (iOS 26) at
runtime.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | required | The verb label shown on the button face in pull-down mode (e.g., "Add", "Export", or "..."). Not updated when an item is chosen -- pull-down buttons always show the same face. |
| `is_pull_down` | `Bool` | `false` | When true, renders as a pull-down button (action list, no selection tracking). When false, renders as a pop-up button (selection tracking, face updates). |
| `button_style` | `Symbol` | `:default` | `:default` uses the system control bezel (NSPopUpButton) or gray capsule (UIButton). `:prominent` uses a filled tinted capsule on iOS (filledButtonConfiguration, system blue); on macOS the distinction is planned (bridge enhancement needed). |
| `items` | `Array(MenuItem)` | `[]` | The menu items shown when the button is tapped. Add via `add_item(label, icon:, is_destructive:)`. |
| `accessibility_label` | `String?` | `nil` | VoiceOver label. Required on interactive elements; defaults to "label, pull-down button" if nil. |
| `icon` | `String?` | `nil` | Optional SF Symbol name to show on the button face (icon-only pull-down pattern). |
| `selected_index` | `Int32` | `0` | Ignored in pull-down mode. Only used when is_pull_down is false (pop-up mode). |

**Theming**: `UI::Theme.primary` drives the prominent (filled) button tint color on
iOS. `UI::Theme.label_primary` (resolves to NSColor.labelColor / UIColor.labelColor)
drives verb and context label text in both appearances. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

**Button chrome in light appearance:**
- macOS: NSPopUpButton with system NSControlStyleRounded bezel. Fill color
  NSColor.controlBackgroundColor light (~0.94 RGB white-gray). Verb label and
  chevron.down in NSColor.labelColor light (~0.0 RGB near-black). Contrast against
  bezel fill ~18:1.
- iOS: UIButton capsule. grayButtonConfiguration fill ~0.91 RGB warm gray; verb
  label and chevron.down in UIColor.label light (~0.0 RGB). Contrast ~18:1.
  filledButtonConfiguration (prominent) fill is system blue (0.0/0.478/1.0);
  label and chevron in white (1.0/1.0/1.0), contrast ~7:1.

**Button chrome in dark appearance:**
- macOS: NSPopUpButton bezel fill NSColor.controlBackgroundColor dark (~0.22 RGB).
  Verb label and chevron.down in NSColor.labelColor dark (~1.0 RGB near-white).
  Contrast against bezel fill ~7:1. Typography weight unchanged -- NSPopUpButton
  does not auto-thin in DarkAqua.
- iOS: grayButtonConfiguration fill in dark ~0.22 RGB dark gray. Verb label and
  chevron.down in UIColor.label dark (~1.0 RGB). Contrast ~7:1.
  filledButtonConfiguration (prominent) stays system blue in dark (appearance-
  tracking); white label contrast against blue on dark background ~6:1.

**SF Symbol:**
- macOS: NSPopUpButton renders chevron.down natively as part of its pullsDown
  chrome. No explicit SF Symbol is placed by the renderer.
- iOS: "chevron.down" systemImageNamed:, monochrome rendering mode, ~13pt. Single
  downward chevron only -- no "chevron.up" component (which would indicate pop-up
  mode). The symbol appears leading-of-title in the current implementation
  (UIButtonConfiguration default image placement). The HIG illustration shows
  trailing placement; a follow-up can set imagePlacement = .trailing via the bridge.

**Contrast caveats:** A brand override that replaces the system blue prominent fill
with a low-chroma color (e.g., a light beige brand primary) may produce insufficient
contrast for the white label in dark mode. Always verify prominent button contrast
in both appearances when overriding `UI::Theme.primary`.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary (prominent pull-down buttons).**
```crystal
# Override the theme primary before rendering the prominent pull-down.
# This affects only filledButtonConfiguration buttons (button_style: :prominent).
# Hit targets (44pt iOS, 22pt macOS), spacing, typography, and the chevron.down
# indicator all remain HIG-default.
theme = UI::Theme.new
theme.primary = UI::ThemeColor.new(r: 0.18, g: 0.55, b: 0.34)  # brand green

export_btn = UI::MenuButton.new("Export")
export_btn.is_pull_down = true
export_btn.button_style = :prominent
# The renderer reads theme.primary to resolve the fill color for iOS prominent style.
# macOS prominent style uses the native bezel (setBezelColor: planned).
```

**Replace the prominent glass-capsule with a flat brand surface.**
```crystal
# Use button_style: :default to opt out of the prominent (filled) style entirely.
# The default gray bezel or gray capsule provides a neutral surface that any
# background color will contrast against.  Warn: this reduces visual hierarchy
# in toolbar contexts where the prominent pull-down is meant to be the primary
# action.
export_btn = UI::MenuButton.new("Export")
export_btn.is_pull_down = true
export_btn.button_style = :default  # plain gray bezel instead of filled
# Pair with a custom UI::Label above the button if you need brand voice in context.
```

**Override typography while keeping HIG spacing.**
```crystal
# UI::MenuButton uses the system font (13pt Regular on macOS, 15pt Regular on iOS)
# by default, inherited from NSPopUpButton / UIButtonConfiguration.
# To override, set a custom font on the button's font property (if exposed in a
# future bridge enhancement) or set it via the containing UI::Label context labels.
# For now, brand font on pull-down button titles requires a bridge enhancement
# (planned: UIButtonConfiguration.attributedTitle / NSAttributedString helpers).
# Context labels next to the pull-down CAN use UI::Font.new:
ctx_label = UI::Label.new("Export:")
ctx_label.font = UI::Font.new(name: "YourBrandFont-Regular", size: 13.0)
```

## Feel recipes
Short examples that map design intent to code.

**"I want an 'Add' button in a toolbar that lets users create different item types."**
→ Use `UI::MenuButton.new("Add")` with `is_pull_down = true` and `button_style = :prominent`.
→ Add 3-5 item types via `add_item`. Keep verb labels short (one or two words).
→ Set `accessibility_label = "Add item, pull-down button"`.

**"I want a '...' overflow menu in a tight list row for destructive actions."**
→ Use `UI::MenuButton.new("\u2026")` with `is_pull_down = true` and `button_style = :default`.
→ Mark destructive items: `add_item("Delete", is_destructive: true)`.
→ List the destructive item last per HIG: "list them at the end of the menu."
→ Set `accessibility_label = "More options, pull-down button"`.

## What happens on each platform
- **iOS 26**: UIButton via UIButtonConfiguration. grayButtonConfiguration for
  :default style; filledButtonConfiguration (system blue or brand primary) for
  :prominent. showsMenuAsPrimaryAction: YES. Open menu surface uses UIGlassEffect
  (UIGlassContainerEffect wrapping a UIVisualEffectView with .systemChromeMaterial)
  on iOS 26. chevron.down SF Symbol, monochrome.
- **iPadOS 26**: Same UIButton + UIButtonConfiguration rendering as iOS. On iPadOS,
  pull-down menus may appear as popovers in some configurations (platform-managed);
  the button chrome is identical.
- **macOS 26**: NSPopUpButton with pullsDown: YES. Single trailing chevron.down
  rendered natively by NSPopUpButton. Open menu surface uses NSVisualEffectMaterial.menu
  (system-provided, appearance-tracking). No checkmarks in the open menu.

## HIG citations (validated)
- Pull-down buttons → Abstract: "A pull-down button displays a menu of items or
  actions that directly relate to the button's purpose."
- Pull-down buttons → Best practices: "Use a pull-down button to present commands
  or items that are directly related to the button's action."
- Pull-down buttons → Best practices: "If you need to provide a list of mutually
  exclusive choices that aren't commands, use a Pop-up button instead."
- Pull-down buttons → Best practices: "Let people know when a pull-down button's
  menu item is destructive, and ask them to confirm their intent. Menus use red text
  to highlight actions that you identify as potentially destructive."
- Pull-down buttons → Best practices: "Balance menu length with ease of use. Because
  people have to interact with a pull-down button before they can view its menu,
  listing a minimum of three items can help the interaction feel worthwhile."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/pull-down-buttons.md](../validation/reports/pull-down-buttons.md)

## Related
- `UI::MenuButton` (is_pull_down: false) -- use when you need a pop-up button that
  tracks the currently selected value and updates its face on selection.
- `UI::Button` -- use when you have a single action that needs no sub-menu.
- `recipes/toolbar-actions.md` -- multi-component pattern combining prominent
  pull-down buttons with a UI::Toolbar surface.

## Distinction from pop-up buttons

| Attribute | Pull-down (is_pull_down: true) | Pop-up (is_pull_down: false) |
|-----------|-------------------------------|------------------------------|
| Button face | Always shows the verb label (e.g., "Add") | Updates to show the current selection |
| Disclosure indicator | chevron.down (single, downward only) | chevron.up.chevron.down (paired) |
| Checkmarks in menu | None | System-provided on the selected item |
| Selection tracking | No | Yes (selected_index property) |
| HIG use case | Action list (commands) | Mutually exclusive settings |
| AppKit class | NSPopUpButton pullsDown: YES | NSPopUpButton pullsDown: NO |
| UIKit class | UIButton showsMenuAsPrimaryAction: YES | UIButton changesSelectionAsPrimaryAction |
