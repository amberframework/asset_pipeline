# Screenshot capture helpers for the AXTest harness. Shells out to the macOS
# `screencapture` CLI to produce full-screen or per-window PNGs.

{% if flag?(:macos) %}

module UI::AXTest
  # Screenshot capture utility using macOS screencapture CLI.
  module Screenshot
    # Capture full screen to a PNG file.
    def self.capture(path : String)
      dir = File.dirname(path)
      Dir.mkdir_p(dir) unless Dir.exists?(dir)
      Process.run("/usr/sbin/screencapture", ["-x", path])
    end

    # Capture a specific window by its window ID.
    def self.capture_window(window_id : Int32, path : String)
      dir = File.dirname(path)
      Dir.mkdir_p(dir) unless Dir.exists?(dir)
      Process.run("/usr/sbin/screencapture", ["-x", "-l", window_id.to_s, path])
    end

    # Generate a timestamped screenshot path in the standard test output directory.
    def self.test_path(name : String, app_name : String = "app") : String
      dir = "/tmp/#{app_name}_test_screenshots"
      Dir.mkdir_p(dir) unless Dir.exists?(dir)
      timestamp = Time.local.to_s("%Y%m%d_%H%M%S")
      "#{dir}/#{name}_#{timestamp}.png"
    end
  end
end

{% end %}
