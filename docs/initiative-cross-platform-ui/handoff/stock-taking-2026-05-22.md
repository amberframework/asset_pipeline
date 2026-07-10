# Initiative stock-taking — 2026-05-22

Owner asked to pause and audit before Phase 5 dispatch. This memo surfaces what's accumulated, what depends on what, and the decisions worth making before next dispatch.

## Where we are

Four phases passed, three remaining:

| # | Phase | Status | Cost (loops + iters) |
|---|---|---|---|
| 1 | Design Token Foundation | Passed `phase-01-passed-2026-05-20` | 1 remediation, 2 validator iters |
| 2 | Responsive Web Fluid Resize | Passed `phase-02-passed-2026-05-20` | 1 remediation, 2 validator iters |
| 3 | SwiftUI Native Bridge | Passed `phase-03-passed-2026-05-21` | **10 remediations, 7 validator iters** |
| 4 | Platform Tier Gating | Passed `phase-04-passed-2026-05-22` | 2 remediations, 2 validator iters |
| 5 | Glass Material Tokenization | Not started | budget: 1 loop |
| 6 | Side-by-Side Demo App | Not started | budget: 1 loop |
| 7 | Accessibility & Visual Verification Automation | Not started | budget: 1-2 loops |

Phase 3 absorbed most of the project's hidden complexity (cross-language interop, reactivity, AX-tree routing, class-init gap). Phases 1, 2, 4 each cost roughly what was budgeted.

## Inheritance backlog (everything deferred, with status + blocking)

| Item | Origin | Workaround in place? | Blocks |
|---|---|---|---|
| **Crystal-iOS class-init systematic fix** | Phase 3 R9 | Yes — `probe.reset` calls in `hig_bridge.cr#initialize_runtime` cover the 6 known probe singletons. Float `#to_s` via integer-arithmetic formatter. STDERR untouched on iOS render path. | **Likely Phase 6** (real demo app may introduce new class vars / `Crystal::once` paths). **Not strictly blocking Phase 5** because Phase 5 adds token struct *values*, not new class-var initializers. |
| **HapticFeedback widget** | Phase 4 deferred | N/A — no consumer | Nothing currently. Would block any phase that adds an `<UI::HapticFeedback>` consumer. |
| **Groups 4-5 widgets (15)** | Phase 3 owner-deferred | N/A — not in tier matrix as missing; tier matrix classifies them all as Tier 2 with current renderers | **Phase 6** if the demo app's design uses any of them (ProgressView, ActivityIndicator, RichText, VideoPlayer, MapView, WebViewComponent, ChartView, Tooltip, Snackbar, Circle, Rectangle, RoundedRectangle, Capsule, Canvas, PathView). |
| **Slider UIKit-wrapper migration** | Phase 3 R10 Codex Checkpoint 2A | N/A — BX4 currently PASSES via `.adjust(toNormalizedSliderPosition:)` which routes through binding fine | Nothing currently. Would block if a future test surface needs `XCUIElement.tap()`-style synthesis on Slider. |
| **macOS AXTest TCC re-grant after binary rebuild** | Phase 3 R8 onward | Manual — Seth granted; persisted through Phase 4 iter 2 | Operational; Phase 7's CI infrastructure must handle this. |
| **ListView `on_item_tap` regression follow-up** | Phase 3 R3 | Low-priority cleanup mentioned in early reflection | Nothing currently. |

The biggest backlog item is **class-init systematic fix**. The others are either parked correctly (HapticFeedback, ListView followup) or covered by workarounds (probe reset, integer-arithmetic Float formatter, TCC).

## What's worked + what's still risky

