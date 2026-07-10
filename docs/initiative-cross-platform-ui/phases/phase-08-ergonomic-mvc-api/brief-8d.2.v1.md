# Phase 8D.2 — iOS Bridge Migration to UI::ActionDispatcher (BRIEF v1)

**Date drafted:** 2026-05-25
**Status:** Brief v1 — pending Codex antagonist critique.
**Branch:** `phase-08d.2-ios-bridge-migration` (to be cut at owner-approval checkpoint).
**Predecessor:** Phase 8D.1 PASS_WITH_NOTES at tag `phase-08d.1-pass-with-notes-2026-05-25`, HEAD `97b63466`.
**Planning artifacts:** `scoping-8d.2.md`, `coplan-8d.2-codex-1.md`.

---

## 1. Mission

Migrate `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` from the `Voyager.build_route` compat shim to the `UI::ActionDispatcher` host pattern that 8D.1 landed on macOS. After 8D.2 the iOS Voyager binary has live action dispatch: tapping any button on iOS fires the controller layer, returns an `ActionResult`, mounts the new screen before publishing the coord change, and Swift re-renders.

This closes:
- The "dead button" regression Phase 8D.1 knowingly introduced on iOS by leaving the compat shim's dispatcher-less ScreenContext in place.
- Phase 8B's deferred iOS dispatcher integration.

## 2. Architectural contracts (frozen)

The following surfaces MUST NOT change in 8D.2:

- **C ABI of `bridge.cr`** — the four exports (`voyager_init`, `voyager_render`, `voyager_current_slug`, `voyager_register_route_changed_callback`) keep their signatures byte-for-byte. Swift's `VoyagerBridge.swift` + `ContentView.swift` are not edited.
- **Test Swift IS free to change** — UITests under `samples/initiative-cross-platform-ui-voyager/ios/UITests/` may be edited or extended.
- **No Phase 8A/8B/8C/8D.1 API changes.** If the implementer believes a Phase 8B API gap exists (e.g., dispatcher needs a host-driven navigation API), STOP and escalate to architect — do NOT improvise.
- **Voyager.build_route compat shim** remains untouched in 8D.2. Web's `static_site.cr` still calls it. Phase 8D.3 evaluates final disposition.
- **Existing iOS Voyager render behavior** stays equivalent: each route renders the same UIView tree; `accessibility_label`/`test_id` continue to be set.

## 3. Item-by-item scope

### Item 1 — Build the dispatcher in `initialize_runtime`

`bridge.cr` `VoyagerBridge.initialize_runtime` must, in this exact order:

1. Run the existing iOS class-init gap recovery: `GC.init`, `Thread.init`, `Fiber.init`, `Crystal::Once.init`, all probe resets, `VoyagerApp.bootstrap!`.
2. Allocate `@@current_slug_buf = Bytes.new(64)`.
3. `state = Voyager::State.new`.
4. **`Voyager.state = state`** — explicit assignment of the module singleton BEFORE any dispatcher build, screen build, or callback registration. Per Codex co-plan R7+R8: without this, screens lazily allocate a different singleton than the bridge's pinned `@@state`.
5. `coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))`.
6. `session = UI::Session::InProcess.new`.
7. `flash = UI::Flash::InProcess.new`.
8. `dispatcher = UI::ActionDispatcher.new(app: VoyagerApp, navigation: coord, session: session, flash: flash, design_tokens: UI::DesignTokens::Tokens.default)`.
9. `dispatcher.mount_screen(coord.current)` — bumps the mount token + seeds FormState BEFORE the on_change subscriber is registered, so the first mount doesn't fire a Swift round-trip.
10. Assign all class-var pins: `@@state = state`, `@@coord = coord`, `@@session = session`, `@@flash = flash`, `@@dispatcher = dispatcher`. The existing `@@renderer` pin is removed — per Codex co-plan §6, it is misleading because `render_slug` creates a fresh renderer per call.
11. **`Voyager.dispatcher = dispatcher`** — so screen callbacks routing through `Voyager.dispatch(...)` find a live dispatcher.
12. Register the `coord.on_change` subscriber: copies slug into `@@current_slug_buf`, invokes the Swift callback (skips when `@@suppress_route_changed`). No `mount_screen` call inside the subscriber.
13. Set `@@initialized = true`.

