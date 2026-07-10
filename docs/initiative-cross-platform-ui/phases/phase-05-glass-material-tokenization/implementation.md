
# Phase 5 — Implementation Brief: Glass Material Tokenization

**Audience:** Implementer agent (single execution).
**Read also:** `README.md` (this folder), `../../rubric/implementation_criteria.md`, `validation.md` (this folder — to anticipate what the validator will check), Phase 1 + Phase 3 READMEs.

---

## Goal

Promote glass material strength from hard-coded per-renderer constants to a first-class branch of the `UI::DesignTokens` system. Wire every renderer — web, AppKit, UIKit, and Android — to read material parameters from the resolved token tree. Add a brand-overridable `intensity` scalar so a single line in a brand declaration uniformly scales how frosted glass surfaces appear on all four platforms. Add a `@supports` fallback for web browsers without `backdrop-filter`. Add a real `RenderEffect.createBlurEffect` path on Android API 31+ with a graceful pre-API-31 fallback.

After this phase, no renderer file contains a hard-coded blur radius or material constant for `GlassBackground` (or for any other glass-using widget — see deviation prompt below). All of those values flow from `tokens.material`. A brand declaration in `samples/cross_platform/` can change `material.intensity` to `1.3` and produce visibly more frosted glass on all four platforms with no other code changes.

---

## Pre-reading checklist

Before writing any code, the implementer must read:

- [ ] `README.md` (this folder) — scope and risk notes.
- [ ] `../phase-01-design-token-foundation/README.md` — token system shape and brand override mechanism.
- [ ] `../phase-03-swiftui-native-bridge/README.md` — the `AssetPipelineSwiftKit` package and the `Overrides` struct pattern the bridge uses.
- [ ] `../../rubric/implementation_criteria.md` — universal standards (commit cadence, Crystal style, doc comments, branch).
- [ ] `src/ui/views/glass_background.cr` — the widget. Note that `material : Symbol` is the public API; that does not change in this phase.
- [ ] `src/ui/renderers/web_renderer.cr` lines 1335–1359 — current `GlassBackground` visit. Read also line 1786 (toast) for the existing solid-fallback color pattern.
- [ ] `src/ui/renderers/uikit_renderer.cr` lines 3068–3117 — current `GlassBackground` visit. Read also lines 1228–1300, 1463–1530, 2380–2480, 2489–2560, 2620–2740, 2776–2870 — every other glass-using widget. (See **Deviation prompt** below.)
- [ ] `src/ui/renderers/appkit_renderer.cr` lines 2731–2774 — current `GlassBackground` visit. Read also lines 1051–1100, 1261–1420, 2005–2100, 2154–2210, 2302–2400, 2428–2500 for sibling glass widgets.
- [ ] `src/ui/renderers/android_renderer.cr` lines 2154–2189 — current placeholder.
- [ ] `validation.md` (this folder) — what the validator will check.

If the token system or SwiftUI bridge code differs substantially from what the Phase 1 and Phase 3 READMEs describe (e.g., the type is named differently, the `Overrides` struct uses a different file convention), surface that to the team lead before continuing. See "When the brief is wrong" in `implementation_criteria.md`.

---

## Existing infrastructure to use (vs. rebuild)

Phase 5 is the smallest implementation surface in the initiative — it threads one new token branch (`Material`) through four renderers. Almost everything you need is already in place from Phases 1 and 3.

### Crystal source you extend

- `src/ui/design_tokens.cr` — Phase 1's source-of-truth. You add a `material : Material` getter on the `Tokens` aggregate. Do not redefine the namespace.
- `src/ui/views/glass_background.cr` — the widget. `material : Symbol` public API is unchanged.
- `src/ui/renderers/web_renderer.cr` (lines 1335–1359 + 1786) — `GlassBackground` visit + toast solid fallback pattern.
- `src/ui/renderers/uikit_renderer.cr` (lines 3068–3117 + the other glass-using visit methods listed in the Deviation prompt).
- `src/ui/renderers/appkit_renderer.cr` (lines 2731–2774 + sibling glass methods).
- `src/ui/renderers/android_renderer.cr` (lines 2154–2189 placeholder).
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift` — Phase 3's overrides class. Extend it with `intensity`, `blurDelta`, `opacityOverride`, `saturationOverride` fields per §SwiftUI bridge contract. If the file does not exist, Phase 3 has not landed — **stop and return early**.
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift` — existing facade. Extend the `make*` signature to accept the new override fields.

### Crystal source you create

- `src/ui/design_tokens/material.cr` — the new `Material` type and `Step` substruct.
- `spec/ui/design_tokens/material_spec.cr`, `spec/ui/design_tokens/web_generator_material_spec.cr`, four renderer-specific specs (`spec/ui/renderers/{web,uikit,appkit,android}_glass_spec.cr`).
- `samples/cross_platform/glass_intensity_demo.cr` — the cross-platform intensity demo used by validator checks 1–6.

