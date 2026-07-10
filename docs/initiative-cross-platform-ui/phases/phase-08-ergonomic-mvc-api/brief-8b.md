# Phase 8B — Native UI::App + UI::Controller + ActionDispatcher + FormState

**Date opened:** 2026-05-24
**Authored by:** Architect (Codex critique before dispatch)
**Branch:** to be cut as `phase-08b-native-app-controller` from feature branch (after Phase 8A merge — already done at `721768e1`).
**Codex protocol:** Per-iteration critique on every code-touching iteration. No self-assessment.

---

## Why this phase exists

Phase 8A shipped the WEB side of the ergonomic top-level API: Amber controllers `include UI::ScreenHelpers`, call `compute_screen_html SignInScreen`, render via the production integration path. Browser POST proof closed the gate.

Phase 8B ships the NATIVE side — `UI::App` + `UI::Controller` + `UI::ActionDispatcher` + `UI::FormState` — so iOS/macOS apps can use the SAME `UI::Screen` subclasses that Amber web targets render. The controller idioms differ per platform (web inherits Amber::Controller::Base; native inherits UI::Controller) but the SCREEN AUTHORING is shared. This is the parallel-controllers architecture from design v2.

The native infrastructure layers on top of proven Phase 6.10/6.11 primitives:
- `UI::NavigationCoordinator` (`push/pop/replace_root/on_change`) — exists.
- Reactive Button/Label runtime state mutators — exist.
- iOS UIKit + macOS AppKit renderers — exist.
- iOS class-init gap workaround pattern — proven in Voyager's `bridge.cr`.

Phase 8B introduces NEW public API on top:
- `UI::App` declarative screen registry.
- `UI::Controller` base class with action helpers + `before_action` callbacks.
- `UI::ActionDispatcher` — converts `Button(action: :submit)` taps into controller method calls.
- `UI::FormState` — per-screen field-name → value registry; inputs update via `on_change`; submit action reads from it.
- `UI::ScreenContext::Native` — concrete Context impl for native targets.
- `UI::ActionResult` type hierarchy.

A minimal native demo at `samples/phase-08b-native-spike/` proves the flow on macOS (the easiest platform to drive deterministically). iOS validation is best-effort with the existing simulator infrastructure. Voyager STAYS UNCHANGED in Phase 8B — Voyager migration is Phase 8D.

---

## Environment assumptions

1. Branch HEAD `721768e1` (Phase 8A merged) exists locally.
2. `crystal spec` baseline 1576/4/0 at `721768e1`. Preserve through every commit.
3. `Color::SYSTEM_ACCENT`, `UI::NavigationCoordinator`, `UI::ScreenContext`, `UI::Screen` base class — all shipped by prior phases. Build on top.
4. iOS class-init gap workaround pattern documented in Phase 6.10 bridge.cr commit and the project memory file `project_crystal_ios_class_init_gap.md`. Apply to any class-var that holds runtime state.
5. `codex` CLI at `/opt/homebrew/bin/codex` for per-iteration review.

---

## Scope — 6 items + native macOS spike

### Item 1 — `UI::App` base class with `screen` macros

`src/asset_pipeline/native_app.cr` (NEW):

```crystal
abstract class UI::App
  # Registry of route_id => ScreenRegistration.
  # Populated by `screen` macros at class-load time.
  class_getter screens : Hash(Symbol, ScreenRegistration) = {} of Symbol => ScreenRegistration
  class_getter initial_route_id : Symbol = :_unset

  record ScreenRegistration,
    route_id : Symbol,
    controller_class : UI::Controller.class,
    screen_class : UI::Screen.class

  # Declare the initial route on launch.
  macro initial_route(route_id)
    class_getter initial_route_id : Symbol = {{route_id}}
  end

  # Register a screen with its controller. Screen class can be omitted —
  # convention is FooController -> FooScreen (under the app's namespace).
  macro screen(route_id, controller, screen_class = nil)
    @@screens[{{route_id}}] = UI::App::ScreenRegistration.new(
      route_id: {{route_id}},
      controller_class: {{controller}},
      screen_class: {{screen_class || (controller.stringify.gsub(/Controller$/, "Screen").id)}},
    )
  end

  # Optional: per-app design tokens override.
  macro design_tokens(&block)
    class_getter app_design_tokens : UI::DesignTokens::Tokens = begin
      tokens = UI::DesignTokens::Tokens.default
      {{block.body}}
      tokens
    end
  end

  # Look up a screen registration by route_id.
  def self.registration_for(route_id : Symbol) : ScreenRegistration
    @@screens[route_id]? || raise UI::App::UnknownRouteError.new(
      "No screen registered for route_id #{route_id.inspect}. " \
      "Available routes: #{@@screens.keys.inspect}"
    )
  end

  class UnknownRouteError < Exception; end
end
```

