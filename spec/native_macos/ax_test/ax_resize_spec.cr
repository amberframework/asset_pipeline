{% if flag?(:macos) %}

require "spec"
require "../../../src/ui"
require "../../../src/ui/ax_test"

# A5 — App#resize_window(title, width, height).
#
# Sets kAXSizeAttribute on the matched window's AXUIElement directly —
# no AppleScript fallback. Requires the target window to advertise
# AXSize as settable and the runner to have Accessibility permission.
describe UI::AXTest::App do
  describe "#resize_window" do
    it "returns false when window with the given title cannot be found" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      app.resize_window("__no_such_window_#{Time.utc.to_unix}__", 800, 600, timeout: 0.1).should be_false
    end

    pending "resizes a real window in a fixture app (requires Accessibility permission + writable window)"
  end
end

{% end %}
