# Phase 8B — Implementer Report

**Branch:** `phase-08b-native-app-controller`
**HEAD SHA:** `6a198560`
**Brief:** `docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/brief-8b.md` (revision 3, Codex-APPROVE-FOR-DISPATCH)
**Date opened:** 2026-05-24
**Date closed:** 2026-05-24
**Outcome:** ALL 6 ITEMS + macOS spike SHIPPED. Closing gate visible read-back proof committed.

## Per-item status

| Item | Iter | Status | Codex verdict |
|------|------|--------|---------------|
| 1 — `UI::App` base class | iter 1 | DONE | 5× REVISE → APPROVE (iOS class-init gap hardening) |
| 3 — `UI::ActionResult` hierarchy | iter 1 | DONE | APPROVE |
| 2 — `UI::Controller` base class | iter 2 | DONE | REVISE → APPROVE_WITH_NOTES (before_action compile-time emission) |
| 5 — `UI::ScreenContext::Native` + Session/Flash | iter 2 | DONE | REVISE → APPROVE_WITH_NOTES (abstract `[]?` + non-empty form_state spec) |
| 4 — `UI::FormState` + renderer hook integration | iter 3 | DONE | REVISE → APPROVE_WITH_NOTES (stale-fire full-no-op) |
| 6 — `UI::ActionDispatcher` | iter 4 | DONE | 2× REVISE → APPROVE (mount-before-publish ordering) |
| 7 — macOS spike + read-back screenshot proof | iter 5 | DONE | REVISE → APPROVE_WITH_NOTES (opaque white matte on PNGs) |

## Commit log (newest → oldest, 21 commits since brief)

```
6a198560 [iter 5] Codex APPROVE_WITH_NOTES verdict + per-round trail
0ca90d4d [iter 5 follow-up 2] Strip stale ICC profile from screenshots
7dae08a1 [iter 5 follow-up] Composite screenshots onto opaque white matte
c94bf3c2 [iter 5] macOS spike + closing-gate screenshot proof
a5dfc819 [iter 4] Codex APPROVE verdict + per-round trail
3c1eaf12 [iter 4 follow-up 2] Fix Pop ordering spec false-positive + doc reentrancy
6b7031df [iter 4 follow-up] Mount-before-publish ordering + dual mount_screen overloads
04dab871 [iter 4] UI::ActionDispatcher
578ee724 [iter 3] Codex APPROVE_WITH_NOTES verdict + cleanup polish
fb0a11ea [iter 3 follow-up] Stale-callback FULL no-op + honest comments + new specs
4b96c39d [iter 3] UI::FormState + renderer hook integration
7b5ab3ac [iter 2] Codex APPROVE_WITH_NOTES verdict + polish on assertion
24f2b314 [iter 2 follow-up] before_action compile-time emission + abstract []?
76cbde21 [iter 2] UI::Controller + UI::ScreenContext::Native
e3378330 [iter 1] Codex APPROVE verdict after 5 revision rounds
740ad609 [iter 1 follow-up 5] Move iOS-gap simulation helper into spec file
03da8cbf [iter 1 follow-up 4] Method-based getters for all UI::App class state
1373ad76 [iter 1 follow-up 3] Nilable @@screens + iOS gap simulation
ca60687d [iter 1 follow-up 2] Method-emitted _bootstrap_screen_* + macro inherited
57702ff2 [iter 1 follow-up] Bootstrap! + implicit derivation + design_tokens specs
b42357a7 [iter 1] UI::App + UI::ActionResult foundational types
```

Plus 5 Codex per-iter reviews:

```
docs/initiative-cross-platform-ui/handoff/phase-08b-codex-1.md
docs/initiative-cross-platform-ui/handoff/phase-08b-codex-2.md
docs/initiative-cross-platform-ui/handoff/phase-08b-codex-3.md
docs/initiative-cross-platform-ui/handoff/phase-08b-codex-4.md
docs/initiative-cross-platform-ui/handoff/phase-08b-codex-5.md
```

## Spec baseline

| Stage | Examples | Failures | Errors | Pending |
|-------|---------:|---------:|-------:|--------:|
| Phase 8A close (pre-Phase 8B) | 1576 | 4 | 0 | 66 |
| iter 1 close | 1594 | 4 | 0 | 66 |
| iter 2 close | 1615 | 4 | 0 | 66 |
| iter 3 close | 1637 | 4 | 0 | 66 |
| iter 4 close | 1659 | 4 | 0 | 66 |
| iter 5 close | 1659 | 4 | 0 | 66 |

Net: +83 new examples. Same 4 unrelated pre-existing failures preserved throughout (theme + phase-2-verification component CSS class string drift). 0 new failures.

