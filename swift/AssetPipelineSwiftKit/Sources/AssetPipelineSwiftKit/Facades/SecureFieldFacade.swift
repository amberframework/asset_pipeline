// SecureFieldFacade — SwiftUI SecureField bridge.
//
// Mirrors TextFieldFacade but always emits a SecureField so the system
// provides obscured glyphs + password AutoFill out of the box.

import SwiftUI
import Foundation

// watchOS: ENABLED (Phase D Bucket-2 P1 port, 2026-06-02). Mirrors TextField:
// `PromptOverlayField` (declared in TextFieldFacade, watch-enabled) + `SecureField`
// are pure SwiftUI and valid on watchOS. Only `.textFieldStyle(.roundedBorder)`
// (RoundedBorderTextFieldStyle is `@available(watchOS, unavailable)`) is gated for
// non-watch; the watch styles the field through its row/Form chrome. See
// watch-facade-bucket-audit.md.
@objc(APSKSecureFieldFacade)
public class SecureFieldFacade: NSObject {
    @objc public static func makeSecureField(
        placeholder: String,
        initialText: String,
        overrides: SecureFieldOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = TextStorage(initial: initialText, token: actionToken)
        let alignment = swiftUITextFieldAlignment(overrides.textAlignment)
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
        // with an empty placeholder + a logically aligned overlay Text at
        // `Color.primary.opacity(0.5)`. That composites to ~127,127,127
        // on white and ~127,127,127 on black — ~4.6:1 contrast in both
        // appearances, comfortably above WCAG AA's 3:1 floor for UI text.
        // `PromptOverlayField` (declared in TextFieldFacade) owns this
        // pattern; we reuse it here with `isSecure: true` for consistency.
        var content: AnyView = AnyView(
            PromptOverlayField(
                storage: storage,
                placeholder: placeholder,
                isSecure: true,
                textAlignment: alignment
            )
        )
        // Custom font cascade (mirrors TextFieldFacade): custom registered
        // family → system size(+weight) → weight-only. Without this a Crystal-side
        // `secure_field.font = Font.new(...)` was dropped.
        if let fam = overrides.fontFamily, fam != "system", !fam.isEmpty {
            let sz = (overrides.fontSize?.doubleValue).flatMap { $0 > 0 ? $0 : nil } ?? 17.0
            content = AnyView(content.font(.custom(fam, size: CGFloat(sz))))
        } else if let sz = overrides.fontSize, sz.doubleValue > 0 {
            let weight = (overrides.fontWeight.flatMap { Font.Weight(rawValue: $0.intValue) }) ?? .regular
            content = AnyView(content.font(.system(size: CGFloat(sz.doubleValue), weight: weight)))
        } else if let w = overrides.fontWeight {
            content = AnyView(content.fontWeight(Font.Weight(rawValue: w.intValue) ?? .regular))
        }

        // Beauty-by-default border chrome — matches the TextFieldFacade
        // change. Without this, the iOS default plain SecureField renders
        // as a bare strip of placeholder text with no field affordance.
        // watchOS: `.roundedBorder` is unavailable; the watch uses its row/Form
        // chrome, so the style is left at the default there.
        #if !os(watchOS)
        content = AnyView(content.textFieldStyle(.roundedBorder))
        #endif
        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(SecureStorageHost(storage: storage, content: content))
    }
}

private struct SecureStorageHost<Content: View>: View {
    @ObservedObject var storage: TextStorage
    let content: Content
    var body: some View { content }
}

// Local `Font.Weight` rawValue init — matches LabelFacade / TextFieldFacade.
private extension Font.Weight {
    init?(rawValue: Int) {
        switch rawValue {
        case -3: self = .ultraLight
        case -2: self = .thin
        case -1: self = .light
        case 0: self = .regular
        case 1: self = .medium
        case 2: self = .semibold
        case 3: self = .bold
        case 4: self = .heavy
        case 5: self = .black
        default: return nil
        }
    }
}
