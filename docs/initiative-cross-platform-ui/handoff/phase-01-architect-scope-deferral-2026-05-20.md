# Phase 1 — Architect scope deferral (Android generator)

**Date:** 2026-05-20
**Decided by:** Project owner (Seth) at architect checkpoint #1, in response to flagged inconsistency between `origin.md` and the formal Phase 1 docs.
**Effect:** Android generator + Android XML dist artifacts + Android renderer literal-scrub are removed from Phase 1 scope. They will be carved into a follow-up phase (or a Phase 4/5 addendum) to be defined later.

---

## Why

`origin.md` Prompt 1 frames the proof as "web (desktop + mobile) ↔ iOS ↔ macOS, side-by-side, same brand." The MASTER_PLAN's North Star agrees (Phase 6's quad-comparison excludes Android, "consistent with prioritization"). Phase 1 as originally written shipped a full `AndroidGenerator`, four committed XML dist artifacts, an Android-no-hardcoded renderer scrub, and a colors/dimens/themes XML well-formed check.

That Android plumbing is real work — voluminous, and not load-bearing for any of the three platforms named in the origin's proof. Carving it out tightens Phase 1's blast radius without giving up the unified-token contract that downstream phases need. Android renderers continue to work against the legacy `UI::Theme` adapter; they will be migrated when the deferred Android-tokens phase ships.

The audit's Top-10 fix list does not include this scope; this is a fresh architect-level decision at checkpoint #1.

## What changes in the Phase 1 docs

The architect edits the following before creating the phase-01 branch:

1. **`phases/phase-01-design-token-foundation/README.md`** — scope summary and acceptance summary updated to call out web + Apple generators only; Android generator listed under "Out of scope" with a forward pointer to this handoff note.
2. **`phases/phase-01-design-token-foundation/implementation.md`** — Section 2a's "Crystal source you create" loses the `android_generator.cr` + Android dist artifacts. Section 3 keeps the `UI::DesignTokens` model unchanged (the model is platform-agnostic; only the generator changes). The migration steps for `android_renderer.cr` are removed from this phase. The `touch_target_minimum_px` field on the `Tokens` aggregate stays — Phase 2 still needs it.
3. **`phases/phase-01-design-token-foundation/validation.md`** — checks #9 (`generator.android-deterministic`), #10 (`generator.android-well-formed`), and #14 (`renderer.android-no-hardcoded`) are removed; subsequent check numbering shifts up. The Android sample build in #17 is dropped; #20 (`cascade.android-or-ios-changes-on-brand-override`) becomes iOS-only (`cascade.ios-changes-on-brand-override`).
4. **`MASTER_PLAN.md`** — progress ledger row 1 Notes column annotated: "Android generator deferred per `handoff/phase-01-architect-scope-deferral-2026-05-20.md`."

The `UI::DesignTokens` Crystal model is **not** changed by this deferral. Android colors, dimens, motion, etc. still live in the model as data; only the *generator* and *renderer migration* are deferred. A future phase can ship the `AndroidGenerator` against the existing model without revisiting Phase 1.

## What does *not* change

- The `Brand` override surface ships as written.
- The `WebGenerator` and `AppleGenerator` ship as written.
- Cascade checks #18 (web) and #19 (macOS) are unchanged.
- The `touch_target_minimum_px` field on `Tokens` is unchanged.
- All non-Android renderer literal-scrubs (web, AppKit, UIKit) ship as written.

## Architect tolerance call (recorded for audit, not a scope change)

The validator's check #3 (`tokens.default-matches-amber`) tolerance was discussed at the same checkpoint. The original rubric specifies ΔL ≤ 0.001, Δc ≤ 0.001, Δh ≤ 0.5°, ΔRGB ≤ 1/255. The Architect, with the owner's discretion explicitly delegated, has tightened the canonical-palette portion of that tolerance to **ΔE2000 ≤ 1.0** (visual-grade) for the five canonical comparison points (`brand-primary`, `surface-canvas`, `text-primary`, `border-default`, `danger-indicator`). The original tolerance still applies to the round-trip stability check #2 (`tokens.color-roundtrip`), where the bar is implementation-grade arithmetic stability rather than visual perception.

Rationale: origin Prompt 3's "verify behavior, not just presence" directive applies most sharply to the canonical brand identity. A 0.5° hue shift on a saturated brand color is human-visible; ΔE2000 ≤ 1.0 is at the threshold of perception. The round-trip stability check, by contrast, is purely about whether the conversion math is deterministic — that bar is correctly arithmetic.

## Spirit-anchoring (per origin §How future agents should use this file)

This deferral cites origin §Prompt 1's load-bearing concept: "I should be able to look at them side by side and tell that they represent the same brand" referring to the iOS / macOS / desktop-web / mobile-web quad. Android coverage is from MASTER_PLAN's broader sweep, not from origin's load-bearing claim. Cutting Android from Phase 1 is consistent with the spirit; cutting it from any later phase that origin names explicitly (none does) would not be.
