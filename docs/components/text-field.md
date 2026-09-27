# Text fields

`UI::TextField` is a single-line editable field with a logical text alignment. The default is `UI::Alignment::Leading`. Leading and Trailing follow the active reading direction, so they switch edges in right-to-left layouts.

```crystal
email = UI::TextField.new(placeholder: "Email address", name: "email")
email.text_alignment = UI::Alignment::Leading

password = UI::TextField.new(placeholder: "Password")
password.secure_entry = true
password.text_alignment = UI::Alignment::Leading
```

Use `UI::Alignment::Center` or `UI::Alignment::Trailing` when the value belongs in the center or at the trailing edge. `UI::SecureField` exposes the same `text_alignment` property. On Apple platforms, both the value and placeholder use the selected alignment, including when a field appears in a labeled Form row.

## Light / dark appearance notes

Native field chrome and its default colors follow the platform's light or dark appearance. The placeholder uses the library's contrast-aware default. `text_color` and `placeholder_color` are explicit colors; check each override against both field appearances so value and placeholder text remain readable.

## Customization / brand override

Set `text_alignment` per field when a form needs a different value placement. Leading and Trailing remain logical edges in right-to-left layouts. Set `text_color`, `placeholder_color`, or `font` only when the product needs a brand-specific field; explicit colors should preserve readable contrast in light and dark appearances.

```crystal
amount = UI::TextField.new(placeholder: "0.00")
amount.text_alignment = UI::Alignment::Trailing
amount.keyboard_type = UI::KeyboardType::NumberPad
```

## Platform rendering

| Platform | Alignment behavior |
|---|---|
| macOS and iOS | SwiftUI text alignment for the value and placeholder; labeled Form values fill their value area from its leading edge |
| Android | Relative `Gravity.START` / `Gravity.END`, or centered text |
| Web | `text-align: start`, `center`, or `end` |

`UI::TextField#secure_entry` and `UI::SecureField` preserve the same alignment for obscured values and placeholders.
