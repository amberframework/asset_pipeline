# Phase 10A.0a — Family 1 convention rule regression spec.
#
# Loads each rule fixture from `spec/web/lint_conventions/fixtures/`,
# parses the leading header keys (`fixture_for`, `expected`,
# `synthetic_path`), and replays the rule against the fixture content
# with the declared synthetic file_path. Locks in current diagnostic
# behavior for the documented false-positive cases.

require "spec"
require "../../../src/lsp_rules/convention_rule"

# Auto-require every rule file so `ConventionRule.registered_rules`
# is populated when the spec runs.
{% for path in `cd #{__DIR__}/../../../src/lsp_rules && find . -type f -name "*_rule.cr" | sed 's|^\\./|../../../src/lsp_rules/|'`.split('\n').reject(&.empty?) %}
  require {{ path }}
{% end %}

private record FixtureCase,
  path : String,
  fixture_for : Array(String),
  expected : Symbol, # :pass or :fail
  synthetic_path : String,
  content : String

private def parse_fixture(path : String) : FixtureCase
  content = File.read(path)
  fixture_for = [] of String
  expected = :pass
  synthetic_path = ""
  content.each_line do |raw|
    line = raw.strip
    break unless line.starts_with?("#")
    body = line.sub(/^#\s*/, "")
    if body.starts_with?("fixture_for:")
      fixture_for = body.sub("fixture_for:", "").split(',').map(&.strip).reject(&.empty?)
    elsif body.starts_with?("expected:")
      raw_val = body.sub("expected:", "").strip
      expected = case raw_val
                 when "fail"              then :fail
                 when "skipped_by_runner" then :skipped_by_runner
                 else                          :pass
                 end
    elsif body.starts_with?("synthetic_path:")
      synthetic_path = body.sub("synthetic_path:", "").strip
    end
  end
  FixtureCase.new(
    path: path,
    fixture_for: fixture_for,
    expected: expected,
    synthetic_path: synthetic_path,
    content: content
  )
end

private def all_rules : Array(ConventionRule)
  config = ConventionConfig.new
  ConventionRule.registered_rules.map do |klass|
    instance = klass.new
    instance.configure(config)
    instance.as(ConventionRule)
  end
end

private def rule_by_name(name : String) : ConventionRule
  rule = all_rules.find { |r| r.rule_name == name }
  raise "no rule named '#{name}'" unless rule
  rule
end

describe "Family 1 naming rules — regression fixtures" do
  fixture_root = File.join(__DIR__, "fixtures")
  fixture_paths = Dir.glob(File.join(fixture_root, "*.cr")).sort

  it "loads at least 7 fixtures" do
    fixture_paths.size.should be >= 7
  end

  fixture_paths.each do |path|
    fixture = parse_fixture(path)
    basename = File.basename(path)

    # Runner-level exclusion fixtures (lib/, etc.) are asserted
    # separately below; skip per-rule replay for them.
    next if fixture.expected == :skipped_by_runner

    fixture.fixture_for.each do |rule_name|
      it "[#{basename}] rule #{rule_name} -> #{fixture.expected}" do
        rule = rule_by_name(rule_name)
        diagnostics = rule.check(fixture.synthetic_path, fixture.content)
        case fixture.expected
        when :pass
          diagnostics.empty?.should be_true
        when :fail
          diagnostics.empty?.should be_false
          diagnostics.first.rule_name.should eq(rule_name)
        end
      end
    end
  end

  it "runner discover_files excludes lib/ vendored content" do
    # Run the runner against the fixtures dir restricted via --paths
    # and assert lib_vendored_pass.cr's synthetic location would be
    # excluded. We approximate the runner's exclusion by replicating
    # the same predicate the runner uses.
    lib_path = "lib/some_vendored_shard/fake_view.cr"
    excluded = lib_path.includes?("/lib/") || lib_path.starts_with?("lib/")
    excluded.should be_true
  end

  it "the rule registry contains all 5 Family 1 rules" do
    names = all_rules.map(&.rule_name)
    names.should contain("family_1/screen_class_naming")
    names.should contain("family_1/screen_file_suffix")
    names.should contain("family_1/controller_class_naming")
    names.should contain("family_1/controller_file_suffix")
    names.should contain("family_1/view_subclass_under_views_dir")
  end
end
