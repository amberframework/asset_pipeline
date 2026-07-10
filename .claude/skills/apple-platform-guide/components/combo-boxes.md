---
slug: combo-boxes
ui_view: UI::ComboBox
priority: P2
platforms: [macOS]
hig_page: ../../../apple-hig/pages/combo-boxes.md
validation_report: ../validation/reports/combo-boxes.md
---

# UI::ComboBox

> A hybrid text field with an embedded pull-down button that renders as NSComboBox on macOS -- the native system control with a bordered editable field and a trailing arrow button that reveals a preset list. On iOS/iPadOS (not supported per HIG), the UIKit renderer falls back to a UITextField with UITextBorderStyleRoundedRect.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A combo box is the right control when you want to offer users a curated list of
likely choices AND allow them to type a custom value not in the list. It is
distinct from a plain pop-up button (which forces a choice from the list only)
and a plain text field (which offers no suggestions). Reach for a combo box
when the input space is large or domain-specific enough that typing a custom
value is common -- e.g. a city field, a font name picker, a URL scheme
selector.

Do NOT use a combo box for a closed set of values (use a pop-up button or
`UI::Picker`) or for free-form text with no meaningful preset suggestions (use
`UI::TextField`). The combo box shape carries the visual promise that a list
exists; an empty options array breaks that promise.

