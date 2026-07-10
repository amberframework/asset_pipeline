require "base64"
require "file_utils"
require "http/client"
require "http/web_socket"
require "json"
require "uri"

ROOT                = File.expand_path("..", __DIR__)
ARTIFACT_DIR        = File.join(ROOT, "test-results/web-design-system")
LEGACY_ARTIFACT_DIR = File.join(ROOT, "test-results/amber-design-system")
REPORT_FILE         = File.join(ARTIFACT_DIR, "browser-audit.json")
CONTRAST_FILE       = File.join(ARTIFACT_DIR, "contrast-report.json")
CONTRAST_CSV        = File.join(ARTIFACT_DIR, "contrast-report.csv")
REDUCED_MOTION_FILE = File.join(ARTIFACT_DIR, "reduced-motion-report.json")
KEYBOARD_FILE       = File.join(ARTIFACT_DIR, "keyboard-traversal.json")
TOUCH_TARGET_FILE   = File.join(ARTIFACT_DIR, "touch-targets.json")
AX_TREE_FILE        = File.join(ARTIFACT_DIR, "accessibility-tree-report.json")
PAGES               = {
  "overview"      => File.join(ROOT, "output/web-design-system-demo.html"),
  "pricing"       => File.join(ROOT, "output/web-design-system-pricing.html"),
  "forms"         => File.join(ROOT, "output/web-design-system-forms.html"),
  "dashboard"     => File.join(ROOT, "output/web-design-system-dashboard.html"),
  "timeline"      => File.join(ROOT, "output/web-design-system-timeline.html"),
  "collaboration" => File.join(ROOT, "output/web-design-system-collaboration.html"),
  "patterns"      => File.join(ROOT, "output/web-design-system-patterns.html"),
}

CHROME_CANDIDATES = [
  ENV["CHROME_BIN"]?,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  Process.find_executable("google-chrome"),
  Process.find_executable("chromium"),
  Process.find_executable("chrome"),
].compact

class DevTools
  @id = 0

  def initialize(websocket_url : String)
    @messages = Channel(JSON::Any).new(128)
    @ws = HTTP::WebSocket.new(URI.parse(websocket_url))
    @ws.on_message do |message|
      @messages.send(JSON.parse(message))
    end
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
        io << %Q(,"params":)
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
end

def fail!(message : String) : NoReturn
  STDERR.puts message
  exit 1
end

def write_screenshot(devtools : DevTools, artifact_dir : String, name : String)
  screenshot = devtools.call("Page.captureScreenshot", %({"format":"png","captureBeyondViewport":true}))
  encoded = screenshot["result"]["data"].as_s
  File.write(File.join(artifact_dir, "#{name}.png"), Base64.decode(encoded))
end

def json_number_to_f(value : JSON::Any) : Float64
  value.as_f? || value.as_i.to_f
end

