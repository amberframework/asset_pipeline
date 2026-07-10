# Phase 8D.3 Co-Planning — Codex Response

**Date:** 2026-05-25
**Codex session:** medium reasoning, arg-form prompt, default model.
**Role:** Co-planner. Architect asked for engineering judgment on the 14-row interaction proof + capture matrix shape.
**Source log:** `/tmp/codex-coplan-8d3.log`.

---

## Decisions adopted from Codex

### Sub-phase split: 8D.3a / 8D.3b — ADOPT

- **8D.3a** — Save-enabled-on-type fix + owner hand-test gate + `Voyager.build_route` D1 disposition + B2 web architecture position note. ALL architecture + verification, NO captures.
- **8D.3b** — Deterministic capture driver + 28 iOS captures + macOS subset.

Hand-test placement: BEFORE captures, in 8D.3a. Codex reasoning: if real touch input still exposes a dispatcher/renderer bug, the captures become expensive evidence of a state the owner may reject. Hand-test is the higher-fidelity signal; run it first.

### Save-enabled-on-type fix: 1B (local UI mutation) — ADOPT

**Reframing (Codex §8):** The Save button's enabled/disabled state is **view-local control affordance state**, NOT app/domain state. The "every state mutation through dispatcher" rule applies to app/domain state. Local UI affordances are local UI affordances.

`UI::Button#disabled=` already has reactive native propagation (per Codex inspection of `src/ui/views/button.cr`). Wiring:

```crystal
title_field.on_change = ->(value : String) {
  save.disabled = value.strip.empty?
}
```

The existing `UI::FormStateRendererHook.wrap_text_handler` composes: FormState update first, then user handler. So FormState still gets the typed value AND the button reactively re-evaluates.

**1A rejected** (Codex § 2): `ActionResult::Rerender` remounts the route and allocates a fresh FormState. Without preservation plumbing, every keystroke loses the in-progress typed value. Architecturally pure but functionally broken.

**1C does not exist** — `UI::Button` has reactive mutation but no declarative `disabled` ↔ `FormState["field"]` binding. Don't invent one in 8D.3.

### Capture-driver: scenario-flag pre-walked state — ADOPT

- Voyager-only scenario registry (`samples/initiative-cross-platform-ui-voyager/capture_scenarios.cr`).
- Each scenario: initial route, route params, seeded todos/settings, optional form values, optional transient UI flags (e.g. `swipe_revealed_todo_id`).
- iOS bridge reads `VOYAGER_CAPTURE_SCENARIO` env var during `initialize_runtime`.
- Per capture: fresh app launch with scenario + appearance env vars → app renders into target state → `xcrun simctl io DEVICE screenshot` → done.
- Sample-local. NOT a framework API.

**The hand-test proves interaction; the scenario captures prove visual end states.** (Codex §8.)

### macOS swipe-row coverage: capture non-swipe rows only — ADOPT

Don't invent context-menu / right-click substitutes in 8D.3 just for screenshot symmetry. Mark rows 7, 8, (10) as iOS-only gesture evidence. Capture rows 1-6, 9, 11-14 on macOS where existing AppKit UI maps naturally.

Final macOS matrix: ~12 rows × 2 appearances = 24 macOS captures.

### Web shim disposition: D1 (keep) — ADOPT

Keep `Voyager.build_route` as the permanent static-site entry point. Update stale comments in `samples/initiative-cross-platform-ui-voyager/app.cr` that still describe iOS as a caller (R12). NO rename, NO migration.

### macOS HostBootstrap cleanup: defer — ADOPT

Pure cleanup; not required for the 14-row contract. Bumped to a future phase.

## Risk additions (R8-R12)

- **R8** — Rerender path wipes live FormState. *Reinforces rejecting 1A.*
- **R9** — Scenario-driven captures prove renderable end states, NOT interaction. **Brief must explicitly distinguish hand-test evidence from capture evidence.**
- **R10** — Swipe-revealed transient gesture UI may not have a durable-state representation. Capture tooling may need sample-local flags for rows 7/8.
- **R11** — `TodoEditorController#save` returns `Pop` on blank title. If a renderer ignored disabled state, blank Save would Pop without saving. Defensible defensive fallback, but conflicts with "disabled prevents action" UX. Document as a known interaction guarantee, but the new disabled-toggle in 8D.3a closes the visible part of the contract.
- **R12** — `app.cr` comments still describe iOS as a shim caller. D1 includes comment cleanup.

## Closing-gate proposals

### 8D.3a minimum bar
- Save enables/disables live while typing.
- No public UI framework API changes.
- Crystal spec or native smoke for the local wiring if feasible.
- Owner hand-test recipe PASSES on iOS simulator with real touch input.
- `Voyager.build_route` disposition recorded as D1 + stale comments updated.
- B2 web architecture position note committed.
- Validation ladder passes (`crystal spec`, dispatcher integration spec).

### 8D.3b minimum bar
- Deterministic capture driver exists (NOT XCUITest tap-driven).
- 28 iOS screenshots produced.
- macOS capture scope explicit; swipe-only rows documented iOS-only.
- Artifact mapping table (row → scenario id → appearance → path).
- Capture command rerunnable from a clean checkout.

## Architect verdict

Co-plan is clean. **Critical re-framing of the 14-row contract: split into "interaction proof (hand-test)" + "visual state proof (scenario captures)".** That separation is what makes 8D.3 achievable without weakening the Phase 6.10 tap-synthesis wall.

Moving to brief drafting. Two briefs: `brief-8d.3a.md` (architecture + hand-test) and `brief-8d.3b.md` (capture matrix). 8D.3b depends on 8D.3a passing.

— Architect (Claude Opus 4.7)
