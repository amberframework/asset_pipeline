# fixture_for: family_1/controller_file_suffix
# expected: fail
# synthetic_path: src/controllers/todos.cr
#
# A UI::Controller subclass whose file basename does NOT match the
# expected snake_case `_controller.cr` — must trip the
# controller_file_suffix rule.

class TodosController < UI::Controller
end
