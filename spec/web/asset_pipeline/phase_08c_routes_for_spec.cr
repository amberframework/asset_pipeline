# Phase 8C — UI::App.screen web-route extension + UI::AmberIntegration.routes_for.
#
# Covers the 7 acceptance cases (a-g) from brief-8c.md Item 1 plus the
# end-to-end routes_for macro emission against a stub Amber-style router.

require "../spec_helper"
require "../../../src/asset_pipeline/native_app"
require "../../../src/asset_pipeline/native_controller"
require "../../../src/asset_pipeline/action_dispatcher"
require "../../../src/asset_pipeline/amber_integration"

# Stub Amber-style controllers — the spike's `SignInController` extends
# `Amber::Controller::Base`, but we can't require Amber from the unit
# spec without dragging in the whole framework. The macro doesn't care
# what type `web_controller` resolves to (it just interpolates the AST
# node into the macro body); the stub here matches the spike's shape.
private class Phase08CWebSignInController
end

private class Phase08CWebTodosController
end

# Native-side stubs for the dual-target test.
private class Phase08CNativeScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("stub")
  end
end

private class Phase08CTodosScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("todos")
  end
end

private class Phase08CDetailScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("detail")
  end
end

private class Phase08CDetailController < UI::Controller
end

private class Phase08CTodosController < UI::Controller
end

# Stub router. Implements the same DSL surface as Amber::DSL::Router for
# the verbs the macro emits. Each verb captures the call into the
# router's `calls` array so the spec can assert what routes were emitted.
private class Phase08CSpecRouter
  getter calls : Array(NamedTuple(verb: Symbol, path: String, controller: String, action: Symbol))

  def initialize
    @calls = [] of NamedTuple(verb: Symbol, path: String, controller: String, action: Symbol)
  end

  # Public so the macro-generated calls below can reach it. Called via
  # `with router yield` — the implicit receiver IS the router instance
  # so bare `record_call(...)` resolves correctly.
  def record_call(verb : Symbol, path : String, controller : String, action : Symbol) : Nil
    @calls << {verb: verb, path: path, controller: controller, action: action}
    nil
  end

  macro get(path, controller, action)
    record_call(:get, {{path}}, {{controller}}.to_s, {{action}})
  end

  macro post(path, controller, action)
    record_call(:post, {{path}}, {{controller}}.to_s, {{action}})
  end

  macro put(path, controller, action)
    record_call(:put, {{path}}, {{controller}}.to_s, {{action}})
  end

  macro patch(path, controller, action)
    record_call(:patch, {{path}}, {{controller}}.to_s, {{action}})
  end

  macro delete(path, controller, action)
    record_call(:delete, {{path}}, {{controller}}.to_s, {{action}})
  end
end

# Helper that mimics Amber's `router.draw "web", "" do { yield } end` —
# i.e. `with router yield`. Inside the block, `get` / `post` resolve
# to the stub router's macros.
private def with_phase_08c_router(router : Phase08CSpecRouter, &)
  with router yield
end

# --------------------------------------------------------------------
# Acceptance (a) — native-only screen (Phase 8B form preserved).
# --------------------------------------------------------------------
private class Phase08CNativeOnlyApp < UI::App
  initial_route :detail
  screen :detail, Phase08CDetailController
end

# --------------------------------------------------------------------
# Acceptance (b) — web-only screen. No positional controller; only
# kwargs.
# --------------------------------------------------------------------
private class Phase08CWebOnlyApp < UI::App
  screen :sign_in,
         web_controller: Phase08CWebSignInController,
         web_path: "/",
         web_actions: [
           {verb: :get, action: :index},
           {verb: :post, action: :submit, path: "/sign_in/submit"},
         ]
end

# --------------------------------------------------------------------
# Acceptance (c) — dual-target screen. Native controller + web kwargs.
# --------------------------------------------------------------------
private class Phase08CDualApp < UI::App
  initial_route :todos
  screen :todos, Phase08CTodosController,
         web_controller: Phase08CWebTodosController,
         web_path: "/todos"
end

# --------------------------------------------------------------------
# Acceptance (d) — web_path-only registration → defaults to a single
# GET :index action at that path.
# --------------------------------------------------------------------
private class Phase08CWebPathOnlyApp < UI::App
  screen :about, web_controller: Phase08CWebSignInController, web_path: "/about"
