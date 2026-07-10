import UIKit

// Swift wrapper around the Crystal C-ABI bridge functions.
// Pattern mirrors happy_coach/mobile/ios/Sources/CrystalBridge.swift.

enum CrystalBridge {
    private static var didInit = false

    static func initialize() {
        guard !didInit else { return }
        crystal_init()
        didInit = true
    }

    /// Render a HIG component by slug and return the resulting UIView.
    /// Crystal returns a retained UIView*; ownership transfers here.
    static func render(slug: String) -> UIView? {
        initialize()
        return slug.withCString { ptr in
            guard let raw = crystal_render_slug(ptr) else { return nil }
            let view = Unmanaged<UIView>.fromOpaque(raw).takeRetainedValue()
            // Tag the root as a container (NOT an accessibility element)
            // so XCUITest can descend through it to discover the SwiftUI
            // buttons / labels nested underneath. Setting
            // `isAccessibilityElement = true` on a container collapses every
            // descendant out of the AX tree, which is what made
            // `app.buttons["tap-probe-button"]` undiscoverable in iter 5.
            //
            // XCUITest still finds the container via
            // `app.otherElements["hig-component-root"]` because the
            // identifier itself does not require `isAccessibilityElement`
            // — element queries walk the view hierarchy by identifier.
            view.accessibilityIdentifier = "hig-component-root"
            view.isAccessibilityElement = false
            return view
        }
    }
}
