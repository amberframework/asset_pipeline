---
slug: color-wells
ui_view: UI::ColorPicker
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/color-wells.md
validation_report: ../validation/reports/color-wells.md
---

# UI::ColorPicker

> A small swatch button that shows the currently selected color and opens the
> system color picker when tapped or clicked; on macOS it renders as an
> NSColorWell rounded-rect bezel, on iOS as a UIColorWell pill (or a sized
> UIView pill in the validation harness). No Liquid Glass material is applied to
> the swatch itself -- the color-picker popover that it opens inherits the
> platform's standard popover or sheet material.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A color well is a compact, inline affordance that lets a user see and change a
specific color property -- the stroke color of a shape, the background fill of a
text box, the tint of an annotation. It belongs in inspector panels, formatting
toolbars, and settings forms where a user may need to revisit and refine a color
decision during a creative or configuration task.

Do not use a color well for decorative swatches that are not interactive. If the
user cannot tap or click to change the color, use a plain colored rectangle or a
`UI::Label` with a tinted background instead.

(HIG: "A color well displays a color picker when people tap or click it." -- Color
wells / abstract.)

## Quickstart

```crystal
# Labeled red stroke-color well
row = UI::HStack.new(spacing: 12.0)
lbl = UI::Label.new("Stroke color")
lbl.accessibility_label = "Stroke color label"

well = UI::ColorPicker.new
well.selected_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
well.label = "Stroke color"
well.accessibility_label = "Stroke color well, red"
well.on_change = ->(c : UI::Color) { puts "New stroke: #{c.r}/#{c.g}/#{c.b}" }

row << lbl
row << well
```

Renders: NSColorWell on macOS (rounded-rect with a bezel ring, filled with the chosen
color); UIColorWell on iOS 14+ (circular or pill, filled with the chosen color). On the
validation harness iOS path a 44x28pt UIView pill with a 14pt CALayer corner radius
stands in -- visually equivalent for the swatch, without the tap-to-open interaction.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `selected_color` | `UI::Color` | `Color.new(r:0, g:0, b:0)` | The fill color displayed by the swatch. Red/green/blue/alpha components are each 0.0-1.0. |
| `on_change` | `Proc(Color, Nil)?` | `nil` | Called when the user selects a new color from the picker; receives the chosen `UI::Color`. |
| `label` | `String` | `""` | Semantic label string forwarded to NSColorWell / UIColorWell for VoiceOver. Should match the adjacent visible label text. |
| `supports_alpha` | `Bool` | `false` | When `true`, the opened color picker includes an opacity slider. Maps to `UIColorPickerViewController.supportsAlpha` on iOS. |
| `accessibility_label` | `String?` | `nil` | Overrides the platform accessibility label for the swatch button. Should describe both the role and the current color (e.g. "Stroke color well, red"). |

**Theming**: `UI::ColorPicker` does not consume theme tokens -- the swatch fill is
always the developer-supplied `selected_color`. The host container's background reads
from `UI::Theme.apple_default.background` (light ~1.0 RGB / dark ~0.12 RGB). See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

`UI::ColorPicker` has no system-semantic color tokens of its own; the swatch fill is the
developer's static `selected_color` value.

**macOS light (NSAppearanceNameAqua):**
The NSColorWell bezel is a ~1pt light-gray inset ring (~0.7 RGB) that tracks the Aqua
appearance automatically -- AppKit owns bezel drawing. The swatch fill is the baked RGBA
supplied via `setColor:`. The host window background is white (NSColor.windowBackgroundColor
~1.0 RGB). Label text is NSColor.labelColor -- near-black (~0.07 RGB), ~21:1 contrast
against white.

**macOS dark (NSAppearanceNameDarkAqua):**
NSColorWell bezel adapts: the inset ring becomes darker (~0.3 RGB) against the DarkAqua
window background (~0.12 RGB). Label text switches to NSColor.labelColor dark variant
(~0.92 RGB), ~15:1 contrast. The swatch fill stays the developer-supplied RGBA
unchanged -- vivid saturated colors (red, teal, orange) all read cleanly against the
dark background.

**iOS light (UIUserInterfaceStyle.light):**
The UIKit renderer swatch is a 44x28pt UIView pill with a static RGBA backgroundColor.
White UIViewController background. UIColor.labelColor near-black labels, ~21:1 contrast.
All three demonstration swatch colors (red, teal, orange) are clearly visible.

