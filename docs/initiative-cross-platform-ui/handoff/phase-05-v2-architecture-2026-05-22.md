# Phase 5 v2 — Architecture (Verified Against Code Reality) — 2026-05-22

**Status:** ARCHITECTURE PENDING OWNER SIGN-OFF. Authored after Validator iter 2 FAIL + Codex round 1+2 critiques of the original brief + the abandoned R4 Hybrid draft. This doc grounds Phase 5 v2 in the actual code, not the stale assumptions that drove iter 1/2 dispatches.

## Key correction from prior matrix

The capability matrix at `phase-05-material-capability-matrix-2026-05-22.md` cited line numbers that I assumed were inside active visit bodies. Reading the actual code:

- **6 active visit paths route exclusively through SwiftKit facades.** TabView, Alert, NavigationSplitView, Toolbar, Sheet, Popover. The `setMaterial:` integer literals I cited (lines 862, 1093, 2000, 1838, 2178, 2335) are all inside `_legacy_*` private methods — DEAD CODE, not on the dispatch path.
- **2 active visit paths use direct NSVisualEffectView/UIVisualEffectView.** ContextMenu (macOS visit line 2821, iOS visit line 2931), ActivityView (macOS line 3751, iOS line 3725). R3 tokenized the macOS sides via `appkit_visual_effect_material(step : Symbol) : Int64`. iOS sides remain hardcoded `UIBlurEffectStyle`.

**6 macOS** `_legacy_*` methods (`_legacy_tab_view`, `_legacy_alert`, `_legacy_navigation_split_view`, `_legacy_toolbar`, `_legacy_sheet`, `_legacy_popover`) are non-load-bearing on the active dispatch path; preserved as historical comments-with-code. Cross-platform: count is **12** if iOS-side legacy bodies are included. Phase 5.5+ cleanup deletes all.

## The corrected capability matrix

| Widget | macOS active path | iOS active path | Category | Phase 5 v2 work |
|--------|-------------------|-----------------|----------|-----------------|
| TabView | `apsk_make_tab_view` (line 820) | `apsk_make_tab_view` (line 786) | B (SwiftKit facade) | Add material param to facade + populator |
| Alert | `apsk_make_alert` (line 1060) | `apsk_make_alert` (line 1045) | B | Add material param to facade + populator |
| NavigationSplitView | `apsk_make_navigation_split_view` (line 1773) | `apsk_make_navigation_split_view` (line 1822) | B | Add material param to facade + populator |
| Toolbar | `apsk_make_toolbar` (line 1964) | `apsk_make_toolbar` (line 1967) | B | Add material param to facade + populator |
| Sheet | `apsk_make_sheet` (line 2123) | `apsk_make_sheet_reactive` (line 2108) | B | Add material param to facade + populator |
| Popover | `apsk_make_popover` (line 2298) | `apsk_make_popover` (line 2324) | B | Add material param to facade + populator |
| ContextMenu | Direct NSVisualEffectView (line 2821) | Direct UIVisualEffectView (line 2931) | C (custom Apple effect surface) | macOS: re-route from thickness helper to semantic helper. iOS: tokenize hardcoded UIBlurEffectStyle via new semantic helper. |
| ActivityView | Direct NSVisualEffectView (line 3751) | Direct UIVisualEffectView (line 3725) | C | macOS: re-route. iOS: tokenize. |

## The Material two-axis model

Phase 5 ships `UI::DesignTokens::Material` with TWO declared axes per the owner-chosen Hybrid path:

```crystal
enum AppleSemantic
  Menu                # NSVisualEffectMaterialMenu = 5
  Popover             # NSVisualEffectMaterialPopover = 6
  Sidebar             # NSVisualEffectMaterialSidebar = 7
  Sheet               # NSVisualEffectMaterialSheet = 11
  HeaderView          # NSVisualEffectMaterialHeaderView = 10
  WindowBackground    # NSVisualEffectMaterialWindowBackground = 12
  HUDWindow           # NSVisualEffectMaterialHUDWindow = 13
  Titlebar            # NSVisualEffectMaterialTitlebar = 3
  SystemResolved      # special: emit no setMaterial:; let Apple defaults apply
end

enum ThicknessStep
  UltraThin
  Thin
  Regular
  Thick
  Chrome
end

struct Material
  property step : ThicknessStep
  property semantic : AppleSemantic
  property intensity : Float64 = 1.0

  # Apple: returns the declared semantic. Intensity does NOT affect Apple
  # semantic chrome (Apple's NSVisualEffectMaterial is role-based, not
  # a thickness scalar). When intensity != 1.0, emit a debug-mode warning
  # so consumers know the override is advisory on Apple.
  def apple_semantic : AppleSemantic
    semantic
  end

  # Web / Android: quantizes declared step by intensity baseline. Used for
  # backdrop-filter blur radius scaling on web + RenderEffect blur radius
  # scaling on Android API 31+.
  def thickness_for_brand : ThicknessStep
    baseline = step_baseline(step)
    i = baseline * intensity
    return ThicknessStep::UltraThin if i <= 0.3
    return ThicknessStep::Thin if i <= 0.7
    return ThicknessStep::Regular if i <= 1.3
    return ThicknessStep::Chrome if i >= 1.8
    ThicknessStep::Thick
  end
end
```

