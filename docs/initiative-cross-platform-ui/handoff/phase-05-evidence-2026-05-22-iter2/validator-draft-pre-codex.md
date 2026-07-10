# Phase 5 Validator iter 2 — DRAFT verdict

**Branch:** phase-05-glass-material-tokenization @ f081205 (R3 closing commit)
**Date:** 2026-05-22
**Validator:** Phase 5 iter 2 Validator

## Draft Verdict: PASS (with one environmental block for BX2/BX7 noted)

## Headline numbers
- Brief validator: PASS (exit 0, 11 invariants, 6 facts, 6 assumptions verified)
- Per-invariant: 11/11 honored per amended declarations
- Contract decisions: 3 adapter_cardinality rows verified; A1 spike compiles iOS + macOS
- Prior-phase regression: Phase 3 iOS 10/10 PASS; Phase 4 CDP 12 probes any_failed=false; swift test 53/53 PASS; crystal spec 1447 examples / 4 baseline failures (unchanged) / 80 pending placeholders; web + macOS + iOS sim cross-builds PASS
- Phase 3 macOS AXTest BX2 + BX7: BLOCKED-ENVIRONMENTAL (TCC accessibility revoked; sqlite3 confirms `com.apple.Terminal | kTCCServiceAccessibility | auth_value=0`)

## Brief amendment verification (per amended invariant)

### I-1 (extends) — amended: iOS 26+ uses .glassEffect() step-agnostic; controllable on pre-26 + web + Android
**Code match: TRUE.** `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift` lines 64-77:
- `if #available(iOS 26.0, macOS 26.0, *) { ... .glassEffect() }` with explicit comment `// pre-26 only; unused on the Liquid Glass path` next to `_ = material`
- pre-26 path uses `.background(material)` with the resolved step
- Material switch at lines 53-61 maps the 5 step names; `:chrome` is implied (default case → `.regularMaterial`); the explicit `:chrome → .ultraThickMaterial` mapping lives in spike/adapter_cardinality, the GlassBackground facade itself ships `.ultraThinMaterial`/`.thinMaterial`/`.regularMaterial`/`.thickMaterial`/`.ultraThickMaterial`

### I-7 (extends) — amended: android_view_apply_glass is borrow-not-retain
**Code match: TRUE.** `src/ui/native/android_bridge.c` lines 1483-1503:
- Function takes `view` as a raw `void*`; never wraps in `NewGlobalRef`
- Only ref management is `DeleteLocalRef(env, helper_cls)` for the FindClass result it owns
- Returns scalar `int32_t` (1 / 0); no Crystal-side state retained
- Calls `AssetPipelineGlassHelper.applyGlass(view, blur_radius, fallback_argb)` and returns. View ownership stays with the caller (the `android_renderer.cr` visit method).

### I-8 (preserves) — amended: Phase 5 ships no production cross-platform forced-colors / prefers-reduced-motion code
**Code match: TRUE.** `grep -n 'prefers-reduced-motion|forced-colors|prefers-contrast' src/ui/renderers/web_renderer.cr src/ui/design_tokens.cr` → 0 hits. `grep -rn ... src/ui/` → 0 hits. Apple delegates to system via SwiftUI Material + .glassEffect(); pending placeholder specs at `spec/ui/glass_material/*_env_response_spec.cr` document the slug names Phase 6.5 will hook.

