# Phase 8D Co-Planning — Codex Response

**Date:** 2026-05-24
**Codex session:** medium reasoning, prompt as arg-form
**Role:** Co-planner (not antagonist). Architect asked for engineering judgment on structure + decisions.

---

## Sub-phase structure (Decision A)

Split Phase 8D. One phase is too large because it mixes architectural migration, native event semantics, web target choice, and long-deferred visual behavior proof.

**8D.1: Voyager app/controller spine**
Closing gate:
- `samples/initiative-cross-platform-ui-voyager/app.cr` becomes a `UI::App` class declaration, not only the current `Voyager` module route switch.
- Four screen routes are registered through `screen :id, Controller`.
- `screens/{sign_in,todos,todo_editor,settings}.cr` build through controller-owned entry points.
- macOS host still renders all four routes.
- No behavior-contract capture required yet; this is the structural migration gate.

**8D.2: Native dispatcher migration**
Closing gate:
- macOS host uses `UI::ActionDispatcher`.
- iOS bridge uses `UI::ActionDispatcher`.
- Navigation and mutating actions return `UI::ActionResult`, rather than screens directly owning route mutation.
- Existing native smoke proof passes for all four routes.
- Deferred iOS bridge item from 8B is closed or explicitly documented as blocked.

**8D.3: Interaction proof and known bridge gaps**
Closing gate:
- 14-row Voyager behavior contract is exercised on macOS and iOS where technically possible.
- Light + dark captures are produced for the iOS 28-capture matrix.
- Real-keyboard interactive typing is attempted and either passes or is recorded as a bridge/tooling limitation.
- SecureField limitation is documented in the phase note if still blocked by SwiftKit emitting `""`.

**8D.4: Web decision implementation**
Closing gate depends on Decision B. My recommendation below is B2, so the gate is:
- `web/static_site.cr` continues to generate static Voyager pages.
- Docs clearly say Voyager's static-site target is not the Amber integration proof.
- Amber route macro proof remains covered by Phase 8C tests or a separate minimal Amber fixture, not Voyager.

## Web target choice (Decision B)

Recommend **B2: keep Voyager web as static-site and document Amber web as a separate path. Phase 8D should be native-first.**

Reasoning: Voyager's current web target, `samples/initiative-cross-platform-ui-voyager/web/static_site.cr`, is not an Amber app. Converting it to four Amber controllers would prove `UI::AmberIntegration.routes_for`, but Phase 8C already shipped that architectural primitive. It would also introduce a server lifecycle, controller setup, Selenium proof, and POST semantics into a phase whose real unfinished work is native unification and the 14-row behavior contract.

B1 is attractive as a story, but it creates a false requirement: "unified architecture" would become "every canonical demo must be an Amber app." That is too narrow for a cross-platform UI library that also supports static rendering.

Better claim: Voyager proves the shared `UI::App` / `UI::Controller` / `UI::ActionDispatcher` architecture across native hosts, while Amber remains a first-class web integration path proven separately.

## State management (Decision C)

Keep `Voyager::State` as a module singleton for Phase 8D.

For a four-screen demo with seed todos and no persistence, moving state into `UI::App` or per-controller instances is extra churn without much architectural payoff. The migration should isolate the change to routing/action ownership first.

Recommended discipline:
- Controllers read and mutate `Voyager::State`.
- Do not introduce persistence, dependency injection, or per-session state in 8D.
- Leave a phase note that singleton state is demo-scoped and unsuitable for multi-user Amber server state.

Do not move state into `UI::App` yet. `UI::App` should stay the declarative registry and bootstrap surface unless there is already a designed state container contract.

## Coord.push vs dispatcher (Decision D)

Every user-intent callback in Voyager should go through the dispatcher, including navigation-only callbacks.

Direct `coord.push(Route.new(:todos))` inside screen callbacks preserves the old architecture and weakens the reason Phase 8B exists. The canonical demo should model the preferred pattern: screen emits an action, controller dispatches it, controller returns `ActionResult`, dispatcher mutates the coordinator.

Yes, this means one controller per screen:
- `SignInController`
- `TodosController`
- `TodoEditorController`
- `SettingsController`

That is acceptable. "Barely any logic" is exactly where the pattern should stay lightweight. If the controller ceremony feels too high, fix the controller ergonomics later; do not bypass the architecture in the canonical demo.

Exception: purely local UI rendering details that do not represent application intent can stay local. But route changes, todo mutations, sign-in, delete, filter, save, and back should be dispatcher actions.

