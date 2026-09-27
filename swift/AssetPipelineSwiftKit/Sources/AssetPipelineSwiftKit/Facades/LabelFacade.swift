// LabelFacade — SwiftUI Text(_:) bridge.
//
// Default (empty LabelOverrides): system body font, `.primary` foreground
// (Apple-tracking light/dark), `.leading` alignment, unlimited line wrap.
// Overrides surface only via the ViewOverrides cascade or the
// LabelOverrides knobs (semantic role, alignment, line cap).
//
// Phase 3 Remediation 4: the facade now holds an `APSKLabelState`
// `@ObservedObject` so Crystal-side `text=` mutations propagate to the
// rendered SwiftUI body. The caller (Crystal renderer) writes the state
// pointer back through the `outState` UnsafeMutablePointer so it can later
// dispatch `apsk_label_set_text` to mutate `state.text`.

import SwiftUI
import Foundation
#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

@objc(APSKLabelFacade)
public class LabelFacade: NSObject {
    /// Static-construction entry point retained for back-compat. Renderers
    /// that don't yet need a reactive label path keep calling this and
    /// receive a non-observable label exactly as before Remediation 4.
    @objc public static func makeLabel(
        text: String,
        overrides: LabelOverrides
    ) -> APSKPlatformView {
        return makeReactiveLabel(
            text: text, overrides: overrides, outState: nil
        )
    }

    /// Reactive-construction entry. When `outState` is non-nil the facade
    /// allocates an `APSKLabelState`, retains it with `passRetained`, writes
    /// the opaque pointer through `outState`, and binds the SwiftUI body to
    /// observe `state.text`.
    ///
    /// `outState` is nullable so the legacy non-reactive path can route
    /// through the same implementation without forcing every call-site to
    /// allocate an out-parameter slot.
    @objc public static func makeReactiveLabel(
        text: String,
        overrides: LabelOverrides,
        outState: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
    ) -> APSKPlatformView {
        let state = APSKLabelState(text: text)

        // Hand the +1 retain to Crystal. The state object stays alive
        // until `apsk_state_release` drops the retain (driven by
        // NativeHandle#release! on the Crystal side).
        if let outState = outState {
            outState.pointee = Unmanaged.passRetained(state).toOpaque()
        }

        let body = APSKLabelHost(state: state, overrides: overrides)
        return HostingHelpers.host(body)
    }
}

// Hosted SwiftUI view that observes the label state and rebuilds its
// modifier chain on every published change. The modifier chain is the
// same one the previous static facade applied, lifted into a `var body`
// so SwiftUI can re-evaluate it.
private struct APSKLabelHost: View {
    @ObservedObject var state: APSKLabelState
    let overrides: LabelOverrides

