#!/usr/bin/env crystal-alpha
# generate.cr -- Regenerate backdrop library for HIG validation captures.
#
# Run from anywhere:
#   crystal-alpha .claude/skills/apple-platform-guide/validation/backdrops/generate.cr
#
# Prerequisites:
#   - crystal-alpha on PATH
#   - Python 3 on PATH (invokes generate_backdrops.py for pixel-level PNG writing)
#   - macOS (backdrops are generated via macOS AppKit + CGWindowListCreateImage)
#
# The script delegates to the sibling Python module for the actual PNG
# generation. Crystal is used as the canonical entry point so the file is
# treated as part of the asset_pipeline build graph.

require "process"

BACKDROP_DIR = Path[__DIR__]
PY_SCRIPT    = BACKDROP_DIR / "generate_backdrops.py"

puts "[backdrops] Generating via #{PY_SCRIPT}..."
status = Process.run(
  "python3",
  [PY_SCRIPT.to_s],
  output: STDOUT,
  error:  STDERR
)

unless status.success?
  STDERR.puts "[backdrops] Python generator exited with code #{status.exit_code}"
  exit 1
end

puts "[backdrops] Done."
