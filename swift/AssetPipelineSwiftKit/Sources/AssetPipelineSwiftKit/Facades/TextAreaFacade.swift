// TextAreaFacade — SwiftUI multi-line text input bridge.
//
// SwiftUI's stable multi-line input is `TextEditor`; iOS 16+ also
// supports `TextField(text:axis:.vertical)`. We use TextEditor as the
// trunk so behaviour is identical across iOS 16+ and macOS 13+.

import SwiftUI
import Foundation

@objc(APSKTextAreaFacade)
public class TextAreaFacade: NSObject {
    @objc public static func makeTextArea(
        placeholder: String,
        initialText: String,
        overrides: TextAreaOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = TextStorage(initial: initialText, token: actionToken)

        var editor: AnyView = AnyView(
            TextEditor(text: storage.binding)
                .frame(minHeight: 80)
        )
        if let n = overrides.lineLimit, n.intValue > 0 {
            editor = AnyView(editor.lineLimit(n.intValue))
        }
        if let editable = overrides.editable, !editable.boolValue {
            editor = AnyView(editor.disabled(true))
        }

        var content: AnyView = editor
        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(TextAreaStorageHost(storage: storage, content: content))
    }
}

private struct TextAreaStorageHost<Content: View>: View {
    @ObservedObject var storage: TextStorage
    let content: Content
    var body: some View { content }
}
