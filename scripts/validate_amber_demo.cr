require "file_utils"
require "json"

ROOT                 = File.expand_path("..", __DIR__)
JS                   = File.join(ROOT, "public/js/design-system.js")
RESULT_DIR           = File.join(ROOT, "test-results/web-design-system")
LEGACY_RESULT_DIR    = File.join(ROOT, "test-results/amber-design-system")
RESULT_FILE          = File.join(RESULT_DIR, "static-audit.json")
CANONICAL_AUDIT_FILE = File.join(RESULT_DIR, "canonical-surface-audit.json")
PAGES                = {
  "overview"      => File.join(ROOT, "output/web-design-system-demo.html"),
  "pricing"       => File.join(ROOT, "output/web-design-system-pricing.html"),
  "forms"         => File.join(ROOT, "output/web-design-system-forms.html"),
  "dashboard"     => File.join(ROOT, "output/web-design-system-dashboard.html"),
  "timeline"      => File.join(ROOT, "output/web-design-system-timeline.html"),
  "collaboration" => File.join(ROOT, "output/web-design-system-collaboration.html"),
  "patterns"      => File.join(ROOT, "output/web-design-system-patterns.html"),
}

def assert(name : String, condition : Bool, failures : Array(String))
  failures << name unless condition
end

def strip_runtime(html : String) : String
  html
    .gsub(/<script\b.*?<\/script>/mi, "")
    .gsub(/<style\b.*?<\/style>/mi, "")
end

def attrs(tag : String) : Hash(String, String)
  parsed = {} of String => String
  tag.scan(/([a-zA-Z0-9_\-:]+)(?:\s*=\s*"([^"]*)")?/).each do |match|
    key = match[1]
    next if key == tag.split(/\s+/, 2)[0].gsub(/[<>\/]/, "")
    parsed[key] = match[2]? || ""
  end
  parsed
end

def control_has_label?(html : String, tag : String, index : Int32) : Bool
  attributes = attrs(tag)
  return true if attributes.has_key?("aria-label") || attributes.has_key?("aria-labelledby")
  if id = attributes["id"]?
    return true if html.includes?(%Q(for="#{id}"))
  end

  before = html[0, index]
  after = html[index, html.size - index]
  last_open = before.rindex(/<label\b/i)
  last_close = before.rindex(/<\/label>/i)
  next_close = after.index(/<\/label>/i)
  !!(last_open && (!last_close || last_open > last_close) && next_close)
end

failures = [] of String
pages = PAGES.transform_values { |path| File.exists?(path) ? File.read(path) : "" }
runtime_free_pages = pages.transform_values { |html| strip_runtime(html) }
html = pages.values.join("\n")
runtime_free_html = runtime_free_pages.values.join("\n")
js = File.exists?(JS) ? File.read(JS) : ""

PAGES.each do |key, path|
  assert("#{key} page exists at #{path}", File.exists?(path), failures)
end

PAGES.each do |key, _|
  page_html = pages[key]
  clean = runtime_free_pages[key]
  assert("#{key} has html lang", page_html.includes?(%(<html lang="en">)), failures)
  assert("#{key} has title", page_html.match(/<title>[^<]+<\/title>/).try { true } || false, failures)
  assert("#{key} has viewport meta", page_html.includes?(%(<meta name="viewport")), failures)
  assert("#{key} has labelled nav", clean.includes?(%(<nav class="am-demo-nav" aria-label="Demo pages">)), failures)
  assert("#{key} has main landmark", clean.includes?(%(<main id="main")), failures)
  h1_count = clean.scan(/<h1\b/i).size
  assert("#{key} has exactly one h1, found #{h1_count}", h1_count == 1, failures)

  ids = clean.scan(/\sid="([^"]+)"/).map { |match| match[1] }
  duplicates = ids.group_by(&.itself).select { |_, values| values.size > 1 }.keys
  assert("#{key} has unique ids: #{duplicates.join(", ")}", duplicates.empty?, failures)

  controls = [] of {String, Int32}
  clean.scan(/<(input|select|textarea)\b[^>]*>/i) do |match|
    controls << {match[0], match.begin(0)}
  end
  unlabeled = controls.reject { |tag, index| control_has_label?(clean, tag, index) }
  assert("#{key} form controls have accessible labels: #{unlabeled.map(&.[0]).join(", ")}", unlabeled.empty?, failures)
end

PAGE_LINKS = PAGES.values.map { |path| File.basename(path) }
PAGE_LINKS.each do |file|
  assert("overview links to #{file}", pages["overview"].includes?(file), failures)
end

