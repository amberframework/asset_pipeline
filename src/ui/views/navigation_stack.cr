# Push/pop navigation container hosting a sequence of screens.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A navigation container that manages a stack of views with push/pop transitions.
  #
  # On iOS: UINavigationController
  # On macOS: Custom view stack with NSViewController
  # On Android: Fragment backstack
  # On Web: SPA router with browser history
  class NavigationStack < View
    # The root/initial view displayed when no views are pushed
    property root : View

    # Title displayed in the navigation bar
    property title : String? = nil

    # Whether to display the title prominently (large title on iOS)
    property large_title : Bool = false

    # Whether to show the navigation bar
    property shows_navigation_bar : Bool = true

    # Stack of pushed views (managed internally)
    getter stack : Array(View) = [] of View

    def initialize(@root : View, @title : String? = nil)
    end

    # Push a view onto the navigation stack
    def push(view : View)
      @stack << view
    end

    # Pop the top view from the stack (returns it or nil if empty)
    def pop : View?
      @stack.pop?
    end

    # Pop all views and return to root
    def pop_to_root
      @stack.clear
    end

    # The currently visible view (top of stack or root)
    def current_view : View
      @stack.last? || @root
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
