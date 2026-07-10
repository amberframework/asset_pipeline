# Phase 6.10 Remediation 4 — Completion Blocker

**Date:** 2026-05-23
**Author:** Completion Agent (Claude Opus 4.7)
**Branch:** `phase-06.10-navigable-crud-demo`
**Branch HEAD at time of blocker:** `b1bd8ef` (working tree NOT committed)
**Codex review:** `handoff/phase-06.10-remediation-4-codex-1.md`

## TL;DR

The prior Implementer agent stopped mid-action without running Codex or
committing. This Completion Agent ran Codex against the full uncommitted
diff. **Codex flagged 1 × P1 + 4 × P2 issues; at least one P1 and several
P2s are honest regressions on Brief Item 2.** Per the completion
protocol's hard rule ("REGRESSION on any item → STOP, do NOT commit,
return to architect"), the working tree has NOT been committed.

## Verification context (so the architect doesn't have to re-run it)

| Check | Result |
|-------|--------|
| `crystal spec` (unit baseline) | **1497 / 4 / 0 / 66** — pre-existing 4 failures (Phase 2 verification + UI::Theme empty-string spec); no new regressions. +7 examples vs Rem 3 baseline (1490/4/0/66), accounted for by `spec/ui/device_metrics_spec.cr` (new file, untracked). |
| `make -C samples/.../voyager macos` | **PASS** (after rebuilding `swift/AssetPipelineSwiftKit/.build/release` — the `release` symlink was pointing at `arm64-apple-ios-simulator/release` because the previous build was iOS; running `swift build -c release` from the SwiftKit dir flipped it back to `arm64-apple-macosx/release` and the macOS link succeeded). |
| `make -C samples/.../voyager ios` | **PASS** (clean xcodebuild for `iPhone 17 Simulator`). |
| `crystal-alpha spec spec/ui/` (AX) | Not run — out of scope per protocol (Rem 3 documented XCUI tap synthesis can't reliably drive these in the agent env). |

The unit-spec baseline is healthy; no regressions there. The regressions
Codex identified are runtime / rendering regressions in the web + macOS
root-fill paths and a security regression in the SwiftKit string callback
bridge.

## Per-item disposition

### Item 1 — Save-propagation fix → NEEDS_WORK (test does not assert)

Architecture work appears in place:

- `swift/.../CallbackBridge.swift` adds `fireString` for TextField string
  callbacks (so closures like `->(value : String) { draft.title = value }`
  work, replacing the previous length-only signal).
- `samples/.../ios/Sources/ContentView.swift` adds a `renderVersion`
  counter, bumps `.id("\(slug)#\(renderVersion)")`, and implements
  `updateUIView` to defensively swap the Crystal root inside the existing
  UIScrollView wrap on slug/version change.
- `samples/.../screens/todo_editor.cr` + `todos.cr` updated to mutate
  state through the new string callbacks.
- 4 evidence captures saved at `phase-06.10-remediation-4-evidence/save-propagation-step{1,2,3,4}*.png` and 4 `voyager-save-chain*.log` files.

Codex P2 finding (`VoyagerVisualTests.swift:238-240`): the new save-
propagation XCUITest sets a local `propagated` boolean but only attaches
it as an attachment — never `XCTAssert(propagated, ...)` — so the test
green-lights even when the chain breaks.

This is a NEEDS_WORK (test cosmetics, not a functional regression). On
its own it would not block the commit; combined with the Item 2 P1+P2
regressions it stays open.

### Item 2 — Framework device-aware utilities → REGRESSION

Codex identified four distinct problems introduced by the device-metrics
+ root-fill scaffolding:

1. **[P1, SECURITY]** `swift/.../CallbackBridge.swift:181` — the new
   `fireString` NSLogs the raw `value` BEFORE the token guard. SecureField
   text now appears in the unified log every keystroke (the prior `fire`
   bridge only logged numeric `value: Double`; this is a new privacy
   regression introduced specifically by Rem 4). The
   `[voyager-interaction-proof]` marker tag is the same one Rem 3 used
   for diagnostic instrumentation — that pattern doesn't translate
   safely to string-valued callbacks.

2. **[P2, WEB LAYOUT]** `src/ui/renderers/web_renderer.cr:2398-2401` —
   new `root_fill` branch emits `width: 100%` without `box-sizing:
   border-box`. Voyager screens all set padding, so under the browser's
   default content-box sizing the root overflows horizontally by exactly
   `padding-left + padding-right`. The web static-site output (the
   primary deliverable for the state-propagation litmus) is now
   regressed.

3. **[P2, MACOS LAYOUT]** `src/ui/native/objc_bridge.m:364-368` — the
   macOS `DeviceMetrics.content_width_pt` returns the physical screen
   width, but `root_fill` consumes that value as the width-pin. In the
   880px / 720px Voyager + screenshot windows that produces a root view
   wider than the window content area, clipping or horizontal scrolling,
   and breaking the fluid-resize acceptance bullet from the brief.

4. **[P2, WEB / FALLBACK LEAK]** `src/ui/design_tokens.cr:1110-1111` —
   the fallback `DeviceMetrics.current` provider hard-codes iPhone-shaped
   safe-area values (95px top / 82px bottom etc.). Static web generation
   runs before any per-renderer provider is installed, so the canonical
   web output now gains iPhone-shaped safe-area padding. Brief design
   constraint: "Do NOT hardcode iPhone 17 Pro dimensions" — the spirit
   of that constraint is violated when the fallback bakes in iPhone
   safe areas as the universal default.

#1 alone is enough to block the commit (password leak in CI / production
logs is a P1 security regression). #2-#4 together regress web + macOS
where Rem 3 was green.

