# Phase 6.5 D5 — axe_probe.cr
#
# Routes I-6 web cells (axe-core leg). Injects vendored axe-core into a
# CDP target, runs axe.run(), surfaces violations as exit 1 if any.
#
# axe-core source MUST be vendored at vendor/audit/axe.min.js. The
# Phase 6.5 D5 vendor step pins this to a specific version.
#
# Usage:
#   crystal-alpha run scripts/cdp_probes/axe_probe.cr -- --slug action_sheet

require "./devtools"
require "option_parser"

slug = ""
include_tags = "wcag2a,wcag2aa,wcag21a,wcag21aa"

OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Slug to load") { |v| slug = v }
  opts.on("--tags T", "Comma-separated axe tag filter (default wcag2a,wcag2aa,wcag21a,wcag21aa)") { |v| include_tags = v }
end

if slug.empty?
  STDERR.puts "axe_probe: --slug is required"
  exit 3
end

unless File.exists?(CDPProbes::AXE_PATH)
  STDERR.puts "axe_probe: axe-core not vendored at #{CDPProbes::AXE_PATH}. Run scripts/cdp_probes/vendor_install.sh."
  exit 3
end

axe_source = File.read(CDPProbes::AXE_PATH)

begin
  page_path = CDPProbes::SlugResolver.resolve(slug)
rescue ex
  STDERR.puts "axe_probe: #{ex.message}"
  exit 3
end

CDPProbes::CDPSession.with_chrome(page_path) do |dt|
  dt.evaluate(axe_source)
  tags_json = include_tags.split(",").map(&.strip).to_json
  result_json = dt.evaluate(<<-JS).try(&.as_s?)
    JSON.stringify(axe.run(document, {
      runOnly: { type: 'tag', values: #{tags_json} }
    }).then(r => ({
      violations: r.violations.map(v => ({id: v.id, impact: v.impact, nodes: v.nodes.length})),
      passes: r.passes.length,
      incomplete: r.incomplete.length
    }))).then ? null : null;
  JS

  # The above pattern is async; for sync evaluation, await:
  result_json = dt.evaluate(<<-JS).try(&.as_s?)
    (async function(){
      var r = await axe.run(document, {runOnly: {type:'tag', values: #{tags_json}}});
      return JSON.stringify({
        violations: r.violations.map(v => ({id: v.id, impact: v.impact, nodes: v.nodes.length})),
        passes: r.passes.length,
        incomplete: r.incomplete.length
      });
    })();
  JS

  if result_json.nil?
    STDERR.puts "axe_probe: axe.run returned nil"
    exit 1
  end

  result = JSON.parse(result_json)
  violations = result["violations"].as_a
  if violations.empty?
    puts "axe_probe: PASS slug=#{slug} passes=#{result["passes"]} incomplete=#{result["incomplete"]}"
    exit 0
  else
    STDERR.puts "axe_probe: FAIL slug=#{slug} violations=#{violations.size}"
    violations.each do |v|
      STDERR.puts "  - #{v["id"]} (impact=#{v["impact"]}, nodes=#{v["nodes"]})"
    end
    exit 1
  end
end
