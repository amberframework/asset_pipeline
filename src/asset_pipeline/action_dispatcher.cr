# Phase 8B — UI::ActionDispatcher.
#
# The dispatcher is the per-app coordinator that translates user
# actions (Button taps, form submits) into navigation operations or
# inline view renders. It owns:
#
#   * the registered `UI::App` subclass (for screen lookup),
#   * the `UI::NavigationCoordinator` (route stack + on_change),
#   * the `UI::Session` + `UI::Flash` (in-process or app-supplied),
#   * the `UI::DesignTokens::Tokens` (per-app brand),
#   * the CURRENT `UI::FormState` (replaced on every screen mount),
#   * a monotonic `current_mount_token : Int64` (per-mount fresh).
#
# Lifecycle:
#
#   * App startup creates ONE dispatcher and wires
#     `UI::FormState.current = @current_form_state` +
#     `UI::FormState.current_mount_token = 0` (via mount_screen).
#   * Each screen mount calls `dispatcher.mount_screen(route_id)`,
#     which increments the token and allocates a fresh FormState.
#     Renderer hook reads the new current FormState on its next
#     visit pass.
#   * Each Button tap with `action: :submit` invokes
#     `dispatcher.dispatch(action_ref, explicit_params)`. The
#     dispatcher resolves the action_ref to a controller method,
#     runs any before_actions, calls dispatch_action, and translates
#     the returned UI::ActionResult into a coordinator op.
#
# Action refs:
#
#   * `Symbol`: the action runs on the CURRENT screen's controller
#     (looked up via `app.registration_for(coord.current.id)`).
#   * `Tuple(UI::Controller.class, Symbol)`: the action runs on the
#     given controller (e.g. cross-screen action wiring).
#
# Inline render results (UI::ActionResult::RenderInline) emit through
# the dispatcher's `on_render_inline : Proc(UI::View, Nil)?` hook
# rather than the navigation coordinator. macOS/iOS hosts bind to
# this hook for sheet / popover presentation.

