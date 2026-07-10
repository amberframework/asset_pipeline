# Phase 8E Co-Planning — Codex Response

**Date:** 2026-05-25
**Codex session:** medium reasoning, arg-form prompt, default model.
**Role:** Co-planner.
**Source log:** `/tmp/codex-coplan-8e.log`.

## Adopted decisions

- **Single phase** — confirmed.
- **Skill name** — `ui-app`.
- **Tutorial code policy** — fresh minimal example FIRST (1-page on-ramp), THEN lift Voyager verbatim (line-cited) for the realistic case. Lift `Voyager::HostBootstrap.build` as canonical native wiring.
- **CLAUDE.md scope** — surgical add of new section + Key Entry Points additions + Quick Reference row. Not a full audit.
- **`apple-platform-guide` update** — defer.
- **Tutorial as `.md` only** — confirmed (Voyager IS the runnable example).
- **Architectural rules** — five (not four), per Codex §12. Renderer/provider install ordering is architectural, not incidental.

## Skill structure (Codex §3)

`.claude/skills/ui-app/SKILL.md` sections:
1. When To Use This Skill (vs build-ui / component-api).
2. Core Architecture (four-piece model + FormState).
3. Screens.
4. Controllers And Actions.
5. Action References (`:action` vs `{Controller, :action}` tuple).
6. Native Host Wiring (prefer `HostBootstrap.build`; manual sequence is the invariant).
7. Amber Host Wiring (`UI::AmberIntegration.routes_for(App)`).
8. Static-Site Web Target (link `web-target-position.md`).
9. Architectural Rules (five rules — see below).
10. Common Pitfalls.
11. Live References.

## Tutorial structure (Codex §4)

`docs/initiative-cross-platform-ui/tutorial-ui-app.md` chapters:
1. What This Tutorial Builds.
2. Minimal App Declaration (fresh `TasksApp`; then Voyager lift).
3. Writing A Screen (fresh + Voyager reference).
4. Writing A Controller (lift `SignInController#submit` near-verbatim).
5. Action References From Views (fresh).
6. Action Results (compact table).
7. FormState And ScreenContext (small snippets).
8. Native Host Wiring (lift `Voyager::HostBootstrap.build`).
9. iOS / macOS Host Notes (fresh prose; tiny snippets only).
10. Amber Full-Server Wiring (fresh).
11. Static-Site Web Is Different (link position note).
12. Five Rules To Remember (fresh summary).
13. Where To Read Next (link list).

## Five architectural rules (final list)

1. **App/domain state mutations go through controllers + dispatcher.**
2. **View-local affordances may use closures.** (e.g. `save.disabled = title.empty?` on `title_field.on_change` — not a dispatcher Rerender.)
3. **Mount before publish/render.** (Dispatcher's mount_screen ALWAYS precedes coord.push/replace_root or any subscriber-fire.)
4. **Renderer/provider install before screen build.** (`UI::UIKit::Renderer.new` MUST run before `screen.build(ctx)` on iOS fresh-renderer paths; install_provider side-effect required for `DeviceMetrics.current`.)
5. **Capture evidence ≠ interaction evidence.** (Screenshots prove visual state at known scenario; dispatcher specs + hand-tests prove action behavior.)

## CLAUDE.md edit plan (Codex §5)

Add a new subsection `### UI::App application architecture` after the "Cross-Platform UI System" opener and BEFORE "Design philosophy: beauty-by-default." Contents:

- 1-paragraph four-piece summary.
- Target-split table (3 rows: macOS/iOS native; Amber full-server web; Voyager static-site web).
- Warning paragraph + link to `architecture/web-target-position.md`.

Add to **Key Entry Points** existing list: `UI::App`, `UI::Screen`, `UI::Controller`, `UI::ActionDispatcher`, `UI::ActionResult`, `UI::FormState`, `UI::ScreenContext`, `UI::AmberIntegration.routes_for`.

Add to **Quick Reference** existing table: row pointing to `ui-app` skill.

Phase 8 close note: 1 line "Phase 8 closed the ergonomic MVC-style app API in May 2026 across 8A, 8B, 8C, 8D.1, 8D.2, 8D.3a, and 8D.3b." Implementer verifies all tag names against `git tag --list "phase-08*"` before committing.

## Risk additions (R6-R12, adopted)

- **R6** — Original Phase 8 design.md partially superseded by shipped behavior; cite shipped code + reflections as authoritative.
- **R7** — Tutorial may blur three web meanings (Amber full-server / Voyager static-site / generic web renderer); name explicitly every time.
- **R8** — Skill may become tutorial-like; skill is operational reference, tutorial owns narrative.
- **R9** — Host wiring examples may encode stale manual setup; prefer `HostBootstrap.build`.
- **R10** — "All mutations through dispatcher" rule may be over-applied; explicitly separate app/domain from view-local affordances.
- **R11** — Cross-controller tuple refs can be misused as command bus; document intentional cross-controller dispatch only.
- **R12** — Line numbers rot; link files + symbol names, line numbers sparingly.

## Closing-gate (Codex §7)

- `.claude/skills/ui-app/SKILL.md` exists with valid skill frontmatter.
- `CLAUDE.md` has the new section + Key Entry Points additions + Quick Reference row.
- `docs/initiative-cross-platform-ui/tutorial-ui-app.md` exists, covers native + Amber + static-site without conflating.
- All five architectural rules present in BOTH skill and tutorial.
- Voyager snippets verified against live files (no stale paths).
- No code/API changes outside `.claude/skills/`, `CLAUDE.md`, `docs/`.
- A reviewer can answer from the docs alone: "Where do I declare routes? Where do actions live? How do native hosts dispatch? How does Amber wire in? Why is Voyager web different?"

## Critical insight (Codex §8)

**The original Phase 8 `design.md` is not fully equivalent to shipped behavior.** Docs must privilege shipped API + reflections:
- `UI::AmberIntegration.routes_for` is the Amber story (not the older `render_screen` framing).
- `HostBootstrap.build` is canonical native wiring.
- `Voyager.build_route` is **permanent static-site infrastructure**, NOT a compat shim.
- View-local affordance rule is explicit + load-bearing.
- Renderer/provider install ordering is architectural.
- Capture-vs-interaction evidence separation is a proof contract.

— Architect (Claude Opus 4.7)
