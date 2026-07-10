# Phase 8B iter 5 — Codex Antagonist Review Trail

**Iteration:** 5 (Item 7 — macOS spike + closing-gate read-back proof)
**Final verdict:** APPROVE_WITH_NOTES (after 2 revision rounds)
**Final commit:** `0ca90d4d`

## Round 1 — REVISE

**Findings:**

1. **Blocking:** `findings-macos-todos-with-name.png` had alpha-only background. OCR could read "Welcome, seth@example.com" but the image viewer rendered it as black-on-transparent. The brief requires the screenshot to VISIBLY contain the email — "needs special compositing" doesn't count.
2. **Note:** `PHASE8B_AUTOFILL_EMAIL` is acceptable proof for `FormState#update -> controller -> session -> next screen` (the wrap_text_handler calls the SAME `update` method). It is NOT proof of the native typing bridge wiring itself, which bypasses AppKit's `register_string` path. Handoff should phrase the proof narrowly.

## Round 2 — APPROVE_WITH_NOTES

**Findings:** None blocking.

- Both PNGs now have opaque white matte (`magick -alpha remove -alpha off`). ImageMagick confirms `channels=gray`, `opaque=True`. "Welcome, seth@example.com" is readable in any image viewer.

**Non-blocking note (addressed in follow-up commit):** Stale ICC profile (RGB profile on grayscale PNG) caused ImageMagick iCCP warnings. Stripped via `magick +profile icc`.

## Architectural notes

The macOS spike validates the Phase 8B native flow end-to-end:

1. `dispatcher.current_form_state.update("email", "seth@example.com")` simulates what `UI::FormStateRendererHook.wrap_text_handler` does at user-typing time (the wrapper calls the same `update` method).
2. `dispatcher.dispatch(:submit)` invokes the full controller resolution path: `app.registration_for(:sign_in)` → `SignInController.new` → `before_actions` → `dispatch_action(:submit, ctx)` → `submit(ctx)` returns `navigate_to(:todos)`.
3. `translate_result(Navigate)` calls `mount_screen(next_route)` FIRST (bumps token + swaps `UI::FormState.current`), then `coord.push(next_route)`.
4. `coord.push` synchronously fires `on_change`, our subscriber rebuilds the view for `:todos`.
5. `TodosScreen.build(ctx)` reads `ctx.session["user_email"]`, renders `Label.new("Welcome, seth@example.com")`.
6. Screenshot captures the visible text — closing-gate proof.

What's NOT proven by this iteration:
- The native typing bridge from AppKit's NSTextField → SwiftKit `register_string` callback → wrapped on_change handler. That path is exercised by `UI::FormStateRendererHook` specs (iter 3) but not by an interactive macOS click-trace.

## Commit chronology

```
c94bf3c2  [Phase 8B iter 5] Initial spike + screenshots (alpha-only background)
7dae08a1  [follow-up 1] Composite screenshots onto opaque white matte
0ca90d4d  [follow-up 2] Strip stale ICC profile
```

— Codex Antagonist Reviewer (final round APPROVE_WITH_NOTES)
