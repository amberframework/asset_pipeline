# Phase 9 Implementer Iteration 1 — Codex Review

**Date:** 2026-05-25
**Source log:** `/tmp/codex-iter-9.log`
**Codex invocation:** `codex exec -c 'model_reasoning_effort="medium"' ...` (medium reasoning, arg-form).

## Verdict — Iter 1: REVISE

Codex flagged 1 HIGH + 2 MEDIUM + 2 LOW. The HIGH is catalog-content (architect ownership). The MEDIUMs are implementer-side. LOWs are positive spot-checks. Implementer applied iter-1.5 fixes for the MEDIUMs; HIGH is escalated to architect.

### HIGH — Catalog snake_case schema lint failures (architect escalation)

Files: `docs/initiative-cross-platform-ui/architecture/intent-catalog.md` + `scripts/lint_intent_catalog.cr`.

Lint reports **11 violations** where `intent_identifier_crystal` does not equal `:` + snake_case(`primary_apple_name`) and no `apple_canonical_name_exists: false` exception is declared:

| Identifier | primary_apple_name | Expected by lint |
|---|---|---|
| `:accessibility_voice_over` | `accessibilityVoiceOverEnabled` | `:accessibility_voice_over_enabled` |
| `:accessibility_switch_control` | Switch Control | `:switch_control` |
| `:accessibility_voice_control` | Voice Control | `:voice_control` |
| `:accessibility_full_keyboard_access` | Full Keyboard Access | `:full_keyboard_access` |
| `:accessibility_element_grouping` | `accessibilityElement(children:)` | `:accessibility_element` |
| `:accessibility_captions` | Captions / Subtitles / Transcripts | `:captions_subtitles_transcripts` |
| `:accessibility_assistive_access` | Assistive Access | `:assistive_access` |
| `:accessibility_dim_flashing_lights` | Dim Flashing Lights | `:dim_flashing_lights` |
| `:pasteboard_copy` | `UIPasteboard` (copy) | `:ui_pasteboard` |
| `:pasteboard_paste` | `UIPasteboard` (paste) / `PasteButton` | `:ui_pasteboard` |
| `:print_interaction` | `UIPrintInteractionController` | `:ui_print_interaction_controller` |

**Implementer judgment:** these are legitimate catalog-content gaps. Two patterns:

1. **HIG-page-only intents** (`Switch Control`, `Voice Control`, etc.) have no canonical SwiftUI API name. Per brief-9 §3 "Exception process," they require an explicit `apple_canonical_name_exists: false` declaration plus a justification.
2. **Disambiguation suffixes** (`:pasteboard_copy` vs `:pasteboard_paste`; `:print_interaction`) — the identifier diverges from snake_case to keep two related intents distinguishable. Either rename the identifiers to match, or move the suffix into a more disambiguating `primary_apple_name`, or declare an exception.

**Escalation:** architect owns the catalog (per brief-9 §5 Item 1: "Implementer does NOT invent new intents — that's architect work"). Implementer does NOT auto-fix.

### MEDIUM 1 — `widget-intent-mapping.md` Class column violated brief-9's exact-A/B/C/D rule (FIXED iter 1.5)

Codex caught that 10 layout-primitive rows used `Class = —`, but brief-9 §"Item 6" says: *"Class assignment is EXACT. One of A/B/C/D. No 'D-ish.' Layout primitives that aren't intent-routed are Class D (direct translation to native primitives)."*

**Fix applied (iter 1.5):** reclassified all 10 layout-primitive rows (`capsule.cr`, `circle.cr`, `divider.cr`, `hstack.cr`, `path_view.cr`, `rectangle.cr`, `rounded_rectangle.cr`, `spacer.cr`, `vstack.cr`, `zstack.cr`) from `—` to `D`. Updated the column rubric and the summary section. Row math now: 1 (A) + 0 (B) + 1 (C) + 80 (D) = 82.

