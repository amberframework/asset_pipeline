require "../../../src/ui"
require "spec"

# Phase 6.10 D1 — UI::NavigationCoordinator
#
# Contract:
#   - push / pop / replace_root / pop_to_root mutate @routes, then notify.
#   - subscribers see the NEW current route (mutation precedes notify).
#   - pop at depth 1 is a no-op and does NOT notify.
#   - replace_root resets the whole stack (depth always becomes 1).
#   - multiple subscribers all fire on each change.
describe UI::NavigationCoordinator do
  describe "#initialize" do
    it "starts with the given root as the only route" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.current.id.should eq :sign_in
      coord.depth.should eq 1
      coord.routes.size.should eq 1
    end

    it "starts with zero subscribers" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.subscriber_count.should eq 0
    end
  end

  describe "#push" do
    it "appends the route and updates #current" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      coord.current.id.should eq :todos
      coord.depth.should eq 2
    end

    it "fires on_change AFTER the route is appended" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      observed = [] of Symbol
      coord.on_change { |route| observed << route.id }
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      observed.should eq [:todos]
    end

    it "passes params through the route" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todos))
      params = {:id => "42"} of Symbol => String
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, params))
      coord.current.params[:id].should eq "42"
    end
  end

  describe "#pop" do
    it "removes the top route and updates #current" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      popped = coord.pop
      popped.try(&.id).should eq :todos
      coord.current.id.should eq :sign_in
    end

    it "fires on_change AFTER mutating the stack" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      observed = [] of Symbol
      coord.on_change { |route| observed << route.id }
      coord.pop
      observed.should eq [:sign_in]
    end

    it "returns nil and does NOT fire on_change when at root" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      observed = [] of Symbol
      coord.on_change { |route| observed << route.id }
      coord.pop.should be_nil
      observed.should be_empty
      coord.depth.should eq 1
    end
  end

  describe "#pop_to_root" do
    it "drops every pushed route" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      params = {:id => "1"} of Symbol => String
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, params))
      coord.pop_to_root
      coord.depth.should eq 1
      coord.current.id.should eq :sign_in
    end

    it "fires on_change exactly once when popping multiple levels" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor))
      observed = [] of Symbol
      coord.on_change { |route| observed << route.id }
      coord.pop_to_root
      observed.should eq [:sign_in]
    end

    it "is a no-op at root depth" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      observed = [] of Symbol
      coord.on_change { |route| observed << route.id }
      coord.pop_to_root
      observed.should be_empty
    end
  end

  describe "#replace_root" do
    it "replaces the entire stack with a new root" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      coord.replace_root(UI::NavigationCoordinator::Route.new(:dashboard))
      coord.depth.should eq 1
      coord.current.id.should eq :dashboard
    end

    it "fires on_change with the new root" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      observed = [] of Symbol
      coord.on_change { |route| observed << route.id }
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      observed.should eq [:todos]
    end
  end

  describe "#on_change" do
    it "supports multiple subscribers; all fire in registration order" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      order = [] of String
      coord.on_change { |_| order << "A" }
      coord.on_change { |_| order << "B" }
      coord.subscriber_count.should eq 2
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      order.should eq ["A", "B"]
    end

    it "subscribers see the NEW current route, not the prior one" do
      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
      seen_during_push : Symbol? = nil
      coord.on_change { |route| seen_during_push = route.id }
      coord.push(UI::NavigationCoordinator::Route.new(:todos))
      seen_during_push.should eq :todos
    end
  end
end
