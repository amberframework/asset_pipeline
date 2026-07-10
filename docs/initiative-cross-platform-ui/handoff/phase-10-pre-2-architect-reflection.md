# Phase 10-pre.2 — Architect Reflection

**Sub-phase:** 10-pre.2 — API freeze + Class D `crystal_api_shape` reconciliation.
**Date closed:** 2026-05-25.
**Final HEAD:** `0150abe3`
**Tag:** `phase-10-pre.2-pass-2026-05-25`
**Verdict:** PASS (after iter 2 remediation of Codex BLOCK).

## What shipped

10-pre.2 closed the catalog's `crystal_api_shape` accuracy after 10-pre.1 closed `coverage_today` accuracy. Together they make the intent catalog a true source of truth for the Crystal API surface.

- 64 Class D rows verified or rewritten.
- 8 `# pending 10-pre.2 rename audit` markers cleared.
- 23 + 17 `crystal_api_shape` rewrites (iter 1: 23 source-aligned + iter 2: 17 placeholder/fictional cleanup).
- 2 `coverage_today` cleanups (`:presentation_detents`, `:presentation_drag_indicator`) — both upgraded `missing` → `partial` after `swiftkit_overrides.cr` evidence surfaced. `:presentation_drag_indicator` further corrected in iter 2 to "stored-not-applied" honesty after Codex caught the SwiftKit overstatement.
- 0 catalog-wins escalations. The "code wins by default" rubric held across all 64 rows.
- Lint extended (Rules A + B) — now rejects `# pending 10-pre.2 rename audit` markers, embedded placeholder substrings (`TBD`, `[...]`, `API TBD`, 4+ dot ellipses), and empty Class D `crystal_api_shape`.
- One real shipping bug surfaced: `setShowsDragIndicator` is stored in `swiftkit_overrides.cr` but never applied to SwiftUI in `SheetFacade.swift`. Tracked under B-007.

## Numbers

- 11 commits on `phase-10-pre-2` (iter 1: 5 + iter 2 single atomic + close).
- 5 files touched (lint script + 2 catalog/backlog + 2 handoff docs).
- Codex verdict: BLOCK iter 1 → APPROVE iter 2 (3 HIGH + 4 MEDIUM + 2 LOW addressed).
- Re-audit verdict: APPROVE iter 1 directly (different sample; missed Codex's findings — exactly the parallel-verification value).

## Lessons

### 1. Parallel verification with non-overlapping samples is high-value

10-pre.1 first introduced the pattern. 10-pre.2 proved it again. The re-audit APPROVED iter 1 cleanly because its samples didn't include the rows Codex flagged. Codex's BLOCK caught 3 HIGH-severity issues invisible to the re-audit's sampling:

- `:palette_picker_style` rewritten to a fictional `UI::PickerStyle::Palette` enum value that doesn't exist.
- `:toolbar_item_group` + `:toolbar_spacer` malformed with `API TBD` and missing backticks.
- Lint Rule B too narrow — only rejected exact-match placeholders, not embedded.

Lesson: parallel verification is NOT redundant. Each pass catches what the other's sampling misses. Default to running both for any sub-phase with non-trivial scope.

### 2. The lint rule itself is part of the work product, not just the gate

Iter 1's Rule B passed its own check (a row containing `[...]` slipped through because the rule required exact-match). Iter 2 tightened the rule THEN re-ran lint to surface the rows the iter 1 rule had let through. The lint became MORE strict as a result of an antagonist's review of the lint logic itself.

Lesson: when extending a lint script, the antagonist needs to review the rule semantics as critically as the affected catalog rows. A rule that's too loose is worse than no rule — it gives false confidence.

### 3. "Code wins by default" worked

Of 64 Class D rows, 0 needed catalog-wins escalation. The pre-rulings on 10 rows + the rubric (code-wins unless name makes two Apple intents indistinguishable OR labels wrong HIG role) was sufficient. The implementer correctly identified `:menu` (UI::MenuButton vs catalog's UI::Menu) as a close call but defensible because `UI::MenuButton` is an existing shipped public API.

Lesson: when documenting an existing framework, default to source-accuracy. Catalog text rewrites are cheap; renaming public APIs is expensive and ripples through every consumer.

### 4. Brief pre-rulings can be wrong; source is the arbiter

Codex MED-1 flagged that 10 pre-rulings weren't applied verbatim. The implementer investigated and found 3 of 4 pre-rulings had source-incorrect details (e.g., brief said `id: :save` but actual API uses `id: "save"`). The catalog stayed source-accurate and documented the deviations.

Lesson: an antagonist's "verbatim" critique is itself something to verify against source. Sometimes the brief is wrong; the source is the final word.

### 5. SwiftKit `setShowsDragIndicator` shipping bug found by accident

Codex's MED-2 critique of the `:presentation_drag_indicator` SwiftKit cite turned up a real bug: the Crystal property mutation reaches the SwiftKit bridge (`swiftkit_overrides.cr:468`) but the bridge never calls `presentationDragIndicator` in `SheetFacade.swift`. The bool is stored but never applied to SwiftUI.

This is exactly the kind of finding `[[plan-what-to-understand-not-just-what-to-build]]` is for — the catalog correction work surfaced a real implementation gap that documentation alone wouldn't have caught. B-007 backlog item now flags the bug for Phase 10B.

Lesson: documentation correction CAN surface code bugs. When a catalog row claims "shipped" but careful source-reading shows the path is broken, that's a bug, not just doc drift.

## Process notes for the parallel trio (10A.0 / 10C.0 / 10B.0)

- After 10-pre.2's merge to `phase-10`, three sub-phases unlock simultaneously per scoping v3's dependency lanes.
- Each gets its own implementer dispatch + Codex antagonist + verification pattern.
- They're independent: 10A.0 (LSP rules) doesn't touch what 10B.0 (resolver) builds; 10C.0 (spec dirs) is a precondition to 10B's spec coverage but 10B.0 itself ships specs to those dirs.
- Recommendation: dispatch all three implementer briefs together (after each has been through Codex antagonist), let them run in parallel.

## Open items carried forward

- **B-007 with corrected detents description.** SwiftKit `setShowsDragIndicator` shipping bug.
- **Forward-looking gaps (7)**: `:list_row_separator` per-row override, `:presentation_drag_indicator` `:automatic` tri-state, `:toolbar_item_group`/`:toolbar_spacer`/`:toolbar_item_placement` (3 catalog rows), `UI::PickerStyle::Palette` enum addition, `UI::UIMenu`/`UI::UIAction`, `UI::Color` token shorthand, multiple `UI::View`-base modifier proposals (`:transition`, `:matched_geometry_effect`, etc.).
- These stay in close handoff prose; they don't become new backlog items.

## Next

1. ✅ Tag `phase-10-pre.2-pass-2026-05-25`.
2. ✅ Fast-forward merge `phase-10-pre-2` → `phase-10`.
3. ⏭ Dispatch Codex antagonist on 10A.0 + 10C.0 + 10B.0 briefs (parallel).
4. ⏭ Reconcile findings.
5. ⏭ Dispatch all three implementers in parallel.

— Architect (Claude Opus 4.7)
