require "../spec_helper"
require "../../../samples/initiative-cross-platform-ui-voyager/app"

# Phase 8D.1 — per-controller unit specs.
#
# Each controller is exercised by constructing a fresh
# ScreenContext::Native (with the relevant form_state/action_params)
# and asserting that:
#   - the right action method returns the right ActionResult subtype,
#   - unknown action names raise UnknownActionError,
#   - the specific contracts from the brief (ReplaceRoot vs Navigate,
#     Pop, Rerender) are honored.
#
# These are isolated-controller tests (no dispatcher integration);
# dispatcher integration scenarios are in
# spec/asset_pipeline/voyager_dispatcher_integration_spec.cr (Phase
# 8D.1 iter 2).

private def make_ctx(
  form_values : Hash(String, String) = {} of String => String,
  action_params : Hash(String, String) = {} of String => String,
) : UI::ScreenContext::Native
  fs = UI::FormState.new
  form_values.each { |k, v| fs.update(k, v) }
  coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
  UI::ScreenContext::Native.new(
    form_state: fs,
    session: UI::Session::InProcess.new,
    flash: UI::Flash::InProcess.new,
    design_tokens: UI::DesignTokens::Tokens.default,
    navigation: coord,
    action_params: action_params,
  )
end

describe Voyager::SignInController do
  it "submit with non-empty email + password returns ReplaceRoot(:todos)" do
    ctrl = Voyager::SignInController.new
    ctx = make_ctx(form_values: {"email" => "seth@example.com", "password" => "hunter2"})

    result = ctrl.dispatch_action(:submit, ctx)
    result.should be_a UI::ActionResult::ReplaceRoot
    result.as(UI::ActionResult::ReplaceRoot).route_id.should eq :todos
  end

  it "submit stashes user_email in session on success" do
    ctrl = Voyager::SignInController.new
    ctx = make_ctx(form_values: {"email" => "seth@example.com", "password" => "hunter2"})

    ctrl.dispatch_action(:submit, ctx)
    ctx.session["user_email"].should eq "seth@example.com"
  end

  it "submit with empty email returns Rerender + sets flash[\"error\"]" do
    ctrl = Voyager::SignInController.new
    ctx = make_ctx(form_values: {"email" => "", "password" => "hunter2"})

    result = ctrl.dispatch_action(:submit, ctx)
    result.should be_a UI::ActionResult::Rerender
    ctx.flash["error"]?.should_not be_nil
  end

  it "submit with empty password returns Rerender" do
    ctrl = Voyager::SignInController.new
    ctx = make_ctx(form_values: {"email" => "seth@example.com", "password" => ""})

    result = ctrl.dispatch_action(:submit, ctx)
    result.should be_a UI::ActionResult::Rerender
  end

  it "raises UnknownActionError on an unrecognised action name" do
    ctrl = Voyager::SignInController.new
    ctx = make_ctx
    expect_raises(UI::Controller::UnknownActionError) do
      ctrl.dispatch_action(:bogus, ctx)
    end
  end
end

describe Voyager::TodosController do
  it ":new_todo returns Navigate(:todo_editor) with todo_id => \"0\"" do
    ctrl = Voyager::TodosController.new
    ctx = make_ctx
    result = ctrl.dispatch_action(:new_todo, ctx)
    result.should be_a UI::ActionResult::Navigate
    nav = result.as(UI::ActionResult::Navigate)
    nav.route_id.should eq :todo_editor
    nav.params[:todo_id]?.should eq "0"
  end

  it ":edit_row returns Navigate(:todo_editor) with action_params[\"todo_id\"]" do
    Voyager.state = Voyager::State.new
    ctrl = Voyager::TodosController.new
    ctx = make_ctx(action_params: {"todo_id" => "3"})
    result = ctrl.dispatch_action(:edit_row, ctx)
    result.should be_a UI::ActionResult::Navigate
    nav = result.as(UI::ActionResult::Navigate)
    nav.route_id.should eq :todo_editor
    nav.params[:todo_id]?.should eq "3"
  end

  it ":delete_row mutates Voyager.state and returns Rerender" do
    state = Voyager::State.new
    Voyager.state = state
    initial_count = state.todos.size

    ctrl = Voyager::TodosController.new
    ctx = make_ctx(action_params: {"todo_id" => "1"})
    result = ctrl.dispatch_action(:delete_row, ctx)

    result.should be_a UI::ActionResult::Rerender
    state.todos.size.should eq(initial_count - 1)
    state.find_todo(1).should be_nil
  end

  it ":toggle_row flips the targeted todo and returns Rerender" do
    state = Voyager::State.new
    Voyager.state = state
    target = state.find_todo(1).not_nil!
    initial_completed = target.completed

    ctrl = Voyager::TodosController.new
    ctx = make_ctx(action_params: {"todo_id" => "1"})
    result = ctrl.dispatch_action(:toggle_row, ctx)

    result.should be_a UI::ActionResult::Rerender
    state.find_todo(1).not_nil!.completed.should eq !initial_completed
  end

  it ":open_settings returns Navigate(:settings)" do
    ctrl = Voyager::TodosController.new
    ctx = make_ctx
    result = ctrl.dispatch_action(:open_settings, ctx)
    result.should be_a UI::ActionResult::Navigate
    result.as(UI::ActionResult::Navigate).route_id.should eq :settings
  end

  it "raises UnknownActionError on an unrecognised action name" do
    ctrl = Voyager::TodosController.new
    expect_raises(UI::Controller::UnknownActionError) do
      ctrl.dispatch_action(:bogus, make_ctx)
    end
  end
