# Phase 9 Brief — Codex Antagonist Findings

**Date:** 2026-05-25
**Brief reviewed:** `brief-9.md` v1.
**Source logs:** `/tmp/codex-brief-9-antagonist.log`, `/tmp/codex-brief-9-revalidate.log`.
**Final verdict:** APPROVE_WITH_NOTES.

## Iteration 1 — REVISE (4 HIGH + 4 MEDIUM + 1 LOW)

- **HIGH 1** — Schema lint regressed (`or` between Apple API fields instead of requiring all three). **Resolved:** all three Apple API fields required with `"—"` sentinel.
- **HIGH 2** — Apple-surface coverage gate weakened to "at least one per family." **Resolved:** every named API entry gets its own catalog row.
- **HIGH 3** — Item 3 freshness reconciliation ownership unclear. **Resolved:** architect drafts translation table; implementer writes freshness reconciliation paragraph.
- **HIGH 4** — Class D missing `crystal_api_shape` + `platforms` fields per scoping v3. **Resolved:** Class D rows now carry 14 fields (12 common + 2 extras).
- **MEDIUM 1** — Lint should reject whitespace, "TBD", wrong dash variants. **Resolved:** explicit INVALID_VALUES list in lint pseudocode.
- **MEDIUM 2** — "No code" conflicts with lint script suggestion. **Resolved:** scripts/ exception added to Hard Rules.
- **MEDIUM 3** — Catalog content needs Codex antagonist pass before implementer. **Resolved:** §8 step 2 mandates content-level Codex review of `intent-catalog.md` before implementer dispatch.
- **MEDIUM 4** — Owner-screen intake window dropped. **Resolved:** explicit deferral in §10 Hard Rules per owner directive 2026-05-25 "work entirely through Phase 9."
- **LOW 1** — "11 fields" vs "12 fields" inconsistency. **Resolved:** "12 common-schema fields; Class D adds 2."

## Iteration 2 — APPROVE_WITH_NOTES

8 of 9 findings ADDRESSED. The remaining MEDIUM 4 was a Codex misread (it cited "window dimension" but the brief addresses it via explicit deferral in §10). Cross-reference added in §8 step 6 to make the deferral findable from the implementation order.

**Dispatch ready.**

— Codex (medium reasoning, arg-form prompt, antagonist mode)
