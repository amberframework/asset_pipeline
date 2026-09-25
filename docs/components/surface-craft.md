# Surface craft primitives

The surface-craft API adds optional visual overrides to generic UI views. It gives an app a tactile hardware surface while leaving the library's native appearance unchanged by default.

On macOS, SwiftUI facades render gradients, custom toggle styles, keycaps, swatches, and tabbed Form sections. Raw AppKit views use CAGradientLayer and cached texture tiles. On the web, gradients use CSS linear-gradient, grain uses an inline SVG filter, and colors use design-token variables. iOS and Android compile the same view types and keep their current plain rendering; custom styling on those platforms is a documented gap.

For app-wide palettes, fonts, control helpers, window-chrome limits, and per-platform skin coverage, see the [theming guide](../theming.md).

## Surface fills and shadows

UI::View exposes these optional properties:

| Property | Type | Behavior |
|---|---|---|
| background_fill_color | UI::SurfaceColor? | Literal UI::Color or semantic UI::ColorRole fill |
| linear_gradient | UI::LinearGradient? | Two or more ordered stops and a clockwise angle in degrees |
| list_of_inner_shadows | Array(UI::InnerShadow) | Inset shadows; a light top edge and dark lower edge make a bevel |
| list_of_drop_shadows | Array(UI::DropShadow) | One or more outside shadows, composed with legacy shadow_* properties |
| texture_overlay | UI::TextureOverlay? | Tiled Noise or Brushed grain and opacity from 0.0 to 1.0 |

UI::ColorRole accepts BrandPrimary, BrandAccent, SurfaceCanvas, SurfaceElevated, SurfacePanel, SurfaceSunken, SurfaceInverse, TextPrimary, TextInverse, and Warning. Use a role where a surface should follow the active theme; use UI::Color for a fixed brand color.

~~~crystal
panel = UI::Surface.new(UI::Label.new("Machined panel"))
panel.background_fill_color = UI::ColorRole::SurfacePanel
panel.linear_gradient = UI::LinearGradient.new(
  list_of_stops: [
    UI::GradientStop.new(stop_color: UI::ColorRole::SurfaceElevated, stop_position: 0.0),
    UI::GradientStop.new(stop_color: UI::ColorRole::SurfacePanel, stop_position: 1.0),
  ],
  gradient_angle: 180.0,
)
panel.list_of_inner_shadows = [
  UI::InnerShadow.new(shadow_color: UI::ColorRole::TextInverse, offset_y: 1.0, blur_radius: 2.0),
  UI::InnerShadow.new(shadow_color: UI::ColorRole::SurfaceInverse, offset_y: -2.0, blur_radius: 4.0),
]
panel.list_of_drop_shadows = [
  UI::DropShadow.new(shadow_color: UI::ColorRole::TextPrimary, offset_y: 3.0, blur_radius: 8.0),
]
panel.texture_overlay = UI::TextureOverlay.new(
  texture_kind: UI::TextureKind::Brushed,
  texture_opacity: 0.08,
)
~~~

The old shadow_radius, shadow_color, and shadow_offset_* properties remain supported. Their shadow is composed with the new arrays when both are set.

## Tabbed Form sections

UI::Form#add_section keeps the tab attached to its fields. Omitting tab_shape preserves the current section rendering. The tab and panel both accept UI::SurfaceStyle values.

~~~crystal
section = form.add_section(
  "Storage",
  tab_shape: UI::TabShape::Rounded,
  tab_icon: "folder",
  panel_style: UI::SurfaceStyle.new(
    background_fill_color: UI::ColorRole::SurfacePanel,
    texture_overlay: UI::TextureOverlay.new(
      texture_kind: UI::TextureKind::Noise,
      texture_opacity: 0.06,
    ),
  ),
  tab_style: UI::SurfaceStyle.new(
    background_fill_color: UI::ColorRole::SurfaceElevated,
  ),
)
section.fields << UI::Form::Field.new(label: "Save to", content: UI::Label.new("Documents"))
~~~

UI::TabShape values are Angled (one sloped trailing edge), Rounded (folder tab), Notched (cut corners), and Flush (label row inside the panel with a hairline rule).

## Toggle appearance

UI::Toggle#appearance defaults to Native, preserving the system switch. The explicit options are Pill, Rocker, Slide, and LampPill. Colors accept UI::Color or UI::ColorRole through track_color, knob_color, on_color, and lamp_color.

~~~crystal
toggle = UI::Toggle.new("Launch at sign in", true)
toggle.appearance = UI::ToggleAppearance::Slide
toggle.track_color = UI::ColorRole::SurfaceSunken
toggle.knob_color = UI::ColorRole::SurfaceElevated
toggle.on_color = UI::ColorRole::BrandPrimary
~~~

Rocker shows I/O markings. Slide uses an inset groove, a ridged square knob, and a flat indicator lamp. LampPill has a separate flat lamp. Native lamps use flat fills without glow or bloom.

## Keycaps

UI::Keycap.new(text, style: ...) is a semantic keyboard label with a monospaced font by default. Styles are Outlined, Sculpted, Inset, and Text.

~~~crystal
shortcut = UI::Keycap.new("⌥ S", style: UI::KeycapStyle::Sculpted)
~~~

## Named color swatches

UI::ColorSwatchPicker takes named UI::ColorSwatch values and a selected index. Its on_change callback follows UI::Picker's index callback contract. Styles are SwatchButton (square swatch, chevron, and eyedropper glyph with a palette), SwatchRow (round swatches with a selected ring), NamedPopup, and BezelLamp (a 22pt color lamp inside a bezel ring). The selected SwatchRow ring uses `selection_ring_color`, which defaults to `UI::ColorRole::TextPrimary` and accepts a literal color or any color role.

