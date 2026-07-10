# Phase 6.10 Remediation 4 — Codex Review 2

**Date:** 2026-05-23
**Reviewer:** Codex (`codex exec --sandbox read-only`, model gpt-5.5, reasoning xhigh)
**Branch:** `phase-06.10-navigable-crud-demo` (continuation work atop `b1bd8ef`, still uncommitted at time of review)
**Prior review:** `handoff/phase-06.10-remediation-4-codex-1.md` (REGRESSION + NEEDS_WORK — 1 × P1, 4 × P2)
**Continuation prompt:** `/tmp/codex-rem4-cont-prompt2.txt` (verbatim below)

## Headline verdict

**PASS across the board.** All 5 prior Codex findings closed in the
continuation diff; no new regressions detected in the static review.

## Per-item closure verdicts (Codex final output)

| Prior finding | Continuation fix location | Verdict |
|---------------|---------------------------|---------|
| P1 SECURITY — `CallbackBridge.fireString` NSLog leaked SecureField text | `swift/.../CallbackBridge.swift:159` (NSLog wholesale removed from both `fire` and `fireString`) | **PASS** |
| P2 WEB LAYOUT — root_fill `width:100%` overflowed under content-box | `src/ui/renderers/web_renderer.cr:2405` (now also emits `box-sizing: border-box`) | **PASS** |
| P2 MACOS LAYOUT — `objc_macos_screen_width` returned physical screen | `src/ui/native/objc_bridge.m:367, 384` (now queries the active NSWindow's contentView frame) | **PASS** |
| P2 WEB FALLBACK LEAK — fallback DeviceMetrics returned iPhone safe-area insets | `src/ui/design_tokens.cr:1111` (now zero-insets); `spec/ui/device_metrics_spec.cr:21` (now asserts `eq(0.0)`) | **PASS** |
| P2 NEEDS_WORK — VoyagerVisualTests save-propagation didn't assert | `samples/.../ios/UITests/VoyagerVisualTests.swift:241` (real `XCTAssertTrue(propagated, ...)`) | **PASS** |

## Codex's verbatim final message

```
No blocking findings. All five prior findings are closed in the current worktree.

Notes:
- Source scan for `voyager-(save-chain|interaction-proof)` is clean. Tracked
  docs/evidence still contain historical references, but not tracked source
  files.
- `spec/ui/device_metrics_spec.cr` exists and passes, but it is currently
  untracked.
- I did not run native iOS/macOS UI automation; I did run `git diff --check`,
  `crystal spec spec/ui/device_metrics_spec.cr`,
  `crystal spec spec/ui/voyager_state_propagation_spec.cr`, and
  `crystal spec spec/components/examples/example_components_spec.cr`.

Evidence:
- `CallbackBridge.fireString` no longer logs raw values, and `fire` has no
  NSLog (CallbackBridge.swift:159).
- Web `root_fill` emits `width: 100%` plus `box-sizing: border-box`
  (web_renderer.cr:2405).
- macOS width/height now use active window `contentView.frame`
  (objc_bridge.m:367, objc_bridge.m:384).
- Device fallback zeros all four safe-area fields; spec asserts top/bottom
  zero (design_tokens.cr:1111, device_metrics_spec.cr:21).
- Save propagation now has a real XCTAssertTrue(propagated, ...)
  (VoyagerVisualTests.swift:241).

Structured verdict:
- Item 1: PASS
- Item 2: PASS
- Item 3: PASS
- Item 4: PASS
- Item 5: PASS
- New regressions: none found in static diff review
```

## Additional continuation work covered (not in Codex's 5-item closure)

Beyond closing the prior findings, the continuation iteration also:

- **Closed Item 6 (Sign-in button post-fix capture).** Captured at
  `phase-06.10-remediation-4-evidence/voyager-ios-signin-iphone17pro-after.png`
  on the booted iPhone 17 Pro sim — the Sign-in button is fully inside
  the screen bounds (x >= 0, x + width <= screen_width).
- **Captured macOS fluid-resize evidence at 3 widths** —
  `voyager-macos-todos-{default,narrow,wide}.png` (880 / 480 / 1280 pt
  capture windows). Default + wide show clean reflow; narrow exposes
  that the in-screen author code uses `Spacer` between title + Settings
  button so the button hugs the right edge (which on a 480pt-wide
  window can clip — this is a per-screen design concern, not a
  framework root_fill bug).
- **Reordered macOS host to create the NSWindow BEFORE the first
  `build_route`** so the first paint reads live `contentView.frame` via
  the AppKit DeviceMetrics provider — closes the secondary observation
  Codex flagged as PROGRESS in its first continuation pass (before
  Codex re-reviewed the fix and upgraded to PASS).
- **Reverted incidental `spec/test_js/some_js.js` fixture churn** that
  Codex flagged as non-functional dirty file in its first continuation
  pass.

## Iteration trail

1. **Codex 1 (handoff/phase-06.10-remediation-4-codex-1.md)** —
   REGRESSION + NEEDS_WORK. Prior Implementer's diff had P1 NSLog leak,
   P2 layout/fallback regressions, and a non-asserting test.
2. **Completion blocker (handoff/phase-06.10-remediation-4-completion-blocker.md)** —
   prior Implementer agent stopped mid-action; Completion agent ran Codex
   1, saw REGRESSION, escalated without committing.
3. **Continuation Implementer (this dispatch)** — closed all 5 prior
   findings + the 2 unverified Item 1/Item 3 brief items + the macOS
   resize evidence the brief required.
4. **Codex 2 (this file)** — PASS across the board.

## Codex prompt (verbatim)

```
You are reviewing the uncommitted changes in this repo (run `git diff` first
to see them all).

Context: Phase 6.10 Remediation 4 continuation. The prior Codex review
flagged 1 × P1 + 4 × P2 regressions. This continuation iteration is
intended to close them.

Confirm whether each of these 5 prior findings is closed by the CURRENT
uncommitted diff:

1. P1 SECURITY: ... CallbackBridge.swift ... NSLog of raw value removed ...
   no diagnostic tokens voyager-(save-chain|interaction-proof) remain ...
2. P2 WEB LAYOUT: web_renderer.cr root_fill emits box-sizing: border-box ...
3. P2 MACOS LAYOUT: objc_bridge.m macOS uses NSWindow contentView frame ...
4. P2 WEB FALLBACK LEAK: design_tokens.cr fallback zero safe-area ...
5. NEEDS_WORK TEST: VoyagerVisualTests testSavePropagation has
   XCTAssertTrue(propagated, ...) ...

For each of these 5 items output: PASS / PROGRESS / REGRESSION.
Surface ANY new regressions introduced ...
```

— Continuation Implementer (Phase 6.10 Rem 4)
