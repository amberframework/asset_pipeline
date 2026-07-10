# Phase 8B iter 4 — Codex Antagonist Review Trail

**Iteration:** 4 (Item 6 — UI::ActionDispatcher)
**Final verdict:** APPROVE (after 2 revision rounds)
**Final commit:** `3c1eaf12`

## Round 1 — REVISE

**Findings (High):**

1. `translate_result` mounted the new screen AFTER calling
   `coord.push/pop/replace_root/republish`. But `NavigationCoordinator#notify`
   is synchronous, so the renderer's `on_change` subscriber rebuilt the view
   tree while `UI::FormState.current` still pointed at the PRIOR mount. Then
   `mount_screen` swapped to the new FormState — making every just-wired
   on_change callback immediately stale (token mismatch).

**Findings (Medium):**

2. `mount_screen(route_id : Symbol)` ignored its parameter and read from
   `navigation.current.params` instead. Fragile post-fix #1, since the
   new ordering needs to mount BEFORE coord.push (when coord.current is
   still the prior route).

## Round 2 — REVISE

**Findings (Medium):**

1. The Pop ordering spec was a false-positive. `TodosController` has
   `before_action :require_signed_in`; the test pushed `:todos` then
   dispatched `:back` without setting the session. The before_action
   redirected to `:sign_in`, so the test passed by coincidence —
   Navigate ALSO ends at `:sign_in`. Missing assertion: depth.

**Non-blocking note:**

- Reentrant `on_change` subscribers (e.g. analytics that dispatch
  another action from inside their callback) can invalidate
  route/FormState alignment for later subscribers in the same notify.

## Round 3 — APPROVE

**Findings:** None.

Both Pop test fix (Tuple action_ref + session-seed + depth assertion +
route_id during-notify assertion) and translate_result invariant
(mount-before-publish) are correctly landed. Reentrancy caveat
documented in the production code's translate_result header.

## Architectural notes

The invariant the dispatcher enforces:

```
For every coord-mutating action result (Navigate / Pop / Rerender /
ReplaceRoot):

  1. Compute the route the NEW mount represents.
  2. Allocate a fresh FormState (mount_screen → bumps token, seeds
     from route.params, syncs UI::FormState.current).
  3. Call the coord mutation (which synchronously notifies subscribers).
  4. Renderer's on_change subscriber rebuilds the view tree with
     UI::FormState.current = the new mount, so wire-time callback
     capture matches.
```

This closes Codex finding #3 on the original brief end-to-end: a
TextField mounted on screen A wires its on_change against the screen-A
FormState's token; after navigation to B, that token is stale and the
captured callback is a full no-op (including the user handler).

## Commit chronology

```
04dab871  [Phase 8B iter 4] Initial UI::ActionDispatcher
6b7031df  [follow-up 1] Mount-before-publish ordering + dual mount_screen overloads
3c1eaf12  [follow-up 2] Fix Pop spec false-positive + document reentrancy
```

— Codex Antagonist Reviewer (final round APPROVE)
