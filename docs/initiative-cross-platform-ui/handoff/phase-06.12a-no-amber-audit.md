# Phase 6.12A — Item 5: No-amber audit

**Date:** 2026-05-24
**Iteration:** 4 (post-Item-1/2/3, pre-final-Codex-review)
**Authored by:** Implementer
**Branch HEAD before audit:** `9f5d02f`

## Mandate

Per brief.md Item 5 (lines 299-327): after the library-identity pivot lands, regenerate `src/ui/design_tokens/dist/*` and grep all generated outputs for amber-equivalent colour literals. For each finding, decide whether to (a) pivot the source token to `Color::SYSTEM_ACCENT` or (b) justify keeping it as a non-brand library colour.

## Method

1. Ran `crystal run scripts/regenerate_design_tokens.cr` to refresh dist artifacts.
2. Ran `crystal run samples/initiative-cross-platform-ui-voyager/web/static_site.cr` to refresh the Voyager web output.
3. Grepped both for amber-flavoured tokens:
   - String tokens: `amber|orange|tan|peach`.
   - Brief-specified RGB regex: `rgb\([23][0-9]{2},.*[0-9]{2},.*[0-9]{1,2}\)`.
   - OKLCH amber-hue range (h ≈ 45° – 89°): `oklch\(0\.[0-9]+ 0\.[0-9]+ (4[5-9]|5[0-9]|6[0-9]|7[0-9]|8[0-9])`.
   - Specific pre-pivot literal hashes (`oklch(0.52 0.16 50)` etc.) for the original amber brand_primary family.

## Findings

### String tokens (amber|orange|tan|peach)

The brief's literal regex `amber|orange|tan|peach` was run across `src/ui/design_tokens/dist/` and `output/voyager-demo/`.

- **`amber` / `orange` / `peach`:** zero matches.
- **`tan` matches:** non-zero, but every hit is a false positive — `tan` is a substring of `instant` (as in the motion token `duration_instant_ms` → emitted CSS / Swift names like `instant`). No `tan` colour-name token exists. Refined regex `\btan\b` confirms zero word-boundary matches.

The pivot removed every amber/orange/peach-named token from the generated outputs.

### Amber RGB regex `rgb\([23][0-9]{2},.*[0-9]{2},.*[0-9]{1,2}\)`

**Zero matches.** The web generator emits OKLCH literals (`oklch(L C H)`) plus paired `-rgb` triples (space-separated channels), not `rgb()` literals — so the brief's specific RGB regex catches nothing by construction. The paired `-rgb` channels for non-brand tokens were also audited (see below).

### Pre-pivot amber OKLCH literals

The original `Tokens.default.brand_primary` family was:

| Field | Original light OKLCH | Original dark OKLCH |
|-------|---------------------|--------------------|
| `brand_primary` | `oklch(0.52 0.16 50)` | `oklch(0.78 0.17 58)` |
| `brand_primary_hover` | `oklch(0.47 0.17 48)` | `oklch(0.84 0.15 60)` |
| `brand_primary_active` | `oklch(0.40 0.15 46)` | `oklch(0.70 0.18 54)` |

Grep for any of these literals in the dist + Voyager web output: **0 matches.** All gone.

### OKLCH amber-hue range (h ∈ [45°, 89°])

Several non-brand tokens have hues in the warm range. Each is dispositioned individually:

