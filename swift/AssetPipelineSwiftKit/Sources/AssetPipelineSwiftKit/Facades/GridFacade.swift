// GridFacade — SwiftUI Grid { GridRow { ... } } bridge.
//
// Children are flattened into a single `childViews` array; the
// `rowCellCounts` override carries the per-row cell count so the
// facade can slice them back into GridRow chunks.

import SwiftUI
import Foundation

@objc(APSKGridFacade)
public class GridFacade: NSObject {
    @objc public static func makeGrid(
        childViews: [APSKPlatformView],
        overrides: GridOverrides
    ) -> APSKPlatformView {
        let rowCounts = overrides.rowCellCounts.map { $0.intValue }
        var offsets: [Int] = []
        var acc = 0
        for c in rowCounts {
            offsets.append(acc)
            acc += c
        }

        let hSpacing = overrides.columnSpacing.map { CGFloat($0.doubleValue) }
        let vSpacing = overrides.rowSpacing.map { CGFloat($0.doubleValue) }
        let alignment = alignmentFor(overrides.alignment)

        var content: AnyView
        if #available(iOS 16.0, macOS 13.0, *) {
            content = AnyView(
                Grid(
                    alignment: alignment,
                    horizontalSpacing: hSpacing,
                    verticalSpacing: vSpacing
                ) {
                    ForEach(0..<rowCounts.count, id: \.self) { rIdx in
                        let off = offsets[rIdx]
                        let cnt = rowCounts[rIdx]
                        GridRow {
                            ForEach(0..<cnt, id: \.self) { cIdx in
                                APSKHostedChild(view: childViews[off + cIdx])
                            }
                        }
                    }
                }
            )
        } else {
            // Pre-iOS-16 fallback: VStack of HStacks.
            content = AnyView(
                VStack(spacing: vSpacing ?? 8) {
                    ForEach(0..<rowCounts.count, id: \.self) { rIdx in
                        let off = offsets[rIdx]
                        let cnt = rowCounts[rIdx]
                        HStack(spacing: hSpacing ?? 8) {
                            ForEach(0..<cnt, id: \.self) { cIdx in
                                APSKHostedChild(view: childViews[off + cIdx])
                            }
                        }
                    }
                }
            )
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }

    private static func alignmentFor(_ s: String?) -> Alignment {
        switch s {
        case "leading":  return .leading
        case "trailing": return .trailing
        case "top":      return .top
        case "bottom":   return .bottom
        case "center":   return .center
        default:         return .center
        }
    }
}
