---
slug: pickers
ui_view: UI::Picker
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/pickers.md
validation_report: ../validation/reports/pickers.md
---

# UI::Picker

> A picker presents a list of distinct string values from which the user selects
> one. On macOS it renders as a native NSPopUpButton. On iOS it renders as an
> inline list with a trailing checkmark on the selected row (iOS Settings style),
> following HIG guidance for short static option sets. No Liquid Glass material is
> used on either platform; pickers are content controls with system-provided chrome.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A picker makes sense when you need the user to choose one value from a known,
bounded set -- country, language, unit, category -- where the options are well-
known enough that users can predict the available values. On macOS the pop-up form
is space-efficient and familiar from Finder, System Settings, and nearly every
macOS form. On iOS the inline-list-with-checkmarks shape is used in iOS Settings
for every single-option selection: Language, Region, App Language, Default Browser,
and so on.

HIG says "For short lists, consider using a menu or segmented control instead of
a wheel picker." The asset_pipeline iOS renderer follows this recommendation
directly: for the current static option set size (2-10 items), it renders the
inline-list flavor rather than a UIPickerView wheel, because the list shape is
immediately readable without user interaction.

Do not reach for a picker for an extremely large dataset (hundreds of items) where
an index is required: use a searchable list instead.

(HIG: "Consider using a picker to offer medium-to-long lists of items. Although
a picker makes it easy to scroll quickly through many items, it may add too much
visual weight to a short list of items." -- Pickers / Best practices.)

## Quickstart

```crystal
options = ["United States", "Canada", "Mexico", "United Kingdom", "Germany"]

picker = UI::Picker.new(options, 0)
picker.label = "Country"
picker.accessibility_label = "Country picker"

container = UI::VStack.new(spacing: 16.0)
container << UI::Label.new("Select a country")
container << picker
```

Renders: NSPopUpButton on macOS showing the current selection with an up/down
chevron (no Liquid Glass material; system NSControl chrome). On iOS, a vertical
UIStackView with 10pt corner radius and secondarySystemGroupedBackground fill,
containing one row per option; the selected row shows a trailing "checkmark"
SF Symbol tinted systemBlue. This is the iOS Settings inline-list picker flavor,
legible in both light and dark appearances without datasource wiring.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `options` | `Array(String)` | `[]` | The list of string values the picker presents. HIG: "Use predictable and logically ordered values." |
| `selected_index` | `Int32` | `0` | Zero-based index of the currently selected option. Drives `selectItemAtIndex:` on NSPopUpButton; future datasource wiring on UIPickerView. |
| `label` | `String` | `""` | Descriptive label string. Stored on the view; pair with a `UI::Label` above the picker for full HIG-conformant labeling. |
| `style` | `UI::PickerStyle` | `PickerStyle::Menu` | `Menu` maps to NSPopUpButton (macOS) / UIPickerView (iOS). `Segmented` maps to NSSegmentedControl (macOS); iOS renderer ignores this value and always uses UIPickerView. `Wheel` is an alias for Menu on macOS. |
| `on_change` | `Proc(Int32, Nil)?` | `nil` | Callback invoked with the new selected index when the user changes selection. Wired via `CallbackRegistry` on macOS; iOS wiring is planned (datasource gap). |
| `accessibility_label` | `String?` | `nil` | VoiceOver label set via `setAccessibilityLabel:`. Required on all interactive controls per HIG Accessibility guidelines. |

**Theming**: `UI::Picker` does not directly reference `UI::Theme` tokens. The
system NSPopUpButton / UIPickerView control draws its bezel, selection highlight,
and text using the system NSColor / UIColor semantic palette, which tracks
appearance automatically. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** NSPopUpButton renders with NSColor.controlBackgroundColor light
(~0.94 RGB gray fill) as the bezel background. Title text uses
NSColor.controlTextColor light (~0.0 RGB near-black). The up/down chevron
(NSPopUpButton's pull-down disclosure indicator) inherits NSColor.controlTextColor.
Contrast of title text against bezel: approximately 4.5:1.

**macOS dark:** NSPopUpButton bezel switches to NSColor.controlBackgroundColor dark
(~0.22 RGB dark gray). Title text uses NSColor.controlTextColor dark (~1.0 RGB
near-white). Contrast of title text against dark bezel: approximately 4.5:1.
The system NSControl tracks DarkAqua automatically via the effective appearance.

**iOS light:** The inline list renders with UIColor.secondarySystemGroupedBackground
(white, approximately 1.0 RGB, in light mode). In light mode this matches a white
host background so the card boundary is not visually distinct. Option text uses
UIColor.label (near-black in light, contrast ~21:1 against white). The selected-row
checkmark uses systemBlue (approximately 0.0/0.478/1.0 RGB in light), clearly
distinguishable from the near-black option label text.

**iOS dark:** secondarySystemGroupedBackground resolves to dark gray (~0.17 RGB)
in dark mode, visually distinct from the near-black host background. The 10pt
rounded-corner card surface is visible. Option text uses UIColor.label dark (~1.0
RGB, contrast ~4.5:1 against the 0.17 RGB surface). The selected-row checkmark
uses systemBlue dark (~0.039/0.518/1.0 RGB), distinguishable from near-white
label text. All five option rows are legible.

**SF Symbols:** The selected-row checkmark uses `UIImage.systemImageNamed: "checkmark"`
tinted via `setTintColor: UIColor.systemBlueColor`. The SF Symbol adapts to
UIImageRenderingModeAlwaysTemplate automatically in UIImageView, so the tintColor
applies in both appearances.

**Contrast caveat:** On both platforms the option text contrast depends on the
system semantic palette (UIColor.label, NSColor.labelColor) rather than any hardcoded
value in the renderer. A brand override that hardcodes a foreground color without
accounting for appearance risks insufficient contrast in one of the two modes. The
iOS secondarySystemGroupedBackground in light mode has zero visual separation from
a white host view; if your app uses a non-white host background, the card boundary
becomes naturally visible.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Wrap the picker in a branded labeled container.**
```crystal
# Pair the picker with a UI::Label using your brand accent color.
# The picker control itself uses system chrome; the label above is the
# natural target for brand typography.
label = UI::Label.new("Country")
label.font = UI::Font.new(family: "YourBrandFont", size: 15.0, weight: :medium)

picker = UI::Picker.new(options, 0)
picker.accessibility_label = "Country picker"

container = UI::VStack.new(spacing: 12.0)
container << label
container << picker
# Keep hit targets and picker chrome HIG-default; only the label font changes.
```

**Use the Segmented style for a short, fixed option set.**
```crystal
# PickerStyle::Segmented maps to NSSegmentedControl on macOS.
# Use only for 2-5 short options; longer lists should stay Menu style.
unit_picker = UI::Picker.new(["km", "mi", "nm"], 0)
unit_picker.style = UI::PickerStyle::Segmented
unit_picker.accessibility_label = "Distance unit"
# NSSegmentedControl uses system blue for the selected segment highlight.
# Overriding this requires NSSegmentedControl.selectedSegmentTintColor
# which is not currently exposed as a knob; log a feature request if needed.
```

**Embed the picker inside a card surface for a form context.**
```crystal
# Wrapping in UI::Card gives a rounded grouped-surface container
# consistent with inset-grouped form sections on both platforms.
form_body = UI::VStack.new(spacing: 12.0)
form_body << UI::Label.new("Country")
form_body << UI::Picker.new(country_options, 0).tap { |p|
  p.accessibility_label = "Country picker"
}
card = UI::Card.new(form_body.as(UI::View))
card.title = "Shipping Address"
# The Card provides the brand surface; the picker stays system-chrome.
# Do not override the card's material with a flat fill unless you verify
# contrast of the picker text against your custom background.
```

## Feel recipes
Short examples that map design intent to code.

**"I want the picker to respond to selection changes."**
```crystal
picker = UI::Picker.new(options, 0) do |new_index|
  puts "User selected: #{options[new_index]}"
end
```
The block overload registers an `on_change` callback wired via `CallbackRegistry`
on macOS. iOS callback wiring is planned (datasource gap, see gaps.md iter-34).

**"I want a compact inline-toggle picker for a short option set."**
```crystal
# For 2-4 options, use PickerStyle::Segmented (NSSegmentedControl on macOS).
# On iOS, UIPickerView is always used regardless of style -- for a short list
# on iOS, consider UI::SegmentedControl directly instead.
view_picker = UI::Picker.new(["List", "Grid", "Map"], 0)
view_picker.style = UI::PickerStyle::Segmented
view_picker.accessibility_label = "View style"
```

## What happens on each platform
- **iOS 26**: Inline list with checkmarks (iOS Settings flavor). A vertical
  `UIStackView` with 10pt corner radius and `secondarySystemGroupedBackground`
  fill contains one row per option. The selected row shows a trailing
  `UIImageView` with the "checkmark" SF Symbol tinted `systemBlue`. This is
  the HIG-recommended shape for short, static option sets. The `UIPickerView`
  wheel flavor is not used by the renderer for this case; it remains available
  as a platform class if you need it for longer dynamic lists.
- **iPadOS 26**: Same inline-list render as iOS. In a split-view or popover
  context the card surface floats over the popover background.
- **macOS 26**: `NSPopUpButton` (pop-up menu style, default) or
  `NSSegmentedControl` (segmented style). NSPopUpButton shows current selection
  + up/down chevron; clicking expands a native pull-down menu with all options.
  Segmented style shows all options inline as tabs.

## HIG citations (validated)
- Pickers / Abstract: "A picker displays one or more scrollable lists of distinct
  values that people can choose from."
- Pickers / Best practices: "Consider using a picker to offer medium-to-long lists
  of items. If you need to display a fairly short list of choices, consider using
  a pull-down button instead of a picker."
- Pickers / Best practices: "Use predictable and logically ordered values. Before
  people interact with a picker, many of its values can be hidden. It's best when
  people can predict what the hidden values are, such as with an alphabetized list
  of countries, so they can move through the items quickly."
- Pickers / Best practices: "Avoid switching views to show a picker. A picker works
  well when displayed in context, below or in proximity to the field people are
  editing. A picker typically appears at the bottom of a window or in a popover."
- Pickers / Developer documentation: `UIPickerView` (UIKit) --
  `NSDatePicker` (AppKit) for the macOS equivalent; `Picker` (SwiftUI) for
  the cross-platform SwiftUI spelling.

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/pickers.md](../validation/reports/pickers.md)

## Related
- `UI::SegmentedControl` -- use when the list has 2-5 short items and you want
  all options visible inline without scrolling.
- `UI::DatePicker` -- purpose-built picker for date and time values; has its own
  HIG slug (`date-pickers`).
- `UI::ColorPicker` -- purpose-built picker for color values; has its own slug
  (`color-pickers`).
- `recipes/form-with-picker.md` -- multi-field form pattern that includes a
  picker in a Card surface.
