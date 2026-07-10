# Single-line plain-text input field.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # An editable single-line text input field.
  #
  # Provides placeholder text, secure entry mode for passwords,
  # keyboard type hints, and a change callback.
  class TextField < View
    # Current text value
    property text : String = ""

    # Placeholder text shown when empty
    property placeholder : String = ""

    # Name attribute for web POST submission. When non-nil and the
    # field renders into a `<form>` (UI::Form), the web renderer emits
    # `name="..."` so the browser includes this field in the form-encoded
    # body. Native renderers ignore this property — they collect field
    # values via FormState in Phase 8B/8C.
    property name : String? = nil

    # Font for the text field content
    property font : Font = Font.new

    # Text color
    property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)

    # Whether input is obscured (password entry)
    property secure_entry : Bool = false

    # Keyboard type hint for platform input method
    property keyboard_type : KeyboardType = KeyboardType::Default

    # Callback invoked when the text value changes.
    # Receives the new text string.
    property on_change : Proc(String, Nil)? = nil

    # Construct a TextField. `text:` pre-populates the value (useful
    # when re-rendering a form after a failed submit). `name:` sets the
    # HTML form-input name for web POST submission.
    def initialize(@placeholder : String = "", *, @name : String? = nil, @text : String = "")
    end

    # Convenience constructor with a change handler block.
    def initialize(@placeholder : String = "", *, @name : String? = nil, @text : String = "", &block : String -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