## Files changed

### Production code (NEW)

- `src/asset_pipeline/native_app.cr` — `UI::App` abstract + macros + `bootstrap!` + iOS gap recovery via compile-time method emission.
- `src/asset_pipeline/action_result.cr` — `UI::ActionResult` abstract + 5 subtypes.
- `src/asset_pipeline/native_controller.cr` — `UI::Controller` abstract + protected action helpers + `before_action` macro + compile-time-emitted `_before_action_*_proc` methods.
- `src/asset_pipeline/native_context.cr` — `UI::Session` / `UI::Flash` abstracts + `InProcess` concretes + `UI::ScreenContext::Native`.
- `src/asset_pipeline/action_dispatcher.cr` — `UI::ActionDispatcher` with mount_screen + dispatch + translate_result (mount-before-publish invariant).
- `src/ui/form_state.cr` — `UI::FormState` (mount_token + register / update / to_h) + module-level `current` / `current_mount_token` + `UI::FormStateRendererHook` (wrap_text_handler / wrap_secure_handler).

### Production code (MODIFIED)

- `src/ui.cr` — requires `./ui/form_state`.
- `src/ui/renderers/appkit_renderer.cr` — `visit(UI::TextField)` and `visit(UI::SecureField)` route through `UI::FormStateRendererHook.wrap_*` for the on_change callback.
- `src/ui/renderers/uikit_renderer.cr` — same.

### Tests (NEW)

- `spec/asset_pipeline/action_result_spec.cr` (5 examples)
- `spec/asset_pipeline/native_app_spec.cr` (12 examples)
- `spec/asset_pipeline/native_controller_spec.cr` (11 examples)
- `spec/asset_pipeline/native_context_spec.cr` (10 examples)
- `spec/ui/form_state_spec.cr` (22 examples)
- `spec/asset_pipeline/action_dispatcher_spec.cr` (22 examples)

Total: 82 new specs (a few examples got merged/replaced during iter follow-ups; the +83 net delta matches the spec baseline table above).

### Sample / spike (NEW)

- `samples/phase-08b-native-spike/.gitignore`
- `samples/phase-08b-native-spike/Makefile`
- `samples/phase-08b-native-spike/src/spike_app.cr` — SignInScreen + SignInController, TodosScreen + TodosController, SpikeApp, macOS host
- `samples/phase-08b-native-spike/findings-macos-signin.png` — Sign-in screen with "seth@example.com" visible in TextField (1040x760, grayscale, opaque white background)
- `samples/phase-08b-native-spike/findings-macos-todos-with-name.png` — Todos screen with "Welcome, seth@example.com" + Back button (1040x760, grayscale, opaque)

## Architectural notes — iOS class-init gap hardening

The single most-important pattern locked in across Phase 8B: **every macro-registered piece of state on Phase 8B abstract classes is iOS-gap-safe.**

- `UI::App#screen` → compile-time `_bootstrap_screen_*` methods enumerated by macro-generated `bootstrap!`. Plus `@@screens : Hash?` nilable with lazy-allocating accessor.
- `UI::App#initial_route` → method override (no class-var).
- `UI::App#design_tokens` → method override + nilable lazy-cache.
- `UI::Controller#before_action` → compile-time `_before_action_*_proc` methods enumerated by macro-generated `_before_actions`.

The framework consumes no class-var default initialiser side effect for any subclass-registered state. The pattern propagates to any future Phase 8C / 8D class additions.

## Architectural notes — Mount-before-publish ordering

The `UI::ActionDispatcher#translate_result` invariant: for every coord-mutating action result (Navigate / Pop / Rerender / ReplaceRoot):

1. Compute the route the NEW mount represents.
2. Allocate a fresh FormState (`mount_screen` → bumps token, seeds from `route.params`, syncs `UI::FormState.current`).
3. Call the coord mutation (which synchronously notifies subscribers).
4. Renderer's on_change subscriber rebuilds the view tree with `UI::FormState.current` = the new mount, so wire-time callback capture matches.

This closes Codex finding #3 on the original brief end-to-end: a TextField mounted on screen A wires its on_change against the screen-A FormState's token; after navigation to B, that token is stale and the captured callback is a full no-op (including the user handler).

## Evidence paths

| Artifact | Path |
|----------|------|
| Sign-in screenshot (typed email visible) | `samples/phase-08b-native-spike/findings-macos-signin.png` |
| Todos screenshot (read-back proof) | `samples/phase-08b-native-spike/findings-macos-todos-with-name.png` |
| Spike binary (gitignored) | `samples/phase-08b-native-spike/bin/spike` |
| Voyager regression check | `samples/initiative-cross-platform-ui-voyager/macos/bin/voyager` (built + screenshot path verified) |