(HIG: "People can enter a custom value into the field or click the button to
choose from a list of predefined values." -- Combo boxes, abstract.)

## Quickstart

```crystal
# Introductory label follows HIG: title-case, ends with colon.
country_label = UI::Label.new("Country:")

# Combo box with a meaningful default from the list per HIG Best practices.
# value: must be one of the options (or empty) -- HIG: "the default value
# doesn't have to be the first item in the list."
cb = UI::ComboBox.new(
  value: "United States",
  options: ["United States", "Canada", "Mexico", "United Kingdom", "Germany"],
  placeholder: "Select or type...",
  width: 240.0
)
cb.accessibility_label = "Country combo box"
```

Renders: NSComboBox on macOS (editable text field + pull-down arrow button,
system-tracked appearance). UITextField with UITextBorderStyleRoundedRect on
iOS (graceful fallback; HIG explicitly states the control is not supported on
iOS/iPadOS). No Liquid Glass material -- the combo box is an input control, not
a surface component.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `value` | `String` | `""` | The current text shown in the editable field. Should be one of the `options` entries per HIG Best practices, or empty to show the placeholder. |
| `options` | `Array(String)` | `[]` | Preset items shown in the pull-down list when the user clicks the trailing arrow button. HIG: "Make sure list items aren't wider than the text field." |
| `placeholder` | `String` | `""` | Gray hint text shown in the field when `value` is empty. NSComboBox uses `setPlaceholderString:`; UITextField uses `setPlaceholder:`. |
| `on_change` | `Proc(String, Void)?` | `nil` | Called with the committed value when the user picks from the list or finishes typing. Retained by CallbackRegistry so the native side holds the pointer safely. |
| `width` | `Float64?` | `nil` | Optional width constraint in pt. When nil, NSComboBox uses its intrinsic content width (~150pt). HIG: "Make sure list items aren't wider than the text field" -- set a width that accommodates the longest option. |
| `accessibility_label` | `String?` | `nil` | VoiceOver label. When nil, VoiceOver reads the field's current text or placeholder. Always set an explicit label that describes the field's purpose ("Country combo box", not "Combo box"). |

**Theming**: `UI::Theme` does not expose combo-box-specific tokens. NSComboBox
appearance-tracks automatically via the system bezel and NSColor.controlColor /
NSColor.textColor / NSColor.controlAccentColor. To override the accent (e.g.
the pull-down button highlight in a brand color), set a custom
`NSAppearance` on the window level rather than on the control. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light (NSAppearanceNameAqua):**
NSComboBox renders with a thin rounded-rect bezel (~0.85 RGB border on a white
field background). The pull-down arrow button sits in a light gray capsule
(~0.92 RGB) at the trailing edge. `value` text uses NSColor.textColor
(near-black ~0.0 RGB in light). Placeholder text uses NSColor.placeholderTextColor
(~0.6 RGB gray), contrast ~4.5:1 on white -- at the 4.5:1 WCAG AA body-text
threshold. The selection highlight when the field gains focus uses
NSColor.selectedTextBackgroundColor (system blue tint). All colors track
the system appearance automatically; no token override needed.

**macOS dark (NSAppearanceNameDarkAqua):**
NSComboBox bezel shifts to a dark fill (~0.22 RGB) with a medium-gray border
(~0.35 RGB). The pull-down arrow glyph lightens to ~0.65 RGB against a darker
button background (~0.28 RGB) -- still clearly visible. `value` text:
NSColor.textColor dark variant (near-white ~0.95 RGB), contrast ~21:1 on dark
fill. Placeholder: NSColor.placeholderTextColor dark (~0.55 RGB), contrast
~3.2:1 on ~0.22 background -- above 3:1 large-text threshold, visible. The
selection highlight tracks NSColor.selectedTextBackgroundColor dark (a muted
blue-gray). All adaptive; no dark-mode-specific overrides needed.

**iOS light (UIKit fallback, HIG: "Not supported"):**
UITextField with UITextBorderStyleRoundedRect: ~8pt corner radius, 1pt gray
border on white field background. `value` text: UIColor.label (~0.0 RGB),
~21:1. Placeholder: UIColor.placeholderText (~0.55 RGB), ~4.8:1 on white.
Field height 44pt (HIG minimum touch target). The chevron.down trailing icon
is not rendered in the current implementation (see validation report, Deviation
1). The rounded-rect border alone conveys the "text field" shape.

**iOS dark (UIKit fallback):**
UITextField dark-mode appearance: dark fill (~0.12 RGB), muted border (~0.25
RGB). `value` text: UIColor.label dark (near-white), ~21:1. Placeholder:
UIColor.placeholderText dark (~0.43 RGB), ~3.6:1 on near-black -- above 3:1.
Legible in both appearances.

**SF Symbol usage:** The chevron.down symbol (weight: regular, scale: medium)
is used as the trailing icon in the iOS UITextField right view. On macOS,
NSComboBox renders its own native pull-down arrow glyph (not an SF Symbol);
this is the HIG-authentic macOS rendering.

**Contrast caveat for brand overrides:** If you change the field background via
a custom theme token or direct NSColor override, verify that the placeholder
text retains at least 3:1 contrast on the new background. Low-contrast
placeholders in dark mode are a common accessibility failure.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# NSComboBox inherits controlAccentColor for its pull-down button highlight.
# To globally shift it to a brand color, set the accent on NSApp before
# showing the window. This changes ALL controls in the app, not just the combo.
# Per-control tinting is not exposed by NSComboBox's public API.
#
# In your AppKit setup code (before hig_run_app):
#   [NSApp setAccentColor:[NSColor colorWithRed:0.2 green:0.4 blue:0.9 alpha:1.0]];
#
# In Crystal (via ObjC bridge):
# accent = LibObjCBridge.nscolor_rgba(0.2, 0.4, 0.9, 1.0)
# LibObjCBridge.objc_send_id(
#   LibObjCBridge.objc_getClass("NSApplication"),  # NSApp class
#   LibObjCBridge.sel_registerName("setAccentColor:".to_unsafe),
#   accent
# )
#
# What stays HIG-default: bezel shape, font, height, placeholder behavior.
# What changes: pull-down button highlight color.
```

**Replace the field background with a flat brand surface.**
```crystal
# NSComboBox (an NSTextField subclass) supports setBackgroundColor:.
# Use NSColor.colorWithSRGBRed:green:blue:alpha: via the bridge.
brand_bg = LibObjCBridge.nscolor_rgba(0.95, 0.97, 1.0, 1.0)  # very light blue
LibObjCBridge.objc_send_id(combo_ptr, sel("setBackgroundColor:"), brand_bg)
LibObjCBridge.objc_send_bool(combo_ptr, sel("setDrawsBackground:"), 1)

# Warning: this opts out of NSComboBox's appearance-tracking background.
# In dark mode the light-blue fill will look wrong unless you check
# NSApp.effectiveAppearance and choose a dark-appropriate brand color.
# The legibility trade-off: placeholder contrast may drop below 3:1 on a
# custom background. Verify with the Accessibility Inspector.
```

**Override typography while keeping HIG spacing.**
```crystal
# NSComboBox inherits NSTextField font. Override via setFont:.
brand_font = LibObjCBridge.nsfont_named(
  LibObjCBridge.nsstring_from_cstr("YourBrandFont-Regular".to_unsafe),
  13.0  # keep HIG's 13pt size for desktop text-field density
)
# Fall back to system if custom font not installed:
brand_font = LibObjCBridge.nsfont_system(13.0) if brand_font.null?
LibObjCBridge.objc_send_id(combo_ptr, sel("setFont:"), brand_font)

# What stays HIG-default: bezel shape, corner radius, pull-down button,
#   vertical spacing in the host VStack, 22pt intrinsic height.
# What changes: typeface.
# Do NOT change the size below 13pt -- NSComboBox items in the pop-up list
# will stay at the system size regardless, causing a mismatch.
```

## Feel recipes
Short examples that map design intent to code.

**"I want the combo to always show the first option as the default."**
Pass `options.first? || ""` as the `value`:
```crystal
opts = ["Safari", "Chrome", "Firefox"]
cb = UI::ComboBox.new(value: opts.first? || "", options: opts)
```

**"I want a read-only combo that only allows list choices, not free typing."**
NSComboBox has `setEditable:` (YES by default). Disable it:
```crystal
# After `emit` in the AppKit renderer, or via a post-init hook:
LibObjCBridge.objc_send_bool(combo_ptr, sel("setEditable:"), 0)
# This makes it behave like a pop-up button but with the combo box chrome.
# HIG note: for a truly closed set, a pull-down button is the preferred choice.
```

## What happens on each platform
- **macOS 26**: NSComboBox (AppKit). Full native control: editable text field,
  trailing pull-down button, pop-up list on click. System-tracked appearance
  in both Aqua and DarkAqua. Control height ~22pt (macOS HIG-authentic desktop
  density; no 44pt requirement for pointer-based interaction).
- **iPadOS 26**: Not supported per HIG. UIKit renderer falls back to UITextField
  with UITextBorderStyleRoundedRect, 44pt height. Same as iOS.
- **iOS 26**: Not supported per HIG. UIKit renderer falls back to UITextField
  with UITextBorderStyleRoundedRect, 44pt height (HIG minimum touch target).
  The trailing chevron.down icon currently does not render (see validation
  report, Deviation 1).

## HIG citations (validated)
- Combo boxes -> abstract: "A combo box combines a text field with a pull-down
  button in a single control."
- Combo boxes -> Best practices: "Populate the field with a meaningful default
  value from the list. Although the field can be empty by default, it's best
  when the default value refers to the hidden choices. The default value
  doesn't have to be the first item in the list."
- Combo boxes -> Best practices: "Use an introductory label to let people know
  what types of items to expect. Generally, use title-style capitalization for
  labels and end them with a colon."
- Combo boxes -> Best practices: "Make sure list items aren't wider than the
  text field. If an item is too wide, the text field might truncate it, which
  is hard for people to read."
- Combo boxes -> Platform considerations: "Not supported in iOS, iPadOS, tvOS,
  visionOS, or watchOS."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/combo-boxes.md](../validation/reports/combo-boxes.md)

## Related
- `UI::TextField` -- when no preset list is needed (free-form text only).
- `UI::Picker` -- when the user must choose from a closed list (no free typing).
- `UI::MenuButton` -- pull-down menu without an editable text field.
- `recipes/form-layout.md` -- multi-field form patterns using labels + combo boxes.
