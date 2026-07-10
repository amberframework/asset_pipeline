// APSKBrandProminentButtonStyle — macOS-only ButtonStyle that paints
// `.borderedProminent`-equivalent chrome using a brand tint.
//
// Why this exists (Phase 6.12C):
//   SwiftUI's `.borderedProminent` button style on macOS uses the
//   *system* accent color exclusively. Setting `.tint(brandColor)` on
//   the button (or in the environment) is silently ignored — the
//   background fill always resolves to the system accent. Confirmed
//   empirically in `docs/initiative-cross-platform-ui/handoff/
//   phase-06.12c-probe-findings.md`.
//
//   iOS does not exhibit this divergence: `.tint(...) +
//   .buttonStyle(.borderedProminent)` correctly recolors the prominent
//   chrome. So the workaround is conditionally compiled `#if os(macOS)`
//   only.
//
// Activation contract (see `ButtonFacade.swift` case "prominent"):
//   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
//     → this style is used.
//   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
//     SYSTEM_ACCENT) → stock `.borderedProminent` is used (system blue
//     / system accent — exactly what the consumer wants).
//   - iOS → stock `.borderedProminent` always (system honors `.tint`).
//
// State coverage:
//   - Pressed: fill darkens to `tint.opacity(0.85)`, overall opacity
//     dims slightly to 0.95.
//   - Disabled: read `@Environment(\.isEnabled)`; overall opacity drops
//     to 0.5 so the button matches SwiftUI's stock disabled treatment.
//   - Focused (keyboard): SwiftUI's system-drawn focus ring still
//     surrounds the Button regardless of ButtonStyle; the style does not
//     need to draw it explicitly.
//   - High-contrast: brand tint × white foreground; consumers with very
//     demanding contrast budgets should override `brand_primary` to a
//     darker primary in their `DesignTokens::Brand` subclass.

#if os(macOS)
import SwiftUI

struct APSKBrandProminentButtonStyle: ButtonStyle {
    let tint: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        // The button's `Label` content is wrapped (in `ButtonFacade`) with
        // `.frame(maxWidth: .infinity)` when the call site asks for a
        // stretched-prominent recipe (min_w == max_w form column). The
        // ButtonStyle itself does NOT pin maxWidth so non-stretched
        // prominent buttons (e.g. inline action chips) keep their
        // intrinsic label width.
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? tint.opacity(0.85) : tint)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.95 : 1.0) : 0.5)
            .contentShape(Capsule())
            .accessibilityAddTraits(.isButton)
    }
}
#endif
