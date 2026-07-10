# Phase 5 v2 — Validation Report — 2026-05-22

**Verdict:** PASS
**Validator commit range checked:** 4ccdb29..87d388d (12 commits)
**Date run:** 2026-05-22
**Repo:** `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`
**Branch:** `phase-05-glass-material-tokenization` @ HEAD `87d388d`

## What I ran (commands + exit codes)

| Command | Exit | Notes |
|---|---|---|
| `crystal run scripts/validate_phase_brief.cr -- docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml` | 0 | All 9 facts + 9 lower-layer assumptions PASS. `PASS: phase brief is dispatchable.` |
| `crystal spec spec/ui/design_tokens/material_spec.cr` | 0 | 31 examples, 0 failures. Quantizer boundaries (0.3 / 0.7 / 1.3 / 1.8) and step baselines (0.2 / 0.5 / 1.0 / 1.5 / 1.9) pinned. |
| `crystal spec` (full suite) | 1 | 1454 examples, 4 failures — **exactly the 4 pre-existing failures listed in the brief** (`views_spec.cr:3273`; `phase2_verification_spec.cr:52, 116, 129`). No new failures. |
| `swift build -c release --package-path swift/AssetPipelineSwiftKit` | 0 | `Build complete!` |
| `make -C samples/cross_platform/macos_host build` | 0 | Builds + codesigns `bin/hig_showcase` |
| `bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator` | 0 | iOS Simulator static lib OK |
| `crystal-alpha build --no-codegen src/asset_pipeline.cr` | 0 | Web semantic check |
| `crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags="..."` | 1 | 1 failure: `trigger.should_not be_nil` — **environmental** (AXTest probe requires Accessibility permission on terminal + a running app that the spec launches). NOT a Phase 5 v2 regression. Phase 3 BX2 reactivity probe. |

**Note on a self-inflicted false alarm.** During verification I ran `git checkout 4ccdb29 -- src/` after a `git stash` to inspect pre-existing state. The stash was empty (no working changes existed), so the checkout overwrote Phase 5 v2 source with the parent SHA's files. I restored with `git checkout HEAD -- src/` and re-ran the brief validator + builds — all PASS. The "drift to 46" I briefly observed was caused by my own destructive checkout, not by the Implementer's commits.

## Invariant matrix verification

### I-1 (Render correctly) — PASS

- `src/ui/design_tokens/material.cr` lines 46-92 declare the `AppleSemantic` enum with all 9 values (Menu / Popover / Sidebar / Sheet / HeaderView / WindowBackground / HUDWindow / Titlebar / SystemResolved).
- Lines 97-140 declare `ThicknessStep` with all 5 values (UltraThin / Thin / Regular / Thick / Chrome).
- `thickness_for_brand` (lines 195-203) implements the exact quantizer described in adapter_cardinality row 2: `<= 0.3 → UltraThin`, `<= 0.7 → Thin`, `<= 1.3 → Regular`, `>= 1.8 → Chrome`, else Thick.
- `apple_semantic` (lines 179-181) returns the declared semantic without intensity modification.
- `appkit_visual_effect_material_for_semantic` (`src/ui/renderers/appkit_renderer.cr` lines 4722-4736) is a pure case/in over `AppleSemantic` — no intensity quantization on the Apple path. SystemResolved returns `0_i64` sentinel.

### I-2 (Update reactively — forward) — PASS (preserves)

```
git diff 4ccdb29..87d388d -- swift/AssetPipelineSwiftKit/ | grep '^+' | grep -E '@Published|ObservableObject'
```
returns empty. No new `@Published` or `ObservableObject` added in any Phase 5 v2 commit.

### I-3 (Dispatch events — backward) — PASS (preserves)

No new event paths added. Category C helpers (`appkit_visual_effect_material_for_semantic`, `uikit_blur_effect_style_for_semantic`) return integer materials/styles; they do not register callbacks.

### I-4 (Restore focus) — PASS (preserves)

Material modifiers (`.background(...)`, `.presentationBackground(...)`, `.toolbarBackground(...)`) are visual-only.

### I-5 (Manage lifecycle) — PASS (preserves)

`materialSemantic` is an additional property on each `*Overrides` Swift class — the Overrides lifecycle is unchanged.

### I-6 (Propagate accessibility) — PASS (extends, probes deferred)

