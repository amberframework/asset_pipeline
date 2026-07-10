# Hover / focus-driven tooltip overlay attached to a host view.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Tooltip — Hover / focus-driven tooltip overlay attached to a host view.
  class Tooltip < View
    property text : String = ""
    property content : View? = nil
    property position : Symbol = :top # :top, :bottom, :leading, :trailing
    property delay : Float64 = 0.5
    property is_visible : Bool = false

    def initialize(@text : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
