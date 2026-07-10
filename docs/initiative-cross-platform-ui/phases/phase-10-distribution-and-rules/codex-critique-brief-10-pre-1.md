# Codex Antagonist on 10-pre.1 Brief v1

**Date:** 2026-05-25
**Codex:** medium reasoning, default model.
**Source log:** `/tmp/codex-brief-10-pre-1.log` (2882 lines).
**Verdict:** v1 had two load-bearing issues, both adopted into v2.

---

## Codex iteration on v1

Codex ran a partial pass — it dug deep enough to surface two critical findings before its session terminated (clean exit code 0 but no final structured verdict block). The findings are concrete and adoptable.

## Finding 1 — Brief contradiction

> "The brief says 'no new backlog items,' while both scoping and deliverable text allow or require B-036/B-037."

Codex caught a direct contradiction between v1 §3 Constraints (`No new backlog items.`) and v1 §4 Deliverable 6 (`add as B-036... add as B-037`).

**Resolution adopted in v2:** §3 explicitly carves out B-036 and B-037 BY NAME as the only permitted additions. No other new backlog entries allowed. Updated constraint wording:

> **NEW backlog items allowed BY NAME only.** You may add **B-036** (`:swipe_actions` capability honesty work — references 10B.1b slice) and **B-037** (`accessibility_hint` + `accessibility_value` surfacing — references 10B.2a slice). No other new B-NNN entries.

## Finding 2 — Activity view reclassification was WRONG

> "One more material issue surfaced: the audit's `activity_view.cr` conclusion appears stale against the current checkout. The current renderers and native bridges do call `UIActivityViewController`, `NSSharingServicePicker`, and Android share chooser paths, so the brief's forced Class C-to-D move is not just debatable, it may be wrong."

Codex read the renderer files and the ObjC bridge and proved that `UI::ActivityView` IS wired to native sharing APIs:

- `src/ui/renderers/uikit_renderer.cr:3408` — `LibObjCBridge.uiactivityview_present(...)` → UIActivityViewController.
- `src/ui/renderers/appkit_renderer.cr:3417` — `LibObjCBridge.nssharingservicepicker_present(...)` → NSSharingServicePicker.
- `src/ui/renderers/android_renderer.cr:2871` — `LibAndroidBridge.android_context_start_share_chooser(...)` → Intent.ACTION_SEND.
- `src/ui/native/objc_bridge.m:2148-2245` — actual ObjC implementations.

The freshness check (`phase-10-pre-catalog-freshness-2026-05-25.md`) was wrong about Class C being 0/9 realized — it only scanned `src/ui/views/activity_view.cr` doc comments + `src/asset_pipeline/`. It missed the renderer-side bridge wiring entirely. Verified by architect post-Codex: `:share_link` is the ONLY Class C intent shipped (the other 8 are honestly missing — verified by grep across `src/ui/renderers/`, `src/ui/native/`, `src/ui/`).

**Resolutions adopted in v2:**

1. **Reverse the reclassification.** `activity_view.cr` STAYS Class C. Its `widget-intent-mapping.md` row gets renderer-bridge citations.
2. **Upgrade catalog row for `:share_link` from `missing` to `shipped`** with full citations (uikit_renderer.cr:3408 + appkit_renderer.cr:3417 + android_renderer.cr:2871 + objc_bridge.m:2148-2245).
3. **Class C re-audit (NEW Deliverable 8).** Verify the OTHER 8 Class C intents against renderers + native bridges, not just view files. Document the scan command used.
4. **Audit-scope discipline rule** added to §3 Constraints: every `coverage_today: shipped` claim verification MUST scan renderers + native bridges.
5. **Correction note appended to `phase-10-pre-catalog-freshness-2026-05-25.md`** documenting the false-negative and the methodological fix.
6. **B-026 (`:share_link`) closed/removed from backlog** in v2's Deliverable 6 (since the intent is shipped, not buildable backlog work).
7. **New memory** `[[audit-scope-discipline]]` saved to prevent recurrence.

## Architect reflection

The original freshness check (which I trusted as 10-pre.1's input) had its own accuracy problem — same shape as `[[audit-shortcut-trap]]`. The audit prompt I gave the general-purpose agent didn't explicitly include `src/ui/renderers/` or `src/ui/native/` in scope. Codex's brief antagonist caught it.

Process lessons:
- The audit-then-correct loop has its own audit problem. The corrector (10-pre.1 implementer) needs scope discipline that the auditor didn't have.
- Codex as antagonist on the BRIEF can surface flaws in the AUDIT that the brief consumed — even though the brief isn't the audit's job. This is exactly the kind of orthogonal critique [[codex-as-architect-antagonist]] is for.
- v2 brief explicitly inherits the audit-scope-discipline lesson so the implementer doesn't repeat the failure mode.

## Verdict on v2

v2 is dispatch-ready. v2 changes are mechanically derived from Codex's findings + the verified facts about `:share_link`. No further Codex round needed before implementer dispatch — the corrections are concrete and verifiable.

Architect proceeds to implementer dispatch.

— Architect (Claude Opus 4.7)
