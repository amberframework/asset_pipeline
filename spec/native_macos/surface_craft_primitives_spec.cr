require "spec"
require "../../src/ui"

{% if flag?(:macos) %}
  @[Link("objc")]
  lib SurfaceCraftObjCRuntime
    fun objc_getClass(name : UInt8*) : Void*
    fun sel_registerName(name : UInt8*) : Void*
    fun objc_msgSend(receiver : Void*, selector : Void*) : UInt8*
  end

  lib PreviewStateCaptureTestBridge
    fun ap_spec_capture_appkit_view(view : Void*) : Int32
    fun ap_spec_attach_noise_view_and_change_backing_scale(
      view : Void*,
      point_width : Float64,
      point_height : Float64,
      initial_scale : Float64,
      changed_scale : Float64,
      initial_tile_width : Int32*,
      initial_tile_height : Int32*,
      changed_tile_width : Int32*,
      changed_tile_height : Int32*,
    ) : Int32
    fun ap_spec_attach_and_detach_noise_view(
      view : Void*,
      point_width : Float64,
      point_height : Float64,
      backing_scale : Float64,
    ) : Int32
    fun ap_spec_attach_noise_view_to_held_window(
      view : Void*,
      point_width : Float64,
      point_height : Float64,
      backing_scale : Float64,
    ) : Int32
    fun ap_spec_close_held_noise_window : Void
    fun ap_spec_noise_texture_layout_metrics(
      view : Void*,
      texture_width : Float64*,
      texture_height : Float64*,
      row_count : Int32*,
      column_count : Int32*,
    ) : Int32
    fun ap_spec_surface_layer_count(view : Void*, name : UInt8*) : Int32
    fun ap_spec_appkit_view_layer_translation_y(view : Void*) : Float64
    fun ap_spec_appkit_view_layer_shadow_opacity(view : Void*) : Float32
  end

  lib NoiseTextureFixtureBridge
    fun ap_spec_render_noise_red_grayscale_reference(
      base_frequency : Float64,
      octave_count : Int32,
      seed : Int32,
      tile_size : Int32,
      backing_scale : Float64,
      pixels : UInt8*,
      capacity : Int32,
      pixel_width : Int32*,
      pixel_height : Int32*,
    ) : Int32
    fun ap_spec_render_surface_craft_json(
      json : UInt8*,
      point_width : Float64,
      point_height : Float64,
      backing_scale : Float64,
      pixels : UInt8*,
      capacity : Int32,
      pixel_width : Int32*,
      pixel_height : Int32*,
      tile_pixel_width : Int32*,
      tile_pixel_height : Int32*,
      texture_opacity : Float64*,
      contents_scale : Float64*,
      has_compositing_filter : Int32*,
    ) : Int32
    fun ap_spec_rebake_noise_surface_on_scale_change(
      json : UInt8*,
      point_width : Float64,
      point_height : Float64,
      initial_scale : Float64,
      new_scale : Float64,
      initial_tile_width : Int32*,
      initial_tile_height : Int32*,
      initial_contents_scale : Float64*,
      new_tile_width : Int32*,
      new_tile_height : Int32*,
      new_contents_scale : Float64*,
    ) : Int32
    fun ap_spec_copy_png_rgba(
      path : UInt8*,
      pixels : UInt8*,
      capacity : Int32,
      pixel_width : Int32*,
      pixel_height : Int32*,
    ) : Int32
  end

  private def surface_craft_capture_native(native : UI::NativeView) : Int32
    UI::ObjC.autoreleasepool do
      PreviewStateCaptureTestBridge.ap_spec_capture_appkit_view(native.handle.ptr!)
    end
  end

  private def surface_craft_capture_view(view : UI::View) : Int32
    native = UI::AppKit::Renderer.new.render(view)
    begin
      surface_craft_capture_native(native)
    ensure
      native.teardown!
    end
  end

  private def surface_craft_test_nsview : Void*
    cls = SurfaceCraftObjCRuntime.objc_getClass("NSView")
    allocated = UI::AppKit::LibObjCBridge.objc_send(cls, SurfaceCraftObjCRuntime.sel_registerName("alloc"))
    UI::AppKit::LibObjCBridge.objc_send(allocated, SurfaceCraftObjCRuntime.sel_registerName("init"))
  end

  private def surface_craft_gray_statistics(pixels : Array(UInt8), pixel_width : Int32, pixel_height : Int32) : {Float64, Float64}
    pixel_count = pixel_width.to_i64 * pixel_height.to_i64
    values = Array(Float64).new(pixel_count.to_i32)
    total = 0.0
    pixel_count.times do |index|
      gray_value = pixels[index.to_i32 * 4].to_f64
      values << gray_value
      total += gray_value
    end
    mean = total / pixel_count
    sum_of_squared_differences = values.sum do |value|
      difference = value - mean
      difference * difference
    end
    {mean, Math.sqrt(sum_of_squared_differences / pixel_count)}
  end

  private def surface_craft_measure_luma_statistics(pixels : Array(UInt8), pixel_width : Int32, pixel_height : Int32) : {Float64, Float64}
    pixel_count = pixel_width.to_i64 * pixel_height.to_i64
    list_of_luma_values = Array(Float64).new(pixel_count.to_i32)
    pixel_count.times do |index|
      offset = index.to_i32 * 4
      red = pixels[offset].to_f64
      green = pixels[offset + 1].to_f64
      blue = pixels[offset + 2].to_f64
      list_of_luma_values << red * 0.2126 + green * 0.7152 + blue * 0.0722
    end
    mean = list_of_luma_values.sum / pixel_count
    sum_of_squared_differences = list_of_luma_values.sum do |value|
      difference = value - mean
      difference * difference
    end
    {mean, Math.sqrt(sum_of_squared_differences / pixel_count)}
  end

  describe "surface-craft macOS native rendering" do
    it "creates gradient, tiled texture, inner-shadow, and multiple drop-shadow layers on raw AppKit views" do
      gradient = UI::LinearGradient.new(
        list_of_stops: [
          UI::GradientStop.new(stop_color: UI::ColorRole::SurfaceElevated, stop_position: 0.0),
          UI::GradientStop.new(stop_color: UI::ColorRole::SurfacePanel, stop_position: 1.0),
        ],
        gradient_angle: 135.0,
      )
      surface = UI::VStack.new
      surface.linear_gradient = gradient
      surface.texture_overlay = UI::TextureOverlay.new(texture_kind: UI::TextureKind::Noise, texture_opacity: 0.1)
      surface.list_of_inner_shadows = [
        UI::InnerShadow.new(shadow_color: UI::ColorRole::TextInverse, offset_y: 1.0, blur_radius: 2.0),
      ]
      surface.list_of_drop_shadows = [
        UI::DropShadow.new(shadow_color: UI::ColorRole::TextPrimary, offset_y: 2.0, blur_radius: 5.0),
        UI::DropShadow.new(shadow_color: UI::ColorRole::BrandPrimary, offset_y: 4.0, blur_radius: 9.0),
      ]

      native_view = surface_craft_test_nsview
      payload = surface.surface_craft_json
      if json = payload
        UI::AppKit::LibObjCBridge.appkit_view_apply_surface_craft(native_view, json.to_unsafe)
      else
        fail "surface-craft payload was not created"
      end

      UI::AppKit::LibObjCBridge.appkit_view_has_surface_layer(native_view, "ap.surfaceCraft.gradient").should eq(1)
      UI::AppKit::LibObjCBridge.appkit_view_has_surface_layer(native_view, "ap.surfaceCraft.texture").should eq(1)
      UI::AppKit::LibObjCBridge.appkit_view_has_surface_layer(native_view, "ap.surfaceCraft.drop.0").should eq(1)
      UI::AppKit::LibObjCBridge.appkit_view_has_surface_layer(native_view, "ap.surfaceCraft.drop.1").should eq(1)
      UI::AppKit::LibObjCBridge.appkit_view_has_surface_layer(native_view, "ap.surfaceCraft.inner.0").should eq(1)
    end

    it "keeps the existing fixed brushed tile and multiply compositing" do
      surface = UI::VStack.new
      surface.texture_overlay = UI::TextureOverlay.new(
        texture_kind: UI::TextureKind::Brushed,
        texture_opacity: 0.08,
        base_frequency: 0.83,
        octave_count: 5,
        seed: 7,
        tile_size: 128,
      )
      json = if payload = surface.surface_craft_json
               payload
             else
               fail "Brushed surface payload was not emitted"
             end
      pixels = Array(UInt8).new(32 * 32 * 4, 0_u8)
      pixel_width = 0
      pixel_height = 0
      tile_pixel_width = 0
      tile_pixel_height = 0
      texture_opacity = 0.0
      contents_scale = 0.0
      has_compositing_filter = 0

      NoiseTextureFixtureBridge.ap_spec_render_surface_craft_json(
        json.to_unsafe,
        32.0,
        32.0,
        1.0,
        pixels.to_unsafe,
        pixels.size,
        pointerof(pixel_width),
        pointerof(pixel_height),
        pointerof(tile_pixel_width),
        pointerof(tile_pixel_height),
        pointerof(texture_opacity),
        pointerof(contents_scale),
        pointerof(has_compositing_filter),
      ).should eq(1)

      tile_pixel_width.should eq(64)
      tile_pixel_height.should eq(64)
      (texture_opacity - 0.08).abs.should be <= 0.001
      has_compositing_filter.should eq(1)
    end

    it "attaches Noise to an ordered-out window and rebakes after its backing scale changes" do
      surface = UI::VStack.new
      surface << UI::Label.new("Panel content")
      surface.texture_overlay = UI::TextureOverlay.new(
        texture_kind: UI::TextureKind::Noise,
        texture_opacity: 0.07,
        base_frequency: 0.83,
        octave_count: 3,
        seed: 7,
        tile_size: 128,
      )
      surface.linear_gradient = UI::LinearGradient.new(
        list_of_stops: [
          UI::GradientStop.new(stop_color: UI::ColorRole::SurfaceElevated, stop_position: 0.0),
          UI::GradientStop.new(stop_color: UI::ColorRole::SurfacePanel, stop_position: 1.0),
        ],
        gradient_angle: 135.0,
      )
      surface.list_of_drop_shadows = [
        UI::DropShadow.new(shadow_color: UI::ColorRole::TextPrimary, offset_y: 2.0, blur_radius: 5.0),
      ]
      native = UI::AppKit::Renderer.new.render(surface)
      initial_tile_width = 0
      initial_tile_height = 0
      changed_tile_width = 0
      changed_tile_height = 0
      texture_width = 0.0
      texture_height = 0.0
      texture_row_count = 0
      texture_column_count = 0

      begin
        result = UI::ObjC.autoreleasepool do
          PreviewStateCaptureTestBridge.ap_spec_attach_noise_view_and_change_backing_scale(
            native.handle.ptr!,
            300.0,
            270.0,
            2.0,
            1.0,
            pointerof(initial_tile_width),
            pointerof(initial_tile_height),
            pointerof(changed_tile_width),
            pointerof(changed_tile_height),
          )
        end
        result.should eq(1)
        initial_tile_width.should eq(256)
        initial_tile_height.should eq(256)
        changed_tile_width.should eq(128)
        changed_tile_height.should eq(128)
        PreviewStateCaptureTestBridge.ap_spec_noise_texture_layout_metrics(
          native.handle.ptr!,
          pointerof(texture_width),
          pointerof(texture_height),
          pointerof(texture_row_count),
          pointerof(texture_column_count),
        ).should eq(1)
        texture_width.should eq(300.0)
        texture_height.should eq(270.0)
        texture_row_count.should eq(3)
        texture_column_count.should eq(3)
        PreviewStateCaptureTestBridge.ap_spec_surface_layer_count(
          native.handle.ptr!, "ap.surfaceCraft.gradient",
        ).should eq(1)
        PreviewStateCaptureTestBridge.ap_spec_surface_layer_count(
          native.handle.ptr!, "ap.surfaceCraft.texture",
        ).should eq(1)
        PreviewStateCaptureTestBridge.ap_spec_surface_layer_count(
          native.handle.ptr!, "ap.surfaceCraft.drop.0",
        ).should eq(1)
      ensure
        native.teardown!
      end
    end

    it "tears down a Noise view immediately after ordered-out window attachment" do
      surface = UI::VStack.new
      surface << UI::Label.new("Panel content")
      surface.texture_overlay = UI::TextureOverlay.new(
        texture_kind: UI::TextureKind::Noise,
        texture_opacity: 0.07,
        base_frequency: 0.83,
        octave_count: 3,
        seed: 7,
        tile_size: 128,
      )
      native = UI::AppKit::Renderer.new.render(surface)

      begin
        result = UI::ObjC.autoreleasepool do
          PreviewStateCaptureTestBridge.ap_spec_attach_noise_view_to_held_window(
            native.handle.ptr!,
            128.0,
            128.0,
            2.0,
          )
        end
        result.should eq(1)
        UI::ObjC.autoreleasepool { native.teardown! }
      ensure
        UI::ObjC.autoreleasepool do
          PreviewStateCaptureTestBridge.ap_spec_close_held_noise_window
          native.teardown!
        end
      end
    end

    it "attaches a Noise Surface hosting view to an ordered-out window" do
      surface = UI::Surface.new(UI::Label.new("Panel content"))
      surface.texture_overlay = UI::TextureOverlay.new(
        texture_kind: UI::TextureKind::Noise,
        texture_opacity: 0.07,
        base_frequency: 0.83,
        octave_count: 3,
        seed: 7,
        tile_size: 128,
      )
      native = UI::AppKit::Renderer.new.render(surface)

      begin
        result = UI::ObjC.autoreleasepool do
          PreviewStateCaptureTestBridge.ap_spec_attach_and_detach_noise_view(
            native.handle.ptr!,
            128.0,
            128.0,
            2.0,
          )
        end
        result.should eq(1)
      ensure
        native.teardown!
      end
    end

    it "matches the red-channel grayscale SVG turbulence fixture over a flat fill at 2x" do
      pixel_capacity = 256 * 256 * 4
      native_pixels = Array(UInt8).new(pixel_capacity, 0_u8)
      repeated_pixels = Array(UInt8).new(pixel_capacity, 0_u8)
      reference_pixels = Array(UInt8).new(pixel_capacity, 0_u8)
      native_pixel_width = 0
      native_pixel_height = 0
      reference_pixel_width = 0
      reference_pixel_height = 0
      NoiseTextureFixtureBridge.ap_spec_render_noise_red_grayscale_reference(
        0.83,
        3,
        7,
        128,
        2.0,
        native_pixels.to_unsafe,
        pixel_capacity,
        pointerof(native_pixel_width),
        pointerof(native_pixel_height),
      ).should eq(1)

      repeated_pixel_width = 0
      repeated_pixel_height = 0
      NoiseTextureFixtureBridge.ap_spec_render_noise_red_grayscale_reference(
        0.83,
        3,
        7,
        128,
        2.0,
        repeated_pixels.to_unsafe,
        pixel_capacity,
        pointerof(repeated_pixel_width),
        pointerof(repeated_pixel_height),
      ).should eq(1)

      fixture_path = File.expand_path("fixtures/noise-tile/reference.png", __DIR__)
      NoiseTextureFixtureBridge.ap_spec_copy_png_rgba(
        fixture_path.to_unsafe,
        reference_pixels.to_unsafe,
        pixel_capacity,
        pointerof(reference_pixel_width),
        pointerof(reference_pixel_height),
      ).should eq(1)
      native_pixel_width.should eq(256)
      native_pixel_height.should eq(256)
      reference_pixel_width.should eq(256)
      reference_pixel_height.should eq(256)

      maximum_pixel_difference = 0
      pixel_count = native_pixel_width * native_pixel_height
      pixel_count.times do |index|
        pixel_offset = index * 4
        native_gray = native_pixels[pixel_offset]
        reference_gray = reference_pixels[pixel_offset]
        (0..2).each do |channel_offset|
          (native_pixels[pixel_offset + channel_offset].to_i32 - native_gray.to_i32).abs.should be <= 1
          (reference_pixels[pixel_offset + channel_offset].to_i32 - reference_gray.to_i32).abs.should be <= 1
        end
        difference = (native_gray.to_i32 - reference_gray.to_i32).abs
        maximum_pixel_difference = difference if difference > maximum_pixel_difference
      end

      native_mean, native_standard_deviation = surface_craft_gray_statistics(native_pixels, native_pixel_width, native_pixel_height)
      reference_mean, reference_standard_deviation = surface_craft_gray_statistics(reference_pixels, reference_pixel_width, reference_pixel_height)
      # The fixture is rendered by librsvg and the live layer by Core Animation;
      # the measured output-channel difference is at most 7/255 at 7% opacity.
      maximum_pixel_difference.should be <= 7
      (native_mean - reference_mean).abs.should be <= 0.5
      (native_standard_deviation - reference_standard_deviation).abs.should be <= 0.5
      repeated_pixels.should eq(native_pixels)
    end

    it "matches browser RGBA Noise compositing over light and dark fills at 2x" do
      list_of_fixture_cases = [
        {fill: UI::Color.new(r: 251.0 / 255.0, g: 248.0 / 255.0, b: 242.0 / 255.0), file: "light-reference.png"},
        {fill: UI::Color.new(r: 43.0 / 255.0, g: 50.0 / 255.0, b: 69.0 / 255.0), file: "dark-reference.png"},
      ]
      pixel_capacity = 256 * 256 * 4

      list_of_fixture_cases.each do |fixture_case|
        surface = UI::VStack.new
        surface.background_fill_color = fixture_case[:fill]
        surface.texture_overlay = UI::TextureOverlay.new(
          texture_kind: UI::TextureKind::Noise,
          texture_opacity: 0.07,
          base_frequency: 0.83,
          octave_count: 3,
          seed: 7,
          tile_size: 128,
        )
        json = surface.surface_craft_json || fail("Noise surface payload was not emitted")
        native_pixels = Array(UInt8).new(pixel_capacity, 0_u8)
        native_pixel_width = 0
        native_pixel_height = 0
        tile_pixel_width = 0
        tile_pixel_height = 0
        texture_opacity = 0.0
        contents_scale = 0.0
        has_compositing_filter = 0

        NoiseTextureFixtureBridge.ap_spec_render_surface_craft_json(
          json.to_unsafe,
          128.0,
          128.0,
          2.0,
          native_pixels.to_unsafe,
          pixel_capacity,
          pointerof(native_pixel_width),
          pointerof(native_pixel_height),
          pointerof(tile_pixel_width),
          pointerof(tile_pixel_height),
          pointerof(texture_opacity),
          pointerof(contents_scale),
          pointerof(has_compositing_filter),
        ).should eq(1)

        reference_path = File.expand_path("fixtures/noise-composite/#{fixture_case[:file]}", __DIR__)
        reference_pixels = Array(UInt8).new(pixel_capacity, 0_u8)
        reference_pixel_width = 0
        reference_pixel_height = 0
        NoiseTextureFixtureBridge.ap_spec_copy_png_rgba(
          reference_path.to_unsafe,
          reference_pixels.to_unsafe,
          pixel_capacity,
          pointerof(reference_pixel_width),
          pointerof(reference_pixel_height),
        ).should eq(1)

        native_pixel_width.should eq(256)
        native_pixel_height.should eq(256)
        reference_pixel_width.should eq(256)
        reference_pixel_height.should eq(256)
        native_mean, native_standard_deviation = surface_craft_measure_luma_statistics(native_pixels, native_pixel_width, native_pixel_height)
        reference_mean, reference_standard_deviation = surface_craft_measure_luma_statistics(reference_pixels, reference_pixel_width, reference_pixel_height)

        # The mean allows one 8-bit level for compositor rounding. The tighter
        # standard-deviation bound catches a doubled or missing layer opacity.
        (native_mean - reference_mean).abs.should be <= 1.0
        (native_standard_deviation - reference_standard_deviation).abs.should be <= 0.15
        tile_pixel_width.should eq(256)
        tile_pixel_height.should eq(256)
        (texture_opacity - 0.07).abs.should be <= 0.001
        (contents_scale - 2.0).abs.should be <= 0.001
        has_compositing_filter.should eq(0)
      end
    end

    it "renders custom toggle styles, keycaps, swatch pickers, and tabbed sections through SwiftUI hosts" do
      renderer = UI::AppKit::Renderer.new

      [
        UI::ToggleAppearance::Pill,
        UI::ToggleAppearance::Rocker,
        UI::ToggleAppearance::Slide,
        UI::ToggleAppearance::LampPill,
      ].each do |appearance|
        toggle = UI::Toggle.new("Enable")
        toggle.appearance = appearance
        toggle.on_color = UI::ColorRole::BrandPrimary
        renderer.render(toggle).handle.label.should eq("NSHostingView[Toggle]")
      end

      [
        UI::KeycapStyle::Outlined,
        UI::KeycapStyle::Sculpted,
        UI::KeycapStyle::Inset,
        UI::KeycapStyle::Text,
      ].each do |style|
        keycap = UI::Keycap.new("⌥", style: style)
        renderer.render(keycap).handle.label.should eq("NSHostingView[Label]")
      end

      swatches = [
        UI::ColorSwatch.new(color_name: "Gold", swatch_color: UI::ColorRole::Warning),
        UI::ColorSwatch.new(color_name: "Ink", swatch_color: UI::ColorRole::TextPrimary),
      ]
      [
        UI::ColorSwatchPickerStyle::SwatchButton,
        UI::ColorSwatchPickerStyle::SwatchRow,
        UI::ColorSwatchPickerStyle::NamedPopup,
        UI::ColorSwatchPickerStyle::BezelLamp,
      ].each do |appearance|
        picker = UI::ColorSwatchPicker.new(list_of_color_swatches: swatches, appearance: appearance)
        picker.on_change = ->(_index : Int32) { nil }
        renderer.render(picker).handle.label.should eq("NSHostingView[Picker]")
      end

      [
        UI::InteractionFeedback::Sink,
        UI::InteractionFeedback::Lift,
        UI::InteractionFeedback::Edge,
        UI::InteractionFeedback::None,
      ].each do |feedback|
        button = UI::Button.new("Open")
        button.interaction_feedback = feedback
        renderer.render(button).handle.label.should eq("NSHostingController[Button]")
      end

      form = UI::Form.new
      [UI::TabShape::Angled, UI::TabShape::Rounded, UI::TabShape::Notched, UI::TabShape::Flush].each do |shape|
        form.add_section("Panel", tab_shape: shape, tab_icon: "folder")
      end
      renderer.render(form).handle.label.should eq("NSHostingView[Form]")
    end

    it "renders and captures a Toggle in every preview state" do
      appearances = [
        {UI::ToggleAppearance::Native, UI::InteractionFeedback::None},
        {UI::ToggleAppearance::Pill, UI::InteractionFeedback::Sink},
        {UI::ToggleAppearance::Rocker, UI::InteractionFeedback::Lift},
        {UI::ToggleAppearance::Slide, UI::InteractionFeedback::Edge},
        {UI::ToggleAppearance::LampPill, UI::InteractionFeedback::Sink},
      ]
      preview_states = {
        UI::PreviewState::None,
        UI::PreviewState::Hover,
        UI::PreviewState::Pressed,
        UI::PreviewState::Focus,
      }

      appearances.each do |appearance, feedback|
        preview_states.each do |preview_state|
          toggle = UI::Toggle.new("Preview toggle")
          toggle.appearance = appearance
          toggle.interaction_feedback = feedback
          toggle.preview_state = preview_state

          surface_craft_capture_view(toggle).should eq(1)
        end
      end
    end

    it "captures a preview-state Toggle after six static AppKit cells" do
      renderer = UI::AppKit::Renderer.new
      6.times do |index|
        cell = UI::HStack.new(spacing: 6.0)
        cell.background_fill_color = UI::ColorRole::SurfacePanel
        cell.interaction_feedback = UI::InteractionFeedback::Edge
        cell << UI::Label.new("Static cell #{index + 1}")
        cell << UI::Keycap.new("⌘")
        native = renderer.render(cell)
        begin
          surface_craft_capture_native(native).should eq(1)
        ensure
          native.teardown!
        end
      end

      {
        UI::PreviewState::Hover,
        UI::PreviewState::Pressed,
        UI::PreviewState::Focus,
      }.each do |preview_state|
        toggle = UI::Toggle.new("Preview toggle")
        toggle.appearance = UI::ToggleAppearance::Pill
        toggle.interaction_feedback = UI::InteractionFeedback::Sink
        toggle.preview_state = preview_state
        native = renderer.render(toggle)
        begin
          surface_craft_capture_native(native).should eq(1)
        ensure
          native.teardown!
        end
      end
    end

    it "changes an HStack container face for forced hover, pressed, and focus" do
      capture_stack = ->(preview_state : UI::PreviewState, feedback : UI::InteractionFeedback) do
        stack = UI::HStack.new(spacing: 8.0)
        stack.background_fill_color = UI::ColorRole::SurfacePanel
        stack.corner_radius = 8.0
        stack.interaction_feedback = feedback
        stack.preview_state = preview_state
        stack << UI::Button.new("Composite control")
        native = UI::AppKit::Renderer.new.render(stack)
        begin
          native.children.size.should eq(1)
          child = native.children.first
          {
            "ap.surfaceCraft.preview.hover",
            "ap.surfaceCraft.preview.edge",
            "ap.surfaceCraft.preview.focusRing",
          }.each do |preview_layer|
            UI::AppKit::LibObjCBridge.appkit_view_has_surface_layer(child.handle.ptr!, preview_layer).should eq(0)
          end

          expected_layer = case preview_state
                           when UI::PreviewState::Hover then "ap.surfaceCraft.preview.hover"
                           when UI::PreviewState::Focus
                             feedback == UI::InteractionFeedback::Edge ? "ap.surfaceCraft.preview.edge" : "ap.surfaceCraft.preview.focusRing"
                           when UI::PreviewState::Pressed
                             feedback == UI::InteractionFeedback::Edge ? "ap.surfaceCraft.preview.edge" : nil
                           else nil
                           end
          if layer_name = expected_layer
            UI::AppKit::LibObjCBridge.appkit_view_has_surface_layer(native.handle.ptr!, layer_name).should eq(1)
          end
          expected_translation = case feedback
                                 when UI::InteractionFeedback::Sink
                                   preview_state == UI::PreviewState::Pressed ? -1.0 : 0.0
                                 when UI::InteractionFeedback::Lift
                                   preview_state == UI::PreviewState::Hover ? 2.0 : (preview_state == UI::PreviewState::Pressed ? -1.0 : 0.0)
                                 when UI::InteractionFeedback::Edge
                                   preview_state == UI::PreviewState::Pressed ? -1.0 : 0.0
                                 else
                                   0.0
                                 end
          PreviewStateCaptureTestBridge.ap_spec_appkit_view_layer_translation_y(native.handle.ptr!).should eq(expected_translation)
          expected_shadow_opacity = feedback == UI::InteractionFeedback::Lift &&
                                    {UI::PreviewState::Hover, UI::PreviewState::Pressed}.includes?(preview_state) ? 0.16_f32 : 0.0_f32
          PreviewStateCaptureTestBridge.ap_spec_appkit_view_layer_shadow_opacity(native.handle.ptr!).should eq(expected_shadow_opacity)
          UI::ObjC.autoreleasepool do
            PreviewStateCaptureTestBridge.ap_spec_capture_appkit_view(native.handle.ptr!).should eq(1)
          end
        ensure
          native.teardown!
        end
      end

      capture_stack.call(UI::PreviewState::None, UI::InteractionFeedback::Sink)
      {
        {UI::PreviewState::Hover, UI::InteractionFeedback::Sink},
        {UI::PreviewState::Pressed, UI::InteractionFeedback::Sink},
        {UI::PreviewState::Hover, UI::InteractionFeedback::Lift},
        {UI::PreviewState::Pressed, UI::InteractionFeedback::Lift},
        {UI::PreviewState::Hover, UI::InteractionFeedback::Edge},
        {UI::PreviewState::Pressed, UI::InteractionFeedback::Edge},
        {UI::PreviewState::Focus, UI::InteractionFeedback::Sink},
        {UI::PreviewState::Focus, UI::InteractionFeedback::Edge},
      }.each do |preview_state, feedback|
        capture_stack.call(preview_state, feedback)
      end
    end

    it "passes the selected custom toggle appearance through the Objective-C override bridge" do
      toggle = UI::Toggle.new("Hardware mode", true)
      toggle.appearance = UI::ToggleAppearance::Rocker
      toggle.on_color = UI::ColorRole::BrandPrimary

      overrides = LibSwiftKitBridge.apsk_toggle_overrides_new
      sender = UI::Native::SwiftKitObjCSender.new(overrides)
      UI::Native::Populator.populate_toggle(overrides.address.to_s(16), toggle, sender)

      getter = SurfaceCraftObjCRuntime.sel_registerName("surfaceCraftToggleSpec".to_unsafe)
      spec_object = UI::AppKit::LibObjCBridge.objc_send(overrides, getter)
      utf8_getter = SurfaceCraftObjCRuntime.sel_registerName("UTF8String".to_unsafe)
      spec_value = String.new(SurfaceCraftObjCRuntime.objc_msgSend(spec_object, utf8_getter))
      spec_value.should contain(%("appearance":"rocker"))
      spec_value.should contain("role:brand-primary")
    end

    it "registers font files at process scope and rejects a missing path" do
      UI::FontRegistry.register_bundled_font_file("/missing/surface-craft-font.otf").should be_false
    end
  end
{% end %}
