{% if flag?(:macos) %}

require "spec"
require "../../../src/ui"
require "../../../src/ui/ax_test"

describe UI::AXTest::App do
  describe ".accessibility_trusted?" do
    it "returns a boolean" do
      result = UI::AXTest::App.accessibility_trusted?
      (result == true || result == false).should be_true
    end
  end

  describe "querying Finder (always-running macOS app)" do
    # Use Finder as a test target since it's always running on macOS.
    finder_pid : Int32 = 0

    before_each do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      finder_pid = output.to_s.strip.to_i32
    end

    it "connects to a running app by PID" do
      app = UI::AXTest::App.connect(finder_pid)
      app.pid.should eq(finder_pid)
      app.running?.should be_true
    end

    it "reads the app's accessibility role" do
      app = UI::AXTest::App.connect(finder_pid)
      app.root.role.should eq("AXApplication")
    end

    it "can list windows" do
      app = UI::AXTest::App.connect(finder_pid)
      windows = app.windows
      windows.should be_a(Array(UI::AXTest::Element))
      # Finder might have 0 or more windows
    end

    it "can search for elements by role" do
      app = UI::AXTest::App.connect(finder_pid)
      # Look for any menu bar
      menu_bar = app.find(role: "AXMenuBar")
      menu_bar.should_not be_nil
    end
  end

  describe "querying Scribe (if installed)" do
    it "connects to Scribe and finds the menu bar" do
      # Only run if Scribe is installed and running
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "scribe"], output: output) rescue nil
      pid_str = output.to_s.strip
      pending!("Scribe not running") if pid_str.empty?

      app = UI::AXTest::App.connect(pid_str.to_i32)
      app.root.role.should eq("AXApplication")
    end
  end

  describe UI::AXTest::Screenshot do
    it "generates a test path" do
      path = UI::AXTest::Screenshot.test_path("test_capture", "scribe")
      path.should contain("/tmp/scribe_test_screenshots/")
      path.should contain("test_capture")
      path.should end_with(".png")
    end
  end
end

{% end %}
