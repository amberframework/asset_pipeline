# Phase 4 R1 — CDP behavior harness for the *WithWebFallback widgets.
#
# Runs the 12 BLOCKED checks from Phase 4 Validator iter 1 against
# the three demo pages under samples/cross_platform/web/dist/. Each
# probe produces a JSON record under
# docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/
# matching the schema documented in the Phase 4 R1 dispatch brief
# §2a (check_id, page, selectors, cdp_methods, trusted_input_trace,
# expected_state, observed_state, pass, artifacts).
#
# Toolkit cites (rubric/behavior-simulation-toolkit.md):
#   §3.1-3.2 Chrome launch + CDP session
#   §3.5 Tab cycle via Input.dispatchKeyEvent (trusted by default)
#   §3.6 Escape + backdrop click via Input.dispatchKeyEvent / dispatchMouseEvent
#   §3.10 axe-core injection via Runtime.evaluate
#   §3.11 file:// URL navigation
#
# Codex Checkpoint 2 corrections applied:
#   * One Chrome process, one fresh /json/new target per probe
#     (matches scripts/axe_amber_demo_audit.cr pattern; avoids
#     focus/global/emulation leakage between probes).
#   * Accessibility.enable added to bootstrap (per toolkit §3.2).
#   * Audit JS (axe-core 4.10.2, ACE 4.0.17) is cached at
#     vendor/cdp/ on first fetch so subsequent runs are offline.
#   * Context-menu open dispatches `trigger.focus()` BEFORE
#     `dispatchEvent("contextmenu", ...)` so the trigger is the
#     focus restoration target.
#
# Usage:
#   crystal run scripts/phase04_cdp_harness.cr
# Optional:
#   PROBE=focus.action-sheet-focus-trap crystal run scripts/phase04_cdp_harness.cr
#     -> only that probe.

require "file_utils"
require "http/client"
require "http/web_socket"
require "json"
require "uri"
require "base64"

ROOT         = File.expand_path("..", __DIR__)
EVIDENCE_DIR = File.join(
  ROOT,
  "docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21",
)
DIST_DIR     = File.join(ROOT, "samples/cross_platform/web/dist")
VENDOR_DIR   = File.join(ROOT, "vendor/cdp")

AXE_URL = "https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js"
ACE_URL = "https://unpkg.com/accessibility-checker-engine@4.0.17/ace.js"

PAGES = {
  "action_sheet"  => File.join(DIST_DIR, "phase04_action_sheet_demo.html"),
  "context_menu"  => File.join(DIST_DIR, "phase04_context_menu_demo.html"),
  "path_control"  => File.join(DIST_DIR, "phase04_path_control_demo.html"),
}

CHROME_CANDIDATES = [
  ENV["CHROME_BIN"]?,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  Process.find_executable("google-chrome"),
  Process.find_executable("chromium"),
  Process.find_executable("chrome"),
].compact

