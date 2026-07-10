# Phase 8B — Native UI::App declarative screen registry.
#
# An app defines its top-level structure by subclassing `UI::App` and
# declaring its screens. Each `screen :route_id, FooController` macro
# call registers a route_id → (controller, screen) mapping that the
# `UI::ActionDispatcher` consults when an action resolves to a route.
#
# Example:
#
#     class SpikeApp < UI::App
#       initial_route :sign_in
#
#       screen :sign_in, SignInController     # → SignInScreen by convention
#       screen :todos,   TodosController      # → TodosScreen by convention
#       screen :detail,  DetailController, screen_class: DetailScreen
#     end
#
# Per [[project_crystal_ios_class_init_gap]]: on iOS embedding the
# class-init pass may silently skip class-var initialiser side effects.
# A class-var-side-effect-based recovery hatch (e.g. an
# `@@_bootstrap_registrations` proc list) would be just as vulnerable —
# the gap that silently skipped the `@@screens[...] = ...` write would
# also silently skip the proc-append. So we use a different mechanism:
#
# Every `screen :foo, FooController` macro call generates a NAMED
# class-method `def self._bootstrap_screen_foo; @@screens[:foo] = ...; end`.
# Method definitions are class-text emitted by macro expansion — they
# exist at COMPILE time, not at module-load time, and are reachable
# regardless of whether `_main` runs. `bootstrap!` is itself macro-
# generated via `macro inherited` so each subclass gets its own
# generated body listing the explicit method calls.
#
# iOS apps invoke `MyApp.bootstrap!` from their bridge entry function
# AFTER `Thread.init` / `Fiber.init` / `Crystal::Once.init`. macOS /
# web also get a working `bootstrap!` (no-op if @@screens is already
# populated — registrations are idempotent re-assignments).

