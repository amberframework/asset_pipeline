#!/usr/bin/env bash
#
# run_android_material_tests.sh
#
# Android Material validation shell runner.
# Builds the Android host, launches one study at a time, and captures device
# screenshots into docs/android-material-validation/screenshots/.
#
# This script is intentionally honest about current phase status:
# host-shell captures are useful for plumbing checks, but they are not
# ledger-grade evidence until the renderer mount contains real renderer output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOST_DIR="$PROJECT_ROOT/samples/cross_platform/android_host"
MANIFEST_PATH="$PROJECT_ROOT/docs/android-material-validation/manifest.json"
SCREENSHOT_DIR="$PROJECT_ROOT/docs/android-material-validation/screenshots"

CANONICAL_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"
FALLBACK_SDK_ROOT="$HOME/Library/Android/sdk"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-}"

if [[ -z "$ANDROID_SDK_ROOT" ]]; then
  if [[ -d "$CANONICAL_SDK_ROOT/platform-tools" ]]; then
    ANDROID_SDK_ROOT="$CANONICAL_SDK_ROOT"
  else
    ANDROID_SDK_ROOT="$FALLBACK_SDK_ROOT"
  fi
fi

ADB="$ANDROID_SDK_ROOT/platform-tools/adb"
GRADLEW="$HOST_DIR/gradlew"
APP_COMPONENT="dev.assetpipeline.androidhost/.MainActivity"
APK_PATH="$HOST_DIR/app/build/outputs/apk/debug/app-debug.apk"
JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"

ONLY_SLUGS=""
APPEARANCE="both"
SERIAL="${ANDROID_SERIAL:-}"
DEVICE_ROLE="phone"
SKIP_BUILD=0
DRY_RUN=0

usage() {
  cat <<EOF
Usage:
  ./scripts/run_android_material_tests.sh
  ./scripts/run_android_material_tests.sh --only buttons,webview
  ./scripts/run_android_material_tests.sh --device-role tablet --serial emulator-5556
  ANDROID_SERIAL=emulator-5554 ./scripts/run_android_material_tests.sh --appearance light

Options:
  --only <csv>         Comma-separated slugs to capture
  --appearance <mode>  light, dark, or both (default: both)
  --serial <serial>    Explicit adb device serial
  --device-role <role> phone or tablet (default: phone)
  --skip-build         Reuse the installed host APK on the target device
  --dry-run            Print commands without launching or capturing
  -h, --help           Show this help
EOF
}

info() { printf '\033[0;34m[android-material]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[warn]\033[0m             %s\n' "$*" >&2; }
fail() { printf '\033[0;31m[fail]\033[0m             %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only) ONLY_SLUGS="$2"; shift 2 ;;
    --appearance) APPEARANCE="$2"; shift 2 ;;
    --serial) SERIAL="$2"; shift 2 ;;
    --device-role) DEVICE_ROLE="$2"; shift 2 ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown arg: $1" ;;
  esac
done

[[ -x "$ADB" ]] || fail "adb not found at $ADB"
[[ -x "$GRADLEW" ]] || fail "gradlew not found at $GRADLEW"
[[ -x "$JAVA_HOME/bin/java" ]] || fail "java not found under $JAVA_HOME"
[[ -f "$MANIFEST_PATH" ]] || fail "Manifest not found at $MANIFEST_PATH"

mkdir -p "$SCREENSHOT_DIR"

manifest_slugs() {
  ruby -rjson -e '
    manifest = JSON.parse(File.read(ARGV[0]))
    puts manifest.fetch("studies").map { |study| study.fetch("slug") }
  ' "$MANIFEST_PATH"
}

resolve_slugs() {
  if [[ -n "$ONLY_SLUGS" ]]; then
    printf '%s\n' "$ONLY_SLUGS" | tr ',' '\n' | sed '/^$/d'
  else
    manifest_slugs
  fi
}

resolve_appearances() {
  case "$APPEARANCE" in
    light) printf 'light\n' ;;
    dark) printf 'dark\n' ;;
    both) printf 'light\ndark\n' ;;
    *) fail "Unsupported appearance: $APPEARANCE" ;;
  esac
}

