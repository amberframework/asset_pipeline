# List row with edge-swipe revealed actions (leading / trailing).
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A single swipe action attached to a SwipeActionRow.
  #
  # On iOS / mobile-web: revealed by swiping the row horizontally.
  # On macOS / desktop-web: rendered inline as a visible trailing button.
  #
  # `role` accepts `:default`, `:destructive`, `:cancel`. The renderer maps
  # destructive to the platform-native danger tint (red on iOS / macOS /
  # web via `--ap-color-danger-text`).
  #
  # `icon` is the SF Symbol name on iOS / macOS, ignored elsewhere.
  #
  # `on_tap` is the callback fired when the user activates the action.
  # On iOS / macOS it's registered through the existing Phase 3
  # CallbackRegistry so the Crystal Proc isn't GC'd while native code
  # holds a function pointer to it.
  class SwipeAction
    property label : String
    property role : Symbol
    property icon : String?
    property on_tap : Proc(Nil)?

    # Optional route id the web renderer wires to a client-side
    # UIRouteHost.push() invocation. The static-site web target
    # cannot invoke Crystal Procs client-side, so demos that need
    # runtime swipe-button interactivity supply this string.
    property on_tap_route : String?

    def initialize(
      @label : String,
      @on_tap : Proc(Nil)? = nil,
      @role : Symbol = :default,
      @icon : String? = nil,
      @on_tap_route : String? = nil,
    )
    end
  end

  # A list row with optional leading + trailing swipe actions.
  #
  # On iOS / UIKit: SwiftUI `.swipeActions(edge: .trailing) { ... }` and
  #                 `.swipeActions(edge: .leading) { ... }` modifiers.
  # On macOS / AppKit: visible HStack of trailing buttons (HIG — macOS
  #                    doesn't have swipe-to-reveal; an explicit row
  #                    affordance is the idiomatic equivalent).
  # On web desktop:    visible HStack of trailing buttons (same as macOS).
  # On web mobile:     touch-event handler that translates the row on
  #                    touchmove and reveals the trailing-actions panel.
  #
  # The `content` view is the primary row content (typically an HStack
  # with a label + meta info). Actions are flat lists; the renderer
  # builds platform-appropriate chrome around them.
  #
  # Example:
  #   row = UI::SwipeActionRow.new(content_view)
  #   row.trailing_actions = [
  #     UI::SwipeAction.new("Edit") { open_editor(item) },
  #     UI::SwipeAction.new("Delete", role: :destructive) { delete(item) },
  #   ]
  class SwipeActionRow < View
    property content : View
    property leading_actions : Array(SwipeAction)
    property trailing_actions : Array(SwipeAction)

    # Mobile-web breakpoint: viewports below this width get touch-swipe
    # chrome; viewports at/above this width get visible trailing
    # buttons. Defaults to 768px (tablet-portrait boundary).
    property mobile_breakpoint_px : Int32 = 768

    def initialize(@content : View)
      @leading_actions = [] of SwipeAction
      @trailing_actions = [] of SwipeAction
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
