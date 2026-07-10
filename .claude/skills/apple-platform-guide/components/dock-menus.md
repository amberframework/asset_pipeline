---
slug: dock-menus
ui_view: UI::MenuButton
priority: P0
platforms: [macOS]
hig_page: ../../../apple-hig/pages/dock-menus.md
validation_report: ../validation/reports/dock-menus.md
---

# UI::MenuButton (Dock menu pattern)

> A macOS-only secondary-click surface extending from an app's Dock tile
> that lists system-provided items (Options, Show in Finder, Hide, Quit)
> alongside high-value custom actions and recent documents. On macOS 26
> AppKit renders the surface with `NSVisualEffectMaterial.menu` (value 10),
> a Liquid Glass material that automatically tracks Aqua (light) and Dark
> Aqua (dark) appearances. Not supported on iOS, iPadOS, tvOS, visionOS, or
> watchOS.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Reach for a Dock menu when the user is outside your app's window -- either
your app is not frontmost or there are no open windows -- and you want to
let them jump straight to a meaningful action without clicking through the
Dock tile first. Good Dock menus surface what people actually want when
window-hunting: recent documents, open windows by name, a "Compose New
Message", a "Check for New Mail". The menu is a shortcut layer, not a
feature surface. HIG cap: three to five custom items maximum alongside the
system-provided Options sub-group.

Do not use a Dock menu as the only home for a command. HIG is explicit that
Dock menus are a convenience layer -- not everyone opens them, so every
custom item must also be reachable from your menu bar menu or main interface.

(HIG: "Prefer high-value custom items for your Dock menu. For example, a
Dock menu can list all currently or recently open windows, making it a
convenient way to jump to the window people want." -- Dock menus / Best
practices.)

## Quickstart

```crystal
# Build the Dock menu item tree.
menu = UI::MenuButton.new("App")

# Group 1: app-specific custom items (top of menu, high-value first)
menu.add_item("New Window",   icon: "plus.rectangle")
menu.add_item("Open Recent",  icon: "clock.arrow.circlepath")

# Group 2: recent documents (add_item for each recently opened file)
menu.add_item("report-q1.pdf", icon: "doc.fill")
menu.add_item("notes.md",      icon: "doc.text")
menu.add_item("drafts.md",     icon: "doc.text")

# Group 3: system items (Options sub-group + Show in Finder / Hide / Quit)
# "Keep in Dock" and "Open at Login" are AppKit-managed; you surface them
# here so the user can toggle them without opening the app first.
menu.add_item("Keep in Dock",   icon: "pin")
menu.add_item("Open at Login",  icon: "power")
menu.add_item("Show in Finder", icon: "folder")
menu.add_item("Hide",           icon: "eye.slash")
menu.add_item("Quit",           icon: "xmark.circle")
```

Renders: on macOS, `UI::MenuButton` maps to a `UI::Sheet.new(..., surface_style: :grouped_card)` in the validation host -- a `NSVisualEffectView` with `NSVisualEffectMaterial.menu` (10), `blendingMode: BehindWindow`, `state: Active`, and ~12pt corner radius. In a production app, return the menu from `NSApplicationDelegate.applicationDockMenu(_:)`; AppKit draws it as a Liquid Glass card anchored to the Dock tile. No iOS rendering -- this slug is macOS-only per HIG.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | (required) | Diagnostic only for Dock menus -- the Dock tile is the real trigger; this label is used by the AppKit visitor for the NSButton title in non-Dock uses of `UI::MenuButton`. Keep short. |
| `icon` | `String?` | `nil` | Optional SF Symbol name on the trigger button. Not consumed by the AppKit Dock-menu path (AppKit owns the Dock tile rendering). Used in non-Dock `UI::MenuButton` presentations. |
| `items` | `Array(MenuItem)` | `[]` | Ordered command list. Order matters: custom app actions first, recent documents second, system group (Options / Hide / Quit) last. HIG: "organize them logically." |
| `MenuItem#label` | `String` | `""` | Row title. HIG: "label Dock menu items succinctly." Keep to 1-3 words. |
| `MenuItem#icon` | `String?` | `nil` | Optional leading SF Symbol name. Symbol wiring pending full `UI::MenuButton` native renderer (gaps.md iteration 25). In the validation host, symbols are forwarded via the `UI::Button.new(..., symbol:)` path. |
| `MenuItem#is_destructive` | `Bool` | `false` | Flags the item as data-destroying; visual red-label wiring via `UI::Button#role = :destructive`. Quit is NOT destructive (it is an app-lifecycle action); reserve for irreversible user-data operations. |
| `MenuItem#action` | `Proc(Nil)?` | `nil` | Called when the item is chosen. `nil` means system-handled (e.g. "Keep in Dock" is forwarded to AppKit). |

