# Phase 6.12A — Item 0: Cascade preflight (read-only)

**Date:** 2026-05-24
**Iteration:** 1 (preflight, no code changes)
**Author:** Implementer
**Branch HEAD:** `d275d9f` (pre-Item-1)

## Mandate

Per brief.md Item 0 (lines 37-54): identify how the Cascade demo (`samples/initiative-cross-platform-ui-demo/`) applies its deep-teal brand BEFORE pivoting `Tokens.default` to `Color::SYSTEM_ACCENT`, so Item 4 can verify (or repair) Cascade post-pivot.

The pivot risk is straightforward: if Cascade relies *implicitly* on the library default having amber and only overrides specific colors with `copy_with`, then dropping amber from `Tokens.default` could leak the sentinel into Cascade's surfaces. If Cascade calls `.with_brand(...)` explicitly, the pivot is invisible to Cascade.

## Naming clarification

The brief uses the placeholder name **`CascadeBrand`**. The actual class in source is **`InitiativeDemo::DemoBrand`**, exposed via the helper `InitiativeDemo.brand_tokens`. Same role, different name. No `CascadeBrand` class exists.

## Findings

### Brand-application path (single entrypoint, three call sites)

Cascade's brand application is **fully explicit**. The brand class is `InitiativeDemo::DemoBrand` (a `UI::DesignTokens::Brand` subclass), wrapped by a helper that returns a fresh `Tokens` per call:

| File | Line | Code | Notes |
|------|------|------|-------|
| `samples/initiative-cross-platform-ui-demo/brand.cr` | 40-58 | `class DemoBrand < UI::DesignTokens::Brand` — overrides `override_color_light` and `override_color_dark` via `palette.copy_with(brand_primary: …, brand_primary_hover: …, brand_primary_active: …, brand_secondary: …)` | Light + dark palettes both overridden. Only brand_primary family + brand_secondary are touched; all other tokens flow from `Tokens.default`. |
| `samples/initiative-cross-platform-ui-demo/brand.cr` | 69-71 | `def self.brand_tokens : UI::DesignTokens::Tokens; UI::DesignTokens::Tokens.default.with_brand(DemoBrand.new); end` | Single helper. Returns `Tokens.default.with_brand(DemoBrand.new)`. Method (not constant) to dodge the iOS class-init gap (see file comments lines 60-68; canonical workaround at `samples/cross_platform/ios_host/hig_bridge.cr:25-50`). |

### Consumer call sites (three: macOS, web, iOS)

| File | Line | Code |
|------|------|------|
| `samples/initiative-cross-platform-ui-demo/macos/host.cr` | 58 | `renderer.design_tokens = InitiativeDemo.brand_tokens` |
| `samples/initiative-cross-platform-ui-demo/web/static_site.cr` | 27 | `renderer.design_tokens = InitiativeDemo.brand_tokens` |
| `samples/initiative-cross-platform-ui-demo/ios/bridge.cr` | 74 | `renderer.design_tokens = InitiativeDemo.brand_tokens` |

All three Cascade renderer entrypoints assign `InitiativeDemo.brand_tokens` to `renderer.design_tokens` before rendering. There is **no implicit reliance** on `Tokens.default` for any brand color in Cascade.

### Brand color values

`samples/initiative-cross-platform-ui-demo/brand.cr` lines 25-38:

```
BRAND_PRIMARY_LIGHT         = UI::DesignTokens::Color.oklch(0.56, 0.13, 195.0)
BRAND_PRIMARY_HOVER         = UI::DesignTokens::Color.oklch(0.50, 0.13, 195.0)
BRAND_PRIMARY_ACTIVE        = UI::DesignTokens::Color.oklch(0.44, 0.13, 195.0)
BRAND_PRIMARY_DARK          = UI::DesignTokens::Color.oklch(0.68, 0.14, 195.0)
BRAND_PRIMARY_DARK_HOVER    = UI::DesignTokens::Color.oklch(0.74, 0.14, 195.0)
BRAND_PRIMARY_DARK_ACTIVE   = UI::DesignTokens::Color.oklch(0.62, 0.14, 195.0)
BRAND_SECONDARY_LIGHT       = UI::DesignTokens::Color.oklch(0.62, 0.12, 215.0)
BRAND_SECONDARY_DARK        = UI::DesignTokens::Color.oklch(0.72, 0.13, 215.0)
```

