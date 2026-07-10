# Phase 6.10 — Voyager demo Makefile.
#
# Three targets:
#   make web   -> output/voyager-demo/*.html (single-page + per-screen)
#   make macos -> macos/bin/voyager (NavigationCoordinator-driven host)
#   make ios   -> Voyager.app for iPhone 17 Simulator
#
# Web is the primary deliverable for the state-propagation litmus;
# macOS + iOS hosts mirror the Cascade demo's structure for the
# native NSWindow setContentView + UIKit SwiftUI @State trampoline
# patterns.

PROJECT_DIR := $(shell pwd)
SHARD_ROOT  := $(abspath $(PROJECT_DIR)/../..)

CRYSTAL_VANILLA := crystal
CRYSTAL_NATIVE  := crystal-alpha
CRYSTAL         := $(CRYSTAL_NATIVE)

.PHONY: all web macos macos-build macos-run ios ios-bridge ios-xcodeproj ios-build clean

all: web

# ---------------------------------------------------------------------------
# Web target — pure Crystal, no native toolchain required.
# ---------------------------------------------------------------------------

web:
	@echo "[voyager web] building single-page navigable demo -> output/voyager-demo/"
	$(CRYSTAL_VANILLA) run $(PROJECT_DIR)/web/static_site.cr

# ---------------------------------------------------------------------------
# macOS target — Crystal-alpha + AppKit + AssetPipelineSwiftKit.
# Mirrors samples/initiative-cross-platform-ui-demo/Makefile macos block.
# ---------------------------------------------------------------------------

MACOS_BIN := $(PROJECT_DIR)/macos/bin/voyager
MACOS_SRC := $(PROJECT_DIR)/macos/host.cr

AP_BRIDGE     := $(SHARD_ROOT)/src/ui/native/objc_bridge.o
AP_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/objc_bridge.m

SWIFTKIT_DIR        := $(SHARD_ROOT)/swift/AssetPipelineSwiftKit
SWIFTKIT_LIB        := $(SWIFTKIT_DIR)/.build/release/libAssetPipelineSwiftKit.a
SWIFTKIT_BRIDGE     := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.o
SWIFTKIT_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.m

# Reuse the validated window_helper.m from the HIG host — same compositing
# requirements (NSWindow setup, capture window, run-loop pump).
WIN_HELPER     := $(SHARD_ROOT)/samples/cross_platform/macos_host/window_helper.o
WIN_HELPER_SRC := $(SHARD_ROOT)/samples/cross_platform/macos_host/window_helper.m

MACOS_FRAMEWORKS := -framework AppKit -framework Foundation \
	-framework SwiftUI -framework Combine \
	-framework ApplicationServices -framework CoreFoundation \
	-framework CoreGraphics -framework ImageIO -framework QuartzCore \
	-framework UserNotifications -framework WebKit \
	-framework MapKit -framework CoreLocation \
	-framework AVKit -framework AVFoundation \
	-lobjc

MACOS_LINK_FLAGS := $(AP_BRIDGE) $(SWIFTKIT_BRIDGE) $(WIN_HELPER) \
	-Wl,-force_load,$(SWIFTKIT_LIB) \
	$(MACOS_FRAMEWORKS) \
	-Wl,-rpath,/usr/lib/swift

CODESIGN_IDENTITY ?= -

macos: macos-build

macos-build: $(MACOS_BIN)

$(MACOS_BIN): $(MACOS_SRC) $(AP_BRIDGE) $(SWIFTKIT_BRIDGE) $(SWIFTKIT_LIB) $(WIN_HELPER)
	@mkdir -p $(PROJECT_DIR)/macos/bin
	$(CRYSTAL_NATIVE) build $(MACOS_SRC) -o $(MACOS_BIN) -Dmacos \
		--link-flags="$(MACOS_LINK_FLAGS)"
	@if [ "$(CODESIGN_IDENTITY)" != "-" ]; then \
		codesign --force --sign "$(CODESIGN_IDENTITY)" --timestamp=none $(MACOS_BIN); \
	fi
	@echo "[voyager macos] built -> $(MACOS_BIN)"

# Run the macOS app interactively (opens a window for human exploration).
macos-run: macos-build
	$(MACOS_BIN) $(SLUG)

$(AP_BRIDGE): $(AP_BRIDGE_SRC)
	clang -c $(AP_BRIDGE_SRC) -o $(AP_BRIDGE) -fno-objc-arc

$(SWIFTKIT_BRIDGE): $(SWIFTKIT_BRIDGE_SRC)
	clang -c $(SWIFTKIT_BRIDGE_SRC) -o $(SWIFTKIT_BRIDGE) -fno-objc-arc

$(SWIFTKIT_LIB):
	swift build -c release --package-path $(SWIFTKIT_DIR)

$(WIN_HELPER): $(WIN_HELPER_SRC)
	clang -c $(WIN_HELPER_SRC) -o $(WIN_HELPER) -fno-objc-arc

# ---------------------------------------------------------------------------
# iOS target — cross-compile Crystal bridge + xcodegen + xcodebuild.
# Mirrors samples/initiative-cross-platform-ui-demo/Makefile ios block.
# ---------------------------------------------------------------------------

IOS_DIR        := $(PROJECT_DIR)/ios
IOS_BRIDGE_SH  := $(IOS_DIR)/build_crystal_lib.sh
IOS_PROJECT    := $(IOS_DIR)/VoyagerDemo.xcodeproj
IOS_SCHEME     := VoyagerDemo
IOS_DEST       ?= platform=iOS Simulator,name=iPhone 17

ios: ios-build

ios-bridge:
	@echo "[voyager ios] cross-compiling Crystal bridge -> libvoyager.a"
	bash $(IOS_BRIDGE_SH) simulator

ios-xcodeproj: ios-bridge
	@echo "[voyager ios] generating Xcode project via xcodegen"
	cd $(IOS_DIR) && xcodegen generate

ios-build: ios-xcodeproj
	@echo "[voyager ios] xcodebuild build -> VoyagerDemo.app"
	xcodebuild build \
		-project $(IOS_PROJECT) \
		-scheme $(IOS_SCHEME) \
		-destination "$(IOS_DEST)" \
		CODE_SIGNING_ALLOWED=NO

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------

clean:
	rm -rf $(PROJECT_DIR)/macos/bin
	rm -rf $(IOS_DIR)/build
	rm -rf $(IOS_DIR)/VoyagerDemo.xcodeproj
	rm -f  $(AP_BRIDGE) $(SWIFTKIT_BRIDGE) $(WIN_HELPER)
	rm -rf $(SHARD_ROOT)/output/voyager-demo
