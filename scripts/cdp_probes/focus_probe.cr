# Phase 6.5 D5 — focus_probe.cr
#
# Routes I-4 web cells: snapshot document.activeElement pre/post a
# focus-changing action and assert focus restoration.
#
# Usage:
#   crystal-alpha run scripts/cdp_probes/focus_probe.cr -- --slug action_sheet
#   crystal-alpha run scripts/cdp_probes/focus_probe.cr -- --slug action_sheet \
#     --trigger "#open-sheet" --close "#cancel-button"

require "./devtools"
require "option_parser"

slug = ""
trigger_selector = ".phase04-primary-action"
close_selector : String? = nil

OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Slug to load") { |v| slug = v }
  opts.on("--trigger S", "Selector that opens a modal") { |v| trigger_selector = v }
  opts.on("--close S", "Selector to click to restore focus") { |v| close_selector = v }
end

if slug.empty?
  STDERR.puts "focus_probe: --slug is required"
  exit 3
end

begin
  page_path = CDPProbes::SlugResolver.resolve(slug)
rescue ex
  STDERR.puts "focus_probe: #{ex.message}"
  exit 3
end

CDPProbes::CDPSession.with_chrome(page_path) do |dt|
  # Move focus to trigger.
  focus_js = <<-JS
    (function(){
      var el = document.querySelector(#{trigger_selector.to_json});
      if (!el) return null;
      el.focus();
      return document.activeElement ? document.activeElement.id || document.activeElement.tagName : null;
    })();
  JS
  pre_id = dt.evaluate(focus_js).try(&.as_s?) || ""

  # Programmatic click to open whatever modal.
  dt.evaluate("(function(){var el=document.querySelector(#{trigger_selector.to_json}); if(el) el.click(); })();")
  sleep(0.2.seconds)

  # If close selector given, click it; otherwise dispatch ESC.
  if cs = close_selector
    dt.evaluate("(function(){var el=document.querySelector(#{cs.to_json}); if(el) el.click(); })();")
  else
    dt.press_key("Escape", "Escape", 27)
  end
  sleep(0.2.seconds)

  post_id = dt.evaluate("document.activeElement ? document.activeElement.id || document.activeElement.tagName : null").try(&.as_s?) || ""

  if pre_id == post_id && !pre_id.empty?
    puts "focus_probe: PASS slug=#{slug} pre=#{pre_id} post=#{post_id}"
    exit 0
  else
    STDERR.puts "focus_probe: FAIL slug=#{slug} pre=#{pre_id.inspect} post=#{post_id.inspect}"
    exit 1
  end
end
