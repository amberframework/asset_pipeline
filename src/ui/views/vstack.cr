# Vertical stack that arranges children top-to-bottom with configurable spacing.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A vertical stack layout that arranges children top to bottom.
  #
  # Children are laid out sequentially along the vertical axis
  # with configurable spacing and alignment.
  class VStack < View
    # The HIG-conformant default vertical rhythm for stacked form
    # content. Phase 6.10 Rem 1 raised this from 8pt to 12pt because
    # 8pt produced visually-overlapping form fields on iOS (the
    # owner's hands-on report on iPhone 17 showed email + password
    # fields colliding with no air between them). 12pt matches the
    # default `Form { ... }` row separator distance Apple ships and
    # is the floor designers reach for when there's no explicit
    # rhythm to honor. App authors override per-stack as needed.
    DEFAULT_SPACING_PT = 12.0

    # Spacing between children in points
    property spacing : Float64 = DEFAULT_SPACING_PT

    # Horizontal alignment of children within the stack
    property alignment : Alignment = Alignment::Center

    # Ordered list of child views
    getter children : Array(View) = [] of View

    def initialize(@spacing : Float64 = DEFAULT_SPACING_PT, @alignment : Alignment = Alignment::Center)
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
