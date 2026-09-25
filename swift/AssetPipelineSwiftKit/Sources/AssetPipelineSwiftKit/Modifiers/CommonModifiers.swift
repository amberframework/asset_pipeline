// CommonModifiers — the helper every facade calls at the end of its
// pipeline to apply the `ViewOverrides` fields conditionally. A `nil`
// field means the developer left the Crystal property at its type
// default; the corresponding modifier is skipped so SwiftUI's own
// default treatment shows through.
//
// Modifier ordering is deliberate (see implementation.md §5.4):
//   1. background (color)
//   2. foreground (color / style)
//   3. cornerRadius / clip
//   4. padding (insets)
//   5. border overlay
//   6. shadow
//   7. opacity
//   8. hidden
//   9. frame (min/max width/height)
//   10. accessibility identifier
//   11. accessibility label
//
// Each step wraps the prior `AnyView` so the cascade stays composable.

import SwiftUI

enum CommonModifiers {
    static func apply<V: View>(_ view: V, overrides: ViewOverrides) -> AnyView {
        var current = AnyView(view)
        let hasSurfaceFill = SurfaceCraftModifiers.hasSurfaceFill(overrides.apskSurfaceCraftSpec)

        if let bg = overrides.backgroundColor, !hasSurfaceFill {
            current = AnyView(current.background(swiftColor(bg)))
        }
        if let fg = overrides.foregroundColor {
            current = AnyView(current.foregroundStyle(swiftColor(fg)))
        }
        if let r = overrides.cornerRadius {
            current = AnyView(current.clipShape(
                RoundedRectangle(cornerRadius: CGFloat(r.doubleValue))
            ))
        }
        if overrides.paddingTop != nil || overrides.paddingLeading != nil
            || overrides.paddingBottom != nil || overrides.paddingTrailing != nil {
            let insets = EdgeInsets(
                top: overrides.paddingTop.map { CGFloat($0.doubleValue) } ?? 0,
                leading: overrides.paddingLeading.map { CGFloat($0.doubleValue) } ?? 0,
                bottom: overrides.paddingBottom.map { CGFloat($0.doubleValue) } ?? 0,
                trailing: overrides.paddingTrailing.map { CGFloat($0.doubleValue) } ?? 0
            )
            current = AnyView(current.padding(insets))
        }
        if let bw = overrides.borderWidth, let bc = overrides.borderColor {
            current = AnyView(current.overlay(
                RoundedRectangle(cornerRadius: CGFloat(overrides.cornerRadius?.doubleValue ?? 0))
                    .stroke(swiftColor(bc), lineWidth: CGFloat(bw.doubleValue))
            ))
        }
        if let sr = overrides.shadowRadius {
            let sc = overrides.shadowColor.map { swiftColor($0) } ?? Color.black.opacity(0.25)
            let sx = overrides.shadowOffsetX.map { CGFloat($0.doubleValue) } ?? 0
            let sy = overrides.shadowOffsetY.map { CGFloat($0.doubleValue) } ?? 0
            current = AnyView(current.shadow(color: sc, radius: CGFloat(sr.doubleValue), x: sx, y: sy))
        }
        if let o = overrides.opacity {
            current = AnyView(current.opacity(o.doubleValue))
        }
        if let h = overrides.hidden, h.boolValue {
            current = AnyView(current.hidden())
        }
        if overrides.minWidth != nil || overrides.minHeight != nil
            || overrides.maxWidth != nil || overrides.maxHeight != nil {
            // SwiftUI's `frame(minHeight:)` alone does not enlarge the
            // rendered view's size — it only constrains the layout
            // proposal. UIHostingController.sizingOptions reads the
            // rendered size, so `Button {} .frame(minHeight: 44)` still
            // hands UIKit the Button's natural ~25pt body-text height
            // and BX6 / BX9 fail. We need the rendered Button to actually
            // be 44pt tall.
            //
            // Strategy:
            //   - If min == max → exact `frame(height:)` / `frame(width:)`
            //   - If only `minHeight` set → wrap in a `VStack` with the
            //     view centered, then pin the VStack to the minimum
            //     height. This forces a containing frame of at least
            //     `minHeight` tall while preserving the child's intrinsic
            //     width. The accessibility tree still surfaces the inner
            //     control as the addressable element (its accessibility
            //     identifier was applied earlier in the cascade).
            let minW = overrides.minWidth.map { CGFloat($0.doubleValue) }
            let maxW = overrides.maxWidth.map { CGFloat($0.doubleValue) }
            let minH = overrides.minHeight.map { CGFloat($0.doubleValue) }
            let maxH = overrides.maxHeight.map { CGFloat($0.doubleValue) }

            // Height: SwiftUI's `frame(minHeight:)` only resizes the
            // CONTAINER, not the child view. XCUITest reads the inner
            // element's frame, so the inner view must actually be at
            // least minHeight tall. When the developer set only a
            // minimum and no maximum, we treat the minimum as an exact
            // pin (`frame(height: mh)`) so the rendered Button / Toggle
            // / etc. actually grows to that size.
            if let mh = minH, let mxh = maxH, mh == mxh {
                current = AnyView(current.frame(height: mh))
            } else if let mh = minH, maxH == nil {
                // Only minHeight: treat as exact for the touch-target use
                // case. If the caller wants a flexible floor with no
                // ceiling they should set maxHeight = .infinity (or any
                // explicit max) explicitly on the Crystal side.
                current = AnyView(current.frame(height: mh))
            } else if let mh = minH, let mxh = maxH {
                current = AnyView(current.frame(minHeight: mh, maxHeight: mxh))
            } else if let mxh = maxH {
                current = AnyView(current.frame(maxHeight: mxh))
            }

            // Width: same logic.
            if let mw = minW, let mxw = maxW, mw == mxw {
                current = AnyView(current.frame(width: mw))
            } else if let mw = minW, maxW == nil {
                current = AnyView(current.frame(width: mw))
            } else if let mw = minW, let mxw = maxW {
                current = AnyView(current.frame(minWidth: mw, maxWidth: mxw))
            } else if let mxw = maxW {
                current = AnyView(current.frame(maxWidth: mxw))
            }
        }
        if let id = overrides.accessibilityIdentifier {
            current = AnyView(current.accessibilityIdentifier(id))
        }
        if let lbl = overrides.apskAccessibilityLabel {
            current = AnyView(current.accessibilityLabel(Text(lbl)))
        }
        // Phase 10B.2a iter 2 (Codex Finding 1) — five new accessibility
        // metadata slots. Each is applied unconditionally when set;
        // `nil` means "the Crystal author left this at its type default,
        // let SwiftUI's intrinsic accessibility behaviour win."
        if let hint = overrides.apskAccessibilityHint {
            current = AnyView(current.accessibilityHint(Text(hint)))
        }
        if let value = overrides.apskAccessibilityValue {
            current = AnyView(current.accessibilityValue(Text(value)))
        }
        if let traitsBox = overrides.apskAccessibilityTraitsMask {
            let mask = traitsBox.uint64Value
            var traits: AccessibilityTraits = []
            // Bit positions per UIAccessibilityConstants.h (see
            // src/ui/renderers/uikit_renderer.cr uikit_trait_bitmask
            // for the canonical table — these must stay in lockstep).
            if (mask & 0x0001) != 0 { traits.formUnion(.isButton) }
            if (mask & 0x0002) != 0 { traits.formUnion(.isLink) }
            if (mask & 0x0004) != 0 { traits.formUnion(.isSearchField) }
            if (mask & 0x0008) != 0 { traits.formUnion(.isImage) }
            if (mask & 0x0010) != 0 { traits.formUnion(.isSelected) }
            if (mask & 0x0020) != 0 { traits.formUnion(.playsSound) }
            if (mask & 0x0080) != 0 { traits.formUnion(.isStaticText) }
            if (mask & 0x0100) != 0 { traits.formUnion(.isSummaryElement) }
            if (mask & 0x0200) != 0 {
                // SwiftUI represents disabled via .disabled(true), NOT
                // an AccessibilityTraits flag — emit the modifier here
                // so :not_enabled functionally disables the SwiftUI view.
                current = AnyView(current.disabled(true))
            }
            if (mask & 0x0400) != 0 { traits.formUnion(.updatesFrequently) }
            if (mask & 0x0800) != 0 { traits.formUnion(.startsMediaSession) }
            if (mask & 0x1000) != 0 {
                // UIAccessibilityTraitAdjustable has no SwiftUI
                // `AccessibilityTraits` analog (neither `.isAdjustable`
                // nor `.adjustable` exists). SwiftUI exposes adjustable
                // semantics only via `.accessibilityAdjustableAction { ... }`
                // on the view itself — that's a per-callback API, not a
                // trait flag we can fold into a bitmask. The Crystal
                // populator may still emit this bit so the slot stays
                // honestly wired; we deliberately no-op here.
            }
            if (mask & 0x2000) != 0 { traits.formUnion(.allowsDirectInteraction) }
            if (mask & 0x4000) != 0 { traits.formUnion(.causesPageTurn) }
            if (mask & 0x8000) != 0 {
                // `.isTabBar` is iOS 17+ / macOS 14+ only. Deployment
                // targets are iOS 16+ / macOS 14+ (see
                // [[platform_minimums]]), so we must gate per availability.
                if #available(iOS 17, macOS 14, *) {
                    traits.formUnion(.isTabBar)
                }
            }
            if (mask & 0x10000) != 0 { traits.formUnion(.isHeader) }
            if !traits.isEmpty {
                current = AnyView(current.accessibilityAddTraits(traits))
            }
        }
        // Role mapping happens AFTER traits so an explicit role can
        // also seed trait flags via the Crystal-side composition.
        // SwiftUI doesn't expose a generic "role" setter; only specific
        // traits (isButton, isImage, isHeader, ...) exist. The Crystal
        // populator emits the role-bit OR'd into apskAccessibilityTraitsMask
        // already, so this slot is reserved for future per-role
        // dispatch (e.g. headingLevel:) and currently is advisory only.
        // We still log-as-no-op for unknown role strings so the slot is
        // honestly wired even when SwiftUI lacks the analog.
        if let _ = overrides.apskAccessibilityRole {
            // Reserved for future heading-level / image-label specialisation.
            // The trait flag was already applied via the bitmask above.
        }

