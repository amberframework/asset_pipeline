# Phase 9 — Apple-Native Intent Catalog + Tier 2 Translation Contract (BRIEF v1)

**Date drafted:** 2026-05-25
**Status:** Brief v1 — pending Codex antagonist critique.
**Branch:** `phase-09-intent-catalog` (to be cut at brief approval).
**Predecessors:** Phase 8 closed (collective review pending).
**Planning artifacts:** `scoping-9.md` (v3 APPROVED by Codex), `coplan-9-codex-1.md`, `codex-antagonist-9-v2.md`.

---

## 1. Mission

Ship the seven Phase 9A documents per scoping-9.md §"9A deliverables." The catalog speaks Apple SwiftUI/UIKit/AppKit vocabulary verbatim, classifies every intent into exactly one of A/B/C/D, enforces the strict row schema via lint, and passes the Apple-surface coverage gate. No code changes — this is a documentation phase.

The catalog is the foundation for Phase 10B's convention rules: rule names will reference intent identifiers from this catalog.

## 2. The four intent classes (canonical from scoping v3)

Every catalog row is exactly one of:

- **Class A — Widget-routing intents.** Framework picks materially different `UI::View` per platform. Gets the four-part contract (capabilities + defaults + override_registry + resolver-deferred). Expected count: 1-3 intents (likely just `:swipe_actions`, possibly `:navigation_split_view`).
- **Class B — Framework-contract intents.** Cross-cutting invariants every widget must honor. Accessibility + reduced-motion + dynamic-type live here. NOT widget-substitution; documentation contracts.
- **Class C — System-integration intents.** Single author-facing API, different native implementation per platform. Share sheets, clipboard, permissions, deep links, print.
- **Class D — Native modifier intents.** SwiftUI modifiers that configure existing widgets without substituting them. Direct Crystal-API-to-SwiftUI-modifier translations. NO four-part contract; just documented 1:1 mapping. Expected count: ~30-50 modifiers across List/Sheet/Toolbar/Form/Navigation/Picker/Date/Menu/Drag-drop/Animation/Haptics/Accessibility/Gestures families.

## 3. The strict schema (HARD lint requirement)

Every catalog row carries ALL of these fields:

**Common schema (12 fields, ALL required):**

```yaml
intent_identifier_crystal: :swipe_actions       # snake_case of primary_apple_name
primary_apple_name: swipeActions                # SwiftUI modifier OR UIKit type OR AppKit type OR HIG page name
class: A                                        # exactly one of A/B/C/D
tier: 2                                         # 1/2/3 per existing tier model in CLAUDE.md:148-160
swiftui_api: swipeActions(edge:allowsFullSwipe:content:)   # REQUIRED — use "—" if no SwiftUI equivalent
uikit_api: UISwipeActionsConfiguration                       # REQUIRED — use "—" if no UIKit equivalent
appkit_api: NSTableView row actions (NSTableViewRowActionStyle)  # REQUIRED — use "—" if no AppKit equivalent
hig_page: gestures.md, accessibility.md
android_equivalent: SwipeToDismissBox (Material 3)
web_equivalent: CSS swipe libraries / inline buttons fallback
coverage_today: shipped (UI::SwipeActionRow at src/ui/views/swipe_action_row.cr)
description: |
  Reveal trailing or leading actions on a list row via swipe.
  HIG requires an alternate non-gesture path per gestures.md:23,31
  and accessibility.md:134.
```

**Class D entries carry TWO ADDITIONAL required fields** (per scoping v3 §"Class D documentation shape"):

```yaml
crystal_api_shape: |
  list = UI::List.new
  list.refreshable = -> { state.reload_todos }
platforms: ios, ipados, android   # platforms where the modifier is natively honored; others must use "—" or document fallback
```

Class A/B/C entries do NOT carry `crystal_api_shape` / `platforms`. They use the 12-field common schema.

**Lint rule (enforced at catalog close):**
- Every row must declare ALL 12 common-schema fields. Class D rows additionally declare `crystal_api_shape` and `platforms` (14 fields total for Class D).
- Fields with no real equivalent on the target platform are declared with the literal sentinel `"—"` (em-dash, U+2014). NOT `-` (hyphen), NOT `--` (double hyphen), NOT a trailing-space variant — the sentinel is exactly `"—"`.
- The lint REJECTS: missing field declarations, empty string values, whitespace-only values, `null`, `nil`, `TBD`, `XXX`, `FIXME`, hyphen/double-hyphen instead of em-dash.
- The lint ACCEPTS: real-value strings and the exact `"—"` sentinel.
- Zero rows fail = phase ready to close.

**Exception process:** intents where NO Apple canonical name exists carry an extra field `apple_canonical_name_exists: false` + a justification + a reviewed snake_case name. Codex antagonist must approve every exception in writing. Default expectation: rare to nonexistent.

