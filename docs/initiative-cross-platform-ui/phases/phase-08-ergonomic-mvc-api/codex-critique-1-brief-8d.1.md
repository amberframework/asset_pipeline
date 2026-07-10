# Phase 8D.1 Brief Critique — Codex Antagonist (Architect-Side, Iter 1)

**Date:** 2026-05-24
**Brief reviewed:** `phase-08-ergonomic-mvc-api/brief-8d.1.md` (v1)
**Per directive:** [[codex-as-architect-antagonist]]
**Codex CLI invocation:** arg-form prompt, medium reasoning, ran via tee for stdout capture (the only invocation pattern that reliably emits formatted output this session)

## Verdict: REVISE

9 findings (2 BLOCKER, 3 HIGH, 4 MEDIUM). All addressed in brief v2.

## Findings

### 1. BLOCKER — `Voyager.build_route` removal breaks iOS + web

Brief Item 1 removes `Voyager.build_route` but `web/static_site.cr` AND `ios/bridge.cr` both call it. iOS is explicitly out of 8D.1 scope; web is too (per Codex co-plan B2 — web stays static). Removing the method breaks compile/link for both targets during the 8D.1 → 8D.2 window.

**Resolution:** Keep `Voyager.build_route(state, coord, route)` as a temporary COMPATIBILITY SHIM in 8D.1. The shim constructs a minimal `UI::ScreenContext::Native` (without dispatcher integration), looks up the screen class via `VoyagerApp.registration_for(route.id).screen_class`, and calls `screen.build(ctx)`. This is the bridge that keeps iOS + web compiling while the macOS host migrates fully. 8D.2 (iOS bridge migration) is the phase that removes the shim.

### 2. BLOCKER — TodoEditor params mechanism ambiguous

