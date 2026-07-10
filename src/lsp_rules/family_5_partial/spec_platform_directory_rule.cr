# Phase 10C.0 — Family 5 (partial): spec platform-directory convention.
#
# Enforces architecture-decisions.md Decision 5: every spec file under
# spec/ lives in spec/web/, spec/native_macos/, spec/native_ios/, or
# spec/native_android/. The only allowed root file is spec/spec_helper.cr
# (kept as a placeholder for any cross-tree shared helper).
#
# Phase 10C.0 iter 2: this rule now extends Phase 10A.0a's `ConventionRule`
# base class (per architect brief §4 line 133). Auto-discovery via
# `ConventionRule.inherited`. The runner (`scripts/lint_conventions.cr`)
# loads this file at compile time, instantiates the class, and applies
# `check(file_path, content)` to every discovered file.
#
# Test fixtures live under spec/web/lint_conventions/fixtures/ and any
# `*/fixtures/` path is excluded by the runner's `discover_files` walk
# (line 93 of scripts/lint_conventions.cr).

require "../convention_rule"

# Rule: every spec file lives in spec/web/, spec/native_macos/,
# spec/native_ios/, OR spec/native_android/. The only allowed root spec
# file is spec/spec_helper.cr.
class SpecPlatformDirectoryRule < ConventionRule
  RULE_NAME = "family_5_partial/spec_platform_directory"

  ALLOWED_DIRS = [
    "spec/web/",
    "spec/native_macos/",
    "spec/native_ios/",
    "spec/native_android/",
  ]

  ALLOWED_ROOT_FILES = [
    "spec/spec_helper.cr",
  ]

  def rule_name : String
    RULE_NAME
  end

  # `content` is provided by the runner for parity with other rules
  # (Family 1 reads content). This rule is path-based only, so content
  # is ignored.
  def check(file_path : String, content : String) : Array(Diagnostic)
    return [] of Diagnostic unless file_path.starts_with?("spec/")
    return [] of Diagnostic unless file_path.ends_with?(".cr")
    return [] of Diagnostic if ALLOWED_ROOT_FILES.includes?(file_path)
    return [] of Diagnostic if ALLOWED_DIRS.any? { |d| file_path.starts_with?(d) }

    [
      Diagnostic.new(
        file_path: file_path,
        line: 1,
        rule_name: rule_name,
        message: "Spec file '#{file_path}' lives outside the platform-aware " \
                 "tree. Every spec must be in spec/web/, spec/native_macos/, " \
                 "spec/native_ios/, or spec/native_android/.",
        suggested_fix: "move to the appropriate platform directory " \
                       "(see docs/initiative-cross-platform-ui/handoff/" \
                       "phase-10-c-0-spec-inventory.md for the classification " \
                       "rule: deepest platform dependency)"
      ),
    ]
  end
end
