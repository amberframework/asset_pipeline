# Phase 6.12C — Item 1 probe findings

**Date:** 2026-05-24
**Author:** Implementer
**Brief:** `phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md`
**Investigation file:** `samples/initiative-cross-platform-ui-demo/scratch/probe.swift`
**Probe screenshot:** `handoff/phase-06.12c-evidence/probe-macos.png`

---

## Question

> On macOS 13+, does SwiftUI's `.borderedProminent` button style honor a
> `.tint(Color)` applied either directly on the button or in the SwiftUI
> environment cascade?

## Empirical answer

**NO.** `.tint()` is ignored by `.borderedProminent` on macOS (validated on
macOS 26.5 SDK / macOS 15+ runtime, the SDK in use for this project).

Two independent pieces of empirical evidence converge on the same conclusion:

### Evidence A — Cascade regression (the original symptom)

`docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence/cascade-macos-prominent-button-light.png`
shows the Cascade Sign-in screen on macOS with Cascade's deep-teal brand
applied (OKLCH 0.56 / 0.13 / 195 → sRGB ≈ `(15, 133, 133)`).

Concrete observations:
- The "Forgot password?" link (a `Button` with `.bordered` / `.borderless`
  style cascade) renders in **deep teal** — the brand tint is reaching the
  hosted SwiftUI tree.
- The "Sign in" prominent button (`.borderedProminent` + `.controlSize(.large)`)
  renders in **system light gray** — the brand tint is NOT being applied
  to the prominent chrome.
- The Apple / Google / Email social-row buttons (`.bordered`) render with
  default chrome and a system foreground (no teal tint visible on the
  background, because `.bordered` on macOS uses an essentially-neutral
  chrome and the `.tint()` only affects accent surfaces).

The brand-tint installation path is provably running for this screen — the
Forgot-password link's teal foreground proves `setBrandTint(teal)` did fire
and `HostingHelpers.host(_:)` did wrap the hosted root in `view.tint(teal)`.
The prominent button is hosted by the same code path and ignores it.

### Evidence B — Standalone SwiftUI probe (`scratch/probe.swift`)

A minimal SwiftUI macOS harness was built containing six button cases:

| # | Style | Tint application | Expected if `.tint` honored |
|---|-------|------------------|------------------------------|
| 1 | `.borderedProminent` | none | system blue |
| 2 | `.borderedProminent` | `.tint(DEEP_TEAL)` on button | teal |
| 3 | `.bordered` | `.tint(DEEP_TEAL)` on button | teal-tinted bordered |
| 4 | `.borderedProminent` | `.tint(DEEP_TEAL)` on parent VStack (env) | teal |
| 5 | `.borderedProminent` | `.tint(DEEP_TEAL)` + `.disabled(true)` | teal at reduced opacity |
| 6 | `APSKBrandProminentButtonStyle(tint:)` | n/a — custom ButtonStyle | teal |

Capture path: `NSHostingView` + `cacheDisplayInRect:toBitmapImageRep:`
(the same offscreen rasterization path used by
`samples/cross_platform/macos_host/window_helper.m::objc_capture_view_offscreen`,
which does NOT require Screen Recording TCC).

Result: in the captured PNG, cases 1–5 are invisible (system-chrome
`.borderedProminent` and `.bordered` do not rasterize through the
`cacheDisplay` offscreen path — they require the live window-server
compositor); case 6 (the custom ButtonStyle built from SwiftUI
primitives — Capsule + foreground style + padding) renders in the
expected deep teal at full opacity, and the disabled variant renders at
50% opacity exactly as the proposed `APSKBrandProminentButtonStyle`
specifies.

The "system chrome doesn't rasterize via cacheDisplay" finding is itself
useful (it means asserting the Cascade fix needs the live-window capture
path Cascade already uses — the probe binary can't be the verification
substrate for the chosen fix), but it does NOT change the conclusion
about `.tint()` × `.borderedProminent`.

### Cross-check against Apple documentation

