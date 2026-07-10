# Reactive app-level navigation state. Owns the route stack plus on_change
# callbacks that renderers subscribe to in order to rebuild the visible root.

module UI
  # Reactive app-level navigation state.
  #
  # Owns the route stack + on_change callbacks that renderers subscribe to.
  # push / pop / replace_root / pop_to_root mutate state AND fire callbacks
  # synchronously AFTER the mutation, so any subscriber observes the new
  # current route. This is the runtime-navigation substrate Phase 6.10
  # ships — `UI::NavigationStack#push` mutates a `Array(View)` but did NOT
  # fire any callback; renderers therefore had no way to know they should
  # rebuild the visible root. `UI::NavigationCoordinator` closes that gap.
  #
  # Per Phase 6.10 brief decision #3 (architecture choice (a) full root
  # re-render on coordinator change), renderers subscribe via #on_change
  # and on each fire rebuild the platform's content view from the new
  # active route + the shared app state.
  #
  # Per the brief's I-9 invariant + the Crystal iOS class-init gap memory,
  # this class is INSTANCE-level: held by the demo app, not a class var
  # with an initializer that the iOS embedding silently skips. The
  # `@on_change_callbacks` field is a normal instance variable initialised
  # in `#initialize`, NOT a class-var declared with a default value.
  #
  # Example:
  #   coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
  #   coord.on_change { |route| renderer.rebuild_root(route) }
  #   coord.push(UI::NavigationCoordinator::Route.new(:todos))
  #   # subscriber fires; renderer sees route.id == :todos
  #   coord.pop
  #   # subscriber fires again; renderer sees route.id == :sign_in
  class NavigationCoordinator
    # A single navigation destination. `id` identifies the screen; the
    # demo app maps id -> view tree. `params` is an opaque per-route
    # string map for things like "which todo am I editing" (`{id: "42"}`).
    # Kept as String values so the map survives an iOS Swift trampoline
    # round-trip through a C ABI.
    record Route, id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String

    # The full stack, root-first. `routes.last` is the visible route.
    getter routes : Array(Route)

    @on_change_callbacks : Array(Proc(Route, Nil))

    def initialize(root : Route)
      @routes = [root] of Route
      @on_change_callbacks = [] of Proc(Route, Nil)
    end

    # The visible route (top of stack).
    def current : Route
      @routes.last
    end

    # Depth of the stack — `1` means only the root is visible.
    def depth : Int32
      @routes.size
    end

    # Push a new route onto the stack and notify subscribers.
    def push(route : Route) : Nil
      @routes << route
      notify
    end

    # Pop the visible route. Returns the popped route or nil if at root
    # (root cannot be popped — there must always be a visible route).
    def pop : Route?
      return nil if @routes.size <= 1
      popped = @routes.pop
      notify
      popped
    end

    # Pop down to root, clearing every pushed route. Fires exactly one
    # notification if anything was popped.
    def pop_to_root : Nil
      return if @routes.size <= 1
      @routes = [@routes.first]
      notify
    end

    # Replace the entire stack with a single new root. Use after sign-in,
    # sign-out, or any flow where the prior route stack is no longer
    # meaningful (e.g. session reset).
    def replace_root(route : Route) : Nil
      @routes = [route]
      notify
    end

    # Subscribe to coordinator changes. Block receives the new current
    # route. Multiple subscribers are supported (renderer + analytics +
    # logging can all listen). Subscribers are notified in registration
    # order.
    def on_change(&block : Route ->) : Nil
      @on_change_callbacks << block
    end

    # Returns the number of registered subscribers — exposed for specs.
    def subscriber_count : Int32
      @on_change_callbacks.size
    end

    # Phase 6.11 — re-publish the current route without mutating the
    # stack. Useful when the visible screen's underlying state changed
    # (e.g. the user toggled a Todo's completed flag in-row, or deleted
    # a row) and the host needs to rebuild the same route from the new
    # state. Equivalent semantics to push/pop of the same route, minus
    # the stack churn.
    def republish : Nil
      notify
    end

    private def notify : Nil
      current_route = current
      @on_change_callbacks.each { |cb| cb.call(current_route) }
    end
  end
end
