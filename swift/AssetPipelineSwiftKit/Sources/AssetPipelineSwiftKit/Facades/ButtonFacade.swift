// ButtonFacade — the SwiftUI Button bridge.
//
// Call site (Crystal): `LibSwiftKitBridge.make_button(label, overrides, token)`
// → C trampoline `apsk_make_button` → `APSKButtonFacade.makeButton`
//   (this file) → SwiftUI `Button` → `UIHostingController`/`NSHostingController`
// → raw `UIView`/`NSView` pointer handed back to Crystal.
//
// Default (empty `ButtonOverrides`) behavior on iOS 26 / macOS 26:
//   - System tint, system body font, default insets
//   - Built-in hover/press animations
//   - VoiceOver accessibility trait `.button`
//   - Dynamic Type support
//   - Dark / light appearance tracking
//   - Liquid Glass treatment for `.prominent` style on iOS 26+
//
// Phase 3 Remediation 4 (reactive overrides): three properties — background
// color, foreground color, corner radius — are routed through an
// `APSKButtonState` `@ObservedObject` so the Crystal renderer can mutate
// them at runtime (BX5 override-rerender-runtime). Style / role / disabled
// / symbol remain construction-time fixed: they affect Swift type identity
// of the underlying SwiftUI Button and changing them post-compose would
// require a full re-render anyway.

import SwiftUI
import Foundation

@objc(APSKButtonFacade)
public class ButtonFacade: NSObject {

    /// Static-construction entry point retained for back-compat.
    @objc public static func makeButton(
        label: String,
        overrides: ButtonOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        return makeReactiveButton(
            label: label, overrides: overrides,
            actionToken: actionToken, outState: nil
        )
    }

    /// Reactive-construction entry. `outState` receives a +1 retained
    /// pointer to an `APSKButtonState` that Crystal can later mutate via
    /// `apsk_button_set_background_color` etc.
    @objc public static func makeReactiveButton(
        label: String,
        overrides: ButtonOverrides,
        actionToken: UInt64,
        outState: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
    ) -> APSKPlatformView {
        // Seed the reactive state from the construction-time ViewOverrides
        // fields. A nil entry means "leave SwiftUI default in force"; a
        // later Crystal-side mutation toggles the same field on the state.
        let state = APSKButtonState(
            backgroundColor: overrides.backgroundColor,
            foregroundColor: overrides.foregroundColor,
            cornerRadius: overrides.cornerRadius,
            isDisabled: overrides.disabled?.boolValue ?? false
        )

        if let outState = outState {
            outState.pointee = Unmanaged.passRetained(state).toOpaque()
        }

        let body = APSKButtonHost(
            label: label,
            overrides: overrides,
            actionToken: actionToken,
            state: state
        )
        return HostingHelpers.host(body)
    }
}

private struct APSKButtonHost: View {
    let label: String
    let overrides: ButtonOverrides
    let actionToken: UInt64
    @ObservedObject var state: APSKButtonState

