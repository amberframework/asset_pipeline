# Drop-target image well control for accepting an image via drag-and-drop or click.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A bordered image drop-target surface with optional labeling.
  #
  # The shared model stays deliberately conservative: a preview image source
  # or placeholder icon, lightweight descriptive text, and a composed fallback
  # surface that can be rendered consistently before native image-well bridges
  # exist on each platform.
  class ImageWell < View
    property image_source : String? = nil
    property placeholder_icon : String = "photo"
    property label : String? = nil
    property prompt : String? = nil
    property caption : String? = nil
    property help_text : String? = nil
    property well_width : Float64 = 240.0
    property well_height : Float64 = 180.0
    property preview_padding : EdgeInsets = EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
    property viewport_width : Float64 = 0.0
    property viewport_height : Float64 = 0.0

    def initialize(
      @image_source : String? = nil,
      @label : String? = nil,
      @prompt : String? = nil,
      @caption : String? = nil,
      @help_text : String? = nil
    )
    end

    def has_image? : Bool
      !@image_source.nil? && !@image_source.not_nil!.empty?
    end

    def fallback_view : View
      body = UI::VStack.new(spacing: 8.0, alignment: UI::Alignment::Fill)

      if label = @label
        label_view = UI::Label.new(label)
        label_view.font = UI::Font.new(size: 13.0, weight: :semibold)
        body << label_view.as(UI::View)
      end

      if prompt = @prompt
        prompt_view = UI::Label.new(prompt)
        prompt_view.font = UI::Font.new(size: 12.0, weight: :regular)
        prompt_view.text_color_role = UI::LabelRole::Secondary
        body << prompt_view.as(UI::View)
      end

      well = UI::VStack.new(spacing: 0.0, alignment: UI::Alignment::Center)
      well << build_preview_content.as(UI::View)
      well.corner_radius = 16.0
      well.padding = preview_padding
      well.background = UI::Color.new(r: 0.97, g: 0.97, b: 0.98)
      well.border_width = 1.0
      well.border_color = UI::Color.new(r: 0.79, g: 0.80, b: 0.82)
      well.minimum_width = well_width
      well.maximum_width = well_width
      well.minimum_height = well_height
      well.maximum_height = well_height
      body << well.as(UI::View)

      if caption = @caption
        caption_view = UI::Label.new(caption)
        caption_view.font = UI::Font.new(size: 12.0, weight: :regular)
        caption_view.number_of_lines = 0
        body << caption_view.as(UI::View)
      end

      if help_text = @help_text
        help_view = UI::Label.new(help_text)
        help_view.font = UI::Font.new(size: 11.0, weight: :regular)
        help_view.text_color_role = UI::LabelRole::Secondary
        help_view.number_of_lines = 0
        body << help_view.as(UI::View)
      end

      card = UI::Card.new(body.as(UI::View))
      card.material = :secondary
      card.content_padding = EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
      card.minimum_width = minimum_width if minimum_width
      card.minimum_height = minimum_height if minimum_height
      card.maximum_width = maximum_width if maximum_width
      card.maximum_height = maximum_height if maximum_height
      copy_common_properties(card)
      card.as(UI::View)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    private def build_preview_content : UI::View
      stack = UI::VStack.new(spacing: 10.0, alignment: UI::Alignment::Center)

      if image_source = @image_source
        image = UI::Image.new(image_source)
        image.content_mode = UI::ContentMode::Fit
        image.minimum_width = well_width - 48.0
        image.maximum_width = well_width - 48.0
        image.minimum_height = well_height - 48.0
        image.maximum_height = well_height - 48.0
        stack << image.as(UI::View)
      else
        placeholder = UI::Image.new(placeholder_icon)
        placeholder.content_mode = UI::ContentMode::Fit
        placeholder.minimum_width = 44.0
        placeholder.maximum_width = 44.0
        placeholder.minimum_height = 44.0
        placeholder.maximum_height = 44.0
        placeholder.opacity = 0.70
        stack << placeholder.as(UI::View)
      end

      stack.as(UI::View)
    end

    private def copy_common_properties(target : UI::View) : Nil
      target.id = id
      target.accessibility_label = accessibility_label
      target.padding = padding
      target.background = background
      target.hidden = hidden
      target.opacity = opacity
      target.corner_radius = corner_radius
      target.clip_to_bounds = clip_to_bounds
      target.shadow_radius = shadow_radius
      target.shadow_color = shadow_color
      target.shadow_offset_x = shadow_offset_x
      target.shadow_offset_y = shadow_offset_y
      target.border_width = border_width
      target.border_color = border_color
      target.blur_radius = blur_radius
      target.minimum_width = minimum_width
      target.minimum_height = minimum_height
      target.maximum_width = maximum_width
      target.maximum_height = maximum_height
      target.test_id = test_id
    end
  end
end
