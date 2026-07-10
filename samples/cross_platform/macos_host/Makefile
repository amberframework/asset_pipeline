# Makefile for the HIG macOS visual-validation host.
#
# Pattern copied from happy_coach/Makefile; stripped of crystal-audio
# extensions and app-specific bridges. Renders one UI::View per slug
# and opens it in a native AppKit window for AXTest to screenshot.
#
# Usage:
#   make showcase SLUG=buttons
#   make clean

# PROJECT_DIR resolves to this Makefile's directory.
PROJECT_DIR := $(shell pwd)

# asset_pipeline shard root (three levels up from samples/cross_platform/macos_host).
SHARD_ROOT  := $(abspath $(PROJECT_DIR)/../../..)

CRYSTAL     := crystal-alpha
BIN         := bin/hig_showcase
SRC         := hig_showcase.cr

# Code-signing identity. TCC permissions (Screen Recording, Accessibility, etc.)
# persist across rebuilds ONLY if the binary is signed with a stable identity.
# Ad-hoc signatures change hash on every rebuild — TCC grants get invalidated.
# Override with `make CODESIGN_IDENTITY="..."` or set to `-` to disable signing.
CODESIGN_IDENTITY ?= Developer ID Application: AgentC Consulting LLC (PXDF92M2T4)

# Asset Pipeline ObjC bridge (ARM64-safe objc_msgSend wrappers).
# IMPORTANT: -fno-objc-arc is REQUIRED -- the bridge manages its own memory.
AP_BRIDGE     := $(SHARD_ROOT)/src/ui/native/objc_bridge.o
AP_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/objc_bridge.m

# AssetPipelineSwiftKit — Swift companion library that the Phase 3a Button
# (and every Dispatch B widget that follows) routes through. The Crystal
# renderer calls `apsk_make_button(...)` via the C trampolines in
# `swiftkit_bridge.m`; `swiftkit_bridge.o` is the ObjC glue and the static
# `libAssetPipelineSwiftKit.a` is the Swift facade implementation.
SWIFTKIT_DIR        := $(SHARD_ROOT)/swift/AssetPipelineSwiftKit
SWIFTKIT_LIB        := $(SWIFTKIT_DIR)/.build/release/libAssetPipelineSwiftKit.a
SWIFTKIT_BRIDGE     := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.o
SWIFTKIT_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.m

# HIG host window helper (NSApplication + NSWindow init).
WIN_HELPER     := $(PROJECT_DIR)/window_helper.o
WIN_HELPER_SRC := $(PROJECT_DIR)/window_helper.m

# Framework flags for macOS.
# AppKit + Foundation + lobjc = renderer essentials.
# SwiftUI + Combine = AssetPipelineSwiftKit facade runtime.
# ApplicationServices + CoreFoundation = AXTest screenshot harness.
# CoreGraphics + ImageIO = CGWindowListCreateImage capture path (Phase 0.1).
MACOS_FRAMEWORKS := -framework AppKit -framework Foundation \
	-framework SwiftUI -framework Combine \
	-framework ApplicationServices -framework CoreFoundation \
	-framework CoreGraphics -framework ImageIO -framework QuartzCore \
	-framework UserNotifications \
	-framework WebKit -framework MapKit -framework CoreLocation -framework AVKit -framework AVFoundation \
	-lobjc

# The Swift runtime lives at /usr/lib/swift on macOS 13+; embedding the
# rpath lets the binary load Foundation/SwiftUI without DYLD overrides.
# `-force_load $(SWIFTKIT_LIB)` is REQUIRED: AssetPipelineSwiftKit's
# `APSK*` classes are referenced only via `objc_getClass(...)` lookups
# in `swiftkit_bridge.m`. Apple's ld treats unreferenced ObjC classes
# inside .a archives as dead code by default — without `-force_load`
# the Swift facade symbols vanish, `apsk_make_button` returns NULL, and
# every hosted SwiftUI view collapses to a zero-size NSView. Discovered
# during Phase 3a integration; see commit log for the failure mode.
MACOS_LINK_FLAGS := $(AP_BRIDGE) $(SWIFTKIT_BRIDGE) $(WIN_HELPER) \
	-Wl,-force_load,$(SWIFTKIT_LIB) \
	$(MACOS_FRAMEWORKS) \
	-Wl,-rpath,/usr/lib/swift