The brief's acceptance for Item 2 explicitly requires:
- iPhone 17 Pro full-screen edge-to-edge.
- macOS resize fluid reflow.
- `crystal spec` baseline preserved (this IS preserved — unit tests
  don't exercise the rendering code paths Codex flagged).

The first two are owner-hand-test gated, so we can't confirm them from
this seat; but #2 and #3 from Codex tell us they're broken on the macOS
side regardless.

### Item 3 — Off-screen Sign-in button → NOT DIRECTLY ASSESSED

Codex did not single this out in its top-level findings. Diff inspection
shows:

- `samples/.../screens/sign_in.cr` lost the wide-button width and now
  uses `root_fill: true` on its `UI::VStack` with a smaller `max_w` on
  the Sign-in button.
- `samples/.../ios/UITests/VoyagerVisualTests.swift` adds frame-bounds
  assertions for the Sign-in button.

Whether the new sign-in frame is on-screen on iPhone 17 Pro requires
owner hand-test or a clean iOS simulator launch — the evidence dir
contains earlier-iteration sign-in captures (`voyager-ios-signin-iter1*.png`)
but no post-fix captures explicitly labeled as proving the Item 3 fix.
The Implementer's intent here is plausible but the proof artifact is
ambiguous.

## Why the completion agent stopped

The completion protocol section 3 in the activation message reads:

> **Any REGRESSION:** STOP. Do NOT commit. Write
> `handoff/phase-06.10-remediation-4-completion-blocker.md` explaining
> which item regressed and the codex citation. Return to architect — do
> NOT attempt to fix the regression yourself.

Codex's findings include at least one clear regression (the SecureField
password leak — Rem 3's prior diff did not have a string-bridge, so this
is unambiguously NEW with Rem 4), so per the rule I have not committed
and am escalating.

## Uncertainty about the prior Implementer's intent

Because the prior Implementer stopped mid-action, the following are
uncertain and the architect should resolve before any rework commits:

1. **Was the `[voyager-interaction-proof]` NSLog on `fireString`
   intentional debug code that the prior agent planned to redact before
   commit?** If so, Rem 4 closing requires deleting line 181 of
   `CallbackBridge.swift` (parallel to the Rem 3 cleanup item the
   architect already flagged as "first action of whoever closes Item 1").

