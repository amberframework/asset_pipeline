# Runs the macOS tap-latency lane on our own Mac and reports the result to
# GitHub as a commit status, for every pull request branch and every push to
# main that touches the native UI.
#
# Why not a GitHub Actions runner: the repository is public, and a
# self-hosted runner on a public repository would run workflows edited in a
# fork pull request on our Mac. This check only tests branches of the
# repository itself (pushing one already needs write access), from a copy of
# this script deployed from main, and it needs the Mac's logged-in GUI
# session, which a LaunchAgent in that session has.
#
#   /usr/bin/ruby check_tap_latency_for_open_branches.rb [--repo OWNER/REPO]
#     [--work DIR] [--host LABEL]
#
# Install: copy this file from main to ~/build/tap-latency-ci/ on the Mac and
# load scripts/consulting.agentc.tap-latency-check.plist as a LaunchAgent of
# the user who owns the logged-in GUI session.
#
# Each pass (launchd starts one every 5 minutes; a lock keeps passes from
# overlapping) lists the open pull requests and the head of main, skips any
# commit that already has the status, any fork branch, and any commit that
# does not touch the native UI, then runs `make test-latency-macos` at that
# commit and posts `tap-latency (<host>)`: pending, then success or failure
# with the lane's verdict line. On a pull request it also comments the two
# tables. Logs stay in WORK/logs for 14 days.
require "json"
require "open3"
require "optparse"
require "fileutils"
require "time"