**iOS class-init gap discipline:** all newly added class-vars (`@@session`, `@@flash`, `@@dispatcher`) MUST be declared as nilable with `= nil` defaults — NO initializer side effects. The allocations happen in `initialize_runtime` above.

### Item 2 — Rewrite `render_slug` to mirror macOS `rebuild_for`

After 8D.2, `render_slug(slug)` does:

```crystal
def self.render_slug(slug : String) : UI::NativeView
  initialize_runtime
  coord = @@coord.not_nil!
  dispatcher = @@dispatcher.not_nil!

  route = Voyager.route_for_slug(slug)

  # Phase 6.10 Rem 4 — initial-mount resync.
  if coord.current.id != route.id && coord.depth == 1
    @@suppress_route_changed = true
    begin
      dispatcher.mount_screen(route)
      coord.replace_root(route)
    ensure
      @@suppress_route_changed = false
    end
  end

  reg = VoyagerApp.registration_for(coord.current.id)
  screen_class = reg.screen_class
  if screen_class.nil?
    placeholder = UI::Label.new("Unknown screen for route: #{coord.current.id}")
    placeholder.accessibility_label = "Unknown route"
    placeholder.test_id = "voyager-root-unknown"
    renderer = UI::UIKit::Renderer.new
    native = renderer.render(placeholder.as(UI::View))
    @@last_native = native
    return native
  end

  ctx = UI::ScreenContext::Native.new(
    form_state: dispatcher.current_form_state,
    session: dispatcher.session,
    flash: dispatcher.flash,
    design_tokens: dispatcher.design_tokens,
    navigation: dispatcher.navigation,
    action_params: {} of String => String,
  )
  view = screen_class.new.build(ctx)
  view.accessibility_label = "voyager-root-#{slug}" if view.accessibility_label.to_s.empty?
  view.test_id = "voyager-root-#{slug}" if view.test_id.to_s.empty?

  renderer = UI::UIKit::Renderer.new
  native = renderer.render(view)
  @@last_native = native
  native
end
```

