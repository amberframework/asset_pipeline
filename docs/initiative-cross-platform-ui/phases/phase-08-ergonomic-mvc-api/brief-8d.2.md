# Phase 8D.2 — iOS Bridge Migration to UI::ActionDispatcher (BRIEF v2 — DISPATCH-READY)

**Date drafted:** 2026-05-25
**Status:** Brief v2 — addresses Codex antagonist findings (`codex-critique-1-brief-8d.2.md`). Pending owner checkpoint.
**Branch:** `phase-08d.2-ios-bridge-migration` (to be cut at owner-approval checkpoint).
**Predecessor:** Phase 8D.1 PASS_WITH_NOTES at tag `phase-08d.1-pass-with-notes-2026-05-25`, HEAD `97b63466`.
**Planning artifacts:** `scoping-8d.2.md`, `coplan-8d.2-codex-1.md`, `brief-8d.2.v1.md`, `codex-critique-1-brief-8d.2.md`.

---

## 1. Mission

Migrate `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` from the `Voyager.build_route` compat shim to the `UI::ActionDispatcher` host pattern that 8D.1 landed on macOS. After 8D.2 the iOS Voyager binary has live action dispatch: tapping any button on iOS fires the controller layer, returns an `ActionResult`, mounts the new screen before publishing the coord change, and Swift re-renders.

This closes:
- The "dead button" regression Phase 8D.1 knowingly introduced on iOS by leaving the compat shim's dispatcher-less ScreenContext in place.
- Phase 8B's deferred iOS dispatcher integration.

## 2. Architectural contracts (frozen)

The following surfaces MUST NOT change in 8D.2:

- **C ABI of `bridge.cr`** — the four exports (`voyager_init`, `voyager_render`, `voyager_current_slug`, `voyager_register_route_changed_callback`) keep their signatures byte-for-byte.
- **Production Swift source** (`VoyagerBridge.swift`, `ContentView.swift`, `VoyagerApp.swift`, `Voyager-Bridging-Header.h`). NO edits.
- **Test Swift source code IS free to change.** Existing `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift` may be edited or extended. **Test target dependencies, scheme changes, or new target linkage require architect approval BEFORE the edit.**
- **No Phase 8A/8B/8C/8D.1 API changes.** If the implementer believes a Phase 8B API gap exists (e.g., dispatcher needs a host-driven navigation API), STOP and escalate to architect — do NOT improvise.
- **`Voyager.build_route` compat shim** remains untouched in 8D.2. Web's `static_site.cr` still calls it. Phase 8D.3 evaluates final disposition.
- **Existing iOS Voyager render behavior** stays equivalent: each route renders the same UIView tree; `accessibility_label`/`test_id` continue to be set.

## 3. Item-by-item scope

### Item 1 — Build the dispatcher in `initialize_runtime`

`bridge.cr` `VoyagerBridge.initialize_runtime` must, in this exact order:

1. Run the existing iOS class-init gap recovery: `GC.init`, `Thread.init`, `Fiber.init`, `Crystal::Once.init`, all probe resets. (NOTE: `VoyagerApp.bootstrap!` is invoked from inside `Voyager::HostBootstrap.build` — see step 3 — not here. This keeps bootstrap-call ownership in exactly one layer. `bootstrap!` IS idempotent per `src/asset_pipeline/native_app.cr:436-446` so a duplicate call would not corrupt state, but the brief mandates single-ownership.)
2. Allocate `@@current_slug_buf = Bytes.new(64)`.
3. `result = Voyager::HostBootstrap.build(:sign_in)` — Item 7 helper. Internally: calls `VoyagerApp.bootstrap!`, constructs `state` + `coord` + `session` + `flash` + `dispatcher`, assigns `Voyager.state` and `Voyager.dispatcher`, calls `dispatcher.mount_screen(coord.current)` (which bumps the mount_token + seeds FormState; **`mount_screen` does NOT call coord notify** — it is a pure FormState/token swap; safe before any on_change subscriber is registered; **NOT idempotent** — subsequent invocations from `translate_result` are intentional remounts).
4. Assign all class-var pins from `result`: `@@state = result.state`, `@@coord = result.coord`, `@@session = result.session`, `@@flash = result.flash`, `@@dispatcher = result.dispatcher`. **The existing `@@renderer` pin AND its local `renderer = UI::UIKit::Renderer.new` in `initialize_runtime` are both removed** — per co-plan §6, the pin is misleading since `render_slug` creates a fresh renderer per call.
5. Register the `coord.on_change` subscriber: copies slug into `@@current_slug_buf`, invokes the Swift callback (skips when `@@suppress_route_changed`). NO `mount_screen` call inside the subscriber.
6. **`copy_slug_to_buf(Voyager.slug_for_route_id(@@coord.not_nil!.current.id))`** — seed the slug buffer so `voyager_current_slug()` returns the correct initial value BEFORE any navigation event fires (Codex BLOCKER 1).
7. Set `@@initialized = true`.

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
  # mount-before-publish: replace_root synchronously notifies subscribers,
  # so mount_screen first guarantees FormState.current is the new mount's
  # before any subscriber fires.
  if coord.current.id != route.id && coord.depth == 1
    @@suppress_route_changed = true
    begin
      dispatcher.mount_screen(route)
      coord.replace_root(route)
    ensure
      @@suppress_route_changed = false
    end
  end

  # AX labels reflect coord.current — authoritative after resync.
  # If Swift's requested slug disagreed with coord.current and no resync
  # fired (e.g. mid-app slug requests after navigation has begun), the
  # rendered screen and AX identity stay consistent.
  current_slug = Voyager.slug_for_route_id(coord.current.id)
  reg = VoyagerApp.registration_for(coord.current.id)
  screen_class = reg.screen_class

  # Defensive guard — not robust unknown-slug handling (route_for_slug
  # already maps unknown slugs to :sign_in). Catches future registration
  # shapes where screen_class could be nil.
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
  view.accessibility_label = "voyager-root-#{current_slug}" if view.accessibility_label.to_s.empty?
  view.test_id = "voyager-root-#{current_slug}" if view.test_id.to_s.empty?

  renderer = UI::UIKit::Renderer.new
  native = renderer.render(view)
  @@last_native = native
  native
