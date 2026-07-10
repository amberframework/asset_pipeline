# fixture_for: family_1/controller_class_naming,family_1/controller_file_suffix
# expected: pass
# synthetic_path: src/controllers/todos_controller.cr
#
# A well-named UI::Controller subclass in a file with the matching
# snake_case basename. Both naming rules must pass.

class TodosController < UI::Controller
end