## 4. The 7 deliverables

### Item 1 — `docs/initiative-cross-platform-ui/architecture/intent-catalog.md`

The catalog itself. Every intent across Classes A/B/C/D. Schema-compliant rows. Lives at the canonical path.

Structure:
- Brief intro: what this is, the Apple-vocabulary rule, the four classes.
- Section per class: A, B, C, D.
- Within each class section, intents grouped by family (Lists, Sheets, Toolbars, etc.).
- Each intent is a heading + the schema fields rendered as a definition list OR a small table.

**Coverage gate:** every named SwiftUI/UIKit/AppKit family enumerated in `scoping-9.md` §"Apple-surface coverage gate" MUST have catalog rows. The coverage doc (Item 7) tracks this checklist.

### Item 2 — `docs/initiative-cross-platform-ui/architecture/intent-routing-candidates.md`

The small set of Class A intents. Each entry includes:
- The Apple name + Crystal identifier.
- The full capabilities block (predicate-by-predicate; `:swipe_actions` gets all 13 predicates from scoping-9.md §"The Tier 2 translation contract").
- The per-platform defaults table (six keys: ios/ipados/macos/android/web_wide/web_narrow).
- Rationale: why this intent needs routing rather than being a single Tier 2 widget.

Expected size: 1-3 entries. If only `:swipe_actions` qualifies, that's correct.

### Item 3 — `docs/initiative-cross-platform-ui/architecture/translation-matrix.md`

For each Class A intent, the per-platform default translation:
- Which existing `UI::View` class implements the default for each platform.
- If MISSING (no shipped widget), it's a backlog item linked to intent-backlog.md.
- Coverage status: shipped / partial / missing.

Also includes the **view-count freshness reconciliation** (Codex R15): the scoping says 80 view types but the `component-mapping-matrix` skill says 59. Implementer runs `ls src/ui/views/*.cr | wc -l` to settle the actual count, identifies what counts (gate stubs, fallback siblings, presenters, compat files), and writes a one-paragraph reconciliation that gets cross-referenced in `widget-intent-mapping.md` (Item 6).

### Item 4 — `docs/initiative-cross-platform-ui/architecture/tier-2-translation-contract.md`

The contract definition document. Architecturally authoritative.

Content:
- The four parts of the Class A contract: `intent_id`, `capabilities`, `default_table`, `override_registry` (with resolver deferred to Phase 10+).
- The Class D documentation shape (Crystal API emits SwiftUI modifier 1:1; no four-part contract).
- Override registry semantics: app + screen scope, precedence `screen > app > default`.
- Override validation against `capabilities`: missing-capability errors must be loud + name the missing predicate.
- Implementation-shaped pseudocode + acceptance examples (so Phase 10 is implementation, not redesign).
- Cross-references to repo evidence: `src/ui/views/swipe_action_row.cr` (Apple vocab in comments), `src/ui/views/context_menu.cr` (Class D example), `src/ui/views/button.cr` (Class D counterexample showing why most widgets are NOT routing candidates).

### Item 5 — `docs/initiative-cross-platform-ui/architecture/intent-backlog.md`

Class A + Class D intents where no shipped widget exists for some platform default. Buildable backlog for Phase 10+ implementation phases.

Each entry:
- Intent name (Apple identifier).
- Platform with the gap.
- What's missing (e.g., "no `UI::InlineActionRow` view for macOS default of `:swipe_actions`").
- Rough size estimate (S/M/L).
- Priority (P0 if blocks Voyager compliance; P1 if blocks consumer-app realism; P2 if nice-to-have).

### Item 6 — `docs/initiative-cross-platform-ui/architecture/widget-intent-mapping.md`

The full retro-classification of all `src/ui/views/*.cr` files. Table format:

| View file | Primary intent (Apple name) | Class | Tier | Routing candidate? | Reason | Gaps |
|---|---|---|---|---|---|---|

EVERY view file gets a row. Class assignment is exact (no `D-ish`). Reason field is one sentence. Gaps field lists missing per-platform defaults (cross-referenced to intent-backlog.md).

Implementer's responsibility (the bulk single-file audit).

### Item 7 — `docs/initiative-cross-platform-ui/architecture/apple-surface-coverage.md`

Checklist against Codex's enumerated Apple API families (scoping-9.md §"Apple-surface coverage gate"). For each family + each named API in that family, a checkbox + a link to the catalog row that covers it.

Phase 9 close requires every line green OR an explicit deferral with justification.

## 5. Item-by-item scope

### Item 1 (intent-catalog.md) — architect-led writing

Implementer's job: take the architect's catalog draft, verify schema compliance on every row, run the lint check (catalog row schema validation), report any rows that fail. Implementer does NOT invent new intents — that's architect work.

