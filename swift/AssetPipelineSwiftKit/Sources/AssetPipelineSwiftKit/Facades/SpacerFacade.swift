// SpacerFacade — SwiftUI Spacer() bridge.
//
// Spacer is a layout primitive; this facade exists primarily so renderer
// visit methods follow the uniform "populate + make" shape. Inside a
// SwiftUI VStack/HStack the SwiftUI Spacer collapses content; our
// AppKit / UIKit stacks already insert layout guides for Spacer when
// they need true flex behaviour, so this facade returns a SwiftUI
// Spacer wrapped in a hosting view that reports a small intrinsic size
// — sufficient for the cases where a Spacer is hosted directly inside a
// SwiftUI parent (Form / Grid / Card).

import SwiftUI
import Foundation

@objc(APSKSpacerFacade)
public class SpacerFacade: NSObject {
    @objc public static func makeSpacer(
        overrides: SpacerOverrides
    ) -> APSKPlatformView {
        let minLen = overrides.minLength.map { CGFloat($0.doubleValue) } ?? 0
        var content: AnyView = AnyView(Spacer(minLength: minLen))
        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
