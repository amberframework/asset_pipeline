# Phase 8C — `routes_for(UI::App)` Amber-Router Contribution

**Date opened:** 2026-05-24 (v3 — Codex critique-1 folded in: empirical macro mechanism proven, NamedTuple literal for web_actions, controller_class nilable, web-only screens supported)
**Authored by:** Architect (Codex critique before dispatch)
**Branch:** to be cut as `phase-08c-routes-for-app` from feature branch after this brief lands APPROVE.
**Codex protocol:** Per-iteration critique. No self-assessment.

---

## Why this phase exists

Phase 8A shipped `UI::ScreenHelpers#compute_screen_html` so Amber controllers can render `UI::Screen` view trees. Phase 8B ships `UI::App` declarative screen registry so native apps can drive navigation declaratively.

**Phase 8C closes the loop:** the SAME `UI::App` declaration that drives native navigation ALSO contributes web routes to an Amber router. Authors write the screen + web-controller map once; both targets consume it.

Today (post-8A + post-8B):

```crystal
# Web target — config/routes.cr (Amber-style, manual)
Amber::Server.configure do
  routes :web do
    get  "/",               SignInController, :index
    post "/sign_in/submit", SignInController, :submit
    # ... must enumerate every route by hand ...
  end
end

# Native target — separate UI::App declaration
class SpikeApp < UI::App
  initial_route :sign_in
  screen :sign_in, SignInController
  screen :todos,   TodosController
end
```

After 8C:

```crystal
# Single source — used by BOTH web and native
class SpikeApp < UI::App
  initial_route :sign_in
  screen :sign_in, SignInController,
         web_controller: SignInController,
         web_path: "/",
         web_actions: [
           UI::App::WebAction.new(verb: :get,  action: :index),
           UI::App::WebAction.new(verb: :post, action: :submit, path: "/sign_in/submit"),
         ]
  screen :todos, TodosController,
         web_controller: TodosController,
         web_path: "/todos"
end

# Web target — config/routes.cr
Amber::Server.configure do
  routes :web do
    UI::AmberIntegration.routes_for(SpikeApp)
    # Plus any other manual Amber routes the app needs.
  end
end

# Native target — unchanged
SpikeApp.launch_macos  # or launch_ios
```

The `routes_for(UI::App)` helper emits `get` / `post` / `put` / `patch` / `delete` calls per screen's `web_actions`, binding each to the screen's `web_controller` (an `Amber::Controller::Base` subclass — NOT the `UI::Controller` used for native dispatch).