### Bridge naming reconciliation (cross-phase ambiguity flagged by prior audit)

The prior audit (`handoff/plan-quality-audit-2026-05-20.md` §A) noted that Phase 5 references `LibSwiftKitBridge.material_parameters_new(...)` and `LibSwiftKitBridge.glass_background_overrides_new(...)`, but Phase 3 ships a `lib LibObjCBridge` plus a `SwiftKit` Crystal module — `LibSwiftKitBridge` was never explicitly named. Phase 3's revised "Existing infrastructure to use" section now creates `src/ui/native/lib_swiftkit_bridge.cr` as the typed wrapper. **Phase 5 references the same module — if you find `LibSwiftKitBridge` is not defined when you start Phase 5, the Phase 3 implementer did not ship the typed wrapper they were supposed to. Surface this to the team lead before freelancing.** The cross-phase naming contract is `LibSwiftKitBridge` (typed wrapper, defined in `src/ui/native/lib_swiftkit_bridge.cr`); do not coin a new name.

### Pinned conventions

| Convention | Value | Notes |
|---|---|---|
| Material step set | `:ultra_thin, :thin, :regular, :thick, :chrome` | Five steps. Must match what `GlassBackground#material` accepts. |
| Intensity scalar | `Float64`, default `1.0`, brand-overridable | Multiplies `blur_radius` only. |
| CSS variable prefix | `--ap-material-*` | Inherited from Phase 1's `--ap-*` standard. No `--amber-material-*` aliases. |
| AppKit material translation marker | `# AppKit material translation table — only allowed hard-coded glass switch` | **Exact text required**, em dash `—`. Validator check 8 enforces. |
| Android API gate | 31+ for `RenderEffect.createBlurEffect`, ≤ 30 fallback | Both paths invoke `AssetPipelineGlassHelper.applyGlass`. |
| `@supports` fallback opacity | 94% on `regular` tier (per phase brief) | Used when neither `backdrop-filter` nor `-webkit-backdrop-filter` are supported. |

### What is genuinely new vs. extended

| New | Extended |
|---|---|
| `src/ui/design_tokens/material.cr` | `src/ui/design_tokens.cr` (add `material` getter on `Tokens`) |
| `spec/ui/design_tokens/material_spec.cr` + 4 renderer-specific glass specs | `src/ui/renderers/{web,uikit,appkit,android}_renderer.cr` (token-driven glass) |
| `samples/cross_platform/glass_intensity_demo.cr` | `swift/AssetPipelineSwiftKit/.../Overrides/GlassBackgroundOverrides.swift`, `Facades/GlassBackgroundFacade.swift` |
| `AssetPipelineGlassHelper.java` (Android API 31+ blur helper) | `src/ui/native/lib_swiftkit_bridge.cr` (from Phase 3, extended for material params) |

---

## Deviation prompt — read carefully before starting

The Phase 5 scope in `README.md` names `GlassBackground` as the widget being tokenized. However, the existing Apple renderers hard-code `NSVisualEffectMaterial` / `UIBlurEffectStyle` constants inside the visit methods for **TabView, Alert, Sidebar (NavigationSplitView), Toolbar, Sheet, and Popover** as well. If Phase 5 only tokenizes the `GlassBackground` visit, brand `material.intensity = 1.3` will not cascade to those other glass surfaces — only to the ones the developer explicitly wraps in `GlassBackground`. That is almost certainly the wrong behavior for a brand-cascade phase.

**Required action:** Extend the refactor to every visit method that today calls `setMaterial:` with a hard-coded constant. The resolution path is identical to `GlassBackground` — pick the semantic material name (`:popover`, `:sheet`, `:sidebar`, `:toolbar`, etc.), look it up in the token tree, pass the resolved parameters to the renderer call.

If during implementation you discover this would balloon the diff beyond a reasonable single-phase scope (more than ~12 visit methods to refactor), **stop and return** to the team lead with what you found rather than picking an arbitrary subset.

---

## `DesignTokens::Material` type specification

