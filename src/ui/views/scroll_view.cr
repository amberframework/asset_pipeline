# Single-axis or two-axis scrolling viewport wrapping a content view.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Scroll-position primitives (macOS). These C symbols are defined in
  # objc_bridge.m and linked into the app; declaring them here (in addition to
  # the renderer's LibObjCBridge) lets a ScrollView drive its own scroll
  # position after render without a require cycle back into the renderer.
  {% if flag?(:macos) %}
    lib LibScrollViewBridge
      fun nsscrollview_scroll_to_end(scroll_view : Void*) : Void
      fun nsscrollview_is_at_bottom(scroll_view : Void*, tolerance : Float64) : Int32
    end
  {% end %}

  # A scrollable container for a single child view tree.
  #
  # Wraps content that may exceed the visible area, allowing
  # the user to scroll horizontally, vertically, or both.
  class ScrollView < View
    # The content view (typically a stack)
    property content : View? = nil

    # Whether horizontal scrolling is enabled
    property scroll_horizontal : Bool = false

    # Whether vertical scrolling is enabled
    property scroll_vertical : Bool = true

    # Whether scroll indicators are shown
    property shows_indicators : Bool = true

    # Fixed viewport width in points (0 = unconstrained; the scroll view
    # expands to fill its parent stack along this axis).  Set to a non-zero
    # value when the scroll view must have an explicit width constraint —
    # typically always required when embedding in an NSStackView /
    # UIStackView, because the stack cannot infer the scroll view's preferred
    # cross-axis size from its content alone.
    property frame_width : Float64 = 0.0

    # Fixed viewport height in points (0 = unconstrained).  Always set when
    # embedding in a vertical NSStackView / UIStackView: without an explicit
    # height the stack collapses the scroll view to zero height.
    property frame_height : Float64 = 0.0

    # Fill the flexible VERTICAL space of an enclosing stack instead of taking a
    # fixed `frame_height`. The renderer gives the scroll view the lowest
    # vertical hugging priority so the stack stretches it into the remaining
    # window height; the scroll view then reflows on window resize rather than
    # leaving blank space below a fixed-height pane. When true, `frame_height`
    # is ignored on the vertical axis. (macOS/AppKit; other platforms treat it
    # as a normal flexible child.)
    property fill_vertical : Bool = false

    # The rendered NSScrollView pointer, stored by the renderer so the scroll
    # position can be driven after render (scroll_to_end / at_bottom?) without a
    # tree rebuild — the streaming stick-to-bottom path. nil before render.
    property native_handle : Pointer(Void)? = nil

    def initialize(@content : View? = nil)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    # Scroll to the newest (bottom) content. No-op before render or off-macOS.
    def scroll_to_end : Nil
      {% if flag?(:macos) %}
        if h = @native_handle
          LibScrollViewBridge.nsscrollview_scroll_to_end(h)
        end
      {% end %}
    end

    # Whether the viewport is within `tolerance` points of the bottom edge.
    # Returns true before render / off-macOS (nothing to fight for).
    def at_bottom?(tolerance : Float64 = 24.0) : Bool
      {% if flag?(:macos) %}
        if h = @native_handle
          return LibScrollViewBridge.nsscrollview_is_at_bottom(h, tolerance) == 1
        end
      {% end %}
      true
    end
  end
end
