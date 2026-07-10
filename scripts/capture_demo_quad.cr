# Phase 6 D3 — quad-comparison capture harness.
#
# For each of the 5 Cascade demo screens, captures screenshots on the 4
# user-facing surfaces in light + dark mode:
#   - web-desktop (1280x800)  via CDP
#   - web-mobile  (375x812)   via CDP
#   - iOS sim                 via xcodebuild test (CascadeVisualTests)
#   - macOS host              via the cascade binary's HIG_SCREENSHOT_PATH path
#
# Total: 5 screens x 4 surfaces x 2 appearances = 40 PNGs.
#
# Writes the PNGs into docs/initiative-cross-platform-ui/baselines/
# (Phase 6 owns baseline capture per brief decision #9) and emits a
# quad-comparison HTML page at output/initiative-demo/quad-comparison.html.
#
# Usage:
#   crystal-alpha run scripts/capture_demo_quad.cr -- [--surfaces web,macos,ios] [--slugs demo-sign-in,...]
#
# Surfaces default to "web" (always available); macos/ios require the
# corresponding `make macos` / `make ios` builds to have been run.

require "option_parser"
require "file_utils"
require "./cdp_probes/devtools"

REPO_ROOT = File.expand_path("..", __DIR__)
BASELINE_ROOT = File.join(REPO_ROOT, "docs/initiative-cross-platform-ui/baselines")
OUTPUT_DIR = File.join(REPO_ROOT, "output/initiative-demo")
WEB_HTML_DIR = OUTPUT_DIR

SLUGS = %w[demo-sign-in demo-dashboard demo-detail demo-settings demo-tier-three]
APPEARANCES = %w[light dark]
SURFACES_DEFAULT = %w[web-desktop web-mobile]

WEB_DESKTOP_VIEWPORT = {width: 1280, height: 800}
WEB_MOBILE_VIEWPORT  = {width: 375,  height: 812}

active_surfaces = SURFACES_DEFAULT.dup
active_slugs = SLUGS.dup
do_html_only = false

OptionParser.parse(ARGV) do |opts|
  opts.banner = "Usage: crystal[-alpha] run scripts/capture_demo_quad.cr -- [options]"
  opts.on("--surfaces LIST", "Comma-separated: web-desktop,web-mobile,macos,ios (default web only)") do |v|
    active_surfaces = v.split(",").map(&.strip)
  end
  opts.on("--slugs LIST", "Comma-separated demo slug subset") do |v|
    active_slugs = v.split(",").map(&.strip)
  end
  opts.on("--html-only", "Skip capture; only re-render the quad-comparison.html") do
    do_html_only = true
  end
  opts.on("-h", "--help", "Show this help") {
    puts opts
    exit 0
  }
end

# Make sure baseline dirs exist for each surface.
%w[web-desktop web-mobile macos ios].each do |s|
  FileUtils.mkdir_p(File.join(BASELINE_ROOT, s))
end
FileUtils.mkdir_p(OUTPUT_DIR)

def web_html_path(slug : String, appearance : String) : String
  File.join(WEB_HTML_DIR, "#{slug}-#{appearance}.html")
end

def baseline_path(surface : String, slug : String, appearance : String) : String
  File.join(BASELINE_ROOT, surface, "#{slug}-#{appearance}.png")
end

def tolerance_path(surface : String, slug : String, appearance : String) : String
  File.join(BASELINE_ROOT, surface, "#{slug}-#{appearance}.tolerance.json")
end

def write_tolerance_sidecar(surface : String, slug : String, appearance : String)
  path = tolerance_path(surface, slug, appearance)
  return if File.exists?(path)
  # Schema MUST match scripts/visual_diff.cr's Tolerance record —
  # `pixel_diff_max` (Int64) + `channel_diff_max` (Int32). Earlier
  # iterations used a documentary schema (max_pixel_diff_pct +
  # max_delta_e) that visual_diff.cr does not parse, leaving the
  # tolerance silently at strict-zero. ~5000 pixel allowance covers
  # font-hinting / rasterizer drift across cache states on a 1440x1280
  # baseline (~0.27% of total pixels).
  doc = <<-JSON
  {
    "pixel_diff_max": 5000,
    "channel_diff_max": 12,
    "surface": "#{surface}",
    "slug": "#{slug}",
    "appearance": "#{appearance}",
    "created_phase": "phase-06",
    "notes": "Phase 6 quad-comparison baseline. Tolerance budget covers font-hinting / rasterizer drift across cache states."
  }
  JSON
  File.write(path, doc)