Add a new subtype under the existing `UI::DesignTokens` namespace (Phase 1's deliverable). File: `src/ui/design_tokens/material.cr`.

### Type declaration

```crystal
module UI
  class DesignTokens
    # Glass material parameters.
    #
    # A `Material` value declares the five strength steps that map to the
    # public `GlassBackground#material` symbol values, plus a global
    # `intensity` scalar that brands use to dial the frosted look up or
    # down uniformly.
    #
    # `intensity` multiplies `blur_radius` only — opacity, saturation, and
    # luminance are unaffected. Brands that need to skew the look further
    # should override individual `MaterialStep` fields directly.
    class Material
      # One material strength step.
      struct Step
        # Blur kernel radius in points (Apple) / device-independent pixels (Android)
        # / CSS pixels (web). Apple and web treat 1pt ≈ 1 CSS px at 1× rasterization;
        # Android applies the same value as the RenderEffect radius argument.
        getter blur_radius : Float64

        # Tint opacity applied to the surface fill (`color-mix` percentage on web,
        # alpha component on Android, automatic on Apple where the system material
        # controls its own opacity).
        getter opacity : Float64

        # Saturation multiplier applied to backdrop content. 1.0 = neutral.
        # Web emits as a second `backdrop-filter` argument (`saturate(N)`); Apple
        # ignores (system material handles saturation); Android ignores at API 31+
        # (RenderEffect saturation is a separate effect — out of scope for Phase 5).
        getter saturation_boost : Float64

        # Baseline luminance shift in the [-1.0, 1.0] range. Negative = darker.
        # Used by the fallback paths (web `@supports` fallback, Android pre-31)
        # to bias the fallback fill color.
        getter luminance : Float64

        # The integer constant the AppKit/UIKit renderer passes to
        # `setMaterial:` / `effectWithStyle:`. Wrapped in the token so the
        # mapping is one source of truth, not duplicated across visit methods.
        getter apple_material_constant : Int64

        def initialize(
          @blur_radius : Float64,
          @opacity : Float64,
          @saturation_boost : Float64,
          @luminance : Float64,
          @apple_material_constant : Int64,
        )
        end
      end

      getter ultra_thin : Step
      getter thin       : Step
      getter regular    : Step
      getter thick      : Step
      getter chrome     : Step

      # Multiplicative intensity scalar applied to every step's `blur_radius`
      # at resolution time. Brands typically set this in the [0.5, 1.5] range.
      # Clamped at resolution to [0.1, 3.0] to keep web/Android numerically sane.
      property intensity : Float64

      def initialize(
        @ultra_thin : Step,
        @thin       : Step,
        @regular    : Step,
        @thick      : Step,
        @chrome     : Step,
        @intensity  : Float64 = 1.0,
      )
      end

      # Returns the `Step` for a symbol. Raises if the symbol is unknown.
      def step(name : Symbol) : Step
        case name
        when :ultra_thin then ultra_thin
        when :thin       then thin
        when :regular    then regular
        when :thick      then thick
        when :chrome     then chrome
        else raise ArgumentError.new("Unknown material step: #{name}")
        end
      end

      # Resolves a step + intensity into a concrete `ResolvedStep`.
      # Renderers consume this struct only.
      def resolve(name : Symbol) : ResolvedStep
        s = step(name)
        clamped = intensity.clamp(0.1, 3.0)
        ResolvedStep.new(
          name: name,
          blur_radius:     s.blur_radius * clamped,
          opacity:         s.opacity,
          saturation_boost: s.saturation_boost,
          luminance:       s.luminance,
          apple_material_constant: s.apple_material_constant,
        )
      end
    end

    # Output of `Material#resolve` — what renderers actually consume.
    record ResolvedStep,
      name : Symbol,
      blur_radius : Float64,
      opacity : Float64,
      saturation_boost : Float64,
      luminance : Float64,
      apple_material_constant : Int64
  end
end
```

### Default values

Calibrated to preserve existing visual behavior at `intensity = 1.0`. These are the published defaults; brands override by reassigning fields.

| Step       | blur_radius (pt/px) | opacity | saturation_boost | luminance | apple_material_constant |
|------------|--------------------:|--------:|-----------------:|----------:|-----------------------:|
| ultra_thin |                10.0 |    0.20 |             1.05 |      0.00 |  8 (UIBlurEffectStyleSystemUltraThinMaterial / NSVisualEffectMaterialUltraLight=9 — see note) |
| thin       |                20.0 |    0.40 |             1.10 |      0.00 |  9 (UIBlurEffectStyleSystemThinMaterial) |
| regular    |                30.0 |    0.60 |             1.15 |      0.00 | 10 (UIBlurEffectStyleSystemMaterial) |
| thick      |                40.0 |    0.73 |             1.20 |      0.00 | 11 (UIBlurEffectStyleSystemThickMaterial) |
| chrome     |                50.0 |    0.87 |             1.25 |      0.00 | 12 (UIBlurEffectStyleSystemChromeMaterial) |

**Note on `apple_material_constant`:** UIKit and AppKit use **different** integer constants for the same semantic material (UIKit `systemMaterial = 10` is the AppKit `windowBackground = 12`'s rough equivalent, not the same number). The token stores the **UIKit** value as canonical; the AppKit renderer applies a small fixed translation table at the call site.

**Mandatory marker comment.** The AppKit translation table is the only place in `appkit_renderer.cr` where it is allowed to hard-code an integer material constant (or a small switch over them). To make the exception unambiguous to grep-based validator checks, the translation table block in `appkit_renderer.cr` MUST be wrapped with a marker comment ON THE LINE IMMEDIATELY ABOVE the block:

```crystal
# AppKit material translation table — only allowed hard-coded glass switch
case uikit_constant
when 10 then NS_VISUAL_EFFECT_MATERIAL_WINDOW_BACKGROUND   # systemMaterial
when 11 then NS_VISUAL_EFFECT_MATERIAL_HUD                  # thinMaterial
# ...
end
```

The marker text is exactly `# AppKit material translation table — only allowed hard-coded glass switch` (em dash `—`, not `--`). Phase 5's validation check `material.no-hardcoded-blur-or-material` (check #22 in `validation.md`) greps for this string and skips the immediately-following case/switch block when counting hard-coded constants. Any other place in the codebase using hard-coded `NSVisualEffectMaterial*` / `UIBlurEffectStyle*` integers without this marker is a phase-5 regression.

---

## Token resolution math

```
final_blur_radius = step.blur_radius * tokens.material.intensity.clamp(0.1, 3.0)
```

Examples (using the default `regular` step's `30.0` radius):

| `intensity` | clamped | final blur radius |
|------------:|--------:|------------------:|
|         0.0 |     0.1 |               3.0 |
|         0.5 |     0.5 |              15.0 |
|         1.0 |     1.0 |              30.0 |
|         1.3 |     1.3 |              39.0 |
|         1.5 |     1.5 |              45.0 |
|         2.0 |     2.0 |              60.0 |
|         5.0 |     3.0 |              90.0 |

`opacity`, `saturation_boost`, and `luminance` are **not** scaled. Brands that want a more opaque glass should override those fields per-step in their brand declaration.

---

## SwiftUI bridge contract

Phase 3 introduces the `AssetPipelineSwiftKit` Swift package with the `Overrides` struct pattern (see Phase 3 README for `ButtonOverrides`). Phase 5 adds a sibling struct specifically for material parameters.

### Swift side — `MaterialParameters`

In `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/GlassBackground.swift`:

```swift
@objc public class MaterialParameters: NSObject {
    @objc public let blurRadius: Double
    @objc public let opacity: Double
    @objc public let saturationBoost: Double
    @objc public let luminance: Double
    @objc public let appleMaterialConstant: Int64

    @objc public init(blurRadius: Double,
                      opacity: Double,
                      saturationBoost: Double,
                      luminance: Double,
                      appleMaterialConstant: Int64) {
        self.blurRadius = blurRadius
        self.opacity = opacity
        self.saturationBoost = saturationBoost
        self.luminance = luminance
        self.appleMaterialConstant = appleMaterialConstant
        super.init()
    }
}

@objc public class GlassBackgroundFacade: NSObject {
    @objc public static func make(
        material: MaterialParameters,
        overrides: GlassBackgroundOverrides
    ) -> PlatformView {
        // Prefer SwiftUI Material (iOS 15+ / macOS 12+). iOS 26+ Liquid Glass
        // appears automatically on Material-based surfaces. We pick the
        // SwiftUI Material variant by mapping the integer constant the
        // Crystal side passes in.
        let m: Material = materialFromConstant(material.appleMaterialConstant)
        var view: AnyView = AnyView(
            Color.clear
                .background(m)
        )
        if material.blurRadius != defaultBlurFor(material.appleMaterialConstant) {
            // Brand has scaled intensity off the default — apply an extra
            // .blur() modifier on top of the system Material to reach the
            // requested radius. Doing this preserves iOS 26 Liquid Glass
            // (Material) while letting the brand dial blur up or down.
            let delta = material.blurRadius - defaultBlurFor(material.appleMaterialConstant)
            view = AnyView(view.blur(radius: delta))
        }
        // Apply overrides (corner radius, padding, etc.) — same pattern as
        // ButtonOverrides in Phase 3.
        if let cr = overrides.cornerRadius {
            view = AnyView(view.clipShape(RoundedRectangle(cornerRadius: cr)))
        }
        // ... etc.
        #if os(iOS)
        return UIHostingController(rootView: view).view
        #else
        return NSHostingController(rootView: view).view
        #endif
    }
}
```

Notes for the implementer:

- `materialFromConstant(_:)` is a small switch mapping the canonical UIKit integer to the appropriate SwiftUI `Material` case (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`, `.chromeMaterial`).
- `defaultBlurFor(_:)` returns the same radius value as the token default for that step (10, 20, 30, 40, 50). Hard-coding it inside the Swift package is acceptable — it's a constant derived from Apple's published material specs, not a brand value. Document the duplication and reference the token file by path in a code comment.
- The "scale via additional `.blur()` modifier" approach is a deliberate trade. SwiftUI's `Material` doesn't expose a radius knob. To respect both Apple's Liquid Glass (on iOS 26+) **and** brand intensity, we layer a plain `.blur()` modifier *on top* with the delta. At `intensity = 1.0` the delta is zero so no additional blur is applied and Liquid Glass is unmodified. At `intensity = 1.3` an extra ~9pt blur is layered on. The validator confirms iOS 26 Liquid Glass is still visible at default intensity.

### Crystal side — calling into the bridge

In `src/ui/renderers/uikit_renderer.cr` (replacing lines 3071–3117):

```crystal
def visit(view : UI::GlassBackground)
  resolved = tokens.material.resolve(view.material)
  material_params = LibSwiftKitBridge.material_parameters_new(
    resolved.blur_radius,
    resolved.opacity,
    resolved.saturation_boost,
    resolved.luminance,
    resolved.apple_material_constant,
  )
  overrides = LibSwiftKitBridge.glass_background_overrides_new(
    corner_radius: view.corner_radius,
    # ...
  )
  ptr = LibSwiftKitBridge.glass_background_facade_make(material_params, overrides)
  handle = ObjC.owned(ptr, label: "GlassBackgroundFacade")
  native = NativeView.new(handle)

  if content = view.content
    push_stack(native, is_uistack: false)
    content.accept(self)
    pop_stack
  end
  push_native(native)
end
```

The AppKit renderer mirrors this exactly, swapping `LibSwiftKitBridge.glass_background_facade_make` for the `NSHostingController`-returning Mac variant.

**Bridge surface origin.** `LibSwiftKitBridge` is the typed Crystal `lib` block introduced in Phase 3 §7.4 (`src/ui/native/swiftkit_bridge.cr`). Every `LibSwiftKitBridge.*` call in this phase resolves against the `fun` declarations Phase 3 ships:

- `LibSwiftKitBridge.material_parameters_new(...)` — Phase 3 §7.4 already declares this `fun` as part of the Phase 5 hand-off (`fun material_parameters_new : Void*` plus the per-step setter pattern, with the actual fields populated by Phase 5 setter helpers).
- `LibSwiftKitBridge.glass_background_overrides_new(...)` — declared in Phase 3 §7.4 as part of the standard per-widget overrides constructors.
- `LibSwiftKitBridge.glass_background_facade_make(material_params, overrides)` — declared in Phase 3 §7.4 with signature `fun glass_background_facade_make(material_params : Void*, overrides : Void*) : Void*`. The glass surface is created bare; the child view is attached as a subview by the visitor after the facade call (see the code snippet above). Phase 5 does not need to extend this signature — Phase 3 already declares it in the agreed form.

Phase 5 does not introduce a new `lib` block. All Crystal-side calls go through Phase 3's `LibSwiftKitBridge`. If a `fun` Phase 5 needs is missing from Phase 3's declarations, add it to `src/ui/native/swiftkit_bridge.cr` (the file Phase 3 created) and the C trampoline in `swiftkit_bridge.m`. Document each addition in this phase's handoff under "Bridge additions".

---

## Web emission contract

The web renderer no longer hard-codes blur radii or opacity. It reads the resolved step from the token tree and emits CSS that references `var(--ap-material-blur-{step})` custom properties, plus a `@supports` fallback block.

### Custom property emission (one-time, in the stylesheet root)

The CSS generator (Phase 1's `DesignTokens::WebGenerator`) emits these on the `:root` selector. Phase 5 extends the generator to include the material block:

```css
:root {
  /* ... existing tokens ... */

  --ap-material-blur-ultra-thin: calc(10px * var(--ap-material-intensity, 1));
  --ap-material-blur-thin:       calc(20px * var(--ap-material-intensity, 1));
  --ap-material-blur-regular:    calc(30px * var(--ap-material-intensity, 1));
  --ap-material-blur-thick:      calc(40px * var(--ap-material-intensity, 1));
  --ap-material-blur-chrome:     calc(50px * var(--ap-material-intensity, 1));

  --ap-material-opacity-ultra-thin: 0.20;
  --ap-material-opacity-thin:       0.40;
  --ap-material-opacity-regular:    0.60;
  --ap-material-opacity-thick:      0.73;
  --ap-material-opacity-chrome:     0.87;

  --ap-material-saturation-ultra-thin: 1.05;
  --ap-material-saturation-thin:       1.10;
  --ap-material-saturation-regular:    1.15;
  --ap-material-saturation-thick:      1.20;
  --ap-material-saturation-chrome:     1.25;

  --ap-material-intensity: 1;  /* overridden by brand */
}
```

### Per-instance emission (inside `visit(view : UI::GlassBackground)`)

For a `GlassBackground.new(material: :regular)`, the visitor produces:

```html
<div class="ap-glass ap-glass--regular" style="…">…</div>
```

with the inline style block:

```css
backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular));
-webkit-backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular));
background: color-mix(in oklch,
  var(--ap-color-surface-panel)
    calc(var(--ap-material-opacity-regular) * 100%),
  transparent);
