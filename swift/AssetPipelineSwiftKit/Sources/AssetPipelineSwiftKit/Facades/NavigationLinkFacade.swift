// NavigationLinkFacade — SwiftUI NavigationLink bridge.
//
// Crystal passes TWO children: index 0 is the destination view, index 1
// is the optional label child (when nil, the facade renders the label
// as a Text from the positional `label` arg).
//
// Default behavior (no overrides):
//   - Push transition (when embedded inside a NavigationStack)
//   - Label = positional `label` String, optionally with a leading
//     SF Symbol when `icon` override is set.
//   - SwiftUI default disclosure chevron in List contexts.

import SwiftUI
import Foundation

@objc(APSKNavigationLinkFacade)
public class NavigationLinkFacade: NSObject {
    @objc public static func makeNavigationLink(
        label: String,
        childViews: [APSKPlatformView],
        overrides: NavigationLinkOverrides
    ) -> APSKPlatformView {
        // childViews[0] = destination
        let destination: AnyView
        if let dest = childViews.first {
            destination = AnyView(APSKHostedChild(view: dest))
        } else {
            // Fallback destination — empty view (NavigationLink still
            // valid but tap is a no-op visually).
            destination = AnyView(EmptyView())
        }

        var content: AnyView = AnyView(
            NavigationLink {
                destination
            } label: {
                if let symbol = overrides.icon {
                    Label(label, systemImage: symbol)
                } else {
                    Text(label)
                }
            }
        )

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
