// Phase 6.5 D4 — AX tree dump pattern.
//
// Dumps the accessibility tree under a given root element as a JSON
// XCTAttachment for offline inspection. Mirror of AXTestPatterns::AXTreeWalk
// on macOS.

import XCTest

enum AXTreeDumpPattern {
    /// Walk descendants of `root` (default: app root) and return a Codable
    /// dictionary of {identifier, label, type}.
    static func dump(
        app: XCUIApplication,
        root: XCUIElement? = nil,
        depthLimit: Int = 8
    ) -> [[String: String]] {
        let actualRoot = root ?? app
        let snapshot = (try? actualRoot.snapshot()) // XCUIElementSnapshot
        guard let snap = snapshot else { return [] }
        return Self.walk(snap, depth: 0, limit: depthLimit)
    }

    private static func walk(
        _ snap: XCUIElementSnapshot,
        depth: Int,
        limit: Int
    ) -> [[String: String]] {
        var out: [[String: String]] = []
        out.append([
            "identifier": snap.identifier,
            "label": snap.label,
            "type": "\(snap.elementType.rawValue)",
            "depth": "\(depth)",
        ])
        if depth < limit {
            for child in snap.children {
                out.append(contentsOf: Self.walk(child, depth: depth + 1, limit: limit))
            }
        }
        return out
    }

    /// Attach the dump as a JSON XCTAttachment.
    static func attach(testCase: XCTestCase, app: XCUIApplication, name: String) {
        let dump = Self.dump(app: app)
        testCase.attachJSON(dump, name: name)
    }
}