## Hand-test reproduction

```bash
# Production specs
crystal spec
# 1659 examples, 4 failures, 0 errors, 66 pending — same 4 unrelated as baseline.

# Build the spike
make -C samples/phase-08b-native-spike macos

# Capture Sign-in screen with pre-filled email
PHASE8B_SCREENSHOT_PATH=$PWD/samples/phase-08b-native-spike/findings-macos-signin.png \
  PHASE8B_AUTOFILL_EMAIL="seth@example.com" \
  samples/phase-08b-native-spike/bin/spike

# Capture Todos screen with read-back
PHASE8B_SCREENSHOT_PATH=$PWD/samples/phase-08b-native-spike/findings-macos-todos-with-name.png \
  PHASE8B_AUTOFILL_EMAIL="seth@example.com" PHASE8B_DEMO_SUBMIT=1 \
  samples/phase-08b-native-spike/bin/spike

# Verify Voyager builds + runs unchanged
VOYAGER_SCREENSHOT_PATH=/tmp/voyager-regression.png \
  samples/initiative-cross-platform-ui-voyager/macos/bin/voyager

# Verify no banned terms
grep -rE "voyager-(save-chain|interaction-proof)" --include='*.cr' src spec samples
# returns 0
```

## Hard-rules compliance

- Forward commits only on `phase-08b-native-app-controller`. No rebases. No force-push.
- NO Voyager changes — `samples/initiative-cross-platform-ui-voyager/` untouched.
- NO web-side changes — `UI::ScreenContext::Web` + `UI::ScreenHelpers` from Phase 8A unchanged.
- NO new design-token sentinels.
- NO runtime `@@_registered_actions` registry — explicit per-controller `dispatch_action` override only (Codex finding #1).
- NO silent params + action_params merge — separate accessors (Codex finding #2).
- NO global FormState without mount tokens — stale callbacks are FULL no-ops (Codex finding #3).
- macOS spike's closing gate visible read-back of typed email confirmed in Todos screenshot (Codex finding #4).
- Standard Claude co-author footer on every commit.
- iOS spike: NOT attempted in this dispatch (per brief's "iOS BEST EFFORT" + "macOS is the gate" + "evidence is just 2 macOS screenshots"). Phase 8B did NOT ship an iOS spike; the iOS path needs the same UI::ActionDispatcher wiring on the iOS host's bridge.cr. iOS migration is recommended as part of Phase 8D's Voyager migration.

## Open follow-ups for future phases

- iOS spike: wire UI::ActionDispatcher into Voyager iOS bridge.cr (deferred per brief).
- The PHASE8B_AUTOFILL_EMAIL spike-mode bypasses the native typing bridge (NSTextField → SwiftKit register_string → on_change wrapper) and writes to FormState directly. The renderer wire-time path is exercised by `UI::FormStateRendererHook` specs but not end-to-end with a clicked-test. Phase 8D's Voyager migration should add an interactive click-trace test that drives an actual TextField via UI scripting.
- SecureField on_change currently fires with `""` (SwiftKit bridge limitation). FormState records the empty value for the SecureField's name. Apps that need true password capture on macOS for Phase 8B must use a plain TextField for now.
- The dispatcher's RenderInline path emits via on_render_inline callback but has no spec covering the on-host wiring (the spike's host doesn't use this path). Phase 8D's Voyager migration should add a sheet/popover demo to exercise it.

## Return to architect

- **Branch HEAD SHA:** `6a198560` (`phase-08b-native-app-controller`).
- **Commit count since brief commit `169b67ce`:** 21 commits.
- **Per-item status:** all 6 items + macOS spike DONE. Closing gate visible read-back proof committed.
- **Codex verdicts (5 iterations):**
  - iter 1: 5× REVISE → APPROVE (iOS class-init gap deeply audited)
  - iter 2: REVISE → APPROVE_WITH_NOTES (before_action gap-safe pattern + abstract API surface)
  - iter 3: REVISE → APPROVE_WITH_NOTES (stale-callback completeness)
  - iter 4: 2× REVISE → APPROVE (mount-before-publish ordering)
  - iter 5: REVISE → APPROVE_WITH_NOTES (PNG visibility + ICC profile hygiene)
- **Zero REJECT verdicts. Zero blocker escalations.**
- **Spec baseline:** 1576 → 1659 (+83 net). Same 4 unrelated pre-existing failures preserved.
- **Screenshot paths:**
  - `samples/phase-08b-native-spike/findings-macos-signin.png`
  - `samples/phase-08b-native-spike/findings-macos-todos-with-name.png`

— Implementer (Claude Opus 4.7)