Brief says "Receives id via screen subclass instantiation OR via action_params (architect note: brief Item 3 decides the mechanism)." Then later says TodoEditorController reads `ctx.action_params["todo_id"]`. But `ctx.params` and `ctx.action_params` are SEPARATE accessors (Phase 8B Codex finding #2). A mounted editor screen should read route `params`, not the previous action's `action_params`.

**Resolution (codex-recommended pattern):**
- `TodosController#edit_row` reads `ctx.action_params["todo_id"]` (the swipe-row Edit dispatched this with `action_params: {todo_id: "5"}`).
- `TodosController#edit_row` returns `UI::ActionResult::Navigate.new(:todo_editor, params: {todo_id: "5"})`.
- `TodoEditorScreen#build` and `TodoEditorController#save` both read `ctx.params["todo_id"]`.
- Button-local overrides use `action_params` ONLY when needed (e.g. the editor's own "Cancel" button doesn't need params; it dispatches a bare `:cancel`).

### 3. HIGH — Action ref convention (Symbol vs Tuple) ambiguous

When does Voyager use `action: :submit` vs `action: {SignInController, :submit}`?

**Resolution:** Brief now states the rule:
- `Symbol` → action belongs to the CURRENT mounted route's controller. Most callbacks use this form.
- `Tuple({Controller.class, :action})` → explicit cross-controller dispatch ONLY. Used when a widget rendered on screen A needs to dispatch on controller B (rare).
- Voyager's `SwipeActionRow` actions in `TodosScreen`: use `:edit_row` / `:delete_row` (current controller is TodosController; Symbol form).
- Voyager's "Open Settings" link from TodosScreen: `:open_settings` (TodosController#open_settings returns Navigate(:settings)).

### 4. HIGH — `Rerender` operational contract underspecified

What does `UI::ActionResult::Rerender` DO? Re-call current screen's build? Preserve params? Notify coordinator?

**Resolution:** Brief now specifies the Rerender contract:
- Current route ID unchanged.
- Dispatcher rebuilds the current screen by calling `screen.build(ctx)` with current `params`, `session`, `flash`, `form_state`, and latest singleton state.
- Host updates content view without stack mutation.
- Dispatcher does NOT call `coord.push/pop/replace_root`; it directly invokes the render path.

Implementer must verify this matches Phase 8B's `ActionDispatcher#translate_result` implementation; if it doesn't, this is a BUG and gets reported as an escalation per the hard rules.

### 5. HIGH — Pop semantics + stack policy undefined

Brief says "back navigation all functional" but doesn't specify the stack shape.

**Resolution:** Brief now states expected stacks:
- Initial mount: `[sign_in]`
- After Sign In tap (SignInController#submit): `[todos]` — Sign-in should NOT remain in history. **Use `UI::ActionResult::ReplaceRoot.new(:todos)`, NOT `Navigate.new(:todos)`.**
- After "Open Settings" from Todos: `[todos, settings]`
- After "Settings" back tap: `[todos]` (Pop)
- After Add Todo from Todos: `[todos, todo_editor]`
- After swipe-Edit from Todos: `[todos, todo_editor]`
- After editor Save/Cancel: `[todos]` (Pop)
- After Delete row: stays `[todos]` (Rerender, not navigation)

### 6. MEDIUM — Visual regression guard bar too soft

"Small differences acceptable, major regressions not" is unmeasurable.

**Resolution:** Brief now specifies the bar:
- Layout hierarchy preserved (window structure, navigation chrome, primary content area positions).
- All labels present + readable (no clipped text).
- All interactive controls present + visible (no hidden buttons).
- Spacing variance < 4px on primary axes.
- No horizontal scroll on default 880×640 window.
- No route-level missing content (e.g. Todos list still shows 5 seed todos).
- Side-by-side annotated comparison in the implementer report (baseline-vs-postmigration screenshots, deltas documented).

### 7. MEDIUM — Spec scope duplication

Per-screen specs + per-controller specs risk duplication without integration coverage.

**Resolution:** Brief now specifies:
- KEEP focused per-controller unit specs (action dispatch + ActionResult correctness + UnknownAction).
- DROP per-screen specs (the view tree assertions duplicate controller logic).
- ADD 4 dispatcher integration specs in `spec/asset_pipeline/voyager_dispatcher_integration_spec.cr`:
  1. Sign-in submit → ReplaceRoot to :todos
  2. Todos edit_row dispatch → Navigate to :todo_editor with correct params
  3. Settings toggle_filter dispatch → Rerender (verify Voyager::State.hide_completed flips)
  4. Editor cancel → Pop to :todos

### 8. MEDIUM — Item 1 self-contradiction

Brief said "REPLACE the `Voyager.build_route` / `Voyager.route_for_slug` / `Voyager.slug_for_route_id` module methods" then said "Remove `build_route`; keep `route_for_slug` + `slug_for_route_id`."

**Resolution:** Brief v2 says: keep `Voyager.build_route` as a temporary compat shim (per Finding 1); keep `route_for_slug` + `slug_for_route_id` unchanged.

### 9. MEDIUM — macOS host double-build risk

Brief says `coord.on_change` invokes `dispatcher.mount_screen(route.id)`, but `translate_result` already calls mount_screen BEFORE coord.notify. Double-mount risk.

**Resolution:** Brief v2 specifies:
- `coord.on_change` subscriber does NOT call `mount_screen`.
- It renders the DISPATCHER's already-mounted screen + context:
  ```crystal
  coord.on_change do |route|
    # Dispatcher has already mounted the new route's FormState before
    # firing this callback (Phase 8B mount-before-publish invariant).
    # We just render the current screen + setContentView.
    reg = VoyagerApp.registration_for(route.id)
    ctx = dispatcher.current_context  # access the mounted ScreenContext
    view = reg.screen_class.new.build(ctx)
    install_view(view)
  end
  ```
- If `UI::ActionDispatcher` doesn't expose `current_context`, the brief specifies the Implementer must request the architect add it (Phase 8B+ patch). If the Phase 8B spike's host pattern is different, brief should follow the spike. Implementer verifies.

## Open questions for implementer

Same 7 as Codex listed. All seven are addressed via Findings 1-9 resolutions above. Implementer should re-read brief v2 and confirm no remaining ambiguities.

## What's strong about the brief

The brief correctly frames 8D.1 as macOS-first and keeps scope pressure visible. It also respects the no-API-change rule, preserves `Voyager::State` as a singleton, and identifies the key migration from direct coordinator mutation to dispatcher-routed user intent.

The acceptance list is directionally good: it covers registrations, controller unknown-action behavior, no `coord.push` inside screen builds, macOS launch, seed todo visibility, and state propagation through settings. The baseline/post-migration screenshot requirement is also the right instinct; it just needs a sharper pass/fail bar.

— Codex (medium reasoning, arg-form prompt)