**Per [[project_crystal_ios_class_init_gap]]:** the `@@screens` class-var hash IS a default-initialised class var (the iOS class-init gap risk). Mitigation: ensure all `screen` macros are invoked in module-load order BEFORE `UI::App.launch_*` runs. On iOS, the `initialize_runtime` bridge function should access `@@screens` early enough that the class-init gap doesn't strand it. If empirical iOS testing surfaces a strand, the brief includes an escape hatch: `UI::App.bootstrap!` method that re-registers known screens via explicit calls (similar to Voyager's bridge.cr Bytes.new(64) workaround).

**Acceptance:**
- `UI::App` base class compiles.
- `screen` + `initial_route` + `design_tokens` macros work.
- `spec/asset_pipeline/native_app_spec.cr` covers screen registration + lookup.

### Item 2 — `UI::Controller` base class with action helpers

`src/asset_pipeline/native_controller.cr` (NEW):

```crystal
abstract class UI::Controller
  # Protected action-result constructors that subclasses call from
  # their action methods.
  protected def navigate_to(route_id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String) : UI::ActionResult
    UI::ActionResult::Navigate.new(route_id, params)
  end

  protected def pop_navigation : UI::ActionResult
    UI::ActionResult::Pop.new
  end

  protected def render_current_screen : UI::ActionResult
    UI::ActionResult::Rerender.new
  end

  protected def replace_root(route_id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String) : UI::ActionResult
    UI::ActionResult::ReplaceRoot.new(route_id, params)
  end

  protected def respond_with(view : UI::View) : UI::ActionResult
    UI::ActionResult::RenderInline.new(view)
  end

  # `before_action` callback registration. Callbacks are class-level + run
  # in registration order before the action method. Each callback can:
  #   - return nil to continue to the action
  #   - return a UI::ActionResult to short-circuit (e.g. redirect_to)
  macro before_action(method_name)
    @@_before_actions << ->(ctrl : self, ctx : UI::ScreenContext::Native) {
      ctrl.{{method_name.id}}(ctx)
    }
  end

  class_getter _before_actions : Array(Proc(self, UI::ScreenContext::Native, UI::ActionResult?)) =
    [] of Proc(self, UI::ScreenContext::Native, UI::ActionResult?)
end
```

**Acceptance:**
- `UI::Controller` base class compiles.
- Action helper methods produce the correct ActionResult subtypes.
- `before_action` macro registers a callback that the dispatcher invokes.
- `spec/asset_pipeline/native_controller_spec.cr` covers each helper + before_action.

### Item 3 — `UI::ActionResult` type hierarchy

`src/asset_pipeline/action_result.cr` (NEW):

```crystal
abstract class UI::ActionResult
  class Navigate < UI::ActionResult
    getter route_id : Symbol
    getter params : Hash(Symbol, String)
    def initialize(@route_id, @params); end
  end

  class Pop < UI::ActionResult; end

  class Rerender < UI::ActionResult; end

  class ReplaceRoot < UI::ActionResult
    getter route_id : Symbol
    getter params : Hash(Symbol, String)
    def initialize(@route_id, @params); end
  end

  class RenderInline < UI::ActionResult
    getter view : UI::View
    def initialize(@view); end
  end
end
```

**Acceptance:** all 5 subtypes ship with the correct property surface. Specs verify each.

### Item 4 — `UI::FormState` registry

`src/asset_pipeline/form_state.cr` (NEW):