border-radius: inherit;
```

### `@supports` fallback block

Emitted once in the stylesheet root by the generator. Targets browsers where `backdrop-filter` is unsupported (no Safari/WebKit prefix path either):

```css
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .ap-glass--ultra-thin { background: color-mix(in oklch, var(--ap-color-surface-panel) 90%, transparent); }
  .ap-glass--thin       { background: color-mix(in oklch, var(--ap-color-surface-panel) 92%, transparent); }
  .ap-glass--regular    { background: color-mix(in oklch, var(--ap-color-surface-panel) 94%, transparent); }
  .ap-glass--thick      { background: color-mix(in oklch, var(--ap-color-surface-panel) 96%, transparent); }
  .ap-glass--chrome     { background: color-mix(in oklch, var(--ap-color-surface-panel) 98%, transparent); }
}
```

The fallback uses higher opacity (90–98%) than the live values because without backdrop blur, a low-opacity fill reads as transparent muddiness rather than as a glass surface. The fallback aims to communicate "this is a panel" — not to fake the glass effect.

### Class name emission

Add `ap-glass` and `ap-glass--{step}` classes to the emitted `<div>`. Inline style still wins for the live `backdrop-filter` value; the class selectors exist for the `@supports` fallback to bind to. Do **not** delete the inline style — older user agents that don't support `@supports` need the inline form to render the live path.

---

## Android implementation

The `RenderEffect.createBlurEffect` API exists on `android.view.View` from API 31 (Android 12). Below that, no real blur is available. Phase 5 wires both paths via a Java helper invoked over JNI.

### Java helper

New file: `samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java`

```java
package com.assetpipeline.glass;

