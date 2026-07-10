# Phase 10A.0a — Family 1 naming rule: Controller class names end in `Controller`.
#
# Every subclass of `UI::Controller` must use a class name ending in
# `Controller` (e.g. `TodosController`). Detected via regex on
# `class Foo < UI::Controller` declarations.

require "../convention_rule"

# Asserts that subclasses of `UI::Controller` end in `Controller`.
class ControllerClassNamingRule < ConventionRule
  PATTERN = /^\s*class\s+([A-Za-z_][A-Za-z0-9_]*)\s*<\s*(?:::)?UI::Controller\b/

  def rule_name : String
    "family_1/controller_class_naming"
  end

  def check(file_path : String, content : String) : Array(Diagnostic)
    diagnostics = [] of Diagnostic
    content.each_line.with_index(1) do |line, lineno|
      if m = PATTERN.match(line)
        class_name = m[1]
        unless class_name.ends_with?("Controller")
          diagnostics << Diagnostic.new(
            file_path: file_path,
            line: lineno,
            rule_name: rule_name,
            message: "Class '#{class_name}' inherits UI::Controller but does not end in 'Controller'",
            suggested_fix: "rename to '#{class_name}Controller'"
          )
        end
      end
    end
    diagnostics
  end
end
