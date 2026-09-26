// PickerFacade — SwiftUI Picker(...) with configurable picker style.

import SwiftUI
import Foundation

// watchOS: ENABLED (Phase D Bucket-2 P1 port, 2026-06-02). SwiftUI `Picker` is
// watch-native; `.wheel`/`.inline`/`.navigationLink` styles are valid on watchOS,
// but `.menu` (MenuPickerStyle) and `.segmented` (SegmentedPickerStyle) are both
// `@available(watchOS, unavailable)` and are gated off there (unknown keys fall
// through to the default wheel-style picker). See watch-facade-bucket-audit.md.
@objc(APSKPickerFacade)
public class PickerFacade: NSObject {
    @objc public static func makePicker(
        label: String,
        options: [String],
        selectedIndex: Int,
        overrides: PickerOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = IntStorage(initial: selectedIndex, token: actionToken)

        #if os(macOS)
        if let swatchSpec = overrides.surfaceCraftSwatchSpec {
            let content = SwatchPickerHost(storage: storage, specification: swatchSpec)
            return HostingHelpers.host(CommonModifiers.apply(AnyView(content), overrides: overrides))
        }
        #endif

        var content: AnyView = AnyView(
            Picker(label, selection: storage.binding) {
                ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                    Text(opt).tag(idx)
                }
            }
        )

        switch overrides.pickerStyle {
        #if !os(watchOS)
        // MenuPickerStyle + SegmentedPickerStyle are @available(watchOS, unavailable).
        case "menu":
            content = AnyView(content.pickerStyle(.menu))
        case "segmented":
            content = AnyView(content.pickerStyle(.segmented))
        #endif
        case "wheel":
            #if canImport(UIKit)
            content = AnyView(content.pickerStyle(.wheel))
            #endif
        case "inline":
            content = AnyView(content.pickerStyle(.inline))
        case "navigationlink":
            #if canImport(UIKit)
            content = AnyView(content.pickerStyle(.navigationLink))
            #endif
        default: break
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(IntHost(storage: storage, content: content))
    }
}
