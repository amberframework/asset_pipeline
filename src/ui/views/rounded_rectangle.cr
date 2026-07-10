# Rectangular primitive with configurable corner radius.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # RoundedRectangle — Rectangular primitive with configurable corner radius.
  class RoundedRectangle < View
    property fill_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
    property stroke_color : Color? = nil
    property stroke_width : Float64 = 0.0
    property corner_style : Symbol = :continuous # :continuous, :circular
    property corner_radius : Float64
    property width : Float64 = 100.0
    property height : Float64 = 50.0

    def initialize(@corner_radius : Float64 = 8.0, @width : Float64 = 100.0, @height : Float64 = 50.0)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
