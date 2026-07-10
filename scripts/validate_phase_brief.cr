#!/usr/bin/env crystal
# validate_phase_brief.cr
#
# The forcing function for the cross-platform UI initiative's phase briefs.
# Reads a phase brief YAML, validates structure against the schema (manually
# enforced because Crystal doesn't have a built-in JSON Schema validator),
# re-runs every repo-derived-facts query and compares to the captured
# expected values, runs every lower-layer-assumption verification command
# and asserts exit code 0, and checks every probe cell for placeholder
# strings.
#
# Usage:
#   crystal run scripts/validate_phase_brief.cr -- path/to/phase-NN-brief.yml
#
# Exit codes:
#   0 = brief is dispatchable
#   1 = schema violation (missing required field, wrong shape, placeholder detected,
#       null-op probe command like `true`/`false`/`echo …`)
#   2 = repo fact drift (captured expected != current query result)
#   3 = lower-layer assumption falsified (verification command exited non-zero)
#   4 = adapter cardinality MISMATCH without documented_degradation + owner_approved
#   5 = probe cell pre-flight failed (referenced spec/script path does not exist)
#   6 = pre_dispatch_validation section missing or script_path not present at named path
#
# Co-authored-with-Codex as part of the planning retrospective forcing artifact.

require "yaml"

PLACEHOLDER_PATTERNS = [
  /<[^>]+>/,
  /\.\.\./,
]
PLACEHOLDER_LITERALS = %w[same equivalent OR\ deferred TBD TODO FIXME]

# Null-op commands that would silently pass a "did the verification exit 0" check
# without actually verifying anything. Reject as probe values.
NULL_OP_COMMAND_PATTERNS = [
  /^\s*true\s*$/,
  /^\s*false\s*$/,
  /^\s*:\s*$/,              # shell no-op
  /^\s*echo(\s|$)/,         # echo "TODO" exits 0 but proves nothing
  /^\s*#/,                  # comment-only line
  /^\s*\bTODO\b/i,
]

INVARIANT_IDS = %w[I-1 I-2 I-3 I-4 I-5 I-6 I-7 I-8 I-9 I-10 I-11]
TOUCH_LEVELS = %w[preserves extends replaces skips]
PLATFORMS = %w[ios macos web android]

# Recognized top-level keys per phase_brief.schema.json. Reject anything else.
ALLOWED_TOP_LEVEL_KEYS = %w[phase invariant_matrix lower_layer_assumptions repo_derived_facts adapter_cardinality pre_dispatch_validation]

class ValidationError < Exception
  property exit_code : Int32
  def initialize(message : String, @exit_code : Int32)
    super(message)
  end
end

def fail(code : Int32, message : String) : Nil
  STDERR.puts "FAIL[#{code}]: #{message}"
  raise ValidationError.new(message, code)
end

def warn(message : String) : Nil
  STDERR.puts "WARN: #{message}"
end

def ok(message : String) : Nil
  puts "OK: #{message}"
end

def looks_like_placeholder?(value : String) : Bool
  PLACEHOLDER_PATTERNS.any? { |p| value.match(p) } ||
    PLACEHOLDER_LITERALS.any? { |lit| value.strip == lit }
end

def assert_no_placeholder!(value : String, context : String) : Nil
  if looks_like_placeholder?(value)
    fail(1, "Placeholder detected in #{context}: #{value.inspect}. Replace with a real command/string before dispatch.")
  end
end

def assert_no_null_op_command!(value : String, context : String) : Nil
  if NULL_OP_COMMAND_PATTERNS.any? { |p| value.matches?(p) }
    fail(1, "Null-op command detected in #{context}: #{value.inspect}. A command like `true`, `false`, `echo ...`, or a comment doesn't prove anything; replace with a real probe.")
  end
end

# Statically resolve any spec/script path arguments inside a probe command
# and verify they exist. Handles bare paths AND commands like
# `crystal spec spec/foo_spec.cr -Dmacos` by scanning every whitespace-separated
# token for things that look like spec/script paths.
SPEC_PATH_PATTERN = /(?:^|\s)([A-Za-z0-9_\-\.\/]+\.(?:cr|sh|py|rb|js|swift|m|h|html))\b/

