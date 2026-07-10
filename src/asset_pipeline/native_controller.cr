# Phase 8B — Native UI::Controller base class.
#
# Controllers map user actions (Button taps, form submits, navigation
# link activations) to results that the `UI::ActionDispatcher`
# translates into navigation operations or inline view emissions.
#
# Example:
#
#     class SignInController < UI::Controller
#       before_action :require_unauthenticated
#
#       def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
#         case name
#         when :submit then submit(context)
#         when :index  then index(context)
#         else raise UI::Controller::UnknownActionError.new(
#                "SignInController has no action :#{name}")
#         end
#       end
#
#       def submit(context) : UI::ActionResult
#         context.session["user_email"] = context.params["email"]
#         navigate_to(:todos)
#       end
#
#       def index(context) : UI::ActionResult
#         render_current_screen
#       end
#
#       private def require_unauthenticated(context)
#         return nil unless context.session["user_email"]?
#         navigate_to(:todos)
#       end
#     end
#
# # Why explicit `dispatch_action` override + `case` rather than a runtime
#   action registry?
#
# A runtime `@@_registered_actions` Hash + method-name lookup (Ruby-style
# `__send__`) would:
#
# 1. Mix runtime mutation with macro introspection — fights Crystal's
#    type system, which insists on compile-time method resolution.
# 2. Use a default-initialised class-var, which the iOS class-init gap
#    can silently strand as nil.
# 3. Stringify-then-dispatch loses Crystal's compile-time type checking
#    of action arguments.
#
# The explicit override is verbose by a few lines but the cost is paid
# once per controller and the win is enormous: Crystal type-checks every
# action call, no class-var state, no iOS gap risk, and the dispatch
# tree is debuggable as ordinary `case` code. Phase 8C may add an
# optional `action` macro helper to generate the case body via
# compile-time introspection — but Phase 8B ships the explicit override
# as the only supported path.

require "../ui"
require "./amber_integration"
require "./action_result"
require "./native_context"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Abstract base class for native-target controllers that turn user actions into ActionResult values.
  abstract class Controller
    # Subclasses override this method with a `case` dispatch over the
    # action names they implement. The default implementation raises
    # `UnknownActionError` with guidance pointing the author at the
    # override path.
    def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
      raise UI::Controller::UnknownActionError.new(
        "Controller #{self.class.name} did not override `dispatch_action`. " \
        "Override `def dispatch_action(name, context) : UI::ActionResult` " \
        "and dispatch via a `case name` block to each action method."
      )
    end

    # ----- ActionResult constructors -----------------------------------
    # Protected helpers that subclass action methods call. Each returns
    # a specific `UI::ActionResult` subtype that the dispatcher
    # translates into a coordinator operation.

    # Push a new route onto the navigation stack. `params` is the
    # per-route opaque-string-map carried through the
    # `UI::NavigationCoordinator::Route`.
    protected def navigate_to(route_id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String) : UI::ActionResult
      UI::ActionResult::Navigate.new(route_id, params)
    end

    # Pop the top route (back navigation).
    protected def pop_navigation : UI::ActionResult
      UI::ActionResult::Pop.new
    end

    # Re-render the current route without changing the stack. Use after
    # mutating shared state in-place when the view should reflect the
    # change (e.g. toggling a todo's completed flag).
    protected def render_current_screen : UI::ActionResult
      UI::ActionResult::Rerender.new
    end

    # Replace the entire navigation stack with a new root. Use after
    # sign-in, sign-out, or any flow where the prior route stack is
    # no longer meaningful.
    protected def replace_root(route_id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String) : UI::ActionResult
      UI::ActionResult::ReplaceRoot.new(route_id, params)
    end

    # Render the given view inline (e.g. in a popover / sheet host)
    # without affecting the navigation stack. The host wires an inline-
    # render callback via `UI::ActionDispatcher#on_render_inline`.
    protected def respond_with(view : UI::View) : UI::ActionResult
      UI::ActionResult::RenderInline.new(view)
    end

    # ----- before_action callbacks -------------------------------------
    #
    # Subclasses call `before_action :method_name` to register a
    # callback that runs before every action method on that controller.
    # The callback can:
    #   - return `nil` to continue to the action
    #   - return a `UI::ActionResult` to short-circuit (e.g. redirect)
    #
    # iOS class-init gap handling: every `before_action` macro call
    # emits a compile-time-named class method
    # `_before_action_<method_name>_proc : Proc(...)`. The
    # `_before_actions` accessor enumerates those methods (via
    # `macro inherited` + `macro finished` — the same pattern
    # UI::App uses for `bootstrap!`) and builds the callback list at
    # call time. Method definitions are compile-time emitted, not
    # class-load side effects, so they survive the iOS gap.

    # Abstract default — no callbacks registered.
    def self._before_actions : Array(Proc(UI::Controller, UI::ScreenContext::Native, UI::ActionResult?))
      [] of Proc(UI::Controller, UI::ScreenContext::Native, UI::ActionResult?)
    end

    macro inherited
      macro finished
        # Generated per-subclass `_before_actions` that enumerates
        # every `_before_action_*_proc` class method. Walks the
        # subclass's class methods at compile time and emits the
        # `<<` calls explicitly.
        def self._before_actions : Array(Proc(UI::Controller, UI::ScreenContext::Native, UI::ActionResult?))
          list = [] of Proc(UI::Controller, UI::ScreenContext::Native, UI::ActionResult?)
          \{% for method in @type.class.methods %}
            \{% if method.name.starts_with?("_before_action_") && method.name.ends_with?("_proc") %}
              list << \{{method.name}}
            \{% end %}
          \{% end %}
          list
        end
      end
    end

    # Register a before_action. The method must accept a
    # `UI::ScreenContext::Native` and return `UI::ActionResult?`.
    #
    #     before_action :require_authenticated
    #
    #     private def require_authenticated(context)
    #       return nil if context.session["user_email"]?
    #       navigate_to(:sign_in)
    #     end
    #
    # Implementation: emits a compile-time class method
    # `_before_action_<method_name>_proc` that builds and returns the
    # callback proc on demand. `_before_actions` enumerates those
    # methods to assemble the list. Compile-time method emission is
    # gap-safe; the prior `@@_before_actions << ...` class-body side
    # effect was not.
    macro before_action(method_name)
      def self._before_action_{{method_name.id}}_proc : Proc(UI::Controller, UI::ScreenContext::Native, UI::ActionResult?)
        ->(ctrl : UI::Controller, ctx : UI::ScreenContext::Native) : UI::ActionResult? {
          # `ctrl.as(self)` narrows the abstract callback signature back
          # to the concrete controller so the named method is callable
          # without the caller having to cast.
          ctrl.as(self).{{method_name.id}}(ctx)
        }
      end
    end

    class UnknownActionError < Exception
    end
  end
end
