# Phase 6.10 — Owner Hands-On Findings (iOS Sim)

**Date:** 2026-05-23
**Surfaced by:** Seth (project owner), hands-on iOS Sim run of VoyagerDemo.app
**Status:** PHASE 6.10 CANNOT CLOSE. The app does not function on iOS.

This document captures the owner's verbatim findings from a hands-on launch
of the Voyager demo in the iPhone 17 simulator. It is append-only and
sits above the prior `phase-06.10-cont-blocker-2026-05-23.md` (which
diagnosed only the XCUITest AX tree gap). The findings below show the
problem is **larger than the AX tree** — the iOS UIKit renderer produces
a non-functional, non-HIG-shaped UI even for hand interaction.

---

## What the owner observed (verbatim, paraphrased only for line wrap)

> I just tried the application and I agree that this needs a complete fix
> because I did just run the application in the simulator and it doesn't
> function basically at all.
>
> 1. **Inputs don't show focus.** I can't tell if I'm actually clicking
>    into an input field or not because nothing changes to indicate that
>    it's now in an input state.
> 2. **Sign-in button does nothing.** When I click sign in, nothing
>    happens. The initial realization that we didn't tie into taps to
>    test means that we now are completely missing that functionality
>    and it just got glossed over.
> 3. **Screens aren't full-screen.** I would like it so that these
>    screens are actually full screen. That's something that I thought
>    was a little strange when I open this.
> 4. **Email + password fields overlap.** On this Voyager thing it
>    looks like the password field is overlapping the email field.
>    There isn't space between them. I don't know how that happened,
>    but that's got to be fixed.
> 5. **Sign-in button is at the top of the screen.** It's a little weird
>    that it's not below the input or at the bottom of the screen.
> 6. **Black bars across top + bottom of the screen** instead of going
>    all the way to the top of the window. That's weird. It should fill
>    the entire display as much as possible, and then we adjust down
>    with utilities to fit within the viewport. That way we don't have
>    this black background everywhere like it currently has. That's
>    definitely an anti-pattern.
> 7. **Framework default spacing is missing.** That's probably
>    something to address in the framework itself so that things like
>    inputs don't… when they are rendered onto the screen, they
>    naturally appear one after another with some default spacing
>    between them, like a consistent kind of spacing.
> 8. **No gutters.** The inputs actually go the full width of the
>    screen. They don't have any space on the sides to differentiate
>    them from just being part of the layout.
>
> These are the kind of nuances that I expect us to have before we say
> that our component system here is done.

---

## What this means

The earlier blocker doc framed this as "AX tree doesn't propagate so
XCUITest can't see buttons." That was a true diagnosis but a too-narrow
scope. The full picture from the hands-on test:

### A. Interaction is broken at the **UIKit hit-test layer**, not just AX tree

Owner could not tap into TextFields (no focus state) and could not fire
the Sign-in Button (nothing happened). This is not an XCUITest visibility
issue — it is the UIKit event-dispatch chain itself failing. Possibilities
the implementer needs to audit:

- UIButton's target/action wiring back to the Crystal callback registry
  (does `addTarget:action:forControlEvents:` actually land, or is it
  silently dropped on a wrapper UIView instead of the UIButton?).
- `userInteractionEnabled` on container UIViews (a parent stack with
  `userInteractionEnabled=false` blocks touches to all descendants).
- Frame / bounds — if buttons are zero-sized or clipped, taps don't land
  even though the visual draws.
- CallbackRegistry GC — Crystal Procs held only weakly could be reaped
  before the UIKit target/action fires.

### B. Layout is broken **independent of interaction**

Even if taps worked, the layout is HIG-non-conformant in obvious ways:

- Overlapping form fields (VStack spacing of 0 or negative, or
  intrinsic content size collisions with no constraint adjudication).
- Sign-in button at the top (intended bottom or below-fields ordering
  not honored — possibly VStack arranges in declared order with no
  Spacer pushing content; on iOS the brief expected the button to sit
  under the password field with reasonable spacing).
