require "../spec_helper"
require "../../../src/asset_pipeline/action_dispatcher"

# Test-only screens + controllers exercising every dispatch path.
private class ActionDispatcherSpecSignInScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("sign-in")
  end
end

private class ActionDispatcherSpecTodosScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("todos")
  end
end

private class ActionDispatcherSpecInlineScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("inline")
  end
end

private class ActionDispatcherSpecSignInController < UI::Controller
  class_getter calls : Array(Symbol) = [] of Symbol
  class_getter param_snapshots : Array(Hash(String, String)) = [] of Hash(String, String)
  class_getter action_param_snapshots : Array(Hash(String, String)) = [] of Hash(String, String)

  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    self.class.calls << name
    self.class.param_snapshots << context.params
    self.class.action_param_snapshots << context.action_params

    case name
    when :submit         then submit(context)
    when :back           then back(context)
    when :rerender       then render_current_screen
    when :reset          then reset_root(context)
    when :inline         then respond_with(UI::Label.new("snack"))
    when :pass_through   then pass_through(context)
    else raise UI::Controller::UnknownActionError.new("no #{name}")
    end
  end

  def submit(context) : UI::ActionResult
    # Read the email from form_state and stash in session
    email = context.params["email"]? || "anon"
    context.session["user_email"] = email
    navigate_to(:todos, {:from => "sign_in"})
  end

  def back(context) : UI::ActionResult
    pop_navigation
  end

  def reset_root(context) : UI::ActionResult
    replace_root(:sign_in)
  end

  def pass_through(context) : UI::ActionResult
    render_current_screen
  end
end

private class ActionDispatcherSpecTodosController < UI::Controller
  before_action :require_signed_in

  class_getter before_action_calls : Int32 = 0
  class_getter calls : Array(Symbol) = [] of Symbol

  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    self.class.calls << name
    case name
    when :index then index(context)
    else raise UI::Controller::UnknownActionError.new("no #{name}")
    end
  end

  def index(context) : UI::ActionResult
    render_current_screen
  end

  def require_signed_in(context) : UI::ActionResult?
    @@before_action_calls += 1
    return nil if context.session["user_email"]?
    navigate_to(:sign_in)
  end
end

private class ActionDispatcherSpecInlineController < UI::Controller
  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    respond_with(UI::Label.new("inline-from-controller"))
  end
end

private class ActionDispatcherSpecApp < UI::App
  initial_route :sign_in
  screen :sign_in, ActionDispatcherSpecSignInController, screen_class: ActionDispatcherSpecSignInScreen
  screen :todos, ActionDispatcherSpecTodosController, screen_class: ActionDispatcherSpecTodosScreen
  screen :inline, ActionDispatcherSpecInlineController, screen_class: ActionDispatcherSpecInlineScreen
end

private def build_dispatcher : UI::ActionDispatcher
  ActionDispatcherSpecSignInController.calls.clear
  ActionDispatcherSpecSignInController.param_snapshots.clear
  ActionDispatcherSpecSignInController.action_param_snapshots.clear
  ActionDispatcherSpecTodosController.calls.clear

  ActionDispatcherSpecApp.bootstrap!
  coord = UI::NavigationCoordinator.new(
    UI::NavigationCoordinator::Route.new(:sign_in)
  )

  UI::ActionDispatcher.new(
    app: ActionDispatcherSpecApp,
    navigation: coord,
    session: UI::Session::InProcess.new,
    flash: UI::Flash::InProcess.new,
    design_tokens: UI::DesignTokens::Tokens.default,
  )
end

