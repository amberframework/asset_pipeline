
# Phase 1 — Implementation Brief: Design Token Foundation

**Audience:** Implementer agent.
**Companion docs:** `README.md` (orientation), `validation.md` (rubric you do not run), `../../rubric/implementation_criteria.md` (universal standards), `../../rubric/trust_pair_protocol.md` (handoff format).

---

## 1. Goal statement

Unify the library's two parallel token systems (`src/ui/theme.cr` and `src/components/css/tokens/amber_theme.cr`) into one canonical `UI::DesignTokens` source of truth. Build two deterministic generators (web CSS, Apple Swift) that emit from the same Crystal source. Replace every hard-coded color, spacing, type, radius, shadow and motion literal in the **web, AppKit, and UIKit** renderer visit methods with a call into a token accessor. Add a `Brand` override surface that lets a consuming app override any leaf token without forking the defaults. Keep the existing `UI::Theme` and `Components::CSS::Tokens::Theme` types alive as adapters that read from the new model so existing call sites keep compiling — the Android renderer continues to read through that adapter unchanged.

This is plumbing. The default Amber palette must look pixel-equivalent before and after, give or take rounding noise from OKLCH ↔ RGB conversion. No new visual design.

> **Scope note (2026-05-20):** The `AndroidGenerator`, Android XML dist artifacts, and Android renderer literal-scrub are deferred to a follow-up phase per `../../handoff/phase-01-architect-scope-deferral-2026-05-20.md`. The `UI::DesignTokens` model below still carries Android-equivalent data (ARGB ints, `dp`/`sp` conversion helpers) so the deferred generator can read from the same source without revisiting Phase 1. Brand-identity color conformance is held to a visual-grade bar (ΔE2000 ≤ 1.0) at the five canonical comparison points — see Validator check #3 and the architect handoff above.

---

## 2. Pre-reading checklist

Read these before touching code, in order:

1. `docs/initiative-cross-platform-ui/MASTER_PLAN.md` — North Star and tier model.
2. `docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/README.md` — phase scope.
3. `docs/initiative-cross-platform-ui/rubric/implementation_criteria.md` — universal standards.
4. `src/ui/theme.cr` — current native theme record (RGB + Material 3 roles + Apple LabelRole + corner_radius / font_size scalars).
5. `src/components/css/tokens/amber_theme.cr` — current web token generator (OKLCH, light/dark hashes, `--ap-color-*`).
6. `src/components/css/config/css_config.cr` (lines 159–356) — canonical spacing / type / breakpoint / radius / shadow / motion scales.
7. `src/ui/renderers/web_renderer.cr` lines 26–66 (`inject_theme_css`) and any visit method that calls `color_css` — to understand how web reads tokens today.
8. `src/ui/renderers/appkit_renderer.cr` lines 4565–4582 (`resolve_color`, `amber_brand_gold`) — to understand the current ad-hoc native bridge.
9. `src/ui/renderers/android_renderer.cr` lines 3129 (`theme_color_to_argb`), 2167–2172 (glass strength), 2240–2254 (separator/title hard codes), 3308 (`@material_theme` init) — Android's current state.
10. `src/ui/renderers/uikit_renderer.cr` — skim for the same `resolve_color` / hard-coded literal pattern (it mirrors AppKit).
11. `samples/cross_platform/macos_host/hig_showcase.cr` (if present) — used by validator for screenshot diffs.

Do not read this phase's `validation.md`. The validator owns that.

---

## 2a. Existing infrastructure to use (vs. rebuild)

Phase 1 unifies two existing parallel token systems into one. Almost every input artifact you need exists; the new material is the `UI::DesignTokens` source-of-truth file, the three generators, the `Brand` override surface, and the regeneration script.

### Crystal source you replace / adapt (do not rewrite from scratch)

- `src/ui/theme.cr` — current native theme record. Keep alive as a thin adapter that delegates to `UI::DesignTokens::Tokens.default`. Do not delete; existing call sites depend on the type name.
- `src/components/css/tokens/amber_theme.cr` — current web token generator. Same treatment: keep the type, route its lookups through the new model.
- `src/components/css/tokens/design_system_theme.cr` — existing token aggregator. Adapt similarly.
- `src/components/css/config/css_config.cr` (lines 159–356) — canonical spacing/type/breakpoint/radius/shadow/motion scales already live here. The new `UI::DesignTokens` types import these defaults; do not redefine the scales.
- `src/ui/renderers/web_renderer.cr` (lines 26–66) — existing `inject_theme_css`. The token generator's CSS output is what this method emits; the migration replaces ad-hoc hex literals with `var(--ap-*)` references.
- `src/ui/renderers/appkit_renderer.cr` (lines 4565–4582) — `resolve_color` and `amber_brand_gold`. `amber_brand_gold` is **deleted**; `resolve_color` reads from the new token model.
- `src/ui/renderers/uikit_renderer.cr` — mirror AppKit pattern.
- `src/ui/renderers/android_renderer.cr` — **not migrated in Phase 1.** Continues reading through `UI::Theme` (which now wraps `DesignTokens.default`); the renderer's literal-scrub is deferred per the scope note above. Glass-strength block at 2167–2172 is owned by Phase 5 either way.

