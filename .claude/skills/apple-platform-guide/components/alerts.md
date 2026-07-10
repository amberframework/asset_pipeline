---
slug: alerts
ui_view: UI::Alert
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/alerts.md
validation_report: ../validation/reports/alerts.md
---

# UI::Alert

> A modal surface component that gives people critical information they need right away, rendered with NSVisualEffectView (hudWindow material) on macOS 26 and UIVisualEffectView (UIGlassEffect on iOS 26, UIBlurEffectStyleSystemMaterial fallback) on iOS — Liquid Glass by default.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

An alert is the strongest interruption pattern in the HIG toolkit. It suspends the current task and demands a response before the person can continue. Reserve it for situations where the information is critical and the action is non-trivial — a destructive action the person cannot undo, a purchase confirmation, an error that blocks further progress. An alert is NOT the right tool for purely informational messages or for frequent, undoable operations (deleting an email does not warrant an alert; destroying an account does).

The canonical use case is a three-button destructive confirmation: a bold title naming the situation, an informative message sentence, and three role-differentiated buttons — Cancel (leading/bottom, semibold), a default confirmation (trailing/top), and a destructive action (red) that names the action specifically rather than using a generic label.

(HIG: "Use the destructive style to identify a button that performs a destructive action people didn't deliberately choose." — Alerts / Buttons.)

## Quickstart

```crystal
alert = UI::Alert.new("Delete Item?", "This action cannot be undone.")
alert.add_button("Cancel", :cancel)
alert.add_button("OK", :default)
alert.add_button("Delete", :destructive)
```

Renders: on macOS, `NSVisualEffectView` (hudWindow material = 7) containing an `NSStackView` with a bold title `NSTextField`, secondary message `NSTextField`, and an `NSStackView` button row of `NSButton` (NSBezelStyleRounded) with role-colored attributed titles. On iOS 26, `UIVisualEffectView` (`UIGlassEffect`) containing a `UIStackView` with `UILabel` title/message and `UIButton(system)` cells with tint-color role coloring. Both renderers apply `~12pt` corner radius.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `title` | `String` | (required) | Bold title text displayed at the top of the alert card; should name the situation clearly and succinctly per HIG. |
| `message` | `String` | `""` | Secondary message text in regular weight below the title; omitted when empty so no empty space is reserved. |
| `buttons` | `Array(AlertButton)` | `[]` | Ordered list of action buttons; each button has `label`, `style` (`:default`, `:cancel`, `:destructive`), and optional `action : Proc(Nil)?`. |
| `is_presented` | `Bool` | `false` | When `true`, signals that the caller will present the alert modally (production path). The inline glass-card render is the `false` / validation path. |

**Theming**: `UI::Theme.primary` (system blue, default button color), `UI::Theme.error` (system red, destructive button color), `UI::LabelRole::Primary` / `::Secondary` (title / message text colors). See `foundations/color-and-theming.md`.

## Light / dark appearance notes

The alert card uses appearance-tracking system materials and semantic colors throughout, so light and dark appearance work without any per-appearance code.

**macOS — material:** `NSVisualEffectMaterialHUDWindow` (= 7). In light mode the material resolves to a translucent light gray with a subtle rim highlight. In dark mode it resolves to a dark charcoal with the same glass-edge characteristic. The material is set with `NSVisualEffectBlendingModeBehindWindow` and `NSVisualEffectStateActive` so it stays live regardless of window focus.

**iOS — material:** `UIGlassEffect` on iOS 26 (runtime class check via `objc_getClass("UIGlassEffect")`). Fallback to `UIBlurEffect(style: UIBlurEffectStyleSystemMaterial)` (= 7) on iOS 15–25. Both track appearance automatically via the `UIVisualEffectView` compositing pipeline.

**Title color:** `nscolor_label_primary` — resolves to `NSColor.labelColor` (macOS) / `UIColor.labelColor` (iOS). Light: approximately `0.0/0.0/0.0` (black). Dark: approximately `1.0/1.0/1.0` (white). No baked RGBA — fully appearance-tracking.

**Message color:** `nscolor_label_secondary` — resolves to `NSColor.secondaryLabelColor` / `UIColor.secondaryLabelColor`. Light: approximately `0.24/0.24/0.26` at 55% opacity (dark gray). Dark: approximately `0.92/0.92/0.96` at 55% opacity (light gray). Legible in both appearances.

**Destructive button color:** `NSColor.systemRedColor` / `UIColor.systemRedColor`. Light: approximately `1.0/0.23/0.19`. Dark: approximately `1.0/0.27/0.23` (slightly brighter for dark background contrast). Distinguishable from system blue in both appearances.

**Cancel button font:** `nsfont_system_weight(size, 0.4)` — weight 0.4 maps to Semibold in the system font weight scale. This is HIG-mandated: cancel actions on presentation surfaces use Semibold to signal "safe exit."

**Contrast caveats:** If you override `message` to a very long string, `NSColor.secondaryLabelColor` in light mode at 55% opacity may read around 3.8:1 against the light hudWindow fill — below the 4.5:1 body-text target. Keep messages short (one sentence). If you must use longer text, set a larger font size via the `add_button` path or use a primary label color for the message instead.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's legibility, hit targets, or appearance-tracking._

