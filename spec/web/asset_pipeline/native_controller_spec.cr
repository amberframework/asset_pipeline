require "../spec_helper"
require "../../../src/asset_pipeline/native_controller"

private def build_test_context(action_params : Hash(String, String) = {} of String => String) : UI::ScreenContext::Native
  UI::ScreenContext::Native.new(
    form_state: UI::FormState.new,
    session: UI::Session::InProcess.new,
    flash: UI::Flash::InProcess.new,
    design_tokens: UI::DesignTokens::Tokens.default,
    navigation: UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:start)),
    action_params: action_params,
  )
end

# Concrete controller exposing each action-helper.
private class NativeControllerSpecController < UI::Controller
  before_action :record_invocation

  class_getter invocations : Array(Symbol) = [] of Symbol

  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    case name
    when :navigate then test_navigate(context)
    when :pop      then test_pop(context)
    when :rerender then test_rerender(context)
    when :replace  then test_replace(context)
    when :inline   then test_inline(context)
    else raise UI::Controller::UnknownActionError.new(
      "NativeControllerSpecController has no action :#{name}")
    end
  end

  def test_navigate(context) : UI::ActionResult
    navigate_to(:next_screen, {:id => "7"})
  end

  def test_pop(context) : UI::ActionResult
    pop_navigation
  end

  def test_rerender(context) : UI::ActionResult
    render_current_screen
  end

  def test_replace(context) : UI::ActionResult
    replace_root(:root_screen)
  end

  def test_inline(context) : UI::ActionResult
    respond_with(UI::Label.new("inline"))
  end

  def record_invocation(context) : UI::ActionResult?
    self.class.invocations << :before_action_ran
    nil
  end
end

# Controller whose before_action SHORT-CIRCUITS via a redirect.
private class NativeControllerSpecRedirector < UI::Controller
  before_action :require_unauth

  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    case name
    when :index then index(context)
    else raise UI::Controller::UnknownActionError.new("no #{name}")
    end
  end

  def index(context) : UI::ActionResult
    render_current_screen
  end

  def require_unauth(context) : UI::ActionResult?
    # Always redirect — proves short-circuit works.
    navigate_to(:authed_home)
  end
end

# Bare controller — used to assert UnknownActionError on the abstract
# fallback `dispatch_action`.
private class NativeControllerSpecBareController < UI::Controller
end

describe UI::Controller do
  it "navigate_to returns ActionResult::Navigate with route_id + params" do
    ctrl = NativeControllerSpecController.new
    result = ctrl.dispatch_action(:navigate, build_test_context).as(UI::ActionResult::Navigate)
    result.route_id.should eq(:next_screen)
    result.params[:id].should eq("7")
  end

  it "pop_navigation returns ActionResult::Pop" do
    ctrl = NativeControllerSpecController.new
    result = ctrl.dispatch_action(:pop, build_test_context)
    result.should be_a(UI::ActionResult::Pop)
  end

  it "render_current_screen returns ActionResult::Rerender" do
    ctrl = NativeControllerSpecController.new
    result = ctrl.dispatch_action(:rerender, build_test_context)
    result.should be_a(UI::ActionResult::Rerender)
  end

  it "replace_root returns ActionResult::ReplaceRoot" do
    ctrl = NativeControllerSpecController.new
    result = ctrl.dispatch_action(:replace, build_test_context).as(UI::ActionResult::ReplaceRoot)
    result.route_id.should eq(:root_screen)
  end

  it "respond_with returns ActionResult::RenderInline carrying the view" do
    ctrl = NativeControllerSpecController.new
    result = ctrl.dispatch_action(:inline, build_test_context).as(UI::ActionResult::RenderInline)
    result.view.should be_a(UI::Label)
  end

  it "unknown action raises UnknownActionError" do
    ctrl = NativeControllerSpecController.new
    expect_raises(UI::Controller::UnknownActionError, /no action :nope/) do
      ctrl.dispatch_action(:nope, build_test_context)
    end
  end

  it "abstract default dispatch_action raises a guidance error" do
    ctrl = NativeControllerSpecBareController.new
    expect_raises(UI::Controller::UnknownActionError, /did not override/) do
      ctrl.dispatch_action(:anything, build_test_context)
    end
  end

  it "before_action callbacks are registered on the subclass" do
    NativeControllerSpecController._before_actions.size.should eq(1)
  end

  it "before_action returning a UI::ActionResult short-circuits" do
    cb = NativeControllerSpecRedirector._before_actions.first
    ctrl = NativeControllerSpecRedirector.new
    short_circuit = cb.call(ctrl, build_test_context)
    short_circuit.should be_a(UI::ActionResult::Navigate)
    short_circuit.as(UI::ActionResult::Navigate).route_id.should eq(:authed_home)
  end

  it "before_action returning nil allows the action to run (semantically)" do
    NativeControllerSpecController.invocations.clear
    cb = NativeControllerSpecController._before_actions.first
    ctrl = NativeControllerSpecController.new
    result = cb.call(ctrl, build_test_context)
    result.should be_nil
    NativeControllerSpecController.invocations.should eq([:before_action_ran])
  end

  it "each subclass has its own _before_actions list (no shared array)" do
    a = NativeControllerSpecController._before_actions
    b = NativeControllerSpecRedirector._before_actions
    a.should_not be(b)
  end
end
