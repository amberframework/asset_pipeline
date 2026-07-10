# Color selection control bridging to the native color picker on each platform.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # ColorPicker — Color selection control bridging to the native color picker on each platform.
  class ColorPicker < View
    property selected_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
    property on_change : Proc(Color, Nil)? = nil
    property label : String = ""
    property supports_alpha : Bool = false

    def initialize
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