Schema validation pseudocode:
```
INVALID_VALUES = ["", null, "nil", "TBD", "XXX", "FIXME"]
EMDASH_SENTINEL = "—"   # U+2014

REQUIRED_COMMON_FIELDS = [
  intent_identifier_crystal, primary_apple_name, class, tier,
  swiftui_api, uikit_api, appkit_api,           # ALL THREE required; use "—" if no equivalent
  hig_page, android_equivalent, web_equivalent,
  coverage_today, description
]
REQUIRED_CLASS_D_EXTRA = [crystal_api_shape, platforms]

for each row in catalog:
  for each field in REQUIRED_COMMON_FIELDS:
    if field not declared: REJECT row "missing field: #{field}"
    value = row[field]
    if value in INVALID_VALUES: REJECT row "invalid value: #{value}"
    if value.strip == "": REJECT row "whitespace-only value"
    if value matches /^-+$/ AND value != EMDASH_SENTINEL: REJECT row "use em-dash sentinel"

  if row[class] not in [A, B, C, D]: REJECT
  if row[tier] not in [1, 2, 3]: REJECT
  if row[class] == "D":
    for each field in REQUIRED_CLASS_D_EXTRA:
      if field not declared: REJECT row "Class D missing #{field}"

  if row[intent_identifier_crystal] != snake_case(row[primary_apple_name])
     AND row[apple_canonical_name_exists] != false:
    REJECT row "intent_identifier_crystal must be snake_case of primary_apple_name (or declare exception)"
```

### Items 2, 4, 5 — architect-led writing + implementer validation

Same pattern: architect drafts; implementer schema-validates + cross-references.

### Item 3 (translation-matrix.md) — IMPLEMENTER writes the freshness reconciliation

Architect drafts the per-Class-A-intent translation table (1-3 entries). **Implementer separately writes the freshness reconciliation paragraph** — runs `ls src/ui/views/*.cr | wc -l` to settle the actual view count, identifies what counts (gate stubs in `src/ui/views/_gate_stubs/`, `*_with_web_fallback.cr` siblings, presenter classes, compat files), and produces a paragraph that explains the 59-vs-80 discrepancy with the actual ground-truth count. This paragraph gets cross-referenced from `widget-intent-mapping.md` (Item 6) so the audit table's row count matches reality.

### Item 6 (widget-intent-mapping.md) — IMPLEMENTER's bulk audit

This is the largest implementer task. For each `*.cr` file in `src/ui/views/`:
- Read the file's class definition + class-level comment.
- Identify the primary intent (Apple name) it serves.
- Classify A/B/C/D using the catalog as the source of truth.
- Set tier from CLAUDE.md:148-160 tier-3 list (gated widgets are Tier 3; brand-universal are Tier 1; otherwise Tier 2).
- Mark routing candidate (only Class A widgets are routing candidates).
- Write the one-sentence reason.
- Flag gaps (cross-reference intent-backlog.md).

Expected output: ~80 rows. Implementer commits this table.

### Item 7 (apple-surface-coverage.md) — implementer fills checklist

Implementer takes the Apple-surface enumeration from scoping-9.md and produces the checklist. For each named API, find the corresponding catalog row in Item 1 and link to it. If no catalog row exists, the implementer escalates to architect (the catalog is incomplete).

### Codex per-iteration review

Standard pattern. After implementer ships, Codex reviews the bundle. Saved to `docs/initiative-cross-platform-ui/handoff/phase-09-codex-N.md`.

## 6. Acceptance criteria (closing-gate)

A passing Phase 9 means ALL of:

- [ ] `docs/initiative-cross-platform-ui/architecture/intent-catalog.md` exists with all rows schema-compliant.
- [ ] All 4 classes (A/B/C/D) represented in the catalog.
- [ ] Apple-surface coverage gate green: **every named SwiftUI/UIKit/AppKit API entry** enumerated in scoping-9.md §"Apple-surface coverage gate" has its own catalog row (not "at least one per family" — each `toolbar`, `ToolbarItem`, `ToolbarItemGroup`, `ToolbarItemPlacement`, `ToolbarSpacer`, `toolbarBackground` etc. is an individual row).
- [ ] `intent-routing-candidates.md` exists with the small Class A set + full capabilities + defaults.
- [ ] `translation-matrix.md` exists for Class A intents + freshness reconciliation.
- [ ] `tier-2-translation-contract.md` documents the four-part contract (Class A) + direct-modifier shape (Class D) + override registry semantics + implementation pseudocode.
- [ ] `intent-backlog.md` lists every missing per-platform default with size + priority.
- [ ] `widget-intent-mapping.md` covers every file in `src/ui/views/*.cr` with exact A/B/C/D class assignment.
- [ ] `apple-surface-coverage.md` checklist all green (or deferred with justification).
- [ ] Codex antagonist verdict: APPROVE or APPROVE_WITH_NOTES on the bundle.
- [ ] No code changes in this phase. NO new `UI::View` classes. NO LSP rule implementations.
- [ ] `crystal spec` unchanged (no code touched).