Source of truth is OKLCH (`0.56, 0.13, 195°` light primary — deep teal, h ≈ 195°). The brief's "#0F8585" placeholder is approximate (15, 133, 133). The actual baked sRGB for `oklch(0.56, 0.13, 195)` will fall in the deep-teal family but will not exactly match `#0F8585`; Item 4 pixel-sampling will need to assert against the *resolved* sRGB of the OKLCH source (compute once via `Color.oklch(0.56, 0.13, 195.0)` and use that triple ± a tolerance), not against the brief's `(15, 133, 133)` literal.

### Other Cascade surfaces that touch brand identity

- `samples/initiative-cross-platform-ui-demo/screens/state.cr:23` — `property accent_color : UI::DesignTokens::Color = InitiativeDemo::BRAND_PRIMARY_LIGHT`. This is application state seeded from the brand constant; it does not consult `Tokens.default` and is insulated from the pivot.
- `samples/initiative-cross-platform-ui-demo/screens/sign_in.cr:94` — a comment about SwiftUI Link inheriting the brand-tint cascade; no code consequence.
- The iOS host (`ios/bridge.cr:74`) and Swift facade (`ios/Sources/CascadeBridge.swift`) are wired so that `cascade_init` runs before any `cascade_render`, and the renderer carries `InitiativeDemo.brand_tokens` on every call. No other token path exists.

### Cross-check: Voyager (the canary)

For contrast — the Voyager demo, which the pivot must shift visibly, does **not** call `.with_brand`:

- `samples/initiative-cross-platform-ui-voyager/macos/host.cr:86-89`: comment "Phase 6.11 Item 1 — brand override removed. Voyager runs on `UI::DesignTokens::Tokens.default`."
- `grep -rn "with_brand" samples/initiative-cross-platform-ui-voyager/` returns no matches.

So Voyager is the demo that picks up `Tokens.default`'s new sentinel-derived system accent (and renders system blue on iOS, controlAccentColor on macOS, `AccentColor` on web), while Cascade keeps deep teal via its explicit override.

## Disposition for Item 4

**Item 0 finding: Cascade applies its brand EXPLICITLY via `.with_brand(InitiativeDemo::DemoBrand.new)` in all three renderer entrypoints (macOS host.cr:58, web static_site.cr:27, iOS bridge.cr:74).**

Per brief Item 4 (lines 287-291), this means Item 4 is a **verification-only step**: Item 4 must run the Cascade builds post-pivot and assert that:

1. Web: generated HTML contains the resolved teal RGB (not `AccentColor`, not amber).
2. macOS: rendered prominent button background pixel-samples to the resolved teal ± tolerance.
3. iOS (if buildable): same pixel-sample assertion on the prominent button.

**No code change to Cascade is required by Item 4.** The Item 0 preflight has confirmed Cascade is insulated by construction.

## Unanticipated paths (per brief Hard rules: "If Cascade preflight reveals an unanticipated brand path, STOP and report")

None. The brand application is single-source (`InitiativeDemo.brand_tokens`), called explicitly from all three renderer entrypoints, with no fallback path that consults `Tokens.default.brand_primary` directly.

The only minor wrinkle is naming (the brief's `CascadeBrand` placeholder vs the actual `InitiativeDemo::DemoBrand`); this is purely cosmetic and called out above so subsequent Items use the correct identifier.

## Acceptance checklist (per brief lines 50-54)

- [x] Preflight doc committed at this path.
- [x] Cascade brand entrypoint identified by file:line (brand.cr:69-71 helper, plus three consumer call sites).
- [x] Implicit-default reliance: **NOT FOUND**. Item 4 reduces to verification-only.

## Next step

Iteration 2: Item 1 — implement `Color::SYSTEM_ACCENT` sentinel in `src/ui/design_tokens.cr`, pivot `Tokens.default` brand family, ship `spec/ui/design_tokens_default_accent_spec.cr`. Then Codex review committed at `phase-06.12a-codex-1.md`.
