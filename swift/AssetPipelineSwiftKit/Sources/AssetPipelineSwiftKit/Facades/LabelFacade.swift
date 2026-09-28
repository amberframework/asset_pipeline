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

        content = CommonModifiers.apply(content, overrides: overrides)
        if overrides.selectable?.boolValue == true {
            content = AnyView(content.textSelection(.enabled))
        }
        return content
    }
}

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