        // Phase 10B.2b — Custom accessibility actions. The Crystal
        // side surfaces the action names as a comma-joined string.
        // We attach a SwiftUI `.accessibilityAction(named:)` per name
        // whose callback resolves the matching UIAccessibilityCustomAction
        // attached to the underlying UIView (the renderer's ObjC
        // bridge wired those via `apsk_view_add_accessibility_custom_action`).
        // The action closure itself is a no-op at the SwiftUI level;
        // the UIView-level wiring already routes activation to Crystal.
        if let joined = overrides.apskAccessibilityActions, !joined.isEmpty {
            let names = joined.split(separator: ",").map { (s: Substring) -> String in
                // Unescape %2C back to comma.
                String(s).replacingOccurrences(of: "%2C", with: ",")
            }
            for name in names {
                current = AnyView(current.accessibilityAction(named: Text(name)) {
                    // Activation is routed through the underlying UIView
                    // accessibilityCustomActions list (wired in objc_bridge.m).
                    // This closure stays empty so SwiftUI's stub doesn't
                    // duplicate the dispatch.
                })
            }
        }

        // Phase 10B.2b — Keyboard shortcut. SwiftUI's `.keyboardShortcut`
        // takes a `KeyEquivalent` + `EventModifiers`. We map a single-
        // character key directly; named keys (`return`, `escape`, …)
        // map onto SwiftUI's special-key constants when available.
        // watchOS: KeyEquivalent / .keyboardShortcut are unavailable (no hardware
        // keyboard), so the whole block is gated off — a watch app has no key
        // commands to honor.
        #if !os(watchOS)
        if let key = overrides.apskKeyboardShortcutKey, let maskBox = overrides.apskKeyboardShortcutModifiers, !key.isEmpty {
            let mask = maskBox.uint64Value
            var modifiers: EventModifiers = []
            // Bit positions match UIKeyModifierFlags / NSEventModifierFlags.
            if (mask & (1 << 17)) != 0 { modifiers.insert(.shift) }
            if (mask & (1 << 18)) != 0 { modifiers.insert(.control) }
            if (mask & (1 << 19)) != 0 { modifiers.insert(.option) }
            if (mask & (1 << 20)) != 0 { modifiers.insert(.command) }

            let equivalent: KeyEquivalent?
            switch key.lowercased() {
            case "return", "enter": equivalent = .return
            case "escape", "esc": equivalent = .escape
            case "tab": equivalent = .tab
            case "space": equivalent = .space
            case "delete": equivalent = .delete
            case "up": equivalent = .upArrow
            case "down": equivalent = .downArrow
            case "left": equivalent = .leftArrow
            case "right": equivalent = .rightArrow
            default:
                if let first = key.first {
                    equivalent = KeyEquivalent(first)
                } else {
                    equivalent = nil
                }
            }
            if let eq = equivalent {
                current = AnyView(current.keyboardShortcut(eq, modifiers: modifiers))
            }
        }
        #endif

