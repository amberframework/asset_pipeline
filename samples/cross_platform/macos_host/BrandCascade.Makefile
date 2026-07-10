# Makefile for the Phase 1 brand cascade demo (macOS / AppKit).
#
# Builds `brand_cascade_demo.cr` into a signed binary that renders a
# UI::VStack + UI::Button using `Tokens.default.with_brand(SentinelBrand.new)`
# and captures a PNG of the rendered window. The validator flips the
# `BRAND_PRIMARY_HEX` constant in `brand_cascade_demo.cr` and re-runs to
# confirm the sentinel color cascades to the rendered pixel.
#
# Usage (from this directory):
#   make -f BrandCascade.Makefile build
#   HIG_SCREENSHOT_PATH=/tmp/brand_cascade_macos.png ./bin/brand_cascade_demo

PROJECT_DIR := $(shell pwd)
SHARD_ROOT  := $(abspath $(PROJECT_DIR)/../../..)

CRYSTAL     := crystal-alpha
BIN         := bin/brand_cascade_demo
SRC         := brand_cascade_demo.cr

CODESIGN_IDENTITY ?= -

AP_BRIDGE     := $(SHARD_ROOT)/src/ui/native/objc_bridge.o
AP_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/objc_bridge.m

# AssetPipelineSwiftKit — the Swift companion library Phase 3a routes
# UI::Button (and every later widget Dispatch B migrates) through. The
# Crystal renderer calls `apsk_make_button(...)` via the C trampolines
# in `swiftkit_bridge.m`; `swiftkit_bridge.o` is the ObjC glue and the
# static `libAssetPipelineSwiftKit.a` is the Swift facade implementation.
SWIFTKIT_DIR        := $(SHARD_ROOT)/swift/AssetPipelineSwiftKit
SWIFTKIT_LIB        := $(SWIFTKIT_DIR)/.build/release/libAssetPipelineSwiftKit.a
SWIFTKIT_BRIDGE     := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.o
SWIFTKIT_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.m

WIN_HELPER     := $(PROJECT_DIR)/window_helper.o
WIN_HELPER_SRC := $(PROJECT_DIR)/window_helper.m

MACOS_FRAMEWORKS := -framework AppKit -framework Foundation \
	-framework SwiftUI -framework Combine \
	-framework ApplicationServices -framework CoreFoundation \
	-framework CoreGraphics -framework ImageIO -framework QuartzCore \
	-framework UserNotifications \
	-framework WebKit -framework MapKit -framework CoreLocation -framework AVKit -framework AVFoundation \
	-lobjc

