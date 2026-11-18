#!/usr/bin/ruby
# Checks that `require "asset_pipeline"` keeps applications free of PCRE2.
#
# It builds spec/web/linkage/default_require_probe.cr (everything the default
# require loads, exercised) and spec/web/linkage/regex_control_probe.cr (the same
# plus one Regex), runs both, and checks that:
#
#   * the default-require probe links no libpcre2 and carries no pcre2_ symbols;
#   * the control probe shows PCRE2, which proves the check can fail;
#   * the default require loads no UI, components, CSS engine, generator, or
#     lint-rule file (those stay behind their own requires).
#
#   /usr/bin/ruby scripts/check_default_require_linkage.rb
#
# CRYSTAL selects the compiler (default: crystal-alpha).

require "open3"
require "tmpdir"

repo_root = File.expand_path("..", __dir__)
crystal = ENV.fetch("CRYSTAL", "crystal-alpha")
dynamic_libraries_command = RUBY_PLATFORM.include?("darwin") ? %w[otool -L] : %w[ldd]

def run!(*command)
  output, status = Open3.capture2e(*command)
  abort "command failed: #{command.join(" ")}\n#{output}" unless status.success?
  output
end

results = {}

Dir.chdir(repo_root) do
  loaded_files = run!(crystal, "tool", "dependencies", "src/asset_pipeline.cr", "-f", "flat")
    .lines.map(&:strip).select { |line| line.start_with?("src/") }
  opt_in_files = loaded_files.select { |file| file.match?(%r{\Asrc/(ui|components|generators|lsp_rules)(/|\.cr\z)}) }
  puts "default require loads #{loaded_files.size} shard files: #{loaded_files.join(", ")}"
  puts "opt-in files among them: #{opt_in_files.empty? ? "none" : opt_in_files.join(", ")}"
  results["default require stays clear of opt-in files"] = opt_in_files.empty?
end

Dir.mktmpdir("asset_pipeline_linkage") do |build_dir|
  { "default_require_probe" => false, "regex_control_probe" => true }.each do |probe, expect_pcre2|
    binary = File.join(build_dir, probe)
    run!(crystal, "build", File.join(repo_root, "spec/web/linkage/#{probe}.cr"), "-o", binary)
    Dir.chdir(build_dir) { run!(binary) } # the probe must also run cleanly
    library_lines = run!(*dynamic_libraries_command, binary).lines.grep(/pcre2/).size
    symbol_lines = run!("nm", binary).lines.grep(/pcre2_/).size
    has_pcre2 = library_lines > 0 || symbol_lines > 0
    puts format("%-22s %s pcre2 lines: %d   nm pcre2_ symbols: %d", probe, dynamic_libraries_command.join(" "), library_lines, symbol_lines)
    results["#{probe} #{expect_pcre2 ? "shows" : "is free of"} PCRE2"] = (has_pcre2 == expect_pcre2)
  end
end

failed = results.reject { |_, passed| passed }.keys
abort "FAIL: #{failed.join("; ")}" unless failed.empty?
puts "PASS: the default require path links no PCRE2, and the control probe shows the check detects it."
