# Phase 8D.1 — Architect Reflection

**Phase:** 8D.1 — Voyager Native Unification (macOS-first)
**Date closed:** 2026-05-25 (PASS_WITH_NOTES)
**Branch merged:** `phase-08d.1-voyager-native-unification` → `feature/utility-first-css-asset-pipeline`
**Final HEAD:** `68165093`
**Tag:** `phase-08d.1-pass-with-notes-2026-05-25`

## Verdict

PASS_WITH_NOTES. The architectural spine is in place: Voyager macOS now runs on `VoyagerApp < UI::App` with 4 `UI::Controller` subclasses dispatching all user-intent callbacks through `UI::ActionDispatcher`. Visual output is byte-identical to pre-migration across all 4 routes. The unified architecture is no longer hypothetical on a real app — it is shipping in the canonical demo.

The open note is the **deferred live interactive hand-test**: the implementer was sandboxed and could not drive AppKit events against a live NSWindow. Coverage is provided by byte-identical visual captures + 5 dispatcher integration specs + Codex's reachability audit of all 14 dispatch sites. Per owner directive (path 2), live hand-test is folded into Phase 8D.3's scope.

## What shipped

### Item 1 — `VoyagerApp < UI::App` declaration + compat shim
`samples/initiative-cross-platform-ui-voyager/app.cr`. `VoyagerApp` class with `initial_route :sign_in` + 4 `screen` macros. `Voyager.build_route` retained as the compat shim that keeps iOS bridge + web static-site compiling during the 8D.1 → 8D.2 window.

### Item 2 — 4 `UI::Screen` subclasses
`screens/{sign_in,todos,todo_editor,settings}.cr` refactored. All user-intent callbacks now action refs (Symbol or `{Controller, :action}`) per the action ref convention. No direct `coord.push` in any screen build method.

### Item 3 — 4 `UI::Controller` subclasses
New `controllers/{sign_in,todos,todo_editor,settings}_controller.cr`. SignInController#submit returns `ReplaceRoot.new(:todos)` (NOT Navigate) — Sign-in is not in back stack. TodoEditor params propagation follows the codex-recommended pattern: action_params at edge, Navigate.params → ctx.params for the next mount.

### Item 4 — macOS host migration
`macos/host.cr` migrated to use `UI::ActionDispatcher`. Mount-before-publish discipline preserved: dispatcher calls `mount_screen` before coord.notify; the on_change subscriber renders the dispatcher's already-mounted screen via existing getters (form_state / session / flash / design_tokens / navigation). No `current_context` API addition was needed — the spike's getter pattern already covers this.

### Item 5 — 8 captures + visual regression bar
4 baseline + 4 postmigration captures via offscreen render path. **All 4 pairs SHA-256 byte-identical.** The offscreen capture exercises both pre- and post-migration code paths against the same screens; zero pixel drift.

### Item 6 — Dispatcher integration specs
`spec/asset_pipeline/voyager_dispatcher_integration_spec.cr` with 5 scenarios (4 from the brief + 1 bonus). Per-screen specs DROPPED per Codex finding 7; per-controller specs (31 examples) + dispatcher integration (5 examples) provide better integration coverage than the originally-proposed per-screen layer.

## What's open (carried to 8D.2 / 8D.3)

- **iOS bridge migration** — still calls `Voyager.build_route` shim. Phase 8D.2 wires the iOS bridge to `UI::ActionDispatcher` and removes the iOS dependency on the shim. This also closes Phase 8B's deferred iOS dispatcher work.
- **Live interactive hand-test** — owner's "I want to experience it" pass [[owner-hands-on-finds-real-bugs]]. Deferred to 8D.3.
- **14-row behavior contract captures** — 28 iOS captures + macOS equivalents. Phase 8D.3 closing-gate.
- **Web shim disposition** — `Voyager.build_route` still used by `web/static_site.cr`. Phase 8D.3 evaluates whether to remove (migrate web to direct screen.build calls) or keep permanently as the static-site interface.
- **SecureField bridge limitation** — pre-existing, not touched in 8D.1.
- **Brief inaccuracies recorded by implementer** — `ScreenContext::Native#initialize` signature differs from brief (actual: form_state/session/flash/design_tokens/navigation/action_params; params derived from form_state.to_h); actual error class is `UI::Controller::UnknownActionError`; web build emits 11 files not 4. None blocked the implementer; documented in the report.

## Lessons

### The byte-identical-screenshot guarantee is the right closing gate for visual-output migrations

When a phase's architectural change is supposed to be a transparent refactor (same UI, new internals), comparing offscreen captures byte-for-byte is sharper than any pixel-diff threshold or visual review. The implementer ran the SAME offscreen capture against both the pre-migration and post-migration code; the bytes matched. That's a stronger guarantee than "the audit harness said it looked the same."

This pattern generalizes: for any phase where the architectural promise is "no visible change," require byte-identical SHA-256 across baseline + post-migration captures. It eliminates the entire class of "but the audit signed off and it still broke" failures.

### Codex co-planning + critique two-step worked

Phase 8D.1 used Codex twice:
1. **Co-planner** (early): structured the 3-sub-phase split, picked B2 web architecture, ratified Voyager::State singleton retention, mandated all callbacks through dispatcher.
2. **Antagonist** (mid): brief v1 → REVISE with 9 findings (2 BLOCKER, 3 HIGH, 4 MEDIUM). All addressed in brief v2.

The co-planner role surfaces structural decisions; the antagonist role surfaces brief defects. Same model, different prompt framing. The Codex CLI's intermittent output behavior was worked around with arg-form prompts + medium reasoning + tee for stdout capture — the only invocation pattern that reliably produced formatted output this session.

### Compat shims unblock phased migrations cleanly

`Voyager.build_route` was supposed to be removed in 8D.1. Codex finding 1 caught that iOS + web would stop compiling. Retaining the shim with a thin wrapper that calls `registration.screen_class.new.build(ctx)` allowed the macOS migration to land fully while leaving iOS + web on the old call path. The shim doesn't break the architectural claim — it just defers the migration of those targets to their dedicated sub-phases.

The lesson: when a sub-phase migrates ONE target, write a compat shim for the others, even if it's "obviously trivial" to remove. The trivial removal usually isn't.

## Bookkeeping

- 2 implementer commits + 1 architect planning commit on `phase-08d.1-voyager-native-unification`.
- 4 planning artifacts committed: `scoping-8d.md`, `coplan-8d-codex-1.md`, `brief-8d.1.md` (v1 + v2), `codex-critique-1-brief-8d.1.md`.
- 2 implementer-side Codex reviews: `phase-08d.1-codex-1.md` (REVISE → addressed), `phase-08d.1-codex-2.md` (PASS_WITH_NOTES, 0 findings).
- Spec: 1671/4/0/66 → **1707/4/0/66** (+36 new examples, same 4 pre-existing failures).
- Tag: `phase-08d.1-pass-with-notes-2026-05-25`.
- Hand-test gate deferred to 8D.3 per owner directive.

— Architect (Claude Opus 4.7)