def dispatch_tab(devtools : DevTools, shift : Bool = false)
  modifiers = shift ? 8 : 0
  devtools.call("Input.dispatchKeyEvent", %({"type":"keyDown","key":"Tab","code":"Tab","windowsVirtualKeyCode":9,"nativeVirtualKeyCode":9,"modifiers":#{modifiers}}))
  devtools.call("Input.dispatchKeyEvent", %({"type":"keyUp","key":"Tab","code":"Tab","windowsVirtualKeyCode":9,"nativeVirtualKeyCode":9,"modifiers":#{modifiers}}))
end

def ax_value(node : JSON::Any, key : String) : String
  node[key]?.try(&.["value"]?.try(&.as_s?)) || ""
end

def ax_property(node : JSON::Any, name : String) : String?
  properties = node["properties"]?.try(&.as_a?) || [] of JSON::Any
  property = properties.find { |item| item["name"]?.try(&.as_s?) == name }
  property.try(&.["value"]?.try(&.["value"]?.try(&.to_s)))
end

chrome = CHROME_CANDIDATES.find { |path| File::Info.executable?(path) }
fail!("No Chrome/Chromium binary found. Set CHROME_BIN to enable browser screenshot validation.") unless chrome

port = 9400 + Random.rand(400)
profile_dir = File.tempname("amber-demo-chrome")
FileUtils.mkdir_p(profile_dir)
FileUtils.mkdir_p(ARTIFACT_DIR)
Dir.glob(File.join(ARTIFACT_DIR, "*.png")).each { |path| File.delete(path) }

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
  error: Process::Redirect::Close
)

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
  fail!("Chrome did not expose a DevTools endpoint on port #{port}.") unless ready

  cases = [
    {name: "desktop-light", page: "overview", width: 1440, height: 1100, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "desktop-dark", page: "overview", width: 1440, height: 1100, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "mobile-light", page: "overview", width: 390, height: 1250, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "mobile-dark", page: "overview", width: 390, height: 1250, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "pricing-desktop-light", page: "pricing", width: 1440, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "pricing-desktop-dark", page: "pricing", width: 1440, height: 1200, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "pricing-mobile-light", page: "pricing", width: 390, height: 1400, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "pricing-mobile-dark", page: "pricing", width: 390, height: 1400, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "forms-desktop-light", page: "forms", width: 1440, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "forms-desktop-dark", page: "forms", width: 1440, height: 1200, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "forms-mobile-light", page: "forms", width: 390, height: 1400, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "forms-mobile-dark", page: "forms", width: 390, height: 1400, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "dashboard-desktop-light", page: "dashboard", width: 1440, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "dashboard-desktop-dark", page: "dashboard", width: 1440, height: 1200, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "dashboard-mobile-light", page: "dashboard", width: 390, height: 1450, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "dashboard-mobile-dark", page: "dashboard", width: 390, height: 1450, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "timeline-desktop-light", page: "timeline", width: 1440, height: 1300, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "timeline-desktop-dark", page: "timeline", width: 1440, height: 1300, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "timeline-mobile-light", page: "timeline", width: 390, height: 1450, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "timeline-mobile-dark", page: "timeline", width: 390, height: 1450, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "collaboration-desktop-light", page: "collaboration", width: 1440, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "collaboration-desktop-dark", page: "collaboration", width: 1440, height: 1200, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "collaboration-mobile-light", page: "collaboration", width: 390, height: 1450, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "collaboration-mobile-dark", page: "collaboration", width: 390, height: 1450, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "patterns-desktop-light", page: "patterns", width: 1440, height: 1300, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "patterns-desktop-dark", page: "patterns", width: 1440, height: 1300, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "patterns-mobile-light", page: "patterns", width: 390, height: 1450, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false},
    {name: "patterns-mobile-dark", page: "patterns", width: 390, height: 1450, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false},
    {name: "overview-reduced-motion", page: "overview", width: 1440, height: 1000, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
    {name: "pricing-reduced-motion", page: "pricing", width: 1440, height: 1100, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
    {name: "forms-reduced-motion", page: "forms", width: 1440, height: 1100, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
    {name: "dashboard-command-reduced-motion", page: "dashboard", width: 1440, height: 1100, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
    {name: "timeline-reduced-motion", page: "timeline", width: 1440, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
    {name: "collaboration-reduced-motion", page: "collaboration", width: 1440, height: 1100, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
    {name: "patterns-reduced-motion", page: "patterns", width: 1440, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
    {name: "patterns-dialog-reduced-motion", page: "patterns", width: 1440, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: true},
  ]
  PAGES.keys.each do |page|
    cases << {name: "#{page}-reflow-320-light", page: page, width: 320, height: 1800, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false}
    cases << {name: "#{page}-reflow-320-dark", page: page, width: 320, height: 1800, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false}
    # Phase 2 cross-platform UI initiative pinned viewport set:
    # 1280x800, 768x1024, 375x667 (in addition to the 320 reflow above)
    # in both light and dark to validate fluid resize at every anchor.
    cases << {name: "#{page}-reflow-375-light", page: page, width: 375, height: 1600, mobile: true, color_scheme: "light", theme: "light", reduce_motion: false}
    cases << {name: "#{page}-reflow-375-dark", page: page, width: 375, height: 1600, mobile: true, color_scheme: "dark", theme: "dark", reduce_motion: false}
    cases << {name: "#{page}-reflow-768-light", page: page, width: 768, height: 1400, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false}
    cases << {name: "#{page}-reflow-768-dark", page: page, width: 768, height: 1400, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false}
    cases << {name: "#{page}-reflow-1280-light", page: page, width: 1280, height: 1200, mobile: false, color_scheme: "light", theme: "light", reduce_motion: false}
    cases << {name: "#{page}-reflow-1280-dark", page: page, width: 1280, height: 1200, mobile: false, color_scheme: "dark", theme: "dark", reduce_motion: false}
  end

  failures = [] of String
  evidence = [] of Hash(String, JSON::Any)
  contrast_evidence = [] of Hash(String, JSON::Any)
  reduced_motion_evidence = [] of Hash(String, JSON::Any)
  keyboard_evidence = [] of Hash(String, JSON::Any)
  touch_target_evidence = [] of Hash(String, JSON::Any)
  ax_tree_evidence = [] of Hash(String, JSON::Any)

  cases.each do |item|
    page_path = PAGES[item[:page]]
    target_response = client.exec("PUT", "/json/new?about:blank")
    fail!("Unable to create Chrome target: #{target_response.status_code} #{target_response.body}") unless target_response.status.success?

    websocket_url = JSON.parse(target_response.body)["webSocketDebuggerUrl"].as_s
    devtools = DevTools.new(websocket_url)

    begin
      devtools.call("Page.enable")
      devtools.call("Runtime.enable")
      devtools.call("Accessibility.enable")
      devtools.call(
        "Emulation.setDeviceMetricsOverride",
        %({"width":#{item[:width]},"height":#{item[:height]},"deviceScaleFactor":1,"mobile":#{item[:mobile]}})
      )
      motion_feature = item[:reduce_motion] ? %Q(,{"name":"prefers-reduced-motion","value":"reduce"}) : ""
      devtools.call(
        "Emulation.setEmulatedMedia",
        %({"features":[{"name":"prefers-color-scheme","value":#{item[:color_scheme].to_json}}#{motion_feature}]})
      )
      devtools.call("Page.navigate", %({"url":#{"file://#{page_path}".to_json}}))

      50.times do
        ready_state = devtools.evaluate("document.readyState").try(&.as_s?)
        break if ready_state == "complete"
        sleep 0.1.seconds
      end
      sleep 0.15.seconds

      common_result = devtools.evaluate(<<-JS).not_nil!
        (() => {
          const failures = [];
          const visible = (el) => {
            if (!el) return false;
            const rect = el.getBoundingClientRect();
            return rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.right > 0 && rect.left < innerWidth;
          };
          const focusOk = (selector) => {
            const el = document.querySelector(selector);
            if (!el) return `missing ${selector}`;
            el.focus();
            const styles = getComputedStyle(el);
            if (!visible(el)) return `focus target ${selector} is not visible`;
            const authoredFocusRule = Array.from(document.styleSheets).some((sheet) => {
              try {
                return Array.from(sheet.cssRules).some((rule) => rule.cssText?.includes(".am-button:focus") && (rule.cssText.includes("outline") || rule.cssText.includes("box-shadow")));
              } catch {
                return false;
              }
            });
            if (document.activeElement !== el) return `focus target ${selector} did not receive focus`;
            if (styles.outlineStyle === "none" && styles.boxShadow === "none" && !authoredFocusRule) return `focus target ${selector} has no visible focus style`;
            return "";
          };

          const beforeTheme = {
            theme: document.documentElement.dataset.apTheme || "",
            scheme: getComputedStyle(document.documentElement).colorScheme,
            canvas: getComputedStyle(document.documentElement).getPropertyValue("--amber-color-surface-canvas").trim(),
            text: getComputedStyle(document.documentElement).getPropertyValue("--amber-color-text-primary").trim()
          };
          AssetPipelineDesignSystem.setTheme("dark", false);
          const darkTheme = {
            theme: document.documentElement.dataset.apTheme || "",
            scheme: getComputedStyle(document.documentElement).colorScheme,
            canvas: getComputedStyle(document.documentElement).getPropertyValue("--amber-color-surface-canvas").trim(),
            text: getComputedStyle(document.documentElement).getPropertyValue("--amber-color-text-primary").trim()
          };
          AssetPipelineDesignSystem.setTheme("light", false);
          const lightTheme = {
            theme: document.documentElement.dataset.apTheme || "",
            scheme: getComputedStyle(document.documentElement).colorScheme,
            canvas: getComputedStyle(document.documentElement).getPropertyValue("--amber-color-surface-canvas").trim(),
            text: getComputedStyle(document.documentElement).getPropertyValue("--amber-color-text-primary").trim()
          };
          if (darkTheme.theme !== "dark" || lightTheme.theme !== "light") failures.push("theme API did not set root data attribute");
          if (!darkTheme.scheme.includes("dark") || !lightTheme.scheme.includes("light")) failures.push(`color-scheme did not change: ${darkTheme.scheme}/${lightTheme.scheme}`);
          if (darkTheme.canvas === lightTheme.canvas || darkTheme.text === lightTheme.text) failures.push("theme CSS variables did not change");
          AssetPipelineDesignSystem.setTheme("#{item[:theme]}", false);

          const focusFailure = focusOk("[data-ap-theme-toggle]");
          if (focusFailure) failures.push(focusFailure);

          const unnamed = Array.from(document.querySelectorAll("button, a[href], input, select, textarea, [role='dialog'], dialog"))
            .filter((el) => !el.closest("[hidden], dialog:not([open])"))
            .filter((el) => !((el.getAttribute("aria-label") || el.getAttribute("aria-labelledby") || el.textContent || el.labels?.[0]?.textContent || "").trim()))
            .map((el) => el.outerHTML.slice(0, 90));
          if (unnamed.length) failures.push(`unnamed controls: ${unnamed.join(" | ")}`);

          const clipped = Array.from(document.querySelectorAll("button, a[href], input, select, textarea, .am-panel, .am-card, .am-table-wrap, .am-chart, .am-hero-showcase, .am-page-card, .am-price-card, .am-command-panel, .am-chat-panel, .am-timeline-card"))
            .filter((el) => !el.closest("dialog:not([open]), [hidden]"))
            .filter((el) => !el.classList.contains("am-skip-link"))
            .filter((el) => !el.closest(".am-command-panel:not([data-state='open'])"))
            .filter((el) => getComputedStyle(el).display !== "none" && getComputedStyle(el).visibility !== "hidden")
            .filter((el) => {
              const rect = el.getBoundingClientRect();
              return rect.width <= 0 || rect.height <= 0 || rect.right < 0 || rect.bottom < 0 || rect.left > innerWidth;
            })
            .map((el) => el.className || el.tagName);
          const internallyOverflowing = Array.from(document.querySelectorAll(".am-panel, .am-table-wrap, .am-chart, .am-hero-showcase, .am-page-card, .am-price-card, .am-chat-panel"))
            .filter((el) => !el.closest("dialog:not([open]), [hidden]"))
            .filter((el) => el.scrollWidth > el.clientWidth + 1)
            .map((el) => el.className || el.tagName);
          const samples = Array.from(document.querySelectorAll(".am-demo-copy, .am-field label, .am-field__error, .am-button, .am-badge, .am-input"))
            .slice(0, 24)
            .filter((el) => {
              const styles = getComputedStyle(el);
              return styles.color === "rgba(0, 0, 0, 0)" || styles.color === "transparent";
            })
            .map((el) => el.className || el.tagName);

          const parseColor = (value) => {
            if (!value || value === "transparent") return null;
            const rgb = value.match(/rgba?\\(([^)]+)\\)/i);
            if (rgb) {
              const parts = rgb[1].split(/[\\s,\\/]+/).filter(Boolean).map(Number);
              return { r: parts[0] / 255, g: parts[1] / 255, b: parts[2] / 255, a: Number.isFinite(parts[3]) ? parts[3] : 1 };
            }
            const hex = value.match(/^#([0-9a-f]{6})$/i);
            if (hex) {
              const n = Number.parseInt(hex[1], 16);
              return { r: ((n >> 16) & 255) / 255, g: ((n >> 8) & 255) / 255, b: (n & 255) / 255, a: 1 };
            }
            const oklch = value.match(/oklch\\(([^)]+)\\)/i);
            if (oklch) {
              const raw = oklch[1].replace(/deg/g, "").split(/[\\s\\/]+/).filter(Boolean);
              let l = raw[0].includes("%") ? Number.parseFloat(raw[0]) / 100 : Number.parseFloat(raw[0]);
              const c = Number.parseFloat(raw[1]);
              const h = Number.parseFloat(raw[2]) * Math.PI / 180;
              const alpha = raw[3] ? Number.parseFloat(raw[3]) : 1;
              const a = c * Math.cos(h);
              const b = c * Math.sin(h);
              const l1 = l + 0.3963377774 * a + 0.2158037573 * b;
              const m1 = l - 0.1055613458 * a - 0.0638541728 * b;
              const s1 = l - 0.0894841775 * a - 1.2914855480 * b;
              const l3 = l1 ** 3;
              const m3 = m1 ** 3;
              const s3 = s1 ** 3;
              const linear = [
                4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3,
                -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3,
                -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3,
              ];
              const gamma = (v) => {
                const clipped = Math.min(1, Math.max(0, v));
                return clipped <= 0.0031308 ? 12.92 * clipped : 1.055 * (clipped ** (1 / 2.4)) - 0.055;
              };
              return { r: gamma(linear[0]), g: gamma(linear[1]), b: gamma(linear[2]), a: alpha };
            }
            return null;
          };
          const luminance = (c) => {
            const convert = (v) => v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
            return 0.2126 * convert(c.r) + 0.7152 * convert(c.g) + 0.0722 * convert(c.b);
          };
          const ratio = (fg, bg) => {
            const l1 = luminance(fg);
            const l2 = luminance(bg);
            return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
          };
          const backgroundFor = (el) => {
            let node = el;
            while (node) {
              const color = parseColor(getComputedStyle(node).backgroundColor);
              if (color && color.a > 0.98) return color;
              node = node.parentElement;
            }
            return document.documentElement.dataset.apTheme === "dark"
              ? parseColor("rgb(20, 18, 15)")
              : parseColor("rgb(255, 251, 245)");
          };
          const contrastSamples = [];
          [
            [".am-button--solid", 3, "solid-button"],
            [".am-input, .am-select, .am-textarea", 4.5, "field"],
            [".am-badge", 3, "badge"],
            [".am-alert", 4.5, "alert"],
            [".am-table td", 4.5, "table-cell"],
            [".am-chart__summary", 4.5, "chart-summary"],
            [".am-form-status", 4.5, "form-status"],
            [".am-tab-panel", 4.5, "tab-panel"],
            [".am-command-item", 4.5, "command-item"],
          ].forEach(([selector, minimum, label]) => {
            Array.from(document.querySelectorAll(selector)).slice(0, 6).forEach((el) => {
              if (el.closest("[hidden], dialog:not([open]), .am-command-panel:not([data-state='open'])")) return;
              const fg = parseColor(getComputedStyle(el).color);
              const bg = backgroundFor(el);
              if (!fg || !bg) return;
              const value = ratio(fg, bg);
              contrastSamples.push({ label, ratio: Math.round(value * 100) / 100, minimum });
              if (value < minimum) failures.push(`contrast ${label} ${value.toFixed(2)} below ${minimum}`);
            });
          });
          if (contrastSamples.length < 4) failures.push(`contrast sweep produced too few samples: ${contrastSamples.length}`);

          const interactiveSelector = "a[href], button, input, select, textarea, summary, [tabindex]:not([tabindex='-1'])";
          const accessibleName = (el) => (
            el.getAttribute("aria-label") ||
            (el.getAttribute("aria-labelledby") || "").split(/\\s+/).map((id) => document.getElementById(id)?.textContent || "").join(" ") ||
            el.labels?.[0]?.textContent ||
            el.textContent ||
            el.getAttribute("title") ||
            el.getAttribute("name") ||
            ""
          ).trim().replace(/\\s+/g, " ");
          const interactives = Array.from(document.querySelectorAll(interactiveSelector))
            .filter((el) => !el.closest("[hidden], dialog:not([open]), .am-command-panel:not([data-state='open'])"))
            .filter((el) => el.tabIndex >= 0)
            .filter((el) => {
              const styles = getComputedStyle(el);
              const rect = el.getBoundingClientRect();
              return styles.display !== "none" && styles.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
            });
          const focusOrder = interactives.map((el, index) => ({
            index,
            selector: el.id ? `#${el.id}` : `${el.tagName.toLowerCase()}${el.className ? "." + String(el.className).trim().split(/\\s+/).join(".") : ""}`,
            name: accessibleName(el),
            tag: el.tagName.toLowerCase()
          }));
          const positiveTabindex = interactives.filter((el) => Number(el.getAttribute("tabindex") || 0) > 0).map((el) => el.outerHTML.slice(0, 120));
          if (positiveTabindex.length) failures.push(`positive tabindex found: ${positiveTabindex.join(" | ")}`);
          const touchTargets = interactives.map((el) => {
            const target = (["checkbox", "radio"].includes(el.type) && el.closest("label")) ? el.closest("label") : el;
            const rect = target.getBoundingClientRect();
            return {
              selector: el.id ? `#${el.id}` : `${el.tagName.toLowerCase()}${el.className ? "." + String(el.className).trim().split(/\\s+/).join(".") : ""}`,
              name: accessibleName(el),
              width: Math.round(rect.width * 100) / 100,
              height: Math.round(rect.height * 100) / 100
            };
          });
          const smallTargets = touchTargets.filter((target) => target.width < 24 || target.height < 24);
          if (smallTargets.length) failures.push(`touch targets below 24px: ${smallTargets.slice(0, 8).map((target) => `${target.selector} ${target.width}x${target.height}`).join(" | ")}`);

          if (clipped.length) failures.push(`clipped elements: ${clipped.join(", ")}`);
          if (internallyOverflowing.length) failures.push(`internally overflowing: ${internallyOverflowing.join(", ")}`);
          if (document.documentElement.scrollWidth > innerWidth + 1) failures.push(`horizontal overflow ${document.documentElement.scrollWidth}/${innerWidth}`);
          if (document.querySelector(".btn, .btn-primary, .card-body, .form-control")) failures.push("bootstrap-shaped canonical class found");
          if (samples.length) failures.push(`transparent text samples: ${samples.join(", ")}`);

          return {
            failures,
            beforeTheme,
            darkTheme,
            lightTheme,
            contrastSamples,
            focusOrder,
            touchTargets,
            smallTargets,
            height: Math.ceil(document.documentElement.scrollHeight),
            width: document.documentElement.scrollWidth
          };
        })()
        JS
      common_result["failures"].as_a.each { |failure| failures << "#{item[:name]} common audit failed: #{failure.as_s}" }
      common_result["contrastSamples"].as_a.each do |sample|
        contrast_evidence << {
          "case"    => JSON::Any.new(item[:name]),
          "page"    => JSON::Any.new(item[:page]),
          "theme"   => JSON::Any.new(item[:theme]),
          "label"   => JSON::Any.new(sample["label"].as_s),
          "ratio"   => JSON::Any.new(json_number_to_f(sample["ratio"])),
          "minimum" => JSON::Any.new(json_number_to_f(sample["minimum"])),
        }
      end
      keyboard_evidence << {
        "case"        => JSON::Any.new(item[:name]),
        "page"        => JSON::Any.new(item[:page]),
        "theme"       => JSON::Any.new(item[:theme]),
        "focus_order" => common_result["focusOrder"],
      }

      if !item[:reduce_motion]
        expected_order = common_result["focusOrder"].as_a
        if expected_order.any?
          devtools.evaluate("document.body.setAttribute('tabindex', '-1'); document.body.focus();")
          observed = [] of JSON::Any
          (expected_order.size + 10).times do
            dispatch_tab(devtools)
            step = devtools.evaluate(<<-JS).not_nil!
              (() => {
                const el = document.activeElement;
                const name = (
                  el.getAttribute("aria-label") ||
                  (el.getAttribute("aria-labelledby") || "").split(/\\s+/).map((id) => document.getElementById(id)?.textContent || "").join(" ") ||
                  el.labels?.[0]?.textContent ||
                  el.textContent ||
                  el.getAttribute("title") ||
                  el.getAttribute("name") ||
                  ""
                ).trim().replace(/\\s+/g, " ");
                return {
                  selector: el.id ? `#${el.id}` : `${el.tagName.toLowerCase()}${el.className ? "." + String(el.className).trim().split(/\\s+/).join(".") : ""}`,
                  name,
                  tag: el.tagName.toLowerCase()
                };
              })()
              JS
            observed << step
          end

          mismatches = [] of String
          observed_index = 0
          expected_order.each_with_index do |expected, index|
            expected_tag = expected["tag"].as_s
            expected_name = expected["name"].as_s
            found = false
            while actual = observed[observed_index]?
              actual_tag = actual["tag"].as_s
              actual_name = actual["name"].as_s
              observed_index += 1
              if expected_tag == actual_tag && expected_name == actual_name
                found = true
                break
              end
            end
            unless found
              mismatches << "expected #{expected_tag} #{expected_name.inspect} was not reached in order"
            end
          end
          if mismatches.any?
            failures << "#{item[:name]} synthetic tab traversal mismatched: #{mismatches.first(5).join(" | ")}"
          end
          keyboard_evidence[-1]["synthetic_tab_order"] = JSON::Any.new(observed)
          keyboard_evidence[-1]["synthetic_tab_passed"] = JSON::Any.new(mismatches.empty?)
        end
      end
      touch_target_evidence << {
        "case"          => JSON::Any.new(item[:name]),
        "page"          => JSON::Any.new(item[:page]),
        "theme"         => JSON::Any.new(item[:theme]),
        "targets"       => common_result["touchTargets"],
        "small_targets" => common_result["smallTargets"],
      }

      if item[:reduce_motion]
        reduced_result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            if (!AssetPipelineDesignSystem.prefersReducedMotion()) failures.push("prefersReducedMotion returned false");
            const hover = document.querySelector("[data-ap-sticky-hover]");
            hover?.dispatchEvent(new PointerEvent("pointermove", { bubbles: true, clientX: 120, clientY: 120 }));
            if (hover?.style.transform) failures.push(`sticky hover set transform under reduced motion: ${hover.style.transform}`);
            const revealItems = Array.from(document.querySelectorAll("[data-ap-reveal]"));
            const hiddenReveal = revealItems.filter((item) => item.dataset.visible !== "true");
            if (hiddenReveal.length) failures.push(`${hiddenReveal.length} reveal items stayed hidden under reduced motion`);
            const sequencedSvg = Array.from(document.querySelectorAll("[data-svg-part]")).filter((part) => part.dataset.amberSequenced === "true");
            if (sequencedSvg.length) failures.push(`${sequencedSvg.length} svg parts sequenced under reduced motion`);
            const surfaces = [
              { name: "sticky-hover", selector: "[data-ap-sticky-hover]", count: document.querySelectorAll("[data-ap-sticky-hover]").length, expectation: "no inline transform on pointer move" },
              { name: "timeline-reveal", selector: "[data-ap-reveal]", count: revealItems.length, expectation: "all reveal items become visible immediately" },
              { name: "svg-sequence", selector: "[data-svg-part]", count: document.querySelectorAll("[data-svg-part]").length, expectation: "no sequenced animation markers" },
              { name: "chart-bars", selector: ".am-chart__bar", count: document.querySelectorAll(".am-chart__bar").length, expectation: "computed animation duration <= 10ms" },
              { name: "table-rows", selector: "[data-motion='row']", count: document.querySelectorAll("[data-motion='row']").length, expectation: "computed animation duration <= 10ms" },
              { name: "carousel", selector: "[data-ap-carousel]", count: document.querySelectorAll("[data-ap-carousel]").length, expectation: "keyboard/button state changes without animation requirement" },
              { name: "dialog", selector: "dialog.am-dialog", count: document.querySelectorAll("dialog.am-dialog").length, expectation: "open/close behavior works with no transition dependency" },
              { name: "tabs", selector: "[data-ap-tabs]", count: document.querySelectorAll("[data-ap-tabs]").length, expectation: "selection state changes with no transition dependency" },
              { name: "theme-switcher", selector: "[data-ap-theme-toggle], [data-ap-theme-set]", count: document.querySelectorAll("[data-ap-theme-toggle], [data-ap-theme-set]").length, expectation: "theme state changes with no motion dependency" },
              { name: "forms", selector: "form[data-ap-validate]", count: document.querySelectorAll("form[data-ap-validate]").length, expectation: "validation state changes with no motion dependency" },
            ].filter((surface) => surface.count > 0);
            const toMs = (value) => value.split(",").map((part) => {
              const trimmed = part.trim();
              if (trimmed.endsWith("ms")) return Number.parseFloat(trimmed);
              if (trimmed.endsWith("s")) return Number.parseFloat(trimmed) * 1000;
              return Number.parseFloat(trimmed) || 0;
            });
            const offenders = Array.from(document.querySelectorAll("*")).filter((el) => {
              const styles = getComputedStyle(el);
              const durations = [...toMs(styles.transitionDuration), ...toMs(styles.animationDuration)];
              return Math.max(...durations) > 10;
            }).slice(0, 12).map((el) => ({
              selector: el.id ? `#${el.id}` : `${el.tagName.toLowerCase()}${el.className ? "." + String(el.className).trim().split(/\\s+/).join(".") : ""}`,
              transitionDuration: getComputedStyle(el).transitionDuration,
              animationDuration: getComputedStyle(el).animationDuration
            }));
            if (offenders.length) failures.push(`${offenders.length} elements kept motion durations above 10ms under reduced motion`);
            return { failures, offenders, surfaces };
          })()
          JS
        reduced_result["failures"].as_a.each { |failure| failures << "#{item[:name]} reduced motion failed: #{failure.as_s}" }
        reduced_motion_evidence << {
          "case"      => JSON::Any.new(item[:name]),
          "page"      => JSON::Any.new(item[:page]),
          "theme"     => JSON::Any.new(item[:theme]),
          "surfaces"  => reduced_result["surfaces"],
          "offenders" => reduced_result["offenders"],
          "passed"    => JSON::Any.new(reduced_result["failures"].as_a.empty?),
        }
      end

      case item[:page]
      when "pricing"
        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const input = (el, value) => {
              el.value = value;
              el.dispatchEvent(new Event("input", { bubbles: true }));
            };
            const seats = document.querySelector("[data-ap-pricing-seats]");
            input(seats, "20");
            if (!document.querySelector("[data-ap-pricing-seats-label]")?.textContent.includes("20")) failures.push("seat label did not update");
            document.querySelector("[data-billing='monthly']")?.click();
            const total = document.querySelector("[data-ap-pricing-total]")?.textContent || "";
            if (!total.includes("$2,160")) failures.push(`monthly total unexpected: ${total}`);
            const form = document.querySelector("[data-ap-payment-form]");
            form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            if (form.querySelectorAll("[aria-invalid='true']").length < 5) failures.push("invalid payment fields were not marked");
            form.querySelectorAll("[aria-invalid='true']").forEach((field) => {
              const described = (field.getAttribute("aria-describedby") || "").split(/\\s+/).filter(Boolean);
              if (!described.some((id) => document.getElementById(id)?.classList.contains("am-field__error"))) {
                failures.push(`${field.id || field.name} missing described visible error`);
              }
            });
            return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} pricing invalid flow failed: #{failure.as_s}" }

        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const input = (el, value) => {
              el.value = value;
              el.dispatchEvent(new Event("input", { bubbles: true }));
            };
            const form = document.querySelector("[data-ap-payment-form]");
            input(form.querySelector("#card-name"), "Mina Park");
            input(form.querySelector("#card-email"), "mina@example.com");
            input(form.querySelector("#card-number"), "4242424242424241");
            input(form.querySelector("#card-expiry"), "0124");
            input(form.querySelector("#card-cvc"), "123");
            form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            const numberError = document.querySelector("#card-number-error")?.textContent || "";
            const expiryError = document.querySelector("#card-expiry-error")?.textContent || "";
            if (!numberError.includes("valid card number")) failures.push(`luhn error missing: ${numberError}`);
            if (!expiryError.includes("future expiry")) failures.push(`expiry error missing: ${expiryError}`);
            return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} payment helper validation failed: #{failure.as_s}" }

        if item[:name] == "pricing-desktop-light"
          write_screenshot(devtools, ARTIFACT_DIR, "pricing-invalid-state")
          evidence << {
            "name"   => JSON::Any.new("pricing-invalid-state"),
            "page"   => JSON::Any.new("pricing"),
            "width"  => JSON::Any.new(item[:width].to_i64),
            "height" => JSON::Any.new(item[:height].to_i64),
            "theme"  => JSON::Any.new(item[:theme]),
          }
        end

        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const input = (el, value) => {
              el.value = value;
              el.dispatchEvent(new Event("input", { bubbles: true }));
            };
            const form = document.querySelector("[data-ap-payment-form]");
            input(form.querySelector("#card-name"), "Mina Park");
            input(form.querySelector("#card-email"), "mina@example.com");
            input(form.querySelector("#card-number"), "4242424242424242");
            input(form.querySelector("#card-expiry"), "0929");
            input(form.querySelector("#card-cvc"), "123");
            input(form.querySelector("#promo-code"), "AP10");
            form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            if (form.querySelector("[data-ap-form-status]")?.dataset.state !== "success") failures.push("payment form did not reach success");
            if (!document.querySelector("[data-ap-promo-status]")?.textContent.includes("accepted")) failures.push("promo status did not update");
            return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} pricing success flow failed: #{failure.as_s}" }
      when "forms"
        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const input = (el, value) => {
              el.value = value;
              el.dispatchEvent(new Event("input", { bubbles: true }));
            };
            const form = document.querySelector("[data-ap-auth-form]");
            const email = form.querySelector("input[type='email']");
            input(email, "not-an-email");
            if (email.checkValidity()) failures.push("invalid email passed browser validity");
            form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            if (form.querySelector("[data-ap-form-status]")?.dataset.state !== "error") failures.push("auth form did not enter error state");
            form.querySelectorAll("[aria-invalid='true']").forEach((field) => {
              const described = (field.getAttribute("aria-describedby") || "").split(/\\s+/).filter(Boolean);
              if (!described.some((id) => document.getElementById(id)?.classList.contains("am-field__error"))) {
                failures.push(`${field.id || field.name} missing described visible error`);
              }
            });
            return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} form invalid flow failed: #{failure.as_s}" }

        if item[:name] == "forms-desktop-light"
          write_screenshot(devtools, ARTIFACT_DIR, "forms-invalid-state")
          evidence << {
            "name"   => JSON::Any.new("forms-invalid-state"),
            "page"   => JSON::Any.new("forms"),
            "width"  => JSON::Any.new(item[:width].to_i64),
            "height" => JSON::Any.new(item[:height].to_i64),
            "theme"  => JSON::Any.new(item[:theme]),
          }
        end

        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const input = (el, value) => {
              el.value = value;
              el.dispatchEvent(new Event("input", { bubbles: true }));
            };
            const form = document.querySelector("[data-ap-auth-form]");
            const email = form.querySelector("input[type='email']");
            input(form.querySelector("#signup-name"), "Mina Park");
            input(email, "mina@example.com");
            input(form.querySelector("#signup-password"), "ValidPass1!");
            input(form.querySelector("#signup-confirm"), "Mismatch1!");
            form.querySelector("input[name='terms']").checked = true;
            form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            if (!form.querySelector("#signup-confirm")?.getAttribute("aria-invalid")) failures.push("password mismatch was not marked invalid");
            if (!form.querySelector("#signup-confirm")?.getAttribute("aria-describedby")) failures.push("password mismatch did not describe error text");
            input(form.querySelector("#signup-confirm"), "ValidPass1!");
            form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            if (form.querySelector("[data-ap-form-status]")?.dataset.state !== "success") failures.push("auth form did not reach success");
            return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} form success flow failed: #{failure.as_s}" }
      when "dashboard"
        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const filter = document.querySelector("[data-ap-filter]");
            filter.value = "blocked";
            filter.dispatchEvent(new Event("input", { bubbles: true }));
            const status = document.querySelector("#launch-filter-status")?.textContent || "";
            if (!status.includes("1 matching row")) failures.push(`filter status was ${status}`);
            const opener = document.querySelector("[data-ap-command-open]");
            opener.click();
            const panel = document.querySelector("[data-ap-command-panel]");
            return new Promise((resolve) => requestAnimationFrame(() => {
              if (panel?.dataset.state !== "open") failures.push("command palette did not open");
              if (!panel.contains(document.activeElement)) failures.push("focus did not move into command palette");
              panel.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }));
              if (!document.activeElement?.matches(".am-command-item")) failures.push("ArrowDown did not move focus to a command item");
              panel.dispatchEvent(new KeyboardEvent("keydown", { key: "End", bubbles: true }));
              const items = Array.from(panel.querySelectorAll(".am-command-item:not([hidden])"));
              if (document.activeElement !== items[items.length - 1]) failures.push("End did not move to last command item");
              resolve({ failures });
            }));
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} dashboard command open failed: #{failure.as_s}" }

        if item[:name] == "dashboard-desktop-light" || item[:name] == "dashboard-command-reduced-motion"
          modal_before = devtools.evaluate(<<-JS).not_nil!
            (() => {
              const panel = document.querySelector("[data-ap-command-panel]");
              const items = Array.from(panel.querySelectorAll(".am-command-item:not([hidden])"));
              items[items.length - 1]?.focus();
              return { active: document.activeElement?.textContent?.trim().replace(/\\s+/g, " "), contained: panel.contains(document.activeElement) };
            })()
            JS
          dispatch_tab(devtools)
          modal_forward = devtools.evaluate(<<-JS).not_nil!
            (() => {
              const panel = document.querySelector("[data-ap-command-panel]");
              return { active: document.activeElement?.textContent?.trim().replace(/\\s+/g, " "), contained: panel.contains(document.activeElement) };
            })()
            JS
          dispatch_tab(devtools, true)
          modal_backward = devtools.evaluate(<<-JS).not_nil!
            (() => {
              const panel = document.querySelector("[data-ap-command-panel]");
              return { active: document.activeElement?.textContent?.trim().replace(/\\s+/g, " "), contained: panel.contains(document.activeElement) };
            })()
            JS
          unless modal_forward["contained"].as_bool && modal_backward["contained"].as_bool
            failures << "#{item[:name]} command palette synthetic tab escaped panel"
          end
          keyboard_evidence << {
            "case"                 => JSON::Any.new("#{item[:name]} command-palette-open"),
            "page"                 => JSON::Any.new("dashboard"),
            "theme"                => JSON::Any.new(item[:theme]),
            "synthetic_tab_order"  => JSON::Any.new([modal_before, modal_forward, modal_backward]),
            "synthetic_tab_passed" => JSON::Any.new(modal_forward["contained"].as_bool && modal_backward["contained"].as_bool),
          }
        end

        if item[:name] == "dashboard-desktop-light" || item[:name] == "dashboard-command-reduced-motion"
          state_name = item[:name] == "dashboard-command-reduced-motion" ? "dashboard-command-reduced-motion-open" : "dashboard-command-open"
          write_screenshot(devtools, ARTIFACT_DIR, state_name)
          evidence << {
            "name"   => JSON::Any.new(state_name),
            "page"   => JSON::Any.new("dashboard"),
            "width"  => JSON::Any.new(item[:width].to_i64),
            "height" => JSON::Any.new(item[:height].to_i64),
            "theme"  => JSON::Any.new(item[:theme]),
          }
        end

        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const filter = document.querySelector("[data-ap-filter]");
            const opener = document.querySelector("[data-ap-command-open]");
            const panel = document.querySelector("[data-ap-command-panel]");
            document.querySelector("[data-ap-command-close]")?.click();
              if (panel?.dataset.state !== "closed") failures.push("command palette did not close");
              if (document.activeElement !== opener) failures.push("focus did not return to command opener");
              filter.value = "";
              filter.dispatchEvent(new Event("input", { bubbles: true }));
              opener.blur();
              return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} dashboard command close failed: #{failure.as_s}" }
      when "collaboration"
        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const input = (el, value) => {
              el.value = value;
              el.dispatchEvent(new Event("input", { bubbles: true }));
            };
            const search = document.querySelector("[data-ap-live-search]");
            input(search, "payment");
            const results = document.querySelector("[data-ap-search-results]")?.textContent || "";
            if (!results.includes("Pricing payment form")) failures.push(`live search missed payment: ${results}`);
            input(search, "zzzz");
            if (!document.querySelector("[data-ap-search-results]")?.textContent.includes("No matching")) failures.push("live search empty state missing");
            const chatInput = document.querySelector("[data-ap-chat-form] input[name='message']");
            const before = document.querySelectorAll("[data-ap-chat-log] .am-message").length;
            input(chatInput, "This browser audit message was added in Chrome.");
            document.querySelector("[data-ap-chat-form]").dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            const after = document.querySelectorAll("[data-ap-chat-log] .am-message").length;
            if (after !== before + 1) failures.push("chat did not append a message");
            return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} collaboration flow failed: #{failure.as_s}" }
      when "patterns"
        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const tab = document.querySelector("#evidence-tab-audit");
            tab.click();
            if (tab.getAttribute("aria-selected") !== "true" || document.querySelector("#evidence-panel-audit")?.hidden) failures.push("tab activation failed");
            tab.focus();
            tab.dispatchEvent(new KeyboardEvent("keydown", { key: "Home", bubbles: true }));
            if (document.activeElement?.id !== "evidence-tab-spec") failures.push("Home did not move tabs to first item");
            document.activeElement.dispatchEvent(new KeyboardEvent("keydown", { key: "End", bubbles: true }));
            if (document.activeElement?.id !== "evidence-tab-shots") failures.push("End did not move tabs to last item");
            document.querySelector("[data-ap-carousel-next]")?.click();
            if (!document.querySelector("[data-ap-carousel-status]")?.textContent.includes("2 of 3")) failures.push("carousel did not advance");
            const carousel = document.querySelector("[data-ap-carousel]");
            carousel.focus();
            carousel.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }));
            if (!document.querySelector("[data-ap-carousel-status]")?.textContent.includes("3 of 3")) failures.push("carousel ArrowRight did not advance");
            const disclosure = document.querySelector("[data-ap-disclosure]");
            disclosure.click();
            if (disclosure.getAttribute("aria-expanded") !== "true" || document.querySelector("#advanced-panel")?.hidden) failures.push("disclosure did not open");
            return { failures };
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} patterns tab/carousel/disclosure failed: #{failure.as_s}" }

        if item[:name] == "patterns-desktop-light"
          write_screenshot(devtools, ARTIFACT_DIR, "patterns-tabs-carousel-state")
          evidence << {
            "name"   => JSON::Any.new("patterns-tabs-carousel-state"),
            "page"   => JSON::Any.new("patterns"),
            "width"  => JSON::Any.new(item[:width].to_i64),
            "height" => JSON::Any.new(item[:height].to_i64),
            "theme"  => JSON::Any.new(item[:theme]),
          }
        end

        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const opener = document.querySelector("[data-ap-dialog-open]");
            opener.click();
            const dialog = document.querySelector("#pattern-dialog");
            return new Promise((resolve) => requestAnimationFrame(() => {
              if (!dialog?.open) failures.push("dialog did not open");
              if (!dialog.contains(document.activeElement)) failures.push("focus did not move into dialog");
              const buttons = dialog.querySelectorAll("button");
              buttons[buttons.length - 1]?.focus();
              dialog.dispatchEvent(new KeyboardEvent("keydown", { key: "Tab", bubbles: true }));
              if (document.activeElement !== buttons[0]) failures.push("dialog Tab did not wrap to first focusable control");
              resolve({ failures });
            }));
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} patterns dialog open failed: #{failure.as_s}" }

        if item[:name] == "patterns-desktop-light" || item[:name] == "patterns-dialog-reduced-motion"
          modal_before = devtools.evaluate(<<-JS).not_nil!
            (() => {
              const dialog = document.querySelector("#pattern-dialog");
              const buttons = dialog.querySelectorAll("button");
              buttons[buttons.length - 1]?.focus();
              return { active: document.activeElement?.textContent?.trim().replace(/\\s+/g, " "), contained: dialog.contains(document.activeElement) };
            })()
            JS
          dispatch_tab(devtools)
          modal_forward = devtools.evaluate(<<-JS).not_nil!
            (() => {
              const dialog = document.querySelector("#pattern-dialog");
              return { active: document.activeElement?.textContent?.trim().replace(/\\s+/g, " "), contained: dialog.contains(document.activeElement) };
            })()
            JS
          dispatch_tab(devtools, true)
          modal_backward = devtools.evaluate(<<-JS).not_nil!
            (() => {
              const dialog = document.querySelector("#pattern-dialog");
              return { active: document.activeElement?.textContent?.trim().replace(/\\s+/g, " "), contained: dialog.contains(document.activeElement) };
            })()
            JS
          unless modal_forward["contained"].as_bool && modal_backward["contained"].as_bool
            failures << "#{item[:name]} dialog synthetic tab escaped dialog"
          end
          keyboard_evidence << {
            "case"                 => JSON::Any.new("#{item[:name]} dialog-open"),
            "page"                 => JSON::Any.new("patterns"),
            "theme"                => JSON::Any.new(item[:theme]),
            "synthetic_tab_order"  => JSON::Any.new([modal_before, modal_forward, modal_backward]),
            "synthetic_tab_passed" => JSON::Any.new(modal_forward["contained"].as_bool && modal_backward["contained"].as_bool),
          }
        end

        if item[:name] == "patterns-desktop-light" || item[:name] == "patterns-dialog-reduced-motion"
          state_name = item[:name] == "patterns-dialog-reduced-motion" ? "patterns-dialog-reduced-motion-open" : "patterns-dialog-open"
          write_screenshot(devtools, ARTIFACT_DIR, state_name)
          evidence << {
            "name"   => JSON::Any.new(state_name),
            "page"   => JSON::Any.new("patterns"),
            "width"  => JSON::Any.new(item[:width].to_i64),
            "height" => JSON::Any.new(item[:height].to_i64),
            "theme"  => JSON::Any.new(item[:theme]),
          }
        end

        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const opener = document.querySelector("[data-ap-dialog-open]");
            const dialog = document.querySelector("#pattern-dialog");
            dialog.close();
            return new Promise((resolve) => requestAnimationFrame(() => {
              if (dialog.open) failures.push("dialog did not close");
              if (document.activeElement !== opener) failures.push("dialog focus did not return to opener");
              resolve({ failures });
            }));
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} patterns dialog close failed: #{failure.as_s}" }
      when "timeline"
        result = devtools.evaluate(<<-JS).not_nil!
          (() => {
            const failures = [];
            const first = document.querySelector("[data-ap-reveal]");
            if (!first) failures.push("timeline reveal item missing");
            first?.scrollIntoView();
            return new Promise((resolve) => setTimeout(() => {
              if (first && first.dataset.visible !== "true") failures.push("timeline reveal did not mark item visible");
              resolve({ failures });
            }, 300));
          })()
          JS
        result["failures"].as_a.each { |failure| failures << "#{item[:name]} timeline flow failed: #{failure.as_s}" }
      end

      ax = devtools.call("Accessibility.getFullAXTree")
      ax_nodes = ax["result"]["nodes"].as_a
      unnamed_ax = ax["result"]["nodes"].as_a.select do |node|
        role = node["role"]?.try(&.["value"]?.try(&.as_s?))
        next false unless role && ["button", "textbox", "searchbox", "combobox", "checkbox", "radio", "slider", "dialog", "navigation"].includes?(role)
        name = node["name"]?.try(&.["value"]?.try(&.as_s?)) || ""
        name.strip.empty?
      end
      if unnamed_ax.any?
        roles = unnamed_ax.first(8).map { |node| node["role"]["value"].as_s }.join(", ")
        failures << "#{item[:name]} accessibility tree has unnamed controls: #{roles}"
      end
      important_roles = %w[
        main navigation button textbox searchbox combobox checkbox radio slider dialog table row
        columnheader rowheader cell tab tabpanel group link form heading status figure list listitem
      ]
      summarized_ax_nodes = ax_nodes.select do |node|
        role = ax_value(node, "role")
        important_roles.includes?(role)
      end.first(220).map do |node|
        role = ax_value(node, "role")
        JSON::Any.new({
          "role"        => JSON::Any.new(role),
          "name"        => JSON::Any.new(ax_value(node, "name")),
          "value"       => JSON::Any.new(ax_value(node, "value")),
          "description" => JSON::Any.new(ax_value(node, "description")),
          "checked"     => JSON::Any.new(ax_property(node, "checked") || ""),
          "selected"    => JSON::Any.new(ax_property(node, "selected") || ""),
          "disabled"    => JSON::Any.new(ax_property(node, "disabled") || ""),
          "invalid"     => JSON::Any.new(ax_property(node, "invalid") || ""),
          "modal"       => JSON::Any.new(ax_property(node, "modal") || ""),
        })
      end
      role_counts = Hash(String, Int32).new(0)
      ax_nodes.each do |node|
        role = ax_value(node, "role")
        role_counts[role] += 1 unless role.empty?
      end
      ax_tree_evidence << {
        "case"             => JSON::Any.new(item[:name]),
        "page"             => JSON::Any.new(item[:page]),
        "theme"            => JSON::Any.new(item[:theme]),
        "source"           => JSON::Any.new("Chrome DevTools Protocol Accessibility.getFullAXTree"),
        "node_count"       => JSON::Any.new(ax_nodes.size.to_i64),
        "role_counts"      => JSON::Any.new(role_counts.transform_values { |value| JSON::Any.new(value.to_i64) }),
        "sampled_nodes"    => JSON::Any.new(summarized_ax_nodes),
        "unnamed_controls" => JSON::Any.new(unnamed_ax.map do |node|
          JSON::Any.new({
            "role" => JSON::Any.new(ax_value(node, "role")),
            "name" => JSON::Any.new(ax_value(node, "name")),
          })
        end),
      }

      full_height = [common_result["height"].as_i, item[:height]].max
      devtools.call(
        "Emulation.setDeviceMetricsOverride",
        %({"width":#{item[:width]},"height":#{full_height},"deviceScaleFactor":1,"mobile":#{item[:mobile]}})
      )
      write_screenshot(devtools, ARTIFACT_DIR, item[:name])

      evidence << {
        "name"   => JSON::Any.new(item[:name]),
        "page"   => JSON::Any.new(item[:page]),
        "width"  => JSON::Any.new(item[:width].to_i64),
        "height" => JSON::Any.new(full_height.to_i64),
        "theme"  => JSON::Any.new(item[:theme]),
      }
    ensure
      devtools.close
    end
  end

  viewport_summary = {
    "total_screenshots"       => JSON::Any.new(evidence.size.to_i64),
    "desktop_light_dark_1440" => JSON::Any.new(evidence.count do |entry|
      name = entry["name"].as_s
      entry["width"].as_i == 1440 && (name == "desktop-light" || name == "desktop-dark" || name.includes?("-desktop-"))
    end.to_i64),
    "mobile_light_dark_390" => JSON::Any.new(evidence.count do |entry|
      entry["width"].as_i == 390 && entry["name"].as_s.includes?("mobile")
    end.to_i64),
    "reflow_light_dark_320" => JSON::Any.new(evidence.count do |entry|
      entry["width"].as_i == 320
    end.to_i64),
    "reduced_motion_screenshots" => JSON::Any.new(evidence.count do |entry|
      entry["name"].as_s.includes?("reduced-motion")
    end.to_i64),
    "interactive_state_screenshots" => JSON::Any.new(evidence.count do |entry|
      name = entry["name"].as_s
      name.includes?("invalid-state") ||
        name.ends_with?("-open") ||
        name.includes?("tabs-carousel-state") ||
        name.includes?("dialog-open")
    end.to_i64),
  }

  report = {
    "screenshots"               => evidence,
    "viewport_summary"          => viewport_summary,
    "contrast_report"           => CONTRAST_FILE,
    "reduced_motion_report"     => REDUCED_MOTION_FILE,
    "keyboard_traversal_report" => KEYBOARD_FILE,
    "touch_target_report"       => TOUCH_TARGET_FILE,
    "accessibility_tree_report" => AX_TREE_FILE,
    "failures"                  => failures,
    "passed"                    => failures.empty?,
  }
  File.write(REPORT_FILE, report.to_pretty_json)
  File.write(CONTRAST_FILE, {
    "samples"  => contrast_evidence,
    "failures" => failures.select(&.includes?("contrast")),
    "passed"   => failures.none?(&.includes?("contrast")),
  }.to_pretty_json)
  File.write(CONTRAST_CSV, String.build do |io|
    io << "case,page,theme,label,ratio,minimum\n"
    contrast_evidence.each do |sample|
      io << sample["case"].as_s << "," << sample["page"].as_s << "," << sample["theme"].as_s << ","
      io << sample["label"].as_s << "," << sample["ratio"].as_f << "," << sample["minimum"].as_f << "\n"
    end
  end)
  File.write(REDUCED_MOTION_FILE, {
    "cases"            => reduced_motion_evidence,
    "surface_contract" => [
      "sticky-hover",
      "timeline-reveal",
      "svg-sequence",
      "chart-bars",
      "table-rows",
      "carousel",
      "dialog",
      "tabs",
      "theme-switcher",
      "forms",
    ],
    "failures" => failures.select(&.includes?("reduced motion")),
    "passed"   => failures.none?(&.includes?("reduced motion")),
  }.to_pretty_json)
  File.write(AX_TREE_FILE, {
    "source"   => "Chrome DevTools Protocol Accessibility.getFullAXTree",
    "cases"    => ax_tree_evidence,
    "failures" => failures.select(&.includes?("accessibility tree")),
    "passed"   => failures.none?(&.includes?("accessibility tree")),
  }.to_pretty_json)
  File.write(KEYBOARD_FILE, {
    "cases"    => keyboard_evidence,
    "failures" => failures.select { |failure| failure.includes?("tabindex") || failure.includes?("synthetic tab") },
    "passed"   => failures.none? { |failure| failure.includes?("tabindex") || failure.includes?("synthetic tab") },
  }.to_pretty_json)
  File.write(TOUCH_TARGET_FILE, {
    "cases"    => touch_target_evidence,
    "failures" => failures.select { |failure| failure.includes?("touch targets") },
    "passed"   => failures.none? { |failure| failure.includes?("touch targets") },
  }.to_pretty_json)
  FileUtils.rm_rf(LEGACY_ARTIFACT_DIR)
  FileUtils.mkdir_p(File.dirname(LEGACY_ARTIFACT_DIR))
  FileUtils.cp_r(ARTIFACT_DIR, LEGACY_ARTIFACT_DIR)

  if failures.any?
    STDERR.puts "Web design-system browser screenshot validation failed:"
    failures.each { |failure| STDERR.puts "- #{failure}" }
    exit 1
  end

  puts "Web design-system browser screenshots written to #{ARTIFACT_DIR}"
ensure
  process.terminate
  process.wait
  FileUtils.rm_rf(profile_dir)
end
