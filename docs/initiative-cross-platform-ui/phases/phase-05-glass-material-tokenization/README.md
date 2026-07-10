# Phase 5 — Glass Material Tokenization

**Tier:** 1 + 2 (Brand-tunable platform-default treatment)
**Depends on:** Phase 1 (token system), Phase 3 (SwiftUI bridge owns the native glass surface)
**Blocks:** Phase 6 (demo app's glass screens)
**Estimated remediation budget:** 1 loop

---

## Why this phase exists

The current Glass / OS26 story:

- **iOS:** `UIVisualEffectView` + `UIBlurEffect` with system materials (ultra_thin, thin, regular, thick, chrome) — **works correctly** but the material strength is hard-coded in `uikit_renderer.cr`, not driven by a token.
- **macOS:** `NSVisualEffectView` with the same materials — **works correctly** but again hard-coded.
- **Web:** `backdrop-filter: blur(Xpx)` with hard-coded blur amounts (`:ultra_thin` → 10px) and a hard-coded 72% opacity color-mix. **Static approximation.** No fallback for browsers without `backdrop-filter`.
- **Android:** Placeholder — semi-transparent white `FrameLayout`. No actual blur even though API 31+ supports `RenderEffect.createBlurEffect`.

The user-visible consequence: the brand can't tune glass intensity (e.g., "make all glass surfaces in this app slightly more frosted") without editing renderer source. The web glass doesn't degrade gracefully. Android doesn't have glass at all.

This phase makes glass material strength a first-class token, wires it through all four renderers, and adds a brand-overridable intensity multiplier.

## Scope summary

In scope:

- New `DesignTokens::Material` subtype declaring:
  - The five material strength steps (`ultra_thin`, `thin`, `regular`, `thick`, `chrome`).
  - Per-step **blur radius** (in points/pixels), **opacity**, **saturation boost**, **luminance** baseline.
  - An `intensity` scalar (default 1.0) that scales blur and opacity globally — the brand override knob.
- Renderer wiring:
  - `uikit_renderer.cr` and `appkit_renderer.cr`: pass the resolved material parameters into the SwiftUI bridge facade for `GlassBackground`. SwiftUI side applies `.background(.regularMaterial)` or `.background(Material(...))` with overrides where the brand intensity adjusts.
  - `web_renderer.cr`: emit `backdrop-filter: blur(var(--ap-material-blur-{step}))` with the variable computed from `tokens.material.blur * tokens.material.intensity`. Add `-webkit-` prefix. Add fallback color for browsers without `backdrop-filter` (detected via `@supports not (backdrop-filter: blur(1px))`).
  - `android_renderer.cr`: on API 31+, use `RenderEffect.createBlurEffect(radius, radius, TileMode.CLAMP)` with radius from the token. Below API 31, semi-transparent fill with the token's opacity value.
- Brand override demo. A sample theme file shows how to declare `material.intensity = 1.3` for a more frosted look and verify the change cascades to all four platforms.
- Specs:
  - Token resolution math (blur step × intensity → final radius).
  - Web CSS emission (correct `clamp` / `var()` references, `@supports` fallback present).
  - Native renderer: verify the SwiftUI facade receives the resolved material params, not hard-coded constants.
  - Android: verify the API-31 branch and the fallback branch both compile and produce reasonable visual output.

Out of scope:

- Adding new material steps beyond the five. The five are sufficient for parity with iOS/macOS system materials.
- Animated material transitions (e.g., glass "fluidifying" when scrolled over). The user can declare a motion token to animate intensity, but the renderers in this phase don't do animation orchestration.
- Replacing the existing `GlassBackground` widget API. The widget keeps its current `material : Symbol` property; the symbol now resolves through the token system instead of being hard-coded in renderers.

## Acceptance summary

Phase 5 is done when:

- Setting `material.intensity` on the brand declaration changes the visible glass strength on all four platforms — verified by screenshot diff.
- Web glass uses `@supports` fallback correctly: in a browser without `backdrop-filter` (test by overriding the support check), the surface falls back to the documented solid color with appropriate opacity.
- Android sample app on API 31+ shows a real blur. On API 30 and below, shows the semi-transparent fallback.
- iOS 26+ Liquid Glass still appears for `GlassBackground` views — token wiring did not regress the existing-working behavior.
- Spec suite passes.

Detailed checks in `validation.md`.

## Risk notes

- **Web `backdrop-filter` performance** can be poor on stacked layers. The renderer should not double-apply backdrop-filter (e.g., a glass surface inside another glass surface — the inner one inherits the parent's already-blurred content). Validator should check stacking.
- **iOS `Material` vs `BlurEffect`:** SwiftUI's `Material` (introduced iOS 15) is the modern API; older code used `UIBlurEffect`. The SwiftUI bridge should prefer `Material`. iOS 26 Liquid Glass appears automatically on `Material`-based surfaces.
- **Android `RenderEffect`:** must be applied to the View at the JNI bridge level. The Crystal-side abstraction calls into a Java helper.
- **Intensity scaling is multiplicative, not additive.** `intensity: 0.5` halves blur radius; `intensity: 2.0` doubles it. Document this clearly so brands don't accidentally over-frost.

## Briefing documents

- **Phase Brief (YAML, validator-enforced):** `brief.yml` — passes `crystal run scripts/validate_phase_brief.cr -- phases/phase-05-glass-material-tokenization/brief.yml` (exit 0 mandatory before dispatch). Declares all 11 invariant cells, lower-layer assumptions about SwiftUI Material API + backdrop-filter support + Android RenderEffect, repo-derived facts (37 GlassBackground references, 2 backdrop-filter sites in web_renderer.cr, 35311-byte design_tokens.cr), and 3 adapter cardinality MISMATCH rows for SwiftUI's discrete material enum, web `@supports` fallback, and Android < API 31 fallback. Architect-authored 2026-05-22 per `handoff/planning-retrospective-2026-05-22.md` Phase Brief Template.
- Implementer: `implementation.md`
- Validator: `validation.md`
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`

## Class-init prerequisite (per stock-taking 2026-05-22)

Phase 5 introduces token VALUES held in existing `Tokens` struct instances, NOT new Crystal class variables with initializers. Per `memory/project_crystal_ios_class_init_gap.md`, this means Phase 5 should NOT trigger the iOS class-init silent-nil pattern. If the Implementer discovers they need a new class var on iOS-bound code, **stop and surface to architect** — class-init systematic fix is deferred to a future phase, but per-feature workarounds (explicit `.reset` in `hig_bridge.cr#initialize_runtime`) must be applied for any new singleton state.
