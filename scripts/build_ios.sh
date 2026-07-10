#!/usr/bin/env bash
# Build a Crystal shared library for iOS (device or simulator).
#
# Usage:
#   ./scripts/build_ios.sh <source.cr> [device|simulator] [output_name]
#
# Examples:
#   ./scripts/build_ios.sh src/my_app.cr device
#   ./scripts/build_ios.sh src/my_app.cr simulator libmyapp
#
# Prerequisites:
#   - Crystal compiler on PATH (or set CRYSTAL env var)
#   - Xcode + iOS SDK installed
#   - libgc.a + libpcre2-8.a already cross-compiled (run cross_compile_deps.sh first)
#     or set CRYSTAL_CROSS_DEPS to a directory containing ios-device/ or ios-simulator/
#
# Output:
#   build/ios-device/<name>.dylib   (or .a for static)
#   build/ios-simulator/<name>.dylib
#
# The dylib can be embedded in an Xcode project as a framework or linked
# directly. Add ios/CrystalBridge.h as your Xcode bridging header.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CRYSTAL="${CRYSTAL:-crystal}"
CROSS_DEPS="${CRYSTAL_CROSS_DEPS:-/tmp/crystal-cross-deps}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-17.0}"
CRYSTAL_REPO="${CRYSTAL_REPO:-$(cd "$(dirname "$0")/../.." && pwd)/crystal}"
BUILD_DIR="${BUILD_DIR:-$(cd "$(dirname "$0")/.." && pwd)/build}"

# Flags passed to Crystal. Disable features that do not make sense in a
# mobile shared library (no TLS, no XML parsing; full String/Array/Hash
# stdlib is available with the cross-compiled libgc + libpcre2).
CRYSTAL_FLAGS="${CRYSTAL_FLAGS:--Dwithout_openssl -Dwithout_xml}"

# Extra linker flags (e.g. frameworks your Crystal code uses)
EXTRA_LINK_FLAGS="${EXTRA_LINK_FLAGS:-}"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <source.cr> [device|simulator] [output_name]"
    echo ""
    echo "Arguments:"
    echo "  source.cr     Crystal source file to compile"
    echo "  device        Build for physical iOS device (default)"
    echo "  simulator     Build for iOS Simulator (arm64 on Apple Silicon)"
    echo "  output_name   Base name for output library (default: source filename stem)"
    echo ""
    echo "Environment variables:"
    echo "  CRYSTAL              Crystal binary to use (default: crystal)"
    echo "  CRYSTAL_CROSS_DEPS   Directory with ios-device/ and ios-simulator/ (default: /tmp/crystal-cross-deps)"
    echo "  IOS_DEPLOYMENT_TARGET  Minimum iOS version (default: 17.0)"
    echo "  CRYSTAL_FLAGS        Extra -D flags for crystal build"
    echo "  EXTRA_LINK_FLAGS     Extra flags passed to xcrun clang at link time"
    exit 1
fi

SOURCE="$1"
VARIANT="${2:-device}"
STEM="${3:-$(basename "${SOURCE%.cr}")}"

