// ToggleButtonFacade — Button that reflects a boolean selected state.
//
// SwiftUI doesn't expose a single "toggle button" primitive; we render
// a `Toggle` with `.toggleStyle(.button)` which is the canonical SwiftUI
// way to show a button that visually reflects a bool.

import SwiftUI
import Foundation

@objc(APSKToggleButtonFacade)
public class ToggleButtonFacade: NSObject {
    @objc public static func makeToggleButton(
        label: String,
        overrides: ToggleButtonOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let initial = overrides.isSelected?.boolValue ?? false
        let storage = BoolStorage(initial: initial, token: actionToken)

        var content: AnyView
        if let icon = overrides.icon, !icon.isEmpty {
            content = AnyView(
                Toggle(isOn: storage.binding) {
                    Label(label, systemImage: icon)
                }
                .toggleStyle(.button)
            )
        } else {
            content = AnyView(
                Toggle(label, isOn: storage.binding)
                    .toggleStyle(.button)
            )
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(ToggleButtonHost(storage: storage, content: content))
    }
}

private struct ToggleButtonHost<Content: View>: View {
    @ObservedObject var storage: BoolStorage
    let content: Content
    var body: some View { content }
}
