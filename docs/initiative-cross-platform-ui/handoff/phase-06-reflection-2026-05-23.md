# Phase 6 — Architect's Reflection — 2026-05-23

Phase 6 (Side-by-Side Demo App) closed PASS_WITH_NOTES at HEAD `0d19dc0`
on `phase-06-side-by-side-demo-app`, 24 commits past the architect handoff
at `b26b688`. The phase consumed an unusual amount of remediation: 5
cycles (Rem 1 → Rem 5), with Rem 4 actively regressing the prior working
state before Rem 5 rolled back and contained the damage. This reflection
captures both the wins and the convergence failure.

## What worked

**The Cascade demo ships across all 4 surfaces.** 5 demo screens
(sign-in, dashboard, detail, settings, tier-three) render on web (1280 +
375 viewports), macOS, and iOS. 40 baseline PNGs committed (10 per
surface × 5 screens × 2 appearances). The quad-comparison.html grid is
the brand-litmus artifact the user explicitly named as the success
criterion.

**The iOS class-init gap (BRAND_TOKENS module constant)** that crashed
CascadeDemo at launch was diagnosed precisely by Codex (in 15 minutes of
investigation) and fixed in Rem 1 (1 commit changing 1 line in
brand.cr). The pattern — module constants with non-trivial initializers
don't fire under iOS embedding — is now a documented landmine for any
future iOS demo work.

**The audit harness routes every demo cell.** `bash
scripts/audit_harness_smoke.sh I-1 ios demo-all` exits 0 with 5 PASS
entries at ~20s/slug via real xcodebuild test invocations (no
artifact-presence proxies). Same for web + macOS. The Phase 6.5 forcing
function held end-to-end.

**Rem 5's stop-on-regression protocol prevented compounding damage.**
After Rem 4 broke iOS Sign-in button visibility and stalled mid-fix,
Rem 5 (a) rolled back Rem 4 cleanly, (b) attempted Fix 1 with Codex as
a real-time progress critic, (c) detected regression immediately, (d)
reverted cleanly without proceeding to Fix 2/3, (e) wrote a complete
handoff doc documenting the failure mode. That's the right shape of a
remediation cycle that doesn't converge.

## What didn't converge

**Brand-teal tint propagation defeated 2 remediation cycles.** The Phase
6 demo uses a deep-teal brand override. SwiftUI Link picks up the brand
tint via `.foregroundStyle(.tint)` (Rem 2 fix). But SwiftUI
`.borderedProminent` Button does NOT — Rem 4 + Rem 5 each tried
different approaches (host-root .tint cascade; surgical ButtonOverrides
tintColor field) and BOTH regressed the iOS button to invisible.

Codex's hypothesis from Rem 5: iOS 26's `.borderedProminent` chrome
resolves a fill against the `Color.accentColor` *dynamic sentinel* in a
way that produces visible chrome, but against a *concrete*
`Color(red:...)` value produces nothing. The fix path forward (per the
Rem 5 handoff doc) is to bypass `.borderedProminent` and render the
pill explicitly with `.background(Capsule().fill(brandTeal))`. That's a
deeper change than 4 Rem cycles could land safely.

**Lesson:** when a SwiftUI behavior depends on a `Color` sentinel
(.accentColor, .tint, .primary) vs a concrete `Color(...)` value, the
two are NOT interchangeable. The dynamic resolution path uses the
SwiftUI environment hierarchy in subtle ways. Future SwiftKit work
should test BOTH paths empirically before committing to either.

**Two cosmetic gaps remain (Phase 7 follow-ups):**
- macOS Sign-in button doesn't respect the 340pt content_width pin
  (renders narrower than email + password fields above)
- Social-row buttons (Apple/Google/Email) render as default flat
  buttons instead of `.bordered` chrome — `ButtonFacade.swift` has no
  case for `:secondary` style

Both are documented in `handoff/phase-06-rem3c-followups-2026-05-23.md`.

## What to carry forward

1. **The brand-teal-vs-system-blue gap is a Phase 7 concern.** Phase 7
   ships CI gates against the current baselines (which use system
   blue). When the systemic SwiftKit brand-tint propagation gets a
   proper fix, baselines refresh.

2. **5-cycle remediation is too many.** The pattern of "iOS-specific
   visual gaps reveal SwiftKit propagation subtleties" should trigger a
   PAUSE-and-INVESTIGATE before dispatching more Rem cycles. By Rem 4 I
   should have stopped and authored a tighter architecture doc rather
   than dispatching another agent. The Rem 5 protocol (Codex as
   real-time critic) is the right pattern for inherently iterative
   discovery work — adopt it whenever the prior remediation
   regressed.

3. **The "Don't Stall Mid-Investigation" pattern.** Rem 3, 3-completion,
   and 4 all returned with cliffhanger messages instead of clean
   completions. Implementer dispatch prompts now explicitly require
   "ship all fixes OR write a complete handoff doc explaining what's
   blocked — don't return mid-thought." Rem 5 followed this and
   produced a clean exit even on partial success.

4. **The brief contract held.** Despite 5 remediation cycles, the brief
   validator + Codex pre-dispatch antagonist + Validator independent
   verification + Rem 5 rollback protocol all worked. The forcing
   function is doing its job — the failures are about SwiftUI's
   per-platform tint resolution, not about the contract structure.

## Next phase

Phase 7 (CI Integration). With Phase 6 closing PASS_WITH_NOTES + 40
baselines committed + audit harness routing all 32 working cells, Phase
7's scope is to wrap the harness into GitHub Actions / equivalent. The
brand-teal investigation + the 2 cosmetic gaps can ride into Phase 7's
work OR get a small Phase 6.8 follow-up — owner decides.

**Checkpoint 3 surface to owner:**
- Sign off on Phase 6 PASS_WITH_NOTES with the 3 deferrals
  (brand-teal tint, macOS button width, social-row :secondary)
- Tag the passing state (`phase-06-pass-2026-05-23`)
- Authorize Phase 7 brief authoring (or a Phase 6.8 if you want the 3
  deferrals closed before CI work begins)
