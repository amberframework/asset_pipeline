# Filled or stroked circular geometric primitive.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Circle — Filled or stroked circular geometric primitive.
  class Circle < View
    property fill_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
    property stroke_color : Color? = nil
    property stroke_width : Float64 = 0.0
    property size : Float64 = 50.0

    def initialize(@size : Float64 = 50.0)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
