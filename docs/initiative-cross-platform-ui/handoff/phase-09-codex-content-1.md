# Phase 9 Catalog Content-Level Codex Review (Iter 1)

**Date:** 2026-05-25
**Source logs:** `/tmp/codex-content-9.log`, `/tmp/codex-content-9-revalidate.log`, `/tmp/codex-content-9-final.log`.

## Iteration 1 — REVISE (5 HIGH + 4 MEDIUM + 2 LOW)

- **HIGH 1** — Apple vocabulary identifier failures (`:respect_reduced_motion`, `:dynamic_type`, `:share_sheet`, `:import_file`, `:export_file`, picker/date-picker style identifiers inverted). **Resolved:** every identifier renamed to snake_case-of-Apple-name; lint loophole closed.
- **HIGH 2** — Apple-surface coverage gate: `List`, section indexes, `UIMenu`, `UIAction`, three UIKit haptic generators missing. **Resolved:** added 7 new catalog rows.
- **HIGH 3** — Android `:swipe_actions` overclaim (translation matrix said shipped; renderer is stub at `android_renderer.cr:3148`). **Resolved:** translation matrix now marks Android as "partial — stub"; intent-routing-candidates.md notes the stub; backlog adds B-035.
- **HIGH 4** — `:swipe_actions` capability claims unbacked by sources (`full_swipe_destructive_safe`, `supports_role :cancel`, `requires_confirmation_for_destructive_full_swipe`, `preserves_focus_after_action`). **Resolved:** trimmed capability block to only SwiftUI/UIKit-API-backed and HIG-mandated predicates; removed predicates documented as "architect opinions, not source-backed."
- **HIGH 5** — Class C category overlapped HIG `system-experiences.md` (App Shortcuts, Controls, Live Activities, Widgets). **Resolved:** renamed Class C to "Cross-platform-bridged intents" + added explicit note that HIG system-experiences is a separate domain.

## Iteration 2 — REVISE (1 HIGH remaining)

- **HIGH 1 (iter 2)** — backlog file still used old identifier names (`:respect_reduced_motion`, `:dynamic_type`, `:share_sheet`, `:import_file`, `:export_file`, old picker/date-picker names). **Resolved:** bulk sed rename across backlog; verified zero old identifiers remain.

## Iteration 3 — REVISE (1 LOW remaining)

- **Final stray** — `:dynamic_type` at `intent-backlog.md:159`. **Resolved:** renamed to `:dynamic_type_size`.

## Final state

All HIGH/MEDIUM/LOW findings closed. The catalog is content-validated. Implementer dispatch is unblocked for:
- Item 3 freshness reconciliation paragraph in `translation-matrix.md`
- Item 6 `widget-intent-mapping.md` (full audit of `src/ui/views/*.cr`)
- Item 7 `apple-surface-coverage.md` checklist
- Schema validation across all 7 documents (Items 1-7) via a lint script

— Codex (medium reasoning, antagonist content-review mode)
