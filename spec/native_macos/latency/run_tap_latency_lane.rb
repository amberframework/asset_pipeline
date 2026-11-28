# Runs the macOS tap-latency lane: every row in thresholds.yml as one probe
# run, then prints the measurements table and the gate table, and exits
# nonzero when a gate is crossed. `make test-latency-macos` builds the probe
# and calls this script; see README.md beside it.
#
#   /usr/bin/ruby run_tap_latency_lane.rb --probe PATH --out DIR [options]
#     --only ROW[,ROW]     run only these rows
#     --record-baseline    write baseline.json from this run (no gating)
#     --baseline PATH      compare against this baseline (default: beside this file)
require "json"
require "yaml"
require "optparse"
require "fileutils"
require "time"
require_relative "tap_latency_analysis"

class RunTapLatencyLane
  LANE_DIR = File.expand_path(__dir__)
  EXIT_GATE_CROSSED = 1
  EXIT_PROBE_FAILED = 2

  GATE_LABELS = {
    "pressed_within_16ms_percent" => "pressed look within 16 ms (% of taps)",
    "stall_count" => "main-thread stalls over 16 ms",
    "stall_p95_ms" => "main-thread stall length, p95 (ms)",
    "collection_pause_p95_ms" => "collection pause, p95 (ms)",
  }.freeze

  def initialize(argv)
    @probe_path = nil
    @out_dir = File.join(Dir.pwd, "build", "latency-macos", Time.now.utc.strftime("%Y%m%dT%H%M%SZ"))
    @list_of_selected_rows = nil
    @records_baseline = false
    @baseline_path = File.join(LANE_DIR, "baseline.json")
    OptionParser.new do |options|
      options.on("--probe PATH") { |path| @probe_path = File.expand_path(path) }
      options.on("--out DIR") { |dir| @out_dir = File.expand_path(dir) }
      options.on("--only ROWS") { |rows| @list_of_selected_rows = rows.split(",") }
      options.on("--record-baseline") { @records_baseline = true }
      options.on("--baseline PATH") { |path| @baseline_path = File.expand_path(path) }
    end.parse!(argv)
    abort "run_tap_latency_lane.rb: --probe PATH is required" unless @probe_path && File.executable?(@probe_path)
    @thresholds = YAML.safe_load(File.read(File.join(LANE_DIR, "thresholds.yml")))
  end

  def perform
    FileUtils.mkdir_p(@out_dir)
    rows = @thresholds.fetch("rows")
    rows = rows.select { |name, _| @list_of_selected_rows.include?(name) } if @list_of_selected_rows
    summaries = {}
    probe_failures = []
    rows.each do |name, row|
      summary, failure = run_row(name, row)
      summaries[name] = summary if summary
      probe_failures << failure if failure
    end

    puts
    puts measurements_table(rows, summaries)
    puts
    File.write(File.join(@out_dir, "lane_summary.json"), JSON.pretty_generate(summaries))
    # What --record-baseline would write, kept with every run so a new runner
    # image can be baselined from a CI artifact.
    write_baseline(summaries, File.join(@out_dir, "candidate_baseline.json")) if probe_failures.empty?

    if @records_baseline
      abort_with(EXIT_PROBE_FAILED, probe_failures) unless probe_failures.empty?
      write_baseline(summaries, @baseline_path)
      puts "Baseline written to #{@baseline_path}"
      return 0
    end

    results = evaluate_gates(rows, summaries)
    puts gate_table(results)
    puts
    crossed = results.select { |result| result[:status] == "FAIL" }
    notices = results.select { |result| result[:status] == "NOW PASSES" }
    notices.each do |result|
      puts "notice: #{result[:row]} / #{result[:gate]} now passes; remove it from known_failures in thresholds.yml"
    end
    unless probe_failures.empty?
      abort_with(EXIT_PROBE_FAILED, probe_failures)
    end
    if crossed.empty?
      puts "tap-latency lane: PASS (#{results.size} gates; #{results.count { |result| result[:status] == "KNOWN FAIL" }} known failures held at baseline)"
      0
    else
      crossed.each do |result|
        puts "gate crossed: #{result[:row]} / #{result[:gate]}: measured #{format_value(result[:measured])}, #{result[:reason]}"
      end
      puts "tap-latency lane: FAIL (#{crossed.size} of #{results.size} gates crossed)"
      EXIT_GATE_CROSSED
    end
  end

  private

  def abort_with(code, failures)
    failures.each { |failure| puts "probe failed: #{failure}" }
    puts "tap-latency lane: FAIL (probe did not finish)"
    exit(code)
  end

  def probe_environment(row, row_out_dir)
    probe = row.fetch("probe")
    {
      "PROBE_SCENARIO" => probe.fetch("scenario"),
      "PROBE_ROWS" => probe.fetch("rows").to_s,
      "PROBE_TAPS" => probe.fetch("taps").to_s,
      "PROBE_INTERVAL_MS" => probe.fetch("interval_ms").to_s,
      "PROBE_RETAIN" => probe.fetch("retain", 0).to_s,
      "PROBE_OUT" => row_out_dir,
    }
  end

  # Runs one probe under a deadline; a hung probe is sampled, then killed.
  def run_row(name, row)
    row_out_dir = File.join(@out_dir, name)
    FileUtils.mkdir_p(row_out_dir)
    env = probe_environment(row, row_out_dir)
    budget = env["PROBE_TAPS"].to_i * env["PROBE_INTERVAL_MS"].to_f / 1000 + 45
    started = Time.now
    pid = Process.spawn(env, @probe_path, out: File.join(row_out_dir, "stdout.txt"), err: File.join(row_out_dir, "stderr.txt"))
    status = wait_for(pid, started + budget)
    unless status
      system("/usr/bin/sample", pid.to_s, "2", "-file", File.join(row_out_dir, "hang_sample.txt"), out: File::NULL, err: File::NULL)
      stop_process(pid)
      puts format("%-16s killed after %.0f s (hang sample in %s)", name, budget, row_out_dir)
      return [nil, "#{name}: no exit within #{budget.round} s"]
    end
    unless status.success? && File.exist?(File.join(row_out_dir, "rows.txt"))
      puts format("%-16s exit %s", name, status.exitstatus.inspect)
      return [nil, "#{name}: exit #{status.exitstatus.inspect}, see #{row_out_dir}/stderr.txt"]
    end
    analysis = TapLatencyAnalysis.new(row_out_dir, name)
    analysis.write_files
    puts format("%-16s %3d taps in %.1f s", name, analysis.summary["taps"], Time.now - started)
    [analysis.summary, nil]
  end

  def stop_process(pid)
    Process.kill("KILL", pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  end

  def wait_for(pid, deadline)
    while Time.now < deadline
      _, status = Process.wait2(pid, Process::WNOHANG)
      return status if status
      sleep 0.25
    end
    nil
  end

  def triple(stat)
    return "n/a" if stat.nil? || stat.empty?
    [stat["p50"], stat["p95"], stat["max"]].map { |value| format_value(value) }.join(" / ")
  end

  def format_value(value)
    return "n/a" if value.nil?
    return value.to_s if value.is_a?(Integer)
    value >= 100 ? value.round.to_s : format("%.1f", value)
  end

  # The MEASUREMENTS.md table: times in ms, p50 / p95 / max.
  def measurements_table(rows, summaries)
    header = ["Row (taps)", "Click waits for the app", "Pressed commit after click arrives", "Pressed within 16 ms", "Pressed on glass within 16 ms",
              "Action start after mouse-up", "First visible change after mouse-up", "Final view after mouse-up",
              "Main-thread stalls > 16 ms (count; p50 / p95 / max)", "Collections (count; pause p50 / p95 / max)", "Dropped frames"]
    lines = ["| #{header.join(" | ")} |", "|#{header.map { "---" }.join("|")}|"]
    rows.each do |name, row|
      summary = summaries[name]
      unless summary
        lines << "| #{name}: #{row["description"]} | #{(["probe did not finish"] * (header.size - 1)).join(" | ")} |"
        next
      end
      taps = summary["taps"]
      stall = summary["stall_ms"]
      stall_text = stall.empty? ? "0" : "#{summary["stall_count"]}; #{triple(stall)}"
      pause = summary["gc_pause_ms"]
      gc_text = pause.empty? ? "0" : "#{summary["gc_collections"]}; #{triple(pause)}"
      lines << "| #{name}: #{row["description"]} (#{taps}) | #{triple(summary["input_queue_ms"])} | #{triple(summary["press_commit_from_dispatch_ms"])} | " \
               "#{summary["pressed_commit_within_16ms_taps"]} of #{taps} | #{summary["pressed_on_glass_within_16ms_taps"]} of #{taps} | " \
               "#{triple(summary["action_start_after_up_ms"])} | #{triple(summary["first_change_after_up_ms"])} | " \
               "#{triple(summary["final_view_after_up_ms"])} | #{stall_text} | #{gc_text} | #{summary["dropped_frames"]} |"
    end
    lines.join("\n")
  end

  def baseline
    @baseline ||= File.exist?(@baseline_path) ? JSON.parse(File.read(@baseline_path)) : { "rows" => {} }
  end

  def evaluate_gates(rows, summaries)
    gates = @thresholds.fetch("gates")
    tolerances = @thresholds.fetch("tolerance")
    rows.flat_map do |name, row|
      summary = summaries[name] or next []
      known_failures = row.fetch("known_failures", [])
      gates.map do |metric, rule|
        measured = summary.fetch(metric)
        higher_is_better = rule.key?("at_least")
        limit = higher_is_better ? rule["at_least"] : rule["at_most"]
        passes = higher_is_better ? measured >= limit : measured <= limit
        result = { row: name, gate: metric, limit: limit, measured: measured, higher_is_better: higher_is_better }
        if known_failures.include?(metric)
          baseline_value = baseline.dig("rows", name, metric)
          if baseline_value.nil?
            result.merge(status: "FAIL", reason: "known failure has no baseline value in baseline.json")
          elsif passes
            result.merge(status: "NOW PASSES", baseline: baseline_value)
          else
            tolerance = tolerances.fetch(metric)
            slack = [baseline_value.abs * tolerance.fetch("relative"), tolerance.fetch("absolute")].max
            ceiling = higher_is_better ? baseline_value - slack : baseline_value + slack
            regressed = higher_is_better ? measured < ceiling : measured > ceiling
            result.merge(status: regressed ? "FAIL" : "KNOWN FAIL", baseline: baseline_value, ceiling: ceiling,
                         reason: "worse than the baseline #{format_value(baseline_value)} (allowed #{higher_is_better ? ">=" : "<="} #{format_value(ceiling.round(2))})")
          end
        else
          result.merge(status: passes ? "PASS" : "FAIL",
                       reason: "gate is #{higher_is_better ? ">=" : "<="} #{format_value(limit)}")
        end
      end
    end
  end

  def gate_table(results)
    header = ["Row", "Gate", "Limit", "Measured", "Baseline", "Allowed while known", "Status"]
    lines = ["| #{header.join(" | ")} |", "|#{header.map { "---" }.join("|")}|"]
    results.each do |result|
      comparison = result[:higher_is_better] ? ">=" : "<="
      lines << "| #{result[:row]} | #{GATE_LABELS.fetch(result[:gate], result[:gate])} | #{comparison} #{format_value(result[:limit])} | " \
               "#{format_value(result[:measured])} | #{format_value(result[:baseline])} | " \
               "#{result[:ceiling] ? "#{comparison} #{format_value(result[:ceiling].round(2))}" : ""} | #{result[:status]} |"
    end
    lines.join("\n")
  end

  def command_output(*command)
    IO.popen(command, err: File::NULL, &:read).to_s.strip
  rescue SystemCallError
    ""
  end

  def machine_description
    memory_gb = command_output("/usr/sbin/sysctl", "-n", "hw.memsize").to_i / (1024**3)
    {
      "model" => command_output("/usr/sbin/sysctl", "-n", "hw.model"),
      "chip" => command_output("/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string"),
      "cores" => command_output("/usr/sbin/sysctl", "-n", "hw.ncpu").to_i,
      "memory_gb" => memory_gb,
      "macos" => "#{command_output("/usr/bin/sw_vers", "-productVersion")} (#{command_output("/usr/bin/sw_vers", "-buildVersion")})",
    }
  end

  def write_baseline(summaries, path)
    compiler = ENV.fetch("LATENCY_CRYSTAL", "crystal-alpha")
    gate_metrics = @thresholds.fetch("gates").keys
    document = {
      "recorded_on" => Time.now.utc.iso8601,
      "machine" => machine_description,
      "compiler" => command_output(compiler, "--version").lines.first.to_s.strip,
      "compiler_package" => command_output("/opt/homebrew/bin/brew", "list", "--versions", "agent-crystal"),
      "asset_pipeline_commit" => ENV.fetch("LATENCY_SOURCE_COMMIT") { command_output("git", "-C", LANE_DIR, "rev-parse", "HEAD") },
      "note" => "Recorded by `make record-latency-baseline-macos`. Gate values per row; full summaries in lane_summary.json of the recording run.",
      "rows" => summaries.map { |name, summary| [name, summary.select { |key, _| gate_metrics.include?(key) }] }.to_h,
    }
    File.write(path, JSON.pretty_generate(document) + "\n")
  end
end

exit(RunTapLatencyLane.new(ARGV).perform)