describe UI::ActionDispatcher do
  describe "initialisation" do
    it "starts at mount_token 0 with a fresh FormState" do
      d = build_dispatcher
      d.current_mount_token.should eq(0_i64)
      d.current_form_state.mount_token.should eq(0_i64)
    end

    it "syncs the renderer hook surface on construction" do
      d = build_dispatcher
      UI::FormState.current.should be(d.current_form_state)
      UI::FormState.current_mount_token.should eq(0_i64)
    end
  end

  describe "mount_screen" do
    it "increments the mount token + allocates a new FormState (Route overload)" do
      d = build_dispatcher
      d.mount_screen(UI::NavigationCoordinator::Route.new(:sign_in))
      d.current_mount_token.should eq(1_i64)
      d.current_form_state.mount_token.should eq(1_i64)

      d.mount_screen(UI::NavigationCoordinator::Route.new(:todos))
      d.current_mount_token.should eq(2_i64)
      d.current_form_state.mount_token.should eq(2_i64)
    end

    it "seeds the new FormState from the route's params" do
      d = build_dispatcher
      d.mount_screen(UI::NavigationCoordinator::Route.new(:todos, {:from => "spec"}))
      d.current_form_state["from"].should eq("spec")
    end

    it "Symbol overload asserts route_id matches coord.current.id" do
      d = build_dispatcher
      # coord.current is :sign_in
      d.mount_screen(:sign_in)
      d.current_mount_token.should eq(1_i64)

      # Calling mount_screen with a mismatched id raises (caller bug).
      expect_raises(Exception, /does not match coord.current.id/) do
        d.mount_screen(:nonexistent)
      end
    end

    it "updates UI::FormState.current + current_mount_token" do
      d = build_dispatcher
      d.mount_screen(:sign_in)
      UI::FormState.current.should be(d.current_form_state)
      UI::FormState.current_mount_token.should eq(d.current_mount_token)
    end
  end

  describe "dispatch (Symbol action_ref)" do
    it "resolves to the current screen's controller" do
      d = build_dispatcher
      d.dispatch(:pass_through)
      ActionDispatcherSpecSignInController.calls.should eq([:pass_through])
    end

    it "passes explicit_params through as ctx.action_params" do
      d = build_dispatcher
      d.dispatch(:pass_through, {"todo_id" => "42"})
      ActionDispatcherSpecSignInController.action_param_snapshots.first["todo_id"].should eq("42")
    end

    it "exposes form_state values to ctx.params" do
      d = build_dispatcher
      d.current_form_state.update("email", "seth@example.com")
      d.dispatch(:pass_through)
      ActionDispatcherSpecSignInController.param_snapshots.first["email"].should eq("seth@example.com")
    end
  end

  describe "translate_result" do
    it "Navigate -> mount_screen happens BEFORE coord.push notify (renderer sees new mount)" do
      # Per Codex iter-4 finding #1: coord.push fires on_change
      # synchronously. The renderer's wire-time read of
      # UI::FormState.current MUST see the new mount's FormState, not
      # the prior one. The dispatcher's invariant is "mount, then
      # publish."
      d = build_dispatcher
      d.current_form_state.update("email", "seth@example.com")

      observed_tokens = [] of Int64
      observed_form_states_match = [] of Bool
      d.navigation.on_change do |route|
        observed_tokens << UI::FormState.current_mount_token
        observed_form_states_match << (UI::FormState.current.try(&.mount_token) == d.current_mount_token)
      end

      d.dispatch(:submit)

      # The on_change callback fired exactly once (for the Navigate push).
      observed_tokens.size.should eq(1)
      # And by the time it fired, FormState.current was ALREADY the new
      # mount (token 1, not 0).
      observed_tokens.first.should eq(1_i64)
      observed_form_states_match.first.should be_true
    end

    it "Navigate also seeds the new FormState from route params" do
      d = build_dispatcher
      d.current_form_state.update("email", "seth@example.com")

      observed_from = [] of String
      d.navigation.on_change do |route|
        # form_state for the new mount should already be seeded from
        # the route's params (which we set in :submit -> :from=sign_in).
        fs = UI::FormState.current
        observed_from << (fs ? fs["from"] : "")
      end

      d.dispatch(:submit)
      observed_from.first.should eq("sign_in")
    end

    it "Navigate updates coord state + session as expected" do
      d = build_dispatcher
      d.current_form_state.update("email", "seth@example.com")
      d.dispatch(:submit)

      d.navigation.current.id.should eq(:todos)
      d.navigation.depth.should eq(2)
      d.session["user_email"]?.should eq("seth@example.com")
      d.current_mount_token.should eq(1_i64)
    end

    it "Pop -> mount_screen + coord.pop (new mount visible to on_change)" do
      d = build_dispatcher
      # Build up a stack [:sign_in, :todos]. Set session so the todos
      # before_action doesn't redirect.
      d.session["user_email"] = "seth@example.com"
      d.navigation.push(UI::NavigationCoordinator::Route.new(:todos))
      d.mount_screen(:todos)
      before_token = d.current_mount_token
      before_depth = d.navigation.depth

      observed_tokens = [] of Int64
      observed_route_ids = [] of Symbol
      d.navigation.on_change do |route|
        observed_tokens << UI::FormState.current_mount_token
        observed_route_ids << route.id
      end

      # Use Tuple action_ref so the dispatcher routes to the
      # SignInController (which defines :back) — avoids the
      # TodosController before_action redirect.
      d.dispatch({ActionDispatcherSpecSignInController, :back})

      d.navigation.current.id.should eq(:sign_in)
      d.navigation.depth.should eq(before_depth - 1) # actually popped
      d.current_mount_token.should be > before_token

      # Renderer's on_change subscriber saw the NEW (popped-to) mount.
      observed_tokens.first.should eq(d.current_mount_token)
      observed_route_ids.first.should eq(:sign_in)
    end

    it "Pop at root is a no-op (no mount_screen, no error, no token bump)" do
      d = build_dispatcher
      before_token = d.current_mount_token
      d.dispatch(:back)
      d.navigation.depth.should eq(1)
      d.current_mount_token.should eq(before_token)
    end

    it "Rerender -> mount_screen + coord.republish (token bump visible to on_change)" do
      d = build_dispatcher
      before_token = d.current_mount_token

      observed_tokens = [] of Int64
      d.navigation.on_change do |route|
        observed_tokens << UI::FormState.current_mount_token
      end

      d.dispatch(:rerender)
      d.current_mount_token.should be > before_token
      observed_tokens.first.should eq(d.current_mount_token)
    end

    it "ReplaceRoot -> mount_screen + coord.replace_root (new mount visible to on_change)" do
      d = build_dispatcher
      d.navigation.push(UI::NavigationCoordinator::Route.new(:todos))
      d.mount_screen(:todos)

      observed_tokens = [] of Int64
      observed_route_id = [] of Symbol
      d.navigation.on_change do |route|
        observed_tokens << UI::FormState.current_mount_token
        observed_route_id << route.id
      end

      d.dispatch({ActionDispatcherSpecSignInController, :reset})

      d.navigation.current.id.should eq(:sign_in)
      d.navigation.depth.should eq(1)
      observed_tokens.first.should eq(d.current_mount_token)
      observed_route_id.first.should eq(:sign_in)
    end

    it "RenderInline -> on_render_inline callback fires" do
      d = build_dispatcher
      captured = [] of UI::View
      d.on_render_inline = ->(view : UI::View) { captured << view; nil }
      d.dispatch(:inline)
      captured.size.should eq(1)
    end
  end

  describe "before_action wiring" do
    it "runs before_actions before the action method" do
      d = build_dispatcher
      d.dispatch({ActionDispatcherSpecTodosController, :index})
      ActionDispatcherSpecTodosController.before_action_calls.should be > 0
    end

    it "before_action returning UI::ActionResult short-circuits + redirects" do
      d = build_dispatcher
      # require_signed_in redirects to :sign_in when no user_email; the
      # session is empty here so we expect the short-circuit.
      d.dispatch({ActionDispatcherSpecTodosController, :index})

      # The action method NEVER ran (calls list empty)
      ActionDispatcherSpecTodosController.calls.should be_empty
      # And we navigated to :sign_in via the before_action's navigate_to
      d.navigation.current.id.should eq(:sign_in)
    end

    it "before_action returning nil allows the action to run" do
      d = build_dispatcher
      d.session["user_email"] = "seth@example.com"
      d.dispatch({ActionDispatcherSpecTodosController, :index})
      ActionDispatcherSpecTodosController.calls.should eq([:index])
    end
  end

  describe "Tuple action_ref" do
    it "resolves to the given Controller class + method" do
      d = build_dispatcher
      # Even though current route is :sign_in, route to inline controller:
      d.on_render_inline = ->(view : UI::View) { nil }
      d.dispatch({ActionDispatcherSpecInlineController, :anything})
      # No raise = success; full assertion above for RenderInline path.
    end
  end

  describe "unknown route" do
    it "raises UI::App::UnknownRouteError when current route has no registration" do
      ActionDispatcherSpecApp.bootstrap!
      coord = UI::NavigationCoordinator.new(
        UI::NavigationCoordinator::Route.new(:not_a_route)
      )

      d = UI::ActionDispatcher.new(
        app: ActionDispatcherSpecApp,
        navigation: coord,
        session: UI::Session::InProcess.new,
        flash: UI::Flash::InProcess.new,
        design_tokens: UI::DesignTokens::Tokens.default,
      )

      expect_raises(UI::App::UnknownRouteError, /not_a_route/) do
        d.dispatch(:anything)
      end
    end
  end
end
