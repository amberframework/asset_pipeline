# Phase 8B — Action result type hierarchy.
#
# Controllers return one of these subtypes from action methods. The
# `UI::ActionDispatcher` translates the result into a coordinator
# operation (push / pop / replace_root / republish) or an inline render
# emission to the host.
#
# Authors do not construct these directly — the `UI::Controller`
# protected helpers (navigate_to / pop_navigation / render_current_screen
# / replace_root / respond_with) build them on the controller's behalf.

require "../ui"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Abstract base for the ActionResult type hierarchy returned from UI::Controller action methods.
  abstract class ActionResult
    # Navigate to a new route, pushing it on the navigation stack.
    class Navigate < ActionResult
      getter route_id : Symbol
      getter params : Hash(Symbol, String)

      def initialize(@route_id : Symbol, @params : Hash(Symbol, String) = {} of Symbol => String)
      end
    end

    # Pop the top route off the navigation stack (back navigation).
    class Pop < ActionResult
    end

    # Re-render the current route without changing the stack (e.g. after
    # mutating shared state in-place).
    class Rerender < ActionResult
    end

    # Replace the entire navigation stack with a new root (e.g. after
    # sign-in / sign-out).
    class ReplaceRoot < ActionResult
      getter route_id : Symbol
      getter params : Hash(Symbol, String)

      def initialize(@route_id : Symbol, @params : Hash(Symbol, String) = {} of Symbol => String)
      end
    end

    # Render the given view inline (e.g. in a popover / sheet host)
    # without affecting the navigation stack. The host wires a callback
    # via `UI::ActionDispatcher#on_render_inline`.
    class RenderInline < ActionResult
      getter view : UI::View

      def initialize(@view : UI::View)
      end
    end
  end
end
