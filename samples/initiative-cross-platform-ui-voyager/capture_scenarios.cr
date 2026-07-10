# Phase 8D.3b — Voyager capture scenarios.
#
# Sample-local module (NOT a framework API) that walks the runtime into
# each of the 14 contract states the brief enumerates. Driven via the
# `VOYAGER_CAPTURE_SCENARIO` env var, applied by both the iOS bridge
# (`ios/bridge.cr`) and the macOS host (`macos/host.cr`) AFTER they
# construct their state / coord / dispatcher trio.
#
# Per Codex HIGH 1: each scenario's LAST call MUST be
# `dispatcher.mount_screen(coord.current)` so `dispatcher.current_form_state`
# is seeded from the scenario's final route.params before the first
# render. mount_screen also installs `UI::FormState.current` which the
# renderer's wire-time hooks read.
#
# Per Codex BLOCKER 1: scenarios walk `coord` to a state where
# `coord.current.id` matches the slug Swift will request via
# `VOYAGER_ROOT_SLUG`. Multi-depth scenarios (e.g. row 04 / 08 with the
# editor pushed atop todos) end at depth 2 — the iOS bridge's depth-1
# resync (`bridge.cr:246`) only fires at depth 1, so the scenario walk
# is preserved.
#
# Per Codex BLOCKER 2: the editor's title field renders from `seed_title`
# (line 38, 67 of `screens/todo_editor.cr`), which is the editing todo's
# title. So "editor prefilled with 'Rem 6.11 test'" is achieved by adding
# a todo with that title and pushing the editor route with its id —
# not by `FormState.register("title", "...")` (which is seed-only and
# does not flow into the rendered text or the Save-disabled state).
#
# Scenarios mutate the passed-in state, coord, dispatcher instances —
# they MUST NOT re-allocate state (the hosts have already assigned
# `Voyager.state` to the same instance, and screen builds read
# `Voyager.state`, so a fresh State here would be invisible to screens).

require "./app"

