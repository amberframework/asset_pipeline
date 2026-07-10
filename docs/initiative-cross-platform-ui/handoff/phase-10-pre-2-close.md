# Phase 10-pre.2 — Close Handoff

**Date:** 2026-05-25
**Branch:** `phase-10-pre-2` (cut from `phase-10`).
**Implementer:** Claude Opus 4.7
**Brief:** `phases/phase-10-distribution-and-rules/brief-10-pre-2.md` (v2, post-Codex).

## Headline

**6 deliverables shipped. 23 Class D `crystal_api_shape` rows rewritten to match shipped Crystal source (all code-wins). 2 atomic `coverage_today` cleanups (`:presentation_detents`, `:presentation_drag_indicator` — both upgraded `missing` → `partial` after SwiftKit facade audit). Zero catalog-wins renames. Lint extended with Rule A (pending-marker reject) + Rule B (Class D shape placeholder reject); final lint exits 0 on 92 entries.**

After 10-pre.2 closes, every Class D row in the intent catalog satisfies one of: (a) `crystal_api_shape` is verified against cited shipped Crystal source, or (b) `crystal_api_shape` is an honest forward-looking proposal for a missing surface (no source to fabricate against). The catalog stops being a wishlist and becomes a true copy-pasteable reference for today's Crystal API surface.

## Discovery counts (Deliverable 0)

Before editing:

```
$ grep -c "^- \*\*class:\*\* D" docs/initiative-cross-platform-ui/architecture/intent-catalog.md
64

$ grep -c "pending 10-pre.2 rename audit" docs/initiative-cross-platform-ui/architecture/intent-catalog.md
8
```

- **64 Class D rows** — matches brief §1 expected count.
- **8 pending-marker rows** — matches the 10-pre.1 close handoff inventory.
  - Markers were attached to `coverage_today` (not `crystal_api_shape`) on: `:list`, `:list_row_separator`, `:sheet`, `:toolbar`, `:toolbar_item`, `:menu_picker_style`, `:menu`, `:context_menu`.

## Per-deliverable evidence

### Deliverable 0 — Discovery

Documented above. Both counts matched the brief; no scope surprises.

### Deliverable 1 — Lint extension (`scripts/lint_intent_catalog.cr`)

Added two rules:

- **Rule A** — Reject any field carrying `# pending 10-pre.2 rename audit`. After this slice closes, no row should retain the marker.
- **Rule B** — Reject Class D rows whose `crystal_api_shape` is a placeholder token (`TBD`, `...`, `<TODO>`). (Empty / sentinel values were already rejected by the Phase 9 rules.)

Rule C (parse + grep `UI::ClassName` against `src/ui/views/`) was deferred to a future phase — it would have ~doubled this slice's tool-time and is independently valuable as a static-analysis step.

**Lint output BEFORE catalog edits:**

```
$ crystal run scripts/lint_intent_catalog.cr
FAIL
Validated 92 entries; found 8 violation(s):
  - [:list @ line 470] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
  - [:list_row_separator @ line 487] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
  - [:sheet @ line 640] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
  - [:toolbar @ line 793] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
  - [:toolbar_item @ line 810] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
  - [:menu_picker_style @ line 1031] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
  - [:menu @ line 1167] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
  - [:context_menu @ line 1218] field coverage_today still carries `# pending 10-pre.2 rename audit` marker; resolve and remove
