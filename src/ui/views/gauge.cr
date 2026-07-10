# Bounded value indicator showing progress along a fixed range.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A circular gauge rendered as a shared fallback surface.
  #
  # The primitive intentionally stays conservative: a determinate value range,
  # an optional label/prompt/caption/help block, and a composed preview surface
  # built from Canvas plus existing text and container views. Native renderers
  # can later map this to a platform gauge or chart control without changing
  # the shared API.
  class Gauge < View
    property value : Float64 = 0.0
    property minimum_value : Float64 = 0.0
    property maximum_value : Float64 = 100.0
    property units : String? = "%"
    property value_precision : Int32 = 0
    property label : String? = nil
    property prompt : String? = nil
    property caption : String? = nil
    property help_text : String? = nil
    property show_value : Bool = true
    property diameter : Float64 = 180.0
    property ring_thickness : Float64 = 12.0
    property start_angle : Float64 = -2.356194490192345
    property end_angle : Float64 = 2.356194490192345
    property track_color : Color = Color.new(r: 0.82, g: 0.83, b: 0.86)
    property progress_color : Color = Color.new(r: 0.28, g: 0.46, b: 0.84)
    property viewport_width : Float64 = 0.0
    property viewport_height : Float64 = 0.0

    def initialize(
      @value : Float64 = 0.0,
      @minimum_value : Float64 = 0.0,
      @maximum_value : Float64 = 100.0,
      @label : String? = nil,
      @prompt : String? = nil,
      @caption : String? = nil,
      @help_text : String? = nil
    )
    end

    def normalized_value : Float64
      return minimum_value if maximum_value <= minimum_value
      clamped_value
    end

    def progress_fraction : Float64
      return 0.0 if maximum_value <= minimum_value
      (clamped_value - minimum_value) / (maximum_value - minimum_value)
    end

    def display_value : String
      rounded = normalized_value.round(value_precision)
      text = value_precision <= 0 ? rounded.to_i.to_s : rounded.to_s
      if units = @units
        units == "%" ? "#{text}%" : "#{text} #{units}"
      else
        text
      end
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

      body << build_stage.as(UI::View)

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

    private def build_stage : UI::View
      stage = UI::ZStack.new(UI::Alignment::Center)
      stage.minimum_width = diameter
      stage.maximum_width = diameter
      stage.minimum_height = diameter
      stage.maximum_height = diameter

      stage << build_canvas.as(UI::View)
      stage << build_overlay.as(UI::View)
      stage.as(UI::View)
    end

    private def build_canvas : UI::Canvas
      canvas = UI::Canvas.new(diameter, diameter)
      canvas.minimum_width = diameter
      canvas.maximum_width = diameter
      canvas.minimum_height = diameter
      canvas.maximum_height = diameter

      center = diameter / 2.0
      radius = center - (ring_thickness / 2.0) - 8.0
      radius = 0.0 if radius < 0.0
      sweep = end_angle - start_angle
      progress_end = start_angle + sweep * progress_fraction

      canvas.begin_path
      canvas.arc(center, center, radius, start_angle, end_angle)
      canvas.stroke(track_color, ring_thickness)

      canvas.begin_path
      canvas.arc(center, center, radius, start_angle, progress_end)
      canvas.stroke(progress_color, ring_thickness)
      canvas
    end

    private def build_overlay : UI::View
      overlay = UI::VStack.new(spacing: 2.0, alignment: UI::Alignment::Center)

      if show_value
        value_label = UI::Label.new(display_value)
        value_label.font = UI::Font.new(size: 26.0, weight: :semibold)
        overlay << value_label.as(UI::View)
      end

      overlay.as(UI::View)
    end

    private def clamped_value : Float64
      return minimum_value if value < minimum_value
      return maximum_value if value > maximum_value
      value
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
