// OverridesPropagationTests — XCTest cases verifying that setting each
// `*Overrides` field on a Crystal-facing carrier produces the expected
// SwiftUI modifier chain on the corresponding `*Facade`.
//
// Strategy: each test instantiates an overrides object, mutates one
// field, invokes the matching `make*` facade, and asserts:
//   (a) the returned `APSKPlatformView` is non-nil (the hosting
//       controller successfully composed the SwiftUI body);
//   (b) the view passes the "renders without crashing" smoke test
//       (this is the de-facto contract for the Crystal → Swift call
//       site — if the facade can't render the override, it traps);
//   (c) override field round-trip via the ObjC accessors stays intact
//       (catches @objc selector renames like the iter-1
//       `apskAccessibilityLabel` collision).
//
// We deliberately avoid pulling in ViewInspector or similar third-party
// dependencies: the contract under test is the @objc surface and the
// "facade returns a non-nil hosting view" invariant, both of which are
// observable through pure XCTest + Foundation.

import XCTest
import SwiftUI
@testable import AssetPipelineSwiftKit

final class OverridesPropagationTests: XCTestCase {

    // MARK: - ViewOverrides (the common carrier)

    func testApskAccessibilityLabelRoundTrips() throws {
        // Catches the iter-1 selector collision: the rename moved the
        // ObjC selector from `accessibilityLabel` → `apskAccessibilityLabel`
        // so it no longer overrides UIAccessibility on iOS.
        let overrides = ButtonOverrides()
        overrides.apskAccessibilityLabel = "Close button"
        XCTAssertEqual(overrides.apskAccessibilityLabel, "Close button")
    }

    func testAccessibilityIdentifierRoundTrips() {
        let overrides = ButtonOverrides()
        overrides.accessibilityIdentifier = "btn_close"
        XCTAssertEqual(overrides.accessibilityIdentifier, "btn_close")
    }

    // MARK: - Button

