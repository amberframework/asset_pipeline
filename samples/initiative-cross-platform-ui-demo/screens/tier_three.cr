module InitiativeDemo
  # demo-tier-three — explicitly uses platform-only widgets via the
  # *WithWebFallback variants. Demonstrates the Phase 4 degradation
  # contract: on iOS/macOS these resolve to native chrome (action
  # sheet, context menu, path control); on web they resolve to the
  # documented HTML fallback.
  #
  # HapticFeedback is out of scope per Phase 4 deferral.
  module TierThreeScreen
    extend self

    SLUG = "demo-tier-three"

    def build(state : InitiativeDemo::State) : UI::View
      root = UI::VStack.new(spacing: 20.0)
      root.alignment = UI::Alignment::Leading
      root.padding = UI::EdgeInsets.new(top: 20.0, trailing: 24.0, bottom: 24.0, leading: 24.0)
      root.minimum_width = 320.0
      root.maximum_width = 640.0
      root.accessibility_label = "Tier-3 platform-only widgets demo"
      root.test_id = "demo-tier-three-root"

      header = UI::Label.new("Platform-only widgets")
      header.font = UI::Font.new(size: 28.0, weight: :bold)
      root << header.as(UI::View)

      blurb = UI::Label.new(
        "These widgets are platform-only on Apple targets and degrade to " \
        "documented HTML fallbacks on the web. Each row demonstrates one " \
        "*WithWebFallback class from Phase 4.")
      blurb.font = UI::Font.new(size: 13.0, weight: :regular)
      blurb.text_color_role = UI::LabelRole::Secondary
      blurb.maximum_width = 600.0
      root << blurb.as(UI::View)

      root << action_sheet_row(state)
      root << context_menu_row
      root << path_control_row

      root.as(UI::View)
    end

    private def action_sheet_row(state : InitiativeDemo::State) : UI::View
      h = UI::HStack.new(spacing: 12.0)
      label = UI::Label.new("ActionSheet")
      label.font = UI::Font.new(size: 15.0, weight: :semibold)
      h << label.as(UI::View)
      h << UI::Spacer.new.as(UI::View)

      sheet = UI::ActionSheetWithWebFallback.new(
        title: "Delete draft?",
        message: "This cannot be undone.",
      )
      sheet.add_action("Delete forever", :destructive)
      sheet.add_action("Archive", :default)
      sheet.add_action("Cancel", :cancel)
      sheet.accessibility_label = "Action sheet: delete draft"
      sheet.test_id = "demo-tier-three-action-sheet"

      btn = UI::Button.new("Show action sheet")
      btn.role = :secondary
      btn.accessibility_label = "Show action sheet"
      btn.test_id = "demo-tier-three-action-sheet-trigger"
      h << btn.as(UI::View)

      row = UI::VStack.new(spacing: 8.0)
      row.alignment = UI::Alignment::Leading
      row << h.as(UI::View)
      row << sheet.as(UI::View)
      row.as(UI::View)
    end

    private def context_menu_row : UI::View
      h = UI::HStack.new(spacing: 12.0)
      label = UI::Label.new("ContextMenu")
      label.font = UI::Font.new(size: 15.0, weight: :semibold)
      h << label.as(UI::View)
      h << UI::Spacer.new.as(UI::View)

      cm = UI::ContextMenuWithWebFallback.new
      cm.add_item("Rename")
      cm.add_item("Duplicate")
      cm.add_item("Delete", is_destructive: true)
      cm.accessibility_label = "Context menu: item actions"
      cm.test_id = "demo-tier-three-context-menu"

      btn = UI::Button.new("Right-click target")
      btn.role = :secondary
      btn.accessibility_label = "Open context menu (right-click)"
      btn.test_id = "demo-tier-three-context-menu-trigger"
      h << btn.as(UI::View)

      row = UI::VStack.new(spacing: 8.0)
      row.alignment = UI::Alignment::Leading
      row << h.as(UI::View)
      row << cm.as(UI::View)
      row.as(UI::View)
    end

    private def path_control_row : UI::View
      h = UI::HStack.new(spacing: 12.0)
      label = UI::Label.new("PathControl")
      label.font = UI::Font.new(size: 15.0, weight: :semibold)
      h << label.as(UI::View)
      h << UI::Spacer.new.as(UI::View)

      pc_components = ["Home", "Documents", "Projects", "Demo"].map do |name|
        UI::PathControlWithWebFallback::Component.new(name: name)
      end
      pc = UI::PathControlWithWebFallback.new(components: pc_components)
      pc.accessibility_label = "Path control: file location"
      pc.test_id = "demo-tier-three-path-control"
      h << pc.as(UI::View)

      h.as(UI::View)
    end
  end
end
