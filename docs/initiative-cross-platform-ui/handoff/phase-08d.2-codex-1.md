Reading additional input from stdin...
OpenAI Codex v0.130.0
--------
workdir: /Users/crimsonknight/open_source_coding_projects/asset_pipeline
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR, /Users/crimsonknight/.codex/memories]
reasoning effort: medium
reasoning summaries: none
session id: 019e5f06-1147-76e0-b952-123f1e1d1a90
--------
user
You are the antagonist Codex reviewer for Phase 8D.2 of the asset_pipeline cross-platform UI initiative.

CONTEXT:
- Phase 8D.2 migrates samples/initiative-cross-platform-ui-voyager/ios/bridge.cr from the Voyager.build_route compat shim to the UI::ActionDispatcher host pattern that Phase 8D.1 landed on macOS.
- Brief: docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/brief-8d.2.md (DISPATCH-READY v2).
- Branch: phase-08d.2-ios-bridge-migration. HEAD includes 1 prior commit on this branch (HostBootstrap helper + spec) plus uncommitted bridge migration + XCUITest changes.
- The brief froze: C ABI of bridge.cr exports, production Swift source, Phase 8A/8B/8C/8D.1 APIs.

WHAT I SHIPPED (in order):

1. samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr (NEW)
   - `Voyager::HostBootstrap.build(initial_route_id : Symbol = :sign_in) : Result`
   - Calls VoyagerApp.bootstrap!, constructs state + coord + session + flash + dispatcher, calls dispatcher.mount_screen(coord.current), assigns Voyager.state + Voyager.dispatcher.
   - Returns a record with state/coord/session/flash/dispatcher.

2. spec/asset_pipeline/voyager_host_bootstrap_spec.cr (NEW)
   - 7 examples, all green. before_each resets Voyager.dispatcher = nil + Voyager.state = Voyager::State.new.
   - Asserts: state matches Voyager.state, dispatcher matches Voyager.dispatcher, mount_token != 0, navigation.current.id matches initial route, dispatcher.dispatch(:submit) from :sign_in lands on SignInController (proven by ReplaceRoot(:todos) + session["user_email"]), empty-input dispatch hits Rerender + flash["error"].

3. samples/initiative-cross-platform-ui-voyager/ios/bridge.cr (MIGRATED)
   - Added `require "../host_bootstrap"`.
   - REMOVED `@@renderer : UI::UIKit::Renderer? = nil` class var AND the in-`initialize_runtime` `renderer = UI::UIKit::Renderer.new` local allocation.
   - ADDED `@@session : UI::Session::InProcess? = nil`, `@@flash : UI::Flash::InProcess? = nil`, `@@dispatcher : UI::ActionDispatcher? = nil` (all nilable defaults, iOS class-init gap discipline).
   - REMOVED the direct `VoyagerApp.bootstrap!` call from initialize_runtime (it now happens inside HostBootstrap.build).
   - REPLACED state/coord/renderer construction in initialize_runtime with `result = Voyager::HostBootstrap.build(:sign_in)` + class-var pinning.
   - on_change subscriber stays renderer-neutral (slug copy + Swift cb), with the `@@suppress_route_changed` guard preserved. NO mount_screen call inside on_change.
   - Slug buffer seeded with coord.current.id's slug BEFORE @@initialized = true (Codex BLOCKER 1).
   - render_slug rewritten per brief Item 2: dispatcher.mount_screen(route) + coord.replace_root(route) inside begin/ensure `@@suppress_route_changed` block for initial-resync. Builds ctx via UI::ScreenContext::Native.new from dispatcher.current_form_state / session / flash / design_tokens / navigation. screen_class.new.build(ctx) → renderer.render(view).
   - Voyager.build_route is NO LONGER called from this path.
   - Defensive `if screen_class.nil?` placeholder branch preserved.
   - Uses coord.current.id (not the slug arg) for AX label + test_id derivation AFTER resync (current_slug = Voyager.slug_for_route_id(coord.current.id)).

4. samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift (UPDATED, test target only — production Swift untouched)
   - testRenderInitialSlug: changed silent XCTContext.runActivity to XCTAssertTrue(foundRoot, ...).
   - ADDED testColdLaunchSignInDispatcherWired: asserts app.buttons["Sign in"] exists within 10s after cold launch with VOYAGER_ROOT_SLUG=voyager-sign-in.
   - ADDED testColdLaunchTodosDispatcherWired: asserts app.buttons["voyager-todos-add"] exists within 10s after cold launch with VOYAGER_ROOT_SLUG=voyager-todos.

CRITICAL DISCOVERY (brief inaccuracy I had to fix):

The brief's Item 2 sample code put `renderer = UI::UIKit::Renderer.new` AFTER `view = screen_class.new.build(ctx)`. On first run that crashed the app with EXC_BAD_ACCESS / KERN_INVALID_ADDRESS PC=0. Crash trace (VoyagerDemo-2026-05-25-080058.ips):

  UI::DesignTokens::DeviceMetrics::current ←
  Voyager::SignInScreen#build ←
  VoyagerBridge::render_slug ←
  voyager_render

Root cause: `UI::UIKit::Renderer#initialize` calls `UI::DesignTokens::Device.install_provider { ... }` (uikit_renderer.cr line 192). Without that provider installed, `DeviceMetrics.current` SIGSEGVs. Screens call `DeviceMetrics.current` during build (e.g. SignInScreen for responsive layout). The OLD pre-8D.2 bridge constructed `renderer = UI::UIKit::Renderer.new` BEFORE calling Voyager.build_route, so the provider was installed before any build. The macOS host constructs its renderer ONCE in run!, before any build, so it's never affected. The brief's macOS-derived render_slug sample didn't account for this iOS-specific install-before-query ordering.

FIX: Moved `renderer = UI::UIKit::Renderer.new` to BEFORE `screen_class.new.build(ctx)` in render_slug. Documented in code comment with the .ips crash report reference. After the fix, all 3 XCUITests pass.

TEST RESULTS:

- crystal spec (full): 1714 examples / 4 failures / 0 errors / 66 pending. Baseline was 1707/4/0/66; 7 new examples from voyager_host_bootstrap_spec.cr. SAME 4 pre-existing failures (unrelated: phase2_verification + theme_spec).
- crystal spec spec/asset_pipeline/voyager_host_bootstrap_spec.cr: 7 examples / 0 failures.
- crystal spec spec/asset_pipeline/voyager_dispatcher_integration_spec.cr: 5 examples / 0 failures.
- ./build_crystal_lib.sh simulator: produces libvoyager.a successfully.
- xcodebuild ... build: produces VoyagerDemo.app successfully. BUILD SUCCEEDED.
- xcodebuild ... test -only-testing on the 3 named XCUITests: ** TEST SUCCEEDED **. Executed 3 tests, with 0 failures (0 unexpected) in 15.317s.

BRIEF INACCURACIES I FOUND:
1. Brief Item 2 sample code put renderer construction AFTER screen.build — causes crash on iOS. Fixed by moving it BEFORE build. Documented inline.
2. Brief §8 invokes xcodebuild with `-only-testing:VoyagerVisualTests/<name>` but the actual scheme test target is `VoyagerDemoUITests`, so the correct form is `-only-testing:VoyagerDemoUITests/VoyagerVisualTests/<name>`. Not a code change, just a runbook note.

ASK:
Please review this Phase 8D.2 iteration and return one of: APPROVE, APPROVE_WITH_NOTES, or REVISE (with specific findings).

Specifically check:
1. Did I correctly implement the brief's mount-before-publish invariant on initial-resync (dispatcher.mount_screen then coord.replace_root, in begin/ensure)?
2. Did I correctly handle the brief's "use coord.current after resync, not the slug arg" guidance for AX labels?
3. Is my renderer-construction-before-build fix architecturally honest, or does it hide a deeper layering issue I should escalate?
4. Are the class-var pin discipline + iOS class-init gap rules honored?
5. Are the XCUITest smokes specific enough to catch dispatcher-construction regressions?
6. Anything that should block PASS_WITH_NOTES at the close of this iteration?

Be antagonistic. Find what's wrong.
codex
I’ll review this as code, not just the narrative. I’m going to inspect the brief, bridge, bootstrap helper, specs, and test changes, then run the focused validation that can expose mismatches in the invariants you called out.
exec
/bin/zsh -lc "sed -n '1,260p' docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/brief-8d.2.md" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
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

exec
/bin/zsh -lc "sed -n '1,280p' samples/initiative-cross-platform-ui-voyager/ios/bridge.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
# Phase 6.10 — Voyager iOS bridge — exposed via build_crystal_lib.sh
# as libvoyager.a.
#
# C ABI:
#   void  voyager_init(void)
#       — must be called once before any render call. Seeds Crystal
#         probe singletons + builds the shared NavigationCoordinator
#         + State, both as INSTANCE state pinned in a module class
#         var (no class-var initializers — per the iOS class-init gap
#         memory item; we explicitly assign in voyager_init, never via
#         a class-var default value with side effects).
#
#   void* voyager_render(const char* slug)
#       — Builds a UI::View for the given slug (overrides any Crystal-
#         side current route; Swift drives the visible slug via the
#         @State binding). Renders via UIKit::Renderer and returns the
#         retained UIView*. Swift takes ownership via
#         takeRetainedValue().
#
#   const char* voyager_current_slug(void)
#       — Returns the slug-form of `coord.current.id` as a NUL-terminated
#         C string. The pointer is to a stable Crystal-managed buffer;
#         Swift may use it immediately but must not retain past the next
#         Crystal call. Used by the SwiftUI re-render trampoline.
#
#   void voyager_register_route_changed_callback(void (*cb)(const char*))
#       — Registers a C-callable Swift function pointer that Crystal
#         invokes inside coord.on_change with the new slug. This is the
#         runtime-navigation bridge: tapping a Crystal-rendered button
#         calls coord.push(...), which fires the registered callback,
#         which trips a Swift @State update, which causes SwiftUI to
#         re-render via voyager_render(new_slug).
#
# This file is the iOS-only twin of
# samples/initiative-cross-platform-ui-demo/ios/bridge.cr; both share
# the same cross-compile pattern documented in
# samples/initiative-cross-platform-ui-demo/ios/build_crystal_lib.sh.

{% if flag?(:ios) %}

  require "../app"
  require "../host_bootstrap"
  require "../../../src/ui/renderers/uikit_renderer"
  require "../../../src/ui/probes"

  module VoyagerBridge
    # Mirror Cascade's bridge: instance state held in module class
    # variables, but NO initializer side effects — explicit assignment
    # in initialize_runtime so the iOS class-init gap can't strand any
    # of these as nil.
    # IMPORTANT: NONE of these class vars carry an initializer with side
    # effects (no `= Bytes.new(64)`, no `= [] of ...`). The iOS class-init
    # gap (see `project_crystal_ios_class_init_gap` memory) silently
    # SKIPS class-var initializers when _main is hidden for Swift @main,
    # so any allocation that should happen at module load must happen
    # inside `initialize_runtime` (which we call explicitly from
    # voyager_init). Nilable defaults (`= nil`) are safe — the
    # underlying field is just a tagged nil pointer.
    @@initialized = false
    @@state : Voyager::State? = nil
    @@coord : UI::NavigationCoordinator? = nil
    # Phase 8D.2 — new collaborators owned by the dispatcher substrate.
    # `Voyager::HostBootstrap.build` constructs all four and we pin them
    # here so the GC doesn't collect them between Swift round-trips.
    # All declared as nilable with `= nil` defaults: iOS class-init gap
    # discipline (no initializer side effects).
    @@session : UI::Session::InProcess? = nil
    @@flash : UI::Flash::InProcess? = nil
    @@dispatcher : UI::ActionDispatcher? = nil
    @@last_native : UI::NativeView? = nil
    @@current_slug_buf : Bytes? = nil
    @@swift_route_changed_cb : (LibC::Char* -> Void)? = nil
    # Phase 6.10 Rem 4 — suppress the Swift route-changed callback
    # during the initial coord/slug resync (see render_slug). Without
    # this guard, replace_root → notify → Swift cb → render_slug →
    # resync loop fires recursively.
    @@suppress_route_changed = false

    def self.initialize_runtime
      return if @@initialized
      GC.init

      # Phase 6.10 Rem 3 — iOS class-init gap: bootstrap the Crystal
      # runtime subsystems that `__crystal_main`'s `init_runtime`
      # normally calls but the iOS embedding skips (because
      # `_main` is unexported in `build_crystal_lib.sh`).
      #
      # Without these three calls, any `Crystal::once`-guarded constant
      # (e.g. `String::CHAR_TO_DIGIT` used by `String#to_i?`) walks an
      # uninitialised `Thread::LinkedList(Fiber)` and SIGSEGVs at
      # `Thread::LinkedList(Fiber)#push` (KERN_INVALID_ADDRESS at 0x18).
      # Symptom in Rem 2: launching with
      # `VOYAGER_ROOT_SLUG=voyager-todo-editor` crashed silently inside
      # `Voyager.build_route` because the editor's
      # `(route.params[:id]? || "0").to_i?` triggered a const_read.
      # Crash trace preserved at
      # `~/Library/Logs/DiagnosticReports/VoyagerDemo-2026-05-23-155642.ips`.
      #
      # See `src/crystal/main.cr#init_runtime` for the upstream
      # invariant; the comment there reads:
      #   "`__crystal_once` directly or indirectly depends on `Fiber`
      #   and `Thread` so we explicitly initialize their class vars,
      #   then init crystal/once".
      #
      # This is the systematic fix the
      # `project_crystal_ios_class_init_gap` memory item flagged as
      # "Phase 5+ should address this systematically: either patch the
      # iOS embedding to explicitly call the missing init functions ..."
      Thread.init
      Fiber.init
      Crystal::Once.init

      UI::Probes::DismissProbe.reset
      UI::Probes::ToggleProbe.reset
      UI::Probes::SliderProbe.reset
      UI::Probes::TapProbe.reset
      UI::Probes::FormRowProbe.reset
      UI::Probes::RuntimeOverrideProbe.reset

      # Allocate the slug buffer here (NOT as a class-var default) so the
      # iOS class-init gap can't strand it as nil. 64 bytes accommodates
      # the longest known Voyager slug (~"voyager-todo-editor" = 19) with
      # huge headroom for future routes.
      @@current_slug_buf = Bytes.new(64)

      # Phase 8D.2 — call the canonical host-bootstrap helper. This
      # internally:
      #   * calls VoyagerApp.bootstrap! (registers all 4 screens —
      #     mandatory before any dispatcher action lookup; the iOS
      #     class-init gap means the compile-time class-var assignment
      #     in src/asset_pipeline/native_app.cr is skipped, so this
      #     re-runs the registrations defensively).
      #   * constructs Voyager::State + NavigationCoordinator (root
      #     :sign_in) + InProcess Session + InProcess Flash + a
      #     UI::ActionDispatcher.
      #   * calls dispatcher.mount_screen(coord.current) — bumps the
      #     mount_token and seeds FormState BEFORE any render so the
      #     wire-time TextField hook reads the new mount.
      #   * assigns Voyager.state + Voyager.dispatcher so screen
      #     callback closures dispatch through this host's dispatcher.
      #
      # We unpack the result into class-var pins so the GC won't
      # collect them across Swift round-trips.
      result = Voyager::HostBootstrap.build(:sign_in)
      @@state = result.state
      @@coord = result.coord
      @@session = result.session
      @@flash = result.flash
      @@dispatcher = result.dispatcher

      # The reactive substrate: when any dispatcher-routed Navigate /
      # Pop / ReplaceRoot fires `translate_result`, the dispatcher
      # calls mount_screen FIRST (swapping FormState.current under the
      # new token) and THEN invokes the coord op that fires this
      # on_change. The subscriber here is RENDERER-NEUTRAL — it copies
      # the slug into the buffer and hops into Swift via the registered
      # C callback. Swift then trips its @State binding, which re-runs
      # voyager_render(new_slug) and SwiftUI swaps the hosted UIView.
      #
      # NO mount_screen call here: translate_result already mounted
      # before publishing on_change (mount-before-publish invariant,
      # Phase 8B Codex iter-4 finding #1 + 8D.1 macOS pattern).
      # Re-mounting here would double-bump the token.
      coord = @@coord.not_nil!
      coord.on_change do |route|
        slug = Voyager.slug_for_route_id(route.id)
        copy_slug_to_buf(slug)
        cb = @@swift_route_changed_cb
        buf = @@current_slug_buf
        if @@suppress_route_changed
          # Initial resync — Swift callback intentionally suppressed.
        elsif !cb.nil? && !buf.nil?
          cb.call(buf.to_unsafe.as(LibC::Char*))
        end
      end

      # Seed the slug buffer with the bootstrap route's slug BEFORE
      # @@initialized = true (Codex BLOCKER 1 — voyager_current_slug()
      # must return the correct initial value before any navigation
      # event fires).
      copy_slug_to_buf(Voyager.slug_for_route_id(coord.current.id))
      @@initialized = true
    end

    private def self.copy_slug_to_buf(slug : String) : Nil
      buf = @@current_slug_buf
      return if buf.nil? # initialize_runtime always allocates this; guard for safety
      bytes = slug.to_slice
      n = Math.min(bytes.size, buf.size - 1)
      n.times { |i| buf[i] = bytes[i] }
      buf[n] = 0_u8
    end

    def self.current_slug_ptr : LibC::Char*
      initialize_runtime
      @@current_slug_buf.not_nil!.to_unsafe.as(LibC::Char*)
    end

    def self.register_route_changed(cb : LibC::Char* -> Void) : Nil
      @@swift_route_changed_cb = cb
    end

    # Build + render the requested slug. The slug Swift passes is the
    # source of truth for the INITIAL launch resync (Swift's
    # VOYAGER_ROOT_SLUG arg drives the first cold render). After the
    # resync, `coord.current` is the authoritative route and we render
    # from it — so AX labels + test_ids reflect the actual mounted
    # screen, not whatever slug Swift requested.
    #
    # Phase 8D.2 — Voyager.build_route is NO LONGER called from this
    # path. The dispatcher (constructed in initialize_runtime via
    # Voyager::HostBootstrap.build) owns FormState / session / flash /
    # design_tokens / navigation. We build a ScreenContext::Native from
    # the dispatcher's live state on every render so screen builds
    # observe the same form-state + flash + session the controller
    # layer just wrote.
    def self.render_slug(slug : String) : UI::NativeView
      initialize_runtime
      coord = @@coord.not_nil!
      dispatcher = @@dispatcher.not_nil!

      route = Voyager.route_for_slug(slug)

      # Phase 6.10 Rem 4 (Item 1) + Phase 8D.2 Item 3 — coord/slug
      # initial-resync through the host-driven path.
      #
      # When Swift launches with VOYAGER_ROOT_SLUG=voyager-todos, the
      # Crystal coord is still at its constructor default (:sign_in).
      # Without resync, the user's Save → coord.pop returns to
      # :sign_in instead of :todos.
      #
      # The previous logic only synced "if no Swift callback yet" —
      # but the callback gets registered BEFORE the first render, so
      # the branch never fired and the coord stayed misaligned.
      #
      # New rule (8D.2): if the coord is at depth=1 (just the
      # constructor root) AND the requested slug doesn't match, treat
      # this call as a first-time sync from the Swift launch arg.
      #
      # Mount-before-publish: replace_root synchronously notifies
      # on_change subscribers, so we MUST mount_screen first so
      # FormState.current is the new mount's before any subscriber
      # fires. Guard with `@@suppress_route_changed` (begin/ensure) so
      # the resulting notify doesn't fire the Swift callback (which
      # would loop us back into render_slug for the same slug).
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
      # If Swift's requested slug disagreed with coord.current and no
      # resync fired (e.g. mid-app slug requests after navigation has
      # begun), the rendered screen and AX identity stay consistent.
      current_slug = Voyager.slug_for_route_id(coord.current.id)
      reg = VoyagerApp.registration_for(coord.current.id)
      screen_class = reg.screen_class

      # Phase 6.10 Rem 1 — fresh renderer per render call to match
      # Cascade's proven-working pattern. Reusing a single renderer
      # across slug changes produced inverted-order / collapsed-field
      # layouts on iOS even though the same screen authoring rendered
      # correctly with a fresh renderer. The exact root cause appears
      # to be UIHostingController state inside SwiftKit facades; a new
      # renderer instance defensively rebuilds every facade chain.
      #
      # Phase 8D.2 — constructed BEFORE screen.build because the
      # renderer's initializer installs the
      # `UI::DesignTokens::Device.install_provider` block that screens
      # query via `UI::DesignTokens::DeviceMetrics.current` during
      # their build phase (e.g. SignInScreen reads DeviceMetrics for
      # responsive layout). Constructing the renderer AFTER build
      # SIGSEGVs at PC=0 because no provider is installed when build
      # runs (verified via VoyagerDemo-2026-05-25-080058.ips: faulting
      # frame is `UI::DesignTokens::DeviceMetrics::current` inside

