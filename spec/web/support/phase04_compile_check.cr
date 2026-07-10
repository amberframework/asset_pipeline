# Shared compile-time-error spec helper for Phase 4 Tier 3 gates.
#
# Each compile-error spec writes a Crystal source snippet to a uniquely
# named tempfile under `<repo>/tmp/compile-check/`, then invokes
# `crystal build --no-codegen <path>` as a subprocess and asserts against
# the combined stdout+stderr. Tempfiles live inside the repo so Crystal's
# relative-require resolution (`require "../../../src/ui"`) works.
#
# The counter is an Atomic(Int32) so parallel spec runners cannot collide
# on tempfile paths. Tempfiles are deleted in an ensure block; a failed
# example never leaves litter under tmp/compile-check/.

module Phase04CompileCheck
  PROJECT_ROOT = File.expand_path("../../..", __DIR__)
  TEMP_DIR     = File.join(PROJECT_ROOT, "tmp", "compile-check")

  @@counter = Atomic(Int32).new(0)

  def self.next_id : Int32
    @@counter.add(1)
  end

  def self.write_source(snippet : String) : String
    Dir.mkdir_p(TEMP_DIR) unless Dir.exists?(TEMP_DIR)
    path = File.join(TEMP_DIR,
      "asset-pipeline-compile-check-#{Process.pid}-#{next_id}.cr")
    File.write(path, snippet)
    path
  end

  def self.run(snippet : String, flags : Array(String) = [] of String) : {Process::Status, String}
    path = write_source(snippet)
    combined = IO::Memory.new
    begin
      status = Process.run(
        "crystal",
        ["build", "--no-codegen"] + flags + [path],
        output: combined,
        error: combined,
      )
      {status, combined.to_s}
    ensure
      File.delete(path) if File.exists?(path)
    end
  end
end
