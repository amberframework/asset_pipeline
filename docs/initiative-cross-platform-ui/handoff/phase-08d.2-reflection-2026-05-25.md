# Phase 8D.2 — Architect Reflection

**Phase:** 8D.2 — Voyager iOS Bridge Migration to UI::ActionDispatcher
**Date closed:** 2026-05-25 (PASS_WITH_NOTES, merge-on-automated-proof per owner directive)
**Branch merged:** `phase-08d.2-ios-bridge-migration` → `feature/utility-first-css-asset-pipeline`
**Final HEAD:** `8af92f3d`
**Tag:** `phase-08d.2-pass-with-notes-2026-05-25`

## Verdict

PASS_WITH_NOTES. The iOS bridge now dispatches every Voyager button through `UI::ActionDispatcher`. The "dead button" regression Phase 8D.1 knowingly introduced is closed on the Crystal + build path. The Phase 8B deferred iOS dispatcher integration is closed.

Owner deferred Item 9 (7-step hand-test recipe) to Phase 8D.3 — same pattern as 8D.1's path-2 close. Automated evidence covers Crystal + XCUITest layers; the simulator-touch end-to-end proof is folded into 8D.3.

## What shipped

### Item 1 — `Voyager::HostBootstrap` helper + spec
`samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr`. Flag-agnostic helper encapsulating the full dispatcher construction sequence: `VoyagerApp.bootstrap!` → state + coord + session + flash + dispatcher → `dispatcher.mount_screen(coord.current)` → `Voyager.state = state` + `Voyager.dispatcher = dispatcher` assignments. Returns a `Result` record for host-level pinning.

`spec/asset_pipeline/voyager_host_bootstrap_spec.cr` — 7 examples proving state matching, dispatcher matching, mount_token != 0, navigation invariants, and end-to-end dispatch routing to the correct controller. Resets `Voyager.dispatcher = nil` + `Voyager.state = Voyager::State.new` per scenario (R6).

This is the Crystal-side host-wiring proof Codex HIGH 4 + elevated R11 required. Without it, the runtime sequence would have had zero automated assertion until simulator runs.

### Item 2 — iOS bridge migration

`samples/initiative-cross-platform-ui-voyager/ios/bridge.cr`:
- `initialize_runtime` now calls `Voyager::HostBootstrap.build(:sign_in)` and unpacks 5 class-var pins. Direct `VoyagerApp.bootstrap!` call removed (helper owns it). iOS class-init gap recovery (Thread/Fiber/Once init + probe resets) preserved.
- Added class-vars `@@session : UI::Session::InProcess? = nil`, `@@flash : UI::Flash::InProcess? = nil`, `@@dispatcher : UI::ActionDispatcher? = nil` — all nilable with `= nil` defaults (gap discipline).
- Removed dead `@@renderer` pin + its in-`initialize_runtime` local allocation.
- `@@current_slug_buf` seeded with `coord.current.id`'s slug before `@@initialized = true` (Codex BLOCKER 1).
- `render_slug` rewritten to mirror macOS `rebuild_for`: ScreenContext::Native from dispatcher's live state, current_slug derived from `coord.current.id`, fresh renderer per call (Phase 6.10 Rem 1 preserved).
- Initial slug resync: `dispatcher.mount_screen(route)` + `coord.replace_root(route)` in `begin/ensure @@suppress_route_changed` block.

### Item 3 — XCUITest smokes
`samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift`:
- New `testColdLaunchSignInDispatcherWired` — asserts Sign-in button AX-discoverable after cold launch with `VOYAGER_ROOT_SLUG=voyager-sign-in`.
- New `testColdLaunchTodosDispatcherWired` — asserts `voyager-todos-add` AX-discoverable after cold launch with `VOYAGER_ROOT_SLUG=voyager-todos`. Single-element assertion (not disjunction), per Codex v2 note.
- Fixed `testRenderInitialSlug` — now actually asserts `XCTAssertTrue(foundRoot, ...)`. Previously recorded a silent activity on failure.

Production Swift untouched.

### Item 4 — Compat shim disposition
`Voyager.build_route` untouched in `app.cr`. Web's `static_site.cr` still calls it. Phase 8D.3 evaluates final disposition.

## Numbers

- Spec: 1707 → **1714** (+7 new bootstrap examples; same 4 pre-existing failures).
- `voyager_dispatcher_integration_spec.cr`: 5/0 (unchanged).
- iOS simulator build: `libvoyager.a` + `VoyagerDemo.app` build clean.
- XCUITest: 3/3 pass (`testColdLaunchSignInDispatcherWired`, `testColdLaunchTodosDispatcherWired`, `testRenderInitialSlug`).
- Codex per-iteration verdict: APPROVE_WITH_NOTES (no REVISE outstanding).

## What's open (carried to 8D.3)

