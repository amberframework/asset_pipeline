module Voyager
  # Phase 8D.1 — TodosController.
  #
  # Owns the 5 user-intent actions reachable from TodosScreen:
  #   :new_todo       — Navigate(:todo_editor, params: {todo_id: "0"})
  #   :edit_row       — Navigate(:todo_editor, params: {todo_id: <action_params["todo_id"]>})
  #   :delete_row     — mutate Voyager.state, Rerender
  #   :toggle_row     — flip Todo.completed, Rerender
  #   :open_settings  — Navigate(:settings)
  class TodosController < UI::Controller
    def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
      case name
      when :new_todo       then new_todo(context)
      when :edit_row       then edit_row(context)
      when :delete_row     then delete_row(context)
      when :toggle_row     then toggle_row(context)
      when :open_settings  then open_settings(context)
      else
        raise UI::Controller::UnknownActionError.new(
          "TodosController has no action :#{name}"
        )
      end
    end

    def new_todo(context : UI::ScreenContext::Native) : UI::ActionResult
      UI::ActionResult::Navigate.new(
        :todo_editor,
        {:todo_id => "0"} of Symbol => String
      )
    end

    def edit_row(context : UI::ScreenContext::Native) : UI::ActionResult
      todo_id = context.action_params["todo_id"]? || "0"
      UI::ActionResult::Navigate.new(
        :todo_editor,
        {:todo_id => todo_id} of Symbol => String
      )
    end

    def delete_row(context : UI::ScreenContext::Native) : UI::ActionResult
      id = (context.action_params["todo_id"]? || "0").to_i? || 0
      Voyager.state.delete_todo(id)
      UI::ActionResult::Rerender.new
    end

    def toggle_row(context : UI::ScreenContext::Native) : UI::ActionResult
      id = (context.action_params["todo_id"]? || "0").to_i? || 0
      if todo = Voyager.state.find_todo(id)
        todo.completed = !todo.completed
      end
      UI::ActionResult::Rerender.new
    end

    def open_settings(context : UI::ScreenContext::Native) : UI::ActionResult
      UI::ActionResult::Navigate.new(:settings)
    end
  end
end