~~~crystal
swatches = [
  UI::ColorSwatch.new(color_name: "Ocean", swatch_color: UI::Color.new(r: 0.17, g: 0.42, b: 0.69)),
  UI::ColorSwatch.new(color_name: "Brass", swatch_color: UI::Color.new(r: 0.78, g: 0.56, b: 0.24)),
]
picker = UI::ColorSwatchPicker.new(
  list_of_color_swatches: swatches,
  selected_index: 0,
  appearance: UI::ColorSwatchPickerStyle::SwatchButton,
) do |index|
  # Persist the selected palette index here.
  index
end
picker.selection_ring_color = UI::ColorRole::TextPrimary
~~~

SwatchButton and BezelLamp open a native palette popover on macOS. The selected swatch value is displayed in the button, and choosing a palette item dispatches its index through `on_change`.

## Hover and press feedback

Set view.interaction_feedback on a button or row to Sink, Lift, Edge, or None. The default is None. Web feedback uses neutral data-ap-feedback hooks and honors prefers-reduced-motion: reduce: movement stops while hover color changes remain. macOS uses SwiftUI hover and press state and reads the system Reduce Motion setting.

## Font registration

Register an app-bundled font at startup before creating views that name it by PostScript family name. Registration is process-scoped on macOS and returns false for a missing or invalid file. This repository does not bundle fonts.

~~~crystal
unless UI::FontRegistry.register_bundled_font_file("Resources/Michroma-Regular.otf")
  raise "Could not register Michroma"
end

heading.font = UI::Font.new(family: "Michroma", size: 22.0)
~~~

## Scribe-style settings example

This combines a folder-tab section, machined panel, slide toggle, sculpted shortcut keycap, and named swatch menu:

~~~crystal
form = UI::Form.new
audio = form.add_section(
  "Audio",
  tab_shape: UI::TabShape::Rounded,
  tab_icon: "speaker.wave.2",
  panel_style: UI::SurfaceStyle.new(
    background_fill_color: UI::ColorRole::SurfacePanel,
    list_of_inner_shadows: [
      UI::InnerShadow.new(shadow_color: UI::ColorRole::TextInverse, offset_y: 1.0, blur_radius: 2.0),
      UI::InnerShadow.new(shadow_color: UI::ColorRole::SurfaceInverse, offset_y: -2.0, blur_radius: 4.0),
    ],
    texture_overlay: UI::TextureOverlay.new(texture_kind: UI::TextureKind::Brushed, texture_opacity: 0.07),
  ),
  tab_style: UI::SurfaceStyle.new(background_fill_color: UI::ColorRole::SurfaceElevated),
)
slide = UI::Toggle.new("Use system output", true)
slide.appearance = UI::ToggleAppearance::Slide
slide.on_color = UI::ColorRole::BrandPrimary
audio.fields << UI::Form::Field.new(label: "Output", content: slide)

shortcut = UI::Keycap.new("⌥ S", style: UI::KeycapStyle::Sculpted)
audio.fields << UI::Form::Field.new(label: "Shortcut", content: shortcut)

palette = UI::ColorSwatchPicker.new(
  list_of_color_swatches: [
    UI::ColorSwatch.new(color_name: "Ocean", swatch_color: UI::Color.new(r: 0.17, g: 0.42, b: 0.69)),
    UI::ColorSwatch.new(color_name: "Brass", swatch_color: UI::Color.new(r: 0.78, g: 0.56, b: 0.24)),
  ],
  appearance: UI::ColorSwatchPickerStyle::SwatchButton,
) { |_index| nil }
audio.fields << UI::Form::Field.new(label: "Accent", content: palette)
~~~

## Light / dark appearance notes

Semantic roles resolve through web design-token variables and native system colors. Prefer them when a fill should track appearance or the active accent. Literal UI::Color values remain literal in both appearances; choose contrasting light and dark colors when one literal cannot meet contrast in both. Texture opacity is composited over the fill, so keep it low around text and controls.

## Customization / brand override

These properties are explicit brand overrides. Leave them unset to retain the current native surface, switch, and picker defaults. Use UI::SurfaceStyle to share a treatment between a tab and its panel, semantic color roles to follow theme changes, and literal colors for fixed brand marks. The samples/surface-craft/component_study.cr sample shows every visual variant in one macOS window; run with SURFACE_CRAFT_APPEARANCE=light or dark. It passes the selected value to the native sample host so SwiftUI and AppKit use the same appearance.

The captured [light appearance](surface-craft-light.png) and [dark appearance](surface-craft-dark.png) show the macOS component study.

## Platform coverage

| Platform | Behavior |
|---|---|
| Web | CSS gradients, inline SVG grain, combined shadows, tab shapes, custom toggles, keycaps, swatches, and feedback hooks |
| macOS | SwiftUI facades for controls and Forms; CAGradientLayer and cached grain tiles for raw AppKit views; process font registration |
| iOS | Compiles and keeps the existing plain Form, native switch, and Picker rendering; custom surface styling is a gap |
| Android | Keeps existing plain Form, Toggle, and Picker rendering; custom surface styling and font registration are gaps. The macOS-hosted Android compile remains blocked by the Crystal stdlib's missing `c/sys/epoll`; validation needs a Linux-targeted Crystal and Android NDK. |
