require "file_utils"
require "http/client"
require "http/web_socket"
require "json"
require "uri"

ROOT         = File.expand_path("..", __DIR__)
ARTIFACT_DIR = File.join(ROOT, "test-results/web-design-system")
LEGACY_ARTIFACT_DIR = File.join(ROOT, "test-results/amber-design-system")
REPORT_FILE  = File.join(ARTIFACT_DIR, "axe-audit.json")
AXE_URL      = "https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js"
PAGES        = {
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
fail!("No Chrome/Chromium binary found. Set CHROME_BIN to enable axe audit.") unless chrome

axe_response = HTTP::Client.get(AXE_URL)
fail!("Unable to fetch axe-core from #{AXE_URL}: #{axe_response.status_code}") unless axe_response.status.success?
axe_source = axe_response.body

port = 9700 + Random.rand(300)
profile_dir = File.tempname("amber-axe-chrome")
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
      devtools.evaluate(axe_source)
      raw = devtools.evaluate(<<-JS).not_nil!.as_s
        axe.run(document, {
          runOnly: {
            type: "tag",
            values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22a", "wcag22aa"]
          },
          resultTypes: ["violations", "incomplete"]
        }).then((result) => JSON.stringify({
          violations: result.violations.map((item) => ({
            id: item.id,
            impact: item.impact,
            description: item.description,
            help: item.help,
            nodes: item.nodes.map((node) => ({
              target: node.target,
              html: node.html.slice(0, 180),
              failureSummary: node.failureSummary || ""
            }))
          })),
          incomplete: result.incomplete.map((item) => ({
            id: item.id,
            impact: item.impact,
            help: item.help,
            nodes: item.nodes.length
          }))
        }))
        JS
      parsed = JSON.parse(raw)
      serious = parsed["violations"].as_a.select do |violation|
        impact = violation["impact"]?.try(&.as_s?) || ""
        ["serious", "critical"].includes?(impact)
      end
      serious.each do |violation|
        failures << "#{item[:page]} #{item[:theme]} axe #{violation["impact"].as_s}: #{violation["id"].as_s} - #{violation["help"].as_s}"
      end

      results << {
        "page" => JSON::Any.new(item[:page]),
        "theme" => JSON::Any.new(item[:theme]),
        "violations" => parsed["violations"],
        "incomplete" => parsed["incomplete"],
        "serious_or_critical_count" => JSON::Any.new(serious.size.to_i64),
      }
    ensure
      devtools.close
    end
  end

  report = {
    "axe_url" => AXE_URL,
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
    STDERR.puts "Web design-system axe audit failed:"
    failures.each { |failure| STDERR.puts "- #{failure}" }
    exit 1
  end

  puts "Web design-system axe audit passed: #{REPORT_FILE}"
ensure
  process.terminate
  process.wait
  FileUtils.rm_rf(profile_dir)
end