### Crystal source you create

- `src/ui/design_tokens.cr` — the new source-of-truth file.
- `src/ui/design_tokens/generators/web_generator.cr`, `apple_generator.cr` — two generators. (`android_generator.cr` is deferred to a follow-up phase; do not create it here.)
- `src/ui/design_tokens/dist/web_tokens.css`, `AssetPipelineTokens.swift` — deterministic generated output, committed to the repo. (Android XML dist artifacts are deferred.)
- `scripts/regenerate_design_tokens.cr` — the regenerator script (driver for the three generators).
- `samples/cross_platform/web/brand_cascade_demo.cr` — sample referenced by validator check #18 (cascade.web-changes-on-brand-override). Phase 1 commits this file so the validator has a concrete edit target.
- `spec/ui/design_tokens_*_spec.cr` — per-aspect specs (conversion, default-match, brand-override-merge, cascade).

### Existing scripts to extend (do not duplicate)

- `scripts/validate_design_system_manifest.cr` — already validates the design system manifest. Your generator output should pass this validation.
- `scripts/axe_web_demo_audit.cr` / `scripts/ibm_web_demo_audit.cr` — accessibility audits. The new `--ap-*` variables must satisfy contrast checks against the default Amber palette.

### Pinned versions and conventions

| Tool / convention | Value | Notes |
|---|---|---|
| Crystal compiler | `crystal-alpha` | Standard. |
| CSS variable prefix | `--ap-*` | Canonical. `--amber-*` aliases are **removed entirely** by Phase 1 (see validation check #6 — zero `--amber-*` matches in `dist/web_tokens.css`). |
| Color baseline | OKLCH (canonical) + RGBA (deterministic bake) | Native renderers without OKLCH support read the baked RGBA. |
| Unit baseline | 1 rem = 16 logical points | Generators lower to `rem`/`CGFloat`/`dp`/`sp`. |
| Token round-trip tolerance | ΔL ≤ 0.001, Δc ≤ 0.001, Δh ≤ 0.5°, ΔRGB ≤ 1/255 | Universal. |
| `touch_target_minimum_px` | `Float64`, default `44.0`, declared on `Tokens` aggregate | Phase 2 dependency — required, not optional. The prior plan audit explicitly flagged Phase 2 will halt if this is missing. |

### Tier model implication for Phase 1

Phase 1 is the source of the **Tier 1 brand contract**. Every later phase reads from this model. If a token does not exist in Phase 1's model, no later phase can reference it. Add fields conservatively but completely — `touch_target_minimum_px` is the load-bearing example (Phase 2 needs it; Phase 1 must ship it).

### What is genuinely new vs. extended

| New | Extended / adapted |
|---|---|
| `src/ui/design_tokens.cr` (entire file) | `src/ui/theme.cr` (becomes adapter) |
| `src/ui/design_tokens/generators/` (three files) | `src/components/css/tokens/amber_theme.cr` (becomes adapter) |
| `src/ui/design_tokens/dist/` (two committed artifacts: `web_tokens.css`, `AssetPipelineTokens.swift`) | `src/ui/renderers/{web,appkit,uikit}_renderer.cr` (color/scale literals replaced by token reads; `android_renderer.cr` is untouched in this phase) |
| `scripts/regenerate_design_tokens.cr` | `src/components/css/config/css_config.cr` (defaults imported by the new model) |
| `samples/cross_platform/web/brand_cascade_demo.cr` | (none — sample is fresh) |

---

## 3. Token model spec

Add a new file `src/ui/design_tokens.cr`. All types live in `UI`. All scalar dimensions are `Float64` in CSS-rem-equivalent units (1 rem = 16 logical points) so the generators can lower to `rem` for web, `CGFloat` for Apple, `dp/sp` for Android without re-encoding. All colors are stored as `Color` with both an OKLCH triple **and** a precomputed RGBA fallback — the OKLCH is the canonical value; the RGBA is the deterministic baked output used by native renderers that have no OKLCH support.

### 3.1 Core types

```crystal
module UI
  module DesignTokens
    # Canonical color: OKLCH is source of truth, RGBA is the deterministic
    # bake for native renderers. Constructor that takes OKLCH computes RGBA;
    # constructor that takes RGBA stores the RGBA verbatim and leaves OKLCH
    # nil (used for platform-system references that must not round-trip).
    struct Color
      getter l : Float64?     # OKLCH lightness 0..1
      getter c : Float64?     # OKLCH chroma   0..0.4
      getter h : Float64?     # OKLCH hue      0..360 (deg)
      getter alpha : Float64  # 0..1
      getter r : Float64      # sRGB 0..1
      getter g : Float64
      getter b : Float64

      def self.oklch(l : Float64, c : Float64, h : Float64, alpha : Float64 = 1.0) : Color
        # uses Conversion module (3.4)
      end

      def self.rgb(r : Float64, g : Float64, b : Float64, alpha : Float64 = 1.0) : Color
      end

      def self.hex(value : String) : Color  # "#7c9a92" or "#7c9a92ff"

      # Used by every generator
      def to_oklch_css : String
      def to_rgba_css : String
      def to_hex : String            # "#rrggbb" or "#rrggbbaa"
      def to_swift_color : String    # "Color(red: 0.486, green: 0.604, blue: 0.573, opacity: 1.0)"
      def to_android_argb : Int32    # 0xAARRGGBB packed
    end

    # 16 semantic color roles. The set is the union of the Material 3 set
    # already in UI::Theme and the surface/text/border set in the web token
    # bag. Names use library-generic vocabulary, not platform vocabulary.
    record ColorPalette,
      brand_primary : Color,
      brand_primary_hover : Color,
      brand_primary_active : Color,
      brand_secondary : Color,
      brand_accent : Color,

      surface_canvas : Color,
      surface_panel : Color,
      surface_elevated : Color,
      surface_sunken : Color,
      surface_inverse : Color,

      text_primary : Color,
      text_secondary : Color,
      text_muted : Color,
      text_inverse : Color,
      text_link : Color,

      border_subtle : Color,
      border_default : Color,
      border_strong : Color,
      border_focus : Color,

      success : Color,
      warning : Color,
      danger : Color,
      info : Color do
      # Convenience accessor by string key, for generators that iterate.
      def to_h : Hash(String, Color)
        {
          "brand-primary" => brand_primary,
          # ...one entry per field
        }
      end
    end

    # Storage is rem-equivalent Float64. Generators emit per-platform units.
    record SpacingScale,
      px : Float64,          # 0.0625 rem == 1 px
      x0 : Float64, x0_5 : Float64,
      x1 : Float64, x1_5 : Float64, x2 : Float64, x2_5 : Float64,
      x3 : Float64, x3_5 : Float64, x4 : Float64,
      x5 : Float64, x6 : Float64, x7 : Float64, x8 : Float64,
      x9 : Float64, x10 : Float64, x11 : Float64, x12 : Float64,
      x14 : Float64, x16 : Float64, x20 : Float64, x24 : Float64,
      x28 : Float64, x32 : Float64, x36 : Float64, x40 : Float64,
      x44 : Float64, x48 : Float64, x52 : Float64, x56 : Float64,
      x60 : Float64, x64 : Float64, x72 : Float64, x80 : Float64,
      x96 : Float64 do
      # Tailwind/css_config keys ("0.5", "1", "1.5", ...) -> field
      def by_key(key : String) : Float64?
    end

    record TypeStep,
      size : Float64,          # rem
      line_height : Float64,   # unitless multiplier
      weight : Int32,          # 100..900
      tracking : Float64       # em (letter-spacing)

    record TypeScale,
      family_sans : String,
      family_display : String,
      family_mono : String,
      caption : TypeStep,      # ~12.5 px
      body : TypeStep,         # 16 px
      body_emph : TypeStep,    # 16 px, semibold
      title : TypeStep,        # 22 px
      headline : TypeStep,     # 28 px / 34 px depending on default
      display : TypeStep       # 48 px

    record RadiusScale,
      none : Float64, sm : Float64, md : Float64,
      lg : Float64, xl : Float64, x2l : Float64,
      pill : Float64              # 9999 px sentinel

    record ShadowLevel,
      offset_x : Float64,
      offset_y : Float64,
      blur : Float64,
      spread : Float64,
      color : Color

    record ShadowScale,
      flat : Array(ShadowLevel),     # empty array
      raised : Array(ShadowLevel),
      floating : Array(ShadowLevel),
      overlay : Array(ShadowLevel)

    record MotionScale,
      duration_instant_ms : Int32,   # 80
      duration_fast_ms : Int32,      # 150
      duration_base_ms : Int32,      # 240
      duration_slow_ms : Int32,      # 420
      ease_standard : String,        # cubic-bezier(...)
      ease_emphasized : String,
      spring : String                # CSS linear() or platform-equivalent identifier

    record Breakpoints,
      sm : Float64,   # px
      md : Float64,
      lg : Float64,
      xl : Float64,
      x2l : Float64
  end
end
```

### 3.2 `DesignTokens` aggregate and brand override surface

```crystal
module UI
  module DesignTokens
    class Tokens
      getter colors_light : ColorPalette
      getter colors_dark : ColorPalette
      getter spacing : SpacingScale
      getter type : TypeScale
      getter radius : RadiusScale
      getter shadow : ShadowScale
      getter motion : MotionScale
      getter breakpoints : Breakpoints
      # Minimum interactive target size in CSS pixels. Phase 2 consumes this
      # to enforce WCAG 2.2 AA touch targets and to derive the lower bound
      # of `clamp()` expressions for tappable controls. Default 44.0 per WCAG /
      # Apple HIG. Brand may override via `override_touch_target_minimum_px`.
      getter touch_target_minimum_px : Float64

      def initialize(
        @colors_light : ColorPalette,
        @colors_dark : ColorPalette,
        @spacing : SpacingScale,
        @type : TypeScale,
        @radius : RadiusScale,
        @shadow : ShadowScale,
        @motion : MotionScale,
        @breakpoints : Breakpoints,
        @touch_target_minimum_px : Float64 = 44.0,
      )
      end

      # The canonical built-in brand. Existing Amber palette transcribed
      # from amber_theme.cr (OKLCH source values).
      def self.default : Tokens
      end

      # Apply a Brand override on top of self. Returns a NEW Tokens; never
      # mutates self.
      def with_brand(brand : Brand) : Tokens
        brand.apply(self)
      end

      # Look up a single token by dotted path. Used by generators iterating
      # and by debug tooling. Unknown paths return nil.
      #   tokens.lookup("colors.light.brand_primary") # => Color
      #   tokens.lookup("spacing.x4")                 # => Float64
      def lookup(path : String) : (Color | Float64 | Int32 | String | TypeStep)?
    end

    # The override surface. A consumer subclasses Brand, sets any subset
    # of fields, and passes the instance to Tokens.default.with_brand(...).
    # Unset fields fall through to defaults.
    abstract class Brand
      def apply(base : Tokens) : Tokens
        # Implementation merges using the protected `override_*` accessors
        # below. Implementer: prefer record `copy_with` if Crystal version
        # allows; otherwise hand-roll the merge via to_h pattern.
      end

      # Optional overrides. Subclasses redefine the ones they care about.
      protected def override_color_light(palette : ColorPalette) : ColorPalette
        palette
      end

      protected def override_color_dark(palette : ColorPalette) : ColorPalette
        palette
      end

      protected def override_spacing(scale : SpacingScale) : SpacingScale
        scale
      end

      protected def override_type(scale : TypeScale) : TypeScale
        scale
      end

      protected def override_radius(scale : RadiusScale) : RadiusScale
        scale
      end

      protected def override_shadow(scale : ShadowScale) : ShadowScale
        scale
      end

      protected def override_motion(scale : MotionScale) : MotionScale
        scale
      end

      protected def override_breakpoints(scale : Breakpoints) : Breakpoints
        scale
      end

      protected def override_touch_target_minimum_px(value : Float64) : Float64
        value
      end
    end
  end
end
```

`touch_target_minimum_px` is a top-level field on `Tokens` (peer of `spacing`, `radius`, etc.), not nested inside `SpacingScale`. Phase 2 reads it via `tokens.touch_target_minimum_px`. Default is `44.0`. Bake the default into `Tokens.default`.

### 3.3 Consumer-side API ("good" example)

This is the API surface a downstream app uses to override the brand. It must keep working unchanged through future phases.

```crystal
class AcmeBrand < UI::DesignTokens::Brand
  protected def override_color_light(p)
    p.copy_with(
      brand_primary: UI::DesignTokens::Color.hex("#1d4ed8"),
      brand_primary_hover: UI::DesignTokens::Color.hex("#1e40af"),
    )
  end

  protected def override_radius(r)
    r.copy_with(md: 0.25, lg: 0.5)  # tighter radii
  end
end

tokens = UI::DesignTokens::Tokens.default.with_brand(AcmeBrand.new)
```

**`copy_with` is mandatory on every record-derived token type.** Phase 6 (and any consuming app brand) writes `palette.copy_with(brand_primary: ...)`-style merges relying on this method existing. If Crystal's `record` macro auto-generates `copy_with` on the pinned compiler version, that satisfies the requirement. If it does not, hand-roll `copy_with` on each affected type — `ColorPalette`, `SpacingScale`, `TypeScale`, `RadiusScale`, `ShadowScale`, `MotionScale`, `Breakpoints`, and `Tokens` itself — taking keyword arguments matching the record's fields and returning a new instance with the named fields replaced and the rest copied. Verify on the actual compiler version before assuming auto-generation; if uncertain, hand-roll. The file header in `design_tokens.cr` documents which path was taken.

### 3.4 OKLCH ↔ sRGB conversion

The existing web token file stores OKLCH strings only; it never computes RGB. Native renderers need RGB. Implement deterministic OKLCH→sRGB and sRGB→OKLCH in a new module `UI::DesignTokens::Conversion`:

- Reference algorithm: Björn Ottosson's OKLab/OKLCH (Lab → linear sRGB → companding to gamma sRGB).
- Out-of-gamut OKLCH must be clipped using chroma reduction (not naive RGB clamp). Reduce chroma to 0 in steps of 0.001 until in gamut, then return.
- Round trip tolerance: any default Amber color round-tripped (OKLCH → RGB → OKLCH) must be within 0.001 on L, 0.001 on c, 0.5° on h. Spec this explicitly.

---

## 4. Generator output specs

All three generators live under `src/ui/design_tokens/generators/`. Each exposes a single class method `generate(tokens : Tokens) : String` and a CLI hook (added to `scripts/`) so the build pipeline can regenerate when source tokens change. Generated text is deterministic: same input bytes → same output bytes.

### 4.1 `WebGenerator` → CSS

File: `src/ui/design_tokens/generators/web_generator.cr`.
Default output path target: `src/ui/design_tokens/dist/web_tokens.css` (regenerated, checked in for transparency; spec asserts equality).

Output shape:

```css
/* GENERATED by UI::DesignTokens::WebGenerator. Do not edit by hand. */
:root {
  color-scheme: light dark;

  /* colors — canonical OKLCH plus baked RGB fallback */
  --ap-color-brand-primary: oklch(0.520 0.160 50.00);
  --ap-color-brand-primary-rgb: 213 110 32;
  --ap-color-brand-primary-hover: oklch(0.470 0.170 48.00);
  /* ... one pair per ColorPalette field ... */

  /* spacing — rem */
  --ap-space-px: 1px;
  --ap-space-0: 0rem;
  --ap-space-0_5: 0.125rem;
  --ap-space-1: 0.25rem;
  /* ... */

  /* type */
  --ap-font-sans: Inter, ui-sans-serif, system-ui, -apple-system, ...;
  --ap-font-display: Newsreader, Georgia, ui-serif, serif;
  --ap-font-mono: ui-monospace, SFMono-Regular, ...;
  --ap-type-body-size: 1rem;
  --ap-type-body-line-height: 1.55;
  --ap-type-body-weight: 450;
  /* ... one block per TypeStep ... */

  /* radius */
  --ap-radius-none: 0rem;
  --ap-radius-sm: 0.125rem;
  --ap-radius-md: 0.375rem;
  /* ... */

  /* shadow */
  --ap-shadow-flat: none;
  --ap-shadow-raised: 0 1px 2px oklch(0 0 0 / 0.08), 0 8px 24px oklch(0.18 0.02 248 / 0.08);
  /* ... */

  /* motion */
  --ap-motion-duration-instant: 80ms;
  --ap-motion-duration-fast: 150ms;
  --ap-motion-ease-standard: cubic-bezier(0.2, 0, 0, 1);
  /* ... */

  /* breakpoints — informational only; actual breakpoints live in @media rules */
  --ap-bp-sm: 640px;
  --ap-bp-md: 768px;
  /* ... */
}

@media (prefers-color-scheme: dark) {
  :root {
    --ap-color-brand-primary: oklch(0.780 0.170 58.00);
    --ap-color-brand-primary-rgb: 255 173 51;
    /* ... dark overrides ... */
  }
}

[data-ap-theme="light"] { /* identical to :root light block */ }
[data-ap-theme="dark"]  { /* identical to dark block */ }
```

The canonical CSS custom-property prefix is `--ap-*`. The previously-discussed `--amber-*` alias block is **NOT** emitted in this phase or any later phase — the prefix change is total. Any existing utility CSS or downstream consumers that referenced `--amber-color-*` must be migrated to `--ap-color-*` (the Phase 1 implementer's adapter rewrite of `Components::CSS::Tokens::Theme` in Step 7 is the migration vehicle; existing call sites read the same logical values through the new prefix).

### 4.2 `AppleGenerator` → Swift

File: `src/ui/design_tokens/generators/apple_generator.cr`.
Output path: `src/ui/design_tokens/dist/AssetPipelineTokens.swift` (checked in; consumed by phase 3 SwiftUI bridge).

```swift
// GENERATED by UI::DesignTokens::AppleGenerator. Do not edit by hand.
import SwiftUI

public enum AssetPipelineTokens {

    public enum Color {
        public static let brandPrimary = SwiftUI.Color(.sRGB,
            red: 0.835, green: 0.431, blue: 0.125, opacity: 1.0)
        public static let brandPrimaryHover = SwiftUI.Color(.sRGB,
            red: 0.733, green: 0.357, blue: 0.090, opacity: 1.0)
        // ... one per ColorPalette field ...

        public enum Dark {
            public static let brandPrimary = SwiftUI.Color(.sRGB,
                red: 1.000, green: 0.678, blue: 0.200, opacity: 1.0)
            // ... one per ColorPalette field ...
        }
    }

    public enum Spacing {
        public static let px: CGFloat = 1
        public static let x0:   CGFloat = 0
        public static let x0_5: CGFloat = 2
        public static let x1:   CGFloat = 4
        // ... convert rem * 16 -> pt ...
    }

    public enum Radius {
        public static let none: CGFloat = 0
        public static let sm:   CGFloat = 2
        public static let md:   CGFloat = 6
        // ...
    }

    public enum Typography {
        public static let familySans = "system"     // Apple resolves to SF
        public static let familyDisplay = "system"
        public static let familyMono = "system-monospaced"

        public struct Step {
            public let size: CGFloat
            public let lineHeight: CGFloat
            public let weight: Font.Weight
            public let tracking: CGFloat
        }

        public static let body = Step(size: 17, lineHeight: 22, weight: .regular, tracking: 0)
        public static let bodyEmph = Step(size: 17, lineHeight: 22, weight: .semibold, tracking: 0)
        public static let title = Step(size: 22, lineHeight: 28, weight: .semibold, tracking: 0)
        // ...
    }

    public enum Motion {
        public static let durationInstant: Double = 0.080
        public static let durationFast:    Double = 0.150
        public static let durationBase:    Double = 0.240
        public static let durationSlow:    Double = 0.420
        public static let easeStandard   = UnitCurve.easeInOut       // mapped
        public static let easeEmphasized = UnitCurve.bezier(0.16, 1, 0.30, 1)
    }
}
```

Mapping rules:

- Spacing/radius rem are multiplied by 16 to convert to Apple points. Result is rounded to half-points when fractional (Apple convention).
- Type sizes for body/title/headline use Apple's HIG defaults (17/22/28) **only when** the brand has not overridden them. Otherwise the brand's value passes through unchanged.
- Font.Weight mapping: 100→.ultraLight, 200→.thin, 300→.light, 400→.regular, 450→.regular (rounds down), 500→.medium, 600→.semibold, 700→.bold, 800→.heavy, 900→.black.
- Curves: `ease_standard` maps to `UnitCurve.easeInOut`; `ease_emphasized` round-trips the bezier 4-tuple exactly. `spring` is dropped on Apple (SwiftUI has its own `.spring()` and brand can't override the SwiftUI default through tokens in phase 1).

### 4.3 `AndroidGenerator` — **DEFERRED**

The Android XML generator is not built in this phase. See `../../handoff/phase-01-architect-scope-deferral-2026-05-20.md` for the rationale and the future-phase reference shape. The `UI::DesignTokens::Color#to_android_argb` helper still ships in §3 so the deferred generator has a stable conversion API to call.

---

## 5. Step-by-step implementation plan

Commit-sized chunks. Land them in order; do not bundle.

### Step 1 — Add the new types, no behavior change

**Change:** introduce `src/ui/design_tokens.cr` and `src/ui/design_tokens/conversion.cr`. Define every struct, record and class above. `Tokens.default` returns the transcribed Amber palette with values that exactly match the existing `amber_theme.cr` light/dark hashes (do not re-derive — read the existing OKLCH strings and parse them).
**Files touched:** new files only.
**Rationale:** type surface first, generators next. Keeps the diff reviewable and lets the spec for round-trip conversion run before generator wiring.
**Good output:** `crystal spec spec/ui/design_tokens_spec.cr` green. `Tokens.default.colors_light.brand_primary.to_oklch_css == "oklch(0.520 0.160 50.00)"`.

### Step 2 — `Brand` override surface and merge semantics

**Change:** finish `Brand.apply` and `Tokens#with_brand`. Add `copy_with`-style merge for each record (or hand-roll if Crystal records lack it on your version).
**Files touched:** `src/ui/design_tokens.cr`, new spec `spec/ui/design_tokens_brand_spec.cr`.
**Rationale:** generators depend on the merge being correct.
**Good output:** spec where `AcmeBrand` overrides `brand_primary` only — assert every other field equals default.

### Step 3 — WebGenerator + dist file

**Change:** add `src/ui/design_tokens/generators/web_generator.cr`. Add a script `scripts/regenerate_design_tokens.cr` that writes the three dist files. Run the script and commit the dist files.
**Files touched:** generator file, script, `src/ui/design_tokens/dist/web_tokens.css` (generated).
**Rationale:** web is the highest-fidelity surface; nailing it first surfaces token-naming bugs early.
**Good output:** the generated CSS contains every variable listed in §4.1. Spec asserts the generator is byte-stable across two consecutive runs.

### Step 4 — AppleGenerator + dist file

**Change:** add `src/ui/design_tokens/generators/apple_generator.cr`. Extend the regen script.
**Files touched:** generator file, `src/ui/design_tokens/dist/AssetPipelineTokens.swift`.
**Rationale:** sets up phase 3.
**Good output:** Swift file is byte-stable. Cross-checked manually: each color's RGB matches the OKLCH source bake within 1/255 per channel.

### Step 5 — *(deferred)* AndroidGenerator + dist files

Skipped in this phase per the scope deferral. Step 6 follows directly. Renumbering is intentionally avoided so commit messages and validator references can quote the original step numbers — when you read "Step 11" below, treat it as also deferred.

### Step 6 — Adapter: `UI::Theme` reads from `DesignTokens`

**Change:** rewrite `src/ui/theme.cr` `Theme` defaults (`design_system_default`, `amber_default`, `material_baseline`, `apple_default`) to *derive* their RGB and scalar values from `Tokens.default` (or a brand variant). Do not change the `Theme` public API. Existing callers stay compiling.
**Files touched:** `src/ui/theme.cr`.
**Rationale:** all four renderers consume `UI::Theme`; this is the cheapest cascade path.
**Good output:** `UI::Theme.design_system_default.primary` returns the same RGB as before (within the round-trip tolerance from §3.4).

### Step 7 — Adapter: `Components::CSS::Tokens::Theme` reads from `DesignTokens`

**Change:** rewrite `src/components/css/tokens/amber_theme.cr` so `amber_default` and `design_system_default` construct from `UI::DesignTokens::Tokens.default`. The legacy `light` / `dark` hashes are *populated from* the new model, not hand-edited.
**Files touched:** `src/components/css/tokens/amber_theme.cr`.
**Rationale:** kills the second source of truth without breaking the public CSS variable surface.
**Good output:** every existing call site of `Theme.amber_default` keeps working; `to_css_variables(:light)` returns the same set of variable names as before (you may add new variables; you may not remove or rename any existing one in this phase).

### Step 8 — `WebRenderer` migration

**Change:** in `src/ui/renderers/web_renderer.cr`, replace every `"rgba(#{to_rgb_int(...)})"` inline color emit and every literal `9999px`, `#FFCC00`, etc. with a call into a new private helper `token_css(:color, :brand_primary)` / `token_css(:radius, :pill)` / etc. `inject_theme_css` re-derives its output by calling `WebGenerator.generate(tokens)` directly — no parallel string-building.
**Files touched:** `web_renderer.cr` only.
**Rationale:** prove the new system end-to-end on the simplest renderer first.
**Good output:** `grep -nE '"#[0-9A-Fa-f]{3,8}"|rgba\(' src/ui/renderers/web_renderer.cr` returns zero hits in `visit` methods (the `to_rgb_int` helper itself may remain only if it is used exclusively by view-level color attributes the user explicitly set; if so, document why in a code comment).

### Step 9 — `AppKitRenderer` migration

**Change:** in `src/ui/renderers/appkit_renderer.cr`, delete `amber_brand_gold` and any literal RGBA in visitors. Add `token_color(:brand_primary, appearance: current_appearance)` private helper that resolves a `DesignTokens::Color` to `NSColor*` via the existing bridge. Every `LibObjCBridge.nsfont_system(13.0)` etc. is replaced with `token_font(:body)` returning the bridge call with the size pulled from `DesignTokens::Tokens.default.type.body.size` (multiplied to pt). Corner radius literals like `setCornerRadius:` numeric arguments come from `token_radius(:md)` etc.
**Files touched:** `appkit_renderer.cr` only.
**Rationale:** appkit is the largest surface; the recipe proves out before you do uikit.
**Good output:** `grep -nE 'nsfont_system\([0-9]+\.[0-9]+|nscolor_rgba\([0-9]+\.[0-9]+' src/ui/renderers/appkit_renderer.cr` returns zero hits in visit methods (helpers that *receive* a token still call the raw bridge — that's allowed).

### Step 10 — `UIKitRenderer` migration

**Change:** mirror Step 9 for `uikit_renderer.cr`.
**Files touched:** `uikit_renderer.cr` only.

### Step 11 — *(deferred)* `AndroidRenderer` migration

Skipped per the scope deferral. `android_renderer.cr` continues to read brand decisions via the `UI::Theme` adapter (which now wraps `DesignTokens.default` thanks to Step 6) without any visit-method edits in this phase.

### Step 12 — Spec coverage for cascade + cascade demo sample

**Change:** add `spec/ui/design_tokens_cascade_spec.cr` that uses a `TestBrand` overriding `brand_primary` to a sentinel color, then asserts:
- `WebGenerator.generate(tokens)` includes the sentinel RGB.
- `AppleGenerator.generate(tokens)` includes the sentinel RGB in `SwiftUI.Color(red: ...)`.
- A fake render of a `Button` through `WebRenderer` emits the sentinel via the brand-primary CSS variable.

(The deferred Android generator would add a third assertion against `to_android_argb` output; that assertion lands with the future Android phase.)

Additionally, create `samples/cross_platform/web/brand_cascade_demo.cr` — a minimal Crystal source that emits a single web page using brand-tokenized colors (a primary button, a panel surface, a link). The page must read its colors via `Tokens.default.with_brand(SentinelBrand.new)` so a validator can flip the sentinel and observe the cascade. This file is the path the validator will edit (and revert) in cascade checks 18–20.

**Files touched:** new spec, new sample (`samples/cross_platform/web/brand_cascade_demo.cr`).
**Rationale:** mechanizes the validator's headline cascade check and pins the sample file path the validator uses across checks 18–20.

### Step 13 — README / docs

**Change:** update `CLAUDE.md` (repo root) with a one-paragraph "Design tokens" section pointing to `src/ui/design_tokens.cr` and the regen script. Update the repo top-level `README.md` only if the public API surface visible to library consumers changed (it shouldn't have).
**Files touched:** `CLAUDE.md` (maybe `README.md`).

---

## 6. Migration recipe per renderer

Apply once per renderer file in the order above. The recipe is mechanical; follow it to the letter to keep diffs reviewable.

1. **Audit.** Run `grep -nE 'rgba?\([0-9]|#[0-9A-Fa-f]{6}|0xFF[0-9A-Fa-f]{6}|nsfont_system\([0-9]|systemFontOfSize:[0-9]|setCornerRadius.*[0-9]+\.[0-9]|cornerRadius:[0-9]' <file>`. Collect every match into a checklist in your scratch notes.
2. **Classify each hit:**
   - (a) Brand color → replace with `token_color(:role)` or `token_argb(:role)`.
   - (b) Scalar dimension (radius, padding, font size) → replace with `token_*(:key)`.
   - (c) Platform-system reference (`NSColor.labelColor`, `UIColor.systemBlue`) → leave alone; these are intentional Tier 2 defaults.
   - (d) Numeric literal that is genuinely platform-specific (e.g. accent-color alpha 0.4 for unselected tabs) → leave alone but add a `# Tier 2 platform default` comment so the validator's grep knows to skip it.
3. **Add a private helper section at the bottom of the file.** Wrap the bridge calls so the visit methods stay readable. Example for AppKit:
   ```crystal
   private def token_nscolor(role : Symbol, appearance : Symbol = current_appearance) : Void*
     palette = appearance == :dark ? tokens.colors_dark : tokens.colors_light
     c = palette.lookup(role) || raise "Unknown color role: #{role}"
     LibObjCBridge.nscolor_rgba(c.r, c.g, c.b, c.alpha)
   end
   ```
4. **Refactor visitors top-down.** Commit each ~500-line block of the renderer separately if you find it useful, but a single per-renderer commit is acceptable.
5. **Re-run audit.** The only allowed remaining hits in visit methods are class (c) and (d) above. Class (d) must have a `# Tier 2` comment within 3 lines.

---

## 7. Testing requirements

Place specs under `spec/ui/` mirroring the source path.

Required specs:

1. `spec/ui/design_tokens_spec.cr` — constructor behavior for `Color`, `Tokens.default` equality, `lookup` paths.
2. `spec/ui/design_tokens_conversion_spec.cr` — round-trip OKLCH↔sRGB within tolerance for every default Amber color. Edge cases: pure white, pure black, alpha < 1, out-of-gamut OKLCH triple.
3. `spec/ui/design_tokens_brand_spec.cr` — single-field override, multi-field override, full-palette override, no-op brand. Assert immutability of `Tokens.default` after each test.
4. `spec/ui/design_tokens/generators/web_generator_spec.cr` — output contains expected variable names; output is byte-stable across two calls; light and dark blocks both present.
5. `spec/ui/design_tokens/generators/apple_generator_spec.cr` — output contains every color; SwiftUI.Color RGB triples within tolerance.
6. *(deferred)* `spec/ui/design_tokens/generators/android_generator_spec.cr` — ships with the deferred Android phase.
7. `spec/ui/design_tokens_cascade_spec.cr` — see Step 12.
8. Update `spec/ui/theme_spec.cr` (if exists) to assert `Theme.design_system_default.primary.r` lies within 0.005 of the pre-migration value.

Required to keep green:
- Full `crystal spec` suite from repo root.
- `crystal build --no-codegen src/asset_pipeline.cr` for web build.
- macOS sample build: `crystal build samples/cross_platform/macos_host/<showcase>.cr -Dmacos --no-codegen` if such a sample exists.
- iOS equivalent documented in `samples/cross_platform/` — `--no-codegen` is sufficient for this phase.
- Android sample (if documented in `samples/cross_platform/`) must still compile against the unchanged renderer + `UI::Theme` adapter. This is a regression guard, not a migration target.

---

## 8. Definition of done

Phase 1 is done when all of the following hold:

1. `src/ui/design_tokens.cr` and its sub-modules exist, are spec'd, and `Tokens.default` is the single canonical source for every Tier 1 value (including the Android-equivalent data the deferred generator will read).
2. Two generators (`WebGenerator`, `AppleGenerator`) emit deterministic, byte-stable output. The two dist files are checked into the repo.
3. `UI::Theme` and `Components::CSS::Tokens::Theme` keep their public API but their values are derived from `Tokens.default`. The Android renderer continues to read through `UI::Theme` unchanged.
4. The **web, AppKit, and UIKit** renderers' visit methods are free of hard-coded brand color, brand radius, brand spacing, brand type-size, and brand motion literals. The only exceptions are documented Tier 2 platform-system references and class-(d) numeric literals with a comment. The Android renderer is exempt from this check in this phase.
5. Defining a 5-line subclass of `Brand` that overrides `brand_primary` to a sentinel and rendering a sample view on **web and at least one Apple target (macOS or iOS)** shows the sentinel color. Android sentinel-cascade is deferred along with the generator.
6. `crystal spec` from repo root passes with zero failures and zero new pending tests.
7. The web entrypoint and the macOS / iOS sample app builds (`--no-codegen`) succeed. The Android sample must keep compiling against the unchanged renderer.
8. A handoff message in `trust_pair_protocol.md` format is written, including commit hashes for steps 1–13 (acknowledging steps 5 and 11 are deferred — your handoff should note their absence rather than fabricating commits) and a Deviations section if you diverged from this brief.

What is **not** in done:
- Deleting `UI::Theme`. It stays as an adapter through phase 4 minimum.
- Glass material token wiring. Phase 5 owns that.

(The earlier draft of this brief listed "removing legacy `--amber-*` CSS aliases" as a Phase 6 follow-up; that is no longer accurate. The prefix change to `--ap-*` is total in Phase 1 — no `--amber-*` aliases are emitted, so there is nothing for a later phase to remove.)