SLUG ?= buttons

.PHONY: showcase build ext-ap ext-swiftkit ext-swiftkit-lib ext-win clean

# --- Build + run ---

showcase: build
	@echo "[hig_showcase] SLUG=$(SLUG) -> $(BIN)"
	@if [ -z "$$HIG_SCREENSHOT_PATH" ]; then \
		echo "[hig_showcase] build complete. NOT running the binary because HIG_SCREENSHOT_PATH is unset."; \
		echo "[hig_showcase] To capture: HIG_SCREENSHOT_PATH=/tmp/out.png HIG_SLUG=$(SLUG) ./$(BIN)"; \
		echo "[hig_showcase] Automated pipelines should use spec/ui/hig_validation/macos_visual_spec.cr which sets the env vars."; \
	else \
		HIG_SLUG=$(SLUG) ./$(BIN); \
	fi

build: ext-ap ext-swiftkit ext-swiftkit-lib ext-win $(BIN)

$(BIN): $(SRC) ext-ap ext-swiftkit ext-swiftkit-lib ext-win
	@mkdir -p bin
	$(CRYSTAL) build $(SRC) -o $(BIN) -Dmacos \
		--link-flags="$(MACOS_LINK_FLAGS)"
	@$(MAKE) --no-print-directory sign

# --- Code signing ---
# Sign with a stable identity so TCC permissions (Screen Recording, etc.)
# persist across rebuilds. The Developer ID identity hash is derived from
# the signing certificate's team ID, which is stable forever — so granting
# Screen Recording to this binary once makes it work for every rebuild.

.PHONY: sign
sign:
	@if [ "$(CODESIGN_IDENTITY)" = "-" ]; then \
		echo "[codesign] Skipping (CODESIGN_IDENTITY=-)"; \
	else \
		echo "[codesign] Signing $(BIN) with: $(CODESIGN_IDENTITY)"; \
		codesign --force --sign "$(CODESIGN_IDENTITY)" \
			--timestamp=none \
			$(BIN); \
		codesign --verify --verbose=1 $(BIN); \
	fi
	# Note: hardened runtime (--options runtime) is intentionally NOT enabled.
	# The binary loads homebrew dylibs (libssl, libcrypto) signed by their own
	# teams; hardened runtime would reject them as "different Team IDs."
	# Hardened runtime is required for notarized distribution, not dev tools.

# --- ObjC bridge ---
# IMPORTANT: -fno-objc-arc is REQUIRED.

ext-ap: $(AP_BRIDGE)
$(AP_BRIDGE): $(AP_BRIDGE_SRC)
	clang -c $(AP_BRIDGE_SRC) -o $(AP_BRIDGE) -fno-objc-arc

# AssetPipelineSwiftKit C trampoline + Swift static library targets.
ext-swiftkit: $(SWIFTKIT_BRIDGE)
$(SWIFTKIT_BRIDGE): $(SWIFTKIT_BRIDGE_SRC)
	clang -c $(SWIFTKIT_BRIDGE_SRC) -o $(SWIFTKIT_BRIDGE) -fno-objc-arc

ext-swiftkit-lib: $(SWIFTKIT_LIB)
$(SWIFTKIT_LIB): $(wildcard $(SWIFTKIT_DIR)/Sources/AssetPipelineSwiftKit/*.swift) \
                 $(wildcard $(SWIFTKIT_DIR)/Sources/AssetPipelineSwiftKit/**/*.swift) \
                 $(SWIFTKIT_DIR)/Package.swift
	swift build -c release --package-path $(SWIFTKIT_DIR)

ext-win: $(WIN_HELPER)
$(WIN_HELPER): $(WIN_HELPER_SRC)
	clang -c $(WIN_HELPER_SRC) -o $(WIN_HELPER) -fno-objc-arc

# --- Clean ---

clean:
	rm -f $(BIN) $(AP_BRIDGE) $(SWIFTKIT_BRIDGE) $(WIN_HELPER)
	rm -rf bin
	rm -rf $(SWIFTKIT_DIR)/.build