```crystal
# Per-screen registry of field name -> current value. Populated by
# input on_change callbacks. Read by submit-action dispatch to build
# the controller's params hash.
#
# Per-screen lifecycle: a new FormState is created on screen mount;
# the ActionDispatcher passes a reference to it through the
# UI::ScreenContext::Native; TextField/SecureField/Toggle inputs
# rendered inside the screen tree wire their on_change to update it.
class UI::FormState
  getter values : Hash(String, String) = {} of String => String

  def initialize(initial : Hash(String, String) = {} of String => String)
    @values = initial.dup
  end

  # Inputs register the initial value when the view is built. Called
  # by the renderer's TextField/SecureField visit when the view has
  # a non-empty `name` property.
  def register(name : String, initial : String = "") : Nil
    @values[name] = initial unless @values.has_key?(name)
  end

  # on_change wiring: called from the Crystal callback that fires
  # when SwiftUI's TextStorage / Crystal's Binding updates.
  def update(name : String, value : String) : Nil
    @values[name] = value
  end

  def [](name : String) : String
    @values[name]? || ""
  end

  def []?(name : String) : String?
    @values[name]?
  end

  # Snapshot for the controller action.
  def to_h : Hash(String, String)
    @values.dup
  end
end
```

**Native renderer integration with mount tokens (Codex-revised):**

The renderer callbacks need to capture the FormState for the SPECIFIC screen mount, not a globally-mutable "current FormState." Stale controls (e.g. a TextField from the prior screen whose on_change fires after navigation) must NOT update the next screen's FormState.

Approach: each screen mount generates a fresh `UI::FormState` AND a fresh `mount_token : Int64`. When the renderer wires a TextField's on_change, it captures BOTH the FormState reference AND the token. The callback closure compares the captured token against the dispatcher's CURRENT token; if they don't match, the callback is a no-op.

```crystal
class UI::FormState
  getter mount_token : Int64

  def initialize(@mount_token : Int64, initial : Hash(String, String) = {} of String => String)
    @values = initial.dup
  end

  # ... rest unchanged
end

class UI::ActionDispatcher
  getter current_mount_token : Int64 = 0_i64

  def mount_screen(route_id : Symbol) : Nil
    @current_mount_token += 1
    @current_form_state = UI::FormState.new(mount_token: @current_mount_token)
    # ... apply route params
  end
end

# In the renderer's visit_text_field, wiring the on_change:
form_state_ref = dispatcher.current_form_state
captured_token = form_state_ref.mount_token
text_field.on_change = ->(new_value : String) do
  if dispatcher.current_mount_token == captured_token
    form_state_ref.update(text_field.name.not_nil!, new_value)
  end
  # else: stale control fired after navigation — silently ignore.
end
```

This addresses Codex's concern: a TextField rendered for `:sign_in` cannot leak values into the `:todos` FormState if the user pops back and the prior screen's input fires a delayed on_change.

**Acceptance:** FormState class compiles. Renderer integration tested via a minimal native demo (Item 7). Form-state updates work synchronously with input changes.

### Item 5 — `UI::ScreenContext::Native` concrete impl

`src/asset_pipeline/amber_integration.cr` ALREADY has `UI::ScreenContext` abstract + `UI::ScreenContext::Web` from Phase 8A. Phase 8B ships:

