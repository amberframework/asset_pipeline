require "../spec_helper"
require "../../../src/ui"

describe "surface-craft UI primitives" do
  describe UI::LinearGradient do
    it "keeps ordered color stops and an angle" do
      gradient = UI::LinearGradient.new(
        list_of_stops: [
          UI::GradientStop.new(stop_color: UI::ColorRole::BrandPrimary, stop_position: 0.0),
          UI::GradientStop.new(stop_color: UI::Color.new(r: 0.9, g: 0.6, b: 0.2), stop_position: 1.0),
        ],
        gradient_angle: 135.0,
      )

      gradient.list_of_stops.size.should eq(2)
      gradient.gradient_angle.should eq(135.0)
    end

    it "rejects fewer than two stops and positions outside the normalized range" do
      one_stop = [UI::GradientStop.new(stop_color: UI::ColorRole::BrandPrimary, stop_position: 0.0)]
      expect_raises(UI::SurfaceCraftError, "A linear gradient requires at least two stops") do
        UI::LinearGradient.new(list_of_stops: one_stop)
      end

      invalid_stops = [
        UI::GradientStop.new(stop_color: UI::ColorRole::BrandPrimary, stop_position: 0.0),
        UI::GradientStop.new(stop_color: UI::ColorRole::BrandAccent, stop_position: 1.2),
      ]
      expect_raises(UI::SurfaceCraftError, "Gradient stop positions must be between 0 and 1") do
        UI::LinearGradient.new(list_of_stops: invalid_stops)
      end
    end

    it "rejects descending stop positions" do
      descending_stops = [
        UI::GradientStop.new(stop_color: UI::ColorRole::BrandPrimary, stop_position: 0.8),
        UI::GradientStop.new(stop_color: UI::ColorRole::BrandAccent, stop_position: 0.2),
      ]
      expect_raises(UI::SurfaceCraftError, "Gradient stop positions must be in ascending order") do
        UI::LinearGradient.new(list_of_stops: descending_stops)
      end
    end
  end

  describe UI::TextureOverlay do
    it "rejects opacity outside the inclusive zero-to-one range" do
      expect_raises(UI::SurfaceCraftError, "Texture opacity must be between 0 and 1") do
        UI::TextureOverlay.new(texture_kind: UI::TextureKind::Noise, texture_opacity: -0.1)
      end
      expect_raises(UI::SurfaceCraftError, "Texture opacity must be between 0 and 1") do
        UI::TextureOverlay.new(texture_kind: UI::TextureKind::Brushed, texture_opacity: 1.1)
      end
    end
  end

  describe UI::SurfaceCraftEncoding do
    it "serializes one typed payload shape for section styles and view overrides" do
      style = UI::SurfaceStyle.new(
        background_fill_color: UI::ColorRole::SurfacePanel,
        linear_gradient: UI::LinearGradient.new(
          list_of_stops: [
            UI::GradientStop.new(stop_color: UI::ColorRole::BrandPrimary, stop_position: 0.0),
            UI::GradientStop.new(stop_color: UI::ColorRole::SurfaceElevated, stop_position: 1.0),
          ],
          gradient_angle: 135.0,
        ),
        list_of_inner_shadows: [
          UI::InnerShadow.new(shadow_color: UI::ColorRole::TextInverse, offset_y: 1.0, blur_radius: 2.0),
        ],
        list_of_drop_shadows: [
          UI::DropShadow.new(shadow_color: UI::ColorRole::TextPrimary, offset_y: 3.0, blur_radius: 8.0),
        ],
        texture_overlay: UI::TextureOverlay.new(texture_kind: UI::TextureKind::Brushed, texture_opacity: 0.08),
      )

      style_json = UI::SurfaceCraftEncoding.style_json(style)
      style_json.should contain(%("fill":"role:surface-panel"))
      style_json.should contain(%("angle":135.0))
      style_json.should contain(%("innerShadows":[{"color":"role:text-inverse","x":0.0,"y":1.0,"blur":2.0}]))
      style_json.should contain(%("dropShadows":[{"color":"role:text-primary","x":0.0,"y":3.0,"blur":8.0}]))
      style_json.should contain(%("texture":{"kind":"brushed","opacity":0.08}))

      view = UI::VStack.new
      view.background_fill_color = UI::ColorRole::SurfacePanel
      view.list_of_inner_shadows = style.list_of_inner_shadows
      view.interaction_feedback = UI::InteractionFeedback::Sink
      view_json = view.surface_craft_json
      if payload = view_json
        payload.should contain(%("fill":"role:surface-panel"))
        payload.should contain(%("innerShadows"))
        payload.should contain(%("feedback":"sink"))
      else
        fail "surface-craft view payload was not emitted"
      end

      UI::SurfaceCraftEncoding.style_json(UI::SurfaceStyle.new).should eq("{}")
    end
  end

  describe "web surface rendering" do
    it "emits horizontal frequency for brushed texture streaks" do
      surface = UI::Surface.new(UI::Label.new("Brushed panel"))
      surface.texture_overlay = UI::TextureOverlay.new(
        texture_kind: UI::TextureKind::Brushed,
        texture_opacity: 0.08,
      )
      html = UI::Web::Renderer.new.render(surface)
      encoded_svg = if data_uri = html.split("data:image/svg+xml;base64,")[1]?
                      data_uri.split("&quot;").first?
                    end

      if encoded_svg
        String.new(Base64.decode(encoded_svg)).should contain(%(baseFrequency="0.72 0.018"))
      else
        fail "brushed texture data URI was not emitted"
      end
    end

    it "emits gradient, combined inner and drop shadows, and a procedural texture" do
      surface = UI::Surface.new(UI::Label.new("Machined panel"))
      surface.linear_gradient = UI::LinearGradient.new(
        list_of_stops: [
          UI::GradientStop.new(stop_color: UI::ColorRole::SurfaceElevated, stop_position: 0.0),
          UI::GradientStop.new(stop_color: UI::ColorRole::SurfacePanel, stop_position: 1.0),
        ],
        gradient_angle: 180.0,
      )
      surface.list_of_inner_shadows = [
        UI::InnerShadow.new(shadow_color: UI::ColorRole::TextInverse, offset_x: 0.0, offset_y: 1.0, blur_radius: 1.0),
        UI::InnerShadow.new(shadow_color: UI::ColorRole::SurfaceInverse, offset_x: 0.0, offset_y: -2.0, blur_radius: 4.0),
      ]
      surface.list_of_drop_shadows = [
        UI::DropShadow.new(shadow_color: UI::ColorRole::TextPrimary, offset_x: 0.0, offset_y: 3.0, blur_radius: 8.0),
      ]
      surface.texture_overlay = UI::TextureOverlay.new(
        texture_kind: UI::TextureKind::Noise,
        texture_opacity: 0.12,
      )

      html = UI::Web::Renderer.new.render(surface)

      html.should contain("linear-gradient(180.0deg")
      html.should contain("inset 0px 1px 1px")
      html.should contain("0px 3px 8px")
      html.should contain("data:image/svg+xml")
      html.should contain("--ap-color-surface-elevated")
    end

    it "renders all four tabbed Form section shapes with separate panel and tab styles" do
      shapes = [
        UI::TabShape::Angled,
        UI::TabShape::Rounded,
        UI::TabShape::Notched,
        UI::TabShape::Flush,
      ]

      shapes.each do |shape|
        form = UI::Form.new
        section = form.add_section(
          header: "Storage",
          tab_shape: shape,
          tab_icon: "folder",
          panel_style: UI::SurfaceStyle.new(
            background_fill_color: UI::ColorRole::SurfacePanel,
            texture_overlay: UI::TextureOverlay.new(
              texture_kind: UI::TextureKind::Brushed,
              texture_opacity: 0.08,
            ),
          ),
          tab_style: UI::SurfaceStyle.new(
            background_fill_color: UI::ColorRole::BrandAccent,
          ),
        )
        section.fields << UI::Form::Field.new(label: "Save to", content: UI::Label.new("Documents"))

        html = UI::Web::Renderer.new.render(form)

        html.should contain(%(data-ap-tab-shape="#{shape.to_s.downcase}"))
        html.should contain(%(data-ap-tab-icon="folder"))
        html.should contain("--ap-color-surface-panel")
        html.should contain("--ap-color-brand-accent")
      end
    end

    it "renders explicit machined toggle appearances with switch semantics and token colors" do
      appearances = [
        UI::ToggleAppearance::Pill,
        UI::ToggleAppearance::Rocker,
        UI::ToggleAppearance::Slide,
        UI::ToggleAppearance::LampPill,
      ]

      appearances.each do |appearance|
        toggle = UI::Toggle.new("Enable", true)
        toggle.appearance = appearance
        toggle.track_color = UI::ColorRole::SurfaceSunken
        toggle.knob_color = UI::ColorRole::TextInverse
        toggle.on_color = UI::ColorRole::BrandPrimary
        toggle.lamp_color = UI::ColorRole::Warning

        html = UI::Web::Renderer.new.render(toggle)

        html.should contain(%(data-ap-toggle-appearance="#{appearance.to_s.underscore}"))
        html.should contain(%(role="switch"))
        html.should contain(%(aria-checked="true"))
        html.should contain("--ap-color-surface-sunken")
        html.should contain("--ap-color-warning")
      end
    end

    it "renders the four keycap styles as semantic keyboard labels" do
      styles = [
        UI::KeycapStyle::Outlined,
        UI::KeycapStyle::Sculpted,
        UI::KeycapStyle::Inset,
        UI::KeycapStyle::Text,
      ]

      styles.each do |style|
        html = UI::Web::Renderer.new.render(UI::Keycap.new("⌥", style: style))
        html.should contain("<kbd")
        html.should contain(%(data-ap-keycap-style="#{style.to_s.downcase}"))
        html.should contain("monospace")
      end
    end

    it "renders all named swatch picker appearances with accessible selection state" do
      swatches = [
        UI::ColorSwatch.new(color_name: "Gold", swatch_color: UI::Color.new(r: 0.85, g: 0.65, b: 0.25)),
        UI::ColorSwatch.new(color_name: "Ink", swatch_color: UI::ColorRole::TextPrimary),
      ]
      appearances = [
        UI::ColorSwatchPickerStyle::SwatchButton,
        UI::ColorSwatchPickerStyle::SwatchRow,
        UI::ColorSwatchPickerStyle::NamedPopup,
        UI::ColorSwatchPickerStyle::BezelLamp,
      ]

      appearances.each do |appearance|
        picker = UI::ColorSwatchPicker.new(list_of_color_swatches: swatches, selected_index: 1)
        picker.appearance = appearance

        html = UI::Web::Renderer.new.render(picker)

        html.should contain(%(data-ap-swatch-style="#{appearance.to_s.underscore}"))
        html.should contain(%(aria-checked="true"))
        html.should contain("Ink")
        html.should contain("--ap-color-text-primary")
      end
    end

    it "uses the text-ink role for the swatch-row ring by default and accepts an override" do
      swatches = [
        UI::ColorSwatch.new(color_name: "Copper", swatch_color: UI::ColorRole::Warning),
        UI::ColorSwatch.new(color_name: "Ink", swatch_color: UI::ColorRole::TextPrimary),
      ]
      picker = UI::ColorSwatchPicker.new(
        list_of_color_swatches: swatches,
        selected_index: 1,
        appearance: UI::ColorSwatchPickerStyle::SwatchRow,
      )

      html = UI::Web::Renderer.new.render(picker)
      html.should contain("outline: 2px solid var(--ap-color-text-primary)")
      html.should_not contain("outline: 2px solid var(--ap-color-brand-primary)")

      picker.selection_ring_color = UI::ColorRole::BrandAccent
      html = UI::Web::Renderer.new.render(picker)
      html.should contain("outline: 2px solid var(--ap-color-brand-accent)")
    end

    it "emits typed toggle and named swatch payloads with the Swift facade's camel-case keys" do
      toggle = UI::Toggle.new("Enable")
      toggle.appearance = UI::ToggleAppearance::Slide
      toggle.track_color = UI::ColorRole::SurfaceSunken
      toggle.lamp_color = UI::ColorRole::Warning

      toggle_json = toggle.surface_craft_toggle_json
      if payload = toggle_json
        payload.should contain(%("appearance":"slide"))
        payload.should contain(%("track":"role:surface-sunken"))
        payload.should contain(%("lamp":"role:warning"))
        payload.should_not contain(%("on":null))
      else
        fail "custom toggle payload was not emitted"
      end

      picker = UI::ColorSwatchPicker.new(
        list_of_color_swatches: [
          UI::ColorSwatch.new(color_name: "Copper", swatch_color: UI::ColorRole::Warning),
        ],
      )
      picker_json = picker.surface_craft_picker_json
      picker_json.should contain(%("appearance":"swatch_button"))
      picker_json.should contain(%("name":"Copper","color":"role:warning"))
      picker_json.should contain(%("selectionRing":"role:text-primary"))

      picker.selection_ring_color = UI::ColorRole::BrandAccent
      picker.surface_craft_picker_json.should contain(%("selectionRing":"role:brand-accent"))
    end

    it "emits opt-in feedback hooks and a reduced-motion rule" do
      button = UI::Button.new("Open")
      button.interaction_feedback = UI::InteractionFeedback::Lift

      html = UI::Web::Renderer.new.render(button)
      css = UI::Web::Renderer.new.inject_theme_css

      html.should contain(%(data-ap-feedback="lift"))
      css.should contain("prefers-reduced-motion: reduce")
      css.should contain(%([data-ap-feedback="lift"]:hover))
    end
  end
end
