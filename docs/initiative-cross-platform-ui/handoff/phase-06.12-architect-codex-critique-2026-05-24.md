# Phase 6.12A — Architect-side Codex Critique Trail

**Date:** 2026-05-24
**Per directive:** `[[codex-as-architect-antagonist]]` — Codex critique applied to architect-authored briefs before Implementer dispatch.

This file preserves the trail of Codex antagonist reviews against the Phase 6.12A brief BEFORE dispatch.

## Review 1: brief revision 1

**Verdict:** REVISE

**Findings (5):**

1. **Scope right-sizing:** Too large. Code pivot + 3 renderer paths + macOS host polish + Cascade preservation + 44 evidence captures + 2 audits was one phase. Should split.
2. **Hidden dependencies:** Cascade preservation must be preflighted BEFORE pivot, not after. `brand_primary` alone too narrow — the brand family (primary/hover/active/link/focus + generated outputs) needed full coverage.
3. **Path C1 vs C2 framing:** C1 was correctly recommended but underspecified. Missing: sentinel API, serialization behavior, equality/debug output, generator behavior, exact renderer mapping. Web especially left to "emit/omit/system color" guess.
4. **Acceptance not objectively verifiable:** "Teal as before" / "system blue" / "resizable" — claims, not measurements.
5. **Missing:** No-amber audit across brand-family tokens + generated CSS/Swift; exact Cascade entrypoint assertions; Android deferral language; phase split.

**Architect action:** Wrote revision 2 addressing all 5 findings.

## Review 2: brief revision 2

**Verdict:** REVISE-AGAIN, narrowly.

**Per-finding status:**

- (a) Scope split: **CLOSED.** 6.12A code + 6.12B captures explicit.
- (b) Cascade preflight + brand family: **CLOSED.** Item 0 is preflight; brand_primary + hover + active all covered.
- (c) C1 sentinel framing: **PARTIALLY_CLOSED.** Sentinel samples exist but CSS serialization said `accent-color` (the CSS property) while renderer used `AccentColor` (CSS Color Level 4 keyword). Generator behavior was "must not crash" rather than concrete output contract.
- (d) Acceptance: **CLOSED.** osascript bounds + pixel-sample teal + grep audits all objective.
- (e) Missing items: **CLOSED.** No-amber audit + Cascade entrypoint assertions + Android deferral language all present.

**Architect action:** Wrote revision 3 fixing finding (c) only — corrected the CSS keyword + spelled out generated output contract for web/Swift/Android.

## Review 3: brief revision 3

**Verdict:** **APPROVE.**

**Per-finding status:**

- (c) C1 sentinel framing: **CLOSED.** `to_css` returns `AccentColor` (CSS Color Module Level 4 system keyword), distinguished from the `accent-color` property. Generated-output contract gives concrete web/Swift/Android behavior. Android's deferred path is explicit — raise, skip/log in regeneration, do not silently emit broken output.

**Architect action:** Brief approved for Implementer dispatch.

## Process notes

- Three Codex reviews, ~140k tokens total across the revisions.
- The first review took ~88k tokens (largest — investigation + 5 findings).
- The second took ~28k (just the narrow C1 inconsistency).
- The third took ~23k (verification).
- The architect-side antagonist protocol caught the CSS keyword conflation that would have produced broken web output if the Implementer had implemented the brief literally as written.
- The phase-split recommendation (6.12A code + 6.12B captures) directly addresses [[mid-stop-pattern-evidence-capture]] — codifying the split-dispatch pattern that emerged organically in Phase 6.11 iter-3 close.

— Architect (Claude Opus 4.7)