    var body: some View {
        let action: () -> Void = { [actionToken] in
            CallbackBridge.fire(token: actionToken, value: 0.0)
        }

        // Construct base view. Destructive role uses the SwiftUI role
        // initializer so the system applies its red emphasis treatment.
        //
        // Phase 6.11 Iter 4: when the call-site asks for a prominent button
        // pinned to a fixed width (min_w == max_w — the standard form-column
        // recipe), build the Button with an explicit label wrapped in a
        // `.frame(maxWidth: .infinity)`. SwiftUI's `.borderedProminent`
        // chrome sizes to the label's intrinsic width by default; pushing
        // the label to expand horizontally is the canonical idiom for a
        // stretched prominent button. The outer width pin (applied via
        // `.frame(width:)` after the style cascade) caps the touch target.
        let wantsStretchedProminent: Bool = {
            guard overrides.style == "prominent" else { return false }
            guard let mw = overrides.minWidth, let mxw = overrides.maxWidth else { return false }
            return mw.doubleValue == mxw.doubleValue
        }()

        var base: AnyView
        if overrides.role == "destructive" {
            if let symbol = overrides.symbolName {
                base = AnyView(
                    Button(role: .destructive, action: action) {
                        Label(label, systemImage: symbol)
                            .frame(maxWidth: wantsStretchedProminent ? .infinity : nil)
                    }
                )
            } else {
                base = AnyView(
                    Button(role: .destructive, action: action) {
                        Text(label)
                            .frame(maxWidth: wantsStretchedProminent ? .infinity : nil)
                    }
                )
            }
        } else if let symbol = overrides.symbolName {
            base = AnyView(
                Button(action: action) {
                    Label(label, systemImage: symbol)
                        .frame(maxWidth: wantsStretchedProminent ? .infinity : nil)
                }
            )
        } else if wantsStretchedProminent {
            base = AnyView(
                Button(action: action) {
                    Text(label).frame(maxWidth: .infinity)
                }
            )
        } else {
            base = AnyView(Button(label, action: action))
        }

        // BX6 / BX9: apply minHeight/minWidth as exact frame() pins
        // on the Button. SwiftUI's body-Button intrinsic is ~25pt; the
        // `.frame(height:)` modifier widens the rendered Button (and
        // its content-shape hit-test rect). Use `.contentShape` to also
        // expand the AX hit rect so XCUITest's `frame.size` reads the
        // touch-target floor rather than the natural body-text rect.
        if let mh = overrides.minHeight {
            let mhCG = CGFloat(mh.doubleValue)
            base = AnyView(
                base.frame(minHeight: mhCG)
                    .contentShape(Rectangle())
            )
        }
        if let mw = overrides.minWidth {
            let mwCG = CGFloat(mw.doubleValue)
            // Phase 6.11 Iter 4: the stretched-prominent recipe pushes the
            // *label* to fill horizontally above; the outer width pin is
            // applied AFTER the style cascade so the touch-target / a11y
            // frame matches. For any other configuration, fall back to
            // `.frame(minWidth:)` here.
            if !wantsStretchedProminent {
                base = AnyView(base.frame(minWidth: mwCG))
            }
        }

        // Style cascade. SwiftUI layers system defaults (font, animation,
        // focus, dynamic type, dark mode) over whatever style we pick.
        //
        // Phase 6 Rem 3-completion fix for the iOS-light "invisible
        // Sign-in button" Codex blocker: `.borderedProminent` does NOT
        // render any chrome on iOS-light when no `.tint(...)` is active
        // in the SwiftUI environment — each Crystal-produced Button is
        // hosted in its own UIHostingController so the host app's
        // SwiftUI `.tint(...)` cascade does not reach it. We force the
        // accent on the Button itself so `.borderedProminent` resolves
        // its fill against the system accent (`accentColor` —
        // appearance-tracking, so this respects light / dark and any
        // explicit accent override in the SwiftUI environment if one
        // happens to be in scope). The `.tint` is only applied for
        // `prominent` and `tinted`: `.bordered` and `.borderless` are
        // already visible without an accent.
        var content: AnyView = base
        switch overrides.style {
        case "prominent":
            // Phase 6.11 Iter 4 — Item 1.
            //
            // The Phase 6.8 Fix 1 brand-teal Capsule hardcode is removed.
            // That workaround was retained while Phase 6.10 Rem 2 was
            // still investigating a SwiftUI Button tap-closure bug at the
            // UIHostingController boundary. Phase 6.10 Path A (VC
            // parenting) closed that bug architecturally, so a prominent
            // button can now resolve through SwiftUI's stock
            // `.borderedProminent` style and surface the system tint
            // (default iOS system blue, or whatever `.tint(...)` happens
            // to cascade into the hosting environment).
            //
            // `.controlSize(.large)` lifts the inner padding to the iOS
            // "large prominent" floor (~50pt tall) so a pinned-width
            // sign-in button reads as a primary action, not a chip.
            //
            // Phase 6.12C — macOS divergence workaround.
            //
            // On macOS, SwiftUI's `.borderedProminent` ignores `.tint()`
            // and always uses the system accent color. iOS does NOT have
            // this divergence. Consumers like Cascade install a brand
            // tint via `APSKRuntime.setBrandTint(...)`, which
            // `HostingHelpers.host(_:)` then applies as `.tint(brand)`
            // on the hosted root — that tint reaches `.bordered` /
            // `.borderless` chrome (Forgot-password link goes teal) but
            // NOT `.borderedProminent` chrome. To restore the brand
            // promise on macOS we paint the prominent chrome from
            // primitives via `APSKBrandProminentButtonStyle` (Capsule +
            // white foreground + pressed/disabled state coverage). The
            // style only activates when:
            //   1. The build target is macOS.
            //   2. A custom brand is installed
            //      (`APSKRuntime.brandTint != nil`).
            // When either condition is false (iOS, or macOS with
            // SYSTEM_ACCENT / `Tokens.default`), the stock
            // `.borderedProminent` chain runs unchanged so Voyager
            // continues to render with the macOS system accent.
            // See `handoff/phase-06.12c-probe-findings.md` for evidence.
            #if os(macOS)
            if let activeTint = APSKRuntime.brandTint {
                content = AnyView(
                    content.buttonStyle(
                        APSKBrandProminentButtonStyle(tint: activeTint)
                    )
                )
            } else {
                content = AnyView(
                    content
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                )
            }
            #else
            content = AnyView(
                content
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
            )
            #endif
            // Re-apply the form-column width after the style so the
            // touch-target / a11y frame matches the surrounding field
            // column. The inner `Text(label).frame(maxWidth: .infinity)`
            // made the *content* stretch within the bordered prominent
            // chrome; this outer pin caps the overall width to the form
            // column.
            if wantsStretchedProminent, let mw = overrides.minWidth {
                let mwCG = CGFloat(mw.doubleValue)
                content = AnyView(content.frame(width: mwCG))
            }
        case "tinted":
            content = AnyView(content
                .tint(.accentColor)
                .buttonStyle(.bordered))
        case "bordered":
            content = AnyView(content.buttonStyle(.bordered))
        case "borderless":
            content = AnyView(content.buttonStyle(.borderless))
        default:
            break
        }

        if overrides.role == "cancel" {
            content = AnyView(content.fontWeight(.semibold))
        }
        // Phase 6.8 Fix 3: map the `:secondary` role from the Crystal facade
        // to SwiftUI's `.bordered` chrome. Used by social-row buttons
        // (Apple / Google / Email) on the demo sign-in screen so they render
        // with an outlined border instead of falling through to default flat
        // text. Applied as a role check (not a style switch case) because
        // `:secondary` arrives via `setRole`, not `setStyle`, in the bridge.
        // Only override when no explicit style was provided so app code that
        // sets a style alongside `:secondary` still wins.
        if overrides.role == "secondary" && overrides.style == nil {
            content = AnyView(content.buttonStyle(.bordered))
        }
        if let weight = overrides.fontWeight {
            let resolved = Font.Weight(rawValue: weight.intValue) ?? .regular
            content = AnyView(content.fontWeight(resolved))
        }
        // Phase 6.11 — reactive disabled. Source of truth is the state
        // object's `isDisabled` (seeded from `overrides.disabled` and
        // mutable through `apsk_button_set_disabled`). Reading the
        // observable property here gives SwiftUI the dependency edge
        // needed to re-render the button when Crystal flips disabled.
        if state.isDisabled {
            content = AnyView(content.disabled(true))
        }

        // ----- Reactive (Remediation 4) override layer ---------------------
        //
        // Apply background / foreground / cornerRadius from the reactive
        // state. These three fields are explicitly NOT applied through
        // `CommonModifiers.apply` below (we shadow them on a per-render
        // override carrier so the static cascade leaves them alone). The
        // state was seeded from the construction-time ViewOverrides
        // equivalents in `makeReactiveButton`, so this stays the single
        // source of truth for those three properties.

        if let bg = state.backgroundColor {
            #if canImport(UIKit)
            content = AnyView(content.background(Color(uiColor: bg)))
            #elseif canImport(AppKit)
            content = AnyView(content.background(Color(nsColor: bg)))
            #endif
        }

        if let fg = state.foregroundColor {
            #if canImport(UIKit)
            content = AnyView(content.foregroundStyle(Color(uiColor: fg)))
            #elseif canImport(AppKit)
            content = AnyView(content.foregroundStyle(Color(nsColor: fg)))
            #endif
        }

        if let cr = state.cornerRadius {
            content = AnyView(
                content.clipShape(RoundedRectangle(cornerRadius: CGFloat(cr.doubleValue)))
            )
        }

        // Apply common (View-level) overrides last, excluding the three
        // reactive fields that the state layer above already handled.
        // We shadow them on a copy of the overrides so CommonModifiers
        // does not re-apply (which would either double-stack the
        // background / foreground or use a stale value after a runtime
        // mutation).
        let shadowed = ButtonOverrides()
        copyViewOverrides(from: overrides, to: shadowed, skipReactiveFields: true)
        // BX6 / BX9: the inner `.frame(height: minHeight)` already pinned
        // the rendered Button to the touch-target floor above; null these
        // out on the shadowed overrides so CommonModifiers does not apply
        // a second outer frame that would double-stack.
        shadowed.minHeight = nil
        shadowed.minWidth = nil
        shadowed.fontWeight = overrides.fontWeight
        shadowed.role = overrides.role
        shadowed.style = overrides.style
        shadowed.disabled = overrides.disabled
        shadowed.symbolName = overrides.symbolName
        content = CommonModifiers.apply(content, overrides: shadowed)
        return content
    }
}

