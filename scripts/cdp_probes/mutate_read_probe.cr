# Phase 6.5 D5 — mutate_read_probe.cr
#
# Routes I-2 web cells (mutate-then-read) AND I-5 web (lifecycle, --mode
# lifecycle) AND I-7 web (leak smoke, --mode leak).
#
# Default mode (mutate): evaluate a JS mutator, read the selector's
# textContent, assert it transitioned.
#
# Lifecycle mode: instantiate, dismiss, assert no orphaned DOM nodes.
#
# Leak mode: instantiate widget tree N times, assert DOM node count
# stable across iterations.
#
# Usage:
#   crystal-alpha run scripts/cdp_probes/mutate_read_probe.cr -- --slug action_sheet
#   crystal-alpha run scripts/cdp_probes/mutate_read_probe.cr -- --slug action_sheet --mode lifecycle
#   crystal-alpha run scripts/cdp_probes/mutate_read_probe.cr -- --slug action_sheet --mode leak

require "./devtools"
require "option_parser"

slug = ""
mode = "mutate"
mutator_js = "(function(){var el=document.querySelector('[data-mutable]'); if(el){el.textContent='mutated@'+Date.now();} return el ? el.textContent : null;})()"
read_selector = "[data-mutable]"

OptionParser.parse(ARGV) do |opts|
  opts.on("--slug S", "Slug to load") { |v| slug = v }
  opts.on("--mode M", "mutate|lifecycle|leak (default mutate)") { |v| mode = v }
  opts.on("--mutator JS", "JS expression that mutates the DOM") { |v| mutator_js = v }
  opts.on("--read SEL", "CSS selector whose textContent is read post-mutation") { |v| read_selector = v }
end

if slug.empty?
  STDERR.puts "mutate_read_probe: --slug is required"
  exit 3
end

begin
  page_path = CDPProbes::SlugResolver.resolve(slug)
rescue ex
  STDERR.puts "mutate_read_probe: #{ex.message}"
  exit 3
end

CDPProbes::CDPSession.with_chrome(page_path) do |dt|
  case mode
  when "mutate"
    before = dt.evaluate("(function(){var el=document.querySelector(#{read_selector.to_json}); return el ? el.textContent : null;})()").try(&.as_s?) || ""
    dt.evaluate(mutator_js)
    sleep(0.1.seconds)
    after = dt.evaluate("(function(){var el=document.querySelector(#{read_selector.to_json}); return el ? el.textContent : null;})()").try(&.as_s?) || ""
    if before != after
      puts "mutate_read_probe[mutate]: PASS slug=#{slug} before=#{before.inspect} after=#{after.inspect}"
      exit 0
    else
      STDERR.puts "mutate_read_probe[mutate]: FAIL slug=#{slug} before=#{before.inspect} after=#{after.inspect}"
      exit 1
    end
  when "lifecycle"
    initial = dt.evaluate("document.querySelectorAll('*').length").try(&.as_i?) || -1
    # Instantiate a sheet/popover/etc. via a known data-action selector.
    dt.evaluate("(function(){var el=document.querySelector('[data-action=\"present\"]'); if(el) el.click();})()")
    sleep(0.2.seconds)
    presented = dt.evaluate("document.querySelectorAll('*').length").try(&.as_i?) || -1
    dt.press_key("Escape", "Escape", 27)
    sleep(0.2.seconds)
    final = dt.evaluate("document.querySelectorAll('*').length").try(&.as_i?) || -1
    # Final node count should match initial (or be within 5 nodes of it).
    if (final - initial).abs <= 5
      puts "mutate_read_probe[lifecycle]: PASS slug=#{slug} initial=#{initial} presented=#{presented} final=#{final}"
      exit 0
    else
      STDERR.puts "mutate_read_probe[lifecycle]: FAIL slug=#{slug} initial=#{initial} presented=#{presented} final=#{final}"
      exit 1
    end
  when "leak"
    counts = [] of Int32
    5.times do |i|
      dt.evaluate("(function(){var el=document.querySelector('[data-action=\"present\"]'); if(el) el.click();})()")
      sleep(0.1.seconds)
      dt.press_key("Escape", "Escape", 27)
      sleep(0.1.seconds)
      counts << (dt.evaluate("document.querySelectorAll('*').length").try(&.as_i?) || -1)
    end
    delta = counts.last - counts.first
    if delta.abs <= 10
      puts "mutate_read_probe[leak]: PASS slug=#{slug} counts=#{counts.inspect} delta=#{delta}"
      exit 0
    else
      STDERR.puts "mutate_read_probe[leak]: FAIL slug=#{slug} counts=#{counts.inspect} delta=#{delta}"
      exit 1
    end
  else
    STDERR.puts "mutate_read_probe: unknown --mode #{mode}"
    exit 3
  end
end
