# Vector path primitive driven by an explicit drawing command sequence.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  enum PathCommand
    MoveTo
    LineTo
    QuadCurveTo
    CurveTo
    Close
  end

  record PathSegment,
    command : PathCommand,
    x : Float64 = 0.0,
    y : Float64 = 0.0,
    control_x1 : Float64 = 0.0,
    control_y1 : Float64 = 0.0,
    control_x2 : Float64 = 0.0,
    control_y2 : Float64 = 0.0

  # PathView — Vector path primitive driven by an explicit drawing command sequence.
  class PathView < View
    property segments : Array(PathSegment) = [] of PathSegment
    property fill_color : Color? = nil
    property stroke_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
    property stroke_width : Float64 = 1.0
    property width : Float64 = 100.0
    property height : Float64 = 100.0

    def initialize(@width : Float64 = 100.0, @height : Float64 = 100.0)
    end

    def move_to(x : Float64, y : Float64)
      @segments << PathSegment.new(command: PathCommand::MoveTo, x: x, y: y)
    end

    def line_to(x : Float64, y : Float64)
      @segments << PathSegment.new(command: PathCommand::LineTo, x: x, y: y)
    end

    def curve_to(x : Float64, y : Float64, cx1 : Float64, cy1 : Float64, cx2 : Float64, cy2 : Float64)
      @segments << PathSegment.new(command: PathCommand::CurveTo, x: x, y: y, control_x1: cx1, control_y1: cy1, control_x2: cx2, control_y2: cy2)
    end

    def close
      @segments << PathSegment.new(command: PathCommand::Close)
    end

    # Generate SVG path data string from segments
    def to_svg_path : String
      String.build do |io|
        segments.each do |seg|
          case seg.command
          when PathCommand::MoveTo      then io << "M#{seg.x} #{seg.y} "
          when PathCommand::LineTo      then io << "L#{seg.x} #{seg.y} "
          when PathCommand::QuadCurveTo then io << "Q#{seg.control_x1} #{seg.control_y1} #{seg.x} #{seg.y} "
          when PathCommand::CurveTo     then io << "C#{seg.control_x1} #{seg.control_y1} #{seg.control_x2} #{seg.control_y2} #{seg.x} #{seg.y} "
          when PathCommand::Close       then io << "Z "
          end
        end
      end.strip
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
