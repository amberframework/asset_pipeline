// RadioGroupFacade — SwiftUI Picker(...).pickerStyle(.radioGroup) bridge.

import SwiftUI
import Foundation

@objc(APSKRadioGroupFacade)
public class RadioGroupFacade: NSObject {
    @objc public static func makeRadioGroup(
        options: [String],
        selectedIndex: Int,
        overrides: RadioGroupOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = IntStorage(initial: selectedIndex, token: actionToken)

        var content: AnyView = AnyView(
            Picker("", selection: storage.binding) {
                ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                    Text(opt).tag(idx)
                }
            }
        )
        #if canImport(AppKit)
        content = AnyView(content.pickerStyle(.radioGroup))
        #endif

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(IntHost(storage: storage, content: content))
    }
}

struct IntHost<Content: View>: View {
    @ObservedObject var storage: IntStorage
    let content: Content
    var body: some View { content }
}