Note the route lookup: after resync, the registration must match `coord.current.id` (not the passed slug's route.id), because in the rare case Swift's slug disagreed with the post-resync state, the coord is authoritative. In the common case they match.

**Voyager.build_route is NOT called from this path after 8D.2.** The compat shim continues to exist for the web target only.

### Item 3 — Initial-resync invariant: mount-before-publish through host-driven path

`coord.replace_root` synchronously fires `on_change`. The subscriber runs BEFORE Crystal returns from the call, so the FormState/mount_token visible to the on_change subscriber MUST already be the new mount's. Calling `dispatcher.mount_screen(route)` first is the correct order. The `@@suppress_route_changed` window prevents the resulting Swift round-trip recursion (Swift would otherwise call `voyager_render(same_slug)` immediately).

This is a HOST-DRIVEN navigation — not an action-driven dispatch. Per Codex co-plan Q1: this is the honest API. No new dispatcher method needed.

### Item 4 — `coord.on_change` subscriber stays renderer-neutral

The on_change subscriber does:
- Copy the new slug into `@@current_slug_buf`.
- If `@@suppress_route_changed`, do nothing else.
- Else, invoke `@@swift_route_changed_cb` with the buffer pointer.

The on_change subscriber does NOT call `dispatcher.mount_screen` — `translate_result` already mounted before the coord op (Phase 8B mount-before-publish invariant + 8D.1 macOS pattern). Re-mounting here would double-bump the token.

### Item 5 — Compat shim disposition (UNCHANGED in 8D.2)

`Voyager.build_route(state, coord, route)` stays as-is in `app.cr`. After 8D.2:
- iOS bridge does NOT call it.
- Web `static_site.cr` STILL calls it.
- 8D.3 decides whether to keep, rename, or migrate web off.

If the implementer wants to add a comment to `Voyager.build_route`'s docstring noting "as of 8D.2 only `web/static_site.cr` calls this" — fine.

### Item 6 — Remove the dead `@@renderer` class-var pin

The existing `@@renderer : UI::UIKit::Renderer? = nil` in `VoyagerBridge` is unused after Phase 6.10 Rem 1 moved to fresh-renderer-per-render. Delete the field + its `@@renderer = renderer` assignment + the corresponding nil-pin commentary. Mention the cleanup in the implementer report.

### Item 7 — Spec coverage (acknowledging R11)

Per Codex co-plan R11: a `crystal spec` invocation under default flags does NOT compile the `flag?(:ios)` branch of `bridge.cr`. Two options:

- **7A** — Skip iOS-bridge-specific Crystal specs. Rely on:
  - The existing `voyager_dispatcher_integration_spec.cr` (host-agnostic; covers dispatch semantics).
  - The XCUITest cold-launch + AX-discovery smoke (Item 8).
  - The owner hands-on (Item 9).
- **7B** — Author a Crystal spec that exercises a host-helper extracted from the bridge (e.g. a `VoyagerHostHelpers.build_dispatcher` factory) so the dispatcher-construction sequence is testable under default `crystal spec`. This requires a small refactor of `initialize_runtime` to delegate construction to a flag-agnostic helper.

**Architect direction:** **option 7A.** The extraction in 7B is architecturally clean but the value is low — the host-agnostic dispatcher specs from 8D.1 already prove ActionDispatcher semantics; the iOS-specific path is so thin that XCUITest + hands-on is more honest evidence than a Crystal mock. Implementer may choose 7B if the refactor surfaces naturally; not required.

### Item 8 — XCUITest smoke (mid-stop-pattern aware)

Per Phase 6.10 documented limitation: **XCUITest tap synthesis on Crystal-rendered UIButtons (hosted under UIHostingController) does NOT reliably fire the on_tap closure** in the agent env. This was Codex iter-3's blocker; the workaround across Voyager has been "AX discovery via XCUITest + hands-on for interaction."

Therefore the XCUITest smoke in 8D.2 only proves:
- **Cold launch succeeds.** App launches, does not SIGSEGV, no crash log.
- **AX tree discovery.** `app.buttons["Sign in"]` or `app.buttons["voyager-sign-in-submit"]` exists within 10s.
- **`voyager-root-voyager-sign-in`** element is present (proves the Crystal-rendered UIView mounts).

The implementer ADDS a focused test in `VoyagerVisualTests.swift`:

```swift
func testColdLaunchDispatcherWired() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-sign-in"]
    app.launch()

    let signIn = app.buttons["Sign in"]
    XCTAssertTrue(signIn.waitForExistence(timeout: 10),
        "Cold-launch failed to reach AX-discoverable Sign-in button. " +
        "Possible class-init crash or render failure post-dispatcher migration.")
}
```

The XCUITest does NOT assert tap → navigation (per the Phase 6.10 caveat). The existing `testNavigationFlow` test continues to attempt taps via coordinate sweep but its tap-acceptance is best-effort.

### Item 9 — Owner hands-on gate (HARD)

Per `[[owner-hands-on-finds-real-bugs]]`: the real interaction proof is the owner running the simulator binary and tapping with the macOS host's real touch input (the simulator forwards macOS touch input to the iOS Crystal runtime correctly; XCUI tap synthesis does not). Implementer must deliver:

- `samples/initiative-cross-platform-ui-voyager/ios/build/VoyagerDemo.app` installed in the iOS simulator and ready to launch.
- A 5-step hand-test recipe in the implementer report:
  1. Open simulator. Launch VoyagerDemo. Confirm Sign-in screen renders.
  2. Tap "Sign in". Confirm navigation to Todos.
  3. Tap "Add Todo". Confirm Editor screen. Type title. Tap Save. Confirm back to Todos with new row.
  4. Tap row's swipe → Edit. Confirm Editor screen prefilled with row data. Type new title. Save. Confirm back to Todos with updated row.
  5. Tap Settings. Toggle Hide-Completed. Tap back. Confirm Todos rerenders with filter applied.

**Owner runs the recipe before merging 8D.2.** Implementer's report includes screenshots from a successful local run (best-effort) but the gate is the owner's verification.

### Item 10 — Codex per-iteration validation

Implementer dispatches Codex (medium reasoning, arg-form prompt + tee log pattern) at iteration close to validate the work. Codex output goes into `docs/initiative-cross-platform-ui/handoff/phase-08d.2-codex-N.md`. Architect handles antagonist critique of THIS brief separately.

## 4. Acceptance criteria (closing-gate)

A passing 8D.2 means ALL of:

- [ ] `bridge.cr` no longer calls `Voyager.build_route`.
- [ ] `bridge.cr` constructs a `UI::ActionDispatcher`, calls `mount_screen` before the first render, and assigns `Voyager.dispatcher` to that dispatcher.
- [ ] `bridge.cr` explicitly assigns `Voyager.state = state` before the first render.
- [ ] All newly-introduced class-vars (`@@session`, `@@flash`, `@@dispatcher`) are nilable with `= nil` defaults (no initializer side effects).
- [ ] The dead `@@renderer` pin is removed.
- [ ] `crystal spec` passes — same baseline as 8D.1 (1707 examples / 4 failures / 0 errors / 66 pending; the 4 failures are pre-existing and unrelated).
- [ ] Existing `voyager_dispatcher_integration_spec.cr` still passes.
- [ ] iOS simulator build succeeds: `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator` produces `libvoyager.a`. Subsequent `xcodebuild` produces `VoyagerDemo.app`.
- [ ] `testColdLaunchDispatcherWired` XCUITest passes (AX discovery proof).
- [ ] Existing `testRenderInitialSlug` XCUITest passes for `voyager-sign-in`, `voyager-todos`, `voyager-todo-editor`, `voyager-settings` (the visual capture path, not tap-driven).
- [ ] Owner hands-on recipe (Item 9 steps 1-5) executes successfully — owner confirms.
- [ ] Production Swift (`VoyagerBridge.swift`, `ContentView.swift`, `VoyagerApp.swift`) unchanged.
- [ ] C ABI of `bridge.cr` unchanged.
- [ ] Implementer report includes a Codex review summary verdict (APPROVE or APPROVE_WITH_NOTES — no REVISE outstanding).

## 5. Risk register (R1-R11 inherited from scoping + co-plan)

- **R1** — Cold-launch SIGSEGV on `Crystal::Once`. *Mitigation:* keep Thread/Fiber/Once init order; verify cold install in simulator.
- **R2** — Mid-stop pattern at evidence capture. *Mitigation:* implementer ships through `.app` build + automated XCUITest smoke; owner runs hands-on.
- **R3** — Audit harness can't validate runtime dispatch. *Mitigation:* hands-on gate is non-negotiable (Item 9).
- **R4** — Renderer-reuse vs FormState wire-time-read ordering. *Mitigation:* fresh renderer per call means renderer reads FormState.current AFTER mount_screen has updated it. Implementer traces the first dispatch and reports.
- **R5** — Multiple consecutive dispatches before Swift re-renders. *Mitigation:* documented as "Voyager doesn't auto-dispatch" + audit-only.
- **R6** — `Voyager.dispatcher = nil` test teardown leak. *Mitigation:* implementer adds an after-each in any new spec that touches it.
- **R7** — `Voyager.state` divergence after shim removal. *Mitigation:* explicit `Voyager.state = state` in `initialize_runtime` (Item 1 step 4).
- **R8** — `Voyager.state ||= State.new` lazy-allocation race. *Mitigation:* assignment happens before any screen build / dispatcher use.
- **R9** — Fresh renderer per `render_slug` → makeUIView + updateUIView both render. *Mitigation:* `FormState#register` is non-overwriting; sign-in + editor field registration must not depend on "exactly one render after mount." Implementer verifies on first dispatch trace.
- **R10** — Async Swift `@State` vs sync Crystal dispatch. *Mitigation:* documented as supported-host assumption — on_change subscribers must be renderer-only + non-reentrant.
- **R11** — iOS bridge spec is awkward under default `crystal spec` flags. *Mitigation:* Item 7A chosen; rely on XCUITest + hands-on.

## 6. Implementation order (Codex-recommended verbatim)

1. Bootstrap state discipline first: `VoyagerApp.bootstrap!` → `state = Voyager::State.new` → `Voyager.state = state`.
2. Add iOS bridge pins: `@@session`, `@@flash`, `@@dispatcher`. All allocations inside `initialize_runtime`.
3. Construct dispatcher: coord at `:sign_in` → session/flash → `UI::ActionDispatcher.new(...)` → `dispatcher.mount_screen(coord.current)` → `Voyager.dispatcher = dispatcher`.
4. Replace `render_slug` internals: remove `Voyager.build_route(...)`, build `ScreenContext::Native` from dispatcher getters, call `registration_for(route.id).screen_class.new.build(ctx)`, preserve fresh `UIKit::Renderer.new` per call.
5. Handle initial slug resync: depth=1 + route mismatch → suppress callback → `dispatcher.mount_screen(route)` → `coord.replace_root(route)` → unsuppress in ensure pattern.
6. Leave `coord.on_change` renderer-neutral: no mount call inside subscriber.
7. Add tests/evidence: XCUITest cold-launch smoke; iOS simulator build → `.app`; implementer hands-on recipe.

## 7. Mid-stop dispatch protocol

Per `[[mid-stop-pattern]]`: implementer agents stop mid-action at simulator screenshot/interactive flows. This phase's implementer is dispatched in TWO modes:

- **Mode A (code work):** Make all the Crystal + XCUITest swift code changes. Build `libvoyager.a` for simulator. Run all the unit specs. Validate via the build chain. Do NOT need to launch the simulator or run XCUITest.
- **Mode B (capture work):** A SEPARATE dispatch (could be the same or a different agent invocation) that takes Mode A's `.app` artifact, installs in simulator, runs XCUITest + best-effort manual screenshots, attaches outputs to the implementer report.

Mode A must complete and report before Mode B is dispatched. If Mode A's build fails, Mode B never runs. Architect splits the dispatch via a single SendMessage to the same implementer agent or via two separate Agent calls, per architect discretion.

## 8. Validation invocations

- Crystal spec: `crystal spec spec/asset_pipeline/voyager_dispatcher_integration_spec.cr` (plus any new helper spec). Full suite baseline: `crystal spec` → 1707 examples / 4 failures / 0 errors / 66 pending (failures pre-existing).
- iOS simulator build: `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator && xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`.
- iOS UITests: `xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:VoyagerVisualTests/testColdLaunchDispatcherWired -only-testing:VoyagerVisualTests/testRenderInitialSlug`.
- Codex review: `codex exec -c 'model_reasoning_effort="medium"' "<prompt>" 2>&1 | tee /tmp/codex-iter.log | tail -300`.

## 9. Hard rules

- Forward commits only on `phase-08d.2-ios-bridge-migration`.
- NO Phase 8A/8B/8C/8D.1 API changes. If a gap appears, STOP and escalate.
- NO regression in iOS Voyager render behavior. The four routes must render the same UIView tree under the new path.
- NO Swift production-code changes (`VoyagerBridge.swift`, `ContentView.swift`, `VoyagerApp.swift`). Test Swift is free.
- NO C ABI changes to `bridge.cr` exports.
- NO touch on `web/static_site.cr` or `Voyager.build_route`.
- Codex review per iteration.
- Standard Claude co-author footer on commits: `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`.

— Architect (Claude Opus 4.7)
