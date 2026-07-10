# Phase 8D.2 — iOS Bridge Migration to UI::ActionDispatcher (SCOPING DRAFT)

**Date opened:** 2026-05-25
**Status:** SCOPING — architect → Codex co-planner → brief.
**Branch:** to be cut as `phase-08d.2-ios-bridge-migration` after planning lands.
**Predecessor:** Phase 8D.1 PASS_WITH_NOTES, tag `phase-08d.1-pass-with-notes-2026-05-25`, HEAD `97b63466`.

---

## The problem being solved

Phase 8D.1 migrated Voyager's macOS host to `UI::ActionDispatcher`. The iOS bridge at `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` still calls the `Voyager.build_route(state, coord, route)` **compat shim**, which constructs a dispatcher-less `ScreenContext::Native`. As a result:

- The 8D.1-migrated screens dispatch via `Voyager.dispatch(:submit)` etc.
- `Voyager.@@dispatcher` is `nil` on iOS because no iOS host has assigned it.
- `Voyager.dispatch` short-circuits to no-op.
- **Every Voyager button on iOS today is dead — render works, interaction does not.**

This is the regression Phase 8D.1 introduced (knowingly, per the compat-shim discipline). Phase 8D.2 closes it.

### Secondary goal — close Phase 8B's deferred iOS dispatcher work

Phase 8B's `samples/phase-08b-native-spike/` proved `UI::ActionDispatcher` on macOS only. The iOS-side dispatcher integration was deferred all the way through 8B → 8C → 8D.1. Phase 8D.2 is the natural close.

### Tertiary goal — verify the iOS class-init gap doesn't strand dispatcher state

The dispatcher itself has no class-vars. `UI::FormState.@@current_mount_token : Int64 = 0_i64` is the only class-level initialiser on the hot path; the existing comment (form_state.cr:104-113) argues 0_i64 is gap-safe because the gap would strand it at the same value. Phase 8D.2 verifies this empirically on a cold-launch iOS binary.

## Why this is its own sub-phase

Splitting iOS off from 8D.1 was the correct call (Codex co-plan):

- iOS bridges Crystal ↔ Swift ↔ SwiftUI ↔ UIKit. Different ownership model than macOS NSWindow.
- iOS is subject to the class-init gap. Every class-var must be allocated in `initialize_runtime`, not via default initialiser. macOS doesn't have this constraint.
- The render call is **Swift-driven**: Swift owns the `@State` for the slug; Crystal cannot force a render — it can only fire the route-changed C callback that prompts Swift to call `voyager_render(new_slug)`. Mount-before-publish discipline must work across this boundary.
- iOS pattern uses **fresh renderer per render call** (per Phase 6.10 Rem 1 — UIHostingController state quirks). macOS reuses a single renderer.

These are real architectural differences. Folding them into 8D.1 risked correctness regression on the lower-risk macOS path.

## Scope (candidate items — open for Codex critique)

### Item 1 — `VoyagerBridge.initialize_runtime` builds the dispatcher

