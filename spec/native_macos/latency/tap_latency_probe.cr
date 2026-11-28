# Tap-latency probe for asset_pipeline's AppKit renderer.
#
# Renders a screen through `UI::AppKit::Renderer` the way the sample apps do
# (rebuild the whole tree on every state change and replace the window's
# content view), clicks the first button with synthetic mouse events posted
# from a background thread, and writes every timestamp to `rows.txt`, which
# `tap_latency_analysis.rb` reads.
#
# This file is a standalone program, not a spec: `make test-latency-macos`
# builds it and `run_tap_latency_lane.rb` runs it once per scenario. The
# environment is the probe's command line, read once in `ProbeSettings`.
#
#   PROBE_SCENARIO     press | rerender | slow | gc
#   PROBE_ROWS         rows of (Label, Button, Toggle) under the probe button
#   PROBE_TAPS         taps in the click plan
#   PROBE_INTERVAL_MS  time between taps
#   PROBE_HOLD_MS      time between mouse-down and mouse-up
#   PROBE_RETAIN       resident records of 100 strings (gc scenario heap)
#   PROBE_OUT          output directory
{% unless flag?(:macos) %}
  {% raise "tap_latency_probe.cr drives the AppKit renderer: build it with -Dmacos (make test-latency-macos)" %}
{% end %}

require "../../../src/ui"

lib LibTapLatencyProbe
  fun probe_now_ns : UInt64
  fun probe_mark(kind : Int32, v : Int64) : Void
  fun probe_create_window(w : Float64, h : Float64) : Void*
  fun probe_set_content(view : Void*) : Void
  fun probe_retarget(n : Int32) : Void
  fun probe_reset_rest : Void
  fun probe_start(count : Int32, interval_ms : Float64, hold_ms : Float64, watch_pixels : Int32, done : ->) : Void
  fun probe_dump(path : UInt8*) : Void
  fun probe_run_app : Void
  fun usleep(microseconds : UInt32) : Int32
end

