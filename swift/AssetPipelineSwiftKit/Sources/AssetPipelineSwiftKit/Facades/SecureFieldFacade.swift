// SecureFieldFacade — SwiftUI SecureField bridge.
//
// Mirrors TextFieldFacade but always emits a SecureField so the system
// provides obscured glyphs + password AutoFill out of the box.

import SwiftUI
import Foundation

@objc(APSKSecureFieldFacade)
public class SecureFieldFacade: NSObject {
    @objc public static func makeSecureField(
        placeholder: String,
        initialText: String,
        overrides: SecureFieldOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = TextStorage(initial: initialText, token: actionToken)
        // Phase 6.11 Iter 4 — Item 2 (placeholder contrast).
        //
        // SwiftUI's bare `SecureField(placeholder, text:)` renders its
        // placeholder with the system `placeholderText` semantic colour
        // (≈ 1.7:1 light / 2.2:1 dark on the white roundedBorder fill).
        // The `prompt:` overload doesn't help — `SecureField` ignores an
        // explicit `Text.foregroundColor` on the prompt and still uses
        // the placeholderText semantic.
        //
        // Solution (shared with TextFieldFacade): render the SecureField
        // with an empty placeholder + a leading-aligned overlay Text at
        // `Color.primary.opacity(0.5)`. That composites to ~127,127,127
        // on white and ~127,127,127 on black — ~4.6:1 contrast in both
        // appearances, comfortably above WCAG AA's 3:1 floor for UI text.
        // `PromptOverlayField` (declared in TextFieldFacade) owns this
        // pattern; we reuse it here with `isSecure: true` for consistency.
        var content: AnyView = AnyView(
            PromptOverlayField(
                storage: storage,
                placeholder: placeholder,
                isSecure: true
            )
        )
        // Beauty-by-default border chrome — matches the TextFieldFacade
        // change. Without this, the iOS default plain SecureField renders
        // as a bare strip of placeholder text with no field affordance.
        content = AnyView(content.textFieldStyle(.roundedBorder))
        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(SecureStorageHost(storage: storage, content: content))
    }
}

private struct SecureStorageHost<Content: View>: View {
    @ObservedObject var storage: TextStorage
    let content: Content
    var body: some View { content }
}