# ------------------------------------------------------------------
# DevTools wrapper (lifted from scripts/axe_amber_demo_audit.cr and
# extended with input + screenshot helpers).
# ------------------------------------------------------------------
class DevTools
  @id = 0

  def initialize(websocket_url : String)
    @messages = Channel(JSON::Any).new(256)
    @ws = HTTP::WebSocket.new(URI.parse(websocket_url))
    @ws.on_message { |message| @messages.send(JSON.parse(message)) }
    spawn { @ws.run }
  end

  def close
    @ws.close
  end

  def call(method : String, params : String? = nil) : JSON::Any
    @id += 1
    payload = String.build do |io|
      io << %({"id":#{@id},"method":)
      method.to_json(io)
      if params
        io << %(,"params":)
        io << params
      end
      io << "}"
    end
    @ws.send(payload)

    loop do
      message = @messages.receive
      if message["id"]?.try(&.as_i?) == @id
        if error = message["error"]?
          raise "#{method} failed: #{error.to_json}"
        end
        return message
      end
    end
  end

  def evaluate(expression : String) : JSON::Any?
    params = %({"expression":#{expression.to_json},"returnByValue":true,"awaitPromise":true})
    result = call("Runtime.evaluate", params)["result"]["result"]
    raise "Runtime.evaluate exception: #{result.to_json}" if result["subtype"]?.try(&.as_s?) == "error"
    result["value"]?
  end

  def dispatch_key(type : String, key : String, code : String, vkc : Int32, modifiers : Int32 = 0)
    call("Input.dispatchKeyEvent",
      %({"type":#{type.to_json},"key":#{key.to_json},"code":#{code.to_json},) +
      %("windowsVirtualKeyCode":#{vkc},"nativeVirtualKeyCode":#{vkc},"modifiers":#{modifiers}})
    )
  end

  # Press a key: keyDown immediately followed by keyUp. CDP-dispatched
  # events are `isTrusted === true` by default — required for the
  # focus-trap probe (the fallback uses real KeyboardEvent semantics
  # rather than gating on `isTrusted`, but several other rubric checks
  # rely on the trust property so this remains the canonical path per
  # toolkit §3.5).
  def press_key(key : String, code : String, vkc : Int32, modifiers : Int32 = 0)
    dispatch_key("keyDown", key, code, vkc, modifiers)
    dispatch_key("keyUp", key, code, vkc, modifiers)
  end

  def mouse_press(x : Float64, y : Float64, button : String = "left", click_count : Int32 = 1)
    call("Input.dispatchMouseEvent",
      %({"type":"mousePressed","x":#{x},"y":#{y},"button":#{button.to_json},"clickCount":#{click_count}})
    )
  end

  def mouse_release(x : Float64, y : Float64, button : String = "left", click_count : Int32 = 1)
    call("Input.dispatchMouseEvent",
      %({"type":"mouseReleased","x":#{x},"y":#{y},"button":#{button.to_json},"clickCount":#{click_count}})
    )
  end

  def click_at(x : Float64, y : Float64, button : String = "left")
    mouse_press(x, y, button)
    mouse_release(x, y, button)
  end

  def screenshot_png : Bytes
    result = call("Page.captureScreenshot")
    Base64.decode(result["result"]["data"].as_s)
  end
end

def fail!(message : String) : NoReturn
  STDERR.puts "[phase04_cdp_harness] FATAL: #{message}"
  exit 1
end

def log(msg : String)
  STDOUT.puts "[phase04_cdp_harness] #{msg}"
end

# ------------------------------------------------------------------
# Resource loader (cached on disk, fetched once per validator host).
# ------------------------------------------------------------------
def load_cached(name : String, url : String) : String
  path = File.join(VENDOR_DIR, name)
  if File.exists?(path) && !File.empty?(path)
    return File.read(path)
  end
  FileUtils.mkdir_p(VENDOR_DIR)
  log "fetching #{name} from #{url}"
  resp = HTTP::Client.get(url)
  fail!("download of #{name} failed: HTTP #{resp.status_code}") unless resp.status.success?
  File.write(path, resp.body)
  resp.body
end

# ------------------------------------------------------------------
# JSON ProbeResult writer per the brief's §2a schema.
# ------------------------------------------------------------------
def write_record(dir : String, check_id : String, hash : Hash)
  FileUtils.mkdir_p(dir)
  path = File.join(dir, "#{check_id}.json")
  File.write(path, hash.to_pretty_json)
  log "  wrote #{path.sub(ROOT + "/", "")}"
end

def write_artifact_png(name : String, bytes : Bytes) : String
  dir = File.join(EVIDENCE_DIR, "screenshots")
  FileUtils.mkdir_p(dir)
  path = File.join(dir, name)
  File.write(path, bytes)
  rel = path.sub(ROOT + "/", "")
  log "  wrote #{rel}"
  rel
end

# ------------------------------------------------------------------
# Chrome boot
# ------------------------------------------------------------------
chrome = CHROME_CANDIDATES.find { |path| File::Info.executable?(path) }
fail!("No Chrome binary found.") unless chrome

axe_source = load_cached("axe.min.js", AXE_URL)
ace_source = load_cached("ace.js", ACE_URL)

port = 9700 + Random.rand(300)
profile_dir = File.tempname("phase04-cdp-chrome")
FileUtils.mkdir_p(profile_dir)
FileUtils.mkdir_p(EVIDENCE_DIR)

log "launching #{chrome} on port #{port}"
process = Process.new(
  chrome,
  [
    "--headless=new",
    "--remote-debugging-port=#{port}",
    "--user-data-dir=#{profile_dir}",
    "--no-first-run",
    "--disable-background-networking",
    "--disable-gpu",
    "about:blank",
  ],
  output: Process::Redirect::Close,
  error: Process::Redirect::Close,
)

# ------------------------------------------------------------------
# Per-probe target factory
# ------------------------------------------------------------------
def with_target(client : HTTP::Client, page_path : String, *, viewport : NamedTuple(width: Int32, height: Int32) = {width: 1280, height: 800}, color_scheme : String = "light", & : DevTools ->)
  resp = client.exec("PUT", "/json/new?about:blank")
  raise "open target failed: #{resp.status_code}" unless resp.status.success?
  ws_url = JSON.parse(resp.body)["webSocketDebuggerUrl"].as_s
  target_id = JSON.parse(resp.body)["id"].as_s

  dt = DevTools.new(ws_url)
  begin
    dt.call("Page.enable")
    dt.call("Runtime.enable")
    dt.call("Accessibility.enable")
    dt.call("Emulation.setDeviceMetricsOverride",
      %({"width":#{viewport[:width]},"height":#{viewport[:height]},"deviceScaleFactor":1,"mobile":false}))
    dt.call("Emulation.setEmulatedMedia",
      %({"features":[{"name":"prefers-color-scheme","value":#{color_scheme.to_json}}]}))
    dt.call("Page.navigate", %({"url":#{"file://#{page_path}".to_json}}))
    100.times do
      break if dt.evaluate(%(document.readyState)).try(&.as_s?) == "complete"
      sleep 0.05.seconds
    end
    yield dt
  ensure
    dt.close
    client.delete("/json/close/#{target_id}") rescue nil
  end
end

# ------------------------------------------------------------------
# Probes
# ------------------------------------------------------------------
PROBE_FILTER = ENV["PROBE"]?

def run?(check_id : String) : Bool
  filter = ENV["PROBE"]?
  filter.nil? || filter.empty? || filter == check_id
end

# ------------------------------------------------------------------
# Accessibility-audit helpers (axe-core + IBM Equal Access).
# ------------------------------------------------------------------
def run_axe_audit(dt : DevTools, axe_source : String, post_open_setup : String? = nil)
  dt.evaluate(post_open_setup) if post_open_setup
  dt.evaluate(axe_source)
  raw = dt.evaluate(<<-JS).not_nil!.as_s
    axe.run(document, {
      runOnly: {
        type: "tag",
        values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22a", "wcag22aa"]
      },
      resultTypes: ["violations", "incomplete"]
    }).then(function (result) {
      return JSON.stringify({
        violations: result.violations.map(function (v) {
          return {
            id: v.id, impact: v.impact, description: v.description, help: v.help,
            nodes: v.nodes.map(function (n) {
              return {target: n.target, html: (n.html || '').slice(0, 180), failureSummary: n.failureSummary || ''};
            })
          };
        }),
        incomplete: result.incomplete.map(function (v) {
          return {id: v.id, impact: v.impact, help: v.help, node_count: v.nodes.length};
        }),
      });
    })
    JS
  JSON.parse(raw)
end

def run_ibm_audit(dt : DevTools, ace_source : String, post_open_setup : String? = nil)
  dt.evaluate(post_open_setup) if post_open_setup
  dt.evaluate(ace_source)
  raw = dt.evaluate(<<-JS).not_nil!.as_s
    (async () => {
      const checker = new ace.Checker();
      const rawReport = await checker.check(document, ["IBM_Accessibility"]);
      const report = rawReport.report || rawReport;
      const active = report.results.filter(function (r) { return r.value && r.value[1] !== "PASS"; });
      return JSON.stringify({
        summary: report.summary,
        active: active.map(function (r) {
          return {
            ruleId: r.ruleId, reasonId: r.reasonId,
            level: r.level || String((r.value || [])[0] || "").toLowerCase(),
            value: r.value, message: r.message, path: r.path,
            snippet: (r.snippet || "").slice(0, 180),
          };
        })
      });
    })()
    JS
  JSON.parse(raw)
end

CASES_4 = [
  {label: "1280-light", w: 1280, h: 800, scheme: "light"},
  {label: "1280-dark",  w: 1280, h: 800, scheme: "dark"},
  {label: "375-light",  w: 375,  h: 667, scheme: "light"},
  {label: "375-dark",   w: 375,  h: 667, scheme: "dark"},
]

# JS to open the center context menu by focusing the trigger and
# dispatching a synthetic contextmenu event at the trigger's center.
# Used by Family B (keyboard nav + outside-click) and Family C
# (axe-core / IBM Equal Access on the open menu DOM).
CTX_OPEN_HELPER = <<-JS
(function () {
  var t = window.__phase4.triggerFor('center');
  t.focus();
  var r = t.getBoundingClientRect();
  var ev = new MouseEvent('contextmenu', {
    bubbles: true, cancelable: true,
    clientX: r.left + r.width / 2, clientY: r.top + r.height / 2,
  });
  t.dispatchEvent(ev);
  return true;
})()
JS

def matrix_audit(client : HTTP::Client, page_path : String, *, axe_source : String? = nil, ace_source : String? = nil, open_helper : String? = nil)
  results = [] of Hash(String, JSON::Any)
  screenshots = [] of String
  failures = [] of String

  CASES_4.each do |c|
    with_target(client, page_path, viewport: {width: c[:w], height: c[:h]}, color_scheme: c[:scheme]) do |dt|
      dt.evaluate(open_helper) if open_helper

      # Capture audit-time DOM context so the validator can verify the
      # auditor was looking at the expected state (per Codex Checkpoint 3
      # Family C: more rigorous documentation of what was audited).
      context_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify({
          action_sheet_presented: !!(document.querySelector('.ap-action-sheet[data-presented="true"]')),
          context_menu_presented: !!(document.querySelector('.ap-ctx-menu[data-presented="true"]')),
          context_menu_item_count: document.querySelectorAll('.ap-ctx-menu__item').length,
          breadcrumb_present: !!(document.querySelector('nav[aria-label="Breadcrumb"]')),
          active_element_tag: document.activeElement ? document.activeElement.tagName : null,
        })
        JS
      audit_context = JSON.parse(context_json)

      if axe_source
        parsed = run_axe_audit(dt, axe_source)
        violations = parsed["violations"].as_a
        serious = violations.select do |v|
          impact = v["impact"]?.try(&.as_s?) || ""
          ["serious", "critical"].includes?(impact)
        end
        results << {
          "viewport"                  => JSON::Any.new(c[:label]),
          "scheme"                    => JSON::Any.new(c[:scheme]),
          "audit_context"             => audit_context,
          "violations"                => parsed["violations"],
          "incomplete"                => parsed["incomplete"],
          "serious_or_critical_count" => JSON::Any.new(serious.size.to_i64),
        }
        serious.each do |v|
          failures << "#{c[:label]} #{v["impact"].as_s}/#{v["id"].as_s}: #{v["help"].as_s}"
        end
      end

      if ace_source
        parsed = run_ibm_audit(dt, ace_source)
        # Hard-fail IBM convention (matches scripts/ibm_amber_demo_audit.cr):
        # only "VIOLATION" rules with "FAIL" status count as gating failures.
        # POTENTIAL / MANUAL findings are retained in `active` for the
        # validator's manual adjudication against the separate behavior probes.
        violations = parsed["active"].as_a.select do |r|
          value = r["value"]?.try(&.as_a?) || [] of JSON::Any
          kind = value[0]?.try(&.as_s?) || ""
          status = value[1]?.try(&.as_s?) || ""
          kind == "VIOLATION" && status == "FAIL"
        end
        results << {
          "viewport"             => JSON::Any.new(c[:label]),
          "scheme"               => JSON::Any.new(c[:scheme]),
          "audit_context"        => audit_context,
          "summary"              => parsed["summary"]? || JSON::Any.new(nil),
          "active"               => parsed["active"],
          "violation_fail_count" => JSON::Any.new(violations.size.to_i64),
        }
        violations.each do |v|
          failures << "#{c[:label]} IBM #{v["ruleId"].as_s}: #{v["message"].as_s}"
        end
      end

      # Screenshot only when axe is running (audits/screenshots are paired
      # in the rubric on the axe-clean check; ibm is structured-data only).
      if axe_source
        shot = dt.screenshot_png
        name = "#{File.basename(page_path, ".html")}-#{c[:label]}.png"
        rel = write_artifact_png(name, shot)
        screenshots << rel
      end
    end
  end
  {results: results, failures: failures, screenshots: screenshots}
end

begin
  client = HTTP::Client.new("127.0.0.1", port)
  ready = false
  60.times do
    begin
      response = client.get("/json/version")
      if response.status.success?
        ready = true
        break
      end
    rescue
    end
    sleep 0.2.seconds
  end
  fail!("Chrome DevTools never came up on port #{port}.") unless ready
  log "DevTools ready on 127.0.0.1:#{port}"

  inspections_dir = File.join(EVIDENCE_DIR, "inspections")
  audits_dir = File.join(EVIDENCE_DIR, "audits")
  FileUtils.mkdir_p(inspections_dir)
  FileUtils.mkdir_p(audits_dir)

  any_failed = false

  # ----------------------------------------------------------------
  # Family A — ActionSheet behavior probes
  # ----------------------------------------------------------------

  if run?("focus.action-sheet-focus-trap")
    log "probe: focus.action-sheet-focus-trap"
    with_target(client, PAGES["action_sheet"], viewport: {width: 1280, height: 800}) do |dt|
      # Open the sheet via the helper (forces closed -> open transition).
      dt.evaluate("(async () => { await window.__phase4.open(); return true; })()")
      dt.evaluate("window.__focusTrace = []; window.__phase4.pushTrace();")

      focusables_count_json = dt.evaluate("window.__phase4.focusables().length")
      focusable_count = focusables_count_json.try(&.as_i?) || 0

      tabs = focusable_count + 2
      tabs.times do
        dt.press_key("Tab", "Tab", 9)
        dt.evaluate("window.__phase4.pushTrace();")
      end
      tabs.times do
        # Shift+Tab. CDP modifier bitmask: 8 = Shift.
        dt.press_key("Tab", "Tab", 9, 8)
        dt.evaluate("window.__phase4.pushTrace();")
      end

      trace_json = dt.evaluate("JSON.stringify(window.__focusTrace)").not_nil!.as_s
      trace = JSON.parse(trace_json).as_a

      # After-open trace[0] is the focus that lands inside the panel.
      # Then Tab entries [1..tabs]. Then Shift+Tab entries [tabs+1..2*tabs].
      tab_entries = trace[1, tabs]
      shift_tab_entries = trace[1 + tabs, tabs]

      all_inside = trace.all? { |e| e["inside"]?.try(&.as_bool?) == true }
      # Action sheet buttons don't carry data-testid (the visitor only emits
      # it on the host root). Identify focusables by label text instead;
      # labels are unique for this test scene (Save / Delete / Cancel).
      distinct_labels = trace.compact_map { |e| e["label"]?.try(&.as_s?) }.to_set
      tab_cycle_detected = tab_entries.size > focusable_count &&
        tab_entries[0]["label"]? == tab_entries[focusable_count]?.try(&.["label"]?)
      shift_cycle_detected = shift_tab_entries.size > focusable_count &&
        shift_tab_entries[0]["label"]? == shift_tab_entries[focusable_count]?.try(&.["label"]?)

      passed = all_inside &&
               distinct_labels.size >= focusable_count &&
               tab_cycle_detected &&
               shift_cycle_detected

      record = {
        "check_id" => "focus.action-sheet-focus-trap",
        "page" => "samples/cross_platform/web/dist/phase04_action_sheet_demo.html",
        "selectors" => [".ap-action-sheet__panel", ".ap-action-sheet__action", "[data-testid=action-sheet-trigger]"],
        "cdp_methods" => ["Page.navigate", "Runtime.evaluate (__phase4.open)", "Input.dispatchKeyEvent (Tab x N)", "Input.dispatchKeyEvent (Shift+Tab x N)", "Runtime.evaluate (window.__focusTrace)"],
        "trusted_input_trace" => (["click trigger (__phase4.open)"] + Array.new(tabs, "Tab") + Array.new(tabs, "Shift+Tab")),
        "expected_state" => {
          "focusable_count_at_least"                 => focusable_count,
          "every_trace_entry_inside_panel"           => true,
          "tab_cycle_returns_to_first_after_N_tabs"  => true,
          "shift_tab_cycle_returns_to_first_after_N" => true,
        },
        "observed_state" => {
          "focusable_count"             => focusable_count,
          "trace_length"                => trace.size,
          "distinct_labels_visited"     => distinct_labels.to_a,
          "all_entries_inside_panel"    => all_inside,
          "tab_cycle_detected"          => tab_cycle_detected,
          "shift_tab_cycle_detected"    => shift_cycle_detected,
          "tab_phase_labels"            => tab_entries.compact_map { |e| e["label"]?.try(&.as_s?) },
          "shift_tab_phase_labels"      => shift_tab_entries.compact_map { |e| e["label"]?.try(&.as_s?) },
          "full_focus_trace"            => trace,
          "testid_note"                 => "renderer does not emit data-testid on inner action buttons; identity established via unique label text (Save / Delete / Cancel)",
        },
        "pass" => passed,
        "artifacts" => ["inspections/focus.action-sheet-focus-trap.json"],
      }
      write_record(inspections_dir, "focus.action-sheet-focus-trap", record)
      any_failed = true unless passed
    end
  end

  if run?("focus.action-sheet-escape-closes")
    log "probe: focus.action-sheet-escape-closes"
    with_target(client, PAGES["action_sheet"]) do |dt|
      dt.evaluate("(async () => { await window.__phase4.open(); return true; })()")
      pre_snapshot_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify({
          data_presented: document.querySelector('.ap-action-sheet').getAttribute('data-presented'),
          dismiss_log_length: (window.__phase4DismissLog || []).length,
          panel_ax_visible: (function() {
            var p = document.querySelector('.ap-action-sheet__panel');
            if (!p) return false;
            if (p.getAttribute('aria-hidden') === 'true') return false;
            if (getComputedStyle(p).display === 'none') return false;
            if (getComputedStyle(document.querySelector('.ap-action-sheet')).display === 'none') return false;
            return true;
          })(),
          active_in_panel: !!(document.activeElement &&
            document.activeElement.closest('.ap-action-sheet__panel')),
          active_tag: document.activeElement ? document.activeElement.tagName : null,
        })
        JS
      pre_snapshot = JSON.parse(pre_snapshot_json)
      dt.press_key("Escape", "Escape", 27)
      sleep 0.05.seconds

      obs_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify({
          dismiss_log: window.__phase4DismissLog,
          data_presented: document.querySelector('.ap-action-sheet').getAttribute('data-presented'),
          panel_ax_visible: (function() {
            var p = document.querySelector('.ap-action-sheet__panel');
            if (!p) return false;
            if (p.getAttribute('aria-hidden') === 'true') return false;
            if (getComputedStyle(p).display === 'none') return false;
            if (getComputedStyle(document.querySelector('.ap-action-sheet')).display === 'none') return false;
            return true;
          })(),
          focus_restored: document.activeElement === window.__trigger,
          active_testid: document.activeElement ? document.activeElement.getAttribute('data-testid') : null,
          trigger_testid: window.__trigger ? window.__trigger.getAttribute('data-testid') : null,
        })
        JS
      obs = JSON.parse(obs_json)
      dismiss_log = obs["dismiss_log"]?.try(&.as_a?) || [] of JSON::Any
      escape_entry = dismiss_log.any? { |e| e["reason"]?.try(&.as_s?) == "escape" } && dismiss_log.size == 1
      passed = escape_entry &&
        obs["data_presented"]?.try(&.as_s?) == "false" &&
        obs["panel_ax_visible"]?.try(&.as_bool?) == false &&
        obs["focus_restored"]?.try(&.as_bool?) == true

      record = {
        "check_id" => "focus.action-sheet-escape-closes",
        "page" => "samples/cross_platform/web/dist/phase04_action_sheet_demo.html",
        "selectors" => [".ap-action-sheet", ".ap-action-sheet__panel", "[data-testid=action-sheet-trigger]"],
        "cdp_methods" => ["Runtime.evaluate (__phase4.open)", "Input.dispatchKeyEvent (Escape)", "Runtime.evaluate (4-boolean snapshot)"],
        "trusted_input_trace" => ["click trigger (__phase4.open)", "Escape"],
        "expected_state" => {
          "dismiss_log_single_escape" => true,
          "data_presented" => "false",
          "panel_ax_visible" => false,
          "focus_restored" => true,
        },
        "observed_state" => {
          "pre_snapshot" => {
            "data_presented"     => pre_snapshot["data_presented"],
            "dismiss_log_length" => pre_snapshot["dismiss_log_length"],
            "panel_ax_visible"   => pre_snapshot["panel_ax_visible"],
            "active_in_panel"    => pre_snapshot["active_in_panel"],
            "active_tag"         => pre_snapshot["active_tag"],
          },
          "post_snapshot" => {
            "dismiss_log"     => obs["dismiss_log"],
            "data_presented"  => obs["data_presented"],
            "panel_ax_visible"=> obs["panel_ax_visible"],
            "focus_restored"  => obs["focus_restored"],
            "active_testid"   => obs["active_testid"],
            "trigger_testid"  => obs["trigger_testid"],
          },
        },
        "pass" => passed,
        "artifacts" => ["inspections/focus.action-sheet-escape-closes.json"],
      }
      write_record(inspections_dir, "focus.action-sheet-escape-closes", record)
      any_failed = true unless passed
    end
  end

  if run?("focus.action-sheet-backdrop-click-closes")
    log "probe: focus.action-sheet-backdrop-click-closes"
    with_target(client, PAGES["action_sheet"]) do |dt|
      dt.evaluate("(async () => { await window.__phase4.open(); return true; })()")
      pre_snapshot_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify({
          data_presented: document.querySelector('.ap-action-sheet').getAttribute('data-presented'),
          dismiss_log_length: (window.__phase4DismissLog || []).length,
          panel_ax_visible: getComputedStyle(document.querySelector('.ap-action-sheet')).display !== 'none',
          active_in_panel: !!(document.activeElement &&
            document.activeElement.closest('.ap-action-sheet__panel')),
        })
        JS
      pre_snapshot = JSON.parse(pre_snapshot_json)
      rects_json = dt.evaluate(<<-JS).not_nil!.as_s
        (function () {
          var p = window.__phase4.panel().getBoundingClientRect();
          var b = window.__phase4.backdrop().getBoundingClientRect();
          return JSON.stringify({
            panel_rect: {left: p.left, top: p.top, right: p.right, bottom: p.bottom, width: p.width, height: p.height},
            backdrop_rect: {left: b.left, top: b.top, right: b.right, bottom: b.bottom, width: b.width, height: b.height},
            viewport: {w: window.innerWidth, h: window.innerHeight}
          });
        })()
        JS
      rects = JSON.parse(rects_json)
      backdrop = rects["backdrop_rect"]
      panel = rects["panel_rect"]
      # Click well above the panel (which docks bottom on mobile, centered on desktop)
      # so we land squarely on the backdrop. On a 1280x800 viewport with a centered
      # panel (max 420 wide), backdrop center vertically at top-quarter is outside the panel.
      click_x = backdrop["left"].as_f + 24.0
      click_y = backdrop["top"].as_f + 24.0
      # Sanity: ensure click is outside panel rect.
      inside_panel = click_x >= panel["left"].as_f && click_x <= panel["right"].as_f &&
                     click_y >= panel["top"].as_f && click_y <= panel["bottom"].as_f
      if inside_panel
        # Fall back to a guaranteed-outside point: top-left + 8 px.
        click_x = 8.0
        click_y = 8.0
      end
      dt.click_at(click_x, click_y)
      sleep 0.1.seconds

      obs_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify({
          dismiss_log: window.__phase4DismissLog,
          data_presented: document.querySelector('.ap-action-sheet').getAttribute('data-presented'),
          panel_ax_visible: (function() {
            var p = document.querySelector('.ap-action-sheet__panel');
            if (!p) return false;
            if (getComputedStyle(document.querySelector('.ap-action-sheet')).display === 'none') return false;
            return true;
          })(),
          focus_restored: document.activeElement === window.__trigger,
          active_testid: document.activeElement ? document.activeElement.getAttribute('data-testid') : null,
        })
        JS
      obs = JSON.parse(obs_json)
      dismiss_log = obs["dismiss_log"]?.try(&.as_a?) || [] of JSON::Any
      backdrop_entry = dismiss_log.any? { |e| e["reason"]?.try(&.as_s?) == "backdrop" } && dismiss_log.size == 1
      passed = backdrop_entry &&
        obs["data_presented"]?.try(&.as_s?) == "false" &&
        obs["panel_ax_visible"]?.try(&.as_bool?) == false &&
        obs["focus_restored"]?.try(&.as_bool?) == true

      record = {
        "check_id" => "focus.action-sheet-backdrop-click-closes",
        "page" => "samples/cross_platform/web/dist/phase04_action_sheet_demo.html",
        "selectors" => [".ap-action-sheet__backdrop", ".ap-action-sheet__panel"],
        "cdp_methods" => ["Runtime.evaluate (__phase4.open)", "Runtime.evaluate (rect capture)", "Input.dispatchMouseEvent (mousePressed/mouseReleased)", "Runtime.evaluate (4-boolean snapshot)"],
        "trusted_input_trace" => ["click trigger (__phase4.open)", "mouseDown@(#{click_x},#{click_y})", "mouseUp@(#{click_x},#{click_y})"],
        "expected_state" => {
          "dismiss_log_single_backdrop" => true,
          "data_presented" => "false",
          "panel_ax_visible" => false,
          "focus_restored" => true,
        },
        "observed_state" => {
          "pre_snapshot" => {
            "data_presented"     => pre_snapshot["data_presented"],
            "dismiss_log_length" => pre_snapshot["dismiss_log_length"],
            "panel_ax_visible"   => pre_snapshot["panel_ax_visible"],
            "active_in_panel"    => pre_snapshot["active_in_panel"],
          },
          "panel_rect" => rects["panel_rect"],
          "backdrop_rect" => rects["backdrop_rect"],
          "click_point" => {"x" => click_x, "y" => click_y},
          "click_outside_panel" => !inside_panel,
          "post_snapshot" => {
            "dismiss_log"      => obs["dismiss_log"],
            "data_presented"   => obs["data_presented"],
            "panel_ax_visible" => obs["panel_ax_visible"],
            "focus_restored"   => obs["focus_restored"],
            "active_testid"    => obs["active_testid"],
          },
        },
        "pass" => passed,
        "artifacts" => ["inspections/focus.action-sheet-backdrop-click-closes.json"],
      }
      write_record(inspections_dir, "focus.action-sheet-backdrop-click-closes", record)
      any_failed = true unless passed
    end
  end

  if run?("conformance.action-sheet-positioning")
    log "probe: conformance.action-sheet-positioning"
    viewports = [
      {label: "1280", w: 1280, h: 800},
      {label: "375", w: 375, h: 667},
      {label: "320", w: 320, h: 568},
    ]
    all_pass = true
    viewports.each do |vp|
      with_target(client, PAGES["action_sheet"], viewport: {width: vp[:w], height: vp[:h]}) do |dt|
        dt.evaluate("(async () => { await window.__phase4.open(); return true; })()")
        rect_json = dt.evaluate(<<-JS).not_nil!.as_s
          (function () {
            var p = window.__phase4.panel().getBoundingClientRect();
            return JSON.stringify({
              rect: {left: p.left, top: p.top, right: p.right, bottom: p.bottom, width: p.width, height: p.height},
              viewport: {w: window.innerWidth, h: window.innerHeight},
              title_lines: (function () {
                var t = document.querySelector('.ap-action-sheet__title');
                if (!t) return 0;
                var lh = parseFloat(getComputedStyle(t).lineHeight);
                if (!isFinite(lh)) lh = parseFloat(getComputedStyle(t).fontSize) * 1.2;
                return Math.round(t.getBoundingClientRect().height / lh);
              })(),
            });
          })()
          JS
        info = JSON.parse(rect_json)
        rect = info["rect"]
        viewport = info["viewport"]
        vw = viewport["w"].as_f
        vh = viewport["h"].as_f
        rl = rect["left"].as_f
        rt = rect["top"].as_f
        rr = rect["right"].as_f
        rb = rect["bottom"].as_f
        rw = rect["width"].as_f
        rh = rect["height"].as_f

        case vp[:label]
        when "1280"
          horiz_center = (rl + rw / 2 - vw / 2).abs
          vert_center = (rt + rh / 2 - vh / 2).abs
          predicates = {
            "horizontal_centered_within_2px" => horiz_center <= 2.0,
            "vertical_centered_within_2px" => vert_center <= 2.0,
          }
        when "375"
          predicates = {
            "panel_bottom_equals_viewport" => (rb - vh).abs <= 0.5,
            "panel_left_equals_0" => rl.abs <= 0.5,
            "panel_right_equals_viewport_width" => (rr - vw).abs <= 0.5,
          }
        else # "320" - mobile-min: predicates from rubric §conformance.action-sheet-positioning
          predicates = {
            "panel_does_not_overflow_horizontally" => rr <= vw + 0.5 && rl >= -0.5,
            "title_at_most_3_lines"                => info["title_lines"].as_i <= 3,
            "panel_bottom_equals_viewport"         => (rb - vh).abs <= 0.5,
            "panel_left_equals_0"                  => rl.abs <= 0.5,
            "panel_right_equals_viewport_width"    => (rr - vw).abs <= 0.5,
          }
        end

        passed = predicates.values.all?
        all_pass = false unless passed
        record = {
          "check_id" => "conformance.action-sheet-positioning-#{vp[:label]}",
          "page" => "samples/cross_platform/web/dist/phase04_action_sheet_demo.html",
          "selectors" => [".ap-action-sheet__panel"],
          "cdp_methods" => ["Emulation.setDeviceMetricsOverride", "Runtime.evaluate (__phase4.open)", "Runtime.evaluate (getBoundingClientRect)"],
          "trusted_input_trace" => ["setDeviceMetricsOverride #{vp[:w]}x#{vp[:h]}", "click trigger (__phase4.open)"],
          "expected_state" => predicates.transform_values { |_| true },
          "observed_state" => {
            "viewport" => viewport,
            "panel_rect" => rect,
            "predicates" => predicates,
            "title_lines" => info["title_lines"],
          },
          "pass" => passed,
          "artifacts" => ["inspections/conformance.action-sheet-positioning-#{vp[:label]}.json"],
        }
        write_record(inspections_dir, "conformance.action-sheet-positioning-#{vp[:label]}", record)
      end
    end
    any_failed = true unless all_pass
  end

  if run?("conformance.action-sheet-touch-targets")
    log "probe: conformance.action-sheet-touch-targets"
    with_target(client, PAGES["action_sheet"], viewport: {width: 375, height: 667}) do |dt|
      dt.evaluate("(async () => { await window.__phase4.open(); return true; })()")
      info_json = dt.evaluate(<<-JS).not_nil!.as_s
        (function () {
          var btns = Array.from(document.querySelectorAll('[data-ap-as-action], [data-ap-as-dismiss="cancel"]'));
          return JSON.stringify(btns.map(function (b) {
            var r = b.getBoundingClientRect();
            return {
              testid_or_action: b.getAttribute('data-ap-as-action') || b.getAttribute('data-ap-as-dismiss'),
              label: (b.textContent || '').trim(),
              width: r.width, height: r.height,
              meets_44pt: r.width >= 44 && r.height >= 44,
            };
          }));
        })()
        JS
      arr = JSON.parse(info_json).as_a
      all_meet = arr.all? { |e| e["meets_44pt"]?.try(&.as_bool?) == true }

      record = {
        "check_id" => "conformance.action-sheet-touch-targets",
        "page" => "samples/cross_platform/web/dist/phase04_action_sheet_demo.html",
        "selectors" => ["[data-ap-as-action]", "[data-ap-as-dismiss=cancel]"],
        "cdp_methods" => ["Emulation.setDeviceMetricsOverride (375x667)", "Runtime.evaluate (__phase4.open)", "Runtime.evaluate (getBoundingClientRect per button)"],
        "trusted_input_trace" => ["setDeviceMetricsOverride 375x667", "click trigger (__phase4.open)"],
        "expected_state" => {"every_button_meets_44pt" => true},
        "observed_state" => {
          "button_count" => arr.size,
          "rects" => arr,
          "every_button_meets_44pt" => all_meet,
        },
        "pass" => all_meet,
        "artifacts" => ["inspections/conformance.action-sheet-touch-targets.json"],
      }
      write_record(inspections_dir, "conformance.action-sheet-touch-targets", record)
      any_failed = true unless all_meet
    end
  end

  # Accessibility audits: axe-core + IBM Equal Access at light/dark x desktop/mobile.
  # The rubric requires "screenshot of the presented sheet at 1280x800 desktop
  # light/dark and 375x667 mobile light/dark" and zero serious/critical violations.

  if run?("fallback.action-sheet-axe-clean")
    log "probe: fallback.action-sheet-axe-clean"
    out = matrix_audit(client, PAGES["action_sheet"],
      axe_source: axe_source,
      open_helper: "(async () => { await window.__phase4.open(); return true; })()")
    passed = out[:failures].empty?
    record = {
      "check_id" => "fallback.action-sheet-axe-clean",
      "page" => "samples/cross_platform/web/dist/phase04_action_sheet_demo.html",
      "selectors" => [".ap-action-sheet[data-presented=true]"],
      "cdp_methods" => ["Runtime.evaluate (axe-core 4.10.2)", "Runtime.evaluate (axe.run)", "Page.captureScreenshot"],
      "trusted_input_trace" => ["click trigger (__phase4.open)", "axe.run(document)"],
      "expected_state" => {"serious_or_critical_violation_count_total" => 0},
      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
      "pass" => passed,
      "artifacts" => out[:screenshots] + ["audits/fallback.action-sheet-axe-clean.json"],
    }
    write_record(audits_dir, "fallback.action-sheet-axe-clean", record)
    any_failed = true unless passed
  end

  if run?("fallback.action-sheet-ibm-equal-access-clean")
    log "probe: fallback.action-sheet-ibm-equal-access-clean"
    out = matrix_audit(client, PAGES["action_sheet"],
      ace_source: ace_source,
      open_helper: "(async () => { await window.__phase4.open(); return true; })()")
    passed = out[:failures].empty?
    record = {
      "check_id" => "fallback.action-sheet-ibm-equal-access-clean",
      "page" => "samples/cross_platform/web/dist/phase04_action_sheet_demo.html",
      "selectors" => [".ap-action-sheet[data-presented=true]"],
      "cdp_methods" => ["Runtime.evaluate (accessibility-checker-engine 4.0.17)", "Runtime.evaluate (ace.Checker.check)"],
      "trusted_input_trace" => ["click trigger (__phase4.open)", "ace.Checker.check(document, ['IBM_Accessibility'])"],
      "expected_state" => {"ibm_violation_fail_count_total" => 0},
      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
      "pass" => passed,
      "artifacts" => ["audits/fallback.action-sheet-ibm-equal-access-clean.json"],
    }
    write_record(audits_dir, "fallback.action-sheet-ibm-equal-access-clean", record)
    any_failed = true unless passed
  end

  # ----------------------------------------------------------------
  # Family B — ContextMenu keyboard
  # ----------------------------------------------------------------

  if run?("focus.context-menu-keyboard-nav")
    log "probe: focus.context-menu-keyboard-nav"
    with_target(client, PAGES["context_menu"]) do |dt|
      dt.evaluate("window.__phase4.ensureDismissLog();")
      # Snapshot the menu item fixture before opening so the validator
      # can independently verify which items are disabled and the
      # expected enabled-traversal order (per Codex Checkpoint 3 Family B).
      menu_items_snapshot_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify(
          Array.from(window.__phase4.menuFor('center').querySelectorAll('.ap-ctx-menu__item')).map(function (el, i) {
            return {
              index: i,
              label: (el.textContent || '').trim(),
              aria_disabled: el.getAttribute('aria-disabled') || 'false',
              is_destructive: el.classList.contains('ap-ctx-menu__item--destructive'),
            };
          })
        )
        JS
      menu_items_snapshot = JSON.parse(menu_items_snapshot_json)
      dt.evaluate(CTX_OPEN_HELPER)
      sleep 0.05.seconds

      transcript = [] of Hash(String, JSON::Any)
      record_active = ->(label : String) {
        info_json = dt.evaluate(<<-JS).not_nil!.as_s
          JSON.stringify({
            tag: document.activeElement ? document.activeElement.tagName : null,
            label: document.activeElement ? (document.activeElement.textContent || '').trim().slice(0, 30) : null,
            disabled: document.activeElement ? document.activeElement.getAttribute('aria-disabled') : null,
            in_menu: !!(document.activeElement && document.activeElement.closest('.ap-ctx-menu')),
          })
          JS
        info = JSON.parse(info_json)
        transcript << {
          "after" => JSON::Any.new(label),
          "tag" => info["tag"],
          "label" => info["label"],
          "aria_disabled" => info["disabled"],
          "in_menu" => info["in_menu"],
        }
      }

      record_active.call("open")
      # ArrowDown ArrowDown ArrowUp Home End Escape
      [{key: "ArrowDown", code: "ArrowDown", vkc: 40},
       {key: "ArrowDown", code: "ArrowDown", vkc: 40},
       {key: "ArrowUp", code: "ArrowUp", vkc: 38},
       {key: "Home", code: "Home", vkc: 36},
       {key: "End", code: "End", vkc: 35},
       {key: "Escape", code: "Escape", vkc: 27}].each do |k|
        dt.press_key(k[:key], k[:code], k[:vkc])
        sleep 0.04.seconds
        record_active.call(k[:key])
      end

      # Post-Escape: menu closed; focus returned to trigger; no disabled item visited
      menu_closed_json = dt.evaluate("window.__phase4.menuFor('center').getAttribute('data-presented')")
      focus_on_trigger_json = dt.evaluate("document.activeElement === window.__phase4.triggerFor('center')")
      no_disabled_visited = transcript.none? { |t| t["aria_disabled"]?.try(&.as_s?) == "true" }
      menu_closed = menu_closed_json.try(&.as_s?) == "false"
      focus_returned = focus_on_trigger_json.try(&.as_bool?) == true

      passed = menu_closed && focus_returned && no_disabled_visited

      record = {
        "check_id" => "focus.context-menu-keyboard-nav",
        "page" => "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
        "selectors" => ["[data-testid=ctx-trigger-center]", ".ap-ctx-menu", ".ap-ctx-menu__item"],
        "cdp_methods" => ["Runtime.evaluate (trigger.focus + dispatchEvent contextmenu)", "Input.dispatchKeyEvent (ArrowDown/Up/Home/End/Escape)", "Runtime.evaluate (activeElement transcript)"],
        "trusted_input_trace" => ["trigger.focus", "dispatchEvent('contextmenu')", "ArrowDown", "ArrowDown", "ArrowUp", "Home", "End", "Escape"],
        "expected_state" => {
          "menu_closed_after_escape" => true,
          "focus_returned_to_trigger" => true,
          "no_disabled_item_visited" => true,
        },
        "observed_state" => {
          "menu_items_fixture"        => menu_items_snapshot,
          "transcript"                => transcript,
          "menu_closed_after_escape"  => menu_closed,
          "focus_returned_to_trigger" => focus_returned,
          "no_disabled_item_visited"  => no_disabled_visited,
        },
        "pass" => passed,
        "artifacts" => ["inspections/focus.context-menu-keyboard-nav.json"],
      }
      write_record(inspections_dir, "focus.context-menu-keyboard-nav", record)
      any_failed = true unless passed
    end
  end

  if run?("focus.context-menu-outside-click-closes")
    log "probe: focus.context-menu-outside-click-closes"
    with_target(client, PAGES["context_menu"]) do |dt|
      dt.evaluate("window.__phase4.ensureDismissLog();")
      dt.evaluate(CTX_OPEN_HELPER)
      sleep 0.05.seconds
      pre = dt.evaluate("window.__phase4.menuFor('center').getAttribute('data-presented')")
      # Click on a point far outside the menu rect (top-right corner area, avoiding
      # the bottom-right trigger which is at the very corner).
      rect_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify({
          menu: window.__phase4.menuFor('center').getBoundingClientRect(),
          viewport: {w: window.innerWidth, h: window.innerHeight},
        })
        JS
      rect = JSON.parse(rect_json)
      menu_rect = rect["menu"]
      # Click 200px to the right of the menu, halfway down the viewport.
      click_x = menu_rect["right"].as_f + 50.0
      click_y = (rect["viewport"]["h"].as_f / 2.0)
      # If that's off-screen, pick a guaranteed-safe point at (vw - 10, vh/4).
      if click_x > rect["viewport"]["w"].as_f - 5
        click_x = rect["viewport"]["w"].as_f - 5.0
        click_y = rect["viewport"]["h"].as_f / 4.0
      end
      dt.click_at(click_x, click_y)
      sleep 0.1.seconds

      obs_json = dt.evaluate(<<-JS).not_nil!.as_s
        JSON.stringify({
          data_presented: window.__phase4.menuFor('center').getAttribute('data-presented'),
          dismiss_log: window.__phase4DismissLog,
          focus_on_trigger: document.activeElement === window.__phase4.triggerFor('center'),
          active_testid: document.activeElement ? document.activeElement.getAttribute('data-testid') : null,
        })
        JS
      obs = JSON.parse(obs_json)
      passed = obs["data_presented"]?.try(&.as_s?) == "false" &&
               obs["focus_on_trigger"]?.try(&.as_bool?) == true

      record = {
        "check_id" => "focus.context-menu-outside-click-closes",
        "page" => "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
        "selectors" => ["[data-testid=ctx-trigger-center]", ".ap-ctx-menu"],
        "cdp_methods" => ["Runtime.evaluate (open via dispatchEvent)", "Runtime.evaluate (rect capture)", "Input.dispatchMouseEvent (outside click)"],
        "trusted_input_trace" => ["trigger.focus + dispatchEvent('contextmenu')", "mouseDown@(#{click_x},#{click_y})", "mouseUp@(#{click_x},#{click_y})"],
        "expected_state" => {
          "data_presented" => "false",
          "focus_on_trigger" => true,
        },
        "observed_state" => {
          "pre_data_presented" => pre,
          "menu_rect" => menu_rect,
          "click_point" => {"x" => click_x, "y" => click_y},
          "data_presented" => obs["data_presented"],
          "dismiss_log" => obs["dismiss_log"],
          "focus_on_trigger" => obs["focus_on_trigger"],
          "active_testid" => obs["active_testid"],
        },
        "pass" => passed,
        "artifacts" => ["inspections/focus.context-menu-outside-click-closes.json"],
      }
      write_record(inspections_dir, "focus.context-menu-outside-click-closes", record)
      any_failed = true unless passed
    end
  end

  if run?("conformance.context-menu-positioning")
    log "probe: conformance.context-menu-positioning"
    # All three triggers at desktop 1280x800 so each has unambiguous quadrant.
    slugs = ["tl", "center", "br"]
    labels = {"tl" => "top-left", "center" => "center", "br" => "bottom-right"}
    all_pass = true
    slugs.each do |slug|
      with_target(client, PAGES["context_menu"], viewport: {width: 1280, height: 800}) do |dt|
        dt.evaluate("window.__phase4.ensureDismissLog();")
        # Real trusted right-click via Input.dispatchMouseEvent (per toolkit §3.6).
        # Read trigger center via Runtime.evaluate first.
        rect_json = dt.evaluate(<<-JS).not_nil!.as_s
          JSON.stringify(window.__phase4.triggerFor(#{slug.to_json}).getBoundingClientRect())
          JS
        tr = JSON.parse(rect_json)
        cx = tr["left"].as_f + tr["width"].as_f / 2.0
        cy = tr["top"].as_f + tr["height"].as_f / 2.0
        # Quadrant sanity check.
        case slug
        when "tl"
          quadrant_ok = cx <= 16.0 + tr["width"].as_f && cy <= 16.0 + tr["height"].as_f
        when "br"
          quadrant_ok = cx >= 1280.0 - 16.0 - tr["width"].as_f && cy >= 800.0 - 16.0 - tr["height"].as_f
        else
          quadrant_ok = (cx - 640.0).abs <= 32.0 && (cy - 400.0).abs <= 32.0
        end

        # Right-click via real CDP input.
        dt.mouse_press(cx, cy, "right", 1)
        dt.mouse_release(cx, cy, "right", 1)
        # Poll for menu mount.
        20.times do
          val = dt.evaluate("window.__phase4.menuFor(#{slug.to_json}).getAttribute('data-presented')")
          break if val.try(&.as_s?) == "true"
          sleep 0.05.seconds
        end

        info_json = dt.evaluate(<<-JS).not_nil!.as_s
          (function () {
            var t = window.__phase4.triggerFor(#{slug.to_json}).getBoundingClientRect();
            var m = window.__phase4.menuFor(#{slug.to_json}).getBoundingClientRect();
            return JSON.stringify({
              trigger_rect: {left: t.left, top: t.top, right: t.right, bottom: t.bottom, width: t.width, height: t.height},
              menu_rect:    {left: m.left, top: m.top, right: m.right, bottom: m.bottom, width: m.width, height: m.height},
              viewport: {w: window.innerWidth, h: window.innerHeight},
            });
          })()
          JS
        info = JSON.parse(info_json)
        m = info["menu_rect"]
        vp = info["viewport"]
        ml = m["left"].as_f; mt = m["top"].as_f
        mr = m["right"].as_f; mb = m["bottom"].as_f
        vw = vp["w"].as_f; vh = vp["h"].as_f

        on_screen = ml >= -0.5 && mt >= -0.5 && mr <= vw + 0.5 && mb <= vh + 0.5

        # Anchoring: for tl + center, the menu's near corner should be within
        # 16 px of the click point (the fallback positions at clientX/clientY).
        # For br, the menu must be flipped/shifted; the fallback's position()
        # function clamps to `Math.max(0, vw - r.width - 8)` so we assert
        # tight viewport-edge insets plus the flipped-edge geometry
        # (menu.right within 8px of viewport.right; menu.bottom within 8px
        # of viewport.bottom; menu shifted left+up of the click point).
        # Per Codex Checkpoint 3 Family B: explicit predicates required.
        anchored_tolerance = 16.0
        if slug == "br"
          br_right_inset_ok  = (vw - mr).abs <= 8.5
          br_bottom_inset_ok = (vh - mb).abs <= 8.5
          br_left_of_click   = ml < cx
          br_above_click     = mt < cy
          anchored = br_right_inset_ok && br_bottom_inset_ok && br_left_of_click && br_above_click
          extra_predicates = {
            "br_right_inset_ok"  => br_right_inset_ok,
            "br_bottom_inset_ok" => br_bottom_inset_ok,
            "br_left_of_click"   => br_left_of_click,
            "br_above_click"     => br_above_click,
          }
        else
          anchored = (ml - cx).abs <= anchored_tolerance && (mt - cy).abs <= anchored_tolerance
          extra_predicates = {} of String => Bool
        end

        passed = quadrant_ok && on_screen && anchored
        all_pass = false unless passed

        record = {
          "check_id" => "conformance.context-menu-positioning-#{labels[slug]}",
          "page" => "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
          "selectors" => ["[data-testid=ctx-trigger-#{slug}]", ".ap-ctx-menu"],
          "cdp_methods" => ["Emulation.setDeviceMetricsOverride (1280x800)", "Runtime.evaluate (rect capture)", "Input.dispatchMouseEvent (right press/release at trigger center)", "Runtime.evaluate (post-open rect capture)"],
          "trusted_input_trace" => ["read trigger rect", "right-mouseDown@(#{cx.round(1)},#{cy.round(1)})", "right-mouseUp@(#{cx.round(1)},#{cy.round(1)})"],
          "expected_state" => {
            "trigger_in_quadrant" => true,
            "menu_on_screen" => true,
            "menu_anchored_within_tolerance_or_repositioned" => true,
          },
          "observed_state" => {
            "click_point"                       => {"x" => cx, "y" => cy},
            "trigger_rect"                      => info["trigger_rect"],
            "menu_rect"                         => info["menu_rect"],
            "viewport"                          => vp,
            "trigger_in_quadrant"               => quadrant_ok,
            "on_screen"                         => on_screen,
            "anchored_within_tolerance"         => anchored,
            "anchor_tolerance_px"               => slug == "br" ? 8.0 : anchored_tolerance,
            "flipped_edge_predicates"           => extra_predicates,
          },
          "pass" => passed,
          "artifacts" => ["inspections/conformance.context-menu-positioning-#{labels[slug]}.json"],
        }
        write_record(inspections_dir, "conformance.context-menu-positioning-#{labels[slug]}", record)
      end
    end
    any_failed = true unless all_pass
  end

  # ----------------------------------------------------------------
  # Family C — Cross-cutting accessibility (axe + IBM on context-menu page)
  # ----------------------------------------------------------------

  if run?("fallback.context-menu-axe-clean")
    log "probe: fallback.context-menu-axe-clean"
    out = matrix_audit(client, PAGES["context_menu"],
      axe_source: axe_source,
      open_helper: CTX_OPEN_HELPER)
    passed = out[:failures].empty?
    record = {
      "check_id" => "fallback.context-menu-axe-clean",
      "page" => "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
      "selectors" => [".ap-ctx-menu[data-presented=true]"],
      "cdp_methods" => ["Runtime.evaluate (axe-core 4.10.2)", "Runtime.evaluate (axe.run)", "Page.captureScreenshot"],
      "trusted_input_trace" => ["trigger.focus + dispatchEvent('contextmenu') @ center", "axe.run(document)"],
      "expected_state" => {"serious_or_critical_violation_count_total" => 0},
      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
      "pass" => passed,
      "artifacts" => out[:screenshots] + ["audits/fallback.context-menu-axe-clean.json"],
    }
    write_record(audits_dir, "fallback.context-menu-axe-clean", record)
    any_failed = true unless passed
  end

  if run?("fallback.context-menu-ibm-equal-access-clean")
    log "probe: fallback.context-menu-ibm-equal-access-clean"
    out = matrix_audit(client, PAGES["context_menu"],
      ace_source: ace_source,
      open_helper: CTX_OPEN_HELPER)
    passed = out[:failures].empty?
    record = {
      "check_id" => "fallback.context-menu-ibm-equal-access-clean",
      "page" => "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
      "selectors" => [".ap-ctx-menu[data-presented=true]"],
      "cdp_methods" => ["Runtime.evaluate (accessibility-checker-engine 4.0.17)", "Runtime.evaluate (ace.Checker.check)"],
      "trusted_input_trace" => ["trigger.focus + dispatchEvent('contextmenu') @ center", "ace.Checker.check(document, ['IBM_Accessibility'])"],
      "expected_state" => {"ibm_violation_fail_count_total" => 0},
      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
      "pass" => passed,
      "artifacts" => ["audits/fallback.context-menu-ibm-equal-access-clean.json"],
    }
    write_record(audits_dir, "fallback.context-menu-ibm-equal-access-clean", record)
    any_failed = true unless passed
  end

  # Optional but valuable: PathControl page axe / IBM too. Not in the 12-check
  # routing table — provided here for the path-control family's evidence.
  if run?("fallback.path-control-axe-clean")
    log "probe: fallback.path-control-axe-clean (supplementary)"
    out = matrix_audit(client, PAGES["path_control"], axe_source: axe_source)
    write_record(audits_dir, "fallback.path-control-axe-clean", {
      "check_id" => "fallback.path-control-axe-clean",
      "page" => "samples/cross_platform/web/dist/phase04_path_control_demo.html",
      "selectors" => ["nav[aria-label=Breadcrumb]", "ol > li", "[aria-current=page]"],
      "cdp_methods" => ["Runtime.evaluate (axe-core 4.10.2)", "Runtime.evaluate (axe.run)"],
      "trusted_input_trace" => ["Page.navigate (file://)", "axe.run(document)"],
      "expected_state" => {"serious_or_critical_violation_count_total" => 0},
      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
      "pass" => out[:failures].empty?,
      "artifacts" => out[:screenshots] + ["audits/fallback.path-control-axe-clean.json"],
    })
  end

  if run?("fallback.path-control-ibm-equal-access-clean")
    log "probe: fallback.path-control-ibm-equal-access-clean (supplementary)"
    out = matrix_audit(client, PAGES["path_control"], ace_source: ace_source)
    write_record(audits_dir, "fallback.path-control-ibm-equal-access-clean", {
      "check_id" => "fallback.path-control-ibm-equal-access-clean",
      "page" => "samples/cross_platform/web/dist/phase04_path_control_demo.html",
      "selectors" => ["nav[aria-label=Breadcrumb]"],
      "cdp_methods" => ["Runtime.evaluate (accessibility-checker-engine 4.0.17)", "Runtime.evaluate (ace.Checker.check)"],
      "trusted_input_trace" => ["Page.navigate (file://)", "ace.Checker.check(document)"],
      "expected_state" => {"ibm_violation_fail_count_total" => 0},
      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
      "pass" => out[:failures].empty?,
      "artifacts" => ["audits/fallback.path-control-ibm-equal-access-clean.json"],
    })
  end

  log "DONE. any_failed=#{any_failed}"
  exit(any_failed ? 2 : 0)
ensure
  log "shutting down chrome"
  process.terminate rescue nil
  process.wait rescue nil
  FileUtils.rm_rf(profile_dir)
end
