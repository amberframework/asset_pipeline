#!/usr/bin/env bash
# run_ios_hig_tests.sh
#
# Orchestrates the iOS HIG visual-validation loop:
#
#   1. Ensure xcodegen is installed
#   2. Build libhighost.a (Crystal static lib for iOS simulator)
#   3. Generate CrystalHIGHost.xcodeproj via xcodegen
#   4. For each component slug (or --only <slug>):
#        a. xcodebuild test -only-testing:CrystalHIGHostUITests/HIGVisualTests/testRenderSlug
#        b. extract the "<slug>-ios.png" attachment from the xcresult bundle
#        c. write to .claude/skills/apple-platform-guide/validation/screenshots/<slug>-ios.png
#
# Prerequisites:
#   - xcodegen (brew install xcodegen)
#   - jq (brew install jq) -- for parsing xcresult attachment manifests
#   - Xcode with iOS 26 simulator SDK
#
# Usage:
#   ./scripts/run_ios_hig_tests.sh                  # all component slugs
#   ./scripts/run_ios_hig_tests.sh --only buttons   # one slug

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/samples/cross_platform/ios_host"
WORKLIST="$PROJECT_ROOT/.claude/skills/apple-platform-guide/validation/worklist.json"
SCREENSHOT_DIR="$PROJECT_ROOT/.claude/skills/apple-platform-guide/validation/screenshots"
XCRESULT_DIR="$IOS_DIR/build/xcresults"

ONLY_SLUG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --only) ONLY_SLUG="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,30p' "$0"
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

info()  { printf '\033[0;34m[ios-hig]\033[0m %s\n' "$*"; }
ok()    { printf '\033[0;32m[ok]\033[0m      %s\n' "$*"; }
fail()  { printf '\033[0;31m[fail]\033[0m    %s\n' "$*" >&2; exit 1; }

SIM_NAME="${SIM_NAME:-}"
SIM_UDID="${SIM_UDID:-}"
MAX_XCODEBUILD_RETRIES="${MAX_XCODEBUILD_RETRIES:-2}"
DESTINATION_POLL_ATTEMPTS="${DESTINATION_POLL_ATTEMPTS:-3}"
DESTINATION_POLL_DELAY="${DESTINATION_POLL_DELAY:-2}"

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

command -v xcodegen >/dev/null 2>&1 || {
    info "xcodegen not found; installing via brew..."
    command -v brew >/dev/null 2>&1 || fail "Homebrew required to auto-install xcodegen"
    brew install xcodegen
}

command -v jq >/dev/null 2>&1 || fail "jq required (brew install jq)"
command -v xcodebuild >/dev/null 2>&1 || fail "xcodebuild required (install Xcode)"

[[ -f "$WORKLIST" ]] || fail "Worklist not found: $WORKLIST"

mkdir -p "$SCREENSHOT_DIR" "$XCRESULT_DIR"

resolve_simulator_device() {
    local devices_json result query
    if [[ -n "$SIM_UDID" ]]; then
        return 0
    fi
    devices_json="$(xcrun simctl list devices available --json 2>/dev/null)" || \
        fail "Unable to query available simulators via simctl"

    if [[ -n "$SIM_NAME" ]]; then
        query='
          [
            .devices | to_entries[]
            | select(.key | test("com\\.apple\\.CoreSimulator\\.SimRuntime\\.iOS-26"))
            | .key as $runtime
            | .value[]
            | select(.isAvailable == true and .name == $requested)
            | {runtime: $runtime, name: .name, udid: .udid, state: .state}
          ]
          | sort_by([if .state == "Booted" then 1 else 0 end, .runtime])
          | last // empty
        '
        result="$(printf '%s' "$devices_json" | jq -c --arg requested "$SIM_NAME" "$query")"
    else
        query='
          [
            .devices | to_entries[]
            | select(.key | test("com\\.apple\\.CoreSimulator\\.SimRuntime\\.iOS-26"))
            | .key as $runtime
            | .value[]
            | select(.isAvailable == true)
            | select(.name | test("^iPhone .* Pro( Max)?$"))
            | {runtime: $runtime, name: .name, udid: .udid, state: .state}
          ]
          | sort_by([if .state == "Booted" then 1 else 0 end, .runtime])
          | last // empty
        '
        result="$(printf '%s' "$devices_json" | jq -c "$query")"
    fi

    [[ -n "$result" && "$result" != "null" ]] || \
        fail "No available iOS 26 simulator matched '${SIM_NAME:-auto-detect}'"

    SIM_NAME="$(printf '%s' "$result" | jq -r '.name')"
    SIM_UDID="$(printf '%s' "$result" | jq -r '.udid')"
}