exec
/bin/zsh -lc "sed -n '1,220p' samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
# Phase 8D.2 — flag-agnostic host bootstrap helper.
#
# Encapsulates the canonical dispatcher construction sequence so the
# iOS bridge AND any future host can call ONE primitive instead of
# duplicating the order. The macOS host predates this helper and may
# be migrated to it in a follow-up cleanup; it is NOT in 8D.2 scope.
#
# Returns a `Bootstrap::Result` struct carrying all the constructed
# collaborators. Caller is responsible for pinning them per its own
# GC discipline (iOS class-vars; macOS local vars).
#
# Per Codex HIGH 4 + R11 elevation in brief-8d.2.md: extracting this
# sequence makes the runtime invariants ("bootstrap before construct",
# "mount_screen before any render", "assign Voyager.state and
# Voyager.dispatcher exactly once") testable under default `crystal
# spec` — no `-Dios` required because the helper does not depend on
# the UIKit renderer.

require "./app"

module Voyager
  module HostBootstrap
    record Result,
      state : Voyager::State,
      coord : UI::NavigationCoordinator,
      session : UI::Session::InProcess,
      flash : UI::Flash::InProcess,
      dispatcher : UI::ActionDispatcher

    # Build the full host substrate. Calls `VoyagerApp.bootstrap!`,
    # constructs state + coord + session + flash + dispatcher, calls
    # `dispatcher.mount_screen` for the initial route, assigns
    # `Voyager.state` and `Voyager.dispatcher`. Returns the constructed
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

      Result.new(
        state: state,
        coord: coord,
        session: session,
        flash: flash,
        dispatcher: dispatcher,
      )
    end
  end
end

exec
/bin/zsh -lc "sed -n '1,260p' spec/asset_pipeline/voyager_host_bootstrap_spec.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
require "../spec_helper"
require "../../samples/initiative-cross-platform-ui-voyager/host_bootstrap"

# Phase 8D.2 Item 7 — Voyager::HostBootstrap.build spec.
#
# Validates the flag-agnostic host bootstrap helper that the iOS bridge
# (and any future host) calls to construct the dispatcher substrate.
# These specs are the testable proof-point for the entire runtime
# sequence — without them, the iOS bridge's runtime assumptions are
# unverified until the simulator runs.
#
# Per brief §3 Item 7 acceptance:
#   - Returned `state` matches `Voyager.state`.
#   - Returned `dispatcher` matches `Voyager.dispatcher`.
#   - `dispatcher.current_form_state.mount_token != 0` (mount_screen ran).
#   - `dispatcher.navigation.current.id == initial_route_id`.
#   - `dispatcher.dispatch(:submit)` from `:sign_in` mount lands on
#     `Voyager::SignInController` (proven by the controller's
#     observable side effects).
#
# Per R6 (Voyager.dispatcher = nil teardown leak): each `it` block
# resets `Voyager.dispatcher` and `Voyager.state` to a fresh baseline
# so test ordering can't carry state forward.

describe "Voyager::HostBootstrap.build" do
  Spec.before_each do
    Voyager.dispatcher = nil
    Voyager.state = Voyager::State.new
  end

  it "returns a state that matches Voyager.state" do
    result = Voyager::HostBootstrap.build(:sign_in)
    result.state.should be(Voyager.state)
  end

  it "returns a dispatcher that matches Voyager.dispatcher" do
    result = Voyager::HostBootstrap.build(:sign_in)
    result.dispatcher.should be(Voyager.dispatcher.not_nil!)
  end

  it "bumps mount_token after mount_screen (token != 0)" do
    result = Voyager::HostBootstrap.build(:sign_in)
    result.dispatcher.current_form_state.mount_token.should_not eq 0_i64
  end

  it "navigation.current.id matches the initial_route_id (default :sign_in)" do
    result = Voyager::HostBootstrap.build
    result.dispatcher.navigation.current.id.should eq :sign_in
  end

  it "navigation.current.id matches the explicit initial_route_id (:todos)" do
    result = Voyager::HostBootstrap.build(:todos)
    result.dispatcher.navigation.current.id.should eq :todos
  end

  it "dispatcher.dispatch(:submit) from :sign_in invokes SignInController#submit" do
    # SignInController#submit's observable side effects:
    #   * On non-empty email + password: session["user_email"] = email,
    #     ReplaceRoot(:todos) → stack becomes [todos], depth == 1.
    #   * On empty inputs: flash["error"] set, Rerender (stack
    #     unchanged).
    # Both branches are SignInController-only behavior; observing them
    # proves the dispatch landed on SignInController.
    result = Voyager::HostBootstrap.build(:sign_in)
    result.dispatcher.current_form_state.update("email", "seth@example.com")
    result.dispatcher.current_form_state.update("password", "hunter2")

    result.dispatcher.dispatch(:submit)

    result.dispatcher.navigation.current.id.should eq :todos
    result.dispatcher.navigation.depth.should eq 1
    result.dispatcher.session["user_email"]?.should eq "seth@example.com"
  end

  it "dispatcher.dispatch(:submit) with empty inputs rerenders + sets flash error" do
    # The Rerender branch is SignInController-specific behavior too —
    # an empty-input dispatch confirms the controller (not some fallback
    # path) handled the action.
    result = Voyager::HostBootstrap.build(:sign_in)
    initial_stack = result.dispatcher.navigation.routes.map(&.id)

    result.dispatcher.dispatch(:submit)

    result.dispatcher.navigation.routes.map(&.id).should eq initial_stack
    result.dispatcher.flash["error"]?.should eq "Please provide both email and password."
  end
end

codex
The first pass shows the migration mostly follows the requested sequence: bootstrap is isolated, the bridge pins nilable collaborators, and the resync order is visibly mount then replace. I’m drilling into the lower half of `render_slug`, the Swift smoke tests, and the dispatcher/navigation internals now because that’s where a false PASS would hide.
exec
/bin/zsh -lc "sed -n '220,520p' samples/initiative-cross-platform-ui-voyager/ios/bridge.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "sed -n '1,260p' samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
      dispatcher = @@dispatcher.not_nil!

      route = Voyager.route_for_slug(slug)

      # Phase 6.10 Rem 4 (Item 1) + Phase 8D.2 Item 3 — coord/slug
      # initial-resync through the host-driven path.
      #
      # When Swift launches with VOYAGER_ROOT_SLUG=voyager-todos, the
      # Crystal coord is still at its constructor default (:sign_in).
      # Without resync, the user's Save → coord.pop returns to
      # :sign_in instead of :todos.
      #
      # The previous logic only synced "if no Swift callback yet" —
      # but the callback gets registered BEFORE the first render, so
      # the branch never fired and the coord stayed misaligned.
      #
      # New rule (8D.2): if the coord is at depth=1 (just the
      # constructor root) AND the requested slug doesn't match, treat
      # this call as a first-time sync from the Swift launch arg.
      #
      # Mount-before-publish: replace_root synchronously notifies
      # on_change subscribers, so we MUST mount_screen first so
      # FormState.current is the new mount's before any subscriber
      # fires. Guard with `@@suppress_route_changed` (begin/ensure) so
      # the resulting notify doesn't fire the Swift callback (which
      # would loop us back into render_slug for the same slug).
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
      # If Swift's requested slug disagreed with coord.current and no
      # resync fired (e.g. mid-app slug requests after navigation has
      # begun), the rendered screen and AX identity stay consistent.
      current_slug = Voyager.slug_for_route_id(coord.current.id)
      reg = VoyagerApp.registration_for(coord.current.id)
      screen_class = reg.screen_class

      # Phase 6.10 Rem 1 — fresh renderer per render call to match
      # Cascade's proven-working pattern. Reusing a single renderer
      # across slug changes produced inverted-order / collapsed-field
      # layouts on iOS even though the same screen authoring rendered
      # correctly with a fresh renderer. The exact root cause appears
      # to be UIHostingController state inside SwiftKit facades; a new
      # renderer instance defensively rebuilds every facade chain.
      #
      # Phase 8D.2 — constructed BEFORE screen.build because the
      # renderer's initializer installs the
      # `UI::DesignTokens::Device.install_provider` block that screens
      # query via `UI::DesignTokens::DeviceMetrics.current` during
      # their build phase (e.g. SignInScreen reads DeviceMetrics for
      # responsive layout). Constructing the renderer AFTER build
      # SIGSEGVs at PC=0 because no provider is installed when build
      # runs (verified via VoyagerDemo-2026-05-25-080058.ips: faulting
      # frame is `UI::DesignTokens::DeviceMetrics::current` inside
      # `Voyager::SignInScreen#build` inside `VoyagerBridge#render_slug`).
      # The macOS host avoids this by constructing the renderer ONCE
      # at startup; iOS uses a fresh renderer per call but must still
      # honor the install-before-query ordering.
      renderer = UI::UIKit::Renderer.new

      # Defensive guard — not robust unknown-slug handling
      # (route_for_slug already maps unknown slugs to :sign_in).
      # Catches future registration shapes where screen_class could be
      # nil (e.g. a web-only screen registered via the screen macro
      # without a controller_class — see Phase 8C web-only-screen
      # support in src/asset_pipeline/native_app.cr).
      if screen_class.nil?
        placeholder = UI::Label.new("Unknown screen for route: #{coord.current.id}")
        placeholder.accessibility_label = "Unknown route"
        placeholder.test_id = "voyager-root-unknown"
        native = renderer.render(placeholder.as(UI::View))
        @@last_native = native
        return native
      end

      # Build a fresh ScreenContext::Native from the dispatcher's live
      # FormState / session / flash / design_tokens / navigation. This
      # is the proven Phase 8B spike pattern + 8D.1 macOS host pattern
      # (samples/initiative-cross-platform-ui-voyager/macos/host.cr#rebuild_for).
      # action_params is empty at render time — it only carries values
      # during in-flight dispatches (e.g. swipe-row Edit's
      # {"todo_id" => "3"}).
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

      native = renderer.render(view)
      @@last_native = native
      native
    end
  end

  # ---------------------------------------------------------------------------
  # C ABI exports
  # ---------------------------------------------------------------------------

  fun voyager_init : Void
    VoyagerBridge.initialize_runtime
  end

  fun voyager_render(slug_ptr : LibC::Char*) : Void*
    VoyagerBridge.initialize_runtime
    slug = String.new(slug_ptr)
    native = VoyagerBridge.render_slug(slug)
    native.handle.ptr!
  end

  fun voyager_current_slug : LibC::Char*
    VoyagerBridge.current_slug_ptr
  end

  fun voyager_register_route_changed_callback(cb : LibC::Char* -> Void) : Void
    VoyagerBridge.register_route_changed(cb)
  end

{% end %}

 succeeded in 0ms:
import XCTest

