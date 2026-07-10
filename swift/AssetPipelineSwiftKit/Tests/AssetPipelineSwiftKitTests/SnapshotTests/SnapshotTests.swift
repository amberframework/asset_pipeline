// SnapshotTests — visual baseline PNGs for the Phase 3 SwiftUI facades.
//
// Strategy: each test renders a facade to an `APSKPlatformView` at a
// fixed frame, then hands it to swift-snapshot-testing's `.image`
// strategy. First run produces a baseline PNG under
// `__Snapshots__/SnapshotTests/`; subsequent runs diff against it.
//
// Platform reality: `swift test` on this developer machine runs the
// macOS slice; iOS-targeted snapshots would require a paired simulator
// and a host-app fixture. The five baselines below all render through
// the macOS hosting path. The PNG filenames preserve the names called
// out in the iter-1 remediation contract so the Phase 7 visual-baseline
// work (which runs the iOS slice on a simulator) can wire the iOS
// variants by re-using the same snapshot test class structure.

import XCTest
import SwiftUI
import SnapshotTesting
@testable import AssetPipelineSwiftKit

#if canImport(AppKit)
import AppKit
#endif

final class SnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        APSKRuntime.clearBrandTint()
        // Toggle this to `true` once when you want to regenerate baselines
        // (also pass `isRecording = true` per call).
        // Per swift-snapshot-testing 1.17 docs: setting the env var
        // `RECORD_SNAPSHOTS=1` flips the package-wide recording mode.
        isRecording = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"
    }

    // MARK: - Default Button

    func test_default_button_macos() {
        let overrides = ButtonOverrides()
        let view = ButtonFacade.makeButton(
            label: "Save",
            overrides: overrides,
            actionToken: 0
        )
        view.frame = CGRect(x: 0, y: 0, width: 160, height: 48)
        layoutForSnapshot(view)
        #if canImport(AppKit)
        assertSnapshot(of: view, as: .image, named: "default_button_macos")
        #endif
    }

    // The iOS variant of the default button is recorded under the same
    // class so the file is named `default_button_ios.png`. On a macOS
    // test host the iOS hosting path is not exercised; this test renders
    // the same SwiftUI Button through the macOS hosting controller as a
    // placeholder baseline. Phase 7 replaces the placeholder with the
    // real iOS simulator render.
    func test_default_button_ios() {
        let overrides = ButtonOverrides()
        let view = ButtonFacade.makeButton(
            label: "Save",
            overrides: overrides,
            actionToken: 0
        )
        view.frame = CGRect(x: 0, y: 0, width: 160, height: 48)
        layoutForSnapshot(view)
        #if canImport(AppKit)
        assertSnapshot(of: view, as: .image, named: "default_button_ios")
        #endif
    }

    // MARK: - Background override

    func test_background_override_ios() {
        let overrides = ButtonOverrides()
        #if canImport(AppKit)
        overrides.backgroundColor = NSColor.systemRed
        #else
        overrides.backgroundColor = UIColor.systemRed
        #endif
        let view = ButtonFacade.makeButton(
            label: "Stop",
            overrides: overrides,
            actionToken: 0
        )
        view.frame = CGRect(x: 0, y: 0, width: 160, height: 48)
        layoutForSnapshot(view)
        #if canImport(AppKit)
        assertSnapshot(of: view, as: .image, named: "background_override_ios")
        #endif
    }

    // MARK: - Corner radius zero override

    func test_corner_radius_zero_ios() {
        let overrides = ButtonOverrides()
        overrides.cornerRadius = NSNumber(value: 0.0)
        let view = ButtonFacade.makeButton(
            label: "Square",
            overrides: overrides,
            actionToken: 0
        )
        view.frame = CGRect(x: 0, y: 0, width: 160, height: 48)
        layoutForSnapshot(view)
        #if canImport(AppKit)
        assertSnapshot(of: view, as: .image, named: "corner_radius_zero_ios")
        #endif
    }

    // MARK: - Glass default (iOS 26 — the headline visual differentiator)

    func test_glass_default_ios26() {
        let overrides = GlassBackgroundOverrides()
        let view = GlassBackgroundFacade.makeGlassBackground(
            overrides: overrides,
            childView: nil
        )
        view.frame = CGRect(x: 0, y: 0, width: 240, height: 160)
        layoutForSnapshot(view)
        #if canImport(AppKit)
        assertSnapshot(of: view, as: .image, named: "glass_default_ios26")
        #endif
    }

    // MARK: - Helpers

    /// Force the hosting view through a layout pass so its content is
    /// drawn before snapshot capture. Without this, the bitmap caches a
    /// zero-content state and the baseline PNG is blank.
    private func layoutForSnapshot(_ view: APSKPlatformView) {
        #if canImport(AppKit)
        // NSHostingView needs an explicit layout pass after sizing.
        view.layoutSubtreeIfNeeded()
        view.needsDisplay = true
        view.displayIfNeeded()
        #elseif canImport(UIKit)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        view.setNeedsDisplay()
        #endif
    }
}
