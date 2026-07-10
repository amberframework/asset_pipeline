require "file_utils"
require "http/client"
require "http/web_socket"
require "json"
require "uri"

ROOT          = File.expand_path("..", __DIR__)
ARTIFACT_DIR  = File.join(ROOT, "test-results/web-design-system")
LEGACY_ARTIFACT_DIR = File.join(ROOT, "test-results/amber-design-system")
REPORT_FILE   = File.join(ARTIFACT_DIR, "ibm-equal-access-audit.json")
ACE_URL       = "https://unpkg.com/accessibility-checker-engine@4.0.17/ace.js"
IBM_RULESET   = "IBM_Accessibility"
PAGES         = {
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

chrome = CHROME_CANDIDATES.find { |path| File::Info.executable?(path) }
fail!("No Chrome/Chromium binary found. Set CHROME_BIN to enable IBM Equal Access audit.") unless chrome

ace_response = HTTP::Client.get(ACE_URL)
fail!("Unable to fetch IBM Equal Access engine from #{ACE_URL}: #{ace_response.status_code}") unless ace_response.status.success?
ace_source = ace_response.body

port = 9800 + Random.rand(300)
profile_dir = File.tempname("amber-ibm-chrome")
FileUtils.mkdir_p(profile_dir)
FileUtils.mkdir_p(ARTIFACT_DIR)

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

  cases = PAGES.keys.flat_map do |page|
    [
      {page: page, theme: "light", color_scheme: "light"},
      {page: page, theme: "dark", color_scheme: "dark"},
    ]
  end

  failures = [] of String
  results = [] of Hash(String, JSON::Any)

  cases.each do |item|
    page_path = PAGES[item[:page]]
    response = client.exec("PUT", "/json/new?about:blank")
    fail!("Unable to create Chrome target: #{response.status_code} #{response.body}") unless response.status.success?

    devtools = DevTools.new(JSON.parse(response.body)["webSocketDebuggerUrl"].as_s)
    begin
      devtools.call("Page.enable")
      devtools.call("Runtime.enable")
      devtools.call("Emulation.setDeviceMetricsOverride", %({"width":1440,"height":1100,"deviceScaleFactor":1,"mobile":false}))
      devtools.call("Emulation.setEmulatedMedia", %({"features":[{"name":"prefers-color-scheme","value":#{item[:color_scheme].to_json}}]}))
      devtools.call("Page.navigate", %({"url":#{"file://#{page_path}".to_json}}))
      50.times do
        break if devtools.evaluate("document.readyState").try(&.as_s?) == "complete"
        sleep 0.1.seconds
      end
      devtools.evaluate(%(AssetPipelineDesignSystem.setTheme(#{item[:theme].to_json}, false)))
      devtools.evaluate(ace_source)
      raw = devtools.evaluate(<<-JS).not_nil!.as_s
        (async () => {
          const checker = new ace.Checker();
          const rawReport = await checker.check(document, [#{IBM_RULESET.to_json}]);
          const report = rawReport.report || rawReport;
          const active = report.results.filter((result) => result.value && result.value[1] !== "PASS");
          return JSON.stringify({
            summary: report.summary,
            active: active.map((result) => ({
              ruleId: result.ruleId,
              reasonId: result.reasonId,
              level: result.level || String((result.value || [])[0] || "").toLowerCase(),
              value: result.value,
              message: result.message,
              path: result.path,
              snippet: (result.snippet || "").slice(0, 180)
            }))
          });
        })()
        JS
      parsed = JSON.parse(raw)
      violations = parsed["active"].as_a.select do |result|
        value = result["value"]?.try(&.as_a?) || [] of JSON::Any
        kind = value[0]?.try(&.as_s?) || ""
        status = value[1]?.try(&.as_s?) || ""
        kind == "VIOLATION" && status == "FAIL"
      end
      violations.each do |violation|
        failures << "#{item[:page]} #{item[:theme]} IBM #{violation["ruleId"].as_s}: #{violation["message"].as_s}"
      end

      results << {
        "page" => JSON::Any.new(item[:page]),
        "theme" => JSON::Any.new(item[:theme]),
        "summary" => parsed["summary"]? || JSON::Any.new(nil),
        "active" => parsed["active"],
        "violation_count" => JSON::Any.new(violations.size.to_i64),
      }
    ensure
      devtools.close
    end
  end

  report = {
    "engine_url" => ACE_URL,
    "ruleset" => IBM_RULESET,
    "pages" => PAGES,
    "results" => results,
    "failures" => failures,
    "passed" => failures.empty?,
  }
  File.write(REPORT_FILE, report.to_pretty_json)
  FileUtils.rm_rf(LEGACY_ARTIFACT_DIR)
  FileUtils.mkdir_p(File.dirname(LEGACY_ARTIFACT_DIR))
  FileUtils.cp_r(ARTIFACT_DIR, LEGACY_ARTIFACT_DIR)

  if failures.any?
    STDERR.puts "Web design-system IBM Equal Access audit failed:"
    failures.each { |failure| STDERR.puts "- #{failure}" }
    exit 1
  end

  puts "Web design-system IBM Equal Access audit passed: #{REPORT_FILE}"
ensure
  process.terminate
  process.wait
  FileUtils.rm_rf(profile_dir)
end
