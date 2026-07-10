# Phase 10 Parallel-Trio Architecture Decisions

**Date:** 2026-05-25
**Context:** Codex antagonist findings on the three v1 briefs (10A.0, 10B.0, 10C.0) revealed scope-affecting issues. This document records the architectural decisions reconciling those findings before brief v2 dispatch.

---

## Decision 1: Convention enforcement uses a Crystal-side runner, not AmberLSP

**Trigger:** Codex 10A.0 HIGH-4. AmberLSP's `CustomRule` mechanism is YAML-regex-only. No Crystal compiled rule loader, no asset_pipeline shard detection, no `ProjectContext` support. Scoping v3 §"10A.0" assumed a Crystal loader exists; that assumption is wrong.

**Owner ruling (2026-05-25):** Crystal-side runner. Ship asset_pipeline rule logic as a standalone Crystal program. Runs in CI + as a pre-commit hook + invokable by AI agents via grep-style output. Preserves the spirit of "rules encoded, violations discoverable" but doesn't require AmberLSP extension.

**Implications:**

- **10A.0 reframes** from "AmberLSP CustomRule integration" to "Crystal-side convention runner."
  - New artifact: `scripts/lint_conventions.cr` (or equivalent) — a Crystal program that walks repo files, applies all loaded rule classes, prints diagnostics, exits 0/1.
  - Rule classes still live in `src/lsp_rules/family_N_*/foo_rule.cr` (keep the directory naming for future-LSP-port viability).
  - Each rule class implements `check(file_path, content) : Array(Diagnostic)`.
  - The runner aggregates diagnostics across rules; output format includes file:line + rule name + message + suggested fix.
  - Family 1, 2, 3 rules from 10A.0 ship under this mechanism.
  - Family 5 directory-convention rule from 10C.0 ships under the same mechanism.
  - Family 4 + Family 5 deep rules in 10A.final extend the same runner.

- **Skill documentation** still ships via the `shards` package manager (not `shards-alpha` — Codex 10A.0 MED-4 correction). The skill documents: how to invoke the runner, what each rule checks, where to add new rules.

- **Future-port path:** if AmberLSP later grows a Crystal compiled rule loader, the rule classes in `src/lsp_rules/` port directly. The runner becomes a thin wrapper that AmberLSP can also call.

- **AmberLSP extension** is NOT in asset_pipeline's Phase 10 scope. If the amber_cli project later adopts the same rule shape, that's a follow-up cross-repo task.

---

## Decision 2: 10A.0 splits into 10A.0a / 10A.0b / 10A.0c

**Trigger:** Codex 10A.0 HIGH-2. 13 rules + spike + distribution + docs is 2-3 weeks for one sub-phase. Codex recommends splitting.

**Decision:** 10A.0 becomes three sub-slices, dispatched in order:

- **10A.0a — Runner substrate + Family 1 (naming rules)**: build the Crystal runner; ship 5 file/class naming rules; skill documentation. Establishes the rule-class pattern + diagnostic shape + runner invocation.
- **10A.0b — Family 2 (view-spec pair)**: depends on 10C.0 close (needs `spec/web/` + `spec/native_<X>/` directories to exist).
- **10A.0c — Family 3 (architectural rules)**: 5 architectural rules with narrow heuristics + false-positive fixtures + Voyager calibration.

**Implications:**

- Replaces task #129 (single 10A.0) with three sub-tasks.
- 10A.0a is the only true parallel sub-phase with 10B.0 + 10C.0. 10A.0b waits for 10C.0; 10A.0c can run after 10A.0a closes.
- "Minimal doc scaffolding" (file headers + module summaries) becomes a separate slice (call it 10A.0d) or rolls into 10A.0a.

---

## Decision 3: Family 3 architectural rules start narrow

**Trigger:** Codex 10A.0 HIGH-3. Regex-based AST analysis (`no_app_domain_mutation_in_build_rule`) can't reliably distinguish domain mutation from view-local mutation. False-positive risk is high.

**Decision:**

