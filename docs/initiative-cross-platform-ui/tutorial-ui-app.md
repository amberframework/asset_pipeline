# Tutorial — Building a UI::App

**Audience:** A new contributor (or a returning library user) who wants to wire a cross-platform app on top of `asset_pipeline`'s UI system and doesn't yet know how `UI::App`, `UI::Controller`, and `UI::ActionDispatcher` fit together.

**Companion skill:** `.claude/skills/ui-app/SKILL.md` (operational reference). This tutorial owns the narrative; the skill owns the lookup.

**Predecessors:** Phases 8A, 8B, 8C, 8D.1, 8D.2, 8D.3a, 8D.3b. The Voyager sample (`samples/initiative-cross-platform-ui-voyager/`) is the runnable, validated reference for every pattern here. Where this tutorial introduces a fresh minimal example to teach a concept, the realistic version follows immediately afterward by reference to Voyager.

---

## Chapter 1 — What This Tutorial Builds

You will end with a working mental model of the four-piece app architecture and the three deployment targets it supports. Concretely:

- `UI::App` declares routes once. The same declaration drives every target.
- **Three target paths**, all proven:
  - **macOS / iOS native** — `UI::ActionDispatcher` constructed in a host bootstrap, driven by callback closures from your screens. Voyager (`samples/initiative-cross-platform-ui-voyager/`) is the reference.
  - **Amber full-server web** — `UI::AmberIntegration.routes_for(YourApp)` inside Amber's `routes :web do ... end` block. The Phase 8 Amber spike (`samples/phase-08-amber-spike/`) is the reference.
  - **Voyager static-site web** — `Voyager.build_route` at build time, no live dispatcher. This is **permanent static-site infrastructure**, not a failed migration. See `docs/initiative-cross-platform-ui/architecture/web-target-position.md`.

By the end you should be able to: declare a `UI::App`, write a screen with action closures, write a controller that handles them and returns the right `UI::ActionResult`, bootstrap a native host, and wire the same app into Amber. You should also know exactly when the static-site path applies and why it is intentionally separate.

---

## Chapter 2 — Minimal App Declaration

Start fresh. A `UI::App` subclass declares an initial route and one `screen :route_id, Controller` line per route:

```crystal
class TasksApp < UI::App
  initial_route :sign_in
  screen :sign_in,    SignInController
  screen :tasks,      TasksController
  screen :task_editor, TaskEditorController
end
```

By convention, `FooController` → `FooScreen` (same namespace). To override, pass a `screen_class:` kwarg:

```crystal
screen :detail, DetailController, screen_class: CustomDetailScreen
```

The shipped Voyager declaration looks almost identical (`samples/initiative-cross-platform-ui-voyager/app.cr`):

```crystal
class VoyagerApp < UI::App
  initial_route :sign_in
  screen :sign_in,     Voyager::SignInController
  screen :todos,       Voyager::TodosController
  screen :todo_editor, Voyager::TodoEditorController
  screen :settings,    Voyager::SettingsController
end
```

That is the entire shape of an app declaration. No mixins, no DSL block. The `screen` macro registers a route_id → controller mapping that `UI::ActionDispatcher` looks up at dispatch time and `UI::AmberIntegration.routes_for` walks at compile time.

---

## Chapter 3 — Writing A Screen

A screen is a pure-render function. Subclass `UI::Screen` and return a `UI::View` tree from `build(context)`:

```crystal
class TasksScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    root = UI::VStack.new(spacing: 16.0)
    root.padding = UI::EdgeInsets.new(top: 24.0, trailing: 16.0, bottom: 24.0, leading: 16.0)
    root << UI::Label.new("Tasks").as(UI::View)

    add_btn = UI::Button.new("Add task", style: UI::ButtonStyle::Prominent)
    add_btn.accessibility_label = "Add task"
    add_btn.on_tap = -> { TasksApp.dispatch(:new_task) }

    root << add_btn.as(UI::View)
    root.as(UI::View)
  end
end
```

Two rules apply:

- **No domain mutations in `build`.** Build runs on every render. Mutating `state.todos` here would mutate on every redraw.
- **View-local affordance closures are allowed.** A `field.on_change` that flips `submit.disabled` is the right place for that logic (Rule 2 in the architectural rules). Don't route view-local flips through `Rerender`.