- **Item 9 hand-test recipe** (deferred per owner path-2): 7 steps exercising Add Todo Cancel, swipe-Edit Save, checkbox toggle Rerender, swipe-Delete Rerender, Settings filter round-trip. Owner runs on simulator with the pre-built `.app`.
- **`Voyager.build_route` web shim disposition** — keep, rename, or migrate web off.
- **14-row interaction proof + 28 iOS captures** — 8D.3 closing-gate from the Phase 8D scoping.
- **macOS host migration to `HostBootstrap.build`** — optional cleanup; not 8D.2 scope. macOS still uses manual construction in `run!`.
- **Codex APPROVE_WITH_NOTES items** (none blocking):
  - Production Swift overwrites Crystal's root AX identifier with the requested slug at `VoyagerBridge.swift:49`. Frozen by brief §2. Track as follow-up.
  - Renderer-construction-before-build is a layering smell — addressed inline with documentation; deeper API cleanup (decouple `install_provider` from renderer construction) is a follow-up.

## Lessons

### `UIKit::Renderer.new` MUST run before `screen.build` (saved as [[renderer-provider-install-ordering]])

Brief v2 Item 2's sample code put the fresh `UIKit::Renderer.new` AFTER the `screen.build(ctx)` call. On iOS that SIGSEGV'd at PC=0 because the renderer's initializer installs `UI::DesignTokens::Device.install_provider`, which screens query via `DeviceMetrics.current` during build for responsive layout. The macOS host masked this because its renderer is constructed ONCE in `run!` at startup, so the provider is always installed by the time any screen builds.

The implementer caught it via the iOS crash report (`VoyagerDemo-2026-05-25-080058.ips`), inverted the order, documented inline at `bridge.cr:272-284`, and reported the deviation as a brief inaccuracy. The fix is correct; the architect's mental model — drafted from the macOS pattern — missed the per-call-renderer ordering constraint.

Lesson for future briefs: when a host uses a fresh renderer per render call, explicitly call out the install-before-query ordering. The "lower-layer assumption" pattern in `[[plan-what-to-understand-not-just-what-to-build]]` applies.

### `HostBootstrap.build` is the right primitive for cross-host coherence

8D.1 left the macOS host with hand-rolled construction in `run!`. 8D.2 introduced `HostBootstrap.build` so iOS doesn't duplicate the sequence. macOS migration to the helper is a follow-up cleanup, but the helper EXISTS and is testable under default `crystal spec` — that's the Crystal-side proof Codex HIGH 4 required.

The pattern generalizes: any host construction sequence with > 4 steps and an iOS / macOS / web counterpart should be extracted to a flag-agnostic helper. The helper is testable without platform flags; the host-side wiring becomes a thin 5-line unpack.

### Codex two-step (co-planner + antagonist) continues to deliver

8D.2 used Codex three times:
1. **Co-planner** on the scoping doc — agreed one-phase scope, answered 4 open questions, added R7-R11.
2. **Antagonist on brief v1** — REVISE with 2 BLOCKER + 5 HIGH + 6 MEDIUM + 3 LOW. BLOCKERS included missing slug-buffer seeding and an impossible hand-test step (pre-existing `save.disabled` bug).
3. **Re-validation of brief v2** — APPROVE_WITH_NOTES on the revised brief; both notes applied surgically.

Three Codex passes on a planning document is the right level of antagonism for a phase where the runtime substrate touches three boundaries (Crystal ↔ UIKit ↔ Swift). The cost is ~10 minutes of Codex CLI time; the value is the 16-finding catch on brief v1 that would have surfaced as Implementer Mode A blockers otherwise.

### The "merge on automated proof, defer hands-on" pattern is becoming standard

Both 8D.1 and 8D.2 closed with the owner choosing to defer the hand-test gate to the next phase. The implementer in both cases shipped:
- Build artifacts that prove non-interactive compilation + render.
- XCUITest smokes that prove AX-tree wiring.
- Crystal-side unit specs that prove dispatcher/controller semantics.
- A documented hand-test recipe for later.

This works because the architectural changes ARE testable via the automated layers. The hand-test catches integration bugs the audit harness misses (per `[[owner-hands-on-finds-real-bugs]]`), but as long as the hand-test happens BEFORE the architecture is locked in (Phase 8D.3 close), the deferral is acceptable.

Caveat: this pattern requires the owner to actually run the hand-test in the next phase. If 8D.3 also defers, then the recipe becomes a frozen promise instead of a quality gate. Architect must track this debt explicitly in 8D.3 scoping.

## Bookkeeping

- 2 implementer commits + 1 architect planning commit on `phase-08d.2-ios-bridge-migration`.
- 5 planning artifacts committed: `scoping-8d.2.md`, `coplan-8d.2-codex-1.md`, `brief-8d.2.v1.md`, `brief-8d.2.md` (v2), `codex-critique-1-brief-8d.2.md`.
- 1 implementer-side Codex review: `handoff/phase-08d.2-codex-1.md` (APPROVE_WITH_NOTES, 0 REVISE outstanding).
- New memory: `[[renderer-provider-install-ordering]]`.
- Tag: `phase-08d.2-pass-with-notes-2026-05-25`.
- Hand-test gate deferred to 8D.3 per owner directive.

— Architect (Claude Opus 4.7)
