# Phase 6.5 D5 — Shared CDP DevTools wrapper for the cdp_probes/ library.
#
# Extracted verbatim from scripts/phase04_cdp_harness.cr (1272 lines).
# Every probe in scripts/cdp_probes/ requires this file rather than
# vendoring its own websocket plumbing.
#
# Usage:
#   require "./devtools"
#   CDPSession.with_chrome("path/to/page.html") do |dt|
#     dt.evaluate("document.title")
#   end

require "file_utils"
require "http/client"
require "http/web_socket"
require "json"
require "uri"
require "base64"

module CDPProbes
  REPO_ROOT  = File.expand_path("../..", __DIR__)
  VENDOR_DIR = File.join(REPO_ROOT, "vendor/audit")

  # Default a11y audit asset paths (vendored at fixed versions).
  AXE_PATH = File.join(VENDOR_DIR, "axe.min.js")
  ACE_PATH = File.join(VENDOR_DIR, "ace.js")

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

    def set_emulated_media(features : Array(NamedTuple(name: String, value: String)))
      payload = %({"features":[)
      payload += features.map_with_index { |f, i| (i > 0 ? "," : "") + %({"name":#{f[:name].to_json},"value":#{f[:value].to_json}}) }.join
      payload += "]}"
      call("Emulation.setEmulatedMedia", payload)
    end
  end

  # ----------------------------------------------------------------
  # Chrome session helper. Boots a single headless Chrome, yields a
  # block with a DevTools wrapper attached to a fresh target loaded
  # at the given page path (file:// URL), and tears down both on
  # ensure.
  #
  # The vendored axe-core + IBM Equal Access JS lives under
  # vendor/audit/{axe.min.js,ace.js}; the screenshot probe + a11y
  # probes read them.
  # ----------------------------------------------------------------
  module CDPSession
    extend self

    def with_chrome(
      page_path : String,
      *,
      viewport : NamedTuple(width: Int32, height: Int32) = {width: 1280, height: 800},
      color_scheme : String = "light",
      extra_emulated_media : Array(NamedTuple(name: String, value: String)) = [] of NamedTuple(name: String, value: String),
      & : DevTools ->
    )
      chrome = CHROME_CANDIDATES.find { |path| File::Info.executable?(path) }
      raise "No Chrome binary found. Set CHROME_BIN." unless chrome

      port = 9700 + Random.rand(300)
      profile_dir = File.tempname("cdp-probes-chrome")
      FileUtils.mkdir_p(profile_dir)

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

      # Wait for /json/version to be reachable. Chrome 149+ has a slower
      # startup path (5-8s on cold cache) so the original 3s budget
      # would race the DevTools listener. 200x100ms == 20s ceiling
      # leaves headroom for the slowest path.
      client = HTTP::Client.new("127.0.0.1", port)
      ready = false
      200.times do
        begin
          resp = client.exec("GET", "/json/version")
          if resp.status.success?
            ready = true
            break
          end
        rescue
          # connect refused; keep waiting.
        end
        sleep(0.1.seconds)
      end
      raise "Chrome DevTools never became ready on port #{port}" unless ready

      begin
        # Fresh target per session.
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
          # Color scheme + extras.
          features = [{name: "prefers-color-scheme", value: color_scheme}]
          features.concat(extra_emulated_media)
          dt.set_emulated_media(features)
          dt.call("Page.navigate", %({"url":#{"file://#{page_path}".to_json}}))
          100.times do
            break if dt.evaluate(%(document.readyState)).try(&.as_s?) == "complete"
            sleep(0.05.seconds)
          end
          yield dt
        ensure
          dt.close
          client.delete("/json/close/#{target_id}") rescue nil
        end
      ensure
        process.terminate rescue nil
        process.wait rescue nil
        FileUtils.rm_rf(profile_dir) rescue nil
      end
    end
  end

  # ----------------------------------------------------------------
  # Default page resolver — translates --slug <name> into a
  # samples/cross_platform/web/dist/ HTML file path.
  # ----------------------------------------------------------------
  module SlugResolver
    extend self

    DIST_DIRS = [
      File.join(REPO_ROOT, "samples/cross_platform/web/dist"),
      # Phase 6 — demo screens live here, written by
      # `crystal run samples/initiative-cross-platform-ui-demo/web/static_site.cr`.
      File.join(REPO_ROOT, "output/initiative-demo"),
    ]

    def resolve(slug : String) : String
      # Slug may be either a bare slug ("action_sheet") or a filename
      # ("phase04_action_sheet_demo"). Try .html suffixes in dist dirs.
      candidates = [
        slug,
        slug + ".html",
        "phase04_#{slug}_demo.html",
        "phase04_#{slug}.html",
        # Phase 6 demo slug — light-by-default; the harness can swap
        # to the dark variant via a slug suffix.
        "#{slug}-light.html",
        "#{slug}-dark.html",
      ]
      DIST_DIRS.each do |dir|
        candidates.each do |c|
          p = File.join(dir, c)
          return p if File.exists?(p)
        end
      end
      raise "SlugResolver: no HTML page found for slug=#{slug} in #{DIST_DIRS}"
    end
  end
end