```

**Lint output AFTER all corrections:**

```
$ crystal run scripts/lint_intent_catalog.cr
PASS
Validated 92 catalog entries against the schema in brief-9.md §3.
```

**Lint violations: 8 → 0.**

### Deliverable 2 — Catalog `crystal_api_shape` corrections

23 rows rewritten (all code-wins). The 10 pre-ruled rows shipped exactly as the brief's Deliverable 2 table specified; the additional 13 came from the sweep:

| Pre-ruled (10) | Sweep (13) |
|---|---|
| `:list` | `:popover` |
| `:list_row_separator` | `:alert` |
| `:sheet` | `:confirmation_dialog` |
| `:presentation_detents` | `:navigation_stack` |
| `:presentation_drag_indicator` | `:navigation_split_view` |
| `:toolbar` | `:navigation_link` |
| `:toolbar_item` | `:segmented_picker_style` |
| `:menu_picker_style` | `:wheel_picker_style` |
| `:menu` | `:inline_picker_style` |
| `:context_menu` | `:palette_picker_style` |
| | `:toolbar_item_group` |
| | `:toolbar_spacer` |
| | `:tap_gesture` |

Per-row rationale + before/after snippets are in `phase-10-pre-2-decision-log.md`.

### Deliverable 3 — `coverage_today` cleanups (Codex MED-4)

Two rows where source-reading exposed `coverage_today` drift:

| Intent | coverage_today (was) | coverage_today (after) |
|---|---|---|
| `:presentation_detents` | `missing` | `partial (Sheet#detents at sheet.cr:31; SwiftKit setDetents at swiftkit_overrides.cr:464-466; web/android stubs)` |
| `:presentation_drag_indicator` | `missing` | `partial (Sheet#shows_drag_indicator at sheet.cr:30; SwiftKit setShowsDragIndicator at swiftkit_overrides.cr:468-469; web at web_renderer.cr:1367; android at android_renderer.cr:1857)` |

Both rows preserve audit history with a `# was: missing — Phase 10-pre.2 audit ...` suffix.

**Why missed by 10-pre.1:** iOS native binding lives in the SwiftKit facade (`src/ui/native/swiftkit_overrides.cr`), which was not in the original audit-scope grep. The 10-pre.1 close handoff codified the future grep scope as `src/ui/views/ + src/ui/renderers/ + src/ui/native/ + src/ui/`; this slice confirms that `src/ui/native/swiftkit_overrides.cr` falls under the `src/ui/native/` rule. **Update the methodology in the runbook for future audits:** `swiftkit_overrides.cr` is the populator boundary between Crystal property mutations and SwiftUI `@Published` state — always check it when verifying any iOS / macOS view-property-driven behavior.

### Deliverable 4 — Catalog-wins renames

**0 renames applied** (brief expected 0). The only close-call:

- `:menu` (catalog: `UI::Menu`; source: `UI::MenuButton`). Brief pre-ruled this code-wins for 10-pre.2 with a note that the `UI::Menu` rename remains a viable future-phase candidate. Not catalog-wins THIS slice.

No row's existing Crystal name (a) made two distinct Apple intents indistinguishable OR (b) labeled the wrong HIG role.

No Voyager build verification was needed because no Crystal source was edited.

### Deliverable 5 — Decision log

Shipped at `docs/initiative-cross-platform-ui/handoff/phase-10-pre-2-decision-log.md`:

- 23 per-row full sections for code-wins-rewrites (includes the 2 coverage-cleanup rows).
- 41-row appendix table for confirmed-correct rows.
- 0 catalog-wins entries; 0 new-design-needed entries.

### Deliverable 6 — This document.

## Coverage_today cleanups from 10-pre.1 audit gap

| Row | Before | After |
|---|---|---|
| `:presentation_detents` | `missing` | `partial (...sheet.cr:31, swiftkit_overrides.cr:464-466...)` |
| `:presentation_drag_indicator` | `missing` | `partial (...sheet.cr:30, swiftkit_overrides.cr:468-469, web_renderer.cr:1367, android_renderer.cr:1857...)` |

Both rows changed `coverage_today` AND `crystal_api_shape` atomically in the same commit (`e22f3003`).

## Stray 10-pre.1 carry-over cleanups (incidental)

Two `UI::List` references in `coverage_today` messages were updated to `UI::ListView` while sweeping the List family:

- `:refreshable` — `(no \`UI::List.refreshable=\` property)` → `(no \`UI::ListView.refreshable=\` property)`
- `:searchable` — `(no \`UI::List.searchable=\` integration)` → `(no \`UI::ListView.searchable=\` integration)`

These are not coverage classification changes (both stay `missing`); only the cited class name was corrected to match shipped source.

## New gaps surfaced (close handoff only — NOT new backlog items)

Surfaced for architect awareness; per brief §3 no new backlog rows are added in this slice.

1. **`:list_row_separator` per-row override missing.** Today only the list-level `ListView#shows_separators : Bool` ships. SwiftUI's `.listRowSeparator(_:edges:)` is per-row. Candidate Phase 10B backlog item if per-row toggling is intent-critical.

2. **`:presentation_drag_indicator` `:automatic` state missing.** SwiftUI's `.presentationDragIndicator(.automatic)` is tri-valued (`visible` / `hidden` / `automatic`). Today's `Sheet#shows_drag_indicator : Bool` is two-valued. The `:automatic` state would let the OS decide (e.g. hide on non-resizable presentations); not modeled today. Candidate Phase 10B backlog item.

3. **`:toolbar` group/spacer composition.** `Toolbar` today only ships flat `add_item`. Real toolbars need `add_group(...)` (for related controls), `add_spacer(:flexible)` (for right-alignment), and placement semantics. The catalog rows `:toolbar_item_group`, `:toolbar_spacer`, `:toolbar_item_placement` all reference these. Candidate Phase 10B backlog cluster.

4. **`UI::PickerStyle::Palette` enum value missing.** Already tracked by B-012; no new item needed. Surfaced here as confirmation that the audit re-checked.

5. **No standalone `UI::UIMenu` / `UI::UIAction` classes.** Today's `MenuButton.MenuItem` is the analog but is scoped to MenuButton. UIKit's `UIMenu`/`UIAction` are first-class composable types; the asset_pipeline could model them as standalone classes that compose into MenuButton/ContextMenu instead of duplicating the record. Candidate Phase 10B design decision.

6. **No `UI::Color` design-token API.** `:toolbar_background` references `UI::Color.brand_primary` but no such class exists — the actual design-token surface is `UI::DesignTokens::Tokens.default.color_light.brand_primary`. Either the catalog shape should be updated when a `UI::Color` shorthand lands, OR the existing tokens API gets folded into a public `UI::Color` namespace. Candidate Phase 10B design decision.

7. **Forward-looking proposals on `UI::View` base class** (`:transition`, `:matched_geometry_effect`, `:animation`, `:phase_animator`, `:keyframe_animator`, `:sensory_feedback`, `:on_long_press`, `:on_drag`, `:on_magnify`, `:on_rotate`, `:draggable`, `:drop_destination`). All shapes assume these are eventually `UI::View`-base properties. The architect should decide which actually belong on the base vs as opt-in mixins or per-view extensions. Captured here so 10B planning has the full unimplemented surface in one place.

None of these are blocking 10-pre.2; all surface for Phase 10B planning.

## Cross-document consistency check

- **`intent-routing-candidates.md`** — no changes touch its Class A surface.
- **`widget-intent-mapping.md`** — `swipe_action_row.cr` / `UI::InlineActionRow` gaps from 10-pre.1 still stand; this slice did not regress them.
- **`translation-matrix.md`** — Same; no changes needed.
- **`intent-backlog.md`** — No new backlog rows per brief §3. Existing rows (B-001, B-002, B-012, B-026, B-036, B-037) untouched. The 36-tracked / 34-active count from 10-pre.1 carries forward unchanged.
- **`tier-matrix.md`** — Out of scope this slice (10-pre.1 close handoff already flagged for future freshness pass).

## Catalog changes summary

- **23 rows** `crystal_api_shape` updated (10 pre-ruled + 13 sweep).
- **2 rows** `coverage_today` upgraded `missing` → `partial` (atomic with shape updates).
- **2 rows** `coverage_today` had stray `UI::List` → `UI::ListView` carry-over cleanup.
- **8 rows** had `# pending 10-pre.2 rename audit` markers removed.
- **0 Crystal source edits.** No catalog-wins ruling landed.
- **Lint:** 8 violations → 0 violations.

## Branch state

```
$ git log --oneline phase-10..HEAD
61a20383 [Phase 10-pre.2] Sweep missing Class D rows — normalize 3 picker_style + 2 toolbar shapes
2a0434aa [Phase 10-pre.2] Sweep partial/shipped Class D rows — 8 corrections
e22f3003 [Phase 10-pre.2] Apply 10 pre-ruled crystal_api_shape corrections
5ddea126 [Phase 10-pre.2] Lint: pending-marker (Rule A) + Class D shape-placeholder (Rule B)
```

**Branch:** `phase-10-pre-2`
**Base:** `phase-10`
**Commits:** 4 incremental + decision log + this close handoff (6 deliverable artifacts; 5-6 commits depending on how decision log + close are batched).
**Lint:** PASS (0 violations, was 8).

## Acceptance gate (final)

- ✅ Every Class D row's `crystal_api_shape` either verified against source OR rewritten with verification.
- ✅ Zero `# pending 10-pre.2 rename audit` markers remain in `architecture/intent-catalog.md` (confirmed by Rule A passing on the catalog). Note: historical phase/handoff briefs written before 10-pre.2 closed still contain the literal marker phrase in narrative prose; those documents are historical record and are out of Rule A's scope (which lints the catalog only).
- ✅ Per-row decision log shipped (Deliverable 5).
- ✅ `crystal run scripts/lint_intent_catalog.cr` exits 0 with new pending-marker + Class-D-shape-placeholder rules.
- ✅ No catalog-wins renames; no Voyager build verification needed.
- ⏳ Codex content review — pending (this close handoff is the artifact to review).

## Iter-2 remediation (post-Codex BLOCK review)

After iter 1 closed at HEAD `63f8d804`, Codex returned **BLOCK** with 3 HIGH + 4 MEDIUM + 2 LOW findings. Iter 2 applied them all on the same branch:

- **HIGH-1 — Rule B tightened.** The lint now rejects EMBEDDED placeholder substrings in Class D `crystal_api_shape`, not just values that exactly equal a placeholder. Banned (case-insensitive substring): `TBD`, `XXX`, `FIXME`, `<TODO>`. Banned (literal substring): `[...]`, `API TBD`. Banned (regex): 4+ consecutive dots. The tightened rule surfaced 7 violations across 4 rows that iter 1 had passed: `:toolbar_item_group`, `:toolbar_spacer`, `:wheel_picker_style`, `:inline_picker_style`. All 4 rewritten honestly.

- **HIGH-2 — `:toolbar_item_group` / `:toolbar_spacer` no longer reference fictional `add_group` / `add_spacer` methods on `UI::Toolbar`.** Both `crystal_api_shape` fields now read `# Not yet implemented — UI::Toolbar only ships flat add_item ...`. The missing trailing backtick on the `:toolbar_spacer` shape was also fixed.

- **HIGH-3 — `:palette_picker_style` reclassified as forward-looking gap.** Iter 1 wrote `picker.style = UI::PickerStyle::Palette` as if it were a fact; verification against `src/ui/view.cr:66-71` confirmed `Palette` is NOT in the `PickerStyle` enum (only `Wheel`, `Segmented`, `Menu`, `Inline`). Shape rewritten to `# Not yet implemented — UI::PickerStyle enum does not define Palette. Adding the value is tracked under B-012.`

- **MED-1 — Pre-ruling deviations documented.** Codex flagged that the catalog uses `id: "save"` (String) where the brief's pre-ruling table used `id: :save` (Symbol), and uses `label:` without `id:` on `MenuButton.add_item` / `ContextMenu.add_item` where the brief suggested `id:, label:`. Source verification (`src/ui/views/toolbar.cr:23,27` — `id : String`; `src/ui/views/menu_button.cr:48,52` — no `id:`; `src/ui/views/context_menu.cr:28,38` — no `id:`) shows the brief's pre-rulings were wrong. Catalog stays source-accurate; the deviations are recorded in the iter-2 addendum of the decision log.

- **MED-2 — `:presentation_drag_indicator` SwiftKit citation corrected.** Iter 1 claimed iOS/macOS were fully wired. Verification against `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift` showed only `presentationDetents` is applied (line 91); there is NO `.presentationDragIndicator(_:)` call. The bool stored at `swiftkit_overrides.cr:468-469` does not reach SwiftUI. Catalog `coverage_today` rewritten to honestly call out "stored-not-applied" for iOS/macOS. `:presentation_detents` cite verified accurate (`setDetents` IS applied at `SheetFacade.swift:91`).

- **MED-3 — Appendix sweep.** 4+ rows whose appendix entry was over-generous have had their catalog `crystal_api_shape` rewritten to honestly mark them as not-yet-implemented (since the referenced classes/methods literally do not exist): `:full_screen_cover`, `:inspector`, `:interactive_dismiss_disabled`, `:compact_date_picker_style`, `:graphical_date_picker_style`, `:wheel_date_picker_style`, `:ui_menu`, `:ui_action`, `:transferable`, `:animation`, `:ui_impact_feedback_generator`, `:ui_notification_feedback_generator`, `:ui_selection_feedback_generator`. The appendix description "honest forward-looking proposal" was accurate; the catalog SHAPE field was the misleading one. Catalog shapes now match the appendix framing.

- **MED-4 — Backlog B-007 (`:presentation_detents`) updated.** Description now reflects that iOS/iPadOS SwiftKit wiring DOES apply detents to SwiftUI (`SheetFacade.swift:91`), Android stub echoes values without producing detented behavior, macOS+web emit nothing. Companion drag-indicator stored-not-applied gap also called out.

- **LOW-1 — "zero markers" claim made precise.** The acceptance gate bullet now scopes the claim to `architecture/intent-catalog.md`; historical phase/handoff briefs are explicitly out of Rule A's scope.

- **LOW-2 — Lint verified.** `crystal run scripts/lint_intent_catalog.cr` exits 0 after all iter-2 corrections.

**Iter-2 lint sequence:**

```
$ crystal run scripts/lint_intent_catalog.cr   # after Rule B tightening, before catalog edits
FAIL
Validated 92 entries; found 7 violation(s):
  - [:toolbar_item_group @ line 827] ...embedded placeholder "TBD"...
  - [:toolbar_item_group @ line 827] ...embedded placeholder "[...]"...
  - [:toolbar_item_group @ line 827] ...embedded placeholder "API TBD"...
  - [:toolbar_spacer @ line 878] ...embedded placeholder "TBD"...
  - [:toolbar_spacer @ line 878] ...embedded placeholder "API TBD"...
  - [:wheel_picker_style @ line 1065] ...embedded placeholder "TBD"...
  - [:inline_picker_style @ line 1099] ...embedded placeholder "TBD"...

$ crystal run scripts/lint_intent_catalog.cr   # after all iter-2 catalog edits
PASS
Validated 92 catalog entries against the schema in brief-9.md §3.
```

**Iter-2 acceptance check:**

- ✅ Lint Rule B catches embedded placeholders (verified with intentional `[...]` injection, then reverted).
- ✅ `:toolbar_item_group`, `:toolbar_spacer` no longer reference fictional APIs.
- ✅ `:palette_picker_style` reclassified.
- ✅ Pre-ruling deviations documented (source-accurate retention).
- ✅ SwiftKit citation for `:presentation_drag_indicator` accurately reflects stored-not-applied state.
- ✅ Appendix-overstated rows have catalog shapes rewritten to match.
- ✅ Backlog B-007 description matches catalog state.
- ✅ Close handoff "zero markers" claim precise.
- ✅ Lint exits 0.

— Phase 10-pre.2 implementer, Claude Opus 4.7, 2026-05-25 (iter 2).
