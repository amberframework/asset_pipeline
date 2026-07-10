// Phase 6.5 D4 — Attachment pattern.
//
// XCTAttachment helpers extracted from Phase03BehaviorTests so every
// test suite uses the same screenshot + JSON attachment ergonomics.

import XCTest

extension XCTestCase {
    /// Attach a full-screen XCUIScreen screenshot with `.keepAlways`.
    func attachScreenshot(_ app: XCUIApplication, name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: screenshot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Attach an element-scoped screenshot.
    func attachElementScreenshot(_ element: XCUIElement, name: String) {
        let shot = element.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Attach an arbitrary Codable-ish object as pretty-printed JSON.
    func attachJSON(_ object: Any, name: String) {
        guard let data = try? JSONSerialization.data(
            withJSONObject: object, options: [.prettyPrinted]
        ) else { return }
        let att = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Read the displayed text from an XCUIElement. SwiftUI surfaces Text
    /// content as .label normally, but with .accessibilityValue(_:) it
    /// shifts to .value. Read both and take the first non-empty.
    func readDisplay(_ element: XCUIElement) -> String {
        let label = element.label
        if !label.isEmpty { return label }
        if let v = element.value as? String { return v }
        return ""
    }
}