end
```

**Voyager.build_route is NOT called from this path after 8D.2.** The compat shim continues to exist for the web target only.

### Item 3 — Initial-resync invariant: mount-before-publish through host-driven path

`coord.replace_root` synchronously fires `on_change`. The subscriber runs BEFORE Crystal returns from the call, so the FormState/mount_token visible to the on_change subscriber MUST already be the new mount's. Calling `dispatcher.mount_screen(route)` first is the correct order. The `@@suppress_route_changed` window prevents the resulting Swift round-trip recursion (Swift would otherwise call `voyager_render(same_slug)` immediately).

This is a HOST-DRIVEN navigation — not an action-driven dispatch. Per co-plan Q1: this is the honest API. No new dispatcher method needed.

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

Implementer may add a one-line docstring noting "as of 8D.2 only `web/static_site.cr` calls this" — optional.

### Item 6 — Remove the dead `@@renderer` class-var pin AND the local allocation

The existing `@@renderer : UI::UIKit::Renderer? = nil` in `VoyagerBridge` AND its in-`initialize_runtime` local `renderer = UI::UIKit::Renderer.new` assignment are both removed. Per Codex co-plan §6: the field is misleading because `render_slug` always creates a fresh renderer.

### Item 7 — Crystal-side host-bootstrap helper (REQUIRED per Codex HIGH 4)

Per Codex HIGH 4 + elevated R11: extract the dispatcher construction sequence into a flag-agnostic helper so it is testable under default `crystal spec`.

**Implementer creates:** `samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr`:

```crystal
module Voyager
  # Phase 8D.2 — flag-agnostic host bootstrap helper.
  #
  # Encapsulates the canonical dispatcher construction sequence so the
  # iOS bridge AND any future host can call ONE primitive instead of
  # duplicating the order. The macOS host predates this helper and may
  # be migrated to it in a follow-up cleanup; it is NOT in 8D.2 scope.
  #
  # Returns a Bootstrap result struct carrying all the constructed
  # collaborators. Caller is responsible for pinning them per its own
  # GC discipline (iOS class-vars; macOS local vars).
  module HostBootstrap
    record Result,
      state : Voyager::State,
      coord : UI::NavigationCoordinator,
      session : UI::Session::InProcess,
      flash : UI::Flash::InProcess,
      dispatcher : UI::ActionDispatcher

    # Build the full host substrate. Calls VoyagerApp.bootstrap!,
    # constructs state + coord + session + flash + dispatcher, calls
    # dispatcher.mount_screen for the initial route, assigns
    # Voyager.state + Voyager.dispatcher. Returns the constructed
    # collaborators for host-level pinning.
    def self.build(initial_route_id : Symbol = :sign_in) : Result
      VoyagerApp.bootstrap!

      state = Voyager::State.new
      Voyager.state = state

      coord = UI::NavigationCoordinator.new(
        UI::NavigationCoordinator::Route.new(initial_route_id)
      )
      session = UI::Session::InProcess.new
      flash = UI::Flash::InProcess.new
      dispatcher = UI::ActionDispatcher.new(
        app: VoyagerApp,
        navigation: coord,
        session: session,
        flash: flash,
        design_tokens: UI::DesignTokens::Tokens.default,
      )
      dispatcher.mount_screen(coord.current)
      Voyager.dispatcher = dispatcher

      Result.new(state: state, coord: coord, session: session, flash: flash, dispatcher: dispatcher)
    end
  end
