#!/usr/bin/env crystal
# Phase 9 — Schema lint for the Apple-Native Intent Catalog.
#
# Parses `docs/initiative-cross-platform-ui/architecture/intent-catalog.md` and
# validates every `### \`:identifier\`` entry against the strict schema defined
# in brief-9.md §3 and the pseudocode in §5 Item 1.
#
# Rules (binding):
#   1. Every row carries ALL 12 common-schema fields. Class D rows additionally
#      carry `crystal_api_shape` + `platforms` (14 fields total).
#   2. Field values are rejected if they are: empty / whitespace-only / `nil` /
#      `null` / `TBD` / `XXX` / `FIXME`, OR a hyphen variant that is not the
#      U+2014 em-dash sentinel. The em-dash `"—"` IS the accepted sentinel for
#      "no equivalent on platform."
#   3. `class` ∈ {A, B, C, D}; `tier` ∈ {1, 2, 3}.
#   4. `intent_identifier_crystal` MUST equal `:` + snake_case(`primary_apple_name`)
#      unless the row declares `apple_canonical_name_exists: false`.
#
# Output:
#   - Zero violations → exit 0 and print "PASS".
#   - Otherwise → exit 1 and print every violation grouped by entry.
#
# Run:
#   crystal run scripts/lint_intent_catalog.cr

require "file"

CATALOG_PATH = "docs/initiative-cross-platform-ui/architecture/intent-catalog.md"

# Phase 10-pre.2 markers: any row carrying the rename-audit marker is a violation
# after 10-pre.2 closes. The marker was used by 10-pre.1 as a TODO bookmark for
# the 10-pre.2 sweep; once 10-pre.2 lands, every such row must be reconciled.
PENDING_RENAME_AUDIT_MARKER = "pending 10-pre.2 rename audit"

# Phase 10-pre.2 Rule B: placeholder strings in a Class D `crystal_api_shape`
# value are rejected (in addition to the literal sentinels already handled by
# INVALID_LITERAL_VALUES).
#
# Iter 2 (Codex HIGH-1): tightened to reject EMBEDDED placeholders, not only
# values that exactly equal a placeholder. A row whose shape contains
# `[...]`, `API TBD`, or inline `TBD` / `XXX` / `FIXME` / `<TODO>` is still
# a placeholder even if it pretends to be a real expression.
#
# Standalone exact-match tokens (kept for back-compat with the iter 1 rule).
CLASS_D_SHAPE_PLACEHOLDERS = ["TBD", "...", "<TODO>"]
# Case-insensitive substring tokens that mark a value as a placeholder no
# matter where they appear inside the shape.
CLASS_D_SHAPE_BANNED_SUBSTRINGS_CI = ["TBD", "XXX", "FIXME", "<TODO>"]
# Literal substrings (case-sensitive) that mark a value as a placeholder.
# `[...]` is the canonical placeholder-bracket; `API TBD` is the prose form.
CLASS_D_SHAPE_BANNED_SUBSTRINGS = ["[...]", "API TBD"]
# Long consecutive-dot runs (4+) indicate placeholder ellipses substituting
# for real code. Legitimate Crystal range literals use 2-3 dots only.
CLASS_D_SHAPE_LONG_ELLIPSIS = /\.{4,}/

REQUIRED_COMMON_FIELDS = [
  "intent_identifier_crystal",
  "primary_apple_name",
  "class",
  "tier",
  "swiftui_api",
  "uikit_api",
  "appkit_api",
  "hig_page",
  "android_equivalent",
  "web_equivalent",
  "coverage_today",
  "description",
]

REQUIRED_CLASS_D_EXTRA = [
  "crystal_api_shape",
  "platforms",
]

INVALID_LITERAL_VALUES = ["", "nil", "null", "TBD", "XXX", "FIXME"]
EMDASH_SENTINEL        = "—" # U+2014

