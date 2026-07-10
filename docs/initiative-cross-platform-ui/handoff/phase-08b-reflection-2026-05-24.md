# Phase 8B — Architect Reflection

**Phase:** 8B — Native UI::App + UI::Controller + UI::ActionDispatcher + UI::FormState
**Date closed:** 2026-05-24 (PASS_WITH_NOTES)
**Branch:** `phase-08b-native-app-controller` (merging to feature branch)
**Final HEAD:** `0427407f`
**Tag:** `phase-08b-pass-with-notes-2026-05-24`

## Verdict

PASS_WITH_NOTES. All 6 items + macOS spike landed with closing-gate read-back proof ("Welcome, seth@example.com" visible in Todos after Sign-in). Notes carried forward: iOS spike deferred per BEST-EFFORT brief clause; interactive-typing click-trace deferred to Phase 8D; SecureField bridge limitation (empty string on change) pre-existing and unchanged.

## What shipped

### Item 1 — `UI::App` base class

`src/asset_pipeline/native_app.cr`. Macros: `initial_route`, `screen`, `design_tokens`. `UI::App::ScreenRegistration` record + `registration_for(route_id)` lookup + `UnknownRouteError`. **Codex caught 5 REVISE rounds** on this item — the iOS class-init gap discipline forced re-architecting class-var initialization patterns. Final form: macro-emitted compile-time-named class methods (`_bootstrap_screen_*`) enumerated by an inheritance-time `macro inherited { macro finished { ... } }` bootstrap.

### Item 2 — `UI::Controller` base class

`src/asset_pipeline/native_controller.cr`. Action helpers + `before_action` macro. Explicit per-controller `dispatch_action` override (NOT runtime registry, per Codex finding #1 on the brief). REVISE → APPROVE_WITH_NOTES.

### Item 3 — `UI::ActionResult` hierarchy

`src/asset_pipeline/action_result.cr`. 5 subtypes: Navigate / Pop / Rerender / ReplaceRoot / RenderInline. Single-pass APPROVE.

### Item 4 — `UI::FormState` + renderer hook

`src/ui/form_state.cr` + AppKit/UIKit renderer modifications. Mount-token bookkeeping; `UI::FormStateRendererHook.wrap_text_handler` / `wrap_secure_handler` guard BOTH the form_state write AND the user's on_change. Token mismatch = entire wrapped callback is a no-op (full no-op, not partial). REVISE → APPROVE_WITH_NOTES.

### Item 5 — `UI::ScreenContext::Native` + Session/Flash

`src/asset_pipeline/native_context.cr`. **params + action_params SEPARATE accessors** per Codex finding #2 on the brief — no silent merge. `UI::Session::InProcess` + `UI::Flash::InProcess` concrete impls. REVISE → APPROVE_WITH_NOTES.

### Item 6 — `UI::ActionDispatcher`

`src/asset_pipeline/action_dispatcher.cr`. **2 REVISE rounds** to converge — Codex caught a mount-before-publish ordering bug (renderer's on_change subscriber needed to see `UI::FormState.current` already pointing at the new mount BEFORE coord.notify fires), plus a Pop ordering spec false-positive. Final architecture: `translate_result` always calls `mount_screen(next_route)` BEFORE the coord mutation; since `NavigationCoordinator#notify` fires synchronously, wire-time captured callbacks match the new mount.

### Item 7 — macOS spike + screenshots

`samples/phase-08b-native-spike/` (NEW). SignInScreen + TodosScreen, SignInController + TodosController, macOS host using NavigationCoordinator + ActionDispatcher. **Closing-gate read-back proof verified visually:** `findings-macos-todos-with-name.png` shows "Welcome, seth@example.com" — the email typed into the Sign-in TextField flowed all the way through FormState → controller.submit(ctx) → session → TodosScreen.build(ctx) → rendered label. REVISE → APPROVE_WITH_NOTES.

## What's open (carried to Phase 8D)

- **iOS spike:** deferred per brief's BEST-EFFORT clause. macOS was the gate. Phase 8D's Voyager migration will wire `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` to use `UI::ActionDispatcher`.
- **Interactive-typing click-trace:** the spike used `PHASE8B_AUTOFILL_EMAIL` env var to write directly to FormState — proves the end-to-end carry-through but doesn't exercise a real keyboard event into a TextField. Phase 8D's Voyager hand-test gate will close that.
- **SecureField bridge limitation:** SwiftKit's `apsk_secure_field_*` bridge emits `""` on change instead of the real value (pre-existing limitation predating Phase 8B). Documented in renderer + helper module. Phase 8D or a separate cleanup phase can address.

## Lessons (saved or to save)

### iOS class-init gap discipline became architectural

Phase 6.10's `bridge.cr` Bytes-allocation workaround taught us the iOS embedding hides `_main`, so default-initialized class-vars on user code don't always fire. Phase 8B Item 1 (UI::App) had 5 REVISE rounds because EVERY macro-registered piece of state had to use compile-time-named class methods + macro-inherited enumeration. This is now the standard pattern for library-level state in any class that subclasses can register against. The lesson `[[project_crystal_ios_class_init_gap]]` was applied at scale here for the first time.

### Mount-before-publish is a real ordering invariant

Naively, the dispatcher could `coord.push(next_route)` (which fires `notify` synchronously) and then `mount_screen(next_route_id)` (which creates the new FormState). But the renderer's on_change subscriber rebuilds the view tree on `notify`, and the new TextField views' on_change handlers capture `UI::FormState.current` at wire-time. If `current` still points at the OLD mount when the renderer runs, the new mount's FormState never receives any updates. Codex caught this on iter 4; the fix is `mount_screen` BEFORE `coord.push`. Phase 8C/8D must preserve this invariant.

### Full-callback no-op beats partial gating

Initial FormState design gated only the `form_state.update(name, value)` call on token-match. Codex caught: the user's own `on_change` block could still fire as a side-effect on stale taps. Fixed by wrapping the ENTIRE callback in a token-match guard. Lesson: when adding stale-callback protection, gate the whole closure, not just the framework-level write.

## Bookkeeping

- 23 commits on `phase-08b-native-app-controller`.
- 5 Codex iteration reviews (14 Codex passes including revisions). 0 REJECT. 0 blocker escalations.
- Spec: 1576/4/0/66 → **1659/4/0/66** (+83 new examples, same 4 pre-existing failures).
- Tag incoming: `phase-08b-pass-with-notes-2026-05-24`.
- Voyager builds + runs UNCHANGED.

— Architect (Claude Opus 4.7)
