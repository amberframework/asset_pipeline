Reading additional input from stdin...
OpenAI Codex v0.130.0
--------
workdir: /Users/crimsonknight/open_source_coding_projects/asset_pipeline
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR, /Users/crimsonknight/.codex/memories]
reasoning effort: xhigh
reasoning summaries: none
session id: 019e50e4-6ba8-74d2-83b3-4bd446af9a2e
--------
user
Read /tmp/p5-validator-draft.md and the actual Phase 5 implementation at /Users/crimsonknight/open_source_coding_projects/asset_pipeline. The branch is phase-05-glass-material-tokenization at HEAD 9037cc7. Key files: docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml, src/ui/design_tokens/material.cr, src/ui/renderers/{web,uikit,appkit,android}_renderer.cr, src/ui/design_tokens/generators/web_generator.cr, src/ui/native/swiftkit_overrides.cr, swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift, spikes/swiftui_material_spike.swift, spec/ui/glass_material/*.cr. Does my verdict accurately reflect what Phase 5 delivered? Specifically: are any 'preserves' invariants actually 'extends' I missed? Did the implementer make any architectural choice that breaks a brief contract decision but I have not flagged? Are the 6 Phase 5 probe specs at spec/ui/glass_material/ genuinely placeholder-shaped (pending blocks with declared slug/identifier names), or are they vacuous? Be brutal — this is the first validation under the new forcing function and I need it to land cleanly. Address the three architectural concerns I flagged at the bottom of the draft.
codex
I’ll check the draft against the actual branch state and the Phase 5 brief, then verify the probe specs and the three concerns directly from code rather than assuming the draft is right.
exec
/bin/zsh -lc "sed -n '1,240p' /tmp/p5-validator-draft.md" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
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

exec
/bin/zsh -lc 'rg -n "Phase 5|glass|material|phase-05|asset_pipeline|milestone one is web only|vanilla JS only" /Users/crimsonknight/.codex/memories/MEMORY.md' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
132:applies_to: cwd=/Users/crimsonknight/personal_coding_projects; reuse_rule=reuse for Asset Pipeline planning/handoff work that originated from the planning context here, but treat repo-path, branch, and worktree-status details as checkout-specific and revalidate against /Users/crimsonknight/open_source_coding_projects/asset_pipeline before implementation.
138:- rollout_summaries/2026-05-07T12-14-56-b2nZ-asset_pipeline_plan_critique_and_agent_handoff_prompt.md (cwd=/Users/crimsonknight/personal_coding_projects, rollout_path=/Users/crimsonknight/.codex/sessions/2026/05/07/rollout-2026-05-07T08-14-56-019e025c-cb3c-7bb1-9aba-3ca4b2f2592f.jsonl, updated_at=2026-05-07T15:45:33+00:00, thread_id=019e025c-cb3c-7bb1-9aba-3ca4b2f2592f, corrected repo/scope/dependency assumptions and upgraded validation language)
142:- asset_pipeline, /Users/crimsonknight/open_source_coding_projects/asset_pipeline, happy_coach/lib/asset_pipeline, milestone one is web only, vanilla JS only, no Stimulus, external font CDNs are allowed, validation matrix, pre-flight packet, acceptance evidence, screenshot critique
148:- rollout_summaries/2026-05-07T12-14-56-b2nZ-asset_pipeline_plan_critique_and_agent_handoff_prompt.md (cwd=/Users/crimsonknight/personal_coding_projects, rollout_path=/Users/crimsonknight/.codex/sessions/2026/05/07/rollout-2026-05-07T08-14-56-019e025c-cb3c-7bb1-9aba-3ca4b2f2592f.jsonl, updated_at=2026-05-07T15:45:33+00:00, thread_id=019e025c-cb3c-7bb1-9aba-3ca4b2f2592f, handoff prompt captured final constraints and reporting contract)
157:- when scoping Asset Pipeline work, the user corrected: "milestone one is web only" -> default to web-first scope and defer native follow-on work unless the user expands scope [Task 1]
158:- when choosing client-side implementation style, the user said "vanilla JS only" and "no Stimulus" -> use plain JS helpers and avoid framework-specific helpers unless the user reopens that constraint [Task 1]
170:- The canonical Asset Pipeline repo for future implementation is `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`; `/Users/crimsonknight/personal_coding_projects/happy_coach/lib/asset_pipeline` was explicitly rejected as the wrong source tree [Task 1]
177:- Checkout-specific note from the reviewed rollout: the canonical repo was on branch `feature/utility-first-css-asset-pipeline` and had unrelated dirty worktree changes in `.claude/skills/apple-platform-guide/validation/evidence/`, `docs/android-material-validation/screenshots/`, and `samples/cross_platform/`; preserve those if they are still unrelated and the user has not asked for cleanup [Task 1]
184:- Symptom: a prompt or plan accidentally hard-codes the wrong repo assumption. Cause: drafting against stale earlier notes. Fix: reassert the corrected canonical repo path in the final prompt and, when useful, explicitly say not to implement in `happy_coach/lib/asset_pipeline` [Task 2]

exec
/bin/zsh -lc 'pwd && git status --short && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
/Users/crimsonknight/open_source_coding_projects/asset_pipeline
 M docs/initiative-cross-platform-ui/MASTER_PLAN.md
 M docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter5/screenshots/BX2-final.png
 M docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter5/screenshots/BX7-form-rendered.png
 M docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md
 M docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/README.md
 M docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/README.md
 M docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/implementation.md
 M docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/validation.md
 M spec/test_js/some_js.js
?? .ax_probe.cr
?? .ax_probe2.cr
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/
?? docs/initiative-cross-platform-ui/handoff/planning-retrospective-2026-05-22.md
?? docs/initiative-cross-platform-ui/handoff/stock-taking-2026-05-22.md
?? docs/initiative-cross-platform-ui/phases/phase-06.5-audit-infrastructure-first/
?? docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/implementation.stale-pre-2026-05-22.md
?? docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/validation.stale-pre-2026-05-22.md
?? docs/initiative-cross-platform-ui/schemas/
?? scripts/validate_phase_brief.cr
?? spikes/
phase-05-glass-material-tokenization
9037cc7545768e089099b456dd0bf35b8212eac0

codex
The checkout is on `phase-05-glass-material-tokenization` at `9037cc7`, but the worktree is dirty and `spikes/` is untracked. I’m going to read committed `HEAD` for Phase 5 contracts and call out separately when the draft appears to rely on uncommitted evidence.
exec
/bin/zsh -lc 'git ls-tree -r --name-only HEAD docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization src/ui/design_tokens src/ui/renderers src/ui/design_tokens/generators src/ui/native swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades spikes spec/ui/glass_material' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md
spec/ui/glass_material/ios_glass_contrast_spec.cr
spec/ui/glass_material/ios_glass_default_spec.cr
spec/ui/glass_material/ios_glass_env_response_spec.cr
spec/ui/glass_material/macos_glass_contrast_spec.cr
spec/ui/glass_material/macos_glass_default_spec.cr
spec/ui/glass_material/macos_glass_env_response_spec.cr
src/ui/design_tokens/conversion.cr
src/ui/design_tokens/dist/AssetPipelineTokens.swift
src/ui/design_tokens/dist/web_tokens.css
src/ui/design_tokens/generators/apple_generator.cr
src/ui/design_tokens/generators/web_generator.cr
src/ui/design_tokens/material.cr
src/ui/native/android_bridge.c
src/ui/native/callback_registry.cr
src/ui/native/handle_tracker.cr
src/ui/native/jni_collection_bridge.c
src/ui/native/jni_collections.cr
src/ui/native/jni_handle.cr
src/ui/native/lib_objc_runtime.cr
src/ui/native/native_handle.cr
src/ui/native/native_view.cr
src/ui/native/objc_bridge.m
src/ui/native/objc_collections.cr
src/ui/native/objc_handle.cr
src/ui/native/release_strategy.cr
src/ui/native/swiftkit_bridge.cr
src/ui/native/swiftkit_bridge.m
src/ui/native/swiftkit_overrides.cr
src/ui/renderers/android_renderer.cr
src/ui/renderers/appkit_renderer.cr
src/ui/renderers/uikit_renderer.cr
src/ui/renderers/web_renderer.cr
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/AlertFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/CardFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/CheckboxFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ColorPickerFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ConfirmationDialogFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/DatePickerFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/DividerFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/FormFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GridFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/IconButtonFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ImageFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LabelFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LinkButtonFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ListViewFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/MenuButtonFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/NavigationLinkFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/NavigationSplitViewFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/NavigationStackFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/PickerFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/PopoverFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/RadioGroupFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SearchFieldFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SecureFieldFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SegmentedControlFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SliderFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SpacerFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/StepperFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SurfaceFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TabViewFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextAreaFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextEditorFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextFieldFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TimePickerFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ToggleButtonFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ToggleFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ToolbarFacade.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift

exec
/bin/zsh -lc 'git show --stat --oneline --decorate HEAD' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
9037cc7 (HEAD -> phase-05-glass-material-tokenization) [Phase 4 cleanup] iOS hig_bridge uses PathControlWithWebFallback per gating contract
 samples/cross_platform/ios_host/hig_bridge.cr | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

exec
/bin/zsh -lc 'git show HEAD:docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
phase:
  number: 5
  name: "Glass Material Tokenization"
  branch: "phase-05-glass-material-tokenization"
  parent_branch: "feature/utility-first-css-asset-pipeline"
  parent_sha: "2285fa1"
  authored_at: "2026-05-22"

# Phase 5 contract decisions baked into this brief (per Codex round-2 antagonist
# review of brief draft 1):
#
# 1. Material tokens are render-time resolved values. `tokens.material.intensity`
#    is a brand-declaration-time scalar; consumers re-render to see changes.
#    I-2 (forward reactive) is therefore `preserves` — Phase 5 does NOT add a
#    runtime mutator path for material. I-10 (API contract fidelity) documents
#    this as the contract limitation.
#
# 2. SwiftUI's discrete Material enum quantizes the Float64 intensity scalar.
#    Documented in adapter_cardinality with the exact quantization table.
#
# 3. Android renderer code lands in Phase 5 (the Crystal-side RenderEffect
#    emission). Android probe verification is Phase 6.5's responsibility
#    per the audit-first lesson. Brief reflects this: Android cells `extends`
#    with skip records explaining the implementation lands here, verification
#    later.
#
# 4. SwiftUI Material API assumption verified via a Swift compile spike at
#    spikes/swiftui_material_spike.swift (architect authored 2026-05-22).
#
# 5. Phase 5 does NOT introduce new ObservableObjects, new C-export mutators,
#    or new retained state handles on the Swift side. If implementation
#    discovers reactive material is needed, scope expansion surfaces to
#    architect before extending.

invariant_matrix:
  - id: I-1
    name: "Render correctly"
    touch: extends
    rationale: "Phase introduces tokenized blur/opacity/saturation/luminance values per material step + an intensity scalar that quantizes through to the SwiftUI Material enum on Apple, scales backdrop-filter blur radius on web, and scales RenderEffect blur radius on Android API 31+. Visible glass surface changes when material.intensity shifts at brand-declaration time. Phase 5 implementer authors the per-step visual baseline probes."
    probes:
      ios:
        skip: true
        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_default_spec.cr that captures and diffs glass appearance per material step. Probe harness path is Phase 6.5 work; until then validator architect-adjudicates pending Phase 6.5 ship."
        owner_approved: "2026-05-22"
      macos:
        skip: true
        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_default_spec.cr; same as iOS — verification harness is Phase 6.5"
        owner_approved: "2026-05-22"
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Phase 5 ships Android-side RenderEffect emission code; Android empirical verification is Phase 6.5's audit harness deliverable per Phase 1 #17 precedent"
        owner_approved: "2026-05-22"

  - id: I-2
    name: "Update reactively (forward)"
    touch: preserves
    rationale: "Material tokens are RENDER-TIME RESOLVED VALUES. Phase 5 does NOT add a runtime mutator path for material.intensity. Consumers re-render the view tree to see intensity changes; the existing Phase 3 reactive bridge (Label/Button/Toggle/Slider/Sheet) is unchanged. This is a deliberate contract limitation; see I-10 for the documented API contract."
    probes:
      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Android probe harness is Phase 6.5 work per audit-first principle"
        owner_approved: "2026-05-22"

  - id: I-3
    name: "Dispatch events (backward)"
    touch: preserves
    rationale: "Glass material is a pure render-side concern; no new event paths, no new callback registration, no new main-thread/run-loop semantics introduced. Existing Phase 3 R4 + R10 event paths remain authoritative."
    probes:
      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Android probe harness is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-4
    name: "Restore focus"
    touch: preserves
    rationale: "Material tokenization does not change focus order or focus-visible behavior. Glass surfaces remain transparent to focus traversal; child controls retain their focus contract."
    probes:
      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Android probe harness is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-5
    name: "Manage lifecycle"
    touch: preserves
    rationale: "GlassBackground widget API unchanged per scope summary; no new mount/unmount/teardown paths. Token-resolution happens during the existing render pass."
    probes:
      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Android probe harness is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-6
    name: "Propagate accessibility"
    touch: extends
    rationale: "Glass surfaces sit behind text. WCAG-AA contrast must hold for text-on-blurred-background at every material step AND at every intensity value (including the documented 1.3 brand-override example in the README). This is a NEW audit dimension Phase 5 introduces. Dynamic-type response on glass surfaces also belongs here (text must still meet contrast at largest type sizes). Phase 5 implementer authors the contrast audit probes."
    probes:
      ios:
        skip: true
        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_contrast_spec.cr (text-on-each-material-step AA contrast verification); harness is Phase 6.5"
        owner_approved: "2026-05-22"
      macos:
        skip: true
        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_contrast_spec.cr; harness is Phase 6.5"
        owner_approved: "2026-05-22"
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Android contrast audit harness is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-7
    name: "Manage memory ownership"
    touch: preserves
    rationale: "Per the I-9 commitment below, Phase 5 introduces NO new C-export mutators, no new ObservableObjects on the Swift side, no new retained handles on Crystal side. Material values are pure Crystal Float64/Float32 fields resolved at render time and passed by value through the existing bridge."
    probes:
      ios: "spec/asset_pipeline_spec.cr"
      macos: "spec/asset_pipeline_spec.cr"
      web: "spec/asset_pipeline_spec.cr"
      android:
        skip: true
        reason: "Android probe harness is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-8
    name: "Honor environment"
    touch: extends
    rationale: "Glass intensity must respond to reduced-motion (suppress or reduce blur animation if any) AND to high-contrast (Phase 5 must decide: suppress translucency OR strengthen contrast token alongside material). Dark-mode tracking is required for the per-step opacity baseline. RTL/locale are not relevant for material itself. NEW env-response audit surface Phase 5 introduces."
    probes:
      ios:
        skip: true
        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_env_response_spec.cr (reduced-motion / high-contrast / dark-mode cells)"
        owner_approved: "2026-05-22"
      macos:
        skip: true
        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_env_response_spec.cr"
        owner_approved: "2026-05-22"
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Android env-response probe harness is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-9
    name: "Survive embedding"
    touch: preserves
    rationale: "Phase 5 introduces NO new Crystal class vars with initializers AND NO new Crystal::once-protected lazy lookups (token VALUES live in existing Tokens struct instances; resolution is method dispatch, not lazy class-var init). The class-init systematic fix remains deferred to a future phase. If Phase 5 implementer discovers a new class-var is required (e.g., for a material-specific singleton), the implementer MUST stop and surface to architect — the new class-var requires either (a) explicit .reset in hig_bridge.cr#initialize_runtime, OR (b) lazy-instance pattern with nil default and method-side initialization."
    probes:
      ios: "spec/asset_pipeline_spec.cr"
      macos: "spec/asset_pipeline_spec.cr"
      web:
        skip: true
        reason: "No embedding on web; the web target is the host language's natural runtime"
        owner_approved: "2026-05-22"
      android:
        skip: true
        reason: "Android probe harness is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-10
    name: "API/fallback contract fidelity"
    touch: extends
    rationale: "New public token API: tokens.material with per-step blur/opacity/saturation/luminance + intensity Float64 scalar. Phase 5 commits to: (1) intensity is RENDER-TIME ONLY — runtime mutation requires a re-render of the view tree; (2) SwiftUI Material's discrete enum quantizes intensity (see adapter_cardinality row 1); (3) web @supports fallback for backdrop-filter unavailability; (4) Android API < 31 alpha-fallback. All four are documented contract limitations consumers MUST understand."
    probes:
      ios: "spec/asset_pipeline_spec.cr"
      macos: "spec/asset_pipeline_spec.cr"
      web: "crystal-alpha run scripts/validate_web_demo.cr"
      android:
        skip: true
        reason: "Android API-contract probe is Phase 6.5"
        owner_approved: "2026-05-22"

  - id: I-11
    name: "Target build / link / load closure"
    touch: extends
    rationale: "Phase 5 modifies all 4 renderers (uikit/appkit/web/android). Each target's link closure must still resolve after token-resolution paths are added. If Phase 5 calls into SwiftUI Material at the Swift-side facade, the linker must still find the symbols on iOS 26.5 + macOS 26.5 SDKs."
    probes:
      ios: "bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator"
      macos: "make -C samples/cross_platform/macos_host build"
      web: "crystal-alpha build --no-codegen src/asset_pipeline.cr"
      android:
        skip: true
        reason: "Android cross-build remains architect-precedent PASS per Phase 1 #17 (Crystal stdlib c/sys/epoll gap on darwin); Phase 5 ships Android renderer source but cannot verify cross-build until that gap is resolved separately"
        owner_approved: "2026-05-22"

lower_layer_assumptions:
  - id: A1
    claim: "SwiftUI Material API accepts the Material enum values Phase 5 emits (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .chromeMaterial) AND the .background(Material) modifier on a SwiftUI View on iOS 26.5 + macOS 26.5"
    falsifier: "Compiling spikes/swiftui_material_spike.swift returns non-zero exit on either iOS or macOS"
    verification: "test -f spikes/swiftui_material_spike.swift && xcrun --sdk iphonesimulator swiftc -emit-library -target arm64-apple-ios16.0-simulator -o /tmp/spike-ios.dylib spikes/swiftui_material_spike.swift && xcrun --sdk macosx swiftc -emit-library -o /tmp/spike-macos.dylib spikes/swiftui_material_spike.swift"

  - id: A2
    claim: "Crystal toolchain is available as either crystal-alpha or crystal at expected paths"
    falsifier: "which returns non-zero for both"
    verification: "which crystal-alpha || which crystal"

  - id: A3
    claim: "GlassBackground references in src/ + samples/ post-Phase-5 number exactly 46 (binary files excluded) — pre-dispatch was 37 at SHA 2285fa1; Phase 5 added references in samples + specs"
    falsifier: "grep count differs from 46"
    verification: "test \"$(grep -rEnI 'GlassBackground|glass_background' src/ samples/ | wc -l | tr -d ' ')\" = \"46\""

  - id: A4
    claim: "Web renderer post-Phase-5 has exactly 4 backdrop-filter occurrences (the standard + -webkit- prefix variants on each of the 2 touched call sites). Pre-dispatch was 2 at SHA 2285fa1."
    falsifier: "grep count differs from 4"
    verification: "test \"$(grep -c 'backdrop-filter' src/ui/renderers/web_renderer.cr | tr -d ' ')\" = \"4\""

  - id: A5
    claim: "Android renderer's existing GlassBackground visit method uses semi-transparent FrameLayout placeholder (no real blur) — Phase 5 will replace with RenderEffect on API 31+ + alpha-fallback below"
    falsifier: "grep does not find FrameLayout in android_renderer.cr's GlassBackground visit"
    verification: "grep -A 30 'visit(view : UI::GlassBackground)' src/ui/renderers/android_renderer.cr | grep -q FrameLayout"

  - id: A6
    claim: "iOS renderer's existing GlassBackground path uses UIVisualEffectView + UIBlurEffect (will be replaced or extended with Material-based path)"
    falsifier: "neither UIVisualEffectView nor UIBlurEffect appears in uikit_renderer.cr"
    verification: "grep -qE 'UIVisualEffectView|UIBlurEffect' src/ui/renderers/uikit_renderer.cr"

repo_derived_facts:
  - fact: "GlassBackground usage count in src/ and samples/ (binary files excluded)"
    query: "grep -rEnI 'GlassBackground|glass_background' src/ samples/ | wc -l | tr -d ' '"
    expected: "46"
    captured_at_sha: "01e66c7"
    # Pre-dispatch the count was 37 at SHA 2285fa1; Phase 5 implementation
    # added references in src/ui/design_tokens/material.cr (doc comments),
    # samples/cross_platform/web/brand_glass_intensity_demo.cr (the brand
    # cascade demo), and the spec/ui/glass_material/ probe placeholders.
    # The brief's pre-dispatch contract was honored at 2285fa1; this
    # value is updated post-implementation so subsequent phase briefs
    # reading this fact see the actual current state.

  - fact: "backdrop-filter emission count in web_renderer.cr"
    query: "grep -c 'backdrop-filter' src/ui/renderers/web_renderer.cr | tr -d ' '"
    expected: "4"
    captured_at_sha: "01e66c7"
    # Pre-dispatch count was 2 at SHA 2285fa1; Phase 5 tokenization added
    # explicit -webkit-backdrop-filter prefixes alongside the standard
    # backdrop-filter calls on both touched sites (GlassBackground +
    # ActivityView), bringing the count to 4. The tokenization eliminated
    # the hard-coded `blur(Xpx)` literals; both emission sites now route
    # through var(--ap-material-blur-<step>).

  - fact: "Existing design_tokens.cr file size in bytes (sanity: editing the right file)"
    query: "wc -c < src/ui/design_tokens.cr | tr -d ' '"
    expected: "37252"
    captured_at_sha: "01e66c7"
    # Pre-dispatch size was 35311 at SHA 2285fa1; Phase 5 added the
    # Material getter on Tokens, the override_material hook on Brand,
    # the material parameter on copy_with, and the Defaults.material
    # factory. Net growth: ~1941 bytes.

  - fact: "Android renderer alpha-step hex literals (5 material steps + 1 default fallback = 6)"
    query: "grep -cE '0x[0-9A-F]{2}FFFFFF' src/ui/renderers/android_renderer.cr | tr -d ' '"
    expected: "1"
    captured_at_sha: "01e66c7"
    # Pre-dispatch count was 6 at SHA 2285fa1 (the hard-coded
    # 0x33/0x66/0x99/0xBB/0xDD per-step alpha table + the default
    # fallback). Phase 5 replaced the table with token-driven
    # composition; the remaining single literal is the `0x00FFFFFF`
    # white mask used by the fallback-ARGB composition helper.
    # DROPPING FROM 6 -> 1 IS THE INTENDED PHASE 5 OUTCOME.

  - fact: "iOS renderer UIVisualEffectView/UIBlurEffect references that Phase 5 may touch (includes comments + code)"
    query: "grep -cE 'UIVisualEffectView|UIBlurEffect' src/ui/renderers/uikit_renderer.cr | tr -d ' '"
    expected: "60"
    captured_at_sha: "2285fa1"

  - fact: "macOS renderer NSVisualEffectView references that Phase 5 may touch (includes comments + code)"
    query: "grep -c 'NSVisualEffectView' src/ui/renderers/appkit_renderer.cr | tr -d ' '"
    expected: "37"
    captured_at_sha: "2285fa1"

adapter_cardinality:
  - public_api: "UI::DesignTokens::Material#intensity (Float64 scalar; documented multiplicative in [0.0, 2.0])"
    adapter: "SwiftUI Material enum on iOS/macOS (.ultraThinMaterial / .thinMaterial / .regularMaterial / .thickMaterial / .chromeMaterial)"
    adapter_input_space: "5 discrete material steps; no fractional intensity"
    api_input_space: "Float64 in [0.0, 2.0]"
    match_status: "MISMATCH"
    documented_degradation: "QUANTIZATION TABLE (consumer-visible): intensity 0.0–0.3 → .ultraThinMaterial; 0.3–0.7 → .thinMaterial; 0.7–1.3 → .regularMaterial; 1.3–1.8 → .thickMaterial; 1.8+ → .chromeMaterial. Consequence: README's example `intensity = 1.3` quantizes to .regularMaterial on Apple (visually IDENTICAL to default intensity 1.0). Brands wanting a more-frosted Apple look must declare a STEP override (e.g. tokens.material.default_step = :thick) rather than a fractional intensity. This is the documented contract limitation per I-10."
    owner_approved: "2026-05-22"

  - public_api: "UI::DesignTokens::Material#blur_radius (Float64 px, per material step, scaled by intensity)"
    adapter: "CSS backdrop-filter: blur() on web"
    adapter_input_space: "Float64 px; supported in modern browsers; absent in older browsers"
    api_input_space: "Float64 px"
    match_status: "MISMATCH"
    documented_degradation: "Browsers without backdrop-filter (detected via @supports not (backdrop-filter: blur(1px))) fall back to background-color: color-mix(in oklch, var(--ap-color-surface-panel) Z%, transparent) where Z is per-step opacity (ultra_thin=20%, thin=40%, regular=60%, thick=73%, chrome=87%). No blur. WCAG-AA contrast verified for text-on-fallback as well as text-on-blurred. Visible glass surfaces remain visually distinguishable via opacity alone."
    owner_approved: "2026-05-22"

  - public_api: "UI::DesignTokens::Material#blur_radius (Float64 px)"
    adapter: "Android RenderEffect.createBlurEffect (API 31+) or alpha FrameLayout fallback (< API 31)"
    adapter_input_space: "Float64 px on API 31+; null on < API 31"
    api_input_space: "Float64 px"
    match_status: "MISMATCH"
    documented_degradation: "Android API < 31 degrades to FrameLayout with alpha-only background at per-step opacity (matching web fallback's opacity values). No blur. WCAG-AA contrast verified for text-on-alpha-fallback. This is the existing Phase 4-era behavior; Phase 5 keeps it for < API 31 and adds RenderEffect on API 31+."
    owner_approved: "2026-05-22"

pre_dispatch_validation:
  script_path: "scripts/validate_phase_brief.cr"
  expected_exit_code: 0

exec
/bin/zsh -lc 'rg -n "I-[0-9]|preserves|extends|contract|decision|chromeMaterial|ultra|ObservableObject|reduced|contrast|motion|fallback|probe|pending|placeholder" docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization /tmp/p5-validator-draft.md' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
/tmp/p5-validator-draft.md:4:**PASS** — all 11 invariants delivered or preserved; all 5 contract decisions honored; all prior-phase baselines hold.
/tmp/p5-validator-draft.md:14:| I-1 | extends | web renderer emits `--ap-material-{blur,opacity,saturation}-{step}` w/ `calc()` intensity; uikit/appkit call `apple_step`; android `android_view_apply_glass`; web demo + brand glass intensity demo render | PASS (probe harness for ios/macos/android = Phase 6.5, brief acknowledges) |
/tmp/p5-validator-draft.md:15:| I-2 | preserves | render-time resolution only; no def *= on Material; existing Phase 3 reactive bridge unchanged | PASS |
/tmp/p5-validator-draft.md:16:| I-3 | preserves | glass = pure render side; no new event paths | PASS |
/tmp/p5-validator-draft.md:17:| I-4 | preserves | no focus changes | PASS |
/tmp/p5-validator-draft.md:18:| I-5 | preserves | GlassBackground widget API unchanged | PASS |
/tmp/p5-validator-draft.md:19:| I-6 | extends | web @supports not (backdrop-filter) fallback emitted by WebGenerator emit_supports_fallback | PASS (web only verified; iOS/macOS/Android contrast probes are Phase 6.5) |
/tmp/p5-validator-draft.md:20:| I-7 | preserves | grep ObservableObject in Facades/: PRE=4 files, POST=4 files (no new) | PASS |
/tmp/p5-validator-draft.md:21:| I-8 | extends | env-response: implementation delegates to SwiftUI Material's built-in reduced-motion/high-contrast tracking + dark-mode via @media (prefers-color-scheme). Brief documents Phase 5 ships pending Phase 6.5 harness | PASS-with-note: no production code paths for prefers-reduced-motion / forced-colors — delegation-to-SwiftUI is the documented contract |
/tmp/p5-validator-draft.md:22:| I-9 | preserves | grep @@<id>\s*:.*= in views + design_tokens: PRE=0, POST=0 | PASS |
/tmp/p5-validator-draft.md:23:| I-10 | extends | quantization table in Material#apple_step matches brief; web @supports fallback; Android API<31 alpha fallback all in code | PASS |
/tmp/p5-validator-draft.md:24:| I-11 | extends | web no-codegen build OK; iOS build_crystal_lib.sh simulator OK; macOS host make build OK; android skipped per Phase 1 #17 precedent | PASS |
/tmp/p5-validator-draft.md:26:## Contract decision verification
/tmp/p5-validator-draft.md:34:| 5 | No new ObservableObjects | YES — grep ObservableObject Facades/: 4 files PRE, 4 files POST |
/tmp/p5-validator-draft.md:40:- **Phase 4 CDP harness:** 14/14 probes, any_failed=false ✅
/tmp/p5-validator-draft.md:42:- **crystal spec:** 1447 examples, 4 failures, 0 errors, 80 pending. The 4 failures are the documented pre-existing baseline (1 UI::Theme inject_theme_css + 3 Phase 2 Verification component composition specs). The 80 pending are exactly the Phase 5 probe placeholders ✅
/tmp/p5-validator-draft.md:44:## Phase 5 probe placeholders
/tmp/p5-validator-draft.md:47:- `ios_glass_default_spec.cr` — 5 pending (ultra_thin..chrome) with slug `ios.glass.material.default` and AX identifier convention `ap.glass.<step>.intensity_<intensity_x100>` documented
/tmp/p5-validator-draft.md:48:- `macos_glass_default_spec.cr` — 5 pending, parallel macOS version
/tmp/p5-validator-draft.md:49:- `ios_glass_contrast_spec.cr` — 20 pending (4 intensities × 5 steps) with slug `ios.glass.material.contrast.wcag_aa` and identifier `ap.glass.contrast.<step>.intensity_<intensity_x100>`
/tmp/p5-validator-draft.md:50:- `macos_glass_contrast_spec.cr` — 20 pending, parallel
/tmp/p5-validator-draft.md:51:- `ios_glass_env_response_spec.cr` — 15 pending (3 axes × 5 steps), reduced_motion / high_contrast / dark_mode
/tmp/p5-validator-draft.md:52:- `macos_glass_env_response_spec.cr` — 15 pending, parallel
/tmp/p5-validator-draft.md:54:Total: 80 pending Phase 5 probes. Each placeholder body documents the expected shape (`Expected shape (Phase 6.5 will implement)`) and the AX identifier the harness will hook into. NOT vacuous.
/tmp/p5-validator-draft.md:62:1. **Brief claims `1.8+ → .chromeMaterial`. SwiftUI does not expose `.chromeMaterial`.** Spike comment acknowledges chrome maps to `.bar`; the actual facade maps key "ultraThick" → `.ultraThickMaterial`. Crystal-side apple_step still returns :chrome. Crystal Material populator maps :chrome → "ultraThick". Brief text and code path diverge: brief promises `.chromeMaterial`, code delivers `.ultraThickMaterial`. Is this a contract break or documented degradation?
/tmp/p5-validator-draft.md:63:2. **I-8 (env-response) has no production code paths.** Implementation delegates entirely to SwiftUI's built-in respect of accessibility flags + @media (prefers-color-scheme) via WebGenerator's emit_media_dark. No code path checks reduced-motion or forced-colors for material specifically. Is "delegation" sufficient for an `extends` invariant?
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:14:- **iOS:** `UIVisualEffectView` + `UIBlurEffect` with system materials (ultra_thin, thin, regular, thick, chrome) — **works correctly** but the material strength is hard-coded in `uikit_renderer.cr`, not driven by a token.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:16:- **Web:** `backdrop-filter: blur(Xpx)` with hard-coded blur amounts (`:ultra_thin` → 10px) and a hard-coded 72% opacity color-mix. **Static approximation.** No fallback for browsers without `backdrop-filter`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:28:  - The five material strength steps (`ultra_thin`, `thin`, `regular`, `thick`, `chrome`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:33:  - `web_renderer.cr`: emit `backdrop-filter: blur(var(--ap-material-blur-{step}))` with the variable computed from `tokens.material.blur * tokens.material.intensity`. Add `-webkit-` prefix. Add fallback color for browsers without `backdrop-filter` (detected via `@supports not (backdrop-filter: blur(1px))`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:38:  - Web CSS emission (correct `clamp` / `var()` references, `@supports` fallback present).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:40:  - Android: verify the API-31 branch and the fallback branch both compile and produce reasonable visual output.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:45:- Animated material transitions (e.g., glass "fluidifying" when scrolled over). The user can declare a motion token to animate intensity, but the renderers in this phase don't do animation orchestration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:53:- Web glass uses `@supports` fallback correctly: in a browser without `backdrop-filter` (test by overriding the support check), the surface falls back to the documented solid color with appropriate opacity.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:54:- Android sample app on API 31+ shows a real blur. On API 30 and below, shows the semi-transparent fallback.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:69:- **Phase Brief (YAML, validator-enforced):** `brief.yml` — passes `crystal run scripts/validate_phase_brief.cr -- phases/phase-05-glass-material-tokenization/brief.yml` (exit 0 mandatory before dispatch). Declares all 11 invariant cells, lower-layer assumptions about SwiftUI Material API + backdrop-filter support + Android RenderEffect, repo-derived facts (37 GlassBackground references, 2 backdrop-filter sites in web_renderer.cr, 35311-byte design_tokens.cr), and 3 adapter cardinality MISMATCH rows for SwiftUI's discrete material enum, web `@supports` fallback, and Android < API 31 fallback. Architect-authored 2026-05-22 per `handoff/planning-retrospective-2026-05-22.md` Phase Brief Template.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:9:# Phase 5 contract decisions baked into this brief (per Codex round-2 antagonist
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:14:#    I-2 (forward reactive) is therefore `preserves` — Phase 5 does NOT add a
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:15:#    runtime mutator path for material. I-10 (API contract fidelity) documents
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:16:#    this as the contract limitation.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:22:#    emission). Android probe verification is Phase 6.5's responsibility
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:23:#    per the audit-first lesson. Brief reflects this: Android cells `extends`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:30:# 5. Phase 5 does NOT introduce new ObservableObjects, new C-export mutators,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:36:  - id: I-1
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:38:    touch: extends
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:39:    rationale: "Phase introduces tokenized blur/opacity/saturation/luminance values per material step + an intensity scalar that quantizes through to the SwiftUI Material enum on Apple, scales backdrop-filter blur radius on web, and scales RenderEffect blur radius on Android API 31+. Visible glass surface changes when material.intensity shifts at brand-declaration time. Phase 5 implementer authors the per-step visual baseline probes."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:40:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:43:        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_default_spec.cr that captures and diffs glass appearance per material step. Probe harness path is Phase 6.5 work; until then validator architect-adjudicates pending Phase 6.5 ship."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:55:  - id: I-2
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:57:    touch: preserves
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:58:    rationale: "Material tokens are RENDER-TIME RESOLVED VALUES. Phase 5 does NOT add a runtime mutator path for material.intensity. Consumers re-render the view tree to see intensity changes; the existing Phase 3 reactive bridge (Label/Button/Toggle/Slider/Sheet) is unchanged. This is a deliberate contract limitation; see I-10 for the documented API contract."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:59:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:60:      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:61:      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:65:        reason: "Android probe harness is Phase 6.5 work per audit-first principle"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:68:  - id: I-3
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:70:    touch: preserves
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:72:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:73:      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:74:      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:78:        reason: "Android probe harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:81:  - id: I-4
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:83:    touch: preserves
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:84:    rationale: "Material tokenization does not change focus order or focus-visible behavior. Glass surfaces remain transparent to focus traversal; child controls retain their focus contract."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:85:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:86:      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:87:      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:91:        reason: "Android probe harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:94:  - id: I-5
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:96:    touch: preserves
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:98:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:99:      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:100:      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:104:        reason: "Android probe harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:107:  - id: I-6
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:109:    touch: extends
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:110:    rationale: "Glass surfaces sit behind text. WCAG-AA contrast must hold for text-on-blurred-background at every material step AND at every intensity value (including the documented 1.3 brand-override example in the README). This is a NEW audit dimension Phase 5 introduces. Dynamic-type response on glass surfaces also belongs here (text must still meet contrast at largest type sizes). Phase 5 implementer authors the contrast audit probes."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:111:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:114:        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_contrast_spec.cr (text-on-each-material-step AA contrast verification); harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:118:        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_contrast_spec.cr; harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:123:        reason: "Android contrast audit harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:126:  - id: I-7
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:128:    touch: preserves
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:129:    rationale: "Per the I-9 commitment below, Phase 5 introduces NO new C-export mutators, no new ObservableObjects on the Swift side, no new retained handles on Crystal side. Material values are pure Crystal Float64/Float32 fields resolved at render time and passed by value through the existing bridge."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:130:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:136:        reason: "Android probe harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:139:  - id: I-8
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:141:    touch: extends
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:142:    rationale: "Glass intensity must respond to reduced-motion (suppress or reduce blur animation if any) AND to high-contrast (Phase 5 must decide: suppress translucency OR strengthen contrast token alongside material). Dark-mode tracking is required for the per-step opacity baseline. RTL/locale are not relevant for material itself. NEW env-response audit surface Phase 5 introduces."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:143:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:146:        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_env_response_spec.cr (reduced-motion / high-contrast / dark-mode cells)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:155:        reason: "Android env-response probe harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:158:  - id: I-9
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:160:    touch: preserves
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:162:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:171:        reason: "Android probe harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:174:  - id: I-10
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:175:    name: "API/fallback contract fidelity"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:176:    touch: extends
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:177:    rationale: "New public token API: tokens.material with per-step blur/opacity/saturation/luminance + intensity Float64 scalar. Phase 5 commits to: (1) intensity is RENDER-TIME ONLY — runtime mutation requires a re-render of the view tree; (2) SwiftUI Material's discrete enum quantizes intensity (see adapter_cardinality row 1); (3) web @supports fallback for backdrop-filter unavailability; (4) Android API < 31 alpha-fallback. All four are documented contract limitations consumers MUST understand."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:178:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:184:        reason: "Android API-contract probe is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:187:  - id: I-11
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:189:    touch: extends
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:191:    probes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:202:    claim: "SwiftUI Material API accepts the Material enum values Phase 5 emits (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .chromeMaterial) AND the .background(Material) modifier on a SwiftUI View on iOS 26.5 + macOS 26.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:222:    claim: "Android renderer's existing GlassBackground visit method uses semi-transparent FrameLayout placeholder (no real blur) — Phase 5 will replace with RenderEffect on API 31+ + alpha-fallback below"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:239:    # cascade demo), and the spec/ui/glass_material/ probe placeholders.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:240:    # The brief's pre-dispatch contract was honored at 2285fa1; this
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:264:  - fact: "Android renderer alpha-step hex literals (5 material steps + 1 default fallback = 6)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:270:    # fallback). Phase 5 replaced the table with token-driven
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:272:    # white mask used by the fallback-ARGB composition helper.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:287:    adapter: "SwiftUI Material enum on iOS/macOS (.ultraThinMaterial / .thinMaterial / .regularMaterial / .thickMaterial / .chromeMaterial)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:291:    documented_degradation: "QUANTIZATION TABLE (consumer-visible): intensity 0.0–0.3 → .ultraThinMaterial; 0.3–0.7 → .thinMaterial; 0.7–1.3 → .regularMaterial; 1.3–1.8 → .thickMaterial; 1.8+ → .chromeMaterial. Consequence: README's example `intensity = 1.3` quantizes to .regularMaterial on Apple (visually IDENTICAL to default intensity 1.0). Brands wanting a more-frosted Apple look must declare a STEP override (e.g. tokens.material.default_step = :thick) rather than a fractional intensity. This is the documented contract limitation per I-10."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:299:    documented_degradation: "Browsers without backdrop-filter (detected via @supports not (backdrop-filter: blur(1px))) fall back to background-color: color-mix(in oklch, var(--ap-color-surface-panel) Z%, transparent) where Z is per-step opacity (ultra_thin=20%, thin=40%, regular=60%, thick=73%, chrome=87%). No blur. WCAG-AA contrast verified for text-on-fallback as well as text-on-blurred. Visible glass surfaces remain visually distinguishable via opacity alone."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:303:    adapter: "Android RenderEffect.createBlurEffect (API 31+) or alpha FrameLayout fallback (< API 31)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:307:    documented_degradation: "Android API < 31 degrades to FrameLayout with alpha-only background at per-step opacity (matching web fallback's opacity values). No blur. WCAG-AA contrast verified for text-on-alpha-fallback. This is the existing Phase 4-era behavior; Phase 5 keeps it for < API 31 and adds RenderEffect on API 31+."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:11:Promote glass material strength from hard-coded per-renderer constants to a first-class branch of the `UI::DesignTokens` system. Wire every renderer — web, AppKit, UIKit, and Android — to read material parameters from the resolved token tree. Add a brand-overridable `intensity` scalar so a single line in a brand declaration uniformly scales how frosted glass surfaces appear on all four platforms. Add a `@supports` fallback for web browsers without `backdrop-filter`. Add a real `RenderEffect.createBlurEffect` path on Android API 31+ with a graceful pre-API-31 fallback.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:26:- [ ] `src/ui/renderers/web_renderer.cr` lines 1335–1359 — current `GlassBackground` visit. Read also line 1786 (toast) for the existing solid-fallback color pattern.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:29:- [ ] `src/ui/renderers/android_renderer.cr` lines 2154–2189 — current placeholder.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:44:- `src/ui/renderers/web_renderer.cr` (lines 1335–1359 + 1786) — `GlassBackground` visit + toast solid fallback pattern.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:47:- `src/ui/renderers/android_renderer.cr` (lines 2154–2189 placeholder).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:48:- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift` — Phase 3's overrides class. Extend it with `intensity`, `blurDelta`, `opacityOverride`, `saturationOverride` fields per §SwiftUI bridge contract. If the file does not exist, Phase 3 has not landed — **stop and return early**.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:59:The prior audit (`handoff/plan-quality-audit-2026-05-20.md` §A) noted that Phase 5 references `LibSwiftKitBridge.material_parameters_new(...)` and `LibSwiftKitBridge.glass_background_overrides_new(...)`, but Phase 3 ships a `lib LibObjCBridge` plus a `SwiftKit` Crystal module — `LibSwiftKitBridge` was never explicitly named. Phase 3's revised "Existing infrastructure to use" section now creates `src/ui/native/lib_swiftkit_bridge.cr` as the typed wrapper. **Phase 5 references the same module — if you find `LibSwiftKitBridge` is not defined when you start Phase 5, the Phase 3 implementer did not ship the typed wrapper they were supposed to. Surface this to the team lead before freelancing.** The cross-phase naming contract is `LibSwiftKitBridge` (typed wrapper, defined in `src/ui/native/lib_swiftkit_bridge.cr`); do not coin a new name.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:65:| Material step set | `:ultra_thin, :thin, :regular, :thick, :chrome` | Five steps. Must match what `GlassBackground#material` accepts. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:69:| Android API gate | 31+ for `RenderEffect.createBlurEffect`, ≤ 30 fallback | Both paths invoke `AssetPipelineGlassHelper.applyGlass`. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:70:| `@supports` fallback opacity | 94% on `regular` tier (per phase brief) | Used when neither `backdrop-filter` nor `-webkit-backdrop-filter` are supported. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:132:        # Used by the fallback paths (web `@supports` fallback, Android pre-31)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:133:        # to bias the fallback fill color.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:151:      getter ultra_thin : Step
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:163:        @ultra_thin : Step,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:175:        when :ultra_thin then ultra_thin
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:218:| ultra_thin |                10.0 |    0.20 |             1.05 |      0.00 |  8 (UIBlurEffectStyleSystemUltraThinMaterial / NSVisualEffectMaterialUltraLight=9 — see note) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:263:## SwiftUI bridge contract
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:310:            // requested radius. Doing this preserves iOS 26 Liquid Glass
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:332:- `materialFromConstant(_:)` is a small switch mapping the canonical UIKit integer to the appropriate SwiftUI `Material` case (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`, `.chromeMaterial`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:379:## Web emission contract
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:381:The web renderer no longer hard-codes blur radii or opacity. It reads the resolved step from the token tree and emits CSS that references `var(--ap-material-blur-{step})` custom properties, plus a `@supports` fallback block.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:385:The CSS generator (Phase 1's `DesignTokens::WebGenerator`) emits these on the `:root` selector. Phase 5 extends the generator to include the material block:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:391:  --ap-material-blur-ultra-thin: calc(10px * var(--ap-material-intensity, 1));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:397:  --ap-material-opacity-ultra-thin: 0.20;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:403:  --ap-material-saturation-ultra-thin: 1.05;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:433:### `@supports` fallback block
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:439:  .ap-glass--ultra-thin { background: color-mix(in oklch, var(--ap-color-surface-panel) 90%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:447:The fallback uses higher opacity (90–98%) than the live values because without backdrop blur, a low-opacity fill reads as transparent muddiness rather than as a glass surface. The fallback aims to communicate "this is a panel" — not to fake the glass effect.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:451:Add `ap-glass` and `ap-glass--{step}` classes to the emitted `<div>`. Inline style still wins for the live `backdrop-filter` value; the class selectors exist for the `@supports` fallback to bind to. Do **not** delete the inline style — older user agents that don't support `@supports` need the inline form to render the live path.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:481:     * @param fallbackArgb 32-bit ARGB color used as background fill on API 30
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:484:     *         fallback solid fill was used
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:486:    public static boolean applyGlass(View view, float blurRadius, int fallbackArgb) {
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:494:                // Fall through to fallback fill.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:497:        view.setBackgroundColor(fallbackArgb);
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:505:In `src/ui/renderers/android_renderer.cr` (replacing the placeholder body at lines 2162–2189):
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:514:  fallback_argb = compose_argb(
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:526:    fallback_argb.to_i32,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:563:                    when 8_i64  then 9_i64   # ultraThin  -> UltraLight
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:608:2. **`[Phase 5] Generate material CSS custom properties + @supports fallback`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:609:   - Extend `DesignTokens::WebGenerator` to emit the `--ap-material-*` block and the `@supports not (backdrop-filter)` fallback rules.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:613:   - Replace `web_renderer.cr` lines 1335–1359 with the token-driven emission described in "Web emission contract."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:673:      material: :ultra_thin,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:674:      content: UI::Text.new("ultra_thin"),
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:736:5. The web stylesheet emits the `--ap-material-*` custom properties and the `@supports not (backdrop-filter)` fallback block. Verified by reading the generated CSS.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:34:**What:** `GlassBackground` at default intensity (`tokens.material.intensity == 1.0`) on iOS renders the platform-correct surface. On iOS 26+, Liquid Glass appears automatically (system Material). On iOS 15–25, regular blur via system Material. No fallback flat fill.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:39:**Pass:** Five visible glass tiers (ultra_thin → chrome) with a monotonically increasing frosted look. iOS 26+ Liquid Glass present (chromatic edge, dynamic specular highlight on motion). No flat-fill regression.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:57:### Check 3 — `glass.web-default-intensity-renders-with-supports-fallback`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:61:2. A `-webkit-backdrop-filter:` fallback in the same declaration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:68:4. To verify the `@supports` fallback path: temporarily override the support check in DevTools by adding a CSS rule that forces `.ap-glass--regular` to ignore `backdrop-filter` (set `backdrop-filter: none !important` in an inline `<style>` injected via the MCP). Confirm the panel does **not** become invisible — it must show the higher-opacity fallback fill. Capture this screenshot too. Revert the override before moving on.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:69:**Pass:** All four substrings above appear in the source. Live rendering shows blur. Forced-fallback rendering shows the documented higher-opacity solid panel (94% opacity for `regular`). Both screenshots clearly distinguishable.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:70:**Evidence:** `inspections/check-3-html-grep.txt`, `screenshots/check-3-web-live.png`, `screenshots/check-3-web-fallback.png`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:74:### Check 4 — `glass.android-default-intensity-renderseffect-or-fallback`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:76:**What:** On Android API 31+, `GlassBackground` produces a real `RenderEffect.createBlurEffect`-backed view. On API ≤30, it produces the documented semi-transparent fallback fill. Both paths invoke the `AssetPipelineGlassHelper.applyGlass` static method.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:127:- `uikit_renderer.cr` — `visit(view : UI::GlassBackground)` does not contain a `case view.material when :ultra_thin then 8_i64` switch (or equivalent); the integer comes from the resolved token.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:132:2. `grep -nB1 'when :ultra_thin\|when :thin\|when :regular\|when :thick\|when :chrome' src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr` and inspect every hit. **The only acceptable hits are inside the AppKit translation table**, identified by the marker comment on the line immediately above the case/switch block. The marker text must be exactly `# AppKit material translation table — only allowed hard-coded glass switch` (em dash `—`, not `--`). Any hit not preceded by this marker (within 1 line of context) is a fail.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:151:Pass = `0 errors, 0 failures, 0 pending` (pending tests are noted, not failed).

exec
/bin/zsh -lc 'git diff --name-only -- docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml src/ui/design_tokens/material.cr src/ui/renderers/web_renderer.cr src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr src/ui/renderers/android_renderer.cr src/ui/design_tokens/generators/web_generator.cr src/ui/native/swiftkit_overrides.cr swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift spec/ui/glass_material spikes/swiftui_material_spike.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
exec
/bin/zsh -lc 'git status --short -- docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml src/ui/design_tokens/material.cr src/ui/renderers/web_renderer.cr src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr src/ui/renderers/android_renderer.cr src/ui/design_tokens/generators/web_generator.cr src/ui/native/swiftkit_overrides.cr swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift spec/ui/glass_material spikes/swiftui_material_spike.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
?? spikes/swiftui_material_spike.swift

exec
/bin/zsh -lc 'ls -la spikes && git ls-files --error-unmatch spikes/swiftui_material_spike.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 exited 1 in 0ms:
total 8
drwxr-xr-x   3 crimsonknight  staff    96 May 22 14:08 .
drwxr-xr-x@ 42 crimsonknight  staff  1344 May 22 14:08 ..
-rw-r--r--   1 crimsonknight  staff  1834 May 22 14:08 swiftui_material_spike.swift
error: pathspec 'spikes/swiftui_material_spike.swift' did not match any file(s) known to git
Did you forget to 'git add'?

exec
/bin/zsh -lc 'git log --oneline --decorate --graph --max-count=12 --all -- docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml src/ui/design_tokens/material.cr src/ui/renderers/web_renderer.cr src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr src/ui/renderers/android_renderer.cr src/ui/design_tokens/generators/web_generator.cr src/ui/native/swiftkit_overrides.cr swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift spec/ui/glass_material' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
* b9ae9dc [Phase 5] Remediation 2 — codex pre-merge fixes
* 01e66c7 [Phase 5] Remediation 1 — align fallback opacity + pin boundary + iOS 26 contract note
* bd6f807 [Phase 5] Author Phase 5 probe spec placeholders (pending bodies; Phase 6.5 harness ships the actual probe runtime)
* 94f2fb3 [Phase 5] Wire android renderer to emit RenderEffect on API 31+ + alpha fallback
* cb1aa95 [Phase 5] Wire uikit + appkit renderers to emit Apple-quantized Material via SwiftKit bridge
* 579f9d8 [Phase 5] Wire web renderer to emit tokenized backdrop-filter + @supports fallback
* 93ea45a [Phase 5] Add UI::DesignTokens::Material struct + 5 step values
* 6180a14 [Phase 4 R2] Use higher-contrast token for action-sheet action color (WCAG-AA 4.5:1)
* 8192575 [Phase 4 R2] Remove role="group" from action-sheet <ul> (axe listitem violation)
* 022dc11 [Phase 4] Address Codex Checkpoint 4 — pre-merge fixes
* 6da452f [Phase 4] Apply Tier 3 gate to PathControl
* cdee220 [Phase 4] Apply Tier 3 gate to ContextMenu

codex
Phase 5 itself is in earlier commits on this branch; `9037cc7` is a later Phase 4 cleanup commit on top. The files named by the draft are clean against `HEAD`, except the Swift spike, which exists only as an untracked worktree file.
exec
/bin/zsh -lc 'nl -ba src/ui/design_tokens/material.cr' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	module UI
     2	  module DesignTokens
     3	    # One material strength step.
     4	    #
     5	    # Per-step values declare how a particular `UI::GlassBackground#material`
     6	    # symbol renders. `blur_radius` is scaled by the parent `Material#intensity`
     7	    # on web (via `calc()` against `--ap-material-intensity`) and on Android
     8	    # API 31+ (via the `RenderEffect.createBlurEffect` radius argument). On
     9	    # Apple, `intensity` has NO visible effect — SwiftUI's `Material` is a
    10	    # discrete enum and the declared step maps directly. See
    11	    # `docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml`
    12	    # `adapter_cardinality` row 1 for the documented consumer-visible contract.
    13	    record MaterialStep,
    14	      blur_radius : Float64,    # CSS px / Apple pt / Android dp at intensity=1.0
    15	      opacity : Float64,        # 0..1 — fill opacity (web color-mix, Android alpha)
    16	      saturation : Float64,     # backdrop saturation multiplier (1.0 = neutral)
    17	      luminance : Float64       # [-1, 1] luminance bias for fallback fills
    18	
    19	    # Glass material token branch.
    20	    #
    21	    # The five `MaterialStep` fields preserve existing per-step behavior at
    22	    # `intensity == 1.0`. `intensity` is a brand-declaration-time scalar that
    23	    # consumers re-render to observe. Phase 5 explicitly does NOT introduce a
    24	    # runtime mutator path — see `brief.yml` invariant I-2 (`preserves`).
    25	    #
    26	    # ## Apple quantization contract
    27	    #
    28	    # SwiftUI's `Material` enum is discrete (.ultraThinMaterial, .thinMaterial,
    29	    # .regularMaterial, .thickMaterial, .ultraThickMaterial). The declared
    30	    # `GlassBackground#material` symbol maps 1:1 to a SwiftUI Material case.
    31	    # `intensity` does NOT shift Apple per-view material steps — a view
    32	    # declaring `material: :thick` always renders `.thickMaterial` regardless
    33	    # of brand intensity. `apple_step(declared)` exposes this quantization;
    34	    # the Apple renderer invokes it instead of `resolve` so the discrete
    35	    # contract is the single source of truth.
    36	    #
    37	    # When the declared material is `:regular` (the default for unspecified
    38	    # `GlassBackground` views), `apple_step` does honor brand intensity by
    39	    # mapping the intensity scalar through the documented quantization table
    40	    # (see `brief.yml` adapter_cardinality row 1):
    41	    #   intensity <= 0.3 -> :ultra_thin
    42	    #   intensity <= 0.7 -> :thin
    43	    #   intensity <= 1.3 -> :regular   (brief's worked example: 1.3 -> regular)
    44	    #   intensity <  1.8 -> :thick
    45	    #   intensity >= 1.8 -> :chrome    ("1.8+" per the brief)
    46	    #
    47	    # The brief's text uses both en-dash interval notation ("0.7–1.3 ->
    48	    # regular") AND a worked example ("intensity 1.3 quantizes to
    49	    # .regularMaterial on Apple"). The implementation honors the worked
    50	    # example AND the "1.8+" notation by using mixed boundary types:
    51	    # the first three buckets have INCLUSIVE upper bounds (so 1.3 ->
    52	    # :regular) and the last threshold is INCLUSIVE on the chrome side
    53	    # (so 1.8 -> :chrome). `material_spec.cr` pins these exact boundary
    54	    # values so any future drift surfaces as a spec failure.
    55	    record Material,
    56	      ultra_thin : MaterialStep,
    57	      thin : MaterialStep,
    58	      regular : MaterialStep,
    59	      thick : MaterialStep,
    60	      chrome : MaterialStep,
    61	      intensity : Float64 do
    62	      # Lookup the `MaterialStep` for a symbol. Unknown symbols fall back to
    63	      # `:regular` rather than raising — `UI::GlassBackground#material` is
    64	      # already typed `Symbol` and the renderer must not crash on an
    65	      # off-spec value.
    66	      def step(name : Symbol) : MaterialStep
    67	        case name
    68	        when :ultra_thin then ultra_thin
    69	        when :thin       then thin
    70	        when :regular    then regular
    71	        when :thick      then thick
    72	        when :chrome     then chrome
    73	        else                  regular
    74	        end
    75	      end
    76	
    77	      # Apple step quantization. Returns the symbol the Apple facade should
    78	      # use to pick its `SwiftUI.Material` case.
    79	      #
    80	      # When the declared step is anything other than `:regular`, that step
    81	      # is returned unchanged (developer intent wins). When the declared
    82	      # step is `:regular` (the default), intensity is consulted via the
    83	      # documented quantization table from brief.yml row 1:
    84	      #   intensity < 0.3  -> :ultra_thin
    85	      #   intensity < 0.7  -> :thin
    86	      #   intensity < 1.3  -> :regular   (1.0 default lands here)
    87	      #   intensity < 1.8  -> :thick
    88	      #   intensity >= 1.8 -> :chrome   ("1.8+" per the brief)
    89	      # Boundaries are deliberately exclusive on the upper edge so the
    90	      # `1.8+` notation in the brief is honored exactly: `1.8` maps to
    91	      # :chrome (not :thick), `1.299...` maps to :regular, etc.
    92	      def apple_step(declared : Symbol) : Symbol
    93	        return declared unless declared == :regular
    94	        i = intensity
    95	        return :ultra_thin if i <= 0.3
    96	        return :thin if i <= 0.7
    97	        return :regular if i <= 1.3
    98	        return :chrome if i >= 1.8
    99	        :thick
   100	      end
   101	
   102	      # Render-time resolution for web / Android. Renderers consume this.
   103	      # `blur_radius` is scaled by `intensity` clamped to the documented
   104	      # `[0.0, 2.0]` range from brief.yml adapter_cardinality row 1.
   105	      # Out-of-range brand declarations are clamped rather than raising —
   106	      # this matches Crystal's existing `Float64#clamp` semantics on every
   107	      # other token field.
   108	      def resolve(name : Symbol) : ResolvedStep
   109	        s = step(name)
   110	        clamped = intensity.clamp(0.0, 2.0)
   111	        ResolvedStep.new(
   112	          name: name,
   113	          blur_radius: s.blur_radius * clamped,
   114	          opacity: s.opacity,
   115	          saturation: s.saturation,
   116	          luminance: s.luminance,
   117	        )
   118	      end
   119	    end
   120	
   121	    # Output of `Material#resolve` — what web + Android renderers consume.
   122	    record ResolvedStep,
   123	      name : Symbol,
   124	      blur_radius : Float64,
   125	      opacity : Float64,
   126	      saturation : Float64,
   127	      luminance : Float64
   128	
   129	  end
   130	end

exec
/bin/zsh -lc "nl -ba src/ui/design_tokens/generators/web_generator.cr | sed -n '1,260p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	require "../../design_tokens"
     2	
     3	module UI
     4	  module DesignTokens
     5	    # Emits a CSS file from a `UI::DesignTokens::Tokens` instance.
     6	    #
     7	    # The output is deterministic: same input bytes → same output bytes.
     8	    # Canonical CSS custom-property prefix is `--ap-*`. The previously-shipped
     9	    # `--amber-*` alias block is NOT emitted in this phase or any later
    10	    # phase — the prefix change to `--ap-*` is total (see implementation.md
    11	    # §4.1 and the Architect's note in handoff/phase-01-architect-scope-deferral-2026-05-20.md).
    12	    #
    13	    # Output structure:
    14	    #   :root { …light tokens… }
    15	    #   @media (prefers-color-scheme: dark) { :root { …dark tokens… } }
    16	    #   [data-ap-theme="light"] { …light… }
    17	    #   [data-ap-theme="dark"]  { …dark… }
    18	    module WebGenerator
    19	      extend self
    20	
    21	      HEADER = "/* GENERATED by UI::DesignTokens::WebGenerator. Do not edit by hand. */\n"
    22	
    23	      def generate(tokens : Tokens) : String
    24	        String.build do |io|
    25	          io << HEADER
    26	          emit_root_block(io, tokens, :light)
    27	          io << "\n"
    28	          emit_media_dark(io, tokens)
    29	          io << "\n"
    30	          emit_data_theme(io, tokens, :light)
    31	          io << "\n"
    32	          emit_data_theme(io, tokens, :dark)
    33	          io << "\n"
    34	          emit_supports_fallback(io, tokens)
    35	        end
    36	      end
    37	
    38	      private def emit_root_block(io : IO, tokens : Tokens, scheme : Symbol) : Nil
    39	        io << ":root {\n"
    40	        io << "  color-scheme: light dark;\n\n"
    41	        emit_color_vars(io, scheme == :dark ? tokens.colors_dark : tokens.colors_light, indent: "  ")
    42	        io << "\n"
    43	        emit_spacing_vars(io, tokens.spacing, indent: "  ")
    44	        io << "\n"
    45	        emit_type_vars(io, tokens.type, indent: "  ")
    46	        io << "\n"
    47	        emit_radius_vars(io, tokens.radius, indent: "  ")
    48	        io << "\n"
    49	        emit_shadow_vars(io, tokens.shadow, indent: "  ")
    50	        io << "\n"
    51	        emit_motion_vars(io, tokens.motion, indent: "  ")
    52	        io << "\n"
    53	        emit_breakpoint_vars(io, tokens.breakpoints, indent: "  ")
    54	        io << "\n"
    55	        emit_material_vars(io, tokens.material, indent: "  ")
    56	        io << "\n"
    57	        io << "  --ap-touch-target-min: #{format_px(tokens.touch_target_minimum_px)};\n"
    58	        io << "}\n"
    59	      end
    60	
    61	      # Phase 5: glass material custom properties.
    62	      #
    63	      # `--ap-material-intensity` is the brand-declaration-time scalar (default
    64	      # 1.0). Per-step blur radii are emitted as `calc()` expressions referencing
    65	      # the intensity custom property so a brand-overridden Tokens instance
    66	      # produces an entirely different CSS bundle with no per-call-site math.
    67	      # Opacity and saturation are not scaled by intensity per the documented
    68	      # adapter_cardinality contract (brief.yml row 2).
    69	      private def emit_material_vars(io : IO, material : Material, indent : String) : Nil
    70	        io << "#{indent}/* glass material — Phase 5 */\n"
    71	        # Clamp to the brief.yml-declared `[0.0, 2.0]` intensity range.
    72	        intensity_clamped = material.intensity.clamp(0.0, 2.0)
    73	        io << "#{indent}--ap-material-intensity: #{format_number(intensity_clamped)};\n"
    74	        emit_material_step_vars(io, "ultra-thin", material.ultra_thin, indent)
    75	        emit_material_step_vars(io, "thin", material.thin, indent)
    76	        emit_material_step_vars(io, "regular", material.regular, indent)
    77	        emit_material_step_vars(io, "thick", material.thick, indent)
    78	        emit_material_step_vars(io, "chrome", material.chrome, indent)
    79	      end
    80	
    81	      private def emit_material_step_vars(io : IO, name : String, step : MaterialStep, indent : String) : Nil
    82	        # Blur radius scales with intensity via calc(); fallback to "1"
    83	        # via the var() default so static-CSS consumers without the
    84	        # intensity declaration still resolve a sensible value.
    85	        io << "#{indent}--ap-material-blur-#{name}: calc(#{format_px(step.blur_radius)} * var(--ap-material-intensity, 1));\n"
    86	        io << "#{indent}--ap-material-opacity-#{name}: #{format_number(step.opacity)};\n"
    87	        io << "#{indent}--ap-material-saturation-#{name}: #{format_number(step.saturation)};\n"
    88	      end
    89	
    90	      # `@supports not (backdrop-filter)` fallback block. Browsers without
    91	      # `backdrop-filter` (and without `-webkit-backdrop-filter`) get a
    92	      # solid-tinted panel at the per-step opacity the active tokens
    93	      # declare, expressed via `var(--ap-material-opacity-<step>)` so
    94	      # brand overrides cascade into the fallback path too.
    95	      #
    96	      # Per Phase 5 brief.yml adapter_cardinality row 2: fallback uses
    97	      # the same Z% opacity per step as the live backdrop-filter path
    98	      # (ultra_thin=20, thin=40, regular=60, thick=73, chrome=87 at the
    99	      # default brand). WCAG-AA contrast is verified for both the
   100	      # blurred AND fallback paths.
   101	      #
   102	      # The fallback binds to the `.ap-glass--<step>` class names the web
   103	      # renderer emits alongside the inline-style live path. Inline style
   104	      # still wins for browsers that support the live path; the class
   105	      # selector is purely for the fallback.
   106	      private def emit_supports_fallback(io : IO, tokens : Tokens) : Nil
   107	        io << "@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {\n"
   108	        %w[ultra-thin thin regular thick chrome].each do |step|
   109	          io << "  .ap-glass--#{step} { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step}) * 100%), transparent); }\n"
   110	        end
   111	        io << "}\n"
   112	      end
   113	
   114	      private def emit_media_dark(io : IO, tokens : Tokens) : Nil
   115	        io << "@media (prefers-color-scheme: dark) {\n"
   116	        io << "  :root {\n"
   117	        emit_color_vars(io, tokens.colors_dark, indent: "    ")
   118	        io << "  }\n"
   119	        io << "}\n"
   120	      end
   121	
   122	      private def emit_data_theme(io : IO, tokens : Tokens, scheme : Symbol) : Nil
   123	        attr_value = scheme == :dark ? "dark" : "light"
   124	        palette = scheme == :dark ? tokens.colors_dark : tokens.colors_light
   125	        io << "[data-ap-theme=\"#{attr_value}\"] {\n"
   126	        emit_color_vars(io, palette, indent: "  ")
   127	        io << "}\n"
   128	      end
   129	
   130	      private def emit_color_vars(io : IO, palette : ColorPalette, indent : String) : Nil
   131	        io << "#{indent}/* colors — canonical OKLCH plus baked RGB fallback */\n"
   132	        palette.to_h.each do |name, color|
   133	          io << "#{indent}--ap-color-#{name}: #{color.to_oklch_css};\n"
   134	          io << "#{indent}--ap-color-#{name}-rgb: #{color.to_rgb_triple_css};\n"
   135	        end
   136	      end
   137	
   138	      private def emit_spacing_vars(io : IO, scale : SpacingScale, indent : String) : Nil
   139	        io << "#{indent}/* spacing — rem */\n"
   140	        scale.to_h.each do |key, value|
   141	          rendered = key == "px" ? "1px" : format_rem(value)
   142	          io << "#{indent}--ap-space-#{key}: #{rendered};\n"
   143	        end
   144	      end
   145	
   146	      private def emit_type_vars(io : IO, scale : TypeScale, indent : String) : Nil
   147	        io << "#{indent}/* type */\n"
   148	        io << "#{indent}--ap-font-sans: #{scale.family_sans};\n"
   149	        io << "#{indent}--ap-font-display: #{scale.family_display};\n"
   150	        io << "#{indent}--ap-font-mono: #{scale.family_mono};\n"
   151	        emit_type_step(io, "caption", scale.caption, indent)
   152	        emit_type_step(io, "body", scale.body, indent)
   153	        emit_type_step(io, "body-emph", scale.body_emph, indent)
   154	        emit_type_step(io, "title", scale.title, indent)
   155	        emit_type_step(io, "headline", scale.headline, indent)
   156	        emit_type_step(io, "display", scale.display, indent)
   157	      end
   158	
   159	      private def emit_type_step(io : IO, name : String, step : TypeStep, indent : String) : Nil
   160	        io << "#{indent}--ap-type-#{name}-size: #{format_rem(step.size)};\n"
   161	        io << "#{indent}--ap-type-#{name}-line-height: #{format_number(step.line_height)};\n"
   162	        io << "#{indent}--ap-type-#{name}-weight: #{step.weight};\n"
   163	        io << "#{indent}--ap-type-#{name}-tracking: #{format_em(step.tracking)};\n"
   164	      end
   165	
   166	      private def emit_radius_vars(io : IO, scale : RadiusScale, indent : String) : Nil
   167	        io << "#{indent}/* radius */\n"
   168	        io << "#{indent}--ap-radius-none: #{format_rem(scale.none)};\n"
   169	        io << "#{indent}--ap-radius-xs: #{format_rem(scale.xs)};\n"
   170	        io << "#{indent}--ap-radius-sm: #{format_rem(scale.sm)};\n"
   171	        io << "#{indent}--ap-radius-md: #{format_rem(scale.md)};\n"
   172	        io << "#{indent}--ap-radius-lg: #{format_rem(scale.lg)};\n"
   173	        io << "#{indent}--ap-radius-xl: #{format_rem(scale.xl)};\n"
   174	        io << "#{indent}--ap-radius-2xl: #{format_rem(scale.x2l)};\n"
   175	        io << "#{indent}--ap-radius-card: #{format_rem(scale.card)};\n"
   176	        io << "#{indent}--ap-radius-sheet: #{format_rem(scale.sheet)};\n"
   177	        io << "#{indent}--ap-radius-avatar: #{format_rem(scale.avatar)};\n"
   178	        io << "#{indent}--ap-radius-avatar-lg: #{format_rem(scale.avatar_lg)};\n"
   179	        # The pill sentinel renders as a literal pixel size (9999px), not rem,
   180	        # so we don't accidentally get a comically large rem-based render.
   181	        io << "#{indent}--ap-radius-pill: 9999px;\n"
   182	      end
   183	
   184	      private def emit_shadow_vars(io : IO, scale : ShadowScale, indent : String) : Nil
   185	        io << "#{indent}/* shadow */\n"
   186	        io << "#{indent}--ap-shadow-flat: #{render_shadow(scale.flat)};\n"
   187	        io << "#{indent}--ap-shadow-raised: #{render_shadow(scale.raised)};\n"
   188	        io << "#{indent}--ap-shadow-floating: #{render_shadow(scale.floating)};\n"
   189	        io << "#{indent}--ap-shadow-overlay: #{render_shadow(scale.overlay)};\n"
   190	      end
   191	
   192	      private def render_shadow(levels : Array(ShadowLevel)) : String
   193	        return "none" if levels.empty?
   194	        levels.map do |level|
   195	          parts = [format_rem(level.offset_x), format_rem(level.offset_y), format_rem(level.blur)]
   196	          parts << format_rem(level.spread) if level.spread != 0.0
   197	          parts << level.color.to_oklch_css
   198	          parts.join(' ')
   199	        end.join(", ")
   200	      end
   201	
   202	      private def emit_motion_vars(io : IO, scale : MotionScale, indent : String) : Nil
   203	        io << "#{indent}/* motion */\n"
   204	        io << "#{indent}--ap-motion-duration-instant: #{scale.duration_instant_ms}ms;\n"
   205	        io << "#{indent}--ap-motion-duration-fast: #{scale.duration_fast_ms}ms;\n"
   206	        io << "#{indent}--ap-motion-duration-base: #{scale.duration_base_ms}ms;\n"
   207	        io << "#{indent}--ap-motion-duration-slow: #{scale.duration_slow_ms}ms;\n"
   208	        io << "#{indent}--ap-motion-ease-standard: #{scale.ease_standard};\n"
   209	        io << "#{indent}--ap-motion-ease-emphasized: #{scale.ease_emphasized};\n"
   210	        io << "#{indent}--ap-motion-spring: #{scale.spring};\n"
   211	      end
   212	
   213	      private def emit_breakpoint_vars(io : IO, scale : Breakpoints, indent : String) : Nil
   214	        io << "#{indent}/* breakpoints — informational; actual breakpoints live in @media rules */\n"
   215	        io << "#{indent}--ap-bp-sm: #{format_px(scale.sm)};\n"
   216	        io << "#{indent}--ap-bp-md: #{format_px(scale.md)};\n"
   217	        io << "#{indent}--ap-bp-lg: #{format_px(scale.lg)};\n"
   218	        io << "#{indent}--ap-bp-xl: #{format_px(scale.xl)};\n"
   219	        io << "#{indent}--ap-bp-2xl: #{format_px(scale.x2l)};\n"
   220	      end
   221	
   222	      private def format_rem(value : Float64) : String
   223	        return "0rem" if value == 0.0
   224	        "#{format_number(value)}rem"
   225	      end
   226	
   227	      private def format_px(value : Float64) : String
   228	        if value == value.to_i.to_f
   229	          "#{value.to_i}px"
   230	        else
   231	          "#{format_number(value)}px"
   232	        end
   233	      end
   234	
   235	      private def format_em(value : Float64) : String
   236	        "#{format_number(value)}em"
   237	      end
   238	
   239	      private def format_number(value : Float64) : String
   240	        # Print without trailing zeros so 1.0 → "1", 1.55 → "1.55", 0.125 → "0.125".
   241	        if value == value.to_i.to_f
   242	          value.to_i.to_s
   243	        else
   244	          s = "%.6f" % value
   245	          s = s.rstrip('0').rstrip('.')
   246	          s.empty? ? "0" : s
   247	        end
   248	      end
   249	    end
   250	  end
   251	end

exec
/bin/zsh -lc 'rg -n "material|GlassBackground|ap-material|ap-glass|@supports|backdrop-filter|forced-colors|prefers-reduced-motion|prefers-color-scheme" src/ui/renderers/web_renderer.cr src/ui/design_tokens/generators/web_generator.cr src/ui/design_tokens.cr samples/cross_platform/web/brand_glass_intensity_demo.cr' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
samples/cross_platform/web/brand_glass_intensity_demo.cr:6:# Demonstrates that a single brand declaration of `material.intensity = 1.3`
samples/cross_platform/web/brand_glass_intensity_demo.cr:18:#   2. The generated `--ap-material-*` CSS so the cascade is visually
samples/cross_platform/web/brand_glass_intensity_demo.cr:19:#      inspectable (`--ap-material-intensity: 1.3` and the `calc()`
samples/cross_platform/web/brand_glass_intensity_demo.cr:27:  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
samples/cross_platform/web/brand_glass_intensity_demo.cr:28:    material.copy_with(intensity: 1.3)
samples/cross_platform/web/brand_glass_intensity_demo.cr:39:  ladder << UI::GlassBackground.new(material: step)
samples/cross_platform/web/brand_glass_intensity_demo.cr:52:puts "--- Generated material CSS custom properties ---"
samples/cross_platform/web/brand_glass_intensity_demo.cr:55:  puts line if line.includes?("--ap-material-") || line.includes?("ap-glass--")
samples/cross_platform/web/brand_glass_intensity_demo.cr:60:  apple = tokens.material.apple_step(step)
samples/cross_platform/web/brand_glass_intensity_demo.cr:61:  resolved = tokens.material.resolve(step)
src/ui/design_tokens.cr:2:require "./design_tokens/material"
src/ui/design_tokens.cr:494:      # Glass material token branch (Phase 5). Carries the five
src/ui/design_tokens.cr:498:      getter material : Material
src/ui/design_tokens.cr:515:        @material : Material = Defaults.material,
src/ui/design_tokens.cr:532:        material : Material = @material,
src/ui/design_tokens.cr:544:          material: material,
src/ui/design_tokens.cr:686:          material: Defaults.material,
src/ui/design_tokens.cr:696:    # Phase 3 (SwiftUI bridge), Phase 5 (Glass material tokens), and Phase 6
src/ui/design_tokens.cr:712:          material: override_material(base.material),
src/ui/design_tokens.cr:750:      # Subclasses return a new `Material` (typically via `material.copy_with(...)`)
src/ui/design_tokens.cr:753:      protected def override_material(material : Material) : Material
src/ui/design_tokens.cr:754:        material
src/ui/design_tokens.cr:961:      # Phase 5 — glass material defaults.
src/ui/design_tokens.cr:965:      # `Brand#override_material(material)` returning a new `Material` (use
src/ui/design_tokens.cr:968:      def material : Material
src/ui/design_tokens/generators/web_generator.cr:15:    #   @media (prefers-color-scheme: dark) { :root { …dark tokens… } }
src/ui/design_tokens/generators/web_generator.cr:55:        emit_material_vars(io, tokens.material, indent: "  ")
src/ui/design_tokens/generators/web_generator.cr:61:      # Phase 5: glass material custom properties.
src/ui/design_tokens/generators/web_generator.cr:63:      # `--ap-material-intensity` is the brand-declaration-time scalar (default
src/ui/design_tokens/generators/web_generator.cr:69:      private def emit_material_vars(io : IO, material : Material, indent : String) : Nil
src/ui/design_tokens/generators/web_generator.cr:70:        io << "#{indent}/* glass material — Phase 5 */\n"
src/ui/design_tokens/generators/web_generator.cr:72:        intensity_clamped = material.intensity.clamp(0.0, 2.0)
src/ui/design_tokens/generators/web_generator.cr:73:        io << "#{indent}--ap-material-intensity: #{format_number(intensity_clamped)};\n"
src/ui/design_tokens/generators/web_generator.cr:74:        emit_material_step_vars(io, "ultra-thin", material.ultra_thin, indent)
src/ui/design_tokens/generators/web_generator.cr:75:        emit_material_step_vars(io, "thin", material.thin, indent)
src/ui/design_tokens/generators/web_generator.cr:76:        emit_material_step_vars(io, "regular", material.regular, indent)
src/ui/design_tokens/generators/web_generator.cr:77:        emit_material_step_vars(io, "thick", material.thick, indent)
src/ui/design_tokens/generators/web_generator.cr:78:        emit_material_step_vars(io, "chrome", material.chrome, indent)
src/ui/design_tokens/generators/web_generator.cr:81:      private def emit_material_step_vars(io : IO, name : String, step : MaterialStep, indent : String) : Nil
src/ui/design_tokens/generators/web_generator.cr:85:        io << "#{indent}--ap-material-blur-#{name}: calc(#{format_px(step.blur_radius)} * var(--ap-material-intensity, 1));\n"
src/ui/design_tokens/generators/web_generator.cr:86:        io << "#{indent}--ap-material-opacity-#{name}: #{format_number(step.opacity)};\n"
src/ui/design_tokens/generators/web_generator.cr:87:        io << "#{indent}--ap-material-saturation-#{name}: #{format_number(step.saturation)};\n"
src/ui/design_tokens/generators/web_generator.cr:90:      # `@supports not (backdrop-filter)` fallback block. Browsers without
src/ui/design_tokens/generators/web_generator.cr:91:      # `backdrop-filter` (and without `-webkit-backdrop-filter`) get a
src/ui/design_tokens/generators/web_generator.cr:93:      # declare, expressed via `var(--ap-material-opacity-<step>)` so
src/ui/design_tokens/generators/web_generator.cr:97:      # the same Z% opacity per step as the live backdrop-filter path
src/ui/design_tokens/generators/web_generator.cr:102:      # The fallback binds to the `.ap-glass--<step>` class names the web
src/ui/design_tokens/generators/web_generator.cr:107:        io << "@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {\n"
src/ui/design_tokens/generators/web_generator.cr:109:          io << "  .ap-glass--#{step} { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step}) * 100%), transparent); }\n"
src/ui/design_tokens/generators/web_generator.cr:115:        io << "@media (prefers-color-scheme: dark) {\n"
src/ui/renderers/web_renderer.cr:1402:      def visit(view : UI::GlassBackground)
src/ui/renderers/web_renderer.cr:1405:        # Phase 5: glass material is tokenized. The inline style references
src/ui/renderers/web_renderer.cr:1406:        # the per-step `--ap-material-*` custom properties the WebGenerator
src/ui/renderers/web_renderer.cr:1408:        # `calc(<base>px * var(--ap-material-intensity, 1))`). The
src/ui/renderers/web_renderer.cr:1409:        # `ap-glass--<step>` class binds to the `@supports` fallback rule.
src/ui/renderers/web_renderer.cr:1410:        step_key = material_css_step_key(view.material)
src/ui/renderers/web_renderer.cr:1411:        el.add_class("ap-glass")
src/ui/renderers/web_renderer.cr:1412:        el.add_class("ap-glass--#{step_key}")
src/ui/renderers/web_renderer.cr:1414:          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1415:          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1416:          "background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step_key}) * 100%), transparent); " \
src/ui/renderers/web_renderer.cr:1434:      # Map a `GlassBackground#material` Symbol to the CSS class suffix /
src/ui/renderers/web_renderer.cr:1436:      private def material_css_step_key(name : Symbol) : String
src/ui/renderers/web_renderer.cr:2018:        # `:thin` material step. Inline style references `var(--ap-material-*)`
src/ui/renderers/web_renderer.cr:2019:        # for both backdrop-filter and the opacity-driven color-mix
src/ui/renderers/web_renderer.cr:2020:        # background, so brand intensity AND the @supports fallback both
src/ui/renderers/web_renderer.cr:2022:        el.add_class("ap-glass")
src/ui/renderers/web_renderer.cr:2023:        el.add_class("ap-glass--thin")
src/ui/renderers/web_renderer.cr:2024:        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); -webkit-backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")

exec
/bin/zsh -lc 'rg -n "material|GlassBackground|glass_background|swiftkit|override|apple_step|chrome|ultraThick|Material|ObservableObject|UIVisualEffect|NSVisualEffect|forced|contrast|motion|dark" src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr src/ui/native/swiftkit_overrides.cr swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:1:// GlassBackgroundFacade — SwiftUI bridge for UI::GlassBackground, the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:5:// 13..25) it falls back to the matching static Material so the surface
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:8:// Phase 5 will extend this facade with the full material parameter set
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:10:// floor: a developer who writes `UI::GlassBackground.new(content)` gets
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:13:// Brand identity: `GlassBackground` deliberately does NOT apply the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:17:// the glass material itself stays neutral.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:22:@objc(APSKGlassBackgroundFacade)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:23:public final class GlassBackgroundFacade: NSObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:27:    @objc public static func makeGlassBackground(
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:28:        overrides: GlassBackgroundOverrides,
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:34:        let materialKey = overrides.material ?? "regular"
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:36:        // PHASE 5 — Apple-platform material selection.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:38:        // Per brief.yml adapter_cardinality row 1, the SwiftUI Material
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:41:        // `.background(<Material>)` path honors the resolved step
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:47:        // quantizes to .regularMaterial on Apple (visually IDENTICAL to
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:53:        let material: Material = {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:54:            switch materialKey {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:55:            case "thin":       return .thinMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:56:            case "thick":      return .thickMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:57:            case "ultraThin":  return .ultraThinMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:58:            case "ultraThick": return .ultraThickMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:59:            default:           return .regularMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:66:            _ = material  // pre-26 only; unused on the Liquid Glass path
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:72:            // Pre-26 fallback. `Material` tracks appearance + step.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:75:                    .background(material)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:79:        let composed = CommonModifiers.apply(backed, overrides: overrides)
src/ui/native/swiftkit_overrides.cr:40:require "../views/glass_background"
src/ui/native/swiftkit_overrides.cr:41:require "./swiftkit_bridge"
src/ui/native/swiftkit_overrides.cr:45:    # SwiftKit override populator.
src/ui/native/swiftkit_overrides.cr:47:    # Phase 3's renderer migration moves overrides population OUT of each
src/ui/native/swiftkit_overrides.cr:54:    #   `Populator.populate_button(overrides_ptr, view)` walks the
src/ui/native/swiftkit_overrides.cr:159:      # overrides object (in production it's a stringified pointer; in
src/ui/native/swiftkit_overrides.cr:164:        # ---- Button-specific overrides -----------------------------------
src/ui/native/swiftkit_overrides.cr:229:        # only secure-entry needs to flow through overrides.
src/ui/native/swiftkit_overrides.cr:239:        # No widget-specific overrides today; the SwiftUI SecureField default
src/ui/native/swiftkit_overrides.cr:246:        # localizedSystemSearchLabel when no override surfaces.
src/ui/native/swiftkit_overrides.cr:271:        # No widget-specific overrides — label + url are positional.
src/ui/native/swiftkit_overrides.cr:467:          # override per-item if a richer placement model is wired later.
src/ui/native/swiftkit_overrides.cr:514:        unless view.material == :secondary
src/ui/native/swiftkit_overrides.cr:515:          sender.set_string(target, :setMaterial, view.material.to_s)
src/ui/native/swiftkit_overrides.cr:563:      # via callback-token registration (not through overrides).
src/ui/native/swiftkit_overrides.cr:602:      # Liquid Glass; on pre-26 OSes it falls back to `.background(<Material>)`.
src/ui/native/swiftkit_overrides.cr:604:      # `material` mirrors the Crystal `UI::GlassBackground.material`
src/ui/native/swiftkit_overrides.cr:605:      # symbol (:regular | :thin | :ultra_thin | :thick | :chrome). The
src/ui/native/swiftkit_overrides.cr:609:      # Glass populator. `apple_step` is the Apple-quantized step Symbol the
src/ui/native/swiftkit_overrides.cr:610:      # renderer has resolved via `tokens.material.apple_step(view.material)`.
src/ui/native/swiftkit_overrides.cr:611:      # The populator emits the facade `setMaterial:` key derived from the
src/ui/native/swiftkit_overrides.cr:612:      # resolved Symbol, not from `view.material` directly, so brand
src/ui/native/swiftkit_overrides.cr:613:      # intensity overrides cascade onto the SwiftUI Material enum case per
src/ui/native/swiftkit_overrides.cr:616:      # `apple_step` defaults to `view.material` so spec-level callers that
src/ui/native/swiftkit_overrides.cr:619:      def self.populate_glass_background(target : String, view : UI::GlassBackground, sender : Sender, apple_step : Symbol = view.material)
src/ui/native/swiftkit_overrides.cr:624:        # :regular AND the view's declared material differs (brand
src/ui/native/swiftkit_overrides.cr:627:        emit = apple_step != :regular || view.material != :regular
src/ui/native/swiftkit_overrides.cr:629:          key = case apple_step
src/ui/native/swiftkit_overrides.cr:634:                when :chrome      then "ultraThick" # closest SwiftUI Material analogue
src/ui/native/swiftkit_overrides.cr:635:                else                   apple_step.to_s
src/ui/native/swiftkit_overrides.cr:637:          sender.set_string(target, :setMaterial, key)
src/ui/native/swiftkit_overrides.cr:665:    # matching `apsk_overrides_set_*` `fun`. The `target : String`
src/ui/native/swiftkit_overrides.cr:667:    # sender already knows which overrides object it is populating from
src/ui/native/swiftkit_overrides.cr:677:        # The `APSK*Overrides` pointer returned by `apsk_*_overrides_new`.
src/ui/native/swiftkit_overrides.cr:681:        getter overrides_ptr : Void*
src/ui/native/swiftkit_overrides.cr:683:        def initialize(@overrides_ptr : Void*)
src/ui/native/swiftkit_overrides.cr:688:          LibSwiftKitBridge.apsk_overrides_set_color(
src/ui/native/swiftkit_overrides.cr:689:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
src/ui/native/swiftkit_overrides.cr:696:          LibSwiftKitBridge.apsk_overrides_set_number(
src/ui/native/swiftkit_overrides.cr:697:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe, value,
src/ui/native/swiftkit_overrides.cr:703:          LibSwiftKitBridge.apsk_overrides_set_bool(
src/ui/native/swiftkit_overrides.cr:704:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe, value ? 1 : 0,
src/ui/native/swiftkit_overrides.cr:710:          LibSwiftKitBridge.apsk_overrides_set_string(
src/ui/native/swiftkit_overrides.cr:711:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe, value.to_unsafe,
src/ui/native/swiftkit_overrides.cr:720:          # locally until apsk_overrides_set_string_array returns.
src/ui/native/swiftkit_overrides.cr:724:          LibSwiftKitBridge.apsk_overrides_set_string_array(
src/ui/native/swiftkit_overrides.cr:725:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
src/ui/native/swiftkit_overrides.cr:735:          LibSwiftKitBridge.apsk_overrides_set_int_array(
src/ui/native/swiftkit_overrides.cr:736:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
src/ui/native/swiftkit_overrides.cr:746:          LibSwiftKitBridge.apsk_overrides_set_uint64_array(
src/ui/native/swiftkit_overrides.cr:747:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
src/ui/native/swiftkit_overrides.cr:757:          LibSwiftKitBridge.apsk_overrides_set_bool_array(
src/ui/native/swiftkit_overrides.cr:758:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
src/ui/native/swiftkit_overrides.cr:765:          LibSwiftKitBridge.apsk_overrides_set_int(
src/ui/native/swiftkit_overrides.cr:766:            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
src/ui/renderers/appkit_renderer.cr:6:  require "../native/swiftkit_bridge"
src/ui/renderers/appkit_renderer.cr:7:  require "../native/swiftkit_overrides"
src/ui/renderers/appkit_renderer.cr:142:      @swiftkit_action_trampoline_installed : Bool = false
src/ui/renderers/appkit_renderer.cr:165:        ensure_swiftkit_runtime!
src/ui/renderers/appkit_renderer.cr:187:        overrides_ptr = LibSwiftKitBridge.apsk_label_overrides_new
src/ui/renderers/appkit_renderer.cr:188:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:189:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:198:          text.to_unsafe, overrides_ptr, state_box,
src/ui/renderers/appkit_renderer.cr:204:          view.swiftkit_state_handle = state_slot
src/ui/renderers/appkit_renderer.cr:216:      # colour injection (amber-gold fill, plum-for-destructive, dark-mode
src/ui/renderers/appkit_renderer.cr:217:      # contrast cascade, role × style matrix). Instead it routes through
src/ui/renderers/appkit_renderer.cr:221:      # `render(...)` / `ensure_swiftkit_runtime!`).
src/ui/renderers/appkit_renderer.cr:230:      # Per-widget overrides only fire when the developer explicitly sets
src/ui/renderers/appkit_renderer.cr:246:        overrides_ptr = LibSwiftKitBridge.apsk_button_overrides_new
src/ui/renderers/appkit_renderer.cr:247:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:248:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:252:        #    APSKRuntime invokes `ap_swiftkit_invoke_action(token, 0.0)` on
src/ui/renderers/appkit_renderer.cr:253:        #    tap; the trampoline routes via `CallbackRegistry.invoke_swiftkit`
src/ui/renderers/appkit_renderer.cr:269:          button_label.to_unsafe, overrides_ptr, action_token, state_box,
src/ui/renderers/appkit_renderer.cr:278:          view.swiftkit_state_handle = state_slot
src/ui/renderers/appkit_renderer.cr:329:        # via NSColor.labelColor -> near-white in dark) is lost on the white bitmap.
src/ui/renderers/appkit_renderer.cr:336:        # honour that color instead of the hardcoded white/dark fill. This prevents
src/ui/renderers/appkit_renderer.cr:341:        # beneath the chrome and NSVisualEffectView with .withinWindow blending samples
src/ui/renderers/appkit_renderer.cr:344:        # Use clearColor (alpha = 0) so every NSStackView in the chrome hierarchy is
src/ui/renderers/appkit_renderer.cr:359:                    # Backdrop-mode: keep VStack transparent so NSVisualEffectView can blur
src/ui/renderers/appkit_renderer.cr:365:                    # No backdrop — apply the dark-mode legibility fix (gaps.md iter-21).
src/ui/renderers/appkit_renderer.cr:367:                    # for dark/light appearance in the offscreen capture path.
src/ui/renderers/appkit_renderer.cr:368:                    dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
src/ui/renderers/appkit_renderer.cr:369:                    dark_mode ? LibObjCBridge.nscolor_rgba(0.12, 0.12, 0.12, 1.0) :  # Tier 2 dark
src/ui/renderers/appkit_renderer.cr:488:        overrides_ptr = LibSwiftKitBridge.apsk_image_overrides_new
src/ui/renderers/appkit_renderer.cr:489:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:490:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:493:        ptr = LibSwiftKitBridge.apsk_make_image(view.source.to_unsafe, overrides_ptr)
src/ui/renderers/appkit_renderer.cr:506:        overrides_ptr = LibSwiftKitBridge.apsk_text_field_overrides_new
src/ui/renderers/appkit_renderer.cr:507:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:508:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:520:          overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:541:          # hides the scroller chrome when not actively scrolling.
src/ui/renderers/appkit_renderer.cr:620:      #   setContentTintColor: NSColor -- overrides the green track tint
src/ui/renderers/appkit_renderer.cr:627:        overrides_ptr = LibSwiftKitBridge.apsk_toggle_overrides_new
src/ui/renderers/appkit_renderer.cr:628:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:629:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:642:          view.label.to_unsafe, view.is_on ? 1 : 0, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:648:          view.swiftkit_state_handle = state_slot
src/ui/renderers/appkit_renderer.cr:659:        overrides_ptr = LibSwiftKitBridge.apsk_checkbox_overrides_new
src/ui/renderers/appkit_renderer.cr:660:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:661:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:672:          view.label.to_unsafe, view.is_checked ? 1 : 0, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:684:        overrides_ptr = LibSwiftKitBridge.apsk_radio_group_overrides_new
src/ui/renderers/appkit_renderer.cr:685:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:686:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:705:          overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:717:        overrides_ptr = LibSwiftKitBridge.apsk_slider_overrides_new
src/ui/renderers/appkit_renderer.cr:718:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:719:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:732:          view.value, view.minimum, view.maximum, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:738:          view.swiftkit_state_handle = state_slot
src/ui/renderers/appkit_renderer.cr:752:        overrides_ptr = LibSwiftKitBridge.apsk_navigation_stack_overrides_new
src/ui/renderers/appkit_renderer.cr:753:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:754:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:764:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:776:        overrides_ptr = LibSwiftKitBridge.apsk_navigation_link_overrides_new
src/ui/renderers/appkit_renderer.cr:777:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:778:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:789:          children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:798:      # Visit: TabView -> NSVisualEffectView (Liquid Glass root) containing
src/ui/renderers/appkit_renderer.cr:804:      # equivalent; we render the whole component inside NSVisualEffectView
src/ui/renderers/appkit_renderer.cr:805:      # (NSVisualEffectMaterialMenu = 10, tracks light/dark automatically)
src/ui/renderers/appkit_renderer.cr:809:      #   NSVisualEffectView (glass root)
src/ui/renderers/appkit_renderer.cr:824:        # arrays from the overrides.
src/ui/renderers/appkit_renderer.cr:825:        overrides_ptr = LibSwiftKitBridge.apsk_tab_view_overrides_new
src/ui/renderers/appkit_renderer.cr:826:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:827:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:849:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:860:        glass_root = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:861:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:862:        # NSVisualEffectBlendingModeWithinWindow = 1 — samples what is beneath
src/ui/renderers/appkit_renderer.cr:863:        # this NSVisualEffectView within the same window. Correct for validation
src/ui/renderers/appkit_renderer.cr:867:        # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:873:        glass_handle = ObjC.owned(glass_root, label: "NSVisualEffectView[tab-bar-glass]")
src/ui/renderers/appkit_renderer.cr:1048:      # Visit: Alert -> NSVisualEffectView (hudWindow material) inline card
src/ui/renderers/appkit_renderer.cr:1051:      # require Liquid Glass. NSVisualEffectMaterialHUDWindow (= 7) is the
src/ui/renderers/appkit_renderer.cr:1052:      # correct material — it renders the frosted-glass HUD panel that Apple
src/ui/renderers/appkit_renderer.cr:1057:      # by the HIG validation host (screenshot isolation). The material,
src/ui/renderers/appkit_renderer.cr:1062:        overrides_ptr = LibSwiftKitBridge.apsk_alert_overrides_new
src/ui/renderers/appkit_renderer.cr:1063:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1064:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1082:          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:1090:      # Legacy AppKit NSVisualEffectView alert body, retained for reference.
src/ui/renderers/appkit_renderer.cr:1092:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:1093:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 7_i64)
src/ui/renderers/appkit_renderer.cr:1094:        # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:1096:        # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:1229:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[alert-glass]")
src/ui/renderers/appkit_renderer.cr:1239:        overrides_ptr = LibSwiftKitBridge.apsk_picker_overrides_new
src/ui/renderers/appkit_renderer.cr:1240:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1241:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1257:          view.selected_index.to_i32, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1269:        overrides_ptr = LibSwiftKitBridge.apsk_icon_button_overrides_new
src/ui/renderers/appkit_renderer.cr:1270:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1271:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1280:          view.icon.to_unsafe, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1303:        overrides_ptr = LibSwiftKitBridge.apsk_list_view_overrides_new
src/ui/renderers/appkit_renderer.cr:1304:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1305:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1322:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:1338:        # Layer-backed so we can bake the background for dark-mode offscreen renders.
src/ui/renderers/appkit_renderer.cr:1342:          dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
src/ui/renderers/appkit_renderer.cr:1343:          bg_rgba = if dark_mode
src/ui/renderers/appkit_renderer.cr:1344:                      # Tier 2 platform default: NSColor.controlBackgroundColor dark.
src/ui/renderers/appkit_renderer.cr:1425:              dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
src/ui/renderers/appkit_renderer.cr:1429:                card_bg_gray : Float64 = dark_mode ? 0.20 : 0.97
src/ui/renderers/appkit_renderer.cr:1438:                sep_gray : Float64 = dark_mode ? 0.35 : 0.78
src/ui/renderers/appkit_renderer.cr:1499:        overrides_ptr = LibSwiftKitBridge.apsk_secure_field_overrides_new
src/ui/renderers/appkit_renderer.cr:1500:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1501:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1512:          view.placeholder.to_unsafe, view.text.to_unsafe, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1524:        overrides_ptr = LibSwiftKitBridge.apsk_stepper_overrides_new
src/ui/renderers/appkit_renderer.cr:1525:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1526:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1538:          overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1550:        overrides_ptr = LibSwiftKitBridge.apsk_segmented_control_overrides_new
src/ui/renderers/appkit_renderer.cr:1551:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1552:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1568:          overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1580:        overrides_ptr = LibSwiftKitBridge.apsk_date_picker_overrides_new
src/ui/renderers/appkit_renderer.cr:1581:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1582:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1594:          view.label.to_unsafe, epoch, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1606:        overrides_ptr = LibSwiftKitBridge.apsk_time_picker_overrides_new
src/ui/renderers/appkit_renderer.cr:1607:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1608:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1620:          view.label.to_unsafe, epoch, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1632:        overrides_ptr = LibSwiftKitBridge.apsk_search_field_overrides_new
src/ui/renderers/appkit_renderer.cr:1633:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1634:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1646:          overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1658:        overrides_ptr = LibSwiftKitBridge.apsk_text_area_overrides_new
src/ui/renderers/appkit_renderer.cr:1659:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1660:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1672:          overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:1687:        overrides_ptr = LibSwiftKitBridge.apsk_grid_overrides_new
src/ui/renderers/appkit_renderer.cr:1688:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1689:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1703:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:1718:        overrides_ptr = LibSwiftKitBridge.apsk_form_overrides_new
src/ui/renderers/appkit_renderer.cr:1719:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1720:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1742:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:1752:      #        with NSVisualEffectView sidebar column (Liquid Glass)
src/ui/renderers/appkit_renderer.cr:1755:      # The sidebar column wraps in NSVisualEffectView with
src/ui/renderers/appkit_renderer.cr:1756:      # NSVisualEffectMaterialSidebar (= 7). The content / detail
src/ui/renderers/appkit_renderer.cr:1763:      #     NSVisualEffectView[sidebar-glass] (sidebar width pinned)
src/ui/renderers/appkit_renderer.cr:1777:        overrides_ptr = LibSwiftKitBridge.apsk_navigation_split_view_overrides_new
src/ui/renderers/appkit_renderer.cr:1778:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1779:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1799:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:1826:            # NSVisualEffectMaterialSidebar = 7. Tracks light/dark appearance.
src/ui/renderers/appkit_renderer.cr:1827:            sidebar_effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:1828:            LibObjCBridge.objc_send_long(sidebar_effect, sel("setMaterial:"), 7_i64)
src/ui/renderers/appkit_renderer.cr:1829:            # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:1831:            # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:1867:            sidebar_effect_handle = ObjC.owned(sidebar_effect, label: "NSVisualEffectView[sidebar-glass]")
src/ui/renderers/appkit_renderer.cr:1933:      # Visit: Toolbar -> NSVisualEffectView (Liquid Glass) + horizontal
src/ui/renderers/appkit_renderer.cr:1938:      # components classified under navigation/chrome. On macOS 26, the
src/ui/renderers/appkit_renderer.cr:1939:      # toolbar background is a Liquid Glass translucent NSVisualEffectView.
src/ui/renderers/appkit_renderer.cr:1940:      # Material: NSVisualEffectMaterialToolBar = 10 (tracks appearance).
src/ui/renderers/appkit_renderer.cr:1943:      #   NSVisualEffectView (glass root, toolbar material)
src/ui/renderers/appkit_renderer.cr:1957:        overrides_ptr = LibSwiftKitBridge.apsk_toolbar_overrides_new
src/ui/renderers/appkit_renderer.cr:1958:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:1959:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:1978:          Pointer(Void*).null.as(Void*), 0_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:1986:      # Legacy AppKit NSStackView/NSVisualEffectView toolbar body. Kept
src/ui/renderers/appkit_renderer.cr:1989:        glass_root = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:1990:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:1991:        # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:1993:        # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:2007:        glass_handle = ObjC.owned(glass_root, label: "NSVisualEffectView[toolbar-glass]")
src/ui/renderers/appkit_renderer.cr:2111:      # Visit: Sheet -> NSVisualEffectView + inner NSStackView (Liquid Glass)
src/ui/renderers/appkit_renderer.cr:2117:        overrides_ptr = LibSwiftKitBridge.apsk_sheet_overrides_new
src/ui/renderers/appkit_renderer.cr:2118:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2119:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2139:          overrides_ptr, dismiss_token,
src/ui/renderers/appkit_renderer.cr:2154:          # Outer glass container — NSVisualEffectView. This is what the
src/ui/renderers/appkit_renderer.cr:2156:          # backdrop-blurred material and the subtle glass-edge highlight.
src/ui/renderers/appkit_renderer.cr:2157:          effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:2159:          # NSVisualEffectMaterialSheet = 11 (macOS 10.11+). This is the
src/ui/renderers/appkit_renderer.cr:2160:          # canonical material for macOS sheets -- it matches the frosted-glass
src/ui/renderers/appkit_renderer.cr:2161:          # surface Apple uses for Save/Print/Open sheets. Tracks light/dark
src/ui/renderers/appkit_renderer.cr:2162:          # appearance automatically. Material 10 (Menu) was used previously;
src/ui/renderers/appkit_renderer.cr:2163:          # 11 (Sheet) is the semantically correct value per NSVisualEffectMaterial
src/ui/renderers/appkit_renderer.cr:2168:          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)
src/ui/renderers/appkit_renderer.cr:2169:          # NSVisualEffectBlendingModeWithinWindow = 1 — samples what is beneath
src/ui/renderers/appkit_renderer.cr:2170:          # this NSVisualEffectView inside the same window. The validation host
src/ui/renderers/appkit_renderer.cr:2173:          # itself and produced a solid dark fill when no separate window was beneath.
src/ui/renderers/appkit_renderer.cr:2175:          # NSVisualEffectStateActive = 1 — keep the material live regardless
src/ui/renderers/appkit_renderer.cr:2179:          # Rounded corners on the material layer itself.
src/ui/renderers/appkit_renderer.cr:2191:          # insets give the HIG-mandated breathing room inside the material.
src/ui/renderers/appkit_renderer.cr:2220:          # property overrides this default.
src/ui/renderers/appkit_renderer.cr:2224:          outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[sheet-glass]")
src/ui/renderers/appkit_renderer.cr:2265:      # Visit: Popover -> NSVisualEffectView (popover material) inline card
src/ui/renderers/appkit_renderer.cr:2270:      # NSVisualEffectMaterialPopover = 6. Tracks light/dark appearance
src/ui/renderers/appkit_renderer.cr:2273:      # material live regardless of key state.
src/ui/renderers/appkit_renderer.cr:2286:      # Corner radius ~10pt matching NSVisualEffectMaterialPopover default.
src/ui/renderers/appkit_renderer.cr:2290:        overrides_ptr = LibSwiftKitBridge.apsk_popover_overrides_new
src/ui/renderers/appkit_renderer.cr:2291:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2292:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2312:          overrides_ptr, dismiss_token,
src/ui/renderers/appkit_renderer.cr:2323:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:2324:        # NSVisualEffectMaterialPopover = 6.
src/ui/renderers/appkit_renderer.cr:2325:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 6_i64)
src/ui/renderers/appkit_renderer.cr:2326:        # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:2328:        # NSVisualEffectStateActive = 1 -- keep material live regardless of key state.
src/ui/renderers/appkit_renderer.cr:2369:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[popover-glass]")
src/ui/renderers/appkit_renderer.cr:2388:        overrides_ptr = LibSwiftKitBridge.apsk_confirmation_dialog_overrides_new
src/ui/renderers/appkit_renderer.cr:2389:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2390:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2397:          LibSwiftKitBridge.apsk_overrides_set_int(
src/ui/renderers/appkit_renderer.cr:2398:            overrides_ptr, "setConfirmToken:".to_unsafe, tok.to_i64,
src/ui/renderers/appkit_renderer.cr:2404:          LibSwiftKitBridge.apsk_overrides_set_int(
src/ui/renderers/appkit_renderer.cr:2405:            overrides_ptr, "setCancelToken:".to_unsafe, tok.to_i64,
src/ui/renderers/appkit_renderer.cr:2410:          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:2451:      # is dark, producing white-on-white captures (gaps.md iteration-21).
src/ui/renderers/appkit_renderer.cr:2457:      # path it correctly resolves to light gray in light and dark charcoal
src/ui/renderers/appkit_renderer.cr:2458:      # in dark. The hairline border is drawn via layer.borderColor and
src/ui/renderers/appkit_renderer.cr:2469:        overrides_ptr = LibSwiftKitBridge.apsk_card_overrides_new
src/ui/renderers/appkit_renderer.cr:2470:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2471:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2483:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:2515:          # drawing appearance is set, so it does NOT track dark/light via the
src/ui/renderers/appkit_renderer.cr:2518:          # (NSColor.controlBackgroundColor light ~0.97 RGB); dark -> dark-charcoal
src/ui/renderers/appkit_renderer.cr:2519:          # (NSColor.controlBackgroundColor dark ~0.14 RGB). Reading HIG_APPEARANCE
src/ui/renderers/appkit_renderer.cr:2521:          # In production, a real app would subclass NSStackView and override
src/ui/renderers/appkit_renderer.cr:2526:          # block the NSVisualEffectView compositor from reaching the backdrop.
src/ui/renderers/appkit_renderer.cr:2529:          dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
src/ui/renderers/appkit_renderer.cr:2534:          # Not brand decisions; track the system grouped-card chrome.
src/ui/renderers/appkit_renderer.cr:2537:                       dark_mode ? LibObjCBridge.nscolor_rgba(0.12, 0.12, 0.14, 0.75) : LibObjCBridge.nscolor_rgba(0.96, 0.96, 0.97, 0.75)
src/ui/renderers/appkit_renderer.cr:2538:                     elsif dark_mode
src/ui/renderers/appkit_renderer.cr:2539:                       # Tier 2 platform default: NSColor.controlBackgroundColor dark.
src/ui/renderers/appkit_renderer.cr:2550:          # Hairline separator-color border matching HIG grouped-box chrome.
src/ui/renderers/appkit_renderer.cr:2552:          sep_gray : Float64 = dark_mode ? 0.35 : 0.78
src/ui/renderers/appkit_renderer.cr:2579:          # Label-color (dynamic): dark-mode white, light-mode near-black.
src/ui/renderers/appkit_renderer.cr:2602:        overrides_ptr = LibSwiftKitBridge.apsk_surface_overrides_new
src/ui/renderers/appkit_renderer.cr:2603:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2604:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2616:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:2628:        overrides_ptr = LibSwiftKitBridge.apsk_divider_overrides_new
src/ui/renderers/appkit_renderer.cr:2629:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2630:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2633:        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2638:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
src/ui/renderers/appkit_renderer.cr:2639:      # with `.background(<Material>)` fallback on pre-26 OSes.
src/ui/renderers/appkit_renderer.cr:2646:      def visit(view : UI::GlassBackground)
src/ui/renderers/appkit_renderer.cr:2648:        # See uikit_renderer.cr#visit(UI::GlassBackground) for the contract.
src/ui/renderers/appkit_renderer.cr:2649:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/renderers/appkit_renderer.cr:2651:        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
src/ui/renderers/appkit_renderer.cr:2652:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2653:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2654:        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
src/ui/renderers/appkit_renderer.cr:2665:        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
src/ui/renderers/appkit_renderer.cr:2666:        handle = ObjC.owned(ptr, label: "NSHostingView[GlassBackground]")
src/ui/renderers/appkit_renderer.cr:2693:      # detected we substitute NSColor.labelColor so dark-mode text is
src/ui/renderers/appkit_renderer.cr:2742:        overrides_ptr = LibSwiftKitBridge.apsk_link_button_overrides_new
src/ui/renderers/appkit_renderer.cr:2743:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2744:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2753:          view.label.to_unsafe, view.url.to_unsafe, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:2782:        overrides_ptr = LibSwiftKitBridge.apsk_menu_button_overrides_new
src/ui/renderers/appkit_renderer.cr:2783:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2784:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2803:          view.label.to_unsafe, overrides_ptr,
src/ui/renderers/appkit_renderer.cr:2812:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:2813:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 5_i64)     # NSVisualEffectMaterialMenu
src/ui/renderers/appkit_renderer.cr:2913:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[context-menu]")
src/ui/renderers/appkit_renderer.cr:2921:        overrides_ptr = LibSwiftKitBridge.apsk_toggle_button_overrides_new
src/ui/renderers/appkit_renderer.cr:2922:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2923:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2934:          view.label.to_unsafe, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:2943:        overrides_ptr = LibSwiftKitBridge.apsk_text_editor_overrides_new
src/ui/renderers/appkit_renderer.cr:2944:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2945:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:2957:          overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:3289:        dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
src/ui/renderers/appkit_renderer.cr:3299:        bg_gray = dark_mode ? 0.12 : 1.0
src/ui/renderers/appkit_renderer.cr:3300:        bar_area_bg = dark_mode ? 0.16 : 0.97 # subtle off-white / dark card
src/ui/renderers/appkit_renderer.cr:3303:        bar_r = dark_mode ? 0.039 : 0.0
src/ui/renderers/appkit_renderer.cr:3304:        bar_g = dark_mode ? 0.518 : 0.478
src/ui/renderers/appkit_renderer.cr:3309:        line_r = dark_mode ? 1.0 : 1.0
src/ui/renderers/appkit_renderer.cr:3310:        line_g = dark_mode ? 0.62 : 0.58
src/ui/renderers/appkit_renderer.cr:3315:        grid_gray = dark_mode ? 0.3 : 0.85
src/ui/renderers/appkit_renderer.cr:3318:        lbl_gray = dark_mode ? 0.92 : 0.08
src/ui/renderers/appkit_renderer.cr:3647:        overrides_ptr = LibSwiftKitBridge.apsk_color_picker_overrides_new
src/ui/renderers/appkit_renderer.cr:3648:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:3649:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/appkit_renderer.cr:3664:          view.label.to_unsafe, c.r, c.g, c.b, c.a, overrides_ptr, action_token,
src/ui/renderers/appkit_renderer.cr:3716:      # Visit: ActivityView -> NSVisualEffectView (sheet material) + four zones
src/ui/renderers/appkit_renderer.cr:3719:      # This renderer emits a HIG-honest sheet-material surface containing all
src/ui/renderers/appkit_renderer.cr:3726:      # Material: NSVisualEffectMaterialSheet = 11 (tracks appearance). Although
src/ui/renderers/appkit_renderer.cr:3728:      # approximation, so use the same sheet material as UI::Sheet. Popover
src/ui/renderers/appkit_renderer.cr:3729:      # material renders noticeably flatter in the live capture and weakens the
src/ui/renderers/appkit_renderer.cr:3736:        # token shim so a brand override on `design_tokens` cascades here too.
src/ui/renderers/appkit_renderer.cr:3741:        # Outer glass container — sheet material approximates the iOS share sheet
src/ui/renderers/appkit_renderer.cr:3743:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:3744:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)    # NSVisualEffectMaterialSheet
src/ui/renderers/appkit_renderer.cr:3836:        # Apple share sheet destination chrome (Mail, Messages, AirDrop, Notes, etc.).
src/ui/renderers/appkit_renderer.cr:3838:        # produced bare amber outline strokes with no tile chrome (Round 1/Round 7
src/ui/renderers/appkit_renderer.cr:3846:        # White for the template glyph on the filled amber tile (ensures contrast
src/ui/renderers/appkit_renderer.cr:3847:        # regardless of appearance — amber gold fill in both light and dark).
src/ui/renderers/appkit_renderer.cr:3868:            # sufficient contrast (white-on-amber ~3.2:1, passing HIG large-text
src/ui/renderers/appkit_renderer.cr:4023:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[activity-view-glass]")
src/ui/renderers/appkit_renderer.cr:4581:      # Current appearance (light / dark) resolved from HIG_APPEARANCE — the
src/ui/renderers/appkit_renderer.cr:4586:        (ENV["HIG_APPEARANCE"]? == "dark") ? :dark : :light
src/ui/renderers/appkit_renderer.cr:4593:      # override on `design_tokens` cascades through.
src/ui/renderers/appkit_renderer.cr:4595:        palette = appearance == :dark ? @design_tokens.colors_dark : @design_tokens.colors_light
src/ui/renderers/appkit_renderer.cr:4622:      # `.tint()` accent cascade adapts contrast automatically across light
src/ui/renderers/appkit_renderer.cr:4623:      # and dark via the dynamic colour the SwiftUI runtime derives from
src/ui/renderers/appkit_renderer.cr:4626:      private def ensure_swiftkit_runtime! : Nil
src/ui/renderers/appkit_renderer.cr:4627:        unless @swiftkit_action_trampoline_installed
src/ui/renderers/appkit_renderer.cr:4629:          @swiftkit_action_trampoline_installed = true
src/ui/renderers/uikit_renderer.cr:6:  require "../native/swiftkit_bridge"
src/ui/renderers/uikit_renderer.cr:7:  require "../native/swiftkit_overrides"
src/ui/renderers/uikit_renderer.cr:162:      @swiftkit_action_trampoline_installed : Bool = false
src/ui/renderers/uikit_renderer.cr:182:        ensure_swiftkit_runtime!
src/ui/renderers/uikit_renderer.cr:193:        overrides_ptr = LibSwiftKitBridge.apsk_label_overrides_new
src/ui/renderers/uikit_renderer.cr:194:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:195:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:205:          text.to_unsafe, overrides_ptr, state_box,
src/ui/renderers/uikit_renderer.cr:212:          view.swiftkit_state_handle = state_slot
src/ui/renderers/uikit_renderer.cr:224:      # colour injection (amber-gold base, plum-for-destructive, dark-mode
src/ui/renderers/uikit_renderer.cr:225:      # tint contrast pass, role × style matrix). Instead it routes
src/ui/renderers/uikit_renderer.cr:229:      # (see `render(...)` / `ensure_swiftkit_runtime!`).
src/ui/renderers/uikit_renderer.cr:235:      #   - VoiceOver `.button` trait + automatic dark-mode tracking
src/ui/renderers/uikit_renderer.cr:238:      # Per-widget overrides only fire when the developer explicitly sets
src/ui/renderers/uikit_renderer.cr:253:        overrides_ptr = LibSwiftKitBridge.apsk_button_overrides_new
src/ui/renderers/uikit_renderer.cr:254:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:255:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:273:          button_label.to_unsafe, overrides_ptr, action_token, state_box,
src/ui/renderers/uikit_renderer.cr:282:          view.swiftkit_state_handle = state_slot
src/ui/renderers/uikit_renderer.cr:429:        overrides_ptr = LibSwiftKitBridge.apsk_image_overrides_new
src/ui/renderers/uikit_renderer.cr:430:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:431:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:434:        ptr = LibSwiftKitBridge.apsk_make_image(view.source.to_unsafe, overrides_ptr)
src/ui/renderers/uikit_renderer.cr:445:        overrides_ptr = LibSwiftKitBridge.apsk_text_field_overrides_new
src/ui/renderers/uikit_renderer.cr:446:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:447:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:459:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:560:      # "cream" in dark captures because the switch inherits a light trait
src/ui/renderers/uikit_renderer.cr:562:      # overrideUserInterfaceStyle (UIUserInterfaceStyleDark=2, Light=1) on
src/ui/renderers/uikit_renderer.cr:565:      # gray track against the correct dark palette immediately.
src/ui/renderers/uikit_renderer.cr:568:        overrides_ptr = LibSwiftKitBridge.apsk_toggle_overrides_new
src/ui/renderers/uikit_renderer.cr:569:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:570:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:583:          view.label.to_unsafe, view.is_on ? 1 : 0, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:589:          view.swiftkit_state_handle = state_slot
src/ui/renderers/uikit_renderer.cr:607:        overrides_ptr = LibSwiftKitBridge.apsk_checkbox_overrides_new
src/ui/renderers/uikit_renderer.cr:608:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:609:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:621:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:640:        overrides_ptr = LibSwiftKitBridge.apsk_radio_group_overrides_new
src/ui/renderers/uikit_renderer.cr:641:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:642:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:658:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:687:        overrides_ptr = LibSwiftKitBridge.apsk_slider_overrides_new
src/ui/renderers/uikit_renderer.cr:688:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:689:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:702:          view.value, view.minimum, view.maximum, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:708:          view.swiftkit_state_handle = state_slot
src/ui/renderers/uikit_renderer.cr:722:        overrides_ptr = LibSwiftKitBridge.apsk_navigation_stack_overrides_new
src/ui/renderers/uikit_renderer.cr:723:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:724:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:734:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:743:        overrides_ptr = LibSwiftKitBridge.apsk_navigation_link_overrides_new
src/ui/renderers/uikit_renderer.cr:744:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:745:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:756:          children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:765:      # Visit: TabView -> UIVisualEffectView (Liquid Glass root) containing
src/ui/renderers/uikit_renderer.cr:773:      #   UIVisualEffectView (glass root: UIGlassEffect iOS 26 / UIBlurEffect
src/ui/renderers/uikit_renderer.cr:774:      #                        systemChromeMaterial=11 fallback)
src/ui/renderers/uikit_renderer.cr:787:        overrides_ptr = LibSwiftKitBridge.apsk_tab_view_overrides_new
src/ui/renderers/uikit_renderer.cr:788:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:789:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:811:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:831:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:835:        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:841:        glass_handle = ObjC.owned(glass_root, label: "UIVisualEffectView[tab-bar-glass]")
src/ui/renderers/uikit_renderer.cr:844:        # Get the contentView (UIVisualEffectView requirement: subviews MUST go in contentView)
src/ui/renderers/uikit_renderer.cr:1034:      # Visit: Alert -> UIVisualEffectView inline card (Liquid Glass)
src/ui/renderers/uikit_renderer.cr:1037:      # we prefer UIGlassEffect; on older SDKs UIBlurEffect(systemMaterial=7)
src/ui/renderers/uikit_renderer.cr:1042:      # screenshot isolation. Material, corner radius, and role-coloring are
src/ui/renderers/uikit_renderer.cr:1043:      # HIG-faithful — hudWindow-equivalent on iOS is systemMaterial.
src/ui/renderers/uikit_renderer.cr:1046:        overrides_ptr = LibSwiftKitBridge.apsk_alert_overrides_new
src/ui/renderers/uikit_renderer.cr:1047:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1048:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1065:          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:1082:                        # UIBlurEffectStyleSystemMaterial = 7
src/ui/renderers/uikit_renderer.cr:1086:        # [[UIVisualEffectView alloc] initWithEffect:blur_effect]
src/ui/renderers/uikit_renderer.cr:1087:        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:1111:        # Add inner stack to contentView (UIVisualEffectView requirement).
src/ui/renderers/uikit_renderer.cr:1224:        outer_handle = ObjC.owned(effect, label: "UIVisualEffectView[alert-glass]")
src/ui/renderers/uikit_renderer.cr:1238:      # is legible in both light and dark appearances.
src/ui/renderers/uikit_renderer.cr:1252:        overrides_ptr = LibSwiftKitBridge.apsk_picker_overrides_new
src/ui/renderers/uikit_renderer.cr:1253:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1254:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1270:          view.selected_index.to_i32, overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1282:        overrides_ptr = LibSwiftKitBridge.apsk_icon_button_overrides_new
src/ui/renderers/uikit_renderer.cr:1283:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1284:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1293:          view.icon.to_unsafe, overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1316:        overrides_ptr = LibSwiftKitBridge.apsk_list_view_overrides_new
src/ui/renderers/uikit_renderer.cr:1317:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1318:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1335:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:1429:              # NOT track dark/light appearance changes.
src/ui/renderers/uikit_renderer.cr:1582:        overrides_ptr = LibSwiftKitBridge.apsk_secure_field_overrides_new
src/ui/renderers/uikit_renderer.cr:1583:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1584:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1596:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1605:        overrides_ptr = LibSwiftKitBridge.apsk_stepper_overrides_new
src/ui/renderers/uikit_renderer.cr:1606:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1607:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1619:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1628:        overrides_ptr = LibSwiftKitBridge.apsk_segmented_control_overrides_new
src/ui/renderers/uikit_renderer.cr:1629:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1630:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1646:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1655:        overrides_ptr = LibSwiftKitBridge.apsk_date_picker_overrides_new
src/ui/renderers/uikit_renderer.cr:1656:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1657:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1669:          view.label.to_unsafe, epoch, overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1678:        overrides_ptr = LibSwiftKitBridge.apsk_time_picker_overrides_new
src/ui/renderers/uikit_renderer.cr:1679:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1680:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1692:          view.label.to_unsafe, epoch, overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1701:        overrides_ptr = LibSwiftKitBridge.apsk_search_field_overrides_new
src/ui/renderers/uikit_renderer.cr:1702:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1703:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1715:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1724:        overrides_ptr = LibSwiftKitBridge.apsk_text_area_overrides_new
src/ui/renderers/uikit_renderer.cr:1725:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1726:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1738:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:1750:        overrides_ptr = LibSwiftKitBridge.apsk_grid_overrides_new
src/ui/renderers/uikit_renderer.cr:1751:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1752:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1766:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:1778:        overrides_ptr = LibSwiftKitBridge.apsk_form_overrides_new
src/ui/renderers/uikit_renderer.cr:1779:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1780:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1802:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:1812:      #        with UIVisualEffectView sidebar column (Liquid Glass)
src/ui/renderers/uikit_renderer.cr:1820:      # fallback to UIBlurEffect(systemChromeMaterial=11) on older SDKs.
src/ui/renderers/uikit_renderer.cr:1823:        overrides_ptr = LibSwiftKitBridge.apsk_navigation_split_view_overrides_new
src/ui/renderers/uikit_renderer.cr:1824:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1825:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1845:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:1864:            # UIBlurEffectStyleSystemChromeMaterial (= 11) on older SDKs.
src/ui/renderers/uikit_renderer.cr:1876:            uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:1892:            # UIVisualEffectView subviews must go in contentView.
src/ui/renderers/uikit_renderer.cr:1925:            sidebar_effect_handle = ObjC.owned(sidebar_effect, label: "UIVisualEffectView[sidebar-glass]")
src/ui/renderers/uikit_renderer.cr:1947:      # Visit: Toolbar -> UIVisualEffectView (Liquid Glass) + horizontal
src/ui/renderers/uikit_renderer.cr:1952:      # use UIGlassEffect (iOS 26+) or UIBlurEffect.systemChromeMaterial
src/ui/renderers/uikit_renderer.cr:1953:      # (iOS 15+) as the background material.
src/ui/renderers/uikit_renderer.cr:1956:      #   UIVisualEffectView (glass root)
src/ui/renderers/uikit_renderer.cr:1968:        overrides_ptr = LibSwiftKitBridge.apsk_toolbar_overrides_new
src/ui/renderers/uikit_renderer.cr:1969:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:1970:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:1987:          Pointer(Void*).null.as(Void*), 0_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:2000:        # UIBlurEffectStyleSystemChromeMaterial = 11 on older SDKs.
src/ui/renderers/uikit_renderer.cr:2008:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2012:        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:2026:        glass_handle = ObjC.owned(glass_root, label: "UIVisualEffectView[toolbar-glass]")
src/ui/renderers/uikit_renderer.cr:2029:        # UIVisualEffectView subviews MUST go in contentView.
src/ui/renderers/uikit_renderer.cr:2106:      # Visit: Sheet -> UIVisualEffectView + inner UIStackView (Liquid Glass)
src/ui/renderers/uikit_renderer.cr:2109:        overrides_ptr = LibSwiftKitBridge.apsk_sheet_overrides_new
src/ui/renderers/uikit_renderer.cr:2110:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2111:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2133:        # `view.swiftkit_state_handle` so `UI::Sheet#is_presented=`
src/ui/renderers/uikit_renderer.cr:2139:          overrides_ptr, dismiss_token, state_box,
src/ui/renderers/uikit_renderer.cr:2144:          view.swiftkit_state_handle = state_slot
src/ui/renderers/uikit_renderer.cr:2160:          # UIBlurEffectStyleSystemChromeMaterial (iOS 15+, tracks appearance).
src/ui/renderers/uikit_renderer.cr:2168:                          # [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]
src/ui/renderers/uikit_renderer.cr:2169:                          # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2175:          # [[UIVisualEffectView alloc] initWithEffect:blur_effect]
src/ui/renderers/uikit_renderer.cr:2176:          uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:2204:            # with the amber ember backdrop in dark mode. The border is set on the
src/ui/renderers/uikit_renderer.cr:2233:          # the UIStackView is transparent so the UIVisualEffectView material bleeds
src/ui/renderers/uikit_renderer.cr:2234:          # through behind the content rows. Without this the glass material is
src/ui/renderers/uikit_renderer.cr:2241:          # UIVisualEffectView pattern — subviews MUST live in contentView
src/ui/renderers/uikit_renderer.cr:2242:          # for the material to render behind them correctly).
src/ui/renderers/uikit_renderer.cr:2267:          outer_handle = ObjC.owned(effect, label: "UIVisualEffectView[sheet-glass]")
src/ui/renderers/uikit_renderer.cr:2305:      # Visit: Popover -> UIVisualEffectView inline card (Liquid Glass)
src/ui/renderers/uikit_renderer.cr:2313:      # Material: UIGlassEffect (iOS 26) preferred; falls back to
src/ui/renderers/uikit_renderer.cr:2314:      # UIBlurEffectStyleSystemChromeMaterial (= 11, tracks appearance) on
src/ui/renderers/uikit_renderer.cr:2325:        overrides_ptr = LibSwiftKitBridge.apsk_popover_overrides_new
src/ui/renderers/uikit_renderer.cr:2326:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2327:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2347:          overrides_ptr, dismiss_token,
src/ui/renderers/uikit_renderer.cr:2365:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2369:        # [[UIVisualEffectView alloc] initWithEffect:blur_effect]
src/ui/renderers/uikit_renderer.cr:2370:        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:2394:        # Add inner stack to contentView (UIVisualEffectView requirement -- subviews
src/ui/renderers/uikit_renderer.cr:2395:        # must live in contentView for the material to render behind them correctly).
src/ui/renderers/uikit_renderer.cr:2419:        outer_handle = ObjC.owned(effect, label: "UIVisualEffectView[popover-glass]")
src/ui/renderers/uikit_renderer.cr:2437:        overrides_ptr = LibSwiftKitBridge.apsk_confirmation_dialog_overrides_new
src/ui/renderers/uikit_renderer.cr:2438:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2439:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2446:          LibSwiftKitBridge.apsk_overrides_set_int(
src/ui/renderers/uikit_renderer.cr:2447:            overrides_ptr, "setConfirmToken:".to_unsafe, tok.to_i64,
src/ui/renderers/uikit_renderer.cr:2453:          LibSwiftKitBridge.apsk_overrides_set_int(
src/ui/renderers/uikit_renderer.cr:2454:            overrides_ptr, "setCancelToken:".to_unsafe, tok.to_i64,
src/ui/renderers/uikit_renderer.cr:2459:          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:2492:      # chrome is an outer UIView so its rounded background and exact width are
src/ui/renderers/uikit_renderer.cr:2497:        overrides_ptr = LibSwiftKitBridge.apsk_card_overrides_new
src/ui/renderers/uikit_renderer.cr:2498:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2499:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2511:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:2531:        # rounded containers. Install it on the outer chrome and pin the inner
src/ui/renderers/uikit_renderer.cr:2544:        # selection based on UI::Card#material -- default :secondary.
src/ui/renderers/uikit_renderer.cr:2545:        color_sel = case view.material
src/ui/renderers/uikit_renderer.cr:2619:        overrides_ptr = LibSwiftKitBridge.apsk_surface_overrides_new
src/ui/renderers/uikit_renderer.cr:2620:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2621:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2633:          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:2645:        overrides_ptr = LibSwiftKitBridge.apsk_divider_overrides_new
src/ui/renderers/uikit_renderer.cr:2646:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2647:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2650:        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2655:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26+) /
src/ui/renderers/uikit_renderer.cr:2656:      # `.background(<Material>)` fallback on iOS 16..25.
src/ui/renderers/uikit_renderer.cr:2663:      def visit(view : UI::GlassBackground)
src/ui/renderers/uikit_renderer.cr:2665:        # SwiftUI's Material enum is discrete; brand `intensity` shifts the
src/ui/renderers/uikit_renderer.cr:2670:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/renderers/uikit_renderer.cr:2672:        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
src/ui/renderers/uikit_renderer.cr:2673:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2674:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2675:        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
src/ui/renderers/uikit_renderer.cr:2686:        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
src/ui/renderers/uikit_renderer.cr:2687:        handle = ObjC.owned(ptr, label: "UIHostingController[GlassBackground]")
src/ui/renderers/uikit_renderer.cr:2716:      # near-white in dark).
src/ui/renderers/uikit_renderer.cr:2743:        # Text color: sentinel-swap for dark-mode legibility.
src/ui/renderers/uikit_renderer.cr:2761:        overrides_ptr = LibSwiftKitBridge.apsk_link_button_overrides_new
src/ui/renderers/uikit_renderer.cr:2762:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2763:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2772:          view.label.to_unsafe, view.url.to_unsafe, overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:2795:      #   in this validation renderer we construct the visual chrome directly
src/ui/renderers/uikit_renderer.cr:2803:        overrides_ptr = LibSwiftKitBridge.apsk_menu_button_overrides_new
src/ui/renderers/uikit_renderer.cr:2804:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2805:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:2822:          view.label.to_unsafe, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:2942:        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:3061:        outer_handle = ObjC.owned(effect, label: "UIVisualEffectView[context-menu]")
src/ui/renderers/uikit_renderer.cr:3068:        overrides_ptr = LibSwiftKitBridge.apsk_toggle_button_overrides_new
src/ui/renderers/uikit_renderer.cr:3069:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:3070:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:3081:          view.label.to_unsafe, overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:3090:        overrides_ptr = LibSwiftKitBridge.apsk_text_editor_overrides_new
src/ui/renderers/uikit_renderer.cr:3091:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:3092:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:3104:          overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:3330:        # Bar area: subtle gray -- 0.92 alpha works in light; dark mode uses
src/ui/renderers/uikit_renderer.cr:3331:        # UITraitCollection overrideUserInterfaceStyle, so the system bar area
src/ui/renderers/uikit_renderer.cr:3334:        # overrideUserInterfaceStyle on the host window level for dark-mode
src/ui/renderers/uikit_renderer.cr:3340:        # light-mode system blue; the dark capture uses the same value.
src/ui/renderers/uikit_renderer.cr:3383:          # title so it renders near-black in light and near-white in dark.
src/ui/renderers/uikit_renderer.cr:3650:        overrides_ptr = LibSwiftKitBridge.apsk_color_picker_overrides_new
src/ui/renderers/uikit_renderer.cr:3651:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:3652:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:3664:          view.label.to_unsafe, c.r, c.g, c.b, c.a, overrides_ptr, action_token,
src/ui/renderers/uikit_renderer.cr:3715:      # Visit: ActivityView -> UIVisualEffectView + four layout zones
src/ui/renderers/uikit_renderer.cr:3722:      # Material: UIGlassEffect (iOS 26) or
src/ui/renderers/uikit_renderer.cr:3723:      #           UIBlurEffect(systemChromeMaterial=11) fallback.
src/ui/renderers/uikit_renderer.cr:3729:        # token shim so a brand override on `design_tokens` cascades here too.
src/ui/renderers/uikit_renderer.cr:3744:        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
src/ui/renderers/uikit_renderer.cr:3759:          # visible in dark-mode captures where the glass tint and backdrop are
src/ui/renderers/uikit_renderer.cr:3987:        # --- Fix 2 (iter-22): iOS dark glass bleed-through ---
src/ui/renderers/uikit_renderer.cr:3990:        # screenshot, so the glass card appears as a solid fill in dark captures.
src/ui/renderers/uikit_renderer.cr:3991:        # Fix: wrap the UIVisualEffectView in a container UIView; install a
src/ui/renderers/uikit_renderer.cr:3993:        # (behind the glass); lower the UIVisualEffectView's alpha to 0.82 so the
src/ui/renderers/uikit_renderer.cr:3998:        # affects the dark appearance where the solid fill obscured all bleed-through.
src/ui/renderers/uikit_renderer.cr:4168:      # the contrast that differentiates the current-page indicator."
src/ui/renderers/uikit_renderer.cr:4184:        # (semantic, near-black on light / near-white on dark) so the filled dot
src/ui/renderers/uikit_renderer.cr:4197:        # dark) for legible but visually subordinate dots on any background.
src/ui/renderers/uikit_renderer.cr:4244:      # is not implemented. The visual chrome (border + chevron) is the
src/ui/renderers/uikit_renderer.cr:4254:        # We override with a 44pt height constraint to meet the HIG minimum touch
src/ui/renderers/uikit_renderer.cr:4408:        overrides_ptr = LibSwiftKitBridge.apsk_confirmation_dialog_overrides_new
src/ui/renderers/uikit_renderer.cr:4409:        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:4410:        target_str = overrides_ptr.address.to_s(16)
src/ui/renderers/uikit_renderer.cr:4432:            LibSwiftKitBridge.apsk_overrides_set_int(
src/ui/renderers/uikit_renderer.cr:4433:              overrides_ptr, "setConfirmToken:".to_unsafe, tok.to_i64,
src/ui/renderers/uikit_renderer.cr:4444:            LibSwiftKitBridge.apsk_overrides_set_int(
src/ui/renderers/uikit_renderer.cr:4445:              overrides_ptr, "setCancelToken:".to_unsafe, tok.to_i64,
src/ui/renderers/uikit_renderer.cr:4451:          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
src/ui/renderers/uikit_renderer.cr:4660:        (!raw.null? && String.new(raw) == "dark") ? :dark : :light
src/ui/renderers/uikit_renderer.cr:4667:        palette = appearance == :dark ? @design_tokens.colors_dark : @design_tokens.colors_light
src/ui/renderers/uikit_renderer.cr:4673:      # model so a brand override on `design_tokens` cascades through.
src/ui/renderers/uikit_renderer.cr:4687:      # `UI::AppKit::Renderer#ensure_swiftkit_runtime!` — see that method
src/ui/renderers/uikit_renderer.cr:4690:      private def ensure_swiftkit_runtime! : Nil
src/ui/renderers/uikit_renderer.cr:4691:        unless @swiftkit_action_trampoline_installed
src/ui/renderers/uikit_renderer.cr:4693:          @swiftkit_action_trampoline_installed = true
src/ui/renderers/uikit_renderer.cr:4816:        # UIStackView stretch a component until text and chrome clip at the

exec
/bin/zsh -lc "nl -ba src/ui/renderers/uikit_renderer.cr | sed -n '2648,2695p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  2648	        UI::Native::Populator.populate_divider(target_str, view, sender)
  2649	
  2650	        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
  2651	        emit(ptr, "UIHostingController[Divider]")
  2652	      end
  2653	
  2654	      # -----------------------------------------------------------------
  2655	      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26+) /
  2656	      # `.background(<Material>)` fallback on iOS 16..25.
  2657	      #
  2658	      # Phase 3 remediation: migrated to the populator + facade flow so
  2659	      # the "headline visual differentiator" the Phase 3 README names
  2660	      # (Liquid Glass on default Card/Sheet surfaces) is wired through
  2661	      # the same default-detection cascade as every other widget.
  2662	      # -----------------------------------------------------------------
  2663	      def visit(view : UI::GlassBackground)
  2664	        # Phase 5: resolve the Apple-quantized step from the active tokens.
  2665	        # SwiftUI's Material enum is discrete; brand `intensity` shifts the
  2666	        # step picked for `:regular`-declared surfaces per the documented
  2667	        # quantization table in brief.yml adapter_cardinality row 1.
  2668	        # Per-view declared steps (`:thick`, `:thin`, etc.) are honored as
  2669	        # the developer's intent and not remapped by intensity.
  2670	        apple_step = @design_tokens.material.apple_step(view.material)
  2671	
  2672	        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
  2673	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  2674	        target_str = overrides_ptr.address.to_s(16)
  2675	        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
  2676	
  2677	        child_ptr = Pointer(Void).null
  2678	        child_native : NativeView? = nil
  2679	        if content = view.content
  2680	          if d = render_detached(content)
  2681	            child_native = d
  2682	            child_ptr = d.handle.ptr!
  2683	          end
  2684	        end
  2685	
  2686	        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
  2687	        handle = ObjC.owned(ptr, label: "UIHostingController[GlassBackground]")
  2688	        native = NativeView.new(handle)
  2689	        if c = child_native
  2690	          native.add_child(c)
  2691	        end
  2692	        push_native(native)
  2693	      end
  2694	
  2695	      # -----------------------------------------------------------------

exec
/bin/zsh -lc "nl -ba src/ui/renderers/appkit_renderer.cr | sed -n '1558,1615p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  1558	            change_handler.call(v.to_i32)
  1559	          end
  1560	        end
  1561	
  1562	        seg_count = view.segments.size
  1563	        segs_buf = Pointer(UInt8*).malloc(seg_count.to_u64)
  1564	        view.segments.each_with_index { |s, i| segs_buf[i] = s.to_unsafe }
  1565	
  1566	        ptr = LibSwiftKitBridge.apsk_make_segmented_control(
  1567	          segs_buf.as(Void*), seg_count.to_i32, view.selected_index.to_i32,
  1568	          overrides_ptr, action_token,
  1569	        )
  1570	        handle = ObjC.owned(ptr, label: "NSHostingView[SegmentedControl]")
  1571	        native = NativeView.new(handle)
  1572	        native.track_callback_id(action_token) unless action_token == 0_u64
  1573	        push_native(native)
  1574	      end
  1575	
  1576	      # -----------------------------------------------------------------
  1577	      # Visit: DatePicker -> SwiftUI DatePicker(...).
  1578	      # -----------------------------------------------------------------
  1579	      def visit(view : UI::DatePicker)
  1580	        overrides_ptr = LibSwiftKitBridge.apsk_date_picker_overrides_new
  1581	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  1582	        target_str = overrides_ptr.address.to_s(16)
  1583	        UI::Native::Populator.populate_date_picker(target_str, view, sender)
  1584	
  1585	        action_token = 0_u64
  1586	        if change_handler = view.on_change
  1587	          action_token = UI::CallbackRegistry.register_action_with_value do |v|
  1588	            change_handler.call(Time.unix(v.to_i64))
  1589	          end
  1590	        end
  1591	
  1592	        epoch = view.selected_date.to_unix.to_f64
  1593	        ptr = LibSwiftKitBridge.apsk_make_date_picker(
  1594	          view.label.to_unsafe, epoch, overrides_ptr, action_token,
  1595	        )
  1596	        handle = ObjC.owned(ptr, label: "NSHostingView[DatePicker]")
  1597	        native = NativeView.new(handle)
  1598	        native.track_callback_id(action_token) unless action_token == 0_u64
  1599	        push_native(native)
  1600	      end
  1601	
  1602	      # -----------------------------------------------------------------
  1603	      # Visit: TimePicker -> SwiftUI DatePicker(.hourAndMinute).
  1604	      # -----------------------------------------------------------------
  1605	      def visit(view : UI::TimePicker)
  1606	        overrides_ptr = LibSwiftKitBridge.apsk_time_picker_overrides_new
  1607	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  1608	        target_str = overrides_ptr.address.to_s(16)
  1609	        UI::Native::Populator.populate_time_picker(target_str, view, sender)
  1610	
  1611	        action_token = 0_u64
  1612	        if change_handler = view.on_change
  1613	          action_token = UI::CallbackRegistry.register_action_with_value do |v|
  1614	            change_handler.call(Time.unix(v.to_i64))
  1615	          end

exec
/bin/zsh -lc "nl -ba src/ui/native/swiftkit_overrides.cr | sed -n '588,645p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
   588	        # so the facade can slice the flat childViews back into sections.
   589	        unless view.sections.empty?
   590	          sender.set_string_array(target, :setSectionHeaders,
   591	            view.sections.map { |s| s.header || "" })
   592	          sender.set_string_array(target, :setSectionFooters,
   593	            view.sections.map { |s| s.footer || "" })
   594	          sender.set_int_array(target, :setSectionItemCounts,
   595	            view.sections.map { |s| s.items.size })
   596	        end
   597	      end
   598	
   599	      # ---------------------------------------------------------------
   600	      # Glass — the Phase 3 "headline visual differentiator". On iOS 26 /
   601	      # macOS 26 the facade routes through `.glassEffect()` for real
   602	      # Liquid Glass; on pre-26 OSes it falls back to `.background(<Material>)`.
   603	      #
   604	      # `material` mirrors the Crystal `UI::GlassBackground.material`
   605	      # symbol (:regular | :thin | :ultra_thin | :thick | :chrome). The
   606	      # facade switch normalises camelCase keys (`ultraThin`) on the
   607	      # Swift side; we emit them in the same shape so the facade
   608	      # dispatch stays simple.
   609	      # Glass populator. `apple_step` is the Apple-quantized step Symbol the
   610	      # renderer has resolved via `tokens.material.apple_step(view.material)`.
   611	      # The populator emits the facade `setMaterial:` key derived from the
   612	      # resolved Symbol, not from `view.material` directly, so brand
   613	      # intensity overrides cascade onto the SwiftUI Material enum case per
   614	      # the Phase 5 brief's adapter_cardinality row 1 contract.
   615	      #
   616	      # `apple_step` defaults to `view.material` so spec-level callers that
   617	      # don't have a renderer can still exercise the populator without
   618	      # threading tokens through the test fixtures.
   619	      def self.populate_glass_background(target : String, view : UI::GlassBackground, sender : Sender, apple_step : Symbol = view.material)
   620	        populate_view_common(target, view, sender)
   621	
   622	        # Map quantized Crystal Symbol -> Swift facade key. `:regular` is
   623	        # the SwiftUI default; we still emit when the resolved step IS
   624	        # :regular AND the view's declared material differs (brand
   625	        # quantization shifted the step), so the facade receives the
   626	        # resolved value rather than its own default.
   627	        emit = apple_step != :regular || view.material != :regular
   628	        if emit
   629	          key = case apple_step
   630	                when :ultra_thin  then "ultraThin"
   631	                when :thin        then "thin"
   632	                when :regular     then "regular"
   633	                when :thick       then "thick"
   634	                when :chrome      then "ultraThick" # closest SwiftUI Material analogue
   635	                else                   apple_step.to_s
   636	                end
   637	          sender.set_string(target, :setMaterial, key)
   638	        end
   639	      end
   640	
   641	      # Symbol-to-ObjC-selector helper. The Populator emits setter
   642	      # symbols without a trailing colon (`:setStyle`,
   643	      # `:setBackgroundColor`) because that's the shape the spec
   644	      # recording sender asserts against. ObjC selectors for single-
   645	      # argument setters need the colon; the production

exec
/bin/zsh -lc "nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift | sed -n '1,120p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	// GlassBackgroundFacade — SwiftUI bridge for UI::GlassBackground, the
     2	// Phase 3 "headline visual differentiator" the README names. On iOS 26 /
     3	// macOS 26 (the Liquid Glass SDKs) the facade routes through
     4	// `.glassBackgroundEffect()`; on the pre-26 OSes (iOS 16..25 / macOS
     5	// 13..25) it falls back to the matching static Material so the surface
     6	// still tracks appearance correctly.
     7	//
     8	// Phase 5 will extend this facade with the full material parameter set
     9	// (intensity, tint, corner curve). The Phase 3 wiring is the platform
    10	// floor: a developer who writes `UI::GlassBackground.new(content)` gets
    11	// real Liquid Glass on iOS 26 today, with no extra knobs.
    12	//
    13	// Brand identity: `GlassBackground` deliberately does NOT apply the
    14	// brand tint (Apple convention — glass surfaces accept system accent
    15	// only). The `.tint()` cascade in `HostingHelpers.host(_:)` propagates
    16	// the brand colour to interactive descendants inside the glass surface;
    17	// the glass material itself stays neutral.
    18	
    19	import SwiftUI
    20	import Foundation
    21	
    22	@objc(APSKGlassBackgroundFacade)
    23	public final class GlassBackgroundFacade: NSObject {
    24	    /// Build the glass-backed platform view. `childView` is the already-
    25	    /// hosted Crystal child (the content placed behind the glass). When
    26	    /// `nil`, the facade renders an empty glass card.
    27	    @objc public static func makeGlassBackground(
    28	        overrides: GlassBackgroundOverrides,
    29	        childView: APSKPlatformView?
    30	    ) -> APSKPlatformView {
    31	        // Embed the Crystal child via APSKHostedChild so it participates
    32	        // in SwiftUI layout. When no child is supplied we render a clear
    33	        // expanding rectangle so the glass surface has something to back.
    34	        let materialKey = overrides.material ?? "regular"
    35	
    36	        // PHASE 5 — Apple-platform material selection.
    37	        //
    38	        // Per brief.yml adapter_cardinality row 1, the SwiftUI Material
    39	        // enum is the public-API <-> Apple-platform adapter. Brand
    40	        // intensity QUANTIZES through a 5-step table, and the pre-26
    41	        // `.background(<Material>)` path honors the resolved step
    42	        // directly. The iOS 26 / macOS 26+ `.glassEffect()` path is the
    43	        // canonical Apple HIG Liquid Glass treatment — it intentionally
    44	        // does NOT vary by Crystal-side step because Liquid Glass is the
    45	        // system-canonical behavior Apple wants every glass surface to
    46	        // adopt on that OS version. Per the brief: "intensity 1.3
    47	        // quantizes to .regularMaterial on Apple (visually IDENTICAL to
    48	        // default intensity 1.0)" — and the same is true across all 5
    49	        // declared steps on iOS 26+ because Liquid Glass treats them
    50	        // uniformly. Brands wanting a step-differentiated Apple look on
    51	        // pre-26 SDKs do see the difference via the .background fallback
    52	        // below; on iOS 26+ the difference is intentionally absent.
    53	        let material: Material = {
    54	            switch materialKey {
    55	            case "thin":       return .thinMaterial
    56	            case "thick":      return .thickMaterial
    57	            case "ultraThin":  return .ultraThinMaterial
    58	            case "ultraThick": return .ultraThickMaterial
    59	            default:           return .regularMaterial
    60	            }
    61	        }()
    62	
    63	        let backed: AnyView
    64	        if #available(iOS 26.0, macOS 26.0, *) {
    65	            // Liquid Glass — system-canonical, step-agnostic by design.
    66	            _ = material  // pre-26 only; unused on the Liquid Glass path
    67	            backed = AnyView(
    68	                hostedChild(childView)
    69	                    .glassEffect()
    70	            )
    71	        } else {
    72	            // Pre-26 fallback. `Material` tracks appearance + step.
    73	            backed = AnyView(
    74	                hostedChild(childView)
    75	                    .background(material)
    76	            )
    77	        }
    78	
    79	        let composed = CommonModifiers.apply(backed, overrides: overrides)
    80	        return HostingHelpers.host(composed)
    81	    }
    82	
    83	    /// Wrap the platform-view child in `APSKHostedChild` (or an empty
    84	    /// rectangle when absent). Returning an `AnyView` keeps the iOS 26 /
    85	    /// fallback branches both type-erased to the same shape.
    86	    @ViewBuilder
    87	    private static func hostedChild(_ child: APSKPlatformView?) -> some View {
    88	        if let child = child {
    89	            APSKHostedChild(view: child)
    90	        } else {
    91	            Rectangle().fill(Color.clear)
    92	        }
    93	    }
    94	}

exec
/bin/zsh -lc "nl -ba src/ui/renderers/appkit_renderer.cr | sed -n '1840,1905p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  1840	            LibObjCBridge.objc_send_long(sidebar_inner, sel("setOrientation:"), 1_i64)
  1841	            LibObjCBridge.objc_send_1d(sidebar_inner, sel("setSpacing:"), 2.0)
  1842	            LibObjCBridge.objc_send_long(sidebar_inner, sel("setAlignment:"), 5_i64)
  1843	            sidebar_insets = LibObjCBridge::CGRect.new(x: 8.0, y: 8.0, width: 8.0, height: 8.0)
  1844	            LibObjCBridge.objc_send_rect_void(sidebar_inner, sel("setEdgeInsets:"), sidebar_insets)
  1845	            LibObjCBridge.objc_send_bool(sidebar_inner, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
  1846	            LibObjCBridge.objc_add_subview(sidebar_effect, sidebar_inner)
  1847	
  1848	            # Pin inner stack to all four edges of the effect view.
  1849	            %w(topAnchor bottomAnchor leadingAnchor trailingAnchor).each do |anchor_sel|
  1850	              inner_anchor = LibObjCBridge.objc_send(sidebar_inner, sel(anchor_sel))
  1851	              effect_anchor = LibObjCBridge.objc_send(sidebar_effect, sel(anchor_sel))
  1852	              next if inner_anchor.null? || effect_anchor.null?
  1853	              constraint = LibObjCBridge.objc_send_id(inner_anchor, sel("constraintEqualToAnchor:"), effect_anchor)
  1854	              LibObjCBridge.objc_send_bool(constraint, sel("setActive:"), 1) unless constraint.null?
  1855	            end
  1856	
  1857	            sidebar_inner_handle = ObjC.borrowed(sidebar_inner, label: "NSStackView[sidebar-inner]")
  1858	            sidebar_inner_native = NativeView.new(sidebar_inner_handle)
  1859	
  1860	            push_stack(sidebar_inner_native, is_nsstack: true)
  1861	            sidebar.accept(self)
  1862	            pop_stack
  1863	
  1864	            # Add glass sidebar directly as an arranged subview of outer.
  1865	            # Do NOT use push_native here — that would add it to the parent
  1866	            # of the NavigationSplitView, producing the orphaned floating inset.
  1867	            sidebar_effect_handle = ObjC.owned(sidebar_effect, label: "NSVisualEffectView[sidebar-glass]")
  1868	            sidebar_effect_native = NativeView.new(sidebar_effect_handle)
  1869	            outer_native.add_child(sidebar_effect_native)
  1870	            LibObjCBridge.objc_send_void_id(outer, sel("addArrangedSubview:"), sidebar_effect)
  1871	
  1872	            # 1pt vertical separator after sidebar column.
  1873	            sep1 = alloc_init("NSBox")
  1874	            # NSBoxSeparator = 2
  1875	            LibObjCBridge.objc_send_long(sep1, sel("setBoxType:"), 2_i64)
  1876	            sep1_size = LibObjCBridge::CGRect.new(x: 1.0, y: 0.0, width: 1.0, height: 0.0)
  1877	            LibObjCBridge.objc_send_rect_void(sep1, sel("setFrameSize:"), sep1_size)
  1878	            LibObjCBridge.objc_send_void_id(outer, sel("addArrangedSubview:"), sep1)
  1879	          end
  1880	        end
  1881	
  1882	        if content = view.content
  1883	          # Content column: vertical NSStackView, fill-width in the remaining space.
  1884	          content_col = alloc_init("NSStackView")
  1885	          LibObjCBridge.objc_send_long(content_col, sel("setOrientation:"), 1_i64)
  1886	          LibObjCBridge.objc_send_1d(content_col, sel("setSpacing:"), 0.0)
  1887	          LibObjCBridge.objc_send_long(content_col, sel("setDistribution:"), 0_i64)
  1888	          LibObjCBridge.objc_send_long(content_col, sel("setAlignment:"), 5_i64)
  1889	          # Constrain the content column to the width set on the UI::View if provided.
  1890	          if min_w = content.minimum_width
  1891	            LibObjCBridge.objc_constrain_width(content_col, min_w)
  1892	          end
  1893	          content_col_handle = ObjC.owned(content_col, label: "NSStackView[content-col]")
  1894	          content_col_native = NativeView.new(content_col_handle)
  1895	
  1896	          push_stack(content_col_native, is_nsstack: true)
  1897	          content.accept(self)
  1898	          pop_stack
  1899	
  1900	          outer_native.add_child(content_col_native)
  1901	          LibObjCBridge.objc_send_void_id(outer, sel("addArrangedSubview:"), content_col)
  1902	        end
  1903	
  1904	        if detail = view.detail
  1905	          # 1pt separator before detail column.

exec
/bin/zsh -lc "rg -n \"Visit: GlassBackground|def visit\\(view : UI::GlassBackground\\)|apple_step\" src/ui/renderers/appkit_renderer.cr src/ui/renderers/uikit_renderer.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
src/ui/renderers/uikit_renderer.cr:2655:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26+) /
src/ui/renderers/uikit_renderer.cr:2663:      def visit(view : UI::GlassBackground)
src/ui/renderers/uikit_renderer.cr:2670:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/renderers/uikit_renderer.cr:2675:        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
src/ui/renderers/appkit_renderer.cr:2638:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
src/ui/renderers/appkit_renderer.cr:2646:      def visit(view : UI::GlassBackground)
src/ui/renderers/appkit_renderer.cr:2649:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/renderers/appkit_renderer.cr:2654:        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)

exec
/bin/zsh -lc "nl -ba src/ui/renderers/web_renderer.cr | sed -n '1394,1448p' && nl -ba src/ui/renderers/web_renderer.cr | sed -n '2010,2030p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  1394	          el.add_style("width: #{view.thickness}px; background: #{color_css}; height: 100%")
  1395	        end
  1396	        el.set_attribute("role", "separator")
  1397	
  1398	        apply_common_styles(el, view)
  1399	        push_element(el)
  1400	      end
  1401	
  1402	      def visit(view : UI::GlassBackground)
  1403	        el = Components::Elements::Div.new
  1404	
  1405	        # Phase 5: glass material is tokenized. The inline style references
  1406	        # the per-step `--ap-material-*` custom properties the WebGenerator
  1407	        # emits on `:root` (which themselves resolve `blur` via
  1408	        # `calc(<base>px * var(--ap-material-intensity, 1))`). The
  1409	        # `ap-glass--<step>` class binds to the `@supports` fallback rule.
  1410	        step_key = material_css_step_key(view.material)
  1411	        el.add_class("ap-glass")
  1412	        el.add_class("ap-glass--#{step_key}")
  1413	        el.add_style(
  1414	          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
  1415	          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
  1416	          "background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step_key}) * 100%), transparent); " \
  1417	          "border-radius: inherit"
  1418	        )
  1419	
  1420	        if content = view.content
  1421	          @element_stack.push(el)
  1422	          content.accept(self)
  1423	          @element_stack.pop
  1424	        end
  1425	
  1426	        apply_common_styles(el, view)
  1427	        if parent = @element_stack.last?
  1428	          parent.as(Components::Elements::ContainerElement).add_child(el)
  1429	        else
  1430	          @root = el
  1431	        end
  1432	      end
  1433	
  1434	      # Map a `GlassBackground#material` Symbol to the CSS class suffix /
  1435	      # custom-property segment. Unknown symbols fall back to `regular`.
  1436	      private def material_css_step_key(name : Symbol) : String
  1437	        case name
  1438	        when :ultra_thin then "ultra-thin"
  1439	        when :thin       then "thin"
  1440	        when :regular    then "regular"
  1441	        when :thick      then "thick"
  1442	        when :chrome     then "chrome"
  1443	        else                  "regular"
  1444	        end
  1445	      end
  1446	
  1447	      # ---------------------------------------------------------------
  1448	      # P2 Wave 3 Visit methods
  2010	        end
  2011	      end
  2012	
  2013	      # ActivityView -> semantic HTML share-sheet approximation.
  2014	      # Web rendering: popover-style card with all four zones.
  2015	      def visit(view : UI::ActivityView)
  2016	        el = Components::Elements::Div.new
  2017	        # Phase 5: ActivityView's translucent surface is tokenized to the
  2018	        # `:thin` material step. Inline style references `var(--ap-material-*)`
  2019	        # for both backdrop-filter and the opacity-driven color-mix
  2020	        # background, so brand intensity AND the @supports fallback both
  2021	        # cascade through the single token source of truth.
  2022	        el.add_class("ap-glass")
  2023	        el.add_class("ap-glass--thin")
  2024	        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); -webkit-backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")
  2025	        el.set_attribute("role", "dialog")
  2026	        el.set_attribute("aria-label", view.title)
  2027	
  2028	        # Zone 1: Header
  2029	        header = Components::Elements::Div.new
  2030	        header.add_style("display: flex; flex-direction: row; align-items: center; gap: 12px")

exec
/bin/zsh -lc "nl -ba src/ui/renderers/appkit_renderer.cr | sed -n '2630,2678p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  2630	        target_str = overrides_ptr.address.to_s(16)
  2631	        UI::Native::Populator.populate_divider(target_str, view, sender)
  2632	
  2633	        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
  2634	        emit(ptr, "NSHostingView[Divider]")
  2635	      end
  2636	
  2637	      # -----------------------------------------------------------------
  2638	      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
  2639	      # with `.background(<Material>)` fallback on pre-26 OSes.
  2640	      #
  2641	      # Phase 3 remediation: migrated to the populator + facade flow so
  2642	      # the "headline visual differentiator" the Phase 3 README names
  2643	      # (Liquid Glass on default Card/Sheet surfaces) is wired through
  2644	      # the same default-detection cascade as every other widget.
  2645	      # -----------------------------------------------------------------
  2646	      def visit(view : UI::GlassBackground)
  2647	        # Phase 5: resolve the Apple-quantized step from the active tokens.
  2648	        # See uikit_renderer.cr#visit(UI::GlassBackground) for the contract.
  2649	        apple_step = @design_tokens.material.apple_step(view.material)
  2650	
  2651	        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
  2652	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  2653	        target_str = overrides_ptr.address.to_s(16)
  2654	        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
  2655	
  2656	        child_ptr = Pointer(Void).null
  2657	        child_native : NativeView? = nil
  2658	        if content = view.content
  2659	          if d = render_detached(content)
  2660	            child_native = d
  2661	            child_ptr = d.handle.ptr!
  2662	          end
  2663	        end
  2664	
  2665	        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
  2666	        handle = ObjC.owned(ptr, label: "NSHostingView[GlassBackground]")
  2667	        native = NativeView.new(handle)
  2668	        if c = child_native
  2669	          native.add_child(c)
  2670	        end
  2671	        push_native(native)
  2672	      end
  2673	
  2674	      # -----------------------------------------------------------------
  2675	      # P2 Wave 3 Visit methods
  2676	      # -----------------------------------------------------------------
  2677	
  2678	      def visit(view : UI::AsyncImage)

exec
/bin/zsh -lc "nl -ba src/ui/renderers/android_renderer.cr | sed -n '2170,2215p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  2170	    # Visit: GlassBackground -> android.widget.FrameLayout + RenderEffect
  2171	    #
  2172	    # Phase 5: tokenizes the previously hard-coded per-step alpha table.
  2173	    # On API 31+, the host's `AssetPipelineGlassHelper.applyGlass` static
  2174	    # helper applies `RenderEffect.createBlurEffect(radius, radius,
  2175	    # TileMode.CLAMP)` where `radius = step.blur_radius * intensity`. On
  2176	    # API < 31 (or when the helper class is not bundled), the helper
  2177	    # falls back to `setBackgroundColor(fallbackArgb)` at the per-step
  2178	    # opacity. Crystal-side resolution is uniform — only the JNI bridge
  2179	    # branches on SDK version.
  2180	    #
  2181	    # Empirical verification (real RenderEffect render on a real device)
  2182	    # is Phase 6.5's audit harness work per the Phase 5 brief.
  2183	    # -----------------------------------------------------------------
  2184	    def visit(view : UI::GlassBackground)
  2185	      resolved = @design_tokens.material.resolve(view.material)
  2186	
  2187	      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
  2188	
  2189	      # Compose fallback ARGB: white tint (0xFFFFFF) at per-step opacity.
  2190	      # Matches the previous hard-coded alpha-byte table when opacity is
  2191	      # at the default values (0.20/0.40/0.60/0.73/0.87 -> 0x33/0x66/0x99/0xBB/0xDD).
  2192	      alpha_byte = (resolved.opacity * 255.0).round.to_i.clamp(0, 255)
  2193	      fallback_argb = ((alpha_byte.to_u32 << 24) | 0x00FFFFFF_u32).to_i32!
  2194	
  2195	      applied_real_blur = LibAndroidBridge.android_view_apply_glass(
  2196	        @env, fl, resolved.blur_radius.to_f32, fallback_argb
  2197	      )
  2198	
  2199	      # Defensive: if the helper class wasn't bundled (returns 0 even on
  2200	      # API 31+), fall through to the legacy alpha background so the
  2201	      # surface remains visually distinguishable.
  2202	      if applied_real_blur == 0
  2203	        LibAndroidBridge.android_view_set_background_color(@env, fl, fallback_argb)
  2204	      end
  2205	
  2206	      apply_common_properties(fl, view)
  2207	
  2208	      global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
  2209	      handle = JNI.wrap_global(global_fl, label: "FrameLayout[glass]")
  2210	      native = NativeView.new(handle)
  2211	
  2212	      if content = view.content
  2213	        push_stack(native, fl, is_linear: false)
  2214	        content.accept(self)
  2215	        pop_stack

exec
/bin/zsh -lc 'rg -n "GlassBackground|applyGlass|RenderEffect|fallback|compose_argb|material|resolve|API 31|VERSION.SDK_INT|android_view_apply_glass|0x" src/ui/renderers/android_renderer.cr src/ui/native/android_bridge.c' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
src/ui/native/android_bridge.c:108:            (*env)->CallVoidMethod(env, gradient, set_color, 0x00000000);
src/ui/native/android_bridge.c:138:        jclass style_cls = (*env)->FindClass(env, "com/google/android/material/R$style");
src/ui/native/android_bridge.c:890:void android_material_button_set_background_tint(void *env_ptr, void *btn, int32_t argb) {
src/ui/native/android_bridge.c:904:void android_material_button_set_stroke_color(void *env_ptr, void *btn, int32_t argb) {
src/ui/native/android_bridge.c:918:void android_material_button_set_stroke_width(void *env_ptr, void *btn, int32_t width) {
src/ui/native/android_bridge.c:928:void android_material_button_set_corner_radius(void *env_ptr, void *btn, int32_t radius) {
src/ui/native/android_bridge.c:938:void android_material_card_set_background_color(void *env_ptr, void *card, int32_t argb) {
src/ui/native/android_bridge.c:948:void android_material_card_set_radius(void *env_ptr, void *card, float radius) {
src/ui/native/android_bridge.c:958:void android_material_card_set_elevation(void *env_ptr, void *card, float elevation) {
src/ui/native/android_bridge.c:968:void android_material_card_set_stroke_color(void *env_ptr, void *card, int32_t argb) {
src/ui/native/android_bridge.c:978:void android_material_card_set_stroke_width(void *env_ptr, void *card, int32_t width) {
src/ui/native/android_bridge.c:1475:// Phase 5 — Glass material RenderEffect bridge.
src/ui/native/android_bridge.c:1477:// Calls the host's AssetPipelineGlassHelper.applyGlass(view, blurRadius,
src/ui/native/android_bridge.c:1478:// fallbackArgb) static helper. The helper itself decides API 31+ blur vs
src/ui/native/android_bridge.c:1480:// real RenderEffect blur was applied, 0 if the fallback alpha was used or
src/ui/native/android_bridge.c:1483:int32_t android_view_apply_glass(void *env_ptr, void *view, float blur_radius, int32_t fallback_argb) {
src/ui/native/android_bridge.c:1492:    jmethodID apply = ap_get_static_method(env, helper_cls, "applyGlass", "(Landroid/view/View;FI)Z");
src/ui/native/android_bridge.c:1500:                                                     (jint)fallback_argb);
src/ui/renderers/android_renderer.cr:67:    # Load from asset name (resolved via Resources)
src/ui/renderers/android_renderer.cr:135:    fun android_material_button_set_background_tint(env : Void*, btn : Void*, argb : Int32)
src/ui/renderers/android_renderer.cr:136:    fun android_material_button_set_stroke_color(env : Void*, btn : Void*, argb : Int32)
src/ui/renderers/android_renderer.cr:137:    fun android_material_button_set_stroke_width(env : Void*, btn : Void*, width : Int32)
src/ui/renderers/android_renderer.cr:138:    fun android_material_button_set_corner_radius(env : Void*, btn : Void*, radius : Int32)
src/ui/renderers/android_renderer.cr:139:    fun android_material_card_set_background_color(env : Void*, card : Void*, argb : Int32)
src/ui/renderers/android_renderer.cr:140:    fun android_material_card_set_radius(env : Void*, card : Void*, radius : Float32)
src/ui/renderers/android_renderer.cr:141:    fun android_material_card_set_elevation(env : Void*, card : Void*, elevation : Float32)
src/ui/renderers/android_renderer.cr:142:    fun android_material_card_set_stroke_color(env : Void*, card : Void*, argb : Int32)
src/ui/renderers/android_renderer.cr:143:    fun android_material_card_set_stroke_width(env : Void*, card : Void*, width : Int32)
src/ui/renderers/android_renderer.cr:202:    # --- Phase 5: Glass material ---
src/ui/renderers/android_renderer.cr:203:    # Applies AssetPipelineGlassHelper.applyGlass(view, blurRadius,
src/ui/renderers/android_renderer.cr:204:    # fallbackArgb). Helper internally chooses RenderEffect.createBlurEffect
src/ui/renderers/android_renderer.cr:205:    # on API 31+ or alpha-fill on older devices. Returns 1 if real blur
src/ui/renderers/android_renderer.cr:206:    # was applied, 0 if the fallback path ran (or the helper class is
src/ui/renderers/android_renderer.cr:208:    fun android_view_apply_glass(env : Void*, view : Void*, blur_radius : Float32, fallback_argb : Int32) : Int32
src/ui/renderers/android_renderer.cr:268:    @material_theme : UI::Theme
src/ui/renderers/android_renderer.cr:270:    # Phase 5 — Glass material tokens. The renderer resolves
src/ui/renderers/android_renderer.cr:271:    # `tokens.material.resolve(view.material)` inside
src/ui/renderers/android_renderer.cr:272:    # `visit(UI::GlassBackground)` to drive both the API 31+ RenderEffect
src/ui/renderers/android_renderer.cr:273:    # path and the alpha-fallback path.
src/ui/renderers/android_renderer.cr:336:      btn = LibAndroidBridge.android_view_new(@env, "com/google/android/material/button/MaterialButton", @context)
src/ui/renderers/android_renderer.cr:343:      button_size = view.font.size > 0 ? view.font.size.to_f32 : @material_theme.font_size_body.to_f32
src/ui/renderers/android_renderer.cr:349:      background_color = material_color(:primary_container)
src/ui/renderers/android_renderer.cr:350:      foreground_color = material_color(:on_primary_container)
src/ui/renderers/android_renderer.cr:356:          background_color = material_color(:error)
src/ui/renderers/android_renderer.cr:357:          foreground_color = material_color(:on_error)
src/ui/renderers/android_renderer.cr:359:          background_color = material_color(:primary)
src/ui/renderers/android_renderer.cr:360:          foreground_color = material_color(:on_primary)
src/ui/renderers/android_renderer.cr:364:          background_color = material_color(:error_container)
src/ui/renderers/android_renderer.cr:365:          foreground_color = material_color(:on_error_container)
src/ui/renderers/android_renderer.cr:367:          background_color = material_color(:primary_container)
src/ui/renderers/android_renderer.cr:368:          foreground_color = material_color(:on_primary_container)
src/ui/renderers/android_renderer.cr:371:        background_color = material_color(:surface)
src/ui/renderers/android_renderer.cr:372:        foreground_color = view.role == :destructive ? material_color(:error) : material_color(:primary)
src/ui/renderers/android_renderer.cr:373:        stroke_color = material_color(:outline)
src/ui/renderers/android_renderer.cr:375:        background_color = 0x00000000
src/ui/renderers/android_renderer.cr:376:        foreground_color = view.role == :destructive ? material_color(:error) : material_color(:primary)
src/ui/renderers/android_renderer.cr:379:          background_color = material_color(:surface_variant)
src/ui/renderers/android_renderer.cr:380:          foreground_color = material_color(:on_surface)
src/ui/renderers/android_renderer.cr:382:          background_color = material_color(:error_container)
src/ui/renderers/android_renderer.cr:383:          foreground_color = material_color(:on_error_container)
src/ui/renderers/android_renderer.cr:385:          background_color = material_color(:secondary_container)
src/ui/renderers/android_renderer.cr:386:          foreground_color = material_color(:on_secondary_container)
src/ui/renderers/android_renderer.cr:388:        stroke_color = material_color(:outline_variant)
src/ui/renderers/android_renderer.cr:392:      LibAndroidBridge.android_material_button_set_background_tint(@env, btn, background_color)
src/ui/renderers/android_renderer.cr:394:      radius = view.corner_radius > 0.0 ? view.corner_radius.round.to_i : @material_theme.corner_radius_large.round.to_i
src/ui/renderers/android_renderer.cr:395:      LibAndroidBridge.android_material_button_set_corner_radius(@env, btn, radius)
src/ui/renderers/android_renderer.cr:398:        LibAndroidBridge.android_material_button_set_stroke_color(@env, btn, stroke)
src/ui/renderers/android_renderer.cr:399:        LibAndroidBridge.android_material_button_set_stroke_width(@env, btn, 1)
src/ui/renderers/android_renderer.cr:401:        LibAndroidBridge.android_material_button_set_stroke_width(@env, btn, 0)
src/ui/renderers/android_renderer.cr:585:      til = new_material_view(
src/ui/renderers/android_renderer.cr:586:        "com/google/android/material/textfield/TextInputLayout",
src/ui/renderers/android_renderer.cr:590:      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:591:      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
src/ui/renderers/android_renderer.cr:592:      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))
src/ui/renderers/android_renderer.cr:598:      et = new_material_view(
src/ui/renderers/android_renderer.cr:599:        "com/google/android/material/textfield/TextInputEditText",
src/ui/renderers/android_renderer.cr:617:                     0x81 # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_PASSWORD
src/ui/renderers/android_renderer.cr:620:                     when KeyboardType::EmailAddress then 0x21 # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_EMAIL_ADDRESS
src/ui/renderers/android_renderer.cr:621:                     when KeyboardType::NumberPad    then 0x02 # TYPE_CLASS_NUMBER
src/ui/renderers/android_renderer.cr:622:                     when KeyboardType::PhonePad     then 0x03 # TYPE_CLASS_PHONE
src/ui/renderers/android_renderer.cr:623:                     when KeyboardType::URL          then 0x11 # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_URI
src/ui/renderers/android_renderer.cr:624:                     else                                 0x01 # TYPE_CLASS_TEXT
src/ui/renderers/android_renderer.cr:850:        fallback_index = view.selected_index
src/ui/renderers/android_renderer.cr:854:              resolved_index = captured_radio_ids.index(checked_id) || fallback_index
src/ui/renderers/android_renderer.cr:855:              change_handler.call(resolved_index)
src/ui/renderers/android_renderer.cr:1047:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1055:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
src/ui/renderers/android_renderer.cr:1056:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
src/ui/renderers/android_renderer.cr:1057:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
src/ui/renderers/android_renderer.cr:1065:      title_tv = new_text_view(view.title, 22.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:1069:        msg_tv = new_text_view(view.message, 15.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:1125:        LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
src/ui/renderers/android_renderer.cr:1126:        LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:1132:          heading = new_text_view(view.label, 14.0_f32, material_color(:on_surface_variant), 1)
src/ui/renderers/android_renderer.cr:1160:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1164:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
src/ui/renderers/android_renderer.cr:1165:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:1166:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 2.0_f32)
src/ui/renderers/android_renderer.cr:1167:      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:1168:      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
src/ui/renderers/android_renderer.cr:1173:        heading = new_text_view(view.label, 14.0_f32, material_color(:on_surface_variant), 1)
src/ui/renderers/android_renderer.cr:1179:      LibAndroidBridge.android_view_set_background_color(@env, spinner, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:1180:      LibAndroidBridge.android_view_set_corner_radius(@env, spinner, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:1189:        empty_state = new_text_view("No options available", 13.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:1276:      view.fallback_view.accept(self)
src/ui/renderers/android_renderer.cr:1280:      view.fallback_view.accept(self)
src/ui/renderers/android_renderer.cr:1284:      view.fallback_view.accept(self)
src/ui/renderers/android_renderer.cr:1288:      view.fallback_view.accept(self)
src/ui/renderers/android_renderer.cr:1295:      til = new_material_view(
src/ui/renderers/android_renderer.cr:1296:        "com/google/android/material/textfield/TextInputLayout",
src/ui/renderers/android_renderer.cr:1300:      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:1301:      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
src/ui/renderers/android_renderer.cr:1302:      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))
src/ui/renderers/android_renderer.cr:1308:      et = new_material_view(
src/ui/renderers/android_renderer.cr:1309:        "com/google/android/material/textfield/TextInputEditText",
src/ui/renderers/android_renderer.cr:1321:      # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_PASSWORD = 0x81
src/ui/renderers/android_renderer.cr:1322:      LibAndroidBridge.android_edittext_set_input_type(@env, et, 0x81)
src/ui/renderers/android_renderer.cr:1381:      value_tv = new_text_view(label_text, 16.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:1438:        fallback_index = view.selected_index
src/ui/renderers/android_renderer.cr:1442:              resolved_index = captured_segment_ids.index(checked_id) || fallback_index
src/ui/renderers/android_renderer.cr:1443:              change_handler.call(resolved_index)
src/ui/renderers/android_renderer.cr:1546:                   material_color(:on_surface)
src/ui/renderers/android_renderer.cr:1553:                 material_color(:outline_variant)
src/ui/renderers/android_renderer.cr:1560:          LibAndroidBridge.android_view_set_stroke(@env, dot, 1.0_f32, material_color(:outline))
src/ui/renderers/android_renderer.cr:1575:      shell = new_material_view(
src/ui/renderers/android_renderer.cr:1576:        "com/google/android/material/textfield/TextInputLayout",
src/ui/renderers/android_renderer.cr:1580:      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, shell, material_color(:surface))
src/ui/renderers/android_renderer.cr:1581:      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, shell, material_color(:outline))
src/ui/renderers/android_renderer.cr:1582:      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, shell, material_color(:on_surface_variant))
src/ui/renderers/android_renderer.cr:1593:      field = new_material_view(
src/ui/renderers/android_renderer.cr:1594:        "com/google/android/material/textfield/MaterialAutoCompleteTextView",
src/ui/renderers/android_renderer.cr:1602:      LibAndroidBridge.android_textview_set_text_size(@env, field, @material_theme.font_size_body.to_f32)
src/ui/renderers/android_renderer.cr:1603:      LibAndroidBridge.android_textview_set_text_color(@env, field, material_color(:on_surface))
src/ui/renderers/android_renderer.cr:1629:               0xFFFFC107_u32.to_i32
src/ui/renderers/android_renderer.cr:1648:      til = new_material_view(
src/ui/renderers/android_renderer.cr:1649:        "com/google/android/material/textfield/TextInputLayout",
src/ui/renderers/android_renderer.cr:1653:      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:1654:      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
src/ui/renderers/android_renderer.cr:1655:      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))
src/ui/renderers/android_renderer.cr:1661:      et = new_material_view(
src/ui/renderers/android_renderer.cr:1662:        "com/google/android/material/textfield/TextInputEditText",
src/ui/renderers/android_renderer.cr:1672:      # InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE = 0x00020001
src/ui/renderers/android_renderer.cr:1673:      LibAndroidBridge.android_edittext_set_input_type(@env, et, 0x00020001)
src/ui/renderers/android_renderer.cr:1819:      toolbar = LibAndroidBridge.android_view_new(@env, "com/google/android/material/appbar/MaterialToolbar", @context)
src/ui/renderers/android_renderer.cr:1822:      LibAndroidBridge.android_toolbar_set_title_text_color(@env, toolbar, material_color(:on_surface))
src/ui/renderers/android_renderer.cr:1841:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1849:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
src/ui/renderers/android_renderer.cr:1850:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
src/ui/renderers/android_renderer.cr:1851:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 10.0_f32)
src/ui/renderers/android_renderer.cr:1852:      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:1853:      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
src/ui/renderers/android_renderer.cr:1859:        LibAndroidBridge.android_view_set_background_color(@env, handle_bar, material_color(:outline))
src/ui/renderers/android_renderer.cr:1866:      title = new_text_view("Bottom sheet", 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:1867:      subtitle = new_text_view("Detents: #{detents}  Active: #{view.selected_detent.to_s.gsub('_', ' ').capitalize}", 13.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:1922:      arrow = new_text_view(arrow_glyph, 20.0_f32, material_color(:primary), 1)
src/ui/renderers/android_renderer.cr:1924:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1927:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
src/ui/renderers/android_renderer.cr:1928:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:1929:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
src/ui/renderers/android_renderer.cr:1930:      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:1931:      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
src/ui/renderers/android_renderer.cr:1943:      title = new_text_view("Popover", 16.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:1944:      subtitle = new_text_view("Arrow edge: #{view.arrow_edge.to_s.capitalize}", 12.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:1985:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1993:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
src/ui/renderers/android_renderer.cr:1994:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
src/ui/renderers/android_renderer.cr:1995:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
src/ui/renderers/android_renderer.cr:2003:      title_tv = new_text_view(view.title, 22.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2007:        msg_tv = new_text_view(view.message, 15.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2038:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2047:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:inverse_surface))
src/ui/renderers/android_renderer.cr:2048:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
src/ui/renderers/android_renderer.cr:2049:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
src/ui/renderers/android_renderer.cr:2053:      message = new_text_view(view.message, 14.0_f32, material_color(:inverse_on_surface), 0)
src/ui/renderers/android_renderer.cr:2070:        duration = new_text_view("#{view.duration.round.to_i}s", 12.0_f32, material_color(:primary), 1)
src/ui/renderers/android_renderer.cr:2079:    # Visit: Card -> com.google.android.material.card.MaterialCardView (via FrameLayout)
src/ui/renderers/android_renderer.cr:2082:      fl = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2088:      LibAndroidBridge.android_material_card_set_background_color(
src/ui/renderers/android_renderer.cr:2090:        material_color(view.material == :tertiary ? :surface_variant : :surface))
src/ui/renderers/android_renderer.cr:2091:      LibAndroidBridge.android_material_card_set_radius(
src/ui/renderers/android_renderer.cr:2093:        (view.corner_radius > 0.0 ? view.corner_radius : @material_theme.corner_radius_medium).to_f32)
src/ui/renderers/android_renderer.cr:2094:      LibAndroidBridge.android_material_card_set_elevation(
src/ui/renderers/android_renderer.cr:2098:        LibAndroidBridge.android_material_card_set_stroke_color(@env, fl, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:2099:        LibAndroidBridge.android_material_card_set_stroke_width(@env, fl, 1)
src/ui/renderers/android_renderer.cr:2101:        LibAndroidBridge.android_material_card_set_stroke_width(@env, fl, 0)
src/ui/renderers/android_renderer.cr:2116:        title_tv = new_text_view(title, 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2170:    # Visit: GlassBackground -> android.widget.FrameLayout + RenderEffect
src/ui/renderers/android_renderer.cr:2173:    # On API 31+, the host's `AssetPipelineGlassHelper.applyGlass` static
src/ui/renderers/android_renderer.cr:2174:    # helper applies `RenderEffect.createBlurEffect(radius, radius,
src/ui/renderers/android_renderer.cr:2177:    # falls back to `setBackgroundColor(fallbackArgb)` at the per-step
src/ui/renderers/android_renderer.cr:2181:    # Empirical verification (real RenderEffect render on a real device)
src/ui/renderers/android_renderer.cr:2184:    def visit(view : UI::GlassBackground)
src/ui/renderers/android_renderer.cr:2185:      resolved = @design_tokens.material.resolve(view.material)
src/ui/renderers/android_renderer.cr:2189:      # Compose fallback ARGB: white tint (0xFFFFFF) at per-step opacity.
src/ui/renderers/android_renderer.cr:2191:      # at the default values (0.20/0.40/0.60/0.73/0.87 -> 0x33/0x66/0x99/0xBB/0xDD).
src/ui/renderers/android_renderer.cr:2192:      alpha_byte = (resolved.opacity * 255.0).round.to_i.clamp(0, 255)
src/ui/renderers/android_renderer.cr:2193:      fallback_argb = ((alpha_byte.to_u32 << 24) | 0x00FFFFFF_u32).to_i32!
src/ui/renderers/android_renderer.cr:2195:      applied_real_blur = LibAndroidBridge.android_view_apply_glass(
src/ui/renderers/android_renderer.cr:2196:        @env, fl, resolved.blur_radius.to_f32, fallback_argb
src/ui/renderers/android_renderer.cr:2200:      # API 31+), fall through to the legacy alpha background so the
src/ui/renderers/android_renderer.cr:2203:        LibAndroidBridge.android_view_set_background_color(@env, fl, fallback_argb)
src/ui/renderers/android_renderer.cr:2268:      handle = JNI.wrap_global(global_ll, label: "LinearLayout[context-menu-fallback]")
src/ui/renderers/android_renderer.cr:2275:          LibAndroidBridge.android_view_set_background_color(@env, sep, 0x2E3C3C43)
src/ui/renderers/android_renderer.cr:2285:                    0xFFFF3B30_u32
src/ui/renderers/android_renderer.cr:2287:                    0xFF8E8E93_u32
src/ui/renderers/android_renderer.cr:2289:                    0xFF111111_u32
src/ui/renderers/android_renderer.cr:2469:      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
src/ui/renderers/android_renderer.cr:2470:      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:2479:      title = new_text_view("Map preview", 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2483:      subtitle = new_text_view(subtitle_text, 13.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2489:      LibAndroidBridge.android_view_set_background_color(@env, canvas, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:2495:      LibAndroidBridge.android_view_set_background_color(@env, route, material_color(:primary))
src/ui/renderers/android_renderer.cr:2500:      LibAndroidBridge.android_view_set_background_color(@env, block_strip, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:2507:        material_color(:on_surface_variant),
src/ui/renderers/android_renderer.cr:2514:        user = new_text_view("User location enabled", 12.0_f32, material_color(:primary), 1)
src/ui/renderers/android_renderer.cr:2529:      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
src/ui/renderers/android_renderer.cr:2530:      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:2540:      title = new_text_view(chart_title, 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2546:        material_color(:on_surface_variant),
src/ui/renderers/android_renderer.cr:2555:      LibAndroidBridge.android_view_set_background_color(@env, plot, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:2561:        empty_label = new_text_view("No series data", 14.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2580:                        material_color(:primary)
src/ui/renderers/android_renderer.cr:2592:          label = new_text_view(point.label, 11.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2614:                        material_color(:primary)
src/ui/renderers/android_renderer.cr:2621:          label = new_text_view(point.label, 11.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2631:        legend = new_text_view("Legend: #{view.data_points.map(&.label).join(", ")}", 12.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2644:      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
src/ui/renderers/android_renderer.cr:2645:      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:2651:      heading = new_text_view(heading_text, 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2661:      source = new_text_view(source_text, 12.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2666:      LibAndroidBridge.android_view_set_background_color(@env, web, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:2672:        base_url = view.base_url || "https://asset-pipeline.local/android-material"
src/ui/renderers/android_renderer.cr:2692:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2695:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
src/ui/renderers/android_renderer.cr:2696:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:2697:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 4.0_f32)
src/ui/renderers/android_renderer.cr:2698:      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:2699:      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
src/ui/renderers/android_renderer.cr:2704:      title = new_text_view(title_text, 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2705:      subtitle = new_text_view("Selected: #{hex_color(view.selected_color)}", 13.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2719:      LibAndroidBridge.android_view_set_stroke(@env, preview_swatch, 1.5_f32, material_color(:outline))
src/ui/renderers/android_renderer.cr:2721:      preview_note = new_text_view(view.supports_alpha ? "Alpha-aware selection enabled" : "Solid color selection", 12.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2760:            LibAndroidBridge.android_view_set_stroke(@env, swatch, 3.0_f32, material_color(:primary))
src/ui/renderers/android_renderer.cr:2762:            LibAndroidBridge.android_view_set_stroke(@env, swatch, 1.0_f32, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:2772:          label = new_text_view(entry[:label], 11.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2788:      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
src/ui/renderers/android_renderer.cr:2789:      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:2794:      heading = new_text_view("Video preview", 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2800:        material_color(:on_surface_variant),
src/ui/renderers/android_renderer.cr:2807:      LibAndroidBridge.android_view_set_background_color(@env, video, material_color(:inverse_surface))
src/ui/renderers/android_renderer.cr:2818:      play_label = new_text_view(view.is_playing ? "Playing" : "Paused", 12.0_f32, material_color(:primary), 1)
src/ui/renderers/android_renderer.cr:2819:      sound_label = new_text_view(view.muted ? "Muted" : "Audio on", 12.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2820:      controls_label = new_text_view(view.shows_controls ? "Controls visible" : "Controls hidden", 12.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2884:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2887:      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
src/ui/renderers/android_renderer.cr:2888:      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
src/ui/renderers/android_renderer.cr:2889:      LibAndroidBridge.android_material_card_set_elevation(@env, card, 10.0_f32)
src/ui/renderers/android_renderer.cr:2890:      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:2891:      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
src/ui/renderers/android_renderer.cr:2906:        LibAndroidBridge.android_view_set_background_color(@env, thumb, material_color(:secondary_container))
src/ui/renderers/android_renderer.cr:2915:        LibAndroidBridge.android_view_set_background_color(@env, avatar, material_color(:secondary_container))
src/ui/renderers/android_renderer.cr:2924:      title = new_text_view(view.title, 18.0_f32, material_color(:on_surface), 1)
src/ui/renderers/android_renderer.cr:2927:        subtitle_view = new_text_view(subtitle, 13.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2941:      status_view = new_text_view(status, 12.0_f32, material_color(:on_surface_variant), 0)
src/ui/renderers/android_renderer.cr:2946:        destinations_heading = new_text_view("Share targets", 13.0_f32, material_color(:on_surface_variant), 1)
src/ui/renderers/android_renderer.cr:2954:          item = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2958:          LibAndroidBridge.android_material_card_set_background_color(@env, item, material_color(:secondary_container))
src/ui/renderers/android_renderer.cr:2959:          LibAndroidBridge.android_material_card_set_radius(@env, item, 20.0_f32)
src/ui/renderers/android_renderer.cr:2960:          LibAndroidBridge.android_material_card_set_elevation(@env, item, 0.0_f32)
src/ui/renderers/android_renderer.cr:2966:          icon = new_text_view(glyph, 18.0_f32, material_color(:on_secondary_container), 1)
src/ui/renderers/android_renderer.cr:2967:          label = new_text_view(destination.label, 11.0_f32, material_color(:on_secondary_container), 0)
src/ui/renderers/android_renderer.cr:2981:        actions_heading = new_text_view("Quick actions", 13.0_f32, material_color(:on_surface_variant), 1)
src/ui/renderers/android_renderer.cr:2990:            tile = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2993:            LibAndroidBridge.android_material_card_set_background_color(@env, tile, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:2994:            LibAndroidBridge.android_material_card_set_radius(@env, tile, @material_theme.corner_radius_medium.to_f32)
src/ui/renderers/android_renderer.cr:2995:            LibAndroidBridge.android_material_card_set_elevation(@env, tile, 0.0_f32)
src/ui/renderers/android_renderer.cr:2996:            LibAndroidBridge.android_material_card_set_stroke_color(@env, tile, material_color(:outline_variant))
src/ui/renderers/android_renderer.cr:2997:            LibAndroidBridge.android_material_card_set_stroke_width(@env, tile, 1)
src/ui/renderers/android_renderer.cr:3001:            action_color = action.role == :destructive ? material_color(:error) : material_color(:on_surface)
src/ui/renderers/android_renderer.cr:3119:      handle = JNI.wrap_global(global_ll, label: "LinearLayout[path-control-fallback]")
src/ui/renderers/android_renderer.cr:3125:        LibAndroidBridge.android_textview_set_text_color(@env, tv, 0xFF111111_u32.to_i32)
src/ui/renderers/android_renderer.cr:3136:        LibAndroidBridge.android_textview_set_text_color(@env, sep, 0xFF8E8E93_u32.to_i32)
src/ui/renderers/android_renderer.cr:3173:    # Android Color format: 0xAARRGGBB
src/ui/renderers/android_renderer.cr:3202:    private def material_color(role : Symbol) : Int32
src/ui/renderers/android_renderer.cr:3203:      theme = @material_theme
src/ui/renderers/android_renderer.cr:3242:                              color : Int32 = material_color(:on_surface),
src/ui/renderers/android_renderer.cr:3252:    private def new_material_view(class_name : String, style_field_name : String) : Void*
src/ui/renderers/android_renderer.cr:3361:      @material_theme = UI::Theme.material_baseline

exec
/bin/zsh -lc "nl -ba src/ui/native/android_bridge.c | sed -n '1470,1525p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "nl -ba src/ui/renderers/android_renderer.cr | sed -n '2560,2595p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  1470	    if (global_ref) {
  1471	        (*env)->DeleteGlobalRef(env, (jobject)global_ref);
  1472	    }
  1473	}
  1474	
  1475	// Phase 5 — Glass material RenderEffect bridge.
  1476	//
  1477	// Calls the host's AssetPipelineGlassHelper.applyGlass(view, blurRadius,
  1478	// fallbackArgb) static helper. The helper itself decides API 31+ blur vs
  1479	// alpha fill — Crystal-side resolution remains uniform. Returns 1 if a
  1480	// real RenderEffect blur was applied, 0 if the fallback alpha was used or
  1481	// the helper class could not be loaded (e.g., the consumer app did not
  1482	// bundle the helper).
  1483	int32_t android_view_apply_glass(void *env_ptr, void *view, float blur_radius, int32_t fallback_argb) {
  1484	    JNIEnv *env = (JNIEnv *)env_ptr;
  1485	    jclass helper_cls = (*env)->FindClass(env, "com/assetpipeline/glass/AssetPipelineGlassHelper");
  1486	    if (!helper_cls) {
  1487	        if ((*env)->ExceptionCheck(env)) {
  1488	            (*env)->ExceptionClear(env);
  1489	        }
  1490	        return 0;
  1491	    }
  1492	    jmethodID apply = ap_get_static_method(env, helper_cls, "applyGlass", "(Landroid/view/View;FI)Z");
  1493	    if (!apply) {
  1494	        (*env)->DeleteLocalRef(env, helper_cls);
  1495	        return 0;
  1496	    }
  1497	    jboolean result = (*env)->CallStaticBooleanMethod(env, helper_cls, apply,
  1498	                                                     (jobject)view,
  1499	                                                     (jfloat)blur_radius,
  1500	                                                     (jint)fallback_argb);
  1501	    (*env)->DeleteLocalRef(env, helper_cls);
  1502	    return result ? 1 : 0;
  1503	}

 succeeded in 0ms:
  2560	      if view.data_points.empty?
  2561	        empty_label = new_text_view("No series data", 14.0_f32, material_color(:on_surface_variant), 0)
  2562	        LibAndroidBridge.android_viewgroup_add_view_wh(@env, plot, empty_label, -2, -2)
  2563	      elsif view.chart_type == :line
  2564	        max_value = view.data_points.map(&.value).max
  2565	        max_value = 1.0 if max_value <= 0.0
  2566	        view.data_points.each do |point|
  2567	          column = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
  2568	          LibAndroidBridge.android_linearlayout_set_orientation(@env, column, 1)
  2569	          LibAndroidBridge.android_linearlayout_set_gravity(@env, column, 1)
  2570	
  2571	          normalized = (point.value / max_value).clamp(0.0, 1.0)
  2572	          stem_height = (normalized * 96.0).round.to_i
  2573	          spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
  2574	          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, spacer, 32, 100 - stem_height)
  2575	
  2576	          dot = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
  2577	          dot_color = if c = point.color
  2578	                        color_to_argb(c)
  2579	                      else
  2580	                        material_color(:primary)
  2581	                      end
  2582	          LibAndroidBridge.android_view_set_background_color(@env, dot, dot_color)
  2583	          LibAndroidBridge.android_view_set_corner_radius(@env, dot, 6.0_f32)
  2584	          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, dot, 12, 12)
  2585	
  2586	          if stem_height > 12
  2587	            stem = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
  2588	            LibAndroidBridge.android_view_set_background_color(@env, stem, dot_color)
  2589	            LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, stem, 2, stem_height - 12)
  2590	          end
  2591	
  2592	          label = new_text_view(point.label, 11.0_f32, material_color(:on_surface_variant), 0)
  2593	          LibAndroidBridge.android_view_set_padding(@env, label, 0, 8, 0, 0)
  2594	          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, label, 48, -2)
  2595	          LibAndroidBridge.android_viewgroup_add_view_wh(@env, plot, column, 56, -2)

exec
/bin/zsh -lc 'rg -n "glass|material|android_bridge|JNI|AssetPipelineGlassHelper|spikes" docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:4:**Depends on:** Phase 1 (token system), Phase 3 (SwiftUI bridge owns the native glass surface)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:5:**Blocks:** Phase 6 (demo app's glass screens)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:14:- **iOS:** `UIVisualEffectView` + `UIBlurEffect` with system materials (ultra_thin, thin, regular, thick, chrome) — **works correctly** but the material strength is hard-coded in `uikit_renderer.cr`, not driven by a token.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:15:- **macOS:** `NSVisualEffectView` with the same materials — **works correctly** but again hard-coded.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:19:The user-visible consequence: the brand can't tune glass intensity (e.g., "make all glass surfaces in this app slightly more frosted") without editing renderer source. The web glass doesn't degrade gracefully. Android doesn't have glass at all.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:21:This phase makes glass material strength a first-class token, wires it through all four renderers, and adds a brand-overridable intensity multiplier.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:28:  - The five material strength steps (`ultra_thin`, `thin`, `regular`, `thick`, `chrome`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:32:  - `uikit_renderer.cr` and `appkit_renderer.cr`: pass the resolved material parameters into the SwiftUI bridge facade for `GlassBackground`. SwiftUI side applies `.background(.regularMaterial)` or `.background(Material(...))` with overrides where the brand intensity adjusts.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:33:  - `web_renderer.cr`: emit `backdrop-filter: blur(var(--ap-material-blur-{step}))` with the variable computed from `tokens.material.blur * tokens.material.intensity`. Add `-webkit-` prefix. Add fallback color for browsers without `backdrop-filter` (detected via `@supports not (backdrop-filter: blur(1px))`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:35:- Brand override demo. A sample theme file shows how to declare `material.intensity = 1.3` for a more frosted look and verify the change cascades to all four platforms.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:39:  - Native renderer: verify the SwiftUI facade receives the resolved material params, not hard-coded constants.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:44:- Adding new material steps beyond the five. The five are sufficient for parity with iOS/macOS system materials.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:45:- Animated material transitions (e.g., glass "fluidifying" when scrolled over). The user can declare a motion token to animate intensity, but the renderers in this phase don't do animation orchestration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:46:- Replacing the existing `GlassBackground` widget API. The widget keeps its current `material : Symbol` property; the symbol now resolves through the token system instead of being hard-coded in renderers.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:52:- Setting `material.intensity` on the brand declaration changes the visible glass strength on all four platforms — verified by screenshot diff.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:53:- Web glass uses `@supports` fallback correctly: in a browser without `backdrop-filter` (test by overriding the support check), the surface falls back to the documented solid color with appropriate opacity.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:62:- **Web `backdrop-filter` performance** can be poor on stacked layers. The renderer should not double-apply backdrop-filter (e.g., a glass surface inside another glass surface — the inner one inherits the parent's already-blurred content). Validator should check stacking.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:64:- **Android `RenderEffect`:** must be applied to the View at the JNI bridge level. The Crystal-side abstraction calls into a Java helper.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:69:- **Phase Brief (YAML, validator-enforced):** `brief.yml` — passes `crystal run scripts/validate_phase_brief.cr -- phases/phase-05-glass-material-tokenization/brief.yml` (exit 0 mandatory before dispatch). Declares all 11 invariant cells, lower-layer assumptions about SwiftUI Material API + backdrop-filter support + Android RenderEffect, repo-derived facts (37 GlassBackground references, 2 backdrop-filter sites in web_renderer.cr, 35311-byte design_tokens.cr), and 3 adapter cardinality MISMATCH rows for SwiftUI's discrete material enum, web `@supports` fallback, and Android < API 31 fallback. Architect-authored 2026-05-22 per `handoff/planning-retrospective-2026-05-22.md` Phase Brief Template.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:21:- [ ] `src/ui/views/glass_background.cr` (one screen — confirms the public API hasn't moved).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:32:### Check 1 — `glass.ios-default-intensity-renders`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:34:**What:** `GlassBackground` at default intensity (`tokens.material.intensity == 1.0`) on iOS renders the platform-correct surface. On iOS 26+, Liquid Glass appears automatically (system Material). On iOS 15–25, regular blur via system Material. No fallback flat fill.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:36:1. Build and run `samples/cross_platform/glass_intensity_demo.cr` on an iOS simulator booted to the highest available iOS version (capture the version: `xcrun simctl list runtimes`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:38:3. Visually compare to the SwiftUI reference snapshot in `swift/AssetPipelineSwiftKit/Tests/Reference/glass_regular_default.png`. Differences in tile noise are expected; differences in apparent blur radius, opacity, or tint hue are failures.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:39:**Pass:** Five visible glass tiers (ultra_thin → chrome) with a monotonically increasing frosted look. iOS 26+ Liquid Glass present (chromatic edge, dynamic specular highlight on motion). No flat-fill regression.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:44:### Check 2 — `glass.macos-default-intensity-renders`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:46:**What:** `GlassBackground` at default intensity on macOS renders the platform-correct surface (`NSVisualEffectView` material backed; on macOS 26+, Liquid Glass appears automatically via SwiftUI `Material`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:49:2. Drive it to the glass intensity demo screen.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:51:4. Compare to the reference image under `swift/AssetPipelineSwiftKit/Tests/Reference/glass_regular_default_macos.png`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:52:**Pass:** Five tiers visible with the expected blur progression. The macOS material translation (UIKit constant → AppKit constant) produces a `regular`-tier result that looks like `NSVisualEffectMaterial.windowBackground`, not like `light` or `medium`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:57:### Check 3 — `glass.web-default-intensity-renders-with-supports-fallback`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:59:**What:** On web at default intensity, a `GlassBackground.new(material: :regular)` produces:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:60:1. An inline `backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular))` declaration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:62:3. A `color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-regular) * 100%), transparent)` background.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:63:4. A `@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px)))` block in the stylesheet root with five `.ap-glass--{step}` rules.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:65:1. Render `samples/cross_platform/glass_intensity_demo.cr` to HTML via the existing web pipeline.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:66:2. Grep the output: `grep -n 'backdrop-filter\|@supports\|ap-material-blur' samples/cross_platform/dist/glass_intensity_demo.html samples/cross_platform/dist/styles.css`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:68:4. To verify the `@supports` fallback path: temporarily override the support check in DevTools by adding a CSS rule that forces `.ap-glass--regular` to ignore `backdrop-filter` (set `backdrop-filter: none !important` in an inline `<style>` injected via the MCP). Confirm the panel does **not** become invisible — it must show the higher-opacity fallback fill. Capture this screenshot too. Revert the override before moving on.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:74:### Check 4 — `glass.android-default-intensity-renderseffect-or-fallback`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:76:**What:** On Android API 31+, `GlassBackground` produces a real `RenderEffect.createBlurEffect`-backed view. On API ≤30, it produces the documented semi-transparent fallback fill. Both paths invoke the `AssetPipelineGlassHelper.applyGlass` static method.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:78:1. Build the Android sample. Confirm `AssetPipelineGlassHelper.java` exists at the expected path.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:79:2. Boot an Android emulator with API 33 (or higher). Install the sample. Drive to the glass intensity demo. Capture via `adb exec-out screencap -p > screenshots/check-4-android-api33.png`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:82:**Pass:** API 33 capture shows a visibly blurred panel. API 29 capture shows the documented semi-transparent fill (no blur, but readable panel separation). The renderer file no longer contains the `0x33FFFFFF / 0x66FFFFFF / 0x99FFFFFF / 0xBBFFFFFF / 0xDDFFFFFF` literal switch — those values now derive from `tokens.material.resolve(...).opacity` and `tokens.colors.surface_panel`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:87:### Check 5 — `glass.intensity-1.5-increases-blur-all-platforms`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:89:**What:** Setting `material.intensity = 1.5` produces visibly more frosted glass on all four platforms.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:91:1. Run the demo with `1.5` on each platform (per the build commands in `samples/cross_platform/glass_intensity_demo.cr`'s header comment).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:100:### Check 6 — `glass.intensity-0.5-decreases-blur-all-platforms`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:102:**What:** Setting `material.intensity = 0.5` produces visibly less frosted glass on all four platforms.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:104:**Pass:** All four platforms show measurable difference *in the opposite direction*. On the `regular` tier, text behind the panel should be more readable at 0.5 than at 1.0. iOS 26+ Liquid Glass should still appear (the `.background(material)` base is unchanged; only the additive `.blur(_:)` modifier delta has flipped sign — verify the SwiftUI bridge handles negative deltas gracefully or clamps the additive blur to zero).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:106:**Note for validator:** The Swift bridge's "delta blur" approach (additive `.blur()` on top of `Material`) means intensity < 1.0 needs a *negative* delta — but SwiftUI's `.blur(radius:)` clamps negative values to zero, which means iOS *cannot make blur lower than the system material's baseline*. This is an Apple-API limitation, not an implementer failure. Confirm with the implementer's handoff whether they documented this and whether the visual difference at 0.5 is therefore smaller on iOS than on web/Android. If the visual difference on iOS at 0.5 is essentially zero, that is acceptable per the limitation but must be acknowledged; the other three platforms still need a clear visible difference.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:110:### Check 7 — `glass.no-nested-double-blur`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:112:**What:** Two `GlassBackground` views nested (one inside the other) do not double-apply the blur effect on web. The inner glass must inherit the parent's already-blurred backdrop rather than re-blurring it.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:114:1. Write a small ad-hoc demo: a `GlassBackground(material: :regular)` containing a `GlassBackground(material: :thin)` containing text.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:115:2. Render to web. Inspect the resulting HTML/CSS: the inner `.ap-glass--thin` should still emit its own `backdrop-filter`, but the validator should confirm that the *visual* result is not a doubly-frosted panel (i.e., the text behind the *outer* panel is blurred once, the inner panel adds its own slight tint but does not stack a second `blur(20px)` on top of the already-blurred backdrop).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:123:### Check 8 — `inspection.no-hard-coded-blur-or-material-constants`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:125:**What:** Three renderer files no longer hard-code blur amounts or material constants for glass surfaces:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:126:- `web_renderer.cr` — no `blur(10px)`, `blur(20px)`, `blur(30px)`, `blur(40px)`, `blur(50px)`, no `72%` opacity literal in the glass visit method.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:127:- `uikit_renderer.cr` — `visit(view : UI::GlassBackground)` does not contain a `case view.material when :ultra_thin then 8_i64` switch (or equivalent); the integer comes from the resolved token.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:128:- `appkit_renderer.cr` — same as uikit, with **one documented exception**: the UIKit→AppKit translation table. That block is the only acceptable hard-coded glass switch in the entire codebase post-Phase 5 and **must be wrapped with the exact marker comment** `# AppKit material translation table — only allowed hard-coded glass switch` immediately above it (see `implementation.md` §"Mandatory marker comment").
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:129:- `android_renderer.cr` — no `0x33FFFFFF / 0x66FFFFFF / 0x99FFFFFF / 0xBBFFFFFF / 0xDDFFFFFF` literals in the glass visit method.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:132:2. `grep -nB1 'when :ultra_thin\|when :thin\|when :regular\|when :thick\|when :chrome' src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr` and inspect every hit. **The only acceptable hits are inside the AppKit translation table**, identified by the marker comment on the line immediately above the case/switch block. The marker text must be exactly `# AppKit material translation table — only allowed hard-coded glass switch` (em dash `—`, not `--`). Any hit not preceded by this marker (within 1 line of context) is a fail.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:133:3. Confirm the marker is present and unique: `grep -nE '# AppKit material translation table — only allowed hard-coded glass switch' src/ui/renderers/appkit_renderer.cr` must return exactly one match in `appkit_renderer.cr` and zero matches in any other source file.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:154:- `spec/ui/design_tokens/material_spec.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:155:- `spec/ui/design_tokens/web_generator_material_spec.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:156:- `spec/ui/renderers/web_glass_spec.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:157:- `spec/ui/renderers/uikit_glass_spec.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:158:- `spec/ui/renderers/appkit_glass_spec.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:159:- `spec/ui/renderers/android_glass_spec.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:191:Otherwise FAIL. If any check is `blocked: true` (e.g., simulator unavailable, JNI bridge not present in sandbox), that counts as a failure for verdict purposes; the team lead may choose to unblock and re-run rather than ship back to the implementer.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:11:Promote glass material strength from hard-coded per-renderer constants to a first-class branch of the `UI::DesignTokens` system. Wire every renderer — web, AppKit, UIKit, and Android — to read material parameters from the resolved token tree. Add a brand-overridable `intensity` scalar so a single line in a brand declaration uniformly scales how frosted glass surfaces appear on all four platforms. Add a `@supports` fallback for web browsers without `backdrop-filter`. Add a real `RenderEffect.createBlurEffect` path on Android API 31+ with a graceful pre-API-31 fallback.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:13:After this phase, no renderer file contains a hard-coded blur radius or material constant for `GlassBackground` (or for any other glass-using widget — see deviation prompt below). All of those values flow from `tokens.material`. A brand declaration in `samples/cross_platform/` can change `material.intensity` to `1.3` and produce visibly more frosted glass on all four platforms with no other code changes.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:25:- [ ] `src/ui/views/glass_background.cr` — the widget. Note that `material : Symbol` is the public API; that does not change in this phase.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:27:- [ ] `src/ui/renderers/uikit_renderer.cr` lines 3068–3117 — current `GlassBackground` visit. Read also lines 1228–1300, 1463–1530, 2380–2480, 2489–2560, 2620–2740, 2776–2870 — every other glass-using widget. (See **Deviation prompt** below.)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:28:- [ ] `src/ui/renderers/appkit_renderer.cr` lines 2731–2774 — current `GlassBackground` visit. Read also lines 1051–1100, 1261–1420, 2005–2100, 2154–2210, 2302–2400, 2428–2500 for sibling glass widgets.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:42:- `src/ui/design_tokens.cr` — Phase 1's source-of-truth. You add a `material : Material` getter on the `Tokens` aggregate. Do not redefine the namespace.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:43:- `src/ui/views/glass_background.cr` — the widget. `material : Symbol` public API is unchanged.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:45:- `src/ui/renderers/uikit_renderer.cr` (lines 3068–3117 + the other glass-using visit methods listed in the Deviation prompt).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:46:- `src/ui/renderers/appkit_renderer.cr` (lines 2731–2774 + sibling glass methods).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:53:- `src/ui/design_tokens/material.cr` — the new `Material` type and `Step` substruct.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:54:- `spec/ui/design_tokens/material_spec.cr`, `spec/ui/design_tokens/web_generator_material_spec.cr`, four renderer-specific specs (`spec/ui/renderers/{web,uikit,appkit,android}_glass_spec.cr`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:55:- `samples/cross_platform/glass_intensity_demo.cr` — the cross-platform intensity demo used by validator checks 1–6.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:59:The prior audit (`handoff/plan-quality-audit-2026-05-20.md` §A) noted that Phase 5 references `LibSwiftKitBridge.material_parameters_new(...)` and `LibSwiftKitBridge.glass_background_overrides_new(...)`, but Phase 3 ships a `lib LibObjCBridge` plus a `SwiftKit` Crystal module — `LibSwiftKitBridge` was never explicitly named. Phase 3's revised "Existing infrastructure to use" section now creates `src/ui/native/lib_swiftkit_bridge.cr` as the typed wrapper. **Phase 5 references the same module — if you find `LibSwiftKitBridge` is not defined when you start Phase 5, the Phase 3 implementer did not ship the typed wrapper they were supposed to. Surface this to the team lead before freelancing.** The cross-phase naming contract is `LibSwiftKitBridge` (typed wrapper, defined in `src/ui/native/lib_swiftkit_bridge.cr`); do not coin a new name.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:65:| Material step set | `:ultra_thin, :thin, :regular, :thick, :chrome` | Five steps. Must match what `GlassBackground#material` accepts. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:67:| CSS variable prefix | `--ap-material-*` | Inherited from Phase 1's `--ap-*` standard. No `--amber-material-*` aliases. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:68:| AppKit material translation marker | `# AppKit material translation table — only allowed hard-coded glass switch` | **Exact text required**, em dash `—`. Validator check 8 enforces. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:69:| Android API gate | 31+ for `RenderEffect.createBlurEffect`, ≤ 30 fallback | Both paths invoke `AssetPipelineGlassHelper.applyGlass`. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:76:| `src/ui/design_tokens/material.cr` | `src/ui/design_tokens.cr` (add `material` getter on `Tokens`) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:77:| `spec/ui/design_tokens/material_spec.cr` + 4 renderer-specific glass specs | `src/ui/renderers/{web,uikit,appkit,android}_renderer.cr` (token-driven glass) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:78:| `samples/cross_platform/glass_intensity_demo.cr` | `swift/AssetPipelineSwiftKit/.../Overrides/GlassBackgroundOverrides.swift`, `Facades/GlassBackgroundFacade.swift` |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:79:| `AssetPipelineGlassHelper.java` (Android API 31+ blur helper) | `src/ui/native/lib_swiftkit_bridge.cr` (from Phase 3, extended for material params) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:85:The Phase 5 scope in `README.md` names `GlassBackground` as the widget being tokenized. However, the existing Apple renderers hard-code `NSVisualEffectMaterial` / `UIBlurEffectStyle` constants inside the visit methods for **TabView, Alert, Sidebar (NavigationSplitView), Toolbar, Sheet, and Popover** as well. If Phase 5 only tokenizes the `GlassBackground` visit, brand `material.intensity = 1.3` will not cascade to those other glass surfaces — only to the ones the developer explicitly wraps in `GlassBackground`. That is almost certainly the wrong behavior for a brand-cascade phase.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:87:**Required action:** Extend the refactor to every visit method that today calls `setMaterial:` with a hard-coded constant. The resolution path is identical to `GlassBackground` — pick the semantic material name (`:popover`, `:sheet`, `:sidebar`, `:toolbar`, etc.), look it up in the token tree, pass the resolved parameters to the renderer call.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:95:Add a new subtype under the existing `UI::DesignTokens` namespace (Phase 1's deliverable). File: `src/ui/design_tokens/material.cr`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:102:    # Glass material parameters.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:105:    # public `GlassBackground#material` symbol values, plus a global
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:113:      # One material strength step.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:121:        # alpha component on Android, automatic on Apple where the system material
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:127:        # ignores (system material handles saturation); Android ignores at API 31+
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:139:        getter apple_material_constant : Int64
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:146:          @apple_material_constant : Int64,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:180:        else raise ArgumentError.new("Unknown material step: #{name}")
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:195:          apple_material_constant: s.apple_material_constant,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:207:      apple_material_constant : Int64
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:216:| Step       | blur_radius (pt/px) | opacity | saturation_boost | luminance | apple_material_constant |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:224:**Note on `apple_material_constant`:** UIKit and AppKit use **different** integer constants for the same semantic material (UIKit `systemMaterial = 10` is the AppKit `windowBackground = 12`'s rough equivalent, not the same number). The token stores the **UIKit** value as canonical; the AppKit renderer applies a small fixed translation table at the call site.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:226:**Mandatory marker comment.** The AppKit translation table is the only place in `appkit_renderer.cr` where it is allowed to hard-code an integer material constant (or a small switch over them). To make the exception unambiguous to grep-based validator checks, the translation table block in `appkit_renderer.cr` MUST be wrapped with a marker comment ON THE LINE IMMEDIATELY ABOVE the block:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:229:# AppKit material translation table — only allowed hard-coded glass switch
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:237:The marker text is exactly `# AppKit material translation table — only allowed hard-coded glass switch` (em dash `—`, not `--`). Phase 5's validation check `material.no-hardcoded-blur-or-material` (check #22 in `validation.md`) greps for this string and skips the immediately-following case/switch block when counting hard-coded constants. Any other place in the codebase using hard-coded `NSVisualEffectMaterial*` / `UIBlurEffectStyle*` integers without this marker is a phase-5 regression.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:244:final_blur_radius = step.blur_radius * tokens.material.intensity.clamp(0.1, 3.0)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:259:`opacity`, `saturation_boost`, and `luminance` are **not** scaled. Brands that want a more opaque glass should override those fields per-step in their brand declaration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:265:Phase 3 introduces the `AssetPipelineSwiftKit` Swift package with the `Overrides` struct pattern (see Phase 3 README for `ButtonOverrides`). Phase 5 adds a sibling struct specifically for material parameters.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:295:        material: MaterialParameters,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:302:        let m: Material = materialFromConstant(material.appleMaterialConstant)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:307:        if material.blurRadius != defaultBlurFor(material.appleMaterialConstant) {
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:312:            let delta = material.blurRadius - defaultBlurFor(material.appleMaterialConstant)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:332:- `materialFromConstant(_:)` is a small switch mapping the canonical UIKit integer to the appropriate SwiftUI `Material` case (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`, `.chromeMaterial`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:333:- `defaultBlurFor(_:)` returns the same radius value as the token default for that step (10, 20, 30, 40, 50). Hard-coding it inside the Swift package is acceptable — it's a constant derived from Apple's published material specs, not a brand value. Document the duplication and reference the token file by path in a code comment.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:342:  resolved = tokens.material.resolve(view.material)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:343:  material_params = LibSwiftKitBridge.material_parameters_new(
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:348:    resolved.apple_material_constant,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:350:  overrides = LibSwiftKitBridge.glass_background_overrides_new(
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:354:  ptr = LibSwiftKitBridge.glass_background_facade_make(material_params, overrides)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:367:The AppKit renderer mirrors this exactly, swapping `LibSwiftKitBridge.glass_background_facade_make` for the `NSHostingController`-returning Mac variant.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:371:- `LibSwiftKitBridge.material_parameters_new(...)` — Phase 3 §7.4 already declares this `fun` as part of the Phase 5 hand-off (`fun material_parameters_new : Void*` plus the per-step setter pattern, with the actual fields populated by Phase 5 setter helpers).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:372:- `LibSwiftKitBridge.glass_background_overrides_new(...)` — declared in Phase 3 §7.4 as part of the standard per-widget overrides constructors.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:373:- `LibSwiftKitBridge.glass_background_facade_make(material_params, overrides)` — declared in Phase 3 §7.4 with signature `fun glass_background_facade_make(material_params : Void*, overrides : Void*) : Void*`. The glass surface is created bare; the child view is attached as a subview by the visitor after the facade call (see the code snippet above). Phase 5 does not need to extend this signature — Phase 3 already declares it in the agreed form.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:381:The web renderer no longer hard-codes blur radii or opacity. It reads the resolved step from the token tree and emits CSS that references `var(--ap-material-blur-{step})` custom properties, plus a `@supports` fallback block.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:385:The CSS generator (Phase 1's `DesignTokens::WebGenerator`) emits these on the `:root` selector. Phase 5 extends the generator to include the material block:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:391:  --ap-material-blur-ultra-thin: calc(10px * var(--ap-material-intensity, 1));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:392:  --ap-material-blur-thin:       calc(20px * var(--ap-material-intensity, 1));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:393:  --ap-material-blur-regular:    calc(30px * var(--ap-material-intensity, 1));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:394:  --ap-material-blur-thick:      calc(40px * var(--ap-material-intensity, 1));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:395:  --ap-material-blur-chrome:     calc(50px * var(--ap-material-intensity, 1));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:397:  --ap-material-opacity-ultra-thin: 0.20;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:398:  --ap-material-opacity-thin:       0.40;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:399:  --ap-material-opacity-regular:    0.60;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:400:  --ap-material-opacity-thick:      0.73;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:401:  --ap-material-opacity-chrome:     0.87;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:403:  --ap-material-saturation-ultra-thin: 1.05;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:404:  --ap-material-saturation-thin:       1.10;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:405:  --ap-material-saturation-regular:    1.15;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:406:  --ap-material-saturation-thick:      1.20;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:407:  --ap-material-saturation-chrome:     1.25;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:409:  --ap-material-intensity: 1;  /* overridden by brand */
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:415:For a `GlassBackground.new(material: :regular)`, the visitor produces:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:418:<div class="ap-glass ap-glass--regular" style="…">…</div>
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:424:backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:425:-webkit-backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:428:    calc(var(--ap-material-opacity-regular) * 100%),
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:439:  .ap-glass--ultra-thin { background: color-mix(in oklch, var(--ap-color-surface-panel) 90%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:440:  .ap-glass--thin       { background: color-mix(in oklch, var(--ap-color-surface-panel) 92%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:441:  .ap-glass--regular    { background: color-mix(in oklch, var(--ap-color-surface-panel) 94%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:442:  .ap-glass--thick      { background: color-mix(in oklch, var(--ap-color-surface-panel) 96%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:443:  .ap-glass--chrome     { background: color-mix(in oklch, var(--ap-color-surface-panel) 98%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:447:The fallback uses higher opacity (90–98%) than the live values because without backdrop blur, a low-opacity fill reads as transparent muddiness rather than as a glass surface. The fallback aims to communicate "this is a panel" — not to fake the glass effect.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:451:Add `ap-glass` and `ap-glass--{step}` classes to the emitted `<div>`. Inline style still wins for the live `backdrop-filter` value; the class selectors exist for the `@supports` fallback to bind to. Do **not** delete the inline style — older user agents that don't support `@supports` need the inline form to render the live path.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:457:The `RenderEffect.createBlurEffect` API exists on `android.view.View` from API 31 (Android 12). Below that, no real blur is available. Phase 5 wires both paths via a Java helper invoked over JNI.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:461:New file: `samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:464:package com.assetpipeline.glass;
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:471:public final class AssetPipelineGlassHelper {
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:473:    private AssetPipelineGlassHelper() {}
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:476:     * Applies a frosted-glass effect to {@code view}.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:479:     *                    wrapping the glass content)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:509:  resolved = tokens.material.resolve(view.material)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:520:  LibAndroidBridge.android_call_static_glass_helper(
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:522:    "com/assetpipeline/glass/AssetPipelineGlassHelper",
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:532:  handle = JNI.wrap_global(global_fl, label: "FrameLayout[glass]")
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:545:`android_call_static_glass_helper` is a new entry point in the JNI bridge layer (`src/lib_android_bridge.cr`). It performs `GetStaticMethodID` + `CallStaticBooleanMethod` for the helper signature `(Landroid/view/View;FI)Z`. If the project already has a generic static-call entry, reuse it instead of adding a specialized wrapper.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:553:The current `appkit_renderer.cr` `visit(view : UI::GlassBackground)` (lines 2734–2774) hard-codes a switch on `view.material` to an integer `NSVisualEffectMaterial` constant. After Phase 5 it becomes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:557:  resolved = tokens.material.resolve(view.material)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:561:  # UIKit <-> AppKit material translation.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:562:  appkit_material = case resolved.apple_material_constant
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:571:  material_params = LibSwiftKitBridge.material_parameters_new(
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:576:    appkit_material,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:578:  overrides = LibSwiftKitBridge.glass_background_overrides_new(
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:581:  ptr = LibSwiftKitBridge.glass_background_facade_make_macos(material_params, overrides)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:600:The implementer should plan to produce roughly 8 commits on the phase branch `phase-05-glass-material-tokenization` (created by the Architect before dispatch; do not branch further).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:603:   - New file `src/ui/design_tokens/material.cr` with `Material`, `Step`, `ResolvedStep`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:605:   - Add `material : Material` accessor.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:606:   - Specs for resolution math (`spec/ui/design_tokens/material_spec.cr`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:608:2. **`[Phase 5] Generate material CSS custom properties + @supports fallback`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:609:   - Extend `DesignTokens::WebGenerator` to emit the `--ap-material-*` block and the `@supports not (backdrop-filter)` fallback rules.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:610:   - Stability spec: pin the generator output for the default brand (`spec/ui/design_tokens/web_generator_material_spec.cr`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:612:3. **`[Phase 5] Wire web renderer to material tokens`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:615:   - Inline style now uses `var(--ap-material-blur-*)` and `color-mix(... var(--ap-material-opacity-*) ...)`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:616:   - Spec asserting the emitted HTML for a `GlassBackground.new(material: :regular)` includes the expected `var()` references.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:625:   - Crystal-side spec asserting the resolved material params struct is populated from tokens, not from a hard-coded switch.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:628:   - Replace `appkit_renderer.cr` lines 2734–2774. Include the UIKit→AppKit material constant translation table inline.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:633:   - New JNI entry point in `src/lib_android_bridge.cr`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:637:8. **`[Phase 5] Extend material tokenization to TabView, Alert, Sidebar, Toolbar, Sheet, Popover visitors`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:639:   - Every visit method that today calls `setMaterial:` with a hard-coded integer now reads from `tokens.material.resolve(:semantic_name)`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:641:After commit 8, run the full spec suite and the four sample builds. If any glass-using widget regresses visually, the brand intensity cascade is the cause and the visit method needs review.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:647:New sample file: `samples/cross_platform/glass_intensity_demo.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:652:# Demonstrates that setting material.intensity on the brand declaration
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:653:# uniformly scales glass-surface blur on every renderer.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:656:#   crystal run samples/cross_platform/glass_intensity_demo.cr            # web (default 1.0)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:657:#   crystal run samples/cross_platform/glass_intensity_demo.cr -- 1.3     # web (boosted)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:658:#   crystal run samples/cross_platform/glass_intensity_demo.cr -Dmacos -- 1.3
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:659:#   crystal run samples/cross_platform/glass_intensity_demo.cr -Dios -- 1.3
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:660:#   crystal run samples/cross_platform/glass_intensity_demo.cr -Dandroid -- 1.3
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:665:  b.material.intensity = intensity
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:673:      material: :ultra_thin,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:677:      material: :thin,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:681:      material: :regular,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:685:      material: :thick,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:689:      material: :chrome,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:706:- `spec/ui/design_tokens/material_spec.cr` — resolution math at boundary values (intensity 0.0, 0.5, 1.0, 1.5, 3.0, 5.0 — last two confirm clamping). Round-trip a brand override of one step's `blur_radius` and verify the resolved value is multiplied by intensity, not the override's value before multiplication.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:707:- `spec/ui/design_tokens/web_generator_material_spec.cr` — generator output stability: snapshot the `:root` block and the `@supports` block, compare to a fixture. If the implementer changes the published default values, the fixture updates with that commit.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:708:- `spec/ui/renderers/web_glass_spec.cr` — render a `GlassBackground.new(material: :thick)` and assert the inline style contains `var(--ap-material-blur-thick)` and `color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thick) * 100%), transparent)`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:709:- `spec/ui/renderers/uikit_glass_spec.cr` and `spec/ui/renderers/appkit_glass_spec.cr` — assert the `MaterialParameters` struct passed to the bridge contains the resolved (not raw) values. Drive a brand with `intensity = 1.5` and confirm `material_params.blur_radius == 45.0` for `:regular`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:710:- `spec/ui/renderers/android_glass_spec.cr` — confirm the helper is invoked with the resolved blur radius and the computed ARGB.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:714:Existing visual regression harness covers `samples/cross_platform/showcase.html`. Add a new harness entry for `glass_intensity_demo.cr` rendered at intensity 0.5, 1.0, 1.5. Three PNGs per browser; commit baselines after manual review.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:719:- macOS: extend `samples/cross_platform/macos_host/` visual regression harness to include the glass intensity demo.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:733:2. Every renderer's `visit(view : UI::GlassBackground)` reads from `tokens.material.resolve(view.material)` — no hard-coded numbers in any of the four files.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:734:3. The deviation prompt's question is resolved: either every other glass-using visit method is also tokenized, or the team lead has been notified and chosen the narrower scope.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:736:5. The web stylesheet emits the `--ap-material-*` custom properties and the `@supports not (backdrop-filter)` fallback block. Verified by reading the generated CSS.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:737:6. The Android Java helper exists and is invoked over JNI with the resolved blur radius. Verified by reading the call sites.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:738:7. `samples/cross_platform/glass_intensity_demo.cr` exists, takes intensity from `ARGV`, and renders on all four platforms.

exec
/bin/zsh -lc 'rg -n "AssetPipelineGlassHelper|class GlassHelper|applyGlass|RenderEffect|createBlurEffect|setRenderEffect|Build.VERSION|TileMode" -S .' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
./src/ui/native/android_bridge.c:1475:// Phase 5 — Glass material RenderEffect bridge.
./src/ui/native/android_bridge.c:1477:// Calls the host's AssetPipelineGlassHelper.applyGlass(view, blurRadius,
./src/ui/native/android_bridge.c:1480:// real RenderEffect blur was applied, 0 if the fallback alpha was used or
./src/ui/native/android_bridge.c:1485:    jclass helper_cls = (*env)->FindClass(env, "com/assetpipeline/glass/AssetPipelineGlassHelper");
./src/ui/native/android_bridge.c:1492:    jmethodID apply = ap_get_static_method(env, helper_cls, "applyGlass", "(Landroid/view/View;FI)Z");
./src/ui/design_tokens/material.cr:8:    # API 31+ (via the `RenderEffect.createBlurEffect` radius argument). On
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:7:// On API 31+ (Android 12 / S), the helper applies a real RenderEffect
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:19:import android.graphics.RenderEffect;
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:24:public final class AssetPipelineGlassHelper {
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:26:    private AssetPipelineGlassHelper() {}
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:35:     *                     API 30 and below, or if RenderEffect creation
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:37:     * @return true if a real RenderEffect blur was applied; false if the
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:40:    public static boolean applyGlass(View view, float blurRadius, int fallbackArgb) {
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:41:        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:43:                RenderEffect effect = RenderEffect.createBlurEffect(
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:44:                        blurRadius, blurRadius, Shader.TileMode.CLAMP);
./samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:45:                view.setRenderEffect(effect);
./src/ui/renderers/android_renderer.cr:203:    # Applies AssetPipelineGlassHelper.applyGlass(view, blurRadius,
./src/ui/renderers/android_renderer.cr:204:    # fallbackArgb). Helper internally chooses RenderEffect.createBlurEffect
./src/ui/renderers/android_renderer.cr:272:    # `visit(UI::GlassBackground)` to drive both the API 31+ RenderEffect
./src/ui/renderers/android_renderer.cr:2170:    # Visit: GlassBackground -> android.widget.FrameLayout + RenderEffect
./src/ui/renderers/android_renderer.cr:2173:    # On API 31+, the host's `AssetPipelineGlassHelper.applyGlass` static
./src/ui/renderers/android_renderer.cr:2174:    # helper applies `RenderEffect.createBlurEffect(radius, radius,
./src/ui/renderers/android_renderer.cr:2175:    # TileMode.CLAMP)` where `radius = step.blur_radius * intensity`. On
./src/ui/renderers/android_renderer.cr:2181:    # Empirical verification (real RenderEffect render on a real device)
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:21:# 3. Android renderer code lands in Phase 5 (the Crystal-side RenderEffect
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:39:    rationale: "Phase introduces tokenized blur/opacity/saturation/luminance values per material step + an intensity scalar that quantizes through to the SwiftUI Material enum on Apple, scales backdrop-filter blur radius on web, and scales RenderEffect blur radius on Android API 31+. Visible glass surface changes when material.intensity shifts at brand-declaration time. Phase 5 implementer authors the per-step visual baseline probes."
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:52:        reason: "Phase 5 ships Android-side RenderEffect emission code; Android empirical verification is Phase 6.5's audit harness deliverable per Phase 1 #17 precedent"
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:222:    claim: "Android renderer's existing GlassBackground visit method uses semi-transparent FrameLayout placeholder (no real blur) — Phase 5 will replace with RenderEffect on API 31+ + alpha-fallback below"
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:303:    adapter: "Android RenderEffect.createBlurEffect (API 31+) or alpha FrameLayout fallback (< API 31)"
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:307:    documented_degradation: "Android API < 31 degrades to FrameLayout with alpha-only background at per-step opacity (matching web fallback's opacity values). No blur. WCAG-AA contrast verified for text-on-alpha-fallback. This is the existing Phase 4-era behavior; Phase 5 keeps it for < API 31 and adds RenderEffect on API 31+."
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:17:- **Android:** Placeholder — semi-transparent white `FrameLayout`. No actual blur even though API 31+ supports `RenderEffect.createBlurEffect`.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:34:  - `android_renderer.cr`: on API 31+, use `RenderEffect.createBlurEffect(radius, radius, TileMode.CLAMP)` with radius from the token. Below API 31, semi-transparent fill with the token's opacity value.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:64:- **Android `RenderEffect`:** must be applied to the View at the JNI bridge level. The Crystal-side abstraction calls into a Java helper.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:69:- **Phase Brief (YAML, validator-enforced):** `brief.yml` — passes `crystal run scripts/validate_phase_brief.cr -- phases/phase-05-glass-material-tokenization/brief.yml` (exit 0 mandatory before dispatch). Declares all 11 invariant cells, lower-layer assumptions about SwiftUI Material API + backdrop-filter support + Android RenderEffect, repo-derived facts (37 GlassBackground references, 2 backdrop-filter sites in web_renderer.cr, 35311-byte design_tokens.cr), and 3 adapter cardinality MISMATCH rows for SwiftUI's discrete material enum, web `@supports` fallback, and Android < API 31 fallback. Architect-authored 2026-05-22 per `handoff/planning-retrospective-2026-05-22.md` Phase Brief Template.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:76:**What:** On Android API 31+, `GlassBackground` produces a real `RenderEffect.createBlurEffect`-backed view. On API ≤30, it produces the documented semi-transparent fallback fill. Both paths invoke the `AssetPipelineGlassHelper.applyGlass` static method.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:78:1. Build the Android sample. Confirm `AssetPipelineGlassHelper.java` exists at the expected path.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:11:Promote glass material strength from hard-coded per-renderer constants to a first-class branch of the `UI::DesignTokens` system. Wire every renderer — web, AppKit, UIKit, and Android — to read material parameters from the resolved token tree. Add a brand-overridable `intensity` scalar so a single line in a brand declaration uniformly scales how frosted glass surfaces appear on all four platforms. Add a `@supports` fallback for web browsers without `backdrop-filter`. Add a real `RenderEffect.createBlurEffect` path on Android API 31+ with a graceful pre-API-31 fallback.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:69:| Android API gate | 31+ for `RenderEffect.createBlurEffect`, ≤ 30 fallback | Both paths invoke `AssetPipelineGlassHelper.applyGlass`. |
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:79:| `AssetPipelineGlassHelper.java` (Android API 31+ blur helper) | `src/ui/native/lib_swiftkit_bridge.cr` (from Phase 3, extended for material params) |
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:117:        # Android applies the same value as the RenderEffect radius argument.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:128:        # (RenderEffect saturation is a separate effect — out of scope for Phase 5).
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:457:The `RenderEffect.createBlurEffect` API exists on `android.view.View` from API 31 (Android 12). Below that, no real blur is available. Phase 5 wires both paths via a Java helper invoked over JNI.
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:461:New file: `samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java`
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:466:import android.graphics.RenderEffect;
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:471:public final class AssetPipelineGlassHelper {
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:473:    private AssetPipelineGlassHelper() {}
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:482:     *                    and below (or if RenderEffect creation fails)
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:483:     * @return true if a real RenderEffect blur was applied; false if the
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:486:    public static boolean applyGlass(View view, float blurRadius, int fallbackArgb) {
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:487:        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:489:                RenderEffect effect = RenderEffect.createBlurEffect(
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:490:                        blurRadius, blurRadius, Shader.TileMode.CLAMP);
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:491:                view.setRenderEffect(effect);
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:522:    "com/assetpipeline/glass/AssetPipelineGlassHelper",
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:523:    "applyGlass",
./docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:631:7. **`[Phase 5] Add Android RenderEffect helper + wire renderer`**
./docs/initiative-cross-platform-ui/MASTER_PLAN.md:104:| 5 | **Glass Material Tokenization** | Promote glass material strength to design tokens. Wire all renderers (incl. RenderEffect on Android API 31+). Brand override of glass intensity. | `phases/phase-05-glass-material-tokenization/` |
./docs/initiative-cross-platform-ui/handoff/planning-retrospective-2026-05-22.md:383:- Section 2 assumptions: SwiftUI Material API on iOS 26.5 + macOS 26.5; web `backdrop-filter` browser matrix; Android `RenderEffect` min SDK.
./docs/initiative-cross-platform-ui/handoff/stock-taking-2026-05-22.md:54:- Risks: cross-renderer scope (touches all 4 renderers). Android is new functionality (`RenderEffect.createBlurEffect` on API 31+). Web `backdrop-filter` performance + `@supports` fallback.
./docs/initiative-cross-platform-ui/handoff/stock-taking-2026-05-22.md:83:Same as Phase 4 worked. Codex-reviewed wrapper over canonical `implementation.md`. Specific to Phase 5: the brief should call out the cross-renderer scope explicitly (4 renderers, 4 different idioms — UIKit material, AppKit material, web `backdrop-filter`, Android `RenderEffect`) and require diagnostic-first verification on EACH platform, not just one.
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:18:--- D3: Android renderer RenderEffect emission code ---
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:19:src/ui/renderers/android_renderer.cr:204:    # fallbackArgb). Helper internally chooses RenderEffect.createBlurEffect
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:21:src/ui/renderers/android_renderer.cr:272:    # `visit(UI::GlassBackground)` to drive both the API 31+ RenderEffect
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:22:src/ui/renderers/android_renderer.cr:2170:    # Visit: GlassBackground -> android.widget.FrameLayout + RenderEffect
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:23:src/ui/renderers/android_renderer.cr:2174:    # helper applies `RenderEffect.createBlurEffect(radius, radius,
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:24:src/ui/renderers/android_renderer.cr:2181:    # Empirical verification (real RenderEffect render on a real device)
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:26:src/ui/native/android_bridge.c:1475:// Phase 5 — Glass material RenderEffect bridge.
./docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/inspections/contract_decisions.log:27:src/ui/native/android_bridge.c:1480:// real RenderEffect blur was applied, 0 if the fallback alpha was used or

exec
/bin/zsh -lc "nl -ba samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java | sed -n '1,120p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	// Phase 5 — Glass material helper for the Android renderer.
     2	//
     3	// The Crystal-side android_renderer.cr#visit(UI::GlassBackground) resolves
     4	// the material step from tokens and calls into the JNI bridge function
     5	// android_view_apply_glass which dispatches into this static helper.
     6	//
     7	// On API 31+ (Android 12 / S), the helper applies a real RenderEffect
     8	// gaussian blur to the supplied View. On older devices it falls back to
     9	// setBackgroundColor at the supplied fallback ARGB. The Crystal-side code
    10	// observes the return value and, if 0 (no real blur), falls back to a
    11	// setBackgroundColor of its own as a defense in depth.
    12	//
    13	// Empirical verification of the API 31+ blur path is Phase 6.5's audit
    14	// harness deliverable; this file is the production code that harness
    15	// validates.
    16	
    17	package com.assetpipeline.glass;
    18	
    19	import android.graphics.RenderEffect;
    20	import android.graphics.Shader;
    21	import android.os.Build;
    22	import android.view.View;
    23	
    24	public final class AssetPipelineGlassHelper {
    25	
    26	    private AssetPipelineGlassHelper() {}
    27	
    28	    /**
    29	     * Apply a frosted-glass effect to {@code view}.
    30	     *
    31	     * @param view         the View receiving the effect (typically a
    32	     *                     FrameLayout wrapping the glass content)
    33	     * @param blurRadius   blur kernel radius in device-independent pixels
    34	     * @param fallbackArgb 32-bit ARGB color used as background fill on
    35	     *                     API 30 and below, or if RenderEffect creation
    36	     *                     fails
    37	     * @return true if a real RenderEffect blur was applied; false if the
    38	     *         fallback solid fill was used
    39	     */
    40	    public static boolean applyGlass(View view, float blurRadius, int fallbackArgb) {
    41	        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    42	            try {
    43	                RenderEffect effect = RenderEffect.createBlurEffect(
    44	                        blurRadius, blurRadius, Shader.TileMode.CLAMP);
    45	                view.setRenderEffect(effect);
    46	                return true;
    47	            } catch (Throwable t) {
    48	                // Fall through to fallback fill.
    49	            }
    50	        }
    51	        view.setBackgroundColor(fallbackArgb);
    52	        return false;
    53	    }
    54	}

exec
/bin/zsh -lc 'git ls-files samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java samples/cross_platform/web/brand_glass_intensity_demo.cr samples/cross_platform/glass_intensity_demo.cr spec/ui/design_tokens/material_spec.cr spec/ui/design_tokens/web_generator_material_spec.cr spec/ui/renderers/web_glass_spec.cr spec/ui/renderers/uikit_glass_spec.cr spec/ui/renderers/appkit_glass_spec.cr spec/ui/renderers/android_glass_spec.cr' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java
samples/cross_platform/web/brand_glass_intensity_demo.cr
spec/ui/design_tokens/material_spec.cr
spec/ui/renderers/web_glass_spec.cr

exec
/bin/zsh -lc "nl -ba samples/cross_platform/web/brand_glass_intensity_demo.cr | sed -n '1,100p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	require "../../../src/ui"
     2	require "../../../src/ui/renderers/web_renderer"
     3	
     4	# Phase 5 — brand glass intensity demo.
     5	#
     6	# Demonstrates that a single brand declaration of `material.intensity = 1.3`
     7	# cascades to every renderer via the `UI::DesignTokens::Tokens` token tree,
     8	# without touching any individual renderer or component. The intensity scalar
     9	# is brand-declaration-time (NOT runtime-mutable) per the Phase 5 brief I-2
    10	# `preserves` contract — consumers re-render the view tree to observe
    11	# changes.
    12	#
    13	# Run with:
    14	#   crystal run samples/cross_platform/web/brand_glass_intensity_demo.cr
    15	#
    16	# The script prints:
    17	#   1. The five-step glass ladder as HTML (web renderer output).
    18	#   2. The generated `--ap-material-*` CSS so the cascade is visually
    19	#      inspectable (`--ap-material-intensity: 1.3` and the `calc()`
    20	#      expressions on the per-step blur properties).
    21	#   3. The Apple-quantized step each Crystal step resolves to at the
    22	#      brand intensity — useful for understanding the SwiftUI Material
    23	#      enum quantization documented in brief.yml adapter_cardinality
    24	#      row 1 ("intensity 1.3 quantizes to .regularMaterial").
    25	
    26	class BoostedGlassBrand < UI::DesignTokens::Brand
    27	  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
    28	    material.copy_with(intensity: 1.3)
    29	  end
    30	end
    31	
    32	# Original Tokens.default has intensity=1.0; the with_brand cascade
    33	# returns a NEW Tokens instance — the original is unchanged (I-2 / I-9
    34	# preserves).
    35	tokens = UI::DesignTokens::Tokens.default.with_brand(BoostedGlassBrand.new)
    36	
    37	ladder = UI::VStack.new(spacing: 12.0)
    38	[:ultra_thin, :thin, :regular, :thick, :chrome].each do |step|
    39	  ladder << UI::GlassBackground.new(material: step)
    40	end
    41	
    42	renderer = UI::Web::Renderer.new
    43	renderer.design_tokens = tokens
    44	
    45	puts "================================================================"
    46	puts "Phase 5 brand glass intensity demo (intensity=1.3 cascade proof)"
    47	puts "================================================================"
    48	puts
    49	puts "--- Rendered HTML (web) ---"
    50	puts renderer.render(ladder)
    51	puts
    52	puts "--- Generated material CSS custom properties ---"
    53	css = renderer.inject_theme_css
    54	css.each_line do |line|
    55	  puts line if line.includes?("--ap-material-") || line.includes?("ap-glass--")
    56	end
    57	puts
    58	puts "--- Apple-quantized step per declared step at intensity=1.3 ---"
    59	[:ultra_thin, :thin, :regular, :thick, :chrome].each do |step|
    60	  apple = tokens.material.apple_step(step)
    61	  resolved = tokens.material.resolve(step)
    62	  printf("  %-11s -> apple=%s  blur=%.2fpx  opacity=%.2f\n",
    63	    step.to_s, apple.to_s, resolved.blur_radius, resolved.opacity)
    64	end

exec
/bin/zsh -lc "ls -1 spec/ui/design_tokens spec/ui/renderers | sed -n '1,200p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
spec/ui/design_tokens:
generators
material_spec.cr

spec/ui/renderers:
container_query_spec.cr
document_mode_spec.cr
fluid_emission_spec.cr
swiftkit
touch_target_spec.cr
web_glass_spec.cr
web_renderer_spec.cr

codex
One important mismatch is already visible: the validator draft says the full Phase 5 focused spec set exists, but at `HEAD` only `spec/ui/design_tokens/material_spec.cr`, `spec/ui/renderers/web_glass_spec.cr`, and the six pending probe specs are present. There are no tracked `uikit_glass_spec.cr`, `appkit_glass_spec.cr`, `android_glass_spec.cr`, or `web_generator_material_spec.cr` files.
exec
/bin/zsh -lc "nl -ba spec/ui/design_tokens/material_spec.cr | sed -n '1,260p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	require "../../spec_helper"
     2	require "../../../src/ui/design_tokens"
     3	
     4	describe UI::DesignTokens::Material do
     5	  describe "#step" do
     6	    it "returns the matching MaterialStep for each declared symbol" do
     7	      m = UI::DesignTokens::Defaults.material
     8	      m.step(:ultra_thin).blur_radius.should eq(10.0)
     9	      m.step(:thin).blur_radius.should eq(20.0)
    10	      m.step(:regular).blur_radius.should eq(30.0)
    11	      m.step(:thick).blur_radius.should eq(40.0)
    12	      m.step(:chrome).blur_radius.should eq(50.0)
    13	    end
    14	
    15	    it "falls back to :regular for unknown symbols" do
    16	      m = UI::DesignTokens::Defaults.material
    17	      m.step(:nonexistent_step).should eq(m.step(:regular))
    18	    end
    19	  end
    20	
    21	  describe "#resolve" do
    22	    it "scales blur_radius by intensity at the default 1.0" do
    23	      m = UI::DesignTokens::Defaults.material
    24	      resolved = m.resolve(:regular)
    25	      resolved.blur_radius.should eq(30.0)
    26	      resolved.opacity.should eq(0.60)
    27	      resolved.saturation.should eq(1.15)
    28	      resolved.name.should eq(:regular)
    29	    end
    30	
    31	    it "scales blur_radius by intensity at 1.3" do
    32	      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.3)
    33	      m.resolve(:regular).blur_radius.should be_close(39.0, 1e-9)
    34	      m.resolve(:thick).blur_radius.should be_close(52.0, 1e-9)
    35	    end
    36	
    37	    it "scales blur_radius by intensity at 0.5" do
    38	      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 0.5)
    39	      m.resolve(:regular).blur_radius.should eq(15.0)
    40	    end
    41	
    42	    it "clamps intensity to the brief.yml [0.0, 2.0] range" do
    43	      # Lower bound preserves 0.0 -> 0 blur (panel fully transparent).
    44	      m_low = UI::DesignTokens::Defaults.material.copy_with(intensity: 0.0)
    45	      m_low.resolve(:regular).blur_radius.should eq(0.0)
    46	      # Negative values clamp to 0.
    47	      m_neg = UI::DesignTokens::Defaults.material.copy_with(intensity: -1.0)
    48	      m_neg.resolve(:regular).blur_radius.should eq(0.0)
    49	      # Above 2.0 clamps to 2.0 -> 60.0 blur for regular default.
    50	      m_high = UI::DesignTokens::Defaults.material.copy_with(intensity: 10.0)
    51	      m_high.resolve(:regular).blur_radius.should eq(60.0)
    52	    end
    53	
    54	    it "does NOT scale opacity, saturation, or luminance" do
    55	      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 2.0)
    56	      m.resolve(:regular).opacity.should eq(0.60)
    57	      m.resolve(:regular).saturation.should eq(1.15)
    58	      m.resolve(:regular).luminance.should eq(0.0)
    59	    end
    60	  end
    61	
    62	  describe "#apple_step (Apple quantization contract)" do
    63	    it "honors the declared step at default intensity 1.0" do
    64	      m = UI::DesignTokens::Defaults.material
    65	      m.apple_step(:ultra_thin).should eq(:ultra_thin)
    66	      m.apple_step(:thin).should eq(:thin)
    67	      m.apple_step(:regular).should eq(:regular)
    68	      m.apple_step(:thick).should eq(:thick)
    69	      m.apple_step(:chrome).should eq(:chrome)
    70	    end
    71	
    72	    it "honors a non-:regular declared step regardless of intensity" do
    73	      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.5)
    74	      m.apple_step(:thick).should eq(:thick)
    75	      m.apple_step(:ultra_thin).should eq(:ultra_thin)
    76	    end
    77	
    78	    it "quantizes :regular declared step through the documented table" do
    79	      # Per Phase 5 brief.yml adapter_cardinality row 1 worked examples.
    80	      base = UI::DesignTokens::Defaults.material
    81	      base.copy_with(intensity: 0.2).apple_step(:regular).should eq(:ultra_thin)
    82	      base.copy_with(intensity: 0.5).apple_step(:regular).should eq(:thin)
    83	      base.copy_with(intensity: 1.0).apple_step(:regular).should eq(:regular)
    84	      base.copy_with(intensity: 1.3).apple_step(:regular).should eq(:regular)  # brief worked example
    85	      base.copy_with(intensity: 1.5).apple_step(:regular).should eq(:thick)
    86	      base.copy_with(intensity: 1.8).apple_step(:regular).should eq(:chrome)   # brief "1.8+"
    87	      base.copy_with(intensity: 2.0).apple_step(:regular).should eq(:chrome)
    88	    end
    89	
    90	    it "pins boundary semantics matching brief.yml worked-example + 1.8+ notation" do
    91	      # Brief.yml row 1: "intensity 1.3 quantizes to .regularMaterial" AND
    92	      # "1.8+ -> .chromeMaterial". The implementation honors the worked
    93	      # example (1.3 -> :regular) by using inclusive upper bounds on the
    94	      # first three buckets, and the inclusive lower bound `>= 1.8` for
    95	      # the chrome bucket per the brief's `1.8+` notation.
    96	      base = UI::DesignTokens::Defaults.material
    97	      # 1.3 worked example
    98	      base.copy_with(intensity: 1.3).apple_step(:regular).should eq(:regular)
    99	      # 1.8+ chrome boundary
   100	      base.copy_with(intensity: 1.8).apple_step(:regular).should eq(:chrome)
   101	      base.copy_with(intensity: 1.79).apple_step(:regular).should eq(:thick)
   102	      # Other shared endpoints: inclusive on the lower bucket per
   103	      # the worked-example pattern (0.3 -> :ultra_thin since 0.3 is the
   104	      # documented upper edge of that bucket).
   105	      base.copy_with(intensity: 0.3).apple_step(:regular).should eq(:ultra_thin)
   106	      base.copy_with(intensity: 0.7).apple_step(:regular).should eq(:thin)
   107	      base.copy_with(intensity: 1.301).apple_step(:regular).should eq(:thick)
   108	    end
   109	  end
   110	
   111	  describe "brand override cascade" do
   112	    it "exposes intensity via Tokens.with_brand without runtime mutation" do
   113	      brand = TestGlassBrand.new
   114	      tokens = UI::DesignTokens::Tokens.default.with_brand(brand)
   115	      tokens.material.intensity.should eq(1.3)
   116	      # Original Tokens.default is unchanged — copy_with returns a new instance.
   117	      UI::DesignTokens::Tokens.default.material.intensity.should eq(1.0)
   118	    end
   119	  end
   120	end
   121	
   122	private class TestGlassBrand < UI::DesignTokens::Brand
   123	  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
   124	    material.copy_with(intensity: 1.3)
   125	  end
   126	end

exec
/bin/zsh -lc "for f in spec/ui/glass_material/*.cr; do printf '\\n### %s\\n' \""'$f"; nl -ba "$f" | sed -n '"'1,220p'; done" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:

### spec/ui/glass_material/ios_glass_contrast_spec.cr
     1	require "../../spec_helper"
     2	require "../../../src/ui/design_tokens"
     3	
     4	# Phase 5 probe placeholder — slug `ios.glass.material.contrast.wcag_aa`.
     5	#
     6	# Verifies text-on-glass WCAG 2.2 AA contrast (4.5:1 for normal text;
     7	# 3:1 for large text per WCAG 1.4.3) on each material step at each
     8	# declared intensity in the matrix:
     9	#
    10	#   intensities x steps = {0.5, 1.0, 1.3, 1.5} x {ultra_thin..chrome}
    11	#
    12	# Phase 6.5 harness will:
    13	#   1. Render the glass surface with text_primary as foreground.
    14	#   2. Capture the rasterized region (XCUITest screenshot of the AXElement).
    15	#   3. Sample foreground color, sample average background luminance under
    16	#      the foreground (since real Material backdrops vary), compute the
    17	#      effective contrast ratio.
    18	#   4. Assert >= 4.5 for normal text, >= 3.0 for large text.
    19	#
    20	# AX identifier convention: `ap.glass.contrast.<step>.intensity_<intensity_x100>`.
    21	describe "Phase 5 probe: ios.glass.material.contrast.wcag_aa" do
    22	  intensities = [0.5, 1.0, 1.3, 1.5]
    23	  steps = [:ultra_thin, :thin, :regular, :thick, :chrome]
    24	
    25	  intensities.each do |intensity|
    26	    steps.each do |step|
    27	      pending "text_primary on `#{step}` at intensity=#{intensity} meets WCAG-AA 4.5:1 contrast" do
    28	        # Expected shape (Phase 6.5 will implement):
    29	        #   intensity_x100 = (intensity * 100).round.to_i
    30	        #   tokens = UI::DesignTokens::Tokens.default.copy_with(
    31	        #     material: UI::DesignTokens::Tokens.default.material.copy_with(intensity: intensity)
    32	        #   )
    33	        #   identifier = "ap.glass.contrast.#{step}.intensity_#{intensity_x100}"
    34	        #   contrast = capture_text_glass_contrast(tokens, step, identifier)
    35	        #   contrast.should be >= 4.5
    36	      end
    37	    end
    38	  end
    39	end

### spec/ui/glass_material/ios_glass_default_spec.cr
     1	require "../../spec_helper"
     2	require "../../../src/ui/design_tokens"
     3	
     4	# Phase 5 probe placeholder — slug `ios.glass.material.default`.
     5	#
     6	# Verifies per-material-step visual baseline on iOS. The body is `pending`
     7	# until Phase 6.5 ships the audit harness (visual diff + screenshot capture)
     8	# referenced from this slug. The AX identifier convention captured here is
     9	# the contract Phase 6.5 will hook into:
    10	#
    11	#   ap.glass.<step>.intensity_<intensity_x100>
    12	#
    13	# At default intensity 1.0 each step's identifier therefore reads
    14	# `ap.glass.ultra_thin.intensity_100`, `ap.glass.thin.intensity_100`, etc.
    15	#
    16	# The pending assertion shape below documents what the Phase 6.5 harness
    17	# will verify once it runs.
    18	describe "Phase 5 probe: ios.glass.material.default" do
    19	  [:ultra_thin, :thin, :regular, :thick, :chrome].each do |step|
    20	    pending "renders SwiftUI Material `#{step}` at the per-step default blur" do
    21	      # Expected shape (Phase 6.5 will implement):
    22	      #   tokens = UI::DesignTokens::Tokens.default
    23	      #   app = UI::AXTest::App.launch(IOS_GLASS_FIXTURE_APP)
    24	      #   screen = app.window("Glass Material Default — #{step}")
    25	      #   elem = screen.find(identifier: "ap.glass.#{step}.intensity_100")
    26	      #   elem.should_not be_nil
    27	      #   captured = capture_render(elem)
    28	      #   captured.blur_radius.should be_close(
    29	      #     tokens.material.resolve(:#{step}).blur_radius, 0.5)
    30	      #   captured.material_enum.should eq("#{step}".to_apple_material_case)
    31	      #   app.screenshot("/tmp/p5-#{step}.png")
    32	      #   visual_diff("/tmp/p5-#{step}.png", "fixtures/p5-#{step}-baseline.png").should be_within_tolerance
    33	    end
    34	  end
    35	end

### spec/ui/glass_material/ios_glass_env_response_spec.cr
     1	require "../../spec_helper"
     2	require "../../../src/ui/design_tokens"
     3	
     4	# Phase 5 probe placeholder — slug `ios.glass.material.env_response`.
     5	#
     6	# Verifies glass material responds correctly to the three environment
     7	# response axes Phase 5 inherits from the I-8 invariant:
     8	#
     9	#   - reduced_motion: blur intensity transitions are NOT animated (system-
    10	#     level on Apple — SwiftUI Material respects UIAccessibility.isReduceMotionEnabled
    11	#     automatically; the probe verifies the renderer does not layer its
    12	#     own animation on top).
    13	#   - high_contrast: when UIAccessibility.isDarkerSystemColorsEnabled (or
    14	#     equivalent), the glass surface either suppresses translucency or
    15	#     strengthens the contrast token. Phase 5 delegates to SwiftUI Material's
    16	#     own response; the probe verifies the contract is documented + the
    17	#     renderer does not override.
    18	#   - dark_mode: each step's appearance must track .light/.dark color
    19	#     scheme. Probe captures both appearances and asserts the resolved
    20	#     palette differs.
    21	#
    22	# AX identifier convention: `ap.glass.env.<axis>.<step>`.
    23	describe "Phase 5 probe: ios.glass.material.env_response" do
    24	  steps = [:ultra_thin, :thin, :regular, :thick, :chrome]
    25	
    26	  describe "reduced_motion cell" do
    27	    steps.each do |step|
    28	      pending "renders `#{step}` without renderer-side animation under reduced_motion" do
    29	        # Expected shape (Phase 6.5 will implement):
    30	        #   identifier = "ap.glass.env.reduced_motion.#{step}"
    31	        #   recording = capture_intensity_transition(tokens, step, identifier,
    32	        #     from_intensity: 1.0, to_intensity: 1.3, reduced_motion: true)
    33	        #   recording.frame_deltas.should be_under_threshold
    34	      end
    35	    end
    36	  end
    37	
    38	  describe "high_contrast cell" do
    39	    steps.each do |step|
    40	      pending "renders `#{step}` with documented high_contrast response" do
    41	        # Expected shape: identifier `ap.glass.env.high_contrast.#{step}`.
    42	      end
    43	    end
    44	  end
    45	
    46	  describe "dark_mode cell" do
    47	    steps.each do |step|
    48	      pending "renders `#{step}` differently in dark vs light appearance" do
    49	        # Expected shape: identifier `ap.glass.env.dark_mode.#{step}`.
    50	      end
    51	    end
    52	  end
    53	end

### spec/ui/glass_material/macos_glass_contrast_spec.cr
     1	require "../../spec_helper"
     2	require "../../../src/ui/design_tokens"
     3	
     4	# Phase 5 probe placeholder — slug `macos.glass.material.contrast.wcag_aa`.
     5	#
     6	# Mirror of `ios_glass_contrast_spec.cr` for the AppKit renderer.
     7	# AX identifier convention: `ap.glass.contrast.<step>.intensity_<intensity_x100>`.
     8	describe "Phase 5 probe: macos.glass.material.contrast.wcag_aa" do
     9	  intensities = [0.5, 1.0, 1.3, 1.5]
    10	  steps = [:ultra_thin, :thin, :regular, :thick, :chrome]
    11	
    12	  intensities.each do |intensity|
    13	    steps.each do |step|
    14	      pending "text_primary on `#{step}` at intensity=#{intensity} meets WCAG-AA 4.5:1 contrast on macOS" do
    15	        # Expected shape (Phase 6.5 will implement) — see iOS counterpart.
    16	      end
    17	    end
    18	  end
    19	end

### spec/ui/glass_material/macos_glass_default_spec.cr
     1	require "../../spec_helper"
     2	require "../../../src/ui/design_tokens"
     3	
     4	# Phase 5 probe placeholder — slug `macos.glass.material.default`.
     5	#
     6	# Mirror of `ios_glass_default_spec.cr` for macOS via the AppKit renderer +
     7	# AXTest harness. Same `pending` semantics; Phase 6.5 harness work runs the
     8	# bodies.
     9	#
    10	# AX identifier convention: `ap.glass.<step>.intensity_<intensity_x100>`.
    11	describe "Phase 5 probe: macos.glass.material.default" do
    12	  [:ultra_thin, :thin, :regular, :thick, :chrome].each do |step|
    13	    pending "renders SwiftUI Material `#{step}` at the per-step default blur on macOS" do
    14	      # Expected shape (Phase 6.5 will implement):
    15	      #   tokens = UI::DesignTokens::Tokens.default
    16	      #   app = UI::AXTest::App.launch(MACOS_GLASS_FIXTURE_APP)
    17	      #   screen = app.window("Glass Material Default — #{step}")
    18	      #   elem = screen.find(identifier: "ap.glass.#{step}.intensity_100")
    19	      #   elem.should_not be_nil
    20	      #   visual = app.capture_glass_material(elem)
    21	      #   visual.material_enum.should eq(tokens.material.apple_step(:#{step}))
    22	      #   app.screenshot("/tmp/p5-macos-#{step}.png")
    23	      #   visual_diff("/tmp/p5-macos-#{step}.png", "fixtures/p5-macos-#{step}-baseline.png").should be_within_tolerance
    24	    end
    25	  end
    26	end

### spec/ui/glass_material/macos_glass_env_response_spec.cr
     1	require "../../spec_helper"
     2	require "../../../src/ui/design_tokens"
     3	
     4	# Phase 5 probe placeholder — slug `macos.glass.material.env_response`.
     5	#
     6	# Mirror of `ios_glass_env_response_spec.cr` for the AppKit renderer.
     7	# AX identifier convention: `ap.glass.env.<axis>.<step>`.
     8	describe "Phase 5 probe: macos.glass.material.env_response" do
     9	  steps = [:ultra_thin, :thin, :regular, :thick, :chrome]
    10	
    11	  describe "reduced_motion cell" do
    12	    steps.each do |step|
    13	      pending "renders `#{step}` without renderer-side animation under reduced_motion on macOS" do
    14	      end
    15	    end
    16	  end
    17	
    18	  describe "high_contrast cell" do
    19	    steps.each do |step|
    20	      pending "renders `#{step}` with documented high_contrast response on macOS" do
    21	      end
    22	    end
    23	  end
    24	
    25	  describe "dark_mode cell" do
    26	    steps.each do |step|
    27	      pending "renders `#{step}` differently in dark vs light appearance on macOS" do
    28	      end
    29	    end
    30	  end
    31	end

exec
/bin/zsh -lc "nl -ba spec/ui/renderers/web_glass_spec.cr | sed -n '1,260p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	require "spec"
     2	require "../../../src/ui"
     3	require "../../../src/ui/renderers/web_renderer"
     4	
     5	private def render(view : UI::View) : String
     6	  renderer = UI::Web::Renderer.new
     7	  view.accept(renderer)
     8	  renderer.output
     9	end
    10	
    11	describe "UI::Web::Renderer GlassBackground (Phase 5 tokenization)" do
    12	  it "emits per-step material custom property references for :regular" do
    13	    html = render(UI::GlassBackground.new(material: :regular))
    14	    html.should contain("class=\"ap-glass ap-glass--regular\"")
    15	    html.should contain("var(--ap-material-blur-regular)")
    16	    html.should contain("var(--ap-material-opacity-regular)")
    17	    html.should contain("var(--ap-material-saturation-regular)")
    18	    html.should_not contain("blur(30px)") # no longer hard-coded
    19	  end
    20	
    21	  it "emits per-step material references for each declared step" do
    22	    {:ultra_thin => "ultra-thin", :thin => "thin", :regular => "regular",
    23	     :thick => "thick", :chrome => "chrome"}.each do |sym, key|
    24	      html = render(UI::GlassBackground.new(material: sym))
    25	      html.should contain("ap-glass--#{key}")
    26	      html.should contain("var(--ap-material-blur-#{key})")
    27	    end
    28	  end
    29	
    30	  it "emits the @supports fallback block via theme CSS" do
    31	    renderer = UI::Web::Renderer.new
    32	    css = renderer.inject_theme_css
    33	    css.should contain("@supports not ((backdrop-filter: blur(1px))")
    34	    css.should contain(".ap-glass--regular")
    35	    css.should contain(".ap-glass--ultra-thin")
    36	  end
    37	
    38	  it "emits --ap-material-intensity scaled blur via calc()" do
    39	    renderer = UI::Web::Renderer.new
    40	    css = renderer.inject_theme_css
    41	    css.should contain("--ap-material-intensity: 1")
    42	    css.should contain("--ap-material-blur-regular: calc(30px * var(--ap-material-intensity, 1))")
    43	  end
    44	
    45	  it "cascades brand override of intensity into the generated CSS" do
    46	    renderer = UI::Web::Renderer.new
    47	    renderer.design_tokens = UI::DesignTokens::Tokens.default.with_brand(BoostedGlassWebSpecBrand.new)
    48	    css = renderer.inject_theme_css
    49	    css.should contain("--ap-material-intensity: 1.3")
    50	  end
    51	end
    52	
    53	private class BoostedGlassWebSpecBrand < UI::DesignTokens::Brand
    54	  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
    55	    material.copy_with(intensity: 1.3)
    56	  end
    57	end

exec
/bin/zsh -lc 'crystal spec spec/ui/glass_material --order random' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 1862ms:
Randomized with seed: 30615
********************************************************************************

Pending:
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `thin` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `regular` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `ultra_thin` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `chrome` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `thick` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `thick` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `chrome` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `regular` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `ultra_thin` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `thin` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `regular` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `thin` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `thick` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `chrome` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `ultra_thin` without renderer-side animation under reduced_motion
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `regular` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `thick` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `thin` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `ultra_thin` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `chrome` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `chrome` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `ultra_thin` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `regular` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `thin` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `thick` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `ultra_thin` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `chrome` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `thick` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `regular` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `thin` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `thin` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `regular` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `chrome` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `ultra_thin` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `thick` at the per-step default blur on macOS
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `thin` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `chrome` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `ultra_thin` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `regular` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `thick` at the per-step default blur
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.0 meets WCAG-AA 4.5:1 contrast

Finished in 432 microseconds
80 examples, 0 failures, 0 errors, 80 pending
Randomized with seed: 30615

exec
/bin/zsh -lc "nl -ba spikes/swiftui_material_spike.swift | sed -n '1,220p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	// SwiftUI Material API compile spike — Phase 5 brief assumption A1.
     2	//
     3	// Purpose: prove the SwiftUI Material API accepts the 5 material enum values
     4	// AND the .background(Material) modifier on iOS 26.5 + macOS 26.5 SDKs.
     5	//
     6	// Compile via:
     7	//   xcrun --sdk iphonesimulator swiftc -emit-library -target arm64-apple-ios16.0-simulator -o /tmp/spike-ios.dylib spikes/swiftui_material_spike.swift
     8	//   xcrun --sdk macosx swiftc -emit-library -o /tmp/spike-macos.dylib spikes/swiftui_material_spike.swift
     9	//
    10	// The iOS invocation needs explicit -target because xcrun's default target
    11	// when given an iPhoneSimulator SDK is still the host (macOS); the explicit
    12	// target tells swiftc to use the iOS Simulator SDK as the actual compile target.
    13	//
    14	// Both must exit 0 for assumption A1 to hold. If either fails, surface to
    15	// architect — Phase 5 cannot ship its claimed SwiftUI Material delivery
    16	// without working Material APIs.
    17	
    18	import SwiftUI
    19	
    20	@available(iOS 15.0, macOS 12.0, *)
    21	public struct APSKMaterialSpike: View {
    22	    public let step: APSKMaterialStep
    23	
    24	    public enum APSKMaterialStep {
    25	        case ultraThin
    26	        case thin
    27	        case regular
    28	        case thick
    29	        case chrome
    30	    }
    31	
    32	    public var body: some View {
    33	        switch step {
    34	        case .ultraThin:
    35	            Text("Material spike").padding().background(.ultraThinMaterial)
    36	        case .thin:
    37	            Text("Material spike").padding().background(.thinMaterial)
    38	        case .regular:
    39	            Text("Material spike").padding().background(.regularMaterial)
    40	        case .thick:
    41	            Text("Material spike").padding().background(.thickMaterial)
    42	        case .chrome:
    43	            // .chromeMaterial isn't exposed; .bar is the closest SwiftUI-vended equivalent
    44	            Text("Material spike").padding().background(.bar)
    45	        }
    46	    }
    47	}

exec
/bin/zsh -lc 'rg -n "chromeMaterial|ultraThickMaterial|bar|Material" spikes/swiftui_material_spike.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:2:# Phase 5 — Validation Rubric: Glass Material Tokenization
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:34:**What:** `GlassBackground` at default intensity (`tokens.material.intensity == 1.0`) on iOS renders the platform-correct surface. On iOS 26+, Liquid Glass appears automatically (system Material). On iOS 15–25, regular blur via system Material. No fallback flat fill.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:46:**What:** `GlassBackground` at default intensity on macOS renders the platform-correct surface (`NSVisualEffectView` material backed; on macOS 26+, Liquid Glass appears automatically via SwiftUI `Material`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:52:**Pass:** Five tiers visible with the expected blur progression. The macOS material translation (UIKit constant → AppKit constant) produces a `regular`-tier result that looks like `NSVisualEffectMaterial.windowBackground`, not like `light` or `medium`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:106:**Note for validator:** The Swift bridge's "delta blur" approach (additive `.blur()` on top of `Material`) means intensity < 1.0 needs a *negative* delta — but SwiftUI's `.blur(radius:)` clamps negative values to zero, which means iOS *cannot make blur lower than the system material's baseline*. This is an Apple-API limitation, not an implementer failure. Confirm with the implementer's handoff whether they documented this and whether the visual difference at 0.5 is therefore smaller on iOS than on web/Android. If the visual difference on iOS at 0.5 is essentially zero, that is acceptable per the limitation but must be acknowledged; the other three platforms still need a clear visible difference.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:135:5. **Deviation check:** also grep for `setMaterial:` in `appkit_renderer.cr` and `effectWithStyle:` in `uikit_renderer.cr`. Every remaining hit must either (a) come from a visit method that delegates to a token resolution, or (b) be one of the visit methods that the implementer explicitly disclosed in their handoff as out-of-scope per the deviation prompt, or (c) sit inside the marker-comment-wrapped translation table. Any undisclosed hard-coded `setMaterial:` integer is a fail.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:137:**Pass:** All grep results are clean (or, for the AppKit translation table, are limited to the marker-comment-wrapped block and the marker is present exactly once in `appkit_renderer.cr`). The CSS prefix grep returns zero `--amber-*` hits. Every `setMaterial:` / `effectWithStyle:` call traces back to a token resolution, is disclosed as deferred, or sits inside the marked translation table.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:198:- `phase: 5`, `phase_name: "Glass Material Tokenization"`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:2:# Phase 5 — Implementation Brief: Glass Material Tokenization
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:38:Phase 5 is the smallest implementation surface in the initiative — it threads one new token branch (`Material`) through four renderers. Almost everything you need is already in place from Phases 1 and 3.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:42:- `src/ui/design_tokens.cr` — Phase 1's source-of-truth. You add a `material : Material` getter on the `Tokens` aggregate. Do not redefine the namespace.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:53:- `src/ui/design_tokens/material.cr` — the new `Material` type and `Step` substruct.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:65:| Material step set | `:ultra_thin, :thin, :regular, :thick, :chrome` | Five steps. Must match what `GlassBackground#material` accepts. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:85:The Phase 5 scope in `README.md` names `GlassBackground` as the widget being tokenized. However, the existing Apple renderers hard-code `NSVisualEffectMaterial` / `UIBlurEffectStyle` constants inside the visit methods for **TabView, Alert, Sidebar (NavigationSplitView), Toolbar, Sheet, and Popover** as well. If Phase 5 only tokenizes the `GlassBackground` visit, brand `material.intensity = 1.3` will not cascade to those other glass surfaces — only to the ones the developer explicitly wraps in `GlassBackground`. That is almost certainly the wrong behavior for a brand-cascade phase.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:87:**Required action:** Extend the refactor to every visit method that today calls `setMaterial:` with a hard-coded constant. The resolution path is identical to `GlassBackground` — pick the semantic material name (`:popover`, `:sheet`, `:sidebar`, `:toolbar`, etc.), look it up in the token tree, pass the resolved parameters to the renderer call.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:93:## `DesignTokens::Material` type specification
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:104:    # A `Material` value declares the five strength steps that map to the
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:111:    # should override individual `MaterialStep` fields directly.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:112:    class Material
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:137:        # `setMaterial:` / `effectWithStyle:`. Wrapped in the token so the
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:200:    # Output of `Material#resolve` — what renderers actually consume.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:218:| ultra_thin |                10.0 |    0.20 |             1.05 |      0.00 |  8 (UIBlurEffectStyleSystemUltraThinMaterial / NSVisualEffectMaterialUltraLight=9 — see note) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:219:| thin       |                20.0 |    0.40 |             1.10 |      0.00 |  9 (UIBlurEffectStyleSystemThinMaterial) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:220:| regular    |                30.0 |    0.60 |             1.15 |      0.00 | 10 (UIBlurEffectStyleSystemMaterial) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:221:| thick      |                40.0 |    0.73 |             1.20 |      0.00 | 11 (UIBlurEffectStyleSystemThickMaterial) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:222:| chrome     |                50.0 |    0.87 |             1.25 |      0.00 | 12 (UIBlurEffectStyleSystemChromeMaterial) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:224:**Note on `apple_material_constant`:** UIKit and AppKit use **different** integer constants for the same semantic material (UIKit `systemMaterial = 10` is the AppKit `windowBackground = 12`'s rough equivalent, not the same number). The token stores the **UIKit** value as canonical; the AppKit renderer applies a small fixed translation table at the call site.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:231:when 10 then NS_VISUAL_EFFECT_MATERIAL_WINDOW_BACKGROUND   # systemMaterial
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:232:when 11 then NS_VISUAL_EFFECT_MATERIAL_HUD                  # thinMaterial
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:237:The marker text is exactly `# AppKit material translation table — only allowed hard-coded glass switch` (em dash `—`, not `--`). Phase 5's validation check `material.no-hardcoded-blur-or-material` (check #22 in `validation.md`) greps for this string and skips the immediately-following case/switch block when counting hard-coded constants. Any other place in the codebase using hard-coded `NSVisualEffectMaterial*` / `UIBlurEffectStyle*` integers without this marker is a phase-5 regression.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:267:### Swift side — `MaterialParameters`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:272:@objc public class MaterialParameters: NSObject {
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:277:    @objc public let appleMaterialConstant: Int64
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:283:                      appleMaterialConstant: Int64) {
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:288:        self.appleMaterialConstant = appleMaterialConstant
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:295:        material: MaterialParameters,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:298:        // Prefer SwiftUI Material (iOS 15+ / macOS 12+). iOS 26+ Liquid Glass
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:299:        // appears automatically on Material-based surfaces. We pick the
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:300:        // SwiftUI Material variant by mapping the integer constant the
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:302:        let m: Material = materialFromConstant(material.appleMaterialConstant)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:307:        if material.blurRadius != defaultBlurFor(material.appleMaterialConstant) {
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:309:            // .blur() modifier on top of the system Material to reach the
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:311:            // (Material) while letting the brand dial blur up or down.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:312:            let delta = material.blurRadius - defaultBlurFor(material.appleMaterialConstant)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:332:- `materialFromConstant(_:)` is a small switch mapping the canonical UIKit integer to the appropriate SwiftUI `Material` case (`.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`, `.chromeMaterial`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:334:- The "scale via additional `.blur()` modifier" approach is a deliberate trade. SwiftUI's `Material` doesn't expose a radius knob. To respect both Apple's Liquid Glass (on iOS 26+) **and** brand intensity, we layer a plain `.blur()` modifier *on top* with the delta. At `intensity = 1.0` the delta is zero so no additional blur is applied and Liquid Glass is unmodified. At `intensity = 1.3` an extra ~9pt blur is layered on. The validator confirms iOS 26 Liquid Glass is still visible at default intensity.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:373:- `LibSwiftKitBridge.glass_background_facade_make(material_params, overrides)` — declared in Phase 3 §7.4 with signature `fun glass_background_facade_make(material_params : Void*, overrides : Void*) : Void*`. The glass surface is created bare; the child view is attached as a subview by the visitor after the facade call (see the code snippet above). Phase 5 does not need to extend this signature — Phase 3 already declares it in the agreed form.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:553:The current `appkit_renderer.cr` `visit(view : UI::GlassBackground)` (lines 2734–2774) hard-codes a switch on `view.material` to an integer `NSVisualEffectMaterial` constant. After Phase 5 it becomes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:567:                    when 12_i64 then 3_i64   # chrome     -> Titlebar
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:602:1. **`[Phase 5] Add DesignTokens::Material type and defaults`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:603:   - New file `src/ui/design_tokens/material.cr` with `Material`, `Step`, `ResolvedStep`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:605:   - Add `material : Material` accessor.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:618:4. **`[Phase 5] Add MaterialParameters to AssetPipelineSwiftKit`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:619:   - Add `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/GlassBackground.swift` with `MaterialParameters` and `GlassBackgroundFacade`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:637:8. **`[Phase 5] Extend material tokenization to TabView, Alert, Sidebar, Toolbar, Sheet, Popover visitors`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:639:   - Every visit method that today calls `setMaterial:` with a hard-coded integer now reads from `tokens.material.resolve(:semantic_name)`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:709:- `spec/ui/renderers/uikit_glass_spec.cr` and `spec/ui/renderers/appkit_glass_spec.cr` — assert the `MaterialParameters` struct passed to the bridge contains the resolved (not raw) values. Drive a brand with `intensity = 1.5` and confirm `material_params.blur_radius == 45.0` for `:regular`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:732:1. `DesignTokens::Material` type exists with `Step`, `ResolvedStep`, the five-step default, and the `intensity` scalar (default 1.0).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:735:4. The `AssetPipelineSwiftKit` package exposes `MaterialParameters` and `GlassBackgroundFacade` and builds for iOS device + simulator + macOS.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:1:# Phase 5 — Glass Material Tokenization
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:27:- New `DesignTokens::Material` subtype declaring:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:32:  - `uikit_renderer.cr` and `appkit_renderer.cr`: pass the resolved material parameters into the SwiftUI bridge facade for `GlassBackground`. SwiftUI side applies `.background(.regularMaterial)` or `.background(Material(...))` with overrides where the brand intensity adjusts.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:63:- **iOS `Material` vs `BlurEffect`:** SwiftUI's `Material` (introduced iOS 15) is the modern API; older code used `UIBlurEffect`. The SwiftUI bridge should prefer `Material`. iOS 26 Liquid Glass appears automatically on `Material`-based surfaces.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:69:- **Phase Brief (YAML, validator-enforced):** `brief.yml` — passes `crystal run scripts/validate_phase_brief.cr -- phases/phase-05-glass-material-tokenization/brief.yml` (exit 0 mandatory before dispatch). Declares all 11 invariant cells, lower-layer assumptions about SwiftUI Material API + backdrop-filter support + Android RenderEffect, repo-derived facts (37 GlassBackground references, 2 backdrop-filter sites in web_renderer.cr, 35311-byte design_tokens.cr), and 3 adapter cardinality MISMATCH rows for SwiftUI's discrete material enum, web `@supports` fallback, and Android < API 31 fallback. Architect-authored 2026-05-22 per `handoff/planning-retrospective-2026-05-22.md` Phase Brief Template.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:5:// 13..25) it falls back to the matching static Material so the surface
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:38:        // Per brief.yml adapter_cardinality row 1, the SwiftUI Material
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:41:        // `.background(<Material>)` path honors the resolved step
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:47:        // quantizes to .regularMaterial on Apple (visually IDENTICAL to
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:53:        let material: Material = {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:55:            case "thin":       return .thinMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:56:            case "thick":      return .thickMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:57:            case "ultraThin":  return .ultraThinMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:58:            case "ultraThick": return .ultraThickMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:59:            default:           return .regularMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:72:            // Pre-26 fallback. `Material` tracks appearance + step.
spikes/swiftui_material_spike.swift:1:// SwiftUI Material API compile spike — Phase 5 brief assumption A1.
spikes/swiftui_material_spike.swift:3:// Purpose: prove the SwiftUI Material API accepts the 5 material enum values
spikes/swiftui_material_spike.swift:4:// AND the .background(Material) modifier on iOS 26.5 + macOS 26.5 SDKs.
spikes/swiftui_material_spike.swift:15:// architect — Phase 5 cannot ship its claimed SwiftUI Material delivery
spikes/swiftui_material_spike.swift:16:// without working Material APIs.
spikes/swiftui_material_spike.swift:21:public struct APSKMaterialSpike: View {
spikes/swiftui_material_spike.swift:22:    public let step: APSKMaterialStep
spikes/swiftui_material_spike.swift:24:    public enum APSKMaterialStep {
spikes/swiftui_material_spike.swift:35:            Text("Material spike").padding().background(.ultraThinMaterial)
spikes/swiftui_material_spike.swift:37:            Text("Material spike").padding().background(.thinMaterial)
spikes/swiftui_material_spike.swift:39:            Text("Material spike").padding().background(.regularMaterial)
spikes/swiftui_material_spike.swift:41:            Text("Material spike").padding().background(.thickMaterial)
spikes/swiftui_material_spike.swift:43:            // .chromeMaterial isn't exposed; .bar is the closest SwiftUI-vended equivalent
spikes/swiftui_material_spike.swift:44:            Text("Material spike").padding().background(.bar)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:3:  name: "Glass Material Tokenization"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:12:# 1. Material tokens are render-time resolved values. `tokens.material.intensity`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:18:# 2. SwiftUI's discrete Material enum quantizes the Float64 intensity scalar.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:27:# 4. SwiftUI Material API assumption verified via a Swift compile spike at
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:39:    rationale: "Phase introduces tokenized blur/opacity/saturation/luminance values per material step + an intensity scalar that quantizes through to the SwiftUI Material enum on Apple, scales backdrop-filter blur radius on web, and scales RenderEffect blur radius on Android API 31+. Visible glass surface changes when material.intensity shifts at brand-declaration time. Phase 5 implementer authors the per-step visual baseline probes."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:58:    rationale: "Material tokens are RENDER-TIME RESOLVED VALUES. Phase 5 does NOT add a runtime mutator path for material.intensity. Consumers re-render the view tree to see intensity changes; the existing Phase 3 reactive bridge (Label/Button/Toggle/Slider/Sheet) is unchanged. This is a deliberate contract limitation; see I-10 for the documented API contract."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:84:    rationale: "Material tokenization does not change focus order or focus-visible behavior. Glass surfaces remain transparent to focus traversal; child controls retain their focus contract."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:129:    rationale: "Per the I-9 commitment below, Phase 5 introduces NO new C-export mutators, no new ObservableObjects on the Swift side, no new retained handles on Crystal side. Material values are pure Crystal Float64/Float32 fields resolved at render time and passed by value through the existing bridge."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:177:    rationale: "New public token API: tokens.material with per-step blur/opacity/saturation/luminance + intensity Float64 scalar. Phase 5 commits to: (1) intensity is RENDER-TIME ONLY — runtime mutation requires a re-render of the view tree; (2) SwiftUI Material's discrete enum quantizes intensity (see adapter_cardinality row 1); (3) web @supports fallback for backdrop-filter unavailability; (4) Android API < 31 alpha-fallback. All four are documented contract limitations consumers MUST understand."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:190:    rationale: "Phase 5 modifies all 4 renderers (uikit/appkit/web/android). Each target's link closure must still resolve after token-resolution paths are added. If Phase 5 calls into SwiftUI Material at the Swift-side facade, the linker must still find the symbols on iOS 26.5 + macOS 26.5 SDKs."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:202:    claim: "SwiftUI Material API accepts the Material enum values Phase 5 emits (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .chromeMaterial) AND the .background(Material) modifier on a SwiftUI View on iOS 26.5 + macOS 26.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:227:    claim: "iOS renderer's existing GlassBackground path uses UIVisualEffectView + UIBlurEffect (will be replaced or extended with Material-based path)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:260:    # Material getter on Tokens, the override_material hook on Brand,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:286:  - public_api: "UI::DesignTokens::Material#intensity (Float64 scalar; documented multiplicative in [0.0, 2.0])"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:287:    adapter: "SwiftUI Material enum on iOS/macOS (.ultraThinMaterial / .thinMaterial / .regularMaterial / .thickMaterial / .chromeMaterial)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:291:    documented_degradation: "QUANTIZATION TABLE (consumer-visible): intensity 0.0–0.3 → .ultraThinMaterial; 0.3–0.7 → .thinMaterial; 0.7–1.3 → .regularMaterial; 1.3–1.8 → .thickMaterial; 1.8+ → .chromeMaterial. Consequence: README's example `intensity = 1.3` quantizes to .regularMaterial on Apple (visually IDENTICAL to default intensity 1.0). Brands wanting a more-frosted Apple look must declare a STEP override (e.g. tokens.material.default_step = :thick) rather than a fractional intensity. This is the documented contract limitation per I-10."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:294:  - public_api: "UI::DesignTokens::Material#blur_radius (Float64 px, per material step, scaled by intensity)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:302:  - public_api: "UI::DesignTokens::Material#blur_radius (Float64 px)"

exec
/bin/zsh -lc 'git show HEAD:spikes/swiftui_material_spike.swift >/tmp/head-spike-check 2>&1; code=$?; printf '"'git show HEAD:spikes/swiftui_material_spike.swift exit=%s\\n' \""'$code"; sed -n '"'1,20p' /tmp/head-spike-check" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
git show HEAD:spikes/swiftui_material_spike.swift exit=128
fatal: path 'spikes/swiftui_material_spike.swift' exists on disk, but not in 'HEAD'

exec
/bin/zsh -lc "nl -ba src/ui/design_tokens.cr | sed -n '480,555p' && nl -ba src/ui/design_tokens.cr | sed -n '680,760p' && nl -ba src/ui/design_tokens.cr | sed -n '950,990p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
   480	      x2l : Float64
   481	
   482	    # Top-level token aggregate. Held immutable: `with_brand` returns a new
   483	    # `Tokens` rather than mutating self.
   484	    class Tokens
   485	      getter colors_light : ColorPalette
   486	      getter colors_dark : ColorPalette
   487	      getter spacing : SpacingScale
   488	      getter type : TypeScale
   489	      getter radius : RadiusScale
   490	      getter shadow : ShadowScale
   491	      getter motion : MotionScale
   492	      getter breakpoints : Breakpoints
   493	
   494	      # Glass material token branch (Phase 5). Carries the five
   495	      # `MaterialStep` values + an `intensity` scalar consumers re-render to
   496	      # observe — Phase 5 explicitly does NOT add a runtime mutator path
   497	      # (see I-2 `preserves` in the Phase 5 brief).
   498	      getter material : Material
   499	
   500	      # Minimum interactive target size in CSS pixels. Phase 2 consumes this
   501	      # to enforce WCAG 2.2 AA touch targets and to derive the lower bound
   502	      # of `clamp()` expressions for tappable controls. Default 44.0 per
   503	      # WCAG / Apple HIG.
   504	      getter touch_target_minimum_px : Float64
   505	
   506	      def initialize(
   507	        @colors_light : ColorPalette,
   508	        @colors_dark : ColorPalette,
   509	        @spacing : SpacingScale,
   510	        @type : TypeScale,
   511	        @radius : RadiusScale,
   512	        @shadow : ShadowScale,
   513	        @motion : MotionScale,
   514	        @breakpoints : Breakpoints,
   515	        @material : Material = Defaults.material,
   516	        @touch_target_minimum_px : Float64 = 44.0,
   517	      )
   518	      end
   519	
   520	      # Returns a new `Tokens` with the given fields replaced; everything else
   521	      # is shared by reference (all referenced types are records, so sharing is
   522	      # safe).
   523	      def copy_with(
   524	        colors_light : ColorPalette = @colors_light,
   525	        colors_dark : ColorPalette = @colors_dark,
   526	        spacing : SpacingScale = @spacing,
   527	        type : TypeScale = @type,
   528	        radius : RadiusScale = @radius,
   529	        shadow : ShadowScale = @shadow,
   530	        motion : MotionScale = @motion,
   531	        breakpoints : Breakpoints = @breakpoints,
   532	        material : Material = @material,
   533	        touch_target_minimum_px : Float64 = @touch_target_minimum_px,
   534	      ) : Tokens
   535	        Tokens.new(
   536	          colors_light: colors_light,
   537	          colors_dark: colors_dark,
   538	          spacing: spacing,
   539	          type: type,
   540	          radius: radius,
   541	          shadow: shadow,
   542	          motion: motion,
   543	          breakpoints: breakpoints,
   544	          material: material,
   545	          touch_target_minimum_px: touch_target_minimum_px,
   546	        )
   547	      end
   548	
   549	      # Apply a `Brand` override on top of self. Returns a NEW `Tokens` — never
   550	      # mutates self. Phase 6's consumer-side override path lands here.
   551	      def with_brand(brand : Brand) : Tokens
   552	        brand.apply(self)
   553	      end
   554	
   555	      # Look up a single token by dotted path. Used by debug tooling. Unknown
   680	          spacing: Defaults.spacing,
   681	          type: Defaults.type_scale,
   682	          radius: Defaults.radius_scale,
   683	          shadow: Defaults.shadow_scale,
   684	          motion: Defaults.motion_scale,
   685	          breakpoints: Defaults.breakpoints,
   686	          material: Defaults.material,
   687	          touch_target_minimum_px: 44.0,
   688	        )
   689	      end
   690	    end
   691	
   692	    # Override surface. A consumer subclasses `Brand`, sets any subset of the
   693	    # `override_*` hooks, and passes the instance to
   694	    # `Tokens.default.with_brand(...)`. Unset fields fall through to defaults.
   695	    #
   696	    # Phase 3 (SwiftUI bridge), Phase 5 (Glass material tokens), and Phase 6
   697	    # (Side-by-side demo app) all inherit the shape of this interface. Changing
   698	    # it after Phase 1 ships requires a coordinated cross-phase update.
   699	    abstract class Brand
   700	      # Compose all override hooks into a new `Tokens`. Returns a NEW object;
   701	      # never mutates `base`.
   702	      def apply(base : Tokens) : Tokens
   703	        base.copy_with(
   704	          colors_light: override_color_light(base.colors_light),
   705	          colors_dark: override_color_dark(base.colors_dark),
   706	          spacing: override_spacing(base.spacing),
   707	          type: override_type(base.type),
   708	          radius: override_radius(base.radius),
   709	          shadow: override_shadow(base.shadow),
   710	          motion: override_motion(base.motion),
   711	          breakpoints: override_breakpoints(base.breakpoints),
   712	          material: override_material(base.material),
   713	          touch_target_minimum_px: override_touch_target_minimum_px(base.touch_target_minimum_px),
   714	        )
   715	      end
   716	
   717	      protected def override_color_light(palette : ColorPalette) : ColorPalette
   718	        palette
   719	      end
   720	
   721	      protected def override_color_dark(palette : ColorPalette) : ColorPalette
   722	        palette
   723	      end
   724	
   725	      protected def override_spacing(scale : SpacingScale) : SpacingScale
   726	        scale
   727	      end
   728	
   729	      protected def override_type(scale : TypeScale) : TypeScale
   730	        scale
   731	      end
   732	
   733	      protected def override_radius(scale : RadiusScale) : RadiusScale
   734	        scale
   735	      end
   736	
   737	      protected def override_shadow(scale : ShadowScale) : ShadowScale
   738	        scale
   739	      end
   740	
   741	      protected def override_motion(scale : MotionScale) : MotionScale
   742	        scale
   743	      end
   744	
   745	      protected def override_breakpoints(scale : Breakpoints) : Breakpoints
   746	        scale
   747	      end
   748	
   749	      # Phase 5: brand override hook for the `Material` token branch.
   750	      # Subclasses return a new `Material` (typically via `material.copy_with(...)`)
   751	      # to scale glass intensity uniformly across all renderers, or override
   752	      # individual `MaterialStep` fields for finer control.
   753	      protected def override_material(material : Material) : Material
   754	        material
   755	      end
   756	
   757	      protected def override_touch_target_minimum_px(value : Float64) : Float64
   758	        value
   759	      end
   760	    end
   950	
   951	      def breakpoints : Breakpoints
   952	        Breakpoints.new(
   953	          sm: 640.0,
   954	          md: 768.0,
   955	          lg: 1024.0,
   956	          xl: 1280.0,
   957	          x2l: 1536.0,
   958	        )
   959	      end
   960	
   961	      # Phase 5 — glass material defaults.
   962	      #
   963	      # Per-step values calibrated to preserve every renderer's existing
   964	      # visual behavior at `intensity == 1.0`. Brands override these via
   965	      # `Brand#override_material(material)` returning a new `Material` (use
   966	      # the auto-generated record `copy_with` to mutate just the fields the
   967	      # brand cares about).
   968	      def material : Material
   969	        Material.new(
   970	          ultra_thin: MaterialStep.new(blur_radius: 10.0, opacity: 0.20, saturation: 1.05, luminance: 0.0),
   971	          thin: MaterialStep.new(blur_radius: 20.0, opacity: 0.40, saturation: 1.10, luminance: 0.0),
   972	          regular: MaterialStep.new(blur_radius: 30.0, opacity: 0.60, saturation: 1.15, luminance: 0.0),
   973	          thick: MaterialStep.new(blur_radius: 40.0, opacity: 0.73, saturation: 1.20, luminance: 0.0),
   974	          chrome: MaterialStep.new(blur_radius: 50.0, opacity: 0.87, saturation: 1.25, luminance: 0.0),
   975	          intensity: 1.0,
   976	        )
   977	      end
   978	    end
   979	  end
   980	end

exec
/bin/zsh -lc "rg -n \"@@[A-Za-z0-9_]+\\s*:.*=|ObservableObject|apsk_.*mutator|material_parameters|MaterialParameters|setMaterial|effectWithStyle|UIBlurEffect|NSVisualEffect|glassEffect|glassBackgroundEffect|blur\\(\" src/ui/views src/ui/design_tokens src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
src/ui/renderers/uikit_renderer.cr:773:      #   UIVisualEffectView (glass root: UIGlassEffect iOS 26 / UIBlurEffect
src/ui/renderers/uikit_renderer.cr:830:                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:831:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:832:                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), 11_i64)
src/ui/renderers/uikit_renderer.cr:1037:      # we prefer UIGlassEffect; on older SDKs UIBlurEffect(systemMaterial=7)
src/ui/renderers/uikit_renderer.cr:1081:                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:1082:                        # UIBlurEffectStyleSystemMaterial = 7
src/ui/renderers/uikit_renderer.cr:1083:                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), 7_i64)
src/ui/renderers/uikit_renderer.cr:1820:      # fallback to UIBlurEffect(systemChromeMaterial=11) on older SDKs.
src/ui/renderers/uikit_renderer.cr:1864:            # UIBlurEffectStyleSystemChromeMaterial (= 11) on older SDKs.
src/ui/renderers/uikit_renderer.cr:1871:                            ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:1873:                              ublur_cls, sel("effectWithStyle:"), 11_i64)
src/ui/renderers/uikit_renderer.cr:1952:      # use UIGlassEffect (iOS 26+) or UIBlurEffect.systemChromeMaterial
src/ui/renderers/uikit_renderer.cr:2000:        # UIBlurEffectStyleSystemChromeMaterial = 11 on older SDKs.
src/ui/renderers/uikit_renderer.cr:2007:                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:2008:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2009:                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), 11_i64)
src/ui/renderers/uikit_renderer.cr:2158:          # Build the UIBlurEffect. Prefer UIGlassEffect on iOS 26 if the
src/ui/renderers/uikit_renderer.cr:2160:          # UIBlurEffectStyleSystemChromeMaterial (iOS 15+, tracks appearance).
src/ui/renderers/uikit_renderer.cr:2168:                          # [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]
src/ui/renderers/uikit_renderer.cr:2169:                          # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2170:                          ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:2172:                            ublur_cls, sel("effectWithStyle:"), 11_i64)
src/ui/renderers/uikit_renderer.cr:2314:      # UIBlurEffectStyleSystemChromeMaterial (= 11, tracks appearance) on
src/ui/renderers/uikit_renderer.cr:2364:                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:2365:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2366:                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), 11_i64)
src/ui/renderers/uikit_renderer.cr:2655:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26+) /
src/ui/renderers/uikit_renderer.cr:2938:                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:2939:                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), 11_i64)
src/ui/renderers/uikit_renderer.cr:3723:      #           UIBlurEffect(systemChromeMaterial=11) fallback.
src/ui/renderers/uikit_renderer.cr:3740:                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
src/ui/renderers/uikit_renderer.cr:3741:                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), 11_i64)
src/ui/renderers/uikit_renderer.cr:3988:        # UIGlassEffect / UIBlurEffect compositing is not captured by XCUITest's
src/ui/renderers/appkit_renderer.cr:341:        # beneath the chrome and NSVisualEffectView with .withinWindow blending samples
src/ui/renderers/appkit_renderer.cr:359:                    # Backdrop-mode: keep VStack transparent so NSVisualEffectView can blur
src/ui/renderers/appkit_renderer.cr:798:      # Visit: TabView -> NSVisualEffectView (Liquid Glass root) containing
src/ui/renderers/appkit_renderer.cr:804:      # equivalent; we render the whole component inside NSVisualEffectView
src/ui/renderers/appkit_renderer.cr:805:      # (NSVisualEffectMaterialMenu = 10, tracks light/dark automatically)
src/ui/renderers/appkit_renderer.cr:809:      #   NSVisualEffectView (glass root)
src/ui/renderers/appkit_renderer.cr:860:        glass_root = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:861:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:862:        # NSVisualEffectBlendingModeWithinWindow = 1 — samples what is beneath
src/ui/renderers/appkit_renderer.cr:863:        # this NSVisualEffectView within the same window. Correct for validation
src/ui/renderers/appkit_renderer.cr:867:        # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:873:        glass_handle = ObjC.owned(glass_root, label: "NSVisualEffectView[tab-bar-glass]")
src/ui/renderers/appkit_renderer.cr:1048:      # Visit: Alert -> NSVisualEffectView (hudWindow material) inline card
src/ui/renderers/appkit_renderer.cr:1051:      # require Liquid Glass. NSVisualEffectMaterialHUDWindow (= 7) is the
src/ui/renderers/appkit_renderer.cr:1090:      # Legacy AppKit NSVisualEffectView alert body, retained for reference.
src/ui/renderers/appkit_renderer.cr:1092:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:1093:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 7_i64)
src/ui/renderers/appkit_renderer.cr:1094:        # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:1096:        # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:1229:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[alert-glass]")
src/ui/renderers/appkit_renderer.cr:1752:      #        with NSVisualEffectView sidebar column (Liquid Glass)
src/ui/renderers/appkit_renderer.cr:1755:      # The sidebar column wraps in NSVisualEffectView with
src/ui/renderers/appkit_renderer.cr:1756:      # NSVisualEffectMaterialSidebar (= 7). The content / detail
src/ui/renderers/appkit_renderer.cr:1763:      #     NSVisualEffectView[sidebar-glass] (sidebar width pinned)
src/ui/renderers/appkit_renderer.cr:1826:            # NSVisualEffectMaterialSidebar = 7. Tracks light/dark appearance.
src/ui/renderers/appkit_renderer.cr:1827:            sidebar_effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:1828:            LibObjCBridge.objc_send_long(sidebar_effect, sel("setMaterial:"), 7_i64)
src/ui/renderers/appkit_renderer.cr:1829:            # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:1831:            # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:1867:            sidebar_effect_handle = ObjC.owned(sidebar_effect, label: "NSVisualEffectView[sidebar-glass]")
src/ui/renderers/appkit_renderer.cr:1933:      # Visit: Toolbar -> NSVisualEffectView (Liquid Glass) + horizontal
src/ui/renderers/appkit_renderer.cr:1939:      # toolbar background is a Liquid Glass translucent NSVisualEffectView.
src/ui/renderers/appkit_renderer.cr:1940:      # Material: NSVisualEffectMaterialToolBar = 10 (tracks appearance).
src/ui/renderers/appkit_renderer.cr:1943:      #   NSVisualEffectView (glass root, toolbar material)
src/ui/renderers/appkit_renderer.cr:1986:      # Legacy AppKit NSStackView/NSVisualEffectView toolbar body. Kept
src/ui/renderers/appkit_renderer.cr:1989:        glass_root = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:1990:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:1991:        # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:1993:        # NSVisualEffectStateActive = 1
src/ui/renderers/appkit_renderer.cr:2007:        glass_handle = ObjC.owned(glass_root, label: "NSVisualEffectView[toolbar-glass]")
src/ui/renderers/appkit_renderer.cr:2111:      # Visit: Sheet -> NSVisualEffectView + inner NSStackView (Liquid Glass)
src/ui/renderers/appkit_renderer.cr:2154:          # Outer glass container — NSVisualEffectView. This is what the
src/ui/renderers/appkit_renderer.cr:2157:          effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:2159:          # NSVisualEffectMaterialSheet = 11 (macOS 10.11+). This is the
src/ui/renderers/appkit_renderer.cr:2163:          # 11 (Sheet) is the semantically correct value per NSVisualEffectMaterial
src/ui/renderers/appkit_renderer.cr:2168:          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)
src/ui/renderers/appkit_renderer.cr:2169:          # NSVisualEffectBlendingModeWithinWindow = 1 — samples what is beneath
src/ui/renderers/appkit_renderer.cr:2170:          # this NSVisualEffectView inside the same window. The validation host
src/ui/renderers/appkit_renderer.cr:2175:          # NSVisualEffectStateActive = 1 — keep the material live regardless
src/ui/renderers/appkit_renderer.cr:2224:          outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[sheet-glass]")
src/ui/renderers/appkit_renderer.cr:2265:      # Visit: Popover -> NSVisualEffectView (popover material) inline card
src/ui/renderers/appkit_renderer.cr:2270:      # NSVisualEffectMaterialPopover = 6. Tracks light/dark appearance
src/ui/renderers/appkit_renderer.cr:2286:      # Corner radius ~10pt matching NSVisualEffectMaterialPopover default.
src/ui/renderers/appkit_renderer.cr:2323:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:2324:        # NSVisualEffectMaterialPopover = 6.
src/ui/renderers/appkit_renderer.cr:2325:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 6_i64)
src/ui/renderers/appkit_renderer.cr:2326:        # NSVisualEffectBlendingModeWithinWindow = 1
src/ui/renderers/appkit_renderer.cr:2328:        # NSVisualEffectStateActive = 1 -- keep material live regardless of key state.
src/ui/renderers/appkit_renderer.cr:2369:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[popover-glass]")
src/ui/renderers/appkit_renderer.cr:2526:          # block the NSVisualEffectView compositor from reaching the backdrop.
src/ui/renderers/appkit_renderer.cr:2638:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
src/ui/renderers/appkit_renderer.cr:2812:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:2813:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 5_i64)     # NSVisualEffectMaterialMenu
src/ui/renderers/appkit_renderer.cr:2913:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[context-menu]")
src/ui/renderers/appkit_renderer.cr:3716:      # Visit: ActivityView -> NSVisualEffectView (sheet material) + four zones
src/ui/renderers/appkit_renderer.cr:3726:      # Material: NSVisualEffectMaterialSheet = 11 (tracks appearance). Although
src/ui/renderers/appkit_renderer.cr:3743:        effect = alloc_init("NSVisualEffectView")
src/ui/renderers/appkit_renderer.cr:3744:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)    # NSVisualEffectMaterialSheet
src/ui/renderers/appkit_renderer.cr:4023:        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[activity-view-glass]")
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift:11:// which retains an `APSKSheetState : ObservableObject` and writes the
src/ui/design_tokens/generators/web_generator.cr:107:        io << "@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {\n"
src/ui/views/activity_view.cr:45:  # On macOS the renderer emits an NSVisualEffectView popover approximation
src/ui/views/activity_view.cr:52:  # Glass material: NSVisualEffectMaterialPopover (6) on macOS;
src/ui/views/activity_view.cr:53:  # UIBlurEffect(systemChromeMaterial) / UIGlassEffect on iOS 26.
src/ui/design_tokens/dist/web_tokens.css:328:@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:9:final class BoolStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:40:final class DoubleStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:65:final class IntStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:83:final class DateStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:101:final class ColorStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:1:// ReactiveState — ObservableObject containers that back Phase 3 Remediation 4
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:48:public final class APSKLabelState: NSObject, ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:60:public final class APSKButtonState: NSObject, ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:83:// The Toggle and Slider facades already own an `ObservableObject` storage
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:97:public final class APSKSheetState: NSObject, ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:4:// `.glassBackgroundEffect()`; on the pre-26 OSes (iOS 16..25 / macOS
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:42:        // directly. The iOS 26 / macOS 26+ `.glassEffect()` path is the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:69:                    .glassEffect()
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextFieldFacade.swift:54:final class TextStorage: ObservableObject {

exec
/bin/zsh -lc "nl -ba src/ui/views/glass_background.cr | sed -n '1,160p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	require "../view"
     2	
     3	module UI
     4	  class GlassBackground < View
     5	    property content : View? = nil
     6	    property material : Symbol = :regular  # :thin, :ultra_thin, :regular, :thick, :chrome
     7	    property is_vibrant : Bool = true
     8	
     9	    def initialize(@content : View? = nil, @material : Symbol = :regular)
    10	    end
    11	
    12	    def accept(visitor : PlatformVisitor)
    13	      visitor.visit(self)
    14	    end
    15	  end
    16	end

codex
The probe directory itself runs exactly as 80 pending examples, so the draft’s pending count is right. The quality problem is narrower: several pending bodies, especially macOS env-response, are empty or nearly empty, so the specs encode names/counts more than runnable probe contracts.
exec
/bin/zsh -lc "rg -n \"MaterialParameters|glass_background_facade_make|material_params|setMaterial|apple_step|ultraThick|glassEffect|\\.background\\(material\\)|AssetPipelineGlassHelper|@supports not|--ap-material\" spec src swift samples docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:253:    # through var(--ap-material-blur-<step>).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:299:    documented_degradation: "Browsers without backdrop-filter (detected via @supports not (backdrop-filter: blur(1px))) fall back to background-color: color-mix(in oklch, var(--ap-color-surface-panel) Z%, transparent) where Z is per-step opacity (ultra_thin=20%, thin=40%, regular=60%, thick=73%, chrome=87%). No blur. WCAG-AA contrast verified for text-on-fallback as well as text-on-blurred. Visible glass surfaces remain visually distinguishable via opacity alone."
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:42:        // directly. The iOS 26 / macOS 26+ `.glassEffect()` path is the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:58:            case "ultraThick": return .ultraThickMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:69:                    .glassEffect()
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:75:                    .background(material)
samples/cross_platform/web/brand_glass_intensity_demo.cr:18:#   2. The generated `--ap-material-*` CSS so the cascade is visually
samples/cross_platform/web/brand_glass_intensity_demo.cr:19:#      inspectable (`--ap-material-intensity: 1.3` and the `calc()`
samples/cross_platform/web/brand_glass_intensity_demo.cr:55:  puts line if line.includes?("--ap-material-") || line.includes?("ap-glass--")
samples/cross_platform/web/brand_glass_intensity_demo.cr:60:  apple = tokens.material.apple_step(step)
samples/cross_platform/macos_host/hig_showcase.cr:227:      # NSVisualEffectView grouped_card material (setMaterial: 11) tracks appearance.
samples/cross_platform/macos_host/hig_showcase.cr:597:      # grouped_card, which calls setMaterial:10 in appkit_renderer.cr.
samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:24:public final class AssetPipelineGlassHelper {
samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:26:    private AssetPipelineGlassHelper() {}
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift:25:    /// One of "regular" | "thin" | "thick" | "ultraThin" | "ultraThick".
src/ui/native/android_bridge.c:1477:// Calls the host's AssetPipelineGlassHelper.applyGlass(view, blurRadius,
src/ui/native/android_bridge.c:1485:    jclass helper_cls = (*env)->FindClass(env, "com/assetpipeline/glass/AssetPipelineGlassHelper");
src/ui/native/swiftkit_bridge.m:507:// Swift facade routes through `.glassEffect()` on iOS 26 / macOS 26 and
spec/ui/glass_material/macos_glass_default_spec.cr:21:      #   visual.material_enum.should eq(tokens.material.apple_step(:#{step}))
src/ui/native/swiftkit_bridge.cr:243:    # a single child because the SwiftUI `.glassEffect()` modifier
src/ui/native/swiftkit_overrides.cr:515:          sender.set_string(target, :setMaterial, view.material.to_s)
src/ui/native/swiftkit_overrides.cr:601:      # macOS 26 the facade routes through `.glassEffect()` for real
src/ui/native/swiftkit_overrides.cr:609:      # Glass populator. `apple_step` is the Apple-quantized step Symbol the
src/ui/native/swiftkit_overrides.cr:610:      # renderer has resolved via `tokens.material.apple_step(view.material)`.
src/ui/native/swiftkit_overrides.cr:611:      # The populator emits the facade `setMaterial:` key derived from the
src/ui/native/swiftkit_overrides.cr:616:      # `apple_step` defaults to `view.material` so spec-level callers that
src/ui/native/swiftkit_overrides.cr:619:      def self.populate_glass_background(target : String, view : UI::GlassBackground, sender : Sender, apple_step : Symbol = view.material)
src/ui/native/swiftkit_overrides.cr:627:        emit = apple_step != :regular || view.material != :regular
src/ui/native/swiftkit_overrides.cr:629:          key = case apple_step
src/ui/native/swiftkit_overrides.cr:634:                when :chrome      then "ultraThick" # closest SwiftUI Material analogue
src/ui/native/swiftkit_overrides.cr:635:                else                   apple_step.to_s
src/ui/native/swiftkit_overrides.cr:637:          sender.set_string(target, :setMaterial, key)
spec/ui/design_tokens/material_spec.cr:62:  describe "#apple_step (Apple quantization contract)" do
spec/ui/design_tokens/material_spec.cr:65:      m.apple_step(:ultra_thin).should eq(:ultra_thin)
spec/ui/design_tokens/material_spec.cr:66:      m.apple_step(:thin).should eq(:thin)
spec/ui/design_tokens/material_spec.cr:67:      m.apple_step(:regular).should eq(:regular)
spec/ui/design_tokens/material_spec.cr:68:      m.apple_step(:thick).should eq(:thick)
spec/ui/design_tokens/material_spec.cr:69:      m.apple_step(:chrome).should eq(:chrome)
spec/ui/design_tokens/material_spec.cr:74:      m.apple_step(:thick).should eq(:thick)
spec/ui/design_tokens/material_spec.cr:75:      m.apple_step(:ultra_thin).should eq(:ultra_thin)
spec/ui/design_tokens/material_spec.cr:81:      base.copy_with(intensity: 0.2).apple_step(:regular).should eq(:ultra_thin)
spec/ui/design_tokens/material_spec.cr:82:      base.copy_with(intensity: 0.5).apple_step(:regular).should eq(:thin)
spec/ui/design_tokens/material_spec.cr:83:      base.copy_with(intensity: 1.0).apple_step(:regular).should eq(:regular)
spec/ui/design_tokens/material_spec.cr:84:      base.copy_with(intensity: 1.3).apple_step(:regular).should eq(:regular)  # brief worked example
spec/ui/design_tokens/material_spec.cr:85:      base.copy_with(intensity: 1.5).apple_step(:regular).should eq(:thick)
spec/ui/design_tokens/material_spec.cr:86:      base.copy_with(intensity: 1.8).apple_step(:regular).should eq(:chrome)   # brief "1.8+"
spec/ui/design_tokens/material_spec.cr:87:      base.copy_with(intensity: 2.0).apple_step(:regular).should eq(:chrome)
spec/ui/design_tokens/material_spec.cr:98:      base.copy_with(intensity: 1.3).apple_step(:regular).should eq(:regular)
spec/ui/design_tokens/material_spec.cr:100:      base.copy_with(intensity: 1.8).apple_step(:regular).should eq(:chrome)
spec/ui/design_tokens/material_spec.cr:101:      base.copy_with(intensity: 1.79).apple_step(:regular).should eq(:thick)
spec/ui/design_tokens/material_spec.cr:105:      base.copy_with(intensity: 0.3).apple_step(:regular).should eq(:ultra_thin)
spec/ui/design_tokens/material_spec.cr:106:      base.copy_with(intensity: 0.7).apple_step(:regular).should eq(:thin)
spec/ui/design_tokens/material_spec.cr:107:      base.copy_with(intensity: 1.301).apple_step(:regular).should eq(:thick)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:8:# overrides must surface the corresponding `setMaterial:` /
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:54:      FakeLibObjCBridge.refute_sent(:setMaterial)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:59:    it "skips setMaterial: when material is :regular (type default)" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:63:      FakeLibObjCBridge.refute_sent(:setMaterial)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:66:    it "emits setMaterial: 'thin' when material is :thin" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:70:      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thin"])
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:73:    it "emits setMaterial: 'ultraThin' for :ultra_thin (camelCase normalisation)" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:77:      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThin"])
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:80:    it "emits setMaterial: 'thick' for :thick" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:84:      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thick"])
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:87:    it "emits setMaterial: 'ultraThick' for :chrome (closest Material analogue)" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:91:      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThick"])
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:95:  describe "Phase 5 apple_step quantization parameter" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:96:    it "honors the explicit apple_step override on a :regular-declared view" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:99:      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :thick)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:100:      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thick"])
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:106:      # Renderer-resolved apple_step normally matches declared step for non-:regular.
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:107:      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :thin)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:108:      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thin"])
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:111:    it "emits setMaterial: 'ultraThin' when brand intensity quantizes :regular down to :ultra_thin" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:114:      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :ultra_thin)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:115:      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThin"])
src/ui/renderers/appkit_renderer.cr:861:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:1093:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 7_i64)
src/ui/renderers/appkit_renderer.cr:1828:            LibObjCBridge.objc_send_long(sidebar_effect, sel("setMaterial:"), 7_i64)
src/ui/renderers/appkit_renderer.cr:1990:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:2168:          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)
src/ui/renderers/appkit_renderer.cr:2325:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 6_i64)
src/ui/renderers/appkit_renderer.cr:2638:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
src/ui/renderers/appkit_renderer.cr:2649:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/renderers/appkit_renderer.cr:2654:        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
src/ui/renderers/appkit_renderer.cr:2813:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 5_i64)     # NSVisualEffectMaterialMenu
src/ui/renderers/appkit_renderer.cr:3744:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)    # NSVisualEffectMaterialSheet
src/ui/design_tokens/generators/web_generator.cr:63:      # `--ap-material-intensity` is the brand-declaration-time scalar (default
src/ui/design_tokens/generators/web_generator.cr:73:        io << "#{indent}--ap-material-intensity: #{format_number(intensity_clamped)};\n"
src/ui/design_tokens/generators/web_generator.cr:85:        io << "#{indent}--ap-material-blur-#{name}: calc(#{format_px(step.blur_radius)} * var(--ap-material-intensity, 1));\n"
src/ui/design_tokens/generators/web_generator.cr:86:        io << "#{indent}--ap-material-opacity-#{name}: #{format_number(step.opacity)};\n"
src/ui/design_tokens/generators/web_generator.cr:87:        io << "#{indent}--ap-material-saturation-#{name}: #{format_number(step.saturation)};\n"
src/ui/design_tokens/generators/web_generator.cr:90:      # `@supports not (backdrop-filter)` fallback block. Browsers without
src/ui/design_tokens/generators/web_generator.cr:93:      # declare, expressed via `var(--ap-material-opacity-<step>)` so
src/ui/design_tokens/generators/web_generator.cr:107:        io << "@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {\n"
src/ui/design_tokens/generators/web_generator.cr:109:          io << "  .ap-glass--#{step} { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step}) * 100%), transparent); }\n"
src/ui/renderers/uikit_renderer.cr:2655:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26+) /
src/ui/renderers/uikit_renderer.cr:2670:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/renderers/uikit_renderer.cr:2675:        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
spec/ui/renderers/swiftkit/group3_overrides_spec.cr:245:      FakeLibObjCBridge.refute_sent(:setMaterial)
src/ui/design_tokens/material.cr:7:    # on web (via `calc()` against `--ap-material-intensity`) and on Android
src/ui/design_tokens/material.cr:29:    # .regularMaterial, .thickMaterial, .ultraThickMaterial). The declared
src/ui/design_tokens/material.cr:33:    # of brand intensity. `apple_step(declared)` exposes this quantization;
src/ui/design_tokens/material.cr:38:    # `GlassBackground` views), `apple_step` does honor brand intensity by
src/ui/design_tokens/material.cr:92:      def apple_step(declared : Symbol) : Symbol
src/ui/renderers/web_renderer.cr:1406:        # the per-step `--ap-material-*` custom properties the WebGenerator
src/ui/renderers/web_renderer.cr:1408:        # `calc(<base>px * var(--ap-material-intensity, 1))`). The
src/ui/renderers/web_renderer.cr:1414:          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1415:          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1416:          "background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step_key}) * 100%), transparent); " \
src/ui/renderers/web_renderer.cr:2018:        # `:thin` material step. Inline style references `var(--ap-material-*)`
src/ui/renderers/web_renderer.cr:2024:        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); -webkit-backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")
spec/ui/renderers/web_glass_spec.cr:15:    html.should contain("var(--ap-material-blur-regular)")
spec/ui/renderers/web_glass_spec.cr:16:    html.should contain("var(--ap-material-opacity-regular)")
spec/ui/renderers/web_glass_spec.cr:17:    html.should contain("var(--ap-material-saturation-regular)")
spec/ui/renderers/web_glass_spec.cr:26:      html.should contain("var(--ap-material-blur-#{key})")
spec/ui/renderers/web_glass_spec.cr:33:    css.should contain("@supports not ((backdrop-filter: blur(1px))")
spec/ui/renderers/web_glass_spec.cr:38:  it "emits --ap-material-intensity scaled blur via calc()" do
spec/ui/renderers/web_glass_spec.cr:41:    css.should contain("--ap-material-intensity: 1")
spec/ui/renderers/web_glass_spec.cr:42:    css.should contain("--ap-material-blur-regular: calc(30px * var(--ap-material-intensity, 1))")
spec/ui/renderers/web_glass_spec.cr:49:    css.should contain("--ap-material-intensity: 1.3")
src/ui/renderers/android_renderer.cr:203:    # Applies AssetPipelineGlassHelper.applyGlass(view, blurRadius,
src/ui/renderers/android_renderer.cr:2173:    # On API 31+, the host's `AssetPipelineGlassHelper.applyGlass` static
src/ui/design_tokens/dist/web_tokens.css:156:  --ap-material-intensity: 1;
src/ui/design_tokens/dist/web_tokens.css:157:  --ap-material-blur-ultra-thin: calc(10px * var(--ap-material-intensity, 1));
src/ui/design_tokens/dist/web_tokens.css:158:  --ap-material-opacity-ultra-thin: 0.2;
src/ui/design_tokens/dist/web_tokens.css:159:  --ap-material-saturation-ultra-thin: 1.05;
src/ui/design_tokens/dist/web_tokens.css:160:  --ap-material-blur-thin: calc(20px * var(--ap-material-intensity, 1));
src/ui/design_tokens/dist/web_tokens.css:161:  --ap-material-opacity-thin: 0.4;
src/ui/design_tokens/dist/web_tokens.css:162:  --ap-material-saturation-thin: 1.1;
src/ui/design_tokens/dist/web_tokens.css:163:  --ap-material-blur-regular: calc(30px * var(--ap-material-intensity, 1));
src/ui/design_tokens/dist/web_tokens.css:164:  --ap-material-opacity-regular: 0.6;
src/ui/design_tokens/dist/web_tokens.css:165:  --ap-material-saturation-regular: 1.15;
src/ui/design_tokens/dist/web_tokens.css:166:  --ap-material-blur-thick: calc(40px * var(--ap-material-intensity, 1));
src/ui/design_tokens/dist/web_tokens.css:167:  --ap-material-opacity-thick: 0.73;
src/ui/design_tokens/dist/web_tokens.css:168:  --ap-material-saturation-thick: 1.2;
src/ui/design_tokens/dist/web_tokens.css:169:  --ap-material-blur-chrome: calc(50px * var(--ap-material-intensity, 1));
src/ui/design_tokens/dist/web_tokens.css:170:  --ap-material-opacity-chrome: 0.87;
src/ui/design_tokens/dist/web_tokens.css:171:  --ap-material-saturation-chrome: 1.25;
src/ui/design_tokens/dist/web_tokens.css:328:@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
src/ui/design_tokens/dist/web_tokens.css:329:  .ap-glass--ultra-thin { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-ultra-thin) * 100%), transparent); }
src/ui/design_tokens/dist/web_tokens.css:330:  .ap-glass--thin { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); }
src/ui/design_tokens/dist/web_tokens.css:331:  .ap-glass--regular { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-regular) * 100%), transparent); }
src/ui/design_tokens/dist/web_tokens.css:332:  .ap-glass--thick { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thick) * 100%), transparent); }
src/ui/design_tokens/dist/web_tokens.css:333:  .ap-glass--chrome { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-chrome) * 100%), transparent); }

exec
/bin/zsh -lc 'crystal run scripts/validate_phase_brief.cr -- docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc 'crystal spec spec/ui/design_tokens/material_spec.cr spec/ui/renderers/web_glass_spec.cr spec/ui/glass_material' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 exited 1 in 586ms:
In scripts/validate_phase_brief.cr:374:15

 374 | unless File.executable?(resolved)
                   ^----------
Warning: Deprecated File.executable?. Use `File::Info.executable?` instead

In scripts/validate_phase_brief.cr:378:59

 378 | unless %w[.cr .sh .rb .py .js].includes?(ext) || File.executable?(resolved)
                                                             ^----------
Warning: Deprecated File.executable?. Use `File::Info.executable?` instead

A total of 2 warnings were found.
Unable to create directory: '/Users/crimsonknight/.cache/crystal/Users-crimsonknight-open_source_coding_projects-asset_pipeline-scripts-validate_phase_brief.cr': Operation not permitted (File::Error)
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'raise<Crystal::TypeException+>:NoReturn'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'Dir::mkdir<Path, Int32>:Nil'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'Crystal::CacheDir#directory_for<String>:String'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'Crystal::Compiler#codegen<Crystal::Program, Crystal::ASTNode+, Array(Crystal::Compiler::Source), String>:Array(Crystal::Compiler::CompilationUnit)'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'Crystal::Compiler#compile<Array(Crystal::Compiler::Source), String>:Crystal::Compiler::Result'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'Crystal::Command#run_command<Bool>:Nil'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'Crystal::Command#run:(Bool | Crystal::Repl::Value | Nil)'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in '__crystal_main'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'Crystal::main<Int32, Pointer(Pointer(UInt8))>:Int32'
  from /opt/homebrew/Cellar/crystal/1.20.0/bin/crystal in 'main'
Error: you've found a bug in the Crystal compiler. Please open an issue, including source code that will allow us to reproduce the bug: https://github.com/crystal-lang/crystal/issues

 succeeded in 2399ms:
.................********************************************************************************

Pending:
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `ultra_thin` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `thin` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `regular` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `thick` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response reduced_motion cell renders `chrome` without renderer-side animation under reduced_motion
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `ultra_thin` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `thin` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `regular` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `thick` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response high_contrast cell renders `chrome` with documented high_contrast response
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `ultra_thin` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `thin` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `regular` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `thick` differently in dark vs light appearance
  Phase 5 probe: ios.glass.material.env_response dark_mode cell renders `chrome` differently in dark vs light appearance
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `ultra_thin` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `thin` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `regular` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `thick` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.default renders SwiftUI Material `chrome` at the per-step default blur on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `ultra_thin` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `thin` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `regular` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `thick` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response reduced_motion cell renders `chrome` without renderer-side animation under reduced_motion on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `ultra_thin` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `thin` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `regular` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `thick` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response high_contrast cell renders `chrome` with documented high_contrast response on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `ultra_thin` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `thin` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `regular` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `thick` differently in dark vs light appearance on macOS
  Phase 5 probe: macos.glass.material.env_response dark_mode cell renders `chrome` differently in dark vs light appearance on macOS
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `ultra_thin` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `thin` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `regular` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `thick` at the per-step default blur
  Phase 5 probe: ios.glass.material.default renders SwiftUI Material `chrome` at the per-step default blur
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=0.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.0 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.3 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: ios.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.5 meets WCAG-AA 4.5:1 contrast
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=0.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.0 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.3 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `ultra_thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thin` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `regular` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `thick` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS
  Phase 5 probe: macos.glass.material.contrast.wcag_aa text_primary on `chrome` at intensity=1.5 meets WCAG-AA 4.5:1 contrast on macOS

Finished in 5.65 milliseconds
97 examples, 0 failures, 0 errors, 80 pending

exec
/bin/zsh -lc 'CRYSTAL_CACHE_DIR=/private/tmp/crystal-cache crystal run scripts/validate_phase_brief.cr -- docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 exited 3 in 1650ms:
In scripts/validate_phase_brief.cr:374:15

 374 | unless File.executable?(resolved)
                   ^----------
Warning: Deprecated File.executable?. Use `File::Info.executable?` instead

In scripts/validate_phase_brief.cr:378:59

 378 | unless %w[.cr .sh .rb .py .js].includes?(ext) || File.executable?(resolved)
                                                             ^----------
Warning: Deprecated File.executable?. Use `File::Info.executable?` instead

A total of 2 warnings were found.
Validating phase brief: docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml
OK: top-level keys all recognized
OK: phase section structure valid
OK: invariant_matrix structure valid (11 rows, all platforms cells present, no placeholders)
Re-running query for fact 'GlassBackground usage count in src/ and samples/ (binary files excluded)': ok (46)
Re-running query for fact 'backdrop-filter emission count in web_renderer.cr': ok (4)
Re-running query for fact 'Existing design_tokens.cr file size in bytes (sanity: editing the right file)': ok (37252)
Re-running query for fact 'Android renderer alpha-step hex literals (5 material steps + 1 default fallback = 6)': ok (1)
Re-running query for fact 'iOS renderer UIVisualEffectView/UIBlurEffect references that Phase 5 may touch (includes comments + code)': ok (60)
Re-running query for fact 'macOS renderer NSVisualEffectView references that Phase 5 may touch (includes comments + code)': ok (37)
OK: repo_derived_facts all match captured values (6 facts)
FAIL[3]: Assumption A1 (SwiftUI Material API accepts the Material enum values Phase 5 emits (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .chromeMaterial) AND the .background(Material) modifier on a SwiftUI View on iOS 26.5 + macOS 26.5) FAILED. Command exited 1. stderr: <unknown>:0: error: error opening '/Users/crimsonknight/.cache/clang/ModuleCache/Swift-2OGHNE5VFSLAO.swiftmodule' for output: /Users/crimsonknight/.cache/clang/ModuleCache: Operation not permitted
<unknown>:0: error: unable to load standard library for target 'arm64-apple-ios16.0-simulator'
Running verification for A1: 
Brief is NOT dispatchable. Fix the failure above and re-run.

codex
I also reran the brief validator with a writable Crystal cache. It does not pass in this sandbox: A1 invokes Swift and fails because the assumption command writes Swift/Clang module cache under `~/.cache/clang`, which is outside the writable roots. That does not prove the Swift API is wrong, but it means the draft’s “brief validator EXIT=0” is not reproducible here without fixing the cache path.
exec
/bin/zsh -lc 'xcrun --sdk iphonesimulator swiftc -module-cache-path /private/tmp/swift-module-cache -emit-library -target arm64-apple-ios16.0-simulator -o /private/tmp/spike-ios.dylib spikes/swiftui_material_spike.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc 'xcrun --sdk macosx swiftc -module-cache-path /private/tmp/swift-module-cache -emit-library -o /private/tmp/spike-macos.dylib spikes/swiftui_material_spike.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 3225ms:
 succeeded in 3981ms:
exec
/bin/zsh -lc "nl -ba spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr | sed -n '1,130p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	require "../../../spec_helper"
     2	require "../../../../src/ui"
     3	
     4	# Default-detection invariant spec for the Phase 3 Glass facade populator
     5	# (the "headline visual differentiator" the README names). Mirrors the
     6	# pattern in `button_overrides_spec.cr` and `group3_overrides_spec.cr`:
     7	# default-constructed view must produce zero setter records; per-knob
     8	# overrides must surface the corresponding `setMaterial:` /
     9	# `setApskAccessibilityLabel:` invocation.
    10	
    11	private class RecordingSender < UI::Native::Populator::Sender
    12	  def set_color(target : String, setter : Symbol, color : UI::Color?)
    13	    return if color.nil?
    14	    FakeLibObjCBridge.record(setter, [target, "color"], "")
    15	  end
    16	
    17	  def set_number(target : String, setter : Symbol, value : Float64?)
    18	    return if value.nil?
    19	    FakeLibObjCBridge.record(setter, [target, value.to_s], "")
    20	  end
    21	
    22	  def set_bool(target : String, setter : Symbol, value : Bool?)
    23	    return if value.nil?
    24	    FakeLibObjCBridge.record(setter, [target, value.to_s], "")
    25	  end
    26	
    27	  def set_string(target : String, setter : Symbol, value : String?)
    28	    return if value.nil?
    29	    FakeLibObjCBridge.record(setter, [target, value], "")
    30	  end
    31	end
    32	
    33	describe UI::Native::Populator, "#populate_glass_background" do
    34	  describe "default-detection invariant" do
    35	    it "emits zero setters on a default UI::GlassBackground.new" do
    36	      view = UI::GlassBackground.new
    37	      target = FakeLibObjCBridge.next_sentinel_pointer
    38	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
    39	
    40	      # Common ViewOverrides defaults — all skipped.
    41	      FakeLibObjCBridge.refute_sent(:setBackgroundColor)
    42	      FakeLibObjCBridge.refute_sent(:setCornerRadius)
    43	      FakeLibObjCBridge.refute_sent(:setPaddingTop)
    44	      FakeLibObjCBridge.refute_sent(:setOpacity)
    45	      FakeLibObjCBridge.refute_sent(:setHidden)
    46	      FakeLibObjCBridge.refute_sent(:setBorderWidth)
    47	      FakeLibObjCBridge.refute_sent(:setShadowRadius)
    48	      FakeLibObjCBridge.refute_sent(:setMinWidth)
    49	      FakeLibObjCBridge.refute_sent(:setMaxWidth)
    50	      FakeLibObjCBridge.refute_sent(:setAccessibilityIdentifier)
    51	      FakeLibObjCBridge.refute_sent(:setApskAccessibilityLabel)
    52	
    53	      # Glass-specific default — :regular material is the type default.
    54	      FakeLibObjCBridge.refute_sent(:setMaterial)
    55	    end
    56	  end
    57	
    58	  describe "material override" do
    59	    it "skips setMaterial: when material is :regular (type default)" do
    60	      view = UI::GlassBackground.new(material: :regular)
    61	      target = FakeLibObjCBridge.next_sentinel_pointer
    62	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
    63	      FakeLibObjCBridge.refute_sent(:setMaterial)
    64	    end
    65	
    66	    it "emits setMaterial: 'thin' when material is :thin" do
    67	      view = UI::GlassBackground.new(material: :thin)
    68	      target = FakeLibObjCBridge.next_sentinel_pointer
    69	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
    70	      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thin"])
    71	    end
    72	
    73	    it "emits setMaterial: 'ultraThin' for :ultra_thin (camelCase normalisation)" do
    74	      view = UI::GlassBackground.new(material: :ultra_thin)
    75	      target = FakeLibObjCBridge.next_sentinel_pointer
    76	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
    77	      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThin"])
    78	    end
    79	
    80	    it "emits setMaterial: 'thick' for :thick" do
    81	      view = UI::GlassBackground.new(material: :thick)
    82	      target = FakeLibObjCBridge.next_sentinel_pointer
    83	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
    84	      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thick"])
    85	    end
    86	
    87	    it "emits setMaterial: 'ultraThick' for :chrome (closest Material analogue)" do
    88	      view = UI::GlassBackground.new(material: :chrome)
    89	      target = FakeLibObjCBridge.next_sentinel_pointer
    90	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
    91	      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThick"])
    92	    end
    93	  end
    94	
    95	  describe "Phase 5 apple_step quantization parameter" do
    96	    it "honors the explicit apple_step override on a :regular-declared view" do
    97	      view = UI::GlassBackground.new(material: :regular)
    98	      target = FakeLibObjCBridge.next_sentinel_pointer
    99	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :thick)
   100	      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thick"])
   101	    end
   102	
   103	    it "still emits the resolved key when intensity quantization keeps it at :regular but declared material differs" do
   104	      view = UI::GlassBackground.new(material: :thin)
   105	      target = FakeLibObjCBridge.next_sentinel_pointer
   106	      # Renderer-resolved apple_step normally matches declared step for non-:regular.
   107	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :thin)
   108	      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thin"])
   109	    end
   110	
   111	    it "emits setMaterial: 'ultraThin' when brand intensity quantizes :regular down to :ultra_thin" do
   112	      view = UI::GlassBackground.new(material: :regular)
   113	      target = FakeLibObjCBridge.next_sentinel_pointer
   114	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :ultra_thin)
   115	      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThin"])
   116	    end
   117	  end
   118	
   119	  describe "common ViewOverrides cascade" do
   120	    it "forwards corner_radius override to setCornerRadius:" do
   121	      view = UI::GlassBackground.new
   122	      view.corner_radius = 14.0
   123	      target = FakeLibObjCBridge.next_sentinel_pointer
   124	      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
   125	      FakeLibObjCBridge.assert_sent(:setCornerRadius, times: 1, args: [target, "14.0"])
   126	    end
   127	
   128	    it "forwards accessibility_label to setApskAccessibilityLabel:" do
   129	      view = UI::GlassBackground.new
   130	      view.accessibility_label = "Background panel"

exec
/bin/zsh -lc "nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift | sed -n '1,90p' && nl -ba src/ui/native/swiftkit_bridge.cr | sed -n '220,255p' && nl -ba src/ui/native/swiftkit_bridge.m | sed -n '490,520p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	// GlassBackgroundOverrides — override carrier for the GlassBackground
     2	// widget, the "headline visual differentiator" the Phase 3 README names
     3	// (Liquid Glass on default Card/Sheet). The facade reads the `material`
     4	// key to pick a Material family on pre-iOS 26 OSes and an `if
     5	// #available(iOS 26.0, macOS 26.0, *) { .glassBackgroundEffect() }`
     6	// branch on iOS 26+ — that's where the actual Liquid Glass material
     7	// kicks in.
     8	//
     9	// Phase 5 extension surface: when Phase 5 ships the full glass material
    10	// parameter set (intensity, tint, corner curve) those fields will be
    11	// appended here as additional @objc-exposed nullable properties. The
    12	// Phase 3 shape leaves them as pure extension — no rework. Specifically,
    13	// Phase 5 will add:
    14	//
    15	//   @objc public var materialIntensity: NSNumber?   // 0..1
    16	//   @objc public var tintColor: APSKPlatformColor?  // brand-aware tint
    17	//   @objc public var cornerCurve: String?           // "circular" | "continuous"
    18	//
    19	// and the facade will pass these into the iOS 26 modifier chain.
    20	
    21	import Foundation
    22	
    23	@objc(APSKGlassBackgroundOverrides)
    24	public final class GlassBackgroundOverrides: ViewOverrides {
    25	    /// One of "regular" | "thin" | "thick" | "ultraThin" | "ultraThick".
    26	    /// `nil` selects the SwiftUI default (`.regularMaterial` / Liquid Glass
    27	    /// "regular" on iOS 26).
    28	    @objc public var material: String?
    29	
    30	    // Phase 5 will extend this carrier with material parameters
    31	    // (materialIntensity, tintColor, cornerCurve). The Phase 3 shape
    32	    // leaves those Phase 5 additions as pure extension — no rework.
    33	
    34	    @objc public override init() { super.init() }
    35	}
   220	                          overrides : Void*) : Void*
   221	    fun apsk_make_form(child_views : Void*, child_count : Int32,
   222	                       overrides : Void*) : Void*
   223	    fun apsk_make_grid(child_views : Void*, child_count : Int32,
   224	                       overrides : Void*) : Void*
   225	    fun apsk_make_card(child_views : Void*, child_count : Int32,
   226	                       overrides : Void*) : Void*
   227	    fun apsk_make_surface(child_views : Void*, child_count : Int32,
   228	                          overrides : Void*) : Void*
   229	    fun apsk_make_menu_button(label : UInt8*, overrides : Void*) : Void*
   230	    fun apsk_make_toggle_button(label : UInt8*, overrides : Void*,
   231	                                action_token : UInt64) : Void*
   232	    # `UI::ListView` (§6 #25). The Crystal renderer flattens all section
   233	    # items into a single child-views array and emits `setSectionHeaders` /
   234	    # `setSectionFooters` / `setSectionItemCounts` on the overrides so the
   235	    # facade can slice items back into SwiftUI `Section`s.
   236	    fun apsk_make_list_view(child_views : Void*, child_count : Int32,
   237	                            overrides : Void*) : Void*
   238	
   239	    # ---- Glass facade (P1) --------------------------------------------
   240	    # `child_view` is a single platform-view pointer (the content the
   241	    # glass material backs) or NULL for an empty glass card. Unlike the
   242	    # Group-3 container facades (which take a Void* + count), Glass takes
   243	    # a single child because the SwiftUI `.glassEffect()` modifier
   244	    # composes onto a single content view.
   245	    fun apsk_make_glass_background(overrides : Void*, child_view : Void*) : Void*
   246	
   247	    # -------------------------------------------------------------------------
   248	    # Phase 3 Remediation 4 — reactive facade entry points.
   249	    #
   250	    # Each `apsk_make_*_reactive` mirrors the matching static `apsk_make_*`
   251	    # constructor but takes an extra `out_state : Void**`. The Swift facade
   252	    # writes a +1 retained pointer to an `ObservableObject` state through
   253	    # that out-parameter; Crystal stores it on `NativeHandle#state_handle`
   254	    # and later calls the mutator helpers below.
   255	    #
   490	    SEL sel = sel_registerName("makeToggleButtonWithLabel:overrides:actionToken:");
   491	    return ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
   492	        cls, sel, apsk_nsstring(label), (id)overrides, action_token);
   493	}
   494	
   495	void *apsk_make_list_view(const void *child_views, int child_count,
   496	                          void *overrides) {
   497	    Class cls = objc_getClass("APSKListViewFacade");
   498	    if (cls == nil) return NULL;
   499	    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
   500	    SEL sel = sel_registerName("makeListViewWithChildViews:overrides:");
   501	    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
   502	        cls, sel, children, (id)overrides);
   503	}
   504	
   505	// ---------------------------------------------------------------------------
   506	// Glass facade trampoline. Phase 3 "headline visual differentiator" — the
   507	// Swift facade routes through `.glassEffect()` on iOS 26 / macOS 26 and
   508	// falls back to `.background(<Material>)` on the pre-26 OSes.
   509	// ---------------------------------------------------------------------------
   510	void *apsk_make_glass_background(void *overrides, void *child_view) {
   511	    Class cls = objc_getClass("APSKGlassBackgroundFacade");
   512	    if (cls == nil) return NULL;
   513	    SEL sel = sel_registerName("makeGlassBackgroundWithOverrides:childView:");
   514	    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
   515	        cls, sel, (id)overrides, (id)child_view);
   516	}
   517	
   518	// ---------------------------------------------------------------------------
   519	// Helper: build an NSArray<NSString*> from a C array of UTF-8 strings.
   520	// Used by Picker / RadioGroup / SegmentedControl facades whose options are

exec
/bin/zsh -lc "nl -ba /Users/crimsonknight/.codex/memories/MEMORY.md | sed -n '132,170p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
   132	applies_to: cwd=/Users/crimsonknight/personal_coding_projects; reuse_rule=reuse for Asset Pipeline planning/handoff work that originated from the planning context here, but treat repo-path, branch, and worktree-status details as checkout-specific and revalidate against /Users/crimsonknight/open_source_coding_projects/asset_pipeline before implementation.
   133	
   134	## Task 1: Critique and harden the Asset Pipeline implementation plan, outcome success
   135	
   136	### rollout_summary_files
   137	
   138	- rollout_summaries/2026-05-07T12-14-56-b2nZ-asset_pipeline_plan_critique_and_agent_handoff_prompt.md (cwd=/Users/crimsonknight/personal_coding_projects, rollout_path=/Users/crimsonknight/.codex/sessions/2026/05/07/rollout-2026-05-07T08-14-56-019e025c-cb3c-7bb1-9aba-3ca4b2f2592f.jsonl, updated_at=2026-05-07T15:45:33+00:00, thread_id=019e025c-cb3c-7bb1-9aba-3ca4b2f2592f, corrected repo/scope/dependency assumptions and upgraded validation language)
   139	
   140	### keywords
   141	
   142	- asset_pipeline, /Users/crimsonknight/open_source_coding_projects/asset_pipeline, happy_coach/lib/asset_pipeline, milestone one is web only, vanilla JS only, no Stimulus, external font CDNs are allowed, validation matrix, pre-flight packet, acceptance evidence, screenshot critique
   143	
   144	## Task 2: Write a copy-paste implementation-agent prompt, outcome success
   145	
   146	### rollout_summary_files
   147	
   148	- rollout_summaries/2026-05-07T12-14-56-b2nZ-asset_pipeline_plan_critique_and_agent_handoff_prompt.md (cwd=/Users/crimsonknight/personal_coding_projects, rollout_path=/Users/crimsonknight/.codex/sessions/2026/05/07/rollout-2026-05-07T08-14-56-019e025c-cb3c-7bb1-9aba-3ca4b2f2592f.jsonl, updated_at=2026-05-07T15:45:33+00:00, thread_id=019e025c-cb3c-7bb1-9aba-3ca4b2f2592f, handoff prompt captured final constraints and reporting contract)
   149	
   150	### keywords
   151	
   152	- the prompt that I can hand to an agent, copy-paste-ready prompt, two-agent model, phase reporting, changed files, tests passed/failed, screenshot locations, design choices, remaining work, blockers, no waiting for visual references
   153	
   154	## User preferences
   155	
   156	- when reviewing implementation plans, the user asked to focus on whether "success criteria and validation steps were clear" -> translate plans into concrete gates, evidence tables, and explicit acceptance checks instead of high-level prose [Task 1]
   157	- when scoping Asset Pipeline work, the user corrected: "milestone one is web only" -> default to web-first scope and defer native follow-on work unless the user expands scope [Task 1]
   158	- when choosing client-side implementation style, the user said "vanilla JS only" and "no Stimulus" -> use plain JS helpers and avoid framework-specific helpers unless the user reopens that constraint [Task 1]
   159	- when deciding compatibility targets, the user said "I don't wanna have to support old browser behavior that's five years out of date" -> assume modern browsers and do not spend effort on legacy-browser support by default [Task 1]
   160	- when handling fonts, the user said "external font CDNs are allowed" but also wanted self-hosting flexibility -> preserve both delivery paths rather than forcing one [Task 1]
   161	- when charts come up, the user was unsure and preferred first-party rendering if possible -> avoid hard chart dependencies unless there is a clear justification [Task 1]
   162	- when discussing existing UI examples, the user said the component API can break because the project is still alpha -> legacy Bootstrap-ish examples may be upgraded or deprecated instead of treated as sacred compatibility surface [Task 1]
   163	- when design references were discussed, the user said they have no visual references and are making the taste "as we go" -> do not block on mood boards; build taste iteratively from first principles plus critique [Task 1][Task 2]
   164	- when handing work to another agent, the user asked for "the prompt that I can hand to an agent" -> provide copy-paste-ready delegation text rather than a summary of what the prompt should contain [Task 2]
   165	- when delegating implementation, the user wanted the agent to go "as much as it possibly can" -> shape prompts for ambitious end-to-end progress with disciplined phase reporting and explicit remaining-risk reporting [Task 2]
   166	- when assessing progress, the user asked the agent to justify outcomes as it goes -> require written reasoning for why a phase is acceptable, not only artifacts [Task 1][Task 2]
   167	
   168	## Reusable knowledge
   169	
   170	- The canonical Asset Pipeline repo for future implementation is `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`; `/Users/crimsonknight/personal_coding_projects/happy_coach/lib/asset_pipeline` was explicitly rejected as the wrong source tree [Task 1]

codex
**Short Verdict**

No. I would not sign the draft as a clean `PASS`.

It correctly captures the web tokenization, the material token model, Android source-side helper path, and the `80 pending` count. But it misses material contract drift on Apple, overstates I-8, and treats thin pending specs as stronger probe contracts than they are.

**Main Misses**

1. **Apple Phase 5 does not actually preserve the brief’s material-step contract on iOS/macOS 26+.**  
   `uikit_renderer` / `appkit_renderer` compute `apple_step`, but [GlassBackgroundFacade.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:64) discards `material` on the 26+ path and always renders `.glassEffect()`. The code even documents that all five declared steps are intentionally uniform on 26+ at [GlassBackgroundFacade.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:42). That conflicts with I-1’s visible per-step / intensity-change claim in [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:39).

2. **`.chromeMaterial` is a real contract break, not a documented degradation.**  
   The brief claims `.chromeMaterial` in A1 and adapter cardinality at [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:202) and [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:287). Actual production maps `:chrome` to `"ultraThick"` in [swiftkit_overrides.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/native/swiftkit_overrides.cr:629), then `.ultraThickMaterial` in [GlassBackgroundFacade.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:53). The untracked spike uses `.bar`, not `.chromeMaterial`, at [spikes/swiftui_material_spike.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spikes/swiftui_material_spike.swift:43). Amend the brief or fail the contract.

3. **I-8 should not be `PASS-with-note`; it is partial at best.**  
   The brief says high contrast must either suppress translucency or strengthen contrast tokens at [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:142). The implementation has no material-specific `prefers-reduced-motion`, `forced-colors`, or high-contrast path. SwiftUI delegation is plausible for Apple, but web/Android are not covered. Pending probes are not implementation.

4. **One “preserves” likely should be `extends`: I-7.**  
   There is a new Android JNI bridge mutating a view via `android_view_apply_glass` and local-ref/exception handling in [android_bridge.c](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/native/android_bridge.c:1483). No retained handle was added, so the implementation may be fine, but the invariant should force ownership proof. Calling it pure `preserves` hides new native ownership surface.

5. **The “all glass surfaces” architectural concern is real.**  
   The implementation brief required tokenizing other hard-coded glass surfaces at [implementation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:85). Actual AppKit still has hard-coded `setMaterial:` constants, e.g. [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:861), [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:2168), and [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:3744). If `brief.yml` alone is authoritative, this is scope drift; if `implementation.md` is binding, it is a fail.

**Probe Specs**

The six probe files are not completely vacuous: they declare slugs, pending cells, and identifier conventions, and `crystal spec spec/ui/glass_material` reports `80 examples, 80 pending`.

But they are uneven. The default and contrast specs are decent placeholders. The env-response specs are weak: [macos_glass_env_response_spec.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spec/ui/glass_material/macos_glass_env_response_spec.cr:11) has empty pending bodies, and the iOS high-contrast/dark-mode cells are mostly one-line comments at [ios_glass_env_response_spec.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spec/ui/glass_material/ios_glass_env_response_spec.cr:38). I would call them “placeholder-shaped, but not strong enough for the new forcing function.”

**Three Concerns**

1. `.chromeMaterial`: contract break unless brief is amended to `.ultraThickMaterial` or `.bar`.
2. I-8 delegation: insufficient as an `extends` PASS; make it partial/fail or explicitly defer web/Android high-contrast behavior.
3. macOS AX/TCC: do not chase signing first. The right control is rerun from an Accessibility-authorized runner. Re-signing can change TCC identity and add noise.

One more validation note: the exact brief validator command did not pass here. With writable Crystal cache it failed A1 because Swift wrote module cache under `~/.cache/clang`. The Swift spike compiles when forced to `/private/tmp`, but the spike is untracked and does not prove `.chromeMaterial`.


tokens used
158,159
**Short Verdict**

No. I would not sign the draft as a clean `PASS`.

It correctly captures the web tokenization, the material token model, Android source-side helper path, and the `80 pending` count. But it misses material contract drift on Apple, overstates I-8, and treats thin pending specs as stronger probe contracts than they are.

**Main Misses**

1. **Apple Phase 5 does not actually preserve the brief’s material-step contract on iOS/macOS 26+.**  
   `uikit_renderer` / `appkit_renderer` compute `apple_step`, but [GlassBackgroundFacade.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:64) discards `material` on the 26+ path and always renders `.glassEffect()`. The code even documents that all five declared steps are intentionally uniform on 26+ at [GlassBackgroundFacade.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:42). That conflicts with I-1’s visible per-step / intensity-change claim in [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:39).

2. **`.chromeMaterial` is a real contract break, not a documented degradation.**  
   The brief claims `.chromeMaterial` in A1 and adapter cardinality at [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:202) and [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:287). Actual production maps `:chrome` to `"ultraThick"` in [swiftkit_overrides.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/native/swiftkit_overrides.cr:629), then `.ultraThickMaterial` in [GlassBackgroundFacade.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:53). The untracked spike uses `.bar`, not `.chromeMaterial`, at [spikes/swiftui_material_spike.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spikes/swiftui_material_spike.swift:43). Amend the brief or fail the contract.

3. **I-8 should not be `PASS-with-note`; it is partial at best.**  
   The brief says high contrast must either suppress translucency or strengthen contrast tokens at [brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:142). The implementation has no material-specific `prefers-reduced-motion`, `forced-colors`, or high-contrast path. SwiftUI delegation is plausible for Apple, but web/Android are not covered. Pending probes are not implementation.

4. **One “preserves” likely should be `extends`: I-7.**  
   There is a new Android JNI bridge mutating a view via `android_view_apply_glass` and local-ref/exception handling in [android_bridge.c](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/native/android_bridge.c:1483). No retained handle was added, so the implementation may be fine, but the invariant should force ownership proof. Calling it pure `preserves` hides new native ownership surface.

5. **The “all glass surfaces” architectural concern is real.**  
   The implementation brief required tokenizing other hard-coded glass surfaces at [implementation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:85). Actual AppKit still has hard-coded `setMaterial:` constants, e.g. [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:861), [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:2168), and [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:3744). If `brief.yml` alone is authoritative, this is scope drift; if `implementation.md` is binding, it is a fail.

**Probe Specs**

The six probe files are not completely vacuous: they declare slugs, pending cells, and identifier conventions, and `crystal spec spec/ui/glass_material` reports `80 examples, 80 pending`.

But they are uneven. The default and contrast specs are decent placeholders. The env-response specs are weak: [macos_glass_env_response_spec.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spec/ui/glass_material/macos_glass_env_response_spec.cr:11) has empty pending bodies, and the iOS high-contrast/dark-mode cells are mostly one-line comments at [ios_glass_env_response_spec.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spec/ui/glass_material/ios_glass_env_response_spec.cr:38). I would call them “placeholder-shaped, but not strong enough for the new forcing function.”

**Three Concerns**

1. `.chromeMaterial`: contract break unless brief is amended to `.ultraThickMaterial` or `.bar`.
2. I-8 delegation: insufficient as an `extends` PASS; make it partial/fail or explicitly defer web/Android high-contrast behavior.
3. macOS AX/TCC: do not chase signing first. The right control is rerun from an Accessibility-authorized runner. Re-signing can change TCC identity and add noise.

One more validation note: the exact brief validator command did not pass here. With writable Crystal cache it failed A1 because Swift wrote module cache under `~/.cache/clang`. The Swift spike compiles when forced to `/private/tmp`, but the spike is untracked and does not prove `.chromeMaterial`.


