import XCTest

// Phase03BehaviorTests — iOS XCUITest target for Phase 3 Group BX checks.
//
// Phase 6.5 D4 refactor: delegates host launch, attachment helpers,
// value-bound-control probes, sheet-dismiss probes, and focus snapshots
// to the Patterns/ library under UITests/Patterns/. Each Patterns file
// is documented at the top with its rubric provenance.
//
// Identifier strings are pinned by the rubric and must not be edited
// without an Architect adjudication.

final class Phase03BehaviorTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // ----- BX1 — Button tap fires bound Crystal proc (iOS) -----
    func testBX1_buttonTapFiresHandler() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-action-tap-probe")
        let btn = app.buttons["tap-probe-button"]
        XCTAssertTrue(btn.waitForExistence(timeout: 5),
                      "BX1: tap-probe-button must be discoverable")

        let counter = app.staticTexts["tap-probe-counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 3),
                      "BX1: tap-probe-counter mirror label must be present")

        attachScreenshot(app, name: "BX1-counter-initial.png")
        var transitions: [String] = []
        transitions.append(readDisplay(counter))

        XCTAssertEqual(transitions[0], "0",
                       "BX1: counter must start at \"0\" — got \(transitions[0]). " +
                       "Stale TapProbe singleton from a prior process?")

        for i in 1...3 {
            btn.tap()
            Thread.sleep(forTimeInterval: 0.25)
            let observed = readDisplay(counter)
            transitions.append(observed)
            XCTAssertEqual(observed, "\(i)",
                           "BX1: after tap \(i) counter must read \"\(i)\" — got \"\(observed)\". " +
                           "Transitions so far: \(transitions)")
        }
        attachScreenshot(app, name: "BX1-counter-after-3-taps.png")
        attachJSON(transitions, name: "BX1-label-transitions.json")
    }

    // ----- BX3 — Toggle value callback -----
    func testBX3_toggleValueCallback() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-toggle-value-probe")

        attachScreenshot(app, name: "BX3-toggle-initial.png")
        let transitions = ValueBoundControlPattern.toggleAndAssert(
            app: app,
            testCase: self,
            toggleId: "toggle-probe-toggle",
            probeId: "toggle-probe-value",
            expectedTransitions: [
                (switchValue: "0", probeLabel: "false"),
                (switchValue: "1", probeLabel: "true"),
                (switchValue: "0", probeLabel: "false"),
            ]
        )
        attachJSON(transitions, name: "BX3-transitions.json")
    }

    // ----- BX4 — Slider value callback -----
    func testBX4_sliderValueCallback() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-slider-value-probe")

        let values = ValueBoundControlPattern.driveSlider(
            app: app,
            testCase: self,
            sliderId: "slider-probe-slider",
            probeId: "slider-probe-value",
            positions: [0.0, 0.5, 1.0]
        )

        let v0 = values[0], v1 = values[1], v2 = values[2]

        attachJSON([
            ["position": 0.0, "parsed_value": v0],
            ["position": 0.5, "parsed_value": v1],
            ["position": 1.0, "parsed_value": v2],
        ], name: "BX4-drag-sequence.json")

        XCTAssertTrue(v0 <= 0.05,
                      "BX4: position 0.0 must yield value ≤ 0.05 — got \(v0)")
        XCTAssertTrue(v1 >= 0.45 && v1 <= 0.55,
                      "BX4: position 0.5 must yield value in [0.45, 0.55] — got \(v1)")
        XCTAssertTrue(v2 >= 0.95,
                      "BX4: position 1.0 must yield value ≥ 0.95 — got \(v2)")
        XCTAssertTrue(v0 < v1 && v1 < v2,
                      "BX4: slider drag must produce monotonic values — got \(v0), \(v1), \(v2)")
    }

    // ----- BX5 — Runtime override re-render -----
    func testBX5_runtimeOverrideRerender() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-runtime-override-probe")
        let target = app.buttons["override-target"]
        let trigger = app.buttons["make-red-trigger"]
        XCTAssertTrue(target.waitForExistence(timeout: 5),
                      "BX5: override-target must be discoverable")
        XCTAssertTrue(trigger.waitForExistence(timeout: 3),
                      "BX5: make-red-trigger must be discoverable")

        let stateLabel = app.staticTexts["override-state"]
        XCTAssertTrue(stateLabel.waitForExistence(timeout: 3),
                      "BX5: override-state mirror label must be present")

        let beforeText = readDisplay(stateLabel)
        VisualSnapshotPattern.snapshotElement(testCase: self, element: target, name: "BX5-before.png")

        trigger.tap()
        Thread.sleep(forTimeInterval: 0.5)

        let afterText = readDisplay(stateLabel)
        VisualSnapshotPattern.snapshotElement(testCase: self, element: target, name: "BX5-after.png")

        XCTAssertNotEqual(beforeText, afterText,
                          "BX5: override-state label must transition after trigger tap")

        attachJSON([
            "before_state": beforeText,
            "after_state": afterText,
        ], name: "BX5-state-transition.json")

        XCTAssertTrue(target.exists, "BX5: override-target must remain present")
    }

    // ----- BX6 — Form children non-zero (iOS) -----
    func testBX6_formChildrenNonZero() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-form-nested-buttons")

        let r1 = app.buttons["form-row-1"]
        let r2 = app.buttons["form-row-2"]
        let r3 = app.buttons["form-row-3"]
        XCTAssertTrue(r1.waitForExistence(timeout: 5), "BX6: form-row-1 must exist")
        XCTAssertTrue(r2.exists, "BX6: form-row-2 must exist")
        XCTAssertTrue(r3.exists, "BX6: form-row-3 must exist")

        let f1 = r1.frame, f2 = r2.frame, f3 = r3.frame

        XCTAssertTrue(f1.size.width > 0 && f1.size.height >= 44.0,
                      "BX6: row 1 must be ≥44pt tall — got \(f1)")
        XCTAssertTrue(f2.size.width > 0 && f2.size.height >= 44.0,
                      "BX6: row 2 must be ≥44pt tall — got \(f2)")
        XCTAssertTrue(f3.size.width > 0 && f3.size.height >= 44.0,
                      "BX6: row 3 must be ≥44pt tall — got \(f3)")
        XCTAssertTrue(f1.maxY <= f2.minY + 1.0,
                      "BX6: rows 1/2 must not overlap")
        XCTAssertTrue(f2.maxY <= f3.minY + 1.0,
                      "BX6: rows 2/3 must not overlap")

        attachScreenshot(app, name: "BX6-form-rendered.png")
        attachJSON([
            "row1": ["x": f1.minX, "y": f1.minY, "w": f1.width, "h": f1.height],
            "row2": ["x": f2.minX, "y": f2.minY, "w": f2.width, "h": f2.height],
            "row3": ["x": f3.minX, "y": f3.minY, "w": f3.width, "h": f3.height],
        ], name: "BX6-frames.json")

        let counter = app.staticTexts["form-row-2-counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 3),
                      "BX6: form-row-2-counter mirror label must be present")
        let before = readDisplay(counter)
        r2.tap()
        Thread.sleep(forTimeInterval: 0.25)
        let after = readDisplay(counter)

        attachJSON(["before": before, "after": after], name: "BX6-tap-result.json")
        XCTAssertEqual(after, "1",
                       "BX6: row 2 tap must increment counter to \"1\" — got \"\(after)\"")
    }

    // ----- BX8 — Sheet dismiss returns focus -----
    func testBX8_sheetDismissReturnsFocus() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-sheet-focus-return")
        let trigger = app.buttons["sheet-trigger"]
        XCTAssertTrue(trigger.waitForExistence(timeout: 5),
                      "BX8: sheet-trigger must be discoverable")
        XCTAssertFalse(app.buttons["sheet-primary"].waitForExistence(timeout: 0.5),
                       "BX8: sheet-primary must NOT exist before sheet is presented")
        XCTAssertFalse(app.buttons["sheet-cancel"].exists,
                       "BX8: sheet-cancel must NOT exist before sheet is presented")

        let reason = app.staticTexts["dismiss-reason"]
        XCTAssertTrue(reason.waitForExistence(timeout: 3),
                      "BX8: dismiss-reason mirror label must be present")
        attachScreenshot(app, name: "BX8-initial.png")

        var dismissMatrix: [[String: String]] = []

        for path in ["primary", "cancel", "swipe"] {
            attachScreenshot(app, name: "BX8-presented-for-\(path).png")
            let row = SheetDismissPattern.runDismissPath(
                app: app,
                testCase: self,
                triggerId: "sheet-trigger",
                primaryId: "sheet-primary",
                cancelId: "sheet-cancel",
                reasonLabelId: "dismiss-reason",
                path: path,
                expectedReason: path
            )
            dismissMatrix.append(row)
            attachScreenshot(app, name: "BX8-after-\(path).png")
        }

        attachJSON(dismissMatrix, name: "BX8-dismiss-matrix.json")

        // Focus return: sheet-trigger must remain discoverable.
        XCTAssertTrue(trigger.exists,
                      "BX8: sheet-trigger must remain discoverable after all dismissals")
        XCTAssertTrue(trigger.isHittable,
                      "BX8: sheet-trigger must remain hittable after all dismissals")
    }

    // ----- BX9 — Touch target ≥ 44pt (default Button) -----
    func testBX9_touchTargetMinimum() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-button-default")
        let save = app.buttons["save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5),
                      "BX9: save button must be discoverable")

        let frame = save.frame
        XCTAssertTrue(frame.size.width >= 44.0,
                      "BX9: width must be ≥44pt — got \(frame.size.width)")
        XCTAssertTrue(frame.size.height >= 44.0,
                      "BX9: height must be ≥44pt — got \(frame.size.height)")

        attachScreenshot(app, name: "BX9-default-button.png")
        attachJSON([
            "x": frame.minX, "y": frame.minY,
            "w": frame.width, "h": frame.height,
        ], name: "BX9-frame.json")
    }

    // ----- BX10 — Dark mode tint shift -----
    func testBX10_darkModeTintShift_light() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-button-default", appearance: "light")
        XCTAssertTrue(app.buttons["save"].waitForExistence(timeout: 5),
                      "BX10 light: save button must be discoverable")
        attachScreenshot(app, name: "V1-default-button-ios-light.png")
    }

    func testBX10_darkModeTintShift_dark() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-button-default", appearance: "dark")
        XCTAssertTrue(app.buttons["save"].waitForExistence(timeout: 5),
                      "BX10 dark: save button must be discoverable")
        attachScreenshot(app, name: "V1-default-button-ios-dark.png")
    }

    // ----- BX12 — Runtime init order -----
    func testBX12_runtimeInitOrder() throws {
        let app = HostLaunchPattern.launchHost(slug: "phase-03-button-default")
        XCTAssertTrue(app.buttons["save"].waitForExistence(timeout: 5),
                      "BX12: host must reach first SwiftKit-rendered Button without crashing")
        XCTAssertEqual(app.state, .runningForeground,
                       "BX12: app must remain in foreground after first SwiftKit facade call")
    }
}
