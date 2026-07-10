# Composition of activity rings rendered as a stack of progress indicators.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A three-ring activity summary that follows the HIG's fixed Move /
  # Exercise / Stand semantics.
  #
  # The primitive stays deliberately opinionated: it always renders on a black
  # circular field with the canonical ring colors, while exposing only the
  # geometry and progress values needed to place it cleanly in a larger layout.
  class ActivityRings < View
    MOVE_COLOR     = Color.new(r: 250.0 / 255.0, g: 17.0 / 255.0, b: 79.0 / 255.0)
    EXERCISE_COLOR = Color.new(r: 166.0 / 255.0, g: 1.0, b: 0.0)
    STAND_COLOR    = Color.new(r: 0.0, g: 1.0, b: 246.0 / 255.0)
    BLACK          = Color.new(r: 0.0, g: 0.0, b: 0.0)

    property move : Float64 = 0.0
    property exercise : Float64 = 0.0
    property stand : Float64 = 0.0
    property size : Float64 = 176.0
    property thickness : Float64 = 16.0
    property gap : Float64 = 8.0
    property start_angle : Float64 = -1.5707963267948966
    property end_angle : Float64 = 4.71238898038469

    def initialize(
      @move : Float64 = 0.0,
      @exercise : Float64 = 0.0,
      @stand : Float64 = 0.0
    )
    end

    def move_fraction : Float64
      normalized_fraction(move)
    end

    def exercise_fraction : Float64
      normalized_fraction(exercise)
    end

    def stand_fraction : Float64
      normalized_fraction(stand)
    end

    def fallback_view : View
      stage = UI::ZStack.new(UI::Alignment::Center)
      stage.minimum_width = size
      stage.maximum_width = size
      stage.minimum_height = size
      stage.maximum_height = size

      background_circle = UI::Circle.new(size)
      background_circle.fill_color = BLACK
      background_circle.stroke_color = BLACK
      background_circle.stroke_width = 1.0
      background_circle.minimum_width = size
      background_circle.maximum_width = size
      background_circle.minimum_height = size
      background_circle.maximum_height = size
      stage << background_circle.as(UI::View)

      outer_radius = size / 2.0 - (thickness / 2.0) - gap
      middle_radius = outer_radius - thickness - gap
      inner_radius = middle_radius - thickness - gap

      stage << build_ring_canvas(outer_radius, move_fraction, MOVE_COLOR).as(UI::View)
      stage << build_ring_canvas(middle_radius, exercise_fraction, EXERCISE_COLOR).as(UI::View)
      stage << build_ring_canvas(inner_radius, stand_fraction, STAND_COLOR).as(UI::View)

      copy_common_properties(stage)
      stage.as(UI::View)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    private def build_ring_canvas(radius : Float64, progress : Float64, progress_color : Color) : UI::Canvas
      canvas = UI::Canvas.new(size, size)
      canvas.minimum_width = size
      canvas.maximum_width = size
      canvas.minimum_height = size
      canvas.maximum_height = size

      clamped_radius = radius < 0.0 ? 0.0 : radius
      center = size / 2.0
      progress_end = start_angle + ((end_angle - start_angle) * progress)

      canvas.begin_path
      canvas.arc(center, center, clamped_radius, start_angle, end_angle)
      canvas.stroke(track_color_for(progress_color), thickness)

      canvas.begin_path
      canvas.arc(center, center, clamped_radius, start_angle, progress_end)
      canvas.stroke(progress_color, thickness)
      canvas
    end

    private def normalized_fraction(value : Float64) : Float64
      return 0.0 if value < 0.0
      return 1.0 if value > 1.0
      value
    end

    private def track_color_for(color : Color) : Color
      Color.new(
        r: color.r * 0.26,
        g: color.g * 0.26,
        b: color.b * 0.26,
        a: 1.0
      )
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
      target.minimum_width = minimum_width || target.minimum_width
      target.minimum_height = minimum_height || target.minimum_height
      target.maximum_width = maximum_width || target.maximum_width
      target.maximum_height = maximum_height || target.maximum_height
      target.test_id = test_id
    end
  end
end
