# Multi-line plain-text input field.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # TextArea — Multi-line plain-text input field.
  class TextArea < View
    property text : String = ""
    property placeholder : String = ""
    property font : Font = Font.new
    property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
    property is_editable : Bool = true
    property is_scrollable : Bool = true
    property line_limit : Int32? = nil
    property on_change : Proc(String, Nil)? = nil

    def initialize(@placeholder : String = "")
    end

    def initialize(@placeholder : String = "", &block : String -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
