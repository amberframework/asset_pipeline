# Phase 8B native spike Makefile.
#
# Single target: `make macos` builds a small AppKit .bin that demonstrates
# the full Phase 8B form_state -> controller -> coord.push -> re-render
# flow.

PROJECT_DIR := $(shell pwd)
SHARD_ROOT  := $(abspath $(PROJECT_DIR)/../..)

CRYSTAL := crystal-alpha

.PHONY: all macos clean

all: macos

MACOS_BIN := $(PROJECT_DIR)/bin/spike
MACOS_SRC := $(PROJECT_DIR)/src/spike_app.cr

AP_BRIDGE     := $(SHARD_ROOT)/src/ui/native/objc_bridge.o
AP_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/objc_bridge.m

SWIFTKIT_DIR        := $(SHARD_ROOT)/swift/AssetPipelineSwiftKit
SWIFTKIT_LIB        := $(SWIFTKIT_DIR)/.build/release/libAssetPipelineSwiftKit.a
SWIFTKIT_BRIDGE     := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.o
SWIFTKIT_BRIDGE_SRC := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.m

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

macos: $(MACOS_BIN)

$(MACOS_BIN): $(MACOS_SRC) $(AP_BRIDGE) $(SWIFTKIT_BRIDGE) $(SWIFTKIT_LIB) $(WIN_HELPER)
	@mkdir -p $(PROJECT_DIR)/bin
	$(CRYSTAL) build $(MACOS_SRC) -o $(MACOS_BIN) -Dmacos \
		--link-flags="$(MACOS_LINK_FLAGS)"
	@echo "[phase-08b spike] built -> $(MACOS_BIN)"

$(AP_BRIDGE): $(AP_BRIDGE_SRC)
	clang -c $(AP_BRIDGE_SRC) -o $(AP_BRIDGE) -fno-objc-arc

$(SWIFTKIT_BRIDGE): $(SWIFTKIT_BRIDGE_SRC)
	clang -c $(SWIFTKIT_BRIDGE_SRC) -o $(SWIFTKIT_BRIDGE) -fno-objc-arc

$(SWIFTKIT_LIB):
	swift build -c release --package-path $(SWIFTKIT_DIR)

$(WIN_HELPER): $(WIN_HELPER_SRC)
	clang -c $(WIN_HELPER_SRC) -o $(WIN_HELPER) -fno-objc-arc

clean:
	rm -rf $(PROJECT_DIR)/bin