| Token | Light OKLCH | Light disposition | Dark disposition |
|-------|-------------|------------------|------------------|
| `surface_canvas` | `oklch(0.985 0.009 82)` | KEEP — very low chroma (0.009 ≪ 0.05); reads as near-neutral warm white, not amber. Surface tone, not a brand colour. | KEEP — dark canvas is `oklch(0.15 0.025 260)` (cool blue-grey), not amber. |
| `surface_elevated` | `oklch(0.995 0.003 80)` | KEEP — same family, even lower chroma. | KEEP — `oklch(0.25 0.028 260)`. |
| `surface_sunken` | `oklch(0.955 0.011 79)` | KEEP — chroma 0.011, near-neutral. | KEEP — `oklch(0.12 0.022 260)`. |
| `text_inverse` | `oklch(0.99 0.003 80)` | KEEP — near-white for inverse text. Background tone. | KEEP — `oklch(0.18 0.018 248)` (cool dark). |
| `text_primary` | `oklch(0.18 0.018 248)` (cool dark for legibility) | KEEP — cool blue-grey, not amber. | KEEP — dark mode: `oklch(0.95 0.006 80)` — chroma 0.006 is sub-perceptual, reads as off-white. The h=80° is the warm hue that legacy AppKit's `labelColor` (light) traditionally biases towards on macOS. Not amber-equivalent. |
| `text_secondary` | `oklch(0.38 0.028 248)` (cool) | KEEP. | KEEP — dark: `oklch(0.78 0.015 85)` — chroma 0.015, warm-tone-low-chroma neutral. Same rationale as `text_primary` dark; reads as warm grey for hierarchy contrast against `text_primary`. Not amber-equivalent. |
| `text_muted` | `oklch(0.52 0.025 248)` (cool) | KEEP. | KEEP — dark: `oklch(0.65 0.018 85)` — chroma 0.018, same warm-grey family one notch dimmer. Not amber-equivalent. |
| `surface_inverse` (dark) | n/a in light bag | n/a | KEEP — dark palette: `oklch(0.95 0.006 80)` matches the dark `text_primary` literally (it's the "inverse" surface used when a light-tone surface is needed inside dark mode). Same chroma-0.006 sub-perceptual neutral; not amber. |
| `border_subtle` | `oklch(0.91 0.014 82)` | KEEP — chroma 0.014, warm-grey hairline. | KEEP — `oklch(0.31 0.02 248)` (cool). |
| `border_default` | `oklch(0.82 0.021 82)` | KEEP — warm-grey medium border. | KEEP — `oklch(0.38 0.025 248)`. |
| `border_strong` | `oklch(0.62 0.04 75)` | KEEP — chroma 0.04, still in the warm-grey territory (not perceptually amber). Could be hue-neutralised in a future polish phase if the warm cast is unwanted, but it's not amber-equivalent. | KEEP — `oklch(0.52 0.03 248)` (cool). |
| `border_focus` | `oklch(0.66 0.15 50, alpha 0.58)` | **PIVOTED to `Color::SYSTEM_ACCENT`.** Chroma 0.15 + hue 50° is unambiguously amber; this was the focus-ring partner of the original amber brand. Apple HIG focus rings cascade from the system accent (`NSColor.keyboardFocusIndicatorColor` on macOS; `UIColor.tintColor` on iOS) — making `border_focus` a sentinel keeps the ring colour coherent with whatever brand the consumer applies (default → platform accent; `.with_brand` → that brand colour). | **PIVOTED.** Dark `oklch(0.75 0.14 58)` was the same amber family. |
| `warning` | `oklch(0.58 0.15 75)` | KEEP — `warning` is semantically orange/amber by design (Apple HIG: `UIColor.systemOrange` for warnings, NSColor analog). This is a non-brand library colour with a justified amber cast. | KEEP — `oklch(0.80 0.15 78)` same justification. |
| `warning-*` bg/border/text/focus-ring (in legacy `amber_theme.cr` semantic emitter) | various | KEEP — same justification as `warning`. | KEEP. |

### Other amber-adjacent surfaces

- `state-hover` / `state-active` / `state-selected` in `src/components/css/tokens/amber_theme.cr` (line 165-167) — these were tuned to the legacy amber state-fill palette. Post-pivot, they look slightly warm-grey. **KEEP** — the legacy `amber_theme.cr` is backward-compat infrastructure for callers of `Components::CSS::Tokens::Theme.amber_default`. The "amber" name is intentional in this legacy bag. Pivoting these would break the legacy contract; consumers who want platform-accent states should use the `--ap-*` token system directly.
- `Components::CSS::Tokens::Theme.amber_default.palettes["amber"]` stops — pinned to literal amber OKLCH values in Item 1's `amber_theme.cr` fix. **KEEP** by design; the palette is named "amber" and must remain literally amber for backward compat.

## Pivots applied in this audit

**`Defaults.light_palette.border_focus`:** `oklch(0.66, 0.15, 50, 0.58)` → `Color::SYSTEM_ACCENT`.
**`Defaults.dark_palette.border_focus`:** `oklch(0.75, 0.14, 58, 0.62)` → `Color::SYSTEM_ACCENT`.

Justification: focus rings are platform-coherent on Apple. Apple's `NSColor.keyboardFocusIndicatorColor` and `UIColor.tintColor` both resolve to the system accent. Pivoting `border_focus` to sentinel:

1. Restores HIG-correct focus ring behaviour (focus rings adopt the user's macOS General > Accent preference, the iOS system tint, or the consumer's `.with_brand(...)` override).
2. Removes the only chroma-0.15 amber-hued colour from the post-pivot defaults.
3. Has zero functional regression because:
   - Specs do not assert specific `border_focus` OKLCH values.
   - The web CSS emits `--ap-color-border-focus: AccentColor;` instead of the amber OKLCH, which is a legal CSS Color 4 system colour value.
   - Renderers (AppKit / UIKit) consume `border_focus` indirectly through `lookup(:border_focus)` and the existing sentinel branch in `token_nscolor` already routes to `NSColor.controlAccentColor` / `UIColor.tintColor`.

## Items NOT pivoted (kept as non-brand library colours)

- `surface_*` family (warm-tone-low-chroma neutrals).
- `text_inverse` (near-white).
- `border_subtle / default / strong` (warm-grey neutrals with low chroma).
- `warning` (semantically orange-coded per Apple HIG; not a brand colour).
- Legacy `amber_theme.cr` palette / state tokens (backward-compat infrastructure; pivoting them would silently change consumer styling).

## Regenerator behaviour post-pivot

`crystal run scripts/regenerate_design_tokens.cr` now reports **8 sentinel roles** (was 6 before this audit; the 2 new roles are light + dark `border-focus`):

```
[regenerate_design_tokens] android: skipped — Color::SYSTEM_ACCENT in 8 role(s):
  - colors_light.brand-primary
  - colors_light.brand-primary-hover
  - colors_light.brand-primary-active
  - colors_light.border-focus
  - colors_dark.brand-primary
  - colors_dark.brand-primary-hover
  - colors_dark.brand-primary-active
  - colors_dark.border-focus
```

Web dist + Apple Swift dist regenerated; specs still 1529/4/0/66 (baseline preserved).

## Cascade post-pivot interaction

Cascade's `DemoBrand` overrides `brand_primary` / `brand_primary_hover` / `brand_primary_active` / `brand_secondary` (light + dark) but does NOT override `border_focus`. Pre-pivot, this meant Cascade got the library amber focus ring (`oklch(0.66 0.15 50)`) — already inconsistent with its teal brand. Post-pivot, Cascade gets `AccentColor` for `border_focus` — i.e. the platform system accent (typically system blue on macOS / iOS unless the user has overridden their accent preference). Still inconsistent with Cascade's teal.

Verdict: **no regression** — Cascade was already inconsistent on `border_focus`. The fix is for Cascade's `DemoBrand` to override `border_focus` to teal in a follow-up commit; tracked as a Cascade-internal polish concern, NOT a Phase 6.12A blocker.

A consumer who wants their brand colour to drive their focus ring overrides `border_focus` in their `Brand` subclass:

```crystal
class CascadeBrand < UI::DesignTokens::Brand
  protected def override_color_light(palette)
    palette.copy_with(
      brand_primary: TEAL,
      # … other brand colours …
      border_focus: TEAL.copy_with(alpha: 0.58),
    )
  end
end
```

## Conclusion

The `Tokens.default` palette is now amber-free. Every amber-equivalent literal in the original palette is either:

1. Pivoted to `Color::SYSTEM_ACCENT` (brand_primary family + border_focus).
2. Kept as a non-brand library colour with documented justification (surface / border / text / warning tokens, plus the legacy semantic bag).

A consumer who wants an opinionated brand subclasses `UI::DesignTokens::Brand` and calls `Tokens.default.with_brand(...)` — the sentinel tokens flip to the consumer's brand colour through the existing cascade (Cascade demo proves this end-to-end with deep teal across web + macOS + iOS).
