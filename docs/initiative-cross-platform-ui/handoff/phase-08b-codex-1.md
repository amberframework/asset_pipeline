# Phase 8B iter 1 — Codex Antagonist Review Trail

**Iteration:** 1 (Items 1 + 3 — UI::App + UI::ActionResult)
**Final verdict:** APPROVE (after 5 revision rounds)
**Final commit:** `740ad609`

## Round 1 — REVISE

**Findings:**

1. iOS class-init gap workaround was claimed in the header comment but `MyApp.bootstrap!` did not exist. The `@@screens` class-var hash was a default-initialised class var (same shape that the iOS class-init gap silently skips).
2. Implicit `FooController -> FooScreen` derivation was untested — both registrations in the spec passed `screen_class:` explicitly.
3. The `design_tokens do ... end` macro had no spec exercising the override path.

## Round 2 — REVISE

**Findings:**

1. The `@@_bootstrap_registrations` proc list (added to address round 1 finding #1) was just as vulnerable to the iOS gap — the proc-append `<<` was itself a class-load side effect.
2. The new `design_tokens` spec asserted only that the result was a `Tokens` instance, which would pass even if the block was ignored. Needed an observable sentinel.

## Round 3 — REVISE

**Findings:**

1. The macro-emitted `_bootstrap_screen_*` methods (round 2 fix) survive the iOS gap, but `bootstrap!` still wrote into `@@screens`, whose hash was a class-var default initialiser the gap can skip. The spec cleared an already-initialised hash; it didn't simulate the actual nil-strand state.

## Round 4 — REVISE

**Findings (High):**

1. `initial_route_id` and `app_design_tokens` were still implemented as `class_getter ... = <default>` — same gap shape that round 3 fixed for `@@screens` only.

**Findings (Medium):**

2. `bootstrap_simulate_ios_gap!` was on the public `UI::App` surface despite being a spec-only helper.

## Round 5 — REVISE

**Findings:**

1. The `_strand_screens_registry_for_specs!` helper (renamed in round 4) was still on the production `UI::App` class. Underscore prefix + `:nodoc:` does not remove it from the callable API surface.

## Round 6 — APPROVE

**Findings:** None.

- `_strand_screens_registry_for_specs!` is now in the spec file via a `class UI::App` reopening — production class has no destructive registry helper.
- `UI::App` has method-based `initial_route_id`, lazy `screens` accessor, screen registration via macros that emit `_bootstrap_screen_*` methods, lookup with `UnknownRouteError`, `design_tokens` override support, and subclass `bootstrap!` regeneration via `macro inherited { macro finished { ... } }`.
- `UI::ActionResult` ships all 5 subtypes (Navigate / Pop / Rerender / ReplaceRoot / RenderInline) with expected payload surfaces.

## Architectural notes

The single most-important pattern learned: **on iOS, class-var default-value initialisers (`class_getter x : T = <expr>`) can be silently skipped**. Phase 8B Item 1 enforced this by:

- Method bodies for default values (`def self.x : T; <expr>; end`) — compile-time emitted, gap-safe.
- Nilable class-var caches with lazy method accessors (`@@x : T? = nil; def self.x : T; @@x ||= compute; end`).
- `bootstrap!` re-assigns a fresh `@@screens` hash before invoking each `_bootstrap_screen_*` method, recovering from a stranded-nil state.

This pattern propagates to iter 2 (UI::Controller class-vars) and iter 4 (UI::ActionDispatcher state).

## Commit chronology

```
b42357a7  [Phase 8B iter 1] Initial UI::App + UI::ActionResult
57702ff2  [follow-up 1] Bootstrap! + implicit derivation + design_tokens specs
ca60687d  [follow-up 2] Method-emitted _bootstrap_screen_* + macro inherited
1373ad76  [follow-up 3] Nilable @@screens + iOS gap simulation
03da8cbf  [follow-up 4] Method-based initial_route_id + app_design_tokens
740ad609  [follow-up 5] Move strand helper to spec file
```

— Codex Antagonist Reviewer (final round APPROVE)
