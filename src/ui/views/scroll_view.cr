# Single-axis or two-axis scrolling viewport wrapping a content view.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
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

    def initialize(@content : View? = nil)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
