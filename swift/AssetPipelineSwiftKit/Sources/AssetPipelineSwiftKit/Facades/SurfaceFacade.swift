// SurfaceFacade — custom SwiftUI surface (lighter than Card).
//
// Surface is a thin container: padding + background, no headline, no
// default border. The shape override controls the clip shape (rectangle
// vs rounded vs circle).

import SwiftUI
import Foundation

@objc(APSKSurfaceFacade)
public class SurfaceFacade: NSObject {
    @objc public static func makeSurface(
        childViews: [APSKPlatformView],
        overrides: SurfaceOverrides
    ) -> APSKPlatformView {
        var body: AnyView = AnyView(
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<childViews.count, id: \.self) { idx in
                    APSKHostedChild(view: childViews[idx])
                }
            }
            .padding(12)
        )

        switch overrides.shape {
        case "rounded":
            body = AnyView(
                body
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            )
        case "circle":
            body = AnyView(
                body
                    .background(.regularMaterial)
                    .clipShape(Circle())
            )
        default:
            body = AnyView(body.background(.regularMaterial))
        }

        if let elev = overrides.elevation, elev.doubleValue > 0 {
            body = AnyView(
                body.shadow(
                    color: Color.black.opacity(0.1),
                    radius: CGFloat(elev.doubleValue),
                    x: 0, y: 1
                )
            )
        }

        let content = CommonModifiers.apply(body, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