**iOS dark (UIUserInterfaceStyle.dark):**
Same 44x28pt pill with unchanged baked fills against a black UIViewController background.
Red, teal, and orange all have strong luminance contrast against black. UIColor.labelColor
dark variant (near-white) provides ~21:1 contrast for labels. Note: the baked fills do
not shift to their UIColor dark-adaptive equivalents because CALayer.backgroundColor
requires a static CGColorRef. The vivid-hue primaries used in the default showcase all
remain distinguishable in dark. If your app uses low-saturation swatch colors (near-gray
or near-black) verify that baked values remain legible in dark mode.

**SF Symbol usage:** None. NSColorWell and UIColorWell do not use SF Symbols for the
swatch itself. If you add a complementary icon button (e.g. an eyedropper) alongside
the well, use `UI::IconButton` with the `eyedropper` SF Symbol.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the initial swatch to your brand primary.**
```crystal
well = UI::ColorPicker.new
# Replace with your brand primary (e.g. deep violet 0.40/0.10/0.80).
well.selected_color = UI::Color.new(r: 0.40, g: 0.10, b: 0.80)
well.label = "Brand accent"
well.accessibility_label = "Brand accent color well"
# Keep HIG-default hit target (NSColorWell ~26pt tall on macOS is already adequate;
# on iOS pin via frame_width/frame_height if you size the container manually).
```

**Add opacity support for a design tool context.**
```crystal
well = UI::ColorPicker.new
well.selected_color = UI::Color.new(r: 0.2, g: 0.6, b: 1.0, a: 0.75)
well.supports_alpha = true  # iOS: UIColorPickerViewController.supportsAlpha = true
well.label = "Layer tint"
well.accessibility_label = "Layer tint color well, 75 percent opacity blue"
# Warning: enabling alpha means the swatch fill becomes semi-transparent over the
# host background. Ensure the host background is a legible neutral (not patterned)
# so the partially-transparent swatch is still readable.
```

**Override typography while keeping HIG spacing.**
```crystal
# The color well swatch itself has no typography; the adjacent label does.
lbl = UI::Label.new("Fill color")
# Swap to a brand font at the same body size to keep HIG-mandated 17pt body.
# UI::Font.custom is planned (see gaps.md); use the theme font_family knob today.
theme = UI::Theme.apple_default
theme.font_family = "YourBrandFont-Regular"
theme.font_size_body = 17.0   # Keep HIG body size
# Apply theme globally via the renderer or host.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a formatting inspector row that lets the user repick a stroke color."**
Use `UI::HStack` with a `UI::Label` on the left and `UI::ColorPicker` on the right.
Set `on_change` to update your model and redraw the target element. Set
`accessibility_label` to describe both the role and the current color so VoiceOver
reads "Stroke color well, blue" after a change.

**"I want three swatches (fill, stroke, shadow) in a horizontal row."**
Nest three `UI::ColorPicker` instances in a single `UI::HStack` with 12pt spacing.
Give each a separate `on_change` proc targeting the appropriate property. Do not omit
`accessibility_label` on any of them -- three adjacent colored pills with no labels are
opaque to VoiceOver.

## What happens on each platform
- **iOS 26**: UIColorWell (pill or circular, filled with `selected_color`); tapping opens
  UIColorPickerViewController as a sheet with system material. `supports_alpha` maps to
  `UIColorPickerViewController.supportsAlpha`.
- **iPadOS 26**: Same as iOS. On iPad the UIColorPickerViewController presents as a
  floating panel rather than a full-sheet, matching the popover form factor.
- **macOS 26**: NSColorWell with default bezel (rounded-rect, ~10pt corner radius on
  macOS 26). Clicking opens NSColorPanel (the system color picker). `setColor:` sets the
  initial fill. `supports_alpha` maps to `NSColorPanel.shared.showsAlpha`.

## HIG citations (validated)
- Color wells: "A color well lets people adjust the color of text, shapes, guides, and
  other onscreen elements."
- Color wells -- Best practices: "Consider the system-provided color picker for a
  familiar experience. Using the built-in color picker provides a consistent experience,
  in addition to letting people save a set of colors they can access from any app."
- Color wells -- macOS: "When people click a color well, it receives a highlight to
  provide visual confirmation that it's active. It then opens a color picker so people
  can choose a color. After they make a selection, the color well updates to show the
  new color."
- Color wells -- macOS: "Color wells also support drag and drop, so people can drag
  colors from one color well to another, and from the color picker to a color well."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/color-wells.md](../validation/reports/color-wells.md)

## Related
- `UI::GlassBackground` -- when you need a translucent surface behind a color-picker
  panel; the well itself stays opaque-filled.
- `UI::Button` -- if you need a fully custom color-trigger button that shows a color
  swatch inside a larger button hit target.
- `recipes/inspector-panel.md` -- multi-well inspector row pattern with label
  alignment and accessibility.