require "../ui"
require "./amber_integration"
require "./action_result"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Forward declaration so `UI::App::ScreenRegistration` can carry a
  # `UI::Controller.class` value before `UI::Controller` lands in
  # `native_controller.cr`. The full abstract class definition lives in
  # that file.
  abstract class Controller
  end

  # Abstract base class for the declarative app + route registry; subclasses use the `screen` macro.
  abstract class App
    # Phase 8C — raised by `UI::ActionDispatcher#dispatch` when an
    # action resolves to a screen registration whose `controller_class`
    # is nil (i.e. a screen that was registered as web-only and therefore
    # has no native UI::Controller bound). Surfacing this as a typed
    # exception keeps the native dispatch path honest: a native build
    # that accidentally drives into a web-only screen fails loudly with
    # the route_id and the screen's web binding in the message, rather
    # than NoMethodError on .new of a nil class.
    class WebOnlyScreenError < Exception
    end

    # Registry of route_id => ScreenRegistration. The default-value
    # `class_getter` form would create the hash at module-load time —
    # which iOS embedding can silently skip. So we declare it nilable
    # and lazy-allocate via the `screens` accessor, which on first
    # access creates the hash. `bootstrap!` also force-assigns a fresh
    # hash to recover if the lazy-allocator's class-var write itself
    # stranded under the iOS gap.
    @@screens : Hash(Symbol, UI::App::ScreenRegistration)? = nil

    def self.screens : Hash(Symbol, UI::App::ScreenRegistration)
      @@screens ||= {} of Symbol => UI::App::ScreenRegistration
    end

    # The route_id chosen as the navigation root. Override via the
    # `initial_route` macro. Default `:_unset` is a sentinel that the
    # dispatcher's `launch_*` helper detects and raises against.
    #
    # Implemented as a method (not a `class_getter ... = :_unset`)
    # because class-var default initialisers are skipped under the iOS
    # class-init gap; method bodies are compile-time code unaffected
    # by the gap.
    def self.initial_route_id : Symbol
      :_unset
    end

    # A single registered screen. The dispatcher looks one up by
    # `route_id` to find which controller to construct + which screen
    # class to render.
    #
    # Phase 8C extensions (additive — Phase 8B callers still work):
    #
    #   * `controller_class` is now nilable. A web-only screen (no
    #     native UI::Controller wired) registers with `controller_class:
    #     nil`. `UI::ActionDispatcher#dispatch` raises `WebOnlyScreenError`
    #     if it ever resolves a route to such a registration.
    #   * `screen_class` is now nilable. A web-only screen need not
    #     supply a `UI::Screen` subclass — the native dispatch path that
    #     would consume it is already guarded by the same web-only error.
    #   * `web_controller` carries an `Amber::Controller::Base` subclass
    #     when the screen contributes web routes. Distinct from
    #     `controller_class` because the web and native controller
    #     hierarchies do not unify in Phase 8C (Phase 8A's parallel
    #     architecture). Typed as `Class?` since Amber may not be loaded
    #     when the asset_pipeline shard is compiled standalone.
    #   * `web_path` is the route prefix used by `routes_for` to fill
    #     in any action whose entry omits `path:`.
    #   * `web_actions` is the array of NamedTuple-literal entries
    #     `{verb: Symbol, action: Symbol, path: String?}` driving the
    #     emitted Amber router calls. Kept as a NamedTuple-literal
    #     array (not a Record) because Crystal's macro engine can walk
    #     NamedTuple literals field-by-field; Record-construction Calls
    #     would require Call.named_args AST extraction (Codex finding
    #     #4 in `codex-critique-1-brief-8c.md`).
    # Note on `web_controller_name : String?`:
    #
    # Crystal disallows `Class` in union types ("can't use Class in
    # unions yet") AND `Class` cannot be used as an instance-variable
    # type. The asset_pipeline shard also cannot require Amber (Amber
    # is a peer dependency, not a transitive one), so we cannot type
    # the field as `Amber::Controller::Base.class | Nil`.
    #
    # The pragmatic compromise: store the web controller's class NAME
    # as a `String?` for introspection (so tests / runtime tooling can
    # inspect "which Amber controller does this screen bind to?"), and
    # interpolate the actual class reference DIRECTLY into the macro
    # expansion in `routes_for` (which has the literal class AST node
    # frozen in at outer-screen-macro expansion time). The class ref
    # therefore never needs to be stored at runtime; it lives only in
    # the compile-time macro body.
    #
    # `has_web?` is True iff `web_actions` is non-empty (post-default).
    record ScreenRegistration,
      route_id : Symbol,
      controller_class : UI::Controller.class | Nil,
      screen_class : UI::Screen.class | Nil,
      web_controller_name : String | Nil = nil,
      web_path : String | Nil = nil,
      web_actions : Array(NamedTuple(verb: Symbol, action: Symbol, path: String?)) = [] of NamedTuple(verb: Symbol, action: Symbol, path: String?) do
      # True iff this registration contributes any Amber web routes.
      def has_web? : Bool
        !web_actions.empty?
      end
    end

    # Declare the initial route on launch.
    #
    #     class SpikeApp < UI::App
    #       initial_route :sign_in
    #     end
    macro initial_route(route_id)
      def self.initial_route_id : Symbol
        {{route_id}}
      end
    end

    # Register a screen with its controller. Screen class can be omitted —
    # convention is `FooController` -> `FooScreen` (under the same
    # namespace).
    #
    # Phase 8B form (still works in 8C):
    #
    #     screen :sign_in, SignInController
    #     screen :detail,  DetailController, screen_class: CustomScreen
    #
    # Phase 8C — web-only or dual-target screens. The positional
    # `controller` arg is optional (defaults to nil); `screen_class` is
    # the third positional (preserves Phase 8B's `screen :foo, FooCtrl,
    # CustomScreen` form). The new web kwargs (`web_controller:`,
    # `web_path:`, `web_actions:`) follow and are passed by name. The
    # brief proposed a `*` kwarg-only separator before the web kwargs,
    # but Crystal macros cannot combine `*,` with a default value on a
    # positional arg before it — every call that omits the positional
    # fails with "wrong number of arguments". Without the `*`, the
    # web kwargs are kwarg-by-default at the call site (the kwarg name
    # disambiguates from positional misuse) and the type system catches
    # positional confusion downstream (Class refs for `web_controller`,
    # `String` for `web_path`, `Array(NamedTuple)` for `web_actions`).
    #
    #     # Web-only — no native side yet.
    #     screen :sign_in,
    #            web_controller: SignInController,
    #            web_path: "/",
    #            web_actions: [
    #              {verb: :get,  action: :index},
    #              {verb: :post, action: :submit, path: "/sign_in/submit"},
    #            ]
    #
    #     # Dual-target — same class is the native AND web controller.
    #     # (In the spike, SignInController is `< Amber::Controller::Base`
    #     # only — Phase 8A's parallel-controllers shape. A future spike
    #     # may show a native UI::Controller and Amber::Controller::Base
    #     # passed separately.)
    #     screen :todos, TodosController,
    #            web_controller: TodosController,
    #            web_path: "/todos"
    #
    #     # Web-only shortcut — bare web_path defaults web_actions to
    #     # `[{verb: :get, action: :index, path: web_path}]`.
    #     screen :about, web_controller: AboutController, web_path: "/about"
    #
    # Defaulting and validation (all enforced at macro-expansion time):
    #
    #   * If `controller`, `web_controller`, `web_path`, and `web_actions`
    #     are all unset → `{% raise %}` (registration must declare at
    #     least one side).
    #   * If any web binding is set, `web_controller` MUST be set →
    #     `{% raise %}` otherwise (`web_path` or `web_actions` without
    #     a `web_controller` is meaningless).
    #   * If `web_actions` is non-empty, every entry must either carry
    #     its own `path:` OR `web_path` must be set as the default →
    #     `{% raise %}` otherwise.
    #   * If `web_actions` is empty AND `web_path` is set → default
    #     `web_actions` to `[{verb: :get, action: :index, path: web_path}]`.
    # Note on signature: the brief proposed a `*` kwarg-only separator
    # before the new web kwargs, but Crystal macros cannot combine a
    # `*` separator with a default value on a positional arg before it
    # ("wrong number of arguments" at every call site that omits the
    # positional). To preserve Phase 8B's call shapes EXACTLY, the
    # parameter order keeps `screen_class` as the third positional
    # (immediately after `controller`) so old calls of the form
    # `screen :foo, FooController, CustomScreen` continue to bind
    # `CustomScreen` to `screen_class`. The new web kwargs follow.
    # Codex iter-1 finding identified that re-ordering screen_class
    # past the web kwargs silently re-bound the third positional —
    # this reordering pins the legacy form.
    macro screen(route_id, controller = nil, screen_class = nil, web_controller = nil, web_path = nil, web_actions = nil)
      # ---- Normalise web_actions to an ArrayLiteral. ----
      {% web_actions_norm = web_actions || [] of Nil %}

      # ---- Determine whether the screen contributes web routes. ----
      #
      # A registration contributes web routes iff it has a concrete
      # route description: either an explicit web_path or a non-empty
      # web_actions array. `web_controller` alone is NOT enough — it's
      # just a target for routes that don't yet exist. The runtime
      # `ScreenRegistration#has_web?` predicate uses the same rule
      # (non-empty web_actions, post-default).
      {% has_web_input = (web_path != nil) || (!web_actions_norm.empty?) %}
      {% has_native = controller != nil %}
      {% has_web_controller_only = web_controller != nil && !has_web_input %}

      # ---- Validation 1: must declare at least one side. ----
      {% if !has_native && !has_web_input && !has_web_controller_only %}
        {% raise "UI::App.screen #{route_id} must declare at least one side: pass a native UI::Controller as the second positional arg, OR pass web_controller: ... (+ web_path: / web_actions:) as kwargs, OR both. See `UI::App.screen` doc comment." %}
      {% end %}

      # ---- Validation 1b: bare web_controller is always a footgun. ----
      #
      # A `web_controller` kwarg with no `web_path` AND no `web_actions`
      # records the binding in the ScreenRegistration but emits no
      # route markers, so `routes_for` silently produces nothing for
      # this screen. This is the same foot-gun whether or not a native
      # controller is also present — the author wired a web binding
      # that won't actually route anything. Raise in both cases.
      # (Per Codex iter-1 rev-1 MINOR finding.)
      {% if has_web_controller_only %}
        {% raise "UI::App.screen #{route_id} sets web_controller but neither web_path nor web_actions. A web binding with no route description emits nothing — pass web_path: or web_actions: (or drop web_controller: if the screen is native-only)." %}
      {% end %}

      # ---- Validation 2: any web binding implies web_controller. ----
      {% if has_web_input && web_controller == nil %}
        {% raise "UI::App.screen #{route_id} declares web_path or web_actions but no web_controller. The web_controller: kwarg must be set to an Amber::Controller::Base subclass that handles the emitted routes." %}
      {% end %}

      # ---- Default web_actions when only web_path is given. ----
      {% if has_web_input && web_actions_norm.empty? && web_path != nil %}
        {% web_actions_norm = [{verb: :get, action: :index, path: web_path}] %}
      {% end %}

      # ---- has_web for downstream marker emission ----
      {% has_web = has_web_input %}

      # ---- Validation 3: every web_actions entry must resolve to a path. ----
      {% if has_web %}
        {% for entry in web_actions_norm %}
          {% if entry[:path] == nil && web_path == nil %}
            {% raise "UI::App.screen #{route_id} web_actions entry #{entry} has no :path and the registration's web_path is nil. Either set web_path: as the default OR set path: on each entry." %}
          {% end %}
        {% end %}
      {% end %}

      # ---- screen_class resolution. ----
      #
      # Three cases:
      #   (a) screen_class is explicitly passed -> use it.
      #   (b) screen_class is omitted but a positional controller is
      #       set -> derive `FooController -> FooScreen` (Phase 8B form).
      #   (c) screen_class is omitted AND no controller -> nil (web-only,
      #       no native screen tree expected).
      {% if screen_class %}
        {% screen_lookup = screen_class %}
      {% elsif controller %}
        {% screen_lookup = controller.stringify.gsub(/Controller$/, "Screen").id %}
      {% else %}
        {% screen_lookup = nil %}
      {% end %}

      # Class-load side effect for the macOS / web happy path. The
      # `screens` accessor lazy-allocates if `@@screens` is nil. If the
      # iOS class-init gap skips this write entirely, `bootstrap!`
      # re-runs the registration via the generated method below.
      screens[{{route_id}}] = UI::App::ScreenRegistration.new(
        route_id: {{route_id}},
        controller_class: {{controller}},
        screen_class: {{screen_lookup}},
        web_controller_name: {% if web_controller %}{{web_controller.stringify}}{% else %}nil{% end %},
        web_path: {{web_path}},
        web_actions: [
          {% for entry in web_actions_norm %}
            {verb: {{entry[:verb]}}, action: {{entry[:action]}}, path: {{entry[:path] || web_path}}.as(String?)},
          {% end %}
        ] of NamedTuple(verb: Symbol, action: Symbol, path: String?),
      )

      # Compile-time-emitted named class method. Crystal method
      # definitions exist at COMPILE time, not module-load time, so
      # they are reachable regardless of whether the iOS embedding ran
      # `_main`'s class-init pass. `bootstrap!` calls every such
      # method on the subclass.
      def self._bootstrap_screen_{{route_id.id}} : Nil
        screens[{{route_id}}] = UI::App::ScreenRegistration.new(
          route_id: {{route_id}},
          controller_class: {{controller}},
          screen_class: {{screen_lookup}},
          web_controller_name: {% if web_controller %}{{web_controller.stringify}}{% else %}nil{% end %},
          web_path: {{web_path}},
          web_actions: [
            {% for entry in web_actions_norm %}
              {verb: {{entry[:verb]}}, action: {{entry[:action]}}, path: {{entry[:path] || web_path}}.as(String?)},
            {% end %}
          ] of NamedTuple(verb: Symbol, action: Symbol, path: String?),
        )
        nil
      end

      # ---------------------------------------------------------------
      # Phase 8C — twin emission: a marker class method PLUS a same-named
      # class macro. UI::AmberIntegration.routes_for enumerates the
      # marker methods at compile time (@type.class.methods) and emits
      # the same-named macro calls per app subclass; Crystal's macro
      # engine resolves them to the macro (not the method) at
      # macro-expansion time. The macro body expands inside the
      # consumer's routes :web do .. end block where Amber's get /
      # post / put / patch / delete macros are the implicit DSL.
      #
      # Empirical verification: see
      # docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/codex-critique-1-brief-8c.md
      # ("The proven mechanism" section).
      #
      # The marker + macro are emitted ONLY for screens with a web
      # binding. Native-only screens produce no marker; routes_for
      # silently skips them.
      # ---------------------------------------------------------------
      {% if has_web %}
        def self._web_route_emit_{{route_id.id}} : Nil
          nil
        end

        macro _web_route_emit_{{route_id.id}}
          {% for entry in web_actions_norm %}
            {{entry[:verb].id}} {{entry[:path] || web_path}}, {{web_controller}}, {{entry[:action]}}
          {% end %}
        end
      {% end %}
    end

    # Optional: per-app design-token override block. The block receives
    # the default `Tokens` instance and must RETURN a (possibly
    # transformed) `Tokens`. Macro hygiene means we can't expose a local
    # variable named `tokens` for the block to reassign, so the contract
    # is "block in, transformed Tokens out".
    #
    #     design_tokens do |tokens|
    #       tokens.copy_with(touch_target_minimum_px: 51.0)
    #     end
    #
    #     design_tokens do |tokens|
    #       tokens.with_brand(AcmeBrand.new)
    #     end
    macro design_tokens(&block)
      # Generate a subclass-specific override of `app_design_tokens`.
      # The body is method code (compile-time emitted), so the iOS
      # class-init gap can't skip it. We cache the result in a
      # nilable class var with lazy allocation — each accessor call
      # returns the same instance after the first.
      @@app_design_tokens : UI::DesignTokens::Tokens? = nil

      def self.app_design_tokens : UI::DesignTokens::Tokens
        cached = @@app_design_tokens
        return cached if cached
        block = ->({{block.args.first || "tokens".id}} : UI::DesignTokens::Tokens) : UI::DesignTokens::Tokens {
          {{block.body}}
        }
        @@app_design_tokens = block.call(UI::DesignTokens::Tokens.default)
      end
    end

    # If the consumer did not declare `design_tokens do ... end`, this
    # default method returns the framework default. Method body is
    # compile-time emitted code, unaffected by the iOS class-init gap.
    def self.app_design_tokens : UI::DesignTokens::Tokens
      UI::DesignTokens::Tokens.default
    end

    # Look up a screen registration by route_id. Raises
    # `UI::App::UnknownRouteError` with the list of known routes if the
    # id is not registered.
    def self.registration_for(route_id : Symbol) : ScreenRegistration
      registry = screens
      registry[route_id]? || raise UI::App::UnknownRouteError.new(
        "No screen registered for route_id #{route_id.inspect}. " \
        "Available routes: #{registry.keys.inspect}"
      )
    end

    # Default `bootstrap!` on the abstract `UI::App` itself — no-op
    # (no screens to register). Subclasses override via the
    # `macro inherited` hook below, which uses `macro finished` to
    # enumerate every `_bootstrap_screen_*` method that the `screen`
    # macro emitted and emit explicit calls to each.
    def self.bootstrap! : Nil
      nil
    end


    # When any class subclasses `UI::App`, install a generated
    # `bootstrap!` whose body explicitly calls every `_bootstrap_screen_*`
    # method on the subclass. Wrapped in `macro finished` so the
    # enumeration sees every `screen` macro call inside the subclass
    # body — `inherited` alone fires too early (at the start of the
    # subclass declaration).
    macro inherited
      macro finished
        def self.bootstrap! : Nil
          # Force-assign a fresh registry hash. If the iOS class-init
          # gap stranded `@@screens` as nil, this write recovers it.
          # If `@@screens` is already populated (macOS / web happy path
          # or a prior bootstrap! call), we still want to reset to a
          # clean slate before re-registering — registrations are
          # idempotent and the writes are deterministic.
          @@screens = {} of Symbol => UI::App::ScreenRegistration
          \{% for method in @type.class.methods %}
            \{% if method.name.starts_with?("_bootstrap_screen_") %}
              \{{method.name}}
            \{% end %}
          \{% end %}
          nil
        end
      end
    end

    class UnknownRouteError < Exception
    end
  end
end
