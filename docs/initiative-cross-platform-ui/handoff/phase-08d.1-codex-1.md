# Phase 8D.1 — Codex review iter-1

**Date:** 2026-05-24
**Verdict:** REVISE → addressed (see remediation below)
**Iteration scope:** Items 1 + 2 + 3 (VoyagerApp + compat shim, 4 screens migrated, 4 controllers added).

## Findings

### HIGH — iOS bridge does not invoke VoyagerApp.bootstrap! (addressed)

`Voyager.build_route` (the Phase 8D.1 compat shim at
`samples/initiative-cross-platform-ui-voyager/app.cr:104`) looks up the
screen registration via `VoyagerApp.registration_for(route.id)`. On
macOS / vanilla Crystal that works because the `screen` macro emits a
module-level `screens[...] = ...` write at compile time. But under the
iOS class-init gap (`src/asset_pipeline/native_app.cr:33-37`), that
side-effecting write may not run when `_main` is hidden for Swift
@main; the framework documents that iOS apps invoke `bootstrap!` from
the bridge entry function (after `Thread.init` / `Fiber.init` /
`Crystal::Once.init`) as the recovery hatch.

Codex pointed out: `VoyagerBridge.initialize_runtime` did NOT call
`VoyagerApp.bootstrap!` before render setup, so the compat shim could
raise `UnknownRouteError` on the first `voyager_render` call when run
under the gap.

**Remediation:** added `VoyagerApp.bootstrap!` call to
`samples/initiative-cross-platform-ui-voyager/ios/bridge.cr`
inside `initialize_runtime` immediately after the probe resets. This
is the minimum-required-correctness fix for the compat shim path;
full iOS migration to the dispatcher remains Phase 8D.2's scope.
Recorded in the implementer report under "iOS bridge minimum change".

### LOW — make macos target underspecifies its source dependencies

`samples/initiative-cross-platform-ui-voyager/Makefile:73` declares
`$(MACOS_BIN)` depends only on `macos/host.cr` and the native bridge
artefacts — not on `app.cr`, `screens/*.cr`, or `controllers/*.cr`.
After Phase 8D.1's edits, `make macos` reports "Nothing to be done"
unless a previous build artefact is missing.

**Disposition:** out-of-scope for Phase 8D.1; the brief explicitly
limits scope to the 6 items. Iteration 1 used a direct
`crystal-alpha build -Dmacos` invocation (and the full `make macos`
ran clean on a fresh `make clean` setup). Logged in the implementer
report so the Makefile dependency tightening can land in a follow-up
phase.

### LOW — "4 HTML files" description inaccuracy

The brief / dispatch text describes the web build as "4 HTML files",
but `web/static_site.cr` emits 11 files (1 light + 1 dark single-page
host, 4 slugs × 2 appearances per-fragment files, and `index.html`).
The web build runs clean post-Phase 8D.1; this is a wording
inaccuracy in the dispatch wording, not a code issue.

**Disposition:** noted in the implementer report; no code change.

## Pass Evidence

- `VoyagerApp` registers all 4 screens via the `screen` macro at
  `app.cr:165` (or near it after iter-1 edits).
- Compat shim signature `Voyager.build_route(state, coord, route)`
  preserved at `app.cr:104`.
- All 4 screens extend `UI::Screen`; callbacks dispatch via
  `Voyager.dispatch(:action_ref[, action_params])`.
- All 4 controllers extend `UI::Controller`, override `dispatch_action`
  with explicit `case`, and raise `UI::Controller::UnknownActionError`
  on unknown action names.
- `SignInController#submit` returns `ReplaceRoot.new(:todos)` (per
  brief stack-policy contract).
- `TodoEditorController#save` reads `ctx.params["todo_id"]` (via
  FormState mount seed) and `ctx.form_state.values["title"]`, returns
  `Pop`.
- `SettingsController#toggle_filter` returns `Rerender`.

## Validation runs (Codex-executed)

- `crystal spec spec/asset_pipeline/voyager_app_spec.cr spec/asset_pipeline/voyager_controllers_spec.cr`
  → 31 examples, 0 failures, 0 errors.
- `crystal spec`
  → 1702 examples, 4 failures, 0 errors, 66 pending. Baseline
  preserved (1671/4/0/66 + 31 new = 1702/4/0/66).
- Web static-site (`make web`) succeeded, wrote 11 files.
- iOS cross-compile (`crystal-alpha --cross-compile --target=arm64-apple-ios-simulator -Dios`)
  succeeded.
- Direct macOS build (`crystal-alpha build -Dmacos`) succeeded.

## Brief inaccuracies recorded (NOT Phase 8B API gaps)

- The brief showed `UI::ScreenContext::Native.new(params:, action_params:, form_state:, session:, flash:)`;
  the actual `ScreenContext::Native#initialize` signature is
  `(form_state, session, flash, design_tokens, navigation, action_params)`.
  No `params:` kwarg — params is derived via `form_state.to_h`.
- Brief showed `UI::Controller::UnknownAction`; the actual error
  class is `UI::Controller::UnknownActionError`.

## API gaps escalated

None. The ActionDispatcher exposes `form_state` / `session` /
`flash` / `design_tokens` / `navigation` getters that are sufficient
to build a `ScreenContext::Native` at host rebuild time (the Phase
8B spike pattern). No `current_context` accessor needs to be added.

— Codex iter-1 review captured at `/tmp/codex-iter1.log`.
