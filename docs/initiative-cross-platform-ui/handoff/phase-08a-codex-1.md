# Phase 8A — Codex review, iter 1 (Item 1: lift Amber integration helpers)

**Commit reviewed:** a499472c (HEAD of `phase-08a-amber-render-screen-form` at review time).
**Item:** 1 — Lift `UI::ScreenContext`, `UI::ScreenHelpers`, `UI::AmberConfig`, `UI::Screen`, `UI::RenderContext`, and CLI shim generator into production.
**Date:** 2026-05-24.

## Verdict

**REVISE** — one minor API finding.

## Codex transcript (verbatim, abbreviated)

> Verdict: REVISE
>
> Finding:
> - [Minor/API] `src/ui/renderers/web_renderer.cr:79`: `render_context` is documented and briefed as a keyword API, but the signature allows positional use: `renderer.render(view, UI::RenderContext.empty)` compiles. Since this is new public surface, make it keyword-only with `def render(view : UI::View, *, render_context : UI::RenderContext = UI::RenderContext.empty) : String` before callers couple to the positional second argument.
>
> Checks against the requested review points:
> - API surface is otherwise narrow: `ScreenContext::Web` stores plain hashes/tokens, no Amber controller/context leakage, and session iteration was deliberately excluded.
> - No Amber hard dependency found in the integration. `amber_integration.cr:76` only requires `../ui`; focused specs requiring the integration passed without Amber.
> - CSRF threading uses Amber's `csrf_token` helper path and threads through `UI::RenderContext`; I did not find post-build `Form#csrf_token` mutation.
> - Static shim generator matches finding #3: it writes checked-in `src/views/<controller>/<action>.ecr` files and refuses overwrites, which is the right replacement for macro file generation.
>
> Verification:
> - `crystal spec spec/asset_pipeline/amber_integration_spec.cr spec/asset_pipeline/cli/amber_generator_spec.cr` passed: 13 examples.
> - Spike build passed from sample dir.

## Remediation

Single follow-up commit on the same iter making `render_context` a keyword-only argument by inserting `*,` before it:

```diff
- def render(view : UI::View, render_context : UI::RenderContext = UI::RenderContext.empty) : String
+ def render(view : UI::View, *, render_context : UI::RenderContext = UI::RenderContext.empty) : String
```

13 amber-integration specs still pass after the change.

## Tokens used

~94k.