[[ -f "$SOURCE" ]] || { echo "ERROR: Source file not found: $SOURCE" >&2; exit 1; }
[[ "$VARIANT" == "device" || "$VARIANT" == "simulator" ]] \
    || { echo "ERROR: Second argument must be 'device' or 'simulator', got: $VARIANT" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info() { echo "==> $*"; }
step() { echo "  -> $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

check_tool() {
    command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not found in PATH."
}

# ---------------------------------------------------------------------------
# Resolve platform-specific settings
# ---------------------------------------------------------------------------

if [[ "$VARIANT" == "device" ]]; then
    CRYSTAL_TARGET="aarch64-apple-ios${IOS_DEPLOYMENT_TARGET}"
    XCODE_SDK="iphoneos"
    DEPS_DIR="${CROSS_DEPS}/ios-device"
    CLANG_TARGET="arm64-apple-ios${IOS_DEPLOYMENT_TARGET}"
    OUT_SUBDIR="ios-device"
    info "Target: iOS Device (${CLANG_TARGET})"
else
    CRYSTAL_TARGET="aarch64-apple-ios${IOS_DEPLOYMENT_TARGET}-simulator"
    XCODE_SDK="iphonesimulator"
    DEPS_DIR="${CROSS_DEPS}/ios-simulator"
    CLANG_TARGET="arm64-apple-ios${IOS_DEPLOYMENT_TARGET}-simulator"
    OUT_SUBDIR="ios-simulator"
    info "Target: iOS Simulator (${CLANG_TARGET})"
fi

OUT_DIR="${BUILD_DIR}/${OUT_SUBDIR}"
OBJECT_FILE="${OUT_DIR}/${STEM}.o"
DYLIB_FILE="${OUT_DIR}/lib${STEM}.dylib"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

check_tool xcrun
check_tool "$CRYSTAL"

if [[ ! -f "${DEPS_DIR}/lib/libgc.a" ]]; then
    echo "ERROR: libgc.a not found at ${DEPS_DIR}/lib/libgc.a" >&2
    echo "       Run: ./scripts/cross_compile_deps.sh ios" >&2
    exit 1
fi

if [[ ! -f "${DEPS_DIR}/lib/libpcre2-8.a" ]]; then
    echo "ERROR: libpcre2-8.a not found at ${DEPS_DIR}/lib/libpcre2-8.a" >&2
    echo "       Run: ./scripts/cross_compile_deps.sh ios" >&2
    exit 1
fi

SDK_PATH="$(xcrun --sdk "${XCODE_SDK}" --show-sdk-path)"
XCRUN_CLANG="$(xcrun --sdk "${XCODE_SDK}" --find clang)"

# ---------------------------------------------------------------------------
# Step 1: Crystal cross-compile -> object file
# ---------------------------------------------------------------------------

mkdir -p "$OUT_DIR"

info "Step 1/2: Crystal cross-compile"
step "Source:  $SOURCE"
step "Target:  $CRYSTAL_TARGET"
step "Output:  $OBJECT_FILE"

# Crystal --cross-compile emits an .o file and prints the linker command.
# We capture the printed command but use our own link step (Step 2) instead,
# because we have additional link flags and need the shared library format.
"$CRYSTAL" build "$SOURCE" \
    --cross-compile \
    --target "$CRYSTAL_TARGET" \
    --shared \
    $CRYSTAL_FLAGS \
    -o "${OUT_DIR}/${STEM}"

# Crystal --cross-compile writes <stem>.o
[[ -f "$OBJECT_FILE" ]] \
    || die "Crystal did not produce $OBJECT_FILE"

step "Object file produced:"
file "$OBJECT_FILE"

# ---------------------------------------------------------------------------
# Step 2: Link with xcrun clang -> .dylib
# ---------------------------------------------------------------------------

info "Step 2/2: Linking shared library"
step "Output:  $DYLIB_FILE"

"$XCRUN_CLANG" \
    -target "${CLANG_TARGET}" \
    -isysroot "${SDK_PATH}" \
    -dynamiclib \
    -install_name "@rpath/lib${STEM}.dylib" \
    -o "$DYLIB_FILE" \
    "$OBJECT_FILE" \
    "${DEPS_DIR}/lib/libgc.a" \
    "${DEPS_DIR}/lib/libpcre2-8.a" \
    -framework UIKit \
    -framework Foundation \
    -framework CoreFoundation \
    -framework UserNotifications \
    -framework WebKit \
    -framework MapKit \
    -framework CoreLocation \
    -framework AVKit \
    -framework AVFoundation \
    ${EXTRA_LINK_FLAGS}

step "Library produced:"
file "$DYLIB_FILE"
ls -lh "$DYLIB_FILE"

# ---------------------------------------------------------------------------
# Step 3: Copy bridge header
# ---------------------------------------------------------------------------

BRIDGE_HEADER="$(dirname "$0")/../../../crystal/samples/cross_platform/ios/CrystalBridge.h"
if [[ -f "$BRIDGE_HEADER" ]]; then
    cp "$BRIDGE_HEADER" "${OUT_DIR}/CrystalBridge.h"
    step "Copied CrystalBridge.h to ${OUT_DIR}/"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "Build successful!"
echo ""
echo "  Library:       $DYLIB_FILE"
echo "  Bridge header: ${OUT_DIR}/CrystalBridge.h"
echo ""
echo "Xcode integration:"
echo "  1. Drag $DYLIB_FILE into your Xcode project"
echo "  2. Set 'Build Settings > Objective-C Bridging Header' to CrystalBridge.h"
echo "  3. Add the library directory to 'Build Settings > Library Search Paths'"
echo "  4. Call crystal_init() from your AppDelegate before using any Crystal functions"
echo ""
echo "See CROSS_COMPILE.md for full integration guide."
