// Phase 6.5 D4 — Host launch pattern.
//
// Centralizes the XCUIApplication launch sequence used by every iOS
// XCUITest in CrystalHIGHost. Extracted from
// `Phase03BehaviorTests.launchHost` so all behavior + visual tests share
// one launch contract.
//
// Usage:
//   let app = HostLaunchPattern.launchHost(slug: "phase-03-action-tap-probe")
//   // assertions...

import XCTest

enum HostLaunchPattern {
    /// Launch the host application with HIG_SLUG and appearance set via
    /// both launchArguments (for the underlying Crystal-lib slug router)
    /// and launchEnvironment (so the app process reads them from its own
    /// ProcessInfo.environment).
    ///
    /// - Parameters:
    ///   - slug: required HIG_SLUG (drives the in-host slug router).
    ///   - appearance: "light" or "dark"; defaults to "light".
    ///   - extraArgs: appended to launchArguments.
    ///   - extraEnv: merged into launchEnvironment.
    ///   - waitForRoot: when true (default), waits up to 10s for the
    ///     `hig-component-root` other-element to attach to the AX tree.
    static func launchHost(
        slug: String,
        appearance: String = "light",
        extraArgs: [String] = [],
        extraEnv: [String: String] = [:],
        waitForRoot: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-HIGSlug", slug] + extraArgs
        app.launchEnvironment["HIG_SLUG"] = slug
        app.launchEnvironment["HIG_APPEARANCE"] = appearance
        app.launchEnvironment["HIG_VALIDATION_CAPTURE"] = "1"
        for (k, v) in extraEnv {
            app.launchEnvironment[k] = v
        }
        app.launch()

        if waitForRoot {
            let root = app.otherElements["hig-component-root"]
            _ = root.waitForExistence(timeout: 10)
        }
        return app
    }
}
