// SearchFieldFacade — SwiftUI search-field bridge.
//
// SwiftUI's `.searchable` modifier is attached to a containing surface
// (List / NavigationStack) rather than constructing a stand-alone
// component. Crystal's `UI::SearchField` ships as a free-standing widget,
// so this facade emits a TextField with a leading magnifying-glass
// SF Symbol and a trailing clear-button to approximate the search look
// outside a List context. When dropped into a SwiftUI `.searchable`
// pipeline by the host app the appearance still composes cleanly.

import SwiftUI
import Foundation

@objc(APSKSearchFieldFacade)
public class SearchFieldFacade: NSObject {
    @objc public static func makeSearchField(
        placeholder: String,
        initialText: String,
        overrides: SearchFieldOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = TextStorage(initial: initialText, token: actionToken)
        let showsCancel = overrides.showsCancelButton?.boolValue ?? true

        let body = HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(placeholder, text: storage.binding)
            if showsCancel && !storage.text.isEmpty {
                Button(action: { storage.binding.wrappedValue = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

        var content: AnyView = AnyView(body)
        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(SearchStorageHost(storage: storage, content: content))
    }
}

private struct SearchStorageHost<Content: View>: View {
    @ObservedObject var storage: TextStorage
    let content: Content
    var body: some View { content }
}