boot_simulator() {
    [[ -n "$SIM_UDID" ]] || fail "boot_simulator called before SIM_UDID was resolved"
    xcrun simctl boot "$SIM_UDID" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null 2>&1 || true
}

restart_simulator_services() {
    info "Restarting CoreSimulatorService for $SIM_NAME..."
    killall -9 com.apple.CoreSimulator.CoreSimulatorService >/dev/null 2>&1 || true
    sleep 2
    resolve_simulator_device
    boot_simulator
}

showdestinations_has_simulator() {
    local log_path="$XCRESULT_DIR/showdestinations.log"
    local output
    output="$(xcodebuild -showdestinations \
        -project "$IOS_DIR/CrystalHIGHost.xcodeproj" \
        -scheme CrystalHIGHost 2>&1 || true)"
    printf '%s\n' "$output" > "$log_path"

    [[ "$output" == *"$SIM_NAME"* ]] || return 1
    [[ "$output" != *"DVTiOSDeviceSimulatorPlaceholder"* ]] || return 1
}

wait_for_xcode_destination() {
    local phase="${1:-simulator}"
    local attempt

    for ((attempt = 1; attempt <= DESTINATION_POLL_ATTEMPTS; attempt++)); do
        if showdestinations_has_simulator; then
            return 0
        fi

        if [[ $attempt -lt $DESTINATION_POLL_ATTEMPTS ]]; then
            info "Waiting for xcodebuild to rediscover $SIM_NAME ($phase ${attempt}/${DESTINATION_POLL_ATTEMPTS})..."
            sleep "$DESTINATION_POLL_DELAY"
            boot_simulator
        fi
    done

    return 1
}

ensure_simulator_ready() {
    resolve_simulator_device
    info "Preparing simulator: $SIM_NAME ($SIM_UDID)"
    boot_simulator

    if wait_for_xcode_destination "initial"; then
        ok "Simulator destination ready"
        return 0
    fi

    info "xcodebuild does not see $SIM_NAME yet; retrying after CoreSimulatorService restart..."
    restart_simulator_services
    if wait_for_xcode_destination "post-restart"; then
        ok "Simulator destination ready after restart"
        return 0
    fi

    info "xcodebuild still does not list $SIM_NAME after preflight; continuing and letting the test run retry path recover if needed."
}

xcodebuild_needs_simulator_retry() {
    local rc="$1"
    local log_path="$2"

    [[ "$rc" -eq 70 ]] && return 0

    grep -Eq \
        'CoreSimulatorService connection became invalid|Unable to find a device matching the provided destination specifier|DVTiOSDeviceSimulatorPlaceholder|Supported platforms for the buildables in the current scheme is empty|Connection refused' \
        "$log_path"
}

run_xcodebuild_test() {
    local slug="$1"
    local appearance="$2"
    local xcresult="$3"
    local resolved_backdrop="$4"
    local log_path="$XCRESULT_DIR/${slug}-${appearance}.log"
    local rc attempt
    local -a xcode_env=(
        "TEST_RUNNER_HIG_SLUG=$slug"
        "TEST_RUNNER_HIG_APPEARANCE=$appearance"
    )

    if [[ -n "$resolved_backdrop" ]]; then
        xcode_env+=("TEST_RUNNER_HIG_BACKDROP_PATH=$resolved_backdrop")
    fi

    for ((attempt = 1; attempt <= MAX_XCODEBUILD_RETRIES; attempt++)); do
        rm -rf "$xcresult"

        set +e
        env "${xcode_env[@]}" \
        xcodebuild test \
            -project "$IOS_DIR/CrystalHIGHost.xcodeproj" \
            -scheme CrystalHIGHost \
            -destination "platform=iOS Simulator,id=$SIM_UDID" \
            -only-testing:CrystalHIGHostUITests/HIGVisualTests/testRenderSlug \
            -resultBundlePath "$xcresult" >"$log_path" 2>&1
        rc=$?
        set -e

        tail -20 "$log_path" || true

        if [[ $rc -eq 0 ]]; then
            return 0
        fi

        if [[ $attempt -lt $MAX_XCODEBUILD_RETRIES ]] && xcodebuild_needs_simulator_retry "$rc" "$log_path"; then
            info "[$slug/$appearance] simulator destination dropped; restarting CoreSimulatorService and retrying (${attempt}/${MAX_XCODEBUILD_RETRIES})"
            restart_simulator_services
            continue
        fi

        return "$rc"
    done
}

