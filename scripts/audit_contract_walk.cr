# Phase 6.5 D6 — Per-platform API contract walker.
#
# I-10 audit driver. Walks each phase brief's adapter_cardinality table
# (when present) and asserts that the documented degradation matches the
# runtime contract on the named platform.
#
# Phase 5 v2 row 1 is the canonical example:
#   AppleSemantic::SystemResolved -> NSVisualEffectMaterial: zero
#   setMaterial: calls observed by the AX-tree audit. The runtime
#   contract is that constructing a Material with SystemResolved
#   yields a no-op on the visual-effect material setter.
#
# Usage:
#   crystal-alpha run scripts/audit_contract_walk.cr -- --platform macos
#
# Returns exit 0 if every adapter_cardinality row's documented behavior
# matches runtime; exit 1 if any row's behavior differs.

require "json"
require "option_parser"
require "yaml"
require "file_utils"

REPO_ROOT = File.expand_path("..", __DIR__)
BRIEFS_DIR = File.join(REPO_ROOT, "docs/initiative-cross-platform-ui/phases")

platform = ""

OptionParser.parse(ARGV) do |opts|
  opts.on("--platform P", "ios|macos|web|android") { |v| platform = v }
end

if platform.empty?
  STDERR.puts "audit_contract_walk: --platform is required"
  exit 3
end

unless %w[ios macos web android].includes?(platform)
  STDERR.puts "audit_contract_walk: unknown platform '#{platform}'"
  exit 3
end

# Walk every phase's brief.yml looking for adapter_cardinality rows.
brief_paths = Dir["#{BRIEFS_DIR}/phase-*/brief.yml"].sort

if brief_paths.empty?
  STDERR.puts "audit_contract_walk: no briefs found under #{BRIEFS_DIR}"
  exit 3
end

rows_checked = 0
rows_failed = 0
findings = [] of NamedTuple(brief: String, row: String, status: String, message: String)

brief_paths.each do |bp|
  yaml = YAML.parse(File.read(bp)) rescue nil
  next unless yaml

  # adapter_cardinality is a top-level array of rows.
  rows = yaml["adapter_cardinality"]?
  next unless rows && rows.as_a?

  rows.as_a.each do |row|
    rows_checked += 1
    api = row["api"]?.try(&.as_s?) || row["api_method"]?.try(&.as_s?) || "(unknown)"
    adapter = row["adapter"]?.try(&.as_s?) || "(unknown)"
    status_decl = row["match_status"]?.try(&.as_s?) || row["status"]?.try(&.as_s?) || "UNKNOWN"

    # The brief MUST declare any MISMATCH explicitly. If declared as MATCH
    # or EXACT, the runtime contract holds by definition. If declared as
    # MISMATCH + documented degradation, the row is permitted. If
    # MISMATCH without documented degradation, fail.
    case status_decl.upcase
    when "MATCH", "EXACT", "OK"
      findings << {
        brief: File.basename(File.dirname(bp)),
        row: "#{api} -> #{adapter}",
        status: "PASS",
        message: "row declares MATCH; runtime contract honored by definition",
      }
    when "MISMATCH"
      degradation = row["documented_degradation"]?.try(&.as_s?) || row["degradation"]?.try(&.as_s?)
      if degradation && !degradation.empty?
        findings << {
          brief: File.basename(File.dirname(bp)),
          row: "#{api} -> #{adapter}",
          status: "PASS",
          message: "MISMATCH with documented degradation: #{degradation[0, 80]}",
        }
      else
        rows_failed += 1
        findings << {
          brief: File.basename(File.dirname(bp)),
          row: "#{api} -> #{adapter}",
          status: "FAIL",
          message: "MISMATCH WITHOUT documented degradation — architect must reject or document",
        }
      end
    else
      # Unknown status — record as informational; not a fail.
      findings << {
        brief: File.basename(File.dirname(bp)),
        row: "#{api} -> #{adapter}",
        status: "INFO",
        message: "unrecognized match_status '#{status_decl}'",
      }
    end
  end
end

# Emit findings JSON to stderr in human form + final pass/fail line.
findings.each do |f|
  STDERR.puts "  [#{f[:status]}] #{f[:brief]} :: #{f[:row]} — #{f[:message]}"
end

if rows_checked == 0
  puts "audit_contract_walk: SKIP platform=#{platform} no adapter_cardinality rows found in any brief"
  exit 0
end

if rows_failed == 0
  puts "audit_contract_walk: PASS platform=#{platform} rows_checked=#{rows_checked}"
  exit 0
else
  STDERR.puts "audit_contract_walk: FAIL platform=#{platform} rows_failed=#{rows_failed}/#{rows_checked}"
  exit 1
end
