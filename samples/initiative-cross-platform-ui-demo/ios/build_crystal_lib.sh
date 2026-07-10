#!/usr/bin/env bash
# Cascade iOS bridge — cross-compile script. Pattern mirrors
# samples/cross_platform/ios_host/build_crystal_lib.sh; the only
# differences are the source path (bridge.cr) and the output name
# (libcascade.a vs libhighost.a).
#
# Output: samples/initiative-cross-platform-ui-demo/ios/build/libcascade.a
#
# Usage: ./build_crystal_lib.sh [simulator|device]

set -euo pipefail

CRYSTAL=${CRYSTAL:-crystal-alpha}
BUILD_TARGET="${1:-simulator}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_LIB="$BUILD_DIR/libcascade.a"
BRIDGE_SRC="$SCRIPT_DIR/bridge.cr"
BRIDGE_BASE="$BUILD_DIR/bridge"

MIN_IOS_VER="16.0"

case "$BUILD_TARGET" in
    simulator)
        LLVM_TARGET="arm64-apple-ios-simulator"
        SDK_NAME="iphonesimulator"
        ;;
    device)
        LLVM_TARGET="arm64-apple-ios"
        SDK_NAME="iphoneos"
        ;;
    *)
        echo "Usage: $0 [simulator|device]" >&2
        exit 1
        ;;
esac

info()  { printf '\033[0;34m[cascade-build]\033[0m %s\n' "$*"; }
ok()    { printf '\033[0;32m[ok]\033[0m            %s\n' "$*"; }
fail()  { printf '\033[0;31m[fail]\033[0m          %s\n' "$*" >&2; exit 1; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

require_cmd "$CRYSTAL"
require_cmd xcrun
require_cmd xcodebuild

[[ ! -f "$BRIDGE_SRC" ]] && fail "Bridge source not found: $BRIDGE_SRC"

SDK_PATH="$(xcrun --sdk $SDK_NAME --show-sdk-path)"
CLANG="$(xcrun --sdk $SDK_NAME --find clang)"

info "Target         : $LLVM_TARGET"
info "SDK            : $SDK_PATH"
info "Bridge source  : $BRIDGE_SRC"

mkdir -p "$BUILD_DIR"

# Step 1: asset_pipeline ObjC bridge.
AP_BRIDGE_SRC="$PROJECT_ROOT/src/ui/native/objc_bridge.m"
AP_BRIDGE_OBJ="$BUILD_DIR/objc_bridge_ios.o"
if [[ -f "$AP_BRIDGE_SRC" ]]; then
    info "Compiling asset_pipeline ObjC bridge for $BUILD_TARGET..."
    "$CLANG" -c "$AP_BRIDGE_SRC" -o "$AP_BRIDGE_OBJ" \
        -target "$LLVM_TARGET" -isysroot "$SDK_PATH" \
        -mios-version-min=$MIN_IOS_VER -fno-objc-arc
    ok "ObjC bridge compiled"
fi

# Step 2: AssetPipelineSwiftKit C trampolines + Swift facade.
SWIFTKIT_BRIDGE_SRC="$PROJECT_ROOT/src/ui/native/swiftkit_bridge.m"
SWIFTKIT_BRIDGE_OBJ="$BUILD_DIR/swiftkit_bridge_ios.o"
SWIFTKIT_PACKAGE_DIR="$PROJECT_ROOT/swift/AssetPipelineSwiftKit"
SWIFTKIT_BUILD_TARGET="$BUILD_DIR/swiftkit_${BUILD_TARGET}.a"

if [[ -f "$SWIFTKIT_BRIDGE_SRC" ]]; then
    info "Compiling AssetPipelineSwiftKit C trampolines for $BUILD_TARGET..."
    "$CLANG" -c "$SWIFTKIT_BRIDGE_SRC" -o "$SWIFTKIT_BRIDGE_OBJ" \
        -target "$LLVM_TARGET" -isysroot "$SDK_PATH" \
        -mios-version-min=$MIN_IOS_VER -fno-objc-arc
    ok "SwiftKit C trampolines compiled"
fi

info "Compiling AssetPipelineSwiftKit Swift facade for $BUILD_TARGET..."
swift build -c release --package-path "$SWIFTKIT_PACKAGE_DIR" \
    --triple "$LLVM_TARGET" --sdk "$SDK_PATH"

SWIFTKIT_SRC_LIB="$SWIFTKIT_PACKAGE_DIR/.build/$LLVM_TARGET/release/libAssetPipelineSwiftKit.a"
if [[ -f "$SWIFTKIT_SRC_LIB" ]]; then
    cp "$SWIFTKIT_SRC_LIB" "$SWIFTKIT_BUILD_TARGET"
    ok "SwiftKit static library staged at $SWIFTKIT_BUILD_TARGET"
fi

# Step 3: cross-compile Crystal bridge.
info "Cross-compiling Crystal bridge..."
"$CRYSTAL" build "$BRIDGE_SRC" --cross-compile \
    --target="$LLVM_TARGET" -Dios -o "$BRIDGE_BASE"
ok "Crystal cross-compilation complete"

# Step 4: hide _main to coexist with Swift @main.
info "Hiding _main symbol..."
if [[ -f "$BRIDGE_BASE.o" ]]; then
    ld -r -unexported_symbol _main "$BRIDGE_BASE.o" -o "$BUILD_DIR/bridge_fixed.o"
    mv "$BUILD_DIR/bridge_fixed.o" "$BRIDGE_BASE.o"
    ok "_main symbol hidden"
fi

# Step 5: pack into static library.
info "Creating static library..."
OBJ_FILES="$BRIDGE_BASE.o"
[[ -f "$AP_BRIDGE_OBJ" ]] && OBJ_FILES="$OBJ_FILES $AP_BRIDGE_OBJ"
[[ -f "$SWIFTKIT_BRIDGE_OBJ" ]] && OBJ_FILES="$OBJ_FILES $SWIFTKIT_BRIDGE_OBJ"
ar rcs "$OUTPUT_LIB" $OBJ_FILES
ok "Static library created: $OUTPUT_LIB"
