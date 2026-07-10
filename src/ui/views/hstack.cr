# Horizontal stack that arranges children leading-to-trailing with configurable spacing.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A horizontal stack layout that arranges children leading to trailing.
  #
  # Children are laid out sequentially along the horizontal axis
  # with configurable spacing and alignment.
  class HStack < View
    # The HIG-conformant default horizontal rhythm for adjacent
    # controls. Mirrors `UI::VStack::DEFAULT_SPACING_PT` (12pt) for
    # symmetry — controls in a row have the same air as rows in a
    # column. See VStack for the Phase 6.10 Rem 1 rationale.
    DEFAULT_SPACING_PT = 12.0

    # Spacing between children in points
    property spacing : Float64 = DEFAULT_SPACING_PT

    # Vertical alignment of children within the stack
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
