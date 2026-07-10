# Group of mutually exclusive radio buttons with a shared selection.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # RadioGroup — Group of mutually exclusive radio buttons with a shared selection.
  class RadioGroup < View
    property options : Array(String) = [] of String
    property selected_index : Int32 = 0
    property on_change : Proc(Int32, Nil)? = nil

    def initialize(@options : Array(String) = [] of String, @selected_index : Int32 = 0)
    end

    def initialize(@options : Array(String), @selected_index : Int32 = 0, &block : Int32 -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
