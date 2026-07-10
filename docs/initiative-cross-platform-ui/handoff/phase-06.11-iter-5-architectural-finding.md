# Phase 6.11 Iter 5 — Architectural Finding (Surfaced to Architect)

**Date:** 2026-05-24
**Discovered by:** Architect, post-Codex-3 + post-Codex critique of iter-5 brief
**Status:** Awaiting owner decision on scope

## The finding

Phase 6.11 Item 1 deleted Voyager's `brand.cr` (the VoyagerBrand indigo override). The iter-4 recapture revealed Cancel buttons still render in amber/tan, not SwiftUI default blue, in BOTH light and dark appearance.

Investigation traces this to a library-level brand cascade:

```
1. UIKit renderer (src/ui/renderers/uikit_renderer.cr:4109-4112):
     brand = @design_tokens.colors_light.brand_primary
     LibSwiftKitBridge.apsk_runtime_set_brand_tint(
       brand.r, brand.g, brand.b, brand.alpha,
     )
   → Called on EVERY render. No conditional.

2. Voyager uses Tokens.default (no .with_brand(...) since iter-1).

3. Tokens.default.colors_light.brand_primary returns the LIBRARY's default
   amber/tan — set at the design-token level long before Phase 6.11.

4. CallbackBridge.swift caches this as APSKRuntime.brandTint.

5. HostingHelpers.host applies `.tint(amber)` to every hosted SwiftUI root.

6. SwiftUI's `.bordered` / `.tinted` button chrome resolves against the
   environment tint → Cancel button renders amber.
```

**Phase 6.11 Item 1 only stripped the CONSUMER-side override.** It didn't address that `Tokens.default` itself has an opinionated brand the renderer dutifully installs.

## What "stick with SwiftUI defaults" actually requires

The owner directive cannot be honored at the consumer level alone — the library's iOS renderer is the source of the brand cascade. To get a Voyager that looks like SwiftUI-default iOS, one of these architectural choices must land:

### Option A: `Tokens.default` carries no brand
- `brand_primary` becomes `Color?` (nilable).
- `Tokens.default.colors_light.brand_primary == nil` for the unbranded library default.
- Renderer only calls `apsk_runtime_set_brand_tint(...)` when brand_primary is non-nil.
- Consumers who want a brand provide one via `Tokens.default.with_brand(...)`.
- **Cost:** widest refactor — propagates through Crystal types + all design-token consumers (web, macOS, iOS, Android). Affects Cascade demo which DOES have a brand.
- **Benefit:** cleanest semantic — "default = system, brand = opt-in." Owner directive honored at the right layer.

### Option B: Per-consumer opt-out
- Voyager's iOS bridge calls `apsk_runtime_clear_brand_tint` after every render.
- Other consumers (Cascade, future apps) keep getting the library's amber unless they also opt out.
- **Cost:** ~3 lines in `samples/.../voyager/ios/bridge.cr`. Mid-render or post-render hook required.
- **Benefit:** ships in minutes. Doesn't disturb other consumers.
- **Drawback:** doesn't change the library's "amber-by-default" identity. Future consumers who want SwiftUI defaults have to know this and opt out. Owner directive only honored for Voyager, not library-wide.

### Option C: Tokens.default uses iOS system accent (system blue)
- Library's `Tokens.default.brand_primary` changes from amber to a value that semantically resolves to "system accent" on each platform.
- On iOS: tint installed = `Color.accentColor` (system blue).
- On macOS: tint installed = `NSColor.controlAccentColor` (system blue).
- On web: tint = `-apple-system-blue` or a CSS system color.
- **Cost:** medium — requires platform-aware brand_primary resolution.
- **Benefit:** library default tracks each platform's accent without losing the brand-cascade infrastructure.
- **Drawback:** loses the asset_pipeline visual identity. Library no longer has "an amber look."

### Option D: Defer
- Phase 6.11 closes PASS_WITH_NOTES with this finding documented.
- Phase 6.12 takes the architectural pivot alongside macOS polish.
- **Cost:** zero immediate.
- **Drawback:** Voyager hand-test will still show amber Cancel buttons. Owner directive remains visibly unmet.

## Owner decision required

Which option above? This is bigger than an Implementer dispatch — it's a library-identity question.

— Architect