import android.graphics.RenderEffect;
import android.graphics.Shader;
import android.os.Build;
import android.view.View;

public final class AssetPipelineGlassHelper {

    private AssetPipelineGlassHelper() {}

    /**
     * Applies a frosted-glass effect to {@code view}.
     *
     * @param view        the View receiving the effect (typically a FrameLayout
     *                    wrapping the glass content)
     * @param blurRadius  blur kernel radius in device-independent pixels
     * @param fallbackArgb 32-bit ARGB color used as background fill on API 30
     *                    and below (or if RenderEffect creation fails)
     * @return true if a real RenderEffect blur was applied; false if the
     *         fallback solid fill was used
     */
    public static boolean applyGlass(View view, float blurRadius, int fallbackArgb) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                RenderEffect effect = RenderEffect.createBlurEffect(
                        blurRadius, blurRadius, Shader.TileMode.CLAMP);
                view.setRenderEffect(effect);
                return true;
            } catch (Throwable t) {
                // Fall through to fallback fill.
            }
        }
        view.setBackgroundColor(fallbackArgb);
        return false;
    }
}
```

### Crystal-side call

In `src/ui/renderers/android_renderer.cr` (replacing the placeholder body at lines 2162–2189):

```crystal
def visit(view : UI::GlassBackground)
  resolved = tokens.material.resolve(view.material)

  fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)

  # Fallback ARGB: surface color at the step's opacity.
  fallback_argb = compose_argb(
    tokens.colors.surface_panel,
    resolved.opacity,
    resolved.luminance,
  )

  LibAndroidBridge.android_call_static_glass_helper(
    @env,
    "com/assetpipeline/glass/AssetPipelineGlassHelper",
    "applyGlass",
    fl,
    resolved.blur_radius.to_f32,
    fallback_argb.to_i32,
  )

  apply_common_properties(fl, view)

  global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
  handle = JNI.wrap_global(global_fl, label: "FrameLayout[glass]")
  native = NativeView.new(handle)

  if content = view.content
    push_stack(native, fl, is_linear: false)
    content.accept(self)
    pop_stack
  end

  push_native(native, fl)
