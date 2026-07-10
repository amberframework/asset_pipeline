# Phase 8B iter 3 — Codex Antagonist Review Trail

**Iteration:** 3 (Item 4 — UI::FormState + renderer integration)
**Final verdict:** APPROVE_WITH_NOTES (after 1 revision round + 1 polish)
**Final commit:** `fb0a11ea` (plus a contradicting-comment cleanup polish)

## Round 1 — REVISE

**Findings:**

1. Stale callbacks were not FULL no-ops. The mount-token guard only protected `captured_fs.update`; the user's `on_change` still ran after a token mismatch, leaking side effects (logging, analytics, validation) from the prior screen into the new one.
2. AppKit SecureField comment falsely claimed "form_state update IS called with the input's current text, so the controller still sees the password." The bridge actually passes `""`.
3. Specs lacked `wrap_secure_handler` coverage + handler-suppression proof. The stale-fire spec hand-rolled a simplified callback instead of exercising the hook.

## Round 2 — APPROVE_WITH_NOTES

**Findings:** None blocking.

- `user_handler.try(&.call)` moved INSIDE the mount-token guard. Stale fire = full no-op.
- AppKit + UIKit SecureField comments now honestly state the bridge passes `""` + recommend plain `UI::TextField` as the Phase 8B workaround.
- 4 new specs: stale-suppress-handler proof (text), wrap_secure_handler live+stale paths, returns-nil-on-no-name path.

**Non-blocking note (addressed in polish commit):** A two-line comment above the renderer hook class vars still claimed "no class-var default initialisers" — contradicting the more detailed comment immediately below that explained why `@@current_mount_token = 0_i64` is acceptable. Deleted the stale comment.

## Architectural notes

The Phase 8B brief's Codex finding #3 is now fully closed:

> "Stale renderer callbacks from prior screens can update next screen's state. Approach: each screen mount generates a fresh UI::FormState AND a fresh mount_token : Int64. When the renderer wires a TextField's on_change, it captures BOTH the FormState reference AND the token. The callback closure compares the captured token against the dispatcher's CURRENT token; if they don't match, the callback is a no-op."

The implementation goes one step further than the brief's literal phrasing: the no-op covers BOTH the FormState write AND the user handler. The brief's "callback is a no-op" was ambiguous on this point; Codex caught it.

## Commit chronology

```
4b96c39d  [Phase 8B iter 3] Initial FormState + renderer hook
fb0a11ea  [follow-up] Move user_handler into guard + honest comments + new specs
            (polish, included this commit: dropped contradicting comment)
```

— Codex Antagonist Reviewer (final round APPROVE_WITH_NOTES, polish applied)
