# Architect-as-Dispatcher (Team Lead collapsed into Architect) — 2026-05-20

**Decided by:** Project owner (Seth) at architect checkpoint #2, in response to a harness-capability gap discovered on the first Team Lead dispatch.

## What's changing

For the duration of this initiative's execution, the Architect dispatches the Implementer and Validator directly. The Team Lead role described in `rubric/trust_pair_protocol.md` §"Roles" is collapsed into the Architect.

## Why

The Team Lead's harness, as currently provisioned, does not surface the `Agent` spawn tool. The trust pair protocol's spawn templates (lines 22–74 and 89–148 of `trust_pair_protocol.md`) explicitly require `Agent` + `subagent_type: "general-purpose"`. The first Phase 1 Team Lead dispatch returned BLOCKED for this reason rather than freelancing the Implementer's work (the correct call per the protocol's anti-patterns list).

Rather than rewrite the protocol mid-flight or chase the harness configuration question, Seth chose the fastest unblock: I (Architect) become the dispatch hub.

## What stays the same — the load-bearing invariants

The trust pair's independence guarantees survive intact:

1. The Implementer never sees Validator findings. They receive only `implementation.md`, the universal implementation criteria, the architect summary, and any handoff continuation prompt (on remediation).
2. The Validator never sees Implementer rationalizations beyond the handoff message they're explicitly forwarded. They form expectations from `validation.md` first.
3. A fresh Validator runs each remediation iteration — the previous Validator is not reused.
4. The Architect (now playing dispatch hub) never edits code, runs tests, or runs audits. Dispatch + ledger + reflection only.
5. Gate reports are archived to `handoff/` append-only; failing reports go through the protocol's continuation prompt to the Implementer.
6. After one remediation loop without a PASS, the Architect escalates to the project owner.

## What changes mechanically

- The "Spawning an implementer" and "Spawning a validator" templates in `trust_pair_protocol.md` are now executed by the Architect instead of a Team Lead. The template bodies are unchanged.
- The "Team Lead playbook" in `MASTER_PLAN.md` §"Team lead playbook" remains as a reference for the workflow logic; the Architect performs every step of it.
- The Architect's checkpoint moments listed in `start-architect.md` are unchanged — checkpoints #2 (before dispatch) and #3 (after validator passes, before next branch) still gate progression.

## Future-session note

A future agent reading this should *not* infer that the Team Lead role is dead. If a later session has a harness with `Agent` spawn capability surfaced to a spawned Team Lead, that session may restore the Team Lead layer and treat this handoff as a transient operational accommodation. The protocol's three-layer structure (Architect → Team Lead → trust pair) is the canonical shape; this is a one-rung compression that preserves the load-bearing properties of the bottom rung.
