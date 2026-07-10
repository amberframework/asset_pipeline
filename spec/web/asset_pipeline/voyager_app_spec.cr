require "../spec_helper"
require "../../../samples/initiative-cross-platform-ui-voyager/app"

# Phase 8D.1 — VoyagerApp registration + compat shim specs.
#
# Covers brief Item 1 acceptance:
#   - VoyagerApp.bootstrap! is callable.
#   - VoyagerApp.registration_for(:sign_in).screen_class == Voyager::SignInScreen
#     (and equivalent for the other 3 routes).
#   - initial_route_id == :sign_in.
#   - Voyager.build_route(state, coord, route) compat shim still returns
#     a non-nil view per route.

describe VoyagerApp do
  it "registers all 4 voyager routes with bootstrap!" do
    VoyagerApp.bootstrap!

    routes = VoyagerApp.screens.keys.sort_by(&.to_s)
    routes.should eq([:sign_in, :settings, :todo_editor, :todos].sort_by(&.to_s))
  end

  it "uses :sign_in as the initial route" do
    VoyagerApp.initial_route_id.should eq :sign_in
  end

  it "wires SignInScreen to SignInController" do
    VoyagerApp.bootstrap!
    reg = VoyagerApp.registration_for(:sign_in)
    reg.screen_class.should eq Voyager::SignInScreen
    reg.controller_class.should eq Voyager::SignInController
  end

  it "wires TodosScreen to TodosController" do
    VoyagerApp.bootstrap!
    reg = VoyagerApp.registration_for(:todos)
    reg.screen_class.should eq Voyager::TodosScreen
    reg.controller_class.should eq Voyager::TodosController
  end

  it "wires TodoEditorScreen to TodoEditorController" do
    VoyagerApp.bootstrap!
    reg = VoyagerApp.registration_for(:todo_editor)
    reg.screen_class.should eq Voyager::TodoEditorScreen
    reg.controller_class.should eq Voyager::TodoEditorController
  end

  it "wires SettingsScreen to SettingsController" do
    VoyagerApp.bootstrap!
    reg = VoyagerApp.registration_for(:settings)
    reg.screen_class.should eq Voyager::SettingsScreen
    reg.controller_class.should eq Voyager::SettingsController
  end
end

describe "Voyager.build_route compat shim" do
  it "returns a non-nil view for :sign_in" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
    view = Voyager.build_route(state, coord, coord.current)
    view.should_not be_nil
  end

  it "returns a non-nil view for :todos" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todos))
    view = Voyager.build_route(state, coord, coord.current)
    view.should_not be_nil
  end

  it "returns a non-nil view for :todo_editor with seeded todo_id" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todo_editor))
    params = {:todo_id => "1"} of Symbol => String
    route = UI::NavigationCoordinator::Route.new(:todo_editor, params)
    view = Voyager.build_route(state, coord, route)
    view.should_not be_nil
  end

  it "returns a non-nil view for :settings" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:settings))
    view = Voyager.build_route(state, coord, coord.current)
    view.should_not be_nil
  end

  it "sets Voyager.state to the passed-in state for the duration" do
    state = Voyager::State.new
    state.current_user = "shim-marker@example.com"
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
    Voyager.build_route(state, coord, coord.current)
    Voyager.state.current_user.should eq "shim-marker@example.com"
  end
end

describe "Voyager.route_for_slug / Voyager.slug_for_route_id" do
  it "round-trips all 4 known slugs through route_for_slug + slug_for_route_id" do
    Voyager::SLUGS.each do |slug|
      route = Voyager.route_for_slug(slug)
      Voyager.slug_for_route_id(route.id).should eq slug
    end
  end
end
