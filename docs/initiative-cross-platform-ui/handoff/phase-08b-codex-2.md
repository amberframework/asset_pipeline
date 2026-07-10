# Phase 8B iter 2 — Codex Antagonist Review Trail

**Iteration:** 2 (Items 2 + 5 — UI::Controller + UI::ScreenContext::Native + Session/Flash)
**Final verdict:** APPROVE_WITH_NOTES (after 1 revision round + 1 polish)
**Final commit:** `24f2b314` (plus a small polish addressing the noted weak assertion)

## Round 1 — REVISE

**Findings:**

1. **High:** `before_action` was iOS-gap-vulnerable — the macro emitted a class-body `<<` side effect (`@@_before_actions << proc`) which the iOS class-init gap can silently skip. Applies the lesson from iter 1's hammering on UI::App.
2. **Medium:** `[]?` existed only on concrete `InProcess` impls, not on the abstract `UI::Session` / `UI::Flash` surfaces. `ScreenContext::Native#session` returns the abstract type, so callers couldn't `context.session["k"]?` against it.
3. **Note:** Spec only proved action_params doesn't merge into params; should also prove non-empty form_state values surface in params.

## Round 2 — APPROVE_WITH_NOTES

**Findings:** None blocking.

- `before_action` now emits compile-time `_before_action_<name>_proc` class methods. `_before_actions` is macro-generated via `macro inherited { macro finished { ... } }` and enumerates the methods at access time. No class-var state, no class-body side effects.
- Abstract `def []?` added to both `UI::Session` and `UI::Flash`.
- New spec uses a stubbed FormState with real values; verifies ctx.params returns form values + action_params with same-key name stays separate.

**Polish (not required, applied anyway):** Strengthened the form_state spec assertion from "keys do not contain X" to `keys.sort.should eq(["email", "password"])` — exact-key match catches more regressions.

## Architectural notes

The pattern locked in across iter 1 + 2: **every macro-registered piece of state on a Phase-8B abstract class is iOS-gap-safe.**

- `UI::App#screen` → compile-time `_bootstrap_screen_*` methods enumerated by macro-generated `bootstrap!`.
- `UI::App#initial_route` → method override (no class-var).
- `UI::App#design_tokens` → method override + nilable lazy-cache.
- `UI::Controller#before_action` → compile-time `_before_action_*_proc` methods enumerated by macro-generated `_before_actions`.

The framework consumes no class-var default initialiser side effect for any subclass-registered state.

## Commit chronology

```
76cbde21  [Phase 8B iter 2] Initial UI::Controller + UI::ScreenContext::Native
24f2b314  [follow-up] before_action method emission + abstract []? + spec
            (polish, included in this commit's spec file: stronger assertion
             on form_state vs action_params separation)
```

— Codex Antagonist Reviewer (final round APPROVE_WITH_NOTES, polish applied)
