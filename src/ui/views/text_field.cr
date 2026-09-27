# Single-line plain-text input field.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Visual chrome for a text field.
  #   RoundedBorder — the default boxed `.roundedBorder` field.
  #   Underline     — a bottom-border-only field (no box) — the Expo onboarding
  #                   input style: a 1px rule under the text, transparent fill.
  #   Plain         — no chrome at all.
  enum TextFieldStyle
    RoundedBorder
    Underline
    Plain
  end

  # An editable single-line text input field.
  #
  # Provides placeholder text, secure entry mode for passwords,
  # keyboard type hints, and a change callback.
  class TextField < View
    # Visual chrome (RoundedBorder default; Underline = bottom-rule only).
    property style : TextFieldStyle = TextFieldStyle::RoundedBorder

    # Current text value
    property text : String = ""

    # Placeholder text shown when empty
    property placeholder : String = ""

    # Horizontal alignment of the value and placeholder inside the field.
    # Leading and Trailing follow the platform's natural reading direction.
    property text_alignment : Alignment = Alignment::Leading

    # Name attribute for web POST submission. When non-nil and the
    # field renders into a `<form>` (UI::Form), the web renderer emits
    # `name="..."` so the browser includes this field in the form-encoded
    # body. Native renderers ignore this property — they collect field
    # values via FormState in Phase 8B/8C.
    property name : String? = nil

    # Font for the text field content
    property font : Font = Font.new

    # Value text color. Until it is assigned, every renderer draws the value in
    # the platform's appearance-tracking text color (label color on Apple,
    # the primary text token on web); the black stored here is only a
    # placeholder value. Assigning it opts the field into this exact color.
    @text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)

    # The explicit value text color (see `#has_explicit_text_color?`).
    getter text_color

    # Whether `text_color` was assigned. Renderers honor `text_color` only
    # when this is true, so an untouched field keeps the appearance-tracking
    # default in light and dark instead of a fixed black.
    getter? has_explicit_text_color : Bool = false

    # Assigns the value text color and marks it explicit.
    def text_color=(color : Color) : Color
      @has_explicit_text_color = true
      @text_color = color
    end

    # Placeholder tint. `nil` (the default) keeps the kit's contrast-safe
    # placeholder (`label @ 50% opacity`, ≥ 3:1 in light + dark). Set it to
    # match a brand placeholder color (e.g. Expo's `#bec2c2` over a photo
    # hero) — the consumer owns the contrast trade-off when they override.
    property placeholder_color : Color? = nil

    # Whether input is obscured (password entry)
    property secure_entry : Bool = false

    # Keyboard type hint for platform input method
    property keyboard_type : KeyboardType = KeyboardType::Default

    # Callback invoked when the text value changes.
    # Receives the new text string.
    property on_change : Proc(String, Nil)? = nil

    # Callback invoked when the user submits the field (bare Return / Enter).
    # Receives the current text. Mirrors SearchField#on_submit; on macOS/iOS the
    # facade attaches SwiftUI `.onSubmit`. nil = Return does nothing (the prior
    # behavior). This is the Enter-to-send primitive.
    property on_submit : Proc(String, Nil)? = nil

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