        // Phase 10B.2b — Focus management. SwiftUI requires a
        // `@FocusState` binding to call `.accessibilityFocused`, which
        // we cannot synthesise from outside the facade. We rely on the
        // ObjC-side `ap_view_become_first_responder` helper (called by
        // the AppKit / UIKit renderer's apply_common_properties) to
        // request focus on the resolved native view. The Swift side
        // therefore intentionally does NOT attach a `.focused()`
        // modifier here; the slot is read so the populator's wiring
        // remains symmetric. Future SwiftKit facades that own their
        // own `@FocusState` may consume this property directly.
        if let _ = overrides.apskFocused {
            // No-op at the modifier layer — the UIView-level helper
            // handles focus request.
        }

        #if os(macOS)
        if overrides.apskSurfaceCraftSpec != nil || overrides.apskSurfaceCraftKeycapStyle != nil {
            current = SurfaceCraftModifiers.apply(
                current,
                spec: overrides.apskSurfaceCraftSpec,
                keycapStyle: overrides.apskSurfaceCraftKeycapStyle,
                cornerRadius: overrides.cornerRadius
            )
        }
        #endif

        return current
    }

    /// Cross-platform `Color` constructor. SwiftUI's `Color(uiColor:)` and
    /// `Color(nsColor:)` are platform-specific; we route through a single
    /// helper so facade code stays platform-agnostic.
    @inline(__always)
    private static func swiftColor(_ c: APSKPlatformColor) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: c)
        #else
        return Color(nsColor: c)
        #endif
    }
}
