# Tappable button with HIG-conformant styling for primary, secondary, and tinted roles.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
{% if flag?(:macos) || flag?(:ios) %}
  require "../native/swiftkit_bridge"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Visual presentation style for UI::Button.
  #
  # Maps to UIButton.Configuration variants on iOS 15+ and to NSButton
  # bezel / fill attributes on macOS. HIG: "Use a consistent style to help
  # people understand which buttons perform primary versus secondary actions."
  #
  #   Default    — bordered system button. UIButton.Configuration.gray() /
  #                NSBezelStyleRounded. The standard interactive affordance
  #                for most secondary and utility actions.
  #   Prominent  — filled blue (or red when role == :destructive). Primary
  #                call-to-action per HIG: "Use a filled button for the most
  #                likely action in a view." UIButton.Configuration.filled() /
  #                NSButton with bezelColor = controlAccentColor.
  #   Tinted     — translucent tint fill, a softer alternative to Prominent
  #                for secondary CTAs. UIButton.Configuration.tinted() /
  #                NSButton with NSBezelStyleFlexiblePush.
  #   Bordered   — explicit bordered button (same as Default on most surfaces;
  #                use when you want to be explicit in code). Resolves
  #                identically to Default in both renderers.
  #   Borderless — no bezel; label text only. UIButton.Configuration.plain() /
  #                NSButton with isBordered = false. Use for low-prominence
  #                inline actions (e.g. "Learn more", "See details").
  enum ButtonStyle
    Default
    Prominent
    Tinted
    Bordered
    Borderless
  end

  # A tappable button with a text label and optional action callback.
  #
  # The `on_tap` proc is invoked when the button is activated.
  # Buttons can be disabled to prevent interaction.
  class Button < View
    # HTML form-submission role for `UI::Button` on the web target.
    # Native renderers (AppKit / UIKit) ignore this property —
    # buttons are dispatched via `on_tap` on native.
    #
    # * `Button` — non-submitting; the default. Web emits `type="button"`.
    # * `Submit` — submits the enclosing `<form>`. Web emits `type="submit"`.
    # * `Reset`  — resets the enclosing `<form>`. Web emits `type="reset"`.
    #
    # `UI::Form` web-visit auto-promotes a single-button form's lone
    # Button from `Type::Button` to `Type::Submit`. Multi-button forms
    # MUST set `type: UI::Button::Type::Submit` explicitly on the
    # intended submitter — no surprising "last button wins" convention.
    enum Type
      Button
      Submit
      Reset
    end

    # The button's display label
    property label : String

    # Font for the button label
    property font : Font = Font.new

    # Foreground (label) color
    property foreground_color : Color = Color.new(r: 0.0, g: 0.478, b: 1.0)

    # Maximum label lines. Default `1` keeps the single-line, truncating
    # CTA behavior. Set `0` for unlimited (wrap to as many lines as needed)
    # or `n > 1` for a wrapping cap — used for content buttons whose label is
    # user text (e.g. a tappable thought card) that must wrap, not truncate.
    # The SwiftUI facade also applies `.fixedSize(vertical:)` so the wrapped
    # label takes its natural multi-line height inside a width-constrained
    # (fill_horizontal) container.
    property number_of_lines : Int32 = 1

    # Horizontal alignment of the label text. Defaults to `Center` — the
    # conventional CTA presentation and the browser's native `<button>` default.
    # Set `Leading`/`Trailing` for content buttons whose label is body text that
    # should read left/right-aligned (e.g. a wrapping tappable affirmation/thought
    # card, matching the Expo design's left-aligned Pressable text). Web emits
    # `text-align`; native button renderers currently treat the label as centered.
    property text_alignment : Alignment = Alignment::Center

    # Whether the button is disabled (non-interactive).
    #
    # Reactive: after the renderer has emitted the SwiftUI hosting view,
    # mutating this property propagates through the SwiftKit bridge so
    # SwiftUI re-renders the Button with `.disabled(true)` / `.disabled(false)`
    # without a tree rebuild. Setters issued before the view has been
    # rendered are plain property assignments — the next render seeds the
    # reactive state from the new value. Phase 6.11 added the reactive
    # path so the Voyager Todo editor can flip Save's disabled state as
    # the user types (blank title → disabled; non-blank → enabled) without
    # rebuilding the whole screen.
    getter disabled : Bool = false

    # Assigns the disabled flag.
    def disabled=(new_value : Bool) : Bool
      @disabled = new_value
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          LibSwiftKitBridge.apsk_button_set_disabled(sh, new_value ? 1 : 0)
        end
      {% end %}
      new_value
    end

    # Callback invoked when the button is tapped
    property on_tap : Proc(Nil)? = nil

    # Semantic role for the button. HIG-standard values:
    #   :default      — normal/primary action (no special styling)
    #   :destructive  — action destroys data; renderers color the label red
    #   :cancel       — dismisses a presentation surface; renderers weight
    #                   the label Semibold per HIG
    property role : Symbol = :default

    # Visual style. See ButtonStyle for full documentation.
    # Default renders as a system bordered button; override to Prominent for
    # filled-blue primary CTAs or Borderless for text-link style.
    property style : ButtonStyle = ButtonStyle::Default

    # Leading SF Symbol glyph name (macOS 11+ / iOS 13+). When non-nil the
    # renderers prepend an SF Symbol image to the button. Unknown symbol
    # names are silently skipped rather than crashing.
    property symbol : String? = nil

    # HTML form-submission role on the web target. See `UI::Button::Type`.
    # Defaults to `Type::Button` (non-submitting). Set explicitly on the
    # button intended to submit a `UI::Form` — multi-button forms do NOT
    # auto-promote; only single-button forms do (see `UI::Form`).
    property type : Type = Type::Button

    def initialize(@label : String, *, @role : Symbol = :default, @style : ButtonStyle = ButtonStyle::Default, @symbol : String? = nil, @type : Type = Type::Button)
    end

    # Convenience constructor that accepts a tap handler block
    def initialize(@label : String, *, @role : Symbol = :default, @style : ButtonStyle = ButtonStyle::Default, @symbol : String? = nil, @type : Type = Type::Button, &block : -> Nil)
      @on_tap = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    # Phase 10B.2a — default AX role: `:button`.
    def default_accessibility_role : Symbol?
      :button
    end

    # Phase 10B.2b — interactive widgets default to focusable.
    def default_focusable : Bool
      true
    end

    # ---- Phase 3 Remediation 4 reactive overrides ----------------------
    #
    # Override the three setters that the SwiftKit bridge can mutate at
    # runtime so a property change after the renderer has emitted the
    # SwiftUI hosting view propagates to a SwiftUI re-render of just the
    # affected modifier. Setters issued before the view is rendered are
    # plain property assignments — the next render seeds reactive state
    # from the new value.
    #
    # `background` and `corner_radius` live on UI::View; the override
    # delegates to a single helper so all three call-sites stay
    # consistent.

    # Assigns the background fill.
    def background=(new_color : Color?) : Color?
      @background = new_color
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          if c = new_color
            LibSwiftKitBridge.apsk_button_set_background_color(sh, c.r, c.g, c.b, c.a)
          else
            LibSwiftKitBridge.apsk_button_clear_background_color(sh)
          end
        end
      {% end %}
      new_color
    end

    # Assigns the foreground color.
    def foreground_color=(new_color : Color) : Color
      @foreground_color = new_color
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          LibSwiftKitBridge.apsk_button_set_foreground_color(
            sh, new_color.r, new_color.g, new_color.b, new_color.a,
          )
        end
      {% end %}
      new_color
    end

    # Assigns the corner radius (pt).
    def corner_radius=(new_radius : Float64) : Float64
      @corner_radius = new_radius
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          if new_radius == 0.0
            LibSwiftKitBridge.apsk_button_clear_corner_radius(sh)
          else
            LibSwiftKitBridge.apsk_button_set_corner_radius(sh, new_radius)
          end
        end
      {% end %}
      new_radius
    end
  end
end
