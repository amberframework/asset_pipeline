require "../../../src/ui"
require "../../../samples/initiative-cross-platform-ui-voyager/app"
require "spec"

# Phase 6.10 — Voyager state-propagation litmus.
#
# THIS IS THE MAKE-OR-BREAK TEST. Per the brief:
#
#   "Toggle Settings 'Hide completed' → tap back → Todos list AND
#    chart reflect immediately. If state-propagation across pop
#    doesn't work, Phase 6.10 fails."
#
# This Crystal-side spec covers the contract that the NATIVE targets
# (macOS + iOS) rely on: when the coordinator pops back to :todos,
# the host calls Voyager.build_route(state, coord, route) again, and
# the returned view tree reflects the NEW state.hide_completed value.
#
# (The web demo's state-propagation is verified via a manual
# browser test recorded in docs/initiative-cross-platform-ui/baselines/.)
describe "Voyager state-propagation litmus" do
  it "Todos route reflects hide_completed=false initially" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todos))
    view = Voyager.build_route(state, coord, coord.current)

    renderer = UI::Web::Renderer.new
    # Phase 6.11 — brand override dropped; default tokens via renderer constructor.
    html = renderer.render(view)

    # All 5 seeded todos visible (3 open, 2 completed).
    html.should contain "Buy groceries"
    html.should contain "Call dentist"
    html.should contain "Water plants"
    # Chart: 3 open / 2 done.
    html.should contain "data-testid=\"voyager-count-open\">3"
    html.should contain "data-testid=\"voyager-count-done\">2"
    # No filter banner.
    html.should_not contain "Completed items hidden"
  end

  it "Todos route reflects hide_completed=true after mutation" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todos))

    # Simulate the navigation flow:
    #   1. Coordinator at :todos, state.hide_completed=false
    #   2. Push :settings, toggle on, pop
    # We model the toggle by mutating state directly (the actual
    # toggle's on_change closure does the same thing).
    coord.push(UI::NavigationCoordinator::Route.new(:settings))
    state.hide_completed = true
    coord.pop  # back to :todos

    # Now rebuild the visible route — this is what the host does
    # in its coordinator.on_change handler.
    view = Voyager.build_route(state, coord, coord.current)
    renderer = UI::Web::Renderer.new
    # Phase 6.11 — brand override dropped; default tokens via renderer constructor.
    html = renderer.render(view)

    # The two completed todos must be GONE from the visible list.
    html.should_not contain "data-testid=\"voyager-todo-row-3\""  # Call dentist (completed)
    html.should_not contain "data-testid=\"voyager-todo-row-5\""  # Water plants (completed)
    # The 3 open todos remain.
    html.should contain "data-testid=\"voyager-todo-row-1\""  # Buy groceries
    html.should contain "data-testid=\"voyager-todo-row-2\""  # quarterly report
    html.should contain "data-testid=\"voyager-todo-row-4\""  # Read a book
    # Filter banner is now visible.
    html.should contain "Completed items hidden"
    # Phase 6.11 — the chart now shows underlying totals so the user
    # always sees how many completed items are hidden. The Done card
    # visually dims when filtering is on (per brief rows 13-14).
    html.should contain "data-testid=\"voyager-count-open\">3"
    html.should contain "data-testid=\"voyager-count-done\">2"
  end

  it "the chart counts show the underlying totals when hide_completed is on" do
    # Phase 6.11 revision: per the 14-row contract, the chart shows
    # Open + Done totals (independent of the filter) so the user can
    # see how many items they've completed even while filtered.
    state = Voyager::State.new
    state.hide_completed = true
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todos))

    view = Voyager.build_route(state, coord, coord.current)
    renderer = UI::Web::Renderer.new
    html = renderer.render(view)

    html.should contain "data-testid=\"voyager-count-open\">3"
    html.should contain "data-testid=\"voyager-count-done\">2"

    # The underlying totals match.
    state.open_count_total.should eq 3
    state.completed_count_total.should eq 2
  end

  it "Coordinator on_change fires the rebuild callback on pop" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todos))
    fires = [] of Symbol
    coord.on_change { |route| fires << route.id }

    coord.push(UI::NavigationCoordinator::Route.new(:settings))
    state.hide_completed = true
    coord.pop

    fires.should eq [:settings, :todos]
  end

  it "Adding a todo via the editor then popping back updates the chart" do
    state = Voyager::State.new
    coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todos))
    initial_open = state.open_count

    # Push editor, add a new todo (simulating save), pop back.
    params = {:id => "0"} of Symbol => String
    coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, params))
    state.add_todo("New task", "", false)
    coord.pop

    view = Voyager.build_route(state, coord, coord.current)
    renderer = UI::Web::Renderer.new
    html = renderer.render(view)

    html.should contain "New task"
    html.should contain "data-testid=\"voyager-count-open\">#{initial_open + 1}"
  end
end