**Worked (apply forward):**
- Codex-reviewed dispatch briefs (multiple rounds; each round catches real defects)
- 4-checkpoint Codex critique cadence inside Implementer dispatches
- Diagnostic-first protocol (instrument before fixing; no hypothesize-then-defer)
- Deferral checklist (bug-class-appropriate items; 5-7 mandatory)
- Stating load-bearing invariants explicitly in the brief
- Listing the exact check IDs from `validation.md` in the brief (R1 brief did this; R10 did not, and we paid for it in R10's wrong identifier guesses)

**Still risky / to watch:**
- **CDP-style behavior probe infrastructure** only exists for the web target via R1's harness. Phase 5's iOS/macOS glass changes will need empirical verification through the existing AXTest + XCUITest paths (which work). Phase 7 should eventually formalize all of this into reusable CI.
- **Cross-language interop additions** (Phase 3 was the proof that this is high surface area). Phase 5 adds new C-export mutators for material params, so the same risks apply but at smaller scope. Phase 6 will rely heavily on the bridge but add no new bridge surface (it's a consumer).
- **Class-init gap** stays latent. If Phase 5 or 6 accidentally introduces a new class var on iOS-bound code that depends on initializer-by-`__crystal_main`, the silent-nil pattern returns.

## Phase 5-7 dependencies

**Phase 5 (Glass Material Tokenization):**
- Hard deps: Phase 1 (tokens) ✓, Phase 3 (SwiftUI bridge) ✓
- Soft deps: class-init fix would be nice but not blocking. Phase 5 adds tokens via `DesignTokens::Material` struct instances, not class variables.
- Risks: cross-renderer scope (touches all 4 renderers). Android is new functionality (`RenderEffect.createBlurEffect` on API 31+). Web `backdrop-filter` performance + `@supports` fallback.

**Phase 6 (Side-by-Side Demo App):**
- Hard deps: Phase 1 + 3 + 4 + 5 (a demo app needs glass material to demonstrate brand cascade end-to-end)
- Soft deps: **class-init fix becomes important here** — the demo app will exercise real user-app patterns and may surface latent class-init issues. Resolving it before Phase 6 reduces risk.
- Groups 4-5 widgets may need to be migrated if the demo design uses them.
- Risks: high surface area (all 4 platforms, real interactivity, brand cascade).

**Phase 7 (Accessibility & Visual Verification Automation):**
- Hard deps: Phase 6 (need a real app to validate against, not just per-component HIG studies)
- Operational deps: CI runner with macOS + iOS sim + Chrome + axe-core + IBM Equal Access + TCC management
- Risks: Phase 7 inherits the visual-baseline + behavioral-test infrastructure. The CDP harness from Phase 4 R1 is a model; needs to extend to iOS/macOS app testing.

## Decisions worth making before Phase 5 dispatch

### 1. Class-init systematic fix — when?

Three positions:

**(a) Defer until it actually blocks.** Phase 5 doesn't strictly need it. Phase 6 likely will but not guaranteed. Cheapest forward motion.

**(b) Phase 4.5 interstitial.** Small dedicated dispatch authoring `UI::Native::iOS::Runtime.boot` helper that explicitly initializes the subsystems Crystal's hidden `_main` skips (Fiber, STDERR, Float::Printer::Dragonbox, any other class-var initializers in `src/`). Removes a latent landmine that downstream consumers might hit. Adds ~1 cycle.

**(c) Bundle into Phase 5.** Probably the worst option — scope creep risk on a phase already touching all 4 renderers.

My architect's read: **(a)** is reasonable if you want speed; **(b)** is reasonable if you want to clear the deck. The decision matters because Phase 6 will likely exercise it and we'd rather find the fix in a focused dispatch than mid-Phase-6 chase.

### 2. Phase 5 brief style

Same as Phase 4 worked. Codex-reviewed wrapper over canonical `implementation.md`. Specific to Phase 5: the brief should call out the cross-renderer scope explicitly (4 renderers, 4 different idioms — UIKit material, AppKit material, web `backdrop-filter`, Android `RenderEffect`) and require diagnostic-first verification on EACH platform, not just one.

### 3. Phase 6 + 7 sequencing

Phase 7 is described as "Accessibility & Visual Verification Automation" — CI + reusable test infra. Should Phase 7 happen BEFORE Phase 6 so we have the infrastructure to verify Phase 6's demo app? Or after, treating Phase 6's demo as the canonical exemplar Phase 7 builds CI around?

Honest read: **Phase 7 needs Phase 6's app to exist** to validate against. So 6 → 7 is the order. But Phase 6 will benefit from incremental Phase 7 infrastructure (e.g., a basic CDP-like harness for each platform). Resolving this might mean re-scoping Phase 7 into "Phase 6.5 (infra)" + "Phase 7 (full CI integration)." Worth Seth's call when we get there.

### 4. Anything else parked I missed?

This memo is the architect's read. If anything's been deferred that I haven't surfaced, flag it.

## What I'd recommend (architect's read)

If I had to pick: **(1a) defer class-init, dispatch Phase 5 lean, watch for it in Phase 6.** Phase 4's 2-loop cost on a much simpler scope suggests Phase 5's 1-loop budget is optimistic. Don't add scope.

But the call is yours. The pause was the right move; this is the data to make it on.