end
```

**iOS `initialize_runtime` calls** `Voyager::HostBootstrap.build(:sign_in)` and unpacks the result into the class-var pins. The macOS host is NOT migrated to this helper in 8D.2 (out of scope).

**Implementer creates:** `spec/asset_pipeline/voyager_host_bootstrap_spec.cr` verifying:
- Returned `state` matches `Voyager.state`.
- Returned `dispatcher` matches `Voyager.dispatcher`.
- `dispatcher.current_form_state.mount_token != 0` (mount_screen was called).
- `dispatcher.navigation.current.id == :sign_in` (or the passed initial_route_id).
- Subsequent dispatch via the dispatcher invokes the correct controller (e.g. assert that `dispatcher.dispatch(:submit)` from `:sign_in` mount lands on `Voyager::SignInController`).

Spec runs under `crystal spec` default flags — no `-Dios` needed because the helper does not depend on the UIKit renderer.

### Item 8 — XCUITest cold-launch smokes (TWO smokes, both required)

Per Codex HIGH 2 + HIGH 3: Sign-in cold-launch alone is too weak. Implementer adds two new XCUITest functions in `VoyagerVisualTests.swift`:

```swift
func testColdLaunchSignInDispatcherWired() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-sign-in"]
    app.launch()

    let signIn = app.buttons["Sign in"]
    XCTAssertTrue(signIn.waitForExistence(timeout: 10),
        "Cold-launch failed to reach AX-discoverable Sign-in button. " +
        "Possible class-init crash, dispatcher construction failure, or render failure.")
}

func testColdLaunchTodosDispatcherWired() throws {
    let app = XCUIApplication()
    app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-todos"]
    app.launch()

    // voyager-todos-add is the Add Todo button, unique to the Todos screen.
    // If this exists, the initial-slug resync + dispatcher-backed
    // ScreenContext + Todos screen build all succeeded. Asserting on
    // voyager-todos-add specifically (not a label-or-id disjunction)
    // keeps the smoke specific: the Todos screen, not just "some screen
    // that happens to also have a Settings button."
    let addButton = app.buttons["voyager-todos-add"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 10),
        "Cold-launch with VOYAGER_ROOT_SLUG=voyager-todos failed to render the Todos screen. " +
        "voyager-todos-add not AX-discoverable. Initial slug resync " +
        "(dispatcher.mount_screen + coord.replace_root) likely broken.")
}
```

**Additionally** — implementer fixes the existing `testRenderInitialSlug` to actually assert `foundRoot`:

```swift
XCTAssertTrue(foundRoot,
    "voyager-root-\(slug) not discoverable in AX tree within 10s. " +
    "Likely cold-render failure for slug \(slug).")
