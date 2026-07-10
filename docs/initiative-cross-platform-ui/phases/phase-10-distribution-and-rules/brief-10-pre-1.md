# Phase 10-pre.1 — Implementer Brief (v2)

**Phase:** 10-pre.1 — Factual catalog correction.
**Branch:** `phase-10-pre-1` cut from `phase-10`.
**Status:** v2 — incorporates Codex antagonist findings on v1 (see `codex-brief-10-pre-1-critique.md`).
**Predecessor:** Phase 9 closed PASS but with documented accuracy gaps; see `handoff/phase-10-pre-catalog-freshness-2026-05-25.md` (including the **2026-05-25 correction** for `:share_link`).

---

## What changed from v1

1. **Removed the contradiction.** v1 said "no new backlog items" in Constraints, then added B-036 + B-037 in Deliverable 6. v2 resolves: B-036 + B-037 are explicit Phase 10-pre.1 amendments allowed by name; no other new backlog items are permitted.
2. **Reversed the `activity_view.cr` reclassification.** v1 said reclassify Class C → D ("presentational, not bridge"). **Codex caught the error**: `UI::ActivityView` IS wired to native sharing APIs through the renderers (`uikit_renderer.cr:3408`, `appkit_renderer.cr:3417`, `android_renderer.cr:2871`, `objc_bridge.m:2148-2245`). v2 keeps `activity_view.cr` as Class C with proper citations.
3. **Catalog correction for `:share_link` is `shipped`, not `missing`.** The freshness audit's false-negative is documented inline in the audit file (correction block 2026-05-25). The catalog row for `:share_link` becomes `shipped (citations)`, NOT `missing`.
4. **Added Deliverable 8: Class C re-audit.** Verify the freshness check's "0/9 realized" claim against renderers + native bridges (not just `src/ui/views/`). v1 trusted the audit's `0/9` — Codex proved it was wrong on `:share_link`. The other 8 Class C intents may have similar false-negatives.
5. **Audit-scope discipline.** Every "check whether X is shipped" step in the workflow now requires scanning `src/ui/renderers/*.cr`, `src/ui/native/*.{cr,m}`, AND `src/ui/*.cr` (not just `src/ui/views/`). The `[[audit-shortcut-trap]]` lesson made concrete.

---

## 1. What you are doing

You are correcting the Phase 9 intent catalog documentation to accurately describe the framework as it stands on 2026-05-25. The catalog currently overstates the framework's coverage in some places AND understates it in at least one (`:share_link`). Phase 10's widget implementation work (10B) cannot proceed against an inaccurate catalog. Your job is to make every claim in the catalog match the source code.

**You are NOT writing code. You are NOT renaming Crystal APIs. You are NOT adding widgets.**

You ARE correcting prose, capability claims, and `coverage_today` values — but `crystal_api_shape` corrections are 10-pre.2's job, not yours. In 10-pre.1, your scope is limited to:

- `coverage_today` field values (move false "partial"/"shipped" claims to `missing` OR add proper citations for verified claims OR upgrade false-"missing" to verified-"shipped").
- Class A capability block trimming (remove the FALSE/UNBACKED claims).
- Class C re-audit + catalog correction (the freshness check missed `:share_link`).
- `translation-matrix.md` honest "MISSING" markings for non-existent widgets.
- Backlog count reconciliation + priority adjustments per freshness audit (with the `:share_link` correction).
- Lint script extension (citation-presence check).

## 2. Read first (in order)

Working directory: `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`.

1. `docs/initiative-cross-platform-ui/handoff/phase-10-pre-catalog-freshness-2026-05-25.md` — your starting source of truth. **Read the 2026-05-25 correction block** at the bottom of the Class C section carefully — it overrides part of the audit's original verdict.
2. `docs/initiative-cross-platform-ui/phases/phase-10-distribution-and-rules/scoping-10.md` — v3 scoping. Read §"10-pre.1" for your scope boundary.
3. `docs/initiative-cross-platform-ui/architecture/intent-catalog.md` — the document you're correcting (1571 lines).
4. `docs/initiative-cross-platform-ui/architecture/intent-routing-candidates.md` — Class A capability block.
5. `docs/initiative-cross-platform-ui/architecture/widget-intent-mapping.md` — 82-row widget audit.
6. `docs/initiative-cross-platform-ui/architecture/translation-matrix.md` — per-platform defaults.
7. `docs/initiative-cross-platform-ui/architecture/intent-backlog.md` — backlog item priorities.
8. `scripts/lint_intent_catalog.cr` — existing lint script.
9. `CLAUDE.md` — project conventions (especially the section on intent classes A/B/C/D and tier model).

