#!/usr/bin/ruby
# Checks that `require "asset_pipeline"`, and what a generated Amber app's
# initializers require, keep applications free of PCRE2, and of OpenSSL and
# libz in a build made with -Dwithout_openssl and -Dwithout_zlib.
#
# It builds and runs three probes under spec/web/linkage/:
# default_require_probe.cr (everything the default require loads, exercised),
# generated_app_initializers_probe.cr (exactly the requires amber_cli writes into
# config/initializers/page_cache.cr, used as the generated app uses them) and
# regex_control_probe.cr (the default require plus one Regex). It checks that:
#
#   * the default-require and generated-initializers probes link no libpcre2 and
#     carry no pcre2_ symbols;
#   * the control probe shows PCRE2, which proves the check can fail;
#   * the default-require and generated-initializers probes, built with
#     -Dwithout_openssl, link no libssl or libcrypto, carry no EVP_, SSL_ or
#     OPENSSL_ symbol and run; built without the flag they show OpenSSL, which
#     proves that check can fail;
#   * the default-require and generated-initializers probes, built with
#     -Dwithout_zlib, link no libz, take no inflate, deflate or crc32 symbol
#     from it and run (they gzip assets and cached pages and expand them
#     again); built without the flag they show libz, which proves that check
#     can fail;
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
  { "default_require_probe" => false, "generated_app_initializers_probe" => false, "regex_control_probe" => true }.each do |probe, expect_pcre2|
    binary = File.join(build_dir, probe)
    run!(crystal, "build", File.join(repo_root, "spec/web/linkage/#{probe}.cr"), "-o", binary)
    Dir.chdir(build_dir) { run!(binary) } # the probe must also run cleanly
    library_lines = run!(*dynamic_libraries_command, binary).lines.grep(/pcre2/).size
    symbol_lines = run!("nm", binary).lines.grep(/pcre2_/).size
    has_pcre2 = library_lines > 0 || symbol_lines > 0
    puts format("%-34s %s pcre2 lines: %d   nm pcre2_ symbols: %d", probe, dynamic_libraries_command.join(" "), library_lines, symbol_lines)
    results["#{probe} #{expect_pcre2 ? "shows" : "is free of"} PCRE2"] = (has_pcre2 == expect_pcre2)
  end
end

openssl_library = /libssl|libcrypto/
openssl_symbol = /[ _](EVP|SSL|OPENSSL)_/
Dir.mktmpdir("asset_pipeline_openssl_linkage") do |build_dir|
  %w[default_require_probe generated_app_initializers_probe].each do |probe|
    { "with -Dwithout_openssl" => ["-Dwithout_openssl"], "without the flag" => [] }.each do |label, list_of_flags|
      expect_openssl = list_of_flags.empty?
      binary = File.join(build_dir, "#{probe}_#{expect_openssl ? "default" : "without_openssl"}")
      run!(crystal, "build", *list_of_flags, File.join(repo_root, "spec/web/linkage/#{probe}.cr"), "-o", binary)
      Dir.chdir(build_dir) { run!(binary) } unless expect_openssl # the flagged probe must also run cleanly
      library_lines = run!(*dynamic_libraries_command, binary).lines.grep(openssl_library).size
      symbol_lines = run!("nm", binary).lines.grep(openssl_symbol).size
      has_openssl = library_lines > 0 || symbol_lines > 0
      puts format("%-34s %-24s libssl/libcrypto lines: %d   OpenSSL symbols: %d", probe, label, library_lines, symbol_lines)
      results["#{probe} #{label} #{expect_openssl ? "shows" : "is free of"} OpenSSL"] = (has_openssl == expect_openssl)
    end
  end
end

zlib_library = /libz\./
zlib_symbol = /\s_?(inflate|deflate|crc32|adler32)(Init2?_|End|Reset)?(@.*)?$/
Dir.mktmpdir("asset_pipeline_zlib_linkage") do |build_dir|
  %w[default_require_probe generated_app_initializers_probe].each do |probe|
    { "with -Dwithout_zlib" => ["-Dwithout_zlib"], "without the flag" => [] }.each do |label, list_of_flags|
      expect_zlib = list_of_flags.empty?
      binary = File.join(build_dir, "#{probe}_#{expect_zlib ? "default" : "without_zlib"}")
      run!(crystal, "build", *list_of_flags, File.join(repo_root, "spec/web/linkage/#{probe}.cr"), "-o", binary)
      Dir.chdir(build_dir) { run!(binary) } unless expect_zlib # the flagged probe must also run cleanly
      library_lines = run!(*dynamic_libraries_command, binary).lines.grep(zlib_library).size
      symbol_lines = run!("nm", binary).lines.grep(zlib_symbol).size
      has_zlib = library_lines > 0 || symbol_lines > 0
      puts format("%-34s %-24s libz lines: %d   libz symbols: %d", probe, label, library_lines, symbol_lines)
      results["#{probe} #{label} #{expect_zlib ? "shows" : "is free of"} libz"] = (has_zlib == expect_zlib)
    end
  end
end

failed = results.reject { |_, passed| passed }.keys
abort "FAIL: #{failed.join("; ")}" unless failed.empty?
puts "PASS: the default require path and the generated app's initializer requires link no PCRE2, no OpenSSL with -Dwithout_openssl and no libz with -Dwithout_zlib; the control builds show each check detects what it looks for."
