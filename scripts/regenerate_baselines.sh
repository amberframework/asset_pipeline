#!/usr/bin/env bash
# Phase 6.5 D2 — Regenerate visual baselines.
#
# Captures fresh PNGs into the canonical baselines tree at
# docs/initiative-cross-platform-ui/baselines/{platform}/{slug}.png by
# driving the platform's underlying capture mechanism:
#
#   macOS : bin/hig_showcase with HIG_SLUG=<slug> + HIG_SCREENSHOT_PATH=<out>
#           (self-snapshot path; no TCC needed)
#   iOS   : scripts/run_ios_hig_tests.sh per slug (extracts PNG from xcresult)
#   web   : scripts/cdp_probes/screenshot_probe.cr (D5; CDP Page.captureScreenshot)
#
# Usage:
#   bash scripts/regenerate_baselines.sh --platform macos --slug button_default
#   bash scripts/regenerate_baselines.sh --platform macos --all
#   bash scripts/regenerate_baselines.sh --platform web --slug action_sheet
#
# Each new baseline gets a default tolerance.json (pixel_diff_max=250)
# if one does not already exist.
#
# Also records a toolchain fingerprint in
# `baselines/<platform>/<slug>.fingerprint.json` so visual regressions
# caused by toolchain upgrades are diagnosable.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASELINES_ROOT="$ROOT/docs/initiative-cross-platform-ui/baselines"

PLATFORM=""
SLUG=""
ALL="no"
APPEARANCE="light"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2;;
    --slug)     SLUG="$2"; shift 2;;
    --appearance) APPEARANCE="$2"; shift 2;;
    --all)      ALL="yes"; shift;;
    -h|--help)
      cat <<EOH
Usage: bash scripts/regenerate_baselines.sh --platform <ios|macos|web> [--slug <s>] [--all]

Captures a baseline PNG, writes the default tolerance.json + fingerprint.json
if absent. Stored at docs/initiative-cross-platform-ui/baselines/<platform>/<slug>.png.
EOH
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 3;;
  esac
done

if [ -z "$PLATFORM" ]; then
  echo "regenerate_baselines: --platform is required" >&2
  exit 3
fi

if [ "$ALL" != "yes" ] && [ -z "$SLUG" ]; then
  echo "regenerate_baselines: --slug or --all is required" >&2
  exit 3
fi

OUT_DIR="$BASELINES_ROOT/$PLATFORM"
mkdir -p "$OUT_DIR"

write_tolerance_if_absent() {
  local tol_path="$1"
  if [ ! -f "$tol_path" ]; then
    cat > "$tol_path" <<'EOJ'
{
  "pixel_diff_max": 250,
  "channel_diff_max": 8,
  "notes": "Default tolerance; tighten per-slug as the baseline stabilizes."
}
EOJ
    echo "regenerate_baselines: wrote default tolerance -> $tol_path"
  fi
}

write_fingerprint() {
  local fp_path="$1"
  local platform="$2"
  local macos_version="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
  local xcode_version="$(xcodebuild -version 2>/dev/null | head -1 || echo unknown)"
  local crystal_version="$(crystal-alpha --version 2>/dev/null | head -1 || crystal --version 2>/dev/null | head -1 || echo unknown)"
  local imagemagick_version="$(magick --version 2>/dev/null | head -1 || echo unknown)"
  cat > "$fp_path" <<EOJ
{
  "platform": "$platform",
  "captured_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "macos_version": "$macos_version",
  "xcode_version": "$xcode_version",
  "crystal_version": "$crystal_version",
  "imagemagick_version": "$imagemagick_version"
}
EOJ
}

