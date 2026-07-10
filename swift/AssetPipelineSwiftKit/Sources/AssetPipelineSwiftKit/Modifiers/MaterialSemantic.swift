// MaterialSemantic — Phase 5 v2 cross-facade helper.
//
// Resolves the Crystal-side AppleSemantic key (lowercase snake_case from
// `UI::DesignTokens::AppleSemantic#to_key`) into:
//
//   * A SwiftUI Material value for the per-widget modifier dispatch
//     (`.background(Material)`, `.presentationBackground(Material)`,
//     `.toolbarBackground(Material, for:)`).
//   * A boolean predicate `shouldSkipModifier` indicating that the caller
//     should emit NO material modifier (the `SystemResolved` sentinel —
//     used for widgets whose chrome is system-drawn).
//
// The approximation table from the v2 architecture doc:
//
//   menu              → .ultraThinMaterial
//   popover           → .regularMaterial
//   sidebar           → .regularMaterial   (SwiftUI has no first-class
//                                            sidebar Material; .regular is
//                                            the closest analogue)
//   sheet             → .thickMaterial
//   header_view       → .bar
//   window_background → .regularMaterial
//   hud_window        → .bar               (HUD chrome ≈ chrome-tinted bar)
//   titlebar          → .bar
//   system_resolved   → SKIP (no modifier)
//
// Used by NavigationSplitViewFacade / SheetFacade / PopoverFacade for
// `.background()` / `.presentationBackground()` dispatch, and by
// TabViewFacade / ToolbarFacade which pass the SwiftUI `.bar` Material to
// `.toolbarBackground(_:for:)`.
//
// Per the brief.yml A1 spike: SwiftUI Material on iOS 16.4+ / macOS 13.3+
// exposes all the cases used here. The `.glassEffect()` Liquid Glass path
// for iOS 26+ / macOS 26+ is handled inside each facade via its own
// `#available` guard — it is system-resolved and AppleSemantic only
// advisory on that path.

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
public enum MaterialSemanticResolver {
    /// True when the given Crystal-side key means "let Apple defaults
    /// apply" (no material modifier should be emitted by the facade).
    public static func shouldSkipModifier(_ key: String?) -> Bool {
        guard let k = key?.lowercased() else { return true }
        return k == "system_resolved" || k == "systemresolved" || k.isEmpty
    }

    /// SwiftUI Material lookup. Returns nil for `system_resolved` /
    /// nil / unknown keys — callers should check `shouldSkipModifier`
    /// first when nil should mean "no modifier", or treat nil as
    /// "platform default" when calling the modifier is unconditional.
    @available(iOS 15.0, macOS 12.0, *)
    public static func material(for key: String?) -> Material? {
        guard let k = key?.lowercased() else { return nil }
        switch k {
        case "menu":
            return .ultraThinMaterial
        case "popover":
            return .regularMaterial
        case "sidebar":
            return .regularMaterial
        case "sheet":
            return .thickMaterial
        case "header_view", "headerview":
            return .bar
        case "window_background", "windowbackground":
            return .regularMaterial
        case "hud_window", "hudwindow":
            return .bar
        case "titlebar":
            return .bar
        case "system_resolved", "systemresolved":
            return nil
        default:
            return nil
        }
    }
}
