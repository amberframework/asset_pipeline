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
#   * the control probe, built with -Duse_pcre2, shows PCRE2, which proves the
#     check can fail;
#   * the default-require and generated-initializers probes, built with
#     -Dwithout_openssl, link no libssl or libcrypto, carry no EVP_, SSL_ or
#     OPENSSL_ symbol and run; built without the flag they make no OpenSSL
#     digest call (EVP_Digest*, EVP_MD*) on Crystal 1.21 or newer, where
#     Beryl is the default SHA-256, and make one on older compilers;
#     openssl_control_probe.cr (the default require plus Crystal's
#     Digest::SHA256) makes one, which proves that check can fail;
#   * the default-require and generated-initializers probes, built with
#     -Dwithout_zlib, link no libz, take no inflate, deflate or crc32 symbol
#     from it and run (they gzip assets and cached pages and expand them
#     again); built with -Duse_libz they show libz, which proves that check
#     can fail (stock Crystal links libz by default, crystal-alpha only with
#     that flag);
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
    # -Duse_pcre2 selects PCRE2 on compilers whose default Regex engine is
    # Mica (crystal-alpha); stock Crystal uses PCRE2 either way.
    list_of_flags = expect_pcre2 ? ["-Duse_pcre2"] : []
    run!(crystal, "build", *list_of_flags, File.join(repo_root, "spec/web/linkage/#{probe}.cr"), "-o", binary)
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
# OpenSSL's message-digest calls: what Crystal's Digest::SHA256 imports.
openssl_digest_symbol = /[ _]EVP_(Digest|MD)/
compiler_version = run!(crystal, "--version")[/Crystal (\d+\.\d+\.\d+)/, 1] || abort("cannot read the #{crystal} version")
beryl_is_the_default = Gem::Version.new(compiler_version) >= Gem::Version.new("1.21.0")
Dir.mktmpdir("asset_pipeline_openssl_linkage") do |build_dir|
  # With -Dwithout_openssl: no OpenSSL at all, and the probe runs.
  %w[default_require_probe generated_app_initializers_probe].each do |probe|
    binary = File.join(build_dir, "#{probe}_without_openssl")
    run!(crystal, "build", "-Dwithout_openssl", File.join(repo_root, "spec/web/linkage/#{probe}.cr"), "-o", binary)
    Dir.chdir(build_dir) { run!(binary) }
    library_lines = run!(*dynamic_libraries_command, binary).lines.grep(openssl_library).size
    symbol_lines = run!("nm", binary).lines.grep(openssl_symbol).size
    puts format("%-34s %-24s libssl/libcrypto lines: %d   OpenSSL symbols: %d", probe, "with -Dwithout_openssl", library_lines, symbol_lines)
    results["#{probe} with -Dwithout_openssl is free of OpenSSL"] = library_lines == 0 && symbol_lines == 0
  end

  # Without the flag: SHA-256 is Beryl's on Crystal 1.21 or newer, so no
  # OpenSSL digest call. (A probe that requires http/server can still link
  # OpenSSL for TLS; that is Crystal's, not asset_pipeline's.) The control
  # probe hashes with Crystal's Digest::SHA256 and must show the digest calls.
  %w[default_require_probe generated_app_initializers_probe openssl_control_probe].each do |probe|
    expect_digest = probe == "openssl_control_probe" || !beryl_is_the_default
    binary = File.join(build_dir, "#{probe}_default")
    run!(crystal, "build", File.join(repo_root, "spec/web/linkage/#{probe}.cr"), "-o", binary)
    Dir.chdir(build_dir) { run!(binary) }
    digest_lines = run!("nm", binary).lines.grep(openssl_digest_symbol).size
    puts format("%-34s %-24s OpenSSL digest symbols: %d", probe, "without the flag", digest_lines)
    results["#{probe} without the flag #{expect_digest ? "shows" : "is free of"} OpenSSL's SHA-256"] = (digest_lines > 0) == expect_digest
  end
end

zlib_library = /libz\./
zlib_symbol = /\s_?(inflate|deflate|crc32|adler32)(Init2?_|End|Reset)?(@.*)?$/
Dir.mktmpdir("asset_pipeline_zlib_linkage") do |build_dir|
  %w[default_require_probe generated_app_initializers_probe].each do |probe|
    # The control is built with -Duse_libz: compilers whose Compress runs on
    # Mica (crystal-alpha) need it to link libz; stock Crystal links it anyway.
    { "with -Dwithout_zlib" => ["-Dwithout_zlib"], "control, -Duse_libz" => ["-Duse_libz"] }.each do |label, list_of_flags|
      expect_zlib = list_of_flags == ["-Duse_libz"]
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
puts "PASS: the default require path and the generated app's initializer requires link no PCRE2, no OpenSSL with -Dwithout_openssl, no OpenSSL SHA-256 by default on Crystal 1.21 or newer, and no libz with -Dwithout_zlib; the control builds show each check detects what it looks for."
