# Voyager demo app — unified UI::App / UI::Controller / UI::ActionDispatcher.
#
# A navigable Todos CRUD demo. Screens are `UI::Screen` subclasses with
# `build(ctx : UI::ScreenContext) : UI::View`; their callbacks dispatch
# action refs through `Voyager.dispatch(:action_name, action_params)`,
# which routes to the controller layer (one controller per route).
#
# Routes (4):
#   :sign_in       -> SignInScreen     / SignInController
#   :todos         -> TodosScreen      / TodosController
#   :todo_editor   -> TodoEditorScreen / TodoEditorController
#   :settings      -> SettingsScreen   / SettingsController
#
# Native targets (macOS + iOS) drive screens through the dispatcher;
# the iOS bridge migrated in Phase 8D.2 and now dispatches actions
# through `UI::ActionDispatcher` (see `ios/bridge.cr`).
#
# `Voyager.build_route(state, coord, route)` survives as the permanent
# entry point for the static-site web target (`web/static_site.cr`) —
# the only caller post-8D.2. See
# `docs/initiative-cross-platform-ui/architecture/web-target-position.md`
# for the architectural rationale (Voyager web is deliberately
# static-site, not a full-server dispatcher path; the Amber spike in
# `samples/phase-08-amber-spike/` proves the dispatcher web target on
# a different sample). The shim constructs a minimal
# ScreenContext::Native (no dispatcher attached) so user-intent
# callbacks become no-ops on the static-site path — static HTML + JS
# handles navigation client-side.

require "../../src/ui"
require "../../src/asset_pipeline/native_app"
require "../../src/asset_pipeline/native_controller"
require "../../src/asset_pipeline/action_dispatcher"
require "../../src/asset_pipeline/action_result"
require "../../src/asset_pipeline/native_context"

require "./screens/state"

require "./screens/sign_in_screen"
require "./screens/todos_screen"
require "./screens/todo_editor_screen"
require "./screens/settings_screen"

require "./controllers/sign_in_controller"
require "./controllers/todos_controller"
require "./controllers/todo_editor_controller"
require "./controllers/settings_controller"

# Phase 8D.3b — sample-local capture-scenario registry. No-op unless
# `VOYAGER_CAPTURE_SCENARIO` is set; the iOS bridge and macOS host both
# read that env var after constructing the dispatcher and call
# `Voyager::CaptureScenarios.apply` to walk into the target visual state.
require "./capture_scenarios"

