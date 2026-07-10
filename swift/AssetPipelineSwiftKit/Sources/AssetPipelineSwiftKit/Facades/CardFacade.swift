// CardFacade — custom SwiftUI Card built from VStack + padding + material
// background + corner radius.
//
// "Card" is not a single SwiftUI primitive; this facade composes the
// HIG-correct grouped-card chrome the existing Crystal Card renders.
// Default behavior:
//   - 21pt padding (Lg token per HIG Boxes / Content)
//   - .regularMaterial background (Liquid Glass-friendly grouped card)
//   - Rounded corners at ~10pt (HIG card token)
//   - Optional headline title above content

import SwiftUI
import Foundation

@objc(APSKCardFacade)
public class CardFacade: NSObject {
    @objc public static func makeCard(
        childViews: [APSKPlatformView],
        overrides: CardOverrides
    ) -> APSKPlatformView {
        var body: AnyView = AnyView(
            VStack(alignment: .leading, spacing: 8) {
                if let title = overrides.title {
                    Text(title).font(.headline)
                }
                ForEach(0..<childViews.count, id: \.self) { idx in
                    APSKHostedChild(view: childViews[idx])
                }
            }
            .padding(21)
        )

        // Background material vs outline:
        if overrides.isOutlined?.boolValue == true {
            body = AnyView(
                body
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
        } else {
            body = AnyView(
                body
                    .background(materialFor(overrides.material))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
        }

        if let elev = overrides.elevation {
            body = AnyView(
                body.shadow(
                    color: Color.black.opacity(0.12),
                    radius: CGFloat(elev.doubleValue),
                    x: 0, y: 1
                )
            )
        }

        let content = CommonModifiers.apply(body, overrides: overrides)
        return HostingHelpers.host(content)
    }

    private static func materialFor(_ s: String?) -> some ShapeStyle {
        switch s {
        case "thin":       return AnyShapeStyle(.thinMaterial)
        case "thick":      return AnyShapeStyle(.thickMaterial)
        case "ultra_thin": return AnyShapeStyle(.ultraThinMaterial)
        case "regular":    return AnyShapeStyle(.regularMaterial)
        case "tertiary":   return AnyShapeStyle(.thinMaterial)
        case "secondary":  return AnyShapeStyle(.regularMaterial)
        default:           return AnyShapeStyle(.regularMaterial)
        }
    }
}
