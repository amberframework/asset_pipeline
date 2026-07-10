---
slug: sliders
ui_view: UI::Slider
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/sliders.md
validation_report: ../validation/reports/sliders.md
---

# UI::Slider

> A horizontal track with a thumb control that lets people select a value between
> a minimum and maximum; on iOS 26 the track and thumb are rendered by UISlider
> (no Liquid Glass material -- sliders are content controls, not surfaces).

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A slider is the right control when a value is continuous, the exact number is less
important than the relative position, and the user benefits from direct manipulation.
Volume, brightness, and opacity are canonical examples: the user drags toward "more"
or "less" rather than typing a precise percentage.

Do not use a slider when the exact value matters and the range is wide. In those
cases, HIG recommends pairing the slider with a text field and stepper so the user
can also type an explicit value.

(HIG: "Consider supplementing a slider with a corresponding text field and stepper.
Especially when a slider represents a wide range of values, people may appreciate
seeing the exact slider value and having the ability to enter a specific value in a
text field." -- Sliders / Best practices.)

## Quickstart

```crystal
# Volume-style slider with SF Symbol icons flanking the track.
# HIG Best practices: "A slider can optionally display left and right icons that
# illustrate the meaning of the minimum and maximum values."
vol_row = UI::HStack.new(spacing: 8.0)

vol_min = UI::Image.new("speaker.slash")
vol_min.accessibility_label = "Speaker off"
vol_row << vol_min

vol_slider = UI::Slider.new(0.0, 1.0, 0.55)
vol_slider.accessibility_label = "Volume slider at 55 percent"
vol_row << vol_slider

vol_max = UI::Image.new("speaker.wave.3")
vol_max.accessibility_label = "Speaker full volume"
vol_row << vol_max

# Plain percentage slider with min/max text labels and a current-value readout.
labeled_row = UI::HStack.new(spacing: 8.0)

min_lbl = UI::Label.new("0")
min_lbl.text_color_role = UI::LabelRole::Secondary
labeled_row << min_lbl

slider = UI::Slider.new(0.0, 100.0, 65.0)
slider.accessibility_label = "Brightness slider at 65 percent"
labeled_row << slider

max_lbl = UI::Label.new("100")
max_lbl.text_color_role = UI::LabelRole::Secondary
labeled_row << max_lbl
```

Renders: NSSlider (AppKit) with a lozenge-shaped thumb and a filled blue leading
track on macOS; UISlider (UIKit) with a circular rubber thumb on iOS -- no Liquid
Glass material, as sliders are HIG-classified content controls, not surfaces.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `minimum` | `Float64` | `0.0` | Minimum value of the range; maps to `setMinValue:` (NSSlider) / `setMinimumValue:` (UISlider). |
| `maximum` | `Float64` | `1.0` | Maximum value of the range; maps to `setMaxValue:` (NSSlider) / `setMaximumValue:` (UISlider). |
| `value` | `Float64` | `0.0` | Current thumb position; maps to `setDoubleValue:` (NSSlider) / `setValue:` (UISlider). |
| `step` | `Float64` | `0.0` (continuous) | When > 0, NSSlider shows tick marks and `allowsTickMarkValuesOnly`; UISlider snaps values in the on_change handler. |
| `tint_color` | `Color?` | `nil` (system blue) | On iOS, sets `minimumTrackTintColor` on UISlider to tint the filled leading track. On macOS, `NSSlider` does not expose a track-fill color selector via this bridge -- the tint is silently ignored (planned: `NSSliderCell.trackFillColor`). |
| `on_change` | `Proc(Float64, Nil)?` | `nil` | Callback invoked when the thumb moves; receives the current value as a Float64. |
| `accessibility_label` | `String?` | `nil` | VoiceOver label; **required** on all interactive sliders per HIG accessibility guidance. |

**Theming**: `UI::Theme.primary` (RGB 0.0/0.478/1.0) is the nearest semantic token
to the system blue that fills the slider track, but the AppKit / UIKit renderers
resolve the track color from the system accent color, not from `UI::Theme.primary`
directly. Override via `tint_color` on iOS or (planned) `NSSliderCell.trackFillColor`
on macOS. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** NSWindow white background (~1.0 RGB). NSSlider lozenge thumb (~20pt
wide, ~12pt tall) is a system-managed gray surface that lightens in light mode. Filled
track: system blue (R=0.0, G=0.478, B=1.0), approximately 4pt tall. Unfilled track:
light gray (~0.75 RGB). Filled/unfilled distinction: clearly visible (~21:1 blue vs
white-gray contrast). Secondary label text (flanking labels, captions) in
NSColor.secondaryLabelColor (~0.55 RGB), contrast ~4.5:1 against white background.
PASS.

**macOS dark:** NSWindow near-black DarkAqua (~0.09 RGB). NSSlider lozenge thumb
rendered as a pale gray lozenge (~0.85 RGB), clearly visible against the dark window.
Filled track: system blue (same RGB), contrast ~5:1 against dark window. Unfilled
track: dark gray (~0.25 RGB), distinct from filled blue. The filled/unfilled boundary
is legible in both directions. NSColor.secondaryLabelColor near-white (~0.65 RGB),
contrast ~8:1 against dark window. Weight preserved: NSTextField captions do not
auto-thin in dark mode on macOS. PASS.

**iOS light:** UIViewController white background. UISlider circular rubber thumb
(~28pt diameter, white with system shadow). Filled track (minimumTrackTintColor):
system blue. Unfilled track (maximumTrackTintColor): system gray. NOTE: in the
current iteration's validation captures, the UISlider track layers are not visible
in XCUITest rasterized screenshots -- the thumb capsule appears but the track is
absent. This is a known rendering gap (see `validation/gaps.md` iteration-42).
SF Symbol icons flanking the slider use UIColor.label monochrome rendering,
legible against white. NEEDS_WORK (track not visible in static captures).

**iOS dark:** UIViewController black background. UISlider thumb white capsule
visible. Same track visibility gap as light. SF Symbols in system blue, legible
(~5:1 contrast against black). NEEDS_WORK (track not visible in static captures).

**SF Symbol rendering:** `UI::Image("speaker.slash")` and `UI::Image("speaker.wave.3")`
are resolved via `systemImageNamed:` (macOS) / `imageWithSystemSymbolName:
accessibilityDescription:` (iOS) since iteration-41's SF Symbol fix. Both symbols
render in the platform's default monochrome mode (follows system accent color on
macOS; `.label` tint on iOS). No hierarchical or palette rendering is applied by
default.

