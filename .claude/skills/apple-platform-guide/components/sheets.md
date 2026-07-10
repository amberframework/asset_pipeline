---
slug: sheets
ui_view: UI::Sheet
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/sheets.md
validation_report: ../validation/reports/sheets.md
---

# UI::Sheet

> A sheet helps people perform a scoped task closely related to their current
> context; by default it renders with a Liquid Glass surface --
> NSVisualEffectView (material: NSVisualEffectMaterialSheet = 11, tracks
> appearance) on macOS 26 and UIVisualEffectView+UIGlassEffect on iOS 26.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A sheet interrupts the current flow to collect focused input or confirm a
consequential decision before the user returns to the parent context. It is
the right choice when the task is scoped (filling in a form, attaching a file,
choosing a save location) and finite -- the user completes it and comes back.
It is NOT the right choice for open-ended tasks, media-viewing sessions, or
multi-document editing workflows; those should be a full-screen modal view,
a separate window (macOS), or a panel.

(HIG: "Provide an alternative to the Done button. If you provide a Done button,
always pair it with a Cancel button to give people a clear way to dismiss the
sheet without confirming or saving their changes." -- Sheets / Best practices.)

On iOS 26 / iPadOS 26 a sheet slides up from the bottom, supports multiple
detents (medium, large, custom), shows a grabber when resizable, and can be
nonmodal (people interact with the parent view without dismissing). On macOS 26
a sheet is always modal -- a centered card that dims its parent window.

## Quickstart

```crystal
# Sheet body: 17pt semibold title, form rows, Cancel + Save action bar.
sh_title = UI::Label.new("Add Reminder")
sh_title.font = UI::Font.new(size: 17.0, weight: :semibold)
sh_title.accessibility_label = "Sheet title"

sh_form = UI::VStack.new(spacing: 10.0)
sh_form << UI::Label.new("Title:")
sh_form << UI::TextField.new("Reminder name")
sh_form << UI::Label.new("Date:")
sh_form << UI::TextField.new("e.g. Apr 15, 2026")

sh_cancel = UI::Button.new("Cancel", role: :cancel)
sh_cancel.accessibility_label = "Cancel sheet"
sh_save   = UI::Button.new("Save",   role: :default)
sh_save.accessibility_label = "Save reminder"

sh_actions = UI::HStack.new(spacing: 12.0)
sh_actions << sh_cancel
sh_actions << UI::Spacer.new
sh_actions << sh_save

sh_body = UI::VStack.new(spacing: 12.0)
sh_body << sh_title
sh_body << UI::Divider.new
sh_body << sh_form
sh_body << UI::Divider.new
sh_body << sh_actions

# Inline render (surface_style: :grouped_card) for visual capture / preview.
# Production: set is_presented: true and use UI::SheetPresenter to trigger
# the platform modal lifecycle.
sheet = UI::Sheet.new(sh_body.as(UI::View), surface_style: :grouped_card)
```

Renders: on iOS 26, UIVisualEffectView+UIGlassEffect with 12pt corner radius,
supporting UISheetPresentationController detents; on macOS 26,
NSVisualEffectView (NSVisualEffectMaterialSheet = 11, tracks appearance) with
12pt corner radius and inner NSStackView with 16pt insets. The macOS sheet is
top-anchored at the titlebar (44pt offset from window top), 540pt wide, with
a dimming overlay behind it.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `content` | `UI::View?` | `nil` | The view tree rendered inside the sheet surface. All subviews should have transparent backgrounds so the glass material shows through. |
| `is_presented` | `Bool` | `false` | When `true`, the renderer triggers the platform modal lifecycle (NSWindow sheet / UISheetPresentationController). When `false`, the sheet surface renders inline into the host view tree (used for screenshots and previews). |
| `shows_drag_indicator` | `Bool` | `true` | Controls `UISheetPresentationController.prefersGrabberVisible` on iOS. The grabber is a thin pill at the top of the sheet that indicates drag-to-resize. Has no effect on macOS. |
| `detents` | `Array(Symbol)` | `[:medium, :large]` | Passed to `UISheetPresentationController.detents` on iOS. `:medium` rests at approximately half the screen height; `:large` is full-height. Has no effect on macOS (sheets are always full-height on macOS). |
| `selected_detent` | `Symbol` | `:medium` | The initial resting detent on iOS. |
| `on_dismiss` | `Proc(Nil)?` | `nil` | Callback invoked by `UI::SheetPresenter#dismiss`. |
| `surface_style` | `Symbol` | `:auto` | `:auto` / `:grouped_card` compose a Liquid Glass surface; `:plain` renders a bare container with no chrome (useful for brand-flat overrides). |

**Theming**: `UI::Theme.primary` drives action-button tint; `UI::Theme.label_primary` drives title and label text; `UI::Theme.font_size_title` and `font_size_body` drive typography sizes. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** NSVisualEffectView material 11 (NSVisualEffectMaterialSheet)
resolves to a light-frosted fill (~0.94 RGB). `NSColor.labelColor` resolves to
near-black (~0.0 RGB) for the title and form labels -- contrast ~18:1 against the
frosted fill. `NSColor.separatorColor` resolves to a mid-gray (~0.6 RGB) 1pt line
for the dividers. Action buttons use `NSColor.controlAccentColor` (system blue or
brand Amber gold for the prominent CTA) -- contrast against frosted background at
least 4.8:1. The dimming overlay behind the card uses 30% black alpha.

**macOS dark:** The same NSVisualEffectView material 11 resolves to a dark-frosted
fill (~0.18 RGB) in NSAppearanceNameDarkAqua. `NSColor.labelColor` dark resolves
to near-white (~1.0 RGB) -- contrast ~17:1. Action buttons: system blue adjusted
(~0.0/0.518/1.0) or Amber gold, contrast ~6.0:1. Dividers use
`NSColor.separatorColor` dark (~0.3 RGB); visible as shape against the dark fill.
Typography weight does not auto-thin in DarkAqua for NSVisualEffectView content.
Dimming overlay: 50% black alpha.

**iOS light:** UIVisualEffectView+UIGlassEffect (iOS 26) / UIBlurEffect(style=
UIBlurEffectStyleSystemChromeMaterial=11) resolves to a light-frosted fill
(~0.94 RGB). `UIColor.label` (~0.0 RGB) contrast ~18:1. Action buttons
`UIColor.tintColor` system blue ~4.8:1 against frosted background. Placeholder
text `UIColor.placeholderText` (~0.6 RGB) against field background -- acceptable
for secondary text. The 12pt corner radius on the outer UIVisualEffectView clips
the card cleanly.

**iOS dark:** UIVisualEffectView dark resolves to a dark fill (~0.14 RGB).
`UIColor.label` dark (~1.0 RGB) contrast ~20:1. `UIColor.tintColor` dark
(~0.039/0.518/1.0) contrast ~6.2:1. Placeholder text `UIColor.placeholderText`
dark (~0.45 RGB) contrast ~3.2:1 -- above the 3:1 minimum for secondary text.

**Contrast caution:** if a brand override swaps the sheet background to a custom
color (via `surface_style: :plain` + background token), verify that the new
background provides sufficient contrast against `UI::Theme.label_primary` in both
appearances. The HIG glass materials automatically track the system appearance and
maintain legibility; a flat custom color requires manual verification.

**SF Symbols:** No SF Symbols are embedded in the sheet surface itself. Any symbols
in the sheet's content tree (e.g. action-button leading icons) should use the
`.hierarchical` rendering mode for best appearance tracking.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override the theme primary color so action buttons and focused fields
# use your brand blue instead of system blue. Hit targets, spacing, and
# typography stay HIG-default.
theme = UI::Theme::Colors.new
theme.primary = UI::Theme::ThemeColor.new(r: 0.0, g: 0.38, b: 0.8)
# Apply theme globally or pass to the renderer context.
# The Cancel and Save buttons inherit tint from theme.primary via
# NSColor.controlAccentColor override (macOS) / UIView.tintColor (iOS).
```

**Replace the glass material with a flat brand surface.**
```crystal
# surface_style: :plain disables the Liquid Glass NSVisualEffectView /
# UIVisualEffectView and renders a bare container. Supply your own
# background color via a wrapping UI::ZStack or a background property.
# WARNING: this removes appearance-tracking and backdrop bleed-through.
# You must verify legibility in both light and dark manually.
flat_sheet = UI::Sheet.new(body_view, surface_style: :plain)
# Wrap in a ZStack to supply a flat brand background:
# bg = UI::RoundedRectangle.new(radius: 12.0)
# bg.background_color = UI::Color.new(r: 0.96, g: 0.97, b: 1.0)
# container = UI::ZStack.new; container << bg; container << flat_sheet
```

**Override typography while keeping HIG spacing.**
```crystal
# Replace system font with a brand font on the title label.
# Keep the 17pt size and :semibold weight -- HIG mandates these for sheet
# titles to ensure legibility. Only the family name changes.
sh_title = UI::Label.new("Add Reminder")
sh_title.font = UI::Font.new(size: 17.0, weight: :semibold, family: "YourBrandFont")
# Form row labels: 14pt :regular. Keep the size; vary the family only.
row_label = UI::Label.new("Title:")
row_label.font = UI::Font.new(size: 14.0, weight: :regular, family: "YourBrandFont")
```

## Feel recipes
Short examples that map design intent to code.

**"I want a half-height sheet that people can drag to expand"**
-> Set `detents: [:medium, :large]` (default) and `shows_drag_indicator: true`
   (default). On iOS the sheet rests at medium height initially; dragging the
   grabber or scrolling content expands to large.

**"I want a confirmation sheet that cannot be dismissed without a choice"**
-> Set `is_presented: true`, omit the Cancel button from the action bar, and
   include only a primary action (e.g. "Delete"). On iOS this blocks swipe-to-
   dismiss; pair with an `on_dismiss` callback that re-presents the sheet if
   called without explicit confirmation. HIG: "Display only one sheet at a
   time from the main interface."

## What happens on each platform
- **iOS 26**: UIVisualEffectView wrapping UIGlassEffect (iOS 26 runtime) or
  UIBlurEffect(style: .systemChromeMaterial) on older SDKs. Inner UIStackView
  in the effect's `contentView`. Full presentation: UISheetPresentationController
  with configurable detents, grabber, and swipe-to-dismiss.
- **iPadOS 26**: Same UIVisualEffectView surface. HIG recommends page or form
  sheet presentation styles on iPad (`UIModalPresentationStyle.pageSheet` /
  `.formSheet`) which center the sheet over a dimmed parent.
- **macOS 26**: NSVisualEffectView (NSVisualEffectMaterialSheet = 11,
  blendingMode: .withinWindow = 1, state: .active = 1). 12pt corner radius. Inner
  NSStackView with 16pt edge insets, anchor-constrained to the effect view. Sheet
  is top-anchored at 44pt from window top (titlebar height), 540pt wide, with a
  30% (light) / 50% (dark) black dimming overlay between the chrome and the card.
  Full presentation: `NSViewController.presentAsSheet(_:)` / `NSWindow.beginSheet`.

## HIG citations (validated)
- Sheets -> Abstract: "A sheet helps people perform a scoped task that's closely
  related to their current context."
- Sheets -> Best practices: "Provide an alternative to the Done button. If you
  provide a Done button, always pair it with a Cancel button to give people a
  clear way to dismiss the sheet without confirming or saving their changes."
- Sheets -> Best practices: "Display only one sheet at a time from the main
  interface. When people close a sheet, they expect to return to the parent view
  or window."
- Sheets -> Platform considerations -> iOS, iPadOS: "Include a grabber in a
  resizable sheet. A grabber shows people that they can drag the sheet to resize
  it; they can also tap it to cycle through the detents."
- Sheets -> Platform considerations -> macOS: "In macOS, a sheet is a cardlike
  view with rounded corners that floats on top of its parent window. The parent
  window is dimmed while the sheet is onscreen."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/sheets.md](../validation/reports/sheets.md)

## Related
- `UI::Alert` -- when you need a title + message + up to three action buttons
  with no form content; alert is shorter and more disruptive than a sheet.
- `UI::Popover` -- when the task originates from a specific control and the
  presentation should be anchored (arrow pointing to the source).
- `recipes/modal-form.md` -- multi-step form pattern combining UI::Sheet,
  UI::NavigationStack, and UI::Form.