In the spike, the native controller and the web controller happen to be the same class (`SignInController` extends `Amber::Controller::Base` AND has no `UI::Controller` heritage — Phase 8A's parallel-controllers architecture). Phase 8C's `web_controller:` kwarg makes the binding explicit so the macro never confuses the two roles.

---

## Environment assumptions

1. Phase 8B has merged. `UI::App` + `UI::Controller` + `UI::ActionDispatcher` + `UI::FormState` shipped. Tag: `phase-08b-pass-with-notes-2026-05-24`.
2. Phase 8A's `UI::ScreenHelpers` mixin still works as the rendering path on web.
3. `samples/phase-08-amber-spike/` is the proven web spike harness — used here as the test target.
4. The web app's controllers inherit `Amber::Controller::Base` (NOT `UI::Controller`). Phase 8C is about ROUTE registration, not controller-class unification.
5. **`UI::App` does NOT expose a compile-time `SCREENS` constant.** Its `@@screens` hash is populated at runtime by macro-generated `_bootstrap_screen_*` methods that an inheritance-time `macro inherited { macro finished { ... } }` enumerates. Phase 8C's macro must use a compatible mechanism — see Item 2.

---

## Scope — 3 items

### Item 1 — Extend `UI::App::ScreenRegistration` + `screen` macro with web route metadata

Add optional fields to the existing `ScreenRegistration` record (shipped in Phase 8B). The `web_controller` field carries an `Amber::Controller::Base` subclass — distinct from `controller_class` (which carries `UI::Controller.class` for native dispatch). The `controller_class` field becomes **nilable** so that web-only screens (no native side yet) can register cleanly without inventing a placeholder `UI::Controller` subclass.

```crystal
record ScreenRegistration,
  route_id : Symbol,
  controller_class : UI::Controller.class? = nil,    # NULLABILITY EXPANDED IN 8C
  screen_class : UI::Screen.class,
  # NEW IN 8C:
  web_controller : Amber::Controller::Base.class? = nil,
  web_path : String? = nil,                          # e.g. "/sign_in" or "/todos"
  web_actions : Array(NamedTuple(verb: Symbol, action: Symbol, path: String?)) = [] of NamedTuple(verb: Symbol, action: Symbol, path: String?)
```

`web_actions` entries are **NamedTuple literals**, not a Record type — Codex empirical testing showed NamedTuple literals iterate cleanly in macros while a `WebAction` Record would force `Call.named_args` AST extraction. No `UI::App::WebAction` type is shipped; the shape is documented in the brief and enforced by Crystal's NamedTuple type system at the macro-arg type.

Extend the `screen` macro. The positional `controller` argument becomes **optional** (default `nil`) so web-only screens are declarable without a UI::Controller placeholder:

```crystal
# Native-only screen (Phase 8B form, still works):
class SpikeApp < UI::App
  screen :detail, DetailController, screen_class: DetailScreen
end

# Web-only screen (new in 8C):
class SpikeApp < UI::App
  screen :sign_in,
         web_controller: SignInController,
         web_path: "/",
         web_actions: [
           {verb: :get,  action: :index},
           {verb: :post, action: :submit, path: "/sign_in/submit"},
         ]
end

# Dual-target screen (when consumer has both sides):
class SpikeApp < UI::App
  screen :todos, TodosController,
         web_controller: TodosController,
         web_path: "/todos"
end
```

**Macro signature:**

```crystal
macro screen(route_id, controller = nil, *, web_controller = nil, web_path = nil, web_actions = [] of Nil, screen_class = nil)
```

The kwargs are `*`-prefixed so all of `web_controller:`, `web_path:`, `web_actions:`, `screen_class:` must be passed by name (not positionally) — preserves Phase 8B's positional `screen :id, Controller` form while preventing accidental confusion with `web_controller`.

**Defaulting rules:**

- If `controller` is nil AND `web_controller` is nil AND `web_path` is nil AND `web_actions` is empty → ERROR. A registration must declare at least one side (native or web).
- If `web_path` is nil AND `web_actions` is empty → screen is native-only. `routes_for` emits nothing for this screen.
- If `web_path` is set AND `web_actions` is empty → default `web_actions` to `[{verb: :get, action: :index, path: web_path}]`. Convention shortcut for the common case.
- If `web_actions` is non-empty → each entry must carry its own `path:` OR `web_path` must be set (used as the default path). Compile-time check via macro `{% raise %}` if violated.
- If any `web_actions` entry is set OR `web_path` is set → `web_controller` MUST be set. Compile-time check via macro `{% raise %}` if violated.

**Native dispatch on web-only screen:**

`UI::ActionDispatcher#dispatch` on a route whose registration has `controller_class == nil` raises `UI::App::WebOnlyScreenError` (new exception subclass). Spec covers this path. This guards against a native build accidentally trying to dispatch into a screen that was never wired for native dispatch.

**Acceptance:**

- `UI::App::ScreenRegistration` carries the new fields (`controller_class` nilable, `web_controller`, `web_path`, `web_actions`) with the documented defaults.
- The `screen` macro accepts the new kwarg shape (`*`-prefixed kwargs) without breaking any Phase 8B caller. Phase 8B's `screen :foo, FooController` continues to compile.
- Specs cover: (a) native-only screen (Phase 8B form preserved), (b) web-only screen (no `controller` positional, just web kwargs), (c) dual-target screen (both), (d) screen with `web_path` only (auto `:get :index`), (e) missing `web_controller` macro-raise, (f) screen with neither native nor web declaration macro-raises, (g) native dispatch on web-only screen raises `WebOnlyScreenError`.

### Item 2 — `UI::AmberIntegration.routes_for(UI::App.class)` macro

`src/asset_pipeline/amber_integration.cr` already has `UI::ScreenHelpers` + `UI::ScreenContext::Web`. Phase 8C extends with a `UI::AmberIntegration.routes_for` macro that emits Amber router calls inside an Amber `routes :web do ... end` block.

**Mechanism — empirically verified in `codex-critique-1-brief-8c.md`:**

Phase 8B populates `UI::App`'s screen registry via runtime hash-writes in macro-generated methods. There is no compile-time `SCREENS` constant to walk. Phase 8C uses a **twin-emission** pattern from the extended `screen` macro: each `screen` call emits BOTH (a) a compile-time-named class method (the enumeration marker) AND (b) a same-named class-level macro (the body that emits `get` / `post` calls). `routes_for` walks the marker methods at compile time and emits calls to the same-named class macros. The class macros expand inside Amber's `routes :web do ... end` block, where `with router yield` makes Amber's `get` / `post` / `put` / `patch` / `delete` macros bind to the implicit receiver.

Concretely:

```crystal
# In UI::App, extending the Phase 8B screen macro:
macro screen(route_id, controller = nil, web_controller = nil, web_path = nil, web_actions = [] of Nil, screen_class = nil)
  # ... existing Phase 8B emissions (runtime @@screens write + _bootstrap_screen_* method) ...

  # NEW IN 8C — marker method, enumerated by routes_for at compile time.
  # Compile-time method emission is iOS-class-init-gap safe (no class-var defaults).
  def self._web_route_emit_{{route_id.id}} : Nil
    nil
  end

  # NEW IN 8C — class macro with the same name. routes_for emits
  # calls of the form `{{app}}._web_route_emit_<id>` — Crystal resolves
  # this to the macro (not the method) at macro-expansion time, and
  # the macro's body expands inside the consumer's `routes :web do .. end`
  # block, where Amber's get/post macros are the available DSL.
  {% if web_actions.empty? && web_path %}
    # Convention: web_path alone => GET at that path bound to :index.
    {% web_actions = [{verb: :get, action: :index, path: web_path}] %}
  {% end %}
  macro _web_route_emit_{{route_id.id}}
    {% for action in web_actions %}
      {% verb = action[:verb] %}
      {% action_name = action[:action] %}
      {% action_path = action[:path] || web_path %}
      {{verb.id}} {{action_path}}, {{web_controller}}, {{action_name}}
    {% end %}
  end
end

# In UI::AmberIntegration:
module UI::AmberIntegration
  macro routes_for(app_class)
    {% for method in app_class.resolve.class.methods %}
      {% if method.name.starts_with?("_web_route_emit_") %}
        {{app_class}}.{{method.name.id}}
      {% end %}
    {% end %}
  end
end
```

**`web_actions` shape is NamedTuple-literal, not a Record.** Codex empirical testing showed `Crystal::Macros::Call` ASTNodes (`WebAction.new(...)` calls) cannot be iterated field-by-field at macro time without `Call.named_args` extraction — adding engineering overhead. NamedTuple literals (`{verb: :get, action: :index, path: "/sign_in/submit"}`) iterate cleanly. The brief switches to NamedTuple form. Authors write:

```crystal
screen :sign_in,
       web_controller: SignInController,
       web_path: "/",
       web_actions: [
         {verb: :get,  action: :index},
         {verb: :post, action: :submit, path: "/sign_in/submit"},
       ]
```

**Acceptance:**

- Spike app's `config/routes.cr` replaces its manual `get`/`post` block with `UI::AmberIntegration.routes_for(SpikeApp)`.
- Browser GET + POST gates from Phase 8A still pass (same screenshot evidence + same Selenium proof).
- `crystal spec` baseline preserved.
- `routes_for` macro expands to a sequence of `{{app_class}}._web_route_emit_<id>` calls — one per registered screen with web metadata.
- When no screen has web metadata, `routes_for` expands to nothing (no error).

### Item 3 — Spike migration + browser regression proof

Update `samples/phase-08-amber-spike/`:

1. Add `class SpikeApp < UI::App` declaration as a **web-only screen registration** (the spike's `SignInController` extends `Amber::Controller::Base`, NOT `UI::Controller` — Item 1's nilable `controller_class` makes this legal):
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
2. Replace `config/routes.cr` manual route block with `UI::AmberIntegration.routes_for(SpikeApp)`:
   ```crystal
   Amber::Server.configure do
     pipeline :web do
       # ... existing pipes unchanged ...
     end

     routes :web do
       UI::AmberIntegration.routes_for(SpikeApp)
     end
   end
   ```
3. Rebuild (`crystal build src/spike_app.cr -o bin/spike`) + re-run the Phase 8A browser POST proof (`python browser_post_proof.py` driving Selenium against Chrome 149). Confirm same HTTP 200 + flash notice behavior.
4. New screenshot evidence: `samples/phase-08-amber-spike/findings-browser-after-routes-for.png` showing the routes-for-driven app behaves identically.

**Phase 8C does NOT touch the spike's `SignInController`.** It stays `< ApplicationController < Amber::Controller::Base`. The `UI::App` declaration is the only addition to the spike's `src/`. Native-app integration of the spike (a hypothetical `SpikeApp.launch_macos`) is OUT OF SCOPE; the macOS / iOS demonstration of the unified `UI::App` lives in Phase 8D's Voyager migration.

**Acceptance:** browser POST proof passes (same HTTP 200 + flash notice as Phase 8A baseline). `findings-browser-after-routes-for.png` captured. Spike's `config/routes.cr` is one line (the `routes_for` call) instead of per-route manual `get`/`post`.

---

## Codex protocol — NO EXCEPTIONS

Per-iteration Codex review at `handoff/phase-08c-codex-N.md`. No self-assessment.

Iteration boundaries:
- iter 1: Items 1 + 2 (extend ScreenRegistration + ship routes_for macro)
- iter 2: Item 3 (spike migration + browser regression proof)

---

## Acceptance you must meet

- `crystal spec` baseline preserved (1659/4/0/66 entering, 1659/4/0/66 or higher exiting — new specs allowed).
- Spike's `config/routes.cr` uses `UI::AmberIntegration.routes_for(SpikeApp)` (no manual `get`/`post` per route).
- Browser POST proof passes (regression check vs Phase 8A baseline).
- Codex critique-1 already committed at `phases/phase-08-ergonomic-mvc-api/codex-critique-1-brief-8c.md` (architect-side brief review with empirical macro-mechanism proof). The Implementer commits 2 additional per-iteration Codex reviews at `handoff/phase-08c-codex-N.md`.
- Voyager UNCHANGED.
- `grep -rE "voyager-(save-chain|interaction-proof)"` returns 0.

## Hard rules

- Forward commits only on `phase-08c-routes-for-app`.
- NO native side changes — Phase 8B's UI::App/Controller/Dispatcher stay. Item 1's expansion of `ScreenRegistration` is additive (existing fields preserved, new fields optional with sane defaults).
- NO new sentinels or design-token changes.
- NO macro file generation (Codex rejected in Phase 8A; same rule).
- Standard Claude co-author footer.
- **If the `routes_for` macro can't emit valid Amber router calls** against the real `Amber::DSL::Router` (Codex-1 empirically proved the mechanism against a minimal `record R do macro get ... end` shim — the Implementer verifies against the FULL Amber surface), STOP and escalate — do NOT introduce a runtime route-registration shim as a workaround. The compile-time macro IS the design. The escalation path is "back to architect for a brief revision" — not "improvise."

## Reporting

Write `handoff/phase-08c-implementer-report.md`. Return to architect with: branch HEAD, commit count, Codex verdicts, which routes_for Candidate was shipped, screenshot paths.

---

**Status: APPROVED v3 — Codex critique-1 (APPROVE_WITH_NOTES, empirical mechanism verification) folded in. Ready for Implementer dispatch on `phase-08c-routes-for-app`.**