- 10A.0c brief MUST specify narrow checks:
  - Only inspect classes inheriting `UI::Screen`.
  - Only scan inside `def build`.
  - Flag known domain singletons (`Voyager.state`, `App.state`) — not arbitrary setters.
  - Allow view-local mutation on locals created in `build`.
  - Record every known false positive as a regression fixture before widening rule scope.

- Don't claim AST-level certainty. The runner uses regex/string-level analysis until/unless we build a proper parser hook.

- The 5 Phase 8 architectural rules from `ui-app` skill ARE different from the brief's list. Architect to verify the canonical 5 and replace `screen_registration_matches_class_rule` if it's not one of them.

---

## Decision 4: 10B.0 architecture pin-down

**Trigger:** Codex 10B.0 HIGH-1 through HIGH-5. Multiple architectural decisions the brief v1 left to the implementer.

**Architect rulings:**

- **Reactivity loop documented as the actual flow.** Brief v2 specifies: `controller state mutation → UI::ActionResult::Rerender → ActionDispatcher mount → NavigationCoordinator publish → host on_change rebuilds screen → resolve runs`. Plain state mutation (no `Rerender` action result) is NOT enough. The brief surfaces this clearly so the implementer doesn't expect mutation-only triggers.

- **ScreenContext platform extension is in scope for 10B.0.** Add `platform : Symbol` (or similar) to `UI::ScreenContext` so `resolve(intent, context)` can branch on platform. The current context types (`ScreenContext`, `ScreenContext::Native`) get extended. Migration of all consumer code is part of 10B.0.

- **Override storage is class-scoped registry.** NOT instance fields on `UI::Screen`. The brief specifies the registry shape:
  ```crystal
  module UI::Intent::Registry
    @@app_overrides = {} of Symbol => OverrideSpec
    @@screen_overrides = {} of {Screen.class, Symbol} => OverrideSpec
    # ...
  end
  ```
  The public API `UI::App.override_intent(...)` and `UI::Screen.override_intent(...)` (class-level method or macro) writes into the registry. The registry is the source of truth across rebuilds.

- **Capability validation requires a concrete declaration API.** The brief v2 specifies a class-level macro on widgets:
  ```crystal
  class UI::SwipeActionRow < UI::View
    declares_capabilities :swipe_actions, {
      supports_edge_trailing: true,
      supports_role_destructive: :partial,
      # ...
    }
  end
  ```
  Registry validates that the override widget's declared capabilities ⊇ the required capabilities. Validation runs at `override_intent` call time (registration), raises a clear error if mismatch.

- **Resolver return type ships as a working compiling example.** Brief v2 includes the resolver signature + a working call-site like:
  ```crystal
  action_row_class = UI::Intent.resolve(:swipe_actions, ctx)
  action_row = action_row_class.new(content: row_content, trailing_actions: [...])
  ```
  Implementer must prove this compiles before close. The `View.class` return type either works for our concrete view classes (probably) or gets replaced with a typed factory descriptor.

- **No "placeholder fallback for missing widget" silent warning.** Codex MED-1: returning `UI::SwipeActionRow` for macOS/web_wide when `UI::InlineActionRow` is missing hides the gap. Brief v2 instead defines an `UnresolvableDefault` error path that the resolver raises if the default isn't installed — apps must explicitly install an override OR get a clear error. 10B.1a removes the error by introducing `UI::InlineActionRow`.

- **Specs location:** 10B.0 puts specs under `spec/ui/intent_spec.cr` (existing layout) and 10C.0 migrates them. This decouples 10B.0 from 10C.0 close.

- **At least one fake test intent in specs** to prove the registry is plural and data-driven (Codex MED-4).

---

## Decision 5: 10C.0 budget + scope realism

**Trigger:** Codex 10C.0 HIGH-1 through HIGH-3. 132 specs (not 20). 129 with relative `require` paths. Native compile matrix scope ambiguity.

**Architect rulings:**

- **Spec inventory uses the 132 actual count.** Implementer's Deliverable 1 lists all 132 with target paths. Effort budget: ~2-3 days for inventory + classification, ~1-2 days for moves + require-path edits, ~1 day for runner Makefile + bridge `.o` lifecycle.