For citations, you'll need to read source files. **Audit scope discipline** (per the 2026-05-25 correction):

- `src/ui/views/*.cr` — view file definitions.
- `src/ui/renderers/*.cr` — renderer-side bridge wiring (THE files the original audit missed).
- `src/ui/native/*.{cr,m}` — ObjC + lib bridge implementations.
- `src/ui/*.cr` — top-level UI helpers (notifications.cr, app_shortcuts.cr, etc. — though Class E "system experiences" are out of scope for the catalog).
- `src/asset_pipeline/*.cr` — for cross-platform helpers.

## 3. Constraints (Hard Rules)

- **Forward commits only** on branch `phase-10-pre-1`. Cut the branch first: `git checkout -b phase-10-pre-1 phase-10`.
- **Never touch `src/`.** No code changes. If a correction requires code, it's out of 10-pre.1 scope — surface it as a Phase 10B/10-pre.2 finding, do not implement.
- **Citation discipline.** Every `coverage_today` value other than `missing` or `catalog_only` MUST cite a file path + line range, e.g. `coverage_today: shipped (src/ui/views/view.cr:132)`. The lint script will enforce this; you will write that lint extension first so it can guide the rest of your work.
- **No `crystal_api_shape` rewrites.** Those are 10-pre.2. If the freshness audit flagged a Class D shape as wrong, leave the field alone and add a `# pending 10-pre.2 rename audit` comment marker so 10-pre.2 finds them.
- **No new intents.** The 67 catalog rows stay 67.
- **NEW backlog items allowed BY NAME only.** You may add **B-036** (`:swipe_actions` capability honesty work — references 10B.1b slice) and **B-037** (`accessibility_hint` + `accessibility_value` surfacing — references 10B.2a slice). No other new B-NNN entries. If the Class C re-audit (Deliverable 8) surfaces additional gaps, those become 10B.3.x slice work and DO NOT spawn new backlog entries in 10-pre.1.
- **Audit-scope discipline:** when verifying a `coverage_today: shipped` claim, scan renderers AND native bridges, not just `src/ui/views/`. Document the scan command used in the close handoff.
- Per `[[plan-what-to-understand-not-just-what-to-build]]`: if a correction surfaces a deeper inconsistency (e.g., a catalog row cites a SwiftUI API that doesn't exist on Apple's side), surface it in the close handoff. Don't paper over.
- Per `[[codex-as-architect-antagonist]]`: when you produce a draft of any corrected document, the architect dispatches Codex content review. You incorporate Codex's findings before close.
- Per `[[complete-phase-arc-before-review]]`: no owner involvement during 10-pre.1.

## 4. Deliverables (acceptance shape)

### Deliverable 1 — Extended lint script

Edit `scripts/lint_intent_catalog.cr` to add a citation-presence check.

**Rule:** For every catalog row, if `coverage_today` value is not `missing` AND not `catalog_only` AND not `deferred`, then the value MUST contain a substring matching `src/...:` followed by digits (with optional `-digits` range), e.g. `src/ui/views/view.cr:132` or `src/ui/renderers/uikit_renderer.cr:3408-3413`.

**Rule:** The lint MUST reject `partial` and `shipped` values that lack citations.

**Rule:** Vague language ("some views", "most renderers", "partial coverage") in `coverage_today` must be rejected unless backed by a citation OR converted to `missing`/`catalog_only`.

**Rule:** Multi-citation values are valid — split on semicolons, each segment must match the citation pattern OR be a literal `missing`/`catalog_only`/`deferred`/explanatory clause.

**Exit:** Non-zero if any violation found. Print the offending row's intent identifier + the bad value + the issue.

Test the extension by running it against the current catalog BEFORE making corrections — expect it to fail with many violations. That's your work list.

### Deliverable 2 — `intent-catalog.md` corrected

For each of the 67 catalog rows:

- If `coverage_today` is honestly `missing` → leave alone.
- If `coverage_today` claims `shipped` or `partial`:
  - Read the cited source files (views + renderers + native bridges).
  - If the claim is verified → add a citation `(src/.../foo.cr:N-M)`.
  - If the claim is FALSE → change to `missing` with a `# was: shipped (false claim per phase-10-pre-1 audit)` inline note.
  - If the claim is PARTIAL with caveats → preserve "partial" but add citation AND a `# caveats: ...` note explaining which renderers honor it.
- If `coverage_today` claims `missing` but Deliverable 8's Class C re-audit finds the intent IS shipped → upgrade to `shipped` with full citations.

**Specific known corrections from the freshness audit + Codex's catch:**