# Phase 10-pre.1: citation-presence check for `coverage_today`.
# A `coverage_today` value other than `missing` / `catalog_only` / `deferred`
# MUST cite at least one source file + line range, e.g.
#   `src/ui/views/view.cr:132`
#   `src/ui/renderers/uikit_renderer.cr:3408-3413`
# We split the value on `;` and inspect each segment; at least one segment
# of a `partial` / `shipped` value must match the citation pattern.
CITATION_PATTERN = /src\/[A-Za-z0-9_\/\.\-]+\.(cr|m|c|h|swift):\d+(?:-\d+)?/
# Vague language is rejected for `partial`/`shipped` values unless the value
# also contains a citation. These phrases historically masked unbacked claims.
VAGUE_PHRASES = [
  "some views",
  "most renderers",
  "partial coverage",
  "in some places",
  "where appropriate",
  "as needed",
]
# Recognized exemption / clause prefixes inside a multi-clause value.
COVERAGE_SENTINELS = ["missing", "catalog_only", "deferred"]

# Convert an Apple-name (camelCase, dotted, with parens) to canonical snake_case.
# Strategy:
#   - Strip everything after the first `(` (drop signatures).
#   - Drop leading dots (modifier prefix).
#   - Replace any non-alphanumeric with `_`.
#   - Insert `_` at lower→upper transitions and between letter→digit boundaries.
#   - Lowercase + collapse repeated underscores + trim leading/trailing `_`.
def snake_case_of_apple_name(apple : String) : String
  base = apple
  if idx = base.index('(')
    base = base[0...idx]
  end
  base = base.lstrip('.').strip
  # Insert underscore at:
  #   - lower→Upper boundaries (e.g. "swipeActions" → "swipe_Actions"), AND
  #   - boundary between a run of uppercase letters and a following lowercase
  #     letter (e.g. "UIMenu" → "UI_Menu", "UIImpactFeedbackGenerator" →
  #     "UI_Impact_Feedback_Generator"). This honors the Crystal convention
  #     that acronyms split as a separate token.
  out = String.build do |io|
    chars = base.chars
    chars.each_with_index do |ch, i|
      prev = i > 0 ? chars[i - 1] : nil
      nxt = i + 1 < chars.size ? chars[i + 1] : nil
      if prev
        # lower → Upper
        if ch.uppercase? && prev.alphanumeric? && !prev.uppercase?
          io << '_'
        # Upper → Upper followed by lower (end of acronym run, e.g. "UI|Menu").
        elsif ch.uppercase? && prev.uppercase? && nxt && nxt.lowercase?
          io << '_'
        end
      end
      io << ch
    end
  end
  # Normalize non-alphanumerics → underscore, collapse, lowercase, trim.
  out = out.gsub(/[^A-Za-z0-9]+/, "_")
  out = out.gsub(/_+/, "_")
  out = out.strip('_')
  out.downcase
end

# An invalid hyphen-variant string is one composed entirely of `-` characters
# OR an em-dash followed by extra whitespace etc. The em-dash sentinel itself
# is the single character `—` (no surrounding whitespace, no doubling).
def invalid_dash_variant?(value : String) : Bool
  return false if value == EMDASH_SENTINEL
  # Pure hyphen runs ("-", "--", "---") or em-dash with whitespace contamination
  return true if value.matches?(/\A-+\z/)
  return true if value.includes?(EMDASH_SENTINEL) && value != EMDASH_SENTINEL && value.strip == EMDASH_SENTINEL
  false
end

struct Entry
  property identifier : String
  property line : Int32
  property fields : Hash(String, String)

  def initialize(@identifier : String, @line : Int32)
    @fields = {} of String => String
  end
end

