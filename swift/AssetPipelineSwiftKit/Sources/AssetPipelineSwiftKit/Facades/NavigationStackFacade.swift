// NavigationStackFacade — SwiftUI NavigationStack bridge.
//
// Crystal side: a UI::NavigationStack always renders ONE current root
// child (the top of the navigation stack or, if empty, the root). The
// renderer hands that single child to the facade as a one-element
// `childViews` array. The facade wraps it in `APSKHostedChild` and
// embeds it inside a `NavigationStack`. Push/pop transitions are
// handled by SwiftUI's own navigation machinery once the user taps
// any embedded `NavigationLink`.

import SwiftUI
import Foundation

@objc(APSKNavigationStackFacade)
public class NavigationStackFacade: NSObject {
    @objc public static func makeNavigationStack(
        childViews: [APSKPlatformView],
        overrides: NavigationStackOverrides
    ) -> APSKPlatformView {
        let root = childViews.first.map { APSKHostedChild(view: $0) }

        var content: AnyView
        if let title = overrides.title {
            if #available(iOS 16.0, macOS 13.0, *) {
                content = AnyView(
                    NavigationStack {
                        Group {
                            if let root = root { root }
                        }
                        .navigationTitle(title)
                    }
                )
            } else {
                content = AnyView(
                    NavigationView {
                        Group {
                            if let root = root { root }
                        }
                    }
                )
            }
        } else {
            if #available(iOS 16.0, macOS 13.0, *) {
                content = AnyView(
                    NavigationStack {
                        Group {
                            if let root = root { root }
                        }
                    }
                )
            } else {
                content = AnyView(
                    NavigationView {
                        Group {
                            if let root = root { root }
                        }
                    }
                )
            }
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