end

# --------------------------------------------------------------------
# Combined-mixed app — multiple registrations with mixed shapes, used
# to verify routes_for handles the array correctly.
# --------------------------------------------------------------------
private class Phase08CMixedApp < UI::App
  initial_route :sign_in

  screen :sign_in,
         web_controller: Phase08CWebSignInController,
         web_path: "/",
         web_actions: [
           {verb: :get, action: :index},
           {verb: :post, action: :submit, path: "/sign_in/submit"},
         ]

  screen :todos, Phase08CTodosController,
         web_controller: Phase08CWebTodosController,
         web_path: "/todos"

  # Native-only screen — routes_for must NOT emit anything for this one.
  screen :detail, Phase08CDetailController
end

describe "Phase 8C — UI::App.screen web-route extension" do
  it "(a) native-only screen preserves Phase 8B form" do
    reg = Phase08CNativeOnlyApp.registration_for(:detail)
    reg.controller_class.should eq(Phase08CDetailController)
    reg.screen_class.should be_a(UI::Screen.class | Nil)
    reg.has_web?.should be_false
    reg.web_controller_name.should be_nil
    reg.web_path.should be_nil
    reg.web_actions.empty?.should be_true
  end

  it "(b) web-only screen registers with nil controller_class" do
    reg = Phase08CWebOnlyApp.registration_for(:sign_in)
    reg.controller_class.should be_nil
    reg.screen_class.should be_nil
    reg.web_controller_name.should eq("Phase08CWebSignInController")
    reg.web_path.should eq("/")
    reg.web_actions.size.should eq(2)
    reg.web_actions[0].should eq({verb: :get, action: :index, path: "/"})
    reg.web_actions[1].should eq({verb: :post, action: :submit, path: "/sign_in/submit"})
    reg.has_web?.should be_true
  end

  it "(c) dual-target screen carries both controller_class and web binding" do
    reg = Phase08CDualApp.registration_for(:todos)
    reg.controller_class.should eq(Phase08CTodosController)
    reg.screen_class.should eq(Phase08CTodosScreen)
    reg.web_controller_name.should eq("Phase08CWebTodosController")
    reg.web_path.should eq("/todos")
    reg.web_actions.size.should eq(1)
    reg.web_actions[0].should eq({verb: :get, action: :index, path: "/todos"})
  end

  it "(d) web_path-only defaults web_actions to [{verb: :get, action: :index, path: web_path}]" do
    reg = Phase08CWebPathOnlyApp.registration_for(:about)
    reg.web_actions.size.should eq(1)
    reg.web_actions[0].should eq({verb: :get, action: :index, path: "/about"})
  end

  # ----------------------------------------------------------------
  # Acceptance (e) — missing web_controller while web binding declared.
  # Acceptance (f) — registration with no native AND no web side.
  #
  # Both are macro-expansion-time {% raise %} guards. Crystal doesn't
  # offer an `expect_macro_raises` API, so we shell out to `crystal
  # build --no-codegen` on a fixture file that triggers each guard
  # and assert the build fails with the expected diagnostic. This
  # catches accidentally-relocated or unreachable guards (Codex iter-1
  # finding) that a source-grep would miss.
  # ----------------------------------------------------------------
  it "(e) screen macro raises at compile time when web_path is declared without web_controller" do
    fixture = File.expand_path("../fixtures/phase_08c_macro_raise/web_path_without_controller.cr", __DIR__)
    File.exists?(fixture).should be_true

    io_out = IO::Memory.new
    io_err = IO::Memory.new
    status = Process.run(
      "crystal",
      ["build", "--no-codegen", fixture],
      output: io_out,
      error: io_err,
    )
    combined = io_out.to_s + io_err.to_s
    status.success?.should be_false
    combined.should contain("declares web_path or web_actions but no web_controller")
  end

  it "(f) screen macro raises at compile time when neither native nor web side is declared" do
    fixture = File.expand_path("../fixtures/phase_08c_macro_raise/no_side.cr", __DIR__)
    File.exists?(fixture).should be_true

    io_out = IO::Memory.new
    io_err = IO::Memory.new
    status = Process.run(
      "crystal",
      ["build", "--no-codegen", fixture],
      output: io_out,
      error: io_err,
    )
    combined = io_out.to_s + io_err.to_s
    status.success?.should be_false
    combined.should contain("must declare at least one side")
  end

  it "(e3 — codex rev-1) screen macro raises when web_controller is set on a NATIVE screen but no web routes" do
    # Per Codex iter-1 rev-1 MINOR finding: the bare-web_controller
    # foot-gun applies whether or not a native controller is also
    # present. `screen :foo, NativeCtrl, web_controller: WebCtrl` (no
    # web_path / web_actions) records a web_controller binding that
    # never emits any routes — raise instead of silently no-op'ing.
    fixture = File.expand_path("../fixtures/phase_08c_macro_raise/native_plus_web_controller_no_routes.cr", __DIR__)
    File.exists?(fixture).should be_true

    io_out = IO::Memory.new
    io_err = IO::Memory.new
    status = Process.run(
      "crystal",
      ["build", "--no-codegen", fixture],
      output: io_out,
      error: io_err,
    )
    combined = io_out.to_s + io_err.to_s
    status.success?.should be_false
    combined.should contain("web_controller but neither web_path nor web_actions")
  end

  it "(e2 — codex revision) screen macro raises when web_controller is set but no web_path or web_actions" do
    # Per Codex iter-1 MINOR finding: tighten the macro so a bare
    # web_controller: kwarg (without a route description) raises
    # instead of silently producing a no-op registration. Catches the
    # foot-gun where an author wires `web_controller: WebCtrl` and
    # forgets the `web_path:` / `web_actions:` defaulting.
    fixture = File.expand_path("../fixtures/phase_08c_macro_raise/web_controller_no_routes.cr", __DIR__)
    File.exists?(fixture).should be_true

    io_out = IO::Memory.new
    io_err = IO::Memory.new
    status = Process.run(
      "crystal",
      ["build", "--no-codegen", fixture],
      output: io_out,
      error: io_err,
    )
    combined = io_out.to_s + io_err.to_s
    status.success?.should be_false
    combined.should contain("web_controller but neither web_path nor web_actions")
  end