end
```

`android_call_static_glass_helper` is a new entry point in the JNI bridge layer (`src/lib_android_bridge.cr`). It performs `GetStaticMethodID` + `CallStaticBooleanMethod` for the helper signature `(Landroid/view/View;FI)Z`. If the project already has a generic static-call entry, reuse it instead of adding a specialized wrapper.

`compose_argb` is a small helper (add to `src/ui/design_tokens/color.cr` if not already there) that takes an OKLCH color, an opacity, and a luminance bias and returns a packed `Int32` ARGB value. The luminance value comes from the token; for the published defaults it is `0.0`, so the helper is a no-op on default brands.

---

## macOS native wiring

The current `appkit_renderer.cr` `visit(view : UI::GlassBackground)` (lines 2734–2774) hard-codes a switch on `view.material` to an integer `NSVisualEffectMaterial` constant. After Phase 5 it becomes:

```crystal
def visit(view : UI::GlassBackground)
  resolved = tokens.material.resolve(view.material)

  # The token stores the UIKit-canonical constant. The AppKit equivalent is
  # different; this small table is the one place in the codebase that owns the
  # UIKit <-> AppKit material translation.
  appkit_material = case resolved.apple_material_constant
                    when 8_i64  then 9_i64   # ultraThin  -> UltraLight
                    when 9_i64  then 2_i64   # thin       -> Light
                    when 10_i64 then 12_i64  # regular    -> WindowBackground
                    when 11_i64 then 1_i64   # thick      -> Medium
                    when 12_i64 then 3_i64   # chrome     -> Titlebar
                    else             12_i64
                    end

  material_params = LibSwiftKitBridge.material_parameters_new(
    resolved.blur_radius,
    resolved.opacity,
    resolved.saturation_boost,
    resolved.luminance,
    appkit_material,
  )
  overrides = LibSwiftKitBridge.glass_background_overrides_new(
    corner_radius: view.corner_radius,
  )
  ptr = LibSwiftKitBridge.glass_background_facade_make_macos(material_params, overrides)
  handle = ObjC.owned(ptr, label: "GlassBackgroundFacade[macos]")
  native = NativeView.new(handle)

  if content = view.content
    push_stack(native, is_nsstack: false)
    content.accept(self)
    pop_stack
  end
  push_native(native)