module TapLatencyProbe
  # Mark kinds written from Crystal; 1..19 belong to the Objective-C helper.
  MARK_ACTION_START = 20
  MARK_ACTION_END   = 21
  MARK_RENDER_START = 22
  MARK_RENDER_END   = 23
  MARK_HEAP         = 24
  MARK_GC_BASE      = 30

  LIST_OF_SCENARIOS = {"press", "rerender", "slow", "gc"}

  # The probe's command line, read once at program start.
  record ProbeSettings,
    scenario : String,
    row_count : Int32,
    tap_count : Int32,
    interval_ms : Float64,
    hold_ms : Float64,
    retained_record_count : Int32,
    output_directory : String do
    def self.from_environment : ProbeSettings
      scenario = ENV["PROBE_SCENARIO"]? || "rerender"
      unless LIST_OF_SCENARIOS.includes?(scenario)
        raise ArgumentError.new("PROBE_SCENARIO must be one of #{LIST_OF_SCENARIOS.join(", ")}, got #{scenario}")
      end
      new(
        scenario: scenario,
        row_count: (ENV["PROBE_ROWS"]? || "40").to_i,
        tap_count: (ENV["PROBE_TAPS"]? || "30").to_i,
        interval_ms: (ENV["PROBE_INTERVAL_MS"]? || "600").to_f,
        hold_ms: (ENV["PROBE_HOLD_MS"]? || "80").to_f,
        retained_record_count: (ENV["PROBE_RETAIN"]? || "0").to_i,
        output_directory: ENV["PROBE_OUT"]? || ".",
      )
    end

    # The press and gc scenarios never rebuild, so the pressed pixels of the
    # target can be watched across the tap.
    def watches_pressed_pixels? : Bool
      {"press", "gc"}.includes?(scenario)
    end

    # The gc scenario adds a background thread that allocates continuously.
    def runs_background_allocation? : Bool
      scenario == "gc"
    end
  end

  SETTINGS = ProbeSettings.from_environment

  # Main-thread state only: every reader and writer runs on the AppKit main
  # thread (the tap handler, mount, finish), so no lock is needed.
  @@tap_count = 0
  @@renderer = UI::AppKit::Renderer.new
  @@mounted_view : UI::NativeView? = nil
  @@list_of_retained_records = [] of Array(String)

  def self.build_screen : UI::View
    root = UI::VStack.new(spacing: 6.0)
    root << UI::Button.new("Tap me (#{SETTINGS.scenario})") { handle_tap }
    root << UI::Label.new("Taps: #{@@tap_count}")
    list = UI::VStack.new(spacing: 6.0)
    SETTINGS.row_count.times do |index|
      row = UI::HStack.new(spacing: 8.0)
      row << UI::Label.new("Row #{index} · item #{index * 7 + @@tap_count}")
      row << UI::Button.new("Edit #{index}") { }
      row << UI::Toggle.new("On", index.even?)
      list << row
    end
    scroller = UI::ScrollView.new(list)
    scroller.frame_height = 760.0
    root << scroller
    root
  end

  # Rebuilds the whole tree and replaces the window's content view, as the
  # sample hosts do today; the previous tree becomes garbage.
  def self.mount_screen : Nil
    LibTapLatencyProbe.probe_mark(MARK_RENDER_START, @@tap_count.to_i64)
    native_view = @@renderer.render(build_screen)
    LibTapLatencyProbe.probe_set_content(native_view.handle.ptr!)
    @@mounted_view = native_view
    LibTapLatencyProbe.probe_retarget(0)
    LibTapLatencyProbe.probe_reset_rest
    LibTapLatencyProbe.probe_mark(MARK_RENDER_END, @@tap_count.to_i64)
  end

  def self.handle_tap : Nil
    LibTapLatencyProbe.probe_mark(MARK_ACTION_START, @@tap_count.to_i64)
    @@tap_count += 1
    case SETTINGS.scenario
    when "press", "gc"
      # No rerender: isolates the toolkit's own pressed-state path.
    when "slow"
      LibTapLatencyProbe.usleep(1_000_000) # a synchronous network call or query on the main thread
      mount_screen
    else
      mount_screen
    end
    LibTapLatencyProbe.probe_mark(MARK_HEAP, GC.stats.heap_size.to_i64)
    LibTapLatencyProbe.probe_mark(MARK_ACTION_END, @@tap_count.to_i64)
  end

  # A resident model the size of a modest app cache (PROBE_RETAIN x 100 strings).
  def self.retain_resident_model : Nil
    SETTINGS.retained_record_count.times do |index|
      @@list_of_retained_records << Array(String).new(100) { |column| "record #{index}-#{column}" }
    end
  end

  # Background work that allocates (parsing, sync): its collections stop the main thread too.
  def self.start_background_allocation : Nil
    Fiber::ExecutionContext::Isolated.new("tap-latency-churn") do
      loop do
        scratch = Array(String).new(2_000) { |index| "churn #{index}" }
        LibTapLatencyProbe.usleep(2_000) if scratch.size > 0
      end
    end
  end

  def self.finish : Nil
    output_directory = SETTINGS.output_directory
    LibTapLatencyProbe.probe_dump(File.join(output_directory, "rows.txt").to_unsafe)
    stats = GC.prof_stats
    File.write(File.join(output_directory, "gc.txt"),
      "gc_no=#{stats.gc_no} heap=#{stats.heap_size} markers=#{stats.markers_m1 + 1} taps=#{@@tap_count}\n")
    exit(0)
  end

  def self.run : Nil
    LibGC.set_on_collection_event(->(event : LibGC::EventType) {
      LibTapLatencyProbe.probe_mark(MARK_GC_BASE + event.value, 0_i64)
    })
    retain_resident_model
    start_background_allocation if SETTINGS.runs_background_allocation?
    LibTapLatencyProbe.probe_create_window(520.0, 900.0)
    mount_screen
    watch_pixels = SETTINGS.watches_pressed_pixels? ? 1 : 0
    LibTapLatencyProbe.probe_start(SETTINGS.tap_count, SETTINGS.interval_ms, SETTINGS.hold_ms,
      watch_pixels, -> { TapLatencyProbe.finish })
    LibTapLatencyProbe.probe_run_app
  end
end

TapLatencyProbe.run
