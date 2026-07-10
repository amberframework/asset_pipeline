---
slug: digit-entry-views
ui_view: UI::TextField
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/digit-entry-views.md
validation_report: ../validation/reports/digit-entry-views.md
---

# UI::TextField (digit entry pattern)

> A full-screen PIN / passcode / OTP entry surface built from a row of
> secure `UI::TextField` cells with numeric keyboard hints. The native
> HIG "Digit entry view" (`TVDigitEntryViewController`) is tvOS-only;
> on iOS and macOS this pattern is our HIG-faithful approximation
> using the existing `UI::TextField` primitive. No Liquid Glass
> surface on iOS 26 — HIG explicitly says the component is not
> supported there.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Reach for this pattern when your app needs a short fixed-length digit
sequence — a 4 / 6 / 8-digit PIN, an SMS OTP code, a parental-controls
passcode. The HIG shape is *"a line of digits with a title and
optional prompt above, and a digit-specific keyboard below."* The
user's entire attention is on the code; no other navigation affordance
is present.

Don't reach for this pattern for free-form numeric input (phone
numbers, amounts, quantities) — that's a single `UI::TextField` with
`keyboard_type = UI::KeyboardType::NumberPad`. Don't reach for it for
credit-card entry either — that's a `UI::Form` with labeled numeric
fields. This is specifically the *full-screen, fixed-count, secure,
centered* entry shape.

(HIG: *"A digit entry view fills the entire screen and prompts people
to enter a series of digits, like a PIN, using a digit-specific
keyboard."* — Digit entry views, abstract.)

## Quickstart

```crystal
content = UI::VStack.new(spacing: 12.0)
content << UI::Label.new("Enter Passcode")
content << UI::Label.new("Enter the 6-digit code sent to your device.")

digit_row = UI::HStack.new(spacing: 8.0)
6.times do
  cell = UI::TextField.new("·")
  cell.secure_entry = true
  cell.keyboard_type = UI::KeyboardType::NumberPad
  digit_row << cell
end

content << digit_row.as(UI::View)
```

Renders: on iOS, six `UITextField` instances inside a `UIStackView`
(axis: horizontal), each with `isSecureTextEntry = YES` and
`keyboardType = .numberPad`. On macOS, six `NSSecureTextField`
instances inside an `NSStackView` (horizontal orientation). On tvOS
(not yet supported by asset_pipeline), the canonical native
implementation is `TVDigitEntryViewController`.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `placeholder` | `String` | `""` | The character shown when a cell is empty. HIG PIN dots render as `"·"` or `"•"`; empty string hides the cell affordance. |
| `secure_entry` | `Bool` | `false` | When `true`, typed digits render as asterisks. HIG: *"Always use a secure digit field when your app asks for sensitive data."* Route through `NSSecureTextField` / `UITextField.isSecureTextEntry`. |
| `keyboard_type` | `KeyboardType` | `Default` | `NumberPad` surfaces the iOS digit keypad. HIG: *"prompts people to enter a series of digits... using a digit-specific keyboard."* macOS has no hardware numeric-only keyboard so this is a no-op there. |
| `text_color` | `Color` | black `(0,0,0)` | The entered-digit color. HIG: quiet / standard label color per platform — leave default unless the surface is tinted. |
| `font` | `Font` | default system | The entered-digit typography. For digit entry, a large monospaced face (e.g. `UI::Font.new("SF Mono", 28)`) gives even kerning per cell. |
| `on_change` | `Proc(String, Nil)?` | `nil` | Fires on each typed character. For PIN UIs, gate submission on `text.size == expected_length`. |

**Planned / missing (gap-tracked):**
- `fixed_width : Float64?` — would pin each cell to an explicit width
  so the HStack doesn't collapse or stretch them. Without this, the
  current renders exhibit the "first cell eats all the room" macOS
  bug and the "all cells collapse to zero width" iOS bug documented
  in `validation/reports/digit-entry-views.md`.
- `border_style : Symbol` — would expose `:rounded` / `:bezel` /
  `:none` / `:line` so a flat-cornered HIG-style digit box can be
  selected instead of the default rounded-pill bezel.

**Theming**: `UI::Theme.apple_default.primary` (iOS `#007AFF`) for
cursor tint, standard label color for entered digits. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

This slug is SKIPPED in the worklist because HIG Platform Considerations
explicitly disclaims iOS/iPadOS/macOS/visionOS/watchOS — the native
`TVDigitEntryViewController` is tvOS-only. The asset_pipeline surrogate
documented above renders on iOS/macOS for API completeness only; it is
not expected to appear in a shipping app.

For the surrogate on iOS/macOS: each `UITextField` / `NSSecureTextField`
cell tracks system appearance natively (bezel, cursor, selection), so
entered digits are legible in both light and dark modes without extra
wiring. The surrounding prompt labels use the label conventions
documented in `components/labels.md` — they inherit the iteration-12
label-color gap.

On tvOS (not yet a build target), the native component would be
composed against the system's focus engine and dimmer-when-unfocused
chrome automatically; a future `UI::DigitEntryView` →
`TVDigitEntryViewController` map would inherit all of this.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.35, g: 0.20, b: 0.70)  # brand purple
# Affects cursor tint inside each digit cell.
```

**Replace the glass material with a flat brand surface.**
```crystal
# N/A — digit-entry is not a glass-backed surface. The cells are
# bordered text fields on a plain host background.
```

**Override typography while keeping HIG spacing.**
```crystal
# Large monospaced brand font for even kerning per cell:
cell.font = UI::Font.new(
  family: "YourBrand-Mono",
  size: 28.0,                   # large enough for thumb targets
  weight: :medium
)
# Do NOT shrink cells below the 44pt iOS hit-target minimum.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a 4-digit parental controls PIN"**
→ Copy the Quickstart but loop `4.times` and change the prompt to
"Enter your parental controls PIN." Keep `secure_entry = true`.
→ Gate `on_change` so submission fires only when `text.size == 4`.

