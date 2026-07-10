# Phase 8B — Native ScreenContext + in-process Session / Flash.
#
# This file ships:
#
#   * `UI::Session` — abstract per-app key/value store. Web targets
#     use Amber's session store; native targets use the in-process
#     `UI::Session::InProcess` implementation provided here.
#   * `UI::Flash` — abstract one-shot messaging store. Web uses Amber's
#     flash; native uses `UI::Flash::InProcess`.
#   * `UI::ScreenContext::Native` — concrete context for native targets.
#     Implements the `UI::ScreenContext` abstract surface, AND adds
#     `form_state`, `session`, `flash`, `navigation`, and
#     `action_params` accessors.
#
# # Per Codex critique on the Phase 8B brief: `form_state` and
#   `action_params` stay SEPARATE — they have different semantics.
#
#   `params` (Phase 8A web contract): scalar form field values, scope
#     varies (request-wide on web, screen-mount-scoped on native).
#   `form_state.to_h` (native): values typed into TextField / SecureField /
#     Toggle inputs on the CURRENT screen mount.
#   `action_params` (native): explicit params passed via
#     `Button(action: :submit, params: {"todo_id" => "42"})` — e.g. row
#     identity for a list-row Edit / Delete action.
#
# The native `params` accessor returns `form_state.to_h`. Callers that
# need row-identity-only data read `action_params` separately. No
# silent merge — the controller picks which to read based on the action.
#
# # UI::FormState lives in `src/ui/form_state.cr` (shipped iter 3 of
#   Phase 8B). It sits under `src/ui/` (not `src/asset_pipeline/`)
#   because the native renderers (which are in `src/ui/renderers/`)
#   directly call `UI::FormState.current` from inside their visit
#   methods. Keeping it in `src/ui/` keeps the dependency direction
#   pointing the right way (ui → no asset_pipeline coupling).

require "../ui"
require "../ui/form_state"
require "./amber_integration"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI

  # Abstract per-app key / value store. Web concrete impls wrap Amber's
  # session; native uses `UI::Session::InProcess`.
  abstract class Session
    abstract def [](key : String) : String?
    abstract def []?(key : String) : String?
    abstract def []=(key : String, value : String) : Nil
    abstract def to_h : Hash(String, String)

    # In-process session backed by a plain `Hash`. Lifetime: the
    # process. Native apps that want persistence layer their own
    # backing (e.g. NSUserDefaults on macOS / iOS) over this contract.
    class InProcess < Session
      getter store : Hash(String, String) = {} of String => String

      def [](key : String) : String?
        @store[key]?
      end

      def []=(key : String, value : String) : Nil
        @store[key] = value
        nil
      end

      def []?(key : String) : String?
        @store[key]?
      end

      def to_h : Hash(String, String)
        @store.dup
      end
    end
  end

  # Abstract one-shot messaging store. Web wraps Amber's flash; native
  # uses `UI::Flash::InProcess`.
  abstract class Flash
    abstract def [](key : String) : String?
    abstract def []?(key : String) : String?
    abstract def []=(key : String, value : String) : Nil
    abstract def clear : Nil
    abstract def to_h : Hash(String, String)

    class InProcess < Flash
      getter store : Hash(String, String) = {} of String => String

      def [](key : String) : String?
        @store[key]?
      end

      def []=(key : String, value : String) : Nil
        @store[key] = value
        nil
      end

      def []?(key : String) : String?
        @store[key]?
      end

      def clear : Nil
        @store.clear
        nil
      end

      def to_h : Hash(String, String)
        @store.dup
      end
    end
  end

  # Concrete ScreenContext for native targets. Wraps:
  #   - the per-mount FormState,
  #   - the per-app Session + Flash,
  #   - the design tokens,
  #   - the NavigationCoordinator (for screens that need direct access
  #     to the route stack, e.g. depth-aware back-button affordances),
  #   - the per-button action_params payload.
  class ScreenContext::Native < ScreenContext
    getter form_state : UI::FormState
    getter session : UI::Session
    getter flash : UI::Flash
    getter design_tokens : UI::DesignTokens::Tokens
    getter navigation : UI::NavigationCoordinator
    getter action_params : Hash(String, String)

    def initialize(
      @form_state : UI::FormState,
      @session : UI::Session,
      @flash : UI::Flash,
      @design_tokens : UI::DesignTokens::Tokens,
      @navigation : UI::NavigationCoordinator,
      @action_params : Hash(String, String) = {} of String => String,
    )
    end

    # Snapshot of the per-screen form values. Implements the abstract
    # `UI::ScreenContext#params` contract for native targets. Always
    # reads via `form_state.to_h` (which returns a defensive copy in
    # iter 3); does NOT silently merge `action_params`.
    def params : Hash(String, String)
      @form_state.to_h
    end

    # Native targets do not carry multi-value form params yet — text
    # inputs are scalar-only. Returns an empty Hash to satisfy the
    # abstract contract. Future multi-select widgets (e.g. checkbox
    # groups) will populate this.
    def params_multi : Hash(String, Array(String))
      {} of String => Array(String)
    end

    # Flash messages for the current screen (snapshot for display).
    def flash_data : Hash(String, String)
      @flash.to_h
    end

    # Native targets do not have CSRF — the form submission path is
    # an in-process action dispatch, not an HTTP POST. Returns nil
    # explicitly to satisfy the abstract contract and make the
    # absence intentional rather than accidental.
    def csrf_token : String?
      nil
    end
  end
end
