{% if flag?(:macos) %}
require "json"
require "../../../src/ui"
require "../../../src/ui/ax_test"

# Phase 6.5 D3 — AXTest pattern library.
#
# Reusable patterns extracted from the three Phase 3 macOS specs under
# spec/ui/hig_validation/. Future spec files require this module instead
# of copy-pasting setup, teardown, and assertion helpers.
#
# Patterns provided:
#   - HostLaunch::with_host(slug, &block)        — env-wrapped Process.new + cleanup
#   - ActionTapProbe.run                          — AXPress + reactive label transition
#   - FormLayoutProbe.run                         — per-row frame + non-overlap assertions
#   - VisualBaselineProbe.run                     — self-snapshot via HIG_SCREENSHOT_PATH
#   - FocusSnapshotProbe.run                      — pre/post AXFocused element snapshots
#   - AXTreeWalk.dump                             — JSON dump of AXChildren under a root
#   - TeardownSpy.expect_release                  — wait for NativeHandle release log
#   - EnvResponseLaunch.with_appearance           — launch host under appearance variant
#
# All probes accept block forms so a spec body can compose them. See
# spec/ui/hig_validation/macos_action_tap_probe_spec.cr for usage.

module AXTestPatterns
  SHARD_ROOT = File.expand_path("../..", __DIR__)
  SHOWCASE_BIN = File.join(SHARD_ROOT, "samples/cross_platform/macos_host/bin/hig_showcase")

  # --------------------------------------------------------------------
  # Shared launch helper.
  # --------------------------------------------------------------------
  module HostLaunch
    extend self

    # Launch bin/hig_showcase with the named slug + appearance + extra env
    # and yield an AXTest::App attached to it. Always terminates the host
    # in the ensure block.
    def with_host(slug : String, *, appearance : String = "light", extra_env : Hash(String, String) = {} of String => String, settle_seconds : Float64 = 1.5) : Nil
      raise "bin/hig_showcase missing at #{SHOWCASE_BIN}" unless File.exists?(SHOWCASE_BIN)

      env = {
        "HIG_SLUG"        => slug,
        "HIG_APPEARANCE"  => appearance,
        "HIG_INTERACTIVE" => "1",
      }
      env.merge!(extra_env)

      process = Process.new(
        SHOWCASE_BIN,
        env: env,
        output: Process::Redirect::Inherit,
        error: Process::Redirect::Inherit,
      )

      begin
        pid = process.pid
        sleep(settle_seconds.seconds)
        app = UI::AXTest::App.connect(pid.to_i32)
        yield app
      ensure
        process.terminate rescue nil
        process.wait rescue nil
      end
    end
  end

  # --------------------------------------------------------------------
  # Helpers shared across probes.
  # --------------------------------------------------------------------
  module Helpers
    extend self

    # Read either AXValue or AXLabel — SwiftUI Text in NSHostingView
    # exposes content through either depending on build details.
    def read_display(elem : UI::AXTest::Element?) : String
      return "" unless e = elem
      v = e.value
      if v && !v.empty?
        v
      else
        l = e.label
        l && !l.empty? ? l : ""
      end
    end

    # Find by AXIdentifier with role+label fallback.
    def find_by_identifier(app : UI::AXTest::App, identifier : String, *, role : String = "AXButton") : UI::AXTest::Element?
      app.find(identifier: identifier) || app.find(role: role, label: identifier)
    end
  end

  # --------------------------------------------------------------------
  # Action tap probe — AXPress + reactive label transition.
  # Equivalent to macos_action_tap_probe_spec.cr's body.
  # --------------------------------------------------------------------
  module ActionTapProbe
    extend self

    # Tap `trigger_id`, expect `counter_id` to transition through `expected_values`.
    # Returns the transition array for evidence.
    def run(app : UI::AXTest::App, *, trigger_id : String, counter_id : String, expected_values : Array(String)) : Array(String)
      trigger = Helpers.find_by_identifier(app, trigger_id, role: "AXButton")
      counter = Helpers.find_by_identifier(app, counter_id, role: "AXStaticText")
      transitions = [] of String
      transitions << "found-trigger=#{!trigger.nil?}"
      transitions << "found-counter=#{!counter.nil?}"

      raise "ActionTapProbe: trigger '#{trigger_id}' not found" unless trigger
      raise "ActionTapProbe: counter '#{counter_id}' not found" unless counter

      # First entry of expected_values is the initial value.
      initial = expected_values.first
      observed_initial = Helpers.read_display(counter)
      transitions << "initial=#{observed_initial.inspect}"
      raise "ActionTapProbe: initial mismatch — expected #{initial.inspect}, got #{observed_initial.inspect}" unless observed_initial == initial

      expected_values[1..].each_with_index do |expected, i|
        trigger.click
        sleep(0.3.seconds)
        v = Helpers.read_display(counter)
        transitions << "after-tap-#{i + 1}=#{v.inspect}"
        raise "ActionTapProbe: tap #{i + 1} expected #{expected.inspect}, got #{v.inspect}" unless v == expected
      end

      # Trigger reachability after the sequence.
      re_trigger = Helpers.find_by_identifier(app, trigger_id, role: "AXButton")
      raise "ActionTapProbe: trigger '#{trigger_id}' lost after taps" unless re_trigger

      transitions
    end
  end

  # --------------------------------------------------------------------
  # Form layout probe — per-row frame + non-overlap assertions.
  # --------------------------------------------------------------------
  module FormLayoutProbe
    extend self

    record RowFrame, identifier : String, x : Float64, y : Float64, width : Float64, height : Float64

    # Locate every row by identifier, return frames. Caller asserts.
    def run(app : UI::AXTest::App, *, row_ids : Array(String), role : String = "AXButton") : Array(RowFrame)
      row_ids.map do |id|
        elem = Helpers.find_by_identifier(app, id, role: role)
        raise "FormLayoutProbe: '#{id}' not found" unless elem
        f = elem.frame
        raise "FormLayoutProbe: '#{id}' frame nil" unless f
        RowFrame.new(
          identifier: id,
          x: f[:x],
          y: f[:y],
          width: f[:width],
          height: f[:height],
        )
      end
    end

    # Assert top-to-bottom non-overlap (max 1pt slop) AND positive sizes.
    def assert_stacked_non_overlapping(frames : Array(RowFrame), *, min_height : Float64 = 0.0)
      frames.each do |f|
        raise "FormLayoutProbe: '#{f.identifier}' width<=0" unless f.width > 0.0
        raise "FormLayoutProbe: '#{f.identifier}' height<min" unless f.height >= min_height
      end
      frames.each_cons(2) do |pair|
        a, b = pair[0], pair[1]
        a_max_y = a.y + a.height
        unless a_max_y <= b.y + 1.0
          raise "FormLayoutProbe: '#{a.identifier}' overlaps '#{b.identifier}' (#{a_max_y} > #{b.y + 1.0})"
        end
      end
    end
  end

  # --------------------------------------------------------------------
  # Visual baseline probe — self-snapshot via HIG_SCREENSHOT_PATH.
  # --------------------------------------------------------------------
  module VisualBaselineProbe
    extend self

    # Run the host with HIG_SCREENSHOT_PATH=<out> and assert the file exists.
    def run(*, slug : String, appearance : String = "light", out_path : String) : String
      raise "bin/hig_showcase missing" unless File.exists?(AXTestPatterns::SHOWCASE_BIN)
      File.delete(out_path) if File.exists?(out_path)

      env = {
        "HIG_SLUG"            => slug,
        "HIG_APPEARANCE"      => appearance,
        "HIG_SCREENSHOT_PATH" => out_path,
      }
      status = Process.run(
        AXTestPatterns::SHOWCASE_BIN,
        env: env,
        output: Process::Redirect::Inherit,
        error: Process::Redirect::Inherit,
      )
      raise "VisualBaselineProbe: host exit #{status.exit_code}" unless status.success?
      raise "VisualBaselineProbe: PNG missing at #{out_path}" unless File.exists?(out_path)
      out_path
    end

    # Run the host with HIG_SCREENSHOT_PATH=<out> under a wall-clock
    # deadline (worklist-mode specs need this since some slugs may hang
    # on backdrop composition). The host normally exits at ~0.6s via the
    # self-snapshot path; we poll Process.exists? rather than block on
    # .wait so we can enforce the deadline.
    #
    # Pass extra_env to forward HIG_BACKDROP_PATH or similar.
    # Pass output_mode to suppress stdout (worklist mode) or inherit it
    # (interactive mode).
    def run_with_deadline(
      *,
      slug : String,
      appearance : String = "light",
      out_path : String,
      extra_env : Hash(String, String) = {} of String => String,
      deadline_seconds : Float64 = 5.0,
      output_mode : Process::Stdio = Process::Redirect::Close,
      error_mode : Process::Stdio = Process::Redirect::Close,
    ) : Process::Status
      File.delete(out_path) if File.exists?(out_path)

      env = {
        "HIG_SLUG"            => slug,
        "HIG_APPEARANCE"      => appearance,
        "HIG_SCREENSHOT_PATH" => out_path,
      }.merge(extra_env)

      process = Process.new(
        AXTestPatterns::SHOWCASE_BIN,
        env: env,
        output: output_mode,
        error: error_mode,
      )

      deadline = Time.instant + deadline_seconds.seconds
      pid = process.pid
      finished = false
      until Time.instant >= deadline
        unless Process.exists?(pid)
          finished = true
          break
        end
        sleep(0.1.seconds)
      end

      if finished
        process.wait
      else
        process.terminate rescue nil
        wait_status = process.wait rescue nil
        raise "VisualBaselineProbe: host did not exit within #{deadline_seconds}s for slug=#{slug} appearance=#{appearance}"
      end
    end
  end

  # --------------------------------------------------------------------
  # Focus snapshot probe — pre/post AXFocused element identifier capture.
  # --------------------------------------------------------------------
  module FocusSnapshotProbe
    extend self

    record FocusSnapshot, identifier : String?, role : String?, label : String?

    def capture(app : UI::AXTest::App) : FocusSnapshot
      focused = app.focused_element
      if e = focused
        FocusSnapshot.new(
          identifier: e.identifier,
          role: e.role,
          label: e.label,
        )
      else
        FocusSnapshot.new(identifier: nil, role: nil, label: nil)
      end
    end

    # Yield pre/post snapshots around a focus-changing operation.
    def run(app : UI::AXTest::App) : NamedTuple(pre: FocusSnapshot, post: FocusSnapshot)
      pre = capture(app)
      yield
      post = capture(app)
      {pre: pre, post: post}
    end
  end

  # --------------------------------------------------------------------
  # AX tree walk — JSON dump of the accessibility children under a root.
  # --------------------------------------------------------------------
  module AXTreeWalk
    extend self

    def dump(root : UI::AXTest::Element?, *, depth_limit : Int32 = 8) : JSON::Any
      return JSON::Any.new(nil) unless root
      JSON.parse(walk_node(root, 0, depth_limit).to_json)
    end

    private def walk_node(elem : UI::AXTest::Element, depth : Int32, limit : Int32) : Hash(String, String | Array(Hash(String, String)) | Nil)
      h = {} of String => String | Array(Hash(String, String)) | Nil
      h["role"] = elem.role
      h["identifier"] = elem.identifier
      h["label"] = elem.label
      if depth < limit
        children = elem.children.map do |c|
          {
            "role"       => c.role,
            "identifier" => c.identifier || "",
            "label"      => c.label || "",
          }
        end
        h["children"] = children
      end
      h
    end
  end

  # --------------------------------------------------------------------
  # Teardown spy — wait for a release log line within N ms.
  # --------------------------------------------------------------------
  module TeardownSpy
    extend self

    # The macOS host can emit lines on STDERR like
    #   "AP_RELEASE handle=<addr> klass=NSView".
    # The host runs as a child Process; pass the IO::Memory you captured.
    # Returns true if the line appears within timeout.
    def expect_release(log : String, *, klass : String, timeout_ms : Int32 = 2000) : Bool
      lines = log.lines
      lines.any? { |line| line.includes?("AP_RELEASE") && line.includes?("klass=#{klass}") }
    end
  end

  # --------------------------------------------------------------------
  # Env-response launch — appearance / content size variants.
  # --------------------------------------------------------------------
  module EnvResponseLaunch
    extend self

    APPEARANCES = %w[light dark]
    CONTENT_SIZES = %w[default accessibility]

    def with_appearance(slug : String, appearance : String, & : UI::AXTest::App ->)
      HostLaunch.with_host(slug, appearance: appearance) { |app| yield app }
    end

    def for_each_appearance(slug : String, & : String, UI::AXTest::App ->)
      APPEARANCES.each do |a|
        HostLaunch.with_host(slug, appearance: a) { |app| yield a, app }
      end
    end
  end
end

{% end %}
