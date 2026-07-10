# Phase 8D.1 — Voyager Native Unification (macOS-first)

**Date opened:** 2026-05-24 (v2 — Codex critique-1 folded in: build_route compat shim, params mechanism concretized, action ref convention, Rerender contract, stack policy, visual bar, dispatcher integration specs)
**Status:** APPROVED for Implementer dispatch.
**Branch:** to be cut as `phase-08d.1-voyager-native-unification` from feature branch.
**Codex protocol:** Per-iteration critique. No self-assessment.
**Co-planning record:** `phase-08-ergonomic-mvc-api/coplan-8d-codex-1.md`
**Architect-side brief critique:** `phase-08-ergonomic-mvc-api/codex-critique-1-brief-8d.1.md`

---

## Why this phase exists

Phase 8A/8B/8C shipped the unified UI architecture. Phase 8D is the visible payoff — migrate Voyager (the canonical demo) to use it. Per Codex co-plan, Phase 8D is split into 3 sub-phases:

- **8D.1** (this): macOS native unification — VoyagerApp + 4 controllers + macOS host migrated.
- **8D.2**: iOS bridge migration — iOS bridge.cr migrates to UI::ActionDispatcher; closes Phase 8B deferred iOS work.
- **8D.3**: 14-row interaction proof — 28 iOS captures + macOS equivalents + B2 web architecture doc.

Voyager today:
- `app.cr` is a `Voyager` MODULE. `Voyager.build_route(state, coord, route)` is a case statement.
- Screens are module-level classes with `build(state, coord)` class methods.
- Screen callbacks call `coord.push(Route.new(:todos))` directly.
- `Voyager::State` is a module singleton.
- macOS host subscribes to `coord.on_change` to rebuild + setContentView.
- iOS bridge calls `Voyager.build_route` from a C-ABI function.
- Web (`web/static_site.cr`) calls `Voyager.build_route` to generate 4 static HTML files.

After 8D.1 (macOS only):
- `VoyagerApp < UI::App` declared in `app.cr` with `screen :sign_in, SignInController` etc.
- `SignInController`, `TodosController`, `TodoEditorController`, `SettingsController` extend `UI::Controller` with explicit `dispatch_action` overrides.
- Each screen's class file becomes a `UI::Screen` subclass with `build(ctx : UI::ScreenContext::Native) : UI::View`.
- Screen callbacks return action refs (Symbol or `{Controller, :action}`) flowing through `UI::ActionDispatcher`.
- macOS host creates a `UI::ActionDispatcher`, wires it to the coordinator, calls `VoyagerApp.bootstrap!`, mounts the initial screen.
- **`Voyager.build_route` REMAINS as a temporary compat shim** so iOS bridge and web static-site continue to compile. The shim constructs a minimal ScreenContext and calls `registration.screen_class.new.build(ctx)`. 8D.2 removes the iOS dependency; 8D.3 may remove the web dependency or leave the shim permanently.

iOS bridge is **NOT touched in 8D.1** — that's 8D.2's scope.
Web target is **NOT migrated in 8D.1** — per Codex co-plan Decision B2, Voyager web stays static-site.

## Environment assumptions

1. Phase 8A/8B/8C merged. Tags `phase-08a-pass-2026-05-24`, `phase-08b-pass-with-notes-2026-05-24`, `phase-08c-pass-with-notes-2026-05-24` all exist.
2. `UI::ActionDispatcher` carries NO `@@` class-vars (verified: instance-only state). Bootstrap discipline reduces to `VoyagerApp.bootstrap!` + per-host dispatcher instance creation.
3. `samples/phase-08b-native-spike/` is the reference implementation pattern.
4. macOS only in this sub-phase. Compiler: `crystal-alpha` with `-Dmacos`. See CLAUDE.md "Native App Development Workflow".

## Architectural contracts (concrete this phase relies on)

These contracts are derived from Phase 8B. If any of them DOES NOT match the actual implementation of UI::ActionDispatcher / UI::ActionResult / UI::ScreenContext::Native, STOP and escalate — do NOT improvise.

### Action ref convention

Two forms:
- **`Symbol` (preferred)** — the action belongs to the CURRENTLY MOUNTED route's controller. The dispatcher looks up the controller via `registration_for(coord.current.id)`.
- **`Tuple({Controller.class, :action})`** — explicit cross-controller dispatch. Only used when a widget rendered in route A needs to dispatch to controller B (rare).

