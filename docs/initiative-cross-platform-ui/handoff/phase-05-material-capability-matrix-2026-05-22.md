# Phase 5 — Material Capability Matrix (Architecture Addendum)

**Status:** ARCHITECTURE DECISION REQUIRED. Authored 2026-05-22 after Phase 5 Validator iter 2 FAIL + Codex round 3 critique of R4 draft. Owner sign-off required before R4 dispatch.

## Why this exists

Phase 5 brief.yml committed to a **thickness-based quantization model**: intensity Float64 → discrete step (ultra_thin/thin/regular/thick/chrome) → SwiftUI Material enum. Codex's R4 critique pointed out two real problems:

1. **AppKit's NSVisualEffectMaterial is semantic, not thickness-based.** Apple's docs treat it as a dynamic semantic enum (Menu / Popover / Sidebar / Sheet / HUDWindow / etc.), NOT a linear thickness scale. Mapping `:menu` to `:thin` via baseline-table breaks semantic fidelity for the Menu material.

2. **The 8 widgets' actual code path is NOT SwiftKit facade Material; it's Crystal-side direct `setMaterial:` / `setEffect:` ObjC msg_send calls** with hard-coded integers. The SwiftKit facade files for Alert/Toolbar/Sheet/Popover/etc. reference NO SwiftUI Material API. Phase 5's tokenization can only happen at the Crystal-side renderer dispatch site, not via a SwiftKit facade material parameter.

This addendum maps each affected widget to its actual Apple capability + tokenization shape so R4 can be scoped correctly.

## Capability matrix

Per active visit dispatch path. iOS + macOS columns. "Phase 5 needs" describes what R4 must do.

| # | Widget | macOS active visit | macOS material API | iOS active visit | iOS material API | Category | Phase 5 R4 needs |
|---|--------|--------------------|--------------------|------------------|------------------|----------|------------------|
| 1 | **TabView** | `appkit_renderer.cr:820` | NSVisualEffectView `setMaterial: 10` (HUDWindow) — hardcoded | `uikit_renderer.cr:786` | UIBlurEffectStyle 11 (SystemChromeMaterial) — hardcoded | Semantic chrome | Tokenize via `appkit_visual_effect_material(step)` helper; default step `:chrome` (HUDWindow semantic) |
| 2 | **Alert** | `appkit_renderer.cr:1060` | NSVisualEffectView `setMaterial: 7` (Sidebar) — hardcoded | `uikit_renderer.cr:1045` | UIBlurEffectStyle 7 (SystemMaterial) — hardcoded | System-resolved (UIAlertController/NSAlert wraps; this code is for the custom inline alert host) | Tokenize via helper; default step `:sidebar` (semantic Sidebar) — note iOS-side uses Material(7) not Sidebar(7); confirm during dispatch |
| 3 | **NavigationSplitView** | `appkit_renderer.cr:1773` (active); `appkit_renderer.cr:1837` is the inline sidebar effect | NSVisualEffectView `setMaterial: <variable>` — partial tokenization | `uikit_renderer.cr:1822` | UIBlurEffectStyle 11 — hardcoded | Semantic chrome | Tokenize active visit's `sidebar_material` resolution; default step `:sidebar` |
| 4 | **Toolbar** | `appkit_renderer.cr:1964` | NSVisualEffectView `setMaterial: 10` (HUDWindow) — hardcoded | `uikit_renderer.cr:1967` | UIBlurEffectStyle 11 — hardcoded | Semantic chrome | Tokenize via helper; default step `:chrome` |
| 5 | **Sheet** | `appkit_renderer.cr:2123` | NSVisualEffectView `setMaterial: 11` (Sheet) — hardcoded | `uikit_renderer.cr:2108` | UIBlurEffectStyle (or UIGlassEffect on iOS 26+) | Semantic sheet | Tokenize; default step `:sheet` (NSVisualEffectMaterialSheet = 11) |
| 6 | **Popover** | `appkit_renderer.cr:2298` | NSVisualEffectView `setMaterial: 6` (Popover) — hardcoded | `uikit_renderer.cr:2324` | UIBlurEffectStyle 11 — hardcoded | Semantic popover | Tokenize; default step `:popover` (NSVisualEffectMaterialPopover = 6) |
| 7 | **ContextMenu** | `appkit_renderer.cr:2821` | R3-tokenized via `appkit_visual_effect_material(:menu)` returning Menu(5) | `uikit_renderer.cr:2931` | UIBlurEffectStyle — hardcoded | Semantic menu | iOS-side needs tokenization; macOS already done by R3. Default step `:menu` |
| 8 | **ActivityView** | `appkit_renderer.cr:3751` | R3-tokenized via `appkit_visual_effect_material(:thick)` returning Sheet(11) | `uikit_renderer.cr:3725` | UIBlurEffectStyle — hardcoded | Semantic sheet (matches HIG ActivityView) | iOS-side needs tokenization; macOS already done by R3 (though R3 chose `:thick` semantically; could be `:sheet` per HIG) |

