// DividerFacade — SwiftUI Divider() bridge.
//
// SwiftUI's `Divider` reads its colour from the current foreground style
// in the system separator role; the brand tint cascade does NOT colour
// separators (an Apple convention). When `foregroundColor` is set on the
// ViewOverrides the CommonModifiers cascade applies it via
// `.foregroundStyle(_:)`.

import SwiftUI
import Foundation

@objc(APSKDividerFacade)
public class DividerFacade: NSObject {
    @objc public static func makeDivider(
        overrides: DividerOverrides
    ) -> APSKPlatformView {
        var content: AnyView
        if overrides.orientation == "vertical" {
            content = AnyView(Divider().frame(maxHeight: .infinity))
        } else {
            content = AnyView(Divider())
        }
        if let t = overrides.thickness {
            // SwiftUI does not expose a public thickness modifier on
            // Divider; we approximate via a `Rectangle().frame(height:)`
            // fallback when an explicit thickness is requested.
            //
            // `Color(.separator)` (or `.fill(.separator)`) requires
            // iOS 17 / macOS 14. The package targets iOS 16 / macOS 13
            // so we fall back to a semantic secondary tone that tracks
            // appearance correctly on both OSes.
            content = AnyView(
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: CGFloat(t.doubleValue))
            )
        }
        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
