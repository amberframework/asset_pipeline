# Phase 5 Validator Draft Verdict (iter 1, 2026-05-22)

## Headline verdict
**PASS** — all 11 invariants delivered or preserved; all 5 contract decisions honored; all prior-phase baselines hold.

## Brief validator
`crystal run scripts/validate_phase_brief.cr -- docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml`
EXIT=0. All 6 lower_layer_assumptions verified; all 6 repo_derived_facts match captured values; adapter_cardinality valid.

## Per-invariant table

| ID | Touch | Verified by | Status |
|----|-------|-------------|--------|
| I-1 | extends | web renderer emits `--ap-material-{blur,opacity,saturation}-{step}` w/ `calc()` intensity; uikit/appkit call `apple_step`; android `android_view_apply_glass`; web demo + brand glass intensity demo render | PASS (probe harness for ios/macos/android = Phase 6.5, brief acknowledges) |
| I-2 | preserves | render-time resolution only; no def *= on Material; existing Phase 3 reactive bridge unchanged | PASS |
| I-3 | preserves | glass = pure render side; no new event paths | PASS |
| I-4 | preserves | no focus changes | PASS |
| I-5 | preserves | GlassBackground widget API unchanged | PASS |
| I-6 | extends | web @supports not (backdrop-filter) fallback emitted by WebGenerator emit_supports_fallback | PASS (web only verified; iOS/macOS/Android contrast probes are Phase 6.5) |
| I-7 | preserves | grep ObservableObject in Facades/: PRE=4 files, POST=4 files (no new) | PASS |
| I-8 | extends | env-response: implementation delegates to SwiftUI Material's built-in reduced-motion/high-contrast tracking + dark-mode via @media (prefers-color-scheme). Brief documents Phase 5 ships pending Phase 6.5 harness | PASS-with-note: no production code paths for prefers-reduced-motion / forced-colors — delegation-to-SwiftUI is the documented contract |
| I-9 | preserves | grep @@<id>\s*:.*= in views + design_tokens: PRE=0, POST=0 | PASS |
| I-10 | extends | quantization table in Material#apple_step matches brief; web @supports fallback; Android API<31 alpha fallback all in code | PASS |
| I-11 | extends | web no-codegen build OK; iOS build_crystal_lib.sh simulator OK; macOS host make build OK; android skipped per Phase 1 #17 precedent | PASS |

## Contract decision verification

| # | Decision | Verified |
|---|----------|----------|
| 1 | Material tokens render-time resolved (no mutator) | YES — `grep "def [^=]+=" src/ui/design_tokens/material.cr` returned no setter |
| 2 | SwiftUI Material enum quantizes intensity | YES — Material#apple_step in src/ui/design_tokens/material.cr matches brief adapter_cardinality row 1 |
| 3 | Android renderer code lands in Phase 5 | YES — `src/ui/renderers/android_renderer.cr:2184` visit(UI::GlassBackground), `src/ui/native/android_bridge.c:1483` android_view_apply_glass |
| 4 | SwiftUI Material spike compiles | YES — iOS+macOS spike emit-library both EXIT=0 |
| 5 | No new ObservableObjects | YES — grep ObservableObject Facades/: 4 files PRE, 4 files POST |

## Prior-phase regression check

- **iOS XCUITest Phase03BehaviorTests:** 10/10 PASS (96.08s) ✅
- **macOS AXTest BX2+BX7:** FAIL — but Phase 4 SOURCES checked out also FAIL in this environment. Root cause: Terminal lacks Accessibility TCC permission. NOT a Phase 5 regression. Verified by `sqlite3 /Library/Application Support/com.apple.TCC/TCC.db "SELECT client, auth_value FROM access WHERE service='kTCCServiceAccessibility'"` returns `com.apple.Terminal|0` (= not granted). 
- **Phase 4 CDP harness:** 14/14 probes, any_failed=false ✅
- **swift test:** 53/53 PASS ✅
- **crystal spec:** 1447 examples, 4 failures, 0 errors, 80 pending. The 4 failures are the documented pre-existing baseline (1 UI::Theme inject_theme_css + 3 Phase 2 Verification component composition specs). The 80 pending are exactly the Phase 5 probe placeholders ✅

## Phase 5 probe placeholders

6 spec files at `spec/ui/glass_material/`:
- `ios_glass_default_spec.cr` — 5 pending (ultra_thin..chrome) with slug `ios.glass.material.default` and AX identifier convention `ap.glass.<step>.intensity_<intensity_x100>` documented
- `macos_glass_default_spec.cr` — 5 pending, parallel macOS version
- `ios_glass_contrast_spec.cr` — 20 pending (4 intensities × 5 steps) with slug `ios.glass.material.contrast.wcag_aa` and identifier `ap.glass.contrast.<step>.intensity_<intensity_x100>`
- `macos_glass_contrast_spec.cr` — 20 pending, parallel
- `ios_glass_env_response_spec.cr` — 15 pending (3 axes × 5 steps), reduced_motion / high_contrast / dark_mode
- `macos_glass_env_response_spec.cr` — 15 pending, parallel

Total: 80 pending Phase 5 probes. Each placeholder body documents the expected shape (`Expected shape (Phase 6.5 will implement)`) and the AX identifier the harness will hook into. NOT vacuous.

## Brand override demo

`samples/cross_platform/web/brand_glass_intensity_demo.cr` runs EXIT=0, emits 5 ap-glass--<step> divs wrapped in a parent with `--ap-material-intensity: 1.3`. The calc() expressions in --ap-material-blur-<step> reference var(--ap-material-intensity), so the brand cascade is observable in the rendered output.

## Architectural concerns I want Codex to challenge

1. **Brief claims `1.8+ → .chromeMaterial`. SwiftUI does not expose `.chromeMaterial`.** Spike comment acknowledges chrome maps to `.bar`; the actual facade maps key "ultraThick" → `.ultraThickMaterial`. Crystal-side apple_step still returns :chrome. Crystal Material populator maps :chrome → "ultraThick". Brief text and code path diverge: brief promises `.chromeMaterial`, code delivers `.ultraThickMaterial`. Is this a contract break or documented degradation?
2. **I-8 (env-response) has no production code paths.** Implementation delegates entirely to SwiftUI's built-in respect of accessibility flags + @media (prefers-color-scheme) via WebGenerator's emit_media_dark. No code path checks reduced-motion or forced-colors for material specifically. Is "delegation" sufficient for an `extends` invariant?
3. **macOS AXTest TCC failure** — should I be more defensive and rebuild the binary under different signing to confirm?
