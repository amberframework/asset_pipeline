# Phase 10A.0a — Convention rule base class + diagnostic shape.
#
# Every convention rule is a Crystal class subclassing `ConventionRule`.
# Rules are loaded by `scripts/lint_conventions.cr` and applied to every
# file the runner visits. The directory name `src/lsp_rules/` is kept so
# rule classes port directly if AmberLSP later grows a Crystal-compiled
# rule loader; today there is no LSP coupling.
#
# Rule auto-discovery: subclasses register themselves at class-definition
# time via `ConventionRule.inherited`. The runner then loads rule files
# by macro-expanded require of every `family_*/*_rule.cr` and reads the
# global `ConventionRule.registered_rules` registry. Contributors only
# drop a new file in `src/lsp_rules/family_N_*/` — no runner edit needed.

# Diagnostic record produced by a `ConventionRule#check` call.
#
# The runner serializes diagnostics as one line each in the format:
# `<file>:<line>: [<rule_name>] <message> (suggested: <fix>)`
struct Diagnostic
  property file_path : String
  property line : Int32
  property rule_name : String
  property message : String
  property suggested_fix : String?

  def initialize(@file_path : String, @line : Int32, @rule_name : String, @message : String, @suggested_fix : String? = nil)
  end

  # Renders the diagnostic in the runner's stable human + machine format.
  def to_s(io : IO) : Nil
    io << file_path << ':' << line << ": [" << rule_name << "] " << message
    if fix = suggested_fix
      io << " (suggested: " << fix << ')'
    end
  end
end

# Runtime config passed to convention rules. Loaded from
# `.lint_conventions.yml` at the repo root (or defaults) by the runner.
#
# Today only `view_subclass_approved_roots` is configurable; future
# rules can read additional fields without changing the constructor
# signature.
class ConventionConfig
  property view_subclass_approved_roots : Array(String)

  DEFAULT_VIEW_SUBCLASS_APPROVED_ROOTS = ["src/ui/views/", "samples/"]

  def initialize(@view_subclass_approved_roots : Array(String) = DEFAULT_VIEW_SUBCLASS_APPROVED_ROOTS.dup)
  end

  # Loads config from a YAML file at `path`, falling back to defaults
  # for any missing key. Returns a fresh ConventionConfig with the
  # union of file values + defaults.
  def self.load(path : String) : ConventionConfig
    cfg = ConventionConfig.new
    return cfg unless File.exists?(path)
    text = File.read(path)
    roots = parse_yaml_string_list(text, "view_subclass.approved_roots")
    cfg.view_subclass_approved_roots = roots unless roots.empty?
    cfg
  end

  # Tiny inline YAML parser sufficient for the keys we need (a flat
  # `key:` section with a nested `subkey: [a, b]` inline list OR a
  # block list of `- value` lines). Avoids pulling in the full YAML
  # shard at compile time — the runner is a single `crystal run`.
  def self.parse_yaml_string_list(text : String, dotted_key : String) : Array(String)
    parts = dotted_key.split('.')
    section = parts[0]
    key = parts[1]
    in_section = false
    in_key_block = false
    items = [] of String
    text.each_line do |raw|
      line = raw.rstrip
      next if line.empty?
      next if line.strip.starts_with?("#")
      if line == "#{section}:" || line.starts_with?("#{section}:")
        in_section = true
        in_key_block = false
        next
      end
      if in_section
        # Top-level key (no leading whitespace) ends the section.
        if !line.starts_with?(" ") && !line.starts_with?("\t") && line != "#{section}:"
          in_section = false
          in_key_block = false
          next
        end
        stripped = line.lstrip
        # Inline form: `subkey: [a, b]`.
        if stripped.starts_with?("#{key}:")
          rest = stripped[(key.size + 1)..].strip
          if rest.starts_with?("[") && rest.ends_with?("]")
            rest[1..-2].split(',').each do |elt|
              v = elt.strip.gsub(/^['"]|['"]$/, "")
              items << v unless v.empty?
            end
            return items
          end
          in_key_block = true
          next
        end
        # Block list under `subkey:` — lines like `  - value`.
        if in_key_block && stripped.starts_with?("- ")
          v = stripped[2..].strip.gsub(/^['"]|['"]$/, "")
          items << v unless v.empty?
        elsif in_key_block
          # Hit a non-list line; block ends.
          in_key_block = false
        end
      end
    end
    items
  end
end

# Abstract base class for every Phase 10 convention rule.
#
# Subclasses implement `check(file_path, content)` returning zero or more
# `Diagnostic` values. Rules should be stateless — instances are reused
# across files. Heuristics are regex/string level; we do not parse Crystal.
#
# Subclasses are auto-registered into `ConventionRule.registered_rules`
# at class-definition time via the `inherited` macro hook. The runner
# instantiates each registered class with the current `ConventionConfig`.
abstract class ConventionRule
  @@registered_rules = [] of ConventionRule.class

  # Registry of every subclass loaded into the process.
  def self.registered_rules : Array(ConventionRule.class)
    @@registered_rules
  end

  # Auto-registration hook: every subclass appends itself to the
  # registry when its class body is evaluated.
  macro inherited
    ::ConventionRule.registered_rules << self
  end

  abstract def rule_name : String
  abstract def check(file_path : String, content : String) : Array(Diagnostic)

  # Subclasses MAY override to receive the runner-loaded config at
  # construction time. Default no-op so existing rules without
  # config dependence keep working unchanged.
  def configure(config : ConventionConfig) : Nil
  end

  # Returns the 1-based line number of the first match of `pattern` in
  # `content`, or `nil` if the pattern is not found. Helper for rules.
  def find_line(content : String, pattern : Regex) : Int32?
    content.each_line.with_index(1) do |line, lineno|
      return lineno if pattern.matches?(line)
    end
    nil
  end

  # Converts `PascalCase` / `camelCase` identifiers to `snake_case`.
  def snake_case(identifier : String) : String
    s = identifier.gsub(/([A-Z]+)([A-Z][a-z])/) { "#{$1}_#{$2}" }
    s = s.gsub(/([a-z\d])([A-Z])/) { "#{$1}_#{$2}" }
    s.downcase
  end
end
