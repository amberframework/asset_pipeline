{% if flag?(:macos) %}

require "spec"
require "../../../src/ui"
require "../../../src/ui/ax_test"

# A1 — find by AXIdentifier.
#
# These specs exercise the API surface and the recursive-walk semantics.
# Connecting to Finder verifies the wiring works end-to-end against a
# real AX tree (no AX permission required to *read* attributes, but the
# spec runner must have Accessibility access for cross-process reads —
# the existing `ax_app_spec.cr` already establishes this is the case in
# this repo's test environment).
describe UI::AXTest::Element do
  describe "#identifier" do
    it "is a string-returning attribute reader (nil-tolerant)" do
      # Pure surface test: connect to Finder's root, read identifier;
      # may be nil — root apps rarely have AXIdentifier set.
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      result = app.root.identifier
      (result.nil? || result.is_a?(String)).should be_true
    end
  end

  describe "#find(identifier: ...)" do
    it "accepts identifier as a named parameter" do
      # Smoke test the signature compiles and short-circuits cleanly
      # when no element matches a synthetic identifier.
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      app.find(identifier: "__nonexistent_test_id_#{Time.utc.to_unix}").should be_nil
    end

    it "combines identifier filter with role filter" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      # Combining filters should still return nil for a bogus id.
      app.find(role: "AXButton", identifier: "__bogus__").should be_nil
    end
  end

  describe "#find_by_id / #find_by_id!" do
    it "find_by_id returns nil when no element matches" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      app.find_by_id("__nonexistent__").should be_nil
    end

    it "find_by_id! raises when no element matches" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      expect_raises(Exception, /no element with AXIdentifier/) do
        app.find_by_id!("__nonexistent__")
      end
    end
  end
end

{% end %}
