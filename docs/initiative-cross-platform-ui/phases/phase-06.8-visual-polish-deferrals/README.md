# Phase 6.8 — Visual Polish Deferrals from Phase 6

**Inserted:** 2026-05-23, immediately after Phase 6 PASS_WITH_NOTES.
**Dependencies:** Phase 6 PASS (tag `phase-06-pass-2026-05-23`).
**Blocks:** Phase 7 (preferably; Phase 7 can baseline against post-6.8
state rather than mid-state).

## Scope

Close the 3 deferred visual gaps from Phase 6's reflection:

1. **Brand-teal tint propagation** — SwiftUI `.borderedProminent` button
   chrome doesn't resolve a fill against a concrete brand-teal `Color`
   value on iOS 26 (it does resolve `.accentColor`, but that's
   system-blue). Phase 6 ran 4 remediation cycles trying various tint
   cascade approaches; all regressed iOS button visibility. Rem 5's
   handoff doc proposes BYPASSING `.borderedProminent` entirely for
   primary buttons and rendering the pill explicitly with
   `.background(Capsule().fill(brandTeal))`. Phase 6.8 ships this
   bypass.

2. **macOS Sign-in button width pin** — ButtonFacade applies
   `.frame(minWidth: w)` which lets system intrinsic width dominate. On
   macOS the Prominent style's intrinsic width is narrower than the
   340pt content pin set by the Sign-in screen. Fix: use
   `.frame(width: w)` (exact) when `min_w == max_w` AND style is
   `prominent`.

3. **Social-row `:secondary` chrome** — Phase 6 sign-in screen declares
   the Apple/Google/Email row with `:secondary` button role; ButtonFacade
   has no `case "secondary"` in its style switch so they render as
   default flat buttons. Fix: add `case "secondary":` mapping to
   `.buttonStyle(.bordered)` (canonical SwiftUI secondary chrome).

## Out of scope

- Adding new widget types.
- Modifying any Phase 5 v2 design tokens or Material APIs.
- Re-architecting the SwiftKit facade pattern.
- Re-capturing baselines beyond the affected sign-in screen (the other
  4 screens — dashboard, detail, settings, tier-three — should not need
  re-capture unless they use prominent/secondary buttons that change).

## Acceptance

1. iOS sign-in baseline: Sign-in button renders in brand TEAL (sRGB
   approximately `3, 133, 133`), NOT system blue.
2. macOS sign-in baseline: Sign-in button width matches email/password
   field width (340pt content pin respected).
3. iOS + macOS + web sign-in baselines: Apple/Google/Email social-row
   buttons render with bordered chrome (outlined), not default flat.
4. Brief validator exits 0.
5. Regression baselines clean (crystal spec 1455/4/0; material spec
   31/0; all 4 build closures exit 0).
6. iOS Sign-in button is STILL VISIBLE at end of phase (the regression
   mode from Phase 6 Rem 4 must not recur).

## Anticipated work size

~5-8 commits. Three focused fixes in ButtonFacade.swift, possibly small
Crystal-side wiring in `populate_button` for the brand-teal background
color path. Recapture affected baselines.

## Codex co-pilot mode (REQUIRED — per Phase 6 Rem 5 protocol)

Phase 6.8 Implementer MUST run Codex as a real-time progress critic
AFTER EACH FIX, comparing the new baseline against fddcc71/5b5a514's
state. If Codex flags REGRESSION (Sign-in button invisible, button
chrome missing, etc.), Implementer REVERTS the fix immediately and
moves to the next. The fix prompt enumerates the Codex check between
each fix.

This is the protocol that contained Phase 6 Rem 4's damage when the
prior pattern of "investigate deeper, ship anyway" was failing. Adopt
it explicitly here.
