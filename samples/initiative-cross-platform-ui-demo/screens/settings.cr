module InitiativeDemo
  # demo-settings — toggles, picker, segmented control, slider, color
  # picker, button row. Exercises every reactive widget Phase 3 R4 + R10
  # shipped — value flows through the existing reactive bridge.
  module SettingsScreen
    extend self

    SLUG = "demo-settings"

    def build(state : InitiativeDemo::State) : UI::View
      root = UI::VStack.new(spacing: 20.0)
      root.alignment = UI::Alignment::Leading
      root.padding = UI::EdgeInsets.new(top: 20.0, trailing: 24.0, bottom: 24.0, leading: 24.0)
      root.minimum_width = 320.0
      root.maximum_width = 600.0
      root.accessibility_label = "Settings screen"
      root.test_id = "demo-settings-root"

      header = UI::Label.new("Settings")
      header.font = UI::Font.new(size: 28.0, weight: :bold)
      root << header.as(UI::View)

      # Toggle row.
      toggle_row = build_row("Notifications") do
        t = UI::Toggle.new("", state.notifications_enabled) { |v| state.notifications_enabled = v }
        t.accessibility_label = "Notifications toggle"
        t.test_id = "demo-settings-notifications"
        t.as(UI::View)
      end
      root << toggle_row

      # Segmented control row.
      seg_row = build_row("Appearance") do
        seg = UI::SegmentedControl.new(["Auto", "Light", "Dark"], state.dark_mode_preference) do |idx|
          state.dark_mode_preference = idx
        end
        seg.accessibility_label = "Appearance preference"
        seg.test_id = "demo-settings-appearance"
        seg.as(UI::View)
      end
      root << seg_row

      # Picker row.
      pick_row = build_row("Locale") do
        p = UI::Picker.new(["English (US)", "English (UK)", "Spanish", "Japanese"], 0)
        p.style = UI::PickerStyle::Menu
        p.accessibility_label = "Locale picker"
        p.test_id = "demo-settings-locale"
        p.as(UI::View)
      end
      root << pick_row

      # Slider row.
      slide_label = UI::Label.new("Volume")
      slide_label.font = UI::Font.new(size: 15.0, weight: :semibold)
      root << slide_label.as(UI::View)
      s = UI::Slider.new(0.0, 1.0, state.volume)
      s.on_change = ->(v : Float64) { state.volume = v }
      s.accessibility_label = "Volume slider"
      s.test_id = "demo-settings-volume"
      root << s.as(UI::View)

      # Color picker row.
      cp_row = build_row("Accent color") do
        cp = UI::ColorPicker.new
        cp.selected_color = UI::Color.new(r: 0.30, g: 0.55, b: 0.62)
        cp.accessibility_label = "Accent color picker"
        cp.test_id = "demo-settings-accent-color"
        cp.as(UI::View)
      end
      root << cp_row

      # Button row.
      action_row = UI::HStack.new(spacing: 12.0)
      action_row.alignment = UI::Alignment::Center
      save = UI::Button.new("Save changes")
      save.role = :primary
      save.accessibility_label = "Save changes"
      save.test_id = "demo-settings-save"
      cancel = UI::Button.new("Cancel")
      cancel.role = :secondary
      cancel.accessibility_label = "Cancel changes"
      cancel.test_id = "demo-settings-cancel"
      action_row << save.as(UI::View)
      action_row << cancel.as(UI::View)
      root << action_row.as(UI::View)

      root.as(UI::View)
    end

    private def build_row(label_text : String, &control_block : -> UI::View) : UI::View
      h = UI::HStack.new(spacing: 12.0)
      h.alignment = UI::Alignment::Center
      label = UI::Label.new(label_text)
      label.font = UI::Font.new(size: 15.0, weight: :semibold)
      h << label.as(UI::View)
      h << UI::Spacer.new.as(UI::View)
      h << control_block.call
      h.as(UI::View)
    end
  end
end
