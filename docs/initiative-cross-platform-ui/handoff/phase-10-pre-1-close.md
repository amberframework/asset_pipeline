# Phase 10-pre.1 — Close Handoff

**Date:** 2026-05-25
**Branch:** `phase-10-pre-1` (cut from `phase-10`).
**Implementer:** Claude Opus 4.7
**Brief:** `phases/phase-10-distribution-and-rules/brief-10-pre-1.md` (v2, post-Codex).

## Headline

**8 deliverables shipped. Lint passes 0/0. `:share_link` upgraded SHIPPED with renderer + native-bridge citations. Class C re-audit confirmed 1/9 realized + 8/9 honestly missing.**

Phase 9 closed PASS with documented accuracy gaps. Phase 10-pre.1's job was to close them by making every catalog claim cite source code. The audit-scope discipline catch from the 2026-05-25 freshness-audit correction (and Codex's brief-v1 critique) is preserved as the methodology for future re-audits: scan `src/ui/renderers/` AND `src/ui/native/`, not just `src/ui/views/`.

## Per-deliverable evidence

### Deliverable 8 — Class C re-audit (FIRST per brief §5 step 2)

Scanned all 9 Class C intents against `src/ui/renderers/`, `src/ui/native/`, `src/ui/`.

| Intent | Verdict | Action |
|---|---|---|
| `:share_link` | **SHIPPED** | Upgrade `missing` → `shipped` with 10 source citations. |
| `:copyable` | MISSING | Leave as `missing` (zero `UIPasteboard` / `NSPasteboard` / `ClipboardManager`). |
| `:paste_button` | MISSING | Same. |
| `:authorization_request` | MISSING | Leave as `missing` (zero `AVCaptureDevice.requestAccess` / `PHPhotoLibrary` / `CLLocationManager`). |
| `:open_url` | MISSING | Leave as `missing` (zero `openURL:` / `NSWorkspace.open` / `Intent.ACTION_VIEW`). |
| `:on_open_url` | MISSING | Leave as `missing` (zero `application:openURL:options:`). |
| `:ui_print_interaction_controller` | MISSING | Leave as `missing` (zero `UIPrintInteractionController` / `NSPrintInfo`). |
| `:file_importer` | MISSING | Leave as `missing` (zero `UIDocumentPickerViewController` / `NSOpenPanel`). |
| `:file_exporter` | MISSING | Leave as `missing` (zero `NSSavePanel` / `UIDocumentInteractionController`). |

Re-audit evidence: `handoff/phase-10-pre-1-class-c-reaudit-2026-05-25.md`.

**Final Class C tally:** 1/9 shipped, 8/9 honestly missing. The 2026-05-25 correction is now upstream of the catalog row.

### Deliverable 1 — Lint extension (`scripts/lint_intent_catalog.cr`)

New rule: every `coverage_today` value other than `missing` / `catalog_only` / `deferred` MUST contain a citation matching `src/.../foo.{cr,m,c,h,swift}:N` or `:N-M`. Vague phrases ("some views", "most renderers", etc.) are rejected unless cited. Multi-clause values (`partial (cite A); macOS uses ... (cite B)`) are accepted because at least one segment matches the citation pattern.

Implementation refinement (own commit `16a3394c`): the rule splits on `# was:` before testing, so audit-history notes like `missing # was: partial (some views ...)` are accepted — the AUTHORITATIVE classification is the leading token, and the history portion is informational.

### Deliverable 2 — `intent-catalog.md`

31 specific row corrections shipped. Notable changes:

