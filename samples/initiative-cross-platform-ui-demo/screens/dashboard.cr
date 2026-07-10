module InitiativeDemo
  # demo-dashboard — TabView with 3 tabs:
  #   Tab 1: card grid of items
  #   Tab 2: list with section headers
  #   Tab 3: profile / settings entry point
  module DashboardScreen
    extend self

    SLUG = "demo-dashboard"

    def build(state : InitiativeDemo::State) : UI::View
      tabs = [
        UI::TabView::Tab.new(label: "Discover", icon: "sparkles", content: build_discover_tab),
        UI::TabView::Tab.new(label: "Library", icon: "books.vertical", content: build_library_tab),
        UI::TabView::Tab.new(label: "Profile", icon: "person.crop.circle", content: build_profile_tab),
      ]

      tv = UI::TabView.new(tabs, state.selected_tab)
      tv.bar_position = :bottom
      tv.glass_bar = true
      tv.on_change = ->(idx : Int32) { state.selected_tab = idx }
      tv.accessibility_label = "Dashboard tab view"
      tv.test_id = "demo-dashboard-root"
      tv.as(UI::View)
    end

    # Tab 1: card grid (4 cards in 2×2).
    private def build_discover_tab : UI::View
      content = UI::VStack.new(spacing: 16.0)
      content.alignment = UI::Alignment::Leading
      content.padding = UI::EdgeInsets.new(top: 20.0, trailing: 20.0, bottom: 20.0, leading: 20.0)
      content.accessibility_label = "Discover tab content"

      header = UI::Label.new("Discover")
      header.font = UI::Font.new(size: 28.0, weight: :bold)
      header.accessibility_label = "Discover heading"
      content << header.as(UI::View)

      # Card grid — 2 rows of 2 HStack cards each.
      [
        [{title: "Nature", body: "Mountain trails"}, {title: "Coffee", body: "Local roasters"}],
        [{title: "Reading", body: "Recent picks"}, {title: "Music", body: "New releases"}],
      ].each do |row|
        h = UI::HStack.new(spacing: 12.0)
        h.alignment = UI::Alignment::Top
        row.each do |item|
          h << build_card(item[:title], item[:body])
        end
        content << h.as(UI::View)
      end

      content.as(UI::View)
    end

    private def build_card(title : String, body : String) : UI::View
      vs = UI::VStack.new(spacing: 8.0)
      vs.alignment = UI::Alignment::Leading
      title_label = UI::Label.new(title)
      title_label.font = UI::Font.new(size: 17.0, weight: :semibold)
      body_label = UI::Label.new(body)
      body_label.font = UI::Font.new(size: 13.0, weight: :regular)
      body_label.text_color_role = UI::LabelRole::Secondary
      vs << title_label.as(UI::View)
      vs << body_label.as(UI::View)

      card = UI::Card.new(vs.as(UI::View))
      card.title = nil
      card.minimum_width = 160.0
      card.maximum_width = 240.0
      card.elevation = 1.0
      card.accessibility_label = "Card: #{title}"
      card.test_id = "demo-dashboard-card-#{title.downcase}"
      card.as(UI::View)
    end

    # Tab 2: list with section headers.
    private def build_library_tab : UI::View
      content = UI::VStack.new(spacing: 16.0)
      content.alignment = UI::Alignment::Leading
      content.padding = UI::EdgeInsets.new(top: 20.0, trailing: 20.0, bottom: 20.0, leading: 20.0)
      content.accessibility_label = "Library tab content"

      header = UI::Label.new("Library")
      header.font = UI::Font.new(size: 28.0, weight: :bold)
      content << header.as(UI::View)

      [
        {section: "Recent", items: ["Notes 2026", "Sketch pad", "Reading list"]},
        {section: "Archived", items: ["Trip — Big Sur", "Tax docs 2025"]},
      ].each do |group|
        sect = UI::Label.new(group[:section].as(String))
        sect.font = UI::Font.new(size: 13.0, weight: :semibold)
        sect.text_color_role = UI::LabelRole::Secondary
        content << sect.as(UI::View)
        group[:items].as(Array(String)).each do |item|
          row_text = UI::Label.new(item)
          row_text.font = UI::Font.new(size: 15.0, weight: :regular)
          content << row_text.as(UI::View)
          content << UI::Divider.new(:horizontal).as(UI::View)
        end
      end

      content.as(UI::View)
    end

    # Tab 3: profile / settings entry point.
    private def build_profile_tab : UI::View
      content = UI::VStack.new(spacing: 16.0)
      content.alignment = UI::Alignment::Center
      content.padding = UI::EdgeInsets.new(top: 32.0, trailing: 24.0, bottom: 32.0, leading: 24.0)
      content.accessibility_label = "Profile tab content"

      avatar = UI::Image.new("person.crop.circle.fill")
      avatar.content_mode = UI::ContentMode::Fit
      avatar.minimum_width = 96.0
      avatar.minimum_height = 96.0
      content << avatar.as(UI::View)

      name = UI::Label.new("Jordan Rivera")
      name.font = UI::Font.new(size: 22.0, weight: :semibold)
      content << name.as(UI::View)

      sub = UI::Label.new("jordan@example.com")
      sub.font = UI::Font.new(size: 13.0, weight: :regular)
      sub.text_color_role = UI::LabelRole::Secondary
      content << sub.as(UI::View)

      open_settings = UI::Button.new("Open settings")
      open_settings.role = :primary
      open_settings.accessibility_label = "Open settings screen"
      open_settings.test_id = "demo-dashboard-open-settings"
      content << open_settings.as(UI::View)

      open_tier3 = UI::Button.new("Show tier-3 demos")
      open_tier3.role = :secondary
      open_tier3.accessibility_label = "Show platform-only widgets"
      open_tier3.test_id = "demo-dashboard-open-tier3"
      content << open_tier3.as(UI::View)

      content.as(UI::View)
    end
  end
end