require "../ui"
require "./native_app"
require "./native_controller"
require "./native_context"
require "./action_result"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Per-app coordinator that translates UI actions into navigation operations or inline view renders.
  class ActionDispatcher
    getter app : UI::App.class
    getter navigation : UI::NavigationCoordinator
    getter session : UI::Session
    getter flash : UI::Flash
    getter design_tokens : UI::DesignTokens::Tokens
    getter current_form_state : UI::FormState

    # Monotonically-increasing mount token. The dispatcher writes this
    # to `UI::FormState.current_mount_token` on every screen mount so
    # the renderer's stale-callback guard fires correctly.
    getter current_mount_token : Int64

    # Optional callback for `UI::ActionResult::RenderInline` results.
    # The host (macOS / iOS) wires this on startup to present the
    # inline view (e.g. sheet, popover) without disturbing the
    # navigation stack.
    property on_render_inline : Proc(UI::View, Nil)? = nil

    def initialize(
      @app : UI::App.class,
      @navigation : UI::NavigationCoordinator,
      @session : UI::Session,
      @flash : UI::Flash,
      @design_tokens : UI::DesignTokens::Tokens,
    )
      @current_mount_token = 0_i64
      @current_form_state = UI::FormState.new(mount_token: 0_i64)
      sync_renderer_hooks
    end

    # Called when a new screen mounts. Increments the mount token AND
    # creates a new FormState carrying that token. Renderer callbacks
    # captured under the prior token become no-ops (Codex finding #3).
    #
    # Initial form-state values are seeded from the route's params hash
    # (e.g. a `:detail` route's `:id => "42"` ends up as
    # form_state["id"] == "42") — convenient for screens that need to
    # know which row they're showing without the controller pre-pop'ing.
    #
    # The `route` argument is the route being mounted. The caller is
    # responsible for ensuring that this matches what the coordinator
    # will publish (the dispatcher's internal `translate_result` does
    # mount-then-notify to guarantee the renderer's wire-time read of
    # `UI::FormState.current` sees the NEW mount).
    def mount_screen(route : UI::NavigationCoordinator::Route) : Nil
      @current_mount_token += 1
      @current_form_state = UI::FormState.new(mount_token: @current_mount_token)

      # Seed from the route's params (string keys).
      route.params.each do |key, value|
        @current_form_state.register(key.to_s, value)
      end

      sync_renderer_hooks
      nil
    end

    # Convenience overload that resolves the route from the coordinator
    # (the route_id is asserted to match the coord's current route).
    # Useful for `mount_screen(route_id)` callers that have already
    # pushed the route onto the coord and want to mount based on it.
    def mount_screen(route_id : Symbol) : Nil
      current_route = @navigation.current
      if current_route.id != route_id
        raise "UI::ActionDispatcher#mount_screen(route_id): route_id " \
              "#{route_id.inspect} does not match coord.current.id " \
              "#{current_route.id.inspect}. Use mount_screen(route) overload " \
              "to mount before push, or pass the live current id."
      end
      mount_screen(current_route)
    end

    # Resolve + dispatch an action_ref. Builds a fresh Native context
    # with the dispatcher's current FormState + the explicit params
    # from the action_ref's button. Runs before_actions on the
    # resolved controller class; if any returns a UI::ActionResult,
    # the dispatch short-circuits. Otherwise calls dispatch_action
    # and translates the returned result via `translate_result`.
    def dispatch(
      action_ref : Symbol | Tuple(UI::Controller.class, Symbol),
      explicit_params : Hash(String, String) = {} of String => String,
    ) : Nil
      ctx = build_context(explicit_params)
      result = call_action(action_ref, ctx)
      translate_result(result)
      nil
    end

    # Build a fresh Native context for this dispatch. The dispatcher
    # owns the FormState reference; new context wraps it (along with
    # session, flash, etc.). The explicit_params arrive from the
    # Button's per-tap payload (action_params on the context).
    private def build_context(explicit_params : Hash(String, String)) : UI::ScreenContext::Native
      UI::ScreenContext::Native.new(
        form_state: @current_form_state,
        session: @session,
        flash: @flash,
        design_tokens: @design_tokens,
        navigation: @navigation,
        action_params: explicit_params,
      )
    end

    private def call_action(
      action_ref : Symbol | Tuple(UI::Controller.class, Symbol),
      ctx : UI::ScreenContext::Native,
    ) : UI::ActionResult
      case action_ref
      when Symbol
        # Current screen's controller, action_ref method.
        registration = @app.registration_for(@navigation.current.id)
        controller_class = registration.controller_class
        # Phase 8C: a registration whose controller_class is nil is a
        # web-only screen. Native dispatch into it is a programming
        # error — fail loud rather than NoMethodError on nil.new.
        if controller_class.nil?
          raise UI::App::WebOnlyScreenError.new(
            "UI::ActionDispatcher cannot dispatch native action " \
            "#{action_ref.inspect} on route_id #{@navigation.current.id.inspect}: " \
            "the registration has no native controller_class (web-only screen). " \
            "web_controller_name=#{registration.web_controller_name.inspect} " \
            "web_path=#{registration.web_path.inspect}"
          )
        end
        controller = controller_class.new
        run_before_actions(controller, ctx) || controller.dispatch_action(action_ref, ctx)
      when Tuple(UI::Controller.class, Symbol)
        ctrl_class, action_method = action_ref
        controller = ctrl_class.new
        run_before_actions(controller, ctx) || controller.dispatch_action(action_method, ctx)
      else
        raise "UI::ActionDispatcher cannot resolve action_ref of type #{action_ref.class}"
      end
    end

    private def run_before_actions(controller : UI::Controller, ctx : UI::ScreenContext::Native) : UI::ActionResult?
      controller.class._before_actions.each do |cb|
        result = cb.call(controller, ctx)
        return result if result.is_a?(UI::ActionResult)
      end
      nil
    end

    private def translate_result(result : UI::ActionResult) : Nil
      # IMPORTANT ordering invariant (per Codex iter 4 finding #1):
      # `NavigationCoordinator#push/#pop/#replace_root/#republish` notify
      # subscribers SYNCHRONOUSLY inside the call. The renderer's
      # `on_change` subscriber rebuilds the view tree during notify
      # — and its wire-time read of `UI::FormState.current` MUST see the
      # NEW mount's FormState, not the prior mount's. So we mount FIRST
      # (which bumps token + swaps `UI::FormState.current`) and THEN
      # invoke the coord mutation that fires the renderer.
      #
      # Reentrancy caveat (per Codex iter 4 rev 2 note): if an
      # `on_change` subscriber synchronously dispatches another action
      # (e.g. analytics that calls `coord.push` from inside its
      # callback), the resulting nested notify will see a DIFFERENT
      # FormState than this dispatch's subscribers. The supported
      # contract is: `on_change` subscribers are renderer-only +
      # non-reentrant. If an application needs reentrant subscribers,
      # it must use a queue or defer to a later run loop tick.
      case result
      when UI::ActionResult::Navigate
        next_route = UI::NavigationCoordinator::Route.new(result.route_id, result.params)
        mount_screen(next_route)
        @navigation.push(next_route)
      when UI::ActionResult::Pop
        # The route we are popping TO is the route below the top.
        # Compute it before calling pop. If we're already at root,
        # don't mount or pop — both no-op.
        if @navigation.depth > 1
          target_route = @navigation.routes[-2]
          mount_screen(target_route)
          @navigation.pop
        end
      when UI::ActionResult::Rerender
        # Re-mount the SAME route so any in-flight stale-fire callbacks
        # captured under the prior token become no-ops (defensive even
        # on rerender). Then republish so the host rebuilds the view
        # under the new mount.
        current_route = @navigation.current
        mount_screen(current_route)
        @navigation.republish
      when UI::ActionResult::ReplaceRoot
        next_route = UI::NavigationCoordinator::Route.new(result.route_id, result.params)
        mount_screen(next_route)
        @navigation.replace_root(next_route)
      when UI::ActionResult::RenderInline
        # Host-specific. Emit via on_render_inline if a callback is
        # bound; otherwise silently drop (the inline render result is
        # invalid without a host to receive it — log when we add a
        # debug-mode warning in a later phase).
        @on_render_inline.try(&.call(result.view))
      else
        # Unknown ActionResult subtype — should never happen with the
        # current sealed hierarchy, but Crystal's case-when isn't
        # exhaustive against an abstract class so we guard explicitly.
        raise "UI::ActionDispatcher cannot translate result of type #{result.class}"
      end
      nil
    end

    # Push the dispatcher's FormState reference + token into
    # `UI::FormState`'s renderer-hook surface. The renderer reads
    # those module-level slots inside `visit(UI::TextField)` /
    # `visit(UI::SecureField)`; this sync makes the wire-time capture
    # see the dispatcher's current per-mount state.
    private def sync_renderer_hooks : Nil
      UI::FormState.current = @current_form_state
      UI::FormState.current_mount_token = @current_mount_token
      nil
    end
  end
end
