#!/usr/bin/env bash
# Build a Crystal shared library for Android (arm64-v8a, API 31+).
#
# Usage:
#   ./scripts/build_android.sh <source.cr> [output_name]
#
# Examples:
#   ./scripts/build_android.sh src/my_app.cr
#   ./scripts/build_android.sh src/my_app.cr myapp
#
# Prerequisites:
#   - Crystal compiler on PATH (or set CRYSTAL env var)
#   - Android NDK installed (set ANDROID_NDK_HOME)
#   - libgc.a + libpcre2-8.a already cross-compiled (run cross_compile_deps.sh first)
#     or set CRYSTAL_CROSS_DEPS to a directory containing android-arm64/
#
# Output:
#   build/android-arm64/lib<name>.so
#
# The .so can be loaded from Kotlin/Java via System.loadLibrary("<name>").
# The JNI bridge in samples/cross_platform/android/jni_bridge.c provides
# a template for wiring Crystal functions into JNI_OnLoad.
#
# Extra native sources:
#   Set EXTRA_C_SOURCES to a space-separated list of C sources that should be
#   compiled with the NDK clang and linked into the final shared library.
#   This is how Android JNI bridge files and renderer support shims are added.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CRYSTAL="${CRYSTAL:-crystal}"
CROSS_DEPS="${CRYSTAL_CROSS_DEPS:-/tmp/crystal-cross-deps}"
ANDROID_API="${ANDROID_API:-31}"
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-/opt/homebrew/share/android-commandlinetools/ndk/28.2.13676358}"
BUILD_DIR="${BUILD_DIR:-$(cd "$(dirname "$0")/.." && pwd)/build}"

# Flags passed to Crystal. Disable OpenSSL and LibXML2 which are not
# available in NDK sysroot. All other stdlib modules are available.
CRYSTAL_FLAGS="${CRYSTAL_FLAGS:--Dwithout_openssl -Dwithout_xml}"

# Extra flags passed to NDK clang at link time (e.g. -llog for Android logging)
EXTRA_LINK_FLAGS="${EXTRA_LINK_FLAGS:--llog -lz}"

# Optional extra C sources to compile and link into the final shared object.
EXTRA_C_SOURCES="${EXTRA_C_SOURCES:-}"

# Optional extra CFLAGS for additional include paths or feature defines.
EXTRA_CFLAGS="${EXTRA_CFLAGS:-}"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <source.cr> [output_name]"
    echo ""
    echo "Arguments:"
    echo "  source.cr     Crystal source file to compile"
    echo "  output_name   Base name for output library (default: source filename stem)"
    echo ""
    echo "Environment variables:"
    echo "  CRYSTAL              Crystal binary to use (default: crystal)"
    echo "  CRYSTAL_CROSS_DEPS   Directory with android-arm64/ (default: /tmp/crystal-cross-deps)"
    echo "  ANDROID_API          Android minimum API level (default: 31)"
    echo "  ANDROID_NDK_HOME     Path to Android NDK"
    echo "  CRYSTAL_FLAGS        Extra -D flags for crystal build"
    echo "  EXTRA_LINK_FLAGS     Extra flags passed to NDK clang at link time"
    exit 1
fi

SOURCE="$1"
STEM="${2:-$(basename "${SOURCE%.cr}")}"

[[ -f "$SOURCE" ]] || { echo "ERROR: Source file not found: $SOURCE" >&2; exit 1; }

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
# Locate NDK clang
# ---------------------------------------------------------------------------

info "Target: Android arm64 (aarch64-linux-android${ANDROID_API})"

[[ -d "$ANDROID_NDK_HOME" ]] \
    || die "Android NDK not found at '$ANDROID_NDK_HOME'. Set ANDROID_NDK_HOME."

NDK_HOST_TAG=""
for tag in darwin-x86_64 linux-x86_64; do
    if [[ -d "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$tag" ]]; then
        NDK_HOST_TAG="$tag"
        break
    fi
done
[[ -n "$NDK_HOST_TAG" ]] \
    || die "Cannot find NDK prebuilt toolchain under $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/"

NDK_TOOLCHAIN="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${NDK_HOST_TAG}/bin"
NDK_CLANG="${NDK_TOOLCHAIN}/aarch64-linux-android${ANDROID_API}-clang"
NDK_STRIP="${NDK_TOOLCHAIN}/llvm-strip"

[[ -x "$NDK_CLANG" ]] \
    || die "NDK clang not found: $NDK_CLANG"

# ---------------------------------------------------------------------------
# Configuration (derived)
# ---------------------------------------------------------------------------

CRYSTAL_TARGET="aarch64-linux-android${ANDROID_API}"
DEPS_DIR="${CROSS_DEPS}/android-arm64"
OUT_DIR="${BUILD_DIR}/android-arm64"
OBJECT_FILE="${OUT_DIR}/${STEM}.o"
SO_FILE="${OUT_DIR}/lib${STEM}.so"
C_OBJECTS=()

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

check_tool "$CRYSTAL"

if [[ ! -f "${DEPS_DIR}/lib/libgc.a" ]]; then
    echo "ERROR: libgc.a not found at ${DEPS_DIR}/lib/libgc.a" >&2
    echo "       Run: ./scripts/cross_compile_deps.sh android" >&2
    exit 1