end

describe Voyager::TodoEditorController do
  it ":save with an existing todo_id mutates the todo and returns Pop" do
    state = Voyager::State.new
    Voyager.state = state
    target = state.find_todo(2).not_nil!
    original_title = target.title

    ctrl = Voyager::TodoEditorController.new
    ctx = make_ctx(
      form_values: {"todo_id" => "2", "title" => "Refurbished title", "note" => "n", "completed" => "true"}
    )
    result = ctrl.dispatch_action(:save, ctx)

    result.should be_a UI::ActionResult::Pop
    state.find_todo(2).not_nil!.title.should eq "Refurbished title"
    state.find_todo(2).not_nil!.completed.should be_true
    target.title.should_not eq original_title
  end

  it ":save with todo_id=\"0\" creates a new todo and returns Pop" do
    state = Voyager::State.new
    Voyager.state = state
    initial_count = state.todos.size

    ctrl = Voyager::TodoEditorController.new
    ctx = make_ctx(
      form_values: {"todo_id" => "0", "title" => "Brand new", "note" => "", "completed" => "false"}
    )
    result = ctrl.dispatch_action(:save, ctx)

    result.should be_a UI::ActionResult::Pop
    state.todos.size.should eq(initial_count + 1)
    state.todos.last.title.should eq "Brand new"
  end

  it ":save with empty title still returns Pop and does NOT mutate" do
    state = Voyager::State.new
    Voyager.state = state
    initial_count = state.todos.size

    ctrl = Voyager::TodoEditorController.new
    ctx = make_ctx(
      form_values: {"todo_id" => "0", "title" => "   ", "completed" => "false"}
    )
    result = ctrl.dispatch_action(:save, ctx)

    result.should be_a UI::ActionResult::Pop
    state.todos.size.should eq initial_count
  end

  it ":cancel returns Pop without mutating state" do
    state = Voyager::State.new
    Voyager.state = state
    snapshot = state.todos.size

    ctrl = Voyager::TodoEditorController.new
    ctx = make_ctx(form_values: {"todo_id" => "1", "title" => "ignored"})
    result = ctrl.dispatch_action(:cancel, ctx)

    result.should be_a UI::ActionResult::Pop
    state.todos.size.should eq snapshot
  end

  it "raises UnknownActionError on an unrecognised action name" do
    ctrl = Voyager::TodoEditorController.new
    expect_raises(UI::Controller::UnknownActionError) do
      ctrl.dispatch_action(:bogus, make_ctx)
    end
  end
end

describe Voyager::SettingsController do
  it ":toggle_filter flips Voyager.state.hide_completed and returns Rerender" do
    state = Voyager::State.new
    Voyager.state = state
    initial = state.hide_completed

    ctrl = Voyager::SettingsController.new
    result = ctrl.dispatch_action(:toggle_filter, make_ctx)

    result.should be_a UI::ActionResult::Rerender
    state.hide_completed.should eq !initial

    # Toggling again returns to initial.
    ctrl.dispatch_action(:toggle_filter, make_ctx)
    state.hide_completed.should eq initial
  end

  it ":back returns Pop" do
    ctrl = Voyager::SettingsController.new
    result = ctrl.dispatch_action(:back, make_ctx)
    result.should be_a UI::ActionResult::Pop
  end

  it "raises UnknownActionError on an unrecognised action name" do
    ctrl = Voyager::SettingsController.new
    expect_raises(UI::Controller::UnknownActionError) do
      ctrl.dispatch_action(:bogus, make_ctx)
    end
  end
end
