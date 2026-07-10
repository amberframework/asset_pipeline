# Auxiliary panel surface (title + optional subtitle + content + footer) used
# for inspector / settings / details affordances. Conservative shared primitive
# pending true floating-panel platform bridges.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  enum PanelStyle
    Standard
    Inspector
    Compact
  end

  # An auxiliary panel surface for inspector-style tools, settings, or details.
  #
  # This shared primitive is intentionally conservative: a clear title block,
  # optional secondary text, primary content, and an optional footer/action
  # area. Platform renderers can add true floating-panel bridges later while
  # the shard already has an honest in-app expression of the concept.
  class Panel < View
    property title : String
    property subtitle : String? = nil
    property auxiliary_text : String? = nil
    property content : View? = nil
    property footer : View? = nil
    property actions : Array(Button) = [] of Button
    property preferred_width : Float64 = 320.0
    property body_spacing : Float64 = 14.0
    property action_spacing : Float64 = 8.0
    property style : PanelStyle = PanelStyle::Inspector
    property shows_separators : Bool = true

    def initialize(
      @title : String,
      @content : View? = nil,
      @subtitle : String? = nil,
      @auxiliary_text : String? = nil,
      @footer : View? = nil,
      @style : PanelStyle = PanelStyle::Inspector
    )
    end

    def add_action(action : Button) : self
      @actions << action
      self
    end

    def action_count : Int32
      @actions.size.to_i32
    end

    def fallback_view : View
      body = UI::VStack.new(spacing: body_spacing, alignment: UI::Alignment::Fill)
      body << build_header.as(UI::View)

      if content = @content
        body << build_separator.as(UI::View) if shows_separators
        body << content
      end

      if footer_area = build_footer_area
        body << build_separator.as(UI::View) if shows_separators
        body << footer_area
      end

      card = UI::Card.new(body.as(UI::View))
      card.material = style == UI::PanelStyle::Inspector ? :tertiary : :secondary
      card.content_padding = content_padding_for_style
      copy_common_properties(card)
      card.minimum_width = minimum_width || preferred_panel_width
      card.maximum_width = maximum_width || preferred_panel_width
      card.as(UI::View)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    private def build_header : UI::View
      header = UI::VStack.new(spacing: header_spacing, alignment: UI::Alignment::Fill)

      title_label = UI::Label.new(title)
      title_label.font = UI::Font.new(size: title_font_size, weight: :semibold)
      title_label.number_of_lines = 0
      header << title_label.as(UI::View)

      if subtitle = @subtitle
        subtitle_label = UI::Label.new(subtitle)
        subtitle_label.font = UI::Font.new(size: subtitle_font_size, weight: :regular)
        subtitle_label.text_color_role = UI::LabelRole::Secondary
        subtitle_label.number_of_lines = 0
        header << subtitle_label.as(UI::View)
      end

      if auxiliary_text = @auxiliary_text
        auxiliary_label = UI::Label.new(auxiliary_text)
        auxiliary_label.font = UI::Font.new(size: 11.0, weight: :regular)
        auxiliary_label.text_color_role = UI::LabelRole::Tertiary
        auxiliary_label.number_of_lines = 0
        header << auxiliary_label.as(UI::View)
      end

      header.as(UI::View)
    end

    private def build_footer_area : UI::View?
      return nil unless @footer || !@actions.empty?

      footer_stack = UI::VStack.new(spacing: 10.0, alignment: UI::Alignment::Fill)
      footer_stack << @footer.not_nil! if @footer

      unless @actions.empty?
        actions_row = UI::HStack.new(spacing: action_spacing, alignment: UI::Alignment::Center)
        actions_row << UI::Spacer.new.as(UI::View)
        @actions.each do |action|
          actions_row << action.as(UI::View)
        end
        footer_stack << actions_row.as(UI::View)
      end

      footer_stack.as(UI::View)
    end

    private def build_separator : UI::Divider
      divider = UI::Divider.new(:horizontal)
      divider.color = UI::Color.new(r: 0.84, g: 0.84, b: 0.86)
      divider
    end

    private def preferred_panel_width : Float64
      return preferred_width if preferred_width > 0.0
      return minimum_width.not_nil! if minimum_width
      return maximum_width.not_nil! if maximum_width
      320.0
    end

    private def header_spacing : Float64
      case style
      when UI::PanelStyle::Compact
        2.0
      when UI::PanelStyle::Inspector
        4.0
      else
        6.0
      end
    end

    private def title_font_size : Float64
      case style
      when UI::PanelStyle::Compact
        12.0
      when UI::PanelStyle::Inspector
        13.0
      else
        15.0
      end
    end

    private def subtitle_font_size : Float64
      case style
      when UI::PanelStyle::Compact
        11.0
      else
        12.0
      end
    end

    private def content_padding_for_style : UI::EdgeInsets
      case style
      when UI::PanelStyle::Compact
        UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0)
      when UI::PanelStyle::Inspector
        UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
      else
        UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      end
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