## 7. Risk register (R1-R20 from scoping-9.md inherited)

R1-R16 from `coplan-9-codex-1.md`; R17-R20 from scoping v3. All adopted.

- **R-brief-1** — Catalog is huge; implementer may stall on volume. *Mitigation:* architect drafts Items 1-5 directly (not implementer); implementer handles bulk audit (Item 6) + checklist (Item 7) + schema validation across all items.
- **R-brief-2** — Apple vocabulary disagreement between SwiftUI and UIKit (e.g., SwiftUI says `Menu`, UIKit says `UIMenu`). *Mitigation:* `primary_apple_name` defaults to the SwiftUI name (modern API surface); UIKit/AppKit names are secondary citations.
- **R-brief-3** — Modifiers that combine (e.g., `presentationDetents` modifies `sheet`). *Mitigation:* both get catalog rows. The modifier row's `description` notes it composes with the host modifier.

## 8. Implementation order

1. **Architect drafts Items 1 (intent-catalog), 2 (intent-routing-candidates), 4 (tier-2-translation-contract), 5 (intent-backlog).** During the planning phase. Architect ALSO drafts the per-Class-A-intent translation table in Item 3 (the freshness reconciliation paragraph in Item 3 is implementer-led — see §5).
2. **Codex antagonist content-level review of `intent-catalog.md`** before implementer dispatch. This is a CONTENT-level pass (not just schema): verify Apple vocabulary discipline, A/D classification boundaries, no bundled-intent rows, exceptions justified. Saved to `docs/initiative-cross-platform-ui/handoff/phase-09-codex-content-1.md`. If REVISE, architect revises catalog content + re-runs Codex until APPROVE_WITH_NOTES.
3. **Cut `phase-09-intent-catalog` branch.** Commit the architect-led documents in one or more planning commits.
4. **Dispatch implementer** with this brief. Implementer scope: Item 3 freshness reconciliation, Item 6 (widget-intent-mapping audit), Item 7 (apple-surface-coverage checklist), schema validation across all 7 items via the lint script.
5. **Codex per-iteration review** on implementer's output. Saved to `handoff/phase-09-codex-N.md`. Close with APPROVE or APPROVE_WITH_NOTES.
6. **Architect final pass + merge + tag** `phase-09a-pass-2026-05-XX`.

**NOTE on the deferred owner-screen window** (Codex MEDIUM 4): the scoping doc's T+0/T+7/T+9 owner-screen intake loop is explicitly DEFERRED per owner directive 2026-05-25 ("work entirely through Phase 9"). See §10 Hard Rules. Initial catalog ships without waiting for owner screens; gaps surfaced post-merge become Phase 9B amendments.

## 9. Validation invocations

- `crystal spec` — unchanged.
- `ls src/ui/views/*.cr | wc -l` — actual view count for freshness reconciliation.
- Schema lint — implementer writes a small Ruby/Python/Crystal script that parses each row and validates per §3. Script lives at `scripts/lint_intent_catalog.cr` (or similar). Optional but recommended for repeatability.
- Codex review: `codex exec -c 'model_reasoning_effort="medium"' "<prompt>" 2>&1 | tee /tmp/codex-iter.log | tail -300`.

## 10. Hard rules

- Forward commits only on `phase-09-intent-catalog`.
- NO framework code changes. Docs are the deliverable.
- **Validation scripts under `scripts/lint_intent_catalog.cr` (or equivalent) ARE permitted** — this is a tooling exception, not framework code. The script implements §5 Item 1's pseudocode and is checked in alongside the docs.
- NO renames of existing `UI::View` classes.
- Catalog vocabulary derives FROM Apple SwiftUI / UIKit / AppKit FIRST.
- Every catalog row carries the full schema (12 common fields; Class D adds 2 more).
- Class assignment is exact (one of A/B/C/D).
- Apple-surface coverage gate: every named API in Codex's enumeration has its own row (not aggregated by family).
- **Owner-screen intake window from scoping-9.md §"Owner-screen discovery loop" is DEFERRED** per owner directive 2026-05-25 "work entirely through Phase 9." The initial catalog ships without waiting for owner-supplied screens. Owner can add intents post-merge via a Phase 9B amendment if their screens reveal gaps.
- Codex antagonist on every iteration (content-level pass before implementer dispatch + per-iteration during implementer work).
- Standard Claude co-author footer.

— Architect (Claude Opus 4.7)