**Contrast caution for brand overrides:** Replacing system blue with a pale tint
color via `tint_color =` can reduce the filled-track contrast below 3:1 against the
white unfilled track in light mode. Always verify the filled/unfilled contrast ratio
with your brand color.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the track fill to your brand primary (iOS only).**
```crystal
# The tint_color knob maps to UISlider.minimumTrackTintColor on iOS.
# Hit targets, thumb size (44pt effective), and spacing stay HIG-default.
# On macOS, tint_color is currently ignored -- track uses system accent color.
brand_slider = UI::Slider.new(0.0, 100.0, 50.0)
brand_slider.tint_color = UI::Color.new(r: 0.0, g: 0.55, b: 0.27)  # brand green
brand_slider.accessibility_label = "Brand-colored slider"
```

**Step-quantized slider with tick marks on macOS.**
```crystal
# Setting step > 0 enables tick marks on NSSlider (macOS) and
# snap-to-step in the on_change handler (iOS).
# HIG macOS: "Use tick marks to increase clarity and accuracy."
stepped_slider = UI::Slider.new(0.0, 10.0, 5.0)
stepped_slider.step = 1.0
stepped_slider.accessibility_label = "Rating slider 0 to 10"
```

**Override typography while keeping HIG spacing.**
```crystal
# The slider itself has no typography. Apply brand typography only to the
# flanking labels. Preserve the 8pt-grid horizontal spacing in the HStack.
row = UI::HStack.new(spacing: 8.0)

min_label = UI::Label.new("Min")
min_label.font = UI::Font.new(family: "Georgia", size: 13.0, weight: :regular)
min_label.text_color_role = UI::LabelRole::Secondary
row << min_label

sl = UI::Slider.new(0.0, 100.0, 40.0)
sl.accessibility_label = "Slider"
row << sl

max_label = UI::Label.new("Max")
max_label.font = UI::Font.new(family: "Georgia", size: 13.0, weight: :regular)
max_label.text_color_role = UI::LabelRole::Secondary
row << max_label
```

