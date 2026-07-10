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
session id: 019e514c-dccb-71e0-b9f6-62b4795105d8
--------
user
Read /tmp/p5-v2-validator-draft.md plus docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md plus docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml. Are the brief amendments truthful (do they match the shipped implementation)? Is R3's tokenization semantically correct? Is the legacy-debt handoff doc a legitimate escalation per implementation.md:85, or does it normalize unauthorized scope drift? STOP if you find a contract claim the implementation still doesn't honor. Be specific with file:line citations.
codex
I’ll first do the lightweight memory lookup because this is in the Asset Pipeline repo, then I’ll read the three requested docs plus the implementation contract around `implementation.md:85` and compare those claims against the shipped files.
exec
/bin/zsh -lc 'rg -n "phase-05|glass material|legacy-debt|initiative-cross-platform-ui|asset_pipeline|validation matrix|milestone one is web only" /Users/crimsonknight/.codex/memories/MEMORY.md' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
132:applies_to: cwd=/Users/crimsonknight/personal_coding_projects; reuse_rule=reuse for Asset Pipeline planning/handoff work that originated from the planning context here, but treat repo-path, branch, and worktree-status details as checkout-specific and revalidate against /Users/crimsonknight/open_source_coding_projects/asset_pipeline before implementation.
138:- rollout_summaries/2026-05-07T12-14-56-b2nZ-asset_pipeline_plan_critique_and_agent_handoff_prompt.md (cwd=/Users/crimsonknight/personal_coding_projects, rollout_path=/Users/crimsonknight/.codex/sessions/2026/05/07/rollout-2026-05-07T08-14-56-019e025c-cb3c-7bb1-9aba-3ca4b2f2592f.jsonl, updated_at=2026-05-07T15:45:33+00:00, thread_id=019e025c-cb3c-7bb1-9aba-3ca4b2f2592f, corrected repo/scope/dependency assumptions and upgraded validation language)
142:- asset_pipeline, /Users/crimsonknight/open_source_coding_projects/asset_pipeline, happy_coach/lib/asset_pipeline, milestone one is web only, vanilla JS only, no Stimulus, external font CDNs are allowed, validation matrix, pre-flight packet, acceptance evidence, screenshot critique
148:- rollout_summaries/2026-05-07T12-14-56-b2nZ-asset_pipeline_plan_critique_and_agent_handoff_prompt.md (cwd=/Users/crimsonknight/personal_coding_projects, rollout_path=/Users/crimsonknight/.codex/sessions/2026/05/07/rollout-2026-05-07T08-14-56-019e025c-cb3c-7bb1-9aba-3ca4b2f2592f.jsonl, updated_at=2026-05-07T15:45:33+00:00, thread_id=019e025c-cb3c-7bb1-9aba-3ca4b2f2592f, handoff prompt captured final constraints and reporting contract)
157:- when scoping Asset Pipeline work, the user corrected: "milestone one is web only" -> default to web-first scope and defer native follow-on work unless the user expands scope [Task 1]
170:- The canonical Asset Pipeline repo for future implementation is `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`; `/Users/crimsonknight/personal_coding_projects/happy_coach/lib/asset_pipeline` was explicitly rejected as the wrong source tree [Task 1]
182:- Symptom: plan language sounds polished but the user still cannot tell what proves success. Cause: qualitative success criteria and vague labels like "pre-flight packet" or "validation matrix". Fix: replace jargon with plain operational headings such as checklist and acceptance table, and specify the evidence expected for each phase [Task 1]
184:- Symptom: a prompt or plan accidentally hard-codes the wrong repo assumption. Cause: drafting against stale earlier notes. Fix: reassert the corrected canonical repo path in the final prompt and, when useful, explicitly say not to implement in `happy_coach/lib/asset_pipeline` [Task 2]

exec
/bin/zsh -lc "rg --files -g 'AGENTS.md' -g 'implementation.md' -g 'brief.yml' -g '*.md' docs/initiative-cross-platform-ui /tmp/p5-v2-validator-draft.md" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
/tmp/p5-v2-validator-draft.md
docs/initiative-cross-platform-ui/start-architect.md
docs/initiative-cross-platform-ui/rubric/gate_report_schema.md
docs/initiative-cross-platform-ui/rubric/implementation_criteria.md
docs/initiative-cross-platform-ui/rubric/trust_pair_protocol.md
docs/initiative-cross-platform-ui/rubric/behavior-simulation-toolkit.md
docs/initiative-cross-platform-ui/rubric/validation_criteria.md
docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/README.md
docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/validation.md
docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/implementation.md
docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/validation.stale-pre-2026-05-22.md
docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/implementation.stale-pre-2026-05-22.md
docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/README.md
docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/validation.md
docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/implementation.md
docs/initiative-cross-platform-ui/system-prompt.md
docs/initiative-cross-platform-ui/MASTER_PLAN.md
docs/initiative-cross-platform-ui/phases/phase-04-platform-tier-gating/implementation.md
docs/initiative-cross-platform-ui/phases/phase-04-platform-tier-gating/README.md
docs/initiative-cross-platform-ui/phases/phase-04-platform-tier-gating/validation.md
docs/initiative-cross-platform-ui/tier-matrix.md
docs/initiative-cross-platform-ui/origin.md
docs/initiative-cross-platform-ui/phases/phase-02-responsive-web-fluid-resize/README.md
docs/initiative-cross-platform-ui/phases/phase-02-responsive-web-fluid-resize/validation.md
docs/initiative-cross-platform-ui/phases/phase-02-responsive-web-fluid-resize/implementation.md
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/README.md
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/README.md
docs/initiative-cross-platform-ui/phases/phase-06.5-audit-infrastructure-first/README.md
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/validation.md
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/validation.md
docs/initiative-cross-platform-ui/handoff/phase-01-reflection-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-01-architect-scope-deferral-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03-iter4-2026-05-21.md
docs/initiative-cross-platform-ui/handoff/phase-02-dispatch-templates-draft.md
docs/initiative-cross-platform-ui/handoff/phase-03-remediation-5-blockers-2026-05-21.md
docs/initiative-cross-platform-ui/handoff/phase-04-passed-2026-05-22.md
docs/initiative-cross-platform-ui/handoff/planning-retrospective-2026-05-22.md
docs/initiative-cross-platform-ui/handoff/phase-03-reflection-2026-05-21.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter7/README.md
docs/initiative-cross-platform-ui/handoff/phase-04-evidence-2026-05-22-iter2/inspections/r1-r2-deviations-verified.md
docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20-iter2/README.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter4/README.md
docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/codex_reviews/checkpoint3-family-C-accessibility.md
docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/codex_reviews/checkpoint3-family-A-action-sheet.md
docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/codex_reviews/checkpoint4-final-premerge.md
docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/codex_reviews/checkpoint3-family-B-context-menu.md
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/README.md
docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20/README.md
docs/initiative-cross-platform-ui/handoff/phase-02-passed-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/README.md
docs/initiative-cross-platform-ui/handoff/plan-quality-audit-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03-failing-1-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03-failing-2-2026-05-21.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20-iter2/README.md
docs/initiative-cross-platform-ui/handoff/phase-03-state-2026-05-21-codex-context.md
docs/initiative-cross-platform-ui/handoff/phase-02-failing-1-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03-iter3-2026-05-21.md
docs/initiative-cross-platform-ui/handoff/phase-01-passed-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/architect-dispatch-collapse-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03a-stopped-early-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-04-reflection-2026-05-22.md
docs/initiative-cross-platform-ui/handoff/phase-02-reflection-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-01-failing-1-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03-passed-2026-05-21.md
docs/initiative-cross-platform-ui/handoff/phase-03-remediation-8-bx3-bx8-investigation.md
docs/initiative-cross-platform-ui/handoff/phase-04-implementer-deviations.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/README.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/diagnostic/r10-evidence-toggle.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/diagnostic/r10-codex-prefix-sheet.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/diagnostic/r10-codex-postdiag-sheet.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/diagnostic/r10-evidence-sheet.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/diagnostic/r10-codex-postfix.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/diagnostic/r10-codex-prefix-toggle.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-r10/diagnostic/r10-codex-postdiag-toggle.md
docs/initiative-cross-platform-ui/handoff/stock-taking-2026-05-22.md
docs/initiative-cross-platform-ui/handoff/phase-03-stopped-early-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/downstream-phase-audit-status-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03b-returned-2026-05-20.md
docs/initiative-cross-platform-ui/handoff/phase-03-remediation-3-blockers-2026-05-21.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20/README.md
docs/initiative-cross-platform-ui/handoff/phase-03-remediation-9-bx3-bx8-rootcause.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter5/README.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter6/README.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter6/crash_logs/CRASH_SUMMARY.md
docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter3/README.md
docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/codex/p5-validator-draft.md
docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/codex/p5-validator-codex-critique.md

exec
/bin/zsh -lc 'pwd && git status --short' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
/Users/crimsonknight/open_source_coding_projects/asset_pipeline
 M docs/initiative-cross-platform-ui/MASTER_PLAN.md
 M docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter5/screenshots/BX2-final.png
 M docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter5/screenshots/BX7-form-rendered.png
 M docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md
 M docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml
 M docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/README.md
 M docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/README.md
 M docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/implementation.md
 M docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/validation.md
 M spec/test_js/some_js.js
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md
?? docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/
?? docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter2/
?? docs/initiative-cross-platform-ui/handoff/planning-retrospective-2026-05-22.md
?? docs/initiative-cross-platform-ui/handoff/stock-taking-2026-05-22.md
?? docs/initiative-cross-platform-ui/phases/phase-06.5-audit-infrastructure-first/
?? docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/implementation.stale-pre-2026-05-22.md
?? docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/validation.stale-pre-2026-05-22.md
?? docs/initiative-cross-platform-ui/schemas/
?? scripts/validate_phase_brief.cr
?? spikes/

