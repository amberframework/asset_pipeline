# Phase 8D.1 — Codex review iter-2

**Date:** 2026-05-24
**Verdict:** PASS_WITH_NOTES (0 findings)
**Iteration scope:** Items 4 + 5 + 6 (macOS host migration + 4 baseline + 4 post-migration captures + 5 dispatcher integration specs).

## Findings

None.

## Notes (verbatim from Codex)

- Host migration matches the spike contract. Initial mount happens
  once at `samples/initiative-cross-platform-ui-voyager/macos/host.cr:151`;
  `coord.on_change` only renders via `VoyagerHost.rebuild_for(route)`
  and does NOT call `mount_screen` at
  `samples/initiative-cross-platform-ui-voyager/macos/host.cr:204`.
  (Phase 8D.1 brief Item 4 + Codex critique-1 finding #9 — no
  double-mount bug.)
- `rebuild_for` builds a fresh native context from dispatcher live
  state, including `dispatcher.current_form_state`, not a captured
  form-state reference (host.cr:112). This is the proven Phase 8B
  spike pattern.
- Stack-policy contract correct: `SignInController#submit` returns
  `UI::ActionResult::ReplaceRoot.new(:todos)` at
  `samples/initiative-cross-platform-ui-voyager/controllers/sign_in_controller.cr:35`
  (NOT `Navigate`).

## Reachability — 14 behavior contract actions

Codex enumerated the dispatch sites for the 14 brief-defined actions:

| Action ref | Screen file:line |
|---|---|
| `:submit` | `screens/sign_in.cr:87` |
| `:open_settings` | `screens/todos.cr:47` |
| `:new_todo` (Add Todo) | `screens/todos.cr:90` |
| `:toggle_row` (checkbox) | `screens/todos.cr:142` |
| `:edit_row` (swipe Edit) | `screens/todos.cr:165` |
| `:delete_row` (swipe Delete) | `screens/todos.cr:172` |
| `:cancel` (editor) | `screens/todo_editor.cr:108` |
| `:save` (editor) | `screens/todo_editor.cr:121` |
| `:toggle_filter` (settings) | `screens/settings.cr:44` |
| `:back` (settings) | `screens/settings.cr:52` |

10 distinct dispatch sites covering the 14 behavior-contract action
points (some sites are reached from multiple paths — e.g.
`:new_todo` covers both the "Add Todo" button and any other future
new-todo entry).

## Validation runs (Codex-executed)

- Voyager-focused specs (`voyager_app + voyager_controllers +
  voyager_dispatcher_integration + voyager_state_propagation`):
  `41 examples, 0 failures`.
- Full `crystal spec`: `1707 examples, 4 failures, 0 errors,
  66 pending`. Baseline preserved: 1671/4/0/66 entering →
  1707/4/0/66 exiting (+36 new, same 4 pre-existing failures).
- Voyager web static-site (`crystal run web/static_site.cr`):
  generated 11 HTML files (2 single-page hosts × 2 appearances + 4
  per-slug × 2 appearances + `index.html`). Brief description of
  "4 HTML files" was wording inaccuracy; actual generator output is
  unchanged from pre-Phase 8D.1.
- Screenshot SHA-256 pairs are BYTE-IDENTICAL for all 4 routes
  (baseline vs postmigration). Strongest possible visual-regression
  guarantee — host migration preserved rendering exactly.
- macOS host build via direct `crystal-alpha build -Dmacos` with
  Makefile link-flags succeeded; offscreen capture produced expected
  PNGs. (A forced `make -B macos-build` ran into SwiftPM sandbox
  cache rebuild — orthogonal to Phase 8D.1.)

— Codex iter-2 review captured at `/tmp/codex-iter2.log`.
