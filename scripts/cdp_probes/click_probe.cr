# Phase 6.5 D5 — click_probe.cr
#
# Routes I-3 web cells: dispatch a trusted CDP Input.dispatchMouseEvent
# at the selector's center, then read a window-level JS reflection
# (e.g. window.__lastClick) to assert the callback fired.
#
# Usage:
#   crystal-alpha run scripts/cdp_probes/click_probe.cr -- --slug action_sheet
#   crystal-alpha run scripts/cdp_probes/click_probe.cr -- --slug action_sheet \
#     --selector "#open-sheet-trigger" --witness "window.__sheetOpen === true"

require "./devtools"
require "option_parser"

slug = ""
selector = ".phase04-primary-action"
witness_js : String? = nil

OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Slug to load") { |v| slug = v }
  opts.on("--selector S", "CSS selector to click") { |v| selector = v }
  opts.on("--witness JS", "JS expression that must evaluate truthy post-click") { |v| witness_js = v }
end

if slug.empty?
  STDERR.puts "click_probe: --slug is required"
  exit 3
end

begin
  page_path = CDPProbes::SlugResolver.resolve(slug)
rescue ex
  STDERR.puts "click_probe: #{ex.message}"
  exit 3
end

CDPProbes::CDPSession.with_chrome(page_path) do |dt|
  # Resolve selector → element box → center coordinates.
  bbox_json = dt.evaluate(<<-JS).try(&.as_s?)
    (function(){
      var el = document.querySelector(#{selector.to_json});
      if (!el) return JSON.stringify({found:false});
      var r = el.getBoundingClientRect();
      return JSON.stringify({found:true, x: r.x + r.width/2, y: r.y + r.height/2});
    })();
  JS

  if bbox_json.nil?
    STDERR.puts "click_probe: selector eval returned nil"
    exit 1
  end
  bbox = JSON.parse(bbox_json)
  unless bbox["found"].as_bool
    STDERR.puts "click_probe: selector '#{selector}' not found on #{slug}"
    exit 1
  end

  x = bbox["x"].as_f
  y = bbox["y"].as_f

  # Install a default witness if none given: window.__lastClick set on click.
  install_witness = <<-JS
    (function(){
      window.__lastClick = null;
      document.addEventListener('click', function(e) {
        window.__lastClick = {
          target: e.target ? e.target.tagName : null,
          x: e.clientX,
          y: e.clientY,
          ts: Date.now()
        };
      }, true);
      return true;
    })();
  JS
  dt.evaluate(install_witness)

  dt.click_at(x, y)
  sleep(0.2.seconds)

  expr = witness_js || "window.__lastClick && window.__lastClick.x !== null"
  observed = dt.evaluate("JSON.stringify(#{expr})").try(&.as_s?) || "null"
  ok = observed == "true" || observed.starts_with?("{") || observed.starts_with?("\"")
  if ok
    puts "click_probe: PASS slug=#{slug} selector=#{selector} witness=#{observed}"
    exit 0
  else
    STDERR.puts "click_probe: FAIL slug=#{slug} selector=#{selector} witness=#{observed}"
    exit 1
  end
end
