# Pressed-state button used as a toggle (e.g. bold / italic toolbar buttons).
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # ToggleButton — Pressed-state button used as a toggle (e.g. bold / italic toolbar buttons).
  class ToggleButton < View
    property label : String
    property is_selected : Bool = false
    property icon : String? = nil
    property on_toggle : Proc(Bool, Nil)? = nil

    def initialize(@label : String, @is_selected : Bool = false)
    end

    def initialize(@label : String, @is_selected : Bool = false, &block : Bool -> Nil)
      @on_toggle = block
    end

    def toggle
      @is_selected = !@is_selected
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
