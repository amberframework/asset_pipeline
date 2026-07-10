# Navigation affordance that pushes a destination onto the navigation stack.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A tappable element that pushes a destination view onto a NavigationStack.
  #
  # On iOS: pushes via UINavigationController
  # On macOS: pushes onto stack or opens in detail pane
  # On Android: navigates to fragment
  # On Web: renders as <a> with SPA routing
  class NavigationLink < View
    # Text label for the link
    property label : String

    # The destination view to push when tapped
    property destination : View

    # Optional icon name
    property icon : String? = nil

    # Whether to show a disclosure indicator (chevron)
    property shows_disclosure : Bool = true

    def initialize(@label : String, @destination : View)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
