# Phase 6.9 — Architect's Reflection — 2026-05-23

Phase 6.9 (macOS Button Inner-Rectangle Artifact) closed PASS at HEAD
`b4ba884` on `phase-06.9-macos-button-artifact`, 2 commits past the
architect handoff at `c68d36f`. Single-line fix shipped first try with
zero remediation. The cleanest dispatch in the Phase 6.x series.

## What worked

**One-line fix, one dispatch, zero remediations.** Appending
`.buttonStyle(.plain)` to the prominent case's modifier chain
suppressed SwiftUI's default Button label chrome on macOS without
affecting iOS. The Codex check after the fix returned PROGRESS; all 8
regression gates passed; the macOS sign-in baseline now shows a clean
brand-teal Capsule pill with no inner darker rectangle.

**The contrast against Phase 6's 5-cycle saga is instructive.** Phase
6 ran 1 Implementer + 5 remediation cycles trying to close 3 visual
gaps (brand-teal, macOS width, :secondary chrome), with Rem 4
actively regressing prior working state. Phase 6.8 closed those same
3 gaps in 1 Implementer dispatch (with continuation), and Phase 6.9
closed the residual macOS artifact in 1 dispatch. The difference:
**explicit Codex per-fix check + smaller dispatch scope**. When a
phase's scope is tight (1 fix, 1 file, 1 line), agents complete cleanly.

## What to carry forward

1. **Single-fix focused dispatches are the right granularity** when
   the prior work has surfaced a precise mechanism (here:
   `.buttonStyle(.plain)` to suppress default chrome on top of
   Capsule.fill). Don't bundle "while you're at it" improvements.

2. **The macOS-specific SwiftUI Button behavior is documented now.**
   SwiftUI on macOS adds default button-style chrome over a Button's
   label even when an explicit `.background` modifier is applied.
   `.buttonStyle(.plain)` suppresses that default chrome. Future
   SwiftKit work that uses custom `.background` for button chrome
   should append `.buttonStyle(.plain)` from the start.

3. **The Codex per-fix critic protocol scales DOWN well**, not just
   up. Phase 6.8 used it for 3 fixes; Phase 6.9 used it for 1 fix.
   Always-on Codex critique is now the standard for visual-polish
   work.

## Brand-litmus state across all 4 surfaces (post-Phase-6.9)

The Cascade demo sign-in screen now passes the brand-litmus test on
all 4 user-facing surfaces:
- **web-desktop:** brand-teal Forgot password link, social-row buttons,
  fluid layout
- **web-mobile:** same, reflowed to 375px single column
- **iOS sim:** brand-teal Sign-in pill, bordered social-row (clipped
  below viewport — pre-existing layout issue documented)
- **macOS host:** brand-teal Sign-in pill (clean — no inner artifact),
  brand-teal Forgot password link, bordered social-row buttons

A reasonable reviewer looking at the quad-comparison.html grid can
identify all four as the same brand. This was Phase 6's stated success
criterion.

## Next phase

Phase 7 (CI Integration). With Phase 6.x fully closed (Phase 6
PASS_WITH_NOTES + 6.8 PASS + 6.9 PASS), the demo app's visual baselines
are stable and ready to be wrapped into CI gates. Phase 7's scope:
GitHub Actions / equivalent workflow that runs the audit harness on
every PR.

**Checkpoint 3 surface to owner:**
- Sign off on Phase 6.9 PASS
- Tag `phase-06.9-pass-2026-05-23`
- FF-merge into feature/utility-first-css-asset-pipeline
- Authorize Phase 7 brief authoring
