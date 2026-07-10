# Phase 8E — Docs + Skill + Tutorial (BRIEF v1)

**Date drafted:** 2026-05-25
**Status:** Brief v1 — pending Codex antagonist critique.
**Branch:** `phase-08e-docs-skill-tutorial`.
**Predecessors:** 8A, 8B, 8C, 8D.1, 8D.2, 8D.3a, 8D.3b.
**Planning artifacts:** `scoping-8e.md`, `coplan-8e-codex-1.md`.

---

## 1. Mission

Document the Phase 8 architecture so a new contributor or library user has a clean entry point. Three deliverables:
- `.claude/skills/ui-app/SKILL.md` — operational reference for the four-piece API.
- `docs/initiative-cross-platform-ui/tutorial-ui-app.md` — narrative tutorial.
- `CLAUDE.md` updates — top-level pointer.

NO API changes. Docs only.

## 2. Frozen surfaces

- NO code changes outside `.claude/skills/ui-app/`, `CLAUDE.md`, `docs/initiative-cross-platform-ui/`.
- NO renames of existing skills.
- NO new API surfaces.

## 3. Item-by-item scope

### Item 1 — `.claude/skills/ui-app/SKILL.md` (new file)

Use `.claude/skills/build-ui/SKILL.md` as the format template. Adapt the front-matter shape (name, description, etc.) to match the established skill convention.

**Sections (in order):**

