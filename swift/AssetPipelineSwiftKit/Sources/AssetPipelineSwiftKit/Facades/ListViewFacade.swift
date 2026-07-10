// ListViewFacade — SwiftUI `List { Section { ... } }` bridge.
//
// `UI::ListView` (§6 #25) is a vertical scroll of section-grouped rows.
// Crystal flattens its `Array(Section)` hierarchy into a flat
// `childViews` array. The facade slices it back into sections using
// the `sectionItemCounts` array; per-section headers / footers come
// from the parallel `sectionHeaders` / `sectionFooters` arrays.
//
// The `listStyle` override maps to SwiftUI's `.listStyle(...)`
// modifier. SwiftUI's `List` provides default separators, swipe
// actions, and platform-appropriate chrome (iOS plain/grouped/inset,
// macOS bordered list / sidebar). When `listStyle` is nil the facade
// falls back to `.automatic`.
//
// Selection semantics: this facade currently uses SwiftUI's default
// (no programmatic selection binding). Wiring `selection_mode` would
// require a `Binding<Set<ID>>`-style state holder (see the
// `IntStorage` pattern used by ToggleButton). It is left as a
// follow-up; the Crystal side has no `selection_mode` property today
// (verified against `src/ui/views/list_view.cr`).

import SwiftUI
import Foundation

@objc(APSKListViewFacade)
public class ListViewFacade: NSObject {
    @objc public static func makeListView(
        childViews: [APSKPlatformView],
        overrides: ListViewOverrides
    ) -> APSKPlatformView {
        let counts = overrides.sectionItemCounts.map { $0.intValue }
        let headers = overrides.sectionHeaders
        let footers = overrides.sectionFooters

        // Pre-compute slice offsets per section so the ForEach builder
        // body is O(1) per row.
        var offsets: [Int] = []
        var acc = 0
        for c in counts {
            offsets.append(acc)
            acc += c
        }

        // SwiftUI `.listRowSeparator(.hidden)` is iOS 15 / macOS 13. When
        // the Crystal author explicitly disables separators we apply it
        // per-row; SwiftUI default (separators visible) is the nil-path.
        let hideSeparators: Bool = {
            guard let flag = overrides.showsSeparators else { return false }
            return !flag.boolValue
        }()

        let list = List {
            ForEach(0..<counts.count, id: \.self) { sIdx in
                let header = sIdx < headers.count ? headers[sIdx] : ""
                let footer = sIdx < footers.count ? footers[sIdx] : ""
                let off = offsets[sIdx]
                let cnt = counts[sIdx]
                Section {
                    ForEach(0..<cnt, id: \.self) { iIdx in
                        let absIdx = off + iIdx
                        rowBuilder(view: childViews[absIdx],
                                   hideSeparator: hideSeparators)
                    }
                } header: {
                    if !header.isEmpty { Text(header) }
                } footer: {
                    if !footer.isEmpty { Text(footer) }
                }
            }
        }

        let styled: AnyView = applyListStyle(list, key: overrides.listStyle)
        let composed = CommonModifiers.apply(styled, overrides: overrides)
        return HostingHelpers.host(composed)
    }

    // Apply `.listRowSeparator(.hidden)` only when the host platform
    // supports it (iOS 15+ / macOS 13+). On older targets we fall back
    // to the SwiftUI default.
    @ViewBuilder
    private static func rowBuilder(view: APSKPlatformView,
                                   hideSeparator: Bool) -> some View {
        if hideSeparator {
            if #available(iOS 15.0, macOS 13.0, *) {
                APSKHostedChild(view: view)
                    .listRowSeparator(.hidden)
            } else {
                APSKHostedChild(view: view)
            }
        } else {
            APSKHostedChild(view: view)
        }
    }

    // Map the Crystal `UI::ListStyle` enum (passed as a string by the
    // populator) to SwiftUI's `.listStyle(...)` modifier. Unknown /
    // nil keys fall back to `.automatic`, matching the SwiftUI default
    // for the host platform.
    private static func applyListStyle<L: View>(_ list: L, key: String?) -> AnyView {
        switch key {
        case "plain":
            return AnyView(list.listStyle(.plain))
        case "grouped":
            #if os(iOS)
            return AnyView(list.listStyle(.grouped))
            #else
            return AnyView(list.listStyle(.inset))
            #endif
        case "inset":
            return AnyView(list.listStyle(.inset))
        case "insetGrouped":
            #if os(iOS)
            return AnyView(list.listStyle(.insetGrouped))
            #else
            return AnyView(list.listStyle(.inset))
            #endif
        case "sidebar":
            return AnyView(list.listStyle(.sidebar))
        default:
            return AnyView(list.listStyle(.automatic))
        }
    }
}
