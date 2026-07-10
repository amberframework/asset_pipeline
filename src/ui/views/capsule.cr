# Pill-shaped geometric primitive used for badges and chip backgrounds.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Capsule — Pill-shaped geometric primitive used for badges and chip backgrounds.
  class Capsule < View
    property fill_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
    property stroke_color : Color? = nil
    property stroke_width : Float64 = 0.0
    property width : Float64 = 100.0
    property height : Float64 = 40.0

    def initialize(@width : Float64 = 100.0, @height : Float64 = 40.0)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
