# Phase 10A.0a — Family 1 naming rule: Screen class names end in `Screen`.
#
# Every subclass of `UI::Screen` must use a class name ending in
# `Screen` (e.g. `SignInScreen`, `TodosScreen`). Detected via regex on
# `class Foo < UI::Screen` declarations.

require "../convention_rule"

# Asserts that subclasses of `UI::Screen` end in `Screen`.
class ScreenClassNamingRule < ConventionRule
  PATTERN = /^\s*class\s+([A-Za-z_][A-Za-z0-9_]*)\s*<\s*(?:::)?UI::Screen\b/

  def rule_name : String
    "family_1/screen_class_naming"
  end

  def check(file_path : String, content : String) : Array(Diagnostic)
    diagnostics = [] of Diagnostic
    content.each_line.with_index(1) do |line, lineno|
      if m = PATTERN.match(line)
        class_name = m[1]
        unless class_name.ends_with?("Screen")
          diagnostics << Diagnostic.new(
            file_path: file_path,
            line: lineno,
            rule_name: rule_name,
            message: "Class '#{class_name}' inherits UI::Screen but does not end in 'Screen'",
            suggested_fix: "rename to '#{class_name}Screen'"
          )
        end
      end
    end
    diagnostics
  end
end
