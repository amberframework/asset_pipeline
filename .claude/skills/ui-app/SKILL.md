---
name: ui-app
description: Build cross-platform apps with UI::App + UI::Screen + UI::Controller + UI::ActionDispatcher + UI::FormState — route declarations, native action dispatch, Amber web integration, and the static-site web target.
user-invocable: true
---

# Build apps with UI::App, Controllers, and the ActionDispatcher

You are wiring a cross-platform application on top of the asset_pipeline cross-platform UI system. `UI::View` composition (handled by the `build-ui` and `component-api` skills) gives you the visual tree; `UI::App` and its collaborators give you the app shell — routes, navigation, controllers, action dispatch, form state, session, flash, and host integration on macOS, iOS, and Amber web.

This skill is the operational reference. The narrative tutorial lives at `docs/initiative-cross-platform-ui/tutorial-ui-app.md` — read that first if you've never wired a `UI::App` before.

---

## 1. When To Use This Skill

| Goal | Skill |
|------|-------|
| Compose a `UI::View` tree (VStack / Button / TextField / Card / etc.) | `build-ui` |
| Look up the API surface of a single `UI::View` type | `component-api` |
| Declare routes, controllers, action dispatch, host bootstrap, Amber wiring | **`ui-app` (this skill)** |

Use `ui-app` when you are:

- Declaring a `UI::App` subclass with `screen :route_id, FooController`.
- Writing a `UI::Controller` subclass that handles an action (`:submit`, `:edit_row`, `:open_settings`).
- Wiring a native host (macOS or iOS) to drive screens through `UI::ActionDispatcher`.
- Wiring an Amber app to drive the same `UI::App` through `UI::AmberIntegration.routes_for`.
- Reading `ctx.form_state["email"]`, `ctx.action_params["todo_id"]`, `ctx.session`, or `ctx.flash` inside a controller.
- Reasoning about which target — native dispatcher, Amber full-server, or Voyager static-site — your screen runs in.

If you are styling a button, picking a `UI::Color` role, or composing a card layout, you want `build-ui` or `component-api`, not this skill.

---

## 2. Core Architecture

Phase 8 added a four-piece app model layered on top of the existing `UI::View` system. Plus `UI::FormState` for controlled inputs.

```
UI::App                — declarative route registry (one subclass per app)
  ├── UI::Screen       — pure render: build(ctx) -> UI::View
  ├── UI::Controller   — native actions; returns UI::ActionResult
  └── UI::ActionDispatcher  — routes action refs → controllers → coordinator/host

UI::FormState          — per-mount controlled-input store
UI::ScreenContext      — abstract; Web + Native concrete subclasses
UI::ActionResult       — Navigate | Pop | Rerender | ReplaceRoot | RenderInline
```

**Lifecycle (native, per-mount):**

1. Host calls `App.bootstrap!` once at startup.
2. Host constructs `state`, `NavigationCoordinator`, `Session`, `Flash`, then `UI::ActionDispatcher`.
3. Host calls `dispatcher.mount_screen(coord.current)` to allocate the FIRST FormState and bump the mount token.
4. Host publishes the dispatcher into its holder (e.g. Voyager uses sample-local `Voyager.dispatcher = dispatcher`).
5. Each subsequent action (Button tap, form submit) closures into `Voyager.dispatch(:action_name, action_params)`, which calls `dispatcher.dispatch(:action_name, params)`.
6. The dispatcher resolves the current route's controller, runs before_actions, calls `controller.dispatch_action`, and translates the returned `UI::ActionResult` into a coordinator op — mounting the target route's fresh FormState BEFORE the coordinator publishes the new tree.

**Source files:**