class CheckTapLatencyForOpenBranches
  NATIVE_UI_PATHS = %w[src/ui/ swift/ spec/native_macos/latency/ Makefile .github/workflows/tap-latency-macos.yml].freeze
  LOG_RETENTION_SECONDS = 14 * 24 * 3600
  STALE_PENDING_SECONDS = 2 * 3600

  def initialize(argv)
    @repo = "amberframework/asset_pipeline"
    @work_dir = File.expand_path("~/build/tap-latency-ci")
    @host_label = "m4-mini-01"
    OptionParser.new do |options|
      options.on("--repo OWNER/REPO") { |repo| @repo = repo }
      options.on("--work DIR") { |dir| @work_dir = File.expand_path(dir) }
      options.on("--host LABEL") { |label| @host_label = label }
    end.parse!(argv)
    @context = "tap-latency (#{@host_label}, our runner)"
    @checkout_dir = File.join(@work_dir, "checkout")
    @log_dir = File.join(@work_dir, "logs")
  end

  def perform
    FileUtils.mkdir_p(@log_dir)
    File.open(File.join(@work_dir, "pass.lock"), File::RDWR | File::CREAT) do |lock|
      return 0 unless lock.flock(File::LOCK_EX | File::LOCK_NB)
      remove_old_logs
      list_of_candidates.each { |candidate| check(candidate) }
    end
    0
  rescue StandardError => error
    log("pass failed: #{error.class}: #{error.message}")
    1
  end

  private

  def gh(*args)
    output, error, status = Open3.capture3("gh", *args)
    raise "gh #{args.first(3).join(" ")} failed: #{error.strip}" unless status.success?
    output
  end

  def log(message)
    File.open(File.join(@log_dir, "status_check.log"), "a") { |file| file.puts("#{Time.now.utc.iso8601} #{message}") }
  end

  def remove_old_logs
    Dir.glob(File.join(@log_dir, "*.lane.log")).each do |path|
      File.delete(path) if Time.now - File.mtime(path) > LOG_RETENTION_SECONDS
    end
  end

  # Open same-repository pull requests, then the head of main.
  def list_of_candidates
    owner = @repo.split("/").first
    pulls = JSON.parse(gh("pr", "list", "-R", @repo, "--state", "open", "--limit", "50",
      "--json", "number,headRefOid,headRepositoryOwner,isCrossRepository"))
    candidates = pulls.reject { |pull| pull["isCrossRepository"] || pull.dig("headRepositoryOwner", "login") != owner }
      .map { |pull| { sha: pull["headRefOid"], pull_number: pull["number"] } }
    main_sha = gh("api", "repos/#{@repo}/commits/main", "--jq", ".sha").strip
    candidates << { sha: main_sha, pull_number: nil }
  end

  # A commit is done once it has this status, unless the only report is a
  # pending one left by a pass that died (older than two hours).
  def already_reported?(sha)
    statuses = JSON.parse(gh("api", "repos/#{@repo}/commits/#{sha}/statuses"))
    latest = statuses.find { |status| status["context"] == @context } # newest first
    return false unless latest
    return true unless latest["state"] == "pending"
    Time.now - Time.parse(latest["created_at"]) < STALE_PENDING_SECONDS
  end

  def list_of_changed_paths(candidate)
    if candidate[:pull_number]
      JSON.parse(gh("pr", "view", candidate[:pull_number].to_s, "-R", @repo, "--json", "files"))
        .fetch("files").map { |file| file["path"] }
    else
      JSON.parse(gh("api", "repos/#{@repo}/commits/#{candidate[:sha]}")).fetch("files", []).map { |file| file["filename"] }
    end
  end

  def touches_native_ui?(candidate)
    list_of_changed_paths(candidate).any? do |path|
      NATIVE_UI_PATHS.any? { |prefix| prefix.end_with?("/") ? path.start_with?(prefix) : path == prefix }
    end
  end

  def post_status(sha, state, description)
    gh("api", "repos/#{@repo}/statuses/#{sha}", "-f", "state=#{state}", "-f", "context=#{@context}",
      "-f", "description=#{description[0, 140]}")
  end

  def check(candidate)
    sha = candidate[:sha]
    return if already_reported?(sha)
    return unless touches_native_ui?(candidate)
    post_status(sha, "pending", "Running make test-latency-macos")
    log("testing #{sha} (pull #{candidate[:pull_number].inspect})")
    passed, verdict, tables = run_lane(sha)
    post_status(sha, passed ? "success" : "failure", verdict)
    comment_tables(candidate[:pull_number], sha, verdict, tables) if candidate[:pull_number]
    log("#{sha}: #{verdict}")
  end

  def prepare_checkout(sha)
    unless Dir.exist?(File.join(@checkout_dir, ".git"))
      system("git", "clone", "--quiet", "https://github.com/#{@repo}.git", @checkout_dir, exception: true)
    end
    system("git", "-C", @checkout_dir, "fetch", "--quiet", "origin", sha, exception: true)
    system("git", "-C", @checkout_dir, "checkout", "--quiet", "--force", "--detach", sha, exception: true)
    system("git", "-C", @checkout_dir, "clean", "--quiet", "-fdx", "-e", "swift/AssetPipelineSwiftKit/.build", exception: true)
  end

  # Runs the lane through cluster-pool so the run is accounted on this Mac.
  def run_lane(sha)
    prepare_checkout(sha)
    log_path = File.join(@log_dir, "#{sha}.lane.log")
    command = ["cluster-pool", "dispatch", "--on", @host_label, "--no-copy", "--label", "tap-latency #{sha[0, 8]}",
               "--cores", "4", "--ram", "4", "--storage", "3", "--time", "45m", "--wait", "1h", "--",
               "make", "-C", @checkout_dir, "test-latency-macos", "LATENCY_OUT=#{File.join(@work_dir, "runs", sha)}"]
    output, status = Open3.capture2e({ "LATENCY_SOURCE_COMMIT" => sha }, *command, chdir: @checkout_dir)
    File.write(log_path, output)
    verdict = output.lines.reverse.find { |line| line.start_with?("tap-latency lane:") }.to_s.strip
    verdict = "the lane did not finish; see #{log_path} on #{@host_label}" if verdict.empty?
    tables = output.lines.select { |line| line.start_with?("|") || line.start_with?("gate crossed:", "notice:") }.join
    [status.success?, verdict, tables]
  end

  def comment_tables(pull_number, sha, verdict, tables)
    body = "**#{@context}** at #{sha[0, 12]}: #{verdict}\n\n<details><summary>Measurements and gates</summary>\n\n#{tables}\n</details>\n"
    gh("pr", "comment", pull_number.to_s, "-R", @repo, "--body", body)
  end
end

exit(CheckTapLatencyForOpenBranches.new(ARGV).perform)
