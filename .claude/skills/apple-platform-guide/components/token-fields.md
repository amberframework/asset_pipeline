---
slug: token-fields
ui_view: UI::TokenField
priority: P2
platforms: [macOS, iOS, iPadOS]
hig_page: ../../../apple-hig/pages/token-fields.md
validation_report: ../validation/reports/token-fields.md
---

# UI::TokenField

> A compact pill-entry field for recipients, tags, or scoped filters. The
> default taste should feel like Mail: tidy capsules, clear insertion space,
> and a calm field boundary around the whole interaction.

## Feel of the flow

Reach for `UI::TokenField` when people are collecting a short set of semantic
items rather than typing one raw string. Good token fields make the entered
items feel stable and nameable, while still leaving obvious room for the next
entry.

The HIG roots this idea in macOS `NSTokenField`. Our shared primitive starts as
an intentional fallback surface so the shard can model the behavior today
without waiting on a native bridge.

## Quickstart

```crystal
tokens = [
  UI::TokenField::Token.new("Avery", "person.crop.circle"),
  UI::TokenField::Token.new("Design", "tag"),
]

field = UI::TokenField.new(tokens, "Add recipient", "To", "People or groups")
field.selected_indexes = [0]
field.accessibility_label = "Recipients"
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `tokens` | `Array(UI::TokenField::Token)` | `[]` | Current token chips in reading order. |
| `selected_indexes` | `Array(Int32)` | `[]` | Selected token positions for emphasis. |
| `placeholder` | `String` | `""` | Placeholder for the trailing text entry. |
| `label` | `String?` | `nil` | Optional field label above the tray. |
| `prompt` | `String?` | `nil` | Optional secondary prompt above the tray. |
| `chip_spacing` | `Float64` | `8.0` | Gap between visible chips. |
| `row_spacing` | `Float64` | `8.0` | Vertical rhythm between label, prompt, and tray. |
| `chip_padding` | `UI::EdgeInsets` | `6/10/6/10` | Interior padding inside each chip. |
| `input_min_width` | `Float64` | `120.0` | Minimum width reserved for the trailing entry field. |
| `input_max_width` | `Float64` | `220.0` | Maximum width reserved for the trailing entry field. |

## Light / dark appearance notes

Token chips should remain obviously grouped with the field, not look like
separate buttons thrown into a row. Selected tokens can carry a little more
weight, but the field still needs to feel quiet enough for repeated entry. In
dark mode, chip boundaries matter more than hue; the insertion field should
still read immediately as the place where the next token appears.

## Customization / brand override

Brand work should usually happen through icon choice, copy tone, and subtle
neutral shifts instead of loud chip colors. If you tint the selected chip, keep
the tray boundary and input affordance intact. This component turns messy fast
when token labels are long, spacing gets tight, or the entry field visually
disappears into the chips.

## What happens on each platform

- **macOS 26**: Currently rendered through the shared composed fallback while a
  future native `NSTokenField` bridge remains open.
- **iOS 26 / iPadOS 26**: Rendered through the same fallback surface. Apple
  does not offer a direct iOS token-field peer, so the fallback is the honest
  portable shape for now.

## HIG citations (validated)

- Token fields are useful for entering a collection of named items such as
  recipients.
- The field should preserve the sense of one editable control rather than a row
  of detached pills.

Validation report:
[validation/reports/token-fields.md](../validation/reports/token-fields.md)

## Related

- `UI::TextField` for a single raw string.
- `UI::ComboBox` for type-or-pick entry.
- `UI::TokenField` can pair well with `UI::ListView` suggestion panes once
  richer completion behavior lands.
