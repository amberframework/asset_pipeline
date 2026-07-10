# Phase 8C — Codex iter-1 review (Items 1 + 2)

**Branch:** `phase-08c-routes-for-app`
**Iteration scope:** brief-8c.md Items 1 + 2 — extend `UI::App::ScreenRegistration` + `screen` macro with web route metadata, ship `UI::AmberIntegration.routes_for(app_class)` macro.

## Initial review — commit `6be6eb1d`

**Codex verdict:** REVISE.

Codex empirically verified that the twin-emission mechanism + `routes_for` macro works against the FULL `Amber::DSL::Router` surface — a smoke test compiled `class SmokeApp < UI::App; screen :sign_in, web_controller: AmberCtrl, web_path: "/", web_actions: [...]; end` inside `Amber::Server.configure { routes :web { routes_for(SmokeApp) } }` and successfully printed `phase08croutesmokecontroller#index,phase08croutesmokecontroller#submit` as registered routes. The architectural mechanism is sound and proven end-to-end.

### Findings

* **MAJOR 1** — `src/asset_pipeline/native_app.cr:136` made `screen_class` nilable but Phase 8B's native spike (`samples/phase-08b-native-spike/src/spike_app.cr:172`) still called `registration.screen_class.new`, failing with `no method 'new' for Nil`.
* **MAJOR 2** — `src/asset_pipeline/native_app.cr:218` reordered the `screen` macro signature to place `web_controller` as the third positional. Phase 8B's `screen :foo, FooController, CustomScreen` form silently re-bound `CustomScreen` to `web_controller`. The dropped `*` separator was not guarded by type checks for class-vs-class positional misuse.
* **MINOR 1** — `has_web` inconsistency: compile-time `has_web` treated `web_controller` alone as a web binding (emitted marker + class macro), but runtime `ScreenRegistration#has_web?` returned false for the same registration. Registrations with bare `web_controller` would emit a marker but no routes.
* **MINOR 2** — Macro-raise verification used source-grep instead of fixture-based shell-out to `crystal build`. A grep miss-finds re-located guards.

### Rev 1 — commit `8146efa7`

Implementer addressed all 4 findings:

* MAJOR 1: `samples/phase-08b-native-spike/src/spike_app.cr` now explicitly nil-checks `registration.screen_class` and raises with a helpful message.
* MAJOR 2: macro signature reordered to `(route_id, controller = nil, screen_class = nil, web_controller = nil, web_path = nil, web_actions = nil)` — `screen_class` pinned at the third positional slot so Phase 8B's legacy form survives unchanged.
* MINOR 1: tightened compile-time `has_web` to require `web_path` OR `web_actions`. Bare `web_controller` triggers a new `{% raise %}` guard.
* MINOR 2: added `spec/fixtures/phase_08c_macro_raise/*.cr` fixture files. Spec cases (e), (f), and (e2) now shell out to `crystal build --no-codegen` and assert the failure diagnostic.

## Re-review — commit `8146efa7`

**Codex verdict:** REVISE.

Codex confirmed everything compiles + all specs pass + all macro-raise fixtures fail with intended diagnostics. Two MINOR findings remained:

* **MINOR 1** — Bare-web_controller guard only fired on web-only screens. `screen :foo, FooCtrl, web_controller: WebCtrl` (with native, no web_path/actions) still compiled silently with no routes emitted.
* **MINOR 2** — Doc comment still mentioned the `*` separator that was deliberately removed.

### Rev 2 — commit `56c5a3c0`

Implementer addressed both:

* MINOR 1: tightened the guard to fire whenever `web_controller != nil && !has_web_input` regardless of native side. New fixture `native_plus_web_controller_no_routes.cr` + new spec case (e3).
* MINOR 2: doc comment rewritten to describe the actual signature ordering, the rationale for dropping `*`, and the type-system mitigation for positional misuse.

## Final re-review — commit `56c5a3c0`

**Codex verdict:** APPROVE.

> No findings. The tightened guard correctly catches native + bare `web_controller:` while preserving Phase 8B native-only call shapes.
> Verified e3 directly: `crystal build --no-codegen spec/fixtures/phase_08c_macro_raise/native_plus_web_controller_no_routes.cr` fails with the intended diagnostic.
> Verified specs: `phase_08c_routes_for_spec`, `native_app_spec`, and `action_dispatcher_spec` all pass. `git diff --check` is clean.

## Spec drift summary

* Entering iter 1: 1659 / 4 / 0 / 66
* Exiting iter 1 (after rev 2): 1671 / 4 / 0 / 66
* Same 4 pre-existing failures (unrelated to Phase 8C).
* 12 new Phase 8C examples covering acceptance cases (a)-(g), the new tightening case (e3), an additional bare-web_controller case (e2), and end-to-end `routes_for` verification against a stub Amber-style router.

## Empirically-verified mechanism (Codex)

* `routes_for` against the FULL `Amber::DSL::Router` (not just toy shim): smoke-test program compiled and emitted the correct routes — `Amber::Server.router.routes_hash.keys` returned `[phase08croutesmokecontroller#index, phase08croutesmokecontroller#submit]`.
* `with router yield` inside `routes :web do ... end` correctly resolves the macro-emitted `get`/`post` calls to `Amber::DSL::Router`'s macros.
* The same-named class macro on a `UI::App` subclass takes precedence over the same-named class method at macro-expansion time, so `routes_for(SpikeApp)` emits valid router calls (not method calls).

## Status

Iter 1 (Items 1 + 2) — **APPROVED for iter 2.**
