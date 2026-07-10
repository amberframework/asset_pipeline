# Phase 6.5 D5 — Web demo axe-core audit (thin wrapper).
#
# Replaces the previous 1-line shim that simply required the amber-demo
# audit. The web design-system demo lives at
# examples/web_design_system_demo.cr; its rendered HTML target is
# samples/cross_platform/web/dist/. This script invokes the cdp_probes
# axe_probe against each shipped demo HTML in that tree.
#
# Usage:
#   crystal-alpha run scripts/axe_web_demo_audit.cr
#   crystal-alpha run scripts/axe_web_demo_audit.cr -- --slug action_sheet

require "./cdp_probes/devtools"
require "option_parser"

slug : String? = nil
OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Single slug to audit (default: all shipped demos)") { |v| slug = v }
end

dist = File.join(CDPProbes::REPO_ROOT, "samples/cross_platform/web/dist")
unless File.directory?(dist)
  STDERR.puts "axe_web_demo_audit: no dist dir at #{dist}; run examples/web_design_system_demo.cr first"
  exit 3
end

probe = File.join(CDPProbes::REPO_ROOT, "scripts/cdp_probes/axe_probe.cr")

if s = slug
  status = Process.run("crystal-alpha", ["run", probe, "--", "--slug", s], output: STDOUT, error: STDERR)
  exit status.exit_code
else
  # Audit every phase04_*_demo.html shipped under dist.
  htmls = Dir["#{dist}/phase04_*_demo.html"].sort
  if htmls.empty?
    STDERR.puts "axe_web_demo_audit: no phase04_*_demo.html under #{dist}"
    exit 3
  end
  fails = 0
  htmls.each do |path|
    name = File.basename(path, ".html")
    # name like "phase04_action_sheet_demo" -> slug "action_sheet"
    s2 = name.sub("phase04_", "").sub(/_demo$/, "")
    puts "[axe] auditing slug=#{s2}"
    status = Process.run("crystal-alpha", ["run", probe, "--", "--slug", s2], output: STDOUT, error: STDERR)
    fails += 1 unless status.success?
  end
  exit(fails == 0 ? 0 : 1)
end
