---
title: Hierarchy and emphasis
topic: visual-hierarchy
hig_pages:
  - buttons.md
  - layout.md
---

# Hierarchy and emphasis

## What it means

In an Apple UI, hierarchy is expressed through *style* (color, weight, material)
more than *size*. Buttons are the clearest example: a "primary" button uses the
app's accent color for its background, a "destructive" button uses system red
for its label, and a "cancel" button uses the plain style. All three can be the
same physical size and still communicate wildly different levels of prominence.

The HIG is direct on this:

- **Use a prominent visual style for the most likely action in a view.**
- **Keep prominent buttons to one or two per view.** Too many prominent buttons
  increase cognitive load.
- **Use style, not size, to distinguish the preferred option.** Two buttons of
  different sizes near each other reads as inconsistent; two buttons of the same
  size with different styles reads as a coherent set with a recommended choice.

Button roles (from HIG):

| Role | Meaning | Visual |
|------|---------|--------|
| Normal | No specific meaning | Plain |
| Primary | The default, most-likely choice | Accent-color background |
| Cancel | Cancels the current action | Plain |
| Destructive | Performs action that can destroy data | System-red label |

And one critical rule: **never assign the Primary role to a destructive action.**
People pick primary buttons quickly without reading — use the plain or
destructive role for anything that can lose data.

## How it's expressed in asset_pipeline

`UI::Button` today exposes label, font, foreground color, disabled state, and a
tap callback (source: `src/ui/views/button.cr`):

```crystal
class Button < View
  property label : String
  property font : Font = Font.new
  property foreground_color : Color = Color.new(r: 0.0, g: 0.478, b: 1.0)
  property disabled : Bool = false
  property on_tap : Proc(Nil)? = nil
end
```

**A semantic `role` property is planned.** Today you express role by hand:

- **Primary.** Wrap in `UI::GlassBackground` with `:regular` material and a
  white foreground color, or set `foreground_color` and a pigmented background
  directly. Set `font.weight = :semibold`. The iOS 26 renderer applies Liquid
  Glass automatically on platform system-like controls.
- **Destructive.** Set `foreground_color = UI::Color.new(r: 1.0, g: 0.23, b: 0.19)`
  (the Apple system red, matching `Theme.apple_default.error`).
- **Cancel.** Leave defaults — plain accent-blue label, no background.

Example — a three-button footer following HIG conventions:

```crystal
cancel = UI::Button.new("Cancel") { presenter.dismiss }

destructive = UI::Button.new("Delete") { delete_and_dismiss }
destructive.foreground_color = UI::Color.new(r: 1.0, g: 0.23, b: 0.19)

save = UI::Button.new("Save") { save_and_dismiss }
save.foreground_color = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)
save.font = UI::Font.new(size: 17.0, weight: :semibold)
save_glass = UI::GlassBackground.new(content: save, material: :regular)
save_glass.corner_radius = 10.0
save_glass.padding = UI::EdgeInsets.new(top: 10.0, trailing: 20.0, bottom: 10.0, leading: 20.0)

footer = UI::HStack.new(spacing: 12.0)
footer << cancel
footer << destructive
footer << UI::Spacer.new
footer << save_glass
```

**Never put two prominent buttons in the same row.** If the UI seems to need it,
reconsider — one action is usually primary and the other a
cancel/secondary.

### Hierarchy beyond buttons

The same principle applies to other controls:

- `UI::Label` — weight and color carry hierarchy. Title labels use
  `Font.new(size: theme.font_size_title, weight: :semibold)`; body uses
  defaults; captions use smaller size + `on_surface_variant` color.
- `UI::Toggle` — the HIG treats toggles as settings, not primary actions; don't
  put a Toggle in a spot that needs commit/cancel — use a pair of buttons.
- `UI::SegmentedControl` — communicates a set of equal-weight choices; if one
  choice is meaningfully more likely, use separate buttons instead.

## HIG citations

- **Buttons → Best practices**: "Use a button that has a prominent visual style
  for the most likely action in a view. … Keep the number of prominent buttons
  to one or two per view." (`pages/buttons.md`)
- **Buttons → Best practices**: "Use style — not size — to visually distinguish
  the preferred choice among multiple options." (`pages/buttons.md`)
- **Buttons → Role**: the four role definitions (Normal / Primary / Cancel /
  Destructive). (`pages/buttons.md`)
- **Buttons → Role**: "Don't assign the primary role to a button that performs a
  destructive action, even if that action is the most likely choice."
  (`pages/buttons.md`)
- **Layout → Visual hierarchy**: "Place items to convey their relative
  importance." (`pages/layout.md`)
