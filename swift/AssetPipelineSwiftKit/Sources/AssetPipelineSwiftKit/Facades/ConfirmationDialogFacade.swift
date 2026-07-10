// ConfirmationDialogFacade — SwiftUI .confirmationDialog(...) bridge.
//
// On iOS the dialog renders as an action sheet from the bottom of the
// screen; on macOS it renders as a modal alert with destructive emphasis
// for the confirm button when style == "destructive".

import SwiftUI
import Foundation

@objc(APSKConfirmationDialogFacade)
public class ConfirmationDialogFacade: NSObject {
    @objc public static func makeConfirmationDialog(
        title: String,
        message: String,
        overrides: ConfirmationDialogOverrides
    ) -> APSKPlatformView {
        let isPresented = overrides.isPresented?.boolValue ?? false
        let storage = BoolStorage(initial: isPresented, token: 0)

        let confirmLabel = overrides.confirmLabel ?? "Confirm"
        let cancelLabel = overrides.cancelLabel ?? "Cancel"
        let confirmStyle = overrides.confirmStyle ?? "default"
        let confirmToken = overrides.confirmToken?.uint64Value ?? 0
        let cancelToken = overrides.cancelToken?.uint64Value ?? 0

        var content: AnyView = AnyView(
            Color.clear
                .frame(width: 1, height: 1)
                .confirmationDialog(
                    title,
                    isPresented: storage.binding,
                    titleVisibility: .visible
                ) {
                    Button(
                        role: confirmStyle == "destructive" ? .destructive : nil,
                        action: { CallbackBridge.fire(token: confirmToken, value: 0.0) }
                    ) {
                        Text(confirmLabel)
                    }
                    Button(role: .cancel, action: {
                        CallbackBridge.fire(token: cancelToken, value: 0.0)
                    }) {
                        Text(cancelLabel)
                    }
                } message: {
                    if !message.isEmpty { Text(message) }
                }
        )

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(ConfirmHost(storage: storage, content: content))
    }
}

private struct ConfirmHost<Content: View>: View {
    @ObservedObject var storage: BoolStorage
    let content: Content
    var body: some View { content }
}