Currently builds `state + coord + renderer`. After 8D.2 it must also build:
- `session` (`UI::Session::InProcess.new` — symmetric with macOS host).
- `flash` (`UI::Flash::InProcess.new`).
- `dispatcher` (`UI::ActionDispatcher.new(app: VoyagerApp, navigation: coord, session:, flash:, design_tokens:)`).
- Call `dispatcher.mount_screen(coord.current)` BEFORE the on_change subscriber is registered (so the first mount doesn't fire a Swift round-trip).
- Assign `Voyager.dispatcher = dispatcher` so screen callbacks route through it.
- Pin `dispatcher`, `session`, `flash` in class vars (GC, iOS gap discipline — explicit assignment, not default initialiser).

### Item 2 — `render_slug` rebuilds context from dispatcher's live state

Today's `render_slug` calls `Voyager.build_route(state, coord, route)`. After 8D.2 it must:
- Build `UI::ScreenContext::Native` from `dispatcher.current_form_state`, `dispatcher.session`, `dispatcher.flash`, `dispatcher.design_tokens`, `dispatcher.navigation`, plus an empty `action_params`. (Same `rebuild_for` pattern as `macos/host.cr:95-122`.)
- Call `VoyagerApp.registration_for(route.id).screen_class.new.build(ctx)` to produce the `UI::View`.
- Render via `UI::UIKit::Renderer.new` (fresh per call — preserve Phase 6.10 Rem 1 pattern).

### Item 3 — Coord/slug initial-sync routes through the dispatcher

Today's logic at `bridge.cr:225-229`:
```crystal
if coord.current.id != route.id && coord.depth == 1
  @@suppress_route_changed = true
  coord.replace_root(route)
  @@suppress_route_changed = false
end
```

After 8D.2: instead of direct `coord.replace_root(route)`, the host must mount-then-replace to preserve mount-before-publish:
```crystal
if coord.current.id != route.id && coord.depth == 1
  @@suppress_route_changed = true
  dispatcher.mount_screen(route)  # bump token + swap FormState.current
  coord.replace_root(route)       # then fire on_change (suppressed)
  @@suppress_route_changed = false
end
```

This is NOT an action-driven path — Swift is requesting an initial slug, not a controller returning `ReplaceRoot`. So calling `dispatcher.mount_screen(route)` + `coord.replace_root(route)` directly (vs going through a controller dispatch) is the honest API. Implementer must verify this matches the dispatcher's exposed surface.

### Item 4 — Route-changed callback semantics unchanged

The Swift-facing C ABI (`voyager_init`, `voyager_render`, `voyager_current_slug`, `voyager_register_route_changed_callback`) MUST NOT change. Swift's `VoyagerBridge.swift` + `ContentView.swift` are untouched in 8D.2.

The `coord.on_change` subscriber inside Crystal:
- Continues to copy slug to `@@current_slug_buf` + call the Swift callback.
- Continues to honor `@@suppress_route_changed` for the initial resync.
- Does NOT call `dispatcher.mount_screen` — `translate_result` already mounted before the coord op (mount-before-publish invariant).

### Item 5 — Compat shim disposition

After 8D.2:
- `Voyager.build_route` is still called by `samples/initiative-cross-platform-ui-voyager/web/static_site.cr`.
- Phase 8D.3 evaluates whether to keep, rename (`Voyager.static_build_route`), or migrate web off it.
- **8D.2 does NOT touch web.** The shim stays untouched in scope.

### Item 6 — iOS class-init gap verification

Implementer must:
- Confirm no new class-var initialiser side effects in bridge.cr. All allocations stay inside `initialize_runtime`.
- Pin `dispatcher`, `session`, `flash` as `@@dispatcher : UI::ActionDispatcher? = nil` etc. (nilable defaults are safe per the existing gap discipline).
- Verify on a **cold-launched** iOS binary that `voyager_init` → first `voyager_render` sequence does NOT SIGSEGV on `Crystal::Once` walking an uninitialised list (the Rem 3 fix already calls `Thread.init / Fiber.init / Crystal::Once.init` — those stay).

### Item 7 — Spec coverage

- **Add** a unit spec analogous to `voyager_dispatcher_integration_spec.cr` but for the iOS-side dispatcher wiring: `spec/asset_pipeline/voyager_ios_bridge_init_spec.cr`. Crystal-only (no XCUITest), tests `VoyagerBridge.initialize_runtime` side effects: dispatcher constructed, `Voyager.dispatcher` set, FormState seeded under non-zero token, on_change subscriber registered.
- **Reuse** `voyager_dispatcher_integration_spec.cr` from 8D.1 — those 5 scenarios already cover dispatch semantics agnostic of host.
- **No new per-controller specs** — 8D.1 already covers them.

### Item 8 — Evidence captures

Two paths candidate for capture:
1. **Static visual parity** — `voyager_render(slug)` produces the same UIView pixel-for-pixel as the pre-migration path. Could be tested via XCUITest screenshot diff or by snapshotting the four routes' UIViews in a Crystal-side unit test that exercises `VoyagerBridge.render_slug` on a simulator. **Architect lean: defer pixel diff to 8D.3's full 14-row capture matrix.**
2. **Cold-launch smoke test** — XCUITest launches the simulator app, taps Sign-in button, asserts navigation to Todos. Proves the migration didn't break the runtime substrate. **Architect lean: keep this in scope for 8D.2.**

### Item 9 — Hands-on test gate

Per `[[owner-hands-on-finds-real-bugs]]`: the owner has a known pattern of finding bugs in interactive paths that audit harnesses miss. The dispatcher migration on iOS is exactly the kind of change where a hands-on simulator run is the strongest signal.

**Architect proposal:** Implementer ships through to a buildable iOS Voyager .app on the simulator. Owner does a 5-minute hands-on (sign-in → add todo → swipe-edit → save → toggle settings filter → back → verify filter applies). Hands-on gate is a hard pass requirement.

## Sub-phase decision

8D.2 stays one phase — no further splitting. The risk profile is narrower than 8D.1 (one bridge file, ~25-line dispatcher integration delta) and the goal is one clear thing: close the dispatcher gap on iOS. Splitting would just create bookkeeping overhead.

## Risk register

- **R1 — Cold-launch SIGSEGV on `Crystal::Once`.** Existing Rem 3 fix (Thread/Fiber/Once init) covers this for the build_route shim path; new path adds dispatcher construction. **Mitigation:** Implementer verifies on a fresh simulator install with no prior launches.
- **R2 — Mid-stop pattern at evidence capture.** Per `[[mid-stop-pattern]]`: implementer agents stop mid-action at simulator screenshot/interactive flows. **Mitigation:** Split dispatch — code-work agent ships the migration + builds the .app + writes a buildable XCUITest smoke. Capture agent runs the XCUITest + simulator hand-test.
- **R3 — Audit harness can't validate runtime dispatch.** Static screenshot diff proves render parity but says nothing about whether tap → action → mount-before-publish → coord.replace_root → on_change → Swift @State → re-render works. **Mitigation:** Hands-on gate (Item 9) is non-negotiable.
- **R4 — Renderer reuse vs fresh-per-render conflict with mount-before-publish.** The fresh renderer per `render_slug` call means the renderer's wire-time read of `UI::FormState.current` happens AFTER `dispatcher.mount_screen` has updated it. This should work — but worth verifying because macOS reuses a single renderer (different timing). **Mitigation:** Implementer manually traces the FormState.current read-vs-write ordering on the first dispatch and reports.
- **R5 — Multiple consecutive dispatches across the same render boundary.** If a controller returns `Navigate` and the on_change subscriber fires Swift's callback synchronously, then Swift's @State update is async (DispatchQueue.main.async in `VoyagerBridge.swift:36-38`). Between Crystal's `coord.push` returning and Swift calling `voyager_render(new_slug)`, the Crystal coord + dispatcher have already mounted the new route. If another Crystal-side dispatch fires before Swift's render, we have a token mismatch risk. **Mitigation:** Audit-only — Implementer notes whether this scenario can be triggered. Unlikely on Voyager's flows (no auto-dispatching).
- **R6 — `Voyager.dispatcher = nil` in tests.** If specs reset `Voyager.dispatcher = nil` between scenarios and other specs run after iOS bridge init under shared state, they may see a stale dispatcher. **Mitigation:** Implementer adds a tear-down in the new iOS init spec.

## Open questions for Codex

1. **Mount-before-replace_root pattern in initial resync.** Is calling `dispatcher.mount_screen(route)` + `coord.replace_root(route)` directly (bypassing `translate_result`) honest? Or should the dispatcher expose a public host-driven navigation API for this case?
2. **Should `Voyager.dispatcher = dispatcher` be a class-level slot OR per-host instance?** Today it's a module class-var on `Voyager`. Two hosts in the same process (macOS + iOS) would clash — but that's not a real scenario. Worth a sentence to settle.
3. **Should 8D.2 ship XCUITest coverage at all?** The XCUITest setup at `samples/initiative-cross-platform-ui-voyager/ios/UITests/` already exists. Adding one dispatcher smoke test feels low-risk; skipping it pushes ALL iOS interaction proof to 8D.3. **Codex: which way?**
4. **Should the existing `Voyager.state = state` global discipline survive 8D.2?** macOS host sets it (`host.cr:133`). iOS bridge currently creates the state in `initialize_runtime` but doesn't assign `Voyager.state`. Should iOS assign it the same way? Implementer note: the screens read via `Voyager.state.todos` etc.
5. **Anything I'm not seeing.** Standard Codex prompt.

## Hard rules (preserved into the brief)

- Forward commits only on `phase-08d.2-ios-bridge-migration`.
- NO Phase 8A/8B/8C/8D.1 API changes. 8D.2 is APPLYING the dispatcher to iOS; if a gap surfaces (e.g. dispatcher needs a host-navigation API), STOP and escalate to architect — do NOT improvise.
- NO regression in existing iOS Voyager behavior: render path stays equivalent; `accessibility_label` / `test_id` continue to be set.
- NO Swift-side changes. C ABI is frozen.
- Codex per-iteration review of implementer's work.
- Standard Claude co-author footer.

---

**Next steps:**

1. Send to Codex as co-planner. Iterate on questions 1-5.
2. Convert refined scope → `brief-8d.2.md`.
3. Codex antagonist critique on brief.
4. Owner checkpoint before dispatch.
5. Cut branch + dispatch implementer (split for evidence capture).

— Architect (Claude Opus 4.7)