iOS has no semantic NSVisualEffectMaterial equivalent — UIBlurEffectStyle is thickness-like. On iOS, Phase 5 maps Apple semantic → UIBlurEffectStyle via a per-semantic approximation table (documented in I-10 amendment as "iOS approximation; UIKit doesn't expose semantic materials").

## Per-widget HIG-canonical defaults

Codex round 2 critiques applied — corrected mappings:

| Widget | macOS NSVisualEffectMaterial | SwiftUI Material (cross-platform) | thickness step default | iOS UIBlurEffectStyle approximation | SwiftUI modifier API |
|--------|------------------------------|-----------------------------------|------------------------|--------------------------------------|------------------------|
| TabView | SystemResolved (no override; SwiftUI handles bar chrome) | `.bar` | Chrome | systemChromeMaterial | `.toolbarBackground(.bar, for: .automatic)` (.tabBar placement is iOS-only; default to .automatic) |
| Alert | SystemResolved | n/a (SwiftUI `.alert` is system-drawn) | Regular | n/a | none — Alert is system-drawn |
| NavigationSplitView | Sidebar (7) on sidebar pane only | `.regularMaterial` on sidebar VStack | Thin | systemThinMaterial | `.background(Material)` on sidebar pane VStack |
| Toolbar | SystemResolved (no override; SwiftUI handles bar chrome) | `.bar` | Chrome | systemChromeMaterial | `.toolbarBackground(.bar, for: .automatic)` (.navigationBar placement is iOS-only; default to .automatic) |
| Sheet | Sheet (11) | `.thickMaterial` | Thick | systemThickMaterial | `.presentationBackground(.thickMaterial)` (iOS 16.4+ / macOS 13.3+) |
| Popover | Popover (6) | `.regularMaterial` | Regular | systemMaterial | `.presentationBackground(.regularMaterial)` |
| ContextMenu | Menu (5) | `.ultraThinMaterial` (approximation) | Thin | systemUltraThinMaterial | `.background()` on custom NSVisualEffectView surface (Category C) |
| ActivityView | Sheet (11) | `.thickMaterial` | Thick | systemThickMaterial | `.background()` on custom NSVisualEffectView surface (Category C) |

**Per-widget rationale:**

- **Alert** is `SystemResolved`. The active Swift facade uses SwiftUI `.alert` which is system-drawn. Apple HIG explicitly recommends letting the system handle alert chrome. The current legacy code's NSVisualEffectMaterial=7 was incidental, not HIG-correct.
- **TabView + Toolbar**: SwiftUI exposes `.bar` Material specifically for toolbar-style chrome. macOS NSVisualEffectMaterial.HeaderView is for inline headers/footers, NOT toolbar chrome — using it would be wrong per Codex's HIG verification. Solution: TabView/Toolbar emit `.toolbarBackground(.bar, ...)` via SwiftUI; on the AppKit side, they're system-resolved (no setMaterial: call).
- **NavigationSplitView**: only the sidebar pane gets material (Sidebar semantic on macOS, .regularMaterial on iOS); the content + detail panes remain system-default.
- **Sheet / Popover**: must use `.presentationBackground(<Material>)` modifier (iOS 16.4+ / macOS 13.3+). The presentation background is what users see; `.background()` on the anchor view doesn't reach the presented modal.
- **ContextMenu + ActivityView**: Category C custom surfaces. Direct visual-effect view material (via the R3-renamed helper).

## Per-category Phase 5 v2 work

### Category B (6 widgets — SwiftKit facade route)

For each: TabView, Alert, NavigationSplitView, Toolbar, Sheet, Popover:

