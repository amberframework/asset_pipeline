module Voyager
  # Voyager — Settings screen.
  #
  # Phase 8D.1: migrated to `UI::Screen` subclass. Hide-completed toggle
  # dispatches `:toggle_filter` (SettingsController flips
  # `Voyager.state.hide_completed` and returns Rerender). Back link
  # dispatches `:back` (Pop).
  class SettingsScreen < UI::Screen
    SLUG = "voyager-settings"

    def build(context : UI::ScreenContext) : UI::View
      metrics = UI::DesignTokens::DeviceMetrics.current
      content_width = metrics.compact_horizontal? ? 340.0 : 480.0

      state = Voyager.state

      root = UI::VStack.new(spacing: 16.0)
      root.root_fill = true
      root.alignment = UI::Alignment::Leading
      root.padding = UI::EdgeInsets.new(
        top: 24.0 + metrics.safe_area_top_pt,
        trailing: 20.0 + metrics.safe_area_trailing_pt,
        bottom: 24.0 + metrics.safe_area_bottom_pt,
        leading: 20.0 + metrics.safe_area_leading_pt,
      )
      root.accessibility_label = "Voyager settings screen"
      root.test_id = "voyager-settings-root"

      title = UI::Label.new("Settings")
      title.font = UI::Font.new(size: 28.0, weight: :bold)
      title.text_color_role = UI::LabelRole::Primary

      explainer = UI::Label.new("Hide completed todos from the main list.")
      explainer.font = UI::Font.new(size: 14.0, weight: :regular)
      explainer.text_color_role = UI::LabelRole::Secondary

      hide_toggle = UI::Toggle.new(label: "Hide completed", is_on: state.hide_completed)
      hide_toggle.accessibility_label = "Hide completed todos"
      hide_toggle.test_id = "voyager-settings-hide-completed"
      hide_toggle.minimum_width = content_width
      hide_toggle.maximum_width = content_width
      # Phase 8D.1 — :toggle_filter routes to SettingsController#toggle_filter
      # which flips Voyager.state.hide_completed and returns Rerender.
      hide_toggle.on_change = ->(_value : Bool) { Voyager.dispatch(:toggle_filter) }

      back = UI::Button.new("Back to todos")
      back.role = :secondary
      back.accessibility_label = "Back to todos"
      back.test_id = "voyager-settings-back"
      back.minimum_width = content_width
      back.maximum_width = content_width
      back.on_tap = -> { Voyager.dispatch(:back) }

      root << title.as(UI::View)
      root << explainer.as(UI::View)
      root << hide_toggle.as(UI::View)
      root << back.as(UI::View)

      root.as(UI::View)
    end
  end
end