# Swift runtime: the AssetPipelineSwiftKit static archive references
# Swift stdlib symbols (`swift_release`, `swift_bridgeObjectRetain`,
# `$sSSN`, etc.) plus the FORCE_LOAD bootstrap symbols Swift emits for
# every Apple framework it imports (UniformTypeIdentifiers, Combine,
# SwiftUI, etc.). The dylibs live in two places:
#
#   - macOS Big Sur+ : `/usr/lib/swift` ships a tiny stub set bundled
#     with the OS for ABI-stable Swift binaries.
#   - The full toolchain set is under Xcode's
#     `XcodeDefault.xctoolchain/usr/lib/swift-5.0/macosx`.
#
# We add both search paths and link the libraries explicitly. Swift's
# autolink machinery emits `LC_LINKER_OPTION` directives inside the
# .a, but `ld64.lld` (Crystal's default linker on macOS) ignores those
# directives — so passing `-l<lib>` flags is required. Discovered
# during Phase 3a's first end-to-end link attempt; the previous
# `libAssetPipelineSwiftKit.a`-only line silently dropped the SwiftUI
# facade classes via dead-code stripping.
SWIFT_TOOLCHAIN_LIB := $(shell xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.0/macosx
SWIFT_RUNTIME := -L/usr/lib/swift -L$(SWIFT_TOOLCHAIN_LIB) \
	-lswiftCore -lswiftFoundation \
	-lswiftCoreFoundation -lswiftObjectiveC \
	-lswiftDispatch -lswiftDarwin -lswiftIOKit -lswiftos \
	-lswiftQuartzCore -lswiftMetal -lswiftCoreImage -lswiftCoreGraphics \
	-lswiftXPC -lswiftsimd -lswiftAppKit \
	-lswiftUniformTypeIdentifiers -lswiftOSLog \
	-lswift_Concurrency \
	-Wl,-rpath,$(SWIFT_TOOLCHAIN_LIB)

# The Swift runtime lives at /usr/lib/swift on macOS 13+; embedding the
# rpath lets the binary load Foundation/SwiftUI without a system-wide
# DYLD_LIBRARY_PATH dance.
# `-force_load $(SWIFTKIT_LIB)` is REQUIRED: the AssetPipelineSwiftKit
# static archive's `APSK*` classes are referenced only from
# `objc_getClass(...)` lookups inside `swiftkit_bridge.m`. Apple's ld
# (and ld64) treat unreferenced ObjC classes inside .a archives as dead
# code by default — without `-force_load`, the Swift facade symbols are
# stripped, `apsk_make_button` returns NULL, and every hosted SwiftUI
# view collapses to a zero-size NSView (the failure mode observed during
# the Phase 3a integration spin-up).
MACOS_LINK_FLAGS := $(AP_BRIDGE) $(SWIFTKIT_BRIDGE) $(WIN_HELPER) \
	-Wl,-force_load,$(SWIFTKIT_LIB) \
	$(MACOS_FRAMEWORKS) \
	$(SWIFT_RUNTIME) \
	-Wl,-rpath,/usr/lib/swift

.PHONY: build run ext-ap ext-win ext-swiftkit ext-swiftkit-lib clean

build: ext-ap ext-swiftkit ext-swiftkit-lib ext-win $(BIN)

$(BIN): $(SRC) ext-ap ext-swiftkit ext-swiftkit-lib ext-win
	@mkdir -p bin
	$(CRYSTAL) build $(SRC) -o $(BIN) -Dmacos \
		--link-flags="$(MACOS_LINK_FLAGS)"
	@if [ "$(CODESIGN_IDENTITY)" != "-" ]; then \
		codesign --force --sign "$(CODESIGN_IDENTITY)" --timestamp=none $(BIN); \
	fi

run: build
	@HIG_SCREENSHOT_PATH=$${HIG_SCREENSHOT_PATH:-/tmp/brand_cascade_macos.png} ./$(BIN)

ext-ap: $(AP_BRIDGE)
$(AP_BRIDGE): $(AP_BRIDGE_SRC)
	clang -c $(AP_BRIDGE_SRC) -o $(AP_BRIDGE) -fno-objc-arc

ext-swiftkit: $(SWIFTKIT_BRIDGE)
$(SWIFTKIT_BRIDGE): $(SWIFTKIT_BRIDGE_SRC)
	clang -c $(SWIFTKIT_BRIDGE_SRC) -o $(SWIFTKIT_BRIDGE) -fno-objc-arc

# `swift build -c release` produces the static archive at
# .build/release/libAssetPipelineSwiftKit.a. The build is idempotent;
# Swift Package Manager detects file mtimes itself.
ext-swiftkit-lib: $(SWIFTKIT_LIB)
$(SWIFTKIT_LIB): $(wildcard $(SWIFTKIT_DIR)/Sources/AssetPipelineSwiftKit/*.swift) \
                 $(wildcard $(SWIFTKIT_DIR)/Sources/AssetPipelineSwiftKit/**/*.swift) \
                 $(SWIFTKIT_DIR)/Package.swift
	swift build -c release --package-path $(SWIFTKIT_DIR)

ext-win: $(WIN_HELPER)
$(WIN_HELPER): $(WIN_HELPER_SRC)
	clang -c $(WIN_HELPER_SRC) -o $(WIN_HELPER) -fno-objc-arc

clean:
	rm -f $(BIN) $(SWIFTKIT_BRIDGE)
	rm -rf bin
	rm -rf $(SWIFTKIT_DIR)/.build
