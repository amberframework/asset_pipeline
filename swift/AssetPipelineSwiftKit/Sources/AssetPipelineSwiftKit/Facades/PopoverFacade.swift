// PopoverFacade — SwiftUI .popover(isPresented:) bridge.
//
// macOS has rich popover support; iOS has limited popover behavior
// (most popovers degrade to sheets at compact size classes). SwiftUI
// handles this transparently — the `.popover` modifier defers to the
// runtime to pick the right presentation.

import SwiftUI
import Foundation

@objc(APSKPopoverFacade)
public class PopoverFacade: NSObject {
    @objc public static func makePopover(
        childViews: [APSKPlatformView],
        overrides: PopoverOverrides,
        dismissToken: UInt64
    ) -> APSKPlatformView {
        let isPresented = overrides.isPresented?.boolValue ?? false
        let storage = BoolStorage(initial: isPresented, token: dismissToken)

        let body: AnyView
        if let first = childViews.first {
            body = AnyView(APSKHostedChild(view: first))
        } else {
            body = AnyView(EmptyView())
        }

        let arrow: Edge
        switch overrides.arrowEdge {
        case "top":      arrow = .top
        case "bottom":   arrow = .bottom
        case "leading":  arrow = .leading
        case "trailing": arrow = .trailing
        default:         arrow = .bottom
        }

        // Phase 5 v2 — resolve AppleSemantic key (default "popover")
        // for the popover body's .presentationBackground(<Material>)
        // (iOS 16.4+ / macOS 13.3+ per A1 spike).
        let materialKey: String = overrides.materialSemantic ?? "popover"

        var content: AnyView = AnyView(
            Color.clear
                .frame(width: 1, height: 1)
                .popover(isPresented: storage.binding, arrowEdge: arrow) {
                    let popoverBody = AnyView(
                        Group {
                            body
                        }
                        .frame(
                            minWidth: overrides.preferredWidth.map { CGFloat($0.doubleValue) },
                            minHeight: overrides.preferredHeight.map { CGFloat($0.doubleValue) }
                        )
                    )
                    PopoverFacade.applyPresentationBackground(popoverBody, key: materialKey)
                }
        )

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(PopoverHost(storage: storage, content: content))
    }

    // Phase 5 v2 — applies `.presentationBackground(<SwiftUI Material>)`
    // to the popover body. Default key = "popover" → .regularMaterial;
    // "system_resolved" / nil returns the body unchanged.
    //
    // Phase 5 v2 Rem1 — iOS 26+ / macOS 26+ Liquid Glass path: per
    // architecture doc lines 117 + 119-120, the 26+ SDKs swap the pre-26
    // `.presentationBackground(<Material>)` for `.glassEffect()`. Shape
    // choice (same as SheetFacade): `.glassEffect()` is a content-view
    // modifier, so we wrap the popover body itself rather than chaining
    // `.presentationBackground`. Mirrors GlassBackgroundFacade.swift:64-70.
    fileprivate static func applyPresentationBackground(
        _ v: AnyView, key: String
    ) -> AnyView {
        if MaterialSemanticResolver.shouldSkipModifier(key) { return v }
        if #available(iOS 26.0, macOS 26.0, *) {
            return AnyView(v.glassEffect())
        }
        if #available(iOS 16.4, macOS 13.3, *) {
            if let mat = MaterialSemanticResolver.material(for: key) {
                return AnyView(v.presentationBackground(mat))
            }
        }
        return v
    }
}

private struct PopoverHost<Content: View>: View {
    @ObservedObject var storage: BoolStorage
    let content: Content
    var body: some View { content }
}