1. Add `materialSemantic : String?` field to the widget's `*Overrides` Swift class. String key matches `AppleSemantic` enum stringified (e.g., `"menu"`, `"popover"`, `"sidebar"`, `"sheet"`, `"hud_window"`, `"system_resolved"`).
2. In the facade body, resolve the semantic AND apply the per-widget modifier from the per-widget defaults table (NOT a generic `.background()` everywhere):
   - **TabView + Toolbar** → `.toolbarBackground(.bar, for: .automatic)` (the `.navigationBar` / `.tabBar` placements are iOS-only; `.automatic` is the cross-platform-safe default; per-platform tightening uses `#if os(iOS)` inside the facade)
   - **Sheet + Popover** → `.presentationBackground(<SwiftUI Material>)` (iOS 16.4+ / macOS 13.3+)
   - **NavigationSplitView** → `.background(<SwiftUI Material>)` on the sidebar pane VStack only
   - **Alert** → no modifier (system-drawn)
   - **On iOS 26+ / macOS 26+ (Liquid Glass path)**: apply `.glassEffect()` instead of the pre-26 modifier above. `.glassEffect()` is **advisory only** — the system decides material strength; AppleSemantic + intensity are not visually load-bearing on this path. NOTE: Phase 5 v2 brief assumption A1 does NOT compile-verify `.glassEffect()`; it only verifies the pre-26 modifier surface. If the implementer needs to gate Liquid Glass usage compile-time, they MUST author the `.glassEffect()` availability check in the Swift code path and surface to architect if the public API requires it.
   - If semantic is `system_resolved` or nil: no modifier; widget uses Apple default. NOTE: `system_resolved` SUPPRESSES the direct AppKit `setMaterial:` / UIKit `setEffect:` overrides — it does NOT suppress TabView/Toolbar `.toolbarBackground(.bar)`, which is the canonical SwiftUI bar chrome (NOT a setMaterial: call).
3. Crystal-side: `populate_<widget>` in `swiftkit_overrides.cr` adds `sender.set_string(target, :setMaterialSemantic, widget.material_semantic_default_or_override)`
4. The `UI::<Widget>` Crystal class exposes a `material_semantic : Symbol?` property (default nil → use widget's HIG default).

### Category C (2 widgets — direct AppKit/UIKit visual effect)

ContextMenu + ActivityView:

1. macOS (already R3-tokenized via `appkit_visual_effect_material(step : Symbol)`): RENAME this helper to `appkit_visual_effect_material_for_semantic(semantic : AppleSemantic) : Int64`. Update the 2 call sites (line 2832, 3770) to pass the widget's resolved AppleSemantic.
2. iOS: add `uikit_blur_effect_style_for_semantic(semantic : AppleSemantic) : Int64`. Tokenize the 2 iOS visit calls (lines around 2931 + 3725 — verify) to use the helper.

### `Material#thickness_for_brand` fix (load-bearing for web/Android)

Update `src/ui/design_tokens/material.cr`:

```crystal
# Before: only :regular was quantized; everything else passed through.
def thickness_for_brand : ThicknessStep
  # ... baseline-scaled quantization ...
end
```

Used by web_renderer (CSS variable scaling) and android_renderer (RenderEffect blur radius). The thickness-for-brand path is the cross-platform intensity cascade.

### Brief amendments

- I-1: amend to document "Apple chrome = semantic; web/Android cascade = thickness; intensity affects web/Android but is advisory on Apple."
- I-10: amend adapter_cardinality with the corrected 8-widget defaults table; remove the previous "quantization → SwiftUI Material" claim.
- I-7: keep `extends` (still true; android_view_apply_glass is the new mutator).
- A1: reconcile spike vs brief text (spike uses `.ultraThickMaterial`; A1 should say so).

### Phase 5.5 follow-up (NOT in v2 scope)

- Delete the 6 `_legacy_*` methods (`_legacy_tab_view`, `_legacy_alert`, `_legacy_navigation_split_view`, `_legacy_toolbar`, `_legacy_sheet`, `_legacy_popover`). Dead code cleanup; no runtime impact. (The architecture doc earlier line 12 already states the cross-platform count is 12 when iOS-side legacy bodies are included.)

## What this fixes vs leaves open

**Fixed by Phase 5 v2:**
- Material 2-axis model that respects Apple semantic chrome
- Brand intensity cascades visibly on web + Android (full quantizer fix)
- 8 widgets get HIG-correct semantic defaults
- ContextMenu + ActivityView material delivery is end-to-end on both platforms
- Brief contracts match shipped code

**Explicitly out-of-scope (documented as Phase 5.5 / Phase 6.5 work):**
- The 5 `_legacy_*` methods — dead code cleanup
- Phase 6.5 audit harness probes for material visual baselines + env-response
- Cross-platform forced-colors / prefers-reduced-motion handling (Phase 6.5)

## What I need from you

Sign off on:
1. The corrected capability matrix
2. The per-widget AppleSemantic + ThicknessStep defaults (especially Alert = SystemResolved)
3. The 2-category v2 dispatch shape (Category B = facade param; Category C = renderer helper)
4. The Phase 5.5 deferral list

Once signed off, I'll author Phase 5 v2's brief.yml (the validator-enforced contract), run it through Codex review, then dispatch the implementer.
