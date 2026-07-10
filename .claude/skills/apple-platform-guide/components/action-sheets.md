---
slug: action-sheets
ui_view: UI::Sheet
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../apple-hig/pages/action-sheets.md
validation_report: ../validation/reports/action-sheets.md
---

# UI::Sheet (action sheet pattern)

> A modal surface that presents choices related to an intentional action, rendered
> with NSVisualEffectMaterial.sheet (macOS) or UIGlassEffect / UIBlurEffect
> (iOS 26) Liquid Glass by default.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Reach for an action sheet when the user initiated an action — pressed Cancel while
editing a draft, tapped Logout, tried to discard unsaved changes — and you need to
confirm or branch that action with a small set of related choices. The HIG is clear
on when NOT to use it: this is not for system-initiated events (use `UI::Alert`),
not for revealing a menu of unrelated commands (use `UI::MenuButton`), and not for
long modal flows with form input (use a full-height `UI::Sheet`).

Destructive action goes at the top, per HIG, because it is the most noticeable
position — this is the opposite of most dialog conventions, and it matters. Cancel
goes at the very bottom to give users an easy way out.

(HIG: "Make destructive choices visually prominent. Use the destructive style for
buttons that perform destructive actions, and place these buttons at the top of the
action sheet where they tend to be most noticeable." — Action sheets / Best practices.)

## Quickstart

```crystal
content = UI::VStack.new(spacing: 8.0)
content << UI::Label.new("What should Amber do with this draft?")
content << UI::Button.new("Banish draft forever", role: :destructive)
content << UI::Button.new("Archive to vault")
content << UI::Button.new("Conjure copy")
content << UI::Button.new("Never mind", role: :cancel)

sheet = UI::Sheet.new(content.as(UI::View), surface_style: :grouped_card)
presenter = UI::SheetPresenter.new(sheet)

# When the user attempts the dangerous action:
presenter.present
# When a choice is made:
presenter.dismiss
```

Renders: on iOS 26, a UIVisualEffectView with UIGlassEffect (falling back to
UIBlurEffectStyleSystemChromeMaterial on older SDKs) with 16pt corner radius
(Amber phi-scale "sheet" token) and 16pt edge insets around the inner
UIStackView. The inner UIStackView has backgroundColor = UIColor.clear so the
glass material shows through unobstructed. On macOS 26, an NSVisualEffectView
with NSVisualEffectMaterialSheet (material 11), 16pt corner radius, WithinWindow
blending. Both materials track light and dark appearance automatically.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `content` | `UI::View?` | `nil` | The view tree inside the sheet. For action sheets, use a `UI::VStack` containing a `UI::Label` prompt followed by `UI::Button` rows. |
| `surface_style` | `Symbol` | `:auto` | `:auto` and `:grouped_card` apply Liquid Glass (NSVisualEffectView / UIVisualEffectView). `:plain` renders a bare container with no material. |
| `is_presented` | `Bool` | `false` | Drives presentation. Use `UI::SheetPresenter` rather than flipping this directly — the presenter calls `on_dismiss` on close. |
| `shows_drag_indicator` | `Bool` | `true` | iOS only. The drag handle indicating swipe-to-dismiss. Set to `false` for action sheets where only the Cancel button should dismiss. |
| `detents` | `Array(Symbol)` | `[:medium, :large]` | Allowed sheet heights. For a short action-sheet stack, set to `[:small]` so the sheet hugs the button list. |
| `selected_detent` | `Symbol` | `:medium` | Which detent to start at. |
| `on_dismiss` | `Proc(Nil)?` | `nil` | Called when the sheet is dismissed for any reason. |

**Theming**: `UI::Theme.primary` drives the Amber gold accent on normal-role buttons.
`UI::Theme.error` drives the destructive red. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

The sheet surface tracks the system appearance automatically through the platform
material APIs. On macOS the AppKit renderer allocates `NSVisualEffectView` with
`setMaterial: 11` (NSVisualEffectMaterialSheet) and `setBlendingMode: 1`
(WithinWindow). On iOS the UIKit renderer allocates `UIVisualEffectView` preferring
`UIGlassEffect` (iOS 26 only) and falling back to
`UIBlurEffect(style: .systemChromeMaterial)` — style 11 — on earlier SDKs. Both
track light and dark appearance without any application-level code.

In light mode the sheet material resolves to a frosted-white surface; in dark mode
it resolves to a dark-frosted surface tinted by the Deep Ember background
(approximately #3D2614 at 65% opacity per the Amber glass-tint token).

Text on the sheet uses `labelColor` / `secondaryLabelColor` semantics so it adapts
automatically. Destructive buttons use Amber plum (light: #5B3A94, approximately
RGB 0.357/0.227/0.580; dark: #7D59B8, approximately 0.490/0.349/0.722). This
overrides the HIG default systemRed per the Amber brand destructive mapping in
`brand/amber.md`. HIG role semantics are preserved by prominence and position
(destructive at the top, cancel at the bottom). Plum is distinguishable from
Amber gold primary in both light and dark appearances.

Contrast caveat for dark mode: plum #7D59B8 on the deep-ember dark surface
gives approximately 4.1:1 contrast. This passes WCAG AA for large text (3:1)
but falls just below the 4.5:1 target for body text. Brands placing plum on a
lighter dark surface will gain headroom; brands going darker should verify
contrast before shipping.

Cancel buttons use semibold bordered styling. Normal-role buttons use
setContentTintColor: with Amber gold (#FFAD33 light / #FFB84D dark) for the
label tint on macOS NSButton, and baseForegroundColor on iOS UIButtonConfiguration.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# The Amber theme applies Amber gold (#FFAD33) to normal-role buttons
# and Amber plum (#5B3A94) to destructive buttons by default.
# To swap both to your brand colors:
theme = UI::Theme.apple_default
theme.primary     = UI::Color.new(r: 0.118, g: 0.533, b: 0.898)  # brand blue
theme.destructive = UI::Color.new(r: 0.800, g: 0.000, b: 0.000)  # brand red
# Keep spacing, corner_radius_sheet (16pt), and font sizes HIG-default.
```
The knobs that SHOULD remain HIG-default: `spacing` (8pt row, 16pt insets),
`corner_radius_sheet` (16pt phi-scale token), `font_size_*`. The knobs that
CAN safely change: `primary` and `destructive` accent colors — but verify
contrast against the glass surface in both light and dark appearances.

**Replace the glass material with a flat brand surface.**
```crystal
sheet = UI::Sheet.new(content.as(UI::View), surface_style: :plain)
# Apply a flat brand color instead of Liquid Glass:
theme = UI::Theme.apple_default
theme.surface = UI::Color.new(r: 0.980, g: 0.965, b: 0.941)  # Amber Cream #FAF6F0
```
Warning: `surface_style: :plain` removes the HIG Liquid Glass material entirely.
The sheet will no longer blur the content beneath it, losing the translucency that
makes it feel native to iOS/macOS 26. Use only when your brand explicitly requires
an opaque, non-translucent modal surface and you have accepted the legibility
trade-off that HIG glass provides for free.

**Override typography while keeping HIG spacing.**
```crystal
# Crystal UI::Font does not yet expose a custom-family API; this is the planned knob:
# label = UI::Label.new("What should Amber do with this draft?")
# label.font = UI::Font.custom("GT-America", size: 17.0, weight: :regular)
# Until the custom-font knob lands, the renderer uses the HIG system font stack
# (SF Pro Text at sizes < 20pt, SF Pro Display at >= 20pt). Spacing tokens and
# corner radii are set independently of font — override them via UI::Theme
# spacing/radius knobs without touching font to preserve HIG geometry.
```

## Feel recipes
Short examples that map design intent to code.

**"I want the destructive action to have an icon so users cannot miss it."**
```crystal
# UI::Button#symbol (planned knob — use when available):
btn = UI::Button.new("Banish draft forever", role: :destructive)
# btn.symbol = "trash"   # prepend SF Symbol per HIG destructive-action convention
content << btn
```

**"I want the sheet to dismiss only via the explicit Cancel button, not swipe-down."**
```crystal
sheet = UI::Sheet.new(content.as(UI::View), surface_style: :grouped_card)
sheet.shows_drag_indicator = false
sheet.detents = [:small]   # hug the button stack, no large-form area to swipe in
```

## What happens on each platform
- **iOS 26**: UIVisualEffectView + UIGlassEffect (iOS 26) or UIBlurEffectStyleSystemChromeMaterial
  fallback. Bottom-anchored sheet via UIViewController.present when `is_presented: true`; inline
  grouped-card surface via UIVisualEffectView when used for validation.
- **iPadOS 26**: Same as iOS 26. HIG notes no additional considerations for iPadOS beyond iOS.
- **macOS 26**: NSVisualEffectView + NSVisualEffectMaterialSheet (material 11), WithinWindow
  blending. Window-attached sheet via NSWindow.beginSheet when `is_presented: true`; inline
  grouped-card surface for validation.

## HIG citations (validated)
- Action sheets / Best practices: "Use an action sheet — not an alert — to offer choices
  related to an intentional action."
- Action sheets / Best practices: "Make destructive choices visually prominent. Use the
  destructive style for buttons that perform destructive actions, and place these buttons at
  the top of the action sheet where they tend to be most noticeable."
- Action sheets / Best practices: "Place the Cancel button at the bottom of the action sheet."
- Action sheets / Best practices: "Aim to keep titles short enough to display on a single line."
- Action sheets / iOS, iPadOS: "Avoid letting an action sheet scroll. The more buttons an
  action sheet has, the more time and effort it takes for people to make a choice."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/action-sheets.md](../validation/reports/action-sheets.md)

## Related
- `UI::Alert` — for system-initiated events and errors, not user-initiated choices.
- `UI::MenuButton` — for revealing unrelated commands from a button or toolbar icon.
- `UI::ConfirmationDialog` — single destructive confirmation without action branching.
- `UI::Sheet` (full-height, non-action pattern) — for longer modal flows with form input.
- `recipes/destructive-confirmation.md` — multi-component pattern pairing action sheet
  with undo toast.
