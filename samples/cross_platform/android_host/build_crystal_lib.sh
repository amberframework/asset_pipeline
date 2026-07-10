#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HOST_LIB_DIR="$SCRIPT_DIR/app/src/main/jniLibs/arm64-v8a"
OUTPUT_NAME="${OUTPUT_NAME:-android_material_host}"
BRIDGE_SRC="$SCRIPT_DIR/android_material_bridge.cr"

mkdir -p "$HOST_LIB_DIR"

EXTRA_C_SOURCES="${PROJECT_ROOT}/src/ui/native/android_bridge.c ${PROJECT_ROOT}/src/ui/native/jni_collection_bridge.c ${SCRIPT_DIR}/android_host_jni.c" \
  "${PROJECT_ROOT}/scripts/build_android.sh" "$BRIDGE_SRC" "$OUTPUT_NAME"

cp "${PROJECT_ROOT}/build/android-arm64/lib${OUTPUT_NAME}.so" "${HOST_LIB_DIR}/lib${OUTPUT_NAME}.so"
echo "Copied lib${OUTPUT_NAME}.so to ${HOST_LIB_DIR}"