/// Copy every `ViewOverrides` field from `src` to `dst`. When
/// `skipReactiveFields` is true, the three fields the reactive state
/// layer owns (`backgroundColor`, `foregroundColor`, `cornerRadius`)
/// are left at nil on `dst` so `CommonModifiers.apply` no-ops on them.
private func copyViewOverrides(
    from src: ViewOverrides,
    to dst: ViewOverrides,
    skipReactiveFields: Bool
) {
    if !skipReactiveFields {
        dst.backgroundColor = src.backgroundColor
        dst.foregroundColor = src.foregroundColor
        dst.cornerRadius = src.cornerRadius
    }
    dst.paddingTop = src.paddingTop
    dst.paddingLeading = src.paddingLeading
    dst.paddingBottom = src.paddingBottom
    dst.paddingTrailing = src.paddingTrailing
    dst.borderWidth = src.borderWidth
    dst.borderColor = src.borderColor
    dst.shadowRadius = src.shadowRadius
    dst.shadowColor = src.shadowColor
    dst.shadowOffsetX = src.shadowOffsetX
    dst.shadowOffsetY = src.shadowOffsetY
    dst.opacity = src.opacity
    dst.hidden = src.hidden
    dst.minWidth = src.minWidth
    dst.minHeight = src.minHeight
    dst.maxWidth = src.maxWidth
    dst.maxHeight = src.maxHeight
    dst.accessibilityIdentifier = src.accessibilityIdentifier
    dst.apskAccessibilityLabel = src.apskAccessibilityLabel
}

// SwiftUI's `Font.Weight` initializer below is a small extension that
// lets us reconstruct a weight from the `NSNumber` int rawValue Crystal
// passes through. The values match SwiftUI's `Font.Weight` static cases.
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