| Catalog row | Current value | Correct value |
|---|---|---|
| `:accessibility_label` | "shipped" | `shipped (src/ui/views/view.cr:132)` |
| `:accessibility_hint` | "partial" | `missing` |
| `:accessibility_value` | "partial" | `missing` |
| `:tap_gesture` | "shipped" | `partial (src/ui/views/button.cr:93; icon_button.cr:22; link_button.cr:8; not on base UI::View)` |
| `:dynamic_type_size` | "partial" | `partial (design tokens carry semantic font sizes; src/ui/design_tokens.cr — runtime scaling not wired)` |
| `:accessibility_voice_over_enabled` | "partial" | `partial (src/ui/views/view.cr:132 accessibility_label honors VoiceOver; traits/value not exposed)` |
| `:accessibility_full_keyboard_access` | "partial" | `partial (web <button>/<input> focusable by default; no Crystal-side helper)` |
| **`:share_link`** | **"missing"** | **`shipped (src/ui/renderers/uikit_renderer.cr:3408; src/ui/renderers/appkit_renderer.cr:3417; src/ui/renderers/android_renderer.cr:2871; src/ui/native/objc_bridge.m:2148-2245)` — UI::ActivityView wires UIActivityViewController, NSSharingServicePicker, Intent.ACTION_SEND.** |
| Other 8 Class C intents (`:copyable`, `:paste_button`, `:authorization_request`, `:open_url`, `:on_open_url`, `:ui_print_interaction_controller`, `:file_importer`, `:file_exporter`) | "missing" | LEAVE as `missing` (Deliverable 8 verifies, expects to confirm zero matches in `src/ui/renderers/` and `src/ui/native/`) |
| `:swipe_actions` | capability block | trim to verified-only (see Deliverable 3) |

### Deliverable 3 — `intent-routing-candidates.md` capability block trimmed

`:swipe_actions` capability block currently lists 12 capabilities. Per the freshness audit, only 6–7 are backed by source code. Trim the block to those.

Adjustments:

- `supports_edge :leading` — DOWNGRADE: keep listed, but mark "**web only today** (`src/ui/renderers/web_renderer.cr:2909-2911`); UIKit/AppKit/Android render trailing only — **Phase 10B.1b target**".
- `supports_edge :trailing` — KEEP as verified with citations.
- `supports_role :destructive` — DOWNGRADE: "partial — honored on iOS (`uikit_renderer.cr:3852`) and web (`web_renderer.cr:2942`); AppKit drops role (`appkit_renderer.cr:3819-3826`); Android stub. **Phase 10B.1b/c target.**"
- `supports_role :default` — KEEP as verified.
- `supports_disabled_actions` — REMOVE from active capabilities; move to a new "Planned (Phase 10B targets)" section. `SwipeAction` struct has no disabled field.
- `requires_row_identity_dispatch` — REMOVE from active; not enforced by API.
- `requires_visible_or_keyboard_alternative` — KEEP but mark "unenforced today — Phase 10A LSP rule target".
- `requires_accessibility_custom_actions` — REMOVE from active; move to Planned. No `UIAccessibilityCustomAction` wired. Phase 10B.2b target.
- `supports_voiceover_actions` — REMOVE from active; move to Planned. Corollary of above.
- `supports_switch_control_activation` — DOWNGRADE to "partial — web `<button>` focusable; native paths offer no Switch Control surface beyond platform default".
- `supports_voice_control_labels` — DOWNGRADE to "partial — iOS + web set accessibility labels; AppKit does not".
- `does_not_conflict_with_system_gestures` — KEEP but mark "unverified from code; requires runtime testing of ObjC bridge".

The trimmed active block describes the framework as it stands. The "Planned (Phase 10B targets)" section preserves design intent without falsifying the current state.

### Deliverable 4 — `widget-intent-mapping.md` rewritten with citation per row

For all 82 rows:

- Replace "Reason" prose with citation-bearing prose: `<sentence>. See <file>:<lines>.`
- **For `activity_view.cr`: KEEP Class C** (corrected from v1 of this brief). Update "Reason" to: "Activity view for sharing; bridges to UIActivityViewController on iOS (`src/ui/renderers/uikit_renderer.cr:3408`), NSSharingServicePicker on macOS (`appkit_renderer.cr:3417`), Intent.ACTION_SEND on Android (`android_renderer.cr:2871`); inline share-sheet preview on all platforms. Carries an `ActivityViewPresenter` helper."
- For `swipe_action_row.cr` (Class A): keep the row but update "Gaps" to reflect 10B.1a/b/c assignments (B-001, B-002, B-035, B-036) and add "Class A capability claims trimmed in 10-pre.1; full capability surface in 10B.1b."
- Recount: **with `activity_view.cr` staying Class C**, the breakdown is 1 A + 0 B + 1 C + 80 D = 82 (unchanged from current). Update the Summary section only if other reclassifications surface.
- For every row, the "Reason" field MUST cite a source path. If the cite is to a layout primitive that maps 1:1 to a SwiftUI named API, format as `<reason>. Direct mapping; see <file>:<lines>.`

