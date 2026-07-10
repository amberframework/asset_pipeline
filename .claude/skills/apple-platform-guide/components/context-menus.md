---
slug: context-menus
ui_view: UI::MenuButton
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/context-menus.md
validation_report: ../validation/reports/context-menus.md
---

# UI::MenuButton (context menu pattern)

> A hidden-by-default floating card that exposes a short list of commands
> directly relevant to the item under the pointer or finger; on iOS 26 /
> macOS 26 the card is drawn on Liquid Glass `NSVisualEffectMaterial.menu`
> (macOS) or `UIBlurEffect(.systemChromeMaterial)` (iOS) once the system
> presents it natively.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Reach for a context menu when you have an onscreen item -- a row, a
tile, a preview, a selection -- and you want to expose 3-6 task-specific
commands for that item without spending vertical space on a persistent
toolbar. The menu is about the thing under the cursor, not about the app
as a whole. If the commands are app-wide they belong in the main menu bar
(macOS) or a toolbar/overflow button (iOS). If the commands require user
confirmation before executing, reach for `UI::Sheet` used as an action
sheet instead.

HIG is explicit about mutual exclusion: do not provide both a context menu
and an edit menu on the same item because the system cannot reliably detect
which the user intends (HIG iOS/iPadOS: "Provide either a context menu or
an edit menu for an item, but not both.").

Use separators between logical groups. HIG: "you can use separators to
group items in a context menu and help people scan the menu more quickly.
In general, you don't want more than about three groups in a context menu."

(HIG: "A context menu isn't for providing advanced or rarely used items;
instead, it helps people quickly access the commands they're most likely
to need in their current context." -- Context menus / Best practices.)

## Quickstart

```crystal
# Inline validation host pattern: render the menu surface directly.
# Three groups separated by Dividers per HIG separator guidance.
content = UI::VStack.new(spacing: 4.0)
content << UI::Button.new("Cut",       symbol: "scissors")
content << UI::Button.new("Copy",      symbol: "doc.on.doc")
content << UI::Button.new("Paste",     symbol: "clipboard")
content << UI::Divider.new(:horizontal)
content << UI::Button.new("Share...",  symbol: "square.and.arrow.up")
content << UI::Button.new("Duplicate", symbol: "square.on.square")
content << UI::Divider.new(:horizontal)
content << UI::Button.new("Delete", role: :destructive, symbol: "trash")
UI::Sheet.new(content.as(UI::View), surface_style: :grouped_card)

# Production pattern: attach to a target view via MenuButton.
menu = UI::MenuButton.new("More")
menu.add_item("Cut",       icon: "scissors")
menu.add_item("Copy",      icon: "doc.on.doc")
menu.add_item("Paste",     icon: "clipboard")
menu.add_item("Share...",  icon: "square.and.arrow.up")
menu.add_item("Duplicate", icon: "square.on.square")
menu.add_item("Delete",    icon: "trash", is_destructive: true)
```

Renders: on macOS `NSButton` (bezelStyle=1) whose click invokes
`NSMenu.popUpContextMenu(_:with:for:)` backed by `NSVisualEffectMaterial.menu`
glass; on iOS 26 `UIButton(type:.system)` with `UIContextMenuInteraction`
presenting a `UIBlurEffect(.systemChromeMaterial)`-backed card. Validation
host renders the item surface inline via `UI::Sheet` + `UI::VStack` (the
same convention as `action-sheets` and `alerts`).

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | (required) | The trigger button's title. HIG: keep item labels short and descriptive. |
| `icon` | `String?` | `nil` | SF Symbol name for the trigger button's leading glyph. Passed through `UI::Button#symbol` to the renderer. |
| `items` | `Array(MenuItem)` | `[]` | Ordered list of commands. Destructive items must be last per HIG. |
| `MenuItem#label` | `String` | `""` | Row title. HIG: "each item in a context menu needs to display a short label that clearly describes what it does." |
| `MenuItem#icon` | `String?` | `nil` | SF Symbol name for the row's leading glyph. HIG: "Represent menu item actions with familiar icons." |
| `MenuItem#is_destructive` | `Bool` | `false` | Marks the item as data-destroying. The renderer applies system red (`UI::Theme#error`, 1.0/0.23/0.19 in light) via `UI::Button` role wiring. |
| `MenuItem#action` | `Proc(Nil)?` | `nil` | Called when the item is chosen. `nil` means informational-only. |

**Theming**: `UI::Theme#error` (system red, `src/ui/theme.cr:35`) drives
destructive item foreground. `UI::Theme#corner_radius_medium` (8pt default;
the Sheet renderer uses 12pt directly -- `appkit_renderer.cr:1635`) drives
the glass card's corner mask. `UI::Theme#font_size_body` (16pt) drives item
label size. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

The context-menu card tracks system appearance because the validation host
composes a real `NSVisualEffectMaterial.menu` view on macOS and a
`UIBlurEffect(.systemChromeMaterial)` view on iOS. Both materials are
appearance-aware and require no explicit appearance check from app code.

In light appearance:
- macOS: `NSVisualEffectMaterial.menu` (value 10) renders a light-frosted
  white glass card. Against a white window backdrop the frosting is subtle;
  against colored content behind the window the blur and tint are visible.
  Item labels resolve via `NSColor.labelColor` (near-black, ~21:1 on white).
  Destructive label resolves to system red (1.0/0.23/0.19) -- distinguishable
  from standard-item label and from system blue link color.
- iOS: `UIBlurEffect(.systemChromeMaterial)` renders a light-frosted card
  that blurs the content behind it. `UIColor.label` resolves to near-black.
  Destructive label resolves to `UIColor.systemRed` (1.0/0.23/0.19 in light).

In dark appearance:
- macOS: `NSVisualEffectMaterial.menu` switches to a dark-frosted charcoal
  glass automatically. Item labels resolve to `NSColor.labelColor` (white,
  ~21:1 on charcoal). Destructive label resolves to system red dark-mode
  variant (1.0/0.27/0.23) -- still distinguishable from white standard labels.
- iOS: `UIBlurEffect(.systemChromeMaterial)` switches to dark-frosted
  automatically. `UIColor.label` resolves to white. `UIColor.systemRed`
  dark variant (1.0/0.27/0.23) used for the Delete label -- distinguishable
  from white standard labels.

SF Symbols (`scissors`, `doc.on.doc`, `clipboard`, `square.and.arrow.up`,
`square.on.square`, `trash`) render as monochrome template images and inherit
the row's foreground color, so they automatically match item text in both
appearances. The `trash` symbol inherits the destructive-red foreground.

Contrast caution: if you override `UI::Theme#error` to a brand color that
reads similarly to your standard accent in dark mode (e.g. a brand orange
near system blue), the destructive signal is lost. Keep the destructive
token at system red or a clearly distinct hue.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.90, g: 0.34, b: 0.52)  # brand pink
# What stays HIG-default: hit targets (44pt iOS), corner radius (12pt),
# separator thickness (0.5pt), glass material (appearance-tracking).
# What CAN change: the accent tint applied to non-destructive action labels
# and the trigger button bezel color.
# Do NOT override theme.error -- the destructive red is a HIG safety signal.
```

**Replace the glass material with a flat brand surface.**
```crystal
# Use UI::Sheet with surface_style: :plain and an explicit background.
content_view = UI::VStack.new(spacing: 4.0)
# ... add buttons and dividers as above ...
sheet = UI::Sheet.new(content_view.as(UI::View), surface_style: :plain)
# Trade-off: the menu loses Liquid Glass translucency.
# Users accustomed to the system menu material may not recognize it as
# a context menu. Legibility is preserved IF your flat background color
# has sufficient contrast (~4.5:1) against label text in both appearances.
```

**Override typography while keeping HIG spacing.**
```crystal
theme = UI::Theme.apple_default
theme.font_family = "YourBrand-Display"
theme.font_size_body = 17.0   # keep HIG item-label size; do not go below 15pt
# The Sheet renderer uses 16pt insets and 4-8pt row spacing regardless of
# font_size_body -- spacing is not driven by the font token. Safe to change
# the family; unsafe to change the size below 15pt (legibility on small
# display, iPadOS Split View).
```

## Feel recipes
Short examples that map design intent to code.

**"I want a row-level edit menu on a list item"**
-> Attach `UI::MenuButton.new("More")` with items for Copy, Share, and Delete
   (destructive, last). Keep to 5 items or fewer (HIG: "Aim for a small
   number of menu items"). Do NOT also provide an edit menu on the same row.

**"I want a creation affordance from empty canvas space (iPadOS)"**
-> Build `UI::MenuButton.new("New")` triggered on long-press in the empty
   canvas area; add items "New Folder" and "New Document". HIG iPadOS:
   "consider using a context menu to let people create a new object in your
   app. iPadOS lets you reveal a context menu when people perform a long
   press on the touchscreen..."

## What happens on each platform
- **iOS 26**: `UIButton(type:.system)` trigger; system presents menu as a
  Liquid Glass card via `UIContextMenuInteraction` (UIKit) or
  `.contextMenu(menuItems:)` modifier (SwiftUI). Long-press is
  system-standard. Preview image of target content displayed above the menu.
- **iPadOS 26**: same as iOS, plus secondary click from trackpad or Magic
  Mouse. HIG: "consider using a context menu to let people create a new
  object in your app."
- **macOS 26**: `NSButton` (bezelStyle=1) trigger; right-click / Control-click
  on the target calls `NSMenu.popUpContextMenu(_:with:for:)`. The NSMenu
  renders on `NSVisualEffectMaterial.menu` glass automatically. On macOS the
  component is sometimes called a "contextual menu" per HIG.

## HIG citations (validated)
- Context menus -> Best practices: "Prioritize relevancy when choosing items
  to include in a context menu. A context menu isn't for providing advanced
  or rarely used items; instead, it helps people quickly access the commands
  they're most likely to need in their current context."
- Context menus -> Best practices: "Follow best practices for using
  separators. As with other types of menus, you can use separators to group
  items in a context menu and help people scan the menu more quickly. In
  general, you don't want more than about three groups in a context menu."
- Context menus -> Best practices: "In iOS, iPadOS, and visionOS, warn people
  about context menu items that can destroy data. If you need to include
  potentially destructive items in your context menu -- such as Delete or
  Remove -- list them at the end of the menu and identify them as destructive.
  The system can display a destructive menu item using a red text color."
- Context menus -> Content: "Represent menu item actions with familiar icons.
  Icons help people recognize common actions throughout your app. Use the same
  icons as the system to represent actions such as Copy, Share, and Delete,
  wherever they appear."
- Context menus -> iOS, iPadOS: "Provide either a context menu or an edit
  menu for an item, but not both."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/context-menus.md](../validation/reports/context-menus.md)

## Related
- `UI::Sheet` -- the glass-surface container the validation host uses to
  render the menu content inline; also the action-sheet pattern for
  confirmation dialogs.
- `UI::Button` -- the row renderer for individual menu items. Role and symbol
  wiring (`UI::Button#role`, `UI::Button#symbol`) provide destructive-red
  and SF Symbol leading glyphs.
- `UI::Divider` -- the separator between item groups. Renders as a 0.5pt
  NSView (macOS) or UIView (iOS) with NSColor.separatorColor /
  UIColor.separator.
- `components/action-sheets.md` -- inline-VStack validation convention
  reused here; also the right component when you need confirmation.
- `components/edit-menus.md` -- the text-selection edit menu; mutually
  exclusive with context menus on the same item per HIG.
