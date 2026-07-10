// SegmentedControlFacade — SwiftUI Picker(...).pickerStyle(.segmented) bridge.

import SwiftUI
import Foundation

@objc(APSKSegmentedControlFacade)
public class SegmentedControlFacade: NSObject {
    @objc public static func makeSegmentedControl(
        segments: [String],
        selectedIndex: Int,
        overrides: SegmentedControlOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = IntStorage(initial: selectedIndex, token: actionToken)

        var content: AnyView = AnyView(
            Picker("", selection: storage.binding) {
                ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                    Text(seg).tag(idx)
                }
            }
            .pickerStyle(.segmented)
        )

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(IntHost(storage: storage, content: content))
    }
}