```crystal
class UI::ScreenContext::Native < UI::ScreenContext
  getter form_state : UI::FormState
  getter session : UI::Session
  getter flash : UI::Flash
  getter design_tokens : UI::DesignTokens::Tokens
  getter navigation : UI::NavigationCoordinator
  getter action_params : Hash(String, String) = {} of String => String

  def initialize(
    @form_state : UI::FormState,
    @session : UI::Session,
    @flash : UI::Flash,
    @design_tokens : UI::DesignTokens::Tokens,
    @navigation : UI::NavigationCoordinator,
    @action_params : Hash(String, String) = {} of String => String,
  )
  end

  # Per Codex critique: form_state and action_params have different semantics
  # and stay SEPARATE — no silent merge. Callers read whichever is appropriate.
  #
  # form_state: values typed into TextField/SecureField/Toggle inputs on the
  #             current screen, populated by renderer on_change callbacks.
  # action_params: explicit params passed via Button(action:, params: {...})
  #                — e.g. {"todo_id" => "42"} naming WHICH row's Edit/Delete
  #                action this is.
  def params : Hash(String, String)
    @form_state.to_h
  end

  def action_params : Hash(String, String)
    @action_params
  end

  # If a conflict exists (same key in both), the controller is responsible
  # for deciding which to read. Phase 8B exposes both; Phase 8D's Voyager
  # migration documents the typical pattern (form values from .params; row
  # identity from .action_params).
  def csrf_token : String?
    nil  # native has no CSRF — explicit nil for clarity
  end
end

# Native Session is in-process Hash for Phase 8B (per [[design v2 Q4]]).
# Future enhancement: persistent backing via NSUserDefaults / file.
class UI::Session::InProcess < UI::Session
  getter store : Hash(String, String) = {} of String => String
  def [](key : String) : String?
    @store[key]?
  end
  def []=(key : String, value : String) : Nil
    @store[key] = value
  end
  def to_h : Hash(String, String)
    @store.dup
  end
end

# Native Flash is also in-process — same lifecycle as session.
class UI::Flash::InProcess < UI::Flash
  getter store : Hash(String, String) = {} of String => String
  def [](key : String) : String?
    @store[key]?
  end
  def []=(key : String, value : String) : Nil
    @store[key] = value
  end
  def clear : Nil
    @store.clear
  end
end
```