end
```

The Swift side's `GlassBackgroundFacade` `make` function is parameterized on the platform via `#if os(...)`. The same struct fields drive both iOS and macOS code paths.

---

## Step-by-step plan (commit-sized chunks)

The implementer should plan to produce roughly 8 commits on the phase branch `phase-05-glass-material-tokenization` (created by the Architect before dispatch; do not branch further).

1. **`[Phase 5] Add DesignTokens::Material type and defaults`**
   - New file `src/ui/design_tokens/material.cr` with `Material`, `Step`, `ResolvedStep`.
   - Wire defaults into the `DesignTokens` root.
   - Add `material : Material` accessor.
   - Specs for resolution math (`spec/ui/design_tokens/material_spec.cr`).

2. **`[Phase 5] Generate material CSS custom properties + @supports fallback`**
   - Extend `DesignTokens::WebGenerator` to emit the `--ap-material-*` block and the `@supports not (backdrop-filter)` fallback rules.
   - Stability spec: pin the generator output for the default brand (`spec/ui/design_tokens/web_generator_material_spec.cr`).

3. **`[Phase 5] Wire web renderer to material tokens`**
   - Replace `web_renderer.cr` lines 1335–1359 with the token-driven emission described in "Web emission contract."
   - Remove the hard-coded `10/20/30/40/50` switch.
   - Inline style now uses `var(--ap-material-blur-*)` and `color-mix(... var(--ap-material-opacity-*) ...)`.
   - Spec asserting the emitted HTML for a `GlassBackground.new(material: :regular)` includes the expected `var()` references.

4. **`[Phase 5] Add MaterialParameters to AssetPipelineSwiftKit`**
   - Add `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/GlassBackground.swift` with `MaterialParameters` and `GlassBackgroundFacade`.
   - Update the Swift package manifest if needed for the new file.
   - Build verification: iOS device + simulator + macOS targets all compile.

5. **`[Phase 5] Wire uikit_renderer to GlassBackground facade`**
   - Replace `uikit_renderer.cr` lines 3071–3117 with the token-driven facade call.
   - Crystal-side spec asserting the resolved material params struct is populated from tokens, not from a hard-coded switch.

6. **`[Phase 5] Wire appkit_renderer to GlassBackground facade`**
   - Replace `appkit_renderer.cr` lines 2734–2774. Include the UIKit→AppKit material constant translation table inline.
   - Spec mirrors the uikit one.

7. **`[Phase 5] Add Android RenderEffect helper + wire renderer`**
   - New Java helper at the path documented above.
   - New JNI entry point in `src/lib_android_bridge.cr`.
   - Replace `android_renderer.cr` lines 2162–2189 with the helper-calling implementation.
   - Spec asserting the Crystal call resolves the token, computes ARGB, and invokes the static method (mocked).

8. **`[Phase 5] Extend material tokenization to TabView, Alert, Sidebar, Toolbar, Sheet, Popover visitors`**
   - **Only if the deviation prompt above resolves to "extend, do not return early."** This commit may be split across uikit and appkit if the diff is large.
   - Every visit method that today calls `setMaterial:` with a hard-coded integer now reads from `tokens.material.resolve(:semantic_name)`.

After commit 8, run the full spec suite and the four sample builds. If any glass-using widget regresses visually, the brand intensity cascade is the cause and the visit method needs review.

---

## Brand override demo

New sample file: `samples/cross_platform/glass_intensity_demo.cr`

