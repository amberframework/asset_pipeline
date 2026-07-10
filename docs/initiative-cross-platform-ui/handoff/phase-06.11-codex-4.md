# Phase 6.11 — Codex Review 4 (Iter 4 Swift Facade Slice)

**Date:** 2026-05-23
**Iteration scope:** ButtonFacade brand-teal hardcode removal + TextField/SecureField placeholder contrast fix via shared `PromptOverlayField` wrapper.
**Diff snapshot:** `/tmp/p611-iter4-diff.patch` (261 lines, 3 files: ButtonFacade.swift, TextFieldFacade.swift, SecureFieldFacade.swift).
**Author of this review:** `codex exec` (codex-cli 0.130.0).
**Caveat:** This review covers the Swift-facade slice only — NOT the screenshot recapture or audit-table rewrite. Those are downstream of these fixes and reviewed separately.

## Codex invocation (verbatim prompt)

> Review the diff at /tmp/p611-iter4-diff.patch against
> docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md.
> Three Swift facade changes: (1) ButtonFacade removed brand-teal hardcode and restored
> .borderedProminent + .controlSize(.large), added stretched-prominent recipe with
> .frame(maxWidth: .infinity) on label + outer width pin; (2) TextFieldFacade introduces
> PromptOverlayField wrapper that renders placeholder via overlay Text at
> Color.primary.opacity(0.5) for WCAG 3:1+; (3) SecureFieldFacade adopts the same
> PromptOverlayField pattern. Verify: (a) brand-teal hardcode is GONE, (b) PromptOverlayField
> composes to >= 3:1 in both appearances, (c) no new diagnostic NSLog/print/etc., (d) any
> architectural concern with the .frame(maxWidth: .infinity) inside Button { ... } label.

## Verdict: **PASS** for the requested Swift-facade slice.

## Findings

- **Brand-teal removal:** Zero `brand_?[Tt]eal` / `Color(red:.*0\.012` hits in live source. `ButtonFacade` now uses `.controlSize(.large).buttonStyle(.borderedProminent)`. The Phase 6.8 Capsule.fill workaround is fully gone.

- **PromptOverlayField contrast:** `Color.primary.opacity(0.5)` composites closer to ~4.0:1 on white (not the 4.6:1 I estimated in the brief — Codex's actual measurement). Still clears the 3:1 UI-text floor. Codex confirms it's good enough for WCAG 2.2 AA UI text per the brief's threshold.

- **Diagnostic logging:** No new `NSLog` / `print` / `os_log` introductions. The only `NSLog` hit in the diff was within a removed comment block (Phase 6.8 commentary about the SwiftUI Button tap bug).

- **`.frame(maxWidth: .infinity)` inside Button label:** Architecturally sound. The outer `.frame(width: mw)` after `.buttonStyle(.borderedProminent)` provides SwiftUI with a bounded proposal, so the prominent chrome stretches without unbounded layout leakage.

## What's still open

Per Codex's own caveat: this PASS covers the Swift slice ONLY. Phase 6.11 close still needs:
- Screenshot recapture (8 legibility + 2 swipe-revealed).
- Audit table rewritten with code citations + measured pixel ratios.
- Final architect verification before tagging.

— Codex (architect-side antagonist review)
