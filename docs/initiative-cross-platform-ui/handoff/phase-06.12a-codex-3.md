# Phase 6.12A — Codex review iteration 3 (Items 3, 4, 5)

**Date:** 2026-05-24
**Commits reviewed:** `9f5d02f` (Item 3) + `723c037` (Items 4 + 5)
**Reviewer:** Codex (codex-cli 0.130.0)
**Verdict:** **NEEDS_WORK** (doc-only findings; structural work landed cleanly)
**Follow-up commit:** `3b63f03` — closes both doc findings.

## Codex transcript (key excerpts)

**Verdict: NEEDS_WORK**

**Findings:**

1. Item 5 audit doc is not complete enough for PASS. The brief requires each amber-equivalent finding to be pivoted or justified ([brief.md:318](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md), [brief.md:327](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md)). The doc dispositions surface/border/warning well, but generated dark tokens still include warm-hue `surface_inverse`, `text_primary`, `text_secondary`, and `text_muted` ([web_tokens.css:197/201](../../../src/ui/design_tokens/dist/web_tokens.css)) and the doc only lists `text_inverse` / broad surface coverage. Add explicit disposition for those low-chroma text roles.

2. The audit doc has factual drift: it says the regenerator "now reports 6 sentinel roles" while the pasted diagnostic shows 8 roles. Also, the brief's literal `amber|orange|tan|peach` grep is not actually zero because `instant` matches `tan`; that should be documented as a false positive or the grep refined.

**Closed Checks:**

1. PASS. `hig_create_window` is still present with the old signature; `hig_create_window_with_min` is added separately. Cascade still declares/calls only the old helper.

2. PASS. Voyager passes `Pointer(UInt8).null` when no appearance env var is set, and the helper only calls `setAppearance` inside `if (appearance_name)`.

3. PROGRESS. The web grep proves Cascade web token preservation: deep teal is emitted in generated HTML. It does not prove native prominent-button pixels. Given the hard 6.12B capture split, I would defer pixel sampling, but do not call Item 4 fully proven from grep alone.

4. PASS. No specs or renderer paths depending on `border_focus` as a concrete amber token. Component specs assert the CSS variable, not the literal color.

5. PARTIAL. The surface/border/warning justifications hold: low chroma neutrals and semantic warning are valid non-brand dispositions. The missing text-role dispositions still need cleanup.

6. PASS. No new `NSLog` / `STDERR.puts` / `voyager-save-chain` / `voyager-interaction-proof` entries were introduced by these commits. The regenerator `STDERR.puts` diagnostic is intentional; the existing `window_helper.m` `NSLog` predates this work.

## Implementer disposition

Both findings are doc-only — no code changes required to close them. Commit `3b63f03` updates the audit doc:

### Finding 1 — missing text-role dispositions

Added explicit rows in the OKLCH-amber-hue-range table for:

- `text_primary` (light + dark) — dark mode `oklch(0.95 0.006 80)` has chroma 0.006 (sub-perceptual); reads as off-white biased toward the warm side, matching legacy AppKit `labelColor`. **KEEP.**
- `text_secondary` (light + dark) — dark `oklch(0.78 0.015 85)`, chroma 0.015, warm-grey neutral. **KEEP.**
- `text_muted` (light + dark) — dark `oklch(0.65 0.018 85)`, same family one notch dimmer. **KEEP.**
- `surface_inverse` (dark only — it's an unused field in the light palette in this audit) — dark `oklch(0.95 0.006 80)`, matches dark `text_primary` literally. **KEEP.**

All four follow the same chroma-near-zero warm-grey neutral justification already documented for the surface family.

### Finding 2 — factual drift + `tan` false positive

- Corrected the role count from "6" to "8" in the regenerator-output paragraph.
- Documented the `tan` substring false positives (`instant`, `standard`, `important`) — verified by `grep -rEw "tan" ...` returning zero word-boundary matches.

### Finding 3 (Item 4 — Cascade pixel sample) — already-deferred to 6.12B

Codex explicitly defers pixel sampling to 6.12B per the brief's hard scope split (brief line 392). The web grep proof is the structural verification at the Phase 6.12A boundary; the native pixel sample is the owner hand-test at 6.12B end.

## Acceptance vs. brief Items 3-5

| Brief acceptance | Status |
|------------------|--------|
| Item 3 — `osascript` window-bounds probe | DEFERRED to 6.12B (System Events TCC permission unavailable in this iteration; the API-layer proof is the explicit `setContentMinSize` C call + 880/640 constants) |
| Item 3 — resize to 1280×800 honoured | API-PROOF — `NSWindowStyleMaskResizable` set; no runtime probe ran |
| Item 3 — resize to 200×200 clamps to 480×400 | API-PROOF — `setContentMinSize:NSMakeSize(min_w, min_h)` set in code |
| Item 3 — 3 macOS resize screenshots | 6.12B scope per brief hard rule (architect explicitly carves the 44 captures out of 6.12A) |
| Item 3 — dark mode honoured | API-PROOF — appearance pin honoured when env set, system follow otherwise |
| Item 4 — Cascade web emits deep teal | PASS — grep verified `oklch(0.560 0.130 195.00)` (RGB 3 133 134) in generated HTML |
| Item 4 — Cascade macOS prominent button pixel sample | DEFERRED to 6.12B (architect-level scope split) |
| Item 4 — Cascade iOS pixel sample | DEFERRED to 6.12B |
| Item 4 — 0 new spec failures in Cascade-adjacent specs | PASS — 1529/4/0/66 preserved |
| Item 5 — audit doc committed | PASS — `handoff/phase-06.12a-no-amber-audit.md` (with iter-3 doc fixes) |
| Item 5 — every finding pivoted or justified | PASS post-fix — all roles dispositioned |

## Next step

Implementer report at `handoff/phase-06.12a-implementer-report.md` (brief lines 383-387). Then hand off to architect for branch merge.