fi

if [[ ! -f "${DEPS_DIR}/lib/libpcre2-8.a" ]]; then
    echo "ERROR: libpcre2-8.a not found at ${DEPS_DIR}/lib/libpcre2-8.a" >&2
    echo "       Run: ./scripts/cross_compile_deps.sh android" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 1: Crystal cross-compile -> object file
# ---------------------------------------------------------------------------

mkdir -p "$OUT_DIR"

info "Step 1/2: Crystal cross-compile"
step "Source:  $SOURCE"
step "Target:  $CRYSTAL_TARGET"
step "Output:  $OBJECT_FILE"

"$CRYSTAL" build "$SOURCE" \
    --cross-compile \
    --target "$CRYSTAL_TARGET" \
    $CRYSTAL_FLAGS \
    -o "${OUT_DIR}/${STEM}"

[[ -f "$OBJECT_FILE" ]] \
    || die "Crystal did not produce $OBJECT_FILE"

step "Object file produced:"
file "$OBJECT_FILE"

# ---------------------------------------------------------------------------
# Step 1.5: Compile extra C bridge sources
# ---------------------------------------------------------------------------

if [[ -n "$EXTRA_C_SOURCES" ]]; then
    info "Step 1.5/2: Compiling extra C sources"
    for source in $EXTRA_C_SOURCES; do
        [[ -f "$source" ]] || die "Extra C source not found: $source"
        obj_name="$(basename "${source%.*}")"
        obj_path="${OUT_DIR}/${obj_name}.o"
        step "Compiling: $source -> $obj_path"
        "$NDK_CLANG" \
            --target="aarch64-linux-android${ANDROID_API}" \
            -c \
            -fPIC \
            $EXTRA_CFLAGS \
            "$source" \
            -o "$obj_path"
        C_OBJECTS+=("$obj_path")
    done
fi

# ---------------------------------------------------------------------------
# Step 2: Link with NDK clang -> .so
# ---------------------------------------------------------------------------

info "Step 2/2: Linking shared library"
step "Output:  $SO_FILE"

# -fPIC: Position-independent code required for shared libraries on Android.
# -Wl,--build-id: Adds a GNU build ID, required by Android's linker since API 23.
# -Wl,--no-undefined: Fail at link time if any symbol is unresolved.
# -Wl,-z,noexecstack: Security hardening required by the Play Store.
"$NDK_CLANG" \
    --target="aarch64-linux-android${ANDROID_API}" \
    -shared \
    -fPIC \
    -o "$SO_FILE" \
    "$OBJECT_FILE" \
    "${C_OBJECTS[@]}" \
    "${DEPS_DIR}/lib/libgc.a" \
    "${DEPS_DIR}/lib/libpcre2-8.a" \
    -Wl,--build-id \
    -Wl,--no-undefined \
    -Wl,-z,noexecstack \
    -lc \
    -lm \
    -ldl \
    ${EXTRA_LINK_FLAGS}

step "Library produced:"
file "$SO_FILE"
ls -lh "$SO_FILE"

# ---------------------------------------------------------------------------
# Optional: strip debug symbols for release
# ---------------------------------------------------------------------------

if [[ "${STRIP:-0}" == "1" ]]; then
    step "Stripping debug symbols"
    "$NDK_STRIP" --strip-unneeded "$SO_FILE"
    ls -lh "$SO_FILE"
fi

# ---------------------------------------------------------------------------
# Verify JNI_OnLoad is exported (if present)
# ---------------------------------------------------------------------------

NDK_NM="${NDK_TOOLCHAIN}/llvm-nm"
if [[ -x "$NDK_NM" ]]; then
    if "$NDK_NM" --defined-only --extern-only "$SO_FILE" 2>/dev/null | grep -q "JNI_OnLoad"; then
        step "JNI_OnLoad symbol verified present in $SO_FILE"
    else
        step "Note: JNI_OnLoad not found. Add it to your source or a C bridge file."
    fi
fi

# ---------------------------------------------------------------------------
# Show Crystal-exported symbols
# ---------------------------------------------------------------------------

if [[ -x "$NDK_NM" ]]; then
    CRYSTAL_SYMBOLS=$("$NDK_NM" --defined-only --extern-only "$SO_FILE" 2>/dev/null \
        | grep -E "crystal_|^[0-9a-f]+ T crystal" | head -20 || true)
    if [[ -n "$CRYSTAL_SYMBOLS" ]]; then
        step "Crystal-exported symbols (first 20):"
        echo "$CRYSTAL_SYMBOLS" | while read -r line; do echo "     $line"; done
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "Build successful!"
echo ""
echo "  Library: $SO_FILE"
echo ""
echo "Android Studio integration:"
echo "  1. Copy $SO_FILE to app/src/main/jniLibs/arm64-v8a/"
echo "  2. In Kotlin/Java: System.loadLibrary(\"${STEM}\")"
echo "  3. Declare native methods with 'external' keyword in Kotlin"
echo "     (or 'native' in Java), matching the JNI naming convention:"
echo "     Java_<package_underscored>_<ClassName>_<methodName>"
echo ""
echo "JNI bridge template:"
echo "  samples/cross_platform/android/jni_bridge.c"
echo ""
echo "See CROSS_COMPILE.md for full integration guide."