**Swap the default button accent to your brand primary.**
```crystal
# The default and cancel button colors resolve from system blue (0.0/0.478/1.0).
# To use a brand primary, supply a custom action proc and set tint at the
# UIButton / NSButton level after rendering, or override UI::Theme.primary
# before constructing the alert. The destructive button MUST stay system red —
# do not override that role color.
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.4, g: 0.2, b: 0.8) # Brand purple
# Pass theme to the renderer (planned — renderer uses baked colors today).
# What CAN safely change: default and cancel button tint.
# What MUST stay HIG-default: destructive red, semibold cancel weight,
# 12pt corner radius, appearance-tracking label colors.
```

**Replace the glass surface with a flat brand card.**
```crystal
# Build the alert content manually using UI::VStack + UI::Sheet(surface_style: :plain).
# This removes UIGlassEffect / NSVisualEffectView entirely.
# WARNING: removing Liquid Glass on a presentation surface deviates from HIG.
# Acceptable only for highly branded contexts where glass is incompatible
# with the brand language. Test legibility in dark mode carefully — flat
# backgrounds do not auto-track appearance.
content = UI::VStack.new(spacing: 8.0)
content << UI::Label.new("Delete Item?")
content << UI::Label.new("This action cannot be undone.")
content << UI::Button.new("Cancel", role: :cancel)
content << UI::Button.new("Delete", role: :destructive)
UI::Sheet.new(content.as(UI::View), surface_style: :plain)
```

**Override typography while keeping HIG spacing.**
```crystal
# UI::Alert does not expose a font knob on the view directly.
# To substitute a brand font, build the content manually as a VStack and
# set font on each UI::Label and UI::Button individually.
title_label = UI::Label.new("Delete Item?")
title_label.font = UI::Font.new(family: "Georgia", size: 13.0, weight: :bold)
# Keep the HIG-mandated 8pt spacing between elements (passed to VStack.new(spacing: 8.0))
# and the 16pt edge insets (passed to UI::Sheet or the renderer's built-in glass card).
# Do not reduce spacing below 8pt or font size below 11pt (message) / 13pt (title).
```

## Feel recipes
Short examples that map design intent to code.

**"I want a simple informational alert with one dismissal button."**
```crystal
alert = UI::Alert.new("No Internet Connection", "Check your network settings and try again.")
alert.add_button("OK", :default)
```
Do not use Cancel for a single-button informational alert — HIG: "If you must display an alert with a single button that's also the default, use a Done button, not a Cancel button."

**"I want a purchase confirmation alert with a default confirmation and a cancel."**
```crystal
alert = UI::Alert.new("Confirm Purchase", "Buy Pro subscription for $4.99/month?")
alert.add_button("Cancel", :cancel)
alert.add_button("Subscribe", :default)
```
No destructive style here — the action is intentional (HIG: "when people deliberately choose a destructive action... the resulting alert doesn't apply the destructive style").

## What happens on each platform
- **iOS 26**: `UIVisualEffectView` wrapping `UIGlassEffect` (runtime check). Inner `UIStackView` (vertical) with title `UILabel` (bold, UIColor.labelColor), message `UILabel` (regular, UIColor.secondaryLabelColor), and horizontal `UIStackView` (distributionFillEqually) of `UIButton(system)` cells. Cancel tinted system blue semibold; default tinted system blue regular; destructive tinted system red. 44pt minimum height per button.
- **iPadOS 26**: Same as iOS. On iPad, UIAlertController in production renders as a popover; the inline validation render is identical to iPhone.
- **macOS 26**: `NSVisualEffectView` (NSVisualEffectMaterialHUDWindow = 7, blendingMode = BehindWindow, state = Active). Inner `NSStackView` (vertical) with title `NSTextField` (bold, NSColor.labelColor), message `NSTextField` (regular, NSColor.secondaryLabelColor), and vertical `NSStackView` button row of `NSButton` (NSBezelStyleRounded) with role-colored attributed titles. Cancel semibold system blue; default regular system blue; destructive regular system red.

## HIG citations (validated)
- Alerts / Best practices: "Use alerts sparingly. Alerts give people important information, but they interrupt the current task to do so."
- Alerts / Best practices: "Avoid using an alert merely to provide information. People don't appreciate an interruption from an alert that's informative, but not actionable."
- Alerts / Buttons: "Use the destructive style to identify a button that performs a destructive action people didn't deliberately choose."
- Alerts / Buttons: "Always use 'Cancel' to title a button that cancels the alert's action."
- Alerts / Buttons: "Place buttons where people expect. In general, place the button people are most likely to choose on the trailing side in a row of buttons or at the top in a stack of buttons. Always place the default button on the trailing side of a row or at the top of a stack."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/alerts.md](../validation/reports/alerts.md)

## Related
- `UI::Sheet` — when you need a bottom sheet or card presentation rather than an interruptive modal alert
- `UI::ConfirmationDialog` — for destructive confirmations on iOS that prefer the action-sheet pattern over the centered alert card
- `recipes/destructive-confirmation.md` — multi-component pattern combining UI::Alert with UI::Button role wiring