### Deliverable 5 — `translation-matrix.md` honest

Currently advertises `UI::InlineActionRow` as macOS + web_wide default for `:swipe_actions`. The class does not exist in `src/`. Per the freshness audit:

- Mark `UI::InlineActionRow` rows as `MISSING — see backlog B-001 (macOS) and B-002 (web_wide); UI::SwipeActionRow currently rendered as inline buttons on AppKit (appkit_renderer.cr:3801)`.
- Existing Freshness reconciliation paragraph stays — minor edit only if needed to reference the missing default.

### Deliverable 6 — `intent-backlog.md` count reconciled + reprioritized

- Verify total count: file currently says "34" in summary table; ID range goes B-001 to B-035 with gaps. Count actual entries; reconcile to the final number.
- Apply the freshness audit's recommended priority adjustments **as amended by the 2026-05-25 correction**:
  - **B-020** (accessibility actions) — confirm P0 (already P0).
  - **B-001, B-002** (UI::InlineActionRow macOS + web_wide) — promote P1 → P0 (the catalog's only Class A default, currently absent).
  - **B-035** (Android `:swipe_actions` proper integration) — confirm P1.
  - **NEW B-036** (`:swipe_actions` capability honesty — Phase 10B.1b binding work) — P0.
  - **NEW B-037** (`accessibility_hint` + `accessibility_value` surfacing — Phase 10B.2a binding work) — P0.
  - **NO new backlog entries for Class C intents.** The other 8 Class C entries already have IDs B-026 through B-034. Their priorities stay as-is. `:share_link` (B-026) is now SHIPPED — REMOVE from backlog or mark as closed/historic.
- Add a "Frozen 2026-05-25 by 10-pre.1" note at the top of the backlog with the final count.

### Deliverable 7 — Close handoff

Write `docs/initiative-cross-platform-ui/handoff/phase-10-pre-1-close.md`:

- Headline: # corrections shipped vs. freshness audit's findings (note: includes the `:share_link` upgrade).
- Per-deliverable evidence (which catalog rows changed, before/after for the worst offenders).
- Lint output before / after (number of violations went from N to 0).
- New backlog items added (B-036, B-037). B-026 (`:share_link`) removed/closed.
- Class breakdown final: 1 A / 0 B / 1 C / 80 D (unchanged).
- Audit-scope command used (what directories/patterns were scanned) — establishes the discipline for future audits.
- Anything surfaced that's deeper than 10-pre.1 scope (e.g., catalog cites a SwiftUI API that doesn't exist — defer to a Phase 9 amendment if found).
- Codex content review verdict (must be APPROVE before close).

### Deliverable 8 — Class C re-audit (NEW in v2)

Re-audit the 9 Class C intents against `src/ui/renderers/*.cr` AND `src/ui/native/*.{cr,m}`, not just `src/ui/views/`.

For each of the 9 Class C intents (`:share_link`, `:copyable`, `:paste_button`, `:authorization_request`, `:open_url`, `:on_open_url`, `:ui_print_interaction_controller`, `:file_importer`, `:file_exporter`), grep for the relevant native API names:

| Intent | Native APIs to grep |
|---|---|
| `:share_link` | `UIActivityViewController`, `NSSharingServicePicker`, `Intent.ACTION_SEND` (confirmed: SHIPPED) |
| `:copyable` | `UIPasteboard`, `NSPasteboard`, Android `ClipboardManager` |
| `:paste_button` | Same as above |
| `:authorization_request` | `AVCaptureDevice.requestAccess`, `PHPhotoLibrary`, `CLLocationManager`, `Manifest.permission` |
| `:open_url` | `openURL:`, `UIApplication.shared.open`, `NSWorkspace.open`, `Intent.ACTION_VIEW` |
| `:on_open_url` | `application:openURL:options:`, `application:continueUserActivity:`, intent filters |
| `:ui_print_interaction_controller` | `UIPrintInteractionController`, `NSPrintInfo`, `PrintHelper` |
| `:file_importer` | `UIDocumentPickerViewController`, `NSOpenPanel`, `ActivityResultContracts.OpenDocument` |
| `:file_exporter` | `NSSavePanel`, `UIDocumentInteractionController`, `ActivityResultContracts.CreateDocument` |

