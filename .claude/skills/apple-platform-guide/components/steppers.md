---
slug: steppers
ui_view: UI::Stepper
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/steppers.md
validation_report: ../validation/reports/steppers.md
---

# UI::Stepper

> A two-segment increment/decrement control that renders as a vertical up/down
> chevron pill (NSStepper) on macOS and a horizontal minus/plus pill (UIStepper)
> on iOS 26; no Liquid Glass material -- the system bezel material tracks the
> appearance automatically.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A stepper is a precision-adjustment tool. Use it when users need to nudge a
numeric value up or down by a known, consistent step -- quantities, page counts,
font sizes, alarm hours. The control is intentionally minimal: it never shows its
own value. You MUST pair it with a Label that displays the current value to the
left or immediately adjacent. Without that label, the stepper gives users no
feedback on what they are changing or what the current state is.

Do NOT reach for a stepper when the value range is large and users are likely to
want large jumps in one action. In those cases, pair the stepper with a text field
so users can type a target value directly.

(HIG: "Make the value that a stepper affects obvious. A stepper itself doesn't
display any values, so make sure people know which value they're changing when
they use a stepper." -- Steppers / Best practices.)

## Quickstart

```crystal
# Pair the stepper with a label that displays its current value.
# HIG: the stepper never shows its own value.
quantity_label = UI::Label.new("Quantity: 3")
quantity_label.font = UI::Font.new(size: 13.0, weight: :regular)
quantity_label.accessibility_label = "Quantity label, value 3"

stepper = UI::Stepper.new(0.0, 10.0, 3.0)
stepper.step_value = 1.0
stepper.accessibility_label = "Quantity stepper, value 3, minimum 0, maximum 10"

row = UI::HStack.new(spacing: 8.0)
row << quantity_label
row << stepper
```

Renders: `NSStepper` on macOS (vertical up/down chevron pill, ~19x27pt, system
bezel material); `UIStepper` on iOS (horizontal minus/plus pill, ~88x29pt, system
gray capsule). Both controls automatically disable (dim) the appropriate segment
when the value reaches its minimum or maximum.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `minimum` | `Float64` | `0.0` | Lower bound; the decrement segment is disabled when `value == minimum`. |
| `maximum` | `Float64` | `100.0` | Upper bound; the increment segment is disabled when `value == maximum`. |
| `value` | `Float64` | `0.0` | Current numeric value; must be in `[minimum, maximum]`. |
| `step_value` | `Float64` | `1.0` | Amount added or subtracted per tap/click. |
| `wraps` | `Bool` | `false` | When true, incrementing past maximum wraps to minimum (and vice versa). |
| `label` | `String` | `""` | Stored string; not rendered by the native control -- use an adjacent `UI::Label` instead. |
| `on_change` | `Proc(Float64, Nil)?` | `nil` | Called with the new value after each increment or decrement. |
| `accessibility_label` | `String?` | `nil` | VoiceOver label; REQUIRED for every stepper per HIG accessibility guidance. |

**Theming**: `UI::Stepper` uses no explicit `UI::Theme` color tokens -- NSStepper
and UIStepper render in the system control material which tracks the appearance
automatically. The adjacent value `UI::Label` uses `Theme.apple_default.on_background`
for its text color. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

NSStepper and UIStepper both resolve their bezel and glyph colors from the system
appearance without any explicit token reference in the Crystal renderer.

**macOS light:** NSStepper pill uses a light-gray bezel fill (~0.93 RGB, the standard
NSControl background). Chevron glyphs are near-dark (~0.15 RGB), contrast ~7:1
against the bezel. The thin horizontal divider between segments is ~0.7 RGB. The
adjacent value label uses `NSColor.labelColor` which resolves to near-black (~0.0 RGB)
in light mode (~21:1 contrast against the white window background).

**macOS dark:** NSStepper pill uses a dark bezel fill (~0.22 RGB, DarkAqua NSControl
background). Chevron glyphs are near-white (~0.9 RGB), contrast ~4:1 against the dark
bezel. Adjacent label uses `NSColor.labelColor` which resolves to near-white (~1.0 RGB)
in dark mode (~12:1 contrast against the near-black window background). No
auto-thinning of the chevron glyph weight in dark mode -- NSControl preserves the
standard stroke weight.

**iOS light:** UIStepper pill uses a system-gray capsule background (~0.93 RGB).
Enabled segment glyphs (minus, plus) are near-black (~0.0 RGB), contrast ~18:1.
Disabled segment glyphs are dimmed (~0.50 RGB), providing a clear enabled/disabled
distinction visually. Adjacent label uses `UIColor.label` which resolves to near-black
in light mode.

**iOS dark:** UIStepper pill uses a dark capsule background (~0.20 RGB). Enabled
glyphs are near-white (~0.92 RGB), contrast ~4.5:1. Disabled glyphs are reduced-opacity
gray (~0.40 RGB), contrast ~2:1 against the dark background. The relative tonal
difference between enabled and disabled is sufficient for the state to be legible,
especially paired with the adjacent value label. Adjacent label uses `UIColor.label`
resolving to near-white in dark mode.

**SF Symbols:** NSStepper and UIStepper render their own built-in chevron/minus/plus
glyphs -- they do not use SF Symbol names from your code. No `UI::Image` SF Symbol
override is applicable.

**Contrast caution:** If you override the window or cell background color with a brand
color that is close to the system bezel fill, the divider line and chevron glyphs may
lose contrast. Always verify both light and dark captures after any background-color
override.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the adjacent label accent to your brand primary.**
```crystal
# The stepper control itself cannot be tinted via the Crystal renderer.
# The adjacent value label CAN use a brand color for its text.
# Keep the label at >= 4.5:1 contrast against the background in both appearances.
quantity_label = UI::Label.new("Quantity: 3")
quantity_label.font = UI::Font.new(size: 13.0, weight: :semibold)
# Override text color to brand orange -- verify contrast in both appearances.
quantity_label.background = nil  # no background override needed
# The stepper control appearance remains system-default (appearance-tracking).
# What SHOULD stay HIG-default: the stepper itself, hit targets, spacing.
# What CAN safely change: the adjacent label's font weight, color, size.
```

**Replace the glass material with a flat brand surface.**
```crystal
# NSStepper and UIStepper do not use a Liquid Glass material, so there is
# no glass to disable. If you embed the stepper in a container view that uses
# UI::GlassBackground or a surface material, you can replace that container's
# material with a plain background:
container = UI::VStack.new(spacing: 16.0)
container.background = UI::Color.new(r: 0.13, g: 0.09, b: 0.22)  # brand dark purple
container << quantity_label
container << stepper
# Warning: the brand background must provide sufficient contrast for the stepper
# bezel -- NSStepper and UIStepper derive their bezel from the system appearance,
# not from the container background. A very dark or saturated container may clash
# with the system-gray bezel fill.
```

**Override typography while keeping HIG spacing.**
```crystal
# The stepper control's internal glyph typography is system-controlled.
# Override the adjacent label's font family while preserving HIG size (13pt body).
quantity_label = UI::Label.new("Quantity: 3")
quantity_label.font = UI::Font.new(
  size: 13.0,        # HIG-mandated body size -- do not reduce below 11pt
  weight: :regular,  # or :semibold for emphasis
  family: "Georgia"  # brand serif -- ensure it is available or falls back to system
)
# Do not reduce the label size below 11pt (caption threshold per HIG Typography).
```

## Feel recipes
Short examples that map design intent to code.

**"I want a quantity picker bounded to 1-99 with a wrapping option."**
```crystal
qty_label = UI::Label.new("Copies: 1")
qty_label.accessibility_label = "Copies label, value 1"
stepper = UI::Stepper.new(1.0, 99.0, 1.0)
stepper.step_value = 1.0
stepper.wraps = false  # print copies should NOT wrap from 99 back to 1
stepper.accessibility_label = "Copies stepper, 1 to 99"
row = UI::HStack.new(spacing: 8.0)
row << qty_label
row << stepper
```

**"I want a font-size adjuster that changes by 2pt per click."**
```crystal
size_label = UI::Label.new("Size: 16pt")
size_label.accessibility_label = "Font size label, 16 points"
stepper = UI::Stepper.new(8.0, 72.0, 16.0)
stepper.step_value = 2.0  # HIG: Shift-click on macOS could use 10x = 20pt jumps
stepper.accessibility_label = "Font size stepper, 8 to 72 points, step 2"
row = UI::HStack.new(spacing: 8.0)
row << size_label
row << stepper
```

## What happens on each platform
- **iOS 26**: `UIStepper` -- horizontal pill with minus (-) and plus (+) segments
  separated by a 1pt vertical divider, system-gray capsule background. Disabled segment
  glyphs are automatically dimmed by UIKit when `value == minimum` (minus) or
  `value == maximum` (plus). Intrinsic size ~88x29pt; UIKit extends touch targets
  to 44pt per HIG requirement.
- **iPadOS 26**: Same as iOS -- `UIStepper` with the same rendering and same automatic
  disabled-segment dimming. Layout context is typically more spacious; consider
  positioning the value label to the left of the stepper in an HStack at the same
  font size.
- **macOS 26**: `NSStepper` -- vertical pill with up (^) and down (v) chevron segments
  separated by a 1pt horizontal divider, system bezel material that tracks the
  appearance. Static disabled-segment dimming is NOT applied by AppKit; dimming is only
  visible during mouse-down interaction. Default control size ~19x27pt (NSControl
  regular size). Supports Shift-click for 10x increment (macOS platform consideration
  per HIG).

## HIG citations (validated)
- Steppers -- Abstract: "A stepper is a two-segment control that people use to increase
  or decrease an incremental value."
- Steppers -- Best practices: "Make the value that a stepper affects obvious. A stepper
  itself doesn't display any values, so make sure people know which value they're
  changing when they use a stepper."
- Steppers -- Best practices: "Consider pairing a stepper with a text field when large
  value changes are likely. Steppers work well by themselves for making small changes
  that require a few taps or clicks."
- Steppers -- Platform considerations -- macOS: "For large value ranges, consider
  supporting Shift-click to change the value quickly. If your app benefits from larger
  changes in a stepper's value, it can be useful to let people Shift-click the stepper
  to change the value by more than the default increment (by 10 times the default,
  for example)."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/steppers.md](../validation/reports/steppers.md)

## Related
- `UI::Slider` -- when continuous value selection over a range is preferable to discrete
  steps, or when spatial position matters (volume, brightness).
- `UI::TextField` -- pair with a stepper when users may need to type large target values
  directly rather than clicking through many steps.
- `recipes/quantity-row.md` -- HStack pattern combining a value Label, a Stepper, and
  optional text field for print-dialog-style quantity entry.
