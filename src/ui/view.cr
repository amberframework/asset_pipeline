# Defines `UI::View`, the abstract base for every cross-platform view, plus the
# `RenderContext` and `RenderError` types used by the platform-visitor renderers.

require "json"

module UI
  # Phase 6.11 iter-3 — Raised by a platform visitor when a child view
  # cannot be rendered to its native handle. The previous behavior emitted
  # a silent empty placeholder which masked bugs (notably the iOS
  # `SwipeActionRow` content path during the swipe-reveal refactor). The
  # explicit exception surfaces the failure immediately during development
  # and lets call sites that genuinely need a recoverable path opt in via
  # a `begin/rescue` of their own.
  class RenderError < Exception
  end

  # Raised when a surface-craft value does not meet its construction contract.
  class SurfaceCraftError < RenderError
  end

  # Phase 8A — Renderer-scoped per-request context threaded through
  # `UI::Web::Renderer#render(view, render_context:)`. Carries values
  # the web visit methods need but that don't belong on the view tree
  # itself (e.g. the CSRF token for `UI::Form`'s hidden-input
  # injection).
  #
  # Phase 10B.2c iter 2 — Now also carries the `UI::Environment` so
  # widgets that react to user preferences (e.g. `UI::Snackbar`'s
  # `effective_duration` honoring reduce-motion) can read the
  # environment at visit time from the renderer-side context. The
  # `ScreenContext`'s environment is copied here when the host builds
  # the render context (`compute_screen_html` does this); test paths
  # that construct a `RenderContext` directly pass `environment:`
  # explicitly or accept the conservative default.
  #
  # Lives in the core `UI` namespace (rather than the Amber integration
  # file) so the web renderer can read it without requiring the Amber
  # integration to be loaded. Apps not using Amber simply pass a fresh
  # `RenderContext.empty` or omit the argument.
  struct RenderContext
    getter csrf_token : String?
    getter environment : UI::Environment

    def initialize(@csrf_token : String? = nil, @environment : UI::Environment = UI::Environment.default)
    end

    def self.empty : RenderContext
      new(csrf_token: nil, environment: UI::Environment.default)
    end
  end

  # Alignment options for stack layouts
  enum Alignment
    Leading
    Center
    Trailing
    Top
    Bottom
    Fill
  end

  # Content mode for image display
  enum ContentMode
    Fit
    Fill
    Stretch
  end

  # Keyboard type hint for text fields
  enum KeyboardType
    Default
    EmailAddress
    NumberPad
    PhonePad
    URL
  end

  # Style for toggle/switch controls
  enum ToggleStyle
    Switch   # iOS-style toggle switch
    Checkbox # Standard checkbox
  end

  # Style for picker controls
  enum PickerStyle
    Wheel     # Spinning wheel picker
    Segmented # Segmented control inline
    Menu      # Dropdown/popup menu
    Inline    # Expanded inline
  end

  # Mode for date/time pickers
  enum DatePickerMode
    Date        # Date only
    Time        # Time only
    DateAndTime # Both date and time
  end

  # Visual style for date/time pickers.
  # Phase 10D-polish iter 2 (B-DATEPICKER-STYLE-PROPERTY).
  #
  # * `Automatic` — let the platform pick the HIG-correct style for the
  #   mode (`.date` → graphical on iOS; `.compact` on macOS).
  # * `Compact` — inline button that pops a wheel/calendar overlay when
  #   tapped. The asset_pipeline default for in-form usage.
  # * `Graphical` — full inline calendar / clock face. SwiftUI's
  #   `.graphical` (iOS) / `.field` (macOS) date picker style.
  # * `Wheels` — spinning wheel picker. SwiftUI `.wheel`.
  enum DatePickerStyle
    Automatic
    Compact
    Graphical
    Wheels
  end

  # Style for progress indicators
  enum ProgressStyle
    Linear   # Horizontal progress bar
    Circular # Spinning circular progress
  end

  # Direction of a discrete swipe gesture. Used with UI::View#on_swipe to
  # attach directional swipe handlers (e.g. "swipe down to dismiss sheet",
  # "swipe left for destructive action"). Continuous pan/drag is out of scope.
  #
  # Per-platform mapping:
  #   UIKit  — UISwipeGestureRecognizer with the matching direction mask.
  #   AppKit — NSPanGestureRecognizer; the .ended state classifies the
  #            dominant translation component (threshold ~30 pt) to select
  #            the direction. Horizontal translation dominance wins over
  #            vertical when both exceed the threshold simultaneously.
  #   Web    — no-op; swipe handlers are silently ignored.
  enum SwipeDirection
    Left
    Right
    Up
    Down
  end

  # Style for list views
  enum ListStyle
    Plain        # No grouping, no separators between sections
    Inset        # Rounded group sections with insets
    Grouped      # Grouped with section headers
    InsetGrouped # Rounded grouped sections
    Sidebar      # macOS-style sidebar list
  end

  # Layout mode for list/collection views
  enum ListLayout
    List # Vertical row layout (default; maps to UITableView / NSTableView semantics)
    Grid # Multi-column grid layout (maps to UICollectionView / NSCollectionView semantics)
  end

  # Value type representing an RGBA color
  record Color,
    r : Float64,
    g : Float64,
    b : Float64,
    a : Float64 = 1.0

  # Semantic color roles accepted by reusable surface overrides.
  enum ColorRole
    BrandPrimary
    BrandAccent
    SurfaceCanvas
    SurfaceElevated
    SurfacePanel
    SurfaceSunken
    SurfaceInverse
    TextPrimary
    TextInverse
    Warning
  end

  # A literal color or a semantic design-token role.
  alias SurfaceColor = Color | ColorRole

  # One color and normalized position in a linear gradient.
  record GradientStop,
    stop_color : SurfaceColor,
    stop_position : Float64

  # A linear gradient in clockwise degrees, with at least two ordered stops.
  struct LinearGradient
    getter list_of_stops : Array(GradientStop)
    getter gradient_angle : Float64

    def initialize(@list_of_stops : Array(GradientStop), @gradient_angle : Float64 = 0.0)
      raise SurfaceCraftError.new("A linear gradient requires at least two stops") if @list_of_stops.size < 2
      previous_position = -1.0
      @list_of_stops.each do |stop|
        unless stop.stop_position >= 0.0 && stop.stop_position <= 1.0
          raise SurfaceCraftError.new("Gradient stop positions must be between 0 and 1")
        end
        if stop.stop_position < previous_position
          raise SurfaceCraftError.new("Gradient stop positions must be in ascending order")
        end
        previous_position = stop.stop_position
      end
    end
  end

  # Shared drop-shadow value used by view surface overrides.
  record DropShadow,
    shadow_color : SurfaceColor,
    offset_x : Float64 = 0.0,
    offset_y : Float64 = 0.0,
    blur_radius : Float64 = 0.0

  # Inset shadow drawn inside a view's bounds.
  record InnerShadow,
    shadow_color : SurfaceColor,
    offset_x : Float64 = 0.0,
    offset_y : Float64 = 0.0,
    blur_radius : Float64 = 0.0

  # Kind of procedural texture rendered over a surface.
  enum TextureKind
    Noise
    Brushed
  end

  # Generated texture kind and alpha, with validated Noise parameters.
  # Noise parameters use SVG feTurbulence units and defaults. Brushed ignores
  # these Noise-specific values so its existing appearance remains unchanged.
  #
  # ```
  # UI::TextureOverlay.new(
  #   texture_kind: UI::TextureKind::Noise,
  #   texture_opacity: 0.07,
  #   base_frequency: 0.83,
  #   octave_count: 3,
  #   seed: 7,
  #   tile_size: 128,
  # )
  # ```
  struct TextureOverlay
    getter texture_kind : TextureKind
    getter texture_opacity : Float64
    getter base_frequency : Float64
    getter octave_count : Int32
    getter seed : Int32
    getter tile_size : Int32

    def initialize(
      @texture_kind : TextureKind,
      @texture_opacity : Float64,
      @base_frequency : Float64 = 0.72,
      @octave_count : Int32 = 3,
      @seed : Int32 = 4,
      @tile_size : Int32 = 160,
    )
      unless @texture_opacity >= 0.0 && @texture_opacity <= 1.0
        raise SurfaceCraftError.new("Texture opacity must be between 0 and 1")
      end
      unless @base_frequency.finite? && @base_frequency >= 0.0 && @base_frequency <= 16.0
        raise SurfaceCraftError.new("Texture base frequency must be between 0 and 16")
      end
      unless @octave_count >= 1 && @octave_count <= 8
        raise SurfaceCraftError.new("Texture octave count must be between 1 and 8")
      end
      unless @tile_size >= 1 && @tile_size <= 1024
        raise SurfaceCraftError.new("Texture tile size must be between 1 and 1024 points")
      end
    end
  end

  # Optional tactile surface properties for a panel or its tab.
  record SurfaceStyle,
    background_fill_color : SurfaceColor? = nil,
    linear_gradient : LinearGradient? = nil,
    list_of_inner_shadows : Array(InnerShadow) = [] of InnerShadow,
    list_of_drop_shadows : Array(DropShadow) = [] of DropShadow,
    texture_overlay : TextureOverlay? = nil

  # Hover and press response used by buttons and rows.
  enum InteractionFeedback
    None
    Sink
    Lift
    Edge
  end

  # A forced interaction phase used by component previews and review workbenches.
  enum PreviewState
    None
    Hover
    Pressed
    Focus
  end

  # Folder-like tab silhouette used by Form sections.
  enum TabShape
    Angled
    Rounded
    Notched
    Flush
  end

  # Explicit appearance options for UI::Toggle. Native remains the default.
  enum ToggleAppearance
    Native
    Pill
    Rocker
    Slide
    LampPill
  end

  # Keycap treatment for UI::Keycap.
  enum KeycapStyle
    Outlined
    Sculpted
    Inset
    Text
  end

  # Visual treatment for UI::ColorSwatchPicker.
  enum ColorSwatchPickerStyle
    SwatchButton
    SwatchRow
    NamedPopup
    BezelLamp
  end

  # A named color choice in a swatch picker.
  record ColorSwatch,
    color_name : String,
    swatch_color : SurfaceColor

  # Typed payload for a single gradient stop crossing the SwiftUI bridge.
  struct SurfaceCraftGradientStopPayload
    include JSON::Serializable

    property color : String
    property position : Float64

    def initialize(@color : String, @position : Float64)
    end
  end

  # Typed gradient payload crossing the SwiftUI bridge.
  struct SurfaceCraftGradientPayload
    include JSON::Serializable

    property angle : Float64
    property stops : Array(SurfaceCraftGradientStopPayload)

    def initialize(@angle : Float64, @stops : Array(SurfaceCraftGradientStopPayload))
    end
  end

  # Typed shadow payload shared by inner and drop shadows.
  struct SurfaceCraftShadowPayload
    include JSON::Serializable

    property color : String
    @[JSON::Field(key: "x")]
    property offset_x : Float64
    @[JSON::Field(key: "y")]
    property offset_y : Float64
    @[JSON::Field(key: "blur")]
    property blur_radius : Float64

    def initialize(@color : String, @offset_x : Float64, @offset_y : Float64, @blur_radius : Float64)
    end
  end

  # Typed texture payload crossing the SwiftUI bridge.
  struct SurfaceCraftTexturePayload
    include JSON::Serializable

    property kind : String
    property opacity : Float64
    @[JSON::Field(key: "baseFrequency")]
    property base_frequency : Float64
    @[JSON::Field(key: "octaveCount")]
    property octave_count : Int32
    property seed : Int32
    @[JSON::Field(key: "tileSize")]
    property tile_size : Int32

    def initialize(
      @kind : String,
      @opacity : Float64,
      @base_frequency : Float64,
      @octave_count : Int32,
      @seed : Int32,
      @tile_size : Int32,
    )
    end
  end

  # Shared typed payload for view and section surface modifiers.
  struct SurfaceCraftPayload
    include JSON::Serializable

    @[JSON::Field(emit_null: false)]
    property fill : String? = nil
    @[JSON::Field(emit_null: false)]
    property gradient : SurfaceCraftGradientPayload? = nil
    @[JSON::Field(key: "innerShadows", emit_null: false)]
    property list_of_inner_shadows : Array(SurfaceCraftShadowPayload)? = nil
    @[JSON::Field(key: "dropShadows", emit_null: false)]
    property list_of_drop_shadows : Array(SurfaceCraftShadowPayload)? = nil
    @[JSON::Field(emit_null: false)]
    property texture : SurfaceCraftTexturePayload? = nil
    @[JSON::Field(emit_null: false)]
    property feedback : String? = nil
    @[JSON::Field(key: "previewState", emit_null: false)]
    property preview_state : String? = nil

    def initialize(
      @fill : String? = nil,
      @gradient : SurfaceCraftGradientPayload? = nil,
      @list_of_inner_shadows : Array(SurfaceCraftShadowPayload)? = nil,
      @list_of_drop_shadows : Array(SurfaceCraftShadowPayload)? = nil,
      @texture : SurfaceCraftTexturePayload? = nil,
      @feedback : String? = nil,
      @preview_state : String? = nil,
    )
    end
  end

  # Converts typed surface values into the compact payload shared with SwiftUI.
  module SurfaceCraftEncoding
    def self.color_value(color : SurfaceColor) : String
      case color
      when Color
        "rgba(#{(color.r * 255).round},#{(color.g * 255).round},#{(color.b * 255).round},#{color.a})"
      when ColorRole
        "role:#{color.to_s.underscore.gsub('_', '-')}"
      else
        raise SurfaceCraftError.new("Unsupported surface color")
      end
    end

    def self.style_json(
      style : SurfaceStyle,
      interaction_feedback : InteractionFeedback = InteractionFeedback::None,
      preview_state : PreviewState = PreviewState::None,
    ) : String
      surface_payload(style, interaction_feedback, preview_state).to_json
    end

    def self.surface_payload(
      style : SurfaceStyle,
      interaction_feedback : InteractionFeedback = InteractionFeedback::None,
      preview_state : PreviewState = PreviewState::None,
    ) : SurfaceCraftPayload
      fill = if color = style.background_fill_color
               color_value(color)
             end
      gradient = if value = style.linear_gradient
                   gradient_payload(value)
                 end
      inner_shadows = if style.list_of_inner_shadows.empty?
                        nil
                      else
                        style.list_of_inner_shadows.map { |shadow| shadow_payload(shadow) }
                      end
      drop_shadows = if style.list_of_drop_shadows.empty?
                       nil
                     else
                       style.list_of_drop_shadows.map { |shadow| shadow_payload(shadow) }
                     end
      texture = if value = style.texture_overlay
                  texture_payload(value)
                end
      feedback = if interaction_feedback == InteractionFeedback::None
                   nil
                 else
                   interaction_feedback.to_s.underscore
                 end
      preview_state_value = if preview_state == PreviewState::None
                              nil
                            else
                              preview_state.to_s.underscore
                            end

      SurfaceCraftPayload.new(
        fill: fill,
        gradient: gradient,
        list_of_inner_shadows: inner_shadows,
        list_of_drop_shadows: drop_shadows,
        texture: texture,
        feedback: feedback,
        preview_state: preview_state_value,
      )
    end

    private def self.gradient_payload(gradient : LinearGradient) : SurfaceCraftGradientPayload
      stops = gradient.list_of_stops.map do |stop|
        SurfaceCraftGradientStopPayload.new(
          color: color_value(stop.stop_color),
          position: stop.stop_position,
        )
      end
      SurfaceCraftGradientPayload.new(angle: gradient.gradient_angle, stops: stops)
    end

    private def self.shadow_payload(shadow : InnerShadow) : SurfaceCraftShadowPayload
      SurfaceCraftShadowPayload.new(
        color: color_value(shadow.shadow_color),
        offset_x: shadow.offset_x,
        offset_y: shadow.offset_y,
        blur_radius: shadow.blur_radius,
      )
    end

    private def self.shadow_payload(shadow : DropShadow) : SurfaceCraftShadowPayload
      SurfaceCraftShadowPayload.new(
        color: color_value(shadow.shadow_color),
        offset_x: shadow.offset_x,
        offset_y: shadow.offset_y,
        blur_radius: shadow.blur_radius,
      )
    end

    private def self.texture_payload(texture : TextureOverlay) : SurfaceCraftTexturePayload
      SurfaceCraftTexturePayload.new(
        kind: texture.texture_kind.to_s.downcase,
        opacity: texture.texture_opacity,
        base_frequency: texture.base_frequency,
        octave_count: texture.octave_count,
        seed: texture.seed,
        tile_size: texture.tile_size,
      )
    end
  end

  # Value type representing a font specification
  record Font,
    family : String = "system",
    size : Float64 = 17.0,
    weight : Symbol = :regular,
    italic : Bool = false

  # Value type representing edge insets (padding/margins)
  record EdgeInsets,
    top : Float64 = 0.0,
    trailing : Float64 = 0.0,
    bottom : Float64 = 0.0,
    leading : Float64 = 0.0

  # Phase 10B.2b — Custom accessibility action surfaced to assistive tech
  # (VoiceOver / TalkBack / NSAccessibility). Each action carries a
  # human-readable `name` (announced by the screen reader as a verb
  # users invoke via the rotor / actions menu) plus a `callback` Proc
  # invoked when the user activates the action.
  #
  # Per-platform mapping:
  #   - UIKit  -> `UIAccessibilityCustomAction(name:target:selector:)`
  #              array passed to `setAccessibilityCustomActions:`.
  #   - AppKit -> `NSAccessibilityCustomAction(name:handler:)` array
  #              passed to `setAccessibilityCustomActions:`. Available
  #              on macOS 10.13+.
  #   - Web    -> emits `data-ax-actions="action1,action2"` plus a
  #              `data-ax-action-N-token="<n>"` attribute per action so
  #              a JS shim can dispatch keystroke-driven custom actions.
  #              The element is ensured focusable when actions exist.
  #   - Android -> best-effort `AccessibilityNodeInfo.addAction` via the
  #              accessibility delegate. JNI surface is documented as a
  #              deferred limitation when the bridge entry point is not
  #              wired (10B.2b iter 1 ships the Crystal-side data path
  #              and a stub log call).
  class AccessibilityAction
    getter name : String
    getter callback : Proc(Nil)

    def initialize(@name : String, &block : -> Nil)
      @callback = block
    end

    # Spec convenience — constructs an action that records its
    # invocation onto the given Channel/Array. Mostly used by tests
    # so the Crystal-side surface stays plain.
    def self.new(name : String, callback : Proc(Nil)) : AccessibilityAction
      new(name) { callback.call }
    end

    # Invoke the underlying callback. Renderers / dispatchers call this
    # from the native action trampoline.
    def call : Nil
      @callback.call
    end
  end

  # Phase 10B.2b — Keyboard shortcut binding for a view. The `key` is a
  # single character (or a special key name like `:return`, `:escape`,
  # `:tab`, `:up`, `:down`, `:left`, `:right`, `:space`, `:delete`,
  # `:backspace`, `:f1`...`:f12`). `modifiers` is a set of modifier
  # symbols: `:command`, `:control`, `:option` / `:alt`, `:shift`.
  #
  # Per-platform mapping:
  #   - Web    -> `accesskey` attribute (single character only) plus a
  #              `data-keyboard-shortcut` attribute carrying the full
  #              canonical string ("Cmd+Shift+P") for JS handlers that
  #              want richer dispatch.
  #   - UIKit  -> `UIKeyCommand` entries pushed onto the view's
  #              `keyCommands` (we maintain an Objective-C side list
  #              via `apsk_view_add_key_command`).
  #   - AppKit -> on `NSButton`-like controls we set `keyEquivalent` +
  #              `keyEquivalentModifierMask` directly. Non-control views
  #              fall through.
  #   - Android -> no first-class analog beyond `View.setOnKeyListener`;
  #              documented as a deferred limitation.
  struct KeyboardShortcut
    getter key : String
    getter modifiers : Array(Symbol)

    def initialize(key : String | Symbol, @modifiers : Array(Symbol) = [] of Symbol)
      @key = key.to_s
    end

    # Canonical "Cmd+Shift+P"-style label. Renderers / specs can use
    # this directly without re-implementing the join. Modifier ordering
    # matches macOS HIG: Control, Option, Shift, Command.
    def canonical : String
      parts = [] of String
      parts << "Control" if @modifiers.includes?(:control)
      parts << "Option" if @modifiers.includes?(:option) || @modifiers.includes?(:alt)
      parts << "Shift" if @modifiers.includes?(:shift)
      parts << "Command" if @modifiers.includes?(:command) || @modifiers.includes?(:cmd)
      parts << @key
      parts.join("+")
    end

    # Single-character "access key" used by HTML's `accesskey` attribute.
    # Returns the first character of `key` when `key` is a printable
    # single-character string; nil for named keys like `:return`.
    def accesskey_char : String?
      return nil if @key.size != 1
      @key
    end

    # UIKit `UIKeyModifierFlags` bitmask. Bit positions per the
    # UIKit public header:
    #   UIKeyModifierAlphaShift = 1 << 16
    #   UIKeyModifierShift      = 1 << 17
    #   UIKeyModifierControl    = 1 << 18
    #   UIKeyModifierAlternate  = 1 << 19
    #   UIKeyModifierCommand    = 1 << 20
    #   UIKeyModifierNumericPad = 1 << 21
    def uikit_modifier_mask : UInt64
      mask = 0_u64
      mask |= (1_u64 << 17) if @modifiers.includes?(:shift)
      mask |= (1_u64 << 18) if @modifiers.includes?(:control)
      mask |= (1_u64 << 19) if @modifiers.includes?(:option) || @modifiers.includes?(:alt)
      mask |= (1_u64 << 20) if @modifiers.includes?(:command) || @modifiers.includes?(:cmd)
      mask
    end

    # AppKit `NSEventModifierFlags`. Bit positions per AppKit header:
    #   NSEventModifierFlagShift   = 1 << 17
    #   NSEventModifierFlagControl = 1 << 18
    #   NSEventModifierFlagOption  = 1 << 19
    #   NSEventModifierFlagCommand = 1 << 20
    # (Same bit layout as UIKit for the four general modifiers.)
    def appkit_modifier_mask : UInt64
      uikit_modifier_mask
    end
  end

  # Abstract base class for all UI views.
  #
  # Crystal prohibits recursive structs, so View must be a class.
  # VStack/HStack/ZStack children arrays contain View references,
  # creating a recursive type relationship.
  abstract class View
    # Optional identifier for this view, used for lookup and testing
    property id : String? = nil

    # Accessibility label read by screen readers
    property accessibility_label : String? = nil

    # Phase 10B.2a — Supplemental hint announced after the label, used to
    # explain *what activating this element does* (e.g. "Double-tap to
    # open settings"). Web maps to `aria-describedby` (or `aria-description`
    # when the hint stands alone); UIKit maps to `accessibilityHint`;
    # AppKit maps to `setAccessibilityHelp:` (the closest AppKit equivalent
    # — AppKit lacks a first-class hint slot). Android concatenates the
    # hint onto `contentDescription` with a separator since Android's AX
    # API surfaces a single string per view.
    property accessibility_hint : String? = nil

    # Phase 10B.2a — Explicit semantic role for assistive tech. When `nil`
    # the View's `accessibility_role` getter falls back to the widget
    # subclass's `default_accessibility_role`. Set explicitly to override
    # the default (e.g. a `UI::Label` acting as a section header should set
    # `accessibility_role = :header`).
    #
    # Canonical role symbols (per-platform mapping table lives in the
    # phase 10B.2a close handoff):
    #   :button   :link        :text        :header     :image
    #   :tab      :tab_list    :tab_panel   :list       :list_item
    #   :checkbox :radio       :switch      :slider     :progress_bar
    #   :search   :dialog      :alert       :menu       :menu_item
    #   :none     — explicit "no role" (web emits `role="none"`).
    property accessibility_role : Symbol? = nil

    # Phase 10B.2a — UIKit-style traits surfaced to assistive tech as a
    # set of capability flags. Examples:
    #   :selected         — the element is in a selected state
    #   :not_enabled      — the element is non-interactive
    #   :plays_sound      — activating the element produces audio
    #   :starts_media     — activating begins media playback
    #   :causes_page_turn — activating navigates to a new screen
    #   :updates_frequently — value changes rapidly (announce sparingly)
    #
    # Per-platform mapping:
    #   UIKit  — bitwise OR of UIAccessibilityTraits values.
    #   AppKit — best-effort via `setAccessibilityCustomRole` /
    #            `setAccessibilitySelected:`; unmapped traits fall through.
    #   Web    — mapped to `aria-selected`, `aria-disabled`, etc. where
    #            an analog exists.
    #   Android — applied via `AccessibilityNodeInfo` flags where supported.
    property accessibility_traits : Array(Symbol) = [] of Symbol

    # Phase 10B.2a — Current value as a human-readable string. Used by
    # screen readers when the role implies a value (slider, progress,
    # toggle, segmented control). Examples: `"On"`, `"75%"`, `"3 of 7"`.
    # Web emits `aria-valuetext`; UIKit emits `accessibilityValue`;
    # AppKit emits `setAccessibilityValue:`; Android emits
    # `setStateDescription` (API 30+; older versions silently no-op).
    property accessibility_value : String? = nil

    # Phase 10B.2a — Stable identifier surfaced to platform AX trees for
    # automated UI testing. This is intentionally distinct from `test_id`:
    #   - `test_id` is the asset_pipeline / AXTest convention; the AppKit
    #     and UIKit renderers historically map it to `accessibilityIdentifier`.
    #   - `accessibility_identifier` is the explicit XCTest /
    #     Espresso-friendly slot. When both are set, the explicit
    #     `accessibility_identifier` wins on AppKit and UIKit.
    #   - Web emits both as `data-testid` (test_id) and
    #     `data-accessibility-id` (accessibility_identifier) so test
    #     drivers that already query the latter don't break.
    property accessibility_identifier : String? = nil

    # Phase 10B.2b — Custom accessibility actions surfaced to assistive
    # tech. Each action carries a human-readable name and a callback.
    # See `UI::AccessibilityAction`. Renderers walk this array and
    # emit per-platform custom actions (UIKit `UIAccessibilityCustomAction`,
    # AppKit `NSAccessibilityCustomAction`, web data-attribute hooks,
    # Android best-effort).
    property accessibility_actions : Array(AccessibilityAction) = [] of AccessibilityAction

    # Phase 10B.2b — Requests that the view receive focus on render. When
    # toggled true (e.g. via a controller reaction), the matching native
    # renderer calls `becomeFirstResponder` / `makeFirstResponder:` /
    # `requestFocus()` on the resolved native view. Web emits an
    # `autofocus` attribute on form controls and a `data-focused="true"`
    # hook for non-form elements that a JS shim can act on.
    property focused : Bool = false

    # Phase 10B.2b — Whether this view participates in keyboard focus
    # traversal. `nil` means "use the widget's default" (interactive
    # widgets default to focusable, layout primitives to non-focusable).
    # Set explicitly to override. Web emits `tabindex="0"` (focusable)
    # or `tabindex="-1"` (programmatic-focus-only). Native renderers
    # call `setIsAccessibilityElement:` / `setFocusable` to reflect the
    # choice.
    property focusable : Bool? = nil

    # Phase 10B.2b — Explicit tab order index. Web emits `tabindex="<n>"`.
    # On native platforms `tab_index` is advisory because keyboard
    # traversal order is determined by the platform's focus engine; we
    # surface the value in `accessibility_identifier` test attribute
    # form so XCUITest / Espresso can introspect intent.
    property tab_index : Int32? = nil

    # Phase 10B.2b — Keyboard shortcut binding. See `UI::KeyboardShortcut`.
    # Web emits an `accesskey` attribute plus a `data-keyboard-shortcut`
    # canonical string. UIKit and AppKit thread the modifier mask into
    # the platform's key command / key equivalent APIs.
    property keyboard_shortcut : KeyboardShortcut? = nil

    # Chainable convenience setter: `view.with_keyboard_shortcut("S",
    # modifiers: [:command])`. Returns `self`.
    def with_keyboard_shortcut(key : String | Symbol, modifiers : Array(Symbol) = [] of Symbol) : self
      @keyboard_shortcut = KeyboardShortcut.new(key, modifiers)
      self
    end

    # Phase 10B.2b — Per-widget default for `focusable` when the caller
    # leaves the property at `nil`. Interactive subclasses (`Button`,
    # `TextField`, `Toggle`, …) override this to return `true`; layout
    # primitives and decorative views return `false`. The
    # `effective_focusable` getter applies the precedence.
    def default_focusable : Bool
      false
    end

    # Phase 10B.2b — Resolved focusability: explicit `focusable` when
    # set, otherwise the subclass default. Renderers MUST call this
    # method rather than read `@focusable` directly so the default-
    # inference path runs.
    def effective_focusable : Bool
      f = @focusable
      f.nil? ? default_focusable : f
    end

    # Phase 10B.2b — Resolved tab-index emission. Returns the explicit
    # `tab_index` when the caller set one. When `focusable` was
    # explicitly set to `false` on a widget whose default is focusable,
    # returns `-1` so the renderer can opt the element out of tab
    # traversal. Otherwise returns `nil` and the renderer skips the
    # `tabindex` attribute — HTML form controls already have an
    # implicit tab order, so unconditional `tabindex="0"` emission
    # would just produce noise.
    def effective_tab_index : Int32?
      if t = @tab_index
        return t
      end
      # Explicit opt-out: focusable was set to false but the widget
      # default is true (or vice versa needs explicit override).
      if @focusable == false && default_focusable
        return -1
      end
      # Explicit opt-in on a widget whose default is non-focusable —
      # emit tabindex="0" so the browser puts it in the tab order.
      if @focusable == true && !default_focusable
        return 0
      end
      nil
    end

    # Phase 10B.2a — Per-widget default semantic role. Subclasses override
    # to return the role symbol that matches the widget's HIG semantics.
    # The base default is `nil`, which on web emits no `role=` attribute
    # (the HTML tag's intrinsic role wins). The `accessibility_role`
    # getter is overridden via `effective_accessibility_role` so callers
    # never need to pick between the explicit and default channels.
    def default_accessibility_role : Symbol?
      nil
    end

    # Phase 10B.2a — The resolved role: the explicitly set
    # `accessibility_role`, falling back to the subclass's
    # `default_accessibility_role`. Renderers MUST call this method
    # instead of reading the raw `accessibility_role` property so the
    # default-role inference path runs.
    def effective_accessibility_role : Symbol?
      @accessibility_role || default_accessibility_role
    end

    # Padding around the view content
    property padding : EdgeInsets = EdgeInsets.new

    # Background color, nil means transparent/inherited
    property background : Color? = nil

    # Optional brand fill; when present it replaces the plain background fill.
    property background_fill_color : SurfaceColor? = nil

    # Optional two-or-more-stop background gradient.
    property linear_gradient : LinearGradient? = nil

    # Additional inset and drop shadows. The legacy single shadow properties
    # remain supported and are combined with these values by each renderer.
    property list_of_inner_shadows : Array(InnerShadow) = [] of InnerShadow
    property list_of_drop_shadows : Array(DropShadow) = [] of DropShadow

    # Optional generated surface grain.
    property texture_overlay : TextureOverlay? = nil

    # Opt-in hover and press treatment. The default leaves native/web behavior
    # unchanged.
    property interaction_feedback : InteractionFeedback = InteractionFeedback::None

    # Forces the displayed interaction phase for component previews. None keeps
    # platform event handling and focus behavior unchanged.
    property preview_state : PreviewState = PreviewState::None

    # Whether the view is hidden from display
    property hidden : Bool = false

    # Opacity from 0.0 (fully transparent) to 1.0 (fully opaque)
    property opacity : Float64 = 1.0

    # Shape modifiers
    property corner_radius : Float64 = 0.0
    property clip_to_bounds : Bool = false

    # When true this view (and its subtree) is invisible to hit-testing:
    # UIKit gets userInteractionEnabled=false, web gets pointer-events:none.
    # For informational overlays (badges, ribbons) stacked over interactive
    # content — a full-screen overlay view otherwise SWALLOWS every touch on
    # native platforms even though clicks pass through in a browser (root
    # cause of the 2026-07-23 dead-tap bug in the demo shell).
    property touch_passthrough : Bool = false

    # Shadow modifier
    property shadow_radius : Float64 = 0.0
    property shadow_color : Color? = nil
    property shadow_offset_x : Float64 = 0.0
    property shadow_offset_y : Float64 = 0.0

    # Serialize only explicitly selected surface-craft modifiers for the
    # shared SwiftUI facade path. A nil result preserves the facade defaults.
    def surface_craft_json : String?
      return nil if background_fill_color.nil? && linear_gradient.nil? &&
                    list_of_inner_shadows.empty? && list_of_drop_shadows.empty? &&
                    texture_overlay.nil? && interaction_feedback == InteractionFeedback::None &&
                    preview_state == PreviewState::None

      style = SurfaceStyle.new(
        background_fill_color: background_fill_color,
        linear_gradient: linear_gradient,
        list_of_inner_shadows: list_of_inner_shadows,
        list_of_drop_shadows: list_of_drop_shadows,
        texture_overlay: texture_overlay,
      )
      SurfaceCraftEncoding.style_json(style, interaction_feedback, preview_state)
    end

    # Border modifier
    property border_width : Float64 = 0.0
    property border_color : Color? = nil

    # Blur modifier
    property blur_radius : Float64 = 0.0

    # Size constraints
    property minimum_width : Float64? = nil
    property minimum_height : Float64? = nil
    property maximum_width : Float64? = nil
    property maximum_height : Float64? = nil

    # Fluid (responsive) size constraints. When set, the web renderer emits a
    # `width: clamp(min, ideal, max)` (resp. `height:`) declaration instead of
    # the literal `minimum_*` / `maximum_*` pair. Native renderers will adopt
    # platform-idiomatic size class translations in later phases.
    property fluid_width : UI::Fluid? = nil
    property fluid_height : UI::Fluid? = nil

    # Container query name. When set, the web renderer emits
    # `container-type: inline-size; container-name: <name>` on the element so
    # nested `@container <name> (...)` blocks resolve against this view's box
    # rather than the viewport.
    property container_query_name : String? = nil

    # Test identifier for automated UI testing, maps to native test attributes
    property test_id : String? = nil

    # Phase 6.10 Rem 4 (Item 2D) — root-fill flag.
    #
    # When `true`, the renderer treats this view as a full-screen root
    # and:
    #   - iOS: pins the view's width to the device screen width and lets
    #     its height grow (or scroll if content exceeds it). Replaces the
    #     brittle hardcoded `content_width = 340.0` pattern.
    #   - macOS: adds only a SOFT upper cap at the metric width (priority
    #     500), NOT an exact width pin. The actual fill comes from the host
    #     installing the rendered content pinned to the window's content
    #     area (`objc_install_content_view` for capture windows /
    #     `objc_window_set_filling_content_view` for interactive windows).
    #     An exact pin here would force a resizable window to the metric
    #     width and lock horizontal resize (the window's size is a free
    #     variable Auto Layout will grow to satisfy a near-required pin —
    #     see commit "fix(macos): window opened at screen width"). Hosts
    #     that set their contentView via raw `setContentView:` without
    #     pinning MUST migrate to `objc_window_set_filling_content_view`
    #     for `root_fill` to fill; otherwise the view hugs its content.
    #   - Web: emits `min-height: 100dvh` + `width: 100%` (CSS dvh
    #     respects mobile address-bar resizing).
    #
    # Set via `view.root_fill = true` or the chainable shortcut
    # `view.fill_screen!` (returns self for chaining).
    #
    # The renderer-side honoring is best-effort — a `root_fill` view
    # nested deep inside another stack is still constrained by its
    # parent's bounds. The intent is the OUTER root of an iOS / macOS
    # screen.
    property root_fill : Bool = false

    # Chainable shortcut for `self.root_fill = true`. Returns self.
    def fill_screen! : self
      @root_fill = true
      self
    end

    # Cross-platform "flex-grow": when `true`, this view GROWS to fill the remaining
    # space along its containing stack's main axis (the horizontal axis of an `HStack`).
    # It becomes the row's flexible absorber, the way a `Spacer` does — but as a real
    # control (e.g. a compose `TextField` that expands to fill the row beside a
    # fixed-size send button). Without an absorber, a horizontal row of fixed-width
    # children over-constrains UIKit's Fill distribution and the row mispositions.
    #
    # Renderer mapping: AppKit / UIKit lower the view's horizontal content-hugging
    # priority (so the stack stretches it); the web renderer emits `flex: 1`. Do NOT
    # combine with an exact width pin (`minimum_width == maximum_width`) — the pin wins
    # and defeats the grow.
    property fill_horizontal : Bool = false

    # Chainable shortcut for `self.fill_horizontal = true`. Returns self.
    def grow! : self
      @fill_horizontal = true
      self
    end

    # SwiftKit reactive-state opaque pointer (Phase 3 Remediation 4).
    #
    # Populated by the AppKit / UIKit renderer's visit method for views
    # that participate in the reactive surface (today: `UI::Label`,
    # `UI::Button`, `UI::Toggle`, `UI::Slider`). It mirrors the same
    # pointer held on the underlying `NativeHandle` so Crystal-side widget
    # mutators (e.g. `UI::Label#text=`) can dispatch through
    # `LibSwiftKitBridge.apsk_*_set_*` without having to thread the
    # `NativeHandle` back to user code. Nil for views that haven't been
    # rendered yet, weren't rendered by a SwiftKit renderer (Web /
    # Android), or aren't reactive widgets.
    #
    # Lifetime: the pointer is +1 retained on the Swift side. The
    # `NativeHandle.release!` path drops the retain via
    # `apsk_state_release`; the View doesn't need to participate.
    property swiftkit_state_handle : Pointer(Void)? = nil

    # Chainable setter: set a fluid horizontal size. Accepts CSS-compatible
    # strings (e.g. `"60vw"`, `"20rem"`) or numeric pixel values, which are
    # emitted as `Npx`. Returns `self` so calls can be chained.
    def fluid_width(min : String | Number, ideal : String | Number, max : String | Number) : self
      @fluid_width = UI::Fluid.new(
        min: coerce_fluid_size(min),
        ideal: coerce_fluid_size(ideal),
        max: coerce_fluid_size(max),
      )
      self
    end

    # Chainable setter: set a fluid vertical size. See `fluid_width`.
    def fluid_height(min : String | Number, ideal : String | Number, max : String | Number) : self
      @fluid_height = UI::Fluid.new(
        min: coerce_fluid_size(min),
        ideal: coerce_fluid_size(ideal),
        max: coerce_fluid_size(max),
      )
      self
    end

    # Chainable setter: mark this view as a container-query root. Renderers
    # that support container queries emit `container-type: inline-size` and
    # `container-name: <name>` on this element so descendant rules of the
    # form `@container <name> (min-width: ...)` resolve against this box.
    def container_query(name : String) : self
      @container_query_name = name
      self
    end

    # -------------------------------------------------------------------------
    # Discrete gesture surface — swipe (4 directions) + long-press.
    #
    # "Discrete" means each recognizer fires once per completed gesture: a
    # swipe fires when the finger lifts in the recognized direction; a long-
    # press fires when the hold threshold is crossed. Continuous pan/drag
    # tracking is intentionally out of scope.
    #
    # Per-platform behavior:
    #   UIKit  — UISwipeGestureRecognizer (per direction) + UILongPressGestureRecognizer.
    #            cancelsTouchesInView is left at the default (YES) for swipe, set
    #            to NO for long-press so child buttons still fire on tap.
    #   AppKit — NSPanGestureRecognizer classifies direction at .ended by the
    #            dominant translation component (threshold 30 pt). A separate
    #            NSPressGestureRecognizer backs long-press.
    #   Web    — no-op; both handler types are silently ignored.
    # -------------------------------------------------------------------------

    # Swipe handler storage. Lazily initialized on first registration.
    # Direction is the key; only the last-registered handler per direction
    # is kept (matches UIKit's one-recognizer-per-direction model).
    @swipe_handlers : Hash(SwipeDirection, Proc(Nil))? = nil

    # Returns the swipe handler map, nil when no handlers have been registered.
    # Renderers walk registered directions without forcing allocation.
    def swipe_handlers : Hash(SwipeDirection, Proc(Nil))?
      @swipe_handlers
    end

    # Register a swipe handler for `direction`. Replaces any previously
    # registered handler for the same direction. The block is invoked on the
    # main thread when the platform recognizer fires.
    def on_swipe(direction : SwipeDirection, &block : -> Nil) : Nil
      map = @swipe_handlers ||= Hash(SwipeDirection, Proc(Nil)).new
      map[direction] = block
    end

    # Optional long-press callback. When non-nil the renderer attaches a
    # long-press gesture recognizer (minimum hold: 0.5 s) whose action
    # invokes this proc. The proc runs on the main thread.
    property on_long_press : Proc(Nil)? = nil

    # Convenience block-based setter. Equivalent to assigning `on_long_press`
    # directly but avoids the explicit Proc wrapper at call sites.
    def on_long_press(&block : -> Nil) : Nil
      @on_long_press = block
    end

    # Accept a platform visitor for rendering dispatch.
    # Each concrete view type calls `visitor.visit(self)`.
    abstract def accept(visitor : PlatformVisitor)

    # ------------------------------------------------------------------
    # In-place reconciliation hooks (iOS Rerender focus preservation).
    #
    # The reconciler walks a freshly-built view tree against the mounted
    # native tree, aligning by position. `reconcile_kind` must equal the
    # `NativeView#view_kind` the renderer stamped for this view's native
    # node; `reconcile_children` must return this view's children in the
    # SAME order the renderer adds native children. The default is a leaf
    # with no children — containers override `reconcile_children`. Any
    # mismatch (kind or child count) makes the reconciler abort to the
    # safe destructive render path, so an unhandled container/widget is
    # never silently mis-reconciled — it just falls back.
    # ------------------------------------------------------------------
    def reconcile_kind : String
      self.class.name
    end

    def reconcile_children : Array(View)
      [] of View
    end

    # Phase 10B.0 — declare which capabilities this view class supports
    # for a given Tier 2 intent. Used by `UI::WidgetRoute::Registry` to
    # validate overrides at registration time. Subclasses call this
    # exactly once per intent they claim to satisfy:
    #
    #     class UI::SwipeActionRow < UI::View
    #       declares_capabilities :swipe_actions, {
    #         supports_edge_trailing: true,
    #         supports_role_destructive: {ios: true, macos: false, web_wide: true},
    #         supports_role_default: true,
    #       }
    #     end
    #
    # # Capability value shapes (Phase 10B.1b)
    #
    # * `true` — full support on every platform the intent can resolve to.
    # * `false` — no support anywhere (declarative "I do not back this").
    # * `:partial` — fuzzy legacy "some platforms, unspecified." Accepted
    #   for back-compat but the 10B.1b audit prefers explicit Hash form
    #   below.
    # * `Hash(Symbol, Bool)` — platform-keyed support map. Keys are
    #   platform symbols (`:ios`, `:ipados`, `:macos`, `:web_wide`,
    #   `:web_narrow`, `:android`); the value is whether the renderer for
    #   that platform actually backs the capability. `UI::WidgetRoute::Registry`
    #   walks this hash at registration time to detect "claims iOS but
    #   rendered on macOS" mismatches, and again at resolve time when
    #   `capabilities_required:` is passed to `UI::WidgetRoute.resolve`.
    #
    # Both NamedTuple shorthand (`{ios: true, macos: false}`) and rocket-
    # style HashLiteral (`{:ios => true, :macos => false}`) are accepted
    # for the per-capability platform map. They produce the same
    # `Hash(Symbol, Bool)` at the cap site.
    #
    # The macro emits a class-level hook method
    # `_declare_capabilities_for_intent_<intent_id>` that runs the
    # `UI::WidgetRoute::Registry.declare_widget_capabilities` write. Like
    # `UI::App`'s `_bootstrap_screen_*` pattern, method definitions are
    # compile-time-emitted code, unaffected by the iOS class-init gap
    # (see [[project_crystal_ios_class_init_gap]]). The class-load side
    # effect of invoking the named method then writes the capability
    # bag into the registry.
    macro declares_capabilities(intent_id, capabilities)
      def self._declare_capabilities_for_intent_{{intent_id.id}} : Nil
        caps = {} of Symbol => ::UI::WidgetRoute::Registry::CapabilityValue
        {% for key, value in capabilities %}
          {% if value.is_a?(HashLiteral) || value.is_a?(NamedTupleLiteral) %}
            _cap_h_{{intent_id.id}}_{{key.id}} = {} of Symbol => Bool
            {% for plat_key, plat_value in value %}
              {% if plat_key.is_a?(SymbolLiteral) %}
                # Rocket-style HashLiteral key (e.g. `:ios => true`) is
                # already a SymbolLiteral. Emit it directly — calling
                # `.symbolize` would wrap it as `:":ios"`, which then
                # never matches a `:ios` lookup downstream.
                _cap_h_{{intent_id.id}}_{{key.id}}[{{plat_key}}] = {{plat_value}}
              {% else %}
                # NamedTupleLiteral key (`ios: true`) arrives as a
                # MacroId; symbolize it into `:ios`.
                _cap_h_{{intent_id.id}}_{{key.id}}[{{plat_key.symbolize}}] = {{plat_value}}
              {% end %}
            {% end %}
            caps[{% if key.is_a?(SymbolLiteral) %}{{key}}{% else %}{{key.symbolize}}{% end %}] = _cap_h_{{intent_id.id}}_{{key.id}}
          {% else %}
            caps[{% if key.is_a?(SymbolLiteral) %}{{key}}{% else %}{{key.symbolize}}{% end %}] = {{value}}
          {% end %}
        {% end %}
        ::UI::WidgetRoute::Registry.declare_widget_capabilities(
          {{@type}},
          {{intent_id}},
          caps,
        )
        nil
      end

      # Class-load side effect: register the declaration eagerly. iOS
      # embedding may skip this write (class-init gap). The named
      # method above is the recovery hatch — re-running it from a
      # framework bootstrap routine restores the declaration.
      _declare_capabilities_for_intent_{{intent_id.id}}
    end

    # Coerce a fluid size argument into its CSS string form. Numbers are
    # treated as pixel values; strings pass through unchanged.
    private def coerce_fluid_size(value : String | Number) : String
      case value
      when Number then "#{value}px"
      else             value.to_s
      end
    end
  end
end
