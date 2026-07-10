require "../../../scripts/crystal_init"
require "../../../src/ui"

module AndroidMaterialHost
  module Bridge
    @@runtime_initialized = false
    @@last_native : UI::NativeView? = nil
    @@interaction_fired : Bool? = nil
    @@interaction_toggle_on : Bool? = nil
    @@interaction_checkbox_checked : Bool? = nil
    @@interaction_slider_value : Float64? = nil
    @@interaction_radio_index : Int32? = nil
    @@interaction_text_value : String? = nil
    @@selection_menu_index : Int32? = nil
    @@selection_segment_index : Int32? = nil
    @@selection_inline_index : Int32? = nil
    @@selection_stepper_value : Float64? = nil
    @@selection_search_value : String? = nil
    @@surface_note_value : String? = nil
    @@palette_color_value : UI::Color? = nil
    @@activity_note_value : String? = nil

    def self.initialize_runtime : Nil
      return if @@runtime_initialized
      crystal_init
      @@runtime_initialized = true
    end

    def self.record_interaction_fire : Nil
      self.interaction_fired_state = true
    end

    def self.interaction_note : String
      interaction_fired_state ? "Button callback reached." : "No Android callback has fired yet."
    end

    def self.set_interaction_toggle(value : Bool) : Nil
      self.interaction_toggle_state = value
    end

    def self.set_interaction_checkbox(value : Bool) : Nil
      self.interaction_checkbox_state = value
    end

    def self.set_interaction_slider(value : Float64) : Nil
      self.interaction_slider_state = value
    end

    def self.set_interaction_radio(index : Int32) : Nil
      self.interaction_radio_state = index
    end

    def self.set_interaction_text(value : String) : Nil
      self.interaction_text_state = value
    end

    def self.set_selection_menu(index : Int32) : Nil
      self.selection_menu_state = index
    end

    def self.set_selection_segment(index : Int32) : Nil
      self.selection_segment_state = index
    end

    def self.set_selection_inline(index : Int32) : Nil
      self.selection_inline_state = index
    end

    def self.set_selection_stepper(value : Float64) : Nil
      self.selection_stepper_state = value
    end

    def self.set_selection_search(value : String) : Nil
      self.selection_search_state = value
    end

    def self.set_surface_note(value : String) : Nil
      self.surface_note_state = value
    end

    def self.set_palette_color(value : UI::Color) : Nil
      self.palette_color_state = value
    end

    def self.set_activity_note(value : String) : Nil
      self.activity_note_state = value
    end

    private def self.interaction_fired_state
      @@interaction_fired ||= false
    end

    private def self.interaction_fired_state=(value : Bool)
      @@interaction_fired = value
    end

    private def self.interaction_toggle_state
      @@interaction_toggle_on ||= false
    end

    private def self.interaction_toggle_state=(value : Bool)
      @@interaction_toggle_on = value
    end

    private def self.interaction_checkbox_state
      @@interaction_checkbox_checked ||= false
    end

    private def self.interaction_checkbox_state=(value : Bool)
      @@interaction_checkbox_checked = value
    end

    private def self.interaction_slider_state
      @@interaction_slider_value ||= 35.0
    end

    private def self.interaction_slider_state=(value : Float64)
      @@interaction_slider_value = value
    end

    private def self.interaction_radio_state
      @@interaction_radio_index ||= 0
    end

    private def self.interaction_radio_state=(value : Int32)
      @@interaction_radio_index = value
    end

    private def self.interaction_text_state
      @@interaction_text_value ||= "Draft note"
    end

    private def self.interaction_text_state=(value : String)
      @@interaction_text_value = value
    end

    private def self.selection_menu_state
      @@selection_menu_index ||= 1
    end

    private def self.selection_menu_state=(value : Int32)
      @@selection_menu_index = value
    end

    private def self.selection_segment_state
      @@selection_segment_index ||= 0
    end

    private def self.selection_segment_state=(value : Int32)
      @@selection_segment_index = value
    end

    private def self.selection_inline_state
      @@selection_inline_index ||= 1
    end

    private def self.selection_inline_state=(value : Int32)
      @@selection_inline_index = value
    end

    private def self.selection_stepper_state
      @@selection_stepper_value ||= 3.0
    end

    private def self.selection_stepper_state=(value : Float64)
      @@selection_stepper_value = value
    end

    private def self.selection_search_state
      @@selection_search_value ||= "evidence"
    end

    private def self.selection_search_state=(value : String)
      @@selection_search_value = value
    end

    private def self.surface_note_state
      @@surface_note_value ||= "Waiting for a transient-surface callback."
    end

    private def self.surface_note_state=(value : String)
      @@surface_note_value = value
    end

    private def self.palette_color_state
      @@palette_color_value ||= UI::Color.new(r: 0.40, g: 0.31, b: 0.89)
    end

    private def self.palette_color_state=(value : UI::Color)
      @@palette_color_value = value
    end

    private def self.activity_note_state
      @@activity_note_value ||= "No share-sheet action selected yet."
    end

    private def self.activity_note_state=(value : String)
      @@activity_note_value = value
    end

    def self.render_slug(env : Void*, context : Void*, slug : String) : Void*
      initialize_runtime

      # Keep the most recent native tree strongly reachable while the Android
      # host owns the mounted view hierarchy.
      view = build_component(slug)
      renderer = UI::Android::Renderer.new(env, context)
      native = renderer.render(view)
      @@last_native = native
      native.handle.ptr!
    end

    def self.build_component(slug : String) : UI::View
      case slug
      when "buttons"      then build_buttons
      when "text-fields"  then build_text_fields
      when "cards"        then build_cards
      when "dialogs"      then build_dialogs
      when "app-bars"     then build_app_bars
      when "interaction-smoke" then build_interaction_smoke
      when "selection-controls" then build_selection_controls
      when "transient-surfaces" then build_transient_surfaces
      when "share-color" then build_share_color
      when "webview"      then build_webview
      when "map-view"     then build_map_view
      when "video-player" then build_video_player
      when "chart-view"   then build_chart_view
      else
        build_fallback(slug)
      end
    end

    private def self.root_stack : UI::VStack
      stack = UI::VStack.new(16.0, UI::Alignment::Leading)
      stack.test_id = "android-material-study-root"
      stack.accessibility_label = "Android Material study"
      stack.padding = UI::EdgeInsets.new(top: 20.0, trailing: 20.0, bottom: 20.0, leading: 20.0)
      stack.background = UI::Color.new(r: 0.98, g: 0.97, b: 0.99)
      stack.corner_radius = 20.0
      stack
    end

    private def self.heading(text : String) : UI::Label
      label = UI::Label.new(text)
      label.font = UI::Font.new(size: 22.0, weight: :bold)
      label.text_color = UI::Color.new(r: 0.11, g: 0.11, b: 0.15)
      label.text_color_role = nil
      label
    end

    private def self.subheading(text : String) : UI::Label
      label = UI::Label.new(text)
      label.font = UI::Font.new(size: 14.0, weight: :regular)
      label.text_color = UI::Color.new(r: 0.34, g: 0.35, b: 0.4)
      label.text_color_role = nil
      label.number_of_lines = 0
      label
    end

    private def self.body_label(text : String) : UI::Label
      label = UI::Label.new(text)
      label.font = UI::Font.new(size: 15.0, weight: :regular)
      label.text_color = UI::Color.new(r: 0.16, g: 0.16, b: 0.2)
      label.text_color_role = nil
      label.number_of_lines = 0
      label
    end

    private def self.support_card(title : String, detail : String) : UI::Card
      content = UI::VStack.new(10.0, UI::Alignment::Leading)
      content << body_label(detail)

      card = UI::Card.new(content)
      card.title = title
      card.material = :secondary
      card.elevation = 2.0
      card
    end

    private def self.hex_color(color : UI::Color) : String
      r = (color.r * 255.0).round.to_i.clamp(0, 255)
      g = (color.g * 255.0).round.to_i.clamp(0, 255)
      b = (color.b * 255.0).round.to_i.clamp(0, 255)
      "#%02X%02X%02X" % {r, g, b}
    end

    private def self.build_buttons : UI::View
      stack = root_stack
      stack << heading("Material button defaults")
      stack << subheading("Primary, tonal, outlined, and text emphasis rendered through the shared Android renderer.")

      primary_row = UI::HStack.new(12.0, UI::Alignment::Center)
      primary_row << UI::Button.new("Continue", style: UI::ButtonStyle::Prominent)
      primary_row << UI::Button.new("Use sample", style: UI::ButtonStyle::Tinted)
      stack << primary_row

      secondary_row = UI::HStack.new(12.0, UI::Alignment::Center)
      secondary_row << UI::Button.new("Learn more", style: UI::ButtonStyle::Bordered)
      secondary_row << UI::Button.new("Dismiss", role: :cancel, style: UI::ButtonStyle::Borderless)
      stack << secondary_row

      destructive = UI::Button.new("Delete draft", role: :destructive, style: UI::ButtonStyle::Prominent)
      stack << destructive
      stack
    end

    private def self.build_text_fields : UI::View
      stack = root_stack
      stack << heading("Material text fields")
      stack << subheading("Shared token-driven field chrome for common entry surfaces.")

      email = UI::TextField.new("Work email")
      email.text = "alex@amber.dev"
      stack << email

      project = UI::TextField.new("Project name")
      project.text = "Cross-platform launch"
      stack << project

      combo = UI::ComboBox.new(
        value: "Material baseline",
        options: ["Material baseline", "Brand expressive", "High contrast"],
        placeholder: "Select theme mode"
      )
      stack << combo

      stack << support_card("Field guidance", "The Android renderer now applies intentional Material defaults instead of generic boxes.")
      stack
    end

    private def self.build_cards : UI::View
      stack = root_stack
      stack << heading("Material cards")
      stack << subheading("Elevated, outlined, and supporting surfaces rendered with shared defaults.")

      summary_card = support_card("Shipment readiness", "Renderer-backed Android studies are replacing placeholder families first so the validation ledger can graduate honestly.")
      stack << summary_card

      outlined_content = UI::VStack.new(8.0, UI::Alignment::Leading)
      outlined_content << body_label("Outline emphasis for audit-ready secondary groupings.")
      outlined_card = UI::Card.new(outlined_content)
      outlined_card.title = "Outlined status"
      outlined_card.is_outlined = true
      stack << outlined_card

      tertiary_content = UI::VStack.new(8.0, UI::Alignment::Leading)
      tertiary_content << body_label("Supporting detail surfaces can tone down emphasis without collapsing into placeholder chrome.")
      tertiary_card = UI::Card.new(tertiary_content)
      tertiary_card.title = "Tonal surface"
      tertiary_card.material = :tertiary
      tertiary_card.elevation = 1.0
      stack << tertiary_card
      stack
    end

    private def self.build_dialogs : UI::View
      stack = root_stack
      stack << heading("Material dialogs")
      stack << subheading("Inline renderer studies for alert and confirmation flows.")

      alert = UI::Alert.new("Publish this release?", "The screenshot ledger will update after the Android renderer mount contains real output.")
      alert.is_presented = true
      alert.add_button("Review", style: :cancel)
      alert.add_button("Publish", style: :default)
      stack << alert

      confirm = UI::ConfirmationDialog.new("Discard the draft?", "Unsaved Android evidence annotations will be removed.")
      confirm.is_presented = true
      confirm.cancel_label = "Keep editing"
      confirm.confirm_label = "Discard"
      confirm.confirm_style = :destructive
      stack << confirm
      stack
    end

    private def self.build_app_bars : UI::View
      stack = root_stack
      stack << heading("Top app bars")
      stack << subheading("Shared toolbar composition with title and trailing utility actions.")

      main_bar = UI::Toolbar.new("Android validation")
      main_bar.add_item("refresh", "Refresh")
      main_bar.add_item("share", "Share")
      stack << main_bar

      detail_bar = UI::Toolbar.new("Cross-platform story")
      detail_bar.add_item("filter", "Filter")
      detail_bar.add_item("open", "Open")
      stack << detail_bar
      stack
    end

    private def self.build_interaction_smoke : UI::View
      toggle_state_text = interaction_toggle_state ? "on" : "off"
      checkbox_state_text = interaction_checkbox_state ? "checked" : "unchecked"
      slider_state_text = "#{interaction_slider_state.round.to_i}%"
      radio_labels = ["Phone-first", "Balanced", "Tablet-first"]
      radio_state_text = radio_labels[interaction_radio_state]

      stack = root_stack
      stack << heading("Interaction smoke")
      stack << subheading("Internal host-only study for verifying Android button, toggle, slider, radio, and text callback delivery.")

      smoke_button = UI::Button.new("Fire callback", style: UI::ButtonStyle::Prominent) do
        record_interaction_fire
      end
      stack << smoke_button

      note = body_label(interaction_note)
      note.number_of_lines = 0
      stack << note

      toggle = UI::Toggle.new("Send release alerts", interaction_toggle_state) do |value|
        set_interaction_toggle(value)
      end
      stack << toggle
      stack << body_label("Toggle state: " + toggle_state_text)

      checkbox = UI::Checkbox.new("Include tablet captures", interaction_checkbox_state) do |value|
        set_interaction_checkbox(value)
      end
      stack << checkbox
      stack << body_label("Checkbox state: " + checkbox_state_text)

      slider = UI::Slider.new(0.0, 100.0, interaction_slider_state) do |value|
        set_interaction_slider(value)
      end
      slider.label = "Validation confidence"
      stack << slider
      stack << body_label("Slider value: " + slider_state_text)

      radio = UI::RadioGroup.new(["Phone-first", "Balanced", "Tablet-first"], interaction_radio_state) do |index|
        set_interaction_radio(index)
      end
      stack << radio
      stack << body_label("Radio selection: " + radio_state_text)

      field = UI::TextField.new("Validation note") do |value|
        set_interaction_text(value)
      end
      field.text = interaction_text_state
      stack << field
      stack << body_label("Text value: " + interaction_text_state)
      stack
    end

    private def self.build_selection_controls : UI::View
      mode_options = ["Matrix review", "Renderer focus", "Promotion gate"]
      breakpoint_options = ["Phone", "Balanced", "Tablet"]
      section_options = ["Buttons", "Dialogs", "Evidence"]

      stack = root_stack
      stack << heading("Selection controls")
      stack << subheading("Menu, segmented, inline, search, and stepper paths mounted through the shared Android renderer.")

      menu_picker = UI::Picker.new(mode_options, selection_menu_state) do |index|
        set_selection_menu(index)
      end
      menu_picker.label = "Validation mode"
      menu_picker.style = UI::PickerStyle::Menu
      stack << menu_picker
      stack << body_label("Menu picker: #{mode_options[selection_menu_state]}")

      segmented_picker = UI::Picker.new(breakpoint_options, selection_segment_state) do |index|
        set_selection_segment(index)
      end
      segmented_picker.label = "Adaptive breakpoint"
      segmented_picker.style = UI::PickerStyle::Segmented
      stack << segmented_picker
      stack << body_label("Segmented picker: #{breakpoint_options[selection_segment_state]}")

      inline_picker = UI::Picker.new(section_options, selection_inline_state) do |index|
        set_selection_inline(index)
      end
      inline_picker.label = "Priority section"
      inline_picker.style = UI::PickerStyle::Inline
      stack << inline_picker
      stack << body_label("Inline picker: #{section_options[selection_inline_state]}")

      search = UI::SearchField.new("Search studies") do |value|
        set_selection_search(value)
      end
      search.text = selection_search_state
      stack << search
      stack << body_label("Search query: #{selection_search_state}")

      stepper = UI::Stepper.new(0.0, 6.0, selection_stepper_state) do |value|
        set_selection_stepper(value)
      end
      stepper.label = "Promotion count"
      stepper.step_value = 1.0
      stack << stepper
      stack << body_label("Stepper value: #{selection_stepper_state.round.to_i}")
      stack
    end

    private def self.build_transient_surfaces : UI::View
      stack = root_stack
      stack << heading("Transient surfaces")
      stack << subheading("Bottom-sheet, popover, and snackbar surfaces upgraded from placeholder containers to Material-style compositions.")

      sheet_content = UI::VStack.new(10.0, UI::Alignment::Leading)
      sheet_content << body_label("Review the current Android matrix before promoting any study.")
      sheet_content << body_label("Captured evidence stays pending until fidelity and matrix coverage are both clear.")
      sheet = UI::Sheet.new(sheet_content)
      sheet.is_presented = true
      sheet.selected_detent = :medium
      sheet.detents = [:medium, :large]
      sheet.on_dismiss = Proc(Nil).new { set_surface_note("Sheet dismiss callback fired.") }
      stack << sheet

      popover_content = UI::VStack.new(8.0, UI::Alignment::Leading)
      popover_content << body_label("Popover previews can now communicate arrow-edge intent and close actions.")
      popover = UI::Popover.new(popover_content, :bottom)
      popover.is_presented = true
      popover.preferred_width = 280.0
      popover.on_dismiss = Proc(Nil).new { set_surface_note("Popover close callback fired.") }
      stack << popover

      snackbar = UI::Snackbar.new("Renderer-backed Android callbacks are ready for transient surfaces.", "Undo")
      snackbar.is_presented = true
      snackbar.on_action = Proc(Nil).new { set_surface_note("Snackbar action tapped.") }
      stack << snackbar

      stack << body_label("Transient note: #{surface_note_state}")
      stack
    end

    private def self.build_share_color : UI::View
      stack = root_stack
      stack << heading("Share and color")
      stack << subheading("Android-owned share and palette surfaces mounted as renderer-backed showcase studies.")

      picker = UI::ColorPicker.new
      picker.label = "Highlight color"
      picker.selected_color = palette_color_state
      picker.supports_alpha = true
      picker.on_change = Proc(UI::Color, Nil).new do |color|
        set_palette_color(color)
      end
      stack << picker
      stack << body_label("Selected highlight: #{hex_color(palette_color_state)}")

      destinations = [
        UI::ActivityDestination.new("message", "Message", Proc(Nil).new { set_activity_note("Selected Message destination.") }),
        UI::ActivityDestination.new("mail", "Mail", Proc(Nil).new { set_activity_note("Selected Mail destination.") }),
      ]
      actions = [
        UI::ActivityAction.new("bookmark", "Save", Proc(Nil).new { set_activity_note("Save action selected.") }),
        UI::ActivityAction.new("printer", "Print", Proc(Nil).new { set_activity_note("Print action selected.") }),
      ]

      activity = UI::ActivityView.new(
        "Android rollout summary",
        "Share the latest Material validation snapshot with reviewers.",
        nil,
        destinations,
        actions,
        Proc(Nil).new { set_activity_note("Activity view cancel selected.") }
      )
      activity.share_subject = "Android Material status"
      activity.share_text = "Renderer-backed Android studies are expanding beyond the first batch."
      activity.share_url = "https://asset-pipeline.local/android-material"
      activity.is_presented = false
      stack << activity
      stack << body_label("Share note: #{activity_note_state}")
      stack
    end

    private def self.build_webview : UI::View
      stack = root_stack
      stack << heading("Embedded web surface")

      web = UI::WebViewComponent.new
      web.title = "Launch brief"
      web.base_url = "https://asset-pipeline.local/android-material"
      web.html = <<-HTML
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              margin: 0;
              font-family: sans-serif;
              background: #f8f2ff;
              color: #1d192b;
            }
            .shell {
              padding: 20px;
            }
            .eyebrow {
              font-size: 12px;
              letter-spacing: 0.08em;
              text-transform: uppercase;
              color: #6750a4;
            }
            h1 {
              margin: 10px 0 8px;
              font-size: 24px;
            }
            p {
              margin: 0 0 16px;
              line-height: 1.45;
            }
            .grid {
              display: grid;
              grid-template-columns: repeat(2, minmax(0, 1fr));
              gap: 12px;
            }
            .card {
              border-radius: 18px;
              padding: 14px;
              background: white;
              box-shadow: 0 10px 24px rgba(103, 80, 164, 0.12);
            }
            .label {
              font-size: 11px;
              text-transform: uppercase;
              color: #65558f;
            }
            .value {
              margin-top: 6px;
              font-size: 18px;
              font-weight: 700;
            }
          </style>
        </head>
        <body>
          <div class="shell">
            <div class="eyebrow">Android host</div>
            <h1>Renderer-backed web content</h1>
            <p>The shared renderer is now mounting a real Android WebView instead of a placeholder box.</p>
            <div class="grid">
              <div class="card"><div class="label">Mode</div><div class="value">Inline HTML</div></div>
              <div class="card"><div class="label">Phase</div><div class="value">First batch</div></div>
              <div class="card"><div class="label">Goal</div><div class="value">Trustworthy screenshots</div></div>
              <div class="card"><div class="label">Next</div><div class="value">Dark + tablet</div></div>
            </div>
          </div>
        </body>
        </html>
      HTML
      stack << web
      stack
    end

    private def self.build_map_view : UI::View
      stack = root_stack
      stack << heading("Map surface")

      map = UI::MapView.new
      map.latitude = 40.7128
      map.longitude = -74.0060
      map.zoom_level = 11.5
      map.annotations = [
        UI::MapAnnotation.new(latitude: 40.741, longitude: -73.989, title: "Capture site"),
        UI::MapAnnotation.new(latitude: 40.729, longitude: -73.996, title: "Validation lab")
      ]
      map.shows_user_location = true
      stack << map
      stack
    end

    private def self.build_video_player : UI::View
      stack = root_stack
      stack << heading("Video surface")

      video = UI::VideoPlayer.new("https://example.com/demo.mp4")
      video.shows_controls = true
      video.is_playing = false
      video.muted = false
      stack << video
      stack
    end

    private def self.build_chart_view : UI::View
      stack = root_stack
      stack << heading("Chart surface")

      chart = UI::ChartView.new
      chart.title = "Renderer migration status"
      chart.chart_type = :bar
      chart.data_points = [
        UI::ChartDataPoint.new(label: "Buttons", value: 4.0),
        UI::ChartDataPoint.new(label: "Dialogs", value: 3.0),
        UI::ChartDataPoint.new(label: "Media", value: 4.0),
        UI::ChartDataPoint.new(label: "Host", value: 2.0)
      ]
      stack << chart

      trend = UI::ChartView.new
      trend.title = "Evidence maturity"
      trend.chart_type = :line
      trend.data_points = [
        UI::ChartDataPoint.new(label: "Shell", value: 1.0),
        UI::ChartDataPoint.new(label: "Renderer", value: 2.0),
        UI::ChartDataPoint.new(label: "Accepted", value: 3.0)
      ]
      trend.show_legend = false
      stack << trend
      stack
    end

    private def self.build_fallback(slug : String) : UI::View
      stack = root_stack
      stack << heading("Unknown study")
      stack << body_label("No Android Material study is registered for '#{slug}'.")
      stack
    end
  end
end

fun crystal_android_host_render_slug(env : Void*, context : Void*, slug_ptr : UInt8*) : Void*
  slug = slug_ptr.null? ? "buttons" : String.new(slug_ptr)
  AndroidMaterialHost::Bridge.render_slug(env, context, slug)
end
