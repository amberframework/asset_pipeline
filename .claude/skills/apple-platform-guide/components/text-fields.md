---
slug: text-fields
ui_view: UI::TextField
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/text-fields.md
validation_report: ../validation/reports/text-fields.md
---

# UI::TextField

> A single-line editable text input with bordered rounded-rect chrome (NSTextField
> rounded bezel on macOS, UITextField rounded-rect border on iOS), supporting
> placeholder text, filled-value display, secure (password) entry, and keyboard-type
> hints -- no Liquid Glass material required; text fields are content controls, not
> surface containers.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

`UI::TextField` is the right choice when you need a short, focused piece of text from
the user: a name, an email address, a search query, an amount, or a password. It is
NOT the right choice for multi-line input (use `UI::TextArea` / `UI::TextEditor` for
that) or for structured selection from a list (use `UI::Picker` or a combo box).

The HIG requires that every text field either has a placeholder that describes what to
type, or is paired with a visible label that provides that context. Both are acceptable;
using both (label above, placeholder inside) is the clearest pattern.

(HIG: "Show a hint in a text field to help communicate its purpose. A text field can
contain placeholder text -- such as 'Email' or 'Password' -- when there's no other
text in the field. Because placeholder text disappears when people start typing, it can
also be useful to include a separate label describing the field to remind people of its
purpose." -- Text fields / Best practices.)

## Quickstart

```crystal
# Four-field form: empty with placeholder, filled, secure, numeric.
form = UI::VStack.new(spacing: 14.0)

# Row 1: Name (empty, placeholder visible)
name_row = UI::VStack.new(spacing: 4.0)
name_lbl = UI::Label.new("Name:")
name_lbl.accessibility_label = "Name label"
name_field = UI::TextField.new("Your name")
name_field.accessibility_label = "Name field"
name_row << name_lbl.as(UI::View)
name_row << name_field.as(UI::View)
form << name_row.as(UI::View)

# Row 2: Email (pre-filled value)
email_row = UI::VStack.new(spacing: 4.0)
email_lbl = UI::Label.new("Email:")
email_lbl.accessibility_label = "Email label"
email_field = UI::TextField.new("Email address")
email_field.text = "alice@example.com"
email_field.keyboard_type = UI::KeyboardType::EmailAddress
email_field.accessibility_label = "Email field"
email_row << email_lbl.as(UI::View)
email_row << email_field.as(UI::View)
form << email_row.as(UI::View)

# Row 3: Password (secure entry)
pw_row = UI::VStack.new(spacing: 4.0)
pw_lbl = UI::Label.new("Password:")
pw_lbl.accessibility_label = "Password label"
pw_field = UI::TextField.new("Password")
pw_field.secure_entry = true
pw_field.accessibility_label = "Password field"
pw_row << pw_lbl.as(UI::View)
pw_row << pw_field.as(UI::View)
form << pw_row.as(UI::View)

# Row 4: Numeric amount (number-pad keyboard on iOS)
amt_row = UI::VStack.new(spacing: 4.0)
amt_lbl = UI::Label.new("Amount:")
amt_lbl.accessibility_label = "Amount label"
amt_field = UI::TextField.new("0.00")
amt_field.keyboard_type = UI::KeyboardType::NumberPad
amt_field.accessibility_label = "Amount field"
amt_row << amt_lbl.as(UI::View)
amt_row << amt_field.as(UI::View)
form << amt_row.as(UI::View)
```

Renders: macOS produces NSTextField (or NSSecureTextField when `secure_entry` is true)
with NSTextFieldRoundedBezel chrome; iOS produces UITextField with
UITextBorderStyleRoundedRect border. Text color defaults to NSColor.labelColor /
UIColor.labelColor for appearance-tracking across light and dark modes.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `placeholder` | `String` | `""` | Hint text shown in secondary color when the field is empty; disappears when the user begins typing. |
| `text` | `String` | `""` | Pre-populated text value shown in primary color. |
| `font` | `UI::Font` | `UI::Font.new` | Font applied to both the placeholder and the filled text. |
| `text_color` | `UI::Color` | `Color{r:0,g:0,b:0,a:1}` (sentinel -- resolves to system labelColor) | Explicit RGBA text color override; set to a non-sentinel value to apply a brand color instead of the appearance-tracking system label color. |
| `secure_entry` | `Bool` | `false` | When true, renders as NSSecureTextField (macOS) or UITextField with secureTextEntry=true (iOS), hiding input as bullet characters. |
| `keyboard_type` | `UI::KeyboardType` | `KeyboardType::Default` | Keyboard variant shown on iOS/iPadOS. `EmailAddress`, `NumberPad`, `PhonePad`, `URL`, or `Default`. Has no visible effect on macOS. |
| `on_change` | `Proc(String, Nil)?` | `nil` | Callback invoked when the text value changes. Receives the current string. Wired to `controlTextDidChange:` (macOS) or `UIControlEventEditingChanged` (iOS). |
| `accessibility_label` | `String?` | `nil` | VoiceOver label. Required on every interactive element. |

**Theming**: `UI::Theme#font_size_body`, `UI::Theme#font_family`,
`UI::Theme#corner_radius_small` (4pt), `UI::Theme#corner_radius_medium` (8pt).
The text_color sentinel detects the default Color struct and substitutes
`NSColor.labelColor` / `UIColor.labelColor` automatically.
See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS (Aqua / DarkAqua):**
- Text color: when `text_color` is the default sentinel, the renderer substitutes
  `nscolor_label_primary` which resolves to `NSColor.labelColor`. In Aqua this is
  near-black ~0.0 RGB; in DarkAqua it is near-white ~0.95 RGB. The transition is
  automatic and appearance-tracking.
- Placeholder text: NSTextField renders placeholder in NSColor.placeholderTextColor,
  a system-managed secondary gray that tracks both Aqua and DarkAqua automatically.
  In light mode ~0.50 RGB; in dark mode ~0.55 RGB.
- Field background: NSTextField with drawsBackground=1 renders white in Aqua and
  a dark fill ~0.18-0.20 RGB in DarkAqua. This is the standard NSTextField behavior.
- Border: the rounded bezel border adapts to appearance. In Aqua it is a light gray
  ~0.80 RGB; in DarkAqua it is a medium gray ~0.35 RGB.
- No SF Symbol is used by default. A leading SF Symbol can be added by embedding an
  `UI::Image` in an HStack with the text field (no dedicated knob).

**iOS (light / dark):**
- Text color: same labelColor-sentinel pattern, using `UIColor.labelColor`. Light mode
  near-black; dark mode near-white. Both appearances tracked automatically.
- Placeholder text: UITextField uses `UIColor.placeholderTextColor`, an appearance-
  tracking system color. Light ~0.50 RGB; dark ~0.55 RGB.
- Field background: UITextBorderStyleRoundedRect with no explicit background color
  renders the UITextField with the system-default rounded-rect appearance, which is
  white in light mode and a dark fill (~0.12 RGB) in dark mode.
- Border: the rounded-rect border visibility depends on the UITextField's background
  and tint colors which track the appearance.
- Secure entry: UITextField.secureTextEntry=true hides typed text as bullet dots at
  runtime. In static screenshots (XCUITest snapshots) the field appears visually empty
  because the field is not first responder. This is expected UIKit behavior.

**Contrast caveats:**
- Overriding `text_color` to a brand RGBA disables the labelColor tracking. A brand
  color that works in light mode may be invisible in dark mode if it is a dark hue.
  Always verify both appearances when setting an explicit text_color.
- Placeholder contrast is intentionally lower than primary text (HIG convention for
  hints). Avoid using a brand color for placeholder text that is lighter than the
  system secondary gray -- it will fail WCAG 1.4.3 contrast for informational text.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the text color to your brand primary while keeping appearance-tracking.**
```crystal
# Caution: setting an explicit RGBA disables appearance-tracking.
# The example below sets a dark navy that works in light mode but will be
# illegible in dark mode. Prefer using the default (which auto-tracks) unless
# you have a dynamic brand color that resolves correctly in both modes.
field = UI::TextField.new("Your name")
field.text_color = UI::Color.new(r: 0.07, g: 0.12, b: 0.31)  # brand navy
# For dark-mode-safe brand color, wrap in an appearance check or use a theme token.
```

**Override the font to your brand typeface while keeping HIG field geometry.**
```crystal
field = UI::TextField.new("Your name")
# UI::Font.custom keeps the HIG-mandated 17pt body size on iOS (system default).
# Changing only the family preserves line height, spacing, and field height.
field.font = UI::Font.new(size: 17.0, family: "YourBrandFont-Regular")
# Hit target (UITextField height >= 34pt) and border are unaffected by font changes.
```

**Disable the HIG-default bordered chrome for a minimal inline brand appearance.**
```crystal
# On iOS: UITextBorderStyleNone is achieved by NOT setting secure_entry and
# overriding the background via the parent view. There is no direct borderStyle
# knob on UI::TextField today (the renderer always applies RoundedRect).
# To get a borderless field, embed the TextField in a custom-styled HStack and
# rely on the parent container for visual delineation.
# NOTE: removing the border removes the HIG-mandated affordance cue that the
# control is tappable. Ensure an alternative affordance (underline, background
# highlight) is present. See HIG text-fields Best practices: "match the size of
# a text field to the quantity of anticipated text" -- users expect bordered fields.
inline_stack = UI::HStack.new(spacing: 8.0)
icon = UI::Image.new("envelope")
field = UI::TextField.new("Email")
field.keyboard_type = UI::KeyboardType::EmailAddress
inline_stack << icon.as(UI::View)
inline_stack << field.as(UI::View)
```

## Feel recipes
Short examples that map design intent to code.

**"I want a form row where the label sits above the field."**
- Create a `UI::VStack` with `spacing: 4.0`.
- Add a `UI::Label` as the first child; set `accessibility_label` on it.
- Add a `UI::TextField` as the second child; set `accessibility_label` on it.
- Wrap multiple rows in an outer `UI::VStack` with `spacing: 14.0` for the
  evenly-spaced multi-field layout HIG recommends.

**"I want a password field that shows the user's existing value."**
- Set `secure_entry = true` and `text = "existing_password_hash"`.
- The bullets will appear on macOS (NSSecureTextField renders them even when
  not focused). On iOS, the dots appear once the user focuses the field.
- Always provide a "Show password" toggle (a separate `UI::ToggleButton` or
  a trailing button) as an accessibility aid per HIG recommendation.

## What happens on each platform
- **iOS 26**: UITextField with `UITextBorderStyleRoundedRect` (3), system-
  provided clear button in trailing position when non-empty,
  UIColor.labelColor for primary text, UIColor.placeholderTextColor for
  placeholder. Keyboard type controlled by UIKeyboardType via `keyboard_type`.
- **iPadOS 26**: Identical to iOS 26. No material deviations.
- **macOS 26**: NSTextField (or NSSecureTextField) with NSTextFieldRoundedBezel
  (bezelStyle=1), drawsBackground=true, NSColor.labelColor for primary text,
  NSColor.placeholderTextColor for placeholder. Keyboard type has no effect
  on macOS (hardware keyboard).

## HIG citations (validated)
- Text fields - Best practices: "Use a text field to request a small amount of
  information, such as a name or an email address."
- Text fields - Best practices: "Show a hint in a text field to help communicate
  its purpose. A text field can contain placeholder text -- such as 'Email' or
  'Password' -- when there's no other text in the field."
- Text fields - Best practices: "Use secure text fields to hide private data.
  Always use a secure text field when your app asks for sensitive data, such as
  a password."
- Text fields - Best practices: "To the extent possible, match the size of a
  text field to the quantity of anticipated text. The size of a text field helps
  people visually gauge the amount of information to provide."
- Text fields - Platform considerations - iOS, iPadOS: "Display a Clear button
  in the trailing end of a text field to help people erase their input."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/text-fields.md](../validation/reports/text-fields.md)

## Related
- `UI::TextArea` -- multi-line text input for longer freeform content; maps to
  NSTextView (macOS) and UITextView (iOS).
- `UI::SearchField` -- text field styled as a search bar with the pill shape and
  search icon; maps to NSSearchField / UISearchTextField.
- `UI::SecureField` -- (planned) a dedicated secure-entry view with show/hide
  toggle; currently use `UI::TextField` with `secure_entry: true`.
- `recipes/form-layout.md` -- full address-form pattern with validated fields,
  tab order, and error states.
