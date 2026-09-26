# Native macOS study showing the reusable surface-craft overrides.

require "../../src/ui"

{% if flag?(:macos) %}
  APPEARANCE   = ENV["SURFACE_CRAFT_APPEARANCE"]? || "light"
  AX_TEST_MODE = ENV["SURFACE_CRAFT_AX_TEST"]? == "1" || {{ flag?(:surface_craft_ax_test) }}
  {% if flag?(:surface_craft_ax_test) %}
    ENV["HIG_INTERACTIVE"] = "1"
  {% end %}

  def sample_color(light_color : UI::Color, dark_color : UI::Color) : UI::Color
    APPEARANCE == "dark" ? dark_color : light_color
  end

  lib SurfaceCraftWindow
    fun hig_create_window_with_min(
      x : Float64,
      y : Float64,
      width : Float64,
      height : Float64,
      minimum_width : Float64,
      minimum_height : Float64,
      title : UInt8*,
      appearance : UInt8*,
    ) : Void*
    fun hig_run_app(window : Void*) : Void
  end

  lib SurfaceCraftObjC
    fun objc_send_void_id(object : Void*, selector : Void*, argument : Void*) : Void
    fun sel_registerName(name : UInt8*) : Void*
  end

  def machined_panel_style : UI::SurfaceStyle
    panel_color = sample_color(
      UI::Color.new(r: 0.984, g: 0.973, b: 0.949),
      UI::Color.new(r: 0.169, g: 0.196, b: 0.259),
    )
    UI::SurfaceStyle.new(
      background_fill_color: panel_color,
      linear_gradient: UI::LinearGradient.new(
        list_of_stops: [
          UI::GradientStop.new(
            stop_color: sample_color(
              UI::Color.new(r: 1.0, g: 0.996, b: 0.984, a: 0.72),
              UI::Color.new(r: 1.0, g: 1.0, b: 1.0, a: 0.07),
            ),
            stop_position: 0.0,
          ),
          UI::GradientStop.new(stop_color: panel_color, stop_position: 1.0),
        ],
        gradient_angle: 180.0,
      ),
      list_of_inner_shadows: [
        UI::InnerShadow.new(
          shadow_color: sample_color(
            UI::Color.new(r: 1.0, g: 1.0, b: 1.0, a: 0.9),
            UI::Color.new(r: 1.0, g: 1.0, b: 1.0, a: 0.08),
          ),
          offset_y: 1.0,
          blur_radius: 2.0,
        ),
        UI::InnerShadow.new(
          shadow_color: sample_color(
            UI::Color.new(r: 0.137, g: 0.161, b: 0.227, a: 0.13),
            UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.38),
          ),
          offset_y: -2.0,
          blur_radius: 4.0,
        ),
      ],
      list_of_drop_shadows: [
        UI::DropShadow.new(
          shadow_color: sample_color(
            UI::Color.new(r: 0.137, g: 0.161, b: 0.227, a: 0.16),
            UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.42),
          ),
          offset_y: 3.0,
          blur_radius: 8.0,
        ),
      ],
      texture_overlay: UI::TextureOverlay.new(texture_kind: UI::TextureKind::Noise, texture_opacity: 0.07),
    )
  end

  form = UI::Form.new
  [UI::TabShape::Angled, UI::TabShape::Rounded, UI::TabShape::Notched, UI::TabShape::Flush].each_with_index do |shape, index|
    section = form.add_section(
      ["General", "Controls", "Keycaps", "Palette"][index],
      tab_shape: shape,
      tab_icon: "folder",
      panel_style: machined_panel_style,
      tab_style: UI::SurfaceStyle.new(
        background_fill_color: sample_color(
          UI::Color.new(r: 0.914, g: 0.878, b: 0.812),
          UI::Color.new(r: 0.208, g: 0.239, b: 0.329),
        ),
        list_of_inner_shadows: [
          UI::InnerShadow.new(
            shadow_color: sample_color(
              UI::Color.new(r: 0.725, g: 0.663, b: 0.537, a: 0.35),
              UI::Color.new(r: 1.0, g: 1.0, b: 1.0, a: 0.08),
            ),
            offset_y: 1.0,
            blur_radius: 1.0,
          ),
        ],
      ),
    )
    case index
    when 0
      initial_slide_value = !AX_TEST_MODE
      toggle = UI::Toggle.new("Launch", initial_slide_value)
      toggle.test_id = "surface-craft-slide-toggle"
      toggle.appearance = UI::ToggleAppearance::Slide
      toggle.track_color = sample_color(UI::Color.new(r: 0.847, g: 0.812, b: 0.749), UI::Color.new(r: 0.09, g: 0.106, b: 0.153))
      toggle.knob_color = sample_color(UI::Color.new(r: 1.0, g: 0.992, b: 0.973), UI::Color.new(r: 0.224, g: 0.255, b: 0.353))
      toggle.on_color = UI::Color.new(r: 0.855, g: 0.710, b: 0.431)
      toggle.lamp_color = UI::Color.new(r: 0.855, g: 0.710, b: 0.431)
      slide_result = UI::Label.new("Slide value: #{initial_slide_value}")
      slide_result.test_id = "surface-craft-slide-result"
      toggle.on_change = ->(is_on : Bool) { slide_result.text = "Slide value: #{is_on}" }
      pill = UI::Toggle.new("Audio", false)
      pill.appearance = UI::ToggleAppearance::Pill
      pill.track_color = sample_color(UI::Color.new(r: 0.847, g: 0.812, b: 0.749), UI::Color.new(r: 0.09, g: 0.106, b: 0.153))
      pill.knob_color = sample_color(UI::Color.new(r: 1.0, g: 0.992, b: 0.973), UI::Color.new(r: 0.224, g: 0.255, b: 0.353))
      pill.on_color = UI::Color.new(r: 0.855, g: 0.710, b: 0.431)
      switch_examples = UI::HStack.new(spacing: 12.0)
      switch_examples << toggle
      switch_examples << pill
      section.fields << UI::Form::Field.new(label: "Switch styles", content: switch_examples)
      if AX_TEST_MODE
        section.fields << UI::Form::Field.new(label: "AX result", content: slide_result)
      end
    when 1
      rocker = UI::Toggle.new("Hardware mode", true)
      rocker.appearance = UI::ToggleAppearance::Rocker
      rocker.track_color = sample_color(UI::Color.new(r: 0.847, g: 0.812, b: 0.749), UI::Color.new(r: 0.09, g: 0.106, b: 0.153))
      rocker.knob_color = sample_color(UI::Color.new(r: 1.0, g: 0.992, b: 0.973), UI::Color.new(r: 0.224, g: 0.255, b: 0.353))
      rocker.on_color = UI::Color.new(r: 0.855, g: 0.710, b: 0.431)
      section.fields << UI::Form::Field.new(label: "Mode", content: rocker)
      lamp = UI::Toggle.new("Recording", false)
      lamp.appearance = UI::ToggleAppearance::LampPill
      lamp.track_color = sample_color(UI::Color.new(r: 0.847, g: 0.812, b: 0.749), UI::Color.new(r: 0.09, g: 0.106, b: 0.153))
      lamp.knob_color = sample_color(UI::Color.new(r: 1.0, g: 0.992, b: 0.973), UI::Color.new(r: 0.224, g: 0.255, b: 0.353))
      lamp.on_color = UI::Color.new(r: 0.855, g: 0.710, b: 0.431)
      lamp.lamp_color = UI::Color.new(r: 0.855, g: 0.710, b: 0.431)
      section.fields << UI::Form::Field.new(label: "Status", content: lamp)
      auto_save = UI::Toggle.new("Automatic saving", true)
      auto_save.appearance = UI::ToggleAppearance::LampPill
      auto_save.on_color = UI::Color.new(r: 0.855, g: 0.710, b: 0.431)
      section.fields << UI::Form::Field.new(label: "Save", content: auto_save)
    when 2
      keycap_examples = UI::HStack.new(spacing: 8.0)
      [UI::KeycapStyle::Outlined, UI::KeycapStyle::Sculpted, UI::KeycapStyle::Inset, UI::KeycapStyle::Text].each do |style|
        keycap_examples << UI::Keycap.new("⌥ S", style: style)
      end
      section.fields << UI::Form::Field.new(label: "Keycap styles", content: keycap_examples)
    when 3
      swatches = [
        UI::ColorSwatch.new(color_name: "Copper", swatch_color: UI::Color.new(r: 0.72, g: 0.39, b: 0.22)),
        UI::ColorSwatch.new(color_name: "Slate", swatch_color: UI::Color.new(r: 0.34, g: 0.39, b: 0.47)),
        UI::ColorSwatch.new(color_name: "Moss", swatch_color: UI::Color.new(r: 0.34, g: 0.45, b: 0.30)),
      ]
      bezel_result = UI::Label.new("Bezel selection: 1: Slate")
      bezel_result.test_id = "surface-craft-bezel-result"
      row_result = UI::Label.new("Swatch row selection: 1: Slate")
      row_result.test_id = "surface-craft-row-result"
      swatch_examples = UI::HStack.new(spacing: 8.0)
      [
        UI::ColorSwatchPickerStyle::SwatchButton,
        UI::ColorSwatchPickerStyle::SwatchRow,
        UI::ColorSwatchPickerStyle::NamedPopup,
        UI::ColorSwatchPickerStyle::BezelLamp,
      ].each do |style|
        picker = UI::ColorSwatchPicker.new(list_of_color_swatches: swatches, selected_index: 1, appearance: style) do |_index|
          nil
        end
        if style == UI::ColorSwatchPickerStyle::BezelLamp
          picker.test_id = "surface-craft-bezel-picker"
          picker.on_change = ->(index : Int32) { bezel_result.text = "Bezel selection: #{index}: #{swatches[index].color_name}" }
        elsif style == UI::ColorSwatchPickerStyle::SwatchRow
          picker.test_id = "surface-craft-row-picker"
          picker.on_change = ->(index : Int32) { row_result.text = "Swatch row selection: #{index}: #{swatches[index].color_name}" }
        end
        swatch_examples << picker
      end
      section.fields << UI::Form::Field.new(label: "Swatch styles", content: swatch_examples)
      if AX_TEST_MODE
        section.fields << UI::Form::Field.new(label: "AX bezel result", content: bezel_result)
        section.fields << UI::Form::Field.new(label: "AX row result", content: row_result)
      end
    end
  end
  form.minimum_width = 620.0

  feedback_row = UI::HStack.new(spacing: 10.0)
  [UI::InteractionFeedback::Sink, UI::InteractionFeedback::Lift, UI::InteractionFeedback::Edge, UI::InteractionFeedback::None].each do |feedback|
    button = UI::Button.new(feedback.to_s)
    button.interaction_feedback = feedback
    feedback_row << button
  end

  title = UI::Label.new("Surface craft")
  title.font = UI::Font.new(size: 24.0, weight: :semibold)
  if font_path = ENV["SURFACE_CRAFT_FONT"]?
    if UI::FontRegistry.register_bundled_font_file(font_path)
      title.font = UI::Font.new(family: "Noto Sans", size: 24.0)
    end
  end

  content = UI::VStack.new(spacing: 14.0)
  content.padding = UI::EdgeInsets.new(top: 18.0, trailing: 20.0, bottom: 18.0, leading: 20.0)
  content.background_fill_color = sample_color(
    UI::Color.new(r: 0.945, g: 0.925, b: 0.890),
    UI::Color.new(r: 0.137, g: 0.161, b: 0.227),
  )
  content << title
  content << form
  content << feedback_row
  if AX_TEST_MODE
    preview_row = UI::HStack.new(spacing: 8.0)
    [
      {"Hover", UI::PreviewState::Hover, UI::InteractionFeedback::Sink, "hover"},
      {"Pressed", UI::PreviewState::Pressed, UI::InteractionFeedback::Sink, "pressed"},
      {"Focus", UI::PreviewState::Focus, UI::InteractionFeedback::None, "focus"},
      {"Edge focus", UI::PreviewState::Focus, UI::InteractionFeedback::Edge, "edge-focus"},
      {"Default", UI::PreviewState::None, UI::InteractionFeedback::None, "default"},
    ].each do |label, preview_state, feedback, identifier|
      button = UI::Button.new(label)
      button.preview_state = preview_state
      button.interaction_feedback = feedback
      button.test_id = "surface-craft-preview-#{identifier}"
      preview_row << button
    end
    content << preview_row
  end

  ENV["HIG_APPEARANCE"] = APPEARANCE
  renderer = UI::AppKit::Renderer.new
  native = renderer.render(content)
  window_title = "Surface craft component study (#{APPEARANCE})"
  window = SurfaceCraftWindow.hig_create_window_with_min(
    120.0, 100.0, 760.0, 760.0, 620.0, 560.0,
    window_title.to_unsafe, APPEARANCE.to_unsafe,
  )
  set_content = SurfaceCraftObjC.sel_registerName("setContentView:".to_unsafe)
  SurfaceCraftObjC.objc_send_void_id(window, set_content, native.handle.ptr!)
  SurfaceCraftWindow.hig_run_app(window)
{% else %}
  STDERR << "Build this sample with -Dmacos.\n"
  exit 1
{% end %}