resolve_device_role() {
  case "$DEVICE_ROLE" in
    phone|tablet) printf '%s\n' "$DEVICE_ROLE" ;;
    *) fail "Unsupported device role: $DEVICE_ROLE" ;;
  esac
}

settle_seconds_for_study() {
  case "$1" in
    webview) printf '4\n' ;;
    video-player) printf '5\n' ;;
    *) printf '2\n' ;;
  esac
}

ready_timeout_for_study() {
  case "$1" in
    webview|video-player) printf '120\n' ;;
    *) printf '90\n' ;;
  esac
}

resolve_serial() {
  if [[ -n "$SERIAL" ]]; then
    printf '%s\n' "$SERIAL"
    return
  fi

  "$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }'
}

launch_study() {
  local serial="$1"
  local slug="$2"
  local appearance="$3"
  local story="Asset Pipeline Android Material validation"

  "$ADB" -s "$serial" shell am start -S \
    -n "$APP_COMPONENT" \
    --es study_slug "$slug" \
    --es study_appearance "$appearance" \
    --es study_story "$story" >/dev/null </dev/null
}

capture_study() {
  local serial="$1"
  local slug="$2"
  local appearance="$3"
  local role="$4"
  local outfile="$SCREENSHOT_DIR/${slug}-android-${role}-${appearance}.png"

  "$ADB" -s "$serial" exec-out screencap -p </dev/null >"$outfile"
  info "Captured $outfile"
}

wait_for_renderer_mount() {
  local serial="$1"
  local slug="$2"
  local timeout_seconds="$3"
  local dump_path="/sdcard/android-material-ready.xml"
  local elapsed=0

  while (( elapsed < timeout_seconds )); do
    if "$ADB" -s "$serial" shell uiautomator dump "$dump_path" >/dev/null 2>&1 </dev/null; then
      if "$ADB" -s "$serial" shell "grep -q 'Android Material study' '$dump_path'" >/dev/null 2>&1 </dev/null \
        && ! "$ADB" -s "$serial" shell dumpsys window windows </dev/null | grep -q 'Splash Screen dev.assetpipeline.androidhost'; then
        info "Renderer mount ready for $slug after ${elapsed}s"
        return 0
      fi
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  return 1
}

TARGET_SERIAL="$(resolve_serial)"
[[ -n "$TARGET_SERIAL" ]] || fail "No connected Android device found. Boot an emulator first."

info "Using SDK root: $ANDROID_SDK_ROOT"
info "Using JAVA_HOME: $JAVA_HOME"
info "Using adb serial: $TARGET_SERIAL"
info "Using device role: $(resolve_device_role)"

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  info "Building and installing the Android host for $TARGET_SERIAL"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    JAVA_HOME="$JAVA_HOME" \
    ANDROID_HOME="$ANDROID_SDK_ROOT" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    "$GRADLEW" -p "$HOST_DIR" :app:assembleDebug >/dev/null
    [[ -f "$APK_PATH" ]] || fail "APK not found at $APK_PATH after assembleDebug"
    "$ADB" -s "$TARGET_SERIAL" install -r "$APK_PATH" >/dev/null
  fi
else
  info "Skipping build at user request"
fi

warn "Keep studies pending until the captured renderer output is reviewed against Material 3 expectations and ledger criteria."

while IFS= read -r slug; do
  [[ -n "$slug" ]] || continue
  while IFS= read -r appearance; do
    [[ -n "$appearance" ]] || continue
    info "Launching $slug ($appearance)"
    if [[ "$DRY_RUN" -eq 0 ]]; then
      launch_study "$TARGET_SERIAL" "$slug" "$appearance"
      if ! wait_for_renderer_mount "$TARGET_SERIAL" "$slug" "$(ready_timeout_for_study "$slug")"; then
        fail "Renderer mount did not become ready for $slug ($appearance) on $TARGET_SERIAL"
      fi
      sleep "$(settle_seconds_for_study "$slug")"
      capture_study "$TARGET_SERIAL" "$slug" "$appearance" "$(resolve_device_role)"
    else
      printf 'DRY RUN: launch %s (%s) on %s\n' "$slug" "$appearance" "$TARGET_SERIAL"
    fi
  done < <(resolve_appearances)
done < <(resolve_slugs)

info "Android host capture run complete"