end

describe "Phase 8C — UI::ActionDispatcher web-only screen guard (acceptance g)" do
  it "(g) raises UI::App::WebOnlyScreenError on native dispatch into a web-only screen" do
    # Build a minimal dispatcher pointed at Phase08CWebOnlyApp with a
    # current route of :sign_in. The dispatcher's `call_action` Symbol
    # branch looks up the registration and tries to instantiate the
    # controller — which is nil here.
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in, {} of Symbol => String))
    dispatcher = UI::ActionDispatcher.new(
      app: Phase08CWebOnlyApp,
      navigation: coord,
      session: UI::Session::InProcess.new,
      flash: UI::Flash::InProcess.new,
      design_tokens: UI::DesignTokens::Tokens.default,
    )

    expect_raises(UI::App::WebOnlyScreenError, /sign_in/) do
      dispatcher.dispatch(:submit)
    end
  end
end

describe "Phase 8C — UI::AmberIntegration.routes_for" do
  it "emits one router call per web_actions entry, binding to web_controller" do
    router = Phase08CSpecRouter.new

    with_phase_08c_router(router) do
      UI::AmberIntegration.routes_for(Phase08CMixedApp)
    end

    router.calls.size.should eq(3)
    # sign_in's two actions.
    router.calls.should contain({verb: :get, path: "/", controller: "Phase08CWebSignInController", action: :index})
    router.calls.should contain({verb: :post, path: "/sign_in/submit", controller: "Phase08CWebSignInController", action: :submit})
    # todos's defaulted single action.
    router.calls.should contain({verb: :get, path: "/todos", controller: "Phase08CWebTodosController", action: :index})
    # detail (native-only) MUST NOT have emitted anything.
    router.calls.any? { |c| c[:path].includes?("detail") }.should be_false
  end

  it "expands to nothing when the app has no web-bound screens" do
    router = Phase08CSpecRouter.new

    with_phase_08c_router(router) do
      UI::AmberIntegration.routes_for(Phase08CNativeOnlyApp)
    end

    router.calls.empty?.should be_true
  end

  it "expands to nothing when given a bare UI::App (no subclasses-of registrations)" do
    router = Phase08CSpecRouter.new

    # UI::App itself has no `_web_route_emit_*` methods.
    with_phase_08c_router(router) do
      UI::AmberIntegration.routes_for(UI::App)
    end

    router.calls.empty?.should be_true
  end
end