**Theming**: `UI::Theme.apple_default.primary` currently drives button label
color (system blue -- see deviation 1 in the validation report). Once
`UI::Button` default foreground is wired to `LabelRole.Primary`, items will
resolve to `NSColor.labelColor` / `UIColor.label` automatically. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

Dock menus are macOS-only (HIG Platform considerations). The validation host
wraps menu content in `UI::Sheet.new(..., surface_style: :grouped_card)`,
which emits a `NSVisualEffectView` with:

- `setMaterial: 10` -- `NSVisualEffectMaterial.menu`. This is the canonical
  Liquid Glass menu material on macOS 26. It automatically resolves to
  light-frosted in Aqua (system light appearance) and dark charcoal-frosted
  in Dark Aqua (dark appearance). The material tracks the system appearance
  with no Crystal-side toggle required.
- `setBlendingMode: 0` -- `BehindWindow`. Samples the window compositor
  backdrop so the glass shows true bleed-through in production (capture
  harness limitation: `cacheDisplayInRect` does not composite the live
  backdrop, so bleed-through is not visible in validation PNGs).
- `setState: 1` -- `Active`. Required for the material to render actively
  (inactive state produces a dimmer, grayer material).

**Light appearance (Aqua):** Menu card renders as a light-frosted rounded
rect with ~12pt corner radius. Item labels in `Theme.apple_default.primary`
(approximately 0.0/0.478/1.0 system blue). Section headers ("Recent",
"Options") in 0.55 gray approximating `NSColor.secondaryLabelColor`.
Separators visible as hairline ~0.5pt gray lines. All contrast ratios
sufficient for the blue-on-light-glass context (~4.5:1).

**Dark appearance (Dark Aqua):** Menu card renders as dark charcoal frosted
glass with the same ~12pt corner radius. Item labels in system blue dark
variant (approximately 0.25/0.56/1.0) -- ~5:1 on charcoal, legible. Section
headers in 0.55 gray -- approximately 3.5:1 on dark charcoal (legible for
non-interactive section headers). Separators visible as medium-gray lines.
Typography weight unchanged from light (17pt regular; AppKit does not auto-
thin menu-item labels in dark).

**SF Symbol appearance:** Symbol glyphs (plus.rectangle, clock, doc.fill,
doc.text, pin, power, folder, eye.slash, xmark.circle) are template images
that inherit the foreground color of their enclosing NSButton. They resolve
to system blue in both appearances alongside the button label. In production
native NSMenu rendering (outside the validation host), glyphs inherit
`NSColor.labelColor`, tracking appearance automatically without custom wiring.

