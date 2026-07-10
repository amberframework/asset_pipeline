# Phase 6.5 D2 — Visual diff helper.
#
# Wraps `magick compare -metric AE` for the audit harness. Surfaces a
# structured Result that the harness can route through its standard
# pass/fail/skip emitter.
#
# Usage (library):
#   require "./visual_diff"
#   VisualDiff.compare(
#     baseline: "docs/.../baselines/macos/<slug>.png",
#     actual:   "/tmp/<slug>.png",
#     tolerance_path: "docs/.../baselines/macos/<slug>.tolerance.json",
#   )
#
# Usage (CLI):
#   crystal-alpha run scripts/visual_diff.cr -- \
#     --baseline docs/initiative-cross-platform-ui/baselines/macos/button.png \
#     --actual /tmp/button.png
#
# Each baseline carries an adjacent `<slug>.tolerance.json` of shape:
#   { "pixel_diff_max": 250, "channel_diff_max": 8 }
# Defaults (when no tolerance file): exact match (pixel_diff_max=0).
#
# Returns exit 0 on within-tolerance, 1 on out-of-tolerance, 3 on missing
# baseline or actual.

require "json"
require "option_parser"
require "file_utils"

module VisualDiff
  MAGICK_BIN = ENV["MAGICK_BIN"]? || "/opt/homebrew/bin/magick"

  record Tolerance,
    pixel_diff_max : Int64 = 0_i64,
    channel_diff_max : Int32 = 0 do
    def self.from_path(path : String) : Tolerance
      return Tolerance.new unless File.exists?(path)
      json = JSON.parse(File.read(path))
      Tolerance.new(
        pixel_diff_max: (json["pixel_diff_max"]?.try(&.as_i64?) || 0_i64),
        channel_diff_max: json["channel_diff_max"]?.try(&.as_i?) || 0,
      )
    end
  end

  record DiffResult,
    status : Symbol,   # :pass | :fail | :missing
    pixel_diff : Int64,
    tolerance : Tolerance,
    artifact : String?,
    message : String do
    def exit_code : Int32
      case status
      when :pass    then 0
      when :fail    then 1
      else 3
      end
    end
  end

  extend self

  def compare(baseline : String, actual : String, *, tolerance_path : String? = nil, diff_out : String? = nil) : DiffResult
    unless File.exists?(baseline)
      return DiffResult.new(
        status: :missing,
        pixel_diff: -1,
        tolerance: Tolerance.new,
        artifact: nil,
        message: "baseline missing: #{baseline}",
      )
    end
    unless File.exists?(actual)
      return DiffResult.new(
        status: :missing,
        pixel_diff: -1,
        tolerance: Tolerance.new,
        artifact: nil,
        message: "actual missing: #{actual}",
      )
    end

    resolved_tolerance_path = tolerance_path || infer_tolerance_path(baseline)
    tol = Tolerance.from_path(resolved_tolerance_path)

    diff_target = diff_out || default_diff_path(baseline, actual)
    Dir.mkdir_p(File.dirname(diff_target))

    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new

    # `magick compare -metric AE` writes the absolute-error pixel count to
    # stderr (because compare's stdout is image data). Exit code is 0 if
    # images match, 1 if they differ, 2 on error.
    status = Process.run(
      MAGICK_BIN,
      args: ["compare", "-metric", "AE", baseline, actual, diff_target],
      output: stdout_io,
      error: stderr_io,
    )

    stderr_str = stderr_io.to_s.strip
    # `magick compare -metric AE` writes one of:
    #   "0"                 (identical, older ImageMagick)
    #   "0 (0)"             (identical, newer ImageMagick — count + normalized)
    #   "8.64354e+09 (131892)"   leading is channel-diff sum (per pixel,
    #                            per channel, summed), parenthesized is the
    #                            actual count of differing PIXELS.
    # We always prefer the parenthesized pixel count when present, falling
    # back to the leading number for older ImageMagick output.
    pixels =
      if stderr_str =~ /\((\d+)\)\s*$/
        $1.to_i64
      elsif stderr_str =~ /^([-+0-9.eE]+)/
        val = $1.to_f
        val.nan? || val.infinite? ? -1_i64 : val.round.to_i64
      else
        -1_i64
      end

    if status.exit_code == 2 || pixels < 0
      return DiffResult.new(
        status: :fail,
        pixel_diff: pixels,
        tolerance: tol,
        artifact: nil,
        message: "magick compare errored: exit=#{status.exit_code} stderr=#{stderr_str}",
      )
    end

    if pixels <= tol.pixel_diff_max
      DiffResult.new(
        status: :pass,
        pixel_diff: pixels,
        tolerance: tol,
        artifact: diff_target,
        message: "within tolerance (#{pixels} <= #{tol.pixel_diff_max})",
      )
    else
      DiffResult.new(
        status: :fail,
        pixel_diff: pixels,
        tolerance: tol,
        artifact: diff_target,
        message: "out of tolerance (#{pixels} > #{tol.pixel_diff_max}); diff at #{diff_target}",
      )
    end
  end

  private def infer_tolerance_path(baseline : String) : String
    baseline.sub(/\.png$/i, ".tolerance.json")
  end

  private def default_diff_path(baseline : String, actual : String) : String
    base = File.basename(baseline, ".png")
    File.join(Dir.tempdir, "visual_diff_#{base}_#{Time.utc.to_unix_ms}.png")
  end
end

# CLI entry point. This file is only ever run as a script; the harness
# shells out via `crystal-alpha run scripts/visual_diff.cr -- ...`.

baseline = ""
actual = ""
tolerance_path : String? = nil
diff_out : String? = nil
fmt = "text"

OptionParser.parse(ARGV) do |opts|
  opts.banner = "Usage: crystal-alpha run scripts/visual_diff.cr -- [opts]"
  opts.on("--baseline PATH", "Baseline PNG") { |v| baseline = v }
  opts.on("--actual PATH", "Actual PNG to diff") { |v| actual = v }
  opts.on("--tolerance PATH", "Tolerance JSON path") { |v| tolerance_path = v }
  opts.on("--out PATH", "Diff output PNG") { |v| diff_out = v }
  opts.on("--format FMT", "text|json") { |v| fmt = v }
  opts.on("-h", "--help", "Show help") { puts opts; exit 0 }
end

if baseline.empty? || actual.empty?
  STDERR.puts "visual_diff: --baseline and --actual are required"
  exit 3
end

result = VisualDiff.compare(baseline, actual, tolerance_path: tolerance_path, diff_out: diff_out)
if fmt == "json"
  puts({
    "status"     => result.status.to_s,
    "pixel_diff" => result.pixel_diff,
    "tolerance"  => {
      "pixel_diff_max"   => result.tolerance.pixel_diff_max,
      "channel_diff_max" => result.tolerance.channel_diff_max,
    },
    "artifact"   => result.artifact,
    "message"    => result.message,
  }.to_json)
else
  puts "[#{result.status.to_s.upcase}] pixel_diff=#{result.pixel_diff} max=#{result.tolerance.pixel_diff_max}"
  puts "  #{result.message}"
  puts "  diff: #{result.artifact}" if result.artifact
end
exit result.exit_code
