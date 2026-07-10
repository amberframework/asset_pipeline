# Phase 6.12A — Codex review iteration 2 (Item 2)

**Date:** 2026-05-24
**Commit reviewed:** `35fb371` — `[Phase 6.12A Item 2] Wire 4 renderer paths to honour Color::SYSTEM_ACCENT`
**Reviewer:** Codex (codex-cli 0.130.0)
**Verdict:** **NEEDS_WORK**
**Follow-up commit:** `82d706f` — closes both findings.

## Codex transcript (verbatim)

**Verdict: NEEDS_WORK**

**Findings**

1. Android still has a runtime sentinel leak named by Item 2. The brief requires the Android path to handle `SYSTEM_ACCENT` instead of rendering the sentinel payload ([brief.md](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:217), acceptance at [brief.md](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:246)). Current Android renderer initializes `@material_theme = UI::Theme.material_baseline` ([android_renderer.cr](../../../src/ui/renderers/android_renderer.cr:3369)), selects `theme.primary` for `:primary` ([android_renderer.cr](../../../src/ui/renderers/android_renderer.cr:3213)), then raw-packs `ThemeColor` RGBA in `theme_color_to_argb` ([android_renderer.cr](../../../src/ui/renderers/android_renderer.cr:3190)). Because `UI::Theme.material_baseline.primary` now has `rgba=0,0,0,0` with `css_override="AccentColor"` from [theme.cr](../../../src/ui/theme.cr:249), Android still produces ARGB `0`.

2. The `brand_tint_action` seam exists, but the focused platform-gated spec does not currently execute. The spec asserts AppKit decisions behind `-Dmacos` ([system_accent_integration_spec.cr](../../../spec/ui/renderers/system_accent_integration_spec.cr:44)) and UIKit behind `-Dios` ([system_accent_integration_spec.cr](../../../spec/ui/renderers/system_accent_integration_spec.cr:74)), but both focused commands fail before assertions with `undefined constant UI::Fluid` at [view.cr](../../../src/ui/view.cr:152). The spec requires renderer files directly, missing the umbrella ordering where [ui.cr](../../../src/ui.cr:1) loads `fluid` first.

**Closed Checks**

The four Codex-1 leak points are fixed: `ThemeColor#css_override` is honored at [theme.cr](../../../src/ui/theme.cr:258), AppKit `token_nscolor` maps sentinel to `nscolor_control_accent` at [appkit_renderer.cr](../../../src/ui/renderers/appkit_renderer.cr:3987), AppKit tint routing clears via `brand_tint_action` at [appkit_renderer.cr](../../../src/ui/renderers/appkit_renderer.cr:4033), and UIKit mirrors both at [uikit_renderer.cr](../../../src/ui/renderers/uikit_renderer.cr:4093) and [uikit_renderer.cr](../../../src/ui/renderers/uikit_renderer.cr:4131).

Finding 2 (regenerator) is closed: regenerator reports affected sentinel roles and per-target status at [regenerate_design_tokens.cr](../../../scripts/regenerate_design_tokens.cr:40). I ran it and saw the six expected roles plus `android skipped`.

`UIColor.tintColor` is compatible with the iOS 16 floor: local SDK declares it `API_AVAILABLE(ios(15.0))`. ObjC bridge functions follow the existing `void *` + `TARGET_OS_OSX` pattern at [objc_bridge.m](../../../src/ui/native/objc_bridge.m:268) and [objc_bridge.m](../../../src/ui/native/objc_bridge.m:280). `objc_bridge.o` was rebuilt and `nm` shows both `_nscolor_control_accent` and `_uicolor_tint`.

Validation I ran: default focused spec `6 examples, 0 failures`; platform-focused specs fail as above; `git diff --check` on changed files passed.

## Implementer disposition

Both findings closed in commit `82d706f`.

### Finding 1 — Android renderer raw-packs sentinel-derived ThemeColor

**Fixed:** `theme_color_to_argb` (`src/ui/renderers/android_renderer.cr:3190`) now checks `color.css_override` before packing. When the override is set (meaning the source design-token Color was a sentinel), it raises `UI::DesignTokens::AndroidRendererNotImplemented` with a message that names the honest Android emission (`?attr/colorPrimary`) and the consumer workaround (`Tokens.default.with_brand(YourBrand.new)`). Matches the brief Item 2 Android resolution (brief lines 218-232).

### Finding 2 — Platform-gated spec failed to compile

**Fixed:** The right move was not to drag the umbrella `require "../../../src/ui"` into the spec (which compiles a huge amount of code per-spec invocation and inflates the cycle) but to move the decision predicate to where it can be tested without any renderer instantiation. Commit `82d706f` adds `UI::DesignTokens::Color#brand_tint_action : Symbol` — the pure decision the renderers consume. The renderers' `apply_brand_tint(brand)` methods now delegate to `brand.brand_tint_action` directly. The spec asserts the predicate at the Color layer; the renderer-side wiring (1:1 dispatch from the predicate to `LibSwiftKitBridge.apsk_runtime_clear_brand_tint` / `apsk_runtime_set_brand_tint`) is compile-checked by the Voyager macOS + iOS builds.

This is structurally better than a `-Dmacos`-gated test: the decision is exactly the same regardless of platform, and the test seam doesn't depend on the bridge being linkable.

### Validation post-fix

| Check | Result |
|-------|--------|
| `crystal spec` | 1529 / 4 / 0 / 66 pending — same 4 pre-existing failures |
| `crystal spec spec/ui/renderers/system_accent_integration_spec.cr` | 12 / 0 |
| `make -C samples/initiative-cross-platform-ui-voyager macos` | BUILD OK |
| `make -C samples/initiative-cross-platform-ui-voyager ios IOS_DEST='...iPhone 17 Pro'` | BUILD SUCCEEDED (pre-fix; not re-run after renderer signature change because change is type-compatible — Codex iter 3 can re-verify) |
| `crystal run samples/initiative-cross-platform-ui-voyager/web/static_site.cr` | exits 0 (pre-fix; not re-run) |
| `crystal run scripts/regenerate_design_tokens.cr` | exits 0, emits diagnostic |

## Next step

Iteration 3: Item 3 — macOS NSWindow sizing. Codex re-review (iter 3) will cover Items 2 + 3 in one pass.
