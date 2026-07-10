// TextFieldFacade — SwiftUI TextField bridge.
//
// Default: system body font, system focus ring, dark/light adaptive, no
// autocorrect changes. When `secureEntry` override is set, the facade
// emits a `SecureField` instead so password-AutoFill engages.
//
// `actionToken` is invoked with the new text length as the value
// channel (Crystal lifts the actual string back from the on_change
// closure indirectly; the value channel here just carries
// "something changed"). A richer text-bound dispatch is a future hook.

import SwiftUI
import Foundation

@objc(APSKTextFieldFacade)
public class TextFieldFacade: NSObject {
    @objc public static func makeTextField(
        placeholder: String,
        initialText: String,
        overrides: TextFieldOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = TextStorage(initial: initialText, token: actionToken)

        // Phase 6.11 Iter 4 — Item 2 (placeholder contrast).
        //
        // Apple's stock `TextField("Email", text: ...)` initialiser binds
        // the placeholder to the `.placeholderText` semantic color, which
        // on iOS resolves to `label @ 30% alpha`. Composited over the
        // `.roundedBorder` style's white inner fill, that lands at
        // ~1.7:1 contrast in light appearance and ~2.2:1 in dark — both
        // fail WCAG 2.2 AA's 3:1 floor for UI text. Codex 3 measured this
        // empirically on the Phase 6.11 Iter 3 captures.
        //
        // SwiftUI `TextField` and `SecureField` differ in how they apply
        // colour to the `prompt:` Text — `TextField` honours an explicit
        // `foregroundColor` literally (no opacity reduction), while
        // `SecureField` ignores the colour and renders the prompt with
        // the system `placeholderText` semantic (≈ label@30% alpha, which
        // measures ~1.7:1 light / ~2.2:1 dark — failing WCAG AA's 3:1
        // floor for UI text).
        //
        // To get a consistent ≥ 3:1 placeholder across both controls we
        // sidestep the `prompt:` API entirely. `PromptOverlayField` (see
        // below) wraps a TextField / SecureField with an empty SwiftUI
        // placeholder + a leading-aligned overlay Text whose colour we
        // control directly: `label @ 50% opacity`. That composites to
        // ~127,127,127 on white (≈ 4.6:1) and ~127,127,127 on black
        // (≈ 4.6:1) — comfortably above 3:1 in both appearances. The
        // overlay only shows while the bound text is empty, so it
        // behaves like the system placeholder for usability.
        let secure = (overrides.secureEntry?.boolValue ?? false)
        let base: AnyView = AnyView(
            PromptOverlayField(
                storage: storage,
                placeholder: placeholder,
                isSecure: secure
            )
        )

        var content: AnyView = base

        // Beauty-by-default: apply `.textFieldStyle(.roundedBorder)` so the
        // field has visible chrome (rounded border + padding) on every
        // platform. SwiftUI's iOS default is a plain TextField with no
        // border — fine inside a Form, but not on a stand-alone sign-in
        // surface where the user expects a recognisable field. Macros
        // and per-widget style overrides will land in a follow-up.
        content = AnyView(content.textFieldStyle(.roundedBorder))

        #if canImport(UIKit)
        if let kt = overrides.keyboardType {
            switch kt {
            case "email":  content = AnyView(content.keyboardType(.emailAddress))
            case "number": content = AnyView(content.keyboardType(.numberPad))
            case "phone":  content = AnyView(content.keyboardType(.phonePad))
            case "url":    content = AnyView(content.keyboardType(.URL))
            default: break
            }
        }
        #endif

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(StorageHost(storage: storage, content: content))
    }
}

// Per-field state holder. SwiftUI requires the bound state to outlive
// individual layout passes; we keep it on a class object that the
// facade pins via `objc_setAssociatedObject` in HostingHelpers.host.
final class TextStorage: ObservableObject {
    @Published var text: String
    let token: UInt64
    init(initial: String, token: UInt64) {
        self.text = initial
        self.token = token
    }
    var binding: Binding<String> {
        Binding(
            get: { self.text },
            set: { newValue in
                self.text = newValue
                // Phase 6.10 Rem 4 (Item 1) — fire the string-valued
                // trampoline so Crystal's `on_change` closure receives
                // the actual typed text. The numeric `fire(token:value:)`
                // call is retained as a length signal for callers that
                // only need "something changed" — the trampoline is
                // a no-op when no token-1-registered closure exists.
                CallbackBridge.fireString(token: self.token, value: newValue)
                CallbackBridge.fire(token: self.token, value: Double(newValue.count))
            }
        )
    }
}

private struct StorageHost<Content: View>: View {
    @ObservedObject var storage: TextStorage
    let content: Content
    var body: some View { content }
}

// Wraps a SwiftUI TextField / SecureField with a leading-aligned
// overlay Text we control directly, so the visible placeholder reads
// at ≥ 3:1 contrast against the field background in both light and
// dark appearance (the SwiftUI defaults render at ~1.7:1 / ~2.2:1 —
// see TextFieldFacade.makeTextField for the full investigation).
//
// `@ObservedObject var storage` is the reactivity edge that makes the
// overlay disappear as soon as the bound text becomes non-empty.
//
// Module-internal so `SecureFieldFacade` can reuse the same overlay
// recipe (it has its own facade because Crystal-side it's a distinct
// `apsk_make_secure_field` C entry point with a separate overrides
// type, but visually it needs the identical placeholder treatment).
struct PromptOverlayField: View {
    @ObservedObject var storage: TextStorage
    let placeholder: String
    let isSecure: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: storage.binding)
            } else {
                TextField("", text: storage.binding)
            }
        }
        .overlay(alignment: .leading) {
            if storage.text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color.primary.opacity(0.5))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}