end

def capture_web(slug : String, appearance : String, viewport : NamedTuple(width: Int32, height: Int32), surface : String)
  html_path = web_html_path(slug, appearance)
  unless File.exists?(html_path)
    STDERR.puts "capture_web: missing #{html_path} — run `make -C samples/initiative-cross-platform-ui-demo web` first"
    return false
  end
  out_path = baseline_path(surface, slug, appearance)
  FileUtils.mkdir_p(File.dirname(out_path))

  CDPProbes::CDPSession.with_chrome(html_path, viewport: viewport, color_scheme: appearance) do |dt|
    sleep(0.3.seconds)
    bytes = dt.screenshot_png
    File.write(out_path, bytes)
  end
  if File.exists?(out_path) && File.size(out_path) > 0
    puts "  [ok] #{surface}/#{slug}-#{appearance}.png (#{File.size(out_path)} bytes)"
    write_tolerance_sidecar(surface, slug, appearance)
    true
  else
    STDERR.puts "  [fail] #{surface}/#{slug}-#{appearance}.png — zero-byte"
    false
  end
end

def capture_macos(slug : String, appearance : String)
  binary = File.join(REPO_ROOT, "samples/initiative-cross-platform-ui-demo/macos/bin/cascade")
  unless File.exists?(binary)
    STDERR.puts "capture_macos: missing #{binary} — run `make -C samples/initiative-cross-platform-ui-demo macos` first"
    return false
  end
  out_path = baseline_path("macos", slug, appearance)
  FileUtils.mkdir_p(File.dirname(out_path))
  File.delete(out_path) if File.exists?(out_path)
  env = {
    "DEMO_SLUG"           => slug,
    "DEMO_APPEARANCE"     => appearance,
    "HIG_APPEARANCE"      => appearance,
    "HIG_SCREENSHOT_PATH" => out_path,
  }
  status = Process.run(binary, env: env, output: STDOUT, error: STDERR)
  if status.exit_code == 0 && File.exists?(out_path)
    puts "  [ok] macos/#{slug}-#{appearance}.png"
    write_tolerance_sidecar("macos", slug, appearance)
    true
  else
    STDERR.puts "  [fail] macos/#{slug}-#{appearance}.png (exit=#{status.exit_code})"
    false
  end
end