{
  "Frontloader Studio"                  => "brand concept appears",
  "data-ap-theme-toggle"                => "neutral theme toggle exists",
  "data-ap-theme-set"                   => "neutral explicit theme controls exist",
  "data-ap-pricing"                     => "neutral pricing calculator exists",
  "data-ap-payment-form"                => "neutral payment form exists",
  "data-ap-auth-form"                   => "neutral auth form exists",
  "data-ap-password"                    => "neutral password rules exist",
  "data-ap-password-confirm"            => "neutral password confirmation exists",
  "type=\"email\""                      => "email input uses HTML5 type",
  "autocomplete=\"email\""              => "email autocomplete exists",
  "data-ap-card-number"                 => "neutral payment card formatting exists",
  "data-ap-filter"                      => "neutral table filtering exists",
  "data-ap-command-panel"               => "neutral command palette exists",
  "am-heatmap"                          => "schedule heatmap exists",
  "data-ap-reveal"                      => "neutral timeline reveal exists",
  "data-ap-chat-form"                   => "neutral chat form exists",
  "data-ap-live-search"                 => "neutral live search exists",
  "data-ap-carousel"                    => "neutral carousel exists",
  "data-ap-tabs"                        => "neutral tabs exist",
  "data-ap-dialog-open"                 => "neutral dialog opener helper exists",
  "data-component=\"command-palette\""  => "command palette component is promoted",
  "data-component=\"schedule-heatmap\"" => "schedule heatmap component is promoted",
  "data-component=\"timeline\""         => "timeline component is promoted",
  "data-component=\"tabs\""             => "tabs component is promoted",
  "data-component=\"carousel\""         => "carousel component is promoted",
  "data-component=\"dialog\""           => "dialog component is promoted",
  "data-component=\"payment-form\""     => "payment form component is promoted",
  "data-component=\"auth-form\""        => "auth form component is promoted",
  "data-component=\"theme-switcher\""   => "theme switcher component is promoted",
  "data-component=\"pricing-card\""     => "pricing card component is promoted",
  "data-component=\"field\""            => "field component is promoted",
}.each do |needle, label|
  assert(label, runtime_free_html.includes?(needle), failures)
end

assert("collaboration chat log is a live log", runtime_free_pages["collaboration"].includes?(%Q(role="log" aria-live="polite")), failures)
assert("patterns dialog has accessible name", !!runtime_free_pages["patterns"].match(/<dialog class="am-dialog" id="pattern-dialog"[^>]*aria-labelledby="pattern-dialog-title"/), failures)
assert("dashboard heatmap has table fallback", runtime_free_pages["dashboard"].includes?(%Q(<table class="am-sr-only">)) && runtime_free_pages["dashboard"].includes?(%Q(<th scope="col">Hour</th>)), failures)
assert("dashboard chart has table fallback", runtime_free_pages["dashboard"].includes?(%Q(<th scope="col">Label</th>)) && runtime_free_pages["dashboard"].includes?(%Q(data-chart-adapter="first-party-svg")), failures)
chart_source = File.read(File.join(ROOT, "src/components/examples/simple_chart_component.cr"))
assert("simple chart adapter boundary is explicit", chart_source.includes?(%Q(data-chart-external-root)) && chart_source.includes?(%Q(VALID_ADAPTERS)), failures)
assert("dashboard table has row states", runtime_free_pages["dashboard"].includes?(%Q(data-state="danger")) && runtime_free_pages["dashboard"].includes?(%Q(aria-invalid="true")), failures)
assert("timeline page has Crystal milestone content", runtime_free_pages["timeline"].includes?("Crystal 1.0"), failures)
assert("patterns page has parallax-style CSS/SVG band", runtime_free_pages["patterns"].includes?("am-parallax-band"), failures)

%w[
  initPricing
  initForms
  initPaymentFormatting
  luhnValid
  expiryValid
  initLiveSearch
  initChat
  initCommandPalette
  initTabs
  initCarousel
  initTimelineReveal
  initDialogs
  initStickyHover
].each do |helper|
  assert("JS helper #{helper} exists", js.includes?("function #{helper}"), failures)
end

forbidden_class_patterns = {
  "btn"          => /class="[^"]*\bbtn\b/,
  "btn-primary"  => /class="[^"]*\bbtn-primary\b/,
  "card-body"    => /class="[^"]*\bcard-body\b/,
  "form-control" => /class="[^"]*\bform-control\b/,
  "list-group"   => /class="[^"]*\blist-group\b/,
}
canonical_class_hits = [] of Hash(String, JSON::Any)
runtime_free_pages.each do |page, clean|
  forbidden_class_patterns.each do |name, pattern|
    clean.scan(pattern) do |match|
      canonical_class_hits << {
        "page"         => JSON::Any.new(page),
        "class_family" => JSON::Any.new(name),
        "match"        => JSON::Any.new(match[0][0, 160]),
      }
    end
  end
end
assert("Bootstrap-shaped canonical classes absent: #{canonical_class_hits.map(&.["match"].as_s).join(", ")}", canonical_class_hits.empty?, failures)

canonical_class_audit = {
  "generated_pages_scanned"      => PAGES.keys,
  "runtime_stripped"             => true,
  "forbidden_class_families"     => forbidden_class_patterns.keys,
  "hits"                         => canonical_class_hits,
  "legacy_noncanonical_examples" => [
    "src/generators/brand_kit.cr",
    "examples/interactive_app.cr",
    "examples/migration_scenarios.cr",
    "docs/FRAMEWORK_INTEGRATION.md",
    "output/brand-kit.html",
    "output/shop.html",
  ],
  "migration_note" => "docs/web-design-system/migration.md",
  "passed"         => canonical_class_hits.empty?,
}

