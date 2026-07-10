# Phase 10 — Ship the Initiative (SCOPING v3)

**Date opened:** 2026-05-25
**v2 → v3 reconciliation:** 2026-05-25 — adopted all 6 HIGH + 4 MEDIUM + 3 LOW Codex findings.
**Status:** SCOPING v3 — ready to brief 10-pre.1.
**Branch:** `phase-10` cut from `feature/utility-first-css-asset-pipeline`. Sub-phase subbranches off `phase-10`.
**Predecessors:** Phase 9 closed PASS at `phase-09-pass-2026-05-25` but with documented catalog accuracy gaps (see `handoff/phase-10-pre-catalog-freshness-2026-05-25.md`).

---

## What changed from v2

v2 proposed a strict serial 5-sub-phase chain (10-pre → 10A → 10B → 10C → 10D). Codex returned REVISE with 6 HIGH findings (see `codex-coplan-10-v2.md`). v3 adopts all findings:

1. **Hard serialization replaced with dependency lanes.** Spec directory split + LSP substrate + bridge skeleton work overlap after 10-pre.1 closes.
2. **10-pre split.** 10-pre.1 (factual correction) and 10-pre.2 (API freeze) carry distinct concerns.
3. **B.2 split into three.** Static AX metadata / action+focus+keyboard / environment-driven contracts.
4. **B.3.0 bridge substrate before any Class C feature.**
5. **Class D rename moved to 10-pre.2 (API freeze)**, not the end of 10B.
6. **Reactivity contract added as gate** on B.0 resolver + every routed widget.
7. **Docs split 10A.0 (minimal scaffold) + 10A.final (full docs after API freeze).**
8. **Voyager + intent exerciser** at 10D — 4 screens cannot prove 67 intents alone.
9. **Native compile matrix discovery in 10C.0.** Not assumed.
10. **Golden evidence packets per sub-phase** — internal capture replaces lack of owner mid-phase checkpoints.

## The problem being solved

After Phase 8 + 9:

1. **Catalog overstates the framework's actual coverage in 14+ places.** Class A capabilities falsely claim leading-edge support, disabled actions, UIAccessibilityCustomAction. Class B says "partial" on intents that are zero. Class C is 0 of 9 realized. Class D `crystal_api_shape` strings misname classes, properties, init signatures.
2. **8+ named widgets that don't exist in `src/`.** `UI::InlineActionRow`, `UI::Menu`, `UI::FullScreenCover`, `UI::Inspector`, `UI::ToolbarItemGroup`, `UI::ToolbarSpacer`, `UI::NavigationPath`, etc.
3. **API name decisions pending.** Catalog (Apple vocabulary) vs Crystal source code (Crystal idioms) disagree on ~12 of 40 Class D rows. No protocol decides which wins.
4. **No mechanism to enforce framework conventions.** AmberLSP exists; asset_pipeline has no rules.
5. **Crystal API docs are sparse.** `crystal tool docs` output is incomplete for the public surface.
6. **Multi-target test coverage is invisible to `crystal spec`.** Flag-gated code only runs under the right `-D` flag.
7. **Skills don't ship.** shards-alpha supports it; layout untested.
8. **Voyager is not a faithful proof.** 4 screens; never exercised against the catalog contracts; LSP rules never run in a real Claude Code session.
9. **Native compilation matrix is aspirational.** iOS/Android builds were established in Phase 4 (per `[[project_platform_minimums]]` memory: macOS 14+, iOS 16+) but the simulator-run feasibility and CI integration are not proven.

## Owner directives (binding)

From 2026-05-25:

1. **"Move on to phase 10 to complete everything."** Phase 10 is terminal for the initiative.
2. **Full 35-item backlog** (confirmed AskUserQuestion 2026-05-25). All P0 + P1 + P2 widgets land in Phase 10.
3. **"Implementing all of our widgets to test that they work."** Widget implementation in scope.
4. **"Voyager app is functional."** Voyager + companion intent-exerciser must run correctly on all 4 targets.
5. **"Tooling we expect to work should now help improve development."** LSP rules + skills active during widget implementation, not at the end.
6. **Convention B — directory split for spec platforms.** `spec/native_ios/`, `spec/native_macos/`, `spec/native_android/`, `spec/web/`. From v1.
7. **Rules live in asset_pipeline.** AmberLSP loads them via `CustomRule`. From v1.
8. **Public surface only for docs.** From v1.
9. **Don't pause at sub-phase boundaries.** Per `[[complete-phase-arc-before-review]]`. Only owner checkpoint is 10D hands-on test.
10. **Skills ship via shards-alpha.** From v1.

## Sub-phase decomposition (v3)

### Dependency graph

```
10-pre.1 — factual catalog correction
   │
   ├─► 10-pre.2 — API freeze + rename protocol
   │      │
   │      ├─► 10A.0 — LSP families 1–3 + skill substrate + minimal docs
   │      ├─► 10C.0 — spec directory split + runner matrix + Family 5 directory rules
   │      └─► 10B.0 — Tier 2 resolver + reactivity contract
   │                     │
   │                     ├─► 10B.1a — UI::InlineActionRow creation
   │                     ├─► 10B.1b — :swipe_actions capability honesty
   │                     ├─► 10B.1c — Android Material 3 swipe integration
   │                     ├─► 10B.2a — Static AX metadata
   │                     ├─► 10B.2b — Action + focus + keyboard
   │                     ├─► 10B.2c — Environment-driven contracts
   │                     ├─► 10B.3.0 — Native bridge substrate
   │                     │       └─► 10B.3.x — Class C features riding substrate
   │                     ├─► 10B.4 — Missing widgets
   │                     └─► 10B.5 — Remaining Class D implementations
   │                                 │
   │                                 └─► 10A.final — Full docs + LSP families 4–5
   │                                            │
   │                                            └─► 10D — Voyager + intent exerciser + owner test
```

### Sub-phase definitions

#### 10-pre.1 — Factual catalog correction

**Goal.** Make `intent-catalog.md`, `intent-routing-candidates.md`, `widget-intent-mapping.md`, and `translation-matrix.md` accurately reflect what `src/ui/views/` provides today. No API renames — that's 10-pre.2.

**Deliverables.**

1. `intent-catalog.md` corrected: every `coverage_today` value either `missing`/`catalog_only` OR cites `src/...:line-range`. The 9 Class C rows currently labeled various states all become `missing` honestly. The 2 Class B "partial" claims (`accessibility_hint`, `accessibility_value`) become `missing`. The Class A capability block trimmed to verified capabilities only (likely 6–7 of 12).
2. `intent-routing-candidates.md` corrected: capability block matches reality.
3. `widget-intent-mapping.md` rewritten with citation per row. `activity_view.cr` reclassified honestly (presentational, not Class C bridge).
4. `translation-matrix.md` corrected: `UI::InlineActionRow` (macOS + web_wide default) honestly marked as "MISSING — see backlog B-001/B-002."
5. `intent-backlog.md` count reconciled (34 vs 35). Items repriotized per freshness audit: B-001/B-002/B-035 promoted; B-020 confirmed P0; new items added if 10-pre.1 surfaces additional gaps.
6. `scripts/lint_intent_catalog.cr` extended with citation-presence check.
7. `handoff/phase-10-pre.1-close.md` summary.

**Acceptance gate.**
- Independent re-audit by an agent with a different system prompt finds zero unbacked `coverage_today` claims.
- Schema lint passes with citation-presence check ON.

