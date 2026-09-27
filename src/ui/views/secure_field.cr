# Single-line text input that masks its contents (used for passwords).
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A password/secure text input field.
  # This is a convenience wrapper around TextField with secure_entry = true.
  class SecureField < View
    # Body text rendered by the view.
    property text : String = ""
    # Placeholder text shown when the field is empty.
    property placeholder : String = ""
    # Horizontal alignment of the value and placeholder inside the field.
    # Leading and Trailing follow the platform's natural reading direction.
    property text_alignment : Alignment = Alignment::Leading
    # Name attribute for web POST submission. See `UI::TextField#name`
    # for the full doc.
    property name : String? = nil
    # Typography applied to the rendered text.
    property font : Font = Font.new
    # Masked value color. Until it is assigned, every renderer draws the value
    # in the platform's appearance-tracking text color; the black stored here
    # is only a placeholder value. Assigning it opts the field into this exact
    # color. Mirrors `UI::TextField#text_color`.
    @text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)

    # The explicit masked value color (see `#has_explicit_text_color?`).
    getter text_color

    # Whether `text_color` was assigned. Renderers honor `text_color` only
    # when this is true.
    getter? has_explicit_text_color : Bool = false

    # Assigns the masked value color and marks it explicit.
    def text_color=(color : Color) : Color
      @has_explicit_text_color = true
      @text_color = color
    end

    # Placeholder tint. `nil` (the default) keeps the kit's contrast-safe
    # placeholder. Mirrors `UI::TextField#placeholder_color`.
    property placeholder_color : Color? = nil
    # Invoked when the user changes the control's value.
    property on_change : Proc(String, Nil)? = nil

    def initialize(@placeholder : String = "", *, @name : String? = nil, @text : String = "")
    end

    def initialize(@placeholder : String = "", *, @name : String? = nil, @text : String = "", &block : String -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    # Phase 10B.2a — default AX role: `:text_field`.
    def default_accessibility_role : Symbol?
      :text_field
    end

    # Phase 10B.2b — interactive widgets default to focusable.
    def default_focusable : Bool
      true
    end
  end
end
