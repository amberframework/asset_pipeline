# Codex Antagonist on 10-pre.2 Brief v1

**Date:** 2026-05-25
**Codex:** medium reasoning, default model.
**Source log:** `/tmp/codex-brief-10-pre-2.log` (~5052 lines).
**Verdict:** REVISE.

---

## Findings

### HIGH (all adopted)

1. **Class D scope is materially wrong.** v1 said "~40 Class D rows" and "0–3 catalog-wins out of 40"; current catalog has **64 Class D rows**. Affects estimate, decision-log shape, acceptance expectations. v2 fix: replace all "40" with "64".

2. **"Code wins" not operational enough for dispatch.** v1 said catalog wins only when a Crystal name "blocks Apple-vocabulary intent mapping," but then known-divergence section said "For each: code wins" — a contradiction for ambiguous rows like `:list` (UI::List vs UI::ListView), `:presentation_detents` vs `detents`, `:menu` vs `MenuButton`. v2 fix: pre-rule each known row + add objective rubric (shipped Crystal API wins unless name makes two Apple intents indistinguishable OR labels wrong HIG role).

3. **Known-divergence list under-specified.** v1 named 10 divergences but said "rewrite to match Crystal source" without target strings. v2 fix: table with exact replacement `crystal_api_shape` text per row.

4. **Backlog freeze language wrong.** v1 said "36 active items"; 10-pre.1's final state is "36 tracked / 34 active" (B-021 deprecated + B-026 closed). v2 fix: use "36 tracked / 34 active" everywhere; new gaps surface in close handoff only.

### MEDIUM (all adopted)

1. **Decision-log too heavy for 64 rows.** Full section per row is impractical. v2 fix: full sections for corrected/catalog-wins/new-design-needed rows + appendix table for confirmed-correct.

2. **Voyager ripple requirements vague.** "Voyager updates" and "Voyager compiles" too loose. v2 fix: `rg` consumer sweep + spec touch + canonical Voyager build command for any catalog-wins rename.

3. **Lint gate insufficient.** Citation-presence from 10-pre.1 doesn't verify `crystal_api_shape` content. v2 fix: extend lint to reject `# pending 10-pre.2 rename audit` markers AND assert every Class D row has non-empty `crystal_api_shape`. Optional shipped-symbol allowlist deferred.

4. **`coverage_today` interaction unresolved.** `:presentation_detents` and `:presentation_drag_indicator` have actual Crystal API surface (`Sheet#detents`, `Sheet#shows_drag_indicator`) but catalog says `missing`. v1 said coverage is out of scope. v2 fix: ALLOW coverage_today correction when crystal_api_shape proof reveals drift — these are cleanups, recorded in close handoff.

### LOW (all adopted)

1. v2 adds Deliverable 0: discovery step (enumerate Class D rows + pending markers BEFORE editing). 10-pre.2's equivalent of 10-pre.1's "run Deliverable 8 first."

2. Reactivity caveat: if any catalog-wins rename touches source, require focused compile/spec proof.

## Pre-rulings on the 10 known divergences (all code-wins)

Codex provided exact target `crystal_api_shape` text for each. v2 incorporates verbatim:

| Intent | Decision | New crystal_api_shape |
|---|---|---|
| `:list` | code-wins | `UI::ListView.flat(items: rows)` or `UI::ListView.new(sections: [...])` |
| `:sheet` | code-wins | `UI::Sheet.new(content); UI::SheetPresenter.new(sheet); presenter.present` |
| `:presentation_detents` | code-wins | `sheet.detents = [:medium, :large]` (+ coverage_today cleanup) |
| `:presentation_drag_indicator` | code-wins | `sheet.shows_drag_indicator = true` (+ coverage_today cleanup; `automatic` is design gap) |
| `:toolbar` | code-wins | `UI::Toolbar.new("Title"); toolbar.add_item(id:, label:, icon:) { ... }` |
| `:toolbar_item` | code-wins | `toolbar.add_item(id:, label:, icon:) { ... }` (no direct record construction) |
| `:menu_picker_style` | code-wins | `picker.style = UI::PickerStyle::Menu` |
| `:context_menu` | code-wins | `UI::ContextMenu.new; menu.add_item(id:, label:) { ... }` |
| `:menu` | code-wins | Use existing `UI::MenuButton`; do NOT rename to `UI::Menu` in 10-pre.2 |
| `:list_row_separator` | code-wins | `list.shows_separators = false` (per-row remains unimplemented) |

Expected catalog-wins count after this slice: **0**.

## v1 → v2 deltas (architect actions)

1. Scope: 40 → 64 throughout the brief.
2. Pre-ruling table added in Deliverable 2 with exact text for the 10 divergences.
3. Code-wins rubric tightened to objective criteria (indistinguishable Apple intents OR wrong HIG role).
4. Backlog language: "36 tracked / 34 active" everywhere; new gaps to close handoff only.
5. Decision-log format split: full sections for corrected/catalog-wins, appendix table for confirmed-correct.
6. Deliverable 3 added: coverage_today cleanups (with `:presentation_detents` + `:presentation_drag_indicator` as known candidates).
7. Deliverable 0 added: discovery step (enumerate 64 + 8 pending markers before edits).
8. Deliverable 4 expanded with `rg` sweep + spec touch + canonical Voyager build command.
9. Lint extension: pending-marker check + Class-D-shape-presence assertion.

## Architect verdict on v2

Dispatch-ready. v2 incorporates every HIGH/MEDIUM/LOW finding + every pre-ruling verbatim. Implementer has concrete target text for 10 rows, an explicit rubric for the 54 unverified rows, and clear escalation criteria for any catalog-wins candidate.

— Architect (Claude Opus 4.7)