Plus the 5 `_legacy_*` paths from R3's handoff doc:
- _legacy_tab_view, _legacy_alert, _legacy_toolbar, _legacy_sheet, _legacy_popover — these are dead code on macOS; can be cleaned up alongside or after R4.

## The architectural choice

**Two paths the brief could commit to:**

### Path A — Semantic-with-intensity-scaling (matches Apple's NSVisualEffectMaterial design)

Material has two axes:
- **Semantic identity** (the widget's HIG-canonical role): `:menu`, `:popover`, `:sidebar`, `:sheet`, `:hud_window`, `:chrome` etc. Determined by the widget; consumers rarely override.
- **Intensity** (how strong the visual effect should be within the chosen semantic): 0.0–2.0 scalar. Intensity scales blur radius / opacity WITHIN the semantic, does NOT swap semantics.

On Apple platforms: semantic identity → NSVisualEffectMaterial enum directly. Intensity is advisory (Apple doesn't expose per-material intensity; if intensity != 1.0, log warning + use the semantic as-is). On web/Android: intensity scales blur radius numerically; semantic determines baseline opacity.

**Pro:** Honors Apple's design intent. Each widget gets its semantically-correct material. Brand intensity scales within a semantic where supported.

**Con:** Apple platforms don't get per-step intensity cascade. Brand setting `intensity = 1.5` doesn't visibly change an Alert's material on Apple (which uses Sidebar regardless). Cascade is web-only + Android-only.

### Path B — Thickness-quantized (current brief commitment)

Material has one axis: thickness. The 5 steps (ultra_thin/thin/regular/thick/chrome) map to a thickness ranking. Intensity quantizes to a step. Widget defaults pick a step.

On Apple platforms: quantizer determines step → SwiftUI Material enum (.ultraThinMaterial/.thinMaterial/.../.ultraThickMaterial). Widgets that previously used semantic materials (Menu, Popover, Sheet) get mapped onto the thickness scale.

**Pro:** Brand intensity has consistent cross-platform behavior. Single tokenization model.

**Con:** Breaks Apple semantic fidelity. A Popover should use NSVisualEffectMaterialPopover (semantic), but Path B forces it to a thickness step. The visual result may differ from HIG conformance.

### Architect's recommendation: Path A

Apple has been clear since macOS 10.14 that NSVisualEffectMaterial is a semantic vocabulary. SwiftUI's Material enum is more thickness-like but still has semantic variants (.bar). Forcing every widget through a thickness ranking is fighting Apple's design.

Path A's "intensity is advisory on Apple platforms" cost is real but worth it. Brand intensity remains meaningfully load-bearing on web and Android (the cross-platform parity story), and Apple gets correct HIG conformance.

**If Owner chooses Path A:**
- Brief I-1 / I-10 / adapter_cardinality amend further to scope intensity-cascade to web + Android. Apple cascade is documented as "Apple-system-resolved semantic; intensity may not visually affect Apple widgets."
- Material#apple_step quantizer becomes `Material#apple_semantic(declared_or_widget_default : Symbol) : Symbol` — returns the semantic identity (NSVisualEffectMaterial → Symbol), no intensity quantization on Apple.
- New `Material#web_blur_for(step, intensity)` and `Material#android_blur_for(step, intensity)` retain numeric scaling.
- R4 wires each of the 8 widgets to call the Apple-semantic resolver + emit the correct NSVisualEffectMaterial Int64 (via R3's helper, extended with the new semantic Symbols).

**If Owner chooses Path B:**
- Brief stays as-is on thickness cascade.
- Material#apple_step gets the fix Codex flagged (quantize ALL declared steps by intensity, not just :regular).
- R4 wires each widget through the thickness path; accept that Apple semantic fidelity is reduced.

## What I need from you

Pick Path A or Path B. Either is defensible; the choice cascades into R4's scope. Path A is closer to HIG truth; Path B keeps the cross-platform tokenization story uniform.

Once chosen, R4's brief becomes much smaller and more concrete:
- **Path A R4:** Extend R3 helper with Sheet/Popover/HUDWindow/Sidebar semantic Symbols. Tokenize the 6 unconverted macOS sites + 8 iOS sites with semantic resolution. Apple cascade scope-limited; brief I-1/I-10 amends.
- **Path B R4:** Fix Material#apple_step quantizer to scale ALL declared steps. Tokenize via the thickness ranking. Accept reduced semantic fidelity.

Brief A1 text drift (says `.bar`, spike uses `.ultraThickMaterial`) gets reconciled in both paths.
