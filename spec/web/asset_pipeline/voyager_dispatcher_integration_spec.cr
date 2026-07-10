require "../spec_helper"
require "../../../samples/initiative-cross-platform-ui-voyager/app"

# Phase 8D.1 Item 6 — dispatcher integration scenarios.
#
# These specs prove the Phase 8B dispatch path end-to-end for Voyager's
# controllers:
#   * action ref → controller method → ActionResult →
#     translate_result → coord mutation (push/pop/replace_root) OR
#     republish (Rerender) OR inline render (RenderInline).
#   * mount_screen ordering invariant (Codex iter-4 finding):
#     mount-before-notify so a renderer rebuilding under on_change
#     sees the NEW FormState.
#   * stack-policy contract from the brief:
#     sign_in submit → ReplaceRoot(:todos) → stack == [todos]
#     todos edit_row → Navigate(:todo_editor) → stack ends [todo_editor]
#     settings toggle_filter → Rerender → stack unchanged + state flipped
#     editor cancel → Pop → stack returns to predecessor.

private def fresh_state!
  Voyager.state = Voyager::State.new
end

private def make_dispatcher(initial_route_id : Symbol = :sign_in) : UI::ActionDispatcher
  VoyagerApp.bootstrap!
  coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(initial_route_id))
  d = UI::ActionDispatcher.new(
    app: VoyagerApp,
    navigation: coord,
    session: UI::Session::InProcess.new,
    flash: UI::Flash::InProcess.new,
    design_tokens: UI::DesignTokens::Tokens.default,
  )
  d.mount_screen(coord.current)
  d
end

describe "Voyager dispatcher integration" do
  it "Sign-in submit → ReplaceRoot to :todos (stack policy)" do
    fresh_state!
    d = make_dispatcher(:sign_in)

    # Simulate TextField on_change wiring writing into the dispatcher's
    # FormState (what the renderer hook does at runtime).
    d.current_form_state.update("email", "seth@example.com")
    d.current_form_state.update("password", "hunter2")

    d.dispatch(:submit)

    d.navigation.depth.should eq 1
    d.navigation.current.id.should eq :todos
    d.navigation.routes.map(&.id).should eq [:todos]
    # session carries the email through to TodosScreen.
    d.session["user_email"]?.should eq "seth@example.com"
  end

  it "Todos edit_row → Navigate(:todo_editor) with todo_id in mounted ctx.params" do
    fresh_state!
    d = make_dispatcher(:sign_in)
    # Sign in first → [todos]
    d.current_form_state.update("email", "x@example.com")
    d.current_form_state.update("password", "p")
    d.dispatch(:submit)
    d.navigation.current.id.should eq :todos

    # Dispatch edit_row with todo_id action_params (what the swipe row's
    # Edit on_tap does — the brief's action_ref convention).
    d.dispatch(:edit_row, {"todo_id" => "3"})

    d.navigation.current.id.should eq :todo_editor
    d.navigation.routes.map(&.id).should eq [:todos, :todo_editor]
    # The Navigate's params hash seeded the mounted screen's FormState
    # (dispatcher.mount_screen does this in translate_result before
    # coord.push).
    d.current_form_state.values["todo_id"]?.should eq "3"
  end

  it "Settings toggle_filter → Rerender (state flipped, stack unchanged)" do
    fresh_state!
    d = make_dispatcher(:settings)
    initial_flag = Voyager.state.hide_completed
    initial_stack = d.navigation.routes.map(&.id)

    d.dispatch(:toggle_filter)

    Voyager.state.hide_completed.should eq !initial_flag
    d.navigation.routes.map(&.id).should eq initial_stack
  end

  it "Editor cancel → Pop to :todos (stack policy)" do
    fresh_state!
    d = make_dispatcher(:sign_in)
    d.current_form_state.update("email", "x@example.com")
    d.current_form_state.update("password", "p")
    d.dispatch(:submit)
    # Now [todos]. Open editor.
    d.dispatch(:edit_row, {"todo_id" => "1"})
    d.navigation.routes.map(&.id).should eq [:todos, :todo_editor]

    d.dispatch(:cancel)

    d.navigation.routes.map(&.id).should eq [:todos]
    d.navigation.current.id.should eq :todos
  end

  # Extra coverage — mount-before-notify ordering invariant. The brief's
  # Item 4 + Codex iter-4 finding pin this so renderers subscribed to
  # on_change observe the NEW FormState during their rebuild, not the
  # prior screen's. Wire a renderer-style on_change that snapshots
  # FormState.current and assert it points at the new mount's instance.
  it "translate_result mounts BEFORE publishing on_change (renderer sees new FormState)" do
    fresh_state!
    d = make_dispatcher(:sign_in)
    d.current_form_state.update("email", "a@b.com")
    d.current_form_state.update("password", "p")

    snapshots = [] of UI::FormState
    d.navigation.on_change do |_route|
      snapshots << UI::FormState.current.not_nil!
    end

    pre_state = d.current_form_state
    d.dispatch(:submit)
    post_state = d.current_form_state

    # ReplaceRoot bumps the mount token + swaps current_form_state. The
    # subscriber captured at notify time saw the NEW FormState (the
    # mount-before-notify invariant).
    post_state.should_not be(pre_state)
    snapshots.size.should eq 1
    snapshots.first.should be(post_state)
  end
end
