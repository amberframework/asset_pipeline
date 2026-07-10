# Phase 10A.0a — Family 1 naming rule: View subclasses live under views/.
#
# Every concrete subclass of `UI::View` (matched by `< View` inside the
# `UI` module or by `< UI::View` in user code) must live under
# `src/ui/views/` or a configured sample-tree allowlist. The intent is
# to keep the view catalog discoverable and to keep ad-hoc one-off
# views from accreting in random directories.
#
# Allowlist is configurable via `.lint_conventions.yml` at the repo
# root (`view_subclass.approved_roots`). The defaults are
# `src/ui/views/` + `samples/`.

require "../convention_rule"

# Asserts that concrete `UI::View` subclasses live under an approved
# directory tree.
class ViewSubclassUnderViewsDirRule < ConventionRule
  # `< View` (inside the UI module) OR `< UI::View` (from user code).
  PATTERN = /^\s*class\s+([A-Za-z_][A-Za-z0-9_]*)(?:\([^)]*\))?\s*<\s*(?:::)?(?:UI::)?View\b/

  # Default approved roots. Overridable via `.lint_conventions.yml`
  # `view_subclass.approved_roots`. The runner threads the config
  # through `configure`.
  DEFAULT_APPROVED_ROOTS = ["src/ui/views/", "samples/"]

  @approved_roots : Array(String) = DEFAULT_APPROVED_ROOTS.dup

  def configure(config : ConventionConfig) : Nil
    @approved_roots = config.view_subclass_approved_roots.dup
  end

  def rule_name : String
    "family_1/view_subclass_under_views_dir"
  end

  def check(file_path : String, content : String) : Array(Diagnostic)
    diagnostics = [] of Diagnostic
    rel = file_path
    rel = rel[Dir.current.size + 1..-1] if rel.starts_with?(Dir.current + "/")
    return diagnostics if @approved_roots.any? { |root| rel.starts_with?(root) }
    return diagnostics if rel == "src/ui/view.cr"

    content.each_line.with_index(1) do |line, lineno|
      if m = PATTERN.match(line)
        class_name = m[1]
        next if class_name == "View"
        diagnostics << Diagnostic.new(
          file_path: file_path,
          line: lineno,
          rule_name: rule_name,
          message: "Class '#{class_name}' inherits UI::View but lives outside an approved root (#{@approved_roots.join(", ")})",
          suggested_fix: "move file under src/ui/views/ or document a sample allowlist entry"
        )
      end
    end
    diagnostics
  end
end
