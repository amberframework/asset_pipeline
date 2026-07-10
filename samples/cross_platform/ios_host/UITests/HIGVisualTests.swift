import XCTest

// HIG visual-validation XCUITest.
//
// Phase 6.5 D4 refactor: a thin wrapper that delegates to
// VisualSnapshotPattern.runWorklistCapture. The slug-specific
// full-screen-vs-window capture branch lives in the pattern's
// captureForSlug helper (presentation-style components need the full
// screen viewport to include the home-indicator region).
//
// The wrapper script (scripts/run_ios_hig_tests.sh) invokes this test
// once per slug per appearance via TEST_RUNNER_* env vars.

final class HIGVisualTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRenderSlug() throws {
        let attached = VisualSnapshotPattern.runWorklistCapture(testCase: self)
        if !attached {
            let env = ProcessInfo.processInfo.environment
            let slug = env["HIG_SLUG"] ?? "buttons"
            XCTFail("No accessibility root (hig-component-root or -host) for \(slug)")
        }
    }
}