**"I want an SMS-delivered 6-digit OTP with auto-submit"**
→ Keep `secure_entry = false` (OTP codes are not long-term secrets
and HIG doesn't require masking). Use a large monospaced font
(`UI::Font.new("SF Mono", 28)`) so pasted codes kern evenly.
→ Submit automatically when all six cells are filled; HIG: *"Use a
title and prompt that explains why someone needs to enter digits."*

## What happens on each platform
- **iOS 26**: `UITextField` per cell inside a horizontal
  `UIStackView`. No Liquid Glass wrap — HIG says the native Digit
  entry view is *not supported on iOS*, so we don't claim iOS 26 new
  chrome here. The cells are flat surfaces on the host background.
- **iPadOS 26**: same as iOS; the on-screen numeric keypad is the
  iPadOS floating variant when `keyboardType = .numberPad` is set.
- **macOS 26**: `NSSecureTextField` per cell inside a horizontal
  `NSStackView`. HIG explicitly says the native digit-entry
  component is *not supported on macOS*; this pattern is a
  best-effort asset_pipeline surrogate.
- **tvOS**: the canonical native home for this component is
  `TVDigitEntryViewController`. asset_pipeline has no tvOS renderer
  target today; an iteration that adds one can swap this pattern for
  a direct `UI::DigitEntryView` → `TVDigitEntryViewController` map.

## HIG citations (validated)
- Digit entry views → abstract: *"A digit entry view fills the
  entire screen and prompts people to enter a series of digits, like
  a PIN, using a digit-specific keyboard."*
- Digit entry views → Best practices: *"Use secure digit fields.
  Secure digit fields display asterisks instead of the entered digit
  onscreen. Always use a secure digit field when your app asks for
  sensitive data."*
- Digit entry views → Best practices: *"Clearly state the purpose of
  the digit entry view. Use a title and prompt that explains why
  someone needs to enter digits."*
- Digit entry views → Platform considerations: *"Not supported in
  iOS, iPadOS, macOS, visionOS, or watchOS."* (The native component
  is tvOS-exclusive; this asset_pipeline pattern is a surrogate.)

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/digit-entry-views.md](../validation/reports/digit-entry-views.md)

## Related
- `UI::TextField` (single field) — for free-form text / numeric input
  outside the fixed-count digit-entry shape.
- `UI::SecureField` — dedicated password entry (single field, masks
  all characters). Use for account passwords, not for short PINs.
- `components/text-fields.md` — the general `UI::TextField` guide
  that this pattern specializes.
