{% if flag?(:macos) %}

require "spec"
require "../../../src/ui"
require "../../../src/ui/ax_test"

# A4 — Focus (`Element#focus!`, `App#focused_element`,
# `App.system_focused_element`).
#
# Reading focus does not require Accessibility permission on the spec
# runner — the AX API can introspect focus from a cross-process query.
# Writing focus (`Element#focus!`) requires the target to advertise
# `AXFocused` as settable and the spec runner to have AX permission.
describe UI::AXTest do
  describe "App#focused_element" do
    it "returns an Element or nil without raising" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      result = app.focused_element
      (result.nil? || result.is_a?(UI::AXTest::Element)).should be_true
    end
  end

  describe "App.system_focused_element" do
    it "returns an Element or nil without raising" do
      result = UI::AXTest::App.system_focused_element
      (result.nil? || result.is_a?(UI::AXTest::Element)).should be_true
    end
  end

  describe "Element#focus!" do
    it "returns a boolean without raising on a non-focusable element" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      # The app root itself is not focusable.
      result = app.root.focus!
      (result == true || result == false).should be_true
    end

    pending "drives focus to a textfield in a fixture app (requires accessibility permission)"
  end
end

{% end %}
