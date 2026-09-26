PROJECT_DIR := $(shell pwd)
SHARD_ROOT := $(abspath $(PROJECT_DIR)/../..)

CRYSTAL ?= crystal-alpha
BIN := $(PROJECT_DIR)/bin/surface-craft-study
SPEC_BIN := $(PROJECT_DIR)/bin/surface-craft-study-spec
AP_BRIDGE := $(SHARD_ROOT)/src/ui/native/objc_bridge.o
SK_BRIDGE := $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.o
SWIFTKIT_DIR := $(SHARD_ROOT)/swift/AssetPipelineSwiftKit
SWIFTKIT_LIB := $(SWIFTKIT_DIR)/.build/release/libAssetPipelineSwiftKit.a
SWIFTKIT_DEBUG_LIB := $(SWIFTKIT_DIR)/.build/debug/libAssetPipelineSwiftKit.a
WINDOW_HELPER := $(PROJECT_DIR)/bin/window_helper.o
WINDOW_HELPER_SRC := $(SHARD_ROOT)/samples/cross_platform/macos_host/window_helper.m

MACOS_FRAMEWORKS := -framework AppKit -framework Foundation \
	-framework SwiftUI -framework Combine -framework ApplicationServices \
	-framework CoreFoundation -framework CoreGraphics -framework ImageIO \
	-framework QuartzCore -framework UserNotifications -framework WebKit \
	-framework MapKit -framework CoreLocation -framework AVKit \
	-framework AVFoundation -lobjc

SWIFT_TOOLCHAIN_LIB := $(shell xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.0/macosx
SWIFT_RUNTIME := -L/usr/lib/swift -L$(SWIFT_TOOLCHAIN_LIB) \
	-lswiftCore -lswiftFoundation -lswiftCoreFoundation -lswiftObjectiveC \
	-lswiftDispatch -lswiftDarwin -lswiftIOKit -lswiftos -lswiftQuartzCore \
	-lswiftMetal -lswiftCoreImage -lswiftCoreGraphics -lswiftXPC -lswiftsimd \
	-lswiftAppKit -lswiftUniformTypeIdentifiers -lswiftOSLog -lswift_Concurrency \
	-Wl,-rpath,$(SWIFT_TOOLCHAIN_LIB)

MACOS_LINK_FLAGS := $(AP_BRIDGE) $(SK_BRIDGE) $(WINDOW_HELPER) \
	-Wl,-force_load,$(SWIFTKIT_LIB) $(MACOS_FRAMEWORKS) $(SWIFT_RUNTIME) \
	-Wl,-rpath,/usr/lib/swift
SPEC_MACOS_LINK_FLAGS := $(subst $(SWIFTKIT_LIB),$(SWIFTKIT_DEBUG_LIB),$(MACOS_LINK_FLAGS))

.PHONY: build build-spec run-light run-dark clean

build: $(BIN)

build-spec: $(SPEC_BIN)

$(BIN): component_study.cr $(AP_BRIDGE) $(SK_BRIDGE) $(SWIFTKIT_LIB) $(WINDOW_HELPER)
	mkdir -p $(PROJECT_DIR)/bin
	$(CRYSTAL) build component_study.cr -Dmacos -o $(BIN) \
		--link-flags="$(MACOS_LINK_FLAGS)"

$(SPEC_BIN): component_study.cr $(AP_BRIDGE) $(SK_BRIDGE) $(SWIFTKIT_DEBUG_LIB) $(WINDOW_HELPER)
	mkdir -p $(PROJECT_DIR)/bin
	$(CRYSTAL) build component_study.cr -Dmacos -Dsurface_craft_ax_test -o $(SPEC_BIN) \
		--link-flags="$(SPEC_MACOS_LINK_FLAGS)"

$(AP_BRIDGE): $(SHARD_ROOT)/src/ui/native/objc_bridge.m
	clang -c $< -o $@ -fno-objc-arc

$(SK_BRIDGE): $(SHARD_ROOT)/src/ui/native/swiftkit_bridge.m
	clang -c $< -o $@ -fno-objc-arc

$(SWIFTKIT_LIB):
	swift build -c release --package-path $(SWIFTKIT_DIR)

$(SWIFTKIT_DEBUG_LIB):
	swift build -c debug --package-path $(SWIFTKIT_DIR)

$(WINDOW_HELPER): $(WINDOW_HELPER_SRC)
	mkdir -p $(PROJECT_DIR)/bin
	clang -c $< -o $@ -fno-objc-arc


run-light: build
	SURFACE_CRAFT_APPEARANCE=light $(BIN)

run-dark: build
	SURFACE_CRAFT_APPEARANCE=dark $(BIN)

clean:
	rm -rf $(PROJECT_DIR)/bin