# Parse the catalog into Entry records.
def parse_catalog(path : String) : Array(Entry)
  entries = [] of Entry
  current : Entry? = nil
  File.read_lines(path).each_with_index do |line, idx|
    line_num = idx + 1
    # New entry heading: `### \`:identifier\``.
    if m = line.match(/^###\s+`(:[a-z0-9_]+)`/)
      current = Entry.new(identifier: m[1], line: line_num)
      entries << current.not_nil!
      next
    end
    # End of entry when another header level appears (## or new ###).
    if line.starts_with?("## ") && !line.starts_with?("### ")
      current = nil
      next
    end
    next unless ent = current
    # Field bullet: `- **field_name:** value`
    if m = line.match(/^-\s+\*\*([a-z_]+):\*\*\s*(.*)$/)
      field = m[1]
      value = m[2].strip
      # Strip surrounding backticks if the field value is a code span.
      value = value.gsub(/^`/, "").gsub(/`$/, "")
      ent.fields[field] = value
    end
  end
  entries
end

violations = [] of String
entries = parse_catalog(CATALOG_PATH)

if entries.empty?
  puts "FAIL: no entries parsed from #{CATALOG_PATH}"
  exit 1
end

entries.each do |entry|
  prefix = "[#{entry.identifier} @ line #{entry.line}]"

  # 1. Common required fields.
  REQUIRED_COMMON_FIELDS.each do |field|
    unless entry.fields.has_key?(field)
      violations << "#{prefix} missing required field: #{field}"
      next
    end
    value = entry.fields[field]
    if value.strip.empty?
      violations << "#{prefix} whitespace-only value for #{field}"
      next
    end
    if INVALID_LITERAL_VALUES.includes?(value)
      violations << "#{prefix} invalid sentinel value for #{field}: #{value.inspect}"
      next
    end
    if invalid_dash_variant?(value)
      violations << "#{prefix} #{field} uses non-em-dash sentinel #{value.inspect}; must be #{EMDASH_SENTINEL.inspect} (U+2014)"
    end
  end

  # 2. Class membership.
  if klass = entry.fields["class"]?
    unless ["A", "B", "C", "D"].includes?(klass)
      violations << "#{prefix} invalid class value: #{klass.inspect} (must be A/B/C/D)"
    end
  end

  # 3. Tier membership.
  if tier = entry.fields["tier"]?
    unless ["1", "2", "3"].includes?(tier)
      violations << "#{prefix} invalid tier value: #{tier.inspect} (must be 1/2/3)"
    end
  end

  # 4. Class D extra fields.
  if entry.fields["class"]? == "D"
    REQUIRED_CLASS_D_EXTRA.each do |field|
      unless entry.fields.has_key?(field)
        violations << "#{prefix} Class D missing required field: #{field}"
        next
      end
      value = entry.fields[field]
      if value.strip.empty?
        violations << "#{prefix} Class D #{field} is whitespace-only"
      end
      if INVALID_LITERAL_VALUES.includes?(value)
        violations << "#{prefix} Class D #{field} has invalid sentinel value: #{value.inspect}"
      end
    end

    # 4a. Phase 10-pre.2 Rule B: Class D crystal_api_shape must be non-empty
    # AND must not consist solely of — or contain embedded — placeholder
    # tokens. The substantive value carries the consumer-facing copy-paste
    # example; placeholders defeat the whole purpose of Class D.
    if shape = entry.fields["crystal_api_shape"]?
      shape_value = shape.strip
      if CLASS_D_SHAPE_PLACEHOLDERS.includes?(shape_value)
        violations << "#{prefix} Class D crystal_api_shape is a placeholder token #{shape_value.inspect}; must contain a real Crystal expression"
      end
      # Iter 2 (Codex HIGH-1): embedded substring placeholders.
      shape_lower = shape_value.downcase
      CLASS_D_SHAPE_BANNED_SUBSTRINGS_CI.each do |banned|
        if shape_lower.includes?(banned.downcase)
          violations << "#{prefix} Class D crystal_api_shape contains embedded placeholder substring #{banned.inspect} (case-insensitive): #{shape_value.inspect}"
        end
      end
      CLASS_D_SHAPE_BANNED_SUBSTRINGS.each do |banned|
        if shape_value.includes?(banned)
          violations << "#{prefix} Class D crystal_api_shape contains embedded placeholder substring #{banned.inspect}: #{shape_value.inspect}"
        end
      end
      if shape_value.matches?(CLASS_D_SHAPE_LONG_ELLIPSIS)
        violations << "#{prefix} Class D crystal_api_shape contains a 4+ dot ellipsis run (placeholder for real code): #{shape_value.inspect}"
      end
    end
  end

  # 4c. Phase 10-pre.2 Rule A: reject any field still carrying the rename-audit
  # marker. After 10-pre.2 closes, the catalog must have no `# pending 10-pre.2
  # rename audit` markers anywhere.
  entry.fields.each do |field, value|
    if value.includes?(PENDING_RENAME_AUDIT_MARKER)
      violations << "#{prefix} field #{field} still carries `# #{PENDING_RENAME_AUDIT_MARKER}` marker; resolve and remove"
    end
  end

  # 4b. coverage_today citation-presence check (Phase 10-pre.1).
  #
  # Rules:
  #   - If the value's leading token is `missing`, `catalog_only`, or
  #     `deferred`, it is accepted regardless of citations (those classify
  #     the row as having no realized code by design).
  #   - Otherwise the value MUST contain at least one citation matching
  #     CITATION_PATTERN (e.g. `src/ui/views/view.cr:132`).
  #   - `partial` and `shipped` values without a citation are rejected.
  #   - Vague phrases ("some views", "most renderers", etc.) are rejected
  #     unless the value also contains a citation; if cited, they're
  #     accepted because the cite supplies the missing precision.
  if cov = entry.fields["coverage_today"]?
    cov_value = cov.strip
    # The "# was: ..." trailing audit-history note documents what the prior
    # catalog claimed before the 10-pre.1 correction. It is informational —
    # the AUTHORITATIVE coverage classification is the text BEFORE that
    # marker. Strip it before testing.
    cov_authoritative = cov_value.split("# was:", 2).first.strip
    leading_token = cov_authoritative.split(/[\s\(:;]/, 2).first.downcase
    is_sentinel_only = COVERAGE_SENTINELS.includes?(leading_token)
    unless is_sentinel_only
      unless cov_authoritative.matches?(CITATION_PATTERN)
        violations << "#{prefix} coverage_today value lacks required source citation (expected pattern like `src/.../foo.cr:N` or `src/.../foo.cr:N-M`): #{cov_value.inspect}"
      end
      VAGUE_PHRASES.each do |phrase|
        if cov_authoritative.downcase.includes?(phrase) && !cov_authoritative.matches?(CITATION_PATTERN)
          violations << "#{prefix} coverage_today uses vague phrase #{phrase.inspect} without backing citation: #{cov_value.inspect}"
        end
      end
    end
  end

  # 5. snake_case identity vs primary_apple_name.
  if (ident = entry.fields["intent_identifier_crystal"]?) &&
     (apple = entry.fields["primary_apple_name"]?)
    expected = ":" + snake_case_of_apple_name(apple)
    # Strip backticks from ident if present.
    ident_clean = ident.gsub(/`/, "").strip
    exception = entry.fields["apple_canonical_name_exists"]? == "false"
    if ident_clean != expected && !exception
      violations << "#{prefix} intent_identifier_crystal #{ident_clean.inspect} != expected #{expected.inspect} from primary_apple_name #{apple.inspect}"
    end
  end
end

if violations.empty?
  puts "PASS"
  puts "Validated #{entries.size} catalog entries against the schema in brief-9.md §3."
  exit 0
else
  puts "FAIL"
  puts "Validated #{entries.size} entries; found #{violations.size} violation(s):"
  violations.each { |v| puts "  - #{v}" }
  exit 1
end