**iOS:** Not rendered. The iOS captures show an intentional placeholder card
("Dock Menus -- macOS Only") implemented as `UI::Sheet.new(...,
surface_style: :grouped_card)`. It renders with the same UIBlurEffect glass
surface in both iOS light and dark appearances. Legible in both appearances.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
theme = UI::Theme.apple_default.dup
theme.primary = UI::ThemeColor.new(r: 0.22, g: 0.58, b: 0.82)  # brand blue
# Applies to custom Dock-menu rows rendered via UI::MenuButton items.
# System rows (Options sub-group / Quit) are drawn by AppKit and ignore
# theme overrides -- that is intentional; users expect system consistency.
# HIT TARGETS: do not reduce spacing below 8pt row padding; the HIG
# minimum interactive target for macOS menu rows is approximately 22pt tall.
```

**Replace the glass material with a flat brand surface (validation host only).**
```crystal
# In the validation host, the surface_style can be changed:
UI::Sheet.new(content.as(UI::View), surface_style: :plain)
# Sets NSView background instead of NSVisualEffectView. WARNING: this removes
# Liquid Glass entirely. System Dock menus always use NSVisualEffectMaterial.menu
# via AppKit -- you cannot override the material for real Dock menus. Only
# the validation host's inline surface approximation is affected. Removing
# glass reduces legibility in complex wallpaper contexts (no backdrop contrast).
```

**Override typography while keeping HIG spacing.**
```crystal
# System Dock menus: AppKit draws items with the system menu font; Crystal
# font overrides do not apply to native NSMenu rows. For the validation host
# inline approximation:
item_label = UI::Label.new("New Window")
item_label.font = UI::Font.custom("SF Pro Text", size: 13.0, weight: :regular)
# Use SF Pro Text at 13pt for menu-item density matching HIG menu row height.
# Do NOT go below 11pt (legibility threshold for menu-item scanning).
# Spacing: preserve VStack spacing >= 6pt; below 6pt rows are too dense to
# tap-target on macOS (22pt min per row).
```

## Feel recipes
Short examples that map design intent to code.

**"I want recently open documents jump-able from the Dock"**
-> Build a `UI::MenuButton.new("App")`; for each recent file, call
   `add_item(file.name, icon: "doc.text")` with an action that opens the
   document. Sort newest-first per HIG convention.
-> HIG: "a Dock menu can list all currently or recently open windows, making
   it a convenient way to jump to the window people want."

**"I want a common action mirrored in the Dock menu and the menu bar"**
-> Add the custom item to both the Dock-menu `items` list AND the menu bar
   (`UI::Menu` main-menu wiring, planned). Keep the labels identical so
   users recognize them across both entry points.
-> HIG: "Make custom Dock menu items available in other places, too. Not
   everyone uses a Dock menu, so it's important to offer the same commands
   elsewhere, like in your menu bar menus or within your interface."

## What happens on each platform
- **iOS 26**: Not supported. HIG explicitly excludes iOS, iPadOS, tvOS,
  visionOS, and watchOS. The validation host renders an N/A placeholder card.
  iOS equivalent: Home Screen quick actions (long-press on the app icon).
  See HIG: Home Screen quick actions. Separate worklist slug (P2, UI::View
  currently missing).
- **iPadOS 26**: Not supported -- see iOS.
- **macOS 26**: AppKit builds an `NSMenu` from the item list and returns it
  from `applicationDockMenu(_:)` in `NSApplicationDelegate`. The system draws
  the menu as a Liquid Glass card (`NSVisualEffectMaterial.menu`) anchored
  to the Dock tile with a callout arrow. Separators, destructive-item red,
  and submenu indicators are all managed by AppKit when items are expressed
  as native `NSMenuItem` instances.

## HIG citations (validated)
- Dock menus -> Abstract: "On a Mac, people can secondary click an app's or
  game's icon in the Dock to reveal a Dock menu, which presents both
  system-provided and custom items."
- Dock menus -> Best practices: "As with all menus, you need to label Dock
  menu items succinctly and organize them logically."
- Dock menus -> Best practices: "Make custom Dock menu items available in
  other places, too. Not everyone uses a Dock menu, so it's important to
  offer the same commands elsewhere, like in your menu bar menus or within
  your interface."
- Dock menus -> Best practices: "Prefer high-value custom items for your
  Dock menu. For example, a Dock menu can list all currently or recently
  open windows, making it a convenient way to jump to the window people want.
  Also consider listing a few of the actions that are most likely to be
  useful when your app isn't frontmost or when there are no open windows."
- Dock menus -> Platform considerations: "Not supported in iOS, iPadOS,
  tvOS, visionOS, or watchOS."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/dock-menus.md](../validation/reports/dock-menus.md)

## Related
- `UI::MenuButton` under `components/context-menus.md` -- the secondary-
  click-on-an-item pattern (as opposed to secondary-click-on-the-Dock-tile).
- `components/home-screen-quick-actions.md` (planned) -- iOS / iPadOS
  equivalent: long-press on the Home Screen or Dock icon reveals a similar
  contextual command surface. UI::View currently missing; tracked in worklist
  as P2.
- `UI::Menu` (planned) -- menu-bar menus; HIG requires every Dock-menu
  custom item to also appear in the menu bar.