- **Classification rule for ambiguous specs:** Codex's recommendation adopted verbatim — "classify by the deepest platform dependency, not just flags in the spec file." If a spec exercises a platform-gated view/renderer path, place it in the platform directory unless it intentionally uses fakes/stubs to test the platform-neutral contract. Multi-platform contract specs stay in `spec/web/` only if they pass under plain `crystal spec` without native link flags.

- **Native compile matrix: best-effort attempt + documented blockers.** Three statuses per platform: `verified`, `attempted-blocked`, `deferred-not-attempted`. Each blocked status documents: exact attempted command, compiler path/version, SDK assumptions, first actionable error, next remediation owner. Do NOT require fixing iOS/Android in 10C.0.

- **Root Makefile creation in scope.** Repo currently has Makefiles only under `samples/`. 10C.0 creates `Makefile` at repo root with test-web/test-macos/test-ios/test-android/test-all targets.

- **`objc_bridge.o` lifecycle in scope.** `make test-macos` depends on compiling `src/ui/native/objc_bridge.m` to `.o`. The Makefile target has the compile recipe.

- **CI feasibility:** macOS runners already exist in the workflow. Android needs `ubuntu-latest` + Android SDK setup or `continue-on-error` for the Android job. Architect-decided: ship Android as `continue-on-error` initially; reconsider once 10B.1c lands.

- **`crystal-alpha` / `acrystal` naming:** brief uses `acrystal` (per `[[reference_agent_crystal]]`). If the actual binary is still installed as `crystal-alpha`, document the alias requirement in the matrix doc.

- **Family 5 directory rule ships as a Crystal-side rule under Decision 1's runner**, not as an AmberLSP rule. Acceptance: rule file exists + invocation works + flags violations. (Codex was right that the v1 acceptance gate language was misleading.)

---

## Decision 6: Hidden coupling between 10B.0 and 10C.0

**Trigger:** Codex 10B.0 MED-2 + Codex 10A.0 HIGH-2. 10B.0 specs and 10A.0 Family 2 both depend on 10C.0's spec directory split.

**Decision:**

- 10B.0 and 10A.0a ship to current `spec/` layout (`spec/ui/...`, `spec/asset_pipeline/...`). 10C.0 migrates these specs when it lands.
- 10A.0b (Family 2 view-spec pair) waits for 10C.0 close. Becomes a sequential sub-phase, not parallel.
- 10C.0 close coordinates: every spec moved gets a follow-up grep for relative-require breakage.

---

## Updated dependency graph

```
phase-10 (current)
├─► 10B.0 (resolver + reactivity) — parallel slot 1
├─► 10A.0a (runner + Family 1) — parallel slot 2
└─► 10C.0 (spec split + runner matrix + Family 5 rule) — parallel slot 3
        │
        └─► after 10C.0 closes:
             ├─► 10A.0b (Family 2) — sequential
             └─► 10A.0c (Family 3) — sequential or parallel with 10A.0b
                  │
                  └─► 10B.1a–10B.5 (widget implementation) — sequential after 10B.0
                       │
                       └─► 10A.final (full docs + Family 4 + Family 5 deep) — sequential
                            │
                            └─► 10D (Voyager + intent exerciser + owner test)
```

The three parallel slots (10B.0 / 10A.0a / 10C.0) are now truly independent.

---

## Architect status after reconciliation

Ready to write three v2 briefs:
- `brief-10-b-0.md` v2 — addresses all 5 HIGH + 4 MEDIUM findings.
- `brief-10-a-0a.md` v2 (renamed from brief-10-a-0) — Crystal-side runner + Family 1 only.
- `brief-10-c-0.md` v2 — 132 specs, classification rule, root Makefile, .o lifecycle, Family 5 rule shape post-Decision 1.

New brief skeletons (for after 10C.0 closes):
- `brief-10-a-0b.md` — Family 2.
- `brief-10-a-0c.md` — Family 3 with false-positive fixtures.

— Architect (Claude Opus 4.7)
