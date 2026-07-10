module InitiativeDemo
  # demo-detail — triggered from card or list item. Hero image
  # (placeholder), title, description, action buttons. Covers
  # navigation push/pop, image scaling, multi-column wide-viewport
  # layout (HStack on wide, VStack on mobile is platform default
  # behavior for the renderers).
  module DetailScreen
    extend self

    SLUG = "demo-detail"

    def build(state : InitiativeDemo::State) : UI::View
      root = UI::VStack.new(spacing: 16.0)
      root.alignment = UI::Alignment::Leading
      root.padding = UI::EdgeInsets.new(top: 20.0, trailing: 24.0, bottom: 24.0, leading: 24.0)
      root.minimum_width = 320.0
      root.maximum_width = 720.0
      root.accessibility_label = "Detail screen"
      root.test_id = "demo-detail-root"

      hero = UI::Image.new("photo.fill.on.rectangle.fill")
      hero.content_mode = UI::ContentMode::Fit
      hero.minimum_height = 200.0
      hero.minimum_width = 320.0
      hero.tint_color = UI::Color.new(r: 0.30, g: 0.55, b: 0.62)
      hero.accessibility_label = "Hero placeholder image"
      hero.test_id = "demo-detail-hero"
      root << hero.as(UI::View)

      title = UI::Label.new("Coastal trail")
      title.font = UI::Font.new(size: 28.0, weight: :bold)
      title.accessibility_label = "Item title"
      root << title.as(UI::View)

      subtitle = UI::Label.new("Big Sur, California")
      subtitle.font = UI::Font.new(size: 15.0, weight: :regular)
      subtitle.text_color_role = UI::LabelRole::Secondary
      root << subtitle.as(UI::View)

      body = UI::Label.new(
        "A 9.4-mile out-and-back trail with views of the Pacific. Best in late spring " \
        "when the wildflowers are blooming. Bring water — there is no resupply on the " \
        "trail. Pack out everything you pack in."
      )
      body.font = UI::Font.new(size: 15.0, weight: :regular)
      body.text_color_role = UI::LabelRole::Primary
      body.maximum_width = 640.0
      root << body.as(UI::View)

      # Action row.
      actions = UI::HStack.new(spacing: 12.0)
      actions.alignment = UI::Alignment::Center

      primary = UI::Button.new("Start route")
      primary.role = :primary
      primary.accessibility_label = "Start the route"
      primary.test_id = "demo-detail-start"

      secondary = UI::Button.new("Save")
      secondary.role = :secondary
      secondary.accessibility_label = "Save this route"
      secondary.test_id = "demo-detail-save"

      tertiary = UI::Button.new("Share")
      tertiary.role = :secondary
      tertiary.accessibility_label = "Share this route"
      tertiary.test_id = "demo-detail-share"

      actions << primary.as(UI::View)
      actions << secondary.as(UI::View)
      actions << tertiary.as(UI::View)
      root << actions.as(UI::View)

      root.as(UI::View)
    end
  end
end