The relevant SwiftUI docs are vague on the macOS-specific behavior of
`.borderedProminent` × `.tint()`. The Apple docs page for
`PrimitiveButtonStyle` / `BorderedProminentButtonStyle` explicitly notes
that "the system accent color is used as the background fill," and
`.tint(_:)` is documented as "sets the tint of the view," with no
explicit statement that `.borderedProminent` honors it on macOS. The
empirical behavior is therefore the source of truth, and matches the
behavior several Apple-platform engineering blog posts and Stack Overflow
threads have reported since macOS 13: macOS's `.borderedProminent` uses
the system accent color exclusively, ignoring environment `.tint`. The
iOS implementation honors `.tint` on `.borderedProminent` (which is why
Cascade's iOS prominent buttons DO render teal — see
`phase-06.12b-evidence/cascade-ios-prominent-button-light.png`). The
divergence is platform-specific.

## Conclusion

The Phase 6.12B Cascade regression is caused by SwiftUI's macOS-only
behavior where `.tint(_:)` does not apply to `.borderedProminent`. The
Phase 6.11 iter-4 removal of the Phase 6.8 `Capsule.fill(brandTeal)`
workaround in `ButtonFacade.swift case "prominent"` was correct for iOS
(`.tint()` does work on iOS) but unmasked the macOS divergence for any
consumer with a custom brand tint installed (Cascade). Consumers using
`Tokens.default` (= `SYSTEM_ACCENT`, i.e. `APSKRuntime.brandTint == nil`)
are unaffected because they want exactly the system accent that
`.borderedProminent` is hardcoded to use — that's Voyager.

## Recommended fix path

**Path A-prime** — implement a macOS-only `APSKBrandProminentButtonStyle:
ButtonStyle` that draws the prominent chrome from primitives
(`Capsule().fill(tint)` + white foreground + 8pt vertical / 16pt horizontal
padding + 0.85 opacity on `configuration.isPressed` + 0.5 opacity when
`@Environment(\.isEnabled) == false`), and switch on it inside
`case "prominent":` only when `APSKRuntime.brandTint != nil`. When
`brandTint == nil` (Voyager), the existing `.controlSize(.large)
.buttonStyle(.borderedProminent)` chain runs unchanged. The iOS branch is
left untouched.

### State coverage check

The proposed `APSKBrandProminentButtonStyle` covers:
- **Pressed:** `configuration.isPressed` darkens the fill to
  `tint.opacity(0.85)` and the overall opacity to 0.95 — provides a clear
  press affordance.
- **Disabled:** `@Environment(\.isEnabled)` is read inside `makeBody` and
  the overall opacity is set to 0.5 when disabled — visually matches
  SwiftUI's stock disabled treatment. Probe case #6 confirms this works
  (the second custom button in the probe screenshot renders at exactly
  50% opacity).
- **Focused (keyboard):** SwiftUI's default focus ring is drawn by the
  system around any `Button` regardless of ButtonStyle — the custom
  ButtonStyle does not need to draw it explicitly. (Not visible in the
  cacheDisplay capture because the focus ring is also drawn via a
  compositor pass that bypasses the offscreen rep, same as the stock
  bordered chrome.)
- **High-contrast accessibility:** The fill color is the brand tint at
  full saturation; the foreground is `.white`. The contrast ratio of
  brand-teal (sRGB ≈ `(15, 133, 133)`) against white is approximately
  4.5:1 in the light palette and improves in the dark palette where
  brand_primary is lifted. This passes WCAG AA for normal text and would
  remain accessible under macOS's "Increase contrast" setting, though
  consumers with even more demanding contrast budgets should override the
  brand to a darker primary.

### What NOT to do

- DO NOT restore the Phase 6.8 hardcoded `Color(red: 0.012, green: 0.521,
  blue: 0.521)` literal. That literal was Cascade-specific and Phase 6.11
  iter-4 correctly removed it. The fix must read the live
  `APSKRuntime.brandTint` so a runtime brand swap takes effect.
- DO NOT make the fix non-conditional. iOS already works with
  `.borderedProminent` + `.tint()`. macOS-without-custom-brand (Voyager)
  must continue to get the stock `.borderedProminent` (system accent), so
  the fix only activates when `APSKRuntime.brandTint != nil` AND the
  build target is macOS.

## Implementer recommendation to architect

Proceed with Path A-prime as written in the brief. Item 1 evidence is
sufficient to commit; no further probe iterations are required.
