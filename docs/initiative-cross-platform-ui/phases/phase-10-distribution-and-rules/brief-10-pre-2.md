# Phase 10-pre.2 — Implementer Brief (v2)

**Phase:** 10-pre.2 — API freeze + rename protocol.
**Branch:** `phase-10-pre-2` cut from `phase-10` (where 10-pre.1 already merged).
**Status:** v2 — incorporates Codex antagonist findings on v1 (4 HIGH + 4 MEDIUM + 2 LOW + 10 pre-rulings).
**Predecessor:** 10-pre.1 closed PASS at tag `phase-10-pre.1-pass-2026-05-25`. The catalog's `coverage_today` is now honest; this sub-phase closes its `crystal_api_shape` accuracy.

---

## What changed from v1

- **Scope corrected:** 64 Class D rows (not 40). The freshness audit's pre-correction estimate was wrong.
- **Pre-rulings:** all 10 known divergences pre-decided (all code-wins) with exact target `crystal_api_shape` text.
- **Code-wins rubric tightened:** shipped public Crystal API wins unless (a) the existing name makes two Apple intents indistinguishable OR (b) it names the wrong HIG role.
- **Backlog language fixed:** "36 tracked / 34 active." New gaps surface in close handoff ONLY, not as backlog entries.
- **Decision-log format:** full sections for corrected rows + compact appendix table for confirmed-correct.
- **`coverage_today` cleanup allowed:** when `crystal_api_shape` proof exposes a drift in `coverage_today` (e.g. row says `missing` but source exists), the implementer corrects both AND records the cleanup in the close handoff.
- **Voyager verification expanded:** any catalog-wins rename requires `rg` consumer sweep, spec touch on renamed APIs, and the canonical Voyager build command.
- **Lint extended:** fail on `# pending 10-pre.2 rename audit` markers; assert every Class D row has a non-empty `crystal_api_shape`.
- **Discovery step added:** enumerate all 64 Class D rows + pending-marker locations BEFORE editing.

---

## 1. What you are doing

