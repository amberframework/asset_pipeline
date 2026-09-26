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

// watchOS: ENABLED (Phase D Bucket-2 P0 port, 2026-06-02). The control body
// (`PromptOverlayField` → `TextField`/`SecureField` + a contrast overlay) is pure
// SwiftUI and valid on watchOS. The only watch-incompatible bits are gated below:
// `.textFieldStyle(.roundedBorder)` (RoundedBorderTextFieldStyle is
// `@available(watchOS, unavailable)` — watch uses its native field chrome) and the
// UIKit `keyboardType` mapping (watch text entry is dictation/Scribble). See
// watch-facade-bucket-audit.md.
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
        // Optional brand placeholder tint (Crystal `placeholder_color`). nil
        // keeps the contrast-safe default inside PromptOverlayField.
        let phColor: Color? = overrides.placeholderColor.map {
            #if canImport(UIKit)
            return Color(uiColor: $0)
            #else
            return Color(nsColor: $0)
            #endif
        }
        let base: AnyView = AnyView(
            PromptOverlayField(
                storage: storage,
                placeholder: placeholder,
                isSecure: secure,
                placeholderColor: phColor
            )
        )

        var content: AnyView = base

        // Custom font cascade (mirrors LabelFacade / ButtonFacade): custom
        // registered family → system size(+weight) → weight-only. Applied to the
        // field content so both the input text and the placeholder overlay share
        // the face. Without this a Crystal-side `text_field.font = Font.new(...)`
        // was dropped and every field rendered at the SwiftUI body default.
        if let fam = overrides.fontFamily, fam != "system", !fam.isEmpty {
            let sz = (overrides.fontSize?.doubleValue).flatMap { $0 > 0 ? $0 : nil } ?? 17.0
            content = AnyView(content.font(.custom(fam, size: CGFloat(sz))))
        } else if let sz = overrides.fontSize, sz.doubleValue > 0 {
            let weight = (overrides.fontWeight.flatMap { Font.Weight(rawValue: $0.intValue) }) ?? .regular
            content = AnyView(content.font(.system(size: CGFloat(sz.doubleValue), weight: weight)))
        } else if let w = overrides.fontWeight {
            content = AnyView(content.fontWeight(Font.Weight(rawValue: w.intValue) ?? .regular))
        }

        // Beauty-by-default: apply `.textFieldStyle(.roundedBorder)` so the
        // field has visible chrome (rounded border + padding) on every
        // platform. SwiftUI's iOS default is a plain TextField with no
        // border — fine inside a Form, but not on a stand-alone sign-in
        // surface where the user expects a recognisable field. Macros
        // and per-widget style overrides will land in a follow-up.
        //
        // Chrome. "underline" = bottom-rule only (Expo onboarding inputs): a
        // plain field with a 1px #bec2c2 rule along the bottom and a transparent
        // fill, so it reads as an underlined input over a photo. "plain" = no
        // chrome. Default = the boxed `.roundedBorder` field.
        switch overrides.borderStyle {
        case "underline":
            #if !os(watchOS)
            content = AnyView(content.textFieldStyle(.plain))
            #endif
            content = AnyView(
                content.overlay(alignment: .bottom) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color(
                            red: 190.0 / 255.0, green: 194.0 / 255.0, blue: 194.0 / 255.0))
                }
            )
        case "plain":
            #if !os(watchOS)
            content = AnyView(content.textFieldStyle(.plain))
            #endif
        default:
            // watchOS: `.roundedBorder` (RoundedBorderTextFieldStyle) is
            // unavailable; the watch styles a TextField through its row/Form
            // container, so leave the default style there.
            #if !os(watchOS)
            content = AnyView(content.textFieldStyle(.roundedBorder))
            #endif
        }

        // Enter-to-send: when the consumer set on_submit (submitToken), attach
        // `.onSubmit` so bare Return fires the string-valued trampoline with the
        // current text. Mirrors SearchField's on_submit. (Shift+Return newline is
        // a multi-line-composer / TextArea concern and is not implied here — a
        // single-line TextField submits on Return.)
        if let st = overrides.submitToken, st.uint64Value != 0 {
            let submitToken = st.uint64Value
            content = AnyView(content.onSubmit {
                CallbackBridge.fireString(token: submitToken, value: storage.text)
            })
        }

        #if canImport(UIKit) && !os(watchOS)
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
    // nil = the kit's contrast-safe default (`Color.primary @ 50%`). When the
    // consumer sets `text_field.placeholder_color`, the facade threads it here
    // so a brand placeholder renders literally. `var … = nil` keeps the
    // synthesized memberwise init backward-compatible for the SecureFieldFacade
    // call site, which doesn't pass a colour.
    var placeholderColor: Color? = nil

    var body: some View {
        // Width floor: an EMPTY SwiftUI TextField/SecureField has ~0 ideal width,
        // and the visible placeholder is a non-sizing layer (it was an `.overlay`),
        // so inside a non-stretching container (e.g. a VStack form) a placeholder-
        // only field collapsed to a tiny sliver. A hidden, layout-only copy of the
        // placeholder reserves at least its width, and the field fills that width.
        // (Surfaced by Happy Coach's "negative thoughts" screen — placeholder-only
        // fields rendered as unusable slivers.)
        ZStack(alignment: .leading) {
            Text(placeholder)
                .fixedSize(horizontal: true, vertical: false)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Group {
                if isSecure {
                    SecureField("", text: storage.binding)
                } else {
                    TextField("", text: storage.binding)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if storage.text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(placeholderColor ?? Color.primary.opacity(0.5))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

// Local `Font.Weight` rawValue init — matches the convention in LabelFacade /
// ButtonFacade so Crystal's populators can emit the same integer rawValues
// (regular = 0, medium = 1, semibold = 2, bold = 3, …) for the same weight.
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
