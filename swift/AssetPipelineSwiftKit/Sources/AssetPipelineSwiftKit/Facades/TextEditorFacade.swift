// TextEditorFacade — full-featured TextEditor variant.
//
// Differs from TextAreaFacade in that it does not impose a min height
// (callers compose with their own frame) and exposes future hooks for
// syntax highlighting (currently ignored — SwiftUI does not ship a
// built-in highlighter; the override field is recorded for future
// AttributedString integration).

import SwiftUI
import Foundation

@objc(APSKTextEditorFacade)
public class TextEditorFacade: NSObject {
    @objc public static func makeTextEditor(
        placeholder: String,
        initialText: String,
        overrides: TextEditorOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = TextStorage(initial: initialText, token: actionToken)

        var content: AnyView = AnyView(TextEditor(text: storage.binding))
        if let editable = overrides.editable, !editable.boolValue {
            content = AnyView(content.disabled(true))
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(TextEditorStorageHost(storage: storage, content: content))
    }
}

private struct TextEditorStorageHost<Content: View>: View {
    @ObservedObject var storage: TextStorage
    let content: Content
    var body: some View { content }
}