For a realistic screen with device-aware sizing, list rendering, swipe actions, and multiple action refs per row, see `samples/initiative-cross-platform-ui-voyager/screens/todos.cr` — `Voyager::TodosScreen#build` plus the `build_count_card` and `build_todo_row` helpers. The pattern is the same as the minimal example: build a tree, attach closures to interactive views, return the root.

---

## Chapter 4 — Writing A Controller

A controller owns the actions for one screen and returns a `UI::ActionResult` from each. Lifted near-verbatim from `samples/initiative-cross-platform-ui-voyager/controllers/sign_in_controller.cr`:

```crystal
module Voyager
  class SignInController < UI::Controller
    def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
      case name
      when :submit
        submit(context)
      else
        raise UI::Controller::UnknownActionError.new(
          "SignInController has no action :#{name}"
        )
      end
    end

    def submit(context : UI::ScreenContext::Native) : UI::ActionResult
      email = (context.form_state.values["email"]? || "").strip
      password = (context.form_state.values["password"]? || "").strip
      if email.empty? || password.empty?
        context.flash["error"] = "Please provide both email and password."
        UI::ActionResult::Rerender.new
      else
        context.session["user_email"] = email
        # CRITICAL: ReplaceRoot, not Navigate. Sign-in must not be in
        # the back stack.
        UI::ActionResult::ReplaceRoot.new(:todos)
      end
    end
  end
end
```

What's happening:

- **`context.form_state["email"]?`** — typed input from the current screen's `UI::TextField name: "email"`. Renderer-wired during the screen's most recent mount.
- **`context.flash["error"] = "..."`** — one-shot message; renderer reads it on the next build.
- **`context.session["user_email"] = email`** — persistent (per process) key/value store.
- **`UI::ActionResult::Rerender.new`** — re-mount the same route (fresh FormState, bumped token) and republish; the next build call sees the flash.
- **`UI::ActionResult::ReplaceRoot.new(:todos)`** — discard the navigation stack and start over with `:todos` as the new root. (For sign-in, `Navigate` would leave the sign-in screen in the back stack — wrong.)

Controllers also have constructor helpers — `navigate_to`, `pop_navigation`, `render_current_screen`, `replace_root`, `respond_with` — that build the right `UI::ActionResult` for you. See `src/asset_pipeline/native_controller.cr`. SignInController uses the explicit `UI::ActionResult::Rerender.new` and `UI::ActionResult::ReplaceRoot.new(:todos)` constructors; the helpers (`render_current_screen` / `replace_root(:todos)`) are equivalent.

**`before_action`:** for cross-cutting checks (auth, etc.). Register with `before_action :method_name`; the method receives the context and returns `UI::ActionResult?` (return `nil` to continue, return a result to short-circuit).

---

## Chapter 5 — Action References From Views

Screens fire actions through callback closures that call your app's dispatch helper. The shipped Voyager pattern:

```crystal
# Single action, current route's controller.
submit = UI::Button.new("Sign in", style: UI::ButtonStyle::Prominent)
submit.on_tap = -> { Voyager.dispatch(:submit) }

# Action with row-identity payload.
edit_btn.on_tap = -> {
  Voyager.dispatch(:edit_row, {"todo_id" => todo_id_str})
}

# Cross-controller dispatch (rare; explicit on purpose).
sign_out_btn.on_tap = -> {
  Voyager.dispatcher.try &.dispatch({SignInController, :sign_out})
}
```

The dispatcher accepts two action ref forms:

- **`Symbol`** — `:submit` runs on the CURRENT route's registered controller.
- **`Tuple(UI::Controller.class, Symbol)`** — `{SignInController, :sign_out}` runs on the explicitly named controller. Intentional cross-controller dispatch only — do not use this as a command bus.

**The kwarg form (`Button(action: :submit)` / `UI::Button.new("Save", action: :submit, params: {...})`) was never shipped.** An older Phase 8 design draft proposed it; the shipped API uses callback closures. Examples that show the kwarg form are stale and should be ignored. Use `button.on_tap = -> { App.dispatch(:submit) }`.

**Your app exposes its own helper.** Voyager defines `Voyager.dispatch` so screens don't capture a dispatcher reference (`samples/initiative-cross-platform-ui-voyager/app.cr`). A `TasksApp` would expose `TasksApp.dispatch`. There is no generic `UI::App.dispatch` — each app names its own.

---

## Chapter 6 — Action Results

Five subtypes, listed at `src/asset_pipeline/action_result.cr`:

| Result | What it does | Use for |
|--------|--------------|---------|
| `Navigate.new(:route_id, params)` | Push a new route onto the stack | "Open detail" / "Open editor" |
| `Pop.new` | Pop the top route (back nav) | "Cancel" / "Back" — no-op at root |
| `Rerender.new` | Re-mount the same route + republish | After a domain mutation that should propagate (e.g. toggle done) |
| `ReplaceRoot.new(:route_id, params)` | Replace the whole stack | After sign-in or sign-out |
| `RenderInline.new(view)` | Emit via the host's inline-render hook | Sheets / popovers without stack disturbance |

Constructor helpers on `UI::Controller` (preferred): `navigate_to`, `pop_navigation`, `render_current_screen`, `replace_root`, `respond_with`. Voyager's `SignInController` (Chapter 4) uses the explicit constructors for clarity; production controllers can use either.

**`Rerender` vs view-local closures.** `Rerender` rebuilds the whole screen and allocates a fresh `FormState`. Use it after a domain change (e.g. `state.toggle(todo_id)` in `Voyager::TodosController#toggle_row`). DO NOT use it to flip a single button's `disabled` state in response to typing — that's view-local affordance (Rule 2), handled by a closure on `TextField#on_change`.

---

## Chapter 7 — FormState And ScreenContext

`UI::FormState` (in `src/ui/form_state.cr`) holds the typed values of the current screen's controlled inputs. The dispatcher allocates a fresh one on every `mount_screen` and bumps its `mount_token` (monotonic). The renderer's `UI::TextField` / `UI::SecureField` visit reads `UI::FormState.current` at wire time so typed values flow into `context.form_state["field_name"]`.

`UI::ScreenContext` is abstract. Two concrete shapes:

- **`UI::ScreenContext::Native`** (`src/asset_pipeline/native_context.cr`) — carries `form_state`, `session`, `flash`, `design_tokens`, `navigation`, and `action_params`. Used on macOS and iOS.
- **`UI::ScreenContext::Web`** (`src/asset_pipeline/amber_integration.cr`) — carries `params`, `params_multi`, `flash_data`, `design_tokens`, `csrf_token`. Used inside Amber on the request thread.

Both implement the abstract surface (`params`, `params_multi`, `flash_data`, `design_tokens`, `csrf_token`). **Screens should depend only on the abstract surface** when they need to render on both targets — that's how the same `UI::Screen` subclass can drive native and web. The native concrete shape adds `form_state`, `session`, `flash`, `action_params`, and `navigation` for controllers that need them.

Why separate `form_state` and `action_params`? They have different semantics:

- `form_state["email"]` — typed value on the current screen mount (renderer-wired).
- `action_params["todo_id"]` — explicit per-tap payload from the button's closure (`Voyager.dispatch(:edit_row, {"todo_id" => "5"})`).

Controllers read whichever applies to the action. No silent merging.

---

## Chapter 8 — Native Host Wiring

The canonical native bootstrap is `Voyager::HostBootstrap.build` (`samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr`), lifted verbatim:

```crystal
module Voyager
  module HostBootstrap
    record Result,
      state : Voyager::State,
      coord : UI::NavigationCoordinator,
      session : UI::Session::InProcess,
      flash : UI::Flash::InProcess,
      dispatcher : UI::ActionDispatcher

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
```

The sequence is the contract:

1. `App.bootstrap!` — re-runs screen registrations (iOS class-init gap recovery).
2. Construct app/domain state.
3. Construct the `NavigationCoordinator` with the initial route.
4. Construct the `Session` and `Flash` (in-process by default; production may layer NSUserDefaults / Android prefs on top).
5. Construct the `UI::ActionDispatcher` binding it all together.
6. **`dispatcher.mount_screen(coord.current)`** — allocate the FIRST `FormState`, bump the mount token. MUST happen before any render.
7. **`Voyager.dispatcher = dispatcher`** — publish the dispatcher into the host's holder so screen closures can reach it.

Manual host wiring follows the SAME order. The bootstrap helper exists to make the contract testable under default `crystal spec` — the order is the invariant; the helper enforces it.

---

## Chapter 9 — iOS / macOS Host Notes

The host code that calls `HostBootstrap.build` is small but has three load-bearing details specific to each platform:

**Pin lifetime in the host's GC discipline.** The dispatcher (and the state, session, flash, coordinator) must outlive every callback that captures them. On macOS, that means locals in the entry function (which lives for the process). On iOS, that means class-var slots on the bridge module so the values survive across bridge entry calls. Voyager publishes to `Voyager.state` and `Voyager.dispatcher` precisely because those reads happen inside screen build methods and dispatch closures.