def maybe_assert_path_exists!(value : String, context : String) : Nil
  # Bare path (no spaces, no shell metacharacters) — check directly.
  if !value.includes?(" ") && value !~ /[\|&;><`$()]/
    if value.includes?("/") || value.includes?(".")
      unless File.exists?(value)
        fail(5, "Probe cell #{context}: bare path does not exist: #{value.inspect}.")
      end
    end
    return
  end

  # Multi-token command — scan for spec/script path arguments.
  value.scan(SPEC_PATH_PATTERN) do |match|
    path = match[1]
    next unless path.includes?("/")  # skip bare flag values like `something.cr` with no directory
    unless File.exists?(path)
      fail(5, "Probe cell #{context}: command references nonexistent path #{path.inspect} (inside #{value.inspect}).")
    end
  end
end

def run(command : String) : {Int32, String, String}
  # Run a shell command, capture stdout/stderr/exit. Used for both repo
  # fact queries and lower-layer assumption verifications.
  output = IO::Memory.new
  err = IO::Memory.new
  status = Process.run("bash", args: ["-c", command],
    output: output, error: err, shell: false)
  {status.exit_code, output.to_s.strip, err.to_s.strip}
end

def validate_top_level_keys(yaml : YAML::Any) : Nil
  h = yaml.as_h
  h.each_key do |key|
    key_s = key.as_s
    unless ALLOWED_TOP_LEVEL_KEYS.includes?(key_s)
      fail(1, "Unknown top-level key in brief: #{key_s.inspect}. Allowed keys: #{ALLOWED_TOP_LEVEL_KEYS.join(", ")}.")
    end
  end
  ok("top-level keys all recognized")
end

PHASE_ALLOWED_KEYS = %w[number name branch parent_branch parent_sha authored_at]

def validate_phase_section(yaml : YAML::Any) : Nil
  phase = yaml["phase"]?
  fail(1, "Missing required top-level 'phase' object.") if phase.nil?
  phase_h = phase.not_nil!.as_h
  # Schema says additionalProperties: false — reject unknown keys.
  phase_h.each_key do |k|
    unless PHASE_ALLOWED_KEYS.includes?(k.as_s)
      fail(1, "phase.#{k.as_s} unknown — schema only permits #{PHASE_ALLOWED_KEYS.join(", ")}.")
    end
  end
  PHASE_ALLOWED_KEYS.each do |key|
    fail(1, "phase.#{key} missing.") if phase.not_nil![key]?.nil?
  end
  name = phase.not_nil!["name"].as_s
  if name.size < 3
    fail(1, "phase.name too short (< 3 chars). Got: #{name.inspect}")
  end
  parent_branch = phase.not_nil!["parent_branch"].as_s
  if parent_branch.size < 3
    fail(1, "phase.parent_branch too short (< 3 chars). Got: #{parent_branch.inspect}")
  end
  branch = phase.not_nil!["branch"].as_s
  unless branch.matches?(/^phase-[0-9.]+-[a-z0-9-]+$/)
    fail(1, "phase.branch must match phase-NN-slug. Got: #{branch.inspect}")
  end
  sha = phase.not_nil!["parent_sha"].as_s
  unless sha.matches?(/^[0-9a-f]{7,40}$/)
    fail(1, "phase.parent_sha must be a git short or full SHA. Got: #{sha.inspect}")
  end
  authored = phase.not_nil!["authored_at"].as_s
  unless authored.matches?(/^\d{4}-\d{2}-\d{2}$/)
    fail(1, "phase.authored_at must be YYYY-MM-DD. Got: #{authored.inspect}")
  end
  ok("phase section structure valid")
end

def validate_invariant_matrix(yaml : YAML::Any) : Nil
  matrix = yaml["invariant_matrix"]?
  fail(1, "Missing required 'invariant_matrix' array.") if matrix.nil?
  rows = matrix.not_nil!.as_a
  if rows.size != 11
    fail(1, "invariant_matrix must contain exactly 11 rows (one per invariant). Got: #{rows.size}")
  end

  seen_ids = Set(String).new
  rows.each_with_index do |row, idx|
    id = row["id"]?.try(&.as_s) || fail(1, "invariant_matrix[#{idx}].id missing.")
    unless INVARIANT_IDS.includes?(id)
      fail(1, "invariant_matrix[#{idx}].id must be one of I-1..I-11. Got: #{id.inspect}")
    end
    if seen_ids.includes?(id)
      fail(1, "Duplicate invariant id: #{id}")
    end
    seen_ids << id

    # Schema requires `name` field on every row.
    name = row["name"]?.try(&.as_s)
    fail(1, "invariant_matrix[#{idx}].name missing.") if name.nil? || name.size < 3

    touch = row["touch"]?.try(&.as_s) || fail(1, "invariant_matrix[#{idx}].touch missing.")
    unless TOUCH_LEVELS.includes?(touch)
      fail(1, "invariant_matrix[#{idx}].touch must be preserves|extends|replaces|skips. Got: #{touch.inspect}")
    end

    rationale = row["rationale"]?.try(&.as_s) || fail(1, "invariant_matrix[#{idx}].rationale missing.")
    if rationale.size < 8
      fail(1, "invariant_matrix[#{idx}].rationale too short (< 8 chars).")
    end
    assert_no_placeholder!(rationale, "invariant_matrix[#{idx}].rationale")

    probes = row["probes"]?
    fail(1, "invariant_matrix[#{idx}].probes missing.") if probes.nil?
    PLATFORMS.each do |platform|
      cell = probes.not_nil![platform]?
      fail(1, "invariant_matrix[#{idx}].probes.#{platform} missing.") if cell.nil?
      validate_probe_cell!(cell.not_nil!, "#{id}/#{platform}")
    end
  end

  missing = INVARIANT_IDS.reject { |i| seen_ids.includes?(i) }
  unless missing.empty?
    fail(1, "invariant_matrix missing required invariants: #{missing.join(", ")}")
  end
  ok("invariant_matrix structure valid (11 rows, all platforms cells present, no placeholders)")
end

def validate_probe_cell!(cell : YAML::Any, context : String) : Nil
  if (s = cell.as_s?)
    if s.size < 5
      fail(1, "Probe cell #{context}: command too short (< 5 chars). Got: #{s.inspect}")
    end
    assert_no_placeholder!(s, "probe cell #{context}")
    assert_no_null_op_command!(s, "probe cell #{context}")
    maybe_assert_path_exists!(s, context)
  elsif (h = cell.as_h?)
    skip_val = h[YAML::Any.new("skip")]?
    unless skip_val.try(&.as_bool?) == true
      fail(1, "Probe cell #{context}: object cells must be {skip: true, reason, owner_approved}.")
    end
    reason = h[YAML::Any.new("reason")]?.try(&.as_s)
    fail(1, "Probe cell #{context}: skip record missing reason.") if reason.nil?
    if reason.not_nil!.size < 12
      fail(1, "Probe cell #{context}: skip reason too short (< 12 chars).")
    end
    assert_no_placeholder!(reason.not_nil!, "probe cell #{context} reason")
    approved = h[YAML::Any.new("owner_approved")]?.try(&.as_s)
    fail(1, "Probe cell #{context}: skip record missing owner_approved date.") if approved.nil?
    unless approved.not_nil!.matches?(/^\d{4}-\d{2}-\d{2}$/)
      fail(1, "Probe cell #{context}: owner_approved must be YYYY-MM-DD. Got: #{approved.inspect}")
    end
  else
    fail(1, "Probe cell #{context}: must be a string (command) or a skip object. Got: #{cell.inspect}")
  end
end

def validate_lower_layer_assumptions(yaml : YAML::Any) : Nil
  section = yaml["lower_layer_assumptions"]?
  if section.nil?
    fail(1, "Required top-level section 'lower_layer_assumptions' is missing. If the phase genuinely depends on no lower-layer assumption, declare an empty array AND add a top-level comment explaining why — this should be vanishingly rare.")
  end
  rows = section.not_nil!.as_a
  if rows.empty?
    warn("lower_layer_assumptions is empty. Phases that touch ANY layer below the host language should declare at least one assumption with verification.")
  end

  seen_ids = Set(String).new
  rows.each_with_index do |row, idx|
    id = row["id"]?.try(&.as_s) || fail(1, "lower_layer_assumptions[#{idx}].id missing.")
    unless id.matches?(/^A[0-9]+$/)
      fail(1, "lower_layer_assumptions[#{idx}].id must match A<N>. Got: #{id.inspect}")
    end
    if seen_ids.includes?(id)
      fail(1, "Duplicate assumption id: #{id}")
    end
    seen_ids << id

    claim = row["claim"]?.try(&.as_s) || fail(1, "lower_layer_assumptions[#{idx}].claim missing.")
    if claim.size < 10
      fail(1, "lower_layer_assumptions[#{idx}].claim too short (< 10 chars). Got: #{claim.inspect}")
    end
    assert_no_placeholder!(claim, "lower_layer_assumptions[#{idx}].claim")

    falsifier = row["falsifier"]?.try(&.as_s) || fail(1, "lower_layer_assumptions[#{idx}].falsifier missing.")
    if falsifier.size < 10
      fail(1, "lower_layer_assumptions[#{idx}].falsifier too short (< 10 chars). Got: #{falsifier.inspect}")
    end
    assert_no_placeholder!(falsifier, "lower_layer_assumptions[#{idx}].falsifier")

    verification = row["verification"]?.try(&.as_s) || fail(1, "lower_layer_assumptions[#{idx}].verification missing.")
    if verification.size < 5
      fail(1, "lower_layer_assumptions[#{idx}].verification too short (< 5 chars). Got: #{verification.inspect}")
    end
    assert_no_placeholder!(verification, "lower_layer_assumptions[#{idx}].verification")

    print "Running verification for #{id}: "
    exit_code, stdout, stderr = run(verification)
    if exit_code != 0
      fail(3, "Assumption #{id} (#{claim}) FAILED. Command exited #{exit_code}. stderr: #{stderr}")
    end
    puts "ok"
  end
  ok("lower_layer_assumptions all verified (#{rows.size} assumptions)")
end

def validate_repo_derived_facts(yaml : YAML::Any) : Nil
  section = yaml["repo_derived_facts"]?
  if section.nil?
    fail(1, "Required top-level section 'repo_derived_facts' is missing. Briefs MUST capture every count/symbol/version/flag-convention via a query. Declare an empty array only if the brief contains zero numeric or symbolic facts.")
  end
  rows = section.not_nil!.as_a
  if rows.empty?
    warn("repo_derived_facts is empty. The brief should capture every numeric count, symbol name, or version pin via a query, or stale facts will sneak in.")
  end

  rows.each_with_index do |row, idx|
    fact = row["fact"]?.try(&.as_s) || fail(1, "repo_derived_facts[#{idx}].fact missing.")
    if fact.size < 3
      fail(1, "repo_derived_facts[#{idx}].fact too short (< 3 chars). Got: #{fact.inspect}")
    end
    query = row["query"]?.try(&.as_s) || fail(1, "repo_derived_facts[#{idx}].query missing.")
    if query.size < 3
      fail(1, "repo_derived_facts[#{idx}].query too short (< 3 chars). Got: #{query.inspect}")
    end
    expected = row["expected"]? || fail(1, "repo_derived_facts[#{idx}].expected missing.")
    captured_sha = row["captured_at_sha"]?.try(&.as_s) || fail(1, "repo_derived_facts[#{idx}].captured_at_sha missing (schema requires this for every fact row).")
    unless captured_sha.matches?(/^[0-9a-f]{7,40}$/)
      fail(1, "repo_derived_facts[#{idx}].captured_at_sha must be a git short or full SHA. Got: #{captured_sha.inspect}")
    end
    assert_no_placeholder!(query, "repo_derived_facts[#{idx}].query")

    print "Re-running query for fact '#{fact}': "
    exit_code, stdout, stderr = run(query)
    if exit_code != 0
      fail(2, "Fact query '#{fact}' command FAILED. Exit #{exit_code}. stderr: #{stderr}")
    end
    actual_str = stdout
    expected_str = expected.as_s? || expected.as_i?.try(&.to_s) || expected.as_f?.try(&.to_s) ||
                   expected.as_bool?.try(&.to_s) || expected.inspect
    if actual_str != expected_str
      fail(2, "Fact '#{fact}' DRIFTED. Expected: #{expected_str.inspect}. Actual: #{actual_str.inspect}. Update the brief or fix the drift before dispatch.")
    end
    puts "ok (#{actual_str})"
  end
  ok("repo_derived_facts all match captured values (#{rows.size} facts)")
end

def validate_pre_dispatch_validation_section(yaml : YAML::Any, brief_path : String) : Nil
  section = yaml["pre_dispatch_validation"]?
  if section.nil?
    fail(6, "Required top-level section 'pre_dispatch_validation' is missing. Must declare { script_path: <path>, expected_exit_code: 0 }.")
  end
  h = section.not_nil!.as_h
  script_path = h[YAML::Any.new("script_path")]?.try(&.as_s)
  fail(6, "pre_dispatch_validation.script_path missing.") if script_path.nil?
  unless File.exists?(script_path.not_nil!)
    fail(6, "pre_dispatch_validation.script_path #{script_path.inspect} does not exist on disk.")
  end
  expected = h[YAML::Any.new("expected_exit_code")]?.try(&.as_i?)
  fail(6, "pre_dispatch_validation.expected_exit_code missing.") if expected.nil?
  unless expected == 0
    fail(6, "pre_dispatch_validation.expected_exit_code must be 0 (dispatch ready means exit zero). Got: #{expected.inspect}")
  end

  # NEW: actually run the pre-dispatch script unless it IS this validator
  # (avoid infinite recursion). Pass the brief path as the script's $1.
  resolved = File.expand_path(script_path.not_nil!)
  self_path = File.expand_path(PROGRAM_NAME)
  this_validator = File.expand_path("scripts/validate_phase_brief.cr")
  if resolved == this_validator
    ok("pre_dispatch_validation script_path IS this validator — recursive self-run skipped intentionally; we've already verified the brief if we got here.")
    return
  end

  # Check it's executable OR at least readable + a known interpreter prefix
  unless File.executable?(resolved)
    # Crystal files run via `crystal run`; bash files via bash; etc. Don't fail just on missing +x
    # but DO fail if the file has no recognized way to invoke it.
    ext = File.extname(resolved)
    unless %w[.cr .sh .rb .py .js].includes?(ext) || File.executable?(resolved)
      fail(6, "pre_dispatch_validation.script_path #{resolved} is not executable and has no recognized interpreter extension (.cr/.sh/.rb/.py/.js).")
    end
  end

  # Actually invoke the script with the brief as $1
  command = case File.extname(resolved)
            when ".cr" then "crystal run #{resolved} -- #{brief_path}"
            when ".sh" then "bash #{resolved} #{brief_path}"
            when ".py" then "python3 #{resolved} #{brief_path}"
            when ".rb" then "ruby #{resolved} #{brief_path}"
            when ".js" then "node #{resolved} #{brief_path}"
            else resolved + " " + brief_path
            end

  print "Running pre_dispatch_validation script: "
  exit_code, stdout, stderr = run(command)
  if exit_code != expected
    fail(6, "pre_dispatch_validation script exited #{exit_code}; expected #{expected}. stderr: #{stderr.lines.last(5).join("\n  ")}")
  end
  puts "ok (exit #{exit_code})"
end

REQUIRED_CARDINALITY_FIELDS = %w[public_api adapter adapter_input_space api_input_space match_status]

def validate_adapter_cardinality(yaml : YAML::Any) : Nil
  rows = yaml["adapter_cardinality"]?.try(&.as_a) || [] of YAML::Any
  rows.each_with_index do |row, idx|
    # Every row (MATCH or MISMATCH) must have these 5 required fields.
    REQUIRED_CARDINALITY_FIELDS.each do |field|
      val = row[field]?.try(&.as_s?)
      if val.nil? || val.size < 3
        fail(1, "adapter_cardinality[#{idx}].#{field} missing or too short. Required on every row regardless of MATCH/MISMATCH.")
      end
    end

    status = row["match_status"].as_s
    unless %w[MATCH MISMATCH].includes?(status)
      fail(1, "adapter_cardinality[#{idx}].match_status must be MATCH or MISMATCH. Got: #{status.inspect}")
    end
    next if status == "MATCH"

    # MISMATCH requires documented_degradation + owner_approved
    degradation = row["documented_degradation"]?.try(&.as_s)
    approved = row["owner_approved"]?.try(&.as_s)
    if degradation.nil? || degradation.empty?
      fail(4, "adapter_cardinality[#{idx}] is MISMATCH but missing documented_degradation. Public API '#{row["public_api"]?}' silently degrades on adapter '#{row["adapter"]?}'.")
    end
    if degradation.not_nil!.size < 10
      fail(4, "adapter_cardinality[#{idx}].documented_degradation too short (< 10 chars). Schema requires substantive description.")
    end
    if approved.nil? || !approved.matches?(/^\d{4}-\d{2}-\d{2}$/)
      fail(4, "adapter_cardinality[#{idx}] is MISMATCH but missing owner_approved date (YYYY-MM-DD).")
    end
    assert_no_placeholder!(degradation.not_nil!, "adapter_cardinality[#{idx}].documented_degradation")
  end
  ok("adapter_cardinality valid (#{rows.size} rows; all required fields present; MISMATCH rows have degradation + approval)")
end

def main : Nil
  if ARGV.empty?
    STDERR.puts "Usage: crystal run scripts/validate_phase_brief.cr -- path/to/phase-NN-brief.yml"
    exit 1
  end

  brief_path = ARGV[0]
  unless File.exists?(brief_path)
    STDERR.puts "FAIL: Brief not found at #{brief_path}"
    exit 1
  end

  puts "Validating phase brief: #{brief_path}"
  yaml = YAML.parse(File.read(brief_path))

  begin
    validate_top_level_keys(yaml)
    validate_phase_section(yaml)
    validate_invariant_matrix(yaml)
    validate_repo_derived_facts(yaml)
    validate_lower_layer_assumptions(yaml)
    validate_adapter_cardinality(yaml)
    validate_pre_dispatch_validation_section(yaml, brief_path)
    puts ""
    puts "PASS: phase brief is dispatchable."
    exit 0
  rescue e : ValidationError
    puts ""
    puts "Brief is NOT dispatchable. Fix the failure above and re-run."
    exit e.exit_code
  end
end

main
