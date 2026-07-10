// ReactiveStateTests — XCTest coverage for the Phase 3 Remediation 4
// reactive state bridge. Each test:
//   1. Constructs the state class directly OR through `makeReactive*`.
//   2. Drives the matching `apsk_*_set_*` @_cdecl helper.
//   3. Asserts the `@Published` property reflects the mutation.
//
// The @_cdecl functions internally dispatch onto the main queue (so
// SwiftUI publishes happen on the main thread). The tests use
// XCTestExpectation + a brief main-runloop pump to observe the published
// value. Crystal calls the same @_cdecl directly via `LibSwiftKitBridge`;
// the Crystal side is covered by `spec/ui/native/reactive_state_spec.cr`
// (property-update half) and the AXTest behavioral spec
// `spec/ui/hig_validation/macos_action_tap_probe_spec.cr` (end-to-end).

import XCTest
import Combine
@testable import AssetPipelineSwiftKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private func pumpMainRunloop(_ deadline: TimeInterval = 0.2) {
    // Spin the run loop briefly so DispatchQueue.main.async blocks fire.
    let end = Date().addingTimeInterval(deadline)
    while Date() < end {
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
    }
}

final class ReactiveStateTests: XCTestCase {

    // MARK: - Label state

    func testLabelStateInitialText() {
        let state = APSKLabelState(text: "initial")
        XCTAssertEqual(state.text, "initial")
    }

    func testApskLabelSetTextUpdatesPublishedField() {
        let state = APSKLabelState(text: "initial")
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        "updated".withCString { cstr in
            apskLabelSetText(handle, cstr)
        }

        pumpMainRunloop()
        XCTAssertEqual(state.text, "updated")
    }

    func testApskLabelSetTextHandlesEmptyString() {
        let state = APSKLabelState(text: "initial")
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        "".withCString { cstr in
            apskLabelSetText(handle, cstr)
        }
        pumpMainRunloop()
        XCTAssertEqual(state.text, "")
    }

    // MARK: - Button state

    func testButtonStateNilFieldsByDefault() {
        let state = APSKButtonState()
        XCTAssertNil(state.backgroundColor)
        XCTAssertNil(state.foregroundColor)
        XCTAssertNil(state.cornerRadius)
    }

    func testApskButtonSetBackgroundColorUpdatesField() {
        let state = APSKButtonState()
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        apskButtonSetBackgroundColor(handle, 1.0, 0.0, 0.0, 1.0)
        pumpMainRunloop()

        XCTAssertNotNil(state.backgroundColor)
        // Channel round-trip: pull r/g/b/a out of the UIColor/NSColor and
        // confirm the values landed.
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        #if canImport(UIKit)
        state.backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        // NSColor needs the sRGB color space for getRed to be defined.
        let converted = state.backgroundColor?.usingColorSpace(.sRGB)
        converted?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        XCTAssertEqual(r, 1.0, accuracy: 0.001)
        XCTAssertEqual(g, 0.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testApskButtonClearBackgroundColorResetsField() {
        let state = APSKButtonState(
            backgroundColor: APSKPlatformColor(red: 1, green: 0, blue: 0, alpha: 1)
        )
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        apskButtonClearBackgroundColor(handle)
        pumpMainRunloop()
        XCTAssertNil(state.backgroundColor)
    }

    func testApskButtonSetForegroundColorUpdatesField() {
        let state = APSKButtonState()
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        apskButtonSetForegroundColor(handle, 0.0, 1.0, 0.0, 1.0)
        pumpMainRunloop()
        XCTAssertNotNil(state.foregroundColor)
    }

    func testApskButtonSetCornerRadiusUpdatesField() {
        let state = APSKButtonState()
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        apskButtonSetCornerRadius(handle, 12.5)
        pumpMainRunloop()
        XCTAssertEqual(state.cornerRadius?.doubleValue, 12.5)
    }

    func testApskButtonClearCornerRadiusResetsField() {
        let state = APSKButtonState(cornerRadius: NSNumber(value: 12.0))
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        apskButtonClearCornerRadius(handle)
        pumpMainRunloop()
        XCTAssertNil(state.cornerRadius)
    }

    // MARK: - Toggle / Slider storage

    func testApskToggleSetValueUpdatesStorage() {
        let storage = BoolStorage(initial: false, token: 0)
        let handle = Unmanaged.passRetained(storage).toOpaque()
        defer { apskStateRelease(handle) }

        apskToggleSetValue(handle, 1)
        pumpMainRunloop()
        XCTAssertTrue(storage.value)

        apskToggleSetValue(handle, 0)
        pumpMainRunloop()
        XCTAssertFalse(storage.value)
    }

    func testApskSliderSetValueUpdatesStorage() {
        let storage = DoubleStorage(initial: 0.0, token: 0)
        let handle = Unmanaged.passRetained(storage).toOpaque()
        defer { apskStateRelease(handle) }

        apskSliderSetValue(handle, 0.75)
        pumpMainRunloop()
        XCTAssertEqual(storage.value, 0.75, accuracy: 0.001)
    }

    // MARK: - State release

    func testStateReleaseAcceptsNil() {
        // Must not crash; Crystal NativeHandle#release! calls this
        // unconditionally on every handle teardown.
        apskStateRelease(nil)
    }

    // MARK: - Combine observation

    func testLabelStatePublisherFiresOnTextChange() {
        let state = APSKLabelState(text: "a")
        let handle = Unmanaged.passRetained(state).toOpaque()
        defer { apskStateRelease(handle) }

        let expectation = XCTestExpectation(description: "publisher fires")
        var observed: [String] = []
        let cancellable = state.$text.sink { newValue in
            observed.append(newValue)
            if observed.count >= 2 { expectation.fulfill() }
        }

        "b".withCString { apskLabelSetText(handle, $0) }
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()

        XCTAssertEqual(observed, ["a", "b"])
    }

    // MARK: - Reactive facade construction round-trip

    func testMakeReactiveLabelWritesStatePointer() {
        var statePtr: UnsafeMutableRawPointer? = nil
        let overrides = LabelOverrides()
        let view = LabelFacade.makeReactiveLabel(
            text: "hello", overrides: overrides, outState: &statePtr
        )
        XCTAssertNotNil(view)
        XCTAssertNotNil(statePtr)

        // The pointer must reference an APSKLabelState seeded with "hello".
        if let p = statePtr {
            let state = Unmanaged<APSKLabelState>.fromOpaque(p).takeUnretainedValue()
            XCTAssertEqual(state.text, "hello")
            // Drive a mutation through the @_cdecl helper to prove the
            // state object is the live published one.
            "world".withCString { apskLabelSetText(p, $0) }
            pumpMainRunloop()
            XCTAssertEqual(state.text, "world")

            apskStateRelease(p)
        }
    }

    func testMakeReactiveButtonWritesStatePointer() {
        var statePtr: UnsafeMutableRawPointer? = nil
        let overrides = ButtonOverrides()
        let view = ButtonFacade.makeReactiveButton(
            label: "Save", overrides: overrides,
            actionToken: 0, outState: &statePtr
        )
        XCTAssertNotNil(view)
        XCTAssertNotNil(statePtr)

        if let p = statePtr {
            let state = Unmanaged<APSKButtonState>.fromOpaque(p).takeUnretainedValue()
            XCTAssertNil(state.backgroundColor)
            apskButtonSetBackgroundColor(p, 0.0, 0.0, 1.0, 1.0)
            pumpMainRunloop()
            XCTAssertNotNil(state.backgroundColor)
            apskStateRelease(p)
        }
    }
}
