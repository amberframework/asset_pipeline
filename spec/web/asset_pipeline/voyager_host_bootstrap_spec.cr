require "../spec_helper"
require "../../../samples/initiative-cross-platform-ui-voyager/host_bootstrap"

# Phase 8D.2 Item 7 — Voyager::HostBootstrap.build spec.
#
# Validates the flag-agnostic host bootstrap helper that the iOS bridge
# (and any future host) calls to construct the dispatcher substrate.
# These specs are the testable proof-point for the entire runtime
# sequence — without them, the iOS bridge's runtime assumptions are
# unverified until the simulator runs.
#
# Per brief §3 Item 7 acceptance:
#   - Returned `state` matches `Voyager.state`.
#   - Returned `dispatcher` matches `Voyager.dispatcher`.
#   - `dispatcher.current_form_state.mount_token != 0` (mount_screen ran).
#   - `dispatcher.navigation.current.id == initial_route_id`.
#   - `dispatcher.dispatch(:submit)` from `:sign_in` mount lands on
#     `Voyager::SignInController` (proven by the controller's
#     observable side effects).
#
# Per R6 (Voyager.dispatcher = nil teardown leak): each `it` block
# resets `Voyager.dispatcher` and `Voyager.state` to a fresh baseline
# so test ordering can't carry state forward.

describe "Voyager::HostBootstrap.build" do
  Spec.before_each do
    Voyager.dispatcher = nil
    Voyager.state = Voyager::State.new
  end

  it "returns a state that matches Voyager.state" do
    result = Voyager::HostBootstrap.build(:sign_in)
    result.state.should be(Voyager.state)
  end

  it "returns a dispatcher that matches Voyager.dispatcher" do
    result = Voyager::HostBootstrap.build(:sign_in)
    result.dispatcher.should be(Voyager.dispatcher.not_nil!)
  end

  it "bumps mount_token after mount_screen (token != 0)" do
    result = Voyager::HostBootstrap.build(:sign_in)
    result.dispatcher.current_form_state.mount_token.should_not eq 0_i64
  end

  it "navigation.current.id matches the initial_route_id (default :sign_in)" do
    result = Voyager::HostBootstrap.build
    result.dispatcher.navigation.current.id.should eq :sign_in
  end

  it "navigation.current.id matches the explicit initial_route_id (:todos)" do
    result = Voyager::HostBootstrap.build(:todos)
    result.dispatcher.navigation.current.id.should eq :todos
  end

  it "dispatcher.dispatch(:submit) from :sign_in invokes SignInController#submit" do
    # SignInController#submit's observable side effects:
    #   * On non-empty email + password: session["user_email"] = email,
    #     ReplaceRoot(:todos) → stack becomes [todos], depth == 1.
    #   * On empty inputs: flash["error"] set, Rerender (stack
    #     unchanged).
    # Both branches are SignInController-only behavior; observing them
    # proves the dispatch landed on SignInController.
    result = Voyager::HostBootstrap.build(:sign_in)
    result.dispatcher.current_form_state.update("email", "seth@example.com")
    result.dispatcher.current_form_state.update("password", "hunter2")

    result.dispatcher.dispatch(:submit)

    result.dispatcher.navigation.current.id.should eq :todos
    result.dispatcher.navigation.depth.should eq 1
    result.dispatcher.session["user_email"]?.should eq "seth@example.com"
  end

  it "dispatcher.dispatch(:submit) with empty inputs rerenders + sets flash error" do
    # The Rerender branch is SignInController-specific behavior too —
    # an empty-input dispatch confirms the controller (not some fallback
    # path) handled the action.
    result = Voyager::HostBootstrap.build(:sign_in)
    initial_stack = result.dispatcher.navigation.routes.map(&.id)

    result.dispatcher.dispatch(:submit)

    result.dispatcher.navigation.routes.map(&.id).should eq initial_stack
    result.dispatcher.flash["error"]?.should eq "Please provide both email and password."
  end
end