**Estimated size.** 1 implementer iteration (it's documentation correction, mechanical) + 1 Codex content review. ~2 days.

**Out of scope.** No code changes. No widget creation. No API renames. No Class D `crystal_api_shape` rewrites (that's 10-pre.2).

#### 10-pre.2 — API freeze + rename protocol

**Goal.** Decide every catalog ↔ Crystal API name disagreement before downstream phases lock in.

**Protocol** (per Codex Q2 answer): **Code wins by default** for already-shipped public Crystal APIs. Catalog preserves Apple intent identifiers (snake_case-of-Apple-name); `crystal_api_shape` documents the Crystal-idiomatic name. Catalog never invents methods/operators that don't exist in code. Where a Crystal API name is actively misleading or blocks Apple-vocabulary intent mapping (rare), the Crystal API renames and 10-pre.2 ships the rename + a migration note.

**Deliverables.**

1. Class D `crystal_api_shape` reconciliation: every 40 Class D row updated. `UI::ListView` not `UI::List`. `detents` not `presentation_detents`. `shows_drag_indicator : Bool` not three-valued symbol. `add_item(id:, label:, icon:, &block)` not `<<`. `UI::Toolbar.new(@title : String?)` not `(items: [...])`. Etc.
2. Per-row decision log: for each disagreement, recorded outcome (code wins / catalog wins / new design needed) with one-line rationale.
3. Where catalog wins (expected rare — likely 0–3 cases): Crystal API renames committed in the same slice + Voyager updates.
4. `intent-backlog.md` final count: confirmed integer with stable IDs.
5. `handoff/phase-10-pre.2-close.md` records the API freeze.

**Acceptance gate.**
- Codex re-audits all 40 Class D rows against `src/ui/views/` and confirms zero divergence.
- Voyager compiles after any catalog-wins renames (Voyager-side fixes are part of 10-pre.2 scope).

**Estimated size.** 2 implementer iterations + Codex audit. ~3–4 days.

**Out of scope.** New widgets. New Class D entries. Class B/C scope work.

#### 10A.0 — LSP families 1–3 + skill substrate + minimal docs

**Goal.** Land the LSP substrate + skill distribution + minimal doc scaffolding. Defer family 4 (test_id hygiene), family 5 (multi-target coverage deep rules), and full public docs until APIs stabilize.

**Deliverables.**

1. `src/lsp_rules/family_1_naming/*.cr` — file/class naming rules.
2. `src/lsp_rules/family_2_view_spec/*.cr` — view-spec pair rules.
3. `src/lsp_rules/family_3_architectural/*.cr` — Phase 8 architectural rules.
4. AmberLSP `CustomRule` integration: asset_pipeline rules load when AmberLSP detects an asset_pipeline shard dependency.
5. `.claude/skills/asset_pipeline--lsp-rules/SKILL.md` — skill documenting the rule families.
6. shards-alpha install audit in a scratch consumer project.
7. Minimal doc scaffolding: file header comments + module summaries on every public Crystal file, NOT full per-method docs.

**Acceptance gate.**
- All families 1–3 rules pass green on current asset_pipeline + Voyager source.
- All families 1–3 rules fire RED on intentionally-broken scaffolds.
- Skills install correctly in a scratch project.
- Scratch project's AmberLSP server picks up asset_pipeline rules at startup.

**Estimated size.** ~17 rules + skill + scratch validation. 4–6 implementer iterations.

#### 10C.0 — Spec directory split + platform runner matrix + Family 5 directory rules

**Goal.** Move spec organization + platform runners INTO place before any widget code lands, so 10B writes specs into the right structure from day one.

**Deliverables.**

1. Spec directory reorganization: every existing spec moves into `spec/web/` (default) or `spec/native_<X>/` per Convention B. `spec/spec_helper.cr` + any test runners updated.
2. Per-platform test runner shell scripts / Makefile targets:
   - `make test-web` runs `crystal spec spec/web/`.
   - `make test-macos` runs `crystal-alpha spec spec/native_macos/ -Dmacos --link-flags="..."`.
   - `make test-ios` runs `crystal-alpha spec spec/native_ios/ -Dios --link-flags="..."`.
   - `make test-android` runs `crystal-alpha spec spec/native_android/ -Dandroid --link-flags="..."` (if Android compile is feasible).
   - `make test-all` runs everything.
3. **Native compilation matrix discovery** (per Codex MEDIUM-3): exact commands, link flags, expected unsupported cases per platform. Documented in `docs/initiative-cross-platform-ui/native-compile-matrix.md`. If iOS/Android compile is broken today, that's a finding that may demand its own remediation slice.
4. `src/lsp_rules/family_5_partial/spec_platform_directory_convention.cr` — rule that flags spec files outside the convention.
5. CI workflow `.github/workflows/initiative-cross-platform-ui.yml` updated to run all available platform spec targets.

**Acceptance gate.**
- `make test-web` passes.
- `make test-macos` passes (per `[[project_platform_minimums]]`).
- `make test-ios` either passes or has a documented obstacle.
- `make test-android` either passes or has a documented "deferred" state.
- `spec_platform_directory_convention` LSP rule passes green on reorganized tree.
- CI workflow runs all feasible targets.

**Estimated size.** 1 implementer iteration for reorg + 1 for runner discovery + 1 for CI. ~1 week.

#### 10B.0 — Tier 2 resolver + reactivity contract

**Goal.** Turn `tier-2-translation-contract.md` pseudocode into real Crystal. Establish render-time + rerender-safe contract as an invariant.

**Deliverables.**

1. `src/ui/intent.cr` — `UI::Intent.resolve(intent_id, context, capabilities_required:)` returns the platform-resolved widget class.
2. Override registry: `UI::App.override_intent(intent_id, widget_class, capabilities:)` (app-scope) and screen-local override mechanism.
3. Override precedence resolved at `resolve()` call: screen > app > default.
4. Capability validation: registry rejects overrides that don't satisfy declared capabilities.
5. **Reactivity contract gate** (per Codex HIGH-6):
   - `resolve()` runs at every `screen.build(ctx)`, NOT memoized at app boot.
   - State mutation → `screen.build(ctx)` → `resolve()` re-runs.
   - Spec coverage: override change + state change + rerender preserves current platform override.
6. Specs in `spec/web/` exercising resolver + override + capability validation.

**Acceptance gate.**
- Specs prove resolver semantics + reactivity invariant.
- Codex content review on the contract code (architect antagonist mode).

**Estimated size.** 1 implementer iteration. ~3–4 days.

#### 10B.1a — UI::InlineActionRow creation

Create `UI::InlineActionRow` as the macOS + web_wide default for `:swipe_actions`. Move AppKit inline-button rendering logic from `UI::SwipeActionRow`'s renderer into `UI::InlineActionRow`. Migrate override registry. AXTest spec on macOS. Web rendering spec.

**Acceptance gate.** macOS Voyager renders inline buttons via `InlineActionRow`. Web-wide Voyager renders inline buttons via `InlineActionRow`. Web-narrow Voyager still uses `SwipeActionRow`.

**Estimated size.** 1 implementer iteration. ~2–3 days.

#### 10B.1b — `:swipe_actions` capability honesty

Implement the 4 capabilities marked FALSE in the freshness audit: leading-edge actions on UIKit + AppKit + Android (not just web), disabled actions, UIAccessibilityCustomAction wiring on UIKit, AppKit role tinting on NSButton.

**Acceptance gate.** Capability block in `intent-routing-candidates.md` rewritten to match reality after this lands; freshness re-audit (an automated re-check against the catalog) finds zero FALSE claims.

**Estimated size.** 1–2 implementer iterations + AXTest + native build verification. ~1 week.

#### 10B.1c — Android Material 3 swipe integration

Wire `SwipeToDismissBox` (Compose Material 3) into the Android renderer's `visit(UI::SwipeActionRow)` method. Honor trailing + leading actions. Respect destructive role for color tinting.

**Acceptance gate.** Android build of Voyager compiles + renders swipe actions (or the slice formally defers Android with `[[project_platform_minimums]]` rationale).

**Estimated size.** 1 implementer iteration. ~3–5 days.

#### 10B.2a — Static AX metadata on `UI::View` base

Add to `UI::View`: `accessibility_hint : String?`, `accessibility_value : String?`, `accessibility_traits : Array(Symbol)?`, `accessibility_element_children : Symbol?` (grouping).

Each renderer maps to native equivalent. Specs in each platform spec dir.

**Acceptance gate.** All 82 views inherit the new properties. Renderers honor them. AXTest verifies accessibility tree on macOS.

**Estimated size.** 1 implementer iteration. ~3–4 days.

#### 10B.2b — Action + focus + keyboard

`UI::AccessibilityAction` struct + `accessibility_actions : Array(AccessibilityAction)?` on `UI::View`. UIKit `UIAccessibilityCustomAction`. AppKit `NSAccessibilityCustomAction`. Focus management: `focused : Bool?`, `focusable : Bool?`. Full keyboard access audit on every interactive widget.

This closes backlog B-020 (P0) — the HIG-mandated swipe accessibility action surface.

**Acceptance gate.** B-020 closed. Voyager swipe rows expose custom actions via VoiceOver/Switch Control. Full-keyboard navigation works through Voyager screens.

**Estimated size.** 2 implementer iterations + AXTest verification. ~1 week.

#### 10B.2c — Environment-driven contracts (per Codex Q3 answer)

`UI::Environment` module with: `reduce_motion?`, `dynamic_type_size`, `increase_contrast?`, `differentiate_without_color?`, `captions_enabled?`, `dim_flashing_lights?`. Each reads platform setting. Renderer animation modifiers consult `reduce_motion?`. Font scaling consults `dynamic_type_size`.

**Acceptance gate.** Voyager animations honor reduce-motion on macOS. Font scales with macOS Text Size setting.

**Estimated size.** 1 implementer iteration. ~3–4 days.

#### 10B.3.0 — Native bridge substrate

`UI::System` namespace with: platform capability detection (`UI::System.supports?(:share)`), bridge call conventions (sync/async/error result envelope), no-op behavior on unsupported platforms, one golden bridge as proof — likely `UI::System.copy_to_clipboard(text)` since clipboard is simplest.

**Acceptance gate.** Clipboard works on macOS via NSPasteboard, on iOS via UIPasteboard, on web via Clipboard API. Android documented (defer or stub).

**Estimated size.** 1 implementer iteration. ~4–5 days.

#### 10B.3.x — Class C features riding the substrate

Each remaining Class C intent gets its own slice using the B.3.0 substrate: share (B-026), paste (B-028), open_url (B-030), open_deep_link (B-031), print (B-032), file_importer (B-033), file_exporter (B-034), authorization request (B-029).

Priority order per backlog: P1 first (share, copy already done in B.3.0, open_url, request_permission camera/photos), P2 after (paste, open_deep_link, print, file import/export, other permissions).

**Acceptance gate per slice.** Crystal API + macOS bridge + iOS bridge + web fallback. Android either implemented or formally deferred.

**Estimated size.** 1 slice per intent = 8 slices. Each ~2–3 days. ~3 weeks total.

#### 10B.4 — Missing widgets

Create `UI::Menu`, `UI::FullScreenCover`, `UI::Inspector` (`PanelStyle::Inspector` already exists — needs a real widget), `UI::ToolbarItemGroup`, `UI::ToolbarSpacer`, `UI::NavigationPath`. Each: Crystal class + renderer implementations + spec coverage in correct platform directory + catalog row update.

**Acceptance gate.** All 6 widgets compile on all platforms. Voyager uses at least 3 of them. Catalog `coverage_today` updated with citations.

**Estimated size.** 1 implementer iteration per widget = 6 slices. ~2 weeks.

#### 10B.5 — Remaining Class D implementations

Backlog Class D items that need implementation (NOT just renames — those are 10-pre.2): B-003 `:refreshable`, B-004 `:searchable`, B-005 `:on_move`, B-006 `:context_menu` web rendering, B-007 `:presentation_detents`, B-008 form modifiers, B-011 toolbar modifiers, B-012 picker styles, B-013 date picker styles, B-014 drag/drop, B-015 animation modifiers, B-016 haptics, B-017 search suggestions/scopes, B-018 long-press, B-019 magnify/rotate.

Priority order per backlog: P1 (B-003, B-004, B-007), then P2.

**Estimated size.** Variable per item. Cumulatively ~2–3 weeks.

#### 10A.final — Full public docs + LSP families 4–5 deep rules

After API freeze + all widget shapes stabilized:

1. Crystal doc comments on all public classes/methods. Per-method param/return/raise docs.
2. `crystal docs --output docs/api` clean.
3. Codex audit: samples 5 random classes; confirms docs would let it generate a correct file.
4. LSP family 4 rules: `interactive_widget_has_test_id`, `interactive_widget_has_accessibility_label`.
5. LSP family 5 deep rules: `flag_gated_block_requires_platform_spec`, `view_with_interactivity_requires_xcuitest`, `native_widget_requires_axtest`, `ci_workflow_runs_all_platform_specs`.

**Acceptance gate.**
- Doc audit clean.
- All LSP rules green on current source + RED on broken scaffolds.

**Estimated size.** ~90 files for docs + 6 rules. ~2 weeks.

#### 10D — Voyager + intent exerciser + owner hands-on test

**Goal.** Prove the catalog works end-to-end + verify developer experience.

**Deliverables.**

1. Voyager source updated to use new widgets (InlineActionRow, Menu, FullScreenCover, etc.) where appropriate.
2. Voyager screens exercise the Class A `:swipe_actions` routing (macOS = inline buttons, mobile-web = swipe row) — proves resolver works end-to-end.
3. Voyager screens demonstrate at least 3 Class C system integration intents (share, copy, openURL).
4. **Intent exerciser sample app** (per Codex MEDIUM-2): `samples/initiative-cross-platform-ui-intent-exerciser/` — a generated spec gallery exercising the remaining ~50 intents Voyager flagship flows don't cover. Each intent has one screen + one test. The gallery proves coverage without requiring 67 hand-designed Voyager screens.
5. AXTest coverage for every interactive Voyager widget on macOS.
6. XCUITest coverage for every interactive Voyager widget on iOS (where feasible).
7. All 10A.final LSP rules pass green on Voyager + intent exerciser.
8. Updated `samples/initiative-cross-platform-ui-voyager/README.md` with run instructions per target.

**Acceptance gate (owner-driven — THIS IS THE ONLY OWNER CHECKPOINT).**
- Owner runs `shards-alpha install asset_pipeline` in a scratch project; skills install.
- Owner opens Voyager in their editor with AmberLSP active; diagnostics + completions behave.
- Owner intentionally breaks Voyager (flag-gated code without iOS spec; view without spec; dispatcher bypass); rules fire.
- Owner walks Voyager + intent exerciser across all 4 targets (macOS app, iOS sim, desktop web, mobile-web emulation); interactions behave per catalog.

**Estimated size.** ~3 weeks (Voyager migration + intent exerciser generation + AXTest/XCUITest coverage + owner test session).

## Golden evidence packets per sub-phase

Per Codex LOW-3: each sub-phase closes with a `handoff/phase-10-<id>-close.md` capturing:
- Acceptance gate evidence: screenshots, before/after diff snippets, command output.
- Codex review record.
- Test results (where applicable).
- New backlog items discovered.

The architect reviews each packet at sub-phase close. No owner involvement, but drift is visible internally.

## Cross-cutting

### Standard rhythm

Each sub-phase: architect drafts brief → Codex antagonist → reconcile → dispatch implementer → validator (or independent re-audit) → architect closes with reflection + golden packet → tag → fast-forward merge to `phase-10`.

### Reactivity invariant (binding across 10B)

Per `[[reactivity-is-table-stakes]]`: every new widget AND the resolver MUST preserve runtime state mutation → re-render. No build-time caching of resolved classes. No native-only mutation paths that skip re-render. Specs cover state-mutation-then-rerender on every routed widget.

### Branch + commit

- Sub-phase branches: `phase-10-pre-1`, `phase-10-pre-2`, `phase-10-a-0`, `phase-10-c-0`, `phase-10-b-0`, `phase-10-b-1a`, etc.
- Forward commits only. Tags per sub-phase pass. Fast-forward merge to `phase-10` after each.
- Final merge of `phase-10` to `feature/utility-first-css-asset-pipeline` at 10D pass.

## Risks (v3, after Codex)

- **R1 — Catalog correction surfaces more inaccuracies than freshness check found.** Mitigation: 10-pre.1 budgets "as long as needed."
- **R2 — Class B 2a/2b/2c threading is invasive across 82 views.** Mitigation: split into three; each renderer-acceptance-gated.
- **R3 — Class C bridge substrate is harder than expected.** Mitigation: B.3.0 ships ONE golden bridge first; substrate proves itself.
- **R4 — Catalog ↔ Crystal API rename ripples to Voyager.** Mitigation: 10-pre.2 handles all renames upfront with same-slice Voyager fixes.
- **R5 — Family 5 deep rules need ProjectContext extensions.** Mitigation: 10A.final brief opens with ProjectContext audit; extensions are in-scope if needed.
- **R6 — Multi-target CI is slow.** Mitigation: matrix CI jobs.
- **R7 — Doc audit drift after API freeze.** Mitigation: Codex sample audit at 10A.final close.
- **R8 — iOS/Android compile is broken or never verified.** Mitigation: 10C.0 matrix discovery surfaces this as an EXPLICIT phase finding before 10B starts; if Android compile is broken, 10B.1c becomes deferred and the catalog reflects that honestly.
- **R9 — Resolver reactivity violations during widget implementation.** Mitigation: 10B.0 reactivity gate + spec coverage on every routed widget.
- **R10 — Voyager + intent exerciser scope creep.** Mitigation: intent exerciser is generated/scaffolded, not hand-designed. One template per intent class.

## What Phase 10 ships (v3)

1. Corrected + frozen `intent-catalog.md` + `intent-routing-candidates.md` + `widget-intent-mapping.md` + `intent-backlog.md` (10-pre.1, 10-pre.2).
2. `src/ui/intent.cr` resolver + override registry + reactivity contract (10B.0).
3. Full widget implementation: 35 backlog items + 6 missing widgets + capability honesty + Class B accessibility surface + Class C system bridges (10B.1–10B.5).
4. `src/lsp_rules/` with 5 rule families (10A.0, 10C.0, 10A.final).
5. `.claude/skills/asset_pipeline--lsp-rules/SKILL.md` + verified shards-alpha distribution (10A.0).
6. Crystal doc comments + generated doc site on public surface (10A.final).
7. `spec/web/` + `spec/native_<X>/` directory split (10C.0).
8. Per-platform test runners + updated CI workflow (10C.0).
9. `docs/initiative-cross-platform-ui/native-compile-matrix.md` (10C.0).
10. Voyager compliant + intent exerciser sample (10D).
11. Owner-verified developer experience (10D).

## Out of scope

- Custom LSP server (extending AmberLSP).
- Crystalline integration.
- Other package managers beyond shards-alpha.
- Phase 11. Phase 10 is terminal.
- Android proper integration if 10C.0 discovers Android compile is broken — that becomes a documented "deferred" with the catalog reflecting it honestly.

## Hard rules

- Forward commits only on `phase-10*` branches.
- Sub-phase branches off `phase-10`; fast-forward merge back; tag on pass.
- Codex antagonist on every brief, dispatch decision, and architect reflection per `[[codex-as-architect-antagonist]]`.
- Standard Claude co-author footer.
- No owner checkpoints within Phase 10 except 10D.
- 10-pre.1 + 10-pre.2 MUST close green before 10A.0/10C.0/10B.0 brief dispatch.
- Golden evidence packet per sub-phase close.
- Catalog citations: every `coverage_today` claim other than `missing`/`catalog_only` cites `src/...:line-range`.
- Reactivity invariant: every routed widget + resolver passes state-mutation-then-rerender spec.

---

## Next

1. ~~Codex co-plan on v2.~~ DONE — see `codex-coplan-10-v2.md`.
2. ~~Reconcile to v3.~~ DONE — this document.
3. Brief 10-pre.1 → Codex critique → dispatch.
4. Brief 10-pre.2 → Codex critique → dispatch.
5. Once 10-pre.2 closes, brief 10A.0 + 10C.0 + 10B.0 in parallel (they're independent after API freeze).
6. Etc.

— Architect (Claude Opus 4.7)