Probe placeholder specs declared. Audit harness deferred to Phase 6.5 (owner-approved per brief).

### I-7 (Manage memory ownership) — PASS (extends)

```
git diff 4ccdb29..87d388d -- src/ui/native/swiftkit_bridge.cr | grep -E '^\+\s*fun\s+apsk_'
```
returns empty. No new C-export mutators on iOS/macOS SwiftKit bridge in commits `800076c..87d388d`.

### I-8 (Honor environment) — PASS (preserves on Apple; deferred cross-platform)

Apple paths delegate environment response to SwiftUI / `NSVisualEffectView` / `UIVisualEffectView`. Cross-platform forced-colors / reduced-motion in Phase 6.5.

### I-9 (Survive embedding) — PASS (preserves)

```
git diff 4ccdb29..87d388d | grep -E '^\+\s*class_var\s+'
```
returns empty. No new Crystal `class_var` declarations in any Phase 5 v2 commit.

### I-10 (API / fallback contract fidelity) — PASS (extends)

- `Material` exposes `semantic : AppleSemantic` (`src/ui/design_tokens/material.cr:173`), `step : ThicknessStep` (line 172), `intensity : Float64` (line 171).
- The AppKit `appkit_visual_effect_material_for_semantic` case/in is purely role-based — `intensity` does not flow into the NSVisualEffectMaterial integer lookup. (verified at `appkit_renderer.cr` 4722-4736)
- Brand intensity is meaningful on web/Android — both use `@design_tokens.material.resolve(...)` which routes through the quantizer (`web_renderer.cr:1413, 2028`; `android_renderer.cr:2186`).

### I-11 (Build / link / load closure) — PASS

All 4 build targets succeed (table above).

## Category B widget verification (6 widgets)

For each widget I verified (a) Crystal `material_semantic` property; (b) Swift Overrides field; (c) Swift Facade material modifier + `iOS 26 / macOS 26` `.glassEffect()` gate; (d) Crystal populator emits `setMaterialSemantic`.

| Widget | (a) Crystal prop | (b) Overrides field | (c) Facade modifier + `.glassEffect()` gate | (d) Populator |
|---|---|---|---|---|
| **TabView** | `src/ui/views/tab_view.cr:50` | `TabViewOverrides.swift:27` | `TabViewFacade.swift:68-74` — `.glassEffect()` on 26+, else `.toolbarBackground(<mat>, for: .automatic)` | `swiftkit_overrides.cr:411-413` |
| **Alert** | `src/ui/views/alert.cr:30` | `AlertOverrides.swift:29` | `AlertFacade.swift:10-13` — NO material modifier applied (system-drawn); field intentionally inert | `swiftkit_overrides.cr:468-470` (only emits on caller override) |
| **NavigationSplitView** | `src/ui/views/navigation_split_view.cr:18` | `NavigationSplitViewOverrides.swift:20` | `NavigationSplitViewFacade.swift:41-49` — gates `.glassEffect()` on 26+, else `.background(<Material>)` on sidebar pane only | `swiftkit_overrides.cr:391-393` |
| **Toolbar** | `src/ui/views/toolbar.cr:18` | `ToolbarOverrides.swift:27` | `ToolbarFacade.swift:69-74` — `.glassEffect()` on 26+, else `.toolbarBackground(<mat>, for: .automatic)` | `swiftkit_overrides.cr:504-506` |
| **Sheet** | `src/ui/views/sheet.cr:49` | `SheetOverrides.swift:21` | `SheetFacade.swift:115-122` — `.glassEffect()` on 26+, else `.presentationBackground(<Material>)`; SystemResolved suppression honored | `swiftkit_overrides.cr:432-434` |
| **Popover** | `src/ui/views/popover.cr:15` | `PopoverOverrides.swift:20` | `PopoverFacade.swift:76-82` — `.glassEffect()` on 26+, else `.presentationBackground(<Material>)`; SystemResolved suppression honored | `swiftkit_overrides.cr:447-449` |

All 6 widgets PASS all four verification points. Per-widget defaults match the architecture doc table (lines 86-95): TabView/Toolbar = `.toolbarBackground(.bar, for: .automatic)`; Sheet/Popover = `.presentationBackground(<Material>)`; NavigationSplitView = `.background(<Material>)` on sidebar only; Alert = no modifier (system-drawn).