def capture_ios(slug : String, appearance : String)
  ios_dir = File.join(REPO_ROOT, "samples/initiative-cross-platform-ui-demo/ios")
  xcodeproj = File.join(ios_dir, "CascadeDemo.xcodeproj")
  unless File.exists?(xcodeproj)
    STDERR.puts "capture_ios: missing #{xcodeproj} — run `make -C samples/initiative-cross-platform-ui-demo ios` first"
    return false
  end
  out_path = baseline_path("ios", slug, appearance)
  FileUtils.mkdir_p(File.dirname(out_path))
  derived_data = File.tempname("cascade-derived-data")
  cmd = [
    "xcodebuild", "test",
    "-project", xcodeproj,
    "-scheme", "CascadeDemo",
    "-destination", "platform=iOS Simulator,name=iPhone 17",
    "-only-testing:CascadeDemoUITests/CascadeVisualTests/testRenderDemoSlug",
    "-derivedDataPath", derived_data,
  ]
  # iOS UI tests run inside a separate `*-Runner.app` process; xcodebuild
  # only forwards env vars to that runner if they are prefixed with
  # `TEST_RUNNER_`. Without the prefix, `DEMO_APPEARANCE` lands in
  # xcodebuild but never reaches the XCUITest target — causing the test
  # to fall back to `"light"` for every appearance and producing only
  # `<slug>-light` attachments (so dark captures silently miss).
  env = {
    "DEMO_SLUG"                   => slug,
    "DEMO_APPEARANCE"             => appearance,
    "HIG_APPEARANCE"              => appearance,
    "TEST_RUNNER_DEMO_SLUG"       => slug,
    "TEST_RUNNER_DEMO_APPEARANCE" => appearance,
    "TEST_RUNNER_HIG_APPEARANCE"  => appearance,
  }
  status = Process.run(cmd[0], cmd[1..], env: env, output: STDOUT, error: STDERR)
  if status.exit_code != 0
    STDERR.puts "  [fail] ios/#{slug}-#{appearance}.png (xcodebuild exit=#{status.exit_code})"
    FileUtils.rm_rf(derived_data) rescue nil
    return false
  end
  # Locate the screenshot XCTAttachment in the .xcresult bundle.
  xcresult = Dir["#{derived_data}/**/*.xcresult"].first?
  unless xcresult
    STDERR.puts "  [fail] ios/#{slug}-#{appearance}.png — no .xcresult"
    FileUtils.rm_rf(derived_data) rescue nil
    return false
  end
  # Use xcrun xcresulttool to extract the attachment.
  # Xcode 16+ (iOS 26 toolchain) hides attachments behind nested refs:
  #   ActionsInvocationRecord -> testsRef -> ActionTestPlanRunSummaries
  #     -> ... -> ActionTestSummary (summaryRef) -> activitySummaries
  #     -> attachments[].payloadRef -> binary
  # We collect every ref id we see anywhere in the dump, fetch each as
  # JSON, and scan the union for the attachment whose `name` matches
  # `<slug>-<appearance>`. The previous regex only inspected the top
  # JSON, which never contained the attachments.
  expected = "#{slug}-#{appearance}"
  found = false

  fetch_ref = ->(ref_id : String) : String do
    io = IO::Memory.new
    Process.run("xcrun", ["xcresulttool", "get", "--legacy", "--format", "json", "--path", xcresult, "--id", ref_id], output: io, error: Process::Redirect::Close)
    io.to_s
  end

  fetch_root = -> : String do
    io = IO::Memory.new
    Process.run("xcrun", ["xcresulttool", "get", "--legacy", "--format", "json", "--path", xcresult], output: io, error: Process::Redirect::Close)
    io.to_s
  end

  # Collect ids from a JSON blob: every `"id":{"_value":"…"}`.
  collect_ids = ->(blob : String) : Array(String) do
    blob.scan(/"id"\s*:\s*\{\s*(?:"_type"\s*:\s*\{[^}]*\}\s*,\s*)?"_value"\s*:\s*"([^"]+)"/).map { |m| m[1] }
  end

  begin
    seen = Set(String).new
    queue = [] of String
    root_txt = fetch_root.call
    collect_ids.call(root_txt).each { |i| queue << i unless seen.includes?(i); seen << i }

    # Pattern for the attachment record: name -> _value, then later
    # payloadRef -> id -> _value. Allow optional _type before _value.
    attachment_pattern = /"name"\s*:\s*\{\s*(?:"_type"\s*:\s*\{[^}]*\}\s*,\s*)?"_value"\s*:\s*"#{Regex.escape(expected)}"[\s\S]*?"payloadRef"\s*:\s*\{[\s\S]*?"id"\s*:\s*\{\s*(?:"_type"\s*:\s*\{[^}]*\}\s*,\s*)?"_value"\s*:\s*"([^"]+)"/

    until queue.empty?
      ref_id = queue.shift
      blob = fetch_ref.call(ref_id)
      if m = attachment_pattern.match(blob)
        Process.run("xcrun", ["xcresulttool", "export", "--legacy", "--type", "file", "--path", xcresult, "--id", m[1], "--output-path", out_path],
          output: STDOUT, error: STDERR)
        found = File.exists?(out_path) && File.size(out_path) > 0
        break if found
      end
      collect_ids.call(blob).each { |i| queue << i unless seen.includes?(i); seen << i }
    end
  end
  FileUtils.rm_rf(derived_data) rescue nil
  if found
    puts "  [ok] ios/#{slug}-#{appearance}.png"
    write_tolerance_sidecar("ios", slug, appearance)
    true
  else
    STDERR.puts "  [fail] ios/#{slug}-#{appearance}.png — attachment not found"
    false
  end
