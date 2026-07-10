// Phase 6.5 D4 — Value-bound control pattern.
//
// Covers the BX3 (Toggle) + BX4 (Slider) reactive value-mirror checks:
// drive a control, read the value-mirror Label, assert the reactive
// transition.
//
// Usage:
//   ValueBoundControlPattern.toggleAndAssert(
//       app: app,
//       toggleId: "toggle-probe-toggle",
//       probeId: "toggle-probe-value",
//       expectedTransitions: [("0", "false"), ("1", "true"), ("0", "false")]
//   )

import XCTest

enum ValueBoundControlPattern {
    /// Drive the switch through `count` taps, asserting (switchValue, probeLabel)
    /// pairs at each step. The first entry of `expectedTransitions` is the
    /// initial state BEFORE any tap.
    @discardableResult
    static func toggleAndAssert(
        app: XCUIApplication,
        testCase: XCTestCase,
        toggleId: String,
        probeId: String,
        expectedTransitions: [(switchValue: String, probeLabel: String)]
    ) -> [[String: String]] {
        let toggle = app.switches[toggleId]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5),
                      "ValueBoundControlPattern: \(toggleId) must be discoverable")

        let probe = app.staticTexts[probeId]
        XCTAssertTrue(probe.waitForExistence(timeout: 3),
                      "ValueBoundControlPattern: \(probeId) mirror label must be present")

        var transitions: [[String: String]] = []

        let captureFrame: () -> [String: String] = {
            let val = (toggle.value as? String) ?? ""
            return ["switch_value": val, "probe_label": testCase.readDisplay(probe)]
        }

        // Initial.
        let initial = captureFrame()
        transitions.append(initial)
        XCTAssertEqual(initial["switch_value"], expectedTransitions[0].switchValue)
        XCTAssertEqual(initial["probe_label"], expectedTransitions[0].probeLabel)

        for i in 1..<expectedTransitions.count {
            toggle.tap()
            Thread.sleep(forTimeInterval: 0.25)
            let post = captureFrame()
            transitions.append(post)
            XCTAssertEqual(post["switch_value"], expectedTransitions[i].switchValue,
                           "ValueBoundControlPattern: tap \(i) switch value mismatch")
            XCTAssertEqual(post["probe_label"], expectedTransitions[i].probeLabel,
                           "ValueBoundControlPattern: tap \(i) probe label mismatch")
        }
        return transitions
    }

    /// Drive a slider to each of `positions`, return parsed probe values.
    @discardableResult
    static func driveSlider(
        app: XCUIApplication,
        testCase: XCTestCase,
        sliderId: String,
        probeId: String,
        positions: [Double]
    ) -> [Double] {
        let slider = app.sliders[sliderId]
        XCTAssertTrue(slider.waitForExistence(timeout: 5),
                      "ValueBoundControlPattern: \(sliderId) must be discoverable")

        let probe = app.staticTexts[probeId]
        XCTAssertTrue(probe.waitForExistence(timeout: 3),
                      "ValueBoundControlPattern: \(probeId) mirror label must be present")

        var values: [Double] = []
        for pos in positions {
            slider.adjust(toNormalizedSliderPosition: CGFloat(pos))
            Thread.sleep(forTimeInterval: 0.3)
            values.append(Double(testCase.readDisplay(probe)) ?? -1)
        }
        return values
    }
}
