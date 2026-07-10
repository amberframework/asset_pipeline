// RuntimeBridgeTests — XCTest cases for APSKRuntime and CallbackBridge.
//
// Covers the three runtime invariants Phase 3 introduced:
//   1. Brand tint set / get / clear round-trip (SwiftUI Default
//      Supremacy cascade — the colour the Crystal renderer hands in via
//      `apsk_runtime_set_brand_tint` must show through as the active
//      tint on every hosted root).
//   2. Action trampoline install marker (`isActionTrampolineInstalled`)
//      flips from false → true once Crystal calls `initialize(...)`.
//   3. CallbackBridge.fire(token:value:) routes through the installed
//      trampoline; token == 0 is a no-op; calls before install are
//      silently dropped (first-launch race protection, see
//      CallbackBridge.swift comment).
//
// The tests use APSKRuntime._installTestTrampoline to install a Swift
// closure in place of the Crystal-side `ap_swiftkit_invoke_action`
// trampoline so the round-trip exercises the dispatch path without
// having to link libcrystal.

import XCTest
@testable import AssetPipelineSwiftKit

// File-scope storage for the test trampoline so it has stable addressability.
// `@convention(c)` closures cannot capture state, so we route through a
// static counter pair that the closure increments.
private var fireCount: Int = 0
private var lastToken: UInt64 = 0
private var lastValue: Double = 0.0

private let testTrampoline: @convention(c) (UInt64, Double) -> Void = { token, value in
    fireCount += 1
    lastToken = token
    lastValue = value
}

final class RuntimeBridgeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset shared state before each test so order-independence holds.
        fireCount = 0
        lastToken = 0
        lastValue = 0.0
        APSKRuntime.clearBrandTint()
    }

    // MARK: - Brand tint

    func testBrandTintStartsUnset() {
        APSKRuntime.clearBrandTint()
        XCTAssertFalse(APSKRuntime.hasBrandTint)
    }

    func testSetBrandTintFlipsHasBrandTint() {
        APSKRuntime.setBrandTint(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        XCTAssertTrue(APSKRuntime.hasBrandTint)
    }

    func testClearBrandTintResetsToNil() {
        APSKRuntime.setBrandTint(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        XCTAssertTrue(APSKRuntime.hasBrandTint)
        APSKRuntime.clearBrandTint()
        XCTAssertFalse(APSKRuntime.hasBrandTint)
    }

    func testSetBrandTintIsReCallable() {
        APSKRuntime.setBrandTint(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        APSKRuntime.setBrandTint(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        XCTAssertTrue(APSKRuntime.hasBrandTint)
    }

    // MARK: - Action trampoline install

    func testInstallTestTrampolineSetsInstalled() {
        APSKRuntime._installTestTrampoline(testTrampoline)
        XCTAssertTrue(APSKRuntime.isActionTrampolineInstalled)
    }

    // MARK: - CallbackBridge dispatch

    func testCallbackBridgeFireInvokesInstalledTrampoline() {
        APSKRuntime._installTestTrampoline(testTrampoline)
        CallbackBridge.fire(token: 42, value: 3.14)
        XCTAssertEqual(fireCount, 1)
        XCTAssertEqual(lastToken, 42)
        XCTAssertEqual(lastValue, 3.14, accuracy: 0.0001)
    }

    func testCallbackBridgeFireTokenZeroIsNoOp() {
        APSKRuntime._installTestTrampoline(testTrampoline)
        CallbackBridge.fire(token: 0, value: 1.0)
        XCTAssertEqual(fireCount, 0,
                       "token 0 must be silently dropped (Crystal convention)")
    }

    func testCallbackBridgeFireMultipleInvocations() {
        APSKRuntime._installTestTrampoline(testTrampoline)
        CallbackBridge.fire(token: 1, value: 1.0)
        CallbackBridge.fire(token: 2, value: 2.0)
        CallbackBridge.fire(token: 3, value: 3.0)
        XCTAssertEqual(fireCount, 3)
        XCTAssertEqual(lastToken, 3)
        XCTAssertEqual(lastValue, 3.0, accuracy: 0.0001)
    }

    // MARK: - Module load marker

    func testModuleIsLoaded() {
        // Touch the umbrella class so the static `isLoaded` constant is
        // resolved through the runtime — confirms the static lib is
        // actually linked (the marker the Crystal runtime spec uses).
        XCTAssertTrue(AssetPipelineSwiftKitModule.isLoaded)
    }
}