end

def render_quad_html(slugs : Array(String))
  out_html = File.join(OUTPUT_DIR, "quad-comparison.html")
  surfaces = ["web-desktop", "web-mobile", "ios", "macos"]
  html = String.build do |io|
    io << "<!doctype html>\n<html lang=\"en\">\n<head>\n"
    io << %(<meta charset="utf-8">) << '\n'
    io << %(<meta name="viewport" content="width=device-width, initial-scale=1">) << '\n'
    io << "<title>Cascade · quad-comparison</title>\n"
    io << <<-CSS
    <style>
    body { font-family: -apple-system, system-ui, sans-serif; margin: 24px; line-height: 1.4; }
    h1 { margin-top: 0; }
    h2 { margin-top: 32px; border-bottom: 1px solid #ddd; padding-bottom: 4px; }
    table { width: 100%; border-collapse: collapse; table-layout: fixed; }
    th, td { padding: 6px; text-align: center; vertical-align: top; border: 1px solid #eee; }
    th { background: #f7f7f7; font-weight: 600; font-size: 14px; }
    .surface-col { width: 25%; }
    .appearance-pair { display: flex; gap: 6px; justify-content: center; }
    .appearance-pair figure { margin: 0; flex: 1 1 0; }
    .appearance-pair figcaption { font-size: 11px; color: #666; }
    img { max-width: 100%; height: auto; border: 1px solid #ccc; }
    .missing { display: inline-block; width: 100%; height: 80px; line-height: 80px;
              background: #fafafa; color: #999; font-size: 12px; font-style: italic; }
    </style>
    CSS
    io << "</head>\n<body>\n"
    io << "<h1>Cascade — quad-comparison</h1>\n"
    io << "<p>Five demo screens rendered across four user-facing surfaces in light and dark appearance. "
    io << "The litmus question: can a reasonable reviewer see this is the same brand?</p>\n"
    slugs.each do |slug|
      io << "<h2>#{slug}</h2>\n"
      io << "<table>\n<thead>\n<tr>"
      surfaces.each { |s| io << %Q(<th class="surface-col">#{s}</th>) }
      io << "</tr>\n</thead>\n<tbody>\n<tr>"
      surfaces.each do |surface|
        io << %Q(<td><div class="appearance-pair">)
        APPEARANCES.each do |appearance|
          path = "../../docs/initiative-cross-platform-ui/baselines/#{surface}/#{slug}-#{appearance}.png"
          abs = File.join(BASELINE_ROOT, surface, "#{slug}-#{appearance}.png")
          if File.exists?(abs)
            io << %Q(<figure><img src="#{path}" alt="#{slug} on #{surface} (#{appearance})"><figcaption>#{appearance}</figcaption></figure>)
          else
            io << %Q(<figure><span class="missing">missing #{appearance}</span><figcaption>#{appearance}</figcaption></figure>)
          end
        end
        io << "</div></td>"
      end
      io << "</tr>\n</tbody>\n</table>\n"
    end
    io << "</body>\n</html>\n"
  end
  File.write(out_html, html)
  puts "wrote #{out_html}"
end

# ----- Driver -----

unless do_html_only
  active_slugs.each do |slug|
    puts "[#{slug}]"
    APPEARANCES.each do |appearance|
      active_surfaces.each do |surface|
        case surface
        when "web-desktop" then capture_web(slug, appearance, WEB_DESKTOP_VIEWPORT, surface)
        when "web-mobile"  then capture_web(slug, appearance, WEB_MOBILE_VIEWPORT, surface)
        when "macos"       then capture_macos(slug, appearance)
        when "ios"         then capture_ios(slug, appearance)
        else
          STDERR.puts "unknown surface: #{surface}"
        end
      end
    end
  end
end

render_quad_html(active_slugs)
puts "done."