10-pre.1 corrected `coverage_today` (what's shipped vs missing). 10-pre.2 corrects `crystal_api_shape` (what the Crystal API actually looks like). After 10-pre.2 closes, a consumer (human or AI agent) reading any Class D catalog row can copy-paste the `crystal_api_shape` example and have it parse against today's Crystal source.

**Protocol — "Code wins" rubric:**

Shipped public Crystal API wins by default. Catalog `crystal_api_shape` rewrites to match Crystal source. Renames of Crystal source code happen ONLY when one of these is true:

1. The existing Crystal name makes two distinct Apple intents indistinguishable (e.g. one Crystal class spans both `UI::Menu` and `UI::MenuButton` SwiftUI concepts ambiguously).
2. The existing Crystal name labels the wrong HIG role (e.g. a class named `Sheet` that actually implements `Popover` semantics).

Both criteria are objective and rare. Expected catalog-wins count for 10-pre.2: **0** (all 10 known divergences pre-ruled code-wins). If the implementer encounters a candidate during the 54 unverified Class D rows, surface to architect for ruling — do not improvise.

You ARE rewriting catalog `crystal_api_shape` text and possibly extending the lint script. You are NOT writing widget implementations, LSP rules, or new intents. You are NOT renaming Crystal source unless an explicit catalog-wins ruling lands.

## 2. Read first

Working directory: `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`.

1. `docs/initiative-cross-platform-ui/phases/phase-10-distribution-and-rules/scoping-10.md` v3 §"10-pre.2".
2. `docs/initiative-cross-platform-ui/handoff/phase-10-pre-1-close.md` — what 10-pre.1 shipped + the 8 rows that carry `# pending 10-pre.2 rename audit` markers.
3. `docs/initiative-cross-platform-ui/handoff/phase-10-pre-1-architect-reflection.md` — lessons from 10-pre.1 that 10-pre.2 inherits.
4. `docs/initiative-cross-platform-ui/architecture/intent-catalog.md` — your target document (92 entries; 64 Class D).
5. `docs/initiative-cross-platform-ui/handoff/phase-10-pre-catalog-freshness-2026-05-25.md` (with 2026-05-25 correction) — original audit's Class D spot-check section (12 rows; 9 known wrong).
6. `scripts/lint_intent_catalog.cr` — extend for pending-marker + Class-D-shape-presence checks.
7. `CLAUDE.md` — Class D definition ("native modifier intents — direct Crystal-to-modifier translation").

For each Class D row, read the named source file. Specifically the Phase 8 view files: `src/ui/views/*.cr`, plus type definitions in `src/ui/*.cr` (enums like `PickerStyle`).

## 3. Constraints (Hard Rules)

- **Forward commits only** on branch `phase-10-pre-2` (cut: `git checkout -b phase-10-pre-2 phase-10`).
- **Crystal source edits ONLY for catalog-wins renames.** Expected catalog-wins count: 0. If the implementer thinks a row needs catalog-wins, escalate to architect — do not improvise.
- **64 Class D rows is the work plan.** Run discovery first to confirm the count.
- **No new backlog items.** Backlog frozen at 36 tracked / 34 active. New gaps surface in close handoff text only.
- **No new intents.** The 92 catalog entries stay 92.
- **`coverage_today` corrections allowed** when `crystal_api_shape` proof reveals drift — these are cleanups, not scope creep. Document in close handoff under "coverage_today cleanups from 10-pre.1 audit gap."
- **Per-row decision log** in compact format: full sections for corrected/catalog-wins/new-design-needed rows; appendix table for confirmed-correct rows.
- **Audit-scope discipline** carries from 10-pre.1: verify every Crystal API reference against actual source (views + renderers + native bridges).
- Per `[[codex-as-architect-antagonist]]`: Codex content review on corrected catalog before close.
- Per `[[complete-phase-arc-before-review]]`: no owner involvement.
- Per `[[plan-what-to-understand-not-just-what-to-build]]`: if a row needs a design decision (e.g. should we add a `present(from:)` method?), surface to architect — do not implement.

## 4. Deliverables

### Deliverable 0 — Discovery (RUN FIRST)

Before editing anything:

1. Enumerate every Class D row: `grep -n "^- \*\*class:\*\* D" docs/initiative-cross-platform-ui/architecture/intent-catalog.md | wc -l`. Expected: 64.
2. List every `# pending 10-pre.2 rename audit` marker: `grep -n "pending 10-pre.2 rename audit" docs/initiative-cross-platform-ui/architecture/intent-catalog.md`. Expected: 8 rows.
3. Record both lists in the close handoff's discovery section.
4. Sanity-check the work estimate against the 64-row count.

### Deliverable 1 — Lint extension

Edit `scripts/lint_intent_catalog.cr` to add:

**Rule A:** Reject any row carrying `# pending 10-pre.2 rename audit`. After 10-pre.2 closes, no row should have this marker.

**Rule B:** For every Class D row, assert `crystal_api_shape` is non-empty AND does not contain placeholder strings (`TBD`, `...`, `<TODO>`). Empty or placeholder `crystal_api_shape` on Class D rows is a violation.

**Rule C (optional, if time permits):** parse the `crystal_api_shape` value for any `UI::ClassName` reference and grep `src/ui/views/` to verify the class exists. (This is high-value but may be costly to implement — feel free to defer to a future phase if it doubles the scope.)

Run lint BEFORE making catalog edits. The pending-marker check will fail on the 8 marked rows — that's your work list.

### Deliverable 2 — Catalog `crystal_api_shape` corrections

**Pre-ruled corrections (all code-wins; apply exactly as specified):**

| Intent | New `crystal_api_shape` | Notes |
|---|---|---|
| `:list` | `list = UI::ListView.flat(items: rows)` OR `UI::ListView.new(sections: [...])` | Class is `UI::ListView`, not `UI::List`; no `<<` |
| `:sheet` | `sheet = UI::Sheet.new(content); presenter = UI::SheetPresenter.new(sheet); presenter.present` | No `present(from:)`; `SheetPresenter#present` takes no args |
| `:presentation_detents` | `sheet.detents = [:medium, :large]` | Property is `detents`, not `presentation_detents`. Note: also correct `coverage_today` if it says `missing` — `Sheet#detents` exists at `src/ui/views/sheet.cr:31`. |
| `:presentation_drag_indicator` | `sheet.shows_drag_indicator = true` | Bool, not three-valued symbol. Loss of `automatic` is design gap — note in close handoff. Note: also correct `coverage_today` if `missing`. |
| `:toolbar` | `toolbar = UI::Toolbar.new("Title"); toolbar.add_item(id: :save, label: "Save", icon: "checkmark") { ... }` | Init takes `@title`; items via `add_item` block API |
| `:toolbar_item` | `toolbar.add_item(id:, label:, icon:) { ... }` | Public author API; no direct record construction with `on_tap` |
| `:menu_picker_style` | `picker.style = UI::PickerStyle::Menu` | Property is `style`; value is enum `PickerStyle::Menu`, not symbol |
| `:context_menu` | `menu = UI::ContextMenu.new; menu.add_item(id:, label:) { ... }` | No `view.context_menu=` setter; items via `add_item` block API |
| `:menu` | `menu = UI::MenuButton.new("More"); menu.add_item(...)` | Use existing `UI::MenuButton`; do NOT rename to `UI::Menu` in this slice (would be catalog-wins; future phase scope) |
| `:list_row_separator` | `list.shows_separators = false` | List-level boolean; per-row separator stays unimplemented (note in close handoff) |

For each, ALSO remove the `# pending 10-pre.2 rename audit` marker.

**Remaining 54 Class D rows (unverified):**

For each, verify `crystal_api_shape` matches source:

1. Read the Crystal source file the row references.
2. If `crystal_api_shape` is verifiable → confirm with appendix entry; no edit.
3. If `crystal_api_shape` has any divergence → apply code-wins fix: rewrite to match source.
4. If a divergence triggers catalog-wins criteria (rare; the rubric is in §3) → escalate to architect.
5. If a row has no `crystal_api_shape` value (pre-Class-D-extension Phase 9 leftover) — add one based on source.

### Deliverable 3 — `coverage_today` cleanups (NEW scope per Codex MED-4)

When verifying `crystal_api_shape`, if the source-reading reveals that `coverage_today` is also wrong (e.g. claims `missing` but `Sheet#detents` exists), correct BOTH fields atomically and add the row to a "coverage_today cleanups from 10-pre.1 audit gap" section in the close handoff.

Known candidates from Codex's MED-4:
- `:presentation_detents` — likely `partial` or `shipped`, not `missing` (Sheet#detents exists).
- `:presentation_drag_indicator` — likely `partial` (shows_drag_indicator exists as Bool; missing `automatic` state).

### Deliverable 4 — Catalog-wins renames (expected 0)

If the architect rules any row catalog-wins after escalation:

1. Rename Crystal source file/class/method/property.
2. **Verification commands (Codex MED-2):**
   - `rg "<old_name>"` across the repo to find all consumers.
   - Update Voyager (`samples/initiative-cross-platform-ui-voyager/`).
   - Update specs (`spec/`).
   - Build verification: `crystal build samples/initiative-cross-platform-ui-voyager/src/main.cr` (or the project's canonical Voyager build command — check `Makefile` / `samples/.../README.md`).
   - Run any focused spec that touches the renamed API.
3. The rename + all consumer updates ship in ONE atomic commit.
4. Migration note in `docs/initiative-cross-platform-ui/handoff/phase-10-pre-2-renames.md`.

### Deliverable 5 — Decision log

Write `docs/initiative-cross-platform-ui/handoff/phase-10-pre-2-decision-log.md`:

**Format:**

For corrected rows AND catalog-wins rows AND new-design-needed rows — full section per row:

```
### `:intent_identifier`

- **Catalog crystal_api_shape (was):** `<old value>`
- **Actual Crystal API:** `<grep result>` (cite file:line)
- **New crystal_api_shape:** `<new value>`
- **Decision:** code-wins-rewrite / catalog-wins-rename / new-design-needed
- **Rationale:** [1-2 sentences]
- **Coverage cleanup:** none / coverage_today changed from "missing" → "partial (...)"  [only if applicable]
```

For confirmed-correct rows — compact appendix table:

```
| Intent | crystal_api_shape (unchanged) | Verified against |
|---|---|---|
| :foo | `foo.bar = baz` | `src/ui/views/foo.cr:42` |
| ... | ... | ... |
```

### Deliverable 6 — Close handoff

Write `docs/initiative-cross-platform-ui/handoff/phase-10-pre-2-close.md`:

- Headline: # corrected rows, # confirmed-correct, # catalog-wins (likely 0), # coverage_today cleanups, # new gaps surfaced.
- Decision distribution.
- Lint output before/after.
- `coverage_today` cleanups from 10-pre.1 audit gap (which rows + before/after).
- New gaps surfaced (rows that need Phase 10B work but aren't already in backlog).
- Cross-document consistency check.
- Codex content review verdict.

## 5. Workflow

1. `git checkout -b phase-10-pre-2 phase-10`. Verify.
2. Run Deliverable 0 (discovery). Document counts.
3. Apply Deliverable 1 (lint extension). Run lint — expect failures on the 8 pending-marker rows.
4. Apply Deliverable 2 corrections for the 10 pre-ruled rows. Run lint after each batch.
5. Sweep remaining 54 Class D rows. Apply code-wins fixes; escalate any catalog-wins candidate.
6. Apply Deliverable 3 (coverage_today cleanups) as you encounter them.
7. If any catalog-wins ruling lands, apply Deliverable 4.
8. Write Deliverable 5 decision log.
9. Run `crystal run scripts/lint_intent_catalog.cr` — must exit 0 with new rules.
10. Write Deliverable 6 close handoff.
11. Incremental commits per ~10-15 rows OR per deliverable.
12. Standard footer `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`.

## 6. Acceptance gate

- ✅ Every Class D row's `crystal_api_shape` either verified against source OR rewritten with verification.
- ✅ Zero `# pending 10-pre.2 rename audit` markers remain.
- ✅ Per-row decision log shipped (Deliverable 5).
- ✅ `crystal run scripts/lint_intent_catalog.cr` exits 0 with new pending-marker + Class-D-shape-presence rules.
- ✅ If any catalog-wins renames: verification commands all pass; Voyager builds.
- ✅ Codex content review APPROVE.

## 7. Out of scope

- Widget implementation (10B).
- New intents.
- New backlog items (new gaps go to close handoff text only).
- LSP rules (10A.0).
- Spec reorganization (10C.0).
- Owner involvement.
- Class A/B/C `crystal_api_shape` (Class A is the routing case + has its own contract format; Class B/C don't carry `crystal_api_shape`).

## 8. What success looks like

After 10-pre.2 closes, the intent catalog's `crystal_api_shape` is verified against source for every Class D row. The catalog stops being a wishlist for the API surface and becomes an accurate quick-reference: a consumer can copy-paste any `crystal_api_shape` value into Crystal code and have it parse. Combined with 10-pre.1's `coverage_today` honesty, the catalog is now a true source of truth for both (a) what intents are realized and (b) how to invoke them in Crystal today. 10B widget implementation can proceed with confidence.

— Architect (Claude Opus 4.7), 10-pre.2 brief v2 (post-Codex)