```

(Test Swift source change — permitted per Section 2.)

The XCUITest acceptance is "test passes within timeout" — does NOT assert "no crash log" (XCUITest doesn't actively inspect crash diagnostics).

### Item 9 — Owner hands-on gate (HARD)

Per `[[owner-hands-on-finds-real-bugs]]`: the real interaction proof is the owner running the simulator binary and tapping with the macOS host's real touch input. Implementer delivers a buildable `.app` and the recipe below; owner executes before merge.

**Hand-test recipe (7 steps, REVISED per Codex MEDIUM 4 + BLOCKER 2):**

1. Open simulator. Launch VoyagerDemo. Confirm Sign-in screen renders.
2. Tap "Sign in". Confirm navigation to Todos (5 seed rows visible).
3. Tap "Add Todo". Confirm Editor screen renders with empty title field. Tap "Cancel". Confirm Pop to Todos with NO new row. *(Tests `:new_todo` Navigate + `:cancel` Pop, without depending on the Save-disabled-while-blank pre-existing issue.)*
4. Swipe a seeded row → tap "Edit". Confirm Editor renders with title prefilled. Edit the title (e.g. append " updated"). Tap "Save". Confirm Pop to Todos with row showing updated title. *(Tests `:edit_row` Navigate with `action_params: {todo_id}` → editor reads `ctx.params["todo_id"]` → `:save` Pop with title updated.)*
5. Tap a row's checkbox. Confirm checkmark applies + title strikethrough renders. *(Tests `:toggle_row` Rerender on same route.)*
6. Swipe a row → tap "Delete". Confirm row disappears from the list. *(Tests `:delete_row` Rerender, destructive.)*
7. Tap "Settings". Toggle "Hide completed". Tap "Back to todos". Confirm Todos rerenders with completed rows hidden. *(Tests `:open_settings` Navigate → `:toggle_filter` Rerender → `:back` Pop with state propagated.)*

Owner reports PASS/FAIL per step. Implementer report records the recipe + best-effort local-run screenshots (not gating).

### Item 10 — Codex per-iteration validation

Implementer dispatches Codex (medium reasoning, arg-form prompt + tee log pattern) at iteration close to validate the work. Codex output goes into `docs/initiative-cross-platform-ui/handoff/phase-08d.2-codex-N.md`. Architect handles antagonist critique of THIS brief separately (already done: `codex-critique-1-brief-8d.2.md`).

## 4. Acceptance criteria (closing-gate)

A passing 8D.2 means ALL of:

- [ ] `bridge.cr` no longer calls `Voyager.build_route`.
- [ ] `bridge.cr` constructs a `UI::ActionDispatcher` via `Voyager::HostBootstrap.build`, calls `mount_screen` before the first render, and assigns `Voyager.dispatcher` to that dispatcher.
- [ ] `bridge.cr` explicitly assigns `Voyager.state = state` (via the helper).
- [ ] All newly-introduced class-vars (`@@session`, `@@flash`, `@@dispatcher`) are nilable with `= nil` defaults (no initializer side effects).
- [ ] The dead `@@renderer` pin AND its local allocation in `initialize_runtime` are removed.
- [ ] `@@current_slug_buf` is seeded with `coord.current.id`'s slug before `@@initialized = true`.
- [ ] `samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr` exists with `Voyager::HostBootstrap.build`.
- [ ] `spec/asset_pipeline/voyager_host_bootstrap_spec.cr` exists and passes.
- [ ] `crystal spec` passes: 1707 + new bootstrap-spec examples / 4 pre-existing failures / 0 errors / 66 pending (the 4 failures are pre-existing and unrelated).
- [ ] Existing `voyager_dispatcher_integration_spec.cr` still passes (5 examples).
- [ ] iOS simulator build succeeds: `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator` produces `libvoyager.a`. Subsequent `xcodebuild` produces `VoyagerDemo.app`.
- [ ] `testColdLaunchSignInDispatcherWired` XCUITest passes.
- [ ] `testColdLaunchTodosDispatcherWired` XCUITest passes.
- [ ] `testRenderInitialSlug` XCUITest fixed with `XCTAssertTrue(foundRoot, ...)` and passes for `voyager-sign-in`, `voyager-todos`, `voyager-todo-editor`, `voyager-settings`.
- [ ] Owner hands-on recipe (Item 9 steps 1-7) executes successfully — owner confirms.
- [ ] Production Swift unchanged. C ABI unchanged.
- [ ] Implementer report includes a Codex review summary verdict (APPROVE or APPROVE_WITH_NOTES — no REVISE outstanding).

## 5. Risk register (R1-R11 + R11 elevated)

- **R1** — Cold-launch SIGSEGV on `Crystal::Once`. *Mitigation:* keep Thread/Fiber/Once init order; verify cold install in simulator.
- **R2** — Mid-stop pattern at evidence capture. *Mitigation:* Mode A → Mode B split (Section 7); Mode B failures loop back to same implementer in Mode A.
- **R3** — Audit harness can't validate runtime dispatch. *Mitigation:* hands-on gate is non-negotiable (Item 9).
- **R4** — Renderer-reuse vs FormState wire-time-read ordering. *Mitigation:* fresh renderer per call reads FormState.current AFTER mount_screen updated it. Implementer traces the first dispatch and reports.
- **R5** — Multiple consecutive dispatches before Swift re-renders. *Mitigation:* documented as "Voyager doesn't auto-dispatch" + audit-only.
- **R6** — `Voyager.dispatcher = nil` test teardown leak. *Mitigation:* the new bootstrap spec adds an after-each that resets `Voyager.dispatcher = nil` + `Voyager.state = Voyager::State.new`.
- **R7** — `Voyager.state` divergence after shim removal. *Mitigation:* explicit `Voyager.state = state` inside `HostBootstrap.build` (Item 7).
- **R8** — `Voyager.state ||= State.new` lazy-allocation race. *Mitigation:* assignment happens inside `HostBootstrap.build` before any screen/dispatcher use.
- **R9** — Fresh renderer per `render_slug` → makeUIView + updateUIView both render. *Mitigation:* `FormState#register` is non-overwriting once a key exists; sign-in + editor field registration must not depend on "exactly one render after mount." Implementer verifies on first dispatch trace.
- **R10** — Async Swift `@State` vs sync Crystal dispatch. *Mitigation:* documented as supported-host assumption — on_change subscribers must be renderer-only + non-reentrant.
- **R11 (ELEVATED — was MEDIUM, now HIGH)** — iOS bridge spec coverage. *Mitigation:* Item 7 (HostBootstrap helper + spec) is MANDATORY. Without this, the runtime sequence has zero automated assertion until simulator runs.

