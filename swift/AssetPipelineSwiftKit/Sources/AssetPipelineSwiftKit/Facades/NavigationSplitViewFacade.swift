// NavigationSplitViewFacade — SwiftUI NavigationSplitView bridge.
//
// Crystal hands three slots as `childViews`: [sidebar, content, detail].
// Any slot may be a sentinel-null pointer wrapped as a placeholder — the
// renderer always passes the same count (3) for stable slot semantics.
// When a slot's pointer is null the facade substitutes an empty view.

import SwiftUI
import Foundation

@objc(APSKNavigationSplitViewFacade)
public class NavigationSplitViewFacade: NSObject {
    @objc public static func makeNavigationSplitView(
        childViews: [APSKPlatformView],
        overrides: NavigationSplitViewOverrides
    ) -> APSKPlatformView {
        // childViews indices: 0 = sidebar, 1 = content, 2 = detail.
        // The Crystal side always supplies exactly 3 entries; null slots
        // are passed as freshly-allocated platform views holding nothing
        // (an empty NSView/UIView). Treat any entry as renderable.
        //
        // Phase 5 v2: the sidebar pane gets a SwiftUI Material background
        // resolved from `materialSemantic` (default :sidebar →
        // .regularMaterial). The content + detail panes are left at
        // SwiftUI defaults per architecture doc lines 100-102 (sidebar pane
        // only). On iOS 26+ / macOS 26+ Liquid Glass path, the system
        // resolves material strength automatically.
        let materialKey: String = overrides.materialSemantic ?? "sidebar"
        let sidebarBase: AnyView = childViews.indices.contains(0)
            ? AnyView(APSKHostedChild(view: childViews[0]))
            : AnyView(EmptyView())
        // Phase 5 v2 Rem1 — sidebar-pane-only material gate (architecture
        // doc line 90: "only the sidebar pane gets material … the content +
        // detail panes remain system-default"). On iOS 26+ / macOS 26+ the
        // sidebar pane swaps `.background(<Material>)` for `.glassEffect()`
        // per architecture doc lines 117 + 119-120 — Liquid Glass is
        // advisory-only / system-resolved regardless of semantic. Scoping is
        // PRESERVED: only `sidebarBase` is wrapped; `mid` + `detail` are
        // unchanged.
        let sidebar: AnyView = {
            if MaterialSemanticResolver.shouldSkipModifier(materialKey) {
                return sidebarBase
            }
            if #available(iOS 26.0, macOS 26.0, *) {
                return AnyView(sidebarBase.glassEffect())
            }
            if #available(iOS 15.0, macOS 12.0, *) {
                if let mat = MaterialSemanticResolver.material(for: materialKey) {
                    return AnyView(sidebarBase.background(mat))
                }
            }
            return sidebarBase
        }()
        let mid: AnyView = childViews.indices.contains(1)
            ? AnyView(APSKHostedChild(view: childViews[1]))
            : AnyView(EmptyView())
        let detail: AnyView = childViews.indices.contains(2)
            ? AnyView(APSKHostedChild(view: childViews[2]))
            : AnyView(EmptyView())

        var content: AnyView
        if #available(iOS 16.0, macOS 13.0, *) {
            content = AnyView(
                NavigationSplitView {
                    sidebar
                } content: {
                    mid
                } detail: {
                    detail
                }
            )
        } else {
            // Pre-iOS-16 fallback: two-column NavigationView.
            content = AnyView(
                NavigationView {
                    sidebar
                    mid
                    detail
                }
            )
        }

        if let w = overrides.sidebarWidth {
            // SwiftUI's navigationSplitViewColumnWidth is the canonical
            // sidebar-width modifier on iOS 16+ / macOS 13+; pre-API
            // platforms ignore the request.
            if #available(iOS 16.0, macOS 13.0, *) {
                content = AnyView(
                    content.navigationSplitViewColumnWidth(CGFloat(w.doubleValue))
                )
            }
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