    var body: some View {
        var content: AnyView = AnyView(Text(state.text))

        // Font size + weight. Apply `.font(.system(size:weight:))` when
        // a Crystal-side `UI::Font.size` / `UI::Font.weight` override
        // surfaces. Without this the Crystal `Font` value was silently
        // dropped on the floor and every Label rendered at SwiftUI's
        // body default (~17pt regular), which is why the Phase 6
        // sign-in "Cascade" wordmark looked identical in weight and
        // size to the subtitle below it. The weight rawValue mapping
        // mirrors ButtonOverrides' convention.
        if let fam = overrides.fontFamily, fam != "system", !fam.isEmpty {
            // Custom registered font (e.g. "Alegreya-Medium"). Use the
            // PostScript name for an exact weight/face. Size: the explicit
            // fontSize, else SwiftUI body default (~17).
            let sz = (overrides.fontSize?.doubleValue).flatMap { $0 > 0 ? $0 : nil } ?? 17.0
            if fam == "monospace" {
                content = AnyView(content.font(.system(size: CGFloat(sz), weight: .regular, design: .monospaced)))
            } else {
                content = AnyView(content.font(.custom(fam, size: CGFloat(sz))))
            }
        } else if let sz = overrides.fontSize, sz.doubleValue > 0 {
            let weight: Font.Weight
            if let w = overrides.fontWeight {
                weight = Font.Weight(rawValue: w.intValue) ?? .regular
            } else {
                weight = .regular
            }
            content = AnyView(content.font(.system(size: CGFloat(sz.doubleValue), weight: weight)))
        } else if let w = overrides.fontWeight {
            // No explicit size but explicit weight — keep the body
            // font and just override the weight via `.fontWeight()`.
            let weight = Font.Weight(rawValue: w.intValue) ?? .regular
            content = AnyView(content.fontWeight(weight))
        }

        switch overrides.labelRole {
        case "primary":
            content = AnyView(content.foregroundStyle(.primary))
        case "secondary":
            content = AnyView(content.foregroundStyle(.secondary))
        case "tertiary":
            content = AnyView(content.foregroundStyle(.tertiary))
        case "quaternary":
            content = AnyView(content.foregroundStyle(.quaternary))
        default:
            break
        }

        switch overrides.textAlignment {
        case "leading":  content = AnyView(content.multilineTextAlignment(.leading))
        case "center":   content = AnyView(content.multilineTextAlignment(.center))
        case "trailing": content = AnyView(content.multilineTextAlignment(.trailing))
        default: break
        }

        if let n = overrides.numberOfLines, n.intValue > 0 {
            content = AnyView(content.lineLimit(n.intValue))
        }

        // Phase 6.11 — strikethrough modifier. Applied last among the
        // text-shaping modifiers so it observes the resolved font + color.
        if let st = overrides.strikethrough, st.boolValue {
            content = AnyView(content.strikethrough(true))
        }

        // fill_horizontal: the renderer pins the hosting view wide; without a
        // maxWidth frame the SwiftUI Text centers in it (a full-width title or
        // subtitle rendered centered instead of leading). Fill the width and
        // position the text per textAlignment — default leading.
        //
        // `.fixedSize(horizontal: false, vertical: true)` is the key for WRAPPING:
        // the NSHostingView computes its intrinsic height at the Text's one-line
        // ideal width BEFORE the equal-width constraint pins it wider, so a long
        // subtitle truncated to a single line. fixedSize(vertical:) forces the
        // Text to take its natural multi-line height for the proposed width, so it
        // wraps and grows instead of truncating. Harmless on single-line labels.
        if overrides.fillHorizontal?.boolValue == true || overrides.preferredMaxLayoutWidth != nil {
            let frameAlign: Alignment
            switch overrides.textAlignment {
            case "center":   frameAlign = .center
            case "trailing": frameAlign = .trailing
            default:         frameAlign = .leading
            }
            if let pmlw = overrides.preferredMaxLayoutWidth {
                // Explicit width → SwiftUI computes the correct WRAPPED height at
                // this width, so the NSHostingView reports multi-line height to
                // the NSStackView and the next stacked element no longer overlaps
                // a wrapped label. (A bare `.frame(maxWidth:.infinity)` reports the
                // single-line ideal height at fitting-size time — the root of the
                // long-standing fill-label-height under-reservation bug.) Takes
                // precedence over fillHorizontal.
                content = AnyView(
                    content
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: CGFloat(pmlw.doubleValue), alignment: frameAlign)
                )
            } else {
                content = AnyView(
                    content
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: frameAlign)
                )
            }
        }

#if os(iOS)
        // Keep the original Text as the layout and visible-pixel source. The
        // transparent UITextView accepts selection gestures without adding
        // text insets or changing the Label's measured frame.
        if overrides.selectable?.boolValue == true {
            let visibleContent = CommonModifiers.apply(content, overrides: overrides)
            let selectionControl = APSKSelectableLabelTextView(state: state, overrides: overrides)
                .padding(.top, CGFloat(overrides.paddingTop?.doubleValue ?? 0))
                .padding(.leading, CGFloat(overrides.paddingLeading?.doubleValue ?? 0))
                .padding(.bottom, CGFloat(overrides.paddingBottom?.doubleValue ?? 0))
                .padding(.trailing, CGFloat(overrides.paddingTrailing?.doubleValue ?? 0))
                .accessibilityHidden(true)
            return AnyView(visibleContent.overlay(selectionControl))
        }
#endif

#if os(macOS)
        // Keep the original Text as the layout and visible-pixel source. The
        // transparent NSTextField sits over it, so AppKit selection cannot
        // change the label's measured frame or rendering.
        if overrides.selectable?.boolValue == true {
            let visibleContent = CommonModifiers.apply(content, overrides: overrides)
            let selectionControl = APSKSelectableLabelTextField(state: state, overrides: overrides)
                .padding(.top, CGFloat(overrides.paddingTop?.doubleValue ?? 0))
                .padding(.leading, CGFloat(overrides.paddingLeading?.doubleValue ?? 0))
                .padding(.bottom, CGFloat(overrides.paddingBottom?.doubleValue ?? 0))
                .padding(.trailing, CGFloat(overrides.paddingTrailing?.doubleValue ?? 0))
                .accessibilityHidden(true)
            return AnyView(visibleContent.overlay(selectionControl))
        }
        #endif

        content = CommonModifiers.apply(content, overrides: overrides)
        return content
    }
}

