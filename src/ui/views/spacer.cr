# Layout-only view that expands to fill remaining space along a stack's axis.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A flexible space that expands to fill available room in a stack.
  #
  # When placed inside a VStack or HStack, Spacer pushes adjacent
  # views apart. An optional `min_length` sets a minimum size.
  class Spacer < View
    # Minimum length of the spacer in points
    property min_length : Float64 = 0.0

    def initialize(@min_length : Float64 = 0.0)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