- `src/asset_pipeline/native_app.cr` — `UI::App`, `screen` macro, `bootstrap!`, `registration_for`.
- `src/asset_pipeline/native_controller.cr` — `UI::Controller`, `dispatch_action`, `before_action`, `navigate_to` / `pop_navigation` / `render_current_screen` / `replace_root` / `respond_with`.
- `src/asset_pipeline/action_dispatcher.cr` — `UI::ActionDispatcher#dispatch`, `mount_screen`, `translate_result`.
- `src/asset_pipeline/action_result.cr` — `UI::ActionResult` and its five subclasses.
- `src/asset_pipeline/native_context.cr` — `UI::ScreenContext::Native`, `UI::Session::InProcess`, `UI::Flash::InProcess`.
- `src/asset_pipeline/amber_integration.cr` — `UI::Screen`, `UI::ScreenContext` abstract + `Web` concrete, `UI::AmberIntegration.routes_for`.
- `src/ui/form_state.cr` — `UI::FormState`, `UI::FormState.current`, `UI::FormState.current_mount_token`.

---

## 3. Screens

A screen is a pure-render function. Subclass `UI::Screen` and implement `build(context : UI::ScreenContext) : UI::View`.

```crystal
class TasksScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    root = UI::VStack.new(spacing: 16.0)
    root << UI::Label.new("Tasks")

    add_btn = UI::Button.new("Add task")
    add_btn.on_tap = -> { TasksApp.dispatch(:new_task) }
    root << add_btn.as(UI::View)

    root.as(UI::View)
  end
end
```

**Rules:**

- **No domain mutations in `build`.** Build is called on every render — it must be idempotent given the same `ctx`. App / domain state mutations belong in controllers (Rule 1).
- **View-local affordance closures ARE allowed.** A `title_field.on_change = ->(v : String) { save.disabled = v.empty? }` closure mutates only view-local visual state. This is correct and intended (Rule 2). Routing this through a dispatcher `Rerender` would allocate a fresh `FormState` and lose the in-progress typed value (Phase 8D.3a co-plan).
- **Screen instances are stateless.** Per-render data lives on `ScreenContext`; a new screen instance is constructed for every build call.

`UI::Screen` is the abstract base; both the native dispatcher path and the Amber path consume the same subclass. The same screen class can render on both targets when the build method reads only the abstract `ScreenContext` surface (`params`, `params_multi`, `flash_data`, `design_tokens`, `csrf_token`).

Voyager's `Voyager::TodosScreen#build` (in `samples/initiative-cross-platform-ui-voyager/screens/todos.cr`) is the canonical realistic example — device-aware sizing, list rendering, multiple action refs per row.

---

## 4. Controllers And Actions

A controller owns the actions for one screen. Subclass `UI::Controller` and override `dispatch_action(name, context)`.

```crystal
class TasksController < UI::Controller
  before_action :require_signed_in

  def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
    case name
    when :new_task    then new_task(context)
    when :toggle_row  then toggle_row(context)
    else raise UI::Controller::UnknownActionError.new(
      "TasksController has no action :#{name}")
    end
  end

  def new_task(context : UI::ScreenContext::Native) : UI::ActionResult
    navigate_to(:task_editor)
  end

  def toggle_row(context : UI::ScreenContext::Native) : UI::ActionResult
    todo_id = context.action_params["todo_id"]
    TasksApp.state.toggle(todo_id)
    render_current_screen
  end

  private def require_signed_in(context : UI::ScreenContext::Native) : UI::ActionResult?
    return nil if context.session["user_email"]?
    replace_root(:sign_in)
  end
end
```

**Reads available on `ctx : UI::ScreenContext::Native`:**

| Reader | Source | Use for |
|--------|--------|---------|
| `ctx.form_state["email"]?` | Renderer-wired typed input values for the CURRENT mount | Form submission inputs |
| `ctx.action_params["todo_id"]` | Per-tap payload from the button's closure | Row identity, action-scoped data |
| `ctx.session["user_email"]` | Per-app in-process Session (`UI::Session::InProcess`) | Auth, persistent flags |
| `ctx.flash["error"]` | Per-app in-process Flash (`UI::Flash::InProcess`) | One-shot messages |
| `ctx.design_tokens` | `UI::DesignTokens::Tokens` for the app | Inline color/spacing reads |
| `ctx.navigation` | The `NavigationCoordinator` (for depth-aware affordances) | Back button visibility |