#if os(macOS)
private struct APSKSelectableLabelTextField: NSViewRepresentable {
    let state: APSKLabelState
    let overrides: LabelOverrides

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(string: state.text)
        configure(textField)
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        textField.stringValue = state.text
        configure(textField)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextField, context: Context) -> CGSize? {
        if let width = proposal.width {
            nsView.preferredMaxLayoutWidth = CGFloat(width)
        }
        return nsView.fittingSize
    }

    private func configure(_ textField: NSTextField) {
        let maximumNumberOfLines = overrides.numberOfLines?.intValue ?? 0
        textField.isEditable = false
        textField.isSelectable = true
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.backgroundColor = .clear
        textField.textColor = .clear
        textField.focusRingType = .none
        textField.alignment = textAlignment
        textField.font = labelFont
        textField.maximumNumberOfLines = maximumNumberOfLines
        textField.preferredMaxLayoutWidth = CGFloat(overrides.preferredMaxLayoutWidth?.doubleValue ?? 0)
        textField.cell?.wraps = maximumNumberOfLines != 1
        textField.cell?.usesSingleLineMode = maximumNumberOfLines == 1
        textField.cell?.lineBreakMode = maximumNumberOfLines > 0
            ? .byTruncatingTail
            : .byWordWrapping
    }

    private var labelFont: NSFont {
        let size = CGFloat(overrides.fontSize?.doubleValue ?? NSFont.systemFontSize)
        if let family = overrides.fontFamily, family != "system", !family.isEmpty,
           let customFont = NSFont(name: family, size: size) {
            return customFont
        }
        return NSFont.systemFont(ofSize: size, weight: fontWeight)
    }

    private var fontWeight: NSFont.Weight {
        switch overrides.fontWeight?.intValue ?? 0 {
        case -3: return .ultraLight
        case -2: return .thin
        case -1: return .light
        case 1: return .medium
        case 2: return .semibold
        case 3: return .bold
        case 4: return .heavy
        case 5: return .black
        default: return .regular
        }
    }

    private var textAlignment: NSTextAlignment {
        switch overrides.textAlignment {
        case "center": return .center
        case "trailing": return .right
        default: return .natural
        }
    }
}
#endif

#if os(iOS)
private struct APSKSelectableLabelTextView: UIViewRepresentable {
    let state: APSKLabelState
    let overrides: LabelOverrides

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        configure(textView)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        configure(textView)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    private func configure(_ textView: UITextView) {
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.contentInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.adjustsFontForContentSizeCategory = true
        textView.font = labelFont
        textView.textColor = .clear
        textView.textAlignment = textAlignment
        textView.textContainer.maximumNumberOfLines = overrides.numberOfLines?.intValue ?? 0
        textView.textContainer.lineBreakMode = (overrides.numberOfLines?.intValue ?? 0) > 0
            ? .byTruncatingTail
            : .byWordWrapping

        if overrides.strikethrough?.boolValue == true {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: labelFont,
                .foregroundColor: UIColor.clear,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            ]
            textView.attributedText = NSAttributedString(string: state.text, attributes: attributes)
        } else {
            textView.text = state.text
        }
    }

    private var labelFont: UIFont {
        let preferred = UIFont.preferredFont(forTextStyle: .body)
        let size = CGFloat(overrides.fontSize?.doubleValue ?? Double(preferred.pointSize))
        if let family = overrides.fontFamily, family != "system", !family.isEmpty,
           let customFont = UIFont(name: family, size: size) {
            return customFont
        }
        return UIFont.systemFont(ofSize: size, weight: fontWeight)
    }

    private var fontWeight: UIFont.Weight {
        switch overrides.fontWeight?.intValue ?? 0 {
        case -3: return .ultraLight
        case -2: return .thin
        case -1: return .light
        case 1: return .medium
        case 2: return .semibold
        case 3: return .bold
        case 4: return .heavy
        case 5: return .black
        default: return .regular
        }
    }

    private var textAlignment: NSTextAlignment {
        switch overrides.textAlignment {
        case "center": return .center
        case "trailing": return .right
        default: return .natural
        }
    }
}
#endif

// Local `Font.Weight` rawValue init. Matches the convention used by
// ButtonFacade.swift so Crystal's `populate_label` and `populate_button`
// can emit the same integer rawValues for the same Crystal weight
// Symbols.
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
