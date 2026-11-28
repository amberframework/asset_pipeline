# Reads one tap-latency probe run (`rows.txt`) and derives, per tap, the
# pressed-state commit, the action start, the first visible change and the
# final view, plus every main-thread stall over 16 ms with its cause and the
# garbage-collection pauses. Method: README.md beside this file.
#
# Library use:  TapLatencyAnalysis.new(out_dir, label).summary
# Standalone:   /usr/bin/ruby tap_latency_analysis.rb OUT_DIR [label]
require "json"

class TapLatencyAnalysis
  # Row kinds, shared with tap_latency_probe_helper.m and tap_latency_probe.cr.
  ITER_START = 1
  ITER_END = 2
  VSYNC = 3
  MOUSE_DOWN_POSTED = 10
  MOUSE_DOWN_DISPATCHED = 11
  MOUSE_UP_POSTED = 12
  MOUSE_UP_DISPATCHED = 13
  PRESS_PIXELS = 14
  ACTION_START = 20
  ACTION_END = 21
  RENDER_START = 22
  RENDER_END = 23
  GC_START = 30
  GC_END = 35

  STALL_NS = 16_000_000
  FRAME_BUDGET_MS = 16.0

  attr_reader :out_dir, :label

  def initialize(out_dir, label = File.basename(out_dir))
    @out_dir = out_dir
    @label = label
    rows = File.readlines(File.join(out_dir, "rows.txt")).map { |line| line.split.map(&:to_i) }
    rows.sort_by! { |row| row[1] }
    @times_by_kind = Hash.new { |hash, kind| hash[kind] = [] }
    rows.each { |kind, time, _value| @times_by_kind[kind] << time }
  end

  def summary
    @summary ||= build_summary
  end

  def list_of_taps
    @list_of_taps ||= build_taps
  end

  def list_of_stalls
    @list_of_stalls ||= build_stalls
  end

  def write_files
    File.write(File.join(out_dir, "summary.json"), JSON.pretty_generate(summary))
    File.write(File.join(out_dir, "taps.json"), JSON.pretty_generate(list_of_taps))
    File.write(File.join(out_dir, "stalls.json"), JSON.pretty_generate(list_of_stalls))
  end

  def self.ms(ns)
    (ns / 1e6).round(2)
  end

  # p50 / p95 / max with the nearest-rank method.
  def self.stat(values)
    values = values.compact.sort
    return {} if values.empty?
    rank = ->(fraction) { values[[(values.size * fraction).ceil - 1, 0].max] }
    { "n" => values.size, "p50" => rank.(0.5), "p95" => rank.(0.95), "max" => values.last }
  end

  private

  def times(kind)
    @times_by_kind[kind]
  end

  def first_after(kind, time)
    times(kind).bsearch { |candidate| candidate >= time }
  end

  def ms(ns)
    self.class.ms(ns)
  end

  def collections
    @collections ||= times(GC_START).map do |start|
      finish = first_after(GC_END, start)
      [start, finish] if finish
    end.compact
  end

  def renders
    @renders ||= times(RENDER_START).zip(times(RENDER_END)).select { |start, finish| start && finish && finish >= start }
  end

  def actions
    @actions ||= times(ACTION_START).zip(times(ACTION_END)).select { |start, finish| start && finish && finish >= start }
  end

  def build_taps
    times(MOUSE_DOWN_POSTED).each_with_index.map do |down_posted, index|
      down_dispatched = first_after(MOUSE_DOWN_DISPATCHED, down_posted) or next
      up_posted = first_after(MOUSE_UP_POSTED, down_posted) or next
      up_dispatched = first_after(MOUSE_UP_DISPATCHED, up_posted) or next
      action = actions.find { |start, _| start >= up_dispatched } or next
      press_commit = first_after(ITER_END, down_dispatched)
      press_pixels = times(PRESS_PIXELS).find { |time| time >= down_dispatched && time < up_posted + 50_000_000 }
      render_after = first_after(RENDER_END, action[0])
      next_down = times(MOUSE_DOWN_POSTED).find { |time| time > down_posted }
      render_after = nil if render_after && next_down && render_after > next_down
      final_commit = first_after(ITER_END, [render_after || action[1], action[1]].max)
      first_commit = first_after(ITER_END, action[0])
      first_vsync = first_commit && first_after(VSYNC, first_commit)
      final_vsync = final_commit && first_after(VSYNC, final_commit)
      press_vsync = press_commit && first_after(VSYNC, press_commit)
      {
        "tap" => index + 1,
        "input_queue_ms" => ms(down_dispatched - down_posted),
        "press_commit_from_dispatch_ms" => press_commit && ms(press_commit - down_dispatched),
        "press_glass_from_dispatch_ms" => press_vsync && ms(press_vsync - down_dispatched),
        "press_pixels_from_dispatch_ms" => press_pixels && ms(press_pixels - down_dispatched),
        "mouseup_queue_ms" => ms(up_dispatched - up_posted),
        "action_start_after_up_ms" => ms(action[0] - up_posted),
        "action_ms" => ms(action[1] - action[0]),
        "first_change_after_up_ms" => first_vsync && ms(first_vsync - up_posted),
        "final_view_after_up_ms" => final_vsync && ms(final_vsync - up_posted),
      }
    end.compact
  end

  # A stall is a main run-loop pass over 16 ms, split by overlap into
  # collection, render (the asset_pipeline rebuild), synchronous action work,
  # and other (AppKit/SwiftUI layout and commit).
  def build_stalls
    times(ITER_START).map do |start|
      finish = first_after(ITER_END, start) or next
      duration = finish - start
      next unless duration > STALL_NS
      overlap = ->(pairs) { pairs.sum { |span_start, span_finish| [[finish, span_finish].min - [start, span_start].max, 0].max } }
      collection = overlap.(collections)
      render = overlap.(renders)
      action = overlap.(actions)
      sync_work = [action - render - collection, 0].max
      render_only = [render - collection, 0].max
      other = [duration - collection - render_only - sync_work, 0].max
      { "ms" => ms(duration), "gc_ms" => ms(collection), "render_ms" => ms(render_only),
        "sync_work_ms" => ms(sync_work), "other_ms" => ms(other) }
    end.compact
  end

  def dropped_frames
    gaps = times(VSYNC).each_cons(2).map { |earlier_tick, later_tick| later_tick - earlier_tick }
    frame = gaps.empty? ? 16_666_667 : gaps.sort[gaps.size / 2]
    [ms(frame), gaps.sum { |gap| gap > frame * 1.5 ? (gap.to_f / frame).round - 1 : 0 }]
  end

  def build_summary
    taps = list_of_taps
    stalls = list_of_stalls
    frame_ms, dropped = dropped_frames
    pick = ->(key) { taps.map { |tap| tap[key] } }
    within_budget = ->(key) { taps.count { |tap| (tap[key] || Float::INFINITY) <= FRAME_BUDGET_MS } }
    pressed_within = within_budget.("press_commit_from_dispatch_ms")
    {
      "label" => label,
      "taps" => taps.size,
      "frame_interval_ms" => frame_ms,
      "input_queue_ms" => self.class.stat(pick.("input_queue_ms")),
      "press_commit_from_dispatch_ms" => self.class.stat(pick.("press_commit_from_dispatch_ms")),
      "press_glass_from_dispatch_ms" => self.class.stat(pick.("press_glass_from_dispatch_ms")),
      "press_pixels_from_dispatch_ms" => self.class.stat(pick.("press_pixels_from_dispatch_ms")),
      "pressed_commit_within_16ms_taps" => pressed_within,
      "pressed_within_16ms_percent" => taps.empty? ? 0.0 : (100.0 * pressed_within / taps.size).round(1),
      "pressed_on_glass_within_16ms_taps" => within_budget.("press_glass_from_dispatch_ms"),
      "action_start_after_up_ms" => self.class.stat(pick.("action_start_after_up_ms")),
      "action_ms" => self.class.stat(pick.("action_ms")),
      "first_change_after_up_ms" => self.class.stat(pick.("first_change_after_up_ms")),
      "final_view_after_up_ms" => self.class.stat(pick.("final_view_after_up_ms")),
      "render_ms" => self.class.stat(renders.map { |start, finish| ms(finish - start) }),
      "stall_count" => stalls.size,
      "stall_ms" => self.class.stat(stalls.map { |stall| stall["ms"] }),
      "stall_p95_ms" => self.class.stat(stalls.map { |stall| stall["ms"] }).fetch("p95", 0.0),
      "longest_stall_ms" => stalls.map { |stall| stall["ms"] }.max || 0.0,
      "stall_cause_totals_ms" => %w[gc_ms render_ms sync_work_ms other_ms].to_h { |key| [key, stalls.sum { |stall| stall[key] }.round(1)] },
      "gc_collections" => collections.size,
      "gc_pause_ms" => self.class.stat(collections.map { |start, finish| ms(finish - start) }),
      "collection_pause_p95_ms" => self.class.stat(collections.map { |start, finish| ms(finish - start) }).fetch("p95", 0.0),
      "dropped_frames" => dropped,
    }
  end
end

if $PROGRAM_NAME == __FILE__
  dir = ARGV[0] or abort "usage: tap_latency_analysis.rb OUT_DIR [label]"
  analysis = TapLatencyAnalysis.new(dir, ARGV[1] || File.basename(dir))
  analysis.write_files
  puts JSON.generate(analysis.summary)
end