**Renderer / provider install BEFORE screen build (Rule 4).** Constructing `UI::UIKit::Renderer.new` installs the `UI::DesignTokens::Device.install_provider` block; screens that call `DeviceMetrics.current` during `build` need the provider to exist already. On macOS, a long-lived renderer hides this — you construct once, ignore order. On iOS the bridge often allocates a fresh renderer per render; the order matters and getting it wrong SIGSEGVs (Phase 8D.2 reflection).

```crystal
# Wrong (iOS fresh-renderer path):
view_tree = screen.build(ctx)        # crashes on DeviceMetrics.current
renderer = UI::UIKit::Renderer.new

# Right:
renderer = UI::UIKit::Renderer.new   # installs the provider
view_tree = screen.build(ctx)        # safe
```

**Mount before publish (Rule 3).** The dispatcher's `mount_screen` MUST happen before any path that fires the renderer's `on_change` subscriber — including the first render. `HostBootstrap.build` enforces this for the initial mount; the dispatcher's `translate_result` enforces it for every Navigate / Pop / Rerender / ReplaceRoot. If you bypass the bootstrap helper, replicate the order yourself.

---

## Chapter 10 — Amber Full-Server Wiring

The same `UI::App` declaration can drive a full-server Amber app. Inside Amber's routes config:

```crystal
# config/routes.cr
Amber::Server.configure do
  pipeline :web do
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::Session.new
    plug Amber::Pipe::Flash.new
    plug Amber::Pipe::CSRF.new
  end

  routes :web do
    UI::AmberIntegration.routes_for(YourApp)
  end
end
```

`routes_for` walks `YourApp` at compile time and emits one Amber route per `web_actions` entry on every registered screen. The screen registration declares its web side via additional kwargs (lifted from `samples/phase-08-amber-spike/config/application.cr`):

```crystal
class SpikeApp < UI::App
  screen :sign_in,
         web_controller: SignInController,
         web_path: "/",
         web_actions: [
           {verb: :get,  action: :index},
           {verb: :post, action: :submit, path: "/sign_in/submit"},
         ]
end
```

A screen registration can declare native (`controller:` positional) + web (`web_controller:`, `web_path:`, `web_actions:`) bindings independently. Native-only screens contribute no routes; web-only screens raise `UI::App::WebOnlyScreenError` if a native dispatcher ever tries to drive them.

**What Amber owns** on this path: HTTP request/response, routing (via the emitted `get`/`post` calls), params parsing, session pass-through to `ScreenContext::Web#params`, CSRF token issuance, ECR template rendering. The integration uses per-action shim `.ecr` templates whose contents are `<%= @screen_html %>`; the asset_pipeline shard ships `bin/asset_pipeline_amber` to generate them.

`UI::ScreenContext::Web` carries `csrf_token` through to `UI::Form.csrf_token` so forms get CSRF tokens correctly without per-form wiring. Screens that need request data read `context.params["email"]?` exactly like Voyager's native screen reads `context.form_state["email"]?`.

The asset_pipeline Amber integration does NOT wrap `HTTP::Server::Context`, does NOT replace Amber's `render` macro, and does NOT introduce a new routing layer. It contributes screens, contexts, and `routes_for`.

---

## Chapter 11 — Static-Site Web Is Different

**The Voyager web build is intentionally NOT on the `UI::ActionDispatcher` path.** This trips new readers up; the rationale is in [`docs/initiative-cross-platform-ui/architecture/web-target-position.md`](architecture/web-target-position.md). The short version:

- A `UI::ActionDispatcher` is a Crystal-resident, live-server abstraction. Browser-side JavaScript is not Crystal; static-site deploys have no Crystal at the edge.
- Voyager web optimizes for deployable artifacts — one HTML fragment per known slug, hostable on any object store, no Crystal runtime needed.
- The static-site entry point is `Voyager.build_route(state, coord, route)` in `samples/initiative-cross-platform-ui-voyager/app.cr`. It builds a minimal `ScreenContext::Native` with NO dispatcher attached; screen callbacks become no-ops on this path (client-side JavaScript handles navigation).

`Voyager.build_route` is **permanent infrastructure**, not a transitional shim. Phase 8D.1 originally framed it that way; Phase 8D.3a settled the disposition at D1 (keep, doc) once iOS no longer called it. It is the static-site target.

