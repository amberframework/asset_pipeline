# Phase 6.5 D5 — ibm_equal_access_probe.cr
#
# Routes I-6 web cells (IBM Equal Access leg). Injects vendored
# accessibility-checker-engine (ACE) into a CDP target, runs the checker,
# surfaces violations as exit 1 if any.
#
# ACE source MUST be vendored at vendor/audit/ace.js. The Phase 6.5 D5
# vendor step pins this to a specific version.
#
# Usage:
#   crystal-alpha run scripts/cdp_probes/ibm_equal_access_probe.cr -- --slug action_sheet

require "./devtools"
require "option_parser"

slug = ""
ruleset = "IBM_Accessibility"

OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Slug to load") { |v| slug = v }
  opts.on("--ruleset R", "ACE ruleset (default IBM_Accessibility)") { |v| ruleset = v }
end

if slug.empty?
  STDERR.puts "ibm_equal_access_probe: --slug is required"
  exit 3
end

unless File.exists?(CDPProbes::ACE_PATH)
  STDERR.puts "ibm_equal_access_probe: ACE not vendored at #{CDPProbes::ACE_PATH}. Run scripts/cdp_probes/vendor_install.sh."
  exit 3
end

ace_source = File.read(CDPProbes::ACE_PATH)

begin
  page_path = CDPProbes::SlugResolver.resolve(slug)
rescue ex
  STDERR.puts "ibm_equal_access_probe: #{ex.message}"
  exit 3
end

CDPProbes::CDPSession.with_chrome(page_path) do |dt|
  dt.evaluate(ace_source)
  result_json = dt.evaluate(<<-JS).try(&.as_s?)
    (async function(){
      try {
        var checker = new ace.Checker();
        var report = await checker.check(document, [#{ruleset.to_json}]);
        var viols = report.results.filter(r => r.value && r.value[1] === 'FAIL');
        return JSON.stringify({
          totalChecks: report.results.length,
          violations: viols.map(v => ({ruleId: v.ruleId, message: v.message, path: v.path && v.path.dom}))
        });
      } catch (e) {
        return JSON.stringify({error: e.message});
      }
    })();
  JS

  if result_json.nil?
    STDERR.puts "ibm_equal_access_probe: ACE eval returned nil"
    exit 1
  end

  result = JSON.parse(result_json)
  if err = result["error"]?
    STDERR.puts "ibm_equal_access_probe: ACE error: #{err}"
    exit 1
  end
  violations = result["violations"].as_a
  if violations.empty?
    puts "ibm_equal_access_probe: PASS slug=#{slug} totalChecks=#{result["totalChecks"]}"
    exit 0
  else
    STDERR.puts "ibm_equal_access_probe: FAIL slug=#{slug} violations=#{violations.size}"
    violations.first(10).each do |v|
      STDERR.puts "  - #{v["ruleId"]}: #{v["message"]}"
    end
    exit 1
  end
end
