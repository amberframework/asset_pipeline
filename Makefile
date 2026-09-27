# Phase 10C.0 — Root Makefile for the asset_pipeline shard repo.
#
# Targets:
#   test-web       — runs the default web spec lane with plain `crystal`.
#   test-macos     — runs the macOS native spec lane with `acrystal -Dmacos -Dwithout_mt`
#                    + ObjC bridge + AppKit/ApplicationServices framework
#                    link flags. Requires the macOS SwiftKit static lib
#                    (built via `swift build -c release`).
#   test-ios       — placeholder; see docs/initiative-cross-platform-ui/native-compile-matrix.md
#                    Currently `attempted-blocked` on cross-compiled libgc.
#                    Implementation deferred to Phase 10D / native runner phase.
#   test-android   — placeholder; see native-compile-matrix.md.
#                    Currently `attempted-blocked` on Crystal stdlib host-only.
#                    Implementation deferred to Phase 10D / native runner phase.
#   test-all       — runs `test-web` + `test-macos`.
#   lint           — runs Phase 10A.0a's convention-rule runner
#                    (`scripts/lint_conventions.cr`).
#
# Bridge object file lifecycle:
#   `make test-macos` depends on `src/ui/native/objc_bridge.o`
#   (`$(AP_BRIDGE_OBJ)`), `src/ui/native/swiftkit_bridge.o`
#   (`$(SK_BRIDGE_OBJ)`), and the spec-only first-responder test bridge.
#   All are compiled with `-fno-objc-arc`
#   (the bridges manage their own memory). The `.o` files are .gitignored
#   build artifacts — never check them in.

CRYSTAL       ?= crystal
ACRYSTAL      ?= acrystal

AP_BRIDGE_OBJ := src/ui/native/objc_bridge.o
AP_BRIDGE_SRC := src/ui/native/objc_bridge.m
SK_BRIDGE_OBJ := src/ui/native/swiftkit_bridge.o
SK_BRIDGE_SRC := src/ui/native/swiftkit_bridge.m

COL_BRIDGE_OBJ := src/ui/native/collection_bridge.o
COL_BRIDGE_SRC := src/ui/native/collection_bridge.m
SPEC_FOCUS_BRIDGE_OBJ := src/ui/native/appkit_focus_spec_bridge.o
SPEC_FOCUS_BRIDGE_SRC := spec/native_macos/support/appkit_focus_test_bridge.m
SPEC_PREVIEW_BRIDGE_OBJ := src/ui/native/appkit_preview_state_spec_bridge.o
SPEC_PREVIEW_BRIDGE_SRC := spec/native_macos/support/preview_state_capture_test_bridge.m

SWIFTKIT_DIR  := swift/AssetPipelineSwiftKit
SWIFTKIT_LIB  := $(SWIFTKIT_DIR)/.build/release/libAssetPipelineSwiftKit.a
SWIFT_RUNTIME_LIB_DIR := $(shell xcrun --sdk macosx --show-sdk-path 2>/dev/null)/usr/lib/swift

MACOS_FRAMEWORKS := \
	-framework AppKit -framework Foundation \
	-framework SwiftUI -framework Combine \
	-framework ApplicationServices -framework CoreFoundation \
	-framework CoreGraphics -framework ImageIO -framework QuartzCore \
	-framework UserNotifications \
	-framework WebKit -framework MapKit -framework CoreLocation \
	-framework AVKit -framework AVFoundation \
	-lobjc

MACOS_LINK_FLAGS := \
	$(abspath $(AP_BRIDGE_OBJ)) $(abspath $(SK_BRIDGE_OBJ)) $(abspath $(COL_BRIDGE_OBJ)) \
	$(abspath $(SPEC_FOCUS_BRIDGE_OBJ)) $(abspath $(SPEC_PREVIEW_BRIDGE_OBJ)) \
	-Wl,-force_load,$(abspath $(SWIFTKIT_LIB)) \
	$(MACOS_FRAMEWORKS) \
	-L$(SWIFT_RUNTIME_LIB_DIR) \
	-lswiftCore -lswiftCoreFoundation -lswiftCoreImage -lswiftDispatch \
	-lswiftFoundation -lswiftIOKit -lswiftMetal -lswiftOSLog \
	-lswiftObjectiveC -lswiftQuartzCore -lswiftSpatial \
	-lswiftUniformTypeIdentifiers -lswiftXPC -lswiftos -lswiftsimd \
	-Wl,-rpath,/usr/lib/swift