/// VoyagerVisualTests — Phase 6.10 iOS visual capture harness.
///
/// Unlike Cascade (which captures one slug at a time), Voyager runs a
/// navigable scenario: sign-in -> todos -> settings -> back -> todos.
/// This test taps through the full state-propagation litmus and
/// captures a screenshot at each step.
///
/// Pattern mirrors
/// samples/initiative-cross-platform-ui-demo/ios/UITests/CascadeVisualTests.swift
/// for the launch + screenshot pieces; the navigation taps + assertions
/// are the new bits.
final class VoyagerVisualTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Snapshot one slug (used by the audit harness when capturing
    /// individual screen baselines).
    func testRenderInitialSlug() throws {
        let env = ProcessInfo.processInfo.environment
        let slug = env["VOYAGER_ROOT_SLUG"] ?? "voyager-sign-in"
        let appearance = env["VOYAGER_APPEARANCE"] ?? env["HIG_APPEARANCE"] ?? "light"

        let app = XCUIApplication()
        app.launchArguments = ["-VoyagerRoot", slug]
        app.launchEnvironment = [
            "VOYAGER_ROOT_SLUG": slug,
            "VOYAGER_APPEARANCE": appearance,
        ]
        app.launch()

        let crystalRoot = app.otherElements["voyager-root-\(slug)"]
        let hostRoot    = app.otherElements["voyager-root-host"]
        let foundRoot   = crystalRoot.waitForExistence(timeout: 10)
                       || hostRoot.waitForExistence(timeout: 2)
        XCTAssertTrue(foundRoot,
            "voyager-root-\(slug) not discoverable in AX tree within 10s. " +
            "Likely cold-render failure for slug \(slug).")

        Thread.sleep(forTimeInterval: 0.4)

        let snapshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: snapshot)
        attachment.name = "\(slug)-\(appearance)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Phase 8D.2 Item 8 — cold-launch dispatcher-wired smoke (Sign-in).
    ///
    /// Asserts that the iOS bridge's initialize_runtime →
    /// Voyager::HostBootstrap.build → render_slug pipeline cold-launches
    /// to a working Sign-in screen with the AX-discoverable "Sign in"
    /// button present. If this fails, one of:
    ///   - Crystal class-init crash (Thread/Fiber/Once gap regression).
    ///   - HostBootstrap.build raised (dispatcher construction broken).
    ///   - render_slug raised (ScreenContext::Native shape mismatch).
    ///   - UIKit renderer produced an unhittable view tree.
    func testColdLaunchSignInDispatcherWired() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-sign-in"]
        app.launch()

        let signIn = app.buttons["Sign in"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 10),
            "Cold-launch failed to reach AX-discoverable Sign-in button. " +
            "Possible class-init crash, dispatcher construction failure, or render failure.")
    }

    /// Phase 8D.2 Item 8 — cold-launch dispatcher-wired smoke (Todos).
    ///
    /// Asserts that VOYAGER_ROOT_SLUG=voyager-todos cold-launches the
    /// Todos screen specifically (not just "some screen"). The
    /// voyager-todos-add test_id is unique to the Add Todo button on
    /// the Todos screen, so finding it proves:
    ///   - initial-slug resync (dispatcher.mount_screen +
    ///     coord.replace_root) ran.
    ///   - ScreenContext::Native built from the dispatcher's live
    ///     FormState / session / flash worked.
    ///   - TodosScreen#build rendered without raising.
    ///
    /// Asserting on voyager-todos-add specifically (not a label-or-id
    /// disjunction) keeps the smoke specific: this is the Todos
    /// screen, not just "some screen that happens to have a Settings
    /// button too."
    func testColdLaunchTodosDispatcherWired() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-todos"]
        app.launch()

        let addButton = app.buttons["voyager-todos-add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10),
            "Cold-launch with VOYAGER_ROOT_SLUG=voyager-todos failed to render the Todos screen. " +
            "voyager-todos-add not AX-discoverable. Initial slug resync " +
            "(dispatcher.mount_screen + coord.replace_root) likely broken.")
    }

    /// Full navigation flow — the manual verification the owner asked
    /// for, automated as a smoke test. Launches at sign-in, asserts
    /// AX traversal at each step, attempts each tap, captures a
    /// screenshot at each step.
    ///
    /// Phase 6.10 Rem 2 caveat: even when AX traversal succeeds
    /// (Item 2 PASS), the SwiftUI Button's action closure does NOT
    /// fire under XCUITest tap synthesis on this hierarchy — the
    /// touch-routing bug is documented separately. The AX
    /// assertions still pass because they only require the elements
    /// to be DISCOVERABLE in the tree, not interactive.
    func testNavigationFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-VoyagerRoot", "voyager-sign-in"]
        app.launch()

        // ---- Step 1: sign-in screen ----
        // We don't assert on the host's own accessibilityIdentifier
        // ("voyager-root-host") — Rem 2 iter2 found that even with
        // `.accessibilityElement(children: .contain)` on the SwiftUI
        // ScrollView wrapper, the inner UIViewRepresentable's
        // identifier does NOT propagate up to XCUI's
        // `app.otherElements`. What DOES propagate is the embedded
        // Crystal UIButton's accessibility label + identifier (verified
        // by the iter1 "Activation point invalid" log), so we rely on
        // app.buttons["Sign in"] / app.buttons["voyager-sign-in-submit"]
        // as the AX traversal proof.
        Thread.sleep(forTimeInterval: 3.0)
        attachScreenshot(name: "step1-sign-in")

        // ---- Step 2: discover Sign in button in AX tree, then tap ----
        // Rem 2 Item 2 acceptance: the button must be FOUND via AX
        // (label "Sign in" OR test_id "voyager-sign-in-submit"). The
        // subsequent tap may or may not fire the Crystal on_tap (see
        // Item 1 escalation note); the AX discovery is the Item 2
        // proof.
        var signIn = app.buttons["Sign in"]
        let signInFoundByLabel = signIn.waitForExistence(timeout: 5)
        if !signInFoundByLabel {
            signIn = app.buttons["voyager-sign-in-submit"]
        }
        XCTAssertTrue(signIn.waitForExistence(timeout: 5),
            "Sign in button not found in AX tree by label 'Sign in' nor by " +
            "test_id 'voyager-sign-in-submit'. AX traversal through the " +
            "UIViewRepresentable boundary failed.")

        attachScreenshot(name: "step1b-pre-tap")

        // Phase 6.10 Rem 3 — XCUITest tap synthesis on a UIHostingController-
        // hosted SwiftUI Button does NOT fire the Button's action closure
        // under iPhone 17 simulator even with Path A (UIHostingController
        // VC parenting) in place. Verified via the unified log
        // stream: the container's VC parenting succeeds (5 controllers
        // attached to root SwiftUI UIHostingController), the tap reaches
        // `_UIHostingView` (hitTest returns it for dy=0.53..0.56), but
        // `CallbackBridge.fire` never fires. See
        // handoff/phase-06.10-remediation-3-codex-blocker.md for the
        // captured evidence and the proposed next-iteration path.
        //
        // The XCUITest below still verifies the AX traversal layer
        // (Item 2 from Rem 2) by waiting for the Sign-in button to
        // resolve in the AX tree. Tap synthesis is best-effort —
        // sweep app-global coordinates against multiple dy values to
        // exercise the touch chain in case the simulator's tap
        // synthesizer behaves differently across iOS versions.
        for trialDy in [0.40, 0.45, 0.50, 0.55, 0.60] {
            let c = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: trialDy))
            c.tap()
            Thread.sleep(forTimeInterval: 0.4)
            if app.buttons["Settings"].exists || app.buttons["voyager-todos-settings"].exists {
                break
            }
        }
        Thread.sleep(forTimeInterval: 1.0)
        attachScreenshot(name: "step2-todos")
        Thread.sleep(forTimeInterval: 2.5)
        attachScreenshot(name: "step2-todos")

        // ---- Step 3: discover Settings button on Todos screen ----
        //
        // If step 2's tap successfully navigated to Todos, the
        // Settings button is visible. If it didn't (interaction bug
        // is open), this assertion will fail — making the test
        // accurately report "AX OK on sign-in, navigation stuck."
        var settingsBtn = app.buttons["Settings"]
        let settingsFoundByLabel = settingsBtn.waitForExistence(timeout: 5)
        if !settingsFoundByLabel {
            settingsBtn = app.buttons["voyager-todos-settings"]
        }
        // Do NOT XCTAssertTrue here — if interaction is broken,
        // navigation didn't happen and Settings won't exist. Record
        // the state instead of failing so the AX-traversal pass on
        // step 2 is preserved as proof.
        let settingsFound = settingsBtn.waitForExistence(timeout: 3)
        XCTContext.runActivity(named: "step3-settings-discoverable=\(settingsFound)") { _ in }
        if settingsFound {
            let settingsCoord = settingsBtn.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            settingsCoord.press(forDuration: 0.12)
            Thread.sleep(forTimeInterval: 1.5)
            attachScreenshot(name: "step3-settings")

            // ---- Step 4: back from Settings ----
            var backBtn = app.buttons["Back to todos"]
            if !backBtn.waitForExistence(timeout: 5) {
                backBtn = app.buttons["voyager-settings-back"]
            }
            if backBtn.waitForExistence(timeout: 3) {
                let backCoord = backBtn.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                backCoord.press(forDuration: 0.12)
                Thread.sleep(forTimeInterval: 1.5)
                attachScreenshot(name: "step4-back-to-todos")
            } else {
                attachScreenshot(name: "step4-back-not-found")
            }
        } else {
            // Interaction bug — Sign-in tap did not navigate. Record
            // the stuck screenshot so the proof trail captures the
            // observable symptom.
            attachScreenshot(name: "step3-still-on-sign-in")
        }
    }

    private func attachScreenshot(name: String) {
        let snapshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: snapshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Phase 6.10 Rem 4 Item 1 — Save-propagation proof.
    ///
    /// Launches at the Todos screen, snapshots the initial state,
    /// drives an Add Todo → fill Title → Save flow, and snapshots
    /// the Todos list afterward. The owner's complaint was that the
    /// new todo doesn't appear in the list — the after-screenshot
    /// must show one more row.
    ///
    /// Even when XCUITest tap synthesis doesn't drive SwiftUI Button
    /// actions reliably, the underlying Save chain can be exercised
    /// by `app.buttons["..."].tap()` via the SwiftUI button
    /// accessibility trait (the AX path bypasses hit-testing).
    func testSavePropagation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-VoyagerRoot", "voyager-todos"]
        app.launchEnvironment = [
            "VOYAGER_ROOT_SLUG": "voyager-todos",
        ]
        app.launch()
        Thread.sleep(forTimeInterval: 2.0)
        attachScreenshot(name: "save-propagation-step1-todos-before")

        // Tap Add Todo
        var addBtn = app.buttons["Add a new todo"]
        if !addBtn.waitForExistence(timeout: 5) {
            addBtn = app.buttons["voyager-todos-add"]
        }
        if addBtn.waitForExistence(timeout: 3) {
            addBtn.tap()
            Thread.sleep(forTimeInterval: 1.5)

exec
/bin/zsh -lc 'git diff -- samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr spec/asset_pipeline/voyager_host_bootstrap_spec.cr samples/initiative-cross-platform-ui-voyager/ios/bridge.cr samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
diff --git a/samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift b/samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift
index 1a5e1109..860c5806 100644
--- a/samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift
+++ b/samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift
@@ -36,9 +36,9 @@ final class VoyagerVisualTests: XCTestCase {
         let hostRoot    = app.otherElements["voyager-root-host"]
         let foundRoot   = crystalRoot.waitForExistence(timeout: 10)
                        || hostRoot.waitForExistence(timeout: 2)
-        if !foundRoot {
-            XCTContext.runActivity(named: "root-not-found") { _ in }
-        }
+        XCTAssertTrue(foundRoot,
+            "voyager-root-\(slug) not discoverable in AX tree within 10s. " +
+            "Likely cold-render failure for slug \(slug).")
 
         Thread.sleep(forTimeInterval: 0.4)
 
@@ -49,6 +49,55 @@ final class VoyagerVisualTests: XCTestCase {
         add(attachment)
     }
 
+    /// Phase 8D.2 Item 8 — cold-launch dispatcher-wired smoke (Sign-in).
+    ///
+    /// Asserts that the iOS bridge's initialize_runtime →
+    /// Voyager::HostBootstrap.build → render_slug pipeline cold-launches
+    /// to a working Sign-in screen with the AX-discoverable "Sign in"
+    /// button present. If this fails, one of:
+    ///   - Crystal class-init crash (Thread/Fiber/Once gap regression).
+    ///   - HostBootstrap.build raised (dispatcher construction broken).
+    ///   - render_slug raised (ScreenContext::Native shape mismatch).
+    ///   - UIKit renderer produced an unhittable view tree.
+    func testColdLaunchSignInDispatcherWired() throws {
+        let app = XCUIApplication()
+        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-sign-in"]
+        app.launch()
+
+        let signIn = app.buttons["Sign in"]
+        XCTAssertTrue(signIn.waitForExistence(timeout: 10),
+            "Cold-launch failed to reach AX-discoverable Sign-in button. " +
+            "Possible class-init crash, dispatcher construction failure, or render failure.")
+    }
+
+    /// Phase 8D.2 Item 8 — cold-launch dispatcher-wired smoke (Todos).
+    ///
+    /// Asserts that VOYAGER_ROOT_SLUG=voyager-todos cold-launches the
+    /// Todos screen specifically (not just "some screen"). The
+    /// voyager-todos-add test_id is unique to the Add Todo button on
+    /// the Todos screen, so finding it proves:
+    ///   - initial-slug resync (dispatcher.mount_screen +
+    ///     coord.replace_root) ran.
+    ///   - ScreenContext::Native built from the dispatcher's live
+    ///     FormState / session / flash worked.
+    ///   - TodosScreen#build rendered without raising.
+    ///
+    /// Asserting on voyager-todos-add specifically (not a label-or-id
+    /// disjunction) keeps the smoke specific: this is the Todos
+    /// screen, not just "some screen that happens to have a Settings
+    /// button too."
+    func testColdLaunchTodosDispatcherWired() throws {
+        let app = XCUIApplication()
+        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-todos"]
+        app.launch()
+
+        let addButton = app.buttons["voyager-todos-add"]
+        XCTAssertTrue(addButton.waitForExistence(timeout: 10),
+            "Cold-launch with VOYAGER_ROOT_SLUG=voyager-todos failed to render the Todos screen. " +
+            "voyager-todos-add not AX-discoverable. Initial slug resync " +
+            "(dispatcher.mount_screen + coord.replace_root) likely broken.")
+    }
+
     /// Full navigation flow — the manual verification the owner asked
     /// for, automated as a smoke test. Launches at sign-in, asserts
     /// AX traversal at each step, attempts each tap, captures a
diff --git a/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr b/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr
index 5319bab5..6894b7c7 100644
--- a/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr
+++ b/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr
@@ -39,6 +39,7 @@
 {% if flag?(:ios) %}
 
   require "../app"
+  require "../host_bootstrap"
   require "../../../src/ui/renderers/uikit_renderer"
   require "../../../src/ui/probes"
 
@@ -58,7 +59,14 @@
     @@initialized = false
     @@state : Voyager::State? = nil
     @@coord : UI::NavigationCoordinator? = nil
-    @@renderer : UI::UIKit::Renderer? = nil
+    # Phase 8D.2 — new collaborators owned by the dispatcher substrate.
+    # `Voyager::HostBootstrap.build` constructs all four and we pin them
+    # here so the GC doesn't collect them between Swift round-trips.
+    # All declared as nilable with `= nil` defaults: iOS class-init gap
+    # discipline (no initializer side effects).
+    @@session : UI::Session::InProcess? = nil
+    @@flash : UI::Flash::InProcess? = nil
+    @@dispatcher : UI::ActionDispatcher? = nil
     @@last_native : UI::NativeView? = nil
     @@current_slug_buf : Bytes? = nil
     @@swift_route_changed_cb : (LibC::Char* -> Void)? = nil
@@ -109,39 +117,51 @@
       UI::Probes::FormRowProbe.reset
       UI::Probes::RuntimeOverrideProbe.reset
 
-      # Phase 8D.1 — VoyagerApp.bootstrap! re-registers all 4 screen
-      # registrations through compile-time-emitted class methods. The
-      # `Voyager.build_route` compat shim looks up registrations via
-      # `VoyagerApp.registration_for(route.id)`; without this call, the
-      # iOS class-init gap could leave `@@screens` stranded as nil and
-      # the very first render_slug call would raise UnknownRouteError.
-      # See src/asset_pipeline/native_app.cr:33-37 for the gap rationale
-      # (this is the bridge entry path the framework docs reference).
-      # NOTE: this is the minimum-required-correctness fix for the
-      # Phase 8D.1 compat shim path. Full iOS migration to the
-      # ActionDispatcher is Phase 8D.2 scope.
-      VoyagerApp.bootstrap!
-
       # Allocate the slug buffer here (NOT as a class-var default) so the
       # iOS class-init gap can't strand it as nil. 64 bytes accommodates
       # the longest known Voyager slug (~"voyager-todo-editor" = 19) with
       # huge headroom for future routes.
       @@current_slug_buf = Bytes.new(64)
 
-      state = Voyager::State.new
-      coord = UI::NavigationCoordinator.new(
-        UI::NavigationCoordinator::Route.new(:sign_in)
-      )
-      renderer = UI::UIKit::Renderer.new
-      # Phase 6.11 Item 1 — brand override removed. Renderer carries
-      # `UI::DesignTokens::Tokens.default` already; no per-host override.
+      # Phase 8D.2 — call the canonical host-bootstrap helper. This
+      # internally:
+      #   * calls VoyagerApp.bootstrap! (registers all 4 screens —
+      #     mandatory before any dispatcher action lookup; the iOS
+      #     class-init gap means the compile-time class-var assignment
+      #     in src/asset_pipeline/native_app.cr is skipped, so this
+      #     re-runs the registrations defensively).
+      #   * constructs Voyager::State + NavigationCoordinator (root
+      #     :sign_in) + InProcess Session + InProcess Flash + a
+      #     UI::ActionDispatcher.
+      #   * calls dispatcher.mount_screen(coord.current) — bumps the
+      #     mount_token and seeds FormState BEFORE any render so the
+      #     wire-time TextField hook reads the new mount.
+      #   * assigns Voyager.state + Voyager.dispatcher so screen
+      #     callback closures dispatch through this host's dispatcher.
+      #
+      # We unpack the result into class-var pins so the GC won't
+      # collect them across Swift round-trips.
+      result = Voyager::HostBootstrap.build(:sign_in)
+      @@state = result.state
+      @@coord = result.coord
+      @@session = result.session
+      @@flash = result.flash
+      @@dispatcher = result.dispatcher
 
-      # The reactive substrate: when ANY Crystal code (a tap handler
-      # inside a rendered button, the sign-in submit, the settings
-      # back action) calls coord.push/pop, this callback fires and we
-      # hop into Swift via the registered route-changed C callback. The
-      # Swift side then trips its @State binding, which re-runs
+      # The reactive substrate: when any dispatcher-routed Navigate /
+      # Pop / ReplaceRoot fires `translate_result`, the dispatcher
+      # calls mount_screen FIRST (swapping FormState.current under the
+      # new token) and THEN invokes the coord op that fires this
+      # on_change. The subscriber here is RENDERER-NEUTRAL — it copies
+      # the slug into the buffer and hops into Swift via the registered
+      # C callback. Swift then trips its @State binding, which re-runs
       # voyager_render(new_slug) and SwiftUI swaps the hosted UIView.
+      #
+      # NO mount_screen call here: translate_result already mounted
+      # before publishing on_change (mount-before-publish invariant,
+      # Phase 8B Codex iter-4 finding #1 + 8D.1 macOS pattern).
+      # Re-mounting here would double-bump the token.
+      coord = @@coord.not_nil!
       coord.on_change do |route|
         slug = Voyager.slug_for_route_id(route.id)
         copy_slug_to_buf(slug)
@@ -154,9 +174,10 @@
         end
       end
 
-      @@state = state
-      @@coord = coord
-      @@renderer = renderer
+      # Seed the slug buffer with the bootstrap route's slug BEFORE
+      # @@initialized = true (Codex BLOCKER 1 — voyager_current_slug()
+      # must return the correct initial value before any navigation
+      # event fires).
       copy_slug_to_buf(Voyager.slug_for_route_id(coord.current.id))
       @@initialized = true
     end
@@ -180,57 +201,123 @@
     end
 
     # Build + render the requested slug. The slug Swift passes is the
-    # source of truth — Crystal does NOT override it from the
-    # coordinator's current state, because Swift may be requesting a
-    # slug that the coordinator already moved past (e.g. SwiftUI may
-    # batch state changes). Voyager.build_route operates from the
-    # shared `state` so any prior coord mutations (state.hide_completed
-    # toggling, etc.) are honored.
+    # source of truth for the INITIAL launch resync (Swift's
+    # VOYAGER_ROOT_SLUG arg drives the first cold render). After the
+    # resync, `coord.current` is the authoritative route and we render
+    # from it — so AX labels + test_ids reflect the actual mounted
+    # screen, not whatever slug Swift requested.
+    #
+    # Phase 8D.2 — Voyager.build_route is NO LONGER called from this
+    # path. The dispatcher (constructed in initialize_runtime via
+    # Voyager::HostBootstrap.build) owns FormState / session / flash /
+    # design_tokens / navigation. We build a ScreenContext::Native from
+    # the dispatcher's live state on every render so screen builds
+    # observe the same form-state + flash + session the controller
+    # layer just wrote.
     def self.render_slug(slug : String) : UI::NativeView
       initialize_runtime
-      state = @@state.not_nil!
       coord = @@coord.not_nil!
-
-      # Phase 6.10 Rem 1 — fresh renderer per render call to match
-      # Cascade's proven-working pattern. Reusing a single renderer
-      # across slug changes produced inverted-order / collapsed-field
-      # layouts on iOS even though the same screen authoring rendered
-      # correctly with a fresh renderer. The exact root cause appears
-      # to be UIHostingController state inside SwiftKit facades; a new
-      # renderer instance defensively rebuilds every facade chain.
-      renderer = UI::UIKit::Renderer.new
-      # Phase 6.11 Item 1 — brand override removed. Renderer carries
-      # `UI::DesignTokens::Tokens.default` already; no per-host override.
+      dispatcher = @@dispatcher.not_nil!
 
       route = Voyager.route_for_slug(slug)
-      # Phase 6.10 Rem 4 (Item 1) — coord/slug sync invariant.
+
+      # Phase 6.10 Rem 4 (Item 1) + Phase 8D.2 Item 3 — coord/slug
+      # initial-resync through the host-driven path.
       #
       # When Swift launches with VOYAGER_ROOT_SLUG=voyager-todos, the
       # Crystal coord is still at its constructor default (:sign_in).
       # Without resync, the user's Save → coord.pop returns to
-      # :sign_in instead of :todos, and the new todo never gets
-      # visible because we land on the wrong screen.
+      # :sign_in instead of :todos.
       #
       # The previous logic only synced "if no Swift callback yet" —
-      # but the callback gets registered BEFORE the first render
-      # (VoyagerBridge.initialize() calls both routines), so the
-      # branch never fired and the coord stayed misaligned.
+      # but the callback gets registered BEFORE the first render, so
+      # the branch never fired and the coord stayed misaligned.
+      #
+      # New rule (8D.2): if the coord is at depth=1 (just the
+      # constructor root) AND the requested slug doesn't match, treat
+      # this call as a first-time sync from the Swift launch arg.
       #
-      # New rule: if the coord is at depth=1 (just the constructor
-      # root) AND the requested slug doesn't match, treat this call as
-      # a first-time sync from the Swift launch arg — replace the
-      # root. Guard with `@@suppress_route_changed` so the resulting
-      # notify doesn't fire the Swift callback (which would loop us
-      # back into render_slug for the same slug we just synced).
+      # Mount-before-publish: replace_root synchronously notifies
+      # on_change subscribers, so we MUST mount_screen first so
+      # FormState.current is the new mount's before any subscriber
+      # fires. Guard with `@@suppress_route_changed` (begin/ensure) so
+      # the resulting notify doesn't fire the Swift callback (which
+      # would loop us back into render_slug for the same slug).
       if coord.current.id != route.id && coord.depth == 1
         @@suppress_route_changed = true
-        coord.replace_root(route)
-        @@suppress_route_changed = false
+        begin
+          dispatcher.mount_screen(route)
+          coord.replace_root(route)
+        ensure
+          @@suppress_route_changed = false
+        end
+      end
+
+      # AX labels reflect coord.current — authoritative after resync.
+      # If Swift's requested slug disagreed with coord.current and no
+      # resync fired (e.g. mid-app slug requests after navigation has
+      # begun), the rendered screen and AX identity stay consistent.
+      current_slug = Voyager.slug_for_route_id(coord.current.id)
+      reg = VoyagerApp.registration_for(coord.current.id)
+      screen_class = reg.screen_class
+
+      # Phase 6.10 Rem 1 — fresh renderer per render call to match
+      # Cascade's proven-working pattern. Reusing a single renderer
+      # across slug changes produced inverted-order / collapsed-field
+      # layouts on iOS even though the same screen authoring rendered
+      # correctly with a fresh renderer. The exact root cause appears
+      # to be UIHostingController state inside SwiftKit facades; a new
+      # renderer instance defensively rebuilds every facade chain.
+      #
+      # Phase 8D.2 — constructed BEFORE screen.build because the
+      # renderer's initializer installs the
+      # `UI::DesignTokens::Device.install_provider` block that screens
+      # query via `UI::DesignTokens::DeviceMetrics.current` during
+      # their build phase (e.g. SignInScreen reads DeviceMetrics for
+      # responsive layout). Constructing the renderer AFTER build
+      # SIGSEGVs at PC=0 because no provider is installed when build
+      # runs (verified via VoyagerDemo-2026-05-25-080058.ips: faulting
+      # frame is `UI::DesignTokens::DeviceMetrics::current` inside
+      # `Voyager::SignInScreen#build` inside `VoyagerBridge#render_slug`).
+      # The macOS host avoids this by constructing the renderer ONCE
+      # at startup; iOS uses a fresh renderer per call but must still
+      # honor the install-before-query ordering.
+      renderer = UI::UIKit::Renderer.new
+
+      # Defensive guard — not robust unknown-slug handling
+      # (route_for_slug already maps unknown slugs to :sign_in).
+      # Catches future registration shapes where screen_class could be
+      # nil (e.g. a web-only screen registered via the screen macro
+      # without a controller_class — see Phase 8C web-only-screen
+      # support in src/asset_pipeline/native_app.cr).
+      if screen_class.nil?
+        placeholder = UI::Label.new("Unknown screen for route: #{coord.current.id}")
+        placeholder.accessibility_label = "Unknown route"
+        placeholder.test_id = "voyager-root-unknown"
+        native = renderer.render(placeholder.as(UI::View))
+        @@last_native = native
+        return native
       end
 
-      view = Voyager.build_route(state, coord, route)
-      view.accessibility_label = "voyager-root-#{slug}" if view.accessibility_label.to_s.empty?
-      view.test_id = "voyager-root-#{slug}" if view.test_id.to_s.empty?
+      # Build a fresh ScreenContext::Native from the dispatcher's live
+      # FormState / session / flash / design_tokens / navigation. This
+      # is the proven Phase 8B spike pattern + 8D.1 macOS host pattern
+      # (samples/initiative-cross-platform-ui-voyager/macos/host.cr#rebuild_for).
+      # action_params is empty at render time — it only carries values
+      # during in-flight dispatches (e.g. swipe-row Edit's
+      # {"todo_id" => "3"}).
+      ctx = UI::ScreenContext::Native.new(
+        form_state: dispatcher.current_form_state,
+        session: dispatcher.session,
+        flash: dispatcher.flash,
+        design_tokens: dispatcher.design_tokens,
+        navigation: dispatcher.navigation,
+        action_params: {} of String => String,
+      )
+      view = screen_class.new.build(ctx)
+      view.accessibility_label = "voyager-root-#{current_slug}" if view.accessibility_label.to_s.empty?
+      view.test_id = "voyager-root-#{current_slug}" if view.test_id.to_s.empty?
+
       native = renderer.render(view)
       @@last_native = native
       native

exec
/bin/zsh -lc "rg -n \"class ActionDispatcher|def mount_screen|def translate_result|replace_root|on_change|class NavigationCoordinator|module NavigationCoordinator\" src samples spec docs/initiative-cross-platform-ui -g '*.cr'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
samples/phase-08b-native-spike/src/spike_app.cr:6:#   - The TextField's renderer-wired on_change calls FormState.update("email", ...)
samples/phase-08b-native-spike/src/spike_app.cr:12:#   - macOS host's on_change subscriber rebuilds the view tree for the new
samples/phase-08b-native-spike/src/spike_app.cr:254:        # the :todos screen + push the route + notify our on_change
samples/phase-08b-native-spike/src/spike_app.cr:257:          coord.on_change do |route|
samples/phase-08b-native-spike/src/spike_app.cr:287:      # Subscribe to coord.on_change AFTER the initial render — the
samples/phase-08b-native-spike/src/spike_app.cr:290:      coord.on_change do |route|
src/asset_pipeline.cr:64:    @clear_cache_upon_change : Bool
src/asset_pipeline.cr:68:    def initialize(@js_source_path : Path = Path.new("src/app/javascript"), @js_output_path : Path = Path.new("public/assets/"), @import_maps : Array(ImportMap) = [] of ImportMap, @clear_cache_upon_change : Bool = true)
src/asset_pipeline.cr:74:    def initialize(@js_source_path : Path = Path.new("src/app/javascript"), @js_output_path : Path = Path.new("public/assets/"), import_map : ImportMap = ImportMap.new, @clear_cache_upon_change : Bool = true)
src/asset_pipeline.cr:84:    # Set `clear_cache_upon_change` to `false` to disable automatic clearing of the output path before generating new cached files.
src/asset_pipeline.cr:86:    def initialize(@js_source_path : Path = Path.new("src/app/javascript/"), @js_output_path : Path = Path.new("public/assets"), @clear_cache_upon_change : Bool = true, &block)
src/asset_pipeline.cr:370:    # Clears the cache if the clear_cache_upon_change option is enabled.
src/asset_pipeline.cr:374:      if @clear_cache_upon_change && !@cache_cleared
samples/initiative-cross-platform-ui-voyager/controllers/todo_editor_controller.cr:8:  # context.form_state["completed"] (Toggle on_change writes here).
samples/initiative-cross-platform-ui-voyager/screens/settings.cr:44:      hide_toggle.on_change = ->(_value : Bool) { Voyager.dispatch(:toggle_filter) }
samples/initiative-cross-platform-ui-voyager/screens/sign_in.cr:69:      email.on_change = ->(value : String) { state.current_user = value }
samples/cross_platform/android_host/android_material_bridge.cr:538:      picker.on_change = Proc(UI::Color, Nil).new do |color|
samples/initiative-cross-platform-ui-voyager/screens/state.cr:18:  # effect AFTER the coordinator's on_change fires, so the visible
samples/initiative-cross-platform-ui-voyager/screens/todos.cr:141:      check.on_change = ->(_value : Bool) {
samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr:36:      # type. Toggle's on_change writes its own value into FormState via
samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr:88:      completed_toggle.on_change = ->(value : Bool) {
samples/initiative-cross-platform-ui-demo/screens/settings.cr:58:      s.on_change = ->(v : Float64) { state.volume = v }
samples/initiative-cross-platform-ui-demo/screens/dashboard.cr:21:      tv.on_change = ->(idx : Int32) { state.selected_tab = idx }
samples/initiative-cross-platform-ui-demo/screens/sign_in.cr:64:      email_field.on_change = ->(value : String) { state.email = value }
samples/initiative-cross-platform-ui-demo/screens/sign_in.cr:72:      password_field.on_change = ->(value : String) { state.password = value }
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:28:#         invokes inside coord.on_change with the new slug. This is the
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:75:    # this guard, replace_root → notify → Swift cb → render_slug →
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:155:      # on_change. The subscriber here is RENDERER-NEUTRAL — it copies
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:161:      # before publishing on_change (mount-before-publish invariant,
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:165:      coord.on_change do |route|
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:240:      # Mount-before-publish: replace_root synchronously notifies
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:241:      # on_change subscribers, so we MUST mount_screen first so
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:250:          coord.replace_root(route)
samples/initiative-cross-platform-ui-voyager/web/static_site.cr:33:# Build all 4 routes from a fresh state. The coordinator's on_change
src/ui/views/text_field.cr:36:    property on_change : Proc(String, Nil)? = nil
src/ui/views/text_field.cr:46:      @on_change = block
src/ui/views/date_picker.cr:10:    property on_change : Proc(Time, Nil)? = nil
src/ui/views/date_picker.cr:16:      @on_change = block
src/ui/views/tab_view.cr:29:    property on_change : Proc(Int32, Nil)? = nil
src/ui/views/tab_view.cr:56:      @on_change = block
samples/cross_platform/macos_host/hig_showcase.cr:3821:      # BX3: Toggle on_change writes Bool into ToggleProbe.last_value AND
samples/cross_platform/macos_host/hig_showcase.cr:3842:      # BX4: Slider on_change writes Float64 into SliderProbe.last_value
samples/initiative-cross-platform-ui-voyager/macos/host.cr:4:# build, install as NSWindow contentView, subscribe to `coord.on_change`,
samples/initiative-cross-platform-ui-voyager/macos/host.cr:5:# swap contentView on every push / pop / replace_root.
samples/initiative-cross-platform-ui-voyager/macos/host.cr:16:#   5. Subscribes to `coord.on_change` with a renderer-only callback
samples/initiative-cross-platform-ui-voyager/macos/host.cr:201:      # invokes the coord op that fires this on_change. The subscriber
samples/initiative-cross-platform-ui-voyager/macos/host.cr:204:      coord.on_change do |route|
src/ui/views/slider.cr:11:    # without firing the `on_change` callback (Crystal-initiated mutation
src/ui/views/slider.cr:28:    property on_change : Proc(Float64, Nil)? = nil
src/ui/views/slider.cr:34:      @on_change = block
src/ui/views/radio_group.cr:7:    property on_change : Proc(Int32, Nil)? = nil
src/ui/views/radio_group.cr:13:      @on_change = block
src/ui/form_state.cr:5:# TextField / SecureField / Toggle's `on_change` to call
src/ui/form_state.cr:13:# the user navigates away (push / pop / replace_root), the dispatcher
src/ui/form_state.cr:22:# on_change from a prior screen's TextField from leaking values into
src/ui/form_state.cr:42:    # from view.text) and `update` (on_change from input).
src/ui/form_state.cr:65:    # a failed submit) is in the registry before any on_change fires.
src/ui/form_state.cr:74:    # on_change wiring: called by the renderer's callback when the
src/ui/form_state.cr:102:    # mount-token-scoped on_change callbacks.
src/ui/form_state.cr:150:  # author's on_change so it ALSO updates FormState with mount-token
src/ui/form_state.cr:153:    # Wrap a TextField's on_change. Returns:
src/ui/form_state.cr:155:    #     on_change (no wiring needed).
src/ui/form_state.cr:156:    #   - the original on_change if the view has no `name`.
src/ui/form_state.cr:158:    #     before invoking the original on_change.
src/ui/form_state.cr:161:      user_handler = view.on_change
src/ui/form_state.cr:173:          # — including the user's on_change. Per Codex finding #3 on
src/ui/form_state.cr:189:    # Wrap a SecureField's on_change. Same shape as `wrap_text_handler`
src/ui/form_state.cr:193:    # on_change is invoked with `""`. form_state.update therefore writes
src/ui/form_state.cr:200:      user_handler = view.on_change
src/ui/views/color_picker.cr:6:    property on_change : Proc(Color, Nil)? = nil
src/ui/views/text_editor.cr:12:    property on_change : Proc(String, Nil)? = nil
src/ui/views/text_editor.cr:18:      @on_change = block
src/ui/views/stepper.cr:11:    property on_change : Proc(Float64, Nil)? = nil
src/ui/views/stepper.cr:17:      @on_change = block
src/ui/state.cr:10:  #   counter.on_change { |old_val, new_val| puts "#{old_val} -> #{new_val}" }
src/ui/state.cr:30:    def on_change(&block : T, T -> Nil) : Nil
src/ui/views/toggle.cr:11:    # without firing the `on_change` callback (Crystal initiated the
src/ui/views/toggle.cr:27:    property on_change : Proc(Bool, Nil)? = nil
src/ui/views/toggle.cr:36:      @on_change = block
src/ui/views/secure_field.cr:14:    property on_change : Proc(String, Nil)? = nil
src/ui/views/secure_field.cr:20:      @on_change = block
src/ui/views/picker.cr:19:    property on_change : Proc(Int32, Nil)? = nil
src/ui/views/picker.cr:25:      @on_change = block
src/ui/native/callback_registry.cr:44:#   - the new Float64 for Slider#on_change, Stepper#on_change
src/ui/native/callback_registry.cr:45:#   - 1.0/0.0 for Toggle#on_change (Bool encoded as Float64)
src/ui/native/callback_registry.cr:345:    # Register a Float64-valued SwiftKit action (Slider#on_change,
src/ui/native/callback_registry.cr:346:    # Stepper#on_change, Toggle#on_change after Bool→Float64 coercion).
src/ui/views/time_picker.cr:9:    property on_change : Proc(Time, Nil)? = nil
src/ui/views/time_picker.cr:15:      @on_change = block
src/ui/views/combo_box.cr:33:    property on_change : Proc(String, Void)?
src/ui/views/combo_box.cr:43:      @on_change : Proc(String, Void)? = nil,
src/ui/views/search_field.cr:9:    property on_change : Proc(String, Nil)? = nil
src/ui/views/search_field.cr:17:      @on_change = block
src/ui/navigation_coordinator.cr:4:  # Owns the route stack + on_change callbacks that renderers subscribe to.
src/ui/navigation_coordinator.cr:5:  # push / pop / replace_root / pop_to_root mutate state AND fire callbacks
src/ui/navigation_coordinator.cr:13:  # re-render on coordinator change), renderers subscribe via #on_change
src/ui/navigation_coordinator.cr:20:  # `@on_change_callbacks` field is a normal instance variable initialised
src/ui/navigation_coordinator.cr:25:  #   coord.on_change { |route| renderer.rebuild_root(route) }
src/ui/navigation_coordinator.cr:30:  class NavigationCoordinator
src/ui/navigation_coordinator.cr:41:    @on_change_callbacks : Array(Proc(Route, Nil))
src/ui/navigation_coordinator.cr:45:      @on_change_callbacks = [] of Proc(Route, Nil)
src/ui/navigation_coordinator.cr:84:    def replace_root(route : Route) : Nil
src/ui/navigation_coordinator.cr:93:    def on_change(&block : Route ->) : Nil
src/ui/navigation_coordinator.cr:94:      @on_change_callbacks << block
src/ui/navigation_coordinator.cr:99:      @on_change_callbacks.size
src/ui/navigation_coordinator.cr:114:      @on_change_callbacks.each { |cb| cb.call(current_route) }
src/ui/views/checkbox.cr:7:    property on_change : Proc(Bool, Nil)? = nil
src/ui/views/checkbox.cr:13:      @on_change = block
src/ui/views/text_area.cr:12:    property on_change : Proc(String, Nil)? = nil
src/ui/views/text_area.cr:18:      @on_change = block
src/ui/probes/toggle_probe.cr:7:  # `on_change` updates `last_value`; the adjacent Label mirrors it.
src/ui/views/segmented_control.cr:7:    property on_change : Proc(Int32, Nil)? = nil
src/ui/views/segmented_control.cr:13:      @on_change = block
src/ui/probes/slider_probe.cr:7:  # `on_change` writes the latest Float64 into `last_value`; the
src/ui/renderers/appkit_renderer.cr:553:        # Phase 6.10 Rem 4 (Item 1) — string-typed on_change channel.
src/ui/renderers/appkit_renderer.cr:559:        # has a non-empty `name` property, wrap the user's on_change so
src/ui/renderers/appkit_renderer.cr:685:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:717:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:742:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:775:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:883:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:1010:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:1270:        # The legacy on_change for SecureField receives "" (the SwiftUI
src/ui/renderers/appkit_renderer.cr:1304:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:1330:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:1360:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:1386:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:1412:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:1438:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:2312:        if change_handler = view.on_change
src/ui/renderers/appkit_renderer.cr:3016:        if change_handler = view.on_change
spec/asset_pipeline_spec.cr:126:  it "clears old fingerprinted files when clear_cache_upon_change is true (default)" do
spec/asset_pipeline_spec.cr:134:      js_output_path: Path["spec/test_output"]  # clear_cache_upon_change defaults to true
spec/asset_pipeline_spec.cr:160:      js_output_path: Path["spec/test_output"]  # clear_cache_upon_change defaults to true
spec/asset_pipeline_spec.cr:197:  it "preserves old fingerprinted files when clear_cache_upon_change is false" do
spec/asset_pipeline_spec.cr:206:      clear_cache_upon_change: false  # Disable cache clearing
spec/asset_pipeline_spec.cr:233:      clear_cache_upon_change: false  # Disable cache clearing
src/ui/renderers/uikit_renderer.cr:496:        # Phase 6.10 Rem 4 (Item 1) — TextField on_change must receive
src/ui/renderers/uikit_renderer.cr:632:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:659:      # toggles its checked state on tap and calls the on_change handler.
src/ui/renderers/uikit_renderer.cr:671:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:704:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:751:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:851:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:1007:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:1337:        # The legacy on_change receives "" (the SwiftUI bridge doesn't
src/ui/renderers/uikit_renderer.cr:1365:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:1388:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:1415:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:1438:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:1461:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:1484:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:2431:        if change_handler = view.on_change
src/ui/renderers/uikit_renderer.cr:2991:        if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:187:    fun android_seekbar_set_on_change_listener(env : Void*, sb : Void*, callback_id : UInt64)
src/ui/renderers/android_renderer.cr:646:      # Wire up on_change via TextWatcher.
src/ui/renderers/android_renderer.cr:649:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:752:      # Wire up on_change via OnCheckedChangeListener. The Android listener
src/ui/renderers/android_renderer.cr:754:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:784:      # Wire up on_change via OnCheckedChangeListener (same pattern as Switch).
src/ui/renderers/android_renderer.cr:785:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:845:      # Wire up on_change via OnCheckedChangeListener on the RadioGroup. The
src/ui/renderers/android_renderer.cr:848:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:909:      # Wire up on_change via OnSeekBarChangeListener. The listener dispatches
src/ui/renderers/android_renderer.cr:912:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:937:        LibAndroidBridge.android_seekbar_set_on_change_listener(@env, sb, callback_id)
src/ui/renderers/android_renderer.cr:1109:        segmented = if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:1143:        radio_group = if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:1205:      if !view.options.empty? && (change_handler = view.on_change)
src/ui/renderers/android_renderer.cr:1335:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:1360:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:1385:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:1436:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:1496:      change_callback_id = if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:1686:      if change_handler = view.on_change
src/ui/renderers/android_renderer.cr:2742:      color_change_handler = view.on_change
src/asset_pipeline/action_dispatcher.cr:8:#   * the `UI::NavigationCoordinator` (route stack + on_change),
src/asset_pipeline/action_dispatcher.cr:48:  class ActionDispatcher
src/asset_pipeline/action_dispatcher.cr:93:    def mount_screen(route : UI::NavigationCoordinator::Route) : Nil
src/asset_pipeline/action_dispatcher.cr:110:    def mount_screen(route_id : Symbol) : Nil
src/asset_pipeline/action_dispatcher.cr:192:    private def translate_result(result : UI::ActionResult) : Nil
src/asset_pipeline/action_dispatcher.cr:194:      # `NavigationCoordinator#push/#pop/#replace_root/#republish` notify
src/asset_pipeline/action_dispatcher.cr:196:      # `on_change` subscriber rebuilds the view tree during notify
src/asset_pipeline/action_dispatcher.cr:203:      # `on_change` subscriber synchronously dispatches another action
src/asset_pipeline/action_dispatcher.cr:207:      # contract is: `on_change` subscribers are renderer-only +
src/asset_pipeline/action_dispatcher.cr:235:        @navigation.replace_root(next_route)
src/asset_pipeline/action_result.cr:5:# operation (push / pop / replace_root / republish) or an inline render
src/asset_pipeline/action_result.cr:10:# / replace_root / respond_with) build them on the controller's behalf.
src/asset_pipeline/native_controller.cr:103:    protected def replace_root(route_id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String) : UI::ActionResult
spec/ui/views_spec.cr:703:  describe "TextField on_change callback" do
spec/ui/views_spec.cr:704:    it "stores and calls on_change proc" do
spec/ui/views_spec.cr:707:      field.on_change.should_not be_nil
spec/ui/views_spec.cr:708:      field.on_change.try(&.call("hello"))
spec/ui/views_spec.cr:712:    it "allows setting on_change after construction" do
spec/ui/views_spec.cr:715:      field.on_change = ->(text : String) { values << text; nil }
spec/ui/views_spec.cr:716:      field.on_change.try(&.call("a"))
spec/ui/views_spec.cr:717:      field.on_change.try(&.call("ab"))
spec/ui/views_spec.cr:809:    toggle.on_change.should be_nil
spec/ui/views_spec.cr:821:    toggle.on_change.try(&.call(true))
spec/ui/views_spec.cr:838:    cb.on_change.should be_nil
spec/ui/views_spec.cr:850:    cb.on_change.try(&.call(true))
spec/ui/views_spec.cr:867:    rg.on_change.should be_nil
spec/ui/views_spec.cr:879:    rg.on_change.try(&.call(2))
spec/ui/views_spec.cr:899:    s.on_change.should be_nil
spec/ui/views_spec.cr:912:    s.on_change.try(&.call(0.5))
spec/ui/views_spec.cr:998:    tv.on_change.should be_nil
spec/ui/views_spec.cr:1016:    tv.on_change.try(&.call(1))
spec/ui/views_spec.cr:1134:    picker.on_change.should be_nil
spec/ui/views_spec.cr:1156:    picker.on_change.try(&.call(2))
spec/ui/views_spec.cr:1253:    sf.on_change.should be_nil
spec/ui/views_spec.cr:1264:    sf.on_change.should_not be_nil
spec/ui/views_spec.cr:1265:    sf.on_change.try(&.call("secret"))
spec/ui/views_spec.cr:1328:    sc.on_change.should be_nil
spec/ui/views_spec.cr:1345:    sc.on_change.try(&.call(1))
spec/ui/views_spec.cr:1364:    dp.on_change.should be_nil
spec/ui/views_spec.cr:1375:    dp.on_change.try(&.call(Time.utc))
spec/ui/views_spec.cr:1393:    tp.on_change.should be_nil
spec/ui/views_spec.cr:1404:    tp.on_change.try(&.call(Time.utc))
spec/ui/views_spec.cr:1423:    sf.on_change.should be_nil
spec/ui/views_spec.cr:1434:    sf.on_change.try(&.call("hello"))
spec/ui/views_spec.cr:1464:    ta.on_change.try(&.call("hello world"))
spec/ui/views_spec.cr:2091:    te.on_change.should be_nil
spec/ui/views_spec.cr:2112:    te.on_change.try(&.call("hello world"))
spec/ui/views_spec.cr:3099:    cp.on_change.should be_nil
spec/ui/views_spec.cr:3123:  it "fires on_change callback" do
spec/ui/views_spec.cr:3126:    cp.on_change = ->(c : UI::Color) { received = c; nil }
spec/ui/views_spec.cr:3128:    cp.on_change.not_nil!.call(new_color)
spec/asset_pipeline/action_dispatcher_spec.cr:5:private class ActionDispatcherSpecSignInScreen < UI::Screen
spec/asset_pipeline/action_dispatcher_spec.cr:11:private class ActionDispatcherSpecTodosScreen < UI::Screen
spec/asset_pipeline/action_dispatcher_spec.cr:17:private class ActionDispatcherSpecInlineScreen < UI::Screen
spec/asset_pipeline/action_dispatcher_spec.cr:23:private class ActionDispatcherSpecSignInController < UI::Controller
spec/asset_pipeline/action_dispatcher_spec.cr:56:    replace_root(:sign_in)
spec/asset_pipeline/action_dispatcher_spec.cr:64:private class ActionDispatcherSpecTodosController < UI::Controller
spec/asset_pipeline/action_dispatcher_spec.cr:89:private class ActionDispatcherSpecInlineController < UI::Controller
spec/asset_pipeline/action_dispatcher_spec.cr:95:private class ActionDispatcherSpecApp < UI::App
spec/asset_pipeline/action_dispatcher_spec.cr:198:      # Per Codex iter-4 finding #1: coord.push fires on_change
spec/asset_pipeline/action_dispatcher_spec.cr:208:      d.navigation.on_change do |route|
spec/asset_pipeline/action_dispatcher_spec.cr:215:      # The on_change callback fired exactly once (for the Navigate push).
spec/asset_pipeline/action_dispatcher_spec.cr:228:      d.navigation.on_change do |route|
spec/asset_pipeline/action_dispatcher_spec.cr:250:    it "Pop -> mount_screen + coord.pop (new mount visible to on_change)" do
spec/asset_pipeline/action_dispatcher_spec.cr:262:      d.navigation.on_change do |route|
spec/asset_pipeline/action_dispatcher_spec.cr:276:      # Renderer's on_change subscriber saw the NEW (popped-to) mount.
spec/asset_pipeline/action_dispatcher_spec.cr:289:    it "Rerender -> mount_screen + coord.republish (token bump visible to on_change)" do
spec/asset_pipeline/action_dispatcher_spec.cr:294:      d.navigation.on_change do |route|
spec/asset_pipeline/action_dispatcher_spec.cr:303:    it "ReplaceRoot -> mount_screen + coord.replace_root (new mount visible to on_change)" do
spec/asset_pipeline/action_dispatcher_spec.cr:310:      d.navigation.on_change do |route|
spec/asset_pipeline/native_controller_spec.cr:46:    replace_root(:root_screen)
spec/asset_pipeline/native_controller_spec.cr:105:  it "replace_root returns ActionResult::ReplaceRoot" do
spec/ui/navigation_coordinator_spec.cr:7:#   - push / pop / replace_root / pop_to_root mutate @routes, then notify.
spec/ui/navigation_coordinator_spec.cr:10:#   - replace_root resets the whole stack (depth always becomes 1).
spec/ui/navigation_coordinator_spec.cr:35:    it "fires on_change AFTER the route is appended" do
spec/ui/navigation_coordinator_spec.cr:38:      coord.on_change { |route| observed << route.id }
spec/ui/navigation_coordinator_spec.cr:60:    it "fires on_change AFTER mutating the stack" do
spec/ui/navigation_coordinator_spec.cr:64:      coord.on_change { |route| observed << route.id }
spec/ui/navigation_coordinator_spec.cr:69:    it "returns nil and does NOT fire on_change when at root" do
spec/ui/navigation_coordinator_spec.cr:72:      coord.on_change { |route| observed << route.id }
spec/ui/navigation_coordinator_spec.cr:90:    it "fires on_change exactly once when popping multiple levels" do
spec/ui/navigation_coordinator_spec.cr:95:      coord.on_change { |route| observed << route.id }
spec/ui/navigation_coordinator_spec.cr:103:      coord.on_change { |route| observed << route.id }
spec/ui/navigation_coordinator_spec.cr:109:  describe "#replace_root" do
spec/ui/navigation_coordinator_spec.cr:113:      coord.replace_root(UI::NavigationCoordinator::Route.new(:dashboard))
spec/ui/navigation_coordinator_spec.cr:118:    it "fires on_change with the new root" do
spec/ui/navigation_coordinator_spec.cr:121:      coord.on_change { |route| observed << route.id }
spec/ui/navigation_coordinator_spec.cr:122:      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
spec/ui/navigation_coordinator_spec.cr:127:  describe "#on_change" do
spec/ui/navigation_coordinator_spec.cr:131:      coord.on_change { |_| order << "A" }
spec/ui/navigation_coordinator_spec.cr:132:      coord.on_change { |_| order << "B" }
spec/ui/navigation_coordinator_spec.cr:141:      coord.on_change { |route| seen_during_push = route.id }
spec/ui/state_spec.cr:44:  describe "on_change listeners" do
spec/ui/state_spec.cr:50:      state.on_change do |old_val, new_val|
spec/ui/state_spec.cr:64:      state.on_change do |_old, _new|
spec/ui/state_spec.cr:76:      state.on_change do |old_val, new_val|
spec/ui/state_spec.cr:80:      state.on_change do |old_val, new_val|
spec/ui/state_spec.cr:94:      state.on_change do |old_val, new_val|
spec/ui/state_spec.cr:114:      state.on_change { |_old, _new| call_count += 1 }
spec/ui/state_spec.cr:115:      state.on_change { |_old, _new| call_count += 1 }
spec/ui/form_state_spec.cr:83:    it "returns nil when view has no name and no on_change" do
spec/ui/form_state_spec.cr:89:    it "returns the original on_change unchanged when view has no name" do
spec/ui/form_state_spec.cr:93:      tf.on_change = handler
spec/ui/form_state_spec.cr:120:      tf.on_change = ->(v : String) { observed << v; nil }
spec/ui/form_state_spec.cr:154:    it "stale wrapped handler ALSO suppresses the user's on_change (no side effects)" do
spec/ui/form_state_spec.cr:156:      # not just a no-op against FormState. If the user's on_change
spec/ui/form_state_spec.cr:166:      tf.on_change = ->(v : String) { observed << v; nil }
spec/ui/form_state_spec.cr:186:    it "wraps SecureField on_change with FormState update + mount-token guard" do
spec/ui/form_state_spec.cr:194:      sf.on_change = ->(v : String) { observed << v; nil }
spec/ui/form_state_spec.cr:210:      sf.on_change = ->(v : String) { observed << v; nil }
spec/ui/form_state_spec.cr:223:    it "returns nil when SecureField has no name and no on_change" do
spec/ui/voyager_state_propagation_spec.cr:49:    # toggle's on_change closure does the same thing).
spec/ui/voyager_state_propagation_spec.cr:55:    # in its coordinator.on_change handler.
spec/ui/voyager_state_propagation_spec.cr:97:  it "Coordinator on_change fires the rebuild callback on pop" do
spec/ui/voyager_state_propagation_spec.cr:101:    coord.on_change { |route| fires << route.id }
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr:9:#     translate_result → coord mutation (push/pop/replace_root) OR
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr:12:#     mount-before-notify so a renderer rebuilding under on_change
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr:43:    # Simulate TextField on_change wiring writing into the dispatcher's
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr:108:  # on_change observe the NEW FormState during their rebuild, not the
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr:109:  # prior screen's. Wire a renderer-style on_change that snapshots
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr:111:  it "translate_result mounts BEFORE publishing on_change (renderer sees new FormState)" do
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr:118:    d.navigation.on_change do |_route|

exec
/bin/zsh -lc "sed -n '1,280p' src/asset_pipeline/action_dispatcher.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "sed -n '1,160p' src/ui/navigation_coordinator.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
# Phase 8B — UI::ActionDispatcher.
#
# The dispatcher is the per-app coordinator that translates user
# actions (Button taps, form submits) into navigation operations or
# inline view renders. It owns:
#
#   * the registered `UI::App` subclass (for screen lookup),
#   * the `UI::NavigationCoordinator` (route stack + on_change),
#   * the `UI::Session` + `UI::Flash` (in-process or app-supplied),
#   * the `UI::DesignTokens::Tokens` (per-app brand),
#   * the CURRENT `UI::FormState` (replaced on every screen mount),
#   * a monotonic `current_mount_token : Int64` (per-mount fresh).
#
# Lifecycle:
#
#   * App startup creates ONE dispatcher and wires
#     `UI::FormState.current = @current_form_state` +
#     `UI::FormState.current_mount_token = 0` (via mount_screen).
#   * Each screen mount calls `dispatcher.mount_screen(route_id)`,
#     which increments the token and allocates a fresh FormState.
#     Renderer hook reads the new current FormState on its next
#     visit pass.
#   * Each Button tap with `action: :submit` invokes
#     `dispatcher.dispatch(action_ref, explicit_params)`. The
#     dispatcher resolves the action_ref to a controller method,
#     runs any before_actions, calls dispatch_action, and translates
#     the returned UI::ActionResult into a coordinator op.
#
# Action refs:
#
#   * `Symbol`: the action runs on the CURRENT screen's controller
#     (looked up via `app.registration_for(coord.current.id)`).
#   * `Tuple(UI::Controller.class, Symbol)`: the action runs on the
#     given controller (e.g. cross-screen action wiring).
#
# Inline render results (UI::ActionResult::RenderInline) emit through
# the dispatcher's `on_render_inline : Proc(UI::View, Nil)?` hook
# rather than the navigation coordinator. macOS/iOS hosts bind to
# this hook for sheet / popover presentation.

require "../ui"
require "./native_app"
require "./native_controller"
require "./native_context"
require "./action_result"

module UI
  class ActionDispatcher
    getter app : UI::App.class
    getter navigation : UI::NavigationCoordinator
    getter session : UI::Session
    getter flash : UI::Flash
    getter design_tokens : UI::DesignTokens::Tokens
    getter current_form_state : UI::FormState

    # Monotonically-increasing mount token. The dispatcher writes this
    # to `UI::FormState.current_mount_token` on every screen mount so
    # the renderer's stale-callback guard fires correctly.
    getter current_mount_token : Int64

    # Optional callback for `UI::ActionResult::RenderInline` results.
    # The host (macOS / iOS) wires this on startup to present the
    # inline view (e.g. sheet, popover) without disturbing the
    # navigation stack.
    property on_render_inline : Proc(UI::View, Nil)? = nil

    def initialize(
      @app : UI::App.class,
      @navigation : UI::NavigationCoordinator,
      @session : UI::Session,
      @flash : UI::Flash,
      @design_tokens : UI::DesignTokens::Tokens,
    )
      @current_mount_token = 0_i64
      @current_form_state = UI::FormState.new(mount_token: 0_i64)
      sync_renderer_hooks
    end

    # Called when a new screen mounts. Increments the mount token AND
    # creates a new FormState carrying that token. Renderer callbacks
    # captured under the prior token become no-ops (Codex finding #3).
    #
    # Initial form-state values are seeded from the route's params hash
    # (e.g. a `:detail` route's `:id => "42"` ends up as
    # form_state["id"] == "42") — convenient for screens that need to
    # know which row they're showing without the controller pre-pop'ing.
    #
    # The `route` argument is the route being mounted. The caller is
    # responsible for ensuring that this matches what the coordinator
    # will publish (the dispatcher's internal `translate_result` does
    # mount-then-notify to guarantee the renderer's wire-time read of
    # `UI::FormState.current` sees the NEW mount).
    def mount_screen(route : UI::NavigationCoordinator::Route) : Nil
      @current_mount_token += 1
      @current_form_state = UI::FormState.new(mount_token: @current_mount_token)

      # Seed from the route's params (string keys).
      route.params.each do |key, value|
        @current_form_state.register(key.to_s, value)
      end

      sync_renderer_hooks
      nil
    end

    # Convenience overload that resolves the route from the coordinator
    # (the route_id is asserted to match the coord's current route).
    # Useful for `mount_screen(route_id)` callers that have already
    # pushed the route onto the coord and want to mount based on it.
    def mount_screen(route_id : Symbol) : Nil
      current_route = @navigation.current
      if current_route.id != route_id
        raise "UI::ActionDispatcher#mount_screen(route_id): route_id " \
              "#{route_id.inspect} does not match coord.current.id " \
              "#{current_route.id.inspect}. Use mount_screen(route) overload " \
              "to mount before push, or pass the live current id."
      end
      mount_screen(current_route)
    end

    # Resolve + dispatch an action_ref. Builds a fresh Native context
    # with the dispatcher's current FormState + the explicit params
    # from the action_ref's button. Runs before_actions on the
    # resolved controller class; if any returns a UI::ActionResult,
    # the dispatch short-circuits. Otherwise calls dispatch_action
    # and translates the returned result via `translate_result`.
    def dispatch(
      action_ref : Symbol | Tuple(UI::Controller.class, Symbol),
      explicit_params : Hash(String, String) = {} of String => String,
    ) : Nil
      ctx = build_context(explicit_params)
      result = call_action(action_ref, ctx)
      translate_result(result)
      nil
    end

    # Build a fresh Native context for this dispatch. The dispatcher
    # owns the FormState reference; new context wraps it (along with
    # session, flash, etc.). The explicit_params arrive from the
    # Button's per-tap payload (action_params on the context).
    private def build_context(explicit_params : Hash(String, String)) : UI::ScreenContext::Native
      UI::ScreenContext::Native.new(
        form_state: @current_form_state,
        session: @session,
        flash: @flash,
        design_tokens: @design_tokens,
        navigation: @navigation,
        action_params: explicit_params,
      )
    end

    private def call_action(
      action_ref : Symbol | Tuple(UI::Controller.class, Symbol),
      ctx : UI::ScreenContext::Native,
    ) : UI::ActionResult
      case action_ref
      when Symbol
        # Current screen's controller, action_ref method.
        registration = @app.registration_for(@navigation.current.id)
        controller_class = registration.controller_class
        # Phase 8C: a registration whose controller_class is nil is a
        # web-only screen. Native dispatch into it is a programming
        # error — fail loud rather than NoMethodError on nil.new.
        if controller_class.nil?
          raise UI::App::WebOnlyScreenError.new(
            "UI::ActionDispatcher cannot dispatch native action " \
            "#{action_ref.inspect} on route_id #{@navigation.current.id.inspect}: " \
            "the registration has no native controller_class (web-only screen). " \
            "web_controller_name=#{registration.web_controller_name.inspect} " \
            "web_path=#{registration.web_path.inspect}"
          )
        end
        controller = controller_class.new
        run_before_actions(controller, ctx) || controller.dispatch_action(action_ref, ctx)
      when Tuple(UI::Controller.class, Symbol)
        ctrl_class, action_method = action_ref
        controller = ctrl_class.new
        run_before_actions(controller, ctx) || controller.dispatch_action(action_method, ctx)
      else
        raise "UI::ActionDispatcher cannot resolve action_ref of type #{action_ref.class}"
      end
    end

    private def run_before_actions(controller : UI::Controller, ctx : UI::ScreenContext::Native) : UI::ActionResult?
      controller.class._before_actions.each do |cb|
        result = cb.call(controller, ctx)
        return result if result.is_a?(UI::ActionResult)
      end
      nil
    end

    private def translate_result(result : UI::ActionResult) : Nil
      # IMPORTANT ordering invariant (per Codex iter 4 finding #1):
      # `NavigationCoordinator#push/#pop/#replace_root/#republish` notify
      # subscribers SYNCHRONOUSLY inside the call. The renderer's
      # `on_change` subscriber rebuilds the view tree during notify
      # — and its wire-time read of `UI::FormState.current` MUST see the
      # NEW mount's FormState, not the prior mount's. So we mount FIRST
      # (which bumps token + swaps `UI::FormState.current`) and THEN
      # invoke the coord mutation that fires the renderer.
      #
      # Reentrancy caveat (per Codex iter 4 rev 2 note): if an
      # `on_change` subscriber synchronously dispatches another action
      # (e.g. analytics that calls `coord.push` from inside its
      # callback), the resulting nested notify will see a DIFFERENT
      # FormState than this dispatch's subscribers. The supported
      # contract is: `on_change` subscribers are renderer-only +
      # non-reentrant. If an application needs reentrant subscribers,
      # it must use a queue or defer to a later run loop tick.
      case result
      when UI::ActionResult::Navigate
        next_route = UI::NavigationCoordinator::Route.new(result.route_id, result.params)
        mount_screen(next_route)
        @navigation.push(next_route)
      when UI::ActionResult::Pop
        # The route we are popping TO is the route below the top.
        # Compute it before calling pop. If we're already at root,
        # don't mount or pop — both no-op.
        if @navigation.depth > 1
          target_route = @navigation.routes[-2]
          mount_screen(target_route)
          @navigation.pop
        end
      when UI::ActionResult::Rerender
        # Re-mount the SAME route so any in-flight stale-fire callbacks
        # captured under the prior token become no-ops (defensive even
        # on rerender). Then republish so the host rebuilds the view
        # under the new mount.
        current_route = @navigation.current
        mount_screen(current_route)
        @navigation.republish
      when UI::ActionResult::ReplaceRoot
        next_route = UI::NavigationCoordinator::Route.new(result.route_id, result.params)
        mount_screen(next_route)
        @navigation.replace_root(next_route)
      when UI::ActionResult::RenderInline
        # Host-specific. Emit via on_render_inline if a callback is
        # bound; otherwise silently drop (the inline render result is
        # invalid without a host to receive it — log when we add a
        # debug-mode warning in a later phase).
        @on_render_inline.try(&.call(result.view))
      else
        # Unknown ActionResult subtype — should never happen with the
        # current sealed hierarchy, but Crystal's case-when isn't
        # exhaustive against an abstract class so we guard explicitly.
        raise "UI::ActionDispatcher cannot translate result of type #{result.class}"
      end
      nil
    end

    # Push the dispatcher's FormState reference + token into
    # `UI::FormState`'s renderer-hook surface. The renderer reads
    # those module-level slots inside `visit(UI::TextField)` /
    # `visit(UI::SecureField)`; this sync makes the wire-time capture
    # see the dispatcher's current per-mount state.
    private def sync_renderer_hooks : Nil
      UI::FormState.current = @current_form_state
      UI::FormState.current_mount_token = @current_mount_token
      nil
    end
  end
end

 succeeded in 0ms:
module UI
  # Reactive app-level navigation state.
  #
  # Owns the route stack + on_change callbacks that renderers subscribe to.
  # push / pop / replace_root / pop_to_root mutate state AND fire callbacks
  # synchronously AFTER the mutation, so any subscriber observes the new
  # current route. This is the runtime-navigation substrate Phase 6.10
  # ships — `UI::NavigationStack#push` mutates a `Array(View)` but did NOT
  # fire any callback; renderers therefore had no way to know they should
  # rebuild the visible root. `UI::NavigationCoordinator` closes that gap.
  #
  # Per Phase 6.10 brief decision #3 (architecture choice (a) full root
  # re-render on coordinator change), renderers subscribe via #on_change
  # and on each fire rebuild the platform's content view from the new
  # active route + the shared app state.
  #
  # Per the brief's I-9 invariant + the Crystal iOS class-init gap memory,
  # this class is INSTANCE-level: held by the demo app, not a class var
  # with an initializer that the iOS embedding silently skips. The
  # `@on_change_callbacks` field is a normal instance variable initialised
  # in `#initialize`, NOT a class-var declared with a default value.
  #
  # Example:
  #   coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
  #   coord.on_change { |route| renderer.rebuild_root(route) }
  #   coord.push(UI::NavigationCoordinator::Route.new(:todos))
  #   # subscriber fires; renderer sees route.id == :todos
  #   coord.pop
  #   # subscriber fires again; renderer sees route.id == :sign_in
  class NavigationCoordinator
    # A single navigation destination. `id` identifies the screen; the
    # demo app maps id -> view tree. `params` is an opaque per-route
    # string map for things like "which todo am I editing" (`{id: "42"}`).
    # Kept as String values so the map survives an iOS Swift trampoline
    # round-trip through a C ABI.
    record Route, id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String

    # The full stack, root-first. `routes.last` is the visible route.
    getter routes : Array(Route)

    @on_change_callbacks : Array(Proc(Route, Nil))

    def initialize(root : Route)
      @routes = [root] of Route
      @on_change_callbacks = [] of Proc(Route, Nil)
    end

    # The visible route (top of stack).
    def current : Route
      @routes.last
    end

    # Depth of the stack — `1` means only the root is visible.
    def depth : Int32
      @routes.size
    end

    # Push a new route onto the stack and notify subscribers.
    def push(route : Route) : Nil
      @routes << route
      notify
    end

    # Pop the visible route. Returns the popped route or nil if at root
    # (root cannot be popped — there must always be a visible route).
    def pop : Route?
      return nil if @routes.size <= 1
      popped = @routes.pop
      notify
      popped
    end

    # Pop down to root, clearing every pushed route. Fires exactly one
    # notification if anything was popped.
    def pop_to_root : Nil
      return if @routes.size <= 1
      @routes = [@routes.first]
      notify
    end

    # Replace the entire stack with a single new root. Use after sign-in,
    # sign-out, or any flow where the prior route stack is no longer
    # meaningful (e.g. session reset).
    def replace_root(route : Route) : Nil
      @routes = [route]
      notify
    end

    # Subscribe to coordinator changes. Block receives the new current
    # route. Multiple subscribers are supported (renderer + analytics +
    # logging can all listen). Subscribers are notified in registration
    # order.
    def on_change(&block : Route ->) : Nil
      @on_change_callbacks << block
    end

    # Returns the number of registered subscribers — exposed for specs.
    def subscriber_count : Int32
      @on_change_callbacks.size
    end

    # Phase 6.11 — re-publish the current route without mutating the
    # stack. Useful when the visible screen's underlying state changed
    # (e.g. the user toggled a Todo's completed flag in-row, or deleted
    # a row) and the host needs to rebuild the same route from the new
    # state. Equivalent semantics to push/pop of the same route, minus
    # the stack churn.
    def republish : Nil
      notify
    end

    private def notify : Nil
      current_route = current
      @on_change_callbacks.each { |cb| cb.call(current_route) }
    end
  end
end

exec
/bin/zsh -lc "sed -n '1,260p' samples/initiative-cross-platform-ui-voyager/app.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
# Phase 6.10 + Phase 8D.1 — Voyager demo app.
#
# A navigable Todos CRUD demo, refactored in Phase 8D.1 to use the
# unified Phase 8B UI::App + UI::Controller + UI::ActionDispatcher
# architecture. The screens are now `UI::Screen` subclasses with
# `build(ctx : UI::ScreenContext) : UI::View`; their callbacks dispatch
# action refs through `Voyager.dispatch(:action_name, action_params)`,
# which routes to the controller layer (one controller per route).
#
# Routes (4):
#   :sign_in       -> SignInScreen     / SignInController
#   :todos         -> TodosScreen      / TodosController
#   :todo_editor   -> TodoEditorScreen / TodoEditorController
#   :settings      -> SettingsScreen   / SettingsController
#
# Phase 8D.1 keeps `Voyager.build_route(state, coord, route)` alive as
# a temporary COMPATIBILITY SHIM so iOS bridge.cr + web/static_site.cr
# continue to compile + run unchanged. Phase 8D.2 will migrate iOS to
# the dispatcher and may drop the shim; Phase 8D.3 evaluates the web
# dependency. The shim constructs a minimal ScreenContext::Native (no
# dispatcher attached) so user-intent callbacks become no-ops in the
# shim path — that matches today's web (static HTML + JS) and iOS
# (Swift-driven re-render via voyager_render) flows, which do NOT
# expect Crystal callbacks to do navigation work.

require "../../src/ui"
require "../../src/asset_pipeline/native_app"
require "../../src/asset_pipeline/native_controller"
require "../../src/asset_pipeline/action_dispatcher"
require "../../src/asset_pipeline/action_result"
require "../../src/asset_pipeline/native_context"

require "./screens/state"

require "./screens/sign_in"
require "./screens/todos"
require "./screens/todo_editor"
require "./screens/settings"

require "./controllers/sign_in_controller"
require "./controllers/todos_controller"
require "./controllers/todo_editor_controller"
require "./controllers/settings_controller"

module Voyager
  SLUGS = ["voyager-sign-in", "voyager-todos", "voyager-todo-editor", "voyager-settings"]

  # Phase 8D.1 — host-set dispatcher.
  #
  # macOS host (and 8D.2 iOS host) constructs a `UI::ActionDispatcher`
  # and assigns it here so screen callback closures can route action
  # refs through `Voyager.dispatch(:submit)` /
  # `Voyager.dispatch(:edit_row, {"todo_id" => "5"})` without each
  # screen capturing a dispatcher reference. The compat shim
  # (`Voyager.build_route`) leaves this nil — the static-site web path
  # and iOS render-on-demand path don't dispatch; user-intent callbacks
  # on those targets become no-ops (web uses JS for nav; iOS bridge is
  # migrated in Phase 8D.2).
  #
  # iOS class-init gap (see `project_crystal_ios_class_init_gap` memory):
  # deliberately a nilable default — no class-var initializer side
  # effects.
  @@dispatcher : UI::ActionDispatcher? = nil

  def self.dispatcher : UI::ActionDispatcher?
    @@dispatcher
  end

  def self.dispatcher=(d : UI::ActionDispatcher?) : UI::ActionDispatcher?
    @@dispatcher = d
  end

  # Convenience: dispatch a Symbol action_ref through the host's
  # ActionDispatcher. No-op when no dispatcher is set (static-site web +
  # current iOS bridge). Per the brief's action-ref convention, the
  # Symbol form runs the action on the CURRENTLY MOUNTED route's
  # registered controller; the optional action_params hash forwards to
  # ctx.action_params.
  def self.dispatch(name : Symbol, action_params : Hash(String, String) = {} of String => String) : Nil
    d = @@dispatcher
    return nil if d.nil?
    d.dispatch(name, action_params)
    nil
  end

  # Phase 8D.1 COMPATIBILITY SHIM.
  #
  # iOS bridge.cr + web/static_site.cr still call this. The shim
  # constructs a minimal ScreenContext::Native (no dispatcher
  # attached) so the screen's `build` method has the abstract
  # `ScreenContext` parameter shape it now expects, and renders the
  # screen via its registered class. Sets `Voyager.state` to the
  # passed-in state for the duration so screens reading
  # `Voyager.state` get the caller's instance.
  #
  # NOTE on brief signature: the brief shows
  # `UI::ScreenContext::Native.new(params:, action_params:, form_state:,
  # session:, flash:)` but the actual `ScreenContext::Native#initialize`
  # signature is `(form_state, session, flash, design_tokens,
  # navigation, action_params)` — no `params:` kwarg (params is
  # derived from `form_state.to_h`), and no `route_id` on FormState.
  # Documented in the Phase 8D.1 implementer report as a brief
  # inaccuracy (NOT a Phase 8B API gap).
  def self.build_route(state : State, coord : UI::NavigationCoordinator, route : UI::NavigationCoordinator::Route) : UI::View
    # Make the per-call state visible to screens that read
    # `Voyager.state`.
    Voyager.state = state

    reg = VoyagerApp.registration_for(route.id)
    screen_class = reg.screen_class
    if screen_class.nil?
      placeholder = UI::Label.new("Unknown screen for route: #{route.id}")
      placeholder.accessibility_label = "Unknown route"
      return placeholder.as(UI::View)
    end

    # Seed a fresh FormState with route.params (string keys) so the
    # editor screen's `ctx.params["todo_id"]` works when the shim is
    # exercising it (e.g. spec/ui/voyager_state_propagation_spec.cr's
    # editor flow).
    fs = UI::FormState.new(mount_token: 0_i64)
    route.params.each { |k, v| fs.register(k.to_s, v) }

    ctx = UI::ScreenContext::Native.new(
      form_state: fs,
      session: UI::Session::InProcess.new,
      flash: UI::Flash::InProcess.new,
      design_tokens: UI::DesignTokens::Tokens.default,
      navigation: coord,
      action_params: {} of String => String,
    )
    screen_class.new.build(ctx)
  end

  # Map a static slug ("voyager-todos") to a Route. Used by the web
  # static-site generator (which renders one fragment per known slug
  # at build time) and by the iOS/macOS hosts when they need to
  # pre-build a route by name.
  def self.route_for_slug(slug : String) : UI::NavigationCoordinator::Route
    case slug
    when "voyager-sign-in"     then UI::NavigationCoordinator::Route.new(:sign_in)
    when "voyager-todos"       then UI::NavigationCoordinator::Route.new(:todos)
    when "voyager-todo-editor" then UI::NavigationCoordinator::Route.new(:todo_editor)
    when "voyager-settings"    then UI::NavigationCoordinator::Route.new(:settings)
    else                            UI::NavigationCoordinator::Route.new(:sign_in)
    end
  end

  # Slug for a Route.id (inverse of route_for_slug). Used by the
  # web renderer's UIRouteHost push glue.
  def self.slug_for_route_id(route_id : Symbol) : String
    case route_id
    when :sign_in     then "voyager-sign-in"
    when :todos       then "voyager-todos"
    when :todo_editor then "voyager-todo-editor"
    when :settings    then "voyager-settings"
    else                   "voyager-sign-in"
    end
  end
end

# Phase 8D.1 — UI::App declaration. Routes are registered via the
# `screen` macro; bootstrap! re-runs the registrations defensively (iOS
# class-init gap recovery hatch — see src/asset_pipeline/native_app.cr).
class VoyagerApp < UI::App
  initial_route :sign_in
  screen :sign_in,     Voyager::SignInController
  screen :todos,       Voyager::TodosController
  screen :todo_editor, Voyager::TodoEditorController
  screen :settings,    Voyager::SettingsController
end

exec
/bin/zsh -lc "rg -n \"def self.route_for_slug|def self.slug_for_route_id|screen.*voyager|route_for_slug|slug_for_route\" samples/initiative-cross-platform-ui-voyager -g '*.cr'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
samples/initiative-cross-platform-ui-voyager/app.cr:139:  def self.route_for_slug(slug : String) : UI::NavigationCoordinator::Route
samples/initiative-cross-platform-ui-voyager/app.cr:149:  # Slug for a Route.id (inverse of route_for_slug). Used by the
samples/initiative-cross-platform-ui-voyager/app.cr:151:  def self.slug_for_route_id(route_id : Symbol) : String
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:166:        slug = Voyager.slug_for_route_id(route.id)
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:181:      copy_slug_to_buf(Voyager.slug_for_route_id(coord.current.id))
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:222:      route = Voyager.route_for_slug(slug)
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:260:      current_slug = Voyager.slug_for_route_id(coord.current.id)
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:288:      # (route_for_slug already maps unknown slugs to :sign_in).
samples/initiative-cross-platform-ui-voyager/web/static_site.cr:27:  route = Voyager.route_for_slug(slug)
samples/initiative-cross-platform-ui-voyager/macos/host.cr:135:      coord = UI::NavigationCoordinator.new(Voyager.route_for_slug(ROOT_SLUG))

exec
/bin/zsh -lc "sed -n '1,220p' samples/initiative-cross-platform-ui-voyager/ios/VoyagerDemo/VoyagerBridge.swift" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 exited 1 in 0ms:
sed: samples/initiative-cross-platform-ui-voyager/ios/VoyagerDemo/VoyagerBridge.swift: No such file or directory

exec
/bin/zsh -lc "rg -n \"voyager_init|voyager_register_route_changed_callback|VoyagerBridge|voyager_render|VoyagerRoot|VOYAGER_ROOT_SLUG\" samples/initiative-cross-platform-ui-voyager/ios -g '*.swift' -g '*.h'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:24:        let slug = env["VOYAGER_ROOT_SLUG"] ?? "voyager-sign-in"
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:28:        app.launchArguments = ["-VoyagerRoot", slug]
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:30:            "VOYAGER_ROOT_SLUG": slug,
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:64:        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-sign-in"]
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:75:    /// Asserts that VOYAGER_ROOT_SLUG=voyager-todos cold-launches the
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:91:        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-todos"]
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:96:            "Cold-launch with VOYAGER_ROOT_SLUG=voyager-todos failed to render the Todos screen. " +
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:114:        app.launchArguments = ["-VoyagerRoot", "voyager-sign-in"]
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:245:        app.launchArguments = ["-VoyagerRoot", "voyager-todos"]
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:247:            "VOYAGER_ROOT_SLUG": "voyager-todos",
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:7:/// fires its route-changed callback (via VoyagerBridge.routeChanged
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:10:/// VoyagerHost(slug:) — that calls VoyagerBridge.render(slug:) for
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:83:        .onReceive(VoyagerBridge.routeChanged) { newSlug in
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:93:            // Make sure VoyagerBridge.initialize runs so the route-changed
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:96:            VoyagerBridge.initialize()
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:124:        guard let crystalRoot = VoyagerBridge.render(slug: slug) else {
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:210:        guard let crystalRoot = VoyagerBridge.render(slug: slug) else {
samples/initiative-cross-platform-ui-voyager/ios/Sources/Voyager-Bridging-Header.h:10:void voyager_init(void);
samples/initiative-cross-platform-ui-voyager/ios/Sources/Voyager-Bridging-Header.h:11:void* voyager_render(const char* slug);
samples/initiative-cross-platform-ui-voyager/ios/Sources/Voyager-Bridging-Header.h:13:void voyager_register_route_changed_callback(void (*cb)(const char*));
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerApp.swift:8:// VOYAGER_ROOT_SLUG / -VoyagerRoot launch arg (default "voyager-sign-in"),
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerApp.swift:11:// VoyagerBridge.
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerApp.swift:19:        if let i = args.firstIndex(of: "-VoyagerRoot"), i + 1 < args.count {
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerApp.swift:22:        return ProcessInfo.processInfo.environment["VOYAGER_ROOT_SLUG"] ?? "voyager-sign-in"
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:12:/// `VoyagerBridge.render(slug:)` again for the new route.
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:13:enum VoyagerBridge {
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:22:        voyager_init()
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:23:        voyager_register_route_changed_callback(VoyagerBridge.routeChangedThunk)
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:37:            VoyagerBridge.routeChanged.send(slug)
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:47:            guard let raw = voyager_render(ptr) else { return nil }

exec
/bin/zsh -lc "sed -n '1,220p' samples/initiative-cross-platform-ui-voyager/macos/host.cr" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
# Phase 6.10 + Phase 8D.1 — Voyager macOS host.
#
# Phase 6.10 shape: a NavigationCoordinator-driven AppKit app — initial
# build, install as NSWindow contentView, subscribe to `coord.on_change`,
# swap contentView on every push / pop / replace_root.
#
# Phase 8D.1 migration: user-intent callbacks now flow through
# `UI::ActionDispatcher`. The host:
#   1. Calls `VoyagerApp.bootstrap!` to register the 4 screens.
#   2. Creates a `UI::NavigationCoordinator` + `UI::AppKit::Renderer` +
#      session + flash + `UI::ActionDispatcher`.
#   3. Assigns `Voyager.dispatcher = dispatcher` so screen callback
#      closures route action refs through the dispatcher.
#   4. Calls `dispatcher.mount_screen(coord.current)` to seed the
#      mount-scoped FormState before the initial render.
#   5. Subscribes to `coord.on_change` with a renderer-only callback
#      that does NOT call mount_screen (per the brief's stack-policy
#      contract + spike pattern — the dispatcher's translate_result
#      already mounts before notify).
#
# Slug source: ENV["VOYAGER_ROOT_SLUG"] || ARGV[0] || "voyager-sign-in".
# Set VOYAGER_ROOT_SLUG=voyager-todos to skip the auth flow during
# manual verification.

require "../app"
require "../../../src/ui/renderers/appkit_renderer"

{% if flag?(:macos) %}
  ROOT_SLUG  = ENV["VOYAGER_ROOT_SLUG"]? || ARGV[0]? || "voyager-sign-in"
  APPEARANCE = ENV["VOYAGER_APPEARANCE"]? || ENV["HIG_APPEARANCE"]? || "light"

  # Window helper compiled into the binary at link time (see Makefile).
  lib LibWindowHelper
    fun hig_create_window(x : Float64, y : Float64, w : Float64, h : Float64, title : UInt8*) : Void*
    fun hig_create_window_with_min(
      x : Float64, y : Float64, w : Float64, h : Float64,
      min_w : Float64, min_h : Float64,
      title : UInt8*, appearance : UInt8*,
    ) : Void*
    fun hig_run_app(window : Void*) : Void
    fun objc_create_capture_window(width : Float64, height : Float64, appearance : UInt8*) : Void*
    fun objc_install_content_view(window : Void*, content_view : Void*) : Void
    fun objc_capture_view_offscreen(window : Void*, output_path : UInt8*, width : Float64, height : Float64) : Int32
    fun objc_capture_window_to_png(window : Void*, output_path : UInt8*) : Int32
    fun objc_close_capture_window(window : Void*) : Void
    fun objc_run_loop_for(seconds : Float64) : Void
  end

  lib LibObjCBridgeVoyager
    fun objc_send_void_id(obj : Void*, sel : Void*, arg : Void*) : Void
    fun sel_registerName(name : UInt8*) : Void*
  end

  module VoyagerHost
    WINDOW_WIDTH  = 880.0
    WINDOW_HEIGHT = 640.0
    MIN_WIDTH     = 480.0
    MIN_HEIGHT    = 400.0

    CAPTURE_WIDTH  = (ENV["VOYAGER_CAPTURE_WIDTH"]?.try(&.to_f?) || 720.0)
    CAPTURE_HEIGHT = (ENV["VOYAGER_CAPTURE_HEIGHT"]?.try(&.to_f?) || 640.0)

    # GC-pinned references so the AppKit run loop doesn't collect the
    # Crystal-side state, coordinator, renderer, dispatcher, or active
    # NativeView. NONE carry default initializers — explicit assignment
    # in `run!` so the iOS class-init gap pattern is symmetric across
    # hosts (macOS doesn't suffer the gap; we keep the discipline so the
    # iOS bridge can lift this pattern in Phase 8D.2 unchanged).
    @@coord : UI::NavigationCoordinator? = nil
    @@renderer : UI::AppKit::Renderer? = nil
    @@dispatcher : UI::ActionDispatcher? = nil
    @@window_ptr : Void* = Pointer(Void).null
    @@set_content_sel : Void* = Pointer(Void).null
    @@active_native : UI::NativeView? = nil
    # Tracks whether we're on the capture-window pair (objc_install_content_view)
    # or the regular NSWindow path (setContentView: via objc_send_void_id).
    # Set in `run!` once the window is created.
    @@is_capture_path : Bool = false

    def self.install_view(view : UI::View) : Nil
      renderer = @@renderer.not_nil!
      native = renderer.render(view)
      @@active_native = native
      if @@is_capture_path
        LibWindowHelper.objc_install_content_view(@@window_ptr, native.handle.ptr!)
      else
        LibObjCBridgeVoyager.objc_send_void_id(
          @@window_ptr, @@set_content_sel, native.handle.ptr!,
        )
      end
    end

    # Render the route the dispatcher just mounted (FormState already
    # swapped via translate_result's mount-before-notify ordering).
    def self.rebuild_for(route : UI::NavigationCoordinator::Route) : Nil
      dispatcher = @@dispatcher.not_nil!
      reg = VoyagerApp.registration_for(route.id)
      screen_class = reg.screen_class
      if screen_class.nil?
        placeholder = UI::Label.new("Unknown screen for route: #{route.id}")
        placeholder.accessibility_label = "Unknown route"
        install_view(placeholder.as(UI::View))
        return
      end

      # Build a fresh ScreenContext::Native from the dispatcher's live
      # FormState / session / flash / design_tokens / navigation. This
      # is the proven Phase 8B spike pattern
      # (samples/phase-08b-native-spike/src/spike_app.cr#rebuild_for).
      # action_params is empty at render time — it only carries values
      # during in-flight dispatches.
      ctx = UI::ScreenContext::Native.new(
        form_state: dispatcher.current_form_state,
        session: dispatcher.session,
        flash: dispatcher.flash,
        design_tokens: dispatcher.design_tokens,
        navigation: dispatcher.navigation,
        action_params: {} of String => String,
      )
      view = screen_class.new.build(ctx)
      install_view(view)
    end

    def self.run!
      # Phase 8D.1 — bootstrap registers all 4 screens. macOS doesn't
      # suffer the iOS class-init gap but we keep the call symmetric
      # with the spike + the iOS bridge (Phase 8D.2 will use the same
      # call).
      VoyagerApp.bootstrap!

      # Seed the singleton state so screens that read `Voyager.state`
      # see the same instance across all 4 routes.
      Voyager.state = Voyager::State.new

      coord = UI::NavigationCoordinator.new(Voyager.route_for_slug(ROOT_SLUG))
      renderer = UI::AppKit::Renderer.new
      session = UI::Session::InProcess.new
      flash = UI::Flash::InProcess.new

      dispatcher = UI::ActionDispatcher.new(
        app: VoyagerApp,
        navigation: coord,
        session: session,
        flash: flash,
        design_tokens: UI::DesignTokens::Tokens.default,
      )
      # Initial mount — bumps the dispatcher's mount_token + seeds
      # form_state from coord.current.params + swaps the renderer's
      # wire-time FormState. Must happen BEFORE the first render so
      # the TextField wire-time hook sees the new mount.
      dispatcher.mount_screen(coord.current)

      @@coord = coord
      @@renderer = renderer
      @@dispatcher = dispatcher

      # Phase 8D.1 — wire screens to dispatch through this host's
      # dispatcher.
      Voyager.dispatcher = dispatcher

      screenshot_path = ENV["VOYAGER_SCREENSHOT_PATH"]? || ENV["HIG_SCREENSHOT_PATH"]?
      if screenshot_path
        # Offscreen capture path — capture window is a Void** pair.
        window = LibWindowHelper.objc_create_capture_window(CAPTURE_WIDTH, CAPTURE_HEIGHT, APPEARANCE.to_unsafe)
        @@window_ptr = window
        @@is_capture_path = true

        rebuild_for(coord.current)
        LibWindowHelper.objc_run_loop_for(0.4)
        rc = LibWindowHelper.objc_capture_view_offscreen(
          window, screenshot_path.to_unsafe, CAPTURE_WIDTH, CAPTURE_HEIGHT,
        )
        LibWindowHelper.objc_close_capture_window(window)
        STDERR.puts "[voyager] screenshot rc=#{rc} -> #{screenshot_path}"
        exit(rc == 1 ? 0 : 1)
      end

      # Interactive path — titled NSWindow + setContentView:.
      title_str = "Voyager"
      appearance_arg = if ENV["VOYAGER_APPEARANCE"]? || ENV["HIG_APPEARANCE"]?
                         APPEARANCE.to_unsafe
                       else
                         Pointer(UInt8).null
                       end
      window = LibWindowHelper.hig_create_window_with_min(
        120.0, 120.0, WINDOW_WIDTH, WINDOW_HEIGHT,
        MIN_WIDTH, MIN_HEIGHT,
        title_str.to_unsafe, appearance_arg,
      )
      set_content = LibObjCBridgeVoyager.sel_registerName("setContentView:".to_unsafe)
      @@window_ptr = window
      @@set_content_sel = set_content
      @@is_capture_path = false

      # Initial render of the bootstrap route.
      rebuild_for(coord.current)

      # The reactive substrate: every dispatcher-routed Navigate / Pop /
      # ReplaceRoot fires `translate_result`, which calls mount_screen
      # FIRST (swapping FormState.current under the new token) and THEN
      # invokes the coord op that fires this on_change. The subscriber
      # here only RENDERS — no mount_screen call. Per brief Item 4 +
      # spike pattern.
      coord.on_change do |route|
        VoyagerHost.rebuild_for(route)
      end

      STDERR.puts "[voyager macos] launching with root slug=#{ROOT_SLUG} appearance=#{APPEARANCE}"
      LibWindowHelper.hig_run_app(window)
    end
  end

  VoyagerHost.run!
{% else %}
  STDERR.puts "samples/initiative-cross-platform-ui-voyager/macos/host.cr must be built with -Dmacos"
  exit 1
{% end %}

exec
/bin/zsh -lc 'git status --short' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
 M samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift
 M samples/initiative-cross-platform-ui-voyager/ios/bridge.cr
 M spec/test_js/some_js.js
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-06.10-rem-2-iter1/
?? docs/initiative-cross-platform-ui/handoff/phase-06.10-rem-2-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-06.11-evidence/legibility-audit.md
?? docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-3.md
?? docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md
?? docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-5.md
?? output/initiative-demo/demo-dashboard-dark.html
?? output/initiative-demo/demo-dashboard-light.html
?? output/initiative-demo/demo-detail-dark.html
?? output/initiative-demo/demo-detail-light.html
?? output/initiative-demo/demo-settings-dark.html
?? output/initiative-demo/demo-settings-light.html
?? output/initiative-demo/demo-sign-in-dark.html
?? output/initiative-demo/demo-sign-in-light.html
?? output/initiative-demo/demo-tier-three-dark.html
?? output/initiative-demo/demo-tier-three-light.html
?? output/initiative-demo/index.html
?? output/voyager-demo/

exec
/bin/zsh -lc "sed -n '1,90p' samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
import UIKit
import Combine

/// Swift wrapper around the Crystal C-ABI bridge functions exposed by
/// `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` and
/// packaged into libvoyager.a.
///
/// Adds a Combine PassthroughSubject<String, Never> that fires whenever
/// the Crystal-side NavigationCoordinator's `on_change` callback fires.
/// The ContentView subscribes via `.onReceive` and updates its
/// `@State var slug`, which triggers SwiftUI to call
/// `VoyagerBridge.render(slug:)` again for the new route.
enum VoyagerBridge {
    private static var didInit = false

    /// Fired by Crystal whenever coord.push/pop/replace_root runs.
    /// The payload is the new slug ("voyager-todos" etc).
    static let routeChanged = PassthroughSubject<String, Never>()

    static func initialize() {
        guard !didInit else { return }
        voyager_init()
        voyager_register_route_changed_callback(VoyagerBridge.routeChangedThunk)
        didInit = true
    }

    /// C-callable trampoline. Crystal hands us a NUL-terminated UTF-8
    /// string pointer to a stable Crystal-managed buffer. We copy into
    /// a Swift String IMMEDIATELY (the pointer is only valid until the
    /// next Crystal call) and republish via Combine.
    private static let routeChangedThunk: @convention(c) (UnsafePointer<CChar>?) -> Void = { ptr in
        guard let ptr = ptr else { return }
        let slug = String(cString: ptr)
        // Hop to the main queue — Combine subscribers in SwiftUI views
        // expect updates on the main run loop.
        DispatchQueue.main.async {
            VoyagerBridge.routeChanged.send(slug)
        }
    }

    /// Render the given route slug and return the produced UIView.
    /// Crystal returns a retained UIView*; ownership transfers here via
    /// takeRetainedValue().
    static func render(slug: String) -> UIView? {
        initialize()
        return slug.withCString { ptr in
            guard let raw = voyager_render(ptr) else { return nil }
            let view = Unmanaged<UIView>.fromOpaque(raw).takeRetainedValue()
            view.accessibilityIdentifier = "voyager-root-\(slug)"
            view.isAccessibilityElement = false
            return view
        }
    }

    /// Read the coordinator's current slug — useful for unit tests +
    /// initial-state probes. Returns "voyager-sign-in" as a safe
    /// fallback if Crystal hasn't initialized yet.
    static func currentSlug() -> String {
        initialize()
        guard let ptr = voyager_current_slug() else { return "voyager-sign-in" }
        return String(cString: ptr)
    }
}

codex
One thing to flag already: Swift still overwrites the returned root UIView’s accessibilityIdentifier from the requested slug, so a root-level XCUITest can mask Crystal’s coord-based `test_id`. That may be acceptable because production Swift is frozen, but it matters when interpreting the new assertion in `testRenderInitialSlug`. I’m checking whether there’s a code-level blocker beyond that.
exec
/bin/zsh -lc "nl -ba samples/initiative-cross-platform-ui-voyager/ios/bridge.cr | sed -n '52,330p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    52	    # effects (no `= Bytes.new(64)`, no `= [] of ...`). The iOS class-init
    53	    # gap (see `project_crystal_ios_class_init_gap` memory) silently
    54	    # SKIPS class-var initializers when _main is hidden for Swift @main,
    55	    # so any allocation that should happen at module load must happen
    56	    # inside `initialize_runtime` (which we call explicitly from
    57	    # voyager_init). Nilable defaults (`= nil`) are safe — the
    58	    # underlying field is just a tagged nil pointer.
    59	    @@initialized = false
    60	    @@state : Voyager::State? = nil
    61	    @@coord : UI::NavigationCoordinator? = nil
    62	    # Phase 8D.2 — new collaborators owned by the dispatcher substrate.
    63	    # `Voyager::HostBootstrap.build` constructs all four and we pin them
    64	    # here so the GC doesn't collect them between Swift round-trips.
    65	    # All declared as nilable with `= nil` defaults: iOS class-init gap
    66	    # discipline (no initializer side effects).
    67	    @@session : UI::Session::InProcess? = nil
    68	    @@flash : UI::Flash::InProcess? = nil
    69	    @@dispatcher : UI::ActionDispatcher? = nil
    70	    @@last_native : UI::NativeView? = nil
    71	    @@current_slug_buf : Bytes? = nil
    72	    @@swift_route_changed_cb : (LibC::Char* -> Void)? = nil
    73	    # Phase 6.10 Rem 4 — suppress the Swift route-changed callback
    74	    # during the initial coord/slug resync (see render_slug). Without
    75	    # this guard, replace_root → notify → Swift cb → render_slug →
    76	    # resync loop fires recursively.
    77	    @@suppress_route_changed = false
    78	
    79	    def self.initialize_runtime
    80	      return if @@initialized
    81	      GC.init
    82	
    83	      # Phase 6.10 Rem 3 — iOS class-init gap: bootstrap the Crystal
    84	      # runtime subsystems that `__crystal_main`'s `init_runtime`
    85	      # normally calls but the iOS embedding skips (because
    86	      # `_main` is unexported in `build_crystal_lib.sh`).
    87	      #
    88	      # Without these three calls, any `Crystal::once`-guarded constant
    89	      # (e.g. `String::CHAR_TO_DIGIT` used by `String#to_i?`) walks an
    90	      # uninitialised `Thread::LinkedList(Fiber)` and SIGSEGVs at
    91	      # `Thread::LinkedList(Fiber)#push` (KERN_INVALID_ADDRESS at 0x18).
    92	      # Symptom in Rem 2: launching with
    93	      # `VOYAGER_ROOT_SLUG=voyager-todo-editor` crashed silently inside
    94	      # `Voyager.build_route` because the editor's
    95	      # `(route.params[:id]? || "0").to_i?` triggered a const_read.
    96	      # Crash trace preserved at
    97	      # `~/Library/Logs/DiagnosticReports/VoyagerDemo-2026-05-23-155642.ips`.
    98	      #
    99	      # See `src/crystal/main.cr#init_runtime` for the upstream
   100	      # invariant; the comment there reads:
   101	      #   "`__crystal_once` directly or indirectly depends on `Fiber`
   102	      #   and `Thread` so we explicitly initialize their class vars,
   103	      #   then init crystal/once".
   104	      #
   105	      # This is the systematic fix the
   106	      # `project_crystal_ios_class_init_gap` memory item flagged as
   107	      # "Phase 5+ should address this systematically: either patch the
   108	      # iOS embedding to explicitly call the missing init functions ..."
   109	      Thread.init
   110	      Fiber.init
   111	      Crystal::Once.init
   112	
   113	      UI::Probes::DismissProbe.reset
   114	      UI::Probes::ToggleProbe.reset
   115	      UI::Probes::SliderProbe.reset
   116	      UI::Probes::TapProbe.reset
   117	      UI::Probes::FormRowProbe.reset
   118	      UI::Probes::RuntimeOverrideProbe.reset
   119	
   120	      # Allocate the slug buffer here (NOT as a class-var default) so the
   121	      # iOS class-init gap can't strand it as nil. 64 bytes accommodates
   122	      # the longest known Voyager slug (~"voyager-todo-editor" = 19) with
   123	      # huge headroom for future routes.
   124	      @@current_slug_buf = Bytes.new(64)
   125	
   126	      # Phase 8D.2 — call the canonical host-bootstrap helper. This
   127	      # internally:
   128	      #   * calls VoyagerApp.bootstrap! (registers all 4 screens —
   129	      #     mandatory before any dispatcher action lookup; the iOS
   130	      #     class-init gap means the compile-time class-var assignment
   131	      #     in src/asset_pipeline/native_app.cr is skipped, so this
   132	      #     re-runs the registrations defensively).
   133	      #   * constructs Voyager::State + NavigationCoordinator (root
   134	      #     :sign_in) + InProcess Session + InProcess Flash + a
   135	      #     UI::ActionDispatcher.
   136	      #   * calls dispatcher.mount_screen(coord.current) — bumps the
   137	      #     mount_token and seeds FormState BEFORE any render so the
   138	      #     wire-time TextField hook reads the new mount.
   139	      #   * assigns Voyager.state + Voyager.dispatcher so screen
   140	      #     callback closures dispatch through this host's dispatcher.
   141	      #
   142	      # We unpack the result into class-var pins so the GC won't
   143	      # collect them across Swift round-trips.
   144	      result = Voyager::HostBootstrap.build(:sign_in)
   145	      @@state = result.state
   146	      @@coord = result.coord
   147	      @@session = result.session
   148	      @@flash = result.flash
   149	      @@dispatcher = result.dispatcher
   150	
   151	      # The reactive substrate: when any dispatcher-routed Navigate /
   152	      # Pop / ReplaceRoot fires `translate_result`, the dispatcher
   153	      # calls mount_screen FIRST (swapping FormState.current under the
   154	      # new token) and THEN invokes the coord op that fires this
   155	      # on_change. The subscriber here is RENDERER-NEUTRAL — it copies
   156	      # the slug into the buffer and hops into Swift via the registered
   157	      # C callback. Swift then trips its @State binding, which re-runs
   158	      # voyager_render(new_slug) and SwiftUI swaps the hosted UIView.
   159	      #
   160	      # NO mount_screen call here: translate_result already mounted
   161	      # before publishing on_change (mount-before-publish invariant,
   162	      # Phase 8B Codex iter-4 finding #1 + 8D.1 macOS pattern).
   163	      # Re-mounting here would double-bump the token.
   164	      coord = @@coord.not_nil!
   165	      coord.on_change do |route|
   166	        slug = Voyager.slug_for_route_id(route.id)
   167	        copy_slug_to_buf(slug)
   168	        cb = @@swift_route_changed_cb
   169	        buf = @@current_slug_buf
   170	        if @@suppress_route_changed
   171	          # Initial resync — Swift callback intentionally suppressed.
   172	        elsif !cb.nil? && !buf.nil?
   173	          cb.call(buf.to_unsafe.as(LibC::Char*))
   174	        end
   175	      end
   176	
   177	      # Seed the slug buffer with the bootstrap route's slug BEFORE
   178	      # @@initialized = true (Codex BLOCKER 1 — voyager_current_slug()
   179	      # must return the correct initial value before any navigation
   180	      # event fires).
   181	      copy_slug_to_buf(Voyager.slug_for_route_id(coord.current.id))
   182	      @@initialized = true
   183	    end
   184	
   185	    private def self.copy_slug_to_buf(slug : String) : Nil
   186	      buf = @@current_slug_buf
   187	      return if buf.nil? # initialize_runtime always allocates this; guard for safety
   188	      bytes = slug.to_slice
   189	      n = Math.min(bytes.size, buf.size - 1)
   190	      n.times { |i| buf[i] = bytes[i] }
   191	      buf[n] = 0_u8
   192	    end
   193	
   194	    def self.current_slug_ptr : LibC::Char*
   195	      initialize_runtime
   196	      @@current_slug_buf.not_nil!.to_unsafe.as(LibC::Char*)
   197	    end
   198	
   199	    def self.register_route_changed(cb : LibC::Char* -> Void) : Nil
   200	      @@swift_route_changed_cb = cb
   201	    end
   202	
   203	    # Build + render the requested slug. The slug Swift passes is the
   204	    # source of truth for the INITIAL launch resync (Swift's
   205	    # VOYAGER_ROOT_SLUG arg drives the first cold render). After the
   206	    # resync, `coord.current` is the authoritative route and we render
   207	    # from it — so AX labels + test_ids reflect the actual mounted
   208	    # screen, not whatever slug Swift requested.
   209	    #
   210	    # Phase 8D.2 — Voyager.build_route is NO LONGER called from this
   211	    # path. The dispatcher (constructed in initialize_runtime via
   212	    # Voyager::HostBootstrap.build) owns FormState / session / flash /
   213	    # design_tokens / navigation. We build a ScreenContext::Native from
   214	    # the dispatcher's live state on every render so screen builds
   215	    # observe the same form-state + flash + session the controller
   216	    # layer just wrote.
   217	    def self.render_slug(slug : String) : UI::NativeView
   218	      initialize_runtime
   219	      coord = @@coord.not_nil!
   220	      dispatcher = @@dispatcher.not_nil!
   221	
   222	      route = Voyager.route_for_slug(slug)
   223	
   224	      # Phase 6.10 Rem 4 (Item 1) + Phase 8D.2 Item 3 — coord/slug
   225	      # initial-resync through the host-driven path.
   226	      #
   227	      # When Swift launches with VOYAGER_ROOT_SLUG=voyager-todos, the
   228	      # Crystal coord is still at its constructor default (:sign_in).
   229	      # Without resync, the user's Save → coord.pop returns to
   230	      # :sign_in instead of :todos.
   231	      #
   232	      # The previous logic only synced "if no Swift callback yet" —
   233	      # but the callback gets registered BEFORE the first render, so
   234	      # the branch never fired and the coord stayed misaligned.
   235	      #
   236	      # New rule (8D.2): if the coord is at depth=1 (just the
   237	      # constructor root) AND the requested slug doesn't match, treat
   238	      # this call as a first-time sync from the Swift launch arg.
   239	      #
   240	      # Mount-before-publish: replace_root synchronously notifies
   241	      # on_change subscribers, so we MUST mount_screen first so
   242	      # FormState.current is the new mount's before any subscriber
   243	      # fires. Guard with `@@suppress_route_changed` (begin/ensure) so
   244	      # the resulting notify doesn't fire the Swift callback (which
   245	      # would loop us back into render_slug for the same slug).
   246	      if coord.current.id != route.id && coord.depth == 1
   247	        @@suppress_route_changed = true
   248	        begin
   249	          dispatcher.mount_screen(route)
   250	          coord.replace_root(route)
   251	        ensure
   252	          @@suppress_route_changed = false
   253	        end
   254	      end
   255	
   256	      # AX labels reflect coord.current — authoritative after resync.
   257	      # If Swift's requested slug disagreed with coord.current and no
   258	      # resync fired (e.g. mid-app slug requests after navigation has
   259	      # begun), the rendered screen and AX identity stay consistent.
   260	      current_slug = Voyager.slug_for_route_id(coord.current.id)
   261	      reg = VoyagerApp.registration_for(coord.current.id)
   262	      screen_class = reg.screen_class
   263	
   264	      # Phase 6.10 Rem 1 — fresh renderer per render call to match
   265	      # Cascade's proven-working pattern. Reusing a single renderer
   266	      # across slug changes produced inverted-order / collapsed-field
   267	      # layouts on iOS even though the same screen authoring rendered
   268	      # correctly with a fresh renderer. The exact root cause appears
   269	      # to be UIHostingController state inside SwiftKit facades; a new
   270	      # renderer instance defensively rebuilds every facade chain.
   271	      #
   272	      # Phase 8D.2 — constructed BEFORE screen.build because the
   273	      # renderer's initializer installs the
   274	      # `UI::DesignTokens::Device.install_provider` block that screens
   275	      # query via `UI::DesignTokens::DeviceMetrics.current` during
   276	      # their build phase (e.g. SignInScreen reads DeviceMetrics for
   277	      # responsive layout). Constructing the renderer AFTER build
   278	      # SIGSEGVs at PC=0 because no provider is installed when build
   279	      # runs (verified via VoyagerDemo-2026-05-25-080058.ips: faulting
   280	      # frame is `UI::DesignTokens::DeviceMetrics::current` inside
   281	      # `Voyager::SignInScreen#build` inside `VoyagerBridge#render_slug`).
   282	      # The macOS host avoids this by constructing the renderer ONCE
   283	      # at startup; iOS uses a fresh renderer per call but must still
   284	      # honor the install-before-query ordering.
   285	      renderer = UI::UIKit::Renderer.new
   286	
   287	      # Defensive guard — not robust unknown-slug handling
   288	      # (route_for_slug already maps unknown slugs to :sign_in).
   289	      # Catches future registration shapes where screen_class could be
   290	      # nil (e.g. a web-only screen registered via the screen macro
   291	      # without a controller_class — see Phase 8C web-only-screen
   292	      # support in src/asset_pipeline/native_app.cr).
   293	      if screen_class.nil?
   294	        placeholder = UI::Label.new("Unknown screen for route: #{coord.current.id}")
   295	        placeholder.accessibility_label = "Unknown route"
   296	        placeholder.test_id = "voyager-root-unknown"
   297	        native = renderer.render(placeholder.as(UI::View))
   298	        @@last_native = native
   299	        return native
   300	      end
   301	
   302	      # Build a fresh ScreenContext::Native from the dispatcher's live
   303	      # FormState / session / flash / design_tokens / navigation. This
   304	      # is the proven Phase 8B spike pattern + 8D.1 macOS host pattern
   305	      # (samples/initiative-cross-platform-ui-voyager/macos/host.cr#rebuild_for).
   306	      # action_params is empty at render time — it only carries values
   307	      # during in-flight dispatches (e.g. swipe-row Edit's
   308	      # {"todo_id" => "3"}).
   309	      ctx = UI::ScreenContext::Native.new(
   310	        form_state: dispatcher.current_form_state,
   311	        session: dispatcher.session,
   312	        flash: dispatcher.flash,
   313	        design_tokens: dispatcher.design_tokens,
   314	        navigation: dispatcher.navigation,
   315	        action_params: {} of String => String,
   316	      )
   317	      view = screen_class.new.build(ctx)
   318	      view.accessibility_label = "voyager-root-#{current_slug}" if view.accessibility_label.to_s.empty?
   319	      view.test_id = "voyager-root-#{current_slug}" if view.test_id.to_s.empty?
   320	
   321	      native = renderer.render(view)
   322	      @@last_native = native
   323	      native
   324	    end
   325	  end
   326	
   327	  # ---------------------------------------------------------------------------
   328	  # C ABI exports
   329	  # ---------------------------------------------------------------------------
   330	

exec
/bin/zsh -lc 'git diff --check' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
exec
/bin/zsh -lc 'crystal spec spec/asset_pipeline/voyager_host_bootstrap_spec.cr' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc 'crystal spec spec/asset_pipeline/voyager_dispatcher_integration_spec.cr' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 1960ms:
.....

Finished in 2.15 milliseconds
5 examples, 0 failures, 0 errors, 0 pending

 succeeded in 2746ms:
.......

Finished in 2.44 milliseconds
7 examples, 0 failures, 0 errors, 0 pending

exec
/bin/zsh -lc "nl -ba samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift | sed -n '1,120p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	import XCTest
     2	
     3	/// VoyagerVisualTests — Phase 6.10 iOS visual capture harness.
     4	///
     5	/// Unlike Cascade (which captures one slug at a time), Voyager runs a
     6	/// navigable scenario: sign-in -> todos -> settings -> back -> todos.
     7	/// This test taps through the full state-propagation litmus and
     8	/// captures a screenshot at each step.
     9	///
    10	/// Pattern mirrors
    11	/// samples/initiative-cross-platform-ui-demo/ios/UITests/CascadeVisualTests.swift
    12	/// for the launch + screenshot pieces; the navigation taps + assertions
    13	/// are the new bits.
    14	final class VoyagerVisualTests: XCTestCase {
    15	
    16	    override func setUpWithError() throws {
    17	        continueAfterFailure = false
    18	    }
    19	
    20	    /// Snapshot one slug (used by the audit harness when capturing
    21	    /// individual screen baselines).
    22	    func testRenderInitialSlug() throws {
    23	        let env = ProcessInfo.processInfo.environment
    24	        let slug = env["VOYAGER_ROOT_SLUG"] ?? "voyager-sign-in"
    25	        let appearance = env["VOYAGER_APPEARANCE"] ?? env["HIG_APPEARANCE"] ?? "light"
    26	
    27	        let app = XCUIApplication()
    28	        app.launchArguments = ["-VoyagerRoot", slug]
    29	        app.launchEnvironment = [
    30	            "VOYAGER_ROOT_SLUG": slug,
    31	            "VOYAGER_APPEARANCE": appearance,
    32	        ]
    33	        app.launch()
    34	
    35	        let crystalRoot = app.otherElements["voyager-root-\(slug)"]
    36	        let hostRoot    = app.otherElements["voyager-root-host"]
    37	        let foundRoot   = crystalRoot.waitForExistence(timeout: 10)
    38	                       || hostRoot.waitForExistence(timeout: 2)
    39	        XCTAssertTrue(foundRoot,
    40	            "voyager-root-\(slug) not discoverable in AX tree within 10s. " +
    41	            "Likely cold-render failure for slug \(slug).")
    42	
    43	        Thread.sleep(forTimeInterval: 0.4)
    44	
    45	        let snapshot = XCUIScreen.main.screenshot()
    46	        let attachment = XCTAttachment(screenshot: snapshot)
    47	        attachment.name = "\(slug)-\(appearance)"
    48	        attachment.lifetime = .keepAlways
    49	        add(attachment)
    50	    }
    51	
    52	    /// Phase 8D.2 Item 8 — cold-launch dispatcher-wired smoke (Sign-in).
    53	    ///
    54	    /// Asserts that the iOS bridge's initialize_runtime →
    55	    /// Voyager::HostBootstrap.build → render_slug pipeline cold-launches
    56	    /// to a working Sign-in screen with the AX-discoverable "Sign in"
    57	    /// button present. If this fails, one of:
    58	    ///   - Crystal class-init crash (Thread/Fiber/Once gap regression).
    59	    ///   - HostBootstrap.build raised (dispatcher construction broken).
    60	    ///   - render_slug raised (ScreenContext::Native shape mismatch).
    61	    ///   - UIKit renderer produced an unhittable view tree.
    62	    func testColdLaunchSignInDispatcherWired() throws {
    63	        let app = XCUIApplication()
    64	        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-sign-in"]
    65	        app.launch()
    66	
    67	        let signIn = app.buttons["Sign in"]
    68	        XCTAssertTrue(signIn.waitForExistence(timeout: 10),
    69	            "Cold-launch failed to reach AX-discoverable Sign-in button. " +
    70	            "Possible class-init crash, dispatcher construction failure, or render failure.")
    71	    }
    72	
    73	    /// Phase 8D.2 Item 8 — cold-launch dispatcher-wired smoke (Todos).
    74	    ///
    75	    /// Asserts that VOYAGER_ROOT_SLUG=voyager-todos cold-launches the
    76	    /// Todos screen specifically (not just "some screen"). The
    77	    /// voyager-todos-add test_id is unique to the Add Todo button on
    78	    /// the Todos screen, so finding it proves:
    79	    ///   - initial-slug resync (dispatcher.mount_screen +
    80	    ///     coord.replace_root) ran.
    81	    ///   - ScreenContext::Native built from the dispatcher's live
    82	    ///     FormState / session / flash worked.
    83	    ///   - TodosScreen#build rendered without raising.
    84	    ///
    85	    /// Asserting on voyager-todos-add specifically (not a label-or-id
    86	    /// disjunction) keeps the smoke specific: this is the Todos
    87	    /// screen, not just "some screen that happens to have a Settings
    88	    /// button too."
    89	    func testColdLaunchTodosDispatcherWired() throws {
    90	        let app = XCUIApplication()
    91	        app.launchEnvironment = ["VOYAGER_ROOT_SLUG": "voyager-todos"]
    92	        app.launch()
    93	
    94	        let addButton = app.buttons["voyager-todos-add"]
    95	        XCTAssertTrue(addButton.waitForExistence(timeout: 10),
    96	            "Cold-launch with VOYAGER_ROOT_SLUG=voyager-todos failed to render the Todos screen. " +
    97	            "voyager-todos-add not AX-discoverable. Initial slug resync " +
    98	            "(dispatcher.mount_screen + coord.replace_root) likely broken.")
    99	    }
   100	
   101	    /// Full navigation flow — the manual verification the owner asked
   102	    /// for, automated as a smoke test. Launches at sign-in, asserts
   103	    /// AX traversal at each step, attempts each tap, captures a
   104	    /// screenshot at each step.
   105	    ///
   106	    /// Phase 6.10 Rem 2 caveat: even when AX traversal succeeds
   107	    /// (Item 2 PASS), the SwiftUI Button's action closure does NOT
   108	    /// fire under XCUITest tap synthesis on this hierarchy — the
   109	    /// touch-routing bug is documented separately. The AX
   110	    /// assertions still pass because they only require the elements
   111	    /// to be DISCOVERABLE in the tree, not interactive.
   112	    func testNavigationFlow() throws {
   113	        let app = XCUIApplication()
   114	        app.launchArguments = ["-VoyagerRoot", "voyager-sign-in"]
   115	        app.launch()
   116	
   117	        // ---- Step 1: sign-in screen ----
   118	        // We don't assert on the host's own accessibilityIdentifier
   119	        // ("voyager-root-host") — Rem 2 iter2 found that even with
   120	        // `.accessibilityElement(children: .contain)` on the SwiftUI

exec
/bin/zsh -lc "nl -ba samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift | sed -n '40,62p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    40	
    41	    /// Render the given route slug and return the produced UIView.
    42	    /// Crystal returns a retained UIView*; ownership transfers here via
    43	    /// takeRetainedValue().
    44	    static func render(slug: String) -> UIView? {
    45	        initialize()
    46	        return slug.withCString { ptr in
    47	            guard let raw = voyager_render(ptr) else { return nil }
    48	            let view = Unmanaged<UIView>.fromOpaque(raw).takeRetainedValue()
    49	            view.accessibilityIdentifier = "voyager-root-\(slug)"
    50	            view.isAccessibilityElement = false
    51	            return view
    52	        }
    53	    }
    54	
    55	    /// Read the coordinator's current slug — useful for unit tests +
    56	    /// initial-state probes. Returns "voyager-sign-in" as a safe
    57	    /// fallback if Crystal hasn't initialized yet.
    58	    static func currentSlug() -> String {
    59	        initialize()
    60	        guard let ptr = voyager_current_slug() else { return "voyager-sign-in" }
    61	        return String(cString: ptr)
    62	    }

exec
/bin/zsh -lc "nl -ba samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr | sed -n '1,110p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
exec
/bin/zsh -lc "nl -ba spec/asset_pipeline/voyager_host_bootstrap_spec.cr | sed -n '1,120p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	# Phase 8D.2 — flag-agnostic host bootstrap helper.
     2	#
     3	# Encapsulates the canonical dispatcher construction sequence so the
     4	# iOS bridge AND any future host can call ONE primitive instead of
     5	# duplicating the order. The macOS host predates this helper and may
     6	# be migrated to it in a follow-up cleanup; it is NOT in 8D.2 scope.
     7	#
     8	# Returns a `Bootstrap::Result` struct carrying all the constructed
     9	# collaborators. Caller is responsible for pinning them per its own
    10	# GC discipline (iOS class-vars; macOS local vars).
    11	#
    12	# Per Codex HIGH 4 + R11 elevation in brief-8d.2.md: extracting this
    13	# sequence makes the runtime invariants ("bootstrap before construct",
    14	# "mount_screen before any render", "assign Voyager.state and
    15	# Voyager.dispatcher exactly once") testable under default `crystal
    16	# spec` — no `-Dios` required because the helper does not depend on
    17	# the UIKit renderer.
    18	
    19	require "./app"
    20	
    21	module Voyager
    22	  module HostBootstrap
    23	    record Result,
    24	      state : Voyager::State,
    25	      coord : UI::NavigationCoordinator,
    26	      session : UI::Session::InProcess,
    27	      flash : UI::Flash::InProcess,
    28	      dispatcher : UI::ActionDispatcher
    29	
    30	    # Build the full host substrate. Calls `VoyagerApp.bootstrap!`,
    31	    # constructs state + coord + session + flash + dispatcher, calls
    32	    # `dispatcher.mount_screen` for the initial route, assigns
    33	    # `Voyager.state` and `Voyager.dispatcher`. Returns the constructed
    34	    # collaborators for host-level pinning.
    35	    def self.build(initial_route_id : Symbol = :sign_in) : Result
    36	      VoyagerApp.bootstrap!
    37	
    38	      state = Voyager::State.new
    39	      Voyager.state = state
    40	
    41	      coord = UI::NavigationCoordinator.new(
    42	        UI::NavigationCoordinator::Route.new(initial_route_id)
    43	      )
    44	      session = UI::Session::InProcess.new
    45	      flash = UI::Flash::InProcess.new
    46	      dispatcher = UI::ActionDispatcher.new(
    47	        app: VoyagerApp,
    48	        navigation: coord,
    49	        session: session,
    50	        flash: flash,
    51	        design_tokens: UI::DesignTokens::Tokens.default,
    52	      )
    53	      dispatcher.mount_screen(coord.current)
    54	      Voyager.dispatcher = dispatcher
    55	
    56	      Result.new(
    57	        state: state,
    58	        coord: coord,
    59	        session: session,
    60	        flash: flash,
    61	        dispatcher: dispatcher,
    62	      )
    63	    end
    64	  end
    65	end

 succeeded in 0ms:
     1	require "../spec_helper"
     2	require "../../samples/initiative-cross-platform-ui-voyager/host_bootstrap"
     3	
     4	# Phase 8D.2 Item 7 — Voyager::HostBootstrap.build spec.
     5	#
     6	# Validates the flag-agnostic host bootstrap helper that the iOS bridge
     7	# (and any future host) calls to construct the dispatcher substrate.
     8	# These specs are the testable proof-point for the entire runtime
     9	# sequence — without them, the iOS bridge's runtime assumptions are
    10	# unverified until the simulator runs.
    11	#
    12	# Per brief §3 Item 7 acceptance:
    13	#   - Returned `state` matches `Voyager.state`.
    14	#   - Returned `dispatcher` matches `Voyager.dispatcher`.
    15	#   - `dispatcher.current_form_state.mount_token != 0` (mount_screen ran).
    16	#   - `dispatcher.navigation.current.id == initial_route_id`.
    17	#   - `dispatcher.dispatch(:submit)` from `:sign_in` mount lands on
    18	#     `Voyager::SignInController` (proven by the controller's
    19	#     observable side effects).
    20	#
    21	# Per R6 (Voyager.dispatcher = nil teardown leak): each `it` block
    22	# resets `Voyager.dispatcher` and `Voyager.state` to a fresh baseline
    23	# so test ordering can't carry state forward.
    24	
    25	describe "Voyager::HostBootstrap.build" do
    26	  Spec.before_each do
    27	    Voyager.dispatcher = nil
    28	    Voyager.state = Voyager::State.new
    29	  end
    30	
    31	  it "returns a state that matches Voyager.state" do
    32	    result = Voyager::HostBootstrap.build(:sign_in)
    33	    result.state.should be(Voyager.state)
    34	  end
    35	
    36	  it "returns a dispatcher that matches Voyager.dispatcher" do
    37	    result = Voyager::HostBootstrap.build(:sign_in)
    38	    result.dispatcher.should be(Voyager.dispatcher.not_nil!)
    39	  end
    40	
    41	  it "bumps mount_token after mount_screen (token != 0)" do
    42	    result = Voyager::HostBootstrap.build(:sign_in)
    43	    result.dispatcher.current_form_state.mount_token.should_not eq 0_i64
    44	  end
    45	
    46	  it "navigation.current.id matches the initial_route_id (default :sign_in)" do
    47	    result = Voyager::HostBootstrap.build
    48	    result.dispatcher.navigation.current.id.should eq :sign_in
    49	  end
    50	
    51	  it "navigation.current.id matches the explicit initial_route_id (:todos)" do
    52	    result = Voyager::HostBootstrap.build(:todos)
    53	    result.dispatcher.navigation.current.id.should eq :todos
    54	  end
    55	
    56	  it "dispatcher.dispatch(:submit) from :sign_in invokes SignInController#submit" do
    57	    # SignInController#submit's observable side effects:
    58	    #   * On non-empty email + password: session["user_email"] = email,
    59	    #     ReplaceRoot(:todos) → stack becomes [todos], depth == 1.
    60	    #   * On empty inputs: flash["error"] set, Rerender (stack
    61	    #     unchanged).
    62	    # Both branches are SignInController-only behavior; observing them
    63	    # proves the dispatch landed on SignInController.
    64	    result = Voyager::HostBootstrap.build(:sign_in)
    65	    result.dispatcher.current_form_state.update("email", "seth@example.com")
    66	    result.dispatcher.current_form_state.update("password", "hunter2")
    67	
    68	    result.dispatcher.dispatch(:submit)
    69	
    70	    result.dispatcher.navigation.current.id.should eq :todos
    71	    result.dispatcher.navigation.depth.should eq 1
    72	    result.dispatcher.session["user_email"]?.should eq "seth@example.com"
    73	  end
    74	
    75	  it "dispatcher.dispatch(:submit) with empty inputs rerenders + sets flash error" do
    76	    # The Rerender branch is SignInController-specific behavior too —
    77	    # an empty-input dispatch confirms the controller (not some fallback
    78	    # path) handled the action.
    79	    result = Voyager::HostBootstrap.build(:sign_in)
    80	    initial_stack = result.dispatcher.navigation.routes.map(&.id)
    81	
    82	    result.dispatcher.dispatch(:submit)
    83	
    84	    result.dispatcher.navigation.routes.map(&.id).should eq initial_stack
    85	    result.dispatcher.flash["error"]?.should eq "Please provide both email and password."
    86	  end
    87	end

codex
APPROVE_WITH_NOTES.

No blocker found.

Findings/notes:

- Mount-before-publish is correct. [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:246) does `dispatcher.mount_screen(route)` before `coord.replace_root(route)` inside `begin/ensure`, and the suppress flag is restored correctly.
- AX/test id derivation in Crystal uses `coord.current` after resync. [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:260) computes `current_slug` from `coord.current.id`, then applies it at [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:318). One caveat: production Swift still overwrites the returned root UIView identifier from the requested slug at [VoyagerBridge.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:49), so root-level XCUITest assertions can mask Crystal’s coord-based id.
- Renderer-before-build is architecturally honest for this iteration. [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:285) installs the UIKit device provider before [screen build](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:317). This does expose a layering smell: screen build depends on renderer initialization side effects. Escalate as follow-up API cleanup, not an 8D.2 blocker.
- Class-var pin discipline is honored: new collaborators are nilable defaults at [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:67), assigned explicitly after `HostBootstrap.build` at [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:144).
- XCUITest smokes are good cold-launch/render/resync guards, especially the Todos-specific button at [VoyagerVisualTests.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:89). They do not prove tap-to-controller dispatch, but the Crystal bootstrap spec covers dispatcher assignment and controller routing.

Validation I ran:

- `crystal spec spec/asset_pipeline/voyager_host_bootstrap_spec.cr` passed: 7 examples.
- `crystal spec spec/asset_pipeline/voyager_dispatcher_integration_spec.cr` passed: 5 examples.
- `git diff --check` passed.
tokens used
67,067
APPROVE_WITH_NOTES.

No blocker found.

Findings/notes:

- Mount-before-publish is correct. [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:246) does `dispatcher.mount_screen(route)` before `coord.replace_root(route)` inside `begin/ensure`, and the suppress flag is restored correctly.
- AX/test id derivation in Crystal uses `coord.current` after resync. [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:260) computes `current_slug` from `coord.current.id`, then applies it at [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:318). One caveat: production Swift still overwrites the returned root UIView identifier from the requested slug at [VoyagerBridge.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift:49), so root-level XCUITest assertions can mask Crystal’s coord-based id.
- Renderer-before-build is architecturally honest for this iteration. [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:285) installs the UIKit device provider before [screen build](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:317). This does expose a layering smell: screen build depends on renderer initialization side effects. Escalate as follow-up API cleanup, not an 8D.2 blocker.
- Class-var pin discipline is honored: new collaborators are nilable defaults at [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:67), assigned explicitly after `HostBootstrap.build` at [bridge.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/bridge.cr:144).
- XCUITest smokes are good cold-launch/render/resync guards, especially the Todos-specific button at [VoyagerVisualTests.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:89). They do not prove tap-to-controller dispatch, but the Crystal bootstrap spec covers dispatcher assignment and controller routing.

Validation I ran:

- `crystal spec spec/asset_pipeline/voyager_host_bootstrap_spec.cr` passed: 7 examples.
- `crystal spec spec/asset_pipeline/voyager_dispatcher_integration_spec.cr` passed: 5 examples.
- `git diff --check` passed.
