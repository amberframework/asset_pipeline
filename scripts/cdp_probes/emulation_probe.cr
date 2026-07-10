# Phase 6.5 D5 — emulation_probe.cr
#
# Routes I-8 web cells: drive Emulation.setEmulatedMedia for
# prefers-color-scheme / prefers-reduced-motion / forced-colors, then
# verify the page's matchMedia state matches.
#
# Usage:
#   crystal-alpha run scripts/cdp_probes/emulation_probe.cr -- --slug action_sheet
#   crystal-alpha run scripts/cdp_probes/emulation_probe.cr -- --slug action_sheet \
#     --scheme dark --reduced-motion reduce --forced-colors active

require "./devtools"
require "option_parser"

slug = ""
scheme = "dark"
reduced_motion : String? = "reduce"
forced_colors : String? = nil

OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Slug to load") { |v| slug = v }
  opts.on("--scheme S", "prefers-color-scheme value (light|dark)") { |v| scheme = v }
  opts.on("--reduced-motion S", "prefers-reduced-motion (reduce|no-preference)") { |v| reduced_motion = v }
  opts.on("--forced-colors S", "forced-colors (active|none)") { |v| forced_colors = v }
end

if slug.empty?
  STDERR.puts "emulation_probe: --slug is required"
  exit 3
end

begin
  page_path = CDPProbes::SlugResolver.resolve(slug)
rescue ex
  STDERR.puts "emulation_probe: #{ex.message}"
  exit 3
end

extra = [] of NamedTuple(name: String, value: String)
if rm = reduced_motion
  extra << {name: "prefers-reduced-motion", value: rm}
end
if fc = forced_colors
  extra << {name: "forced-colors", value: fc}
end

CDPProbes::CDPSession.with_chrome(page_path, color_scheme: scheme, extra_emulated_media: extra) do |dt|
  # Verify each emulated media query takes effect.
  results = {} of String => Bool
  results["prefers-color-scheme"] = (dt.evaluate("window.matchMedia('(prefers-color-scheme: #{scheme})').matches").try(&.as_bool?) || false)
  if rm = reduced_motion
    results["prefers-reduced-motion"] = (dt.evaluate("window.matchMedia('(prefers-reduced-motion: #{rm})').matches").try(&.as_bool?) || false)
  end
  if fc = forced_colors
    results["forced-colors"] = (dt.evaluate("window.matchMedia('(forced-colors: #{fc})').matches").try(&.as_bool?) || false)
  end

  failed = results.reject { |_, v| v }
  if failed.empty?
    puts "emulation_probe: PASS slug=#{slug} results=#{results.inspect}"
    exit 0
  else
    STDERR.puts "emulation_probe: FAIL slug=#{slug} not-matched=#{failed.keys.inspect}"
    exit 1
  end
end
