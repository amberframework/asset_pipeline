# Phase 6.5 D5 — screenshot_probe.cr
#
# Routes I-1 web cells: capture Page.captureScreenshot, write to disk,
# optionally diff against a committed baseline via scripts/visual_diff.cr.
#
# Usage:
#   crystal-alpha run scripts/cdp_probes/screenshot_probe.cr -- --slug action_sheet
#   crystal-alpha run scripts/cdp_probes/screenshot_probe.cr -- --slug action_sheet \
#     --out /tmp/action_sheet.png --baseline docs/.../baselines/web/action_sheet.png

require "./devtools"
require "option_parser"
require "file_utils"

slug = ""
out_path : String? = nil
baseline_path : String? = nil
scheme = "light"

OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Slug to load") { |v| slug = v }
  opts.on("--out PATH", "Where to write the PNG (default /tmp/<slug>.png)") { |v| out_path = v }
  opts.on("--baseline PATH", "If set, diff against this baseline via visual_diff.cr") { |v| baseline_path = v }
  opts.on("--scheme S", "prefers-color-scheme (default light)") { |v| scheme = v }
end

if slug.empty?
  STDERR.puts "screenshot_probe: --slug is required"
  exit 3
end

begin
  page_path = CDPProbes::SlugResolver.resolve(slug)
rescue ex
  STDERR.puts "screenshot_probe: #{ex.message}"
  exit 3
end

resolved_out = out_path
target_path = resolved_out.nil? ? File.join(Dir.tempdir, "#{slug}.png") : resolved_out
FileUtils.mkdir_p(File.dirname(target_path))

CDPProbes::CDPSession.with_chrome(page_path, color_scheme: scheme) do |dt|
  # 200ms settle for layout + paint.
  sleep(0.2.seconds)
  bytes = dt.screenshot_png
  File.write(target_path, bytes)
  if File.exists?(target_path) && File.size(target_path) > 0
    puts "screenshot_probe: captured #{target_path} (#{File.size(target_path)} bytes)"
  else
    STDERR.puts "screenshot_probe: capture failed"
    exit 1
  end
end

if bp = baseline_path
  if File.exists?(bp)
    diff_script = File.join(CDPProbes::REPO_ROOT, "scripts/visual_diff.cr")
    status = Process.run(
      "crystal-alpha",
      ["run", diff_script, "--", "--baseline", bp, "--actual", target_path],
      output: STDOUT,
      error: STDERR,
    )
    exit status.exit_code
  else
    puts "screenshot_probe: no baseline at #{bp}; capture saved at #{target_path}"
    exit 0
  end
end
exit 0