unless canonical_class_hits.empty?
  failures << "canonical surface audit found Bootstrap-shaped classes"
end

forbidden_runtime_terms = [
  "node ",
  "node --",
  "playwright",
  "@hotwired/stimulus",
  "Chart.js",
  "chartjs",
  "Amber Cel Studio",
]
forbidden_runtime_terms.each do |term|
  assert("forbidden runtime term #{term.inspect} absent from new web demo/js", !runtime_free_html.includes?(term) && !js.includes?(term), failures)
end
assert("inline onclick handlers absent", !runtime_free_html.includes?("onclick="), failures)

nonzero_tracking = html.lines.select do |line|
  next false unless line.includes?("letter-spacing:")
  value = line.split("letter-spacing:", 2)[1].split(';', 2)[0].strip
  value != "0" && value != "0em"
end
assert("no nonzero letter-spacing in generated demo", nonzero_tracking.empty?, failures)

# === Phase 2 responsive-web assertions =====================================
# Validate that the demo's CSS has been migrated to clamp() and container
# queries rather than relying on fixed pixel min/max-width literals.
clamp_count = html.scan(/\bclamp\(/).size
assert("Phase 2: generated CSS contains >= 20 clamp() expressions (found #{clamp_count})", clamp_count >= 20, failures)

container_block_count = html.scan(/@container\s+[a-zA-Z0-9_-]*\s*\(/).size
assert("Phase 2: generated CSS contains >= 3 @container blocks (found #{container_block_count})", container_block_count >= 3, failures)

# Bare min-width / max-width pixel literals inside *inline* styles outside
# clamp() are forbidden. Block-level <style> rules can still use them in a
# limited way (e.g., the dialog backdrop), but inline `style="..."` strings
# emitted by the renderer must reflow via clamp.
inline_bare_pixel_min = [] of String
runtime_free_pages.each do |_, clean|
  clean.scan(/style="([^"]*)"/) do |match|
    inline = match[1]
    inline.scan(/(?:min|max)-width:\s*(\d{2,4})px/) do |sub|
      # Skip if the surrounding token is inside a clamp() expression.
      pixel_idx = inline.index(sub[0]).not_nil!
      around = inline[Math.max(pixel_idx - 60, 0)..pixel_idx + 10]
      next if around.includes?("clamp(")
      inline_bare_pixel_min << inline[Math.max(pixel_idx - 30, 0)..Math.min(pixel_idx + 30, inline.size - 1)]
    end
  end
end
assert("Phase 2: no bare min/max-width pixel literals outside clamp() in inline styles", inline_bare_pixel_min.empty?, failures)

defined_amber_vars = html.scan(/(--amber-[a-z0-9-]+)\s*:/).map { |match| match[1] }.uniq
used_amber_vars = html.scan(/var\((--amber-[a-z0-9-]+)\)/).map { |match| match[1] }.uniq
undefined_amber_vars = used_amber_vars - defined_amber_vars
assert("all Amber CSS variables used in demo are defined: #{undefined_amber_vars.join(", ")}", undefined_amber_vars.empty?, failures)

audit = {
  "pages"      => PAGES,
  "javascript" => JS,
  "checks"     => {
    "required_pages" => PAGES.keys,
    "theme_contract" => [
      "data-ap-theme-toggle",
      "data-ap-theme-set",
      "data-amber-* compatibility aliases",
      "computed style validation covered by browser audit",
    ],
    "representative_surfaces" => [
      "home",
      "pricing",
      "forms/auth",
      "dashboard",
      "timeline",
      "collaboration",
      "patterns",
    ],
    "semantic_contract" => [
      "one h1 per page",
      "main landmark",
      "unique ids",
      "accessible form labels",
      "native email/password/payment attributes",
      "live regions",
      "no inline onclick",
    ],
    "canonical_surface_audit" => CANONICAL_AUDIT_FILE,
  },
  "failures" => failures,
  "passed"   => failures.empty?,
}

FileUtils.mkdir_p(RESULT_DIR)
FileUtils.mkdir_p(LEGACY_RESULT_DIR)
File.write(CANONICAL_AUDIT_FILE, canonical_class_audit.to_pretty_json)
File.write(RESULT_FILE, audit.to_pretty_json)
FileUtils.cp(CANONICAL_AUDIT_FILE, File.join(LEGACY_RESULT_DIR, File.basename(CANONICAL_AUDIT_FILE)))
FileUtils.cp(RESULT_FILE, File.join(LEGACY_RESULT_DIR, File.basename(RESULT_FILE)))

if failures.empty?
  puts "Web design-system static audit passed: #{RESULT_FILE}"
else
  STDERR.puts "Web design-system static audit failed:"
  failures.each { |failure| STDERR.puts "- #{failure}" }
  exit 1
end