**Acceptance:** UI::ScreenContext::Native compiles. Its `params` returns form_state values; its `action_params` returns explicit Button params SEPARATELY (no silent merge per Codex finding #2). Specs cover both accessors + verify the "form values, row identity" Voyager-style pattern documented in the brief.

### Item 6 — `UI::ActionDispatcher`

`src/asset_pipeline/action_dispatcher.cr` (NEW):

```crystal
# Singleton dispatcher held by UI::App.launch_*. Each app has ONE
# dispatcher that owns the current FormState, session, flash, and
# the registered NavigationCoordinator.
#
# Lifecycle:
#   - App startup: dispatcher.new(app: VoyagerApp, coord: navigation_coord,
#                                  session: in_process_session,
#                                  flash: in_process_flash,
#                                  design_tokens: app_design_tokens)
#   - Each screen mount: dispatcher.mount_screen(route_id) — creates a
#     fresh FormState for the screen.
#   - Each Button tap: the renderer's button-action callback calls
#     dispatcher.dispatch(action_ref, explicit_params, *button_context).
#     The dispatcher resolves the action_ref + calls the controller
#     method + translates the ActionResult.
class UI::ActionDispatcher
  getter app : UI::App.class
  getter navigation : UI::NavigationCoordinator
  getter session : UI::Session
  getter flash : UI::Flash
  getter design_tokens : UI::DesignTokens::Tokens
  getter current_form_state : UI::FormState

  def initialize(@app, @navigation, @session, @flash, @design_tokens)
    @current_mount_token = 0_i64
    @current_form_state = UI::FormState.new(mount_token: @current_mount_token)
  end

  # Called when a new screen mounts. Increments the mount token AND
  # creates a new FormState carrying that token. Renderer callbacks
  # captured under the prior token become no-ops (Codex finding #3).
  def mount_screen(route_id : Symbol) : Nil
    @current_mount_token += 1
    @current_form_state = UI::FormState.new(mount_token: @current_mount_token)
    # Apply any route params from the coord as initial form_state.
    current_route = @navigation.current
    current_route.params.each { |k, v| @current_form_state.register(k.to_s, v) }
  end

  # Resolve + dispatch an action_ref to the appropriate controller method.
  #
  # action_ref can be:
  #   :submit                         -> current screen's controller's :submit method
  #   {TodosController, :create}      -> TodosController.new.create(context)
  #
  # explicit_params: from Button(action:, params: {"todo_id" => "42"})
  def dispatch(action_ref : Symbol | Tuple(UI::Controller.class, Symbol),
               explicit_params : Hash(String, String) = {} of String => String) : Nil
    ctx = build_context(explicit_params)
    result = call_action(action_ref, ctx)
    translate_result(result)
  end

  private def call_action(action_ref, ctx) : UI::ActionResult
    case action_ref
    when Symbol
      # Current screen's controller, action_ref method.
      registration = @app.registration_for(@navigation.current.id)
      controller = registration.controller_class.new
      run_before_actions(controller, ctx) || controller.dispatch_action(action_ref, ctx)
    when Tuple(UI::Controller.class, Symbol)
      ctrl_class, action_method = action_ref
      controller = ctrl_class.new
      run_before_actions(controller, ctx) || controller.dispatch_action(action_method, ctx)
    end
  end

  private def run_before_actions(controller, ctx) : UI::ActionResult?
    controller.class._before_actions.each do |cb|
      result = cb.call(controller, ctx)
      return result if result.is_a?(UI::ActionResult)
    end
    nil
  end

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

  private def translate_result(result : UI::ActionResult) : Nil
    case result
    when UI::ActionResult::Navigate
      @navigation.push(UI::NavigationCoordinator::Route.new(result.route_id, result.params))
    when UI::ActionResult::Pop
      @navigation.pop
    when UI::ActionResult::Rerender
      @navigation.republish if @navigation.responds_to?(:republish)
    when UI::ActionResult::ReplaceRoot
      @navigation.replace_root(UI::NavigationCoordinator::Route.new(result.route_id, result.params))
    when UI::ActionResult::RenderInline
      # Host-specific. The platform's host (iOS bridge, macOS host)
      # subscribes to RenderInline results via a separate callback.
      # Phase 8B's dispatcher emits a Crystal Proc trigger; the host
      # binds to it at startup.
      @on_render_inline.try(&.call(result.view))
    end
  end

  property on_render_inline : Proc(UI::View, Nil)? = nil
end
```

Each `UI::Controller` subclass needs a `dispatch_action(method_name, ctx)` method that maps Symbol → method call. **Per Codex critique on this brief:** do NOT use a runtime `@@_registered_actions` class-var registry — that mixes runtime mutation with macro introspection, fights Crystal's type system, AND risks the iOS class-init gap.

**Approved approach: explicit per-controller `dispatch_action` override.**

```crystal
abstract class UI::Controller
  # Subclasses override this method with a simple case dispatch over
  # their action names. Crystal's type system likes this; no class-var
  # runtime registry; no iOS class-init gap risk.
  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    raise UI::Controller::UnknownActionError.new(
      "Controller #{self.class.name} does not override dispatch_action. " \
      "Override `def dispatch_action(name, context)` and dispatch via case."
    )
  end

  class UnknownActionError < Exception; end
end

# Example controller usage:
class SignInController < UI::Controller
  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    case name
    when :submit then submit(context)
    when :index  then index(context)
    else raise UI::Controller::UnknownActionError.new("SignInController has no action :#{name}")
    end
  end

  def submit(context) : UI::ActionResult
    # ...
  end

  def index(context) : UI::ActionResult
    # ...
  end
end
```

**Phase 8C may add an optional `macro action(name)` helper** that generates the dispatch case via `macro finished` introspection — but Phase 8B ships the explicit override only. Keeps the surface narrow + debug-friendly.

**Acceptance:** dispatcher resolves Symbol + Tuple action refs. Before-actions run. ActionResults translate to coord operations. Specs cover the dispatch flow.

### Item 7 — Native macOS spike demo

`samples/phase-08b-native-spike/` (NEW):

A minimal `crystal-alpha`-built macOS app that:

1. Defines `SpikeApp < UI::App` with `screen :sign_in, SignInController` + `screen :todos, TodosController`.
2. Defines `SignInScreen < UI::Screen` with email TextField (name: "email") + password SecureField (name: "password") + Sign-in Button (`action: :submit`).
3. Defines `SignInController < UI::Controller` overriding `dispatch_action` with `case name when :submit then submit(ctx)` and `def submit(ctx); session["user_email"] = ctx.params["email"]; navigate_to :todos; end`.
4. Defines `TodosScreen` that READS `context.session["user_email"]` and displays `UI::Label.new("Welcome, #{email}")` — this is the **read-back proof** that the form_state → controller → session → next-screen flow actually carried data through.
5. Defines `TodosController` with a `:back` action (just `pop_navigation`).
6. macOS host: creates NavigationCoordinator + ActionDispatcher + renders the initial screen.

Verification (Codex-revised — stronger gate):
- `make -C samples/phase-08b-native-spike macos` builds clean.
- Launching the bin opens the Sign-in screen.
- Typing `seth@example.com` in the email field + clicking Sign-in advances to the Todos screen displaying **"Welcome, seth@example.com"** — proving the email flowed from TextField → form_state → controller.submit → session["user_email"] → TodosScreen.build(context).
- Screenshot proof: `samples/phase-08b-native-spike/findings-macos-{signin,todos-with-name}.png`.
- The Todos screenshot MUST visibly contain the typed email (a generic "Welcome" is INSUFFICIENT per Codex critique — the email is the read-back proof).

iOS validation is best-effort — if the iOS bridge wiring is straightforward, ship it. If not, document the iOS port as Phase 8B follow-up.

**Acceptance:** macOS spike builds + runs + ends-up-on-todos after Sign-in click. Screenshots committed.

---

## Codex protocol

Per-iteration review committed to `handoff/phase-08b-codex-N.md`. Self-assessment NOT acceptable.

Iteration boundaries (suggested):
- iter 1: Items 1 + 3 (UI::App + UI::ActionResult — small, foundational)
- iter 2: Items 2 + 5 (UI::Controller + UI::ScreenContext::Native + Session/Flash impls)
- iter 3: Item 4 (UI::FormState + renderer integration on macOS visit_text_field/visit_secure_field)
- iter 4: Item 6 (UI::ActionDispatcher — the biggest single piece)
- iter 5: Item 7 (native macOS spike demo + closing-gate screenshot proof)

If Codex times out twice on same iteration: STOP, write `handoff/phase-08b-codex-blocker.md`, escalate.

---

## Build + verification

```bash
crystal spec  # baseline 1576/4/0 preserves

# After Items 1-6 land
crystal-alpha build samples/phase-08b-native-spike/src/spike_app.cr \
  -Dmacos -o samples/phase-08b-native-spike/bin/spike \
  --link-flags="..."   # see Voyager's macOS Makefile for the link chain

# Run the spike
samples/phase-08b-native-spike/bin/spike

# Click "Sign in" — should advance to Todos screen + display "Welcome"

# Screenshot proof
screencapture -l$(osascript -e 'tell application "spike" to get id of window 1') \
  samples/phase-08b-native-spike/findings-macos-todos.png
```

---

## Acceptance you must meet

- `crystal spec` baseline 1576/4/0 preserved (or improved with new specs).
- `samples/phase-08b-native-spike/` builds + runs on macOS.
- macOS spike: clicking Sign-in advances to Todos (full form_state → controller → coord.push flow).
- 2 macOS screenshots in `samples/phase-08b-native-spike/findings-macos-*.png`.
- All 5 iteration Codex reviews committed.
- Voyager builds + runs UNCHANGED (no regression to existing demo).
- `grep -rE "voyager-(save-chain|interaction-proof)"` returns 0.

## Reporting

Write `docs/initiative-cross-platform-ui/handoff/phase-08b-implementer-report.md` covering per-item status, commit SHAs, Codex verdicts, evidence paths, hand-test commands.

Return to architect with: branch HEAD SHA, commit count + SHAs, per-item status, Codex verdicts, screenshot paths.

## Hard rules

- Forward commits only on `phase-08b-native-app-controller`.
- NO Voyager changes. Voyager migration is Phase 8D.
- NO web side changes — Phase 8A's `UI::ScreenContext::Web` + `UI::ScreenHelpers` stay as-is.
- NO new design-token sentinels — Phase 6.12A SYSTEM_ACCENT is the model; only add to it if absolutely required.
- Standard Claude co-author footer on every commit.
- iOS spike work is BEST EFFORT — if the iOS bridge wiring exceeds budget, document + defer to Phase 8B follow-up. macOS spike is the closing gate.
- Do NOT use `__send__`-like runtime reflection for action dispatch — Crystal doesn't really have it. Use compile-time macros or explicit case branches.
- ARCHITECT-LEVEL OBSERVATION: prior implementer dispatches stopped mid-action at evidence-capture time. Phase 8B's evidence is just 2 macOS screenshots — keep capture work scoped tight.