2. **Is the macOS `DeviceMetrics` "physical screen vs window content"
   distinction known to the prior agent?** The brief explicitly says use
   `NSScreen.mainScreen.frame` — Codex says that's exactly what landed,
   but the consequence (root wider than the window) was apparently not
   measured. The prior agent's macOS evidence capture is
   `voyager-macos-todos-default-720x640.png` — only one screen, one
   size, no resize trace, no proof of fluid reflow. The Implementer
   appears to have stopped before completing the macOS resize evidence
   the brief required.

3. **The Sign-in button frame fix has no labeled "after" capture.** Only
   pre-fix iter1 captures exist. The Implementer may have intended to
   capture a clean post-fix sign-in screenshot but did not.

4. **`spec/ui/device_metrics_spec.cr` is untracked.** The Implementer
   added it but did not stage it. Whether it passes is now part of the
   1497 / 4 / 0 / 66 number (Crystal picks up `spec/` recursively), so it
   does pass — but the architect should confirm the assertions match
   intent.

5. **No `handoff/phase-06.10-remediation-4-implementer-report.md`
   exists.** Per the protocol the Implementer was required to write it
   before signoff. The Completion Agent did not write it because the
   regression gate fired first — the architect or the next iteration
   needs to compose the canonical implementer report after the
   regressions close.

## What the architect needs to decide

1. **Dispatch a fixup iteration** (Rem 4 iter 2) that addresses Codex's
   5 findings:
   - P1: redact / drop the `value` from `CallbackBridge.fireString`'s
     NSLog (or remove the line wholesale once interaction-proof is no
     longer needed).
   - P2: emit `box-sizing: border-box` (or equivalent) on `root_fill`
     web roots in `web_renderer.cr`.
   - P2: change the macOS `DeviceMetrics` provider to return the
     active `NSWindow` content view size, not `NSScreen.mainScreen.frame`.
   - P2: change the default `DeviceMetrics.current` fallback to
     zero-safe-area (or branch on `flag?(:ios)` so web/macOS never see
     iPhone insets).
   - P2: add `XCTAssert(propagated, ...)` to `VoyagerVisualTests`'s save-
     propagation test so it actually fails on regression.

2. **OR scope-reduce** the rendering regressions out of Item 2 (e.g.
   defer the safe-area-leak fix to a later phase and only enforce P1 +
   the macOS window-sizing fix as Rem 4 acceptance). This is the
   architect's call.

3. **Decide who owns capturing the Item 3 "after" screenshot** — owner
   hand-test or next iteration.

## Files in working tree (uncommitted)

```
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr
samples/initiative-cross-platform-ui-voyager/ios/project.yml
samples/initiative-cross-platform-ui-voyager/screens/settings.cr
samples/initiative-cross-platform-ui-voyager/screens/sign_in.cr
samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr
samples/initiative-cross-platform-ui-voyager/screens/todos.cr
spec/test_js/some_js.js                       # incidental — modified by `crystal spec` test fixture
src/ui/design_tokens.cr
src/ui/native/callback_registry.cr
src/ui/native/objc_bridge.m
src/ui/native/swiftkit_bridge.m
src/ui/renderers/appkit_renderer.cr
src/ui/renderers/uikit_renderer.cr
src/ui/renderers/web_renderer.cr
src/ui/view.cr
swift/.../AssetPipelineSwiftKit/CallbackBridge.swift
swift/.../AssetPipelineSwiftKit/Facades/TextFieldFacade.swift
spec/ui/device_metrics_spec.cr                # NEW (untracked)
```

The working tree is preserved exactly as the prior Implementer left it,
plus a `.build/release` symlink flip on `swift/AssetPipelineSwiftKit/`
that's not tracked (it's a build artifact).

— Completion Agent (Phase 6.10 Rem 4)