### MEDIUM 2 — `translation-matrix.md` freshness reconciliation math + tier-matrix claim (FIXED iter 1.5)

Codex caught two errors in the freshness reconciliation paragraph:

1. The category breakdown summed 76 + 3 + 3 + 3 = **85**, not 82. The `76 concrete top-level` claim was wrong (the correct breakdown is 73 ordinary + 3 gated + 3 fallback = 79 top-level, plus 3 gate stubs = 82).
2. The paragraph said `tier-matrix.md` "groups" `swipe_action_row.cr` as a duplicate row. False — the matrix actually OMITS `swipe_action_row.cr` (`grep swipe_action /docs/.../tier-matrix.md` returns nothing).

**Fix applied (iter 1.5):** rewrote the paragraph with mutually-exclusive buckets (73 + 3 + 3 + 3 = 82) and corrected the tier-matrix claim — now flags `tier-matrix.md`'s missing `swipe_action_row.cr` row as a documented staleness in the matrix, not a discrepancy in the source tree. Also propagated the cross-reference to the corrected `widget-intent-mapping.md` summary.

### LOW 1 — `apple-surface-coverage.md` spot-check passed

Codex sampled `UIImpactFeedbackGenerator`, `accessibilityLabel`, `toolbarBackground`, `SpatialTapGesture`, `formStyle`. All five cited catalog identifiers exist with matching `primary_apple_name`. No action needed.

### LOW 2 — `widget-intent-mapping.md` source spot-check mostly passed

Codex sampled `progress_view.cr`, `navigation_stack.cr`, `grid.cr`, `action_sheet.cr`, `picker.cr` — all matched the table. Only finding rolled into MEDIUM 1.

### NIT (implementer-side) — Crystal cache directory in sandboxed environments

Codex noted that running `crystal run scripts/lint_intent_catalog.cr` in a sandboxed environment fails because `/Users/crimsonknight/.cache/crystal` is outside the writable roots. Workaround documented for future runs:

```bash
CRYSTAL_CACHE_DIR=/private/tmp/asset_pipeline_crystal_cache crystal run scripts/lint_intent_catalog.cr
```

This is environment-specific (not a script issue). No code change needed; the script works correctly in the developer environment.

## State after iter 1.5

- **Item 3 freshness reconciliation:** ✅ shipped, math corrected, tier-matrix staleness flagged.
- **Item 6 widget-intent-mapping:** ✅ shipped, 82 rows, all rows carry exact A/B/C/D classification per brief-9.
- **Item 7 apple-surface-coverage:** ✅ shipped, 65 named APIs, 0 missing, gate green.
- **Schema lint script:** ✅ shipped at `scripts/lint_intent_catalog.cr`. Runs against 92 catalog entries. **11 violations remain in the catalog content** — escalation to architect.
- **Codex iter 1 verdict:** REVISE on iter 1; expected outcome after iter 1.5 fixes + architect catalog resolution is APPROVE_WITH_NOTES.

## Architect escalation summary

The HIGH finding (11 catalog snake_case violations) cannot be closed by the implementer per brief-9 hard rules ("NO new catalog entries. If a coverage gap exists, escalate"). Two paths exist for the architect:

1. **Rename approach:** change `intent_identifier_crystal` for affected rows to match snake_case(`primary_apple_name`) (e.g., `:accessibility_voice_over` → `:accessibility_voice_over_enabled`).
2. **Exception approach:** add `apple_canonical_name_exists: false` + a justification for the HIG-page-only intents (Switch Control, Voice Control, Full Keyboard Access, Captions / Subtitles / Transcripts, Assistive Access, Dim Flashing Lights). For the `UIPasteboard` and `UIPrintInteractionController` rows, decide whether the disambiguation suffix is worth keeping (then add the exception) or whether to rename.

After the architect resolves, `crystal run scripts/lint_intent_catalog.cr` must return `PASS` before Phase 9 close.

— Implementer (Claude Opus 4.7), Phase 9 iter 1 + iter 1.5