**Returns:**

Every action returns a `UI::ActionResult`. The controller-side helpers (`navigate_to`, `pop_navigation`, `render_current_screen`, `replace_root`, `respond_with`) construct them on your behalf.

**`before_action`:**

`before_action :method_name` registers a callback that runs before every action method on that controller. The callback receives the context and returns `UI::ActionResult?` — return `nil` to continue, return a result to short-circuit (typically `replace_root(:sign_in)` for an unauth guard).

**Note on macros:** `before_action` is gap-safe — it emits a named class method per registration so the iOS class-init gap can't strand the callback list. See `src/asset_pipeline/native_controller.cr` for the mechanism.

---

## 5. Action References (Shipped API)

Views call `Voyager.dispatch(:action_name, action_params)` (or your app's equivalent helper) from callback closures. The dispatcher accepts either form:

- **Symbol** — runs the action on the **CURRENT route's** registered controller.
- **`Tuple(UI::Controller.class, Symbol)`** — runs the action on the **explicitly named** controller (cross-controller dispatch).

```crystal
# Current route's controller (typical case).
submit = UI::Button.new("Sign in")
submit.on_tap = -> { Voyager.dispatch(:submit) }

# Per-tap action_params (row identity, etc.).
edit_btn.on_tap = -> {
  Voyager.dispatch(:edit_row, {"todo_id" => todo_id_str})
}

# Explicit cross-controller dispatch (rare; use sparingly).
sign_out_btn.on_tap = -> {
  Voyager.dispatcher.try &.dispatch({SignInController, :sign_out})
}
```

**Important: NEVER write `Button(action: :submit)` or `UI::Button.new(action: :submit, params: ...)`.** An older Phase 8 design draft proposed that kwarg-style syntax, but **it was never shipped**. The shipped API uses callback closures (`button.on_tap = -> { ... }`) that call your app's dispatcher helper. Examples that show the kwarg form are stale and should be ignored.

**Wiring the dispatcher helper** (Voyager pattern):

```crystal
module Voyager
  @@dispatcher : UI::ActionDispatcher? = nil

  def self.dispatcher=(d : UI::ActionDispatcher?); @@dispatcher = d; end
  def self.dispatcher; @@dispatcher; end

  def self.dispatch(name : Symbol, action_params : Hash(String, String) = {} of String => String) : Nil
    d = @@dispatcher
    return nil if d.nil?
    d.dispatch(name, action_params)
    nil
  end
end
```

This is sample-local. There is no generic `UI::App.dispatcher` slot in the framework — each host names its own holder. The framework owns the dispatcher object; the host owns publication.

**Cross-controller note (R11):** The tuple form (`{Controller, :action}`) is intentional cross-controller dispatch for a specific class of cases (e.g. a global sign-out button). It is NOT a command bus — do not use it to bypass route ownership of actions.

---

## 6. Action Results

A controller action returns one of five `UI::ActionResult` subtypes. The dispatcher's `translate_result` (`src/asset_pipeline/action_dispatcher.cr`) does the right thing for each.

| Subtype | Constructor helper | What it does |
|---------|--------------------|--------------|
| `Navigate` | `navigate_to(:route_id, params)` | Mount the new route's FormState; push onto the navigation stack. |
| `Pop` | `pop_navigation` | Mount the underlying route's FormState; pop the stack. No-op at root. |
| `Rerender` | `render_current_screen` | Re-mount the same route (fresh FormState, bumped token); republish. |
| `ReplaceRoot` | `replace_root(:route_id, params)` | Mount the new route's FormState; replace the entire stack. |
| `RenderInline` | `respond_with(view)` | Emit through `dispatcher.on_render_inline` callback (host-bound). No stack change. |

**`Rerender` vs view-local closures:** Use `Rerender` after a domain mutation that should propagate into the rebuilt view (e.g. toggle a todo). DO NOT use `Rerender` to flip a single button's disabled state in response to a TextField — that's view-local affordance (Rule 2) and belongs on the field's `on_change` closure. Routing it through the dispatcher rebuilds the entire screen and discards the typed input.

**`RenderInline`:** Use for sheets, popovers, and inline overlays that should NOT push onto the navigation stack. The host binds `dispatcher.on_render_inline` to its own presentation code (e.g. AppKit `presentAsSheet:`).

---

## 7. Native Host Wiring

The canonical native wiring sequence lives in Voyager's `HostBootstrap.build` (`samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr`). Prefer calling it directly — manual hosts MUST follow the same order.

```crystal
module Voyager
  module HostBootstrap
    def self.build(initial_route_id : Symbol = :sign_in) : Result
      VoyagerApp.bootstrap!                  # (1) re-run screen registrations (iOS gap recovery)

      state = Voyager::State.new             # (2) app/domain state
      Voyager.state = state

      coord = UI::NavigationCoordinator.new( # (3) navigation coordinator
        UI::NavigationCoordinator::Route.new(initial_route_id)
      )
      session = UI::Session::InProcess.new   # (4) session
      flash = UI::Flash::InProcess.new       # (5) flash
      dispatcher = UI::ActionDispatcher.new( # (6) dispatcher binds them all
        app: VoyagerApp,
        navigation: coord,
        session: session,
        flash: flash,
        design_tokens: UI::DesignTokens::Tokens.default,
      )
      dispatcher.mount_screen(coord.current) # (7) mount initial FormState BEFORE publish
      Voyager.dispatcher = dispatcher        # (8) publish to host's holder

      Result.new(state, coord, session, flash, dispatcher)
    end
  end
end
```

**The invariant (Rule 3 — Mount before publish/render):**

`dispatcher.mount_screen` must be called BEFORE anything that publishes to the renderer's `on_change` subscriber — including the initial first-render. The dispatcher's internal `translate_result` enforces this for every action (Navigate / Pop / Rerender / ReplaceRoot). The bootstrap helper enforces it for the initial mount.

**Pin lifetime in the host's GC discipline:**

- macOS: locals in the `main` function (live for the process).
- iOS: class vars on the bridge module (survives across bridge entry calls).
- Voyager uses `Voyager.state = state` and `Voyager.dispatcher = dispatcher` because those are accessed from screen build methods and dispatch closures.

**There is no generic `UI::App.dispatcher` slot.** Each host names its own holder. The framework's contract ends at "dispatcher object exists, mounted, and is reachable from your screens' closures."

---

## 8. Amber Host Wiring

The same `UI::App` declaration that drives native screens can drive a full-server Amber app. Wire it inside Amber's `routes :web do ... end` block:

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
    UI::AmberIntegration.routes_for(SpikeApp)
  end
end
```

**What `routes_for` does:**

For every screen in `SpikeApp` with `web_actions`, it emits the matching Amber `get` / `post` / `put` / `patch` / `delete` calls inline (compile-time macro expansion). See `src/asset_pipeline/amber_integration.cr` and `samples/phase-08-amber-spike/` for the proven shape.

**Declaring web routes on a screen registration:**

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

A `screen` registration can declare any combination of native (`controller:` positional) + web (`web_controller:`, `web_path:`, `web_actions:`) bindings. Native-only screens never appear in `routes_for`; web-only screens raise `UI::App::WebOnlyScreenError` if a native dispatcher ever tries to drive them.

**What Amber owns:**

- HTTP request/response lifecycle.
- Routing (via the emitted `get`/`post` calls).
- Params parsing.
- Session (passes through to `UI::ScreenContext::Web#params` / `flash_data` / `csrf_token`).
- CSRF token issuance (threaded through `UI::ScreenContext::Web#csrf_token` and consumed by `UI::Form.csrf_token`).
- Layouts and ECR template rendering (the integration uses per-action shim `.ecr` files containing `<%= @screen_html %>`).

The asset_pipeline integration does NOT wrap `HTTP::Server::Context`, does NOT replace Amber's `render` macro, and does NOT introduce a new routing layer. It contributes screens, contexts, and the `routes_for` macro.

---

## 9. Static-Site Web Target

**Voyager's web build is NOT on the dispatcher path. This is deliberate.**

`UI::ActionDispatcher` is a Crystal-resident, live-server abstraction. There is no dispatcher in the browser; there is no Crystal runtime at the edge of a static-site deploy. Voyager web is a static-site target — build-time HTML emission per known slug, browser-side JavaScript for navigation.

The static-site entry point is `Voyager.build_route(state, coord, route)` (in `samples/initiative-cross-platform-ui-voyager/app.cr`). It constructs a minimal `ScreenContext::Native` with NO dispatcher attached. Screen callbacks reduce to no-ops on this path — the static-site target hosts its own client-side navigation glue.

`Voyager.build_route` is **permanent infrastructure**, not a failed migration. The earlier Phase 8D.1 framing described it as transitional; Phase 8D.3a settled the disposition at D1 (keep, doc). Full rationale and code paths:

[`docs/initiative-cross-platform-ui/architecture/web-target-position.md`](../../../docs/initiative-cross-platform-ui/architecture/web-target-position.md)

| Target | Entry point |
|--------|-------------|
| macOS / iOS native | `UI::ActionDispatcher` (via `HostBootstrap.build`) |
| Amber full-server web | `UI::AmberIntegration.routes_for(App)` |
| Voyager static-site web | `Voyager.build_route` (sample-local, deliberate) |

The three targets serve different deployment models. A future "Voyager Amber port" could merge them; today it is not a commitment.

---

## 10. Architectural Rules

Five rules that must hold across every `UI::App` deployment. These also appear in the tutorial (Ch. 12); both occurrences are canonical.

1. **App/domain state mutations go through the target's controller layer** — `UI::Controller` + `UI::ActionDispatcher` on native; the Amber controller's request cycle on Amber full-server web; build-time only for static-site. Never in screen `build` methods. Todos toggling, user session writes, settings flags — screens render; the controller layer mutates. On native, `UI::ActionDispatcher` routes the action and applies the returned `UI::ActionResult`. On Amber full-server web, Amber's request cycle invokes the controller and `UI::AmberIntegration` re-renders the screen via `UI::Web::Renderer` (no native dispatcher). The mutation site is the controller in both deployments.

2. **View-local affordances may use closures.** `save.disabled = title.empty?` on `title_field.on_change` is correct and intended. Don't route this through dispatcher `Rerender` — that allocates a fresh `FormState` and loses the in-progress typed value (Phase 8D.3a co-plan).

3. **Mount before publish/render.** The dispatcher's `mount_screen` ALWAYS precedes the coordinator op (`push` / `pop` / `replace_root` / `republish`) that fires the on_change subscriber. **This includes Pop** — `translate_result` mounts the target route BEFORE calling `navigation.pop`. The renderer reads `UI::FormState.current` during wire-time; that must be the NEW mount's FormState.

4. **Renderer/provider install before screen build.** `UI::UIKit::Renderer.new` installs the `UI::DesignTokens::Device.install_provider` block; screens query `DeviceMetrics.current` during `build`. Construct-after-build SIGSEGVs (Phase 8D.2 iOS observed). macOS hosts that reuse a long-lived renderer don't surface this; iOS fresh-renderer-per-render paths MUST honor the order.

5. **Capture evidence ≠ interaction evidence.** Screenshots prove visual state at a known scenario. Dispatcher specs + hand-tests prove action behavior. Asking screenshots to prove "the tap worked" is what runs into Phase 6.10's XCUITest tap-synthesis wall.

---

## 11. Common Pitfalls

| Pitfall | Wrong | Right |
|---------|-------|-------|
| **Mutating domain state in `build`** | `def build(ctx); state.todos << Todo.new; ...; end` | Mutate in controller action; `build` is pure. |
| **Routing a `disabled?` flip through Rerender** | `field.on_change = ->(v) { App.dispatch(:rebuild) }` | View-local closure: `field.on_change = ->(v) { save.disabled = v.empty? }`. |
| **Publishing before mounting on a fresh renderer** | iOS host builds the view first, constructs renderer second | Construct renderer (which installs `DeviceMetrics`), THEN `screen.build(ctx)`. |
| **Using stale `Button(action: :submit)` kwarg syntax** | `UI::Button.new("Sign in", action: :submit)` | `submit = UI::Button.new("Sign in"); submit.on_tap = -> { App.dispatch(:submit) }`. |
| **Assuming a generic `UI::App.dispatcher` slot exists** | `UI::App.dispatcher = dispatcher` | Use your sample-local holder: `Voyager.dispatcher = dispatcher` or your own. |

Reflections behind each pitfall:

- View-local closures vs Rerender — Phase 8D.3a co-plan.
- Renderer-install ordering — Phase 8D.2 iOS SIGSEGV reflection.
- Mount-before-publish on Pop — Codex iter-4 finding #1 in `src/asset_pipeline/action_dispatcher.cr` (translate_result comment block).
- Closure dispatch vs kwarg action — Codex HIGH 1 on `brief-8e.md` (the shipped path).

---

## 12. Live References

Code:

- `src/asset_pipeline/native_app.cr` — `UI::App`, `screen` macro, `bootstrap!`.
- `src/asset_pipeline/native_controller.cr` — `UI::Controller`, `before_action`, result helpers.
- `src/asset_pipeline/action_dispatcher.cr` — `UI::ActionDispatcher`, `mount_screen`, `translate_result`.
- `src/asset_pipeline/action_result.cr` — five `UI::ActionResult` subtypes.
- `src/asset_pipeline/native_context.cr` — `UI::ScreenContext::Native`, `UI::Session::InProcess`, `UI::Flash::InProcess`.
- `src/asset_pipeline/amber_integration.cr` — `UI::Screen`, `UI::ScreenContext::Web`, `UI::AmberIntegration.routes_for`.
- `src/ui/form_state.cr` — `UI::FormState`.

Samples (the canonical realistic examples):

- `samples/initiative-cross-platform-ui-voyager/app.cr` — `VoyagerApp` declaration + `Voyager.dispatch` helper + `Voyager.build_route`.
- `samples/initiative-cross-platform-ui-voyager/host_bootstrap.cr` — `Voyager::HostBootstrap.build` (canonical native bootstrap).
- `samples/initiative-cross-platform-ui-voyager/controllers/sign_in_controller.cr` — `SignInController#submit` (flash + session + ReplaceRoot).
- `samples/initiative-cross-platform-ui-voyager/screens/sign_in.cr` — closure-on-on_tap shipping pattern.
- `samples/initiative-cross-platform-ui-voyager/screens/todos.cr` — `Voyager.dispatch(:edit_row, {"todo_id" => ...})` action_params pattern.
- `samples/phase-08-amber-spike/config/routes.cr` — `UI::AmberIntegration.routes_for(SpikeApp)` Amber wiring.
- `samples/phase-08-amber-spike/config/application.cr` — `SpikeApp` declaration with `web_actions:`.

Architecture and tutorial:

- `docs/initiative-cross-platform-ui/tutorial-ui-app.md` — narrative tutorial.
- `docs/initiative-cross-platform-ui/architecture/web-target-position.md` — why Voyager web is static-site, not dispatcher-backed.
- `docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/` — Phase 8 briefs, reflections, and Codex critiques (the most recent reflections are the authoritative supplement to this skill).