Search command pattern:
```bash
grep -rn "<API_NAME>" src/ui/renderers/ src/ui/native/ src/ui/ 2>/dev/null
```

For each intent:
- If zero matches → confirms `missing` (most expected).
- If matches found → upgrade catalog row to `shipped (<citations>)`, like the `:share_link` correction.

Record findings in the close handoff.

## 5. Workflow (the exact sequence)

1. `git checkout -b phase-10-pre-1 phase-10`. Verify branch.
2. **Run Deliverable 8 first** (Class C re-audit). It's cheap and surfaces any other false-negatives BEFORE you start editing the catalog. Document findings.
3. Extend the lint script (Deliverable 1). Run it against the current catalog. Capture the violation count. This is your work plan.
4. Tackle each violation in order. For each:
   - Read the source files the catalog claims realize the intent (views + renderers + native bridges).
   - Decide: verified → add cite. False → change to `missing`. Partial → add cite + caveat note. Missing-but-actually-shipped (rare, from Deliverable 8) → upgrade to `shipped` with cites.
   - Edit the catalog row.
   - Re-run the lint locally on that row's neighborhood.
5. Trim the `:swipe_actions` capability block (Deliverable 3). Add the "Planned" section for capabilities removed.
6. Update `widget-intent-mapping.md` with per-row citations (Deliverable 4). **DO NOT reclassify `activity_view.cr`** — it stays Class C with renderer-bridge citations.
7. Update `translation-matrix.md` (Deliverable 5).
8. Reconcile + reprioritize the backlog (Deliverable 6). Mark B-026 closed (since `:share_link` is shipped); add B-036 + B-037.
9. Run the full lint script. It must exit 0.
10. Commit incrementally per deliverable with clear messages:
    - `[Phase 10-pre.1] Class C re-audit; confirm :share_link shipped, others missing`
    - `[Phase 10-pre.1] Add citation-presence check to lint_intent_catalog.cr`
    - `[Phase 10-pre.1] Correct intent-catalog.md coverage_today claims with citations`
    - `[Phase 10-pre.1] Trim :swipe_actions capability block; add Planned section`
    - `[Phase 10-pre.1] widget-intent-mapping.md per-row citations; activity_view.cr stays Class C`
    - `[Phase 10-pre.1] translation-matrix.md UI::InlineActionRow MISSING markers`
    - `[Phase 10-pre.1] Reconcile backlog; B-026 closed; B-036, B-037 added P0`
11. Final commit: `[Phase 10-pre.1] Close handoff` with the close doc.

Standard commit footer:

```
Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
```

## 6. Acceptance gate (architect-side close criteria)

The architect closes 10-pre.1 PASS only when:

- ✅ `crystal run scripts/lint_intent_catalog.cr` exits 0.
- ✅ Independent re-audit by a fresh agent (different system prompt) reports zero unbacked `coverage_today` claims, AND the re-audit prompt explicitly requires scanning `src/ui/renderers/` + `src/ui/native/` (audit-scope discipline carried forward).
- ✅ Codex content review on `intent-catalog.md` returns APPROVE.
- ✅ All deliverables 1–8 shipped.
- ✅ `phase-10-pre-1-close.md` includes Codex review verdict + lint before/after counts + Class C re-audit findings.

## 7. Out of scope (explicit, do not do)

- Class D `crystal_api_shape` corrections (those are 10-pre.2).
- Crystal API renames (10-pre.2).
- Writing widget code (10B).
- Adding new intents to the catalog (Phase 9 amendment, not 10-pre.1).
- Adding new backlog items OTHER than B-036 + B-037 (explicitly allowed by name in §3).
- LSP rules (10A).
- Spec directory reorganization (10C.0).
- Owner involvement (none until 10D).
- Re-classifying `UI::ActivityView` to Class D (it IS Class C with renderer bridge wiring).

## 8. What success looks like

After 10-pre.1 closes, anyone (including an AI agent) reading the catalog can:

- Trust every "shipped" or "partial" claim because it cites source.
- See every gap (Class A capability holes, Class B contracts not yet on `UI::View`, 8 of 9 Class C system bridges) marked honestly as `missing`.
- See every realized intent (including `:share_link`) accurately attributed with renderer + bridge citations.
- Find every backlog item with an accurate priority reflecting what blocks Phase 10B.

The catalog stops being a wishlist mixed with reality. It becomes an accurate inventory of "what we have" plus a clearly-marked planned-work section.

— Architect (Claude Opus 4.7), 10-pre.1 brief v2 (post-Codex)