```crystal
require "../../src/asset_pipeline"

# Demonstrates that setting material.intensity on the brand declaration
# uniformly scales glass-surface blur on every renderer.
#
# Run on each platform:
#   crystal run samples/cross_platform/glass_intensity_demo.cr            # web (default 1.0)
#   crystal run samples/cross_platform/glass_intensity_demo.cr -- 1.3     # web (boosted)
#   crystal run samples/cross_platform/glass_intensity_demo.cr -Dmacos -- 1.3
#   crystal run samples/cross_platform/glass_intensity_demo.cr -Dios -- 1.3
#   crystal run samples/cross_platform/glass_intensity_demo.cr -Dandroid -- 1.3

intensity = (ARGV[0]? || "1.0").to_f

brand = UI::Brand.default.with do |b|
  b.material.intensity = intensity
end

view = UI::VStack.new(
  spacing: 16,
  children: [
    UI::Text.new("Intensity: #{intensity}"),
    UI::GlassBackground.new(
      material: :ultra_thin,
      content: UI::Text.new("ultra_thin"),
    ),
    UI::GlassBackground.new(
      material: :thin,
      content: UI::Text.new("thin"),
    ),
    UI::GlassBackground.new(
      material: :regular,
      content: UI::Text.new("regular"),
    ),
    UI::GlassBackground.new(
      material: :thick,
      content: UI::Text.new("thick"),
    ),
    UI::GlassBackground.new(
      material: :chrome,
      content: UI::Text.new("chrome"),
    ),
  ],
)

UI::Renderer.render(view, brand: brand)
```

The validator captures screenshots at intensities 0.5, 1.0, and 1.5 across all four platforms (15 PNGs total) and verifies the visible blur ladder.

---

## Testing requirements

### Crystal specs

- `spec/ui/design_tokens/material_spec.cr` — resolution math at boundary values (intensity 0.0, 0.5, 1.0, 1.5, 3.0, 5.0 — last two confirm clamping). Round-trip a brand override of one step's `blur_radius` and verify the resolved value is multiplied by intensity, not the override's value before multiplication.
- `spec/ui/design_tokens/web_generator_material_spec.cr` — generator output stability: snapshot the `:root` block and the `@supports` block, compare to a fixture. If the implementer changes the published default values, the fixture updates with that commit.
- `spec/ui/renderers/web_glass_spec.cr` — render a `GlassBackground.new(material: :thick)` and assert the inline style contains `var(--ap-material-blur-thick)` and `color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thick) * 100%), transparent)`.
- `spec/ui/renderers/uikit_glass_spec.cr` and `spec/ui/renderers/appkit_glass_spec.cr` — assert the `MaterialParameters` struct passed to the bridge contains the resolved (not raw) values. Drive a brand with `intensity = 1.5` and confirm `material_params.blur_radius == 45.0` for `:regular`.
- `spec/ui/renderers/android_glass_spec.cr` — confirm the helper is invoked with the resolved blur radius and the computed ARGB.

### Snapshot test (web)

Existing visual regression harness covers `samples/cross_platform/showcase.html`. Add a new harness entry for `glass_intensity_demo.cr` rendered at intensity 0.5, 1.0, 1.5. Three PNGs per browser; commit baselines after manual review.

### Screenshot capture scripts (iOS / macOS / Android)

- iOS: extend `samples/cross_platform/ios_host/` build pipeline to take the demo bundle and capture via `xcrun simctl io booted screenshot`. The validator runs this at three intensity values.
- macOS: extend `samples/cross_platform/macos_host/` visual regression harness to include the glass intensity demo.
- Android: extend the Android host sample to take a screenshot via `adb exec-out screencap`.

The implementer wires the capture scripts; the validator runs them and diffs.

### Build verification

After each commit chunk: `crystal build --no-codegen src/asset_pipeline.cr` plus the iOS/macOS/Android sample builds at `--no-codegen`. After commits 4 (Swift package change), 5 + 6 (renderer changes), 7 (Android), do a full link build at minimum on macOS sample.

---

## Definition of done

1. `DesignTokens::Material` type exists with `Step`, `ResolvedStep`, the five-step default, and the `intensity` scalar (default 1.0).
2. Every renderer's `visit(view : UI::GlassBackground)` reads from `tokens.material.resolve(view.material)` — no hard-coded numbers in any of the four files.
3. The deviation prompt's question is resolved: either every other glass-using visit method is also tokenized, or the team lead has been notified and chosen the narrower scope.
4. The `AssetPipelineSwiftKit` package exposes `MaterialParameters` and `GlassBackgroundFacade` and builds for iOS device + simulator + macOS.
5. The web stylesheet emits the `--ap-material-*` custom properties and the `@supports not (backdrop-filter)` fallback block. Verified by reading the generated CSS.
6. The Android Java helper exists and is invoked over JNI with the resolved blur radius. Verified by reading the call sites.
7. `samples/cross_platform/glass_intensity_demo.cr` exists, takes intensity from `ARGV`, and renders on all four platforms.
8. Every new spec passes. The existing spec suite remains green: `crystal spec` returns 0 failures.
9. Four sample apps build clean.
10. Commits are sequenced as described; subjects follow `[Phase 5] {imperative}`; no `Co-Authored-By` lines unless the team lead explicitly requested them.
11. Handoff message names every commit hash and discloses any deviation from this brief.
