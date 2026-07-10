# Phase 10A.0a — Family 1 naming rule: Screen file basename matches class.
#
# When a file declares `class FooScreen < UI::Screen`, the file's
# basename must be `foo_screen.cr`. Library code that intentionally
# defines `UI::Screen` itself (`src/asset_pipeline/amber_integration.cr`)
# is exempt because it declares the abstract base, not a subclass.

require "../convention_rule"

# Asserts that files defining a `UI::Screen` subclass use the matching
# snake_case basename ending in `_screen.cr`.
class ScreenFileSuffixRule < ConventionRule
  PATTERN = /^\s*class\s+([A-Za-z_][A-Za-z0-9_]*)\s*<\s*(?:::)?UI::Screen\b/

  def rule_name : String
    "family_1/screen_file_suffix"
  end

  def check(file_path : String, content : String) : Array(Diagnostic)
    diagnostics = [] of Diagnostic
    basename = File.basename(file_path)
    content.each_line.with_index(1) do |line, lineno|
      if m = PATTERN.match(line)
        class_name = m[1]
        next unless class_name.ends_with?("Screen")
        expected = "#{snake_case(class_name)}.cr"
        unless basename == expected
          diagnostics << Diagnostic.new(
            file_path: file_path,
            line: lineno,
            rule_name: rule_name,
            message: "File '#{basename}' contains '#{class_name}' but should be named '#{expected}'",
            suggested_fix: "rename file to '#{expected}'"
          )
        end
      end
    end
    diagnostics
  end
end