**Voyager's mapping:**
- SignInScreen Sign In button: `action: :submit` (SignInController).
- TodosScreen "Add Todo" button: `action: :new_todo` (TodosController).
- TodosScreen "Open Settings" link: `action: :open_settings` (TodosController).
- TodosScreen SwipeActionRow Edit: `action: :edit_row, action_params: {todo_id: id.to_s}` (TodosController).
- TodosScreen SwipeActionRow Delete: `action: :delete_row, action_params: {todo_id: id.to_s}` (TodosController).
- TodosScreen row Toggle (mark complete): `action: :toggle_row, action_params: {todo_id: id.to_s}` (TodosController).
- TodoEditorScreen Save button: `action: :save` (TodoEditorController; reads `ctx.params["todo_id"]`).
- TodoEditorScreen Cancel button: `action: :cancel` (TodoEditorController; returns Pop).
- SettingsScreen hide-completed Toggle: `action: :toggle_filter` (SettingsController).
- SettingsScreen Back link: `action: :back` (SettingsController; returns Pop).

### Params propagation contract

`UI::ScreenContext::Native` exposes `params` (route params) and `action_params` (kwargs from the triggering action). **Separate accessors — no silent merge.**

- **Action-time:** the dispatched action's `action_params` is in `ctx.action_params`. The current route's `params` is in `ctx.params`.
- **Mount-time:** when an action returns `Navigate.new(:next_route, params: {...})`, the dispatcher mounts the next route with that params hash. The NEXT mount's `ctx.params` reflects those Navigate-supplied params.
- **Voyager TodoEditor pattern (codex-recommended):**
  - `TodosController#edit_row(ctx)` reads `ctx.action_params["todo_id"]` (from the swipe row's action_params).
  - Returns `UI::ActionResult::Navigate.new(:todo_editor, params: {todo_id: id_str})`.
  - `TodoEditorScreen.new.build(ctx)` reads `ctx.params["todo_id"]` (set by the Navigate's params).
  - `TodoEditorController#save(ctx)` reads `ctx.params["todo_id"]` (same — params persist across the screen's lifetime, action_params is per-action).

### Stack policy

NavigationCoordinator stack shape per transition:

| Transition | Stack after |
|---|---|
| App launch | `[sign_in]` |
| Sign In → `ReplaceRoot(:todos)` | `[todos]` |
| Todos → `Navigate(:settings)` | `[todos, settings]` |
| Settings → `Pop` | `[todos]` |
| Todos → `Navigate(:todo_editor, params: ...)` (new or swipe-edit) | `[todos, todo_editor]` |
| Editor Save → `Pop` | `[todos]` |
| Editor Cancel → `Pop` | `[todos]` |
| Todos row Toggle / Settings toggle filter / Delete | stays unchanged (Rerender) |

**Critical: SignInController#submit returns `UI::ActionResult::ReplaceRoot.new(:todos)`, NOT `Navigate.new(:todos)`.** Sign-in must not be in the back stack.

### Rerender contract

`UI::ActionResult::Rerender` semantics:
- Current route ID unchanged.
- Dispatcher rebuilds the current screen by calling `screen.build(ctx)` with current `params`, `session`, `flash`, `form_state`, and latest singleton state.
- Host updates content view without stack mutation.
- Dispatcher does NOT call `coord.push/pop/replace_root`; it directly invokes the render path.

If `UI::ActionResult::Rerender` does NOT have this contract in Phase 8B's implementation, the brief is WRONG and the Implementer must escalate.

## Scope — 6 items

### Item 1 — `VoyagerApp < UI::App` class declaration

**File:** `samples/initiative-cross-platform-ui-voyager/app.cr` (EDIT).

Changes:
- ADD `class VoyagerApp < UI::App` declaration with `initial_route :sign_in` + 4 `screen :id, Controller` macros.
- REMOVE `Voyager.build_route` (the case-statement form). REPLACE with a thin compat shim — see below.
- KEEP `Voyager::SLUGS`, `Voyager.route_for_slug`, `Voyager.slug_for_route_id` unchanged (web target uses these).
- KEEP `Voyager::State` module singleton unchanged (per Codex co-plan Decision C).

The compat shim (for iOS + web during 8D.1 → 8D.2 window):

```crystal
module Voyager
  # 8D.1 compat shim. iOS bridge.cr + web/static_site.cr still call this.
  # 8D.2 removes iOS dependency; 8D.3 evaluates web dependency.
  def self.build_route(state : State, coord : UI::NavigationCoordinator, route : UI::NavigationCoordinator::Route) : UI::View
    reg = VoyagerApp.registration_for(route.id)
    # Minimal ScreenContext for the shim — no dispatcher integration.
    # Direct screen rendering bypasses the controller layer; only suitable
    # for static-site rendering and iOS's existing render-on-demand flow.
    ctx = UI::ScreenContext::Native.new(
      params: route.params.transform_values(&.to_s),
      action_params: {} of String => String,
      form_state: UI::FormState.new(mount_token: 0_u64, route_id: route.id),
      session: UI::Session::InProcess.new,
      flash: UI::Flash::InProcess.new,
    )
    reg.screen_class.new.build(ctx)
  end
end

class VoyagerApp < UI::App
  initial_route :sign_in
  screen :sign_in,     SignInController
  screen :todos,       TodosController
  screen :todo_editor, TodoEditorController
  screen :settings,    SettingsController
end
```

**Note on `ScreenContext::Native` signature:** the brief shows the constructor with keyword args. The Implementer must check `src/asset_pipeline/native_context.cr` for the actual constructor shape and adjust. If the constructor differs, this is a brief inaccuracy, NOT a Phase 8B API gap — fix the brief inline in the implementer report.

**Acceptance:**

- `VoyagerApp.bootstrap!` is callable.
- `VoyagerApp.registration_for(:sign_in).screen_class == SignInScreen`.
- All 4 routes registered.
- `Voyager.build_route(state, coord, route)` still works (compat shim).
- `Voyager::SLUGS`, `route_for_slug`, `slug_for_route_id`, `Voyager::State` unchanged.
- Spec at `spec/asset_pipeline/voyager_app_spec.cr` covers all 4 registrations + initial_route_id + compat shim returns a non-nil view per route.

### Item 2 — Refactor 4 screens into `UI::Screen` subclasses

Each screen file in `samples/initiative-cross-platform-ui-voyager/screens/` changes from a module-level class with `build(state, coord)` class method to a `UI::Screen` subclass with `def build(ctx : UI::ScreenContext::Native) : UI::View`.

**Per the action ref convention above, all user-intent callbacks become action refs.** No direct `coord.push` calls inside screen build methods. `Voyager::State` is accessed as a module singleton inside `build` methods (NOT injected via context).

**Per-screen scope:**

- **SignInScreen** — email TextField (`name: "email"`), password SecureField (`name: "password"`), Sign In Button (`action: :submit`).
- **TodosScreen** — `Voyager::State.visible_todos` rendered as `UI::SwipeActionRow` list. Each row has Toggle (`action: :toggle_row, action_params: {todo_id: id.to_s}`), trailing Edit + Delete swipe actions (`action: :edit_row` / `:delete_row` with `action_params: {todo_id: id.to_s}`). Header: "Add Todo" button (`action: :new_todo`), "Settings" link (`action: :open_settings`).
- **TodoEditorScreen** — receives `todo_id` via `ctx.params["todo_id"]` (set by `Navigate.new(:todo_editor, params: ...)`). If `todo_id == "0"`, blank editor; else look up `Voyager::State.find_todo(id)`. Title TextField (`name: "title"`), Completed Toggle, Save Button (`action: :save`), Cancel Button (`action: :cancel`).
- **SettingsScreen** — hide-completed Toggle bound to `Voyager::State.hide_completed?` (`action: :toggle_filter`). Back link (`action: :back`).

**Per-screen acceptance:**

- Each `*Screen` class extends `UI::Screen`.
- Each `build(ctx : UI::ScreenContext::Native) : UI::View` method composes the view tree.
- No `coord.push` calls inside screen build methods.
- No `Voyager.build_route` calls inside screen build methods (only the compat shim calls it externally).
- **Per-screen specs are DROPPED** (per Codex finding 7). View-tree assertions are covered by dispatcher integration specs in Item 6.

### Item 3 — 4 `UI::Controller` subclasses

Create at `samples/initiative-cross-platform-ui-voyager/controllers/{sign_in,todos,todo_editor,settings}_controller.cr`.

**SignInController:**
```crystal
class SignInController < UI::Controller
  def dispatch_action(name : Symbol, ctx : UI::ScreenContext::Native) : UI::ActionResult
    case name
    when :submit then submit(ctx)
    else raise UI::Controller::UnknownAction.new("SignInController has no action :#{name}")
    end
  end

  def submit(ctx) : UI::ActionResult
    email = ctx.form_state["email"]?.to_s.strip
    password = ctx.form_state["password"]?.to_s.strip
    if email.empty? || password.empty?
      ctx.flash[:error] = "Please provide both email and password."
      UI::ActionResult::Rerender.new
    else
      ctx.session["user_email"] = email
      UI::ActionResult::ReplaceRoot.new(:todos)  # CRITICAL: ReplaceRoot, not Navigate
    end
  end
end
```

**TodosController** — actions: `:new_todo` (Navigate(:todo_editor, params: {todo_id: "0"})), `:edit_row` (Navigate(:todo_editor, params: {todo_id: ctx.action_params["todo_id"]})), `:delete_row` (mutate Voyager::State, return Rerender), `:toggle_row` (toggle todo completed, Rerender), `:open_settings` (Navigate(:settings)).

**TodoEditorController** — actions: `:save` (read ctx.params["todo_id"], read ctx.form_state["title"], mutate Voyager::State, return Pop), `:cancel` (return Pop).

**SettingsController** — actions: `:toggle_filter` (flip Voyager::State.hide_completed, return Rerender), `:back` (return Pop).

**Per-controller acceptance:**

- 4 controller class files exist.
- Each overrides `dispatch_action` with explicit case statement.
- Each raises `UI::Controller::UnknownAction` for unknown action names.
- Unit specs at `spec/asset_pipeline/voyager_*_controller_spec.cr` verify each action returns the correct `ActionResult` subtype + raises `UnknownAction` for unknown names. Sign-in submit returns `ReplaceRoot`, NOT `Navigate`. Editor save returns `Pop`.

### Item 4 — macOS host migration

`samples/initiative-cross-platform-ui-voyager/macos/host.cr` migrates from "build_route on coord change + setContentView" to "ActionDispatcher dispatches actions → ActionResult → coord mutation + renderer rebuild".

The migration follows `samples/phase-08b-native-spike/src/spike_app.cr`'s macOS-host pattern. **The Implementer should READ that file first**.

```crystal
{% if flag?(:macos) %}
  module VoyagerHost
    def self.run(slug : String, appearance : String)
      # Existing AppKit init + renderer creation
      VoyagerApp.bootstrap!

      coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(VoyagerApp.initial_route_id))
      renderer = UI::AppKit::Renderer.new
      dispatcher = UI::ActionDispatcher.new(
        app: VoyagerApp,
        coordinator: coord,
        renderer: renderer,
        on_render_inline: ->(_v : UI::View) { },
      )

      # Initial mount + render
      dispatcher.mount_screen(VoyagerApp.initial_route_id)
      initial_ctx = dispatcher.current_context  # See note below
      initial_screen = VoyagerApp.registration_for(VoyagerApp.initial_route_id).screen_class.new
      initial_view = initial_screen.build(initial_ctx)
      # install_view(initial_view)

      # On-change: dispatcher has ALREADY mounted (Phase 8B mount-before-publish).
      # The subscriber renders the dispatcher's current screen + context.
      coord.on_change do |route|
        reg = VoyagerApp.registration_for(route.id)
        ctx = dispatcher.current_context
        view = reg.screen_class.new.build(ctx)
        # install_view(view)
      end

      # Existing window run loop
    end
  end
{% end %}
```

**Note on `dispatcher.current_context`:** the brief assumes `UI::ActionDispatcher` exposes an accessor for the currently-mounted ScreenContext. If it does not, the Implementer escalates — DO NOT IMPROVISE a workaround. This is the only API gap that may need a Phase 8B+ patch in 8D.1's scope.

**Acceptance:**

- macOS host compiles + launches.
- Initial screen = SignInScreen.
- Typing into TextField fields updates `UI::FormState.current` (Phase 8B renderer hook does this).
- Tapping Sign In dispatches `:submit`, navigates to TodosScreen via ReplaceRoot.
- All 14 behavior contract actions reachable in iteration mode.
- State-propagation litmus preserved (Settings hide-completed → back → Todos reflects).

### Item 5 — Pre-migration behavior baseline (regression guard)

Per Codex co-plan risk R2 + Codex critique-1 finding 6.

**Before any code changes**, capture macOS Voyager baseline screenshots:

- `docs/initiative-cross-platform-ui/handoff/phase-08d.1-baseline/voyager-macos-sign-in-baseline.png`
- `docs/initiative-cross-platform-ui/handoff/phase-08d.1-baseline/voyager-macos-todos-baseline.png`
- `docs/initiative-cross-platform-ui/handoff/phase-08d.1-baseline/voyager-macos-todo-editor-baseline.png`
- `docs/initiative-cross-platform-ui/handoff/phase-08d.1-baseline/voyager-macos-settings-baseline.png`

(Light appearance only — dark is 8D.3 scope.)

After migration, capture the same 4 routes with `-postmigration.png` suffix.

**Visual regression bar (per Codex finding 6):**
- Layout hierarchy preserved (window structure, navigation chrome, primary content area positions).
- All labels present + readable (no clipped text).
- All interactive controls present + visible (no hidden buttons).
- Spacing variance < 4px on primary axes (eyeball acceptable; pixel-diff tool not required).
- No horizontal scroll on default 880×640 window.
- No route-level missing content (Todos still shows 5 seed todos).

Implementer report includes side-by-side annotated comparison (baseline-vs-postmigration screenshots, deltas documented).

### Item 6 — Dispatcher integration specs + spec drift

Add `spec/asset_pipeline/voyager_dispatcher_integration_spec.cr` with 4 integration scenarios:

1. **Sign-in submit → ReplaceRoot to :todos.** Set form_state[email/password], dispatch :submit, assert stack == `[todos]`.
2. **Todos edit_row dispatch → Navigate to :todo_editor with correct params.** Set action_params[todo_id], dispatch :edit_row, assert stack ends `[..., todo_editor]` AND mounted ctx.params["todo_id"] matches.
3. **Settings toggle_filter dispatch → Rerender.** Dispatch :toggle_filter, assert `Voyager::State.hide_completed?` flipped AND coord stack unchanged.
4. **Editor cancel → Pop to :todos.** From `[todos, todo_editor]`, dispatch :cancel, assert stack == `[todos]`.

**Spec drift:**
- `crystal spec` baseline preserved (1671/4/0/66 entering, ≥1671/4/0/66 exiting).
- Per-controller specs (Item 3) + voyager_app_spec.cr (Item 1) + voyager_dispatcher_integration_spec.cr add NEW examples.
- Per-screen specs are DROPPED (per Codex finding 7).

## Codex protocol — NO EXCEPTIONS

Per-iteration Codex review at `handoff/phase-08d.1-codex-N.md`. No self-assessment.

Iteration boundaries:
- **iter 1**: Items 1 + 2 + 3 (VoyagerApp + compat shim, 4 screens, 4 controllers).
- **iter 2**: Items 4 + 5 + 6 (macOS host migration + baseline / post-migration captures + integration specs).
- iter 3 reserved for remediation if needed.

## Acceptance you must meet

- `crystal spec` baseline preserved (1671/4/0/66 entering, ≥1671/4/0/66 exiting).
- macOS Voyager binary launches + sign-in flow works end-to-end (interactive verification: type email + password, tap Sign In, see TodosScreen with 5 seed todos).
- All 14 behavior contract actions reachable in iteration mode on macOS.
- No direct `coord.push` calls in any of the 4 screen build methods.
- `Voyager.build_route` compat shim works for iOS bridge + web static-site (verify both still compile: macOS build + run web/static_site.cr generator).
- Voyager web build still produces 4 HTML files (no regression).
- 2 Codex per-iter reviews committed + 1 architect-side critique (this brief's codex-critique-1) already committed.
- 4 baseline + 4 post-migration captures committed.

## Hard rules

- Forward commits only on `phase-08d.1-voyager-native-unification`.
- NO Phase 8A/8B/8C API changes EXCEPT possibly adding `UI::ActionDispatcher#current_context` if it doesn't exist (Item 4 note). Any other API change requires escalation.
- NO iOS bridge touched. iOS is 8D.2's scope.
- NO web target migration. Static-site stays per Codex co-plan B2.
- NO new sentinels or design-token changes.
- NO new abstractions. Use the Phase 8B vocabulary as-is.
- Standard Claude co-author footer.

## Reporting

Write `docs/initiative-cross-platform-ui/handoff/phase-08d.1-implementer-report.md`. Include:
- Branch HEAD (sha) at completion.
- Commit count + summary of each commit.
- Codex verdicts per iteration.
- Spec counts entering + exiting.
- All 8 capture paths (4 baseline + 4 post-migration).
- Side-by-side annotated visual diff summary.
- Whether `UI::ActionDispatcher#current_context` was already there or had to be added.
- Any deferred / open notes.

Return to architect with a tight summary (≤300 words) covering: did you ship; did macOS Voyager work end-to-end; spec drift; any visual regressions; whether you escalated any API gaps.

---

**Status: APPROVED v2 — Codex critique-1 (REVISE → all 9 findings addressed). Ready for Implementer dispatch.**
