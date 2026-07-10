// Phase 6.5 D4 — Visual snapshot probe pattern.
//
// Wraps the HIGVisualTests one-slug capture flow. Tests opt into either
// full-screen XCUIScreen capture or element-scoped capture for tighter
// before/after deltas (BX5 runtime override).

import XCTest

enum VisualSnapshotPattern {
    /// Full screen XCUIScreen capture; attached with .keepAlways.
    static func snapshotScreen(testCase: XCTestCase, app: XCUIApplication, name: String) {
        testCase.attachScreenshot(app, name: name)
    }

    /// Element-scoped capture; attached with .keepAlways.
    static func snapshotElement(testCase: XCTestCase, element: XCUIElement, name: String) {
        testCase.attachElementScreenshot(element, name: name)
    }

    /// Slug-aware capture that picks between full-screen and window-scoped
    /// screenshot. Presentation components (action-sheets, activity-views)
    /// need full-screen so the home-indicator region is included; all
    /// others use window.screenshot() to drop SpringBoard chrome.
    static func captureForSlug(app: XCUIApplication, slug: String) -> XCUIScreenshot {
        let useFullScreen = (slug == "action-sheets" || slug == "activity-views")
        let window = app.windows.firstMatch
        return useFullScreen
            ? XCUIScreen.main.screenshot()
            : (window.exists ? window.screenshot() : XCUIScreen.main.screenshot())
    }

    /// Run a HIGVisualTests-style capture loop. Reads HIG_SLUG +
    /// HIG_APPEARANCE + HIG_BACKDROP_PATH from the test process
    /// environment, launches the host via HostLaunchPattern, settles
    /// 1.2s for UIVisualEffectView composition, captures the slug-aware
    /// screenshot, and attaches it with name "<slug>-ios-<appearance>.png".
    ///
    /// Returns true if either accessibility root attached within 10s.
    @discardableResult
    static func runWorklistCapture(testCase: XCTestCase) -> Bool {
        let env = ProcessInfo.processInfo.environment
        let slug       = env["HIG_SLUG"]        ?? "buttons"
        let appearance = env["HIG_APPEARANCE"]  ?? "light"
        let backdrop   = env["HIG_BACKDROP_PATH"]

        var extraEnv: [String: String] = [:]
        if let bp = backdrop, !bp.isEmpty {
            extraEnv["HIG_BACKDROP_PATH"] = bp
        }

        let app = HostLaunchPattern.launchHost(
            slug: slug,
            appearance: appearance,
            extraEnv: extraEnv,
            waitForRoot: false,
        )

        let crystalRoot = app.otherElements["hig-component-root"]
        let hostRoot    = app.otherElements["hig-component-root-host"]
        let anyRoot     = crystalRoot.waitForExistence(timeout: 10)
                       || hostRoot.waitForExistence(timeout: 2)

        // 1.2s settle for UIVisualEffectView materials to composite
        // against the backdrop; see Phase 0 fix comments in git history.
        Thread.sleep(forTimeInterval: 1.2)

        let screenshot = captureForSlug(app: app, slug: slug)
        let att = XCTAttachment(screenshot: screenshot)
        att.name = "\(slug)-ios-\(appearance).png"
        att.lifetime = .keepAlways
        testCase.add(att)
        return anyRoot
    }
}
