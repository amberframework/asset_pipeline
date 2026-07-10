require "../src/ui/design_tokens"
require "../src/ui/design_tokens/generators/web_generator"
require "../src/ui/design_tokens/generators/apple_generator"

# Regenerate every committed design-tokens dist artifact from the current
# `UI::DesignTokens::Tokens.default`. Run with `crystal run scripts/regenerate_design_tokens.cr`.
#
# Output is deterministic: invoking the script twice in a row produces
# identical bytes. The CI / pre-commit guard can re-run this script and
# `git diff --exit-code` to detect drift between the Crystal source of truth
# and the committed dist files.
#
# Android XML generator is deferred per
# `docs/initiative-cross-platform-ui/handoff/phase-01-architect-scope-deferral-2026-05-20.md`.
# Phase 6.12A adds an explicit per-target status report at the bottom so
# the deferral is visible at the call site instead of buried in a comment.

repo_root = File.expand_path("..", __DIR__)
tokens = UI::DesignTokens::Tokens.default

target_status = {} of String => String

web_path = File.join(repo_root, "src/ui/design_tokens/dist/web_tokens.css")
File.write(web_path, UI::DesignTokens::WebGenerator.generate(tokens))
puts "wrote #{web_path}"
target_status["web"] = "ok"

apple_path = File.join(repo_root, "src/ui/design_tokens/dist/AssetPipelineTokens.swift")
File.write(apple_path, UI::DesignTokens::AppleGenerator.generate(tokens))
puts "wrote #{apple_path}"
target_status["apple"] = "ok"

# Phase 6.12A — Android target. The Android XML generator is deferred
# (see phase-01-architect-scope-deferral). Probe the active tokens for
# any `Color::SYSTEM_ACCENT` sentinels and emit a clear diagnostic to
# STDERR that the Android dist is intentionally absent — the sentinel
# has no honest ARGB literal and the future Android generator must
# emit `?attr/colorPrimary` instead. We still exit 0 because the
# regenerator's contract for the iOS + macOS + web targets is honoured.
sentinel_roles = [] of String
tokens.colors_light.to_h.each do |name, color|
  sentinel_roles << "colors_light.#{name}" if color.system_accent?
end
tokens.colors_dark.to_h.each do |name, color|
  sentinel_roles << "colors_dark.#{name}" if color.system_accent?
end

if sentinel_roles.empty?
  STDERR.puts "[regenerate_design_tokens] android: skipped (XML generator deferred; no sentinels in active tokens)"
  target_status["android"] = "skipped (deferred, no sentinels)"
else
  STDERR.puts "[regenerate_design_tokens] android: skipped — Color::SYSTEM_ACCENT in #{sentinel_roles.size} role(s):"
  sentinel_roles.each { |role| STDERR.puts "  - #{role}" }
  STDERR.puts "  The deferred Android XML generator must emit '?attr/colorPrimary' for sentinel roles."
  STDERR.puts "  No Android dist file is produced. iOS + macOS + web targets succeeded."
  target_status["android"] = "skipped (sentinel; deferred generator)"
end

puts ""
puts "Target status:"
target_status.each { |target, status| puts "  #{target.ljust(8)} #{status}" }
