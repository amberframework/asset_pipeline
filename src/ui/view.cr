# Defines `UI::View`, the abstract base for every cross-platform view, plus the
# `RenderContext` and `RenderError` types used by the platform-visitor renderers.

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

  # Phase 8A — Renderer-scoped per-request context threaded through
  # `UI::Web::Renderer#render(view, render_context:)`. Carries values
  # the web visit methods need but that don't belong on the view tree
  # itself (e.g. the CSRF token for `UI::Form`'s hidden-input
  # injection).
  #
  # Lives in the core `UI` namespace (rather than the Amber integration
  # file) so the web renderer can read it without requiring the Amber
  # integration to be loaded. Apps not using Amber simply pass a fresh
  # `RenderContext.empty` or omit the argument.
  struct RenderContext
    getter csrf_token : String?

    def initialize(@csrf_token : String? = nil)
    end

    def self.empty : RenderContext
      new(csrf_token: nil)
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

  # Style for progress indicators
  enum ProgressStyle
    Linear   # Horizontal progress bar
    Circular # Spinning circular progress
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

    # Padding around the view content
    property padding : EdgeInsets = EdgeInsets.new

    # Background color, nil means transparent/inherited
    property background : Color? = nil

    # Whether the view is hidden from display
    property hidden : Bool = false

    # Opacity from 0.0 (fully transparent) to 1.0 (fully opaque)
    property opacity : Float64 = 1.0

    # Shape modifiers
    property corner_radius : Float64 = 0.0
    property clip_to_bounds : Bool = false

    # Shadow modifier
    property shadow_radius : Float64 = 0.0
    property shadow_color : Color? = nil
    property shadow_offset_x : Float64 = 0.0
    property shadow_offset_y : Float64 = 0.0

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
    #   - iOS / macOS: pins the view's width to the device screen width
    #     and lets its height grow to the screen height (or scroll if
    #     content exceeds it). Replaces the brittle hardcoded
    #     `content_width = 340.0` pattern.
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

    # Accept a platform visitor for rendering dispatch.
    # Each concrete view type calls `visitor.visit(self)`.
    abstract def accept(visitor : PlatformVisitor)

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