module Voyager
  module CaptureScenarios
    record Result, route_id : Symbol

    # Slug each scenario should be launched with (Swift's
    # VOYAGER_ROOT_SLUG / macOS host's ROOT_SLUG). Per Codex BLOCKER 1,
    # the launch slug MUST match the scenario's final coord.current so
    # the iOS depth-1 resync does not undo the scenario's walk.
    SCENARIO_TO_SLUG = {
      "row-01-sign-in"               => "voyager-sign-in",
      "row-02-todos-launch"          => "voyager-todos",
      "row-03-editor-empty"          => "voyager-todo-editor",
      "row-04-editor-prefilled"      => "voyager-todo-editor",
      "row-05-todos-after-save"      => "voyager-todos",
      "row-06-todos-row-completed"   => "voyager-todos",
      "row-07-todos-swipe-row"       => "voyager-todos",
      "row-08-editor-edit-prefilled" => "voyager-todo-editor",
      "row-09-todos-after-edit"      => "voyager-todos",
      "row-10-todos-after-delete"    => "voyager-todos",
      "row-11-settings-default"      => "voyager-settings",
      "row-12-settings-toggled"      => "voyager-settings",
      "row-13-todos-filtered"        => "voyager-todos",
      "row-14-todos-unfiltered"      => "voyager-todos",
    }

    # Apply the named scenario, mutating the runtime substrate into the
    # target visual end state. Raises on unknown scenario.
    def self.apply(scenario_id : String,
                   state : Voyager::State,
                   coord : UI::NavigationCoordinator,
                   dispatcher : UI::ActionDispatcher) : Result
      case scenario_id
      when "row-01-sign-in"               then row_01(state, coord, dispatcher)
      when "row-02-todos-launch"          then row_02(state, coord, dispatcher)
      when "row-03-editor-empty"          then row_03(state, coord, dispatcher)
      when "row-04-editor-prefilled"      then row_04(state, coord, dispatcher)
      when "row-05-todos-after-save"      then row_05(state, coord, dispatcher)
      when "row-06-todos-row-completed"   then row_06(state, coord, dispatcher)
      when "row-07-todos-swipe-row"       then row_07(state, coord, dispatcher)
      when "row-08-editor-edit-prefilled" then row_08(state, coord, dispatcher)
      when "row-09-todos-after-edit"      then row_09(state, coord, dispatcher)
      when "row-10-todos-after-delete"    then row_10(state, coord, dispatcher)
      when "row-11-settings-default"      then row_11(state, coord, dispatcher)
      when "row-12-settings-toggled"      then row_12(state, coord, dispatcher)
      when "row-13-todos-filtered"        then row_13(state, coord, dispatcher)
      when "row-14-todos-unfiltered"      then row_14(state, coord, dispatcher)
      else
        raise "Unknown VOYAGER_CAPTURE_SCENARIO: #{scenario_id.inspect}"
      end
    end

    # ------------------------------------------------------------------
    # Row 01 — Just-launched Sign-in screen.
    # ------------------------------------------------------------------
    private def self.row_01(state, coord, dispatcher) : Result
      coord.replace_root(UI::NavigationCoordinator::Route.new(:sign_in))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :sign_in)
    end

    # ------------------------------------------------------------------
    # Row 02 — Todos with 5 seeded rows (after sign-in).
    # ------------------------------------------------------------------
    private def self.row_02(state, coord, dispatcher) : Result
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ------------------------------------------------------------------
    # Row 03 — Editor empty (new-todo path). todo_id="0" signals new.
    # Depth 2: todos -> todo_editor. The iOS depth-1 resync only fires
    # at depth 1, so this scenario's walk survives the bridge's
    # initial resync logic.
    # ------------------------------------------------------------------
    private def self.row_03(state, coord, dispatcher) : Result
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      params = {:todo_id => "0"} of Symbol => String
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, params))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todo_editor)
    end

    # ------------------------------------------------------------------
    # Row 04 — Editor prefilled with "Rem 6.11 test", Save enabled.
    # Per Codex BLOCKER 2: prefill is via an existing todo's title, not
    # via FormState.register (which is seed-only).
    # ------------------------------------------------------------------
    private def self.row_04(state, coord, dispatcher) : Result
      todo = state.add_todo("Rem 6.11 test")
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      params = {:todo_id => todo.id.to_s} of Symbol => String
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, params))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todo_editor)
    end

    # ------------------------------------------------------------------
    # Row 05 — After Save: Todos with the new row visible.
    # ------------------------------------------------------------------
    private def self.row_05(state, coord, dispatcher) : Result
      state.add_todo("Rem 6.11 test")
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ------------------------------------------------------------------
    # Row 06 — Row completed (strikethrough + chart shifted).
    # Marks the first seeded todo (id=1, "Buy groceries") completed.
    # ------------------------------------------------------------------
    private def self.row_06(state, coord, dispatcher) : Result
      first = state.todos.first?
      if first
        first.completed = true
      end
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ------------------------------------------------------------------
    # Row 07 — Swipe revealed.
    # iOS caveat (Codex HIGH 3 / Brief R1): UI::SwipeActionRow has no
    # force-revealed setter, so iOS captures the row AT REST. macOS's
    # AppKit renderer (`appkit_renderer.cr:3801`) renders SwipeActionRow
    # with the trailing Edit + Delete buttons inline natively — the
    # macOS capture shows what "revealed" looks like on macOS naturally.
    # Either way, the scenario walk is the same: just land on Todos.
    # ------------------------------------------------------------------
    private def self.row_07(state, coord, dispatcher) : Result
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ------------------------------------------------------------------
    # Row 08 — Editor prefilled from swipe-Edit.
    # Same visual end state as row 04, but uses one of the existing
    # default-seeded todos (id=1, "Buy groceries") so the editor opens
    # showing the seeded title, illustrating the swipe-Edit -> editor
    # navigation path. Depth 2: todos -> todo_editor with todo_id=1.
    # ------------------------------------------------------------------
    private def self.row_08(state, coord, dispatcher) : Result
      first = state.todos.first?
      target_id = first ? first.id : 1
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      params = {:todo_id => target_id.to_s} of Symbol => String
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, params))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todo_editor)
    end

    # ------------------------------------------------------------------
    # Row 09 — After Edit Save: row's title updated.
    # Mutates the first seed todo's title to "Walk the dog updated".
    # ------------------------------------------------------------------
    private def self.row_09(state, coord, dispatcher) : Result
      first = state.todos.first?
      if first
        first.title = "Walk the dog updated"
      end
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ------------------------------------------------------------------
    # Row 10 — After Delete: row removed (4 visible instead of 5).
    # ------------------------------------------------------------------
    private def self.row_10(state, coord, dispatcher) : Result
      first = state.todos.first?
      if first
        state.delete_todo(first.id)
      end
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ------------------------------------------------------------------
    # Row 11 — Settings default (Hide-completed OFF).
    # ------------------------------------------------------------------
    private def self.row_11(state, coord, dispatcher) : Result
      state.hide_completed = false
      coord.replace_root(UI::NavigationCoordinator::Route.new(:settings))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :settings)
    end

    # ------------------------------------------------------------------
    # Row 12 — Settings toggled (Hide-completed ON).
    # ------------------------------------------------------------------
    private def self.row_12(state, coord, dispatcher) : Result
      state.hide_completed = true
      coord.replace_root(UI::NavigationCoordinator::Route.new(:settings))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :settings)
    end

    # ------------------------------------------------------------------
    # Row 13 — Todos filtered (hide_completed=true).
    # Same coord shape as row 02 but with the filter on.
    # ------------------------------------------------------------------
    private def self.row_13(state, coord, dispatcher) : Result
      state.hide_completed = true
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ------------------------------------------------------------------
    # Row 14 — Todos unfiltered (hide_completed=false).
    # Visually identical to row 02; shipped as a distinct artifact per
    # brief MEDIUM 3 so the artifact mapping table has distinct entries
    # (the README documents the equivalence).
    # ------------------------------------------------------------------
    private def self.row_14(state, coord, dispatcher) : Result
      state.hide_completed = false
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end
  end
end
