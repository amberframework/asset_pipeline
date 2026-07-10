# Multi-value tokenized text field (e.g. recipient field in a mail app).
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A pill-style token entry field with optional labeling.
  #
  # The shared primitive keeps the data model renderer-agnostic for now:
  # nested tokens, selected-token state, placeholder text, and a composed
  # fallback surface built from existing UI views. Native token-field bridges
  # can be added later without changing the shared API.
  class TokenField < View
    class Token
      property title : String
      property icon : String?
      property secondary_text : String?

      def initialize(
        @title : String,
        @icon : String? = nil,
        @secondary_text : String? = nil
      )
      end

      def branch? : Bool
        false
      end
    end

    property tokens : Array(Token) = [] of Token
    property selected_indexes : Array(Int32) = [] of Int32
    property placeholder : String = ""
    property label : String? = nil
    property prompt : String? = nil
    property chip_spacing : Float64 = 8.0
    property row_spacing : Float64 = 8.0
    property chip_padding : EdgeInsets = EdgeInsets.new(top: 6.0, trailing: 10.0, bottom: 6.0, leading: 10.0)
    property input_min_width : Float64 = 120.0
    property input_max_width : Float64 = 220.0
    property viewport_width : Float64 = 0.0
    property viewport_height : Float64 = 56.0

    def initialize(
      @tokens : Array(Token) = [] of Token,
      @placeholder : String = "",
      @label : String? = nil,
      @prompt : String? = nil
    )
    end

    def add_token(token : Token) : self
      @tokens << token
      self
    end

    def token_count : Int32
      @tokens.size.to_i32
    end

    def selected_tokens : Array(Token)
      @selected_indexes.compact_map do |index|
        @tokens[index]?
      end
    end

    def fallback_view : View
      card_body = UI::VStack.new(spacing: row_spacing, alignment: UI::Alignment::Fill)

      if label = @label
        label_view = UI::Label.new(label)
        label_view.font = UI::Font.new(size: 13.0, weight: :semibold)
        card_body << label_view.as(UI::View)
      end

      if prompt = @prompt
        prompt_view = UI::Label.new(prompt)
        prompt_view.font = UI::Font.new(size: 12.0, weight: :regular)
        prompt_view.text_color_role = nil
        prompt_view.text_color = UI::Color.new(r: 0.50, g: 0.50, b: 0.50)
        card_body << prompt_view.as(UI::View)
      end

      tray = UI::HStack.new(spacing: chip_spacing, alignment: UI::Alignment::Center)
      if (width = preferred_frame_width) > 0.0
        tray.minimum_width = width
        tray.maximum_width = width
      end
      height = preferred_frame_height
      tray.minimum_height = height
      tray.maximum_height = height
      tokens.each_with_index do |token, index|
        tray << build_token_chip(token, index).as(UI::View)
      end

      entry = UI::TextField.new(placeholder)
      entry.font = UI::Font.new(size: 13.0, weight: :regular)
      entry.minimum_width = input_min_width
      entry.maximum_width = input_max_width
      tray << entry.as(UI::View)

      card_body << tray.as(UI::View)

      card = UI::Card.new(card_body.as(UI::View))
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

    private def build_token_chip(token : Token, index : Int32) : UI::View
      selected = @selected_indexes.includes?(index)

      chip_content = UI::HStack.new(spacing: 6.0, alignment: UI::Alignment::Center)

      if icon = token.icon
        icon_view = UI::Image.new(icon)
        icon_view.minimum_width = 14.0
        icon_view.maximum_width = 14.0
        icon_view.minimum_height = 14.0
        icon_view.maximum_height = 14.0
        icon_view.opacity = selected ? 0.92 : 0.80
        chip_content << icon_view.as(UI::View)
      end

      title = UI::Label.new(token.title)
      title.font = UI::Font.new(size: 13.0, weight: selected ? :semibold : :regular)
      title.text_color_role = nil
      title.text_color = selected ? UI::Color.new(r: 0.18, g: 0.30, b: 0.56) : UI::Color.new(r: 0.18, g: 0.18, b: 0.18)
      chip_content << title.as(UI::View)

      if secondary_text = token.secondary_text
        secondary = UI::Label.new(secondary_text)
        secondary.font = UI::Font.new(size: 12.0, weight: :regular)
        secondary.text_color_role = nil
        secondary.text_color = selected ? UI::Color.new(r: 0.24, g: 0.34, b: 0.58) : UI::Color.new(r: 0.48, g: 0.48, b: 0.48)
        chip_content << secondary.as(UI::View)
      end

      chip_content.padding = chip_padding
      chip_content.corner_radius = 14.0
      chip_content.background = selected ? UI::Color.new(r: 0.28, g: 0.46, b: 0.84, a: 0.18) : UI::Color.new(r: 0.95, g: 0.95, b: 0.96)
      chip_content.border_width = 1.0
      chip_content.border_color = selected ? UI::Color.new(r: 0.28, g: 0.46, b: 0.84, a: 0.30) : UI::Color.new(r: 0.80, g: 0.80, b: 0.82)
      chip_content.as(UI::View)
    end

    private def preferred_frame_width : Float64
      return viewport_width if viewport_width > 0.0
      return minimum_width.not_nil! if minimum_width
      return maximum_width.not_nil! if maximum_width
      0.0
    end

    private def preferred_frame_height : Float64
      return viewport_height if viewport_height > 0.0
      return minimum_height.not_nil! if minimum_height
      return maximum_height.not_nil! if maximum_height
      56.0
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
