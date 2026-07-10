# Overlay container that layers children along the z-axis.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A z-axis stack that overlays children on top of each other.
  #
  # Children are drawn in order, with later children appearing
  # on top of earlier ones. Alignment controls positioning
  # within the stack bounds.
  class ZStack < View
    # Alignment of children within the overlay
    property alignment : Alignment = Alignment::Center

    # Ordered list of child views (later = on top)
    getter children : Array(View) = [] of View

    def initialize(@alignment : Alignment = Alignment::Center)
    end

    # Append a child view. Returns self for chaining.
    def <<(child : View) : self
      @children << child
      self
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