capture_macos_slug() {
  local slug="$1"
  local appearance="$2"
  local out_png="$OUT_DIR/${slug}-${appearance}.png"
  local bin="$ROOT/samples/cross_platform/macos_host/bin/hig_showcase"

  if [ ! -x "$bin" ]; then
    echo "regenerate_baselines: macOS host binary not built; run 'make -C samples/cross_platform/macos_host build'" >&2
    return 1
  fi

  HIG_SLUG="$slug" HIG_APPEARANCE="$appearance" HIG_SCREENSHOT_PATH="$out_png" \
    "$bin" || {
      echo "regenerate_baselines: bin/hig_showcase exited non-zero for $slug/$appearance" >&2
      return 1
    }

  if [ ! -f "$out_png" ]; then
    echo "regenerate_baselines: capture missing for $slug/$appearance at $out_png" >&2
    return 1
  fi

  write_tolerance_if_absent "$OUT_DIR/${slug}-${appearance}.tolerance.json"
  write_fingerprint "$OUT_DIR/${slug}-${appearance}.fingerprint.json" "macos"
  echo "regenerate_baselines: macOS $slug/$appearance -> $out_png"
}

capture_ios_slug() {
  local slug="$1"
  local appearance="$2"
  local runner="$ROOT/scripts/run_ios_hig_tests.sh"
  if [ ! -x "$runner" ]; then
    echo "regenerate_baselines: iOS runner missing at $runner" >&2
    return 1
  fi
  echo "regenerate_baselines: invoking $runner for $slug/$appearance (will take 20-60s)..."
  HIG_SLUG="$slug" HIG_APPEARANCE="$appearance" bash "$runner" || {
    echo "regenerate_baselines: iOS runner exited non-zero" >&2
    return 1
  }
  # The runner deposits the PNG in the xcresult extraction path; move it.
  local extracted="$ROOT/.claude/skills/apple-platform-guide/validation/screenshots/${slug}-ios-${appearance}.png"
  if [ -f "$extracted" ]; then
    cp "$extracted" "$OUT_DIR/${slug}-${appearance}.png"
    write_tolerance_if_absent "$OUT_DIR/${slug}-${appearance}.tolerance.json"
    write_fingerprint "$OUT_DIR/${slug}-${appearance}.fingerprint.json" "ios"
    echo "regenerate_baselines: iOS $slug/$appearance -> $OUT_DIR/${slug}-${appearance}.png"
  else
    echo "regenerate_baselines: iOS extracted PNG not found at $extracted" >&2
    return 1
  fi
}

capture_web_slug() {
  local slug="$1"
  local probe="$ROOT/scripts/cdp_probes/screenshot_probe.cr"
  if [ ! -f "$probe" ]; then
    echo "regenerate_baselines: web screenshot_probe.cr missing (D5 not shipped)" >&2
    return 1
  fi
  local out_png="$OUT_DIR/${slug}.png"
  crystal-alpha run "$probe" -- --slug "$slug" --out "$out_png" || {
    echo "regenerate_baselines: web screenshot probe failed" >&2
    return 1
  }
  write_tolerance_if_absent "$OUT_DIR/${slug}.tolerance.json"
  write_fingerprint "$OUT_DIR/${slug}.fingerprint.json" "web"
  echo "regenerate_baselines: web $slug -> $out_png"
}

case "$PLATFORM" in
  macos)
    if [ "$ALL" = "yes" ]; then
      echo "regenerate_baselines: --all not implemented for macOS; pass --slug" >&2
      exit 3
    fi
    capture_macos_slug "$SLUG" "$APPEARANCE"
    ;;
  ios)
    if [ "$ALL" = "yes" ]; then
      echo "regenerate_baselines: --all not implemented for iOS; pass --slug" >&2
      exit 3
    fi
    capture_ios_slug "$SLUG" "$APPEARANCE"
    ;;
  web)
    if [ "$ALL" = "yes" ]; then
      echo "regenerate_baselines: --all not implemented for web; pass --slug" >&2
      exit 3
    fi
    capture_web_slug "$SLUG"
    ;;
  *)
    echo "regenerate_baselines: unknown platform '$PLATFORM' (expected ios|macos|web)" >&2
    exit 3
    ;;
esac