codex
The worktree is dirty, including the Phase 5 brief and the legacy-debt handoff doc. I’m treating those as existing user/prior-agent changes and only reading them for the audit.
exec
/bin/zsh -lc 'nl -ba /tmp/p5-v2-validator-draft.md' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	# Phase 5 Validator iter 2 — DRAFT verdict
     2	
     3	**Branch:** phase-05-glass-material-tokenization @ f081205 (R3 closing commit)
     4	**Date:** 2026-05-22
     5	**Validator:** Phase 5 iter 2 Validator
     6	
     7	## Draft Verdict: PASS (with one environmental block for BX2/BX7 noted)
     8	
     9	## Headline numbers
    10	- Brief validator: PASS (exit 0, 11 invariants, 6 facts, 6 assumptions verified)
    11	- Per-invariant: 11/11 honored per amended declarations
    12	- Contract decisions: 3 adapter_cardinality rows verified; A1 spike compiles iOS + macOS
    13	- Prior-phase regression: Phase 3 iOS 10/10 PASS; Phase 4 CDP 12 probes any_failed=false; swift test 53/53 PASS; crystal spec 1447 examples / 4 baseline failures (unchanged) / 80 pending placeholders; web + macOS + iOS sim cross-builds PASS
    14	- Phase 3 macOS AXTest BX2 + BX7: BLOCKED-ENVIRONMENTAL (TCC accessibility revoked; sqlite3 confirms `com.apple.Terminal | kTCCServiceAccessibility | auth_value=0`)
    15	
    16	## Brief amendment verification (per amended invariant)
    17	
    18	### I-1 (extends) — amended: iOS 26+ uses .glassEffect() step-agnostic; controllable on pre-26 + web + Android
    19	**Code match: TRUE.** `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift` lines 64-77:
    20	- `if #available(iOS 26.0, macOS 26.0, *) { ... .glassEffect() }` with explicit comment `// pre-26 only; unused on the Liquid Glass path` next to `_ = material`
    21	- pre-26 path uses `.background(material)` with the resolved step
    22	- Material switch at lines 53-61 maps the 5 step names; `:chrome` is implied (default case → `.regularMaterial`); the explicit `:chrome → .ultraThickMaterial` mapping lives in spike/adapter_cardinality, the GlassBackground facade itself ships `.ultraThinMaterial`/`.thinMaterial`/`.regularMaterial`/`.thickMaterial`/`.ultraThickMaterial`
    23	
    24	### I-7 (extends) — amended: android_view_apply_glass is borrow-not-retain
    25	**Code match: TRUE.** `src/ui/native/android_bridge.c` lines 1483-1503:
    26	- Function takes `view` as a raw `void*`; never wraps in `NewGlobalRef`
    27	- Only ref management is `DeleteLocalRef(env, helper_cls)` for the FindClass result it owns
    28	- Returns scalar `int32_t` (1 / 0); no Crystal-side state retained
    29	- Calls `AssetPipelineGlassHelper.applyGlass(view, blur_radius, fallback_argb)` and returns. View ownership stays with the caller (the `android_renderer.cr` visit method).
    30	
    31	### I-8 (preserves) — amended: Phase 5 ships no production cross-platform forced-colors / prefers-reduced-motion code
    32	**Code match: TRUE.** `grep -n 'prefers-reduced-motion|forced-colors|prefers-contrast' src/ui/renderers/web_renderer.cr src/ui/design_tokens.cr` → 0 hits. `grep -rn ... src/ui/` → 0 hits. Apple delegates to system via SwiftUI Material + .glassEffect(); pending placeholder specs at `spec/ui/glass_material/*_env_response_spec.cr` document the slug names Phase 6.5 will hook.
    33	
    34	### I-10 (extends) — amended: SwiftUI Material's discrete enum quantizes intensity; web @supports + Android API<31 alpha fallback
    35	**Code match: TRUE.** Per A1 spike compile (iOS + macOS exit 0). Brief A1 prose has a minor doc-text drift (says "spike uses .bar" but spike actually uses `.ultraThickMaterial` for `:chrome`); falsifier (compile both targets) still passes and substantive claim (`.chromeMaterial` doesn't exist in public SwiftUI; map :chrome to .ultraThickMaterial) is what's shipped.
    36	
    37	### A1 (lower_layer_assumption) — amended: spike uses .ultraThickMaterial for :chrome
    38	**Code match: TRUE for substance; minor TEXT drift.** A1 verification runs `swiftc -emit-library` on both iOS sim + macOS SDKs; both exit 0. The amendment text says "spike uses .bar" but the actual spike code uses `.ultraThickMaterial` (line 47 of spikes/swiftui_material_spike.swift). The amendment's prior sentence ALSO says "Phase 5's :chrome step maps to .ultraThickMaterial (or .bar where chrome-tinted styling is wanted)" — so .ultraThickMaterial IS the documented primary mapping. The "spike uses .bar" trailing sentence is a doc-text artifact; falsifier honors the substantive claim. NOT a blocker.
    39	
    40	## R3 verification (3 sites tokenized? helper exists? 5 legacy hits confined?)
    41	
    42	**3 named R3 sites tokenized:** TRUE.
    43	- NavigationSplitView `_legacy_navigation_split_view` is NOT the site R3 closed; R3 closed the ACTIVE NavigationSplitView visit. grep -n setMaterial: shows `appkit_visual_effect_material(sidebar_step)` at line 1836-1838 in the active visit method.
    44	- ContextMenu `appkit_renderer.cr` lines 2830-2832: `appkit_visual_effect_material(menu_step)` then `objc_send_long(effect, sel("setMaterial:"), menu_material)` with `# :menu -> NSVisualEffectMaterialMenu (5)` marker
    45	- ActivityView `appkit_renderer.cr` lines 3768-3770: `appkit_visual_effect_material(activity_step)` then `objc_send_long(..., activity_material)` with `# :thick -> NSVisualEffectMaterialSheet (11)` marker
    46	
    47	**Helper exists at the reported location:** TRUE.
    48	`appkit_renderer.cr` lines 4695-4709: `private def appkit_visual_effect_material(step : Symbol) : Int64` with the required marker comment "AppKit material translation table — only allowed hard-coded glass switch" — narrowed to only the 3 consumed Symbols (`:thin`, `:thick`, `:menu`) plus the safe default `10_i64`.
    49	
    50	**5 remaining legacy hits confined to `_legacy_*` methods:** TRUE.
    51	- line 861: `_legacy_tab_view` (TabView)
    52	- line 1093: `_legacy_alert` (Alert)
    53	- line 2000: `_legacy_toolbar` (Toolbar)
    54	- line 2178: `_legacy_sheet` (Sheet)
    55	- line 2335: `_legacy_popover` (Popover)
    56	
    57	Exactly matches the architect handoff doc's claim. No leakage into active visit paths.
    58	
    59	## Handoff doc verification
    60	
    61	`docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md` EXISTS (47 lines).
    62	
    63	The doc:
    64	1. Names all 5 `_legacy_*` methods with line numbers (Tab/Alert/Toolbar/Sheet/Popover).
    65	2. Cites `implementation.md` lines 85-89 as the formal escalation clause.
    66	3. Provides 3 cleanup options (delete dead code / migrate to facade / extend helper) for Phase 6.5+.
    67	4. Architect-acknowledged out-of-scope with explicit reasoning (none on active visit path; widget facade migration is its own phase; no consumer-visible regression risk).
    68	
    69	`implementation.md` line 89 reads: "If during implementation you discover this would balloon the diff beyond a reasonable single-phase scope (more than ~12 visit methods to refactor), stop and return to the team lead with what you found rather than picking an arbitrary subset." This handoff doc IS that "stop and return" — a legitimate escalation, NOT scope-drift normalization.
    70	
    71	## Prior-phase regression check
    72	
    73	| Check | Status | Evidence |
    74	|---|---|---|
    75	| crystal spec | PASS (regression-free) | 1447 examples / 4 failures / 80 pending — baseline unchanged |
    76	| swift test | PASS | 53/53 |
    77	| web no-codegen build | PASS | exit 0 |
    78	| validate_web_demo | PASS | "Web design-system static audit passed" |
    79	| iOS sim Crystal lib build | PASS | libhighost.a + swiftkit_simulator.a created |
    80	| macOS host build | PASS | bin/hig_showcase built + signed |
    81	| Phase 4 CDP harness | PASS | any_failed=false (12 probes) |
    82	| Phase 3 iOS Phase03BehaviorTests | PASS | 10/10 |
    83	| Phase 3 macOS BX2 + BX7 AXTest | BLOCKED-ENVIRONMENTAL | TCC `com.apple.Terminal kTCCServiceAccessibility auth_value=0` — system-level Accessibility grant has been REVOKED since iter 1 |
    84	
    85	The macOS BX2/BX7 failures are an **environmental** block (TCC), NOT a Phase 5 regression. The showcase binary launches and runs (verified standalone). AXTest cannot read the accessibility tree because Terminal lacks `kTCCServiceAccessibility`. Per iter 1's procedure instruction "TCC granted (re-verify; macOS AXTest specs need it)" — re-verify here surfaces the revocation.
    86	
    87	## Adapter cardinality verification
    88	
    89	A1 spike compiles both targets (iOS sim + macOS). 3 adapter_cardinality rows valid per brief validator output (`all required fields present; MISMATCH rows have degradation + approval`).
    90	
    91	## What this verdict says
    92	
    93	PASS — all 11 invariants honored per their (amended) declarations, R3 closed the 3 named sites, the helper exists and is correctly narrowed, the 5 legacy hits are properly confined and architect-escalated via a legitimate handoff doc. The amendments to I-1/I-7/I-8/I-10/A1 match the shipped implementation. Prior-phase non-environmental baselines hold.
    94	
    95	The macOS AXTest BX2+BX7 blocker is environmental (TCC accessibility grant revoked; not a Phase 5 regression). The reviewer should grant Terminal accessibility before re-running iter 3 if there's a future iter 3; for THIS verdict it is recorded as environmental and not blocking PASS.
    96	
    97	Minor doc-text drift in A1's "spike uses .bar" trailing sentence (actual spike uses `.ultraThickMaterial`) is recommended for a one-line amendment fix but not a blocker — falsifier passes.

exec
/bin/zsh -lc 'nl -ba docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	# Phase 5 — AppKit Legacy `setMaterial:` Known-Debt — 2026-05-22
     2	
     3	**Status:** Architect-acknowledged out-of-scope; carry-forward to Phase 6.5+ cleanup.
     4	
     5	## What
     6	
     7	After Phase 5 R3 closed the 3 Codex-named AppKit `setMaterial:` scope-drift sites (NavigationSplitView 1828, ContextMenu 2813, ActivityView 3744), `grep -n 'setMaterial:' src/ui/renderers/appkit_renderer.cr` still surfaces **5 additional raw-integer `setMaterial:` calls** in `_legacy_*` methods:
     8	
     9	| File:line range | Method | Hard-coded material |
    10	|---|---|---|
    11	| `_legacy_tab_view` | `_legacy_*` | Integer literal |
    12	| `_legacy_alert` | `_legacy_*` | Integer literal |
    13	| `_legacy_toolbar` | `_legacy_*` | Integer literal |
    14	| `_legacy_sheet` | `_legacy_*` | Integer literal |
    15	| `_legacy_popover` | `_legacy_*` | Integer literal |
    16	
    17	(Exact line numbers shift with edits; grep at HEAD `f081205` for the current set.)
    18	
    19	## Why these were not closed by R3
    20	
    21	R3's named scope was only the 3 active-visit-path sites Codex identified (NavigationSplitView/ContextMenu/ActivityView). The 5 above live in `_legacy_*` methods that are NOT invoked from the active dispatch path; they're preserved as historical references for the facade migration. Per Phase 5 R3's Codex pre-merge critique, the active widgets in this list (TabView/Alert/Toolbar/Sheet/Popover) all route through the SwiftKit facade now via `apsk_make_*` paths — the `_legacy_*` body is dead code for runtime purposes.
    22	
    23	Per `implementation.md` lines 85–89 (tokenize every hard-coded material site OR escalate), this is the formal escalation handoff. Architect's reasoning for acknowledging as out-of-scope:
    24	
    25	1. **Not runtime-active.** None of the 5 `_legacy_*` methods is on the active `visit(...)` dispatch path. Removing or tokenizing them is dead-code cleanup, not behavioral change.
    26	2. **Phase 5's actual architecture diverged from implementation.md's translation-table envisioning.** Implementation.md L555–569 imagined a UIKit→AppKit material-integer translation table. Phase 5 actually shipped SwiftKit facade enum routing — a more modern Swift-side approach. The R3 Symbol→NSVisualEffectMaterial helper is narrow (3 step values) by intent; broadening it for the 5 legacy methods would require either expanding the helper artificially OR migrating those methods to the SwiftKit facade path (which would be Phase 5 facade-migration work, not Phase 5 material-tokenization work).
    27	3. **No consumer-visible regression risk.** The 5 sites are not on user-reachable code paths in the current renderer.
    28	
    29	## What Phase 6.5+ must decide
    30	
    31	When Phase 6.5 (audit infrastructure) ships or when a future cleanup phase touches the AppKit legacy methods:
    32	
    33	- **Option A:** Delete the 5 `_legacy_*` methods entirely (they're dead code by Phase 5's facade migration).
    34	- **Option B:** Migrate them to the SwiftKit facade path so they share the same material tokenization as the active path. Useful if these methods are intended as fallbacks for some flag-gated condition (verify; currently the architect believes they're not).
    35	- **Option C:** Extend the R3 `appkit_visual_effect_material(step : Symbol) : Int64` helper with the additional Symbol mappings these legacy sites need + tokenize them via the helper. Lowest blast radius; preserves the dead code without expanding the Symbol space artificially.
    36	
    37	Architect's recommendation: **Option A** (delete dead code) during whichever cleanup phase touches AppKit. Failing that, Option C as a 30-minute mechanical edit.
    38	
    39	## Validator scope for Phase 5 iter 2
    40	
    41	Phase 5 Validator iter 2 should treat these 5 hits as **architect-adjudicated known-debt**: `_legacy_*` methods are out of Phase 5's named scope; this handoff doc is the formal escalation per `implementation.md:85`. The validator confirms the doc exists + that the 5 hits are confined to `_legacy_*` methods (no leakage into active visit paths).
    42	
    43	## Carry-forward marker
    44	
    45	When Phase 6.5+ closes these, append a "Closed YYYY-MM-DD by Phase N commit SHA" line below.
    46	
    47	(Currently open.)

exec
/bin/zsh -lc 'nl -ba docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	phase:
     2	  number: 5
     3	  name: "Glass Material Tokenization"
     4	  branch: "phase-05-glass-material-tokenization"
     5	  parent_branch: "feature/utility-first-css-asset-pipeline"
     6	  parent_sha: "2285fa1"
     7	  authored_at: "2026-05-22"
     8	
     9	# Phase 5 contract decisions baked into this brief (per Codex round-2 antagonist
    10	# review of brief draft 1):
    11	#
    12	# 1. Material tokens are render-time resolved values. `tokens.material.intensity`
    13	#    is a brand-declaration-time scalar; consumers re-render to see changes.
    14	#    I-2 (forward reactive) is therefore `preserves` — Phase 5 does NOT add a
    15	#    runtime mutator path for material. I-10 (API contract fidelity) documents
    16	#    this as the contract limitation.
    17	#
    18	# 2. SwiftUI's discrete Material enum quantizes the Float64 intensity scalar.
    19	#    Documented in adapter_cardinality with the exact quantization table.
    20	#
    21	# 3. Android renderer code lands in Phase 5 (the Crystal-side RenderEffect
    22	#    emission). Android probe verification is Phase 6.5's responsibility
    23	#    per the audit-first lesson. Brief reflects this: Android cells `extends`
    24	#    with skip records explaining the implementation lands here, verification
    25	#    later.
    26	#
    27	# 4. SwiftUI Material API assumption verified via a Swift compile spike at
    28	#    spikes/swiftui_material_spike.swift (architect authored 2026-05-22).
    29	#
    30	# 5. Phase 5 does NOT introduce new ObservableObjects, new C-export mutators,
    31	#    or new retained state handles on the Swift side. If implementation
    32	#    discovers reactive material is needed, scope expansion surfaces to
    33	#    architect before extending.
    34	
    35	invariant_matrix:
    36	  - id: I-1
    37	    name: "Render correctly"
    38	    touch: extends
    39	    rationale: "Phase introduces tokenized blur/opacity/saturation/luminance values per material step + an intensity scalar. AMENDED 2026-05-22 per Codex resolution review: iOS 26+ / macOS 26+ use SwiftUI .glassEffect() which is SYSTEM-RESOLVED — material step and intensity become advisory only on the Liquid Glass path. Step+intensity ARE enforced on the pre-26 fallback .background(.material) path AND on web (backdrop-filter scaled by intensity) AND on Android (RenderEffect radius scaled by intensity API 31+, alpha fallback < API 31). Phase 5 implementer authors the per-step visual baseline probes for the controllable paths."
    40	    probes:
    41	      ios:
    42	        skip: true
    43	        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_default_spec.cr that captures and diffs glass appearance per material step. Probe harness path is Phase 6.5 work; until then validator architect-adjudicates pending Phase 6.5 ship."
    44	        owner_approved: "2026-05-22"
    45	      macos:
    46	        skip: true
    47	        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_default_spec.cr; same as iOS — verification harness is Phase 6.5"
    48	        owner_approved: "2026-05-22"
    49	      web: "crystal-alpha run scripts/validate_web_demo.cr"
    50	      android:
    51	        skip: true
    52	        reason: "Phase 5 ships Android-side RenderEffect emission code; Android empirical verification is Phase 6.5's audit harness deliverable per Phase 1 #17 precedent"
    53	        owner_approved: "2026-05-22"
    54	
    55	  - id: I-2
    56	    name: "Update reactively (forward)"
    57	    touch: preserves
    58	    rationale: "Material tokens are RENDER-TIME RESOLVED VALUES. Phase 5 does NOT add a runtime mutator path for material.intensity. Consumers re-render the view tree to see intensity changes; the existing Phase 3 reactive bridge (Label/Button/Toggle/Slider/Sheet) is unchanged. This is a deliberate contract limitation; see I-10 for the documented API contract."
    59	    probes:
    60	      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
    61	      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
    62	      web: "crystal-alpha run scripts/validate_web_demo.cr"
    63	      android:
    64	        skip: true
    65	        reason: "Android probe harness is Phase 6.5 work per audit-first principle"
    66	        owner_approved: "2026-05-22"
    67	
    68	  - id: I-3
    69	    name: "Dispatch events (backward)"
    70	    touch: preserves
    71	    rationale: "Glass material is a pure render-side concern; no new event paths, no new callback registration, no new main-thread/run-loop semantics introduced. Existing Phase 3 R4 + R10 event paths remain authoritative."
    72	    probes:
    73	      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
    74	      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
    75	      web: "crystal-alpha run scripts/validate_web_demo.cr"
    76	      android:
    77	        skip: true
    78	        reason: "Android probe harness is Phase 6.5"
    79	        owner_approved: "2026-05-22"
    80	
    81	  - id: I-4
    82	    name: "Restore focus"
    83	    touch: preserves
    84	    rationale: "Material tokenization does not change focus order or focus-visible behavior. Glass surfaces remain transparent to focus traversal; child controls retain their focus contract."
    85	    probes:
    86	      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
    87	      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
    88	      web: "crystal-alpha run scripts/validate_web_demo.cr"
    89	      android:
    90	        skip: true
    91	        reason: "Android probe harness is Phase 6.5"
    92	        owner_approved: "2026-05-22"
    93	
    94	  - id: I-5
    95	    name: "Manage lifecycle"
    96	    touch: preserves
    97	    rationale: "GlassBackground widget API unchanged per scope summary; no new mount/unmount/teardown paths. Token-resolution happens during the existing render pass."
    98	    probes:
    99	      ios: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
   100	      macos: "crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr -Dmacos --link-flags=\"-framework ApplicationServices -framework CoreFoundation\""
   101	      web: "crystal-alpha run scripts/validate_web_demo.cr"
   102	      android:
   103	        skip: true
   104	        reason: "Android probe harness is Phase 6.5"
   105	        owner_approved: "2026-05-22"
   106	
   107	  - id: I-6
   108	    name: "Propagate accessibility"
   109	    touch: extends
   110	    rationale: "Glass surfaces sit behind text. WCAG-AA contrast must hold for text-on-blurred-background at every material step AND at every intensity value (including the documented 1.3 brand-override example in the README). This is a NEW audit dimension Phase 5 introduces. Dynamic-type response on glass surfaces also belongs here (text must still meet contrast at largest type sizes). Phase 5 implementer authors the contrast audit probes."
   111	    probes:
   112	      ios:
   113	        skip: true
   114	        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_contrast_spec.cr (text-on-each-material-step AA contrast verification); harness is Phase 6.5"
   115	        owner_approved: "2026-05-22"
   116	      macos:
   117	        skip: true
   118	        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_contrast_spec.cr; harness is Phase 6.5"
   119	        owner_approved: "2026-05-22"
   120	      web: "crystal-alpha run scripts/validate_web_demo.cr"
   121	      android:
   122	        skip: true
   123	        reason: "Android contrast audit harness is Phase 6.5"
   124	        owner_approved: "2026-05-22"
   125	
   126	  - id: I-7
   127	    name: "Manage memory ownership"
   128	    touch: extends
   129	    rationale: "AMENDED 2026-05-22 per Codex resolution review. Phase 5 added one new native mutator on the Android JNI bridge: `android_view_apply_glass`. This is a render-side application (apply blur/effect to a view) — NOT a state-store like Phase 3's APSKLabelState. It does not retain Crystal-side state; it calls into Android RenderEffect.createBlurEffect and returns. Still, by I-7's primary-ownership clause (any value crossing the language boundary needs a contract), this is `extends`, not `preserves`. Ownership contract: caller (Crystal-side android_renderer.cr visit method) owns the view reference; android_view_apply_glass borrows for the duration of the JNI call and does not retain. No new ObservableObjects on Swift side (grep-verified). No new C-export mutators on iOS/macOS bridge."
   130	    probes:
   131	      ios: "spec/asset_pipeline_spec.cr"
   132	      macos: "spec/asset_pipeline_spec.cr"
   133	      web: "spec/asset_pipeline_spec.cr"
   134	      android:
   135	        skip: true
   136	        reason: "Android probe harness is Phase 6.5"
   137	        owner_approved: "2026-05-22"
   138	
   139	  - id: I-8
   140	    name: "Honor environment"
   141	    touch: preserves
   142	    rationale: "AMENDED 2026-05-22 per Codex resolution review. Original brief overclaimed `extends` for env-response. Reality: Phase 5 DELEGATES env-response on Apple platforms — SwiftUI Material + .glassEffect() automatically respect Reduce Motion, Increase Contrast, dark mode. Phase 5 ships no production code for cross-platform forced-colors / prefers-reduced-motion handling on web; that's Phase 6.5's audit harness work. Phase 5 probe placeholders for env_response cells were authored (spec/ui/glass_material/*_env_response_spec.cr) as pending bodies declaring the slug names Phase 6.5 will hook. So I-8 is `preserves` on Apple (system handles it; Phase 5 doesn't intercept) and cross-platform delivery is explicitly deferred to Phase 6.5."
   143	    probes:
   144	      ios: "spec/ui/glass_material/ios_glass_env_response_spec.cr"
   145	      macos: "spec/ui/glass_material/macos_glass_env_response_spec.cr"
   146	      web: "crystal-alpha run scripts/validate_web_demo.cr"
   147	      android:
   148	        skip: true
   149	        reason: "Android env-response probe harness is Phase 6.5"
   150	        owner_approved: "2026-05-22"
   151	
   152	  - id: I-9
   153	    name: "Survive embedding"
   154	    touch: preserves
   155	    rationale: "Phase 5 introduces NO new Crystal class vars with initializers AND NO new Crystal::once-protected lazy lookups (token VALUES live in existing Tokens struct instances; resolution is method dispatch, not lazy class-var init). The class-init systematic fix remains deferred to a future phase. If Phase 5 implementer discovers a new class-var is required (e.g., for a material-specific singleton), the implementer MUST stop and surface to architect — the new class-var requires either (a) explicit .reset in hig_bridge.cr#initialize_runtime, OR (b) lazy-instance pattern with nil default and method-side initialization."
   156	    probes:
   157	      ios: "spec/asset_pipeline_spec.cr"
   158	      macos: "spec/asset_pipeline_spec.cr"
   159	      web:
   160	        skip: true
   161	        reason: "No embedding on web; the web target is the host language's natural runtime"
   162	        owner_approved: "2026-05-22"
   163	      android:
   164	        skip: true
   165	        reason: "Android probe harness is Phase 6.5"
   166	        owner_approved: "2026-05-22"
   167	
   168	  - id: I-10
   169	    name: "API/fallback contract fidelity"
   170	    touch: extends
   171	    rationale: "New public token API: tokens.material with per-step blur/opacity/saturation/luminance + intensity Float64 scalar. Phase 5 commits to: (1) intensity is RENDER-TIME ONLY — runtime mutation requires a re-render of the view tree; (2) SwiftUI Material's discrete enum quantizes intensity (see adapter_cardinality row 1); (3) web @supports fallback for backdrop-filter unavailability; (4) Android API < 31 alpha-fallback. All four are documented contract limitations consumers MUST understand."
   172	    probes:
   173	      ios: "spec/asset_pipeline_spec.cr"
   174	      macos: "spec/asset_pipeline_spec.cr"
   175	      web: "crystal-alpha run scripts/validate_web_demo.cr"
   176	      android:
   177	        skip: true
   178	        reason: "Android API-contract probe is Phase 6.5"
   179	        owner_approved: "2026-05-22"
   180	
   181	  - id: I-11
   182	    name: "Target build / link / load closure"
   183	    touch: extends
   184	    rationale: "Phase 5 modifies all 4 renderers (uikit/appkit/web/android). Each target's link closure must still resolve after token-resolution paths are added. If Phase 5 calls into SwiftUI Material at the Swift-side facade, the linker must still find the symbols on iOS 26.5 + macOS 26.5 SDKs."
   185	    probes:
   186	      ios: "bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator"
   187	      macos: "make -C samples/cross_platform/macos_host build"
   188	      web: "crystal-alpha build --no-codegen src/asset_pipeline.cr"
   189	      android:
   190	        skip: true
   191	        reason: "Android cross-build remains architect-precedent PASS per Phase 1 #17 (Crystal stdlib c/sys/epoll gap on darwin); Phase 5 ships Android renderer source but cannot verify cross-build until that gap is resolved separately"
   192	        owner_approved: "2026-05-22"
   193	
   194	lower_layer_assumptions:
   195	  - id: A1
   196	    claim: "SwiftUI Material API accepts the Material enum values Phase 5 emits (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .ultraThickMaterial) AND the .background(Material) modifier on a SwiftUI View on iOS 26.5 + macOS 26.5. NOTE 2026-05-22 per Codex resolution review: .chromeMaterial does NOT exist in public SwiftUI; Phase 5's :chrome step maps to .ultraThickMaterial (or .bar where chrome-tinted styling is wanted). The spike at spikes/swiftui_material_spike.swift uses .bar — that's the alternative."
   197	    falsifier: "Compiling spikes/swiftui_material_spike.swift returns non-zero exit on either iOS or macOS"
   198	    verification: "test -f spikes/swiftui_material_spike.swift && xcrun --sdk iphonesimulator swiftc -emit-library -target arm64-apple-ios16.0-simulator -o /tmp/spike-ios.dylib spikes/swiftui_material_spike.swift && xcrun --sdk macosx swiftc -emit-library -o /tmp/spike-macos.dylib spikes/swiftui_material_spike.swift"
   199	
   200	  - id: A2
   201	    claim: "Crystal toolchain is available as either crystal-alpha or crystal at expected paths"
   202	    falsifier: "which returns non-zero for both"
   203	    verification: "which crystal-alpha || which crystal"
   204	
   205	  - id: A3
   206	    claim: "GlassBackground references in src/ + samples/ post-Phase-5 number exactly 46 (binary files excluded) — pre-dispatch was 37 at SHA 2285fa1; Phase 5 added references in samples + specs"
   207	    falsifier: "grep count differs from 46"
   208	    verification: "test \"$(grep -rEnI 'GlassBackground|glass_background' src/ samples/ | wc -l | tr -d ' ')\" = \"46\""
   209	
   210	  - id: A4
   211	    claim: "Web renderer post-Phase-5 has exactly 4 backdrop-filter occurrences (the standard + -webkit- prefix variants on each of the 2 touched call sites). Pre-dispatch was 2 at SHA 2285fa1."
   212	    falsifier: "grep count differs from 4"
   213	    verification: "test \"$(grep -c 'backdrop-filter' src/ui/renderers/web_renderer.cr | tr -d ' ')\" = \"4\""
   214	
   215	  - id: A5
   216	    claim: "Android renderer's existing GlassBackground visit method uses semi-transparent FrameLayout placeholder (no real blur) — Phase 5 will replace with RenderEffect on API 31+ + alpha-fallback below"
   217	    falsifier: "grep does not find FrameLayout in android_renderer.cr's GlassBackground visit"
   218	    verification: "grep -A 30 'visit(view : UI::GlassBackground)' src/ui/renderers/android_renderer.cr | grep -q FrameLayout"
   219	
   220	  - id: A6
   221	    claim: "iOS renderer's existing GlassBackground path uses UIVisualEffectView + UIBlurEffect (will be replaced or extended with Material-based path)"
   222	    falsifier: "neither UIVisualEffectView nor UIBlurEffect appears in uikit_renderer.cr"
   223	    verification: "grep -qE 'UIVisualEffectView|UIBlurEffect' src/ui/renderers/uikit_renderer.cr"
   224	
   225	repo_derived_facts:
   226	  - fact: "GlassBackground usage count in src/ and samples/ (binary files excluded)"
   227	    query: "grep -rEnI 'GlassBackground|glass_background' src/ samples/ | wc -l | tr -d ' '"
   228	    expected: "46"
   229	    captured_at_sha: "01e66c7"
   230	    # Pre-dispatch the count was 37 at SHA 2285fa1; Phase 5 implementation
   231	    # added references in src/ui/design_tokens/material.cr (doc comments),
   232	    # samples/cross_platform/web/brand_glass_intensity_demo.cr (the brand
   233	    # cascade demo), and the spec/ui/glass_material/ probe placeholders.
   234	    # The brief's pre-dispatch contract was honored at 2285fa1; this
   235	    # value is updated post-implementation so subsequent phase briefs
   236	    # reading this fact see the actual current state.
   237	
   238	  - fact: "backdrop-filter emission count in web_renderer.cr"
   239	    query: "grep -c 'backdrop-filter' src/ui/renderers/web_renderer.cr | tr -d ' '"
   240	    expected: "4"
   241	    captured_at_sha: "01e66c7"
   242	    # Pre-dispatch count was 2 at SHA 2285fa1; Phase 5 tokenization added
   243	    # explicit -webkit-backdrop-filter prefixes alongside the standard
   244	    # backdrop-filter calls on both touched sites (GlassBackground +
   245	    # ActivityView), bringing the count to 4. The tokenization eliminated
   246	    # the hard-coded `blur(Xpx)` literals; both emission sites now route
   247	    # through var(--ap-material-blur-<step>).
   248	
   249	  - fact: "Existing design_tokens.cr file size in bytes (sanity: editing the right file)"
   250	    query: "wc -c < src/ui/design_tokens.cr | tr -d ' '"
   251	    expected: "37252"
   252	    captured_at_sha: "01e66c7"
   253	    # Pre-dispatch size was 35311 at SHA 2285fa1; Phase 5 added the
   254	    # Material getter on Tokens, the override_material hook on Brand,
   255	    # the material parameter on copy_with, and the Defaults.material
   256	    # factory. Net growth: ~1941 bytes.
   257	
   258	  - fact: "Android renderer alpha-step hex literals (5 material steps + 1 default fallback = 6)"
   259	    query: "grep -cE '0x[0-9A-F]{2}FFFFFF' src/ui/renderers/android_renderer.cr | tr -d ' '"
   260	    expected: "1"
   261	    captured_at_sha: "01e66c7"
   262	    # Pre-dispatch count was 6 at SHA 2285fa1 (the hard-coded
   263	    # 0x33/0x66/0x99/0xBB/0xDD per-step alpha table + the default
   264	    # fallback). Phase 5 replaced the table with token-driven
   265	    # composition; the remaining single literal is the `0x00FFFFFF`
   266	    # white mask used by the fallback-ARGB composition helper.
   267	    # DROPPING FROM 6 -> 1 IS THE INTENDED PHASE 5 OUTCOME.
   268	
   269	  - fact: "iOS renderer UIVisualEffectView/UIBlurEffect references that Phase 5 may touch (includes comments + code)"
   270	    query: "grep -cE 'UIVisualEffectView|UIBlurEffect' src/ui/renderers/uikit_renderer.cr | tr -d ' '"
   271	    expected: "60"
   272	    captured_at_sha: "2285fa1"
   273	
   274	  - fact: "macOS renderer NSVisualEffectView references that Phase 5 may touch (includes comments + code)"
   275	    query: "grep -c 'NSVisualEffectView' src/ui/renderers/appkit_renderer.cr | tr -d ' '"
   276	    expected: "37"
   277	    captured_at_sha: "2285fa1"
   278	
   279	adapter_cardinality:
   280	  - public_api: "UI::DesignTokens::Material#intensity (Float64 scalar; documented multiplicative in [0.0, 2.0])"
   281	    adapter: "SwiftUI Material enum on iOS/macOS (.ultraThinMaterial / .thinMaterial / .regularMaterial / .thickMaterial / .ultraThickMaterial; chrome step maps to .ultraThickMaterial or .bar). On iOS 26+ / macOS 26+ the SwiftUI .glassEffect() Liquid Glass modifier is SYSTEM-RESOLVED — step + intensity are advisory only."
   282	    adapter_input_space: "5 discrete material steps on pre-26 path; system-resolved single Glass surface on 26+ Liquid Glass path"
   283	    api_input_space: "Float64 in [0.0, 2.0]"
   284	    match_status: "MISMATCH"
   285	    documented_degradation: "QUANTIZATION TABLE (consumer-visible, pre-26 path only): intensity 0.0–0.3 → .ultraThinMaterial; 0.3–0.7 → .thinMaterial; 0.7–1.3 → .regularMaterial; 1.3–1.8 → .thickMaterial; 1.8+ → .ultraThickMaterial. AMENDED 2026-05-22 per Codex resolution review: on iOS 26+ / macOS 26+, the renderer uses SwiftUI .glassEffect() which is system-resolved — the system decides the material strength regardless of the app's intensity. App-side step + intensity are therefore ADVISORY on the Liquid Glass path. Consumers running on 26+ get uniform Liquid Glass; consumers on pre-26 fallback get the quantized material per the table. Brands wanting deterministic per-step rendering must either target pre-26 OR override the GlassBackground.material step explicitly (which the system may still override on 26+)."
   286	    owner_approved: "2026-05-22"
   287	
   288	  - public_api: "UI::DesignTokens::Material#blur_radius (Float64 px, per material step, scaled by intensity)"
   289	    adapter: "CSS backdrop-filter: blur() on web"
   290	    adapter_input_space: "Float64 px; supported in modern browsers; absent in older browsers"
   291	    api_input_space: "Float64 px"
   292	    match_status: "MISMATCH"
   293	    documented_degradation: "Browsers without backdrop-filter (detected via @supports not (backdrop-filter: blur(1px))) fall back to background-color: color-mix(in oklch, var(--ap-color-surface-panel) Z%, transparent) where Z is per-step opacity (ultra_thin=20%, thin=40%, regular=60%, thick=73%, chrome=87%). No blur. WCAG-AA contrast verified for text-on-fallback as well as text-on-blurred. Visible glass surfaces remain visually distinguishable via opacity alone."
   294	    owner_approved: "2026-05-22"
   295	
   296	  - public_api: "UI::DesignTokens::Material#blur_radius (Float64 px)"
   297	    adapter: "Android RenderEffect.createBlurEffect (API 31+) or alpha FrameLayout fallback (< API 31)"
   298	    adapter_input_space: "Float64 px on API 31+; null on < API 31"
   299	    api_input_space: "Float64 px"
   300	    match_status: "MISMATCH"
   301	    documented_degradation: "Android API < 31 degrades to FrameLayout with alpha-only background at per-step opacity (matching web fallback's opacity values). No blur. WCAG-AA contrast verified for text-on-alpha-fallback. This is the existing Phase 4-era behavior; Phase 5 keeps it for < API 31 and adds RenderEffect on API 31+."
   302	    owner_approved: "2026-05-22"
   303	
   304	pre_dispatch_validation:
   305	  script_path: "scripts/validate_phase_brief.cr"
   306	  expected_exit_code: 0

exec
/bin/zsh -lc "nl -ba docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md | sed -n '1,140p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	
     2	# Phase 5 — Implementation Brief: Glass Material Tokenization
     3	
     4	**Audience:** Implementer agent (single execution).
     5	**Read also:** `README.md` (this folder), `../../rubric/implementation_criteria.md`, `validation.md` (this folder — to anticipate what the validator will check), Phase 1 + Phase 3 READMEs.
     6	
     7	---
     8	
     9	## Goal
    10	
    11	Promote glass material strength from hard-coded per-renderer constants to a first-class branch of the `UI::DesignTokens` system. Wire every renderer — web, AppKit, UIKit, and Android — to read material parameters from the resolved token tree. Add a brand-overridable `intensity` scalar so a single line in a brand declaration uniformly scales how frosted glass surfaces appear on all four platforms. Add a `@supports` fallback for web browsers without `backdrop-filter`. Add a real `RenderEffect.createBlurEffect` path on Android API 31+ with a graceful pre-API-31 fallback.
    12	
    13	After this phase, no renderer file contains a hard-coded blur radius or material constant for `GlassBackground` (or for any other glass-using widget — see deviation prompt below). All of those values flow from `tokens.material`. A brand declaration in `samples/cross_platform/` can change `material.intensity` to `1.3` and produce visibly more frosted glass on all four platforms with no other code changes.
    14	
    15	---
    16	
    17	## Pre-reading checklist
    18	
    19	Before writing any code, the implementer must read:
    20	
    21	- [ ] `README.md` (this folder) — scope and risk notes.
    22	- [ ] `../phase-01-design-token-foundation/README.md` — token system shape and brand override mechanism.
    23	- [ ] `../phase-03-swiftui-native-bridge/README.md` — the `AssetPipelineSwiftKit` package and the `Overrides` struct pattern the bridge uses.
    24	- [ ] `../../rubric/implementation_criteria.md` — universal standards (commit cadence, Crystal style, doc comments, branch).
    25	- [ ] `src/ui/views/glass_background.cr` — the widget. Note that `material : Symbol` is the public API; that does not change in this phase.
    26	- [ ] `src/ui/renderers/web_renderer.cr` lines 1335–1359 — current `GlassBackground` visit. Read also line 1786 (toast) for the existing solid-fallback color pattern.
    27	- [ ] `src/ui/renderers/uikit_renderer.cr` lines 3068–3117 — current `GlassBackground` visit. Read also lines 1228–1300, 1463–1530, 2380–2480, 2489–2560, 2620–2740, 2776–2870 — every other glass-using widget. (See **Deviation prompt** below.)
    28	- [ ] `src/ui/renderers/appkit_renderer.cr` lines 2731–2774 — current `GlassBackground` visit. Read also lines 1051–1100, 1261–1420, 2005–2100, 2154–2210, 2302–2400, 2428–2500 for sibling glass widgets.
    29	- [ ] `src/ui/renderers/android_renderer.cr` lines 2154–2189 — current placeholder.
    30	- [ ] `validation.md` (this folder) — what the validator will check.
    31	
    32	If the token system or SwiftUI bridge code differs substantially from what the Phase 1 and Phase 3 READMEs describe (e.g., the type is named differently, the `Overrides` struct uses a different file convention), surface that to the team lead before continuing. See "When the brief is wrong" in `implementation_criteria.md`.
    33	
    34	---
    35	
    36	## Existing infrastructure to use (vs. rebuild)
    37	
    38	Phase 5 is the smallest implementation surface in the initiative — it threads one new token branch (`Material`) through four renderers. Almost everything you need is already in place from Phases 1 and 3.
    39	
    40	### Crystal source you extend
    41	
    42	- `src/ui/design_tokens.cr` — Phase 1's source-of-truth. You add a `material : Material` getter on the `Tokens` aggregate. Do not redefine the namespace.
    43	- `src/ui/views/glass_background.cr` — the widget. `material : Symbol` public API is unchanged.
    44	- `src/ui/renderers/web_renderer.cr` (lines 1335–1359 + 1786) — `GlassBackground` visit + toast solid fallback pattern.
    45	- `src/ui/renderers/uikit_renderer.cr` (lines 3068–3117 + the other glass-using visit methods listed in the Deviation prompt).
    46	- `src/ui/renderers/appkit_renderer.cr` (lines 2731–2774 + sibling glass methods).
    47	- `src/ui/renderers/android_renderer.cr` (lines 2154–2189 placeholder).
    48	- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift` — Phase 3's overrides class. Extend it with `intensity`, `blurDelta`, `opacityOverride`, `saturationOverride` fields per §SwiftUI bridge contract. If the file does not exist, Phase 3 has not landed — **stop and return early**.
    49	- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift` — existing facade. Extend the `make*` signature to accept the new override fields.
    50	
    51	### Crystal source you create
    52	
    53	- `src/ui/design_tokens/material.cr` — the new `Material` type and `Step` substruct.
    54	- `spec/ui/design_tokens/material_spec.cr`, `spec/ui/design_tokens/web_generator_material_spec.cr`, four renderer-specific specs (`spec/ui/renderers/{web,uikit,appkit,android}_glass_spec.cr`).
    55	- `samples/cross_platform/glass_intensity_demo.cr` — the cross-platform intensity demo used by validator checks 1–6.
    56	
    57	### Bridge naming reconciliation (cross-phase ambiguity flagged by prior audit)
    58	
    59	The prior audit (`handoff/plan-quality-audit-2026-05-20.md` §A) noted that Phase 5 references `LibSwiftKitBridge.material_parameters_new(...)` and `LibSwiftKitBridge.glass_background_overrides_new(...)`, but Phase 3 ships a `lib LibObjCBridge` plus a `SwiftKit` Crystal module — `LibSwiftKitBridge` was never explicitly named. Phase 3's revised "Existing infrastructure to use" section now creates `src/ui/native/lib_swiftkit_bridge.cr` as the typed wrapper. **Phase 5 references the same module — if you find `LibSwiftKitBridge` is not defined when you start Phase 5, the Phase 3 implementer did not ship the typed wrapper they were supposed to. Surface this to the team lead before freelancing.** The cross-phase naming contract is `LibSwiftKitBridge` (typed wrapper, defined in `src/ui/native/lib_swiftkit_bridge.cr`); do not coin a new name.
    60	
    61	### Pinned conventions
    62	
    63	| Convention | Value | Notes |
    64	|---|---|---|
    65	| Material step set | `:ultra_thin, :thin, :regular, :thick, :chrome` | Five steps. Must match what `GlassBackground#material` accepts. |
    66	| Intensity scalar | `Float64`, default `1.0`, brand-overridable | Multiplies `blur_radius` only. |
    67	| CSS variable prefix | `--ap-material-*` | Inherited from Phase 1's `--ap-*` standard. No `--amber-material-*` aliases. |
    68	| AppKit material translation marker | `# AppKit material translation table — only allowed hard-coded glass switch` | **Exact text required**, em dash `—`. Validator check 8 enforces. |
    69	| Android API gate | 31+ for `RenderEffect.createBlurEffect`, ≤ 30 fallback | Both paths invoke `AssetPipelineGlassHelper.applyGlass`. |
    70	| `@supports` fallback opacity | 94% on `regular` tier (per phase brief) | Used when neither `backdrop-filter` nor `-webkit-backdrop-filter` are supported. |
    71	
    72	### What is genuinely new vs. extended
    73	
    74	| New | Extended |
    75	|---|---|
    76	| `src/ui/design_tokens/material.cr` | `src/ui/design_tokens.cr` (add `material` getter on `Tokens`) |
    77	| `spec/ui/design_tokens/material_spec.cr` + 4 renderer-specific glass specs | `src/ui/renderers/{web,uikit,appkit,android}_renderer.cr` (token-driven glass) |
    78	| `samples/cross_platform/glass_intensity_demo.cr` | `swift/AssetPipelineSwiftKit/.../Overrides/GlassBackgroundOverrides.swift`, `Facades/GlassBackgroundFacade.swift` |
    79	| `AssetPipelineGlassHelper.java` (Android API 31+ blur helper) | `src/ui/native/lib_swiftkit_bridge.cr` (from Phase 3, extended for material params) |
    80	
    81	---
    82	
    83	## Deviation prompt — read carefully before starting
    84	
    85	The Phase 5 scope in `README.md` names `GlassBackground` as the widget being tokenized. However, the existing Apple renderers hard-code `NSVisualEffectMaterial` / `UIBlurEffectStyle` constants inside the visit methods for **TabView, Alert, Sidebar (NavigationSplitView), Toolbar, Sheet, and Popover** as well. If Phase 5 only tokenizes the `GlassBackground` visit, brand `material.intensity = 1.3` will not cascade to those other glass surfaces — only to the ones the developer explicitly wraps in `GlassBackground`. That is almost certainly the wrong behavior for a brand-cascade phase.
    86	
    87	**Required action:** Extend the refactor to every visit method that today calls `setMaterial:` with a hard-coded constant. The resolution path is identical to `GlassBackground` — pick the semantic material name (`:popover`, `:sheet`, `:sidebar`, `:toolbar`, etc.), look it up in the token tree, pass the resolved parameters to the renderer call.
    88	
    89	If during implementation you discover this would balloon the diff beyond a reasonable single-phase scope (more than ~12 visit methods to refactor), **stop and return** to the team lead with what you found rather than picking an arbitrary subset.
    90	
    91	---
    92	
    93	## `DesignTokens::Material` type specification
    94	
    95	Add a new subtype under the existing `UI::DesignTokens` namespace (Phase 1's deliverable). File: `src/ui/design_tokens/material.cr`.
    96	
    97	### Type declaration
    98	
    99	```crystal
   100	module UI
   101	  class DesignTokens
   102	    # Glass material parameters.
   103	    #
   104	    # A `Material` value declares the five strength steps that map to the
   105	    # public `GlassBackground#material` symbol values, plus a global
   106	    # `intensity` scalar that brands use to dial the frosted look up or
   107	    # down uniformly.
   108	    #
   109	    # `intensity` multiplies `blur_radius` only — opacity, saturation, and
   110	    # luminance are unaffected. Brands that need to skew the look further
   111	    # should override individual `MaterialStep` fields directly.
   112	    class Material
   113	      # One material strength step.
   114	      struct Step
   115	        # Blur kernel radius in points (Apple) / device-independent pixels (Android)
   116	        # / CSS pixels (web). Apple and web treat 1pt ≈ 1 CSS px at 1× rasterization;
   117	        # Android applies the same value as the RenderEffect radius argument.
   118	        getter blur_radius : Float64
   119	
   120	        # Tint opacity applied to the surface fill (`color-mix` percentage on web,
   121	        # alpha component on Android, automatic on Apple where the system material
   122	        # controls its own opacity).
   123	        getter opacity : Float64
   124	
   125	        # Saturation multiplier applied to backdrop content. 1.0 = neutral.
   126	        # Web emits as a second `backdrop-filter` argument (`saturate(N)`); Apple
   127	        # ignores (system material handles saturation); Android ignores at API 31+
   128	        # (RenderEffect saturation is a separate effect — out of scope for Phase 5).
   129	        getter saturation_boost : Float64
   130	
   131	        # Baseline luminance shift in the [-1.0, 1.0] range. Negative = darker.
   132	        # Used by the fallback paths (web `@supports` fallback, Android pre-31)
   133	        # to bias the fallback fill color.
   134	        getter luminance : Float64
   135	
   136	        # The integer constant the AppKit/UIKit renderer passes to
   137	        # `setMaterial:` / `effectWithStyle:`. Wrapped in the token so the
   138	        # mapping is one source of truth, not duplicated across visit methods.
   139	        getter apple_material_constant : Int64
   140	

codex
The key contract clause is in Phase 5 `implementation.md`: it requires every current `setMaterial:` hard-coded visit method to be refactored, or the implementer must stop and return when the diff exceeds reasonable scope. I’m checking whether the reported “legacy only” exception is actually true in code, not just in the handoff prose.
exec
/bin/zsh -lc "rg -n \"setMaterial:|appkit_visual_effect_material|def visit\\(view : UI::(NavigationSplitView|ContextMenu|ActivityView|TabView|Alert|Toolbar|Sheet|Popover|GlassBackground)|def _legacy_(tab_view|alert|toolbar|sheet|popover|navigation_split_view)|apsk_make_|GlassBackground|glassEffect|Material|android_view_apply_glass|prefers-reduced-motion|forced-colors|prefers-contrast|backdrop-filter|RenderEffect|FrameLayout\" src/ui/renderers/appkit_renderer.cr src/ui/renderers/uikit_renderer.cr src/ui/renderers/web_renderer.cr src/ui/renderers/android_renderer.cr src/ui/native/android_bridge.c swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift src/ui/design_tokens.cr src/ui/design_tokens/material.cr spikes/swiftui_material_spike.swift" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
src/ui/design_tokens.cr:187:    # 23 semantic color roles. The set is the union of the Material 3 roles
src/ui/design_tokens.cr:495:      # `MaterialStep` values + an `intensity` scalar consumers re-render to
src/ui/design_tokens.cr:498:      getter material : Material
src/ui/design_tokens.cr:515:        @material : Material = Defaults.material,
src/ui/design_tokens.cr:532:        material : Material = @material,
src/ui/design_tokens.cr:749:      # Phase 5: brand override hook for the `Material` token branch.
src/ui/design_tokens.cr:750:      # Subclasses return a new `Material` (typically via `material.copy_with(...)`)
src/ui/design_tokens.cr:752:      # individual `MaterialStep` fields for finer control.
src/ui/design_tokens.cr:753:      protected def override_material(material : Material) : Material
src/ui/design_tokens.cr:965:      # `Brand#override_material(material)` returning a new `Material` (use
src/ui/design_tokens.cr:968:      def material : Material
src/ui/design_tokens.cr:969:        Material.new(
src/ui/design_tokens.cr:970:          ultra_thin: MaterialStep.new(blur_radius: 10.0, opacity: 0.20, saturation: 1.05, luminance: 0.0),
src/ui/design_tokens.cr:971:          thin: MaterialStep.new(blur_radius: 20.0, opacity: 0.40, saturation: 1.10, luminance: 0.0),
src/ui/design_tokens.cr:972:          regular: MaterialStep.new(blur_radius: 30.0, opacity: 0.60, saturation: 1.15, luminance: 0.0),
src/ui/design_tokens.cr:973:          thick: MaterialStep.new(blur_radius: 40.0, opacity: 0.73, saturation: 1.20, luminance: 0.0),
src/ui/design_tokens.cr:974:          chrome: MaterialStep.new(blur_radius: 50.0, opacity: 0.87, saturation: 1.25, luminance: 0.0),
spikes/swiftui_material_spike.swift:1:// SwiftUI Material API compile spike — Phase 5 brief assumption A1.
spikes/swiftui_material_spike.swift:3:// Purpose: prove the SwiftUI Material API accepts the 5 material enum values
spikes/swiftui_material_spike.swift:4:// AND the .background(Material) modifier on iOS 26.5 + macOS 26.5 SDKs.
spikes/swiftui_material_spike.swift:15:// architect — Phase 5 cannot ship its claimed SwiftUI Material delivery
spikes/swiftui_material_spike.swift:16:// without working Material APIs.
spikes/swiftui_material_spike.swift:21:public struct APSKMaterialSpike: View {
spikes/swiftui_material_spike.swift:22:    public let step: APSKMaterialStep
spikes/swiftui_material_spike.swift:24:    public enum APSKMaterialStep {
spikes/swiftui_material_spike.swift:29:        case chrome  // Maps to .ultraThickMaterial (no public .chromeMaterial in SwiftUI)
spikes/swiftui_material_spike.swift:35:            Text("Material spike").padding().background(.ultraThinMaterial)
spikes/swiftui_material_spike.swift:37:            Text("Material spike").padding().background(.thinMaterial)
spikes/swiftui_material_spike.swift:39:            Text("Material spike").padding().background(.regularMaterial)
spikes/swiftui_material_spike.swift:41:            Text("Material spike").padding().background(.thickMaterial)
spikes/swiftui_material_spike.swift:43:            // .chromeMaterial doesn't exist in public SwiftUI; the closest
spikes/swiftui_material_spike.swift:44:            // equivalents are .ultraThickMaterial (strongest blur) or .bar
spikes/swiftui_material_spike.swift:46:            // chose ultraThickMaterial; spike verifies the API compiles.
spikes/swiftui_material_spike.swift:47:            Text("Material spike").padding().background(.ultraThickMaterial)
src/ui/native/android_bridge.c:1475:// Phase 5 — Glass material RenderEffect bridge.
src/ui/native/android_bridge.c:1480:// real RenderEffect blur was applied, 0 if the fallback alpha was used or
src/ui/native/android_bridge.c:1483:int32_t android_view_apply_glass(void *env_ptr, void *view, float blur_radius, int32_t fallback_argb) {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:1:// GlassBackgroundFacade — SwiftUI bridge for UI::GlassBackground, the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:5:// 13..25) it falls back to the matching static Material so the surface
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:10:// floor: a developer who writes `UI::GlassBackground.new(content)` gets
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:13:// Brand identity: `GlassBackground` deliberately does NOT apply the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:22:@objc(APSKGlassBackgroundFacade)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:23:public final class GlassBackgroundFacade: NSObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:27:    @objc public static func makeGlassBackground(
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:28:        overrides: GlassBackgroundOverrides,
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:38:        // Per brief.yml adapter_cardinality row 1, the SwiftUI Material
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:41:        // `.background(<Material>)` path honors the resolved step
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:42:        // directly. The iOS 26 / macOS 26+ `.glassEffect()` path is the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:47:        // quantizes to .regularMaterial on Apple (visually IDENTICAL to
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:53:        let material: Material = {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:55:            case "thin":       return .thinMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:56:            case "thick":      return .thickMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:57:            case "ultraThin":  return .ultraThinMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:58:            case "ultraThick": return .ultraThickMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:59:            default:           return .regularMaterial
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:69:                    .glassEffect()
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:72:            // Pre-26 fallback. `Material` tracks appearance + step.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift:1:// GlassBackgroundOverrides — override carrier for the GlassBackground
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift:4:// key to pick a Material family on pre-iOS 26 OSes and an `if
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift:23:@objc(APSKGlassBackgroundOverrides)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift:24:public final class GlassBackgroundOverrides: ViewOverrides {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift:26:    /// `nil` selects the SwiftUI default (`.regularMaterial` / Liquid Glass
src/ui/design_tokens/material.cr:5:    # Per-step values declare how a particular `UI::GlassBackground#material`
src/ui/design_tokens/material.cr:6:    # symbol renders. `blur_radius` is scaled by the parent `Material#intensity`
src/ui/design_tokens/material.cr:8:    # API 31+ (via the `RenderEffect.createBlurEffect` radius argument). On
src/ui/design_tokens/material.cr:9:    # Apple, `intensity` has NO visible effect — SwiftUI's `Material` is a
src/ui/design_tokens/material.cr:13:    record MaterialStep,
src/ui/design_tokens/material.cr:21:    # The five `MaterialStep` fields preserve existing per-step behavior at
src/ui/design_tokens/material.cr:28:    # SwiftUI's `Material` enum is discrete (.ultraThinMaterial, .thinMaterial,
src/ui/design_tokens/material.cr:29:    # .regularMaterial, .thickMaterial, .ultraThickMaterial). The declared
src/ui/design_tokens/material.cr:30:    # `GlassBackground#material` symbol maps 1:1 to a SwiftUI Material case.
src/ui/design_tokens/material.cr:32:    # declaring `material: :thick` always renders `.thickMaterial` regardless
src/ui/design_tokens/material.cr:38:    # `GlassBackground` views), `apple_step` does honor brand intensity by
src/ui/design_tokens/material.cr:49:    # .regularMaterial on Apple"). The implementation honors the worked
src/ui/design_tokens/material.cr:55:    record Material,
src/ui/design_tokens/material.cr:56:      ultra_thin : MaterialStep,
src/ui/design_tokens/material.cr:57:      thin : MaterialStep,
src/ui/design_tokens/material.cr:58:      regular : MaterialStep,
src/ui/design_tokens/material.cr:59:      thick : MaterialStep,
src/ui/design_tokens/material.cr:60:      chrome : MaterialStep,
src/ui/design_tokens/material.cr:62:      # Lookup the `MaterialStep` for a symbol. Unknown symbols fall back to
src/ui/design_tokens/material.cr:63:      # `:regular` rather than raising — `UI::GlassBackground#material` is
src/ui/design_tokens/material.cr:66:      def step(name : Symbol) : MaterialStep
src/ui/design_tokens/material.cr:78:      # use to pick its `SwiftUI.Material` case.
src/ui/design_tokens/material.cr:121:    # Output of `Material#resolve` — what web + Android renderers consume.
src/ui/renderers/web_renderer.cr:548:      def visit(view : UI::TabView)
src/ui/renderers/web_renderer.cr:658:      def visit(view : UI::Alert)
src/ui/renderers/web_renderer.cr:1109:      def visit(view : UI::NavigationSplitView)
src/ui/renderers/web_renderer.cr:1159:      def visit(view : UI::Toolbar)
src/ui/renderers/web_renderer.cr:1189:      def visit(view : UI::Sheet)
src/ui/renderers/web_renderer.cr:1225:      def visit(view : UI::Popover)
src/ui/renderers/web_renderer.cr:1402:      def visit(view : UI::GlassBackground)
src/ui/renderers/web_renderer.cr:1414:          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1415:          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1434:      # Map a `GlassBackground#material` Symbol to the CSS class suffix /
src/ui/renderers/web_renderer.cr:1551:        def visit(view : UI::ContextMenu)
src/ui/renderers/web_renderer.cr:1568:      def visit(view : UI::ContextMenuWithWebFallback)
src/ui/renderers/web_renderer.cr:2015:      def visit(view : UI::ActivityView)
src/ui/renderers/web_renderer.cr:2019:        # for both backdrop-filter and the opacity-driven color-mix
src/ui/renderers/web_renderer.cr:2024:        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); -webkit-backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")
src/ui/renderers/appkit_renderer.cr:197:        ptr = LibSwiftKitBridge.apsk_make_label_reactive(
src/ui/renderers/appkit_renderer.cr:268:        ptr = LibSwiftKitBridge.apsk_make_button_reactive(
src/ui/renderers/appkit_renderer.cr:493:        ptr = LibSwiftKitBridge.apsk_make_image(view.source.to_unsafe, overrides_ptr)
src/ui/renderers/appkit_renderer.cr:518:        ptr = LibSwiftKitBridge.apsk_make_text_field(
src/ui/renderers/appkit_renderer.cr:641:        ptr = LibSwiftKitBridge.apsk_make_toggle_reactive(
src/ui/renderers/appkit_renderer.cr:671:        ptr = LibSwiftKitBridge.apsk_make_checkbox(
src/ui/renderers/appkit_renderer.cr:703:        ptr = LibSwiftKitBridge.apsk_make_radio_group(
src/ui/renderers/appkit_renderer.cr:731:        ptr = LibSwiftKitBridge.apsk_make_slider_reactive(
src/ui/renderers/appkit_renderer.cr:763:        ptr = LibSwiftKitBridge.apsk_make_navigation_stack(
src/ui/renderers/appkit_renderer.cr:787:        ptr = LibSwiftKitBridge.apsk_make_navigation_link(
src/ui/renderers/appkit_renderer.cr:805:      # (NSVisualEffectMaterialMenu = 10, tracks light/dark automatically)
src/ui/renderers/appkit_renderer.cr:820:      def visit(view : UI::TabView)
src/ui/renderers/appkit_renderer.cr:848:        ptr = LibSwiftKitBridge.apsk_make_tab_view(
src/ui/renderers/appkit_renderer.cr:859:      private def _legacy_tab_view(view : UI::TabView)
src/ui/renderers/appkit_renderer.cr:861:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:1051:      # require Liquid Glass. NSVisualEffectMaterialHUDWindow (= 7) is the
src/ui/renderers/appkit_renderer.cr:1060:      def visit(view : UI::Alert)
src/ui/renderers/appkit_renderer.cr:1081:        ptr = LibSwiftKitBridge.apsk_make_alert(
src/ui/renderers/appkit_renderer.cr:1091:      private def _legacy_alert(view : UI::Alert)
src/ui/renderers/appkit_renderer.cr:1093:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 7_i64)
src/ui/renderers/appkit_renderer.cr:1255:        ptr = LibSwiftKitBridge.apsk_make_picker(
src/ui/renderers/appkit_renderer.cr:1279:        ptr = LibSwiftKitBridge.apsk_make_icon_button(
src/ui/renderers/appkit_renderer.cr:1321:        ptr = LibSwiftKitBridge.apsk_make_list_view(
src/ui/renderers/appkit_renderer.cr:1511:        ptr = LibSwiftKitBridge.apsk_make_secure_field(
src/ui/renderers/appkit_renderer.cr:1536:        ptr = LibSwiftKitBridge.apsk_make_stepper(
src/ui/renderers/appkit_renderer.cr:1566:        ptr = LibSwiftKitBridge.apsk_make_segmented_control(
src/ui/renderers/appkit_renderer.cr:1593:        ptr = LibSwiftKitBridge.apsk_make_date_picker(
src/ui/renderers/appkit_renderer.cr:1619:        ptr = LibSwiftKitBridge.apsk_make_time_picker(
src/ui/renderers/appkit_renderer.cr:1644:        ptr = LibSwiftKitBridge.apsk_make_search_field(
src/ui/renderers/appkit_renderer.cr:1670:        ptr = LibSwiftKitBridge.apsk_make_text_area(
src/ui/renderers/appkit_renderer.cr:1702:        ptr = LibSwiftKitBridge.apsk_make_grid(
src/ui/renderers/appkit_renderer.cr:1741:        ptr = LibSwiftKitBridge.apsk_make_form(
src/ui/renderers/appkit_renderer.cr:1756:      # NSVisualEffectMaterialSidebar (= 7). The content / detail
src/ui/renderers/appkit_renderer.cr:1773:      def visit(view : UI::NavigationSplitView)
src/ui/renderers/appkit_renderer.cr:1798:        ptr = LibSwiftKitBridge.apsk_make_navigation_split_view(
src/ui/renderers/appkit_renderer.cr:1809:      private def _legacy_navigation_split_view(view : UI::NavigationSplitView)
src/ui/renderers/appkit_renderer.cr:1829:            # then maps to NSVisualEffectMaterialSidebar (7) via the
src/ui/renderers/appkit_renderer.cr:1836:            sidebar_material = appkit_visual_effect_material(sidebar_step)
src/ui/renderers/appkit_renderer.cr:1838:            LibObjCBridge.objc_send_long(sidebar_effect, sel("setMaterial:"), sidebar_material)
src/ui/renderers/appkit_renderer.cr:1950:      # Material: NSVisualEffectMaterialToolBar = 10 (tracks appearance).
src/ui/renderers/appkit_renderer.cr:1964:      def visit(view : UI::Toolbar)
src/ui/renderers/appkit_renderer.cr:1987:        ptr = LibSwiftKitBridge.apsk_make_toolbar(
src/ui/renderers/appkit_renderer.cr:1998:      private def _legacy_toolbar(view : UI::Toolbar)
src/ui/renderers/appkit_renderer.cr:2000:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
src/ui/renderers/appkit_renderer.cr:2123:      def visit(view : UI::Sheet)
src/ui/renderers/appkit_renderer.cr:2147:        ptr = LibSwiftKitBridge.apsk_make_sheet(
src/ui/renderers/appkit_renderer.cr:2159:      private def _legacy_sheet(view : UI::Sheet)
src/ui/renderers/appkit_renderer.cr:2169:          # NSVisualEffectMaterialSheet = 11 (macOS 10.11+). This is the
src/ui/renderers/appkit_renderer.cr:2172:          # appearance automatically. Material 10 (Menu) was used previously;
src/ui/renderers/appkit_renderer.cr:2173:          # 11 (Sheet) is the semantically correct value per NSVisualEffectMaterial
src/ui/renderers/appkit_renderer.cr:2178:          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)
src/ui/renderers/appkit_renderer.cr:2280:      # NSVisualEffectMaterialPopover = 6. Tracks light/dark appearance
src/ui/renderers/appkit_renderer.cr:2296:      # Corner radius ~10pt matching NSVisualEffectMaterialPopover default.
src/ui/renderers/appkit_renderer.cr:2298:      def visit(view : UI::Popover)
src/ui/renderers/appkit_renderer.cr:2320:        ptr = LibSwiftKitBridge.apsk_make_popover(
src/ui/renderers/appkit_renderer.cr:2332:      private def _legacy_popover(view : UI::Popover)
src/ui/renderers/appkit_renderer.cr:2334:        # NSVisualEffectMaterialPopover = 6.
src/ui/renderers/appkit_renderer.cr:2335:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 6_i64)
src/ui/renderers/appkit_renderer.cr:2419:        ptr = LibSwiftKitBridge.apsk_make_confirmation_dialog(
src/ui/renderers/appkit_renderer.cr:2492:        ptr = LibSwiftKitBridge.apsk_make_card(
src/ui/renderers/appkit_renderer.cr:2625:        ptr = LibSwiftKitBridge.apsk_make_surface(
src/ui/renderers/appkit_renderer.cr:2643:        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
src/ui/renderers/appkit_renderer.cr:2648:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
src/ui/renderers/appkit_renderer.cr:2649:      # with `.background(<Material>)` fallback on pre-26 OSes.
src/ui/renderers/appkit_renderer.cr:2656:      def visit(view : UI::GlassBackground)
src/ui/renderers/appkit_renderer.cr:2658:        # See uikit_renderer.cr#visit(UI::GlassBackground) for the contract.
src/ui/renderers/appkit_renderer.cr:2675:        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
src/ui/renderers/appkit_renderer.cr:2676:        handle = ObjC.owned(ptr, label: "NSHostingView[GlassBackground]")
src/ui/renderers/appkit_renderer.cr:2762:        ptr = LibSwiftKitBridge.apsk_make_link_button(
src/ui/renderers/appkit_renderer.cr:2812:        ptr = LibSwiftKitBridge.apsk_make_menu_button(
src/ui/renderers/appkit_renderer.cr:2821:      def visit(view : UI::ContextMenu)
src/ui/renderers/appkit_renderer.cr:2823:        # `NSVisualEffectMaterialMenu` has no SwiftUI Material enum
src/ui/renderers/appkit_renderer.cr:2830:        menu_material = appkit_visual_effect_material(menu_step)
src/ui/renderers/appkit_renderer.cr:2832:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), menu_material) # :menu -> NSVisualEffectMaterialMenu (5)
src/ui/renderers/appkit_renderer.cr:2952:        ptr = LibSwiftKitBridge.apsk_make_toggle_button(
src/ui/renderers/appkit_renderer.cr:2974:        ptr = LibSwiftKitBridge.apsk_make_text_editor(
src/ui/renderers/appkit_renderer.cr:3682:        ptr = LibSwiftKitBridge.apsk_make_color_picker(
src/ui/renderers/appkit_renderer.cr:3745:      # Material: NSVisualEffectMaterialSheet = 11 (tracks appearance). Although
src/ui/renderers/appkit_renderer.cr:3751:      def visit(view : UI::ActivityView)
src/ui/renderers/appkit_renderer.cr:3765:        # maps `:thick` to NSVisualEffectMaterialSheet (11), byte-identical
src/ui/renderers/appkit_renderer.cr:3768:        activity_material = appkit_visual_effect_material(activity_step)
src/ui/renderers/appkit_renderer.cr:3770:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), activity_material) # :thick -> NSVisualEffectMaterialSheet (11)
src/ui/renderers/appkit_renderer.cr:4438:      def visit(view : UI::ContextMenuWithWebFallback)
src/ui/renderers/appkit_renderer.cr:4668:      # Resolve a Phase-5 Material step Symbol to its NSVisualEffectMaterial
src/ui/renderers/appkit_renderer.cr:4676:      # NSVisualEffectMaterial semantics; implementation.md L562 sketches
src/ui/renderers/appkit_renderer.cr:4682:      # The portable Material steps (`:thin`, `:thick`) match the
src/ui/renderers/appkit_renderer.cr:4685:      # `NSVisualEffectMaterialMenu` (no SwiftUI Material enum analogue).
src/ui/renderers/appkit_renderer.cr:4686:      # `:menu` must NOT be advertised as part of the portable Material
src/ui/renderers/appkit_renderer.cr:4691:      # Unknown / unhandled Symbols fall through to `NSVisualEffectMaterialHeaderView`
src/ui/renderers/appkit_renderer.cr:4693:      #   (a) verifying the Apple NSVisualEffectMaterial semantics,
src/ui/renderers/appkit_renderer.cr:4701:      private def appkit_visual_effect_material(step : Symbol) : Int64
src/ui/renderers/appkit_renderer.cr:4704:        when :thin  then  7_i64 # NSVisualEffectMaterialSidebar (NavigationSplitView sidebar)
src/ui/renderers/appkit_renderer.cr:4705:        when :thick then 11_i64 # NSVisualEffectMaterialSheet (ActivityView)
src/ui/renderers/appkit_renderer.cr:4706:        when :menu  then  5_i64 # NSVisualEffectMaterialMenu (ContextMenu, AppKit-semantic; no SwiftUI analogue)
src/ui/renderers/appkit_renderer.cr:4707:        else             10_i64 # NSVisualEffectMaterialHeaderView (safe modern default)
src/ui/renderers/appkit_renderer.cr:4792:      # passing to a `LibSwiftKitBridge.apsk_make_*` facade as its
src/ui/renderers/android_renderer.cr:21:  #   "android/widget/FrameLayout"
src/ui/renderers/android_renderer.cr:45:  # FrameLayout children need FrameLayout.LayoutParams.
src/ui/renderers/android_renderer.cr:82:    # --- Material text fields ---
src/ui/renderers/android_renderer.cr:134:    # --- Material components ---
src/ui/renderers/android_renderer.cr:204:    # fallbackArgb). Helper internally chooses RenderEffect.createBlurEffect
src/ui/renderers/android_renderer.cr:208:    fun android_view_apply_glass(env : Void*, view : Void*, blur_radius : Float32, fallback_argb : Int32) : Int32
src/ui/renderers/android_renderer.cr:257:    # Tracks whether each stack entry is a LinearLayout (true) or FrameLayout
src/ui/renderers/android_renderer.cr:259:    # FrameLayout children use MATCH_PARENT layout.
src/ui/renderers/android_renderer.cr:272:    # `visit(UI::GlassBackground)` to drive both the API 31+ RenderEffect
src/ui/renderers/android_renderer.cr:333:    # Visit: Button -> android.widget.Button (or MaterialButton)
src/ui/renderers/android_renderer.cr:336:      btn = LibAndroidBridge.android_view_new(@env, "com/google/android/material/button/MaterialButton", @context)
src/ui/renderers/android_renderer.cr:511:    # Visit: ZStack -> android.widget.FrameLayout
src/ui/renderers/android_renderer.cr:513:    # FrameLayout is the Android overlay container. Children are stacked
src/ui/renderers/android_renderer.cr:518:      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
src/ui/renderers/android_renderer.cr:524:      handle = JNI.wrap_global(global_fl, label: "FrameLayout[zstack]")
src/ui/renderers/android_renderer.cr:587:        "Widget_Material3_TextInputLayout_FilledBox"
src/ui/renderers/android_renderer.cr:600:        "Widget_Material3_TextInputEditText_FilledBox"
src/ui/renderers/android_renderer.cr:944:    # Visit: NavigationStack -> android.widget.FrameLayout (navigation container)
src/ui/renderers/android_renderer.cr:947:      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
src/ui/renderers/android_renderer.cr:952:      handle = JNI.wrap_global(global_fl, label: "FrameLayout[nav-stack]")
src/ui/renderers/android_renderer.cr:978:    # Visit: TabView -> android.widget.FrameLayout (tab container)
src/ui/renderers/android_renderer.cr:980:    def visit(view : UI::TabView)
src/ui/renderers/android_renderer.cr:981:      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
src/ui/renderers/android_renderer.cr:986:      handle = JNI.wrap_global(global_fl, label: "FrameLayout[tab-view]")
src/ui/renderers/android_renderer.cr:1044:    # Visit: Alert -> inline Material dialog study surface
src/ui/renderers/android_renderer.cr:1046:    def visit(view : UI::Alert)
src/ui/renderers/android_renderer.cr:1047:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1062:      handle = JNI.wrap_global(global_ll, label: "MaterialCardView[alert]")
src/ui/renderers/android_renderer.cr:1160:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1202:      handle = JNI.wrap_global(global_card, label: "MaterialCardView[picker]")
src/ui/renderers/android_renderer.cr:1297:        "Widget_Material3_TextInputLayout_FilledBox"
src/ui/renderers/android_renderer.cr:1310:        "Widget_Material3_TextInputEditText_FilledBox"
src/ui/renderers/android_renderer.cr:1528:    # Visit: PageControl -> Material-style row of page indicator dots
src/ui/renderers/android_renderer.cr:1577:        "Widget_Material3_TextInputLayout_OutlinedBox_ExposedDropdownMenu"
src/ui/renderers/android_renderer.cr:1594:        "com/google/android/material/textfield/MaterialAutoCompleteTextView",
src/ui/renderers/android_renderer.cr:1595:        "Widget_Material3_AutoCompleteTextView_OutlinedBox"
src/ui/renderers/android_renderer.cr:1617:    # Visit: RatingIndicator -> Material-style star row using TextViews
src/ui/renderers/android_renderer.cr:1650:        "Widget_Material3_TextInputLayout_FilledBox"
src/ui/renderers/android_renderer.cr:1663:        "Widget_Material3_TextInputEditText_FilledBox"
src/ui/renderers/android_renderer.cr:1782:    def visit(view : UI::NavigationSplitView)
src/ui/renderers/android_renderer.cr:1818:    def visit(view : UI::Toolbar)
src/ui/renderers/android_renderer.cr:1819:      toolbar = LibAndroidBridge.android_view_new(@env, "com/google/android/material/appbar/MaterialToolbar", @context)
src/ui/renderers/android_renderer.cr:1825:        title_text = view.title || "Material study"
src/ui/renderers/android_renderer.cr:1834:      emit(toolbar, "MaterialToolbar")
src/ui/renderers/android_renderer.cr:1838:    # Visit: Sheet -> inline Material bottom-sheet surface
src/ui/renderers/android_renderer.cr:1840:    def visit(view : UI::Sheet)
src/ui/renderers/android_renderer.cr:1841:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1874:      handle = JNI.wrap_global(global_card, label: "MaterialCardView[sheet]")
src/ui/renderers/android_renderer.cr:1905:    # Visit: Popover -> inline Material callout surface
src/ui/renderers/android_renderer.cr:1907:    def visit(view : UI::Popover)
src/ui/renderers/android_renderer.cr:1924:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:1982:    # Visit: ConfirmationDialog -> inline Material dialog study surface
src/ui/renderers/android_renderer.cr:1985:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2000:      handle = JNI.wrap_global(global_ll, label: "MaterialCardView[confirmation-dialog]")
src/ui/renderers/android_renderer.cr:2035:    # Visit: Snackbar -> inline Material snackbar surface
src/ui/renderers/android_renderer.cr:2038:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2060:      handle = JNI.wrap_global(global_card, label: "MaterialCardView[snackbar]")
src/ui/renderers/android_renderer.cr:2079:    # Visit: Card -> com.google.android.material.card.MaterialCardView (via FrameLayout)
src/ui/renderers/android_renderer.cr:2082:      fl = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2085:      handle = JNI.wrap_global(global_fl, label: "MaterialCardView[card]")
src/ui/renderers/android_renderer.cr:2131:    # Visit: Surface -> android.widget.FrameLayout (elevated surface)
src/ui/renderers/android_renderer.cr:2134:      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
src/ui/renderers/android_renderer.cr:2143:      handle = JNI.wrap_global(global_fl, label: "FrameLayout[surface]")
src/ui/renderers/android_renderer.cr:2170:    # Visit: GlassBackground -> android.widget.FrameLayout + RenderEffect
src/ui/renderers/android_renderer.cr:2174:    # helper applies `RenderEffect.createBlurEffect(radius, radius,
src/ui/renderers/android_renderer.cr:2181:    # Empirical verification (real RenderEffect render on a real device)
src/ui/renderers/android_renderer.cr:2184:    def visit(view : UI::GlassBackground)
src/ui/renderers/android_renderer.cr:2187:      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
src/ui/renderers/android_renderer.cr:2195:      applied_real_blur = LibAndroidBridge.android_view_apply_glass(
src/ui/renderers/android_renderer.cr:2209:      handle = JNI.wrap_global(global_fl, label: "FrameLayout[glass]")
src/ui/renderers/android_renderer.cr:2262:    def visit(view : UI::ContextMenuWithWebFallback)
src/ui/renderers/android_renderer.cr:2640:    # WebViewComponent: native WebView mounted inside a Material study frame.
src/ui/renderers/android_renderer.cr:2692:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2738:      handle = JNI.wrap_global(global_card, label: "MaterialCardView[color-picker]")
src/ui/renderers/android_renderer.cr:2784:    # VideoPlayer: native VideoView mounted in a Material media surface.
src/ui/renderers/android_renderer.cr:2832:    # Tooltip: FrameLayout wrapping optional content with tooltip text stored
src/ui/renderers/android_renderer.cr:2835:      # Use a FrameLayout so optional child content can be added
src/ui/renderers/android_renderer.cr:2837:        @env, "android/widget/FrameLayout", @context)
src/ui/renderers/android_renderer.cr:2848:      handle = JNI.wrap_global(global_ptr, label: "FrameLayout[tooltip]")
src/ui/renderers/android_renderer.cr:2863:    def visit(view : UI::ActivityView)
src/ui/renderers/android_renderer.cr:2884:      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2896:      handle = JNI.wrap_global(global_card, label: "MaterialCardView[activity-view]")
src/ui/renderers/android_renderer.cr:2905:        thumb = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
src/ui/renderers/android_renderer.cr:2954:          item = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:2990:            tile = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
src/ui/renderers/android_renderer.cr:3150:      # and routing through the existing visitor; Material 3 styling is
src/ui/renderers/android_renderer.cr:3429:            # FrameLayout (ZStack) or ScrollView: MATCH_PARENT to fill parent
src/ui/renderers/uikit_renderer.cr:204:        ptr = LibSwiftKitBridge.apsk_make_label_reactive(
src/ui/renderers/uikit_renderer.cr:272:        ptr = LibSwiftKitBridge.apsk_make_button_reactive(
src/ui/renderers/uikit_renderer.cr:434:        ptr = LibSwiftKitBridge.apsk_make_image(view.source.to_unsafe, overrides_ptr)
src/ui/renderers/uikit_renderer.cr:457:        ptr = LibSwiftKitBridge.apsk_make_text_field(
src/ui/renderers/uikit_renderer.cr:582:        ptr = LibSwiftKitBridge.apsk_make_toggle_reactive(
src/ui/renderers/uikit_renderer.cr:619:        ptr = LibSwiftKitBridge.apsk_make_checkbox(
src/ui/renderers/uikit_renderer.cr:656:        ptr = LibSwiftKitBridge.apsk_make_radio_group(
src/ui/renderers/uikit_renderer.cr:701:        ptr = LibSwiftKitBridge.apsk_make_slider_reactive(
src/ui/renderers/uikit_renderer.cr:733:        ptr = LibSwiftKitBridge.apsk_make_navigation_stack(
src/ui/renderers/uikit_renderer.cr:754:        ptr = LibSwiftKitBridge.apsk_make_navigation_link(
src/ui/renderers/uikit_renderer.cr:774:      #                        systemChromeMaterial=11 fallback)
src/ui/renderers/uikit_renderer.cr:786:      def visit(view : UI::TabView)
src/ui/renderers/uikit_renderer.cr:810:        ptr = LibSwiftKitBridge.apsk_make_tab_view(
src/ui/renderers/uikit_renderer.cr:821:      private def _legacy_tab_view(view : UI::TabView)
src/ui/renderers/uikit_renderer.cr:831:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:1037:      # we prefer UIGlassEffect; on older SDKs UIBlurEffect(systemMaterial=7)
src/ui/renderers/uikit_renderer.cr:1042:      # screenshot isolation. Material, corner radius, and role-coloring are
src/ui/renderers/uikit_renderer.cr:1043:      # HIG-faithful — hudWindow-equivalent on iOS is systemMaterial.
src/ui/renderers/uikit_renderer.cr:1045:      def visit(view : UI::Alert)
src/ui/renderers/uikit_renderer.cr:1064:        ptr = LibSwiftKitBridge.apsk_make_alert(
src/ui/renderers/uikit_renderer.cr:1074:      private def _legacy_alert(view : UI::Alert)
src/ui/renderers/uikit_renderer.cr:1082:                        # UIBlurEffectStyleSystemMaterial = 7
src/ui/renderers/uikit_renderer.cr:1268:        ptr = LibSwiftKitBridge.apsk_make_picker(
src/ui/renderers/uikit_renderer.cr:1292:        ptr = LibSwiftKitBridge.apsk_make_icon_button(
src/ui/renderers/uikit_renderer.cr:1334:        ptr = LibSwiftKitBridge.apsk_make_list_view(
src/ui/renderers/uikit_renderer.cr:1594:        ptr = LibSwiftKitBridge.apsk_make_secure_field(
src/ui/renderers/uikit_renderer.cr:1617:        ptr = LibSwiftKitBridge.apsk_make_stepper(
src/ui/renderers/uikit_renderer.cr:1644:        ptr = LibSwiftKitBridge.apsk_make_segmented_control(
src/ui/renderers/uikit_renderer.cr:1668:        ptr = LibSwiftKitBridge.apsk_make_date_picker(
src/ui/renderers/uikit_renderer.cr:1691:        ptr = LibSwiftKitBridge.apsk_make_time_picker(
src/ui/renderers/uikit_renderer.cr:1713:        ptr = LibSwiftKitBridge.apsk_make_search_field(
src/ui/renderers/uikit_renderer.cr:1736:        ptr = LibSwiftKitBridge.apsk_make_text_area(
src/ui/renderers/uikit_renderer.cr:1765:        ptr = LibSwiftKitBridge.apsk_make_grid(
src/ui/renderers/uikit_renderer.cr:1801:        ptr = LibSwiftKitBridge.apsk_make_form(
src/ui/renderers/uikit_renderer.cr:1820:      # fallback to UIBlurEffect(systemChromeMaterial=11) on older SDKs.
src/ui/renderers/uikit_renderer.cr:1822:      def visit(view : UI::NavigationSplitView)
src/ui/renderers/uikit_renderer.cr:1844:        ptr = LibSwiftKitBridge.apsk_make_navigation_split_view(
src/ui/renderers/uikit_renderer.cr:1854:      private def _legacy_navigation_split_view(view : UI::NavigationSplitView)
src/ui/renderers/uikit_renderer.cr:1864:            # UIBlurEffectStyleSystemChromeMaterial (= 11) on older SDKs.
src/ui/renderers/uikit_renderer.cr:1952:      # use UIGlassEffect (iOS 26+) or UIBlurEffect.systemChromeMaterial
src/ui/renderers/uikit_renderer.cr:1967:      def visit(view : UI::Toolbar)
src/ui/renderers/uikit_renderer.cr:1986:        ptr = LibSwiftKitBridge.apsk_make_toolbar(
src/ui/renderers/uikit_renderer.cr:1996:      private def _legacy_toolbar(view : UI::Toolbar)
src/ui/renderers/uikit_renderer.cr:2000:        # UIBlurEffectStyleSystemChromeMaterial = 11 on older SDKs.
src/ui/renderers/uikit_renderer.cr:2008:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2108:      def visit(view : UI::Sheet)
src/ui/renderers/uikit_renderer.cr:2137:        ptr = LibSwiftKitBridge.apsk_make_sheet_reactive(
src/ui/renderers/uikit_renderer.cr:2153:      private def _legacy_sheet(view : UI::Sheet)
src/ui/renderers/uikit_renderer.cr:2160:          # UIBlurEffectStyleSystemChromeMaterial (iOS 15+, tracks appearance).
src/ui/renderers/uikit_renderer.cr:2168:                          # [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]
src/ui/renderers/uikit_renderer.cr:2169:                          # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2313:      # Material: UIGlassEffect (iOS 26) preferred; falls back to
src/ui/renderers/uikit_renderer.cr:2314:      # UIBlurEffectStyleSystemChromeMaterial (= 11, tracks appearance) on
src/ui/renderers/uikit_renderer.cr:2324:      def visit(view : UI::Popover)
src/ui/renderers/uikit_renderer.cr:2345:        ptr = LibSwiftKitBridge.apsk_make_popover(
src/ui/renderers/uikit_renderer.cr:2357:      private def _legacy_popover(view : UI::Popover)
src/ui/renderers/uikit_renderer.cr:2365:                        # UIBlurEffectStyleSystemChromeMaterial = 11
src/ui/renderers/uikit_renderer.cr:2458:        ptr = LibSwiftKitBridge.apsk_make_confirmation_dialog(
src/ui/renderers/uikit_renderer.cr:2510:        ptr = LibSwiftKitBridge.apsk_make_card(
src/ui/renderers/uikit_renderer.cr:2632:        ptr = LibSwiftKitBridge.apsk_make_surface(
src/ui/renderers/uikit_renderer.cr:2650:        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
src/ui/renderers/uikit_renderer.cr:2655:      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26+) /
src/ui/renderers/uikit_renderer.cr:2656:      # `.background(<Material>)` fallback on iOS 16..25.
src/ui/renderers/uikit_renderer.cr:2663:      def visit(view : UI::GlassBackground)
src/ui/renderers/uikit_renderer.cr:2665:        # SwiftUI's Material enum is discrete; brand `intensity` shifts the
src/ui/renderers/uikit_renderer.cr:2686:        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
src/ui/renderers/uikit_renderer.cr:2687:        handle = ObjC.owned(ptr, label: "UIHostingController[GlassBackground]")
src/ui/renderers/uikit_renderer.cr:2771:        ptr = LibSwiftKitBridge.apsk_make_link_button(
src/ui/renderers/uikit_renderer.cr:2821:        ptr = LibSwiftKitBridge.apsk_make_menu_button(
src/ui/renderers/uikit_renderer.cr:2931:      def visit(view : UI::ContextMenu)
src/ui/renderers/uikit_renderer.cr:3080:        ptr = LibSwiftKitBridge.apsk_make_toggle_button(
src/ui/renderers/uikit_renderer.cr:3102:        ptr = LibSwiftKitBridge.apsk_make_text_editor(
src/ui/renderers/uikit_renderer.cr:3663:        ptr = LibSwiftKitBridge.apsk_make_color_picker(
src/ui/renderers/uikit_renderer.cr:3722:      # Material: UIGlassEffect (iOS 26) or
src/ui/renderers/uikit_renderer.cr:3723:      #           UIBlurEffect(systemChromeMaterial=11) fallback.
src/ui/renderers/uikit_renderer.cr:3725:      def visit(view : UI::ActivityView)
src/ui/renderers/uikit_renderer.cr:4450:        ptr = LibSwiftKitBridge.apsk_make_confirmation_dialog(
src/ui/renderers/uikit_renderer.cr:4470:      def visit(view : UI::ContextMenuWithWebFallback)
src/ui/renderers/uikit_renderer.cr:4859:      # passing to a `LibSwiftKitBridge.apsk_make_*` facade as its

exec
/bin/zsh -lc 'rg -n "prefers-reduced-motion|forced-colors|prefers-contrast" src/ui' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 exited 1 in 0ms:
exec
/bin/zsh -lc 'rg -n "ObservableObject|@Published|android_view_apply_glass|glass_background_overrides|material_parameters|NewGlobalRef|DeleteGlobalRef|NewWeakGlobalRef" swift/AssetPipelineSwiftKit src/ui/native src/ui/renderers/android_renderer.cr src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
src/ui/renderers/appkit_renderer.cr:2661:        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
src/ui/renderers/uikit_renderer.cr:2672:        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
src/ui/renderers/android_renderer.cr:36:  # - Global refs (via NewGlobalRef) persist across calls and must be
src/ui/renderers/android_renderer.cr:37:  #   explicitly freed with DeleteGlobalRef.
src/ui/renderers/android_renderer.cr:208:    fun android_view_apply_glass(env : Void*, view : Void*, blur_radius : Float32, fallback_argb : Int32) : Int32
src/ui/renderers/android_renderer.cr:2195:      applied_real_blur = LibAndroidBridge.android_view_apply_glass(
src/ui/native/android_bridge.c:1465:    return (*env)->NewGlobalRef(env, (jobject)local_ref);
src/ui/native/android_bridge.c:1471:        (*env)->DeleteGlobalRef(env, (jobject)global_ref);
src/ui/native/android_bridge.c:1483:int32_t android_view_apply_glass(void *env_ptr, void *view, float blur_radius, int32_t fallback_argb) {
src/ui/native/jni_collection_bridge.c:155:    return (*env)->NewGlobalRef(env, (jobject)local_ref);
src/ui/native/jni_collection_bridge.c:161:        (*env)->DeleteGlobalRef(env, (jobject)global_ref);
src/ui/native/swiftkit_bridge.m:266:APSK_OVERRIDES_NEW(apsk_glass_background_overrides_new,      "APSKGlassBackgroundOverrides")
src/ui/native/release_strategy.cr:14:  #   `NewGlobalRef`. Must be freed with `DeleteGlobalRef` via the JNI environment.
src/ui/native/swiftkit_bridge.cr:100:    fun apsk_glass_background_overrides_new : Void*
src/ui/native/swiftkit_bridge.cr:252:    # writes a +1 retained pointer to an `ObservableObject` state through
src/ui/native/jni_handle.cr:12:  # - **Global refs**: Created via `NewGlobalRef`, valid across native calls
src/ui/native/jni_handle.cr:13:  #   until explicitly freed with `DeleteGlobalRef`. Crystal MUST manage these.
src/ui/native/jni_handle.cr:23:    # This calls `NewGlobalRef(env, local_ref)` to create a durable reference,
src/ui/native/jni_handle.cr:27:    # The `env` pointer is needed for the `NewGlobalRef` call but is NOT stored
src/ui/native/jni_handle.cr:46:    # `DeleteGlobalRef` on release.
src/ui/native/native_handle.cr:53:    # an `ObservableObject` state container (`APSKLabelState`,
src/ui/native/jni_collections.cr:14:  # - **GLOBAL refs**: Created via `NewGlobalRef`, valid across native calls
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextFieldFacade.swift:54:final class TextStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextFieldFacade.swift:55:    @Published var text: String
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift:11:// which retains an `APSKSheetState : ObservableObject` and writes the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:9:final class BoolStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:10:    @Published var value: Bool
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:40:final class DoubleStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:41:    @Published var value: Double
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:65:final class IntStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:66:    @Published var value: Int
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:83:final class DateStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:84:    @Published var value: Date
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:101:final class ColorStorage: ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ValueStorage.swift:102:    @Published var value: Color
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:1:// ReactiveState — ObservableObject containers that back Phase 3 Remediation 4
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:14://   `@_cdecl` mutator functions that update the `@Published` field. SwiftUI
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:26://     the `@Published` property on the main queue (SwiftUI publishes require
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:48:public final class APSKLabelState: NSObject, ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:49:    @Published public var text: String
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:60:public final class APSKButtonState: NSObject, ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:65:    @Published public var backgroundColor: APSKPlatformColor?
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:66:    @Published public var foregroundColor: APSKPlatformColor?
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:67:    @Published public var cornerRadius: NSNumber?
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:83:// The Toggle and Slider facades already own an `ObservableObject` storage
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:86:// parallel state objects: the storage already carries the `@Published`
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:97:public final class APSKSheetState: NSObject, ObservableObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:98:    @Published public var isPresented: Bool
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ReactiveState.swift:113:// All mutations dispatch onto the main queue. SwiftUI's `@Published`
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/ReactiveStateTests.swift:5://   3. Asserts the `@Published` property reflects the mutation.

exec
/bin/zsh -lc 'rg -n "GlassBackground|glass_background" src/ samples/ | wc -l && rg -c "backdrop-filter" src/ui/renderers/web_renderer.cr && rg -c "0x[0-9A-F]{2}FFFFFF" src/ui/renderers/android_renderer.cr && rg -c "UIVisualEffectView|UIBlurEffect" src/ui/renderers/uikit_renderer.cr && rg -c "NSVisualEffectView" src/ui/renderers/appkit_renderer.cr' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
      46
4
1
60
37

exec
/bin/zsh -lc "nl -ba src/ui/renderers/web_renderer.cr | sed -n '1388,1432p;2008,2028p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "rg -n \"@supports|material|ap-material|backdrop-filter|color-mix|supports\" src/ui/renderers/web_renderer.cr src/ui/design_tokens.cr src/ui/design_tokens/material.cr spec/ui/design_tokens spec/ui/renderers scripts samples/cross_platform docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization -g '"'!*.png'"'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  1388	        el = Components::Elements::Div.new
  1389	        c = view.color
  1390	        color_css = "rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a})"
  1391	        if view.orientation == :horizontal
  1392	          el.add_style("height: #{view.thickness}px; background: #{color_css}; width: 100%")
  1393	        else
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
  2008	        else
  2009	          @root = el
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

 succeeded in 0ms:
src/ui/design_tokens/material.cr:3:    # One material strength step.
src/ui/design_tokens/material.cr:5:    # Per-step values declare how a particular `UI::GlassBackground#material`
src/ui/design_tokens/material.cr:7:    # on web (via `calc()` against `--ap-material-intensity`) and on Android
src/ui/design_tokens/material.cr:11:    # `docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml`
src/ui/design_tokens/material.cr:15:      opacity : Float64,        # 0..1 — fill opacity (web color-mix, Android alpha)
src/ui/design_tokens/material.cr:19:    # Glass material token branch.
src/ui/design_tokens/material.cr:30:    # `GlassBackground#material` symbol maps 1:1 to a SwiftUI Material case.
src/ui/design_tokens/material.cr:31:    # `intensity` does NOT shift Apple per-view material steps — a view
src/ui/design_tokens/material.cr:32:    # declaring `material: :thick` always renders `.thickMaterial` regardless
src/ui/design_tokens/material.cr:37:    # When the declared material is `:regular` (the default for unspecified
src/ui/design_tokens/material.cr:53:    # (so 1.8 -> :chrome). `material_spec.cr` pins these exact boundary
src/ui/design_tokens/material.cr:63:      # `:regular` rather than raising — `UI::GlassBackground#material` is
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
src/ui/renderers/web_renderer.cr:1405:        # Phase 5: glass material is tokenized. The inline style references
src/ui/renderers/web_renderer.cr:1406:        # the per-step `--ap-material-*` custom properties the WebGenerator
src/ui/renderers/web_renderer.cr:1408:        # `calc(<base>px * var(--ap-material-intensity, 1))`). The
src/ui/renderers/web_renderer.cr:1409:        # `ap-glass--<step>` class binds to the `@supports` fallback rule.
src/ui/renderers/web_renderer.cr:1410:        step_key = material_css_step_key(view.material)
src/ui/renderers/web_renderer.cr:1414:          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1415:          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1416:          "background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step_key}) * 100%), transparent); " \
src/ui/renderers/web_renderer.cr:1434:      # Map a `GlassBackground#material` Symbol to the CSS class suffix /
src/ui/renderers/web_renderer.cr:1436:      private def material_css_step_key(name : Symbol) : String
src/ui/renderers/web_renderer.cr:1961:        if view.supports_alpha
src/ui/renderers/web_renderer.cr:1962:          input.set_attribute("data-supports-alpha", "true")
src/ui/renderers/web_renderer.cr:2018:        # `:thin` material step. Inline style references `var(--ap-material-*)`
src/ui/renderers/web_renderer.cr:2019:        # for both backdrop-filter and the opacity-driven color-mix
src/ui/renderers/web_renderer.cr:2020:        # background, so brand intensity AND the @supports fallback both
src/ui/renderers/web_renderer.cr:2024:        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); -webkit-backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")
src/ui/renderers/web_renderer.cr:2170:                             "color-mix(in oklch, var(--ap-color-brand-primary) 40%, transparent)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:4:  branch: "phase-05-glass-material-tokenization"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:12:# 1. Material tokens are render-time resolved values. `tokens.material.intensity`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:15:#    runtime mutator path for material. I-10 (API contract fidelity) documents
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:28:#    spikes/swiftui_material_spike.swift (architect authored 2026-05-22).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:32:#    discovers reactive material is needed, scope expansion surfaces to
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:39:    rationale: "Phase introduces tokenized blur/opacity/saturation/luminance values per material step + an intensity scalar. AMENDED 2026-05-22 per Codex resolution review: iOS 26+ / macOS 26+ use SwiftUI .glassEffect() which is SYSTEM-RESOLVED — material step and intensity become advisory only on the Liquid Glass path. Step+intensity ARE enforced on the pre-26 fallback .background(.material) path AND on web (backdrop-filter scaled by intensity) AND on Android (RenderEffect radius scaled by intensity API 31+, alpha fallback < API 31). Phase 5 implementer authors the per-step visual baseline probes for the controllable paths."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:43:        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_default_spec.cr that captures and diffs glass appearance per material step. Probe harness path is Phase 6.5 work; until then validator architect-adjudicates pending Phase 6.5 ship."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:47:        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_default_spec.cr; same as iOS — verification harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:58:    rationale: "Material tokens are RENDER-TIME RESOLVED VALUES. Phase 5 does NOT add a runtime mutator path for material.intensity. Consumers re-render the view tree to see intensity changes; the existing Phase 3 reactive bridge (Label/Button/Toggle/Slider/Sheet) is unchanged. This is a deliberate contract limitation; see I-10 for the documented API contract."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:71:    rationale: "Glass material is a pure render-side concern; no new event paths, no new callback registration, no new main-thread/run-loop semantics introduced. Existing Phase 3 R4 + R10 event paths remain authoritative."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:110:    rationale: "Glass surfaces sit behind text. WCAG-AA contrast must hold for text-on-blurred-background at every material step AND at every intensity value (including the documented 1.3 brand-override example in the README). This is a NEW audit dimension Phase 5 introduces. Dynamic-type response on glass surfaces also belongs here (text must still meet contrast at largest type sizes). Phase 5 implementer authors the contrast audit probes."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:114:        reason: "Phase 5 implementer authors spec/ui/glass_material/ios_glass_contrast_spec.cr (text-on-each-material-step AA contrast verification); harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:118:        reason: "Phase 5 implementer authors spec/ui/glass_material/macos_glass_contrast_spec.cr; harness is Phase 6.5"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:142:    rationale: "AMENDED 2026-05-22 per Codex resolution review. Original brief overclaimed `extends` for env-response. Reality: Phase 5 DELEGATES env-response on Apple platforms — SwiftUI Material + .glassEffect() automatically respect Reduce Motion, Increase Contrast, dark mode. Phase 5 ships no production code for cross-platform forced-colors / prefers-reduced-motion handling on web; that's Phase 6.5's audit harness work. Phase 5 probe placeholders for env_response cells were authored (spec/ui/glass_material/*_env_response_spec.cr) as pending bodies declaring the slug names Phase 6.5 will hook. So I-8 is `preserves` on Apple (system handles it; Phase 5 doesn't intercept) and cross-platform delivery is explicitly deferred to Phase 6.5."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:144:      ios: "spec/ui/glass_material/ios_glass_env_response_spec.cr"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:145:      macos: "spec/ui/glass_material/macos_glass_env_response_spec.cr"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:155:    rationale: "Phase 5 introduces NO new Crystal class vars with initializers AND NO new Crystal::once-protected lazy lookups (token VALUES live in existing Tokens struct instances; resolution is method dispatch, not lazy class-var init). The class-init systematic fix remains deferred to a future phase. If Phase 5 implementer discovers a new class-var is required (e.g., for a material-specific singleton), the implementer MUST stop and surface to architect — the new class-var requires either (a) explicit .reset in hig_bridge.cr#initialize_runtime, OR (b) lazy-instance pattern with nil default and method-side initialization."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:171:    rationale: "New public token API: tokens.material with per-step blur/opacity/saturation/luminance + intensity Float64 scalar. Phase 5 commits to: (1) intensity is RENDER-TIME ONLY — runtime mutation requires a re-render of the view tree; (2) SwiftUI Material's discrete enum quantizes intensity (see adapter_cardinality row 1); (3) web @supports fallback for backdrop-filter unavailability; (4) Android API < 31 alpha-fallback. All four are documented contract limitations consumers MUST understand."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:196:    claim: "SwiftUI Material API accepts the Material enum values Phase 5 emits (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .ultraThickMaterial) AND the .background(Material) modifier on a SwiftUI View on iOS 26.5 + macOS 26.5. NOTE 2026-05-22 per Codex resolution review: .chromeMaterial does NOT exist in public SwiftUI; Phase 5's :chrome step maps to .ultraThickMaterial (or .bar where chrome-tinted styling is wanted). The spike at spikes/swiftui_material_spike.swift uses .bar — that's the alternative."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:197:    falsifier: "Compiling spikes/swiftui_material_spike.swift returns non-zero exit on either iOS or macOS"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:198:    verification: "test -f spikes/swiftui_material_spike.swift && xcrun --sdk iphonesimulator swiftc -emit-library -target arm64-apple-ios16.0-simulator -o /tmp/spike-ios.dylib spikes/swiftui_material_spike.swift && xcrun --sdk macosx swiftc -emit-library -o /tmp/spike-macos.dylib spikes/swiftui_material_spike.swift"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:211:    claim: "Web renderer post-Phase-5 has exactly 4 backdrop-filter occurrences (the standard + -webkit- prefix variants on each of the 2 touched call sites). Pre-dispatch was 2 at SHA 2285fa1."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:213:    verification: "test \"$(grep -c 'backdrop-filter' src/ui/renderers/web_renderer.cr | tr -d ' ')\" = \"4\""
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:231:    # added references in src/ui/design_tokens/material.cr (doc comments),
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:233:    # cascade demo), and the spec/ui/glass_material/ probe placeholders.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:238:  - fact: "backdrop-filter emission count in web_renderer.cr"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:239:    query: "grep -c 'backdrop-filter' src/ui/renderers/web_renderer.cr | tr -d ' '"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:243:    # explicit -webkit-backdrop-filter prefixes alongside the standard
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:244:    # backdrop-filter calls on both touched sites (GlassBackground +
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:247:    # through var(--ap-material-blur-<step>).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:254:    # Material getter on Tokens, the override_material hook on Brand,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:255:    # the material parameter on copy_with, and the Defaults.material
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:258:  - fact: "Android renderer alpha-step hex literals (5 material steps + 1 default fallback = 6)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:282:    adapter_input_space: "5 discrete material steps on pre-26 path; system-resolved single Glass surface on 26+ Liquid Glass path"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:285:    documented_degradation: "QUANTIZATION TABLE (consumer-visible, pre-26 path only): intensity 0.0–0.3 → .ultraThinMaterial; 0.3–0.7 → .thinMaterial; 0.7–1.3 → .regularMaterial; 1.3–1.8 → .thickMaterial; 1.8+ → .ultraThickMaterial. AMENDED 2026-05-22 per Codex resolution review: on iOS 26+ / macOS 26+, the renderer uses SwiftUI .glassEffect() which is system-resolved — the system decides the material strength regardless of the app's intensity. App-side step + intensity are therefore ADVISORY on the Liquid Glass path. Consumers running on 26+ get uniform Liquid Glass; consumers on pre-26 fallback get the quantized material per the table. Brands wanting deterministic per-step rendering must either target pre-26 OR override the GlassBackground.material step explicitly (which the system may still override on 26+)."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:288:  - public_api: "UI::DesignTokens::Material#blur_radius (Float64 px, per material step, scaled by intensity)"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:289:    adapter: "CSS backdrop-filter: blur() on web"
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:293:    documented_degradation: "Browsers without backdrop-filter (detected via @supports not (backdrop-filter: blur(1px))) fall back to background-color: color-mix(in oklch, var(--ap-color-surface-panel) Z%, transparent) where Z is per-step opacity (ultra_thin=20%, thin=40%, regular=60%, thick=73%, chrome=87%). No blur. WCAG-AA contrast verified for text-on-fallback as well as text-on-blurred. Visible glass surfaces remain visually distinguishable via opacity alone."
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:14:- **iOS:** `UIVisualEffectView` + `UIBlurEffect` with system materials (ultra_thin, thin, regular, thick, chrome) — **works correctly** but the material strength is hard-coded in `uikit_renderer.cr`, not driven by a token.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:15:- **macOS:** `NSVisualEffectView` with the same materials — **works correctly** but again hard-coded.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:16:- **Web:** `backdrop-filter: blur(Xpx)` with hard-coded blur amounts (`:ultra_thin` → 10px) and a hard-coded 72% opacity color-mix. **Static approximation.** No fallback for browsers without `backdrop-filter`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:17:- **Android:** Placeholder — semi-transparent white `FrameLayout`. No actual blur even though API 31+ supports `RenderEffect.createBlurEffect`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:21:This phase makes glass material strength a first-class token, wires it through all four renderers, and adds a brand-overridable intensity multiplier.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:28:  - The five material strength steps (`ultra_thin`, `thin`, `regular`, `thick`, `chrome`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:32:  - `uikit_renderer.cr` and `appkit_renderer.cr`: pass the resolved material parameters into the SwiftUI bridge facade for `GlassBackground`. SwiftUI side applies `.background(.regularMaterial)` or `.background(Material(...))` with overrides where the brand intensity adjusts.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:33:  - `web_renderer.cr`: emit `backdrop-filter: blur(var(--ap-material-blur-{step}))` with the variable computed from `tokens.material.blur * tokens.material.intensity`. Add `-webkit-` prefix. Add fallback color for browsers without `backdrop-filter` (detected via `@supports not (backdrop-filter: blur(1px))`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:35:- Brand override demo. A sample theme file shows how to declare `material.intensity = 1.3` for a more frosted look and verify the change cascades to all four platforms.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:38:  - Web CSS emission (correct `clamp` / `var()` references, `@supports` fallback present).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:39:  - Native renderer: verify the SwiftUI facade receives the resolved material params, not hard-coded constants.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:44:- Adding new material steps beyond the five. The five are sufficient for parity with iOS/macOS system materials.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:45:- Animated material transitions (e.g., glass "fluidifying" when scrolled over). The user can declare a motion token to animate intensity, but the renderers in this phase don't do animation orchestration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:46:- Replacing the existing `GlassBackground` widget API. The widget keeps its current `material : Symbol` property; the symbol now resolves through the token system instead of being hard-coded in renderers.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:52:- Setting `material.intensity` on the brand declaration changes the visible glass strength on all four platforms — verified by screenshot diff.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:53:- Web glass uses `@supports` fallback correctly: in a browser without `backdrop-filter` (test by overriding the support check), the surface falls back to the documented solid color with appropriate opacity.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:62:- **Web `backdrop-filter` performance** can be poor on stacked layers. The renderer should not double-apply backdrop-filter (e.g., a glass surface inside another glass surface — the inner one inherits the parent's already-blurred content). Validator should check stacking.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/README.md:69:- **Phase Brief (YAML, validator-enforced):** `brief.yml` — passes `crystal run scripts/validate_phase_brief.cr -- phases/phase-05-glass-material-tokenization/brief.yml` (exit 0 mandatory before dispatch). Declares all 11 invariant cells, lower-layer assumptions about SwiftUI Material API + backdrop-filter support + Android RenderEffect, repo-derived facts (37 GlassBackground references, 2 backdrop-filter sites in web_renderer.cr, 35311-byte design_tokens.cr), and 3 adapter cardinality MISMATCH rows for SwiftUI's discrete material enum, web `@supports` fallback, and Android < API 31 fallback. Architect-authored 2026-05-22 per `handoff/planning-retrospective-2026-05-22.md` Phase Brief Template.
samples/cross_platform/android_host/android_material_bridge.cr:235:      stack.test_id = "android-material-study-root"
samples/cross_platform/android_host/android_material_bridge.cr:275:      card.material = :secondary
samples/cross_platform/android_host/android_material_bridge.cr:350:      tertiary_card.material = :tertiary
samples/cross_platform/android_host/android_material_bridge.cr:537:      picker.supports_alpha = true
samples/cross_platform/android_host/android_material_bridge.cr:563:      activity.share_url = "https://asset-pipeline.local/android-material"
samples/cross_platform/android_host/android_material_bridge.cr:576:      web.base_url = "https://asset-pipeline.local/android-material"
samples/cross_platform/android_host/build_crystal_lib.sh:7:OUTPUT_NAME="${OUTPUT_NAME:-android_material_host}"
samples/cross_platform/android_host/build_crystal_lib.sh:8:BRIDGE_SRC="$SCRIPT_DIR/android_material_bridge.cr"
samples/cross_platform/android_host/README.md:7:- shared validation truth lives under `docs/android-material-validation/`
samples/cross_platform/android_host/README.md:75:./scripts/run_android_material_tests.sh --serial emulator-5554 --device-role phone --appearance both
samples/cross_platform/android_host/README.md:76:./scripts/run_android_material_tests.sh --serial emulator-5556 --device-role tablet --appearance both --skip-build
samples/cross_platform/android_host/README.md:86:  matches your local source tree. If you changed `android_material_bridge.cr`,
samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:1:// Phase 5 — Glass material helper for the Android renderer.
samples/cross_platform/android_host/app/src/main/java/com/assetpipeline/glass/AssetPipelineGlassHelper.java:4:// the material step from tokens and calls into the JNI bridge function
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/CrystalBridge.kt:12:        System.loadLibrary("android_material_host")
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:11:Promote glass material strength from hard-coded per-renderer constants to a first-class branch of the `UI::DesignTokens` system. Wire every renderer — web, AppKit, UIKit, and Android — to read material parameters from the resolved token tree. Add a brand-overridable `intensity` scalar so a single line in a brand declaration uniformly scales how frosted glass surfaces appear on all four platforms. Add a `@supports` fallback for web browsers without `backdrop-filter`. Add a real `RenderEffect.createBlurEffect` path on Android API 31+ with a graceful pre-API-31 fallback.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:13:After this phase, no renderer file contains a hard-coded blur radius or material constant for `GlassBackground` (or for any other glass-using widget — see deviation prompt below). All of those values flow from `tokens.material`. A brand declaration in `samples/cross_platform/` can change `material.intensity` to `1.3` and produce visibly more frosted glass on all four platforms with no other code changes.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:25:- [ ] `src/ui/views/glass_background.cr` — the widget. Note that `material : Symbol` is the public API; that does not change in this phase.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:42:- `src/ui/design_tokens.cr` — Phase 1's source-of-truth. You add a `material : Material` getter on the `Tokens` aggregate. Do not redefine the namespace.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:43:- `src/ui/views/glass_background.cr` — the widget. `material : Symbol` public API is unchanged.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:53:- `src/ui/design_tokens/material.cr` — the new `Material` type and `Step` substruct.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:54:- `spec/ui/design_tokens/material_spec.cr`, `spec/ui/design_tokens/web_generator_material_spec.cr`, four renderer-specific specs (`spec/ui/renderers/{web,uikit,appkit,android}_glass_spec.cr`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:59:The prior audit (`handoff/plan-quality-audit-2026-05-20.md` §A) noted that Phase 5 references `LibSwiftKitBridge.material_parameters_new(...)` and `LibSwiftKitBridge.glass_background_overrides_new(...)`, but Phase 3 ships a `lib LibObjCBridge` plus a `SwiftKit` Crystal module — `LibSwiftKitBridge` was never explicitly named. Phase 3's revised "Existing infrastructure to use" section now creates `src/ui/native/lib_swiftkit_bridge.cr` as the typed wrapper. **Phase 5 references the same module — if you find `LibSwiftKitBridge` is not defined when you start Phase 5, the Phase 3 implementer did not ship the typed wrapper they were supposed to. Surface this to the team lead before freelancing.** The cross-phase naming contract is `LibSwiftKitBridge` (typed wrapper, defined in `src/ui/native/lib_swiftkit_bridge.cr`); do not coin a new name.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:65:| Material step set | `:ultra_thin, :thin, :regular, :thick, :chrome` | Five steps. Must match what `GlassBackground#material` accepts. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:67:| CSS variable prefix | `--ap-material-*` | Inherited from Phase 1's `--ap-*` standard. No `--amber-material-*` aliases. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:68:| AppKit material translation marker | `# AppKit material translation table — only allowed hard-coded glass switch` | **Exact text required**, em dash `—`. Validator check 8 enforces. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:70:| `@supports` fallback opacity | 94% on `regular` tier (per phase brief) | Used when neither `backdrop-filter` nor `-webkit-backdrop-filter` are supported. |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:76:| `src/ui/design_tokens/material.cr` | `src/ui/design_tokens.cr` (add `material` getter on `Tokens`) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:77:| `spec/ui/design_tokens/material_spec.cr` + 4 renderer-specific glass specs | `src/ui/renderers/{web,uikit,appkit,android}_renderer.cr` (token-driven glass) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:79:| `AssetPipelineGlassHelper.java` (Android API 31+ blur helper) | `src/ui/native/lib_swiftkit_bridge.cr` (from Phase 3, extended for material params) |
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:85:The Phase 5 scope in `README.md` names `GlassBackground` as the widget being tokenized. However, the existing Apple renderers hard-code `NSVisualEffectMaterial` / `UIBlurEffectStyle` constants inside the visit methods for **TabView, Alert, Sidebar (NavigationSplitView), Toolbar, Sheet, and Popover** as well. If Phase 5 only tokenizes the `GlassBackground` visit, brand `material.intensity = 1.3` will not cascade to those other glass surfaces — only to the ones the developer explicitly wraps in `GlassBackground`. That is almost certainly the wrong behavior for a brand-cascade phase.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:87:**Required action:** Extend the refactor to every visit method that today calls `setMaterial:` with a hard-coded constant. The resolution path is identical to `GlassBackground` — pick the semantic material name (`:popover`, `:sheet`, `:sidebar`, `:toolbar`, etc.), look it up in the token tree, pass the resolved parameters to the renderer call.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:95:Add a new subtype under the existing `UI::DesignTokens` namespace (Phase 1's deliverable). File: `src/ui/design_tokens/material.cr`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:102:    # Glass material parameters.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:105:    # public `GlassBackground#material` symbol values, plus a global
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:113:      # One material strength step.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:120:        # Tint opacity applied to the surface fill (`color-mix` percentage on web,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:121:        # alpha component on Android, automatic on Apple where the system material
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:126:        # Web emits as a second `backdrop-filter` argument (`saturate(N)`); Apple
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:127:        # ignores (system material handles saturation); Android ignores at API 31+
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:132:        # Used by the fallback paths (web `@supports` fallback, Android pre-31)
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
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:354:  ptr = LibSwiftKitBridge.glass_background_facade_make(material_params, overrides)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:371:- `LibSwiftKitBridge.material_parameters_new(...)` — Phase 3 §7.4 already declares this `fun` as part of the Phase 5 hand-off (`fun material_parameters_new : Void*` plus the per-step setter pattern, with the actual fields populated by Phase 5 setter helpers).
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
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:424:backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:425:-webkit-backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular));
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:426:background: color-mix(in oklch,
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:428:    calc(var(--ap-material-opacity-regular) * 100%),
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:433:### `@supports` fallback block
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:435:Emitted once in the stylesheet root by the generator. Targets browsers where `backdrop-filter` is unsupported (no Safari/WebKit prefix path either):
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:438:@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:439:  .ap-glass--ultra-thin { background: color-mix(in oklch, var(--ap-color-surface-panel) 90%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:440:  .ap-glass--thin       { background: color-mix(in oklch, var(--ap-color-surface-panel) 92%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:441:  .ap-glass--regular    { background: color-mix(in oklch, var(--ap-color-surface-panel) 94%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:442:  .ap-glass--thick      { background: color-mix(in oklch, var(--ap-color-surface-panel) 96%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:443:  .ap-glass--chrome     { background: color-mix(in oklch, var(--ap-color-surface-panel) 98%, transparent); }
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:451:Add `ap-glass` and `ap-glass--{step}` classes to the emitted `<div>`. Inline style still wins for the live `backdrop-filter` value; the class selectors exist for the `@supports` fallback to bind to. Do **not** delete the inline style — older user agents that don't support `@supports` need the inline form to render the live path.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:509:  resolved = tokens.material.resolve(view.material)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:553:The current `appkit_renderer.cr` `visit(view : UI::GlassBackground)` (lines 2734–2774) hard-codes a switch on `view.material` to an integer `NSVisualEffectMaterial` constant. After Phase 5 it becomes:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:557:  resolved = tokens.material.resolve(view.material)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:561:  # UIKit <-> AppKit material translation.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:562:  appkit_material = case resolved.apple_material_constant
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:571:  material_params = LibSwiftKitBridge.material_parameters_new(
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:576:    appkit_material,
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
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:637:8. **`[Phase 5] Extend material tokenization to TabView, Alert, Sidebar, Toolbar, Sheet, Popover visitors`**
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:639:   - Every visit method that today calls `setMaterial:` with a hard-coded integer now reads from `tokens.material.resolve(:semantic_name)`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:652:# Demonstrates that setting material.intensity on the brand declaration
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
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:733:2. Every renderer's `visit(view : UI::GlassBackground)` reads from `tokens.material.resolve(view.material)` — no hard-coded numbers in any of the four files.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:736:5. The web stylesheet emits the `--ap-material-*` custom properties and the `@supports not (backdrop-filter)` fallback block. Verified by reading the generated CSS.
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/StudyCatalog.kt:20:            lane = "material-defaults",
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/StudyCatalog.kt:29:            lane = "material-defaults",
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/StudyCatalog.kt:38:            lane = "material-defaults",
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/StudyCatalog.kt:47:            lane = "material-defaults",
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/StudyCatalog.kt:56:            lane = "material-defaults",
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/StudyCatalog.kt:74:            lane = "material-defaults",
samples/cross_platform/android_host/app/src/main/AndroidManifest.xml:9:        android:supportsRtl="true"
samples/cross_platform/android_host/app/src/main/java/dev/assetpipeline/androidhost/MainActivity.kt:11:import com.google.android.material.chip.Chip
samples/cross_platform/ios_host/Sources/ContentView.swift:37:/// UIVisualEffectView materials can composite against real image content
samples/cross_platform/ios_host/Sources/CrystalHIGHostApp.swift:46:// UIWindow so the Liquid Glass materials sample the correct trait
samples/cross_platform/ios_host/Sources/CrystalHIGHostApp.swift:49:// authoritative knob for UIVisualEffectView material resolution.
samples/cross_platform/ios_host/Sources/CrystalHIGHostApp.swift:53:// UIVisualEffectView materials can blur through real image content rather
samples/cross_platform/ios_host/Sources/CrystalHIGHostApp.swift:94:                // visible content that glass materials blur through.
samples/cross_platform/ios_host/UITests/HIGVisualTests.swift:24:// UIVisualEffectView materials fully composite before the screenshot is taken.
samples/cross_platform/ios_host/UITests/HIGVisualTests.swift:59:        //   - 0.8s was insufficient for UIVisualEffectView materials to
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
spec/ui/design_tokens/material_spec.cr:7:      m = UI::DesignTokens::Defaults.material
spec/ui/design_tokens/material_spec.cr:16:      m = UI::DesignTokens::Defaults.material
spec/ui/design_tokens/material_spec.cr:23:      m = UI::DesignTokens::Defaults.material
spec/ui/design_tokens/material_spec.cr:32:      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.3)
spec/ui/design_tokens/material_spec.cr:38:      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 0.5)
spec/ui/design_tokens/material_spec.cr:44:      m_low = UI::DesignTokens::Defaults.material.copy_with(intensity: 0.0)
spec/ui/design_tokens/material_spec.cr:47:      m_neg = UI::DesignTokens::Defaults.material.copy_with(intensity: -1.0)
spec/ui/design_tokens/material_spec.cr:50:      m_high = UI::DesignTokens::Defaults.material.copy_with(intensity: 10.0)
spec/ui/design_tokens/material_spec.cr:55:      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 2.0)
spec/ui/design_tokens/material_spec.cr:64:      m = UI::DesignTokens::Defaults.material
spec/ui/design_tokens/material_spec.cr:73:      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.5)
spec/ui/design_tokens/material_spec.cr:80:      base = UI::DesignTokens::Defaults.material
spec/ui/design_tokens/material_spec.cr:96:      base = UI::DesignTokens::Defaults.material
spec/ui/design_tokens/material_spec.cr:115:      tokens.material.intensity.should eq(1.3)
spec/ui/design_tokens/material_spec.cr:117:      UI::DesignTokens::Tokens.default.material.intensity.should eq(1.0)
spec/ui/design_tokens/material_spec.cr:123:  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
spec/ui/design_tokens/material_spec.cr:124:    material.copy_with(intensity: 1.3)
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:34:**What:** `GlassBackground` at default intensity (`tokens.material.intensity == 1.0`) on iOS renders the platform-correct surface. On iOS 26+, Liquid Glass appears automatically (system Material). On iOS 15–25, regular blur via system Material. No fallback flat fill.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:46:**What:** `GlassBackground` at default intensity on macOS renders the platform-correct surface (`NSVisualEffectView` material backed; on macOS 26+, Liquid Glass appears automatically via SwiftUI `Material`).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:52:**Pass:** Five tiers visible with the expected blur progression. The macOS material translation (UIKit constant → AppKit constant) produces a `regular`-tier result that looks like `NSVisualEffectMaterial.windowBackground`, not like `light` or `medium`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:57:### Check 3 — `glass.web-default-intensity-renders-with-supports-fallback`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:59:**What:** On web at default intensity, a `GlassBackground.new(material: :regular)` produces:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:60:1. An inline `backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular))` declaration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:61:2. A `-webkit-backdrop-filter:` fallback in the same declaration.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:62:3. A `color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-regular) * 100%), transparent)` background.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:63:4. A `@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px)))` block in the stylesheet root with five `.ap-glass--{step}` rules.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:66:2. Grep the output: `grep -n 'backdrop-filter\|@supports\|ap-material-blur' samples/cross_platform/dist/glass_intensity_demo.html samples/cross_platform/dist/styles.css`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:68:4. To verify the `@supports` fallback path: temporarily override the support check in DevTools by adding a CSS rule that forces `.ap-glass--regular` to ignore `backdrop-filter` (set `backdrop-filter: none !important` in an inline `<style>` injected via the MCP). Confirm the panel does **not** become invisible — it must show the higher-opacity fallback fill. Capture this screenshot too. Revert the override before moving on.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:82:**Pass:** API 33 capture shows a visibly blurred panel. API 29 capture shows the documented semi-transparent fill (no blur, but readable panel separation). The renderer file no longer contains the `0x33FFFFFF / 0x66FFFFFF / 0x99FFFFFF / 0xBBFFFFFF / 0xDDFFFFFF` literal switch — those values now derive from `tokens.material.resolve(...).opacity` and `tokens.colors.surface_panel`.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:89:**What:** Setting `material.intensity = 1.5` produces visibly more frosted glass on all four platforms.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:102:**What:** Setting `material.intensity = 0.5` produces visibly less frosted glass on all four platforms.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:104:**Pass:** All four platforms show measurable difference *in the opposite direction*. On the `regular` tier, text behind the panel should be more readable at 0.5 than at 1.0. iOS 26+ Liquid Glass should still appear (the `.background(material)` base is unchanged; only the additive `.blur(_:)` modifier delta has flipped sign — verify the SwiftUI bridge handles negative deltas gracefully or clamps the additive blur to zero).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:106:**Note for validator:** The Swift bridge's "delta blur" approach (additive `.blur()` on top of `Material`) means intensity < 1.0 needs a *negative* delta — but SwiftUI's `.blur(radius:)` clamps negative values to zero, which means iOS *cannot make blur lower than the system material's baseline*. This is an Apple-API limitation, not an implementer failure. Confirm with the implementer's handoff whether they documented this and whether the visual difference at 0.5 is therefore smaller on iOS than on web/Android. If the visual difference on iOS at 0.5 is essentially zero, that is acceptable per the limitation but must be acknowledged; the other three platforms still need a clear visible difference.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:114:1. Write a small ad-hoc demo: a `GlassBackground(material: :regular)` containing a `GlassBackground(material: :thin)` containing text.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:115:2. Render to web. Inspect the resulting HTML/CSS: the inner `.ap-glass--thin` should still emit its own `backdrop-filter`, but the validator should confirm that the *visual* result is not a doubly-frosted panel (i.e., the text behind the *outer* panel is blurred once, the inner panel adds its own slight tint but does not stack a second `blur(20px)` on top of the already-blurred backdrop).
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:123:### Check 8 — `inspection.no-hard-coded-blur-or-material-constants`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:125:**What:** Three renderer files no longer hard-code blur amounts or material constants for glass surfaces:
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:127:- `uikit_renderer.cr` — `visit(view : UI::GlassBackground)` does not contain a `case view.material when :ultra_thin then 8_i64` switch (or equivalent); the integer comes from the resolved token.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:128:- `appkit_renderer.cr` — same as uikit, with **one documented exception**: the UIKit→AppKit translation table. That block is the only acceptable hard-coded glass switch in the entire codebase post-Phase 5 and **must be wrapped with the exact marker comment** `# AppKit material translation table — only allowed hard-coded glass switch` immediately above it (see `implementation.md` §"Mandatory marker comment").
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:132:2. `grep -nB1 'when :ultra_thin\|when :thin\|when :regular\|when :thick\|when :chrome' src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr` and inspect every hit. **The only acceptable hits are inside the AppKit translation table**, identified by the marker comment on the line immediately above the case/switch block. The marker text must be exactly `# AppKit material translation table — only allowed hard-coded glass switch` (em dash `—`, not `--`). Any hit not preceded by this marker (within 1 line of context) is a fail.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:133:3. Confirm the marker is present and unique: `grep -nE '# AppKit material translation table — only allowed hard-coded glass switch' src/ui/renderers/appkit_renderer.cr` must return exactly one match in `appkit_renderer.cr` and zero matches in any other source file.
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:154:- `spec/ui/design_tokens/material_spec.cr`
docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/validation.md:155:- `spec/ui/design_tokens/web_generator_material_spec.cr`
samples/cross_platform/ios_host/hig_bridge.cr:242:    card.material = :secondary
samples/cross_platform/ios_host/hig_bridge.cr:1921:              ios_tb_card.material = :secondary
samples/cross_platform/ios_host/hig_bridge.cr:1975:              ios_sf_card.material = :secondary
samples/cross_platform/ios_host/hig_bridge.cr:2213:              # lifted to 2nd-level material (~#2A1E0D with glass) so placeholder text
samples/cross_platform/ios_host/hig_bridge.cr:2223:              # 2nd-level material dark fill: #2A1E0D (r=0.165 g=0.118 b=0.051, alpha=1).
samples/cross_platform/ios_host/hig_bridge.cr:2447:              ios_tab_bar_card.material = :secondary
samples/cross_platform/ios_host/hig_bridge.cr:2506:              ios_tab_view_card.material = :secondary
samples/cross_platform/ios_host/hig_bridge.cr:2693:              ios_map_card.material = :secondary
samples/cross_platform/ios_host/hig_bridge.cr:2731:              ios_video_card.material = :secondary
samples/cross_platform/android_host/app/src/main/res/layout/activity_main.xml:8:    <com.google.android.material.appbar.MaterialToolbar
samples/cross_platform/android_host/app/src/main/res/layout/activity_main.xml:45:            <com.google.android.material.chip.ChipGroup
samples/cross_platform/android_host/app/src/main/res/layout/activity_main.xml:54:            <com.google.android.material.card.MaterialCardView
samples/cross_platform/android_host/app/src/main/res/layout/activity_main.xml:92:            </com.google.android.material.card.MaterialCardView>
samples/cross_platform/macos_host/window_helper.m:129:    // material sees nothing and renders as a solid fill.
samples/cross_platform/macos_host/window_helper.m:141:    // Opaque + black/white fallback base so the material compositor has a
samples/cross_platform/macos_host/window_helper.m:177://   3. With .withinWindow mode, the material blurs the NSImageView beneath it.
samples/cross_platform/macos_host/window_helper.m:810:// NSVisualEffectView's material compositing is driven by the window server and
samples/cross_platform/macos_host/window_helper.m:813:// and captures only the raw subview hierarchy (solid fill from the material's
samples/cross_platform/android_host/app/build.gradle.kts:63:    implementation("com.google.android.material:material:1.12.0")
scripts/codex_hig_review.sh:77:  in the screenshot. A material object in code is not enough.
samples/cross_platform/macos_host/hig_showcase.cr:215:      # NSVisualEffectView hudWindow material (7) — HIG surface component.
samples/cross_platform/macos_host/hig_showcase.cr:227:      # NSVisualEffectView grouped_card material (setMaterial: 11) tracks appearance.
samples/cross_platform/macos_host/hig_showcase.cr:284:      # The macOS renderer emits an NSVisualEffectView (popover material)
samples/cross_platform/macos_host/hig_showcase.cr:403:      collections_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1094:      tgl_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1175:      tf_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1271:      rings_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1345:      tv_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1466:      label_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1577:      sliders_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1658:      steppers_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1704:      sc_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1757:      cv_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1859:      progress_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:1877:      # macOS: NSVisualEffectView (popover material = 6) wrapping an NSStackView.
samples/cross_platform/macos_host/hig_showcase.cr:1949:      picker_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:2036:      popup_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:2127:      pd_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:2176:      scroll_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:2182:      # is a Liquid Glass NSVisualEffectView (material: menu/toolbar, tracks
samples/cross_platform/macos_host/hig_showcase.cr:2235:      tb_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:2284:      sf_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:2300:      # material so it gets NSVisualEffectView(material: .sidebar) exactly as HIG
samples/cross_platform/macos_host/hig_showcase.cr:2594:      # Wrap sidebar_stack in GlassBackground with sidebar material so the column
samples/cross_platform/macos_host/hig_showcase.cr:2595:      # renders NSVisualEffectView(material: .sidebar) per HIG. The glass view is
samples/cross_platform/macos_host/hig_showcase.cr:2598:      # material (NSVisualEffectMaterialSidebar = 7), tracking appearance.
samples/cross_platform/macos_host/hig_showcase.cr:2600:      sidebar_glass.material = :sidebar
samples/cross_platform/macos_host/hig_showcase.cr:2608:      # Column 1: sidebar glass (188pt, NSVisualEffectView sidebar material)
samples/cross_platform/macos_host/hig_showcase.cr:2823:      # via NSVisualEffectView (NSVisualEffectMaterialMenu, material 10, tracks
samples/cross_platform/macos_host/hig_showcase.cr:2993:      image_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3060:      tab_bar_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3126:      tab_view_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3162:      chart_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3330:      map_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3370:      video_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3420:      study_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3571:      path_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3659:      outline_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:3778:      rating_card.material = :secondary
samples/cross_platform/macos_host/hig_showcase.cr:4282:    # call the capture sees the pre-blur frame (solid fill from the material's
scripts/run_android_material_tests.sh:3:# run_android_material_tests.sh
scripts/run_android_material_tests.sh:7:# screenshots into docs/android-material-validation/screenshots/.
scripts/run_android_material_tests.sh:18:MANIFEST_PATH="$PROJECT_ROOT/docs/android-material-validation/manifest.json"
scripts/run_android_material_tests.sh:19:SCREENSHOT_DIR="$PROJECT_ROOT/docs/android-material-validation/screenshots"
scripts/run_android_material_tests.sh:49:  ./scripts/run_android_material_tests.sh
scripts/run_android_material_tests.sh:50:  ./scripts/run_android_material_tests.sh --only buttons,webview
scripts/run_android_material_tests.sh:51:  ./scripts/run_android_material_tests.sh --device-role tablet --serial emulator-5556
scripts/run_android_material_tests.sh:52:  ANDROID_SERIAL=emulator-5554 ./scripts/run_android_material_tests.sh --appearance light
scripts/run_android_material_tests.sh:65:info() { printf '\033[0;34m[android-material]\033[0m %s\n' "$*"; }
scripts/run_android_material_tests.sh:172:  local dump_path="/sdcard/android-material-ready.xml"
samples/cross_platform/showcase.html:50:<div style="display: flex; flex-direction: column; gap: 24.0px; align-items: center"><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Base Controls</span><button type="button" style="font-size: 17.0px; color: rgba(0, 122, 255, 1.0)">Click Me</button><input type="text" placeholder="Enter text..." style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0)"><img src="icon_placeholder" alt="icon_placeholder" style="object-fit: contain"></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Layout Containers</span><div style="display: flex; flex-direction: row; gap: 12.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Left</span><div style="flex: 1 1 0%"></div><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Right</span></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Selection Controls</span><div style="display: flex; align-items: center; gap: 8px"><input type="checkbox" style="appearance: none; width: 42px; height: 24px; border-radius: 12px; background: #ccc; position: relative; cursor: pointer; transition: background 0.2s"><span>Airplane Mode</span></div><div style="display: flex; align-items: center; gap: 8px"><input type="checkbox"><span>Accept Terms</span></div><div style="display: flex; flex-direction: column; gap: 4px"><div style="display: flex; align-items: center; gap: 8px"><input type="radio" name="radio_4386145664" value="0"><span>Small</span></div><div style="display: flex; align-items: center; gap: 8px"><input type="radio" name="radio_4386145664" value="1" checked="checked"><span>Medium</span></div><div style="display: flex; align-items: center; gap: 8px"><input type="radio" name="radio_4386145664" value="2"><span>Large</span></div></div><div style="display: flex; align-items: center; gap: 8px"><input type="range" min="0.0" max="100.0" value="50.0"></div><div style="display: flex; align-items: center; gap: 8px"><button type="button" style="width: 32px; height: 32px; border: 1px solid #ccc; border-radius: 4px; cursor: pointer">-</button><span style="min-width: 40px; text-align: center">5.0</span><button type="button" style="width: 32px; height: 32px; border: 1px solid #ccc; border-radius: 4px; cursor: pointer">+</button></div><div style="display: inline-flex; border: 1px solid #007AFF; border-radius: 8px; overflow: hidden"><div style="padding: 6px 16px; cursor: pointer; font-size: 14px; background: #007AFF; color: white"><span>Day</span></div><div style="padding: 6px 16px; cursor: pointer; font-size: 14px; background: transparent; color: #007AFF; border-left: 1px solid #007AFF"><span>Week</span></div><div style="padding: 6px 16px; cursor: pointer; font-size: 14px; background: transparent; color: #007AFF; border-left: 1px solid #007AFF"><span>Month</span></div></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Navigation</span><div style="display: flex; align-items: center; gap: 8px; padding: 12px 16px; cursor: pointer" role="link" tabindex="0"><span style="flex: 1">Go to Details</span><span style="color: #999; font-size: 20px">›</span></div><div style="display: flex; flex-direction: column; height: 100%"><div style="flex: 1; overflow: auto"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Home Tab</span></div><div style="display: flex; border-top: 1px solid #e0e0e0; padding: 8px 0" role="tablist"><div style="flex: 1; text-align: center; padding: 4px; cursor: pointer; color: #007AFF; font-weight: 600" role="tab" aria-selected="true"><span>Home</span></div><div style="flex: 1; text-align: center; padding: 4px; cursor: pointer; color: #999" role="tab"><span>Settings</span></div></div></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Date &amp; Time</span><div style="display: flex; align-items: center; gap: 8px"><input type="date" style="border: 1px solid #ccc; border-radius: 6px; padding: 6px 12px"></div><div style="display: flex; align-items: center; gap: 8px"><input type="time" style="border: 1px solid #ccc; border-radius: 6px; padding: 6px 12px"></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Text Input</span><div style="display: flex; align-items: center; gap: 8px"><input type="search" placeholder="Search items..." style="flex: 1; border: 1px solid #ccc; border-radius: 20px; padding: 8px 16px"></div><div style="display: flex; flex-direction: column"><div contenteditable="true" role="textbox" aria-multiline="true" style="border: 1px solid #ccc; border-radius: 6px; padding: 8px; min-height: 80px; color: #999; font-size: 17.0px">Enter notes...</div></div><input type="password" placeholder="Password" style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0)"><div style="display: flex; flex-direction: column; border: 1px solid #ccc; border-radius: 6px; overflow: hidden"><div contenteditable="true" role="textbox" aria-multiline="true" style="padding: 12px; min-height: 200px; outline: none; white-space: pre-wrap; font-size: 17.0px; color: rgba(0, 0, 0, 1.0); color: #999">Code editor...</div></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Feedback &amp; Status</span><div style="display: flex; align-items: center; gap: 8px"><div role="progressbar" style="width: 100%; height: 4px; background: #e0e0e0; border-radius: 2px; overflow: hidden" aria-valuenow="65.0" aria-valuemin="0" aria-valuemax="100"><div style="height: 100%; width: 65.0%; background: #007AFF"></div></div></div><div style="display: flex; align-items: center; gap: 8px"><div role="progressbar" style="width: 24px; height: 24px; border-radius: 50%; border: 3px solid #e0e0e0; border-top-color: #007AFF; animation: spin 1s linear infinite"></div></div><div role="status" style="display: inline-flex; align-items: center; justify-content: center"><div style="width: 24px; height: 24px; border-radius: 50%; border: 2px solid #e0e0e0; border-top-color: #007AFF; animation: spin 1s linear infinite"></div></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Pickers &amp; Lists</span><div style="display: flex; flex-direction: column; gap: 4px"><div role="combobox" style="border: 1px solid #ccc; border-radius: 6px; padding: 8px 12px; cursor: pointer"><div role="option" style="padding: 4px 8px; font-weight: 600" aria-selected="true"><span>Red</span></div><div role="option" style="padding: 4px 8px"><span>Green</span></div><div role="option" style="padding: 4px 8px"><span>Blue</span></div></div></div><div role="list" style="display: flex; flex-direction: column"><div role="listitem" style="padding: 12px 16px"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Item 1</span></div><div role="listitem" style="padding: 12px 16px"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Item 2</span></div><div role="listitem" style="padding: 12px 16px"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Item 3</span></div></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Button Variants</span><button type="button" aria-label="star.fill" style="display: inline-flex; align-items: center; justify-content: center; cursor: pointer; border: none; background: transparent; padding: 4px"><span style="font-size: 24.0px">star.fill</span></button><div role="link" tabindex="0" style="color: #007AFF; cursor: pointer; display: inline" data-href="https://example.com">Visit Website</div><div style="display: inline-block; position: relative"><button type="button" style="display: flex; align-items: center; gap: 4px; padding: 6px 12px; border: 1px solid #ccc; border-radius: 6px; cursor: pointer">Options</button><div style="position: absolute; top: 100%; left: 0; background: white; border: 1px solid #e0e0e0; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); min-width: 150px; z-index: 100" role="menu"><div role="menuitem" style="padding: 8px 16px; cursor: pointer">Edit</div><div role="menuitem" style="padding: 8px 16px; cursor: pointer; color: #FF3B30">Delete</div></div></div><button type="button" role="switch" aria-checked="false" style="background: transparent; color: #333; border: 1px solid #ccc; padding: 8px 16px; border-radius: 8px; cursor: pointer">Bold</button></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Dialogs &amp; Overlays</span><div role="alertdialog" aria-modal="true" style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.4); display: flex; align-items: center; justify-content: center; z-index: 1000"><div style="background: white; border-radius: 14px; padding: 24px; min-width: 270px; max-width: 400px; box-shadow: 0 4px 32px rgba(0,0,0,0.2)"><span style="display: block; font-size: 17px; font-weight: 600; text-align: center; margin-bottom: 8px">Warning</span><span style="display: block; font-size: 13px; text-align: center; color: #555; margin-bottom: 16px">This is an alert message</span></div></div><div role="alertdialog" aria-modal="true" style="display: none"><div style="background: white; border-radius: 14px; padding: 24px; min-width: 270px; max-width: 400px"><span style="display: block; font-size: 17px; font-weight: 600; text-align: center; margin-bottom: 8px">Delete?</span><span style="display: block; font-size: 13px; text-align: center; color: #555; margin-bottom: 16px">This cannot be undone.</span><div style="display: flex; gap: 8px; justify-content: center"><button type="button" style="padding: 8px 24px; border-radius: 8px; border: 1px solid #ccc; cursor: pointer">Cancel</button><button type="button" style="padding: 8px 24px; border-radius: 8px; border: none; background: #007AFF; color: white; cursor: pointer">Confirm</button></div></div></div><div style="display: none"><span>Item saved</span><button type="button" style="border: none; background: transparent; color: #BB86FC; font-weight: 600; cursor: pointer; text-transform: uppercase">Undo</button></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Containers &amp; Surfaces</span><div style="border-radius: 12px; overflow: hidden; box-shadow: 0 2.0px 4.0px rgba(0,0,0,0.12)"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Card Content</span></div><div><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Surface Content</span></div><div style="height: 1.0px; background: rgba(204, 204, 204, 1.0); width: 100%" role="separator"></div><div style="backdrop-filter: blur(30px); -webkit-backdrop-filter: blur(30px); background: rgba(255,255,255,0.7); border-radius: inherit"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Glass Effect</span></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Advanced Navigation</span><div style="display: flex; height: 100%"><div style="width: 250.0px; border-right: 1px solid #e0e0e0; overflow-y: auto"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Sidebar</span></div><div style="flex: 1; overflow-y: auto"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Content Area</span></div></div><div style="display: flex; align-items: center; gap: 8px; padding: 8px 16px; border-bottom: 1px solid #e0e0e0; background: #f8f8f8" role="toolbar"><span style="font-weight: 600; margin-right: auto">Editor</span><button type="button" style="border: none; background: transparent; cursor: pointer; padding: 4px 8px" aria-label="Bold">Bold</button><button type="button" style="border: none; background: transparent; cursor: pointer; padding: 4px 8px" aria-label="Italic">Italic</button></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Grid &amp; Form</span><div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 8.0px 8.0px"><div><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Name</span></div><div><input type="text" placeholder="Enter name" style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0)"></div><div><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Email</span></div><div><input type="text" placeholder="Enter email" style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0)"></div></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Rich Content</span><div style="text-align: left"><span style="color: rgba(0, 0, 0, 1.0); font-weight: bold">Hello </span><span style="color: rgba(0, 0, 255, 1.0); font-style: italic">World</span></div><div style="display: inline-block; position: relative"><img src="https://example.com/image.png" loading="lazy" style="object-fit: contain"></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Shapes</span><div style="width: 50.0px; height: 50.0px; border-radius: 50%; background: rgba(0, 0, 0, 1.0); display: inline-block" data-component="circle"></div><div style="width: 100.0px; height: 50.0px; background: rgba(0, 0, 0, 1.0); display: inline-block" data-component="rectangle"></div><div style="width: 100.0px; height: 50.0px; border-radius: 12.0px; background: rgba(0, 0, 0, 1.0); display: inline-block; border-radius: 12.0px" data-component="rounded-rectangle" data-corner-style="continuous"></div><div style="width: 100.0px; height: 40.0px; border-radius: 9999px; background: rgba(0, 0, 0, 1.0); display: inline-block" data-component="capsule"></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Drawing</span><div style="width: 300.0px; height: 150.0px; position: relative; overflow: hidden; display: inline-block" role="img" data-component="canvas" data-width="300.0" data-height="150.0" data-operations="0"></div><div style="width: 100.0px; height: 100.0px; display: inline-block" data-component="path" data-path="" data-stroke="rgba(0, 0, 0, 1.0)" data-fill="none" data-stroke-width="1.0"></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Media</span><div style="display: inline-block; position: relative; background: #000" data-component="video" data-src="https://example.com/video.mp4" data-autoplay="false" data-muted="false" data-loop="false" data-controls="true"></div><div style="display: inline-block; position: relative; overflow: hidden" data-component="iframe" data-src="https://example.com" data-allows-navigation="true" data-allows-scripts="true"></div><div style="display: inline-block; position: relative; overflow: hidden; background: #e8e0d8" data-component="map" data-latitude="0.0" data-longitude="0.0" data-zoom="10.0" data-map-type="standard" data-shows-user-location="false" data-annotation-count="0"></div><div style="display: inline-block; position: relative" data-component="chart" data-chart-type="bar" data-title="" data-point-count="0" data-show-legend="true" data-show-grid="true"></div></div><div style="display: flex; flex-direction: column; gap: 8.0px; align-items: center"><span style="font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left">Interactive</span><div style="display: flex; align-items: center; gap: 8px"><input type="color" value="#000000"></div><div style="display: inline-block; position: relative" data-component="tooltip" data-tooltip="Hover for info" data-position="top" data-delay="0.5"></div></div></div>
spec/ui/renderers/swiftkit/group1_overrides_spec.cr:261:    it "skips supportsOpacity at default (false)" do
spec/ui/renderers/web_glass_spec.cr:12:  it "emits per-step material custom property references for :regular" do
spec/ui/renderers/web_glass_spec.cr:13:    html = render(UI::GlassBackground.new(material: :regular))
spec/ui/renderers/web_glass_spec.cr:15:    html.should contain("var(--ap-material-blur-regular)")
spec/ui/renderers/web_glass_spec.cr:16:    html.should contain("var(--ap-material-opacity-regular)")
spec/ui/renderers/web_glass_spec.cr:17:    html.should contain("var(--ap-material-saturation-regular)")
spec/ui/renderers/web_glass_spec.cr:21:  it "emits per-step material references for each declared step" do
spec/ui/renderers/web_glass_spec.cr:24:      html = render(UI::GlassBackground.new(material: sym))
spec/ui/renderers/web_glass_spec.cr:26:      html.should contain("var(--ap-material-blur-#{key})")
spec/ui/renderers/web_glass_spec.cr:30:  it "emits the @supports fallback block via theme CSS" do
spec/ui/renderers/web_glass_spec.cr:33:    css.should contain("@supports not ((backdrop-filter: blur(1px))")
spec/ui/renderers/web_glass_spec.cr:38:  it "emits --ap-material-intensity scaled blur via calc()" do
spec/ui/renderers/web_glass_spec.cr:41:    css.should contain("--ap-material-intensity: 1")
spec/ui/renderers/web_glass_spec.cr:42:    css.should contain("--ap-material-blur-regular: calc(30px * var(--ap-material-intensity, 1))")
spec/ui/renderers/web_glass_spec.cr:49:    css.should contain("--ap-material-intensity: 1.3")
spec/ui/renderers/web_glass_spec.cr:54:  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
spec/ui/renderers/web_glass_spec.cr:55:    material.copy_with(intensity: 1.3)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:53:      # Glass-specific default — :regular material is the type default.
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:58:  describe "material override" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:59:    it "skips setMaterial: when material is :regular (type default)" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:60:      view = UI::GlassBackground.new(material: :regular)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:66:    it "emits setMaterial: 'thin' when material is :thin" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:67:      view = UI::GlassBackground.new(material: :thin)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:74:      view = UI::GlassBackground.new(material: :ultra_thin)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:81:      view = UI::GlassBackground.new(material: :thick)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:88:      view = UI::GlassBackground.new(material: :chrome)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:97:      view = UI::GlassBackground.new(material: :regular)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:103:    it "still emits the resolved key when intensity quantization keeps it at :regular but declared material differs" do
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:104:      view = UI::GlassBackground.new(material: :thin)
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr:112:      view = UI::GlassBackground.new(material: :regular)

exec
/bin/zsh -lc "nl -ba src/ui/design_tokens/material.cr | sed -n '1,160p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
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
/bin/zsh -lc "nl -ba src/ui/design_tokens.cr | sed -n '480,540p;740,756p;958,980p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
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
/bin/zsh -lc "rg -n \"class WebGenerator|def generate|material\" src/ui -g '*.cr'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "rg -n \"@supports|ap-glass|ap-material\" src/ui spec/ui/renderers/web_glass_spec.cr spec/ui/design_tokens/web_generator_material_spec.cr scripts -g '"'!*.html'"'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 exited 2 in 0ms:
rg: spec/ui/design_tokens/web_generator_material_spec.cr: No such file or directory (os error 2)
spec/ui/renderers/web_glass_spec.cr:14:    html.should contain("class=\"ap-glass ap-glass--regular\"")
spec/ui/renderers/web_glass_spec.cr:15:    html.should contain("var(--ap-material-blur-regular)")
spec/ui/renderers/web_glass_spec.cr:16:    html.should contain("var(--ap-material-opacity-regular)")
spec/ui/renderers/web_glass_spec.cr:17:    html.should contain("var(--ap-material-saturation-regular)")
spec/ui/renderers/web_glass_spec.cr:25:      html.should contain("ap-glass--#{key}")
spec/ui/renderers/web_glass_spec.cr:26:      html.should contain("var(--ap-material-blur-#{key})")
spec/ui/renderers/web_glass_spec.cr:30:  it "emits the @supports fallback block via theme CSS" do
spec/ui/renderers/web_glass_spec.cr:33:    css.should contain("@supports not ((backdrop-filter: blur(1px))")
spec/ui/renderers/web_glass_spec.cr:34:    css.should contain(".ap-glass--regular")
spec/ui/renderers/web_glass_spec.cr:35:    css.should contain(".ap-glass--ultra-thin")
spec/ui/renderers/web_glass_spec.cr:38:  it "emits --ap-material-intensity scaled blur via calc()" do
spec/ui/renderers/web_glass_spec.cr:41:    css.should contain("--ap-material-intensity: 1")
spec/ui/renderers/web_glass_spec.cr:42:    css.should contain("--ap-material-blur-regular: calc(30px * var(--ap-material-intensity, 1))")
spec/ui/renderers/web_glass_spec.cr:49:    css.should contain("--ap-material-intensity: 1.3")
src/ui/renderers/web_renderer.cr:1406:        # the per-step `--ap-material-*` custom properties the WebGenerator
src/ui/renderers/web_renderer.cr:1408:        # `calc(<base>px * var(--ap-material-intensity, 1))`). The
src/ui/renderers/web_renderer.cr:1409:        # `ap-glass--<step>` class binds to the `@supports` fallback rule.
src/ui/renderers/web_renderer.cr:1411:        el.add_class("ap-glass")
src/ui/renderers/web_renderer.cr:1412:        el.add_class("ap-glass--#{step_key}")
src/ui/renderers/web_renderer.cr:1414:          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1415:          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1416:          "background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step_key}) * 100%), transparent); " \
src/ui/renderers/web_renderer.cr:2018:        # `:thin` material step. Inline style references `var(--ap-material-*)`
src/ui/renderers/web_renderer.cr:2020:        # background, so brand intensity AND the @supports fallback both
src/ui/renderers/web_renderer.cr:2022:        el.add_class("ap-glass")
src/ui/renderers/web_renderer.cr:2023:        el.add_class("ap-glass--thin")
src/ui/renderers/web_renderer.cr:2024:        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); -webkit-backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")
src/ui/design_tokens/generators/web_generator.cr:63:      # `--ap-material-intensity` is the brand-declaration-time scalar (default
src/ui/design_tokens/generators/web_generator.cr:73:        io << "#{indent}--ap-material-intensity: #{format_number(intensity_clamped)};\n"
src/ui/design_tokens/generators/web_generator.cr:85:        io << "#{indent}--ap-material-blur-#{name}: calc(#{format_px(step.blur_radius)} * var(--ap-material-intensity, 1));\n"
src/ui/design_tokens/generators/web_generator.cr:86:        io << "#{indent}--ap-material-opacity-#{name}: #{format_number(step.opacity)};\n"
src/ui/design_tokens/generators/web_generator.cr:87:        io << "#{indent}--ap-material-saturation-#{name}: #{format_number(step.saturation)};\n"
src/ui/design_tokens/generators/web_generator.cr:90:      # `@supports not (backdrop-filter)` fallback block. Browsers without
src/ui/design_tokens/generators/web_generator.cr:93:      # declare, expressed via `var(--ap-material-opacity-<step>)` so
src/ui/design_tokens/generators/web_generator.cr:102:      # The fallback binds to the `.ap-glass--<step>` class names the web
src/ui/design_tokens/generators/web_generator.cr:107:        io << "@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {\n"
src/ui/design_tokens/generators/web_generator.cr:109:          io << "  .ap-glass--#{step} { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step}) * 100%), transparent); }\n"
src/ui/design_tokens/material.cr:7:    # on web (via `calc()` against `--ap-material-intensity`) and on Android
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

 succeeded in 0ms:
src/ui/validation_scenes/dashboard_scene.cr:308:          backdrop_area = GlassBackground.new(material: :ultra_thin)
src/ui/theme.cr:27:  # `material_baseline`) is preserved verbatim so existing call sites keep
src/ui/theme.cr:113:    def self.material_baseline : Theme
src/ui/design_tokens/generators/apple_generator.cr:27:      def generate(tokens : Tokens) : String
src/ui/views/token_field.cr:102:      card.material = :secondary
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
src/ui/design_tokens/material.cr:3:    # One material strength step.
src/ui/design_tokens/material.cr:5:    # Per-step values declare how a particular `UI::GlassBackground#material`
src/ui/design_tokens/material.cr:7:    # on web (via `calc()` against `--ap-material-intensity`) and on Android
src/ui/design_tokens/material.cr:11:    # `docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml`
src/ui/design_tokens/material.cr:19:    # Glass material token branch.
src/ui/design_tokens/material.cr:30:    # `GlassBackground#material` symbol maps 1:1 to a SwiftUI Material case.
src/ui/design_tokens/material.cr:31:    # `intensity` does NOT shift Apple per-view material steps — a view
src/ui/design_tokens/material.cr:32:    # declaring `material: :thick` always renders `.thickMaterial` regardless
src/ui/design_tokens/material.cr:37:    # When the declared material is `:regular` (the default for unspecified
src/ui/design_tokens/material.cr:53:    # (so 1.8 -> :chrome). `material_spec.cr` pins these exact boundary
src/ui/design_tokens/material.cr:63:      # `:regular` rather than raising — `UI::GlassBackground#material` is
src/ui/native/swiftkit_overrides.cr:514:        unless view.material == :secondary
src/ui/native/swiftkit_overrides.cr:515:          sender.set_string(target, :setMaterial, view.material.to_s)
src/ui/native/swiftkit_overrides.cr:604:      # `material` mirrors the Crystal `UI::GlassBackground.material`
src/ui/native/swiftkit_overrides.cr:610:      # renderer has resolved via `tokens.material.apple_step(view.material)`.
src/ui/native/swiftkit_overrides.cr:612:      # resolved Symbol, not from `view.material` directly, so brand
src/ui/native/swiftkit_overrides.cr:616:      # `apple_step` defaults to `view.material` so spec-level callers that
src/ui/native/swiftkit_overrides.cr:619:      def self.populate_glass_background(target : String, view : UI::GlassBackground, sender : Sender, apple_step : Symbol = view.material)
src/ui/native/swiftkit_overrides.cr:624:        # :regular AND the view's declared material differs (brand
src/ui/native/swiftkit_overrides.cr:627:        emit = apple_step != :regular || view.material != :regular
src/ui/native/swiftkit_bridge.cr:18:# material work extends THIS module — it does not introduce a new lib.
src/ui/native/swiftkit_bridge.cr:241:    # glass material backs) or NULL for an empty glass card. Unlike the
src/ui/renderers/appkit_renderer.cr:1048:      # Visit: Alert -> NSVisualEffectView (hudWindow material) inline card
src/ui/renderers/appkit_renderer.cr:1052:      # correct material — it renders the frosted-glass HUD panel that Apple
src/ui/renderers/appkit_renderer.cr:1057:      # by the HIG validation host (screenshot isolation). The material,
src/ui/renderers/appkit_renderer.cr:1826:            # Token-driven material. Declared step `:thin` quantizes
src/ui/renderers/appkit_renderer.cr:1828:            # non-`:regular` declared steps per material.cr L77-91),
src/ui/renderers/appkit_renderer.cr:1835:            sidebar_step = @design_tokens.material.apple_step(:thin)
src/ui/renderers/appkit_renderer.cr:1836:            sidebar_material = appkit_visual_effect_material(sidebar_step)
src/ui/renderers/appkit_renderer.cr:1838:            LibObjCBridge.objc_send_long(sidebar_effect, sel("setMaterial:"), sidebar_material)
src/ui/renderers/appkit_renderer.cr:1953:      #   NSVisualEffectView (glass root, toolbar material)
src/ui/renderers/appkit_renderer.cr:2166:          # backdrop-blurred material and the subtle glass-edge highlight.
src/ui/renderers/appkit_renderer.cr:2170:          # canonical material for macOS sheets -- it matches the frosted-glass
src/ui/renderers/appkit_renderer.cr:2185:          # NSVisualEffectStateActive = 1 — keep the material live regardless
src/ui/renderers/appkit_renderer.cr:2189:          # Rounded corners on the material layer itself.
src/ui/renderers/appkit_renderer.cr:2201:          # insets give the HIG-mandated breathing room inside the material.
src/ui/renderers/appkit_renderer.cr:2275:      # Visit: Popover -> NSVisualEffectView (popover material) inline card
src/ui/renderers/appkit_renderer.cr:2283:      # material live regardless of key state.
src/ui/renderers/appkit_renderer.cr:2338:        # NSVisualEffectStateActive = 1 -- keep material live regardless of key state.
src/ui/renderers/appkit_renderer.cr:2659:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/renderers/appkit_renderer.cr:2822:        # Token-driven material via the AppKit-semantic `:menu` key —
src/ui/renderers/appkit_renderer.cr:2829:        menu_step = @design_tokens.material.apple_step(:menu)
src/ui/renderers/appkit_renderer.cr:2830:        menu_material = appkit_visual_effect_material(menu_step)
src/ui/renderers/appkit_renderer.cr:2832:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), menu_material) # :menu -> NSVisualEffectMaterialMenu (5)
src/ui/renderers/appkit_renderer.cr:3735:      # Visit: ActivityView -> NSVisualEffectView (sheet material) + four zones
src/ui/renderers/appkit_renderer.cr:3738:      # This renderer emits a HIG-honest sheet-material surface containing all
src/ui/renderers/appkit_renderer.cr:3747:      # approximation, so use the same sheet material as UI::Sheet. Popover
src/ui/renderers/appkit_renderer.cr:3748:      # material renders noticeably flatter in the live capture and weakens the
src/ui/renderers/appkit_renderer.cr:3760:        # Outer glass container — sheet material approximates the iOS share sheet
src/ui/renderers/appkit_renderer.cr:3762:        # Token-driven material. Declared step `:thick` quantizes through
src/ui/renderers/appkit_renderer.cr:3764:        # declared steps per material.cr L77-91); the translation table
src/ui/renderers/appkit_renderer.cr:3767:        activity_step = @design_tokens.material.apple_step(:thick)
src/ui/renderers/appkit_renderer.cr:3768:        activity_material = appkit_visual_effect_material(activity_step)
src/ui/renderers/appkit_renderer.cr:3770:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), activity_material) # :thick -> NSVisualEffectMaterialSheet (11)
src/ui/renderers/appkit_renderer.cr:4688:      # HIG-correct native material while routing through the brand
src/ui/renderers/appkit_renderer.cr:4701:      private def appkit_visual_effect_material(step : Symbol) : Int64
src/ui/renderers/appkit_renderer.cr:4702:        # AppKit material translation table — only allowed hard-coded glass switch
src/ui/design_tokens/generators/web_generator.cr:23:      def generate(tokens : Tokens) : String
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
src/ui/design_tokens/generators/web_generator.cr:93:      # declare, expressed via `var(--ap-material-opacity-<step>)` so
src/ui/design_tokens/generators/web_generator.cr:109:          io << "  .ap-glass--#{step} { background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step}) * 100%), transparent); }\n"
src/ui/views/gauge.cr:96:      card.material = :secondary
src/ui/views/activity_ring.cr:95:      card.material = :secondary
src/ui/views/activity_view.cr:52:  # Glass material: NSVisualEffectMaterialPopover (6) on macOS;
src/ui/views/panel.cr:63:      card.material = style == UI::PanelStyle::Inspector ? :tertiary : :secondary
src/ui/views/image_well.cr:81:      card.material = :secondary
src/ui/views/icon_button.cr:6:    # Icon name (SF Symbol on Apple, material icon on Android, icon class on web)
src/ui/renderers/uikit_renderer.cr:1953:      # (iOS 15+) as the background material.
src/ui/renderers/uikit_renderer.cr:2233:          # the UIStackView is transparent so the UIVisualEffectView material bleeds
src/ui/renderers/uikit_renderer.cr:2234:          # through behind the content rows. Without this the glass material is
src/ui/renderers/uikit_renderer.cr:2242:          # for the material to render behind them correctly).
src/ui/renderers/uikit_renderer.cr:2395:        # must live in contentView for the material to render behind them correctly).
src/ui/renderers/uikit_renderer.cr:2544:        # selection based on UI::Card#material -- default :secondary.
src/ui/renderers/uikit_renderer.cr:2545:        color_sel = case view.material
src/ui/renderers/uikit_renderer.cr:2670:        apple_step = @design_tokens.material.apple_step(view.material)
src/ui/views/glass_background.cr:6:    property material : Symbol = :regular  # :thin, :ultra_thin, :regular, :thick, :chrome
src/ui/views/glass_background.cr:9:    def initialize(@content : View? = nil, @material : Symbol = :regular)
src/ui/renderers/web_renderer.cr:1405:        # Phase 5: glass material is tokenized. The inline style references
src/ui/renderers/web_renderer.cr:1406:        # the per-step `--ap-material-*` custom properties the WebGenerator
src/ui/renderers/web_renderer.cr:1408:        # `calc(<base>px * var(--ap-material-intensity, 1))`). The
src/ui/renderers/web_renderer.cr:1410:        step_key = material_css_step_key(view.material)
src/ui/renderers/web_renderer.cr:1414:          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1415:          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
src/ui/renderers/web_renderer.cr:1416:          "background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step_key}) * 100%), transparent); " \
src/ui/renderers/web_renderer.cr:1434:      # Map a `GlassBackground#material` Symbol to the CSS class suffix /
src/ui/renderers/web_renderer.cr:1436:      private def material_css_step_key(name : Symbol) : String
src/ui/renderers/web_renderer.cr:2018:        # `:thin` material step. Inline style references `var(--ap-material-*)`
src/ui/renderers/web_renderer.cr:2024:        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-thin) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); -webkit-backdrop-filter: blur(var(--ap-material-blur-thin)) saturate(var(--ap-material-saturation-thin)); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")
src/ui/views/card.cr:20:    property material : Symbol = :secondary
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
src/ui/renderers/android_renderer.cr:268:    @material_theme : UI::Theme
src/ui/renderers/android_renderer.cr:270:    # Phase 5 — Glass material tokens. The renderer resolves
src/ui/renderers/android_renderer.cr:271:    # `tokens.material.resolve(view.material)` inside
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
src/ui/renderers/android_renderer.cr:1295:      til = new_material_view(
src/ui/renderers/android_renderer.cr:1296:        "com/google/android/material/textfield/TextInputLayout",
src/ui/renderers/android_renderer.cr:1300:      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:1301:      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
src/ui/renderers/android_renderer.cr:1302:      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))
src/ui/renderers/android_renderer.cr:1308:      et = new_material_view(
src/ui/renderers/android_renderer.cr:1309:        "com/google/android/material/textfield/TextInputEditText",
src/ui/renderers/android_renderer.cr:1381:      value_tv = new_text_view(label_text, 16.0_f32, material_color(:on_surface), 1)
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
src/ui/renderers/android_renderer.cr:1648:      til = new_material_view(
src/ui/renderers/android_renderer.cr:1649:        "com/google/android/material/textfield/TextInputLayout",
src/ui/renderers/android_renderer.cr:1653:      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
src/ui/renderers/android_renderer.cr:1654:      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
src/ui/renderers/android_renderer.cr:1655:      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))
src/ui/renderers/android_renderer.cr:1661:      et = new_material_view(
src/ui/renderers/android_renderer.cr:1662:        "com/google/android/material/textfield/TextInputEditText",
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
src/ui/renderers/android_renderer.cr:2185:      resolved = @design_tokens.material.resolve(view.material)
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
src/ui/renderers/android_renderer.cr:3202:    private def material_color(role : Symbol) : Int32
src/ui/renderers/android_renderer.cr:3203:      theme = @material_theme
src/ui/renderers/android_renderer.cr:3242:                              color : Int32 = material_color(:on_surface),
src/ui/renderers/android_renderer.cr:3252:    private def new_material_view(class_name : String, style_field_name : String) : Void*
src/ui/renderers/android_renderer.cr:3361:      @material_theme = UI::Theme.material_baseline

exec
/bin/zsh -lc "nl -ba spec/ui/renderers/web_glass_spec.cr | sed -n '1,90p' && nl -ba spec/ui/design_tokens/web_generator_material_spec.cr | sed -n '1,140p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
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
nl: spec/ui/design_tokens/web_generator_material_spec.cr: No such file or directory

exec
/bin/zsh -lc "nl -ba src/ui/design_tokens/generators/web_generator.cr | sed -n '55,114p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
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

exec
/bin/zsh -lc "nl -ba src/ui/renderers/android_renderer.cr | sed -n '196,211p;2170,2214p;3468,3508p' && nl -ba src/ui/native/android_bridge.c | sed -n '1475,1510p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
   196	    fun android_spinner_set_on_item_selected_listener(env : Void*, spinner : Void*, callback_id : UInt64)
   197	
   198	    # --- Global reference management ---
   199	    fun android_new_global_ref(env : Void*, local_ref : Void*) : Void*
   200	    fun android_delete_global_ref(env : Void*, global_ref : Void*)
   201	
   202	    # --- Phase 5: Glass material ---
   203	    # Applies AssetPipelineGlassHelper.applyGlass(view, blurRadius,
   204	    # fallbackArgb). Helper internally chooses RenderEffect.createBlurEffect
   205	    # on API 31+ or alpha-fill on older devices. Returns 1 if real blur
   206	    # was applied, 0 if the fallback path ran (or the helper class is
   207	    # missing, which Phase 6.5's audit harness verifies separately).
   208	    fun android_view_apply_glass(env : Void*, view : Void*, blur_radius : Float32, fallback_argb : Int32) : Int32
   209	  end
   210	
   211	  # Renders a UI::View tree to native Android views via the JNI bridge.
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

exec
/bin/zsh -lc "nl -ba src/ui/renderers/uikit_renderer.cr | sed -n '2655,2692p' && nl -ba src/ui/renderers/appkit_renderer.cr | sed -n '2648,2682p' && nl -ba src/ui/native/swiftkit_overrides.cr | sed -n '604,636p' && nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/GlassBackgroundOverrides.swift | sed -n '1,70p' && nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift | sed -n '1,90p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
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
  2648	      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
  2649	      # with `.background(<Material>)` fallback on pre-26 OSes.
  2650	      #
  2651	      # Phase 3 remediation: migrated to the populator + facade flow so
  2652	      # the "headline visual differentiator" the Phase 3 README names
  2653	      # (Liquid Glass on default Card/Sheet surfaces) is wired through
  2654	      # the same default-detection cascade as every other widget.
  2655	      # -----------------------------------------------------------------
  2656	      def visit(view : UI::GlassBackground)
  2657	        # Phase 5: resolve the Apple-quantized step from the active tokens.
  2658	        # See uikit_renderer.cr#visit(UI::GlassBackground) for the contract.
  2659	        apple_step = @design_tokens.material.apple_step(view.material)
  2660	
  2661	        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
  2662	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  2663	        target_str = overrides_ptr.address.to_s(16)
  2664	        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)
  2665	
  2666	        child_ptr = Pointer(Void).null
  2667	        child_native : NativeView? = nil
  2668	        if content = view.content
  2669	          if d = render_detached(content)
  2670	            child_native = d
  2671	            child_ptr = d.handle.ptr!
  2672	          end
  2673	        end
  2674	
  2675	        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
  2676	        handle = ObjC.owned(ptr, label: "NSHostingView[GlassBackground]")
  2677	        native = NativeView.new(handle)
  2678	        if c = child_native
  2679	          native.add_child(c)
  2680	        end
  2681	        push_native(native)
  2682	      end
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

exec
/bin/zsh -lc "nl -ba src/ui/renderers/appkit_renderer.cr | sed -n '1768,1844p;2818,2836p;3751,3772p;4668,4710p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "nl -ba src/ui/renderers/appkit_renderer.cr | sed -n '816,866p;1058,1096p;1958,2002p;2120,2180p;2294,2338p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  1768	      #       <content children>
  1769	      #     [thin 1pt NSBox separator — only if detail present]
  1770	      #     NSStackView[detail-col] (vertical, fills remaining width)
  1771	      #       <detail children>
  1772	      # -----------------------------------------------------------------
  1773	      def visit(view : UI::NavigationSplitView)
  1774	        # SwiftUI NavigationSplitView facade. Three slots: sidebar /
  1775	        # content / detail. Empty slots are passed as an empty NSView
  1776	        # placeholder so the facade can address them by index.
  1777	        overrides_ptr = LibSwiftKitBridge.apsk_navigation_split_view_overrides_new
  1778	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  1779	        target_str = overrides_ptr.address.to_s(16)
  1780	        UI::Native::Populator.populate_navigation_split_view(target_str, view, sender)
  1781	
  1782	        children_native = [] of NativeView
  1783	        [view.sidebar, view.content, view.detail].each do |slot|
  1784	          if slot
  1785	            if d = render_detached(slot)
  1786	              children_native << d
  1787	            else
  1788	              empty_ptr = alloc_init("NSView")
  1789	              children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[split-empty]"))
  1790	            end
  1791	          else
  1792	            empty_ptr = alloc_init("NSView")
  1793	            children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[split-empty]"))
  1794	          end
  1795	        end
  1796	
  1797	        child_buf = build_child_buffer(children_native)
  1798	        ptr = LibSwiftKitBridge.apsk_make_navigation_split_view(
  1799	          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
  1800	        )
  1801	        handle = ObjC.owned(ptr, label: "NSHostingView[NavigationSplitView]")
  1802	        native = NativeView.new(handle)
  1803	        children_native.each { |c| native.add_child(c) }
  1804	        push_native(native)
  1805	      end
  1806	
  1807	      # Legacy AppKit NSStackView NavigationSplitView body, retained for
  1808	      # reference. Replaced by the SwiftUI facade above.
  1809	      private def _legacy_navigation_split_view(view : UI::NavigationSplitView)
  1810	        outer = alloc_init("NSStackView")
  1811	        # NSUserInterfaceLayoutOrientationHorizontal = 0
  1812	        LibObjCBridge.objc_send_long(outer, sel("setOrientation:"), 0_i64)
  1813	        LibObjCBridge.objc_send_1d(outer, sel("setSpacing:"), 0.0)
  1814	        # NSStackViewDistributionFill = 0
  1815	        LibObjCBridge.objc_send_long(outer, sel("setDistribution:"), 0_i64)
  1816	        # NSStackViewAlignmentFill (height fills parent) = 5 (NSLayoutAttributeHeight)
  1817	        # Use leading-edge alignment so rows anchor to the top.
  1818	        LibObjCBridge.objc_send_long(outer, sel("setAlignment:"), 5_i64)
  1819	        apply_common_properties(outer, view)
  1820	        outer_handle = ObjC.owned(outer, label: "NSStackView[split-outer]")
  1821	        outer_native = NativeView.new(outer_handle)
  1822	
  1823	        if view.shows_sidebar
  1824	          if sidebar = view.sidebar
  1825	            # --- Liquid Glass sidebar column ---
  1826	            # Token-driven material. Declared step `:thin` quantizes
  1827	            # through `apple_step` unchanged (developer intent wins for
  1828	            # non-`:regular` declared steps per material.cr L77-91),
  1829	            # then maps to NSVisualEffectMaterialSidebar (7) via the
  1830	            # AppKit translation table — same byte-identical integer the
  1831	            # pre-Phase-5 code emitted. Brand intensity does NOT shift
  1832	            # this surface (declared step wins). Routing through the
  1833	            # token cascade keeps NavigationSplitView consistent with the
  1834	            # rest of the glass surfaces under brand override flow.
  1835	            sidebar_step = @design_tokens.material.apple_step(:thin)
  1836	            sidebar_material = appkit_visual_effect_material(sidebar_step)
  1837	            sidebar_effect = alloc_init("NSVisualEffectView")
  1838	            LibObjCBridge.objc_send_long(sidebar_effect, sel("setMaterial:"), sidebar_material)
  1839	            # NSVisualEffectBlendingModeWithinWindow = 1
  1840	            LibObjCBridge.objc_send_long(sidebar_effect, sel("setBlendingMode:"), 1_i64)
  1841	            # NSVisualEffectStateActive = 1
  1842	            LibObjCBridge.objc_send_long(sidebar_effect, sel("setState:"), 1_i64)
  1843	
  1844	            # Pin the sidebar column width.
  2818	        push_native(native)
  2819	      end
  2820	
  2821	      def visit(view : UI::ContextMenu)
  2822	        # Token-driven material via the AppKit-semantic `:menu` key —
  2823	        # `NSVisualEffectMaterialMenu` has no SwiftUI Material enum
  2824	        # analogue, so we route through the AppKit-private semantic
  2825	        # extension to the translation table. `apple_step(:menu)`
  2826	        # returns `:menu` unchanged (only `:regular` is quantized by
  2827	        # intensity); the translation table maps `:menu` to 5
  2828	        # (byte-identical to the pre-Phase-5 raw constant).
  2829	        menu_step = @design_tokens.material.apple_step(:menu)
  2830	        menu_material = appkit_visual_effect_material(menu_step)
  2831	        effect = alloc_init("NSVisualEffectView")
  2832	        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), menu_material) # :menu -> NSVisualEffectMaterialMenu (5)
  2833	        LibObjCBridge.objc_send_long(effect, sel("setBlendingMode:"), 1_i64) # WithinWindow
  2834	        LibObjCBridge.objc_send_long(effect, sel("setState:"), 1_i64)        # Active
  2835	        LibObjCBridge.objc_send_bool(effect, sel("setWantsLayer:"), 1)
  2836	
  3751	      def visit(view : UI::ActivityView)
  3752	        # Amber gold tint — applied to all destination icon buttons, action icon
  3753	        # buttons, and the Cancel button so the ActivityView renders in the Amber
  3754	        # brand accent rather than the default systemBlue. Routes through the
  3755	        # token shim so a brand override on `design_tokens` cascades here too.
  3756	        # NSButton.contentTintColor uses the light value for both appearances —
  3757	        # the amber backdrop renders correctly under both.
  3758	        amber_gold = amber_brand_gold
  3759	
  3760	        # Outer glass container — sheet material approximates the iOS share sheet
  3761	        # surface on macOS and matches the known-good UI::Sheet glass path.
  3762	        # Token-driven material. Declared step `:thick` quantizes through
  3763	        # `apple_step` unchanged (developer intent wins for non-`:regular`
  3764	        # declared steps per material.cr L77-91); the translation table
  3765	        # maps `:thick` to NSVisualEffectMaterialSheet (11), byte-identical
  3766	        # to the pre-Phase-5 raw integer.
  3767	        activity_step = @design_tokens.material.apple_step(:thick)
  3768	        activity_material = appkit_visual_effect_material(activity_step)
  3769	        effect = alloc_init("NSVisualEffectView")
  3770	        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), activity_material) # :thick -> NSVisualEffectMaterialSheet (11)
  3771	        LibObjCBridge.objc_send_long(effect, sel("setBlendingMode:"), 1_i64) # WithinWindow
  3772	        LibObjCBridge.objc_send_long(effect, sel("setState:"), 1_i64)        # Active
  4668	      # Resolve a Phase-5 Material step Symbol to its NSVisualEffectMaterial
  4669	      # integer constant for the direct-AppKit visit paths that bypass the
  4670	      # SwiftKit facade (NavigationSplitView legacy sidebar, ContextMenu,
  4671	      # ActivityView).
  4672	      #
  4673	      # Scope is intentionally narrow: only the step Symbols actually
  4674	      # consumed by those call sites are mapped here. Expanding this
  4675	      # table requires re-validating each new Symbol against Apple's
  4676	      # NSVisualEffectMaterial semantics; implementation.md L562 sketches
  4677	      # a UIKit-constant <-> AppKit-constant translation that this helper
  4678	      # does NOT implement (Phase 5 shipped the SwiftKit facade path
  4679	      # instead, so the integer translation table the doc envisioned was
  4680	      # never built).
  4681	      #
  4682	      # The portable Material steps (`:thin`, `:thick`) match the
  4683	      # cross-platform token scale. `:menu` is an **AppKit platform
  4684	      # surface semantic** — a renderer-private key for
  4685	      # `NSVisualEffectMaterialMenu` (no SwiftUI Material enum analogue).
  4686	      # `:menu` must NOT be advertised as part of the portable Material
  4687	      # token contract; it exists only so `UI::ContextMenu` can have its
  4688	      # HIG-correct native material while routing through the brand
  4689	      # cascade infrastructure.
  4690	      #
  4691	      # Unknown / unhandled Symbols fall through to `NSVisualEffectMaterialHeaderView`
  4692	      # (10), a safe modern default. Adding new Symbols requires:
  4693	      #   (a) verifying the Apple NSVisualEffectMaterial semantics,
  4694	      #   (b) updating the call site + comment to declare the choice.
  4695	      #
  4696	      # Per Phase 5 implementation.md (lines 226-237), this case/switch is
  4697	      # the ONE allowed hard-coded glass switch in the file and must carry
  4698	      # the exact marker comment on the line directly above. Phase 5
  4699	      # validation.md check #22 greps for that marker. Do not add this
  4700	      # marker anywhere else in the codebase.
  4701	      private def appkit_visual_effect_material(step : Symbol) : Int64
  4702	        # AppKit material translation table — only allowed hard-coded glass switch
  4703	        case step
  4704	        when :thin  then  7_i64 # NSVisualEffectMaterialSidebar (NavigationSplitView sidebar)
  4705	        when :thick then 11_i64 # NSVisualEffectMaterialSheet (ActivityView)
  4706	        when :menu  then  5_i64 # NSVisualEffectMaterialMenu (ContextMenu, AppKit-semantic; no SwiftUI analogue)
  4707	        else             10_i64 # NSVisualEffectMaterialHeaderView (safe modern default)
  4708	        end
  4709	      end
  4710	

 succeeded in 0ms:
   816	      #
   817	      # Selected tab: system blue 0.0/0.478/1.0 (or selected_tint_color).
   818	      # Unselected tabs: NSColor.secondaryLabelColor (appearance-tracking).
   819	      # -----------------------------------------------------------------
   820	      def visit(view : UI::TabView)
   821	        # SwiftUI TabView facade. Each tab's content is rendered detached
   822	        # to obtain a native pointer; the facade wraps each in
   823	        # APSKHostedChild + applies .tabItem with the parallel label/icon
   824	        # arrays from the overrides.
   825	        overrides_ptr = LibSwiftKitBridge.apsk_tab_view_overrides_new
   826	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
   827	        target_str = overrides_ptr.address.to_s(16)
   828	        UI::Native::Populator.populate_tab_view(target_str, view, sender)
   829	
   830	        action_token = 0_u64
   831	        if change_handler = view.on_change
   832	          action_token = UI::CallbackRegistry.register_action_with_value do |v|
   833	            change_handler.call(v.to_i32)
   834	          end
   835	        end
   836	
   837	        children_native = [] of NativeView
   838	        view.tabs.each do |tab|
   839	          if d = render_detached(tab.content)
   840	            children_native << d
   841	          else
   842	            empty_ptr = alloc_init("NSView")
   843	            children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[tab-empty]"))
   844	          end
   845	        end
   846	
   847	        child_buf = build_child_buffer(children_native)
   848	        ptr = LibSwiftKitBridge.apsk_make_tab_view(
   849	          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
   850	        )
   851	        handle = ObjC.owned(ptr, label: "NSHostingView[TabView]")
   852	        native = NativeView.new(handle)
   853	        native.track_callback_id(action_token) unless action_token == 0_u64
   854	        children_native.each { |c| native.add_child(c) }
   855	        push_native(native)
   856	      end
   857	
   858	      # Legacy AppKit tab view body, retained for reference.
   859	      private def _legacy_tab_view(view : UI::TabView)
   860	        glass_root = alloc_init("NSVisualEffectView")
   861	        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
   862	        # NSVisualEffectBlendingModeWithinWindow = 1 — samples what is beneath
   863	        # this NSVisualEffectView within the same window. Correct for validation
   864	        # captures where the backdrop content is composited inside the same
   865	        # window layer stack, not behind a separate NSWindow.
   866	        LibObjCBridge.objc_send_long(glass_root, sel("setBlendingMode:"), 1_i64)
  1058	      # corner radius, and role-coloring are HIG-faithful.
  1059	      # -----------------------------------------------------------------
  1060	      def visit(view : UI::Alert)
  1061	        # SwiftUI .alert(title:isPresented:actions:message:) facade.
  1062	        overrides_ptr = LibSwiftKitBridge.apsk_alert_overrides_new
  1063	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  1064	        target_str = overrides_ptr.address.to_s(16)
  1065	        UI::Native::Populator.populate_alert(target_str, view, sender)
  1066	
  1067	        # Register each button's action token; pass as UInt64 array.
  1068	        tokens = [] of UInt64
  1069	        callback_ids = [] of UInt64
  1070	        view.buttons.each do |btn|
  1071	          if action = btn.action
  1072	            tok = UI::CallbackRegistry.register_action(&action)
  1073	            tokens << tok
  1074	            callback_ids << tok
  1075	          else
  1076	            tokens << 0_u64
  1077	          end
  1078	        end
  1079	        sender.set_uint64_array(target_str, :setButtonTokens, tokens)
  1080	
  1081	        ptr = LibSwiftKitBridge.apsk_make_alert(
  1082	          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
  1083	        )
  1084	        handle = ObjC.owned(ptr, label: "NSHostingView[Alert]")
  1085	        native = NativeView.new(handle)
  1086	        callback_ids.each { |id| native.track_callback_id(id) }
  1087	        push_native(native)
  1088	      end
  1089	
  1090	      # Legacy AppKit NSVisualEffectView alert body, retained for reference.
  1091	      private def _legacy_alert(view : UI::Alert)
  1092	        effect = alloc_init("NSVisualEffectView")
  1093	        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 7_i64)
  1094	        # NSVisualEffectBlendingModeWithinWindow = 1
  1095	        LibObjCBridge.objc_send_long(effect, sel("setBlendingMode:"), 1_i64)
  1096	        # NSVisualEffectStateActive = 1
  1958	      #         NSButton (icon-only or icon+label, borderless, 44x28pt)
  1959	      #           NSImageView (SF Symbol, 20pt, no border per HIG Actions)
  1960	      #
  1961	      # HIG Best practices: "Prefer system-provided symbols without borders."
  1962	      # HIG Best practices: "Choose items deliberately to avoid overcrowding."
  1963	      # -----------------------------------------------------------------
  1964	      def visit(view : UI::Toolbar)
  1965	        # SwiftUI .toolbar(...) facade. The Toolbar carries item arrays
  1966	        # (labels/icons/placements) plus action tokens registered here.
  1967	        overrides_ptr = LibSwiftKitBridge.apsk_toolbar_overrides_new
  1968	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  1969	        target_str = overrides_ptr.address.to_s(16)
  1970	        UI::Native::Populator.populate_toolbar(target_str, view, sender)
  1971	
  1972	        # Register each item's action; pass tokens through as a parallel
  1973	        # UInt64 array.
  1974	        tokens = [] of UInt64
  1975	        callback_ids = [] of UInt64
  1976	        view.items.each do |item|
  1977	          if action = item.action
  1978	            tok = UI::CallbackRegistry.register_action(&action)
  1979	            tokens << tok
  1980	            callback_ids << tok
  1981	          else
  1982	            tokens << 0_u64
  1983	          end
  1984	        end
  1985	        sender.set_uint64_array(target_str, :setItemTokens, tokens)
  1986	
  1987	        ptr = LibSwiftKitBridge.apsk_make_toolbar(
  1988	          Pointer(Void*).null.as(Void*), 0_i32, overrides_ptr,
  1989	        )
  1990	        handle = ObjC.owned(ptr, label: "NSHostingView[Toolbar]")
  1991	        native = NativeView.new(handle)
  1992	        callback_ids.each { |id| native.track_callback_id(id) }
  1993	        push_native(native)
  1994	      end
  1995	
  1996	      # Legacy AppKit NSStackView/NSVisualEffectView toolbar body. Kept
  1997	      # for reference; superseded by the SwiftUI facade above.
  1998	      private def _legacy_toolbar(view : UI::Toolbar)
  1999	        glass_root = alloc_init("NSVisualEffectView")
  2000	        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
  2001	        # NSVisualEffectBlendingModeWithinWindow = 1
  2002	        LibObjCBridge.objc_send_long(glass_root, sel("setBlendingMode:"), 1_i64)
  2120	      # -----------------------------------------------------------------
  2121	      # Visit: Sheet -> NSVisualEffectView + inner NSStackView (Liquid Glass)
  2122	      # -----------------------------------------------------------------
  2123	      def visit(view : UI::Sheet)
  2124	        # SwiftUI .sheet(isPresented:) facade. The Sheet's content is
  2125	        # rendered detached; the facade hosts a 1pt clear rect that
  2126	        # carries the .sheet modifier, presenting the content modally.
  2127	        overrides_ptr = LibSwiftKitBridge.apsk_sheet_overrides_new
  2128	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  2129	        target_str = overrides_ptr.address.to_s(16)
  2130	        UI::Native::Populator.populate_sheet(target_str, view, sender)
  2131	
  2132	        dismiss_token = 0_u64
  2133	        callback_ids = [] of UInt64
  2134	        if dismiss = view.on_dismiss
  2135	          dismiss_token = UI::CallbackRegistry.register_action(&dismiss)
  2136	          callback_ids << dismiss_token
  2137	        end
  2138	
  2139	        children_native = [] of NativeView
  2140	        if content = view.content
  2141	          if d = render_detached(content)
  2142	            children_native << d
  2143	          end
  2144	        end
  2145	
  2146	        child_buf = build_child_buffer(children_native)
  2147	        ptr = LibSwiftKitBridge.apsk_make_sheet(
  2148	          child_buf.as(Void*), children_native.size.to_i32,
  2149	          overrides_ptr, dismiss_token,
  2150	        )
  2151	        handle = ObjC.owned(ptr, label: "NSHostingView[Sheet]")
  2152	        native = NativeView.new(handle)
  2153	        callback_ids.each { |id| native.track_callback_id(id) }
  2154	        children_native.each { |c| native.add_child(c) }
  2155	        push_native(native)
  2156	      end
  2157	
  2158	      # Legacy AppKit Sheet body, retained for reference.
  2159	      private def _legacy_sheet(view : UI::Sheet)
  2160	        grouped_card = !view.is_presented &&
  2161	                       (view.surface_style == :auto || view.surface_style == :grouped_card)
  2162	
  2163	        if grouped_card
  2164	          # Outer glass container — NSVisualEffectView. This is what the
  2165	          # parent tree sees as the sheet view; it renders the translucent
  2166	          # backdrop-blurred material and the subtle glass-edge highlight.
  2167	          effect = alloc_init("NSVisualEffectView")
  2168	
  2169	          # NSVisualEffectMaterialSheet = 11 (macOS 10.11+). This is the
  2170	          # canonical material for macOS sheets -- it matches the frosted-glass
  2171	          # surface Apple uses for Save/Print/Open sheets. Tracks light/dark
  2172	          # appearance automatically. Material 10 (Menu) was used previously;
  2173	          # 11 (Sheet) is the semantically correct value per NSVisualEffectMaterial
  2174	          # enum (Sidebar=1, Titlebar=3, Selection=4, Menu=5, Popover=6,
  2175	          # Sidebar=7, HeaderView=10, Sheet=11, WindowBackground=12,
  2176	          # HUDWindow=13, FullScreenUI=15, Tooltip=17, ContentBackground=18,
  2177	          # UnderWindowBackground=21, UnderPageBackground=22).
  2178	          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)
  2179	          # NSVisualEffectBlendingModeWithinWindow = 1 — samples what is beneath
  2180	          # this NSVisualEffectView inside the same window. The validation host
  2294	      # validation-only visual cue. Logged as a systemic gap in gaps.md.
  2295	      #
  2296	      # Corner radius ~10pt matching NSVisualEffectMaterialPopover default.
  2297	      # -----------------------------------------------------------------
  2298	      def visit(view : UI::Popover)
  2299	        # SwiftUI .popover(isPresented:) facade.
  2300	        overrides_ptr = LibSwiftKitBridge.apsk_popover_overrides_new
  2301	        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
  2302	        target_str = overrides_ptr.address.to_s(16)
  2303	        UI::Native::Populator.populate_popover(target_str, view, sender)
  2304	
  2305	        dismiss_token = 0_u64
  2306	        callback_ids = [] of UInt64
  2307	        if dismiss = view.on_dismiss
  2308	          dismiss_token = UI::CallbackRegistry.register_action(&dismiss)
  2309	          callback_ids << dismiss_token
  2310	        end
  2311	
  2312	        children_native = [] of NativeView
  2313	        if content = view.content
  2314	          if d = render_detached(content)
  2315	            children_native << d
  2316	          end
  2317	        end
  2318	
  2319	        child_buf = build_child_buffer(children_native)
  2320	        ptr = LibSwiftKitBridge.apsk_make_popover(
  2321	          child_buf.as(Void*), children_native.size.to_i32,
  2322	          overrides_ptr, dismiss_token,
  2323	        )
  2324	        handle = ObjC.owned(ptr, label: "NSHostingView[Popover]")
  2325	        native = NativeView.new(handle)
  2326	        callback_ids.each { |id| native.track_callback_id(id) }
  2327	        children_native.each { |c| native.add_child(c) }
  2328	        push_native(native)
  2329	      end
  2330	
  2331	      # Legacy AppKit Popover body, retained for reference.
  2332	      private def _legacy_popover(view : UI::Popover)
  2333	        effect = alloc_init("NSVisualEffectView")
  2334	        # NSVisualEffectMaterialPopover = 6.
  2335	        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 6_i64)
  2336	        # NSVisualEffectBlendingModeWithinWindow = 1
  2337	        LibObjCBridge.objc_send_long(effect, sel("setBlendingMode:"), 1_i64)
  2338	        # NSVisualEffectStateActive = 1 -- keep material live regardless of key state.

exec
/bin/zsh -lc "rg -n \"appkit_visual_effect_material\\(|objc_send_long\\(["'^'"\\n]*setMaterial|def _legacy_navigation_split_view|def visit\\(view : UI::NavigationSplitView\\)\" src/ui/renderers/appkit_renderer.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
861:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
1093:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 7_i64)
1773:      def visit(view : UI::NavigationSplitView)
1809:      private def _legacy_navigation_split_view(view : UI::NavigationSplitView)
1836:            sidebar_material = appkit_visual_effect_material(sidebar_step)
1838:            LibObjCBridge.objc_send_long(sidebar_effect, sel("setMaterial:"), sidebar_material)
2000:        LibObjCBridge.objc_send_long(glass_root, sel("setMaterial:"), 10_i64)
2178:          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 11_i64)
2335:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), 6_i64)
2830:        menu_material = appkit_visual_effect_material(menu_step)
2832:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), menu_material) # :menu -> NSVisualEffectMaterialMenu (5)
3768:        activity_material = appkit_visual_effect_material(activity_step)
3770:        LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), activity_material) # :thick -> NSVisualEffectMaterialSheet (11)
4701:      private def appkit_visual_effect_material(step : Symbol) : Int64

codex
I found a blocking mismatch before needing to run the full validation ladder: the validator draft says the R3 NavigationSplitView fix was in the active visit path, but the cited `setMaterial:` is inside `_legacy_navigation_split_view`, after the active `visit` method has already ended. I’m collecting the exact citations for the final answer and checking whether that also affects the handoff’s escalation claim.
exec
/bin/zsh -lc "nl -ba docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml | sed -n '35,40p;168,198p;279,286p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    35	invariant_matrix:
    36	  - id: I-1
    37	    name: "Render correctly"
    38	    touch: extends
    39	    rationale: "Phase introduces tokenized blur/opacity/saturation/luminance values per material step + an intensity scalar. AMENDED 2026-05-22 per Codex resolution review: iOS 26+ / macOS 26+ use SwiftUI .glassEffect() which is SYSTEM-RESOLVED — material step and intensity become advisory only on the Liquid Glass path. Step+intensity ARE enforced on the pre-26 fallback .background(.material) path AND on web (backdrop-filter scaled by intensity) AND on Android (RenderEffect radius scaled by intensity API 31+, alpha fallback < API 31). Phase 5 implementer authors the per-step visual baseline probes for the controllable paths."
    40	    probes:
   168	  - id: I-10
   169	    name: "API/fallback contract fidelity"
   170	    touch: extends
   171	    rationale: "New public token API: tokens.material with per-step blur/opacity/saturation/luminance + intensity Float64 scalar. Phase 5 commits to: (1) intensity is RENDER-TIME ONLY — runtime mutation requires a re-render of the view tree; (2) SwiftUI Material's discrete enum quantizes intensity (see adapter_cardinality row 1); (3) web @supports fallback for backdrop-filter unavailability; (4) Android API < 31 alpha-fallback. All four are documented contract limitations consumers MUST understand."
   172	    probes:
   173	      ios: "spec/asset_pipeline_spec.cr"
   174	      macos: "spec/asset_pipeline_spec.cr"
   175	      web: "crystal-alpha run scripts/validate_web_demo.cr"
   176	      android:
   177	        skip: true
   178	        reason: "Android API-contract probe is Phase 6.5"
   179	        owner_approved: "2026-05-22"
   180	
   181	  - id: I-11
   182	    name: "Target build / link / load closure"
   183	    touch: extends
   184	    rationale: "Phase 5 modifies all 4 renderers (uikit/appkit/web/android). Each target's link closure must still resolve after token-resolution paths are added. If Phase 5 calls into SwiftUI Material at the Swift-side facade, the linker must still find the symbols on iOS 26.5 + macOS 26.5 SDKs."
   185	    probes:
   186	      ios: "bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator"
   187	      macos: "make -C samples/cross_platform/macos_host build"
   188	      web: "crystal-alpha build --no-codegen src/asset_pipeline.cr"
   189	      android:
   190	        skip: true
   191	        reason: "Android cross-build remains architect-precedent PASS per Phase 1 #17 (Crystal stdlib c/sys/epoll gap on darwin); Phase 5 ships Android renderer source but cannot verify cross-build until that gap is resolved separately"
   192	        owner_approved: "2026-05-22"
   193	
   194	lower_layer_assumptions:
   195	  - id: A1
   196	    claim: "SwiftUI Material API accepts the Material enum values Phase 5 emits (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .ultraThickMaterial) AND the .background(Material) modifier on a SwiftUI View on iOS 26.5 + macOS 26.5. NOTE 2026-05-22 per Codex resolution review: .chromeMaterial does NOT exist in public SwiftUI; Phase 5's :chrome step maps to .ultraThickMaterial (or .bar where chrome-tinted styling is wanted). The spike at spikes/swiftui_material_spike.swift uses .bar — that's the alternative."
   197	    falsifier: "Compiling spikes/swiftui_material_spike.swift returns non-zero exit on either iOS or macOS"
   198	    verification: "test -f spikes/swiftui_material_spike.swift && xcrun --sdk iphonesimulator swiftc -emit-library -target arm64-apple-ios16.0-simulator -o /tmp/spike-ios.dylib spikes/swiftui_material_spike.swift && xcrun --sdk macosx swiftc -emit-library -o /tmp/spike-macos.dylib spikes/swiftui_material_spike.swift"
   279	adapter_cardinality:
   280	  - public_api: "UI::DesignTokens::Material#intensity (Float64 scalar; documented multiplicative in [0.0, 2.0])"
   281	    adapter: "SwiftUI Material enum on iOS/macOS (.ultraThinMaterial / .thinMaterial / .regularMaterial / .thickMaterial / .ultraThickMaterial; chrome step maps to .ultraThickMaterial or .bar). On iOS 26+ / macOS 26+ the SwiftUI .glassEffect() Liquid Glass modifier is SYSTEM-RESOLVED — step + intensity are advisory only."
   282	    adapter_input_space: "5 discrete material steps on pre-26 path; system-resolved single Glass surface on 26+ Liquid Glass path"
   283	    api_input_space: "Float64 in [0.0, 2.0]"
   284	    match_status: "MISMATCH"
   285	    documented_degradation: "QUANTIZATION TABLE (consumer-visible, pre-26 path only): intensity 0.0–0.3 → .ultraThinMaterial; 0.3–0.7 → .thinMaterial; 0.7–1.3 → .regularMaterial; 1.3–1.8 → .thickMaterial; 1.8+ → .ultraThickMaterial. AMENDED 2026-05-22 per Codex resolution review: on iOS 26+ / macOS 26+, the renderer uses SwiftUI .glassEffect() which is system-resolved — the system decides the material strength regardless of the app's intensity. App-side step + intensity are therefore ADVISORY on the Liquid Glass path. Consumers running on 26+ get uniform Liquid Glass; consumers on pre-26 fallback get the quantized material per the table. Brands wanting deterministic per-step rendering must either target pre-26 OR override the GlassBackground.material step explicitly (which the system may still override on 26+)."
   286	    owner_approved: "2026-05-22"

exec
/bin/zsh -lc "rg -n \"_legacy_navigation_split_view\\(|_legacy_tab_view\\(|_legacy_alert\\(|_legacy_toolbar\\(|_legacy_sheet\\(|_legacy_popover\\(\" src/ui/renderers/appkit_renderer.cr src -g '*.cr'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
src/ui/renderers/appkit_renderer.cr:859:      private def _legacy_tab_view(view : UI::TabView)
src/ui/renderers/appkit_renderer.cr:1091:      private def _legacy_alert(view : UI::Alert)
src/ui/renderers/appkit_renderer.cr:1809:      private def _legacy_navigation_split_view(view : UI::NavigationSplitView)
src/ui/renderers/appkit_renderer.cr:1998:      private def _legacy_toolbar(view : UI::Toolbar)
src/ui/renderers/appkit_renderer.cr:2159:      private def _legacy_sheet(view : UI::Sheet)
src/ui/renderers/appkit_renderer.cr:2332:      private def _legacy_popover(view : UI::Popover)
src/ui/renderers/appkit_renderer.cr:859:      private def _legacy_tab_view(view : UI::TabView)
src/ui/renderers/appkit_renderer.cr:1091:      private def _legacy_alert(view : UI::Alert)
src/ui/renderers/appkit_renderer.cr:1809:      private def _legacy_navigation_split_view(view : UI::NavigationSplitView)
src/ui/renderers/appkit_renderer.cr:1998:      private def _legacy_toolbar(view : UI::Toolbar)
src/ui/renderers/appkit_renderer.cr:2159:      private def _legacy_sheet(view : UI::Sheet)
src/ui/renderers/appkit_renderer.cr:2332:      private def _legacy_popover(view : UI::Popover)
src/ui/renderers/uikit_renderer.cr:821:      private def _legacy_tab_view(view : UI::TabView)
src/ui/renderers/uikit_renderer.cr:1074:      private def _legacy_alert(view : UI::Alert)
src/ui/renderers/uikit_renderer.cr:1854:      private def _legacy_navigation_split_view(view : UI::NavigationSplitView)
src/ui/renderers/uikit_renderer.cr:1996:      private def _legacy_toolbar(view : UI::Toolbar)
src/ui/renderers/uikit_renderer.cr:2153:      private def _legacy_sheet(view : UI::Sheet)
src/ui/renderers/uikit_renderer.cr:2357:      private def _legacy_popover(view : UI::Popover)

exec
/bin/zsh -lc "nl -ba docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md | sed -n '83,90p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "nl -ba /tmp/p5-v2-validator-draft.md | sed -n '16,39p;40,57p;59,70p;91,97p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    83	## Deviation prompt — read carefully before starting
    84	
    85	The Phase 5 scope in `README.md` names `GlassBackground` as the widget being tokenized. However, the existing Apple renderers hard-code `NSVisualEffectMaterial` / `UIBlurEffectStyle` constants inside the visit methods for **TabView, Alert, Sidebar (NavigationSplitView), Toolbar, Sheet, and Popover** as well. If Phase 5 only tokenizes the `GlassBackground` visit, brand `material.intensity = 1.3` will not cascade to those other glass surfaces — only to the ones the developer explicitly wraps in `GlassBackground`. That is almost certainly the wrong behavior for a brand-cascade phase.
    86	
    87	**Required action:** Extend the refactor to every visit method that today calls `setMaterial:` with a hard-coded constant. The resolution path is identical to `GlassBackground` — pick the semantic material name (`:popover`, `:sheet`, `:sidebar`, `:toolbar`, etc.), look it up in the token tree, pass the resolved parameters to the renderer call.
    88	
    89	If during implementation you discover this would balloon the diff beyond a reasonable single-phase scope (more than ~12 visit methods to refactor), **stop and return** to the team lead with what you found rather than picking an arbitrary subset.
    90	

 succeeded in 0ms:
    16	## Brief amendment verification (per amended invariant)
    17	
    18	### I-1 (extends) — amended: iOS 26+ uses .glassEffect() step-agnostic; controllable on pre-26 + web + Android
    19	**Code match: TRUE.** `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift` lines 64-77:
    20	- `if #available(iOS 26.0, macOS 26.0, *) { ... .glassEffect() }` with explicit comment `// pre-26 only; unused on the Liquid Glass path` next to `_ = material`
    21	- pre-26 path uses `.background(material)` with the resolved step
    22	- Material switch at lines 53-61 maps the 5 step names; `:chrome` is implied (default case → `.regularMaterial`); the explicit `:chrome → .ultraThickMaterial` mapping lives in spike/adapter_cardinality, the GlassBackground facade itself ships `.ultraThinMaterial`/`.thinMaterial`/`.regularMaterial`/`.thickMaterial`/`.ultraThickMaterial`
    23	
    24	### I-7 (extends) — amended: android_view_apply_glass is borrow-not-retain
    25	**Code match: TRUE.** `src/ui/native/android_bridge.c` lines 1483-1503:
    26	- Function takes `view` as a raw `void*`; never wraps in `NewGlobalRef`
    27	- Only ref management is `DeleteLocalRef(env, helper_cls)` for the FindClass result it owns
    28	- Returns scalar `int32_t` (1 / 0); no Crystal-side state retained
    29	- Calls `AssetPipelineGlassHelper.applyGlass(view, blur_radius, fallback_argb)` and returns. View ownership stays with the caller (the `android_renderer.cr` visit method).
    30	
    31	### I-8 (preserves) — amended: Phase 5 ships no production cross-platform forced-colors / prefers-reduced-motion code
    32	**Code match: TRUE.** `grep -n 'prefers-reduced-motion|forced-colors|prefers-contrast' src/ui/renderers/web_renderer.cr src/ui/design_tokens.cr` → 0 hits. `grep -rn ... src/ui/` → 0 hits. Apple delegates to system via SwiftUI Material + .glassEffect(); pending placeholder specs at `spec/ui/glass_material/*_env_response_spec.cr` document the slug names Phase 6.5 will hook.
    33	
    34	### I-10 (extends) — amended: SwiftUI Material's discrete enum quantizes intensity; web @supports + Android API<31 alpha fallback
    35	**Code match: TRUE.** Per A1 spike compile (iOS + macOS exit 0). Brief A1 prose has a minor doc-text drift (says "spike uses .bar" but spike actually uses `.ultraThickMaterial` for `:chrome`); falsifier (compile both targets) still passes and substantive claim (`.chromeMaterial` doesn't exist in public SwiftUI; map :chrome to .ultraThickMaterial) is what's shipped.
    36	
    37	### A1 (lower_layer_assumption) — amended: spike uses .ultraThickMaterial for :chrome
    38	**Code match: TRUE for substance; minor TEXT drift.** A1 verification runs `swiftc -emit-library` on both iOS sim + macOS SDKs; both exit 0. The amendment text says "spike uses .bar" but the actual spike code uses `.ultraThickMaterial` (line 47 of spikes/swiftui_material_spike.swift). The amendment's prior sentence ALSO says "Phase 5's :chrome step maps to .ultraThickMaterial (or .bar where chrome-tinted styling is wanted)" — so .ultraThickMaterial IS the documented primary mapping. The "spike uses .bar" trailing sentence is a doc-text artifact; falsifier honors the substantive claim. NOT a blocker.
    39	
    40	## R3 verification (3 sites tokenized? helper exists? 5 legacy hits confined?)
    41	
    42	**3 named R3 sites tokenized:** TRUE.
    43	- NavigationSplitView `_legacy_navigation_split_view` is NOT the site R3 closed; R3 closed the ACTIVE NavigationSplitView visit. grep -n setMaterial: shows `appkit_visual_effect_material(sidebar_step)` at line 1836-1838 in the active visit method.
    44	- ContextMenu `appkit_renderer.cr` lines 2830-2832: `appkit_visual_effect_material(menu_step)` then `objc_send_long(effect, sel("setMaterial:"), menu_material)` with `# :menu -> NSVisualEffectMaterialMenu (5)` marker
    45	- ActivityView `appkit_renderer.cr` lines 3768-3770: `appkit_visual_effect_material(activity_step)` then `objc_send_long(..., activity_material)` with `# :thick -> NSVisualEffectMaterialSheet (11)` marker
    46	
    47	**Helper exists at the reported location:** TRUE.
    48	`appkit_renderer.cr` lines 4695-4709: `private def appkit_visual_effect_material(step : Symbol) : Int64` with the required marker comment "AppKit material translation table — only allowed hard-coded glass switch" — narrowed to only the 3 consumed Symbols (`:thin`, `:thick`, `:menu`) plus the safe default `10_i64`.
    49	
    50	**5 remaining legacy hits confined to `_legacy_*` methods:** TRUE.
    51	- line 861: `_legacy_tab_view` (TabView)
    52	- line 1093: `_legacy_alert` (Alert)
    53	- line 2000: `_legacy_toolbar` (Toolbar)
    54	- line 2178: `_legacy_sheet` (Sheet)
    55	- line 2335: `_legacy_popover` (Popover)
    56	
    57	Exactly matches the architect handoff doc's claim. No leakage into active visit paths.
    59	## Handoff doc verification
    60	
    61	`docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md` EXISTS (47 lines).
    62	
    63	The doc:
    64	1. Names all 5 `_legacy_*` methods with line numbers (Tab/Alert/Toolbar/Sheet/Popover).
    65	2. Cites `implementation.md` lines 85-89 as the formal escalation clause.
    66	3. Provides 3 cleanup options (delete dead code / migrate to facade / extend helper) for Phase 6.5+.
    67	4. Architect-acknowledged out-of-scope with explicit reasoning (none on active visit path; widget facade migration is its own phase; no consumer-visible regression risk).
    68	
    69	`implementation.md` line 89 reads: "If during implementation you discover this would balloon the diff beyond a reasonable single-phase scope (more than ~12 visit methods to refactor), stop and return to the team lead with what you found rather than picking an arbitrary subset." This handoff doc IS that "stop and return" — a legitimate escalation, NOT scope-drift normalization.
    70	
    91	## What this verdict says
    92	
    93	PASS — all 11 invariants honored per their (amended) declarations, R3 closed the 3 named sites, the helper exists and is correctly narrowed, the 5 legacy hits are properly confined and architect-escalated via a legitimate handoff doc. The amendments to I-1/I-7/I-8/I-10/A1 match the shipped implementation. Prior-phase non-environmental baselines hold.
    94	
    95	The macOS AXTest BX2+BX7 blocker is environmental (TCC accessibility grant revoked; not a Phase 5 regression). The reviewer should grant Terminal accessibility before re-running iter 3 if there's a future iter 3; for THIS verdict it is recorded as environmental and not blocking PASS.
    96	
    97	Minor doc-text drift in A1's "spike uses .bar" trailing sentence (actual spike uses `.ultraThickMaterial`) is recommended for a one-line amendment fix but not a blocker — falsifier passes.

exec
/bin/zsh -lc "nl -ba spikes/swiftui_material_spike.swift | sed -n '24,48p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    24	    public enum APSKMaterialStep {
    25	        case ultraThin
    26	        case thin
    27	        case regular
    28	        case thick
    29	        case chrome  // Maps to .ultraThickMaterial (no public .chromeMaterial in SwiftUI)
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
    43	            // .chromeMaterial doesn't exist in public SwiftUI; the closest
    44	            // equivalents are .ultraThickMaterial (strongest blur) or .bar
    45	            // (chrome-tinted overlay). Phase 5 implementer's actual binding
    46	            // chose ultraThickMaterial; spike verifies the API compiles.
    47	            Text("Material spike").padding().background(.ultraThickMaterial)
    48	        }

exec
/bin/zsh -lc "nl -ba docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md | sed -n '19,27p;39,42p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "nl -ba src/ui/native/swiftkit_overrides.cr | sed -n '619,638p' && nl -ba src/ui/design_tokens/material.cr | sed -n '77,100p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    19	## Why these were not closed by R3
    20	
    21	R3's named scope was only the 3 active-visit-path sites Codex identified (NavigationSplitView/ContextMenu/ActivityView). The 5 above live in `_legacy_*` methods that are NOT invoked from the active dispatch path; they're preserved as historical references for the facade migration. Per Phase 5 R3's Codex pre-merge critique, the active widgets in this list (TabView/Alert/Toolbar/Sheet/Popover) all route through the SwiftKit facade now via `apsk_make_*` paths — the `_legacy_*` body is dead code for runtime purposes.
    22	
    23	Per `implementation.md` lines 85–89 (tokenize every hard-coded material site OR escalate), this is the formal escalation handoff. Architect's reasoning for acknowledging as out-of-scope:
    24	
    25	1. **Not runtime-active.** None of the 5 `_legacy_*` methods is on the active `visit(...)` dispatch path. Removing or tokenizing them is dead-code cleanup, not behavioral change.
    26	2. **Phase 5's actual architecture diverged from implementation.md's translation-table envisioning.** Implementation.md L555–569 imagined a UIKit→AppKit material-integer translation table. Phase 5 actually shipped SwiftKit facade enum routing — a more modern Swift-side approach. The R3 Symbol→NSVisualEffectMaterial helper is narrow (3 step values) by intent; broadening it for the 5 legacy methods would require either expanding the helper artificially OR migrating those methods to the SwiftKit facade path (which would be Phase 5 facade-migration work, not Phase 5 material-tokenization work).
    27	3. **No consumer-visible regression risk.** The 5 sites are not on user-reachable code paths in the current renderer.
    39	## Validator scope for Phase 5 iter 2
    40	
    41	Phase 5 Validator iter 2 should treat these 5 hits as **architect-adjudicated known-debt**: `_legacy_*` methods are out of Phase 5's named scope; this handoff doc is the formal escalation per `implementation.md:85`. The validator confirms the doc exists + that the 5 hits are confined to `_legacy_*` methods (no leakage into active visit paths).
    42	

 succeeded in 0ms:
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

codex
No. I found a blocking false claim, so I would not accept the iter-2 PASS.

The first blocker is R3. `/tmp/p5-v2-validator-draft.md` claims R3 closed the active NavigationSplitView path and says the `appkit_visual_effect_material(sidebar_step)` call is “in the active visit method” at lines 1836-1838 ([draft](/tmp/p5-v2-validator-draft.md:42)). That is false. The active `visit(view : UI::NavigationSplitView)` ends at [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1805); the cited tokenized `setMaterial:` is inside `_legacy_navigation_split_view`, which begins at [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1809) and contains the cited helper call at [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1835). That directly contradicts the draft’s R3 claim.

R3’s tokenization is not semantically correct. It centralizes old integers, but it does not implement the Phase 5 contract to “look it up in the token tree” and “pass the resolved parameters” ([implementation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:87)). The helper maps `:thin`, `:thick`, and renderer-private `:menu` to fixed AppKit constants ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:4701)). `:menu` is explicitly not a portable material token ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:4682)), and `Material#apple_step` returns any non-`:regular` declared step unchanged, so brand intensity does not affect these sites ([material.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/design_tokens/material.cr:80)). The code comments even call the resulting constants byte-identical to pre-Phase-5 behavior for NavigationSplitView and ActivityView ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1830), [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:3764)).

The legacy-debt handoff is not a legitimate escalation under `implementation.md:85-89`. The contract says refactor every current hard-coded `setMaterial:` visit method, and only “stop and return” if it balloons beyond roughly 12 methods ([implementation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:85)). The handoff instead reclassifies five remaining sites as “known-debt” and tells the validator to accept them ([handoff](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md:41)). That normalizes scope drift, especially because the same handoff calls Option C a “30-minute mechanical edit” ([handoff](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md:37)), not a >12-method blowup.

Brief amendments are only partially truthful. I-7/I-8 look consistent with the code I checked, but A1 is literally false: the brief says the spike uses `.bar` ([brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:196)); the spike uses `.ultraThickMaterial` for `chrome` ([swiftui_material_spike.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spikes/swiftui_material_spike.swift:43)). The draft acknowledges this but incorrectly downgrades it to non-blocking drift ([draft](/tmp/p5-v2-validator-draft.md:97)).

I stopped at the contract mismatch; I did not run the full validation ladder. The PASS verdict should be rejected until the R3/legacy-scope claims are corrected and the implementation either tokenizes the remaining material sites per contract or records a real pre-implementation stop/escalation.


tokens used
111,481
No. I found a blocking false claim, so I would not accept the iter-2 PASS.

The first blocker is R3. `/tmp/p5-v2-validator-draft.md` claims R3 closed the active NavigationSplitView path and says the `appkit_visual_effect_material(sidebar_step)` call is “in the active visit method” at lines 1836-1838 ([draft](/tmp/p5-v2-validator-draft.md:42)). That is false. The active `visit(view : UI::NavigationSplitView)` ends at [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1805); the cited tokenized `setMaterial:` is inside `_legacy_navigation_split_view`, which begins at [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1809) and contains the cited helper call at [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1835). That directly contradicts the draft’s R3 claim.

R3’s tokenization is not semantically correct. It centralizes old integers, but it does not implement the Phase 5 contract to “look it up in the token tree” and “pass the resolved parameters” ([implementation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:87)). The helper maps `:thin`, `:thick`, and renderer-private `:menu` to fixed AppKit constants ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:4701)). `:menu` is explicitly not a portable material token ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:4682)), and `Material#apple_step` returns any non-`:regular` declared step unchanged, so brand intensity does not affect these sites ([material.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/design_tokens/material.cr:80)). The code comments even call the resulting constants byte-identical to pre-Phase-5 behavior for NavigationSplitView and ActivityView ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:1830), [appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:3764)).

The legacy-debt handoff is not a legitimate escalation under `implementation.md:85-89`. The contract says refactor every current hard-coded `setMaterial:` visit method, and only “stop and return” if it balloons beyond roughly 12 methods ([implementation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/implementation.md:85)). The handoff instead reclassifies five remaining sites as “known-debt” and tells the validator to accept them ([handoff](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md:41)). That normalizes scope drift, especially because the same handoff calls Option C a “30-minute mechanical edit” ([handoff](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md:37)), not a >12-method blowup.

Brief amendments are only partially truthful. I-7/I-8 look consistent with the code I checked, but A1 is literally false: the brief says the spike uses `.bar` ([brief.yml](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml:196)); the spike uses `.ultraThickMaterial` for `chrome` ([swiftui_material_spike.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/spikes/swiftui_material_spike.swift:43)). The draft acknowledges this but incorrectly downgrades it to non-blocking drift ([draft](/tmp/p5-v2-validator-draft.md:97)).

I stopped at the contract mismatch; I did not run the full validation ladder. The PASS verdict should be rejected until the R3/legacy-scope claims are corrected and the implementation either tokenizes the remaining material sites per contract or records a real pre-implementation stop/escalation.