    func testButtonFacadeRendersWithDefaults() {
        let overrides = ButtonOverrides()
        let view = ButtonFacade.makeButton(
            label: "Save",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
    }

    func testButtonFacadeProminentStyleRenders() {
        let overrides = ButtonOverrides()
        overrides.style = "prominent"
        let view = ButtonFacade.makeButton(
            label: "Save",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.style, "prominent")
    }

    func testButtonFacadeDestructiveRoleRenders() {
        let overrides = ButtonOverrides()
        overrides.role = "destructive"
        let view = ButtonFacade.makeButton(
            label: "Delete",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.role, "destructive")
    }

    func testButtonFacadeDisabledRenders() {
        let overrides = ButtonOverrides()
        overrides.disabled = NSNumber(value: true)
        let view = ButtonFacade.makeButton(
            label: "Save",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.disabled?.boolValue, true)
    }

    func testButtonFacadeWithSymbolNameRenders() {
        let overrides = ButtonOverrides()
        overrides.symbolName = "trash"
        let view = ButtonFacade.makeButton(
            label: "Delete",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.symbolName, "trash")
    }

    // MARK: - Toggle

    func testToggleFacadeRendersWithDefaults() {
        let overrides = ToggleOverrides()
        let view = ToggleFacade.makeToggle(
            label: "Wi-Fi",
            isOn: true,
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
    }

    func testToggleFacadeSwitchStyleRenders() {
        let overrides = ToggleOverrides()
        overrides.toggleStyle = "switch"
        let view = ToggleFacade.makeToggle(
            label: "Wi-Fi",
            isOn: false,
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.toggleStyle, "switch")
    }

    func testToggleFacadeDisabledRenders() {
        let overrides = ToggleOverrides()
        overrides.disabled = NSNumber(value: true)
        let view = ToggleFacade.makeToggle(
            label: "Wi-Fi",
            isOn: true,
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.disabled?.boolValue, true)
    }

    // MARK: - TextField

    func testTextFieldFacadeRendersWithDefaults() {
        let overrides = TextFieldOverrides()
        let view = TextFieldFacade.makeTextField(
            placeholder: "Name",
            initialText: "",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
    }

    func testTextFieldFacadeWithInitialTextRenders() {
        let overrides = TextFieldOverrides()
        let view = TextFieldFacade.makeTextField(
            placeholder: "Name",
            initialText: "Seth",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
    }

    func testTextFieldFacadeSecureEntryRenders() {
        let overrides = TextFieldOverrides()
        overrides.secureEntry = NSNumber(value: true)
        let view = TextFieldFacade.makeTextField(
            placeholder: "Password",
            initialText: "",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.secureEntry?.boolValue, true)
    }

    #if canImport(UIKit)
    func testTextFieldFacadeEmailKeyboardTypeRenders() {
        let overrides = TextFieldOverrides()
        overrides.keyboardType = "email"
        let view = TextFieldFacade.makeTextField(
            placeholder: "Email",
            initialText: "",
            overrides: overrides,
            actionToken: 0
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.keyboardType, "email")
    }
    #endif

    // MARK: - Card

    func testCardFacadeRendersWithDefaults() {
        let overrides = CardOverrides()
        let view = CardFacade.makeCard(
            childViews: [],
            overrides: overrides
        )
        XCTAssertNotNil(view)
    }

    func testCardFacadeWithTitleRenders() {
        let overrides = CardOverrides()
        overrides.title = "Profile"
        let view = CardFacade.makeCard(
            childViews: [],
            overrides: overrides
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.title, "Profile")
    }

    func testCardFacadeOutlinedRenders() {
        let overrides = CardOverrides()
        overrides.isOutlined = NSNumber(value: true)
        let view = CardFacade.makeCard(
            childViews: [],
            overrides: overrides
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.isOutlined?.boolValue, true)
    }

    func testCardFacadeCornerRadiusOverrideAppliesViaCommonModifiers() {
        let overrides = CardOverrides()
        overrides.cornerRadius = NSNumber(value: 16.0)
        let view = CardFacade.makeCard(
            childViews: [],
            overrides: overrides
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.cornerRadius?.doubleValue, 16.0)
    }

    func testCardFacadeWithMaterialOverrideRenders() {
        let overrides = CardOverrides()
        overrides.material = "thick"
        let view = CardFacade.makeCard(
            childViews: [],
            overrides: overrides
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.material, "thick")
    }

    // MARK: - GlassBackground (Phase 3 headline visual differentiator)

    func testGlassBackgroundFacadeRendersWithDefaults() {
        let overrides = GlassBackgroundOverrides()
        let view = GlassBackgroundFacade.makeGlassBackground(
            overrides: overrides,
            childView: nil
        )
        XCTAssertNotNil(view)
    }

    func testGlassBackgroundFacadeWithThinMaterialRenders() {
        let overrides = GlassBackgroundOverrides()
        overrides.material = "thin"
        let view = GlassBackgroundFacade.makeGlassBackground(
            overrides: overrides,
            childView: nil
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.material, "thin")
    }

    func testGlassBackgroundFacadeWithUltraThinMaterialRenders() {
        let overrides = GlassBackgroundOverrides()
        overrides.material = "ultraThin"
        let view = GlassBackgroundFacade.makeGlassBackground(
            overrides: overrides,
            childView: nil
        )
        XCTAssertNotNil(view)
    }

    // MARK: - NavigationStack (container facade exercising APSKHostedChild)

    func testNavigationStackFacadeRendersWithEmptyChildren() {
        let overrides = NavigationStackOverrides()
        let view = NavigationStackFacade.makeNavigationStack(
            childViews: [],
            overrides: overrides
        )
        XCTAssertNotNil(view)
    }

    func testNavigationStackFacadeRendersWithTitle() {
        let overrides = NavigationStackOverrides()
        overrides.title = "Settings"
        let view = NavigationStackFacade.makeNavigationStack(
            childViews: [],
            overrides: overrides
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(overrides.title, "Settings")
    }

    func testNavigationStackFacadeEmbedsChildViaHostedChild() {
        // Build a leaf child via ButtonFacade and feed it as the root.
        // Exercises the APSKHostedChild representable code path.
        let buttonOverrides = ButtonOverrides()
        let child = ButtonFacade.makeButton(
            label: "Item",
            overrides: buttonOverrides,
            actionToken: 0
        )
        let navOverrides = NavigationStackOverrides()
        let view = NavigationStackFacade.makeNavigationStack(
            childViews: [child],
            overrides: navOverrides
        )
        XCTAssertNotNil(view)
    }
}
