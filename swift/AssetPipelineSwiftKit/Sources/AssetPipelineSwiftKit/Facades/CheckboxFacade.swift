// CheckboxFacade — SwiftUI Toggle(...).toggleStyle(.checkbox) bridge.
// On macOS this produces a native checkbox; on iOS the system falls back
// to the switch style (SwiftUI behaviour) which is the platform-correct
// HIG default.

import SwiftUI
import Foundation

@objc(APSKCheckboxFacade)
public class CheckboxFacade: NSObject {
    @objc public static func makeCheckbox(
        label: String,
        isOn: Bool,
        overrides: CheckboxOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = BoolStorage(initial: isOn, token: actionToken)
        var content: AnyView = AnyView(Toggle(label, isOn: storage.binding))
        #if canImport(AppKit)
        content = AnyView(content.toggleStyle(.checkbox))
        #endif

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(CheckboxHost(storage: storage, content: content))
    }
}

private struct CheckboxHost<Content: View>: View {
    @ObservedObject var storage: BoolStorage
    let content: Content
    var body: some View { content }
}
