# Phase 8E — Docs + Skill + Tutorial (SCOPING DRAFT)

**Date opened:** 2026-05-25
**Status:** SCOPING — architect → Codex co-planner → brief.
**Branch:** to be cut as `phase-08e-docs-skill-tutorial`.
**Predecessors:** 8A, 8B, 8C, 8D.1, 8D.2, 8D.3a, 8D.3b — all PASS/PASS_WITH_NOTES.

---

## The problem being solved

Phase 8 shipped `UI::App` + `UI::Controller` + `UI::ActionDispatcher` + `UI::FormState` + `UI::AmberIntegration.routes_for` + `UI::Screen` + screen-context shape (`Native` / `Web`). It works in three places: Voyager (macOS + iOS native), the Phase 8C Amber spike (web full server). The architectural reframings (view-local affordance vs app/domain state; capture-vs-interaction proof separation; D1 web shim disposition) are buried in handoff reflections.

**Without 8E, a new contributor or user-of-the-library has no entry point into the new API.** The existing `build-ui`, `css-styling`, `component-api`, `cross-platform-components` skills predate Phase 8 entirely. CLAUDE.md doesn't mention `UI::App` / `UI::Controller`. There's no tutorial walking through a fresh app on the new API.

8E closes that gap.

## Three deliverables

### A. New `UI::App` skill
A new top-level skill at `.claude/skills/ui-app/SKILL.md` covering:
- The four-piece architecture: `UI::App` declares routes; `UI::Controller` handles actions; `UI::ActionDispatcher` routes them; `UI::FormState` carries form values.
- The two screen-context shapes: `UI::ScreenContext::Native` (form_state + session + flash + design_tokens + navigation + action_params) and `UI::ScreenContext::Web` (Amber-driven).
- Action ref convention: `Symbol` = current route's controller; `Tuple({Controller, :action})` = explicit cross-controller.
- `UI::ActionResult` subtypes: `Navigate`, `Pop`, `Rerender`, `ReplaceRoot`, `RenderInline`.
- The view-local-affordance-vs-app/domain-state rule (from Phase 8D.3a co-plan).
- The capture-vs-interaction-proof separation (from 8D.3 co-plan).
- The web shim D1 disposition for static-site web targets.
- Wiring to Amber via `UI::AmberIntegration.routes_for(YourApp)`.
- Wiring to native hosts via `dispatcher = UI::ActionDispatcher.new(...)` + `dispatcher.mount_screen(coord.current)`.

### B. CLAUDE.md updates
Add `## UI::App architecture` section. List `UI::App`, `UI::Controller`, `UI::ActionDispatcher`, `UI::FormState`, `UI::Screen`, `UI::ScreenContext` as core entry points. Add the four-piece architecture diagram. Add a Quick Reference row for the new `ui-app` skill. Mention Phase 8 closed in late 2026-05 with all sub-phase tags listed.

### C. Owner-facing tutorial
A new `docs/initiative-cross-platform-ui/tutorial-ui-app.md` walking through:
1. Defining a `UI::App` subclass with `initial_route` + `screen` macros.
2. Authoring `UI::Screen` subclasses with `build(ctx)`.
3. Authoring `UI::Controller` subclasses with action methods.
4. Returning `UI::ActionResult` from actions.
5. Wiring to a macOS host via `UI::ActionDispatcher` (lifted directly from Voyager's `host.cr`).
6. Wiring to an iOS host via `Voyager::HostBootstrap.build` (lifted from `bridge.cr`).
7. Wiring to Amber via `UI::AmberIntegration.routes_for`.
8. The 4 architectural rules: view-local affordance vs app/domain state; mount-before-publish; renderer-provider-install ordering; capture-vs-interaction proof.

Length target: ~5-10 pages. Code samples ARE allowed to be elided/abridged from Voyager.

### D. (Optional) `apple-platform-guide` skill update
The existing `apple-platform-guide` skill predates Phase 8. If 8E has bandwidth, add a "Building with UI::App" section linking to the new `ui-app` skill + tutorial. Architect lean: defer to a follow-up if 8E is otherwise scoped large.

## Out of scope for 8E

- API changes (8E is docs only).
- New code samples beyond what already exists in Voyager.
- Capture/screenshot work (8D.3b shipped 56 PNGs; reuse them in the tutorial).
- Migrating other skills (build-ui, css-styling, etc.) to mention `UI::App` — they cover the View layer, which is unchanged.
- Reflecting Phase 8 in `docs/initiative-cross-platform-ui/MASTER_PLAN.md` — that's standard bookkeeping but no architectural content.

## Sub-phase decision

Single phase. Three docs, all interrelated, all derive from the same Phase 8 architecture. Splitting would be artificial.

## Open questions for Codex

1. **Skill location.** `ui-app` as a sibling of `build-ui` is the obvious place. Should the skill be named differently (e.g. `mvc-architecture`, `screens-controllers-dispatchers`)? Architect lean: `ui-app` mirrors the public API entry point.
2. **Tutorial code-sample policy.** Lift from Voyager verbatim with line numbers, OR write fresh "minimal hello-world" examples? Architect lean: lift from Voyager for the realistic case; supplement with a 1-page minimal example for the on-ramp.
3. **CLAUDE.md scope.** Just add the new section, OR also audit the existing sections for staleness (e.g. the Voyager web is now "static-site mode + Amber via spike," not "the Voyager web target")? Architect lean: surgical add only — full audit is a separate task.
4. **`apple-platform-guide` update.** Bundle into 8E, OR defer to a follow-up?
5. **Tutorial as a `.md` doc vs a runnable example app.** Doc is sufficient (Voyager IS the runnable example). Architect lean: doc only.
6. **Architectural rules section in the skill.** How prescriptive should the rules be? Tone: "use this pattern; here's why; here's the predecessor doc that explored the trade-off." Architect lean: 1 paragraph per rule + link to the predecessor reflection / co-plan.
7. **Anything I'm not seeing.**

## Risk register

- **R1** — Docs go stale fast. *Mitigation:* link to source files with line numbers (Voyager + framework code) so readers can verify the docs against the live code. Avoid duplicating code that lives elsewhere.
- **R2** — Tutorial over-explains and becomes unreadable. *Mitigation:* 5-10 page target; cut anything not pulling its weight.
- **R3** — Skill SKILL.md format must match the existing skills (front-matter + sections). *Mitigation:* implementer reads `.claude/skills/build-ui/SKILL.md` first and matches the shape.
- **R4** — Phase 8 architectural reframings (view-local vs domain; capture-vs-interaction; D1 shim) need to land coherently. *Mitigation:* each rule gets a 1-paragraph statement + link to predecessor doc. Don't re-derive.
- **R5** — Web-target position note from 8D.3a is already at `docs/initiative-cross-platform-ui/architecture/web-target-position.md`. *Mitigation:* tutorial + skill link to it; do not duplicate.

## Hard rules

- Forward commits only on `phase-08e-docs-skill-tutorial`.
- NO code changes outside `.claude/skills/`, `CLAUDE.md`, `docs/initiative-cross-platform-ui/`.
- NO new framework APIs.
- Existing skills are not re-titled or moved.
- Codex per-iteration review.
- Standard Claude co-author footer.

---

**Next steps:**
1. Codex co-plan.
2. Brief.
3. Codex antagonist.
4. Dispatch (no owner checkpoint per `[[complete-phase-arc-before-review]]`).
5. After 8E closes: Phase 8 collective review handoff to owner.

— Architect (Claude Opus 4.7)