module Voyager
  SLUGS = ["voyager-sign-in", "voyager-todos", "voyager-todo-editor", "voyager-settings"]

  # Host-set dispatcher.
  #
  # macOS and iOS hosts each construct a `UI::ActionDispatcher` and
  # assign it here so screen callback closures can route action refs
  # through `Voyager.dispatch(:submit)` /
  # `Voyager.dispatch(:edit_row, {"todo_id" => "5"})` without each
  # screen capturing a dispatcher reference. The static-site web entry
  # point (`Voyager.build_route`) leaves this nil — the static HTML +
  # JS path handles navigation client-side, so user-intent callbacks
  # become no-ops on that target.
  #
  # iOS class-init gap (see `project_crystal_ios_class_init_gap` memory):
  # deliberately a nilable default — no class-var initializer side
  # effects.
  @@dispatcher : UI::ActionDispatcher? = nil

  def self.dispatcher : UI::ActionDispatcher?
    @@dispatcher
  end

  def self.dispatcher=(d : UI::ActionDispatcher?) : UI::ActionDispatcher?
    @@dispatcher = d
  end

  # Convenience: dispatch a Symbol action_ref through the host's
  # ActionDispatcher. No-op when no dispatcher is set (the static-site
  # web path leaves the dispatcher nil; native targets assign one
  # during host bootstrap). Per the brief's action-ref convention, the
  # Symbol form runs the action on the CURRENTLY MOUNTED route's
  # registered controller; the optional action_params hash forwards to
  # ctx.action_params.
  def self.dispatch(name : Symbol, action_params : Hash(String, String) = {} of String => String) : Nil
    d = @@dispatcher
    return nil if d.nil?
    d.dispatch(name, action_params)
    nil
  end

  # Static-site web entry point.
  #
  # Permanent entry point for the static-site web target
  # (`web/static_site.cr`) — the only caller post-8D.2. iOS migrated
  # to the dispatcher path in Phase 8D.2 and no longer calls this.
  # See
  # `docs/initiative-cross-platform-ui/architecture/web-target-position.md`
  # for the architectural rationale.
  #
  # Constructs a minimal ScreenContext::Native (no dispatcher
  # attached) so the screen's `build` method has the abstract
  # `ScreenContext` parameter shape it expects, and renders the
  # screen via its registered class. Sets `Voyager.state` to the
  # passed-in state for the duration so screens reading
  # `Voyager.state` get the caller's instance. User-intent
  # callbacks become no-ops on this path — static HTML + JS handles
  # navigation client-side.
  def self.build_route(state : State, coord : UI::NavigationCoordinator, route : UI::NavigationCoordinator::Route) : UI::View
    # Make the per-call state visible to screens that read
    # `Voyager.state`.
    Voyager.state = state

    reg = VoyagerApp.registration_for(route.id)
    screen_class = reg.screen_class
    if screen_class.nil?
      placeholder = UI::Label.new("Unknown screen for route: #{route.id}")
      placeholder.accessibility_label = "Unknown route"
      return placeholder.as(UI::View)
    end

    # Seed a fresh FormState with route.params (string keys) so the
    # editor screen's `ctx.params["todo_id"]` works when the shim is
    # exercising it (e.g. spec/ui/voyager_state_propagation_spec.cr's
    # editor flow).
    fs = UI::FormState.new(mount_token: 0_i64)
    route.params.each { |k, v| fs.register(k.to_s, v) }

    ctx = UI::ScreenContext::Native.new(
      form_state: fs,
      session: UI::Session::InProcess.new,
      flash: UI::Flash::InProcess.new,
      design_tokens: UI::DesignTokens::Tokens.default,
      navigation: coord,
      action_params: {} of String => String,
    )
    screen_class.new.build(ctx)
  end

  # Map a static slug ("voyager-todos") to a Route. Used by the web
  # static-site generator (which renders one fragment per known slug
  # at build time) and by the iOS/macOS hosts when they need to
  # pre-build a route by name.
  def self.route_for_slug(slug : String) : UI::NavigationCoordinator::Route
    case slug
    when "voyager-sign-in"     then UI::NavigationCoordinator::Route.new(:sign_in)
    when "voyager-todos"       then UI::NavigationCoordinator::Route.new(:todos)
    when "voyager-todo-editor" then UI::NavigationCoordinator::Route.new(:todo_editor)
    when "voyager-settings"    then UI::NavigationCoordinator::Route.new(:settings)
    else                            UI::NavigationCoordinator::Route.new(:sign_in)
    end
  end

  # Slug for a Route.id (inverse of route_for_slug). Used by the
  # web renderer's UIRouteHost push glue.
  def self.slug_for_route_id(route_id : Symbol) : String
    case route_id
    when :sign_in     then "voyager-sign-in"
    when :todos       then "voyager-todos"
    when :todo_editor then "voyager-todo-editor"
    when :settings    then "voyager-settings"
    else                   "voyager-sign-in"
    end
  end
end

# UI::App declaration. Routes are registered via the `screen` macro;
# bootstrap! re-runs the registrations defensively (iOS class-init
# gap recovery hatch — see src/asset_pipeline/native_app.cr).
class VoyagerApp < UI::App
  initial_route :sign_in
  screen :sign_in,     Voyager::SignInController
  screen :todos,       Voyager::TodosController
  screen :todo_editor, Voyager::TodoEditorController
  screen :settings,    Voyager::SettingsController
end
