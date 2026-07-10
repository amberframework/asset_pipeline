# Phase 6.8 — Architect's Reflection — 2026-05-23

Phase 6.8 (Visual Polish Deferrals from Phase 6) closed PASS at HEAD
`3faab95` on `phase-06.8-visual-polish-deferrals`, 5 commits past the
architect handoff at `afb7791`. All 3 deferrals from Phase 6's
PASS_WITH_NOTES closed: brand-teal pill, macOS width pin, and `:secondary`
chrome. The Codex-as-realtime-critic protocol that Phase 6 Rem 5
introduced produced a clean PASS phase first try — no remediation cycles.

## What worked

**The Capsule.fill bypass approach succeeded first try.** Phase 6
consumed 4 remediation cycles trying to coax SwiftUI `.borderedProminent`
into rendering a concrete brand-teal Color (it wouldn't — iOS 26's
chrome only resolves the `.accentColor` dynamic sentinel). Phase 6 Rem 5
documented this gap with a proposed bypass: ignore `.borderedProminent`
entirely and render the pill explicitly via `.background(Capsule().fill(brandTeal))`.
Phase 6.8 Fix 1 shipped this exact approach in one commit. The iOS sign-in
button now samples to **exactly sRGB(3, 133, 133) = #038585** — the Phase
6 brand override's deep teal.

**The Codex per-fix critic protocol contained scope risk.** Each fix
landed with a Codex check before proceeding. When the Implementer
realized `:secondary` arrives as a ROLE not a STYLE (the brief's
suggested fix would have been a no-op), they traced
`swiftkit_overrides.cr`, found the correct dispatch path, and shipped
a post-switch role check instead. That kind of "the brief was wrong;
here's the correct fix" surfacing is exactly what the per-fix
checkpoint enables.

**The Validator's trust-pair verification was decisive.** Verdict PASS
with EXACT color sampling (`magick identify -format "%[pixel:...]"`
on the iOS baseline returned `srgb(3,133,133)` — the brand teal
matches), and explicit diff-scope check (only ButtonFacade.swift + 4
sign-in baselines touched). No findings to remediate.

## What didn't go cleanly

**The Implementer agent stalled mid-execution after Fix 2.** Same
pattern as Phase 6 Rem 3 / 3-completion / 4: returned with a
half-finished thought ("macOS host built. Now recapture macOS
baselines.") rather than a clean completion. The architect (a) committed
the Implementer's uncommitted Fix 2 work, (b) dispatched a focused
continuation agent for just Fix 3, (c) the continuation completed
cleanly with all 10 regression checks reported.

**Lesson:** when an Implementer stalls mid-execution, the architect's
right move is "commit the WIP if salvageable + dispatch a smaller-
scoped continuation for the remaining work" rather than retrying the
same scope. Smaller-scoped dispatches converge.

**Minor cosmetic artifact (Phase 7 follow-up).** On macOS, the Capsule.fill
brand-teal pill has a smaller darker rectangle inside it where the
SwiftUI Button label sits — the Button's default label rendering
overlays the Capsule. iOS doesn't have this artifact (SwiftUI on iOS
respects the .background modifier as the sole pill chrome). Phase 7
can baseline against current state and address the macOS artifact via
either `.buttonStyle(.plain)` or a custom button label view.

## What to carry forward

1. **Per-fix Codex check is the right pattern for visual polish work.**
   Adopt it whenever a remediation regressed prior working state — the
   stop-on-regression-and-continue protocol contains damage.

2. **The SwiftUI .accentColor sentinel vs concrete Color value
   asymmetry is documented as a SwiftKit lesson.** Future SwiftKit
   work should test BOTH paths empirically before committing to either.

3. **Brand-tint propagation via host-root .tint() cascade does NOT
   reach UIHostingController-hosted buttons.** Each Crystal-produced
   Button is hosted in its own UIHostingController; SwiftUI .tint() in
   a parent SwiftUI scope does NOT cross that boundary. Future
   work that depends on tint cascade must either flatten the UIHosting
   hierarchy or propagate tint per-button via the populator.

4. **macOS Capsule.fill inner-rectangle artifact** documented in commit
   524cdd1 as Phase 7 follow-up. Either bypass SwiftUI Button's default
   label rendering, or pick a different macOS button style that doesn't
   add chrome over .background.

## Next phase

Phase 7 (CI Integration). With Phases 1 → 6.8 all PASS (or
PASS_WITH_NOTES), the demo app + audit harness + 40 baselines + brand
override mechanism are all in place. Phase 7's scope: wrap Phase 6.5's
audit harness into GitHub Actions / equivalent CI so the harness runs
on every PR.

**Checkpoint 3 surface to owner:**
- Sign off on Phase 6.8 PASS
- Tag `phase-06.8-pass-2026-05-23`
- FF-merge into feature/utility-first-css-asset-pipeline
- Authorize Phase 7 brief authoring + dispatch