# AppKit must run on the main thread, and the native specs call it from the
# main fiber. Under Crystal's execution-context runtime (the default since
# 1.21) the monitor thread can move the main fiber to a pool thread after any
# blocking syscall (File.open, getaddrinfo), and the next AppKit call then
# traps (SIGTRAP). -Dwithout_mt keeps the main fiber on the main thread.
MACOS_SPEC_FLAGS := -Dmacos -Dwithout_mt

# `crystal spec` writes its binary to $(CRYSTAL_CACHE_DIR)/crystal-run-spec.tmp,
# and the default cache dir is shared by every checkout on the machine, so a
# concurrent spec run elsewhere can replace or delete the binary mid-run.
# Keep this checkout's spec binary in its own cache dir.
MACOS_SPEC_CACHE_DIR := $(CURDIR)/.crystal-cache

# Extra spec-runner arguments, e.g. `make test-macos MACOS_SPEC_ARGS=-v`.
MACOS_SPEC_ARGS ?=

.PHONY: test-web test-macos test-ios test-android test-all lint clean-bridges

test-web:
	$(CRYSTAL) spec spec/web/

test-macos: $(AP_BRIDGE_OBJ) $(SK_BRIDGE_OBJ) $(COL_BRIDGE_OBJ) $(SPEC_FOCUS_BRIDGE_OBJ) $(SPEC_PREVIEW_BRIDGE_OBJ) $(SWIFTKIT_LIB)
	CRYSTAL_CACHE_DIR=$(MACOS_SPEC_CACHE_DIR) $(ACRYSTAL) spec spec/native_macos/ $(MACOS_SPEC_FLAGS) \
		--link-flags="$(MACOS_LINK_FLAGS)" $(MACOS_SPEC_ARGS)

test-ios:
	@echo "[test-ios] iOS spec lane is attempted-blocked."
	@echo "[test-ios] See docs/initiative-cross-platform-ui/native-compile-matrix.md"
	@echo "[test-ios] First actionable error: cross-compiled libgc missing."
	@echo "[test-ios] Existing iOS path (libcascade.a + Xcode) is at"
	@echo "[test-ios]   samples/initiative-cross-platform-ui-demo/ios/build_crystal_lib.sh"

test-android:
	@echo "[test-android] Android spec lane is attempted-blocked."
	@echo "[test-android] See docs/initiative-cross-platform-ui/native-compile-matrix.md"
	@echo "[test-android] First actionable error: Crystal stdlib host-only"
	@echo "[test-android]   (require \"c/sys/epoll\" only ships on Linux Crystal builds)."
	@echo "[test-android] Needs Linux-targeted Crystal compiler + Android NDK."

test-all: test-web test-macos
	@echo "[test-all] web + macOS lanes complete."
	@echo "[test-all] iOS / Android lanes: see native-compile-matrix.md"

lint:
	$(CRYSTAL) run scripts/lint_conventions.cr

$(AP_BRIDGE_OBJ): $(AP_BRIDGE_SRC)
	clang -c $(AP_BRIDGE_SRC) -o $(AP_BRIDGE_OBJ) -fno-objc-arc

$(SK_BRIDGE_OBJ): $(SK_BRIDGE_SRC)
	clang -c $(SK_BRIDGE_SRC) -o $(SK_BRIDGE_OBJ) -fno-objc-arc

$(COL_BRIDGE_OBJ): $(COL_BRIDGE_SRC)
	clang -c $(COL_BRIDGE_SRC) -o $(COL_BRIDGE_OBJ) -fno-objc-arc

$(SPEC_FOCUS_BRIDGE_OBJ): $(SPEC_FOCUS_BRIDGE_SRC)
	clang -c $(SPEC_FOCUS_BRIDGE_SRC) -o $(SPEC_FOCUS_BRIDGE_OBJ) -fno-objc-arc

$(SPEC_PREVIEW_BRIDGE_OBJ): $(SPEC_PREVIEW_BRIDGE_SRC)
	clang -c $(SPEC_PREVIEW_BRIDGE_SRC) -o $(SPEC_PREVIEW_BRIDGE_OBJ) -fno-objc-arc

$(SWIFTKIT_LIB): $(wildcard $(SWIFTKIT_DIR)/Sources/AssetPipelineSwiftKit/*.swift) \
                 $(wildcard $(SWIFTKIT_DIR)/Sources/AssetPipelineSwiftKit/**/*.swift) \
                 $(SWIFTKIT_DIR)/Package.swift
	swift build -c release --package-path $(SWIFTKIT_DIR)

clean-bridges:
	rm -f $(AP_BRIDGE_OBJ) $(SK_BRIDGE_OBJ) $(COL_BRIDGE_OBJ) $(SPEC_FOCUS_BRIDGE_OBJ) $(SPEC_PREVIEW_BRIDGE_OBJ)