1. **When To Use This Skill** — vs `build-ui` (View composition) / `component-api` (View reference). `ui-app` is for app-level navigation, controller actions, form submission, native host bootstrap, Amber routing.
2. **Core Architecture** — four-piece model + FormState. `UI::App` declares routes; `UI::Screen` builds views; `UI::Controller` handles actions; `UI::ActionDispatcher` executes results. `UI::FormState` carries input values.
3. **Screens** — `build(ctx : UI::ScreenContext) : UI::View`. No domain mutations in `build`; view-local affordance closures ARE allowed.
4. **Controllers And Actions** — `UI::Controller` subclass with action methods. Each returns a `UI::ActionResult`. Reads via `ctx.form_state["field"]` / `ctx.action_params["key"]` / `ctx.session` / `ctx.flash`.
5. **Action References (shipped API).** Views set callback closures that call `App.dispatch(...)` (sample-local helper). The dispatcher accepts `:action_name` (current route's controller) OR `{ControllerClass, :action_name}` (explicit cross-controller). The closure pattern shipped by Voyager:
   ```crystal
   button.on_tap = -> { Voyager.dispatch(:submit) }
   button.on_tap = -> { Voyager.dispatch(:edit_row, {"todo_id" => "5"}) }
   ```
   The older Phase 8 design draft mentioned `Button(action: :submit)`; that syntax was NOT shipped. Document the closure form.
6. **Action Results** — table of `Navigate`, `Pop`, `Rerender`, `ReplaceRoot`, `RenderInline` with what each does.
7. **Native Host Wiring** — prefer `Voyager::HostBootstrap.build` (Voyager-side, but the canonical pattern). The invariant: `App.bootstrap!` → state + coord + session + flash + dispatcher → `dispatcher.mount_screen(coord.current)` → publish/pin the dispatcher in the host's holder (Voyager uses sample-local `Voyager.dispatcher = dispatcher`; there is no generic `UI::App.dispatcher` slot).
8. **Amber Host Wiring** — `UI::AmberIntegration.routes_for(YourApp)` inside `routes :web do ... end`. Amber owns the lifecycle, params, session, flash, CSRF/layouts.
9. **Static-Site Web Target** — link to `docs/initiative-cross-platform-ui/architecture/web-target-position.md`. Static-site IS NOT dispatcher-backed; this is intentional (D1 disposition).
10. **Architectural Rules** — the five rules (see §4 below).
11. **Common Pitfalls** — top 5 misuses + correct pattern. Examples from Phase 8 reflections (mount-before-publish, renderer-before-build, view-local affordances).
12. **Live References** — link list: Voyager `app.cr`, `host_bootstrap.cr`, Amber spike routes, framework `action_dispatcher.cr` + `form_state.cr` + `native_app.cr`, web target position note, Phase 8 reflections.

### Item 2 — `docs/initiative-cross-platform-ui/tutorial-ui-app.md` (new file)

5-10 page narrative tutorial. **Lift from Voyager wherever the realistic case matters; write fresh minimal examples for the on-ramp.**

**Chapters (in order):**

1. **What This Tutorial Builds.** One page. Names the three target paths explicitly (macOS/iOS native via dispatcher; Amber full-server web via `routes_for`; Voyager static-site web via `Voyager.build_route` — D1 permanent).
2. **Minimal App Declaration.** Fresh `TasksApp` example. Then the Voyager `VoyagerApp` real declaration (lift from `samples/initiative-cross-platform-ui-voyager/app.cr:165-171`).
3. **Writing A Screen.** Fresh minimal `TasksScreen#build(ctx)`. Reference (don't paste-all) `Voyager::TodosScreen#build`.
4. **Writing A Controller.** Lift `Voyager::SignInController#submit` from `samples/initiative-cross-platform-ui-voyager/controllers/sign_in_controller.cr` near-verbatim. Shows form_state read, session write, flash write, Rerender on validation failure, ReplaceRoot on success.
5. **Action References From Views.** Fresh examples using the shipped closure pattern: `button.on_tap = -> { App.dispatch(:submit) }` (current route's controller) and `button.on_tap = -> { App.dispatch(:edit_row, {"todo_id" => "5"}) }` (with action_params). Note that the dispatcher also accepts `{Controller, :action}` for explicit cross-controller dispatch. **Do NOT use the `Button(action: :submit)` syntax from the original Phase 8 design draft — that was never shipped; use closures.**
6. **Action Results.** Compact table. Use Voyager examples by reference.
7. **FormState And ScreenContext.** Small snippets. Clarify `ScreenContext::Native` vs `ScreenContext::Web` shape difference. Note: screens should not depend on request/response APIs.
8. **Native Host Wiring.** Lift `Voyager::HostBootstrap.build` verbatim from `host_bootstrap.cr`. Add: "Manual host wiring follows the same order."
9. **iOS / macOS Host Notes.** Fresh prose; tiny snippets. Call out: host pins GC-owned collaborators; renderer-provider install ordering before `screen.build` (iOS fresh-renderer path); mount-before-publish.
10. **Amber Full-Server Wiring.** Fresh example: `routes :web do UI::AmberIntegration.routes_for(YourApp) end`. State what Amber owns.
11. **Static-Site Web Is Different.** Mostly fresh prose linking `web-target-position.md`. Use Voyager: `Voyager.build_route` is permanent static-site infrastructure, NOT a failed migration.
12. **Five Rules To Remember.** Fresh summary list (§4).
13. **Where To Read Next.** Link list: ui-app skill, web-target-position.md, Voyager `app.cr`, Voyager `host_bootstrap.cr`, Amber spike routes, Phase 8 reflections.

**Code-sample policy:** lift Voyager with explicit `(samples/initiative-cross-platform-ui-voyager/controllers/sign_in_controller.cr)` path citation. Line numbers sparingly — they rot (R12). When lifting, copy the structure but feel free to trim comments that don't add tutorial value.

### Item 3 — `CLAUDE.md` updates

Four edits (3a-3d):

**3a.** Add a new subsection AFTER the existing "Cross-Platform UI System" opening (and any existing nearby description) and BEFORE the "Design philosophy: beauty-by-default" section. Implementer reads CLAUDE.md to locate the exact insertion point.

```markdown
### UI::App application architecture

Phase 8 added the app-level architecture for cross-platform screens:

- `UI::App` declares routes via the `screen` macro.
- `UI::Screen` builds views from a `ScreenContext` (shared across web + native).
- `UI::Controller` handles native actions and returns `UI::ActionResult`.
- `UI::ActionDispatcher` routes native action refs and applies navigation/render results.
- `UI::FormState` carries controlled input values across renders.
- `UI::AmberIntegration.routes_for` wires a `UI::App` to a full-server Amber target.

**Target split:**

| Target | Path |
|---|---|
| macOS / iOS native | `UI::ActionDispatcher` |
| Amber full-server web | `UI::AmberIntegration.routes_for` |
| Voyager static-site web | `Voyager.build_route` (sample-local, deliberate; see `docs/initiative-cross-platform-ui/architecture/web-target-position.md`) |

Voyager's static-site web target is intentionally NOT dispatcher-backed. See the web target position note for the rationale.

Full guide: `ui-app` skill + `docs/initiative-cross-platform-ui/tutorial-ui-app.md`.
```

**3b.** Add to the existing **Key Entry Points** bulleted list (after `Components::CSS::Engine::Generator` line or wherever fits the existing alphabetic/topical order):

- `UI::App` — declarative app + route registry
- `UI::Screen` — screen authoring with `build(ctx)`
- `UI::Controller` — native action handler
- `UI::ActionDispatcher` — routes action refs to controllers + applies ActionResult
- `UI::ActionResult` — Navigate / Pop / Rerender / ReplaceRoot / RenderInline
- `UI::FormState` — controlled input state across renders
- `UI::ScreenContext` — Native + Web variants passed to `build(ctx)`
- `UI::AmberIntegration.routes_for(App)` — Amber web integration macro

**3c.** Add to the existing **Quick Reference** table near the bottom of CLAUDE.md a new row:

```markdown
| Building apps — UI::App + Controller + Dispatcher + FormState + Amber integration | `ui-app` |
```

**3d.** Phase 8 close note (1 line, near the new section): "Phase 8 closed the ergonomic MVC-style app API in May 2026 across 8A, 8B, 8C, 8D.1, 8D.2, 8D.3a, and 8D.3b." Implementer verifies predecessor tags exist via `git tag --list "phase-08*"` (the existing tags are well-known: `phase-08a-pass-2026-05-24`, `phase-08d.1-pass-with-notes-2026-05-25`, etc.).

### Item 4 — Codex per-iteration review

Standard pattern. Save to `docs/initiative-cross-platform-ui/handoff/phase-08e-codex-N.md`.

## 4. The five architectural rules (CANONICAL — surfaces in BOTH skill and tutorial)

1. **App/domain state mutations go through controllers + dispatcher.** Todos, user session, settings flags. The controller layer is where domain changes happen.
2. **View-local affordances may use closures.** `save.disabled = title.empty?` on `title_field.on_change` is correct. Don't route this through dispatcher Rerender — that allocates a fresh FormState and loses the in-progress typed value (Phase 8D.3a co-plan).
3. **Mount before publish/render.** The dispatcher's `mount_screen` ALWAYS precedes the coord op (`push` / `pop` / `replace_root` / `republish`) that fires the on_change subscriber. This includes Pop — `translate_result` mounts the target route BEFORE calling `navigation.pop`. The renderer reads `UI::FormState.current` during wire-time; that must be the NEW mount's FormState.
4. **Renderer/provider install before screen build.** `UI::UIKit::Renderer.new` installs the `UI::DesignTokens::Device.install_provider` block; screens query `DeviceMetrics.current` during `build`. Construct-after-build SIGSEGVs (Phase 8D.2 iOS observed). macOS hosts that reuse a long-lived renderer don't surface this; iOS fresh-renderer-per-render paths MUST honor the order.
5. **Capture evidence ≠ interaction evidence.** Screenshots prove visual state at a known scenario. Dispatcher specs + hand-tests prove action behavior. Asking screenshots to prove "the tap worked" is what runs into Phase 6.10's XCUITest tap-synthesis wall.

These rules appear in both the skill (Section §10 "Architectural Rules") and the tutorial (Ch. 12 "Five Rules To Remember").

## 5. Acceptance criteria (closing-gate)

- [ ] `.claude/skills/ui-app/SKILL.md` exists with valid frontmatter (matching `build-ui/SKILL.md` shape) and all 12 sections.
- [ ] `docs/initiative-cross-platform-ui/tutorial-ui-app.md` exists with all 13 chapters.
- [ ] All five architectural rules appear in BOTH the skill and the tutorial.
- [ ] `CLAUDE.md` has: new subsection (3a), Key Entry Points additions (3b), Quick Reference row (3c), Phase 8 close note (3d). Tag names verified.
- [ ] Voyager code lifts are accurate against live files (no broken paths or symbol names). Implementer runs `grep` to confirm.
- [ ] `crystal spec` unchanged: 1723 baseline (no code edits).
- [ ] `crystal tool format --check` passes for any edited Crystal files (there should be none in 8E).
- [ ] `git diff --check` passes.
- [ ] Codex review APPROVE or APPROVE_WITH_NOTES.
- [ ] A reader can answer from the docs alone:
  - Where do I declare routes? (Skill §2 "Core Architecture", Tutorial Ch. 2 "Minimal App Declaration")
  - Where do actions live? (Skill §4 "Controllers And Actions", Tutorial Ch. 4 "Writing A Controller")
  - How do native hosts dispatch? (Skill §7 "Native Host Wiring", Tutorial Ch. 8-9)
  - How does Amber wire in? (Skill §8 "Amber Host Wiring", Tutorial Ch. 10)
  - Why is Voyager web different? (Skill §9 "Static-Site Web Target", Tutorial Ch. 11, `web-target-position.md`)

## 6. Risk register (R1-R12)

R1-R5 from scoping; R6-R12 from Codex co-plan (all adopted):
- **R1** — Docs go stale fast. *Mitigation:* link source files + symbol names; line numbers sparingly.
- **R2** — Tutorial over-explains. *Mitigation:* 5-10 page target.
- **R3** — Skill format must match existing skills. *Mitigation:* implementer reads `build-ui/SKILL.md` first.
- **R4** — Architectural reframings need to land coherently. *Mitigation:* 1 paragraph + predecessor link per rule.
- **R5** — `web-target-position.md` already exists. *Mitigation:* link, don't duplicate.
- **R6** — Original Phase 8 `design.md` partially superseded. *Mitigation:* cite shipped code + reflections; `design.md` is background context, not authoritative.
- **R7** — Tutorial may blur three web meanings (Amber / Voyager static-site / generic web renderer). *Mitigation:* name explicitly every mention.
- **R8** — Skill may become tutorial-like. *Mitigation:* skill is operational reference; tutorial owns narrative teaching.
- **R9** — Host wiring may encode stale manual setup. *Mitigation:* prefer `HostBootstrap.build`; manual is "same sequence."
- **R10** — "All mutations through dispatcher" rule may be over-applied. *Mitigation:* Rule 1 + Rule 2 explicitly separate domain from affordance.
- **R11** — Cross-controller tuple refs misuse risk. *Mitigation:* document as intentional explicit cross-controller dispatch only.
- **R12** — Line numbers rot. *Mitigation:* prefer file + symbol names; line numbers only where they pull weight.

## 7. Implementation order

1. **Skill first.** Author `.claude/skills/ui-app/SKILL.md`. Read `build-ui/SKILL.md` for shape. Author all 12 sections; verify Voyager file references with grep.
2. **Tutorial next.** Author `docs/initiative-cross-platform-ui/tutorial-ui-app.md`. Lift Voyager code samples per Item 2 ch-by-ch.
3. **CLAUDE.md edits.** Verify tag names (`git tag --list "phase-08*"`). Apply 3a / 3b / 3c / 3d in surgical edits.
4. **Cross-check.** All five rules appear in BOTH skill + tutorial. All Voyager lifts work (grep + verify). Predecessor doc links resolve.
5. **Codex review.** Send Codex the brief + a diff summary + the three deliverables. APPROVE / APPROVE_WITH_NOTES gates the close.
6. **Commit.** Single commit ideal: `[Phase 8E iter 1] UI::App skill + tutorial + CLAUDE.md updates`. With co-author footer.

## 8. Validation invocations

- `crystal spec` — unchanged baseline 1723.
- `grep -n "..." samples/initiative-cross-platform-ui-voyager/app.cr` — verify each lifted reference.
- `git tag --list "phase-08*"` — verify Phase 8 tag names before CLAUDE.md edit.
- Codex review: `codex exec -c 'model_reasoning_effort="medium"' "<prompt>" 2>&1 | tee /tmp/codex-iter.log | tail -300`.

## 9. Hard rules

- Forward commits only on `phase-08e-docs-skill-tutorial`.
- NO code changes outside `.claude/skills/ui-app/`, `CLAUDE.md`, `docs/initiative-cross-platform-ui/`.
- NO new API surfaces.
- Existing skills are not re-titled or moved.
- Codex review per iteration.
- Standard Claude co-author footer.

— Architect (Claude Opus 4.7)
