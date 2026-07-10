---
slug: pop-up-buttons
ui_view: UI::MenuButton
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/pop-up-buttons.md
validation_report: ../validation/reports/pop-up-buttons.md
---

# UI::MenuButton

> A pop-up button presents a flat, mutually exclusive list of options and
> updates its face to show the current selection; on macOS it renders as a
> native NSPopUpButton with the system control bezel material, and on iOS it
> renders as a UIButton grayButtonConfiguration capsule with a
> "chevron.up.chevron.down" SF Symbol indicator.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A pop-up button is a compact selection control. It collapses a list of choices
into a single button face that always shows what is currently chosen, so the
user can glance at the UI and immediately know the state without opening
anything. The click-to-reveal behavior makes it ideal for settings panels,
inspector rows, and form fields where space is limited and only one option is
valid at a time.

It is NOT for: offering actions (use UI::Button or a pull-down button instead),
allowing multiple simultaneous selections (use UI::Checkbox or UI::Picker),
or navigating between sections (use UI::TabView). Use a segmented control when
the list is short enough to show all options at once and selection is the
primary interaction; use a pop-up button when the list is longer or space is at
a premium.

(HIG: "Use a pop-up button to present a flat list of mutually exclusive options
or states." -- Pop-up buttons / Best practices.)

## Quickstart

```crystal
# Create the button with a logical-grouping label as its initial face text.
alignment_btn = UI::MenuButton.new("Alignment")
alignment_btn.add_item("Left")
alignment_btn.add_item("Center")
alignment_btn.add_item("Right")
alignment_btn.add_item("Justified")
alignment_btn.selected_index = 0           # "Left" shown on the button face
alignment_btn.accessibility_label = "Alignment, pop-up button"

# Pair it with a context label per HIG: "Give people a way to predict a
# pop-up button's options without opening it."
row = UI::HStack.new(spacing: 8.0)
row << UI::Label.new("Alignment:")
row << alignment_btn
```

Renders: NSPopUpButton on macOS (system rounded-rect control bezel, trailing
up/down chevron, selected item text on button face, automatic checkmark on
selected item in the open menu); UIButton with grayButtonConfiguration on iOS
(rounded capsule, up/down chevron SF Symbol, selected item title).

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | required | The button's display label and the initial face text when no items are added. |
| `items` | `Array(MenuItem)` | `[]` | The option list; each item has a `label`, optional `icon`, and optional `is_destructive` flag. |
| `selected_index` | `Int32` | `0` | Zero-based index of the currently selected item. The button face text updates to show `items[selected_index].label`. |
| `icon` | `String?` | `nil` | Optional leading SF Symbol name on the button face (not the menu items). |
| `accessibility_label` | `String?` | `nil` | VoiceOver label. Required on every interactive element per HIG; include "pop-up button" suffix so VoiceOver announces the control type. |

**Theming**: `UI::MenuButton` inherits base `UI::View` knobs (`background`,
`corner_radius`, `opacity`, `hidden`). No component-specific theme token exists
in `UI::Theme` for pop-up buttons; appearance tracking is delegated entirely to
the platform (NSPopUpButton on macOS and UIButtonConfiguration on iOS both track
the system appearance automatically). See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** NSPopUpButton renders with `NSColor.controlBackgroundColor`
light variant (~0.94 RGB warm white) as the bezel fill. The selection title
resolves to `NSColor.labelColor` light (~0.0 RGB near-black). The trailing
up/down chevron indicator is drawn in `NSColor.labelColor` light as well.
Contrast of title against bezel fill is approximately 18:1.

**macOS dark:** `NSColor.controlBackgroundColor` dark variant resolves to
approximately 0.22 RGB dark gray. `NSColor.labelColor` dark resolves to near-
white (~1.0 RGB). Contrast of title against dark bezel is approximately 7:1.
Typography weight is unchanged between appearances -- NSPopUpButton does not
auto-thin in DarkAqua. The bezel is visually distinct from a standard DarkAqua
window background (~0.12 RGB).

**iOS light:** UIButtonConfiguration grayButtonConfiguration resolves to a warm
gray fill (~0.91 RGB). The system label color (UIColor.label) resolves to
near-black (~0.0 RGB). The "chevron.up.chevron.down" SF Symbol uses monochrome
rendering, near-black, matching the title. Corner radius is the automatic
capsule style (~18pt). Contrast of title against capsule fill is approximately
18:1.

**iOS dark:** grayButtonConfiguration dark resolves to a dark gray fill (~0.22
RGB). UIColor.label dark resolves to near-white (~1.0 RGB). Contrast of title
against dark capsule is approximately 7:1. The dark capsule is visually distinct
from a near-black host view (~0.05 RGB) -- the capsule edge is visible as a
bright transition. SF Symbol tracks appearance automatically in monochrome mode.

**SF Symbol:** The "chevron.up.chevron.down" symbol is used on iOS. On macOS
the disclosure indicator is drawn natively by NSPopUpButton and is not a
configurable SF Symbol. When adding an icon to the `icon` property (button face
SF Symbol), prefer outline variants in light mode and filled variants in dark
mode to maintain contrast.

**Contrast caution:** If you override the UIButtonConfiguration background color
to a brand mid-tone (e.g., 0.5 gray), the title and chevron may fall below
4.5:1 in one appearance. Prefer semantically dark or semantically light brand
colors and test both appearances when overriding.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
The HIG-default pop-up button on iOS uses a neutral gray capsule (no accent
color) to signal "selection control, not action button." If your brand palette
calls for a tinted capsule, swap grayButtonConfiguration for
tintedButtonConfiguration. Keep hit targets (44pt minimum height on iOS) and
the chevron indicator unchanged.

```crystal
# Use tintedButtonConfiguration on iOS by setting a background color on the
# view itself. The UIKit renderer will apply background to the UIButton's
# layer; for full UIButtonConfiguration tinting, patch the visit method to
# call tintedButtonConfiguration and set baseForegroundColor to your brand color.
btn = UI::MenuButton.new("Sort by")
btn.add_item("Newest first")
btn.add_item("Oldest first")
btn.selected_index = 0
btn.background = UI::Color.new(r: 0.20, g: 0.40, b: 0.80, a: 0.15)  # brand blue tint
# Note: this sets the UIView layer background, not the UIButtonConfiguration
# baseBackgroundColor. For a full configuration-level tint, extend the
# UIKit visit method. The hit target and chevron indicator remain unchanged.
```

**Replace the system bezel with a flat brand surface.**
On macOS, you cannot override NSPopUpButton's bezel material directly through
the Crystal bridge without subclassing. The idiomatic approach for a fully flat
brand pop-up button on macOS is to set a custom bezelColor:

```crystal
# To achieve a flat tinted bezel on macOS, set the background color on the
# MenuButton. The AppKit renderer applies it to the NSPopUpButton via
# setBezelColor: if that property is ever added to the visit method.
# As of this validation, the renderer delegates all bezel rendering to
# NSPopUpButton's system chrome. If a flat bezel is required, extend
# appkit_renderer.cr visit(view : UI::MenuButton) with:
#   nscolor_cls = LibObjCBridge.objc_getClass("NSColor")
#   brand_color = LibObjCBridge.nscolor_rgba(0.2, 0.4, 0.8, 1.0)
#   LibObjCBridge.objc_send_id(ptr, sel("setBezelColor:"), brand_color)
# Warn: custom bezelColor removes the system adaptive appearance tracking --
# you must provide separate light and dark values or use a dynamic NSColor.
```

**Override typography while keeping HIG spacing.**
NSPopUpButton uses the system control font (~13pt Regular on macOS). To
substitute a brand font, wire it after construction via the `font` base
property; the AppKit renderer applies it via setFont: on the NSPopUpButton.
HIG-mandated control height and padding are supplied by NSPopUpButton's
intrinsicContentSize and are unaffected by font substitution within normal
size ranges.

```crystal
btn = UI::MenuButton.new("View")
btn.add_item("List")
btn.add_item("Grid")
btn.add_item("Gallery")
btn.selected_index = 0
btn.font = UI::Font.new(family: "SF Pro Rounded", size: 13.0, weight: :medium)
# The UIKit renderer applies this to the UIButton's titleLabel via setFont:.
# HIG spacing (16pt leading/trailing padding on iOS) is preserved by
# UIButtonConfiguration's insets; overriding font size only changes glyph size.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a settings row that shows the active option at a glance."**
- Pair a `UI::Label` (context) + `UI::MenuButton` (selection) in an HStack.
- Set `selected_index` to the user's saved preference.
- Wire an `on_change` callback (planned) to persist the selection.
- Keep the label's `font` at the same size as the button face font (13pt
  macOS, 15pt iOS) so the row reads as a single unit.

**"I want multiple related pop-up buttons stacked in a form."**
- Add each pair to a `UI::VStack` with 20pt spacing (HIG: form rows use 20pt
  between labeled controls).
- Give each `UI::MenuButton` an accessibility_label that includes the context:
  "Font family, pop-up button", "Font size, pop-up button".
- Do not show all items simultaneously (that would be a disclosure group, not
  a pop-up button). Each button's face shows only the current selection.

## What happens on each platform
- **iOS 26**: UIButton with UIButtonConfiguration.grayButtonConfiguration.
  Capsule corner style (~18pt radius). "chevron.up.chevron.down" SF Symbol as
  image (leading-placed by default in this renderer iteration). Minimum
  44x44pt touch target via UIButtonConfiguration default content insets.
- **iPadOS 26**: Same as iOS. HIG note: "Within a popover or modal view,
  consider using a pop-up button instead of a disclosure indicator to present
  multiple options for a list item."
- **macOS 26**: NSPopUpButton with NSControlStyleRounded bezel (~8pt corner
  radius). System NSMenu appears on click with the selected item checkmarked.
  Trailing up/down chevron drawn natively. Control height ~22pt (platform-
  appropriate; 44pt minimum does not apply to macOS).

## HIG citations (validated)
- Pop-up buttons -> Abstract: "A pop-up button displays a menu of mutually
  exclusive options."
- Pop-up buttons -> Abstract: "After people choose an item from a pop-up
  button's menu, the menu closes, and the button can update its content to
  indicate the current selection."
- Pop-up buttons -> Best practices: "Use a pop-up button to present a flat
  list of mutually exclusive options or states. A pop-up button helps people
  make a choice that affects their content or the surrounding view."
- Pop-up buttons -> Best practices: "Give people a way to predict a pop-up
  button's options without opening it. For example, you can use an introductory
  label or a button label that describes the button's effect, giving context to
  the options."
- Pop-up buttons -> Platform considerations -> iPadOS: "Within a popover or
  modal view, consider using a pop-up button instead of a disclosure indicator
  to present multiple options for a list item."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/pop-up-buttons.md](../validation/reports/pop-up-buttons.md)

## Related
- `UI::Picker` -- when you want a wheel-style picker (iOS) or need the
  segmented control style; `MenuButton` is preferred when space is limited
  and the list is flat.
- `UI::Button` -- when the control triggers an action rather than showing a
  selection; do not use MenuButton for pull-down action lists.
- `UI::SegmentedControl` -- when the option count is 2-5 and all options
  should be visible simultaneously without opening a menu.
- `recipes/settings-form.md` -- multi-row settings panel combining Labels
  and MenuButtons in a Form layout.