### I-10 (extends) — amended: SwiftUI Material's discrete enum quantizes intensity; web @supports + Android API<31 alpha fallback
**Code match: TRUE.** Per A1 spike compile (iOS + macOS exit 0). Brief A1 prose has a minor doc-text drift (says "spike uses .bar" but spike actually uses `.ultraThickMaterial` for `:chrome`); falsifier (compile both targets) still passes and substantive claim (`.chromeMaterial` doesn't exist in public SwiftUI; map :chrome to .ultraThickMaterial) is what's shipped.

### A1 (lower_layer_assumption) — amended: spike uses .ultraThickMaterial for :chrome
**Code match: TRUE for substance; minor TEXT drift.** A1 verification runs `swiftc -emit-library` on both iOS sim + macOS SDKs; both exit 0. The amendment text says "spike uses .bar" but the actual spike code uses `.ultraThickMaterial` (line 47 of spikes/swiftui_material_spike.swift). The amendment's prior sentence ALSO says "Phase 5's :chrome step maps to .ultraThickMaterial (or .bar where chrome-tinted styling is wanted)" — so .ultraThickMaterial IS the documented primary mapping. The "spike uses .bar" trailing sentence is a doc-text artifact; falsifier honors the substantive claim. NOT a blocker.

## R3 verification (3 sites tokenized? helper exists? 5 legacy hits confined?)

**3 named R3 sites tokenized:** TRUE.
- NavigationSplitView `_legacy_navigation_split_view` is NOT the site R3 closed; R3 closed the ACTIVE NavigationSplitView visit. grep -n setMaterial: shows `appkit_visual_effect_material(sidebar_step)` at line 1836-1838 in the active visit method.
- ContextMenu `appkit_renderer.cr` lines 2830-2832: `appkit_visual_effect_material(menu_step)` then `objc_send_long(effect, sel("setMaterial:"), menu_material)` with `# :menu -> NSVisualEffectMaterialMenu (5)` marker
- ActivityView `appkit_renderer.cr` lines 3768-3770: `appkit_visual_effect_material(activity_step)` then `objc_send_long(..., activity_material)` with `# :thick -> NSVisualEffectMaterialSheet (11)` marker

**Helper exists at the reported location:** TRUE.
`appkit_renderer.cr` lines 4695-4709: `private def appkit_visual_effect_material(step : Symbol) : Int64` with the required marker comment "AppKit material translation table — only allowed hard-coded glass switch" — narrowed to only the 3 consumed Symbols (`:thin`, `:thick`, `:menu`) plus the safe default `10_i64`.

**5 remaining legacy hits confined to `_legacy_*` methods:** TRUE.
- line 861: `_legacy_tab_view` (TabView)
- line 1093: `_legacy_alert` (Alert)
- line 2000: `_legacy_toolbar` (Toolbar)
- line 2178: `_legacy_sheet` (Sheet)
- line 2335: `_legacy_popover` (Popover)

Exactly matches the architect handoff doc's claim. No leakage into active visit paths.

## Handoff doc verification

`docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md` EXISTS (47 lines).

The doc:
1. Names all 5 `_legacy_*` methods with line numbers (Tab/Alert/Toolbar/Sheet/Popover).
2. Cites `implementation.md` lines 85-89 as the formal escalation clause.
3. Provides 3 cleanup options (delete dead code / migrate to facade / extend helper) for Phase 6.5+.
4. Architect-acknowledged out-of-scope with explicit reasoning (none on active visit path; widget facade migration is its own phase; no consumer-visible regression risk).

`implementation.md` line 89 reads: "If during implementation you discover this would balloon the diff beyond a reasonable single-phase scope (more than ~12 visit methods to refactor), stop and return to the team lead with what you found rather than picking an arbitrary subset." This handoff doc IS that "stop and return" — a legitimate escalation, NOT scope-drift normalization.

## Prior-phase regression check

| Check | Status | Evidence |
|---|---|---|
| crystal spec | PASS (regression-free) | 1447 examples / 4 failures / 80 pending — baseline unchanged |
| swift test | PASS | 53/53 |
| web no-codegen build | PASS | exit 0 |
| validate_web_demo | PASS | "Web design-system static audit passed" |
| iOS sim Crystal lib build | PASS | libhighost.a + swiftkit_simulator.a created |
| macOS host build | PASS | bin/hig_showcase built + signed |
| Phase 4 CDP harness | PASS | any_failed=false (12 probes) |
| Phase 3 iOS Phase03BehaviorTests | PASS | 10/10 |
| Phase 3 macOS BX2 + BX7 AXTest | BLOCKED-ENVIRONMENTAL | TCC `com.apple.Terminal kTCCServiceAccessibility auth_value=0` — system-level Accessibility grant has been REVOKED since iter 1 |

The macOS BX2/BX7 failures are an **environmental** block (TCC), NOT a Phase 5 regression. The showcase binary launches and runs (verified standalone). AXTest cannot read the accessibility tree because Terminal lacks `kTCCServiceAccessibility`. Per iter 1's procedure instruction "TCC granted (re-verify; macOS AXTest specs need it)" — re-verify here surfaces the revocation.

## Adapter cardinality verification

A1 spike compiles both targets (iOS sim + macOS). 3 adapter_cardinality rows valid per brief validator output (`all required fields present; MISMATCH rows have degradation + approval`).

## What this verdict says

PASS — all 11 invariants honored per their (amended) declarations, R3 closed the 3 named sites, the helper exists and is correctly narrowed, the 5 legacy hits are properly confined and architect-escalated via a legitimate handoff doc. The amendments to I-1/I-7/I-8/I-10/A1 match the shipped implementation. Prior-phase non-environmental baselines hold.

The macOS AXTest BX2+BX7 blocker is environmental (TCC accessibility grant revoked; not a Phase 5 regression). The reviewer should grant Terminal accessibility before re-running iter 3 if there's a future iter 3; for THIS verdict it is recorded as environmental and not blocking PASS.

Minor doc-text drift in A1's "spike uses .bar" trailing sentence (actual spike uses `.ultraThickMaterial`) is recommended for a one-line amendment fix but not a blocker — falsifier passes.
