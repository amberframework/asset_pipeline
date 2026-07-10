#!/usr/bin/env bash
# Phase 8D.3b — macOS capture loop.
#
# Drives the macOS voyager host through all 14 capture scenarios x 2
# appearances = 28 PNGs. The host reads VOYAGER_CAPTURE_SCENARIO,
# applies the scenario via Voyager::CaptureScenarios.apply, then the
# existing VOYAGER_SCREENSHOT_PATH offscreen-capture branch in host.cr
# writes the PNG and exits.
#
# Both VOYAGER_APPEARANCE and HIG_APPEARANCE are set: the host uses
# VOYAGER_APPEARANCE for the NSWindow appearance attribute, but the
# AppKit renderer's token-resolved colors (appkit_renderer.cr:3986)
# read HIG_APPEARANCE. Per Codex MEDIUM 1.
#
# Run from the repo root:
#   ./samples/initiative-cross-platform-ui-voyager/bin/capture_voyager_macos.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_DIR/../.." && pwd)"

EVIDENCE_DIR="$REPO_ROOT/docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/macos"
mkdir -p "$EVIDENCE_DIR"

# Build (idempotent) the macOS host binary.
echo "[capture] building macOS voyager host..."
make -C "$PROJECT_DIR" macos

VOYAGER_BIN="$PROJECT_DIR/macos/bin/voyager"
if [ ! -x "$VOYAGER_BIN" ]; then
  echo "[capture] error: macOS voyager binary missing at $VOYAGER_BIN" >&2
  exit 1
fi

SCENARIOS=(
  "row-01-sign-in"
  "row-02-todos-launch"
  "row-03-editor-empty"
  "row-04-editor-prefilled"
  "row-05-todos-after-save"
  "row-06-todos-row-completed"
  "row-07-todos-swipe-row"
  "row-08-editor-edit-prefilled"
  "row-09-todos-after-edit"
  "row-10-todos-after-delete"
  "row-11-settings-default"
  "row-12-settings-toggled"
  "row-13-todos-filtered"
  "row-14-todos-unfiltered"
)

# Slug each scenario should be launched with — MUST match the scenario's
# final coord.current.id so any depth-1-resync path is a no-op. Mirrors
# Voyager::CaptureScenarios::SCENARIO_TO_SLUG (kept in sync manually;
# the Crystal map is authoritative).
#
# Macos ships bash 3.2 (no associative arrays), so use a case statement.
slug_for_scenario() {
  case "$1" in
    row-01-sign-in)               echo "voyager-sign-in" ;;
    row-02-todos-launch)          echo "voyager-todos" ;;
    row-03-editor-empty)          echo "voyager-todo-editor" ;;
    row-04-editor-prefilled)      echo "voyager-todo-editor" ;;
    row-05-todos-after-save)      echo "voyager-todos" ;;
    row-06-todos-row-completed)   echo "voyager-todos" ;;
    row-07-todos-swipe-row)       echo "voyager-todos" ;;
    row-08-editor-edit-prefilled) echo "voyager-todo-editor" ;;
    row-09-todos-after-edit)      echo "voyager-todos" ;;
    row-10-todos-after-delete)    echo "voyager-todos" ;;
    row-11-settings-default)      echo "voyager-settings" ;;
    row-12-settings-toggled)      echo "voyager-settings" ;;
    row-13-todos-filtered)        echo "voyager-todos" ;;
    row-14-todos-unfiltered)      echo "voyager-todos" ;;
    *) echo "voyager-sign-in" ;;
  esac
}

count=0
for scenario in "${SCENARIOS[@]}"; do
  slug="$(slug_for_scenario "$scenario")"
  for appearance in light dark; do
    out_png="$EVIDENCE_DIR/voyager-$scenario-$appearance.png"
    echo "[capture] scenario=$scenario appearance=$appearance slug=$slug -> $out_png"
    VOYAGER_CAPTURE_SCENARIO="$scenario" \
    VOYAGER_ROOT_SLUG="$slug" \
    VOYAGER_APPEARANCE="$appearance" \
    HIG_APPEARANCE="$appearance" \
    VOYAGER_SCREENSHOT_PATH="$out_png" \
      "$VOYAGER_BIN"
    count=$((count + 1))
  done
done

produced=$(ls -1 "$EVIDENCE_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo "[capture] macOS captures complete: $produced PNGs in $EVIDENCE_DIR (expected: 28)"

# Size-audit: warn for any PNG that's < 10KB.
small=0
for f in "$EVIDENCE_DIR"/*.png; do
  size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
  if [ "$size" -lt 10240 ]; then
    echo "[capture] WARN $f size=$size bytes (<10KB)" >&2
    small=$((small + 1))
  fi
done
if [ "$small" -gt 0 ]; then
  echo "[capture] WARN: $small PNG(s) under 10KB threshold" >&2
fi
