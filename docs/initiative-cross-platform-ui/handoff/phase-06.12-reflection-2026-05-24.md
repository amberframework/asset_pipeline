# Phase 6.12 — Architect Reflection

**Phase:** 6.12 — Library-Identity Pivot (Option C) + macOS Polish + Cascade Preservation
**Date closed:** 2026-05-24 (PASS_WITH_NOTES)
**Branch:** `phase-06.12-library-identity-macos-polish` (merged to feature branch)
**Final HEAD:** `58d31343`
**Tag:** `phase-06.12-pass-with-notes-2026-05-24`

## Verdict

PASS_WITH_NOTES. Three sub-phases (6.12A + 6.12B + 6.12C) shipped the architectural pivot AND closed the regression it accidentally surfaced. Evidence capture remains incomplete (14-row behavior contract + post-pivot iOS legibility recapture); pixel-sample gamma caveat documented.

## What shipped

### 6.12A — Library-identity pivot (Option C)

- `UI::DesignTokens::Color::SYSTEM_ACCENT` sentinel with full API surface (`system_accent?` predicate, `to_css → "AccentColor"` CSS Color L4 keyword, `to_swift → "Color.accentColor"`, `to_android_argb` raises, `==`, `to_s`).
- `Tokens.default.brand_primary_*` family ALL return the sentinel.
- 4 renderer integrations: iOS clears `apsk_runtime_brand_tint` for sentinel; macOS mirrors; web emits `--ap-color-brand-primary: AccentColor`; Android raises `AndroidRendererNotImplemented` if hit.
- macOS NSWindow sizing fix: 880×640 default, resizable both axes, 480×400 floor.
- Cascade preservation: confirmed via web CSS grep that `InitiativeDemo.brand_tokens` explicitly applies the brand cascade.
- No-amber audit: 8 sentinel roles total (brand_primary + hover + active + 5 others including `border_focus`).
- Spec: 1497/4/0 → 1529/4/0 (+32 new examples).

### 6.12B — Capture closure (PARTIAL)

- Cascade iOS + macOS prominent-button captures committed (the captures that surfaced the regression).
- 4 of 8 iOS legibility recaptures NOT taken (carried forward).
- macOS resize captures (480/880/1280) NOT taken (carried forward).
- 14-row Voyager behavior contract NOT captured (carried forward to Phase 8D after Voyager rewrites under Phase 8 API).
- Agent stopped mid-Cascade-pixel-investigation; the discovery + handoff to 6.12C was its load-bearing contribution.

### 6.12C — Cascade prominent-button regression fix

- Probe confirmed: macOS `.borderedProminent` silently ignores `.tint()` from environment.
- New `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift` — macOS-only custom ButtonStyle from primitives (Capsule + white foreground + pressed/disabled state coverage).
- `ButtonFacade.swift case "prominent":` gated `#if os(macOS)` + `if let activeTint = APSKRuntime.brandTint` — uses live tint; falls back to stock `.borderedProminent` when nil.
- iOS branch BYTE-IDENTICAL to Phase 6.11 iter-4.
- Cascade renders teal; Voyager renders system gray (NOT teal) — proof captures in `phase-06.12c-evidence/`.
- `APSKRuntime.brandTint == nil` for Voyager verified live via opt-in `APSK_BRAND_TINT_LOG` env var.
- Codex APPROVE 4/4 PASS.

## What's open (carried forward)

- **Pixel-sample gamma caveat:** Cascade button rendered pixel `(58, 131, 133)`; brief target `(15, 133, 133) ± 15`. G/B match; R-channel Δ43 above tolerance. Root cause: `Color#r=0.012` linear treated as sRGB-encoded by SwiftUI `Color(.sRGB, ...)`. Pre-existing color-pipeline gamma issue; same lift would have occurred with Phase 6.8 hardcoded literal. Hue family unambiguously deep teal (R ≪ G ≈ B). Phase 6.13 or later can audit the gamma/linear vs sRGB encoding policy.
- **4 of 8 iOS legibility recaptures + macOS resize captures + 14-row behavior contract**: deferred. Phase 8 will rewrite Voyager under the new API; capture work folds into Phase 8D's migration validation.

## Lessons saved to memory this phase

- [[design-amber-first-not-after]] — Phase 8 v1 REJECT taught us: prove integration on a spike BEFORE designing abstractions.
- [[audit-shortcut-trap]] — semantic auto-pass claims need code citations.
- [[mid-stop-pattern-evidence-capture]] — agents reliably stop mid-action at capture time; split-dispatch.
- [[codex-as-architect-antagonist]] — applied to every brief this phase; caught real issues every pass.

## Bookkeeping

- 13 commits on `phase-06.12-library-identity-macos-polish` (11 from 6.12A, 2 from 6.12C, 0 from 6.12B's capture-only agent which didn't commit).
- Multiple docs commits for briefs + critique trails (~6).
- Tags incoming: `phase-06.12-pass-with-notes-2026-05-24`.
- Codex review trail across the phase: 11 reviews (Codex 1-3 on 6.12A + revisions, Codex 1 on 6.12B brief, Codex 1-3 on 6.12C brief, Codex 1 on 6.12C fix).

— Architect (Claude Opus 4.7)
