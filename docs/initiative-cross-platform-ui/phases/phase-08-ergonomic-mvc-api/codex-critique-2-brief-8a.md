# Phase 8A Brief — Codex Antagonist Critique Trail

**Date:** 2026-05-24
**Brief:** `phase-08-ergonomic-mvc-api/brief-8a.md`
**Per directive:** [[codex-as-architect-antagonist]] — Codex critique applied to architect-authored briefs before Implementer dispatch.

## Revision 1 → REVISE

**Findings:**

1. Macro-generated ECR shims not sound — Amber's `render` expands to `Kilt.render("path/template")`; templates must exist at compile time. Macros can't reliably write files for Kilt's compile-time path lookup.
2. Mutating `Form#csrf_token` post-build is acceptable only for fresh per-request view trees. Public API should use explicit `Form.new(action:, csrf_token:)` constructor + renderer-scoped context threading.
3. LAST-button auto-submit is surprising. Require explicit `type: :submit`; allow auto-promotion only when EXACTLY ONE button exists.
4. Item 1 is NOT low-risk (introduces public API). Existing `UI::Form` already has cross-platform section semantics — extend, don't replace. Native-stub work in 8A conflicts with web-only scope.

**Architect action:** Wrote revision 2 addressing all 4 findings.

## Revision 2 → REVISE-AGAIN

**Findings:**

- (1) substantively closed but row 3 of the findings table still said "Macro auto-generates" — stale reference.
- (2) substantively closed.
- (3) NOT closed: Item 5 still said "Promotes the LAST Button"; acceptance expected implicit submit.
- (4) mostly closed but hard rules still said "UI::Form native visit is a stub" — conflicting with "native visit unchanged."

**Architect action:** Wrote revision 3 cleaning all 3 stale references.

## Revision 3 → REVISE-AGAIN

**Findings:**

- One stale contradiction remained: row 2 of findings table + Item 4 heading said `initial:`, while Item 4 body + acceptance required `text:`. API surface inconsistency.

**Architect action:** Wrote revision 4 aligning both to `text:` (matches the existing `text` property name).

## Revision 4 → **APPROVE-FOR-DISPATCH**

> "APPROVE-FOR-DISPATCH"

## Process notes

- 4 Codex iterations, ~180k tokens total across reviews.
- Each iteration caught real issues: from architectural (rev 1) to stale-doc (rev 3-4).
- The 4-pass cycle is consistent with prior briefs (Phase 6.12A took 3 revisions). The architect-side antagonist protocol surfaces the right class of issue at each pass.
- Brief is dispatch-ready. Dispatch waits until Phase 6.12C closes (so the branch state is clean for Phase 8A's branch cut from the feature branch).

— Architect (Claude Opus 4.7)