# ---------------------------------------------------------------------------
# 1. Build Crystal static library
# ---------------------------------------------------------------------------

info "Building libhighost.a for iOS simulator..."
"$IOS_DIR/build_crystal_lib.sh" simulator

[[ -f "$IOS_DIR/build/libhighost.a" ]] || fail "libhighost.a missing after build"
ok "libhighost.a ready"

# ---------------------------------------------------------------------------
# 2. Generate Xcode project
# ---------------------------------------------------------------------------

info "Generating Xcode project..."
(cd "$IOS_DIR" && xcodegen generate --spec project.yml)
ok "CrystalHIGHost.xcodeproj generated"

# ---------------------------------------------------------------------------
# 3. Collect slugs
# ---------------------------------------------------------------------------

if [[ -n "$ONLY_SLUG" ]]; then
    SLUGS="$ONLY_SLUG"
else
    SLUGS="$(jq -r '.pages[] | select((.role == "component") or ((.status == "implemented") and (.ui_view != null) and (.validation_state != "skipped"))) | .slug' "$WORKLIST")"
fi

# ---------------------------------------------------------------------------
# 4. Run tests per slug + extract screenshots
# ---------------------------------------------------------------------------

# Resolve a real iOS 26 simulator once and make sure xcodebuild can see it
# before the per-slug loop starts. This avoids burning time on placeholder
# destinations when CoreSimulatorService has fallen over.
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
ensure_simulator_ready

# Two appearances per slug (iteration-16 acceptance bar). TEST_RUNNER_*
# is the prefix xcodebuild forwards into the test-host process env.
APPEARANCES=("light" "dark")

BACKDROPS_DIR="$PROJECT_ROOT/.claude/skills/apple-platform-guide/validation/backdrops"

for slug in $SLUGS; do
    for appearance in "${APPEARANCES[@]}"; do
        info "=== $slug ($appearance) ==="
        xcresult="$XCRESULT_DIR/${slug}-${appearance}.xcresult"
        rm -rf "$xcresult"

        # Auto-select backdrop from worklist `backdrop` field (Phase 0.3 schema).
        # If HIG_BACKDROP_PATH is already set externally, honour it; otherwise
        # look up the stem from the worklist row and resolve the iOS-specific
        # variant (<stem>-ios-<appearance>.png, fallback to <stem>-<appearance>.png).
        RESOLVED_BACKDROP="${HIG_BACKDROP_PATH:-}"
        if [[ -z "$RESOLVED_BACKDROP" ]]; then
            STEM="$(jq -r --arg s "$slug" '.pages[] | select(.slug == $s) | .backdrop // empty' "$WORKLIST" 2>/dev/null || true)"
            if [[ -n "$STEM" ]]; then
                # Prefer the iOS-specific variant; fall back to the shared variant.
                IOS_CANDIDATE="$BACKDROPS_DIR/${STEM}-ios-${appearance}.png"
                SHARED_CANDIDATE="$BACKDROPS_DIR/${STEM}-${appearance}.png"
                if [[ -f "$IOS_CANDIDATE" ]]; then
                    RESOLVED_BACKDROP="$IOS_CANDIDATE"
                elif [[ -f "$SHARED_CANDIDATE" ]]; then
                    RESOLVED_BACKDROP="$SHARED_CANDIDATE"
                fi
            fi
        fi

        if [[ -n "$RESOLVED_BACKDROP" ]]; then
            info "  backdrop: $RESOLVED_BACKDROP"
        fi

        set +e
        run_xcodebuild_test "$slug" "$appearance" "$xcresult" "$RESOLVED_BACKDROP"
        rc=$?
        set -e

        if [[ $rc -ne 0 ]]; then
            info "[$slug/$appearance] xcodebuild returned $rc (continuing to extract any screenshot)"
        fi

        att_dir="$XCRESULT_DIR/${slug}-${appearance}-attach"
        rm -rf "$att_dir"
        xcrun xcresulttool export attachments \
            --path "$xcresult" \
            --output-path "$att_dir" >/dev/null 2>&1 || true

        out="$SCREENSHOT_DIR/${slug}-ios-${appearance}.png"
        png="$(ls "$att_dir"/*.png 2>/dev/null | head -1 || true)"
        if [[ -z "$png" ]]; then
            info "[$slug/$appearance] no PNG attachment found under $att_dir"
            continue
        fi
        cp "$png" "$out"
        ok "[$slug/$appearance] -> $out"
    done
done

ok "Done."