- Black bars top/bottom (safe area not extended — `ignoresSafeArea` or
  the equivalent UIKit `extendedLayoutIncludesOpaqueBars` not set; root
  UIView's frame doesn't reach to `view.bounds`).
- No horizontal gutters / padding (the brief does not establish a
  framework default for form gutters on iOS — the implementer-side
  layout choice produced edge-to-edge inputs).

### C. The framework itself is missing **iOS form defaults**

Owner's last paragraph is the architectural finding: the framework
should produce sensible defaults for adjacent form elements (vertical
rhythm + horizontal gutter) on iOS without the demo author having to
specify them. Today it doesn't, and that's why the demo looks like it
looks.

---

## Implications for scope

This is a **multi-pronged fix**, not a one-shot:

1. **UIKit interaction layer audit** (must-fix to call iOS native usable
   at all). Touches `uikit_renderer.cr` visit_button / visit_text_field /
   visit_secure_field. Confirm target/action lands on the real UIButton,
   confirm hit-test chain isn't blocked by container userInteractionEnabled,
   confirm CallbackRegistry retains the Proc.

2. **UIKit AX tree propagation** (must-fix to call iOS production-quality).
   Distinct from interaction — once taps work, XCUITest still needs the
   AX tree exposed so automated verification can run. Already specced in
   the prior blocker doc.

3. **UIKit form layout defaults** (must-fix to make the iOS render
   beautiful-by-default — the library's North Star per CLAUDE.md). This
   is framework work, not demo work:
   - Default VStack spacing for form contexts (or document the right
     spacing pattern the demo must adopt).
   - Default horizontal padding / gutters for content roots.
   - Safe-area handling on the root UIView (extend to full bounds,
     respect safe-area insets via auto-layout).
   - Spacer + button-placement semantics (button at bottom should
     mean `Spacer` pushes it down, but if the demo doesn't use
     Spacer the renderer should still produce a sensible order — or
     the documentation should make clear how to position).

4. **Voyager demo layout fixes** (correct the screen authoring once the
   framework supports it):
   - Sign-In screen: move button below fields with consistent spacing.
   - Add gutters to the screen root (or rely on the new framework
     default if 3 is done first).
   - Verify ALL 4 screens look HIG-shaped at iPhone 17 dimensions.

5. **Interaction + state-propagation hands-on verification** (replaces
   the deferred XCUITest as the closing gate). Owner taps through the
   full Sign-In → Todos → Toggle Settings → back flow and confirms each
   step actually works end-to-end. Per the
   `owner-hands-on-finds-real-bugs` feedback memory, hands-on is the
   only legitimate close for native interactive work.

---

## What changes for Phase 6.10's verdict

- The Implementer reported the macOS host as GREEN (offscreen capture
  of Sign-In rendered) but did NOT verify interaction on macOS either.
  macOS likely has analogous bugs (NSButton target/action, NSStackView
  spacing, content-view inset to window) that the hands-on test of the
  macOS host has not yet surfaced. Owner should test macOS by hand
  after the iOS fix lands, before we believe macOS works.
- Web demo passes the litmus at the Crystal contract level and the JS
  shim navigates correctly in the browser. Web is not affected by
  these findings, but is the only platform proven working end-to-end.
- **Phase 6.10 stays open.** Whatever remediation we ship next must
  close all five implication items above before the phase tags PASS.

---

## What does NOT belong in this phase's remediation

- Re-baselining Cascade (Phase 7 baselines are good).
- Audit-harness slug routing for `voyager-*` (mechanical follow-up;
  do not gate Phase 6.10 close on it).
- SwiftUI `.swipeActions(edge:)` native facade (already deferred per
  implementer report; Voyager's inline buttons are acceptable interim).
- Android renderer changes (Phase 1 cross-build precedent stays).

---

## Next architect action

Surface this finding set to the owner, propose a single remediation
scope that bundles 1+2+3+4+5 into ONE focused Implementer dispatch
(versus splitting into multiple sub-phases), and wait for owner to
confirm scope before dispatching. The owner has explicitly authorized
the UIKit AX tree fix; this finding set widens the fix to include
interaction + layout + framework form defaults, which requires
architect-owner alignment before dispatch.

— Architect
