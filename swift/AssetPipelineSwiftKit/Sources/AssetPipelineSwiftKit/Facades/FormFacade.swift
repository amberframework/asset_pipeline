// FormFacade — SwiftUI Form { Section { ... } } bridge.
//
// Crystal flattens its (sections × fields) hierarchy into a flat
// `childViews` array. The facade slices it back into sections using the
// `sectionFieldCounts` array. Headers / footers come from the parallel
// `sectionHeaders` / `sectionFooters` arrays (one entry per section).
// Field labels come from `sectionFieldLabels`, flattened to match
// `childViews`.

import SwiftUI
import Foundation

@objc(APSKFormFacade)
public class FormFacade: NSObject {
    @objc public static func makeForm(
        childViews: [APSKPlatformView],
        overrides: FormOverrides
    ) -> APSKPlatformView {
        let counts = overrides.sectionFieldCounts.map { $0.intValue }
        let headers = overrides.sectionHeaders
        let footers = overrides.sectionFooters
        let labels = overrides.sectionFieldLabels

        // Pre-compute slice offsets per section so the ForEach builder
        // body is O(1) per row.
        var offsets: [Int] = []
        var acc = 0
        for c in counts {
            offsets.append(acc)
            acc += c
        }

        var content: AnyView = AnyView(
            Form {
                ForEach(0..<counts.count, id: \.self) { sIdx in
                    let header = sIdx < headers.count ? headers[sIdx] : ""
                    let footer = sIdx < footers.count ? footers[sIdx] : ""
                    let off = offsets[sIdx]
                    let cnt = counts[sIdx]
                    Section {
                        ForEach(0..<cnt, id: \.self) { fIdx in
                            let absIdx = off + fIdx
                            let lbl = absIdx < labels.count ? labels[absIdx] : ""
                            if !lbl.isEmpty {
                                LabeledContent(lbl) {
                                    APSKHostedChild(view: childViews[absIdx])
                                }
                            } else {
                                APSKHostedChild(view: childViews[absIdx])
                            }
                        }
                    } header: {
                        if !header.isEmpty { Text(header) }
                    } footer: {
                        if !footer.isEmpty { Text(footer) }
                    }
                }
            }
        )

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