## Web Settings JS (Decision E)

For Phase 8D under B2, keep the current JS-only Settings toggle in `web/static_site.cr`.

If Voyager later migrates to Amber, a POST → server-side state mutation → rerender is acceptable for the architectural claim. It demonstrates server-owned state and controller dispatch clearly. Do not invent a sugared "client-state field" concept now.

A client-state field abstraction may become useful later, but it is a separate design surface with serious implications:
- hydration semantics
- native parity
- accessibility state ownership
- form state reconciliation
- server/client divergence

That should not be smuggled into 8D just to preserve a faster static-site toggle.

## Test coverage (Decision F)

Use **unit specs plus integration captures**.

Captures only are too blunt for controller migration. The bugs likely to appear in 8D are action-name wiring, state mutation order, route result translation, and iOS/bootstrap differences. Those are cheaper and clearer in unit specs.

Recommended coverage:
- Controller unit specs with a mock/minimal context for action dispatch.
- Focus unit specs on the 14 behavior-contract actions, not every rendering detail.
- Integration captures remain the authority for visual and host behavior.
- Native captures cover the deferred 14-row matrix and light/dark requirements.

In short: unit specs prove controller semantics; captures prove host integration and visual behavior.

## iOS class-init gap (Decision G)

Bootstrap discipline should be explicit and boring:

- Call `VoyagerApp.bootstrap!` exactly once before any `voyager_render(slug)` or action dispatch entrypoint can run.
- Initialize/register all controllers before Swift can invoke the C ABI.
- Ensure the `NavigationCoordinator` and `UI::ActionDispatcher` are created after bootstrap, not lazily halfway through first render.
- Keep iOS bridge globals deterministic: one app bootstrap path, one coordinator ownership model, one dispatcher ownership model.

I would require the implementer to verify `UI::ActionDispatcher`'s class-vars before coding this. If it carries registry/cache class-vars, the iOS bridge must not rely on Crystal class initialization happening as a side effect of the first render call. The phase should include a small bootstrap smoke test that calls the iOS bridge render/action path from a cold process.

## Risk additions

- **Static singleton state can hide host lifecycle bugs.** It is fine for 8D, but it can make iOS/macOS look correct while masking missing per-window or per-session state boundaries.

- **Action naming drift.** Symbol action refs and controller methods can silently diverge unless specs cover every canonical action name.

- **Back navigation semantics.** `coord.push`, dispatcher navigation results, and host-level back affordances must agree. The behavior contract should explicitly verify route stack behavior, not only final screen content.

- **Amber claim confusion.** If Voyager remains static web, docs must be precise: Voyager is not the Amber proof. Otherwise reviewers will read B2 as a regression from Phase 8C.

## Anything I'm not seeing

- Treat `samples/initiative-cross-platform-ui-voyager/macos/host.cr` and `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` as the real acceptance surfaces for 8D.

- Do not solve SecureField in 8D unless SwiftKit already exposes the real value. Document it as a bridge limitation.

- Make the phase note distinguish "architecture migrated" from "all interaction proof completed"; those are separate gates and should not block each other ambiguously.

---

**Architect notes on Codex's response (post-receipt):**

- I disagree with the 8D.1 vs 8D.2 split. Migrating screens to UI::App + UI::Controller WITHOUT also migrating the dispatch path leaves screens with half-old half-new internals (controllers exist but coord.push stays direct in screen callbacks). That's a worse intermediate state than either pure-old or pure-new. **Refinement: fold 8D.1 + 8D.2 into a single sub-phase: "Native unification (macOS-first, then iOS)."** macOS lands first (lower risk, more debuggable), then iOS bridge migration closes the Phase 8B deferral.
- Codex's 8D.4 ("web decision implementation") with B2 is essentially a doc-only sub-phase. Fold the doc note into 8D.3's reflection.
- Refined 3-sub-phase plan:
  - **8D.1 — Native unification (macOS)** — VoyagerApp class, 4 controllers, ActionDispatcher wired, macOS host migrates, all 4 routes work in iteration mode. Codex's combined 8D.1+8D.2 macOS scope.
  - **8D.2 — iOS bridge migration** — iOS bridge.cr migrates to UI::ActionDispatcher, closes Phase 8B deferral. Real-keyboard click-trace verification.
  - **8D.3 — 14-row interaction proof** — 28 iOS captures + macOS equivalents + phase note documenting B2 web architecture position.

All other Codex recommendations adopted.