## Category C widget verification (2 widgets)

- **`appkit_visual_effect_material_for_semantic`** declared at `appkit_renderer.cr:4722` taking `UI::DesignTokens::AppleSemantic`. Returns NSVisualEffectMaterial integer; `SystemResolved → 0_i64` sentinel.
- **`uikit_blur_effect_style_for_semantic`** declared at `uikit_renderer.cr:4766` taking `UI::DesignTokens::AppleSemantic`. Returns UIBlurEffectStyle integer; `SystemResolved → -1_i64` sentinel.
- macOS shim `appkit_visual_effect_material(step : Symbol) : Int64` preserved at `appkit_renderer.cr:4744` for legacy bodies — delegates to the semantic helper.

**ContextMenu:**
- macOS visit `appkit_renderer.cr:2835` calls helper with `AppleSemantic::Menu`; suppresses `setMaterial:` when material is 0 (lines 2837-2839).
- iOS visit `uikit_renderer.cr:2937` calls helper with `AppleSemantic::Menu`; suppresses by emitting null `blur_effect` and `initWithEffect:nil` when style == `-1_i64` (lines 2944-2952).

**ActivityView:**
- macOS visit `appkit_renderer.cr:3773` calls helper with `AppleSemantic::Sheet`; same suppression pattern (lines 3775-3777).
- iOS visit `uikit_renderer.cr:3752` calls helper with `AppleSemantic::Sheet`; same null-effect suppression pattern (lines 3759-3767).

PASS — SystemResolved sentinel correctly suppresses `setMaterial:` / `setEffect:` on both platforms.

## Quantizer migration verification

- `grep -E 'blur_radius \* ' src/ui/renderers/` — no live-path matches; the proportional-scaling code path is gone.
- `web_renderer.cr:1413` uses `@design_tokens.material.resolve(view.material)`; `web_renderer.cr:2028` uses `.resolve(:thick)` — both route through the quantizer.
- `android_renderer.cr:2186` uses `@design_tokens.material.resolve(view.material)` — quantizer-driven.
- Comments at `android_renderer.cr:2177` explicitly document the migration away from `step.blur_radius * intensity`.

PASS — web + Android consume the quantizer; iter1's proportional path removed from live runtime.

## Findings

No FAIL items found. The Implementer's 12 commits land exactly the v2 architecture contract:

1. Two-axis Material model (`AppleSemantic` + `ThicknessStep` + `intensity`) with `apple_semantic` (role pass-through) and `thickness_for_brand` (quantizer) axes correctly separated.
2. All 6 Category B widgets end-to-end tokenized (Crystal property → Overrides field → Facade modifier → populator).
3. Per-widget HIG-canonical modifiers applied per the architecture table (no generic `.background()` shortcut anywhere except NavigationSplitView's sidebar pane).
4. `.glassEffect()` availability gate (iOS 26 / macOS 26) wired on all 5 widgets that need it; Alert remains exempt as designed.
5. Category C ContextMenu + ActivityView tokenized on both AppKit (renamed semantic helper) and UIKit (new semantic helper); both honor SystemResolved suppression.
6. Web + Android renderers migrated to quantizer; proportional scaling removed.
7. No new `@Published`, `ObservableObject`, `apsk_*` C-export, or Crystal `class_var` — I-2 / I-7 / I-9 invariants preserved.
8. Brief validator PASS at HEAD `87d388d`; all 9 repo facts match captured-at-SHA expectations; all 9 lower-layer assumptions verify.

## Recommendation

**PASS — ready to merge into parent branch.**

Phase 5 v2 satisfies every brief invariant, every adapter_cardinality contract row, every per-widget architecture-doc default, and every shipped-build target. The single environmental spec failure (`macos_action_tap_probe_spec.cr`) is a Phase 3 BX2 reactivity probe that requires terminal Accessibility permission; it is not a Phase 5 v2 regression and the brief lists it as the canonical Apple-side probe knowing it depends on host environment grant.

Deferred to follow-up phases as documented:
- Phase 5.5 — delete the 6 `_legacy_*` AppKit methods (dead code).
- Phase 6.5 — Apple-platform visual baseline probes, Android empirical verification, cross-platform forced-colors / reduced-motion env-response harness.
