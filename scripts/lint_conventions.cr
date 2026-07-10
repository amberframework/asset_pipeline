#!/usr/bin/env crystal
# Phase 10A.0a — Convention rule runner.
#
# Walks the repo, applies loaded rule classes, emits diagnostics.
# Exit 0 if no violations; exit 1 if any. Invoked in CI, in
# pre-commit hooks, or directly by contributors / AI agents.
#
# Usage:
#   crystal run scripts/lint_conventions.cr -- [options]
#
# Options:
#   --rules=family_1[,family_N]    Limit to one or more rule families
#                                  (matches `rule_name` prefix).
#   --paths=path1,path2,...        Override the default scan roots.
#   --no-default-paths             Disable default roots; only scan --paths.
#   --format=human|machine         Output format (default human).
#   --quiet                        Suppress the "OK" banner on green runs.
#   --config=path/to/.lint_conventions.yml
#                                  Override the config file path.
#
# Default scan roots: src/, samples/, spec/.
# Always-excluded paths: lib/, .crystal-cache/, spec/fixtures/ (test fixtures
# intentionally exercise malformed shapes).
#
# Per-file disable: prepend `# lint:disable=<rule_name>` on a line near
# the top of the file to suppress that rule for the whole file. Multiple
# rules can be listed comma-separated. `# lint:disable=all` suppresses
# every rule for the file.
#
# Output format (one line per diagnostic):
#   <file>:<line>: [<rule_name>] <message> (suggested: <fix>)
#
# Rule auto-discovery: every `*_rule.cr` under `src/lsp_rules/family_*/`
# is auto-required at compile time, and each `ConventionRule` subclass
# auto-registers itself via the `inherited` macro hook. The runner reads
# `ConventionRule.registered_rules` — no manual edit needed when adding
# or removing a rule. Drop a file and ship.

require "../src/lsp_rules/convention_rule"

# Auto-require every rule file under `src/lsp_rules/family_*/`.
# The backtick macro expression shells out at compile time to enumerate
# paths (each on its own line, relative to this file's directory);
# Crystal then expands one `require` per discovered file.
{% for path in `cd #{__DIR__}/../src/lsp_rules && find . -type f -name "*_rule.cr" | sed 's|^\\./|../src/lsp_rules/|'`.split('\n').reject(&.empty?) %}
  require {{ path }}
{% end %}

# Aggregates rule classes and runs them across a list of files.
class Linter
  def initialize(@rules : Array(ConventionRule))
  end

  def rules : Array(ConventionRule)
    @rules
  end

  def lint(paths : Array(String)) : Array(Diagnostic)
    diagnostics = [] of Diagnostic
    paths.each do |path|
      content = File.read(path)
      disabled = parse_disabled_rules(content)
      next if disabled.includes?("all")
      @rules.each do |rule|
        next if disabled.includes?(rule.rule_name)
        rule.check(path, content).each { |d| diagnostics << d }
      end
    end
    diagnostics
  end

  private def parse_disabled_rules(content : String) : Set(String)
    disabled = Set(String).new
    content.scan(/^[ \t]*#\s*lint:disable=([^\s#]+)/m) do |m|
      m[1].split(',').each { |name| disabled << name.strip }
    end
    disabled
  end
end

def discover_files(roots : Array(String)) : Array(String)
  files = [] of String
  roots.each do |root|
    next unless File.exists?(root)
    if File.file?(root)
      files << root if root.ends_with?(".cr")
      next
    end
    Dir.glob("#{root}/**/*.cr") do |path|
      next if path.includes?("/lib/")
      next if path.includes?("/.crystal-cache/")
      # Any spec fixtures dir intentionally exercises malformed shapes.
      next if path.includes?("/fixtures/")
      next if path.starts_with?("fixtures/")
      files << path
    end
  end
  files.sort.uniq
end

# Instantiates every registered ConventionRule subclass, applies the
# loaded config, and returns the list of rule instances.
def load_rules(config : ConventionConfig) : Array(ConventionRule)
  rules = [] of ConventionRule
  ConventionRule.registered_rules.each do |klass|
    instance = klass.new
    instance.configure(config)
    rules << instance
  end
  rules.sort_by!(&.rule_name)
  rules
end

family_filters = [] of String
path_overrides = [] of String
use_default_paths = true
format = "human"
quiet = false
config_path = ".lint_conventions.yml"

ARGV.each do |arg|
  case arg
  when .starts_with?("--rules=")
    family_filters = arg["--rules=".size..-1].split(',').map(&.strip).reject(&.empty?)
  when .starts_with?("--paths=")
    path_overrides = arg["--paths=".size..-1].split(',').map(&.strip).reject(&.empty?)
  when "--no-default-paths"
    use_default_paths = false
  when .starts_with?("--format=")
    format = arg["--format=".size..-1]
  when "--quiet"
    quiet = true
  when .starts_with?("--config=")
    config_path = arg["--config=".size..-1]
  when "-h", "--help"
    STDOUT.puts File.read(__FILE__).lines(chomp: false)[2..36].join.gsub(/^# ?/m, "")
    exit 0
  else
    STDERR.puts "lint_conventions: unknown option '#{arg}'"
    exit 2
  end
end

default_roots = use_default_paths ? ["src", "samples", "spec"] : [] of String
roots = default_roots + path_overrides
if roots.empty?
  STDERR.puts "lint_conventions: no scan roots configured"
  exit 2
end

config = ConventionConfig.load(config_path)
rules = load_rules(config)
unless family_filters.empty?
  rules = rules.select do |rule|
    family_filters.any? { |prefix| rule.rule_name.starts_with?(prefix) }
  end
  if rules.empty?
    STDERR.puts "lint_conventions: --rules=#{family_filters.join(",")} matched no rules"
    exit 2
  end
end

files = discover_files(roots)
linter = Linter.new(rules)
diagnostics = linter.lint(files)

case format
when "human", "machine"
  diagnostics.each { |d| STDOUT.puts d.to_s }
else
  STDERR.puts "lint_conventions: unknown --format='#{format}' (expected human|machine)"
  exit 2
end

if diagnostics.empty?
  unless quiet
    STDOUT.puts "lint_conventions: OK (#{files.size} files, #{rules.size} rules, 0 diagnostics)"
  end
  exit 0
else
  STDOUT.puts "lint_conventions: FAIL (#{files.size} files, #{rules.size} rules, #{diagnostics.size} diagnostics)"
  exit 1
end