| Row | Before | After (excerpt) |
|---|---|---|
| `:swipe_actions` | shipped on iOS/iPadOS/web | partial on iOS/iPadOS/web (swipe_action_row.cr:64-65; uikit:3823-3870; web:2887-2911); macOS inline degradation (appkit:3819-3826); Android STUB (android:3148-3152) |
| `:accessibility_label` | shipped (no cite) | shipped (src/ui/view.cr:132) |
| `:accessibility_hint` | partial (some views) | missing # was: partial — zero views expose it (B-037) |
| `:accessibility_value` | partial | missing # was: partial — zero views (B-037) |
| `:tap_gesture` | shipped (`view.on_tap = ...`) | partial — on Button/IconButton/LinkButton/SwipeAction only; NOT on base UI::View |
| **`:share_link`** | **missing** | **shipped (10 citations across uikit/appkit/android renderers + objc_bridge.m + android_bridge.c)** |
| `:toolbar_item_placement` | partial | missing # was: partial — no placement field on ToolbarItem record |

Where the freshness audit flagged a Class D `crystal_api_shape` as wrong, the field was left alone and a `# pending 10-pre.2 rename audit` marker was added on the same line. Affected rows: `:list`, `:list_row_separator`, `:sheet`, `:toolbar`, `:toolbar_item`, `:menu_picker_style`, `:menu`, `:context_menu`. 10-pre.2 will sweep these.

### Deliverable 3 — `intent-routing-candidates.md` capability block trim

**Active capabilities (7) — backed by source today:**

- `supports_edge :leading, web_only: true` (web_renderer.cr:2909-2911)
- `supports_edge :trailing` (swipe_action_row.cr:65; uikit:3851-3860; appkit:3819-3826; web:2905-2907)
- `supports_role :default` (swipe_action_row.cr:21,34)
- `supports_role :destructive, partial: true` (iOS + web only — AppKit drops)
- `requires_visible_or_keyboard_alternative true, enforced: false` (Phase 10A LSP)
- `supports_voice_control_labels partial: true` (iOS + web only — AppKit no label)
- `supports_switch_control_activation partial: true` (web focusable; native default)
- `does_not_conflict_with_system_gestures true, verified_at: :runtime` (Phase 10D)

That's 8 active (one is the runtime-only invariant). Of the original 12, 5 were moved to "Planned (Phase 10B targets)":

- `supports_disabled_actions` (10B.1b)
- `requires_row_identity_dispatch` (10B.1b)
- `requires_accessibility_custom_actions` (10B.2b)
- `supports_voiceover_actions` (10B.2b)
- `supports_edge :leading` (native) (10B.1b)
- `supports_role :destructive` (full) (10B.1b/c)

The keystone Class A contract is now honest about today's surface while preserving design intent.

### Deliverable 4 — `widget-intent-mapping.md`

