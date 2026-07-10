# Phase 8A — Codex review, iter 4 (Item 2: UI::Form web POST semantics)

**Commit reviewed:** 7ec4bcb1 (initial), fc8e53ce (remediation).
**Item:** 2 — UI::Form extension for web POST: action/method/csrf_token/children + auto-promotion + CSRF injection.
**Date:** 2026-05-24.

## Verdict

**REVISE** (then APPROVE after fix).

## Codex transcript (verbatim, abbreviated)

> Verdict: REVISE
>
> Finding: auto-promotion does not implement "exactly one button in the entire form tree." It only checks direct flat children via `view.children.select(UI::Button)` in `web_renderer.cr:1228`. That misses a lone button nested in `VStack/HStack/etc.`, so it stays `type="button"`, and it also ignores section-field buttons rendered through `web_renderer.cr:1200`, so a form with one flat default button plus another section button still auto-promotes the flat one. That violates the brief's "entire form tree" rule and leaves multi-button safety underspecified.
>
> Other review points look sound:
> - CSRF precedence is constructor first, then render context, with nil/empty omitted cleanly.
> - The promotion mechanism itself is mutation-free: identity-tagged `@auto_submit_button`, `same?` check, and `ensure` reset.
> - Existing section-only, nil-action web rendering is preserved by extraction; native AppKit/UIKit/Android visits remain section-only and unchanged.
> - `UI::Form.new` no-args still compiles; keyword-only does not break prior no-arg callers.
> - I saw no action/csrf leakage into native visit methods.
>
> Verification run: `crystal spec spec/ui/renderers/web_renderer_spec.cr` passed: 107 examples, 0 failures.

## Remediation (commit fc8e53ce)

Single follow-up commit replacing the flat select with a tree walk that descends into sections + stack/scroll containers. Nested UI::Form instances are explicitly excluded (each form runs its own auto-promotion lifecycle).

Three new specs cover the corner cases:
- lone Button nested in a VStack auto-promotes
- one flat + one section-field button: no promotion
- one flat + one VStack-nested button: no promotion

Spec count: 1576/4/0 (was 1573/4/0; +3 new). Spike still builds against the lifted helpers.

## Tokens used

~105k.
