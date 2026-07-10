{% if flag?(:macos) %}

require "spec"
require "../../../src/ui"
require "../../../src/ui/ax_test"

# A3 — Value writer (`Element#set_value` and `set_attribute`).
#
# Real verification (sliding a slider, populating a text field, toggling
# a checkbox) requires:
#   1. A target app with a writable kAXValueAttribute on a discoverable
#      element.
#   2. The test runner having Accessibility permission granted to its
#      parent process (Terminal / iTerm / IDE).
#
# Without both, the surface still must be exercised so we get a
# regression signal if the FFI bindings drift. These specs:
#   * Verify the API surface compiles and short-circuits cleanly when
#     called against an element whose AXValue is not settable (returns
#     false rather than raising).
#   * Mark the live-write integration assertion `pending!` with a
#     descriptive reason — when run against a real app with the
#     permission granted, those branches will execute.
describe UI::AXTest::Element do
  describe "#set_value" do
    it "returns false (cleanly) when target attribute is not settable" do
      # The Finder root AXApplication element does not expose a
      # settable AXValue — writes should fail gracefully.
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)

      # Float64
      app.root.set_value(0.5_f64).should be_false
      # Int32
      app.root.set_value(7).should be_false
      # String
      app.root.set_value("ignored").should be_false
      # Bool — false branch (uses kCFBooleanFalse)
      app.root.set_value(false).should be_false
    end

    it "accepts every supported value type without raising" do
      # Purely a surface test — guarantees the dispatch on value type
      # doesn't blow up Crystal's type checker or the runtime.
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)

      [0.5_f64, 0.5_f32, 1_i32, 1_i64, "hi", true, false].each do |v|
        # Should not raise. Return value is bool; we don't assert here.
        app.root.set_value(v)
      end
    end

    pending "writes a real numeric value to a slider (requires test fixture app + accessibility permission)"
  end

  describe "#set_size / #set_position" do
    it "returns false cleanly on non-window elements" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      # The root app element does not have a settable AXSize/AXPosition.
      # We expect a clean false — no crash.
      app.root.set_size(800.0, 600.0).should be_false
      app.root.set_position(100.0, 100.0).should be_false
    end
  end
end

{% end %}
