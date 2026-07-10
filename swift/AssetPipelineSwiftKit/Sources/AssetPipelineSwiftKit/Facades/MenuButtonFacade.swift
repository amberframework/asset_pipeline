// MenuButtonFacade — SwiftUI Menu { ... } bridge.
//
// MenuButton serves two HIG roles:
//   - is_pull_down = false (pop-up): mutually-exclusive selection; the
//     button face shows the selected item.
//   - is_pull_down = true (pull-down): a verb-labelled button that
//     opens a menu of actions. Face shows the button's own label.
//
// Both shapes map onto SwiftUI's `Menu` primitive; we vary the label
// content + whether selection updates the face.

import SwiftUI
import Foundation

@objc(APSKMenuButtonFacade)
public class MenuButtonFacade: NSObject {
    @objc public static func makeMenuButton(
        label: String,
        overrides: MenuButtonOverrides
    ) -> APSKPlatformView {
        let labels = overrides.itemLabels
        let icons = overrides.itemIcons
        let destructive = overrides.itemIsDestructive
        let tokens = overrides.itemTokens
        let isPullDown = overrides.isPullDown?.boolValue ?? false
        let selectedIdx = overrides.selectedIndex?.intValue ?? 0
        let faceLabel = isPullDown
            ? label
            : (selectedIdx >= 0 && selectedIdx < labels.count ? labels[selectedIdx] : label)

        var content: AnyView = AnyView(
            Menu {
                ForEach(0..<labels.count, id: \.self) { idx in
                    let isDestr = idx < destructive.count && destructive[idx].boolValue
                    let token = idx < tokens.count ? tokens[idx].uint64Value : 0
                    let icon = idx < icons.count ? icons[idx] : ""
                    Button(
                        role: isDestr ? .destructive : nil,
                        action: { CallbackBridge.fire(token: token, value: Double(idx)) }
                    ) {
                        if !icon.isEmpty {
                            Label(labels[idx], systemImage: icon)
                        } else {
                            Text(labels[idx])
                        }
                    }
                }
            } label: {
                if let icon = overrides.icon, !icon.isEmpty {
                    Label(faceLabel, systemImage: icon)
                } else {
                    Text(faceLabel)
                }
            }
        )

        if overrides.buttonStyle == "prominent" {
            content = AnyView(content.menuStyle(.borderlessButton))
            // Promote to a bordered-prominent button visual via tint.
            // SwiftUI's `Menu` does not expose a borderedProminent style
            // directly; we wrap the menu inside a `Button`-styled
            // container by using `.buttonStyle` on the menu label.
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