## 6. Implementation order

1. **Helper first** (Item 7): Author `host_bootstrap.cr` + `voyager_host_bootstrap_spec.cr`. Run `crystal spec` to confirm the helper builds + the new spec passes. This is the testable proof-point for the entire sequence.
2. **Bridge migration** (Items 1, 2, 6): Edit `bridge.cr`'s `initialize_runtime` to call `Voyager::HostBootstrap.build` + assign class-var pins; rewrite `render_slug` per Item 2; remove `@@renderer` + local renderer allocation.
3. **Slug-buffer seeding** (Item 1 step 13): Insert `copy_slug_to_buf` call before `@@initialized = true`.
4. **Initial-resync** (Item 3): Implement the `dispatcher.mount_screen + coord.replace_root` block with `@@suppress_route_changed` in `render_slug`.
5. **on_change subscriber** (Item 4): Verify the existing subscriber stays renderer-neutral.
6. **XCUITest fixes + smokes** (Item 8): Add `XCTAssertTrue` to `testRenderInitialSlug`; add the two new cold-launch smokes.
7. **Build + simulator install** (Mode A close): Build `libvoyager.a` for simulator. Run `xcodebuild` build. Confirm `.app` artifact exists. Run XCUITest. Report.
8. **Hand-test recipe execution** (Mode B): Owner runs Item 9 recipe.

## 7. Mid-stop dispatch protocol

Per `[[mid-stop-pattern]]`: implementer agents stop mid-action at simulator screenshot/interactive flows. This phase's implementer is dispatched in TWO modes:

- **Mode A (code work):** Make all the Crystal + test-Swift code changes. Build `libvoyager.a` for simulator. Run all the unit specs. Validate via the build chain. Run XCUITest. Do NOT need to manually drive the simulator.
- **Mode B (capture work):** A SEPARATE dispatch that takes Mode A's `.app` artifact, installs in simulator, runs the cold-launch tests + collects best-effort manual screenshots, attaches outputs to the implementer report.

Mode A must complete and report before Mode B is dispatched. If Mode A's build fails, Mode B never runs.

**Mode B failure loop:** If Mode B's XCUITest or build fails, architect dispatches Mode A REMEDIATION via SendMessage to the same implementer agent (NOT a new agent) — with Mode B's failure log + any simulator artifacts attached. The same agent retains context continuity; a fresh agent loses the bridge-construction reasoning.

## 8. Validation invocations

- **Crystal spec (host-bootstrap):** `crystal spec spec/asset_pipeline/voyager_host_bootstrap_spec.cr`.
- **Crystal spec (full):** `crystal spec` → baseline 1707 + new examples / 4 pre-existing failures / 0 errors / 66 pending.
- **Crystal spec (dispatcher integration):** `crystal spec spec/asset_pipeline/voyager_dispatcher_integration_spec.cr` (5 examples).
- **iOS simulator build:** `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator && xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`.
- **iOS UITests:** `xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:VoyagerVisualTests/testColdLaunchSignInDispatcherWired -only-testing:VoyagerVisualTests/testColdLaunchTodosDispatcherWired -only-testing:VoyagerVisualTests/testRenderInitialSlug`.
- **Codex review:** `codex exec -c 'model_reasoning_effort="medium"' "<prompt>" 2>&1 | tee /tmp/codex-iter-N.log | tail -300`.

## 9. Hard rules

- Forward commits only on `phase-08d.2-ios-bridge-migration`.
- NO Phase 8A/8B/8C/8D.1 API changes. If a gap appears, STOP and escalate.
- NO regression in iOS Voyager render behavior. The four routes must render the same UIView tree under the new path.
- NO Swift PRODUCTION code changes. Test Swift source is free; test target dependencies require architect approval first.
- NO C ABI changes to `bridge.cr` exports.
- NO touch on `web/static_site.cr` or `Voyager.build_route`.
- Codex review per iteration.
- Standard Claude co-author footer on commits: `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`.

— Architect (Claude Opus 4.7)
