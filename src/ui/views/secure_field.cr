# Single-line text input that masks its contents (used for passwords).
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A password/secure text input field.
  # This is a convenience wrapper around TextField with secure_entry = true.
  class SecureField < View
    property text : String = ""
    property placeholder : String = ""
    # Name attribute for web POST submission. See `UI::TextField#name`
    # for the full doc.
    property name : String? = nil
    property font : Font = Font.new
    property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
    property on_change : Proc(String, Nil)? = nil

    def initialize(@placeholder : String = "", *, @name : String? = nil, @text : String = "")
    end

    def initialize(@placeholder : String = "", *, @name : String? = nil, @text : String = "", &block : String -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
