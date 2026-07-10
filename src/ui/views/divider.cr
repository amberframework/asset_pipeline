# Thin horizontal or vertical separator line between content.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Divider — Thin horizontal or vertical separator line between content.
  class Divider < View
    property color : Color = Color.new(r: 0.8, g: 0.8, b: 0.8)
    property thickness : Float64 = 1.0
    property orientation : Symbol = :horizontal  # :horizontal, :vertical

    def initialize(@orientation : Symbol = :horizontal)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
