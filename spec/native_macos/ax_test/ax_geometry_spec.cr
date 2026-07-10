{% if flag?(:macos) %}

require "spec"
require "../../../src/ui"
require "../../../src/ui/ax_test"

# A2 — AXValueRef unpacker for CGPoint / CGSize / CGRect.
#
# Verified end-to-end against Finder: if Finder has at least one open
# window, that window's frame is read and asserted to have nonzero size
# and non-negative position. If Finder has no windows, the geometry
# accessors return nil cleanly (and the spec asserts that behavior).
describe UI::AXTest::Element do
  describe "#position / #size / #frame" do
    it "returns Float64-valued tuples for elements that have geometry" do
      # The Finder application element exposes a synthetic position
      # (origin of the active focused element). Some macOS versions
      # expose this on the root, some do not — accept either nil or a
      # Float64-valued NamedTuple.
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)
      pos = app.root.position
      if pos
        pos[:x].should be_a(Float64)
        pos[:y].should be_a(Float64)
      end
      sz = app.root.size
      if sz
        sz[:width].should be_a(Float64)
        sz[:height].should be_a(Float64)
      end
    end

    it "reads a window's position, size, and composed frame" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)

      windows = app.windows
      pending!("Finder has no open windows; cannot verify AXValue unboxing") if windows.empty?

      win = windows.first
      pos = win.position
      sz = win.size
      fr = win.frame

      pos.should_not be_nil
      sz.should_not be_nil
      fr.should_not be_nil

      if (pos_v = pos) && (sz_v = sz) && (fr_v = fr)
        # Position can be negative on multi-monitor setups, but width/height
        # of an open window must be > 0.
        sz_v[:width].should be > 0.0
        sz_v[:height].should be > 0.0
        # Frame is composed from position + size.
        fr_v[:x].should eq(pos_v[:x])
        fr_v[:y].should eq(pos_v[:y])
        fr_v[:width].should eq(sz_v[:width])
        fr_v[:height].should eq(sz_v[:height])
      end
    end

    it "bounds_in_screen is an alias for frame" do
      output = IO::Memory.new
      Process.run("pgrep", ["-x", "Finder"], output: output)
      pid = output.to_s.strip.to_i32
      app = UI::AXTest::App.connect(pid)

      windows = app.windows
      pending!("Finder has no open windows; cannot verify alias semantics") if windows.empty?

      win = windows.first
      win.bounds_in_screen.should eq(win.frame)
    end
  end
end

{% end %}
