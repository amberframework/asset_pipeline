# Phase 8B Brief — Codex Antagonist Critique Trail

**Date:** 2026-05-24
**Brief:** `phase-08-ergonomic-mvc-api/brief-8b.md`
**Per directive:** [[codex-as-architect-antagonist]]

## Revision 1 → REVISE

**Findings:**

1. **Item 6 dispatch** — runtime `@@_registered_actions` class-var + macro `@type` introspection mixes runtime mutation with macro lookup. Fights Crystal's type system AND risks the iOS class-init gap.
2. **Item 5 params merge** — `form_state` and `action_params` have different semantics; silent last-write-wins merge is surprising.
3. **Item 4 FormState global** — dispatcher-owned "current FormState" too global. Stale renderer callbacks from prior screens can update next screen's state.
4. **macOS spike gate** — "Sign-in click advances to Todos" can pass without reading form_state. Need read-back proof (e.g. "Welcome, seth@example.com").

## Revision 2 → REVISE-AGAIN

**Per-finding status:**
- 1: CLOSED — explicit per-controller `dispatch_action` override with case statement.
- 2: NOT CLOSED — Item 5 acceptance still said "merges form_state + explicit params" (stale doc reference; the new params/action_params split was in the body).
- 3: NOT CLOSED — Item 6 dispatcher init + mount_screen still called `UI::FormState.new` without the mount-token (stale doc reference; the FormState class itself was correctly updated but the dispatcher invocation wasn't).
- 4: CLOSED — macOS gate now requires visible "Welcome, seth@example.com" read-back proof.

## Revision 3 → **APPROVE-FOR-DISPATCH**

Both stale references fixed. Item 5 acceptance now says params + action_params SEPARATELY; Item 6 dispatcher constructs FormState with mount_token bookkeeping.

## Process notes

- 3 Codex passes, ~180k tokens total.
- The Phase 8B brief authoring was tighter than Phase 8A (4 passes) — pattern is consolidating.
- Key lesson: revision 2's REVISE-AGAIN was entirely about stale doc references — the substance was correct but the brief had two callsites I forgot to update. This is the same class of issue from Phase 6.12C + Phase 8A. A future improvement: when revising a brief, grep for any other occurrence of the term being changed before re-submitting to Codex.

— Architect (Claude Opus 4.7)
