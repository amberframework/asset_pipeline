// LinkButtonFacade — SwiftUI Link(_:destination:) bridge.
//
// The system handles tap routing, focus, hover, and accent colour
// (which inherits the brand tint cascade). On a non-URL value we fall
// back to a regular Button that fires the action token so Crystal-side
// custom routing still works.

import SwiftUI
import Foundation

@objc(APSKLinkButtonFacade)
public class LinkButtonFacade: NSObject {
    @objc public static func makeLinkButton(
        label: String,
        url: String,
        overrides: LinkButtonOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        var content: AnyView
        if let parsed = URL(string: url), !url.isEmpty {
            content = AnyView(Link(label, destination: parsed))
        } else {
            content = AnyView(Button(label) {
                CallbackBridge.fire(token: actionToken, value: 0)
            })
        }
        // SwiftUI's `Link` defaults to `.foregroundStyle(.link)` (system
        // blue) and does NOT follow the `.tint()` accent cascade, so a
        // brand-tinted root still renders Link as system blue. Re-applying
        // `.foregroundStyle(.tint)` here pulls Link back into the accent
        // cascade — when the host has installed a brand tint via
        // `APSKRuntime.setBrandTint(...)`, the Link text now renders in the
        // brand colour. Plain Button (the empty-URL fallback) already
        // follows the tint cascade, so this only meaningfully affects the
        // Link branch — but applying it uniformly keeps the behaviour
        // identical across both branches.
        content = AnyView(content.foregroundStyle(.tint))
        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
