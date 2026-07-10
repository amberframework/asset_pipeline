# Phase 10-pre.1 — Architect Reflection

**Sub-phase:** 10-pre.1 — Factual catalog correction.
**Date closed:** 2026-05-25.
**Final HEAD:** `328493b1`
**Tag:** `phase-10-pre.1-pass-2026-05-25`.
**Verdict:** PASS (after iter 2 remediation).

## What shipped

10-pre.1 made the intent catalog factually honest about today's framework. Specifically:

- `coverage_today` field on every catalog row now cites source OR is honestly `missing`.
- 31 lint violations → 0.
- 3 rows downgraded from false `partial`/`shipped` → `missing` (`:accessibility_hint`, `:accessibility_value`, `:toolbar_item_placement`).
- 1 row upgraded from false `missing` → `shipped` (`:share_link` — the Codex catch).
- 1 row upgraded `missing` → `partial` (`:authorization_request` — notifications-auth shipped).
- `:swipe_actions` capability block trimmed 12 → 7 active capabilities; 6 moved to Planned (Phase 10B targets).
- `widget-intent-mapping.md` rewritten with per-row citations; `activity_view.cr` correctly stays Class C with renderer-bridge citations.
- Backlog reconciled: 36 tracked (34 active); B-026 closed; B-036 + B-037 added P0; B-001/B-002 promoted P0.
- Lint script extended with citation-presence check that mandates `src/...:N` or `src/...:N-M` for every non-`missing` `coverage_today` value.
- Audit-scope discipline established: every future audit must scan `src/ui/renderers/` + `src/ui/native/` in addition to `src/ui/views/`.

## Numbers

- 11 commits on `phase-10-pre-1`.
- 4 documents corrected + 1 lint script extended + 2 new handoff docs.
- 92 schema-validated catalog entries (corrected footer math distinguishes 92 entries from 67 top-level concepts).
- Verification: 1 independent re-audit + 1 Codex content review = 2 parallel passes. Iter 1 → iter 2 remediation closed all findings.

## Lessons (banked as memories)

### 1. Audit-scope discipline (`[[audit-scope-discipline]]`)

The original freshness check claimed Class C was 0/9 realized because it scanned only `src/ui/views/activity_view.cr` doc comments + `src/asset_pipeline/`. It missed the renderer-side bridge wiring in `src/ui/renderers/uikit_renderer.cr:3408`, `appkit_renderer.cr:3417`, `android_renderer.cr:2871`, and `src/ui/native/objc_bridge.m:2148-2245`. Codex caught the error when reviewing the 10-pre.1 brief that proposed reclassifying `activity_view.cr` to Class D based on the false audit.

**Lesson:** framework-coverage audits must scan renderers + native bridges, not just view files. Future audit prompts MUST list `src/ui/renderers/` and `src/ui/native/` explicitly.

### 2. Codex background stdin trap (`[[codex-background-stdin-trap]]`)

The Codex content review run got stuck for ~15 minutes at 0% CPU because `codex exec` via `Bash run_in_background` saw stdin as piped (from the `2>&1 | tee` pipeline) and blocked waiting for stdin EOF. Killed and re-launched with `< /dev/null` redirect — completed normally in ~3 minutes.

**Lesson:** every `codex exec` via background Bash needs explicit `< /dev/null` to close stdin.

### 3. Audits have their own audit problem

The 10-pre.1 brief v1 trusted the freshness check as input. The freshness check itself had a false-negative. Codex's antagonist pass on the brief caught it — which is exactly the multi-layer-review pattern `[[codex-as-architect-antagonist]]` is for. Without that pass, 10-pre.1 would have shipped a reclassification of `activity_view.cr` to Class D, falsifying the catalog in the OPPOSITE direction from the audit's claim.

**Lesson:** an audit being "comprehensive" doesn't mean its conclusions are correct. The antagonist's job is to find the load-bearing errors that the implementer would otherwise propagate. Apply Codex to the BRIEF, not just the implementation.

### 4. Iter 1 → iter 2 remediation is the normal pattern

Codex returned REVISE on iter 1. Five concrete findings; all mechanical fixes. The remediation took ~3 minutes (one dispatched sub-agent doing 7 small edits). The remediation discipline is healthy: don't bristle at REVISE, accept the findings, fix them precisely, verify with the same antagonist pattern, close.

What got tested for the first time on this sub-phase: the **parallel verification pattern** (independent re-audit + Codex content review running concurrently). Both passed cleanly with non-overlapping findings, validating that each catches things the other doesn't. Re-audit caught factual notes about specific rows; Codex caught structural/discipline notes about counts + language. Together they covered the catalog more thoroughly than either alone.

## Process notes for 10-pre.2

- 10-pre.2 brief v1 already drafted on this branch (commit `31c7e660`).
- It carries forward when phase-10-pre-1 merges to phase-10.
- 10-pre.2 will need its own Codex antagonist pass on the brief (per `[[codex-as-architect-antagonist]]`) before dispatch.
- Catalog state at 10-pre.2 start: every `coverage_today` is honest; every Class D row's `crystal_api_shape` still carries Phase 9-era claims (some accurate, some wrong per the freshness audit's spot-check of 12 rows where 9 were wrong).
- 10-pre.2 expected duration: 2 implementer iterations (~3-4 days). Slightly larger scope than 10-pre.1 because the full 40 Class D rows need verification, not just spot-check.

## Open items carried forward

- **Catalog footer math now accurate** (92 entries / 67 concepts).
- **`PickerStyle::Palette` enum gap** flagged in 10-pre.1 — out of 10-pre.1 scope; defer to 10B (specifically B-012 picker styles).
- **`tier-matrix.md` staleness** (omits `swipe_action_row.cr`) — Phase 9 carried forward; defer to 10A.0 cleanup if convenient or leave to 10D Voyager work.

## Next

1. ✅ Tag `phase-10-pre.1-pass-2026-05-25`.
2. ✅ Fast-forward merge `phase-10-pre-1` → `phase-10`.
3. ⏭ Dispatch Codex antagonist on 10-pre.2 brief v1.
4. ⏭ Reconcile findings into brief v2.
5. ⏭ Dispatch 10-pre.2 implementer.

— Architect (Claude Opus 4.7)