The three target paths in one table:

| Target | Entry point | Action path |
|--------|-------------|-------------|
| macOS / iOS native | `UI::ActionDispatcher` (via `HostBootstrap.build`) | Native `UI::ActionDispatcher` routes controller actions and applies `UI::ActionResult` |
| Amber full-server web | `UI::AmberIntegration.routes_for(App)` + Amber controllers + `UI::Web::Renderer` | No native `UI::ActionDispatcher`. Amber owns request/response, builds a `UI::ScreenContext::Web`, and re-renders the screen on each request. `web_actions:` declarations emit per-action Amber routes that re-execute the controller logic in Amber's request cycle. |
| Voyager static-site web | `Voyager.build_route` (build-time HTML) | No dispatcher and no live server. Screen callbacks are no-ops; client-side JavaScript (or full-page reloads) handles navigation. |

A future "Voyager Amber port" could merge Voyager's web target onto the dispatcher path. It is not a 2026 commitment. Both deployment models stay demonstrable.

---

## Chapter 12 — Five Rules To Remember

These hold across every `UI::App` deployment. Same five rules as the `ui-app` skill (canonical statement; both occurrences are authoritative):

1. **App/domain state mutations go through the target's controller layer** — `UI::Controller` + `UI::ActionDispatcher` on native; the Amber controller's request cycle on Amber full-server web; build-time only for static-site. Never in screen `build` methods. Todos toggling, user session writes, settings flags — screens render; the controller layer mutates. On native, `UI::ActionDispatcher` routes the action and applies the returned `UI::ActionResult`. On Amber full-server web, Amber's request cycle invokes the controller and `UI::AmberIntegration` re-renders the screen via `UI::Web::Renderer` (no native dispatcher).

2. **View-local affordances may use closures.** `save.disabled = title.empty?` on `title_field.on_change` is correct. Don't route view-local flips through `Rerender` — that allocates a fresh `FormState` and loses the in-progress typed value (Phase 8D.3a co-plan).

3. **Mount before publish/render.** The dispatcher's `mount_screen` ALWAYS precedes the coordinator op (`push` / `pop` / `replace_root` / `republish`) that fires the on_change subscriber. **This includes Pop** — `translate_result` mounts the target route BEFORE calling `navigation.pop`. The renderer reads `UI::FormState.current` during wire-time; that must be the NEW mount's FormState.

4. **Renderer / provider install before screen build.** `UI::UIKit::Renderer.new` installs the `UI::DesignTokens::Device.install_provider` block; screens query `DeviceMetrics.current` during `build`. Construct-after-build SIGSEGVs (Phase 8D.2 iOS observed). macOS hosts that reuse a long-lived renderer don't surface this; iOS fresh-renderer paths MUST honor the order.

5. **Capture evidence ≠ interaction evidence.** Screenshots prove visual state at a known scenario. Dispatcher specs + hand-tests prove action behavior. Asking screenshots to prove "the tap worked" is what runs into Phase 6.10's XCUITest tap-synthesis wall.

---

## Chapter 13 — Where To Read Next

- **`.claude/skills/ui-app/SKILL.md`** — operational reference for everything above (this tutorial's pair).
- **`docs/initiative-cross-platform-ui/architecture/web-target-position.md`** — full rationale for the static-site vs full-server web split.
- **`samples/initiative-cross-platform-ui-voyager/app.cr`** — the canonical `UI::App` declaration + dispatch helper + static-site entry point.
- **`samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr`** — canonical native bootstrap.
- **`samples/initiative-cross-platform-ui-voyager/controllers/sign_in_controller.cr`** — canonical controller with flash + session + result helpers.
- **`samples/initiative-cross-platform-ui-voyager/screens/todos.cr`** — realistic screen with action_params payloads.
- **`samples/phase-08-amber-spike/config/routes.cr` + `config/application.cr`** — `UI::AmberIntegration.routes_for` and `web_actions:` in context.
- **`docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/`** — Phase 8 briefs and reflections (the authoritative supplement to this tutorial; design intent + reflections + Codex critiques).
- **`src/asset_pipeline/action_dispatcher.cr`** — read `translate_result` for the mount-before-publish invariant in source.
- **`src/asset_pipeline/native_app.cr`** — read the `screen` macro and `bootstrap!` to understand the iOS class-init gap recovery hatch.
