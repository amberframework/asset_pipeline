# Phase 4 — Architect Reflection — 2026-05-22

**Phase:** Platform Tier Gating
**Outcome:** PASSED (Validator iter 2 — 31/31 required checks)
**Tag:** `phase-04-passed-2026-05-22` (forthcoming)
**Final HEAD:** `6180a14`

## What this phase actually cost

14 implementer commits + 2 remediation loops + 2 validator iterations + 1 Codex CLI brief-review chain. Estimated budget was 1 remediation loop; landed at 2. One was anticipated (CDP harness was missing test infrastructure); one was emergent (CDP probes surfaced 2 latent renderer-source accessibility bugs that source review couldn't catch).

This is a strong contrast to Phase 3's 10-remediation cost. The patterns that made Phase 4 cheaper:

1. **Codex-reviewed dispatch briefs upfront** caught planning gaps before the Implementer started (Phase 4 initial: 2 review rounds; R1: 3 rounds; R2: 1 round). Phase 3 didn't adopt this until Remediation 9, after most of the cost was already paid.
2. **Diagnostic-first + 4-checkpoint Codex critique cadence inside the Implementer** caught real defects mid-stream rather than letting them surface at validation time. R1's CDP harness design got 4 substantive Codex corrections (closed→open transition forcing, single dismiss listener at DOMContentLoaded, Tab+Shift+Tab separation, IBM precision wording).
3. **Bounded scope.** Phase 4 is mostly Crystal macros + 1 new widget + 3 *WithWebFallback siblings + 2 vanilla JS fallbacks + 1 macro helper + 1 doc + 3 web demo pages + 1 CDP harness. No deep cross-language interop layers (which dominated Phase 3's cost).

## What planning got right

1. **Phase 4 README's "1 remediation loop" budget estimate** was honest about scope. The 2 loops it actually took were both legitimate scope-additions (CDP infrastructure + latent-bug surfacing), not under-estimation.
2. **The "important finding" about ActionSheet being missing as a source file** was caught at brief-authoring time, not validation time. Avoided the "stop early" rabbit hole the brief warned about.
3. **Existing infrastructure called out explicitly** ("don't reinvent") prevented the Implementer from authoring a new web-renderer or test framework when extending was correct.

## What planning got wrong (and what to apply forward)

1. **Tier-matrix widget counts were stale** (canonical said 75; actual was 74-78 depending on commit). The wrapper had to override at multiple points across multiple Codex review rounds. **Lesson:** any count in a plan document is a stale risk; reference via grep ("the actual count is `ls src/ui/views/*.cr | wc -l`") not a literal number.
2. **`:darwin` vs `:macos || :ios` flag pattern.** Canonical said `:darwin`; codebase convention is `:macos || :ios`. **Lesson:** mine the existing codebase for the actual idiom before writing a brief that prescribes one.
3. **`PathControlWithWebFallback` initially dropped from the wrapper** when I summarized to "ActionSheet + ContextMenu only." Codex caught this in round 1. **Lesson:** when summarizing canonical's scope into a wrapper, enumerate by name; don't ad-lib.

## What worked particularly well

1. **The CDP harness exposed real bugs the rubric was specifically designed to catch.** R1's `fallback.action-sheet-axe-clean` FAIL with 1.92:1 contrast and listitem markup violation is exactly the kind of bug source review can't see and structural specs can't catch. The rubric's "no source-only proof on web fallback behavior" requirement is load-bearing for this phase.
2. **One-bug-at-a-time fix discipline in R2.** The Implementer landed Bug #2 (listitem) first, re-ran the harness to confirm listitem violation gone + contrast violation remaining, THEN landed Bug #1. Clean isolation.
3. **R2's surprise catch:** the brief flagged only the default action's contrast violation; R2's audit revealed the cancel button was inheriting the same color rule and ALSO failing. Single CSS swap fixed both. Diagnostic-first protocol enabled this.

## Phase 5 inheritances

1. **Crystal-iOS class-init gap** (carried from Phase 3) — systematic fix via `UI::Native::iOS::Runtime.boot` helper still pending. Phase 5 (Glass Material Tokenization) is the natural place to ship this since Glass material work touches runtime initialization paths anyway.
2. **HapticFeedback widget** (Phase 4 deferred) — Tier 3 iOS-only widget needs to be authored if/when a future phase requires it. Not blocking anything currently.
3. **Action token color theory** — Phase 4 R2 swapped to `--ap-color-brand-primary` for action-sheet actions; Phase 5's token tuning could revisit whether a dedicated `--ap-color-interactive-text` semantic role is worth introducing.

## Phase 5 readiness

Phase 5 README to re-read before dispatch:
- Scope is "Glass Material Tokenization" — building on Phase 3's `GlassBackground` cascade with material tokens.
- Should be informed by Phase 4's tier classifications (Tier 1 widgets that may need glass-aware tokens vs Tier 2 widgets that get them automatically through SwiftUI defaults).
- Class-init gap may want addressing here.

## Closing note

Phase 4 closed with empirical proof of every Tier-3 gate, every web fallback behavior probe, and zero Phase 3 regressions. Cost 2 remediations (1 anticipated, 1 emergent), and the Codex-reviewed brief workflow proved itself again as the cheapest way to keep dispatches scoped and the Implementer un-stuck. Two web-renderer bugs that would have shipped silently without the CDP harness are now fixed at the source.