## Feel recipes
Short examples that map design intent to code.

**"I want a volume-style slider with mute / full-volume icons."**
Wrap a `UI::Slider` in a `UI::HStack` with `UI::Image("speaker.slash")` on
the left and `UI::Image("speaker.wave.3")` on the right. Set `spacing: 8.0` on
the HStack. Set `accessibility_label` on both images and the slider.

**"I want a labeled brightness slider that shows the current value."**
Place a `UI::HStack` containing a "0" label, the slider, and a "100" label.
Below the HStack, add a `UI::Label` displaying the current value string. Wire
`on_change` on the slider to update the label text. Keep `text_color_role:
UI::LabelRole::Tertiary` on the current-value label so it reads as helper text,
not as a primary input.

## What happens on each platform
- **iOS 26**: `UISlider` -- circular rubber thumb, `minimumTrackTintColor` in
  system blue by default, `maximumTrackTintColor` in system gray. Track height
  approximately 4pt. Effective hit target 44x44pt (UIKit default). `tint_color`
  property applies to `minimumTrackTintColor`.
- **iPadOS 26**: Same as iOS 26. Slider typically wider due to larger viewport
  but no API change; thumb size and track height identical.
- **macOS 26**: `NSSlider` linear style -- lozenge-shaped thumb (~20x12pt),
  filled leading track in system accent color (System Preferences > Accent Color,
  default system blue), 4pt track height. `tint_color` not applied on macOS
  (planned via `NSSliderCell.trackFillColor`). Step > 0 adds tick marks and
  `allowsTickMarkValuesOnly`. No Liquid Glass material.

## HIG citations (validated)
- Sliders -> Abstract: "A slider is a horizontal track with a control, called a
  thumb, that people can adjust between a minimum and maximum value."
- Sliders -> Abstract: "As a slider's value changes, the portion of track between
  the minimum value and the thumb fills with color. A slider can optionally display
  left and right icons that illustrate the meaning of the minimum and maximum values."
- Sliders -> Best practices: "Customize a slider's appearance if it adds value. You
  can adjust a slider's appearance -- including track color, thumb image and tint
  color, and left and right icons -- to blend with your app's design and communicate
  intent."
- Sliders -> Best practices: "Use familiar slider directions. People expect the
  minimum and maximum sides of sliders to be consistent in all apps, with minimum
  values on the leading side and maximum values on the trailing side."
- Sliders -> Platform considerations -> macOS: "In a linear slider either with or
  without tick marks, the thumb is a narrow lozenge shape, and the portion of track
  between the minimum value and the thumb is filled with color. A linear slider often
  includes supplementary icons that illustrate the meaning of the minimum and maximum
  values."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/sliders.md](../validation/reports/sliders.md)

## Related
- `UI::Stepper` -- when the value range is small and precise integer increments
  are preferable to continuous drag.
- `UI::ProgressView` -- when the value represents a read-only progress level, not
  a user-adjustable input.
- `recipes/media-controls.md` -- multi-component pattern combining UI::Slider
  (volume), UI::Toggle (mute), and SF Symbol icons in a compact media control bar.