All 82 rows now carry an explicit source citation in the Reason column. `activity_view.cr` STAYS Class C with the four renderer-bridge citations (Codex's catch on brief v1 preserved). `swipe_action_row.cr` Gaps column updated to reflect 10B.1a/b/c assignments: B-001 (P0), B-002 (P0), B-035, B-036 (P0). Class breakdown unchanged: 1 A + 0 B + 1 C + 80 D = 82.

### Deliverable 5 — `translation-matrix.md`

`UI::InlineActionRow` rows marked `MISSING — see backlog B-001 / B-002 (P0)` with explicit citations to where `UI::SwipeActionRow` currently fills the gap. iOS/iPadOS/web_narrow rows now carry trailing-edge-only honesty. Android row cites the stub at `android_renderer.cr:3148-3152`. Tally updated: 2/6 shipped, 1/6 partial, 2/6 MISSING, 1/6 fallback — replacing the previous "3/6 shipped" overcount.

### Deliverable 6 — `intent-backlog.md`

Reconciled count: 36 active (was 34 — the original Class A row missed B-035 in the tally). Priority changes:

| ID | Change | Reason |
|---|---|---|
| B-001 | P1 → **P0** | UI::InlineActionRow macOS default missing — keystone Class A intent advertises non-existent class |
| B-002 | P1 → **P0** | same for web_wide |
| B-020 | P0 confirmed | HIG-mandated for swipe-action rows |
| B-035 | P1 confirmed | Android Material 3 SwipeToDismissBox deferred to 10B.1c |
| **B-026** | **CLOSED** | `:share_link` SHIPPED — Codex catch + Class C re-audit verified renderer-bridge wiring |
| **B-036** | **NEW P0** | `:swipe_actions` capability honesty bundle (10B.1b) |
| **B-037** | **NEW P0** | accessibility_hint + accessibility_value surfacing (10B.2a) — supersedes deprecated B-021 |

P0 total: 5 (was 1). Top of backlog now reads "Frozen 2026-05-25 by Phase 10-pre.1."

### Deliverable 7 — This document.

### Deliverable 8 — See above (run first).

## Lint output before / after

```
# BEFORE (against catalog as committed on phase-10)
$ crystal run scripts/lint_intent_catalog.cr
FAIL
Validated 92 entries; found 31 violation(s):
  - [:swipe_actions @ line 22] coverage_today value lacks required source citation ...
  - [:accessibility_label @ line 41] coverage_today value lacks required source citation ...
  - [:accessibility_hint @ line 56] coverage_today value lacks required source citation ...
  - [:accessibility_hint @ line 56] coverage_today uses vague phrase "some views" without backing citation ...
  ... (27 more)

# AFTER (on phase-10-pre-1 tip)
$ crystal run scripts/lint_intent_catalog.cr
PASS
Validated 92 catalog entries against the schema in brief-9.md §3.
```

**Lint violations: 31 → 0.**

(Note: the lint parses **92 entries**, not the 67 cited in the brief. The catalog has grown since the Phase 9 close baseline. No new intents were added by 10-pre.1 — `git diff phase-10..HEAD -- intent-catalog.md` shows only modifications, no insertions of new `### \`:name\`` headers. The 67 number in the brief is informational and stale.)

## Class C re-audit findings (summary; full detail in `phase-10-pre-1-class-c-reaudit-2026-05-25.md`)

Scan command pattern:

```bash
grep -rn "<NATIVE_API>" src/ui/renderers/ src/ui/native/ src/ui/ 2>/dev/null
```

Per-intent native APIs queried (sourced from brief §4 Deliverable 8 table):

```bash
# :share_link
grep -rn "UIActivityViewController\|NSSharingServicePicker\|uiactivityview_present\|nssharingservicepicker_present\|android_context_start_share_chooser\|Intent.ACTION_SEND" src/ui/renderers/ src/ui/native/ src/ui/

# :copyable / :paste_button
grep -rn "UIPasteboard\|NSPasteboard\|ClipboardManager\|clipboard" src/ui/renderers/ src/ui/native/ src/ui/

# :authorization_request
grep -rn "AVCaptureDevice\|PHPhotoLibrary\|CLLocationManager\|Manifest.permission\|requestAccess" src/ui/renderers/ src/ui/native/ src/ui/

# :open_url
grep -rn "openURL:\|UIApplication.shared.open\|NSWorkspace.open\|Intent.ACTION_VIEW" src/ui/renderers/ src/ui/native/ src/ui/

# :on_open_url
grep -rn "application:openURL:options:\|application:continueUserActivity\|intent.*filter\|onOpenURL" src/ui/renderers/ src/ui/native/ src/ui/

# :ui_print_interaction_controller
grep -rn "UIPrintInteractionController\|NSPrintInfo\|PrintHelper" src/ui/renderers/ src/ui/native/ src/ui/

# :file_importer
grep -rn "UIDocumentPickerViewController\|UIDocumentPicker\|NSOpenPanel" src/ui/renderers/ src/ui/native/ src/ui/

# :file_exporter
grep -rn "NSSavePanel\|UIDocumentInteractionController\|fileExporter" src/ui/renderers/ src/ui/native/ src/ui/
```

**Key finding (preserved as methodology):** `src/ui/renderers/` was THE directory the original freshness audit missed. The bridge wiring lives there — both Crystal `fun ...` lib declarations AND the `LibObjCBridge.foo(...)` / `LibAndroidBridge.foo(...)` invocation sites. Future re-audits MUST grep that directory or they will repeat the `:share_link` false-negative.

Notes carried through:

- `:authorization_request` — notifications-authorization code exists at `src/ui/native/objc_bridge.m:2268-2297` (`ap_notifications_request_authorization` calling `UNAuthorizationOptions`), but notifications are Class E "system experiences" per the catalog preamble (line 11) — out of Phase 9 catalog scope. The `:authorization_request` Class C intent points at AVFoundation / Photos / CoreLocation, which is honestly missing.

- `:open_url` — `link_button.cr` emits `<a href=...>` on web; that is HTML emission inside one view, not a cross-platform `UI::System.open_url(...)` bridge. Class C verdict stands.

## Audit-scope command record (for future re-audits)

The discipline this audit established, captured for any future audit prompt:

```bash
# REQUIRED grep scope for any "is intent X shipped?" check:
#   - src/ui/views/        (where most view files live)
#   - src/ui/renderers/    (where the visit(view) wiring + LibObjCBridge / LibAndroidBridge dispatch lives — THE most-commonly-missed directory)
#   - src/ui/native/       (where the C / ObjC / JNI implementations live; .cr, .m, .c)
#   - src/ui/              (top-level helpers: notifications, app_shortcuts, etc.; Class E surface)
#   - src/asset_pipeline/  (cross-platform helpers, integrations)

# Generic per-API query:
grep -rn "<NATIVE_API_NAME>" src/ui/renderers/ src/ui/native/ src/ui/ src/asset_pipeline/ 2>/dev/null
```

## Catalog changes summary

- **31 rows** updated with citations (lint-driven work list).
- **3 rows** downgraded from a false `partial` to `missing # was: partial`: `:accessibility_hint`, `:accessibility_value`, `:toolbar_item_placement`.
- **1 row** upgraded from a false `missing` to `shipped`: `:share_link` (B-026 closed).
- **8 Class D rows** carry a `# pending 10-pre.2 rename audit` marker because the freshness audit flagged the `crystal_api_shape` field; 10-pre.1 left the shape strings alone per scope.

## Backlog reconciliation summary

- Final count: **36 active**.
- Priority distribution: P0 = 5, P1 = 13, P2 = 18.
- Added: **B-036** (P0), **B-037** (P0).
- Closed: **B-026** (`:share_link` shipped).
- Deprecated: **B-021** (superseded by B-037; kept in numbering for ID-history continuity).
- Promoted: **B-001**, **B-002** → P0.

## Capability block trim

- Active capabilities reduced from 12 to 8 (7 explicit + 1 runtime-only).
- 5 unbacked capabilities moved to "Planned (Phase 10B targets)" with explicit phase-slice attributions (10B.1b for disabled / row-identity / leading-edge / destructive native; 10B.2b for accessibility custom actions + VoiceOver actions).

## Anything surfaced beyond 10-pre.1 scope

- **Catalog has 92 entries, not 67.** Brief §3 says "the 67 catalog rows stay 67." 10-pre.1 did NOT add any entries — `git diff phase-10..HEAD` shows zero new `### \`:` headers in the catalog. The 67 number in the brief is stale; the catalog grew between Phase 9 close and brief drafting. **Surface to architect:** confirm whether the 92 count is correct or whether the catalog needs a separate audit of when/how it grew. This is a numbering question, not a content question.
- **8 Class D rows have wrong `crystal_api_shape` strings** per the freshness audit (`:list`, `:list_row_separator`, `:sheet`, `:toolbar`, `:toolbar_item`, `:menu_picker_style`, `:menu`, `:context_menu`). Each row now carries a `# pending 10-pre.2 rename audit` marker. 10-pre.2 will sweep these.
- **`PickerStyle::Palette` enum value is undefined** (per the freshness audit). 10-pre.1 did not add it because that would be a `src/` change. Catalog row `:palette_picker_style` remains honestly `missing`. Tracked under B-012.
- **`tier-matrix.md` does not list `swipe_action_row.cr`** (called out in widget-intent-mapping.md Summary). 10-pre.1 did not edit `tier-matrix.md` (out of brief scope). **Surface to architect:** may want a separate one-line tier-matrix freshness pass.

## Branch state

```
$ git log --oneline phase-10..HEAD
f0f5a9f3 [Phase 10-pre.1] Reconcile backlog; B-026 closed; B-036, B-037 added P0
fb7e7b04 [Phase 10-pre.1] translation-matrix.md UI::InlineActionRow MISSING markers
fdf30e54 [Phase 10-pre.1] widget-intent-mapping.md per-row citations; activity_view.cr stays Class C
1b79cf41 [Phase 10-pre.1] Trim :swipe_actions capability block; add Planned section
09754e47 [Phase 10-pre.1] Correct intent-catalog.md coverage_today claims with citations
16a3394c [Phase 10-pre.1] Lint: strip "# was:" history note before citation check
b97dfc58 [Phase 10-pre.1] Add citation-presence check to lint_intent_catalog.cr
dc3ff793 [Phase 10-pre.1] Class C re-audit; confirm :share_link shipped, others missing
```

**Branch:** `phase-10-pre-1`
**Base:** `phase-10`
**Commits:** 8 incremental + this close handoff (9 total).
**Lint:** PASS (0 violations, was 31).

## Codex content review (iter 1)

**Verdict:** REVISE — 2 HIGH + 2 MEDIUM + 1 LOW. Source log: `/tmp/codex-content-review-10-pre-1.log` (~4050 lines).

- HIGH-1: catalog footer reported "67 intents" but actual A=1/B=18/C=9/D=64 = 92 schema entries.
- HIGH-2: backlog count language inconsistent (36 vs 34 with B-021 deprecated + B-026 closed).
- MEDIUM-1: `:share_link` web coverage uncited.
- MEDIUM-2: catalog `:tap_gesture` row referenced `src/ui/view.cr` without line number.
- LOW-1: Planned capability count drift (5 vs 6).

## Independent re-audit (parallel to Codex)

**Verdict:** APPROVE_WITH_NOTES — fresh agent, no prior context, full audit-scope discipline. Report at `phase-10-pre-1-independent-reaudit.md`.

- Two material notes:
  - `:authorization_request` is actually `partial` via `UI::Notifications.request_authorization` (`src/ui/notifications.cr:456` → `src/ui/native/objc_bridge.m:2297`), not `missing`.
  - `:swipe_actions` description cited `appkit_renderer.cr:3801` (the comment) instead of `:3806` (the actual `def visit` line).
- All 15+ spot-checked rows verified; all 8 v2-correction rows confirmed correct; activity_view.cr Class C defensible; class breakdown math verified; citation format clean; cross-document consistency PASS.

## Iteration 2 remediation (commit `328493b1`)

All 7 findings (5 Codex + 2 re-audit) applied atomically. Per-correction summary in the iter 2 commit message; verified post-commit via grep that every fix is in place; lint still PASSes 92 entries.

## Acceptance gate (final)

- ✅ `crystal run scripts/lint_intent_catalog.cr` exits 0 (PASS, 92 entries) — confirmed post-iter-2.
- ✅ Independent re-audit verdict: APPROVE_WITH_NOTES — both notes addressed in iter 2.
- ✅ Codex content review verdict: REVISE iter 1 → all 5 findings addressed in iter 2.
- ✅ All 8 deliverables shipped via incremental commits.
- ✅ This handoff records both verifications + iter 2 remediation.

**Final HEAD:** `328493b1`
**Branch:** `phase-10-pre-1`
**Commits vs phase-10:** 11 (iter 1: 9 deliverables + close; 10-pre.2 brief draft; iter 2 remediation).

— Phase 10-pre.1 implementer (iter 1) + architect remediation (iter 2), Claude Opus 4.7, 2026-05-25.
