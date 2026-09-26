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
    fun ap_spec_appkit_view_layer_translation_y(view : Void*) : Float64
    fun ap_spec_appkit_view_layer_shadow_opacity(view : Void*) : Float32
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
