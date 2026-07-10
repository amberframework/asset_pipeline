# Phase 8 — Ergonomic Top-Level API + Amber Integration (revision 2)

**Status:** Design draft revision 2, post-Codex-REJECT salvage
**Date:** 2026-05-24
**Authored by:** Architect (Claude Opus 4.7)
**Critique trail:** `codex-critique-1.md` (rev 1 REJECT) → this redraft
**Memory directive:** [[design-amber-first-not-after]] — proven on a spike before locking abstractions.

---

## What changed from revision 1

Revision 1 designed a unified `UI::Controller` + `UI::Context` model that wrapped Amber's `HTTP::Server::Context`. Codex correctly rejected it — Amber's controller surface is far larger than the wrapper exposed, schema params don't live on the context, CSRF was wrong, and routing-by-convention can't satisfy real apps.

Revision 2 rejects unification at the controller level. Instead:

- **Web (Amber):** authors write normal `Amber::Controller::Base` subclasses. asset_pipeline contributes a single helper, `render_screen`, that converts a `UI::Screen` view tree into HTML and hands it to Amber's render pipeline. No wrapper, no shim, no routing convention.
- **Native (iOS / macOS):** authors write `UI::Controller` subclasses with the same action-name surface (`index`, `submit`, `create`, etc.). The native runtime dispatches `Button(action: :submit)` taps to the controller method.
- **Shared:** `UI::Screen` view-tree authoring (`build(context)`), `UI::View` widgets, `UI::DesignTokens` (Phase 6.12 closed).

The "parallel structure, not unification" insight means each platform's controller idioms stay native. Amber developers get Amber. Native developers get a controller class that fits the native event model. The single authoring surface is the SCREEN — not the controller.

---

## Architecture (parallel-controllers)

```
┌──────────────────────────────────────────────────────────────────┐
│                    SHARED — author writes once                   │
│                                                                  │
│  class TodosScreen < UI::Screen                                  │
│    def build(context : UI::ScreenContext) : UI::View              │
│      UI::VStack.new do |stack|                                   │
│        stack << UI::Label.new("Todos")                           │
│        stack << UI::Button.new("Add Todo", action: :create)      │
│      end                                                         │
│    end                                                           │
│  end                                                             │
└──────────────────────────────────────────────────────────────────┘
                            ▼
        ┌───────────────────┴───────────────────┐
        ▼                                       ▼
┌─────────────────────────────┐    ┌───────────────────────────────┐
│   WEB (Amber)                │    │   NATIVE (iOS / macOS)        │
│                              │    │                               │
│ class TodosController <      │    │ class TodosController <       │
│       Amber::Controller::Base│    │       UI::Controller          │
│   include UI::ScreenHelpers  │    │                               │
│                              │    │   def index(ctx)              │
│   def index                  │    │     render_current_screen     │
│     @todos = TodoStore.all   │    │   end                         │
│     render_screen TodosScreen│    │                               │
│   end                        │    │   def create(ctx)             │
│                              │    │     title = ctx.params["title"]│
│   def create                 │    │     TodoStore.add(ctx, title) │
│     title = params["title"]  │    │     navigate_to :todos        │
│     TodoStore.add(title)     │    │   end                         │
│     redirect_to "/todos"     │    │ end                           │
│   end                        │    │                               │
│ end                          │    │                               │
│                              │    │                               │
│ # config/routes.cr            │    │ # app definition              │
│ get  "/todos",        TodosController, :index        │            │
│ post "/todos/create", TodosController, :create       │            │
│                              │    │                               │
│ Amber handles: layouts, CSRF,│    │ class VoyagerApp < UI::App    │
│ params, schema validation,   │    │   initial_route :todos        │
│ named routes, redirects,     │    │   screen :todos, TodosController│
│ json/xml responders, halt!,  │    │ end                           │
│ before/after callbacks,      │    │                               │
│ asset helpers, etc.          │    │ UI::App.launch_ios            │
│                              │    │ (Phase 6.10/6.11/6.12 runtime)│
└─────────────────────────────┘    └───────────────────────────────┘
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│              SHARED — UI::Web::Renderer (Phase 6.10)             │
│           Turns the UI::View tree into HTML, calls into          │
│           Components::Elements for the actual element output.    │
│              No layout / head / asset handling here.             │
│              Web layout = Amber's layout. Native layout = OS.    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Public API surface

### `UI::Screen` — authoring, shared across web + native

```crystal
abstract class UI::Screen
  # Subclass implements `build(context)`. `context` is a
  # UI::ScreenContext — a NEUTRAL interface that exposes only what a
  # screen-author needs to read at render time:
  #
  #   context.params      → Hash(String, String) | UI::FormState
  #   context.session     → web: Amber session; native: in-process Hash
  #   context.flash       → web: Amber flash; native: in-process Hash
  #   context.design_tokens → Tokens (Phase 6.12 system-accent)
  #
  # The context does NOT expose request/response/csrf_token/cookies —
  # those are platform-specific and belong in the controller, not the
  # screen.
  abstract def build(context : UI::ScreenContext) : UI::View
end
```

### `UI::ScreenContext` — minimal neutral interface

```crystal
abstract class UI::ScreenContext
  abstract def params : Hash(String, String) | UI::FormState
  abstract def session : UI::Session  # opaque storage interface
  abstract def flash   : UI::Flash    # opaque flash interface
  abstract def design_tokens : UI::DesignTokens::Tokens
end

# Web: built by `render_screen` helper, delegates to Amber controller.
class UI::ScreenContext::Web < UI::ScreenContext
  def initialize(@params : Hash(String, String),
                 @session : UI::Session,
                 @flash : UI::Flash,
                 @design_tokens : UI::DesignTokens::Tokens)
  end
  # accessors omitted for brevity
end

# Native: built by ActionDispatcher when a Button tap fires.
class UI::ScreenContext::Native < UI::ScreenContext
  def initialize(@form_state : UI::FormState,
                 @session : UI::Session,
                 @flash : UI::Flash,
                 @design_tokens : UI::DesignTokens::Tokens,
                 @navigation : UI::NavigationCoordinator)
  end
  # navigation accessor is NATIVE-only — not on the abstract base.
  def navigation : UI::NavigationCoordinator
    @navigation
  end
end
```

### Amber integration: a single mixin

```crystal
module UI::ScreenHelpers
  # Render a UI::Screen as HTML inside the current Amber controller's
  # render pipeline. Uses Amber's layout + render() helper — this is
  # JUST a view template; Amber handles the rest.
  #
  # Usage:
  #   class TodosController < Amber::Controller::Base
  #     include UI::ScreenHelpers
  #     def index
  #       render_screen TodosScreen
  #     end
  #   end
  def render_screen(screen_class : UI::Screen.class, **locals) : String
    screen = screen_class.new
    ctx = UI::ScreenContext::Web.new(
      params: params_to_hash,
      session: UI::Session::AmberAdapter.new(session),
      flash: UI::Flash::AmberAdapter.new(flash),
      design_tokens: app_design_tokens,
      **locals,
    )
    view_tree = screen.build(ctx)
    html_body = UI::Web::Renderer.new.render(view_tree)
    # render() is Amber::Controller::Helpers::Render; respects LAYOUT
    render(html: html_body)
  end

  private def params_to_hash : Hash(String, String)
    h = {} of String => String
    params.each { |k, v| h[k.to_s] = v.to_s }
    h
  end

  # Application-wide design tokens (system accent by default per Phase 6.12;
  # apps override via `UI::AmberConfig.design_tokens = ...`).
  private def app_design_tokens : UI::DesignTokens::Tokens
    UI::AmberConfig.design_tokens
  end
end

# Module-level config — apps set this once at boot in config/initializers.cr
module UI::AmberConfig
  class_property design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default
end
```

That's the ENTIRE Amber integration surface. ~40 lines of helper. No wrappers, no convention routing, no CSRF re-implementation, no schema-params re-implementation.

**What Amber provides that we use directly:** layouts (`LAYOUT = "application.ecr"`), `render(html:)` helper, params, session, flash, CSRF (the layout's `<form>` includes `csrf_tag`), schema-validated params (if author uses Amber's schema), redirects, named routes, before/after callbacks, all responders, halt!, all helpers — all of it.

**What asset_pipeline contributes:** `render_screen(TodosScreen)` that produces a string of HTML to render. The Crystal-class-based view tree replaces ERB templates as the authoring layer.

### Native controllers: parallel, not bridged

```crystal
abstract class UI::Controller
  # Action methods are public methods taking a single ctx argument and
  # returning UI::ActionResult.
  protected def navigate_to(route_id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String) : UI::ActionResult
    UI::ActionResult::Navigate.new(route_id, params)
  end

  protected def pop_navigation : UI::ActionResult
    UI::ActionResult::Pop.new
  end

  protected def render_current_screen : UI::ActionResult
    UI::ActionResult::Rerender.new
  end

  protected def replace_root(route_id : Symbol, params : Hash(Symbol, String) = {} of Symbol => String) : UI::ActionResult
    UI::ActionResult::ReplaceRoot.new(route_id, params)
  end

  # Filters (analog of Amber's before_action callbacks).
  macro before_action(method_name)
    @@_before_actions << ->(ctx : UI::ScreenContext::Native) {
      new.{{method_name.id}}(ctx)
    }
  end
end

abstract class UI::App
  macro screen(route_id, controller, screen_class = nil)
    # screen_class defaults to NameController -> NameScreen
    SCREENS[{{route_id}}] = UI::ScreenRegistration.new(
      route_id: {{route_id}}, controller: {{controller}},
      screen_class: {{screen_class || (controller.stringify.gsub(/Controller$/, "Screen").id)}},
    )
  end

  macro initial_route(route_id)
    class_getter initial_route_id : Symbol = {{route_id}}
  end

  SCREENS = {} of Symbol => UI::ScreenRegistration

  # Platform-conditional launchers (compile-time, no runtime dispatch overhead)
  {% if flag?(:ios) %}
    def self.launch_ios; ...; end
  {% elsif flag?(:macos) %}
    def self.launch_macos; ...; end
  {% end %}
end
```

### UI::FormState — controlled form state

(Per Codex finding: SwiftUI text fields store values in `TextStorage`/`Binding`; we can't DOM-scrape at tap-time.)

```crystal
class UI::FormState
  # A per-screen registry of field name → current value, populated by
  # input on_change callbacks. The active screen has ONE FormState
  # instance; Button taps read from it.
  getter values : Hash(String, String) = {} of String => String

  # Inputs register via this method (called inside Crystal's TextField
  # constructor when the view tree is built).
  def bind(name : String, initial : String = "")
    @values[name] = initial unless @values.has_key?(name)
  end

  def update(name : String, value : String) : Nil
    @values[name] = value
  end

  def [](name : String) : String
    @values[name]? || ""
  end

  def []?(name : String) : String?
    @values[name]?
  end
end
```

The native renderer wires each TextField's `on_change` callback to call `screen_context.form_state.update(name, new_value)`. When a `Button(action: :submit)` fires, the ActionDispatcher calls the controller method with a context whose `params` IS the FormState (or a snapshot of it).

On web, the same TextField name maps to an HTML `<input name="...">`; Amber receives the values via standard form POST → `params["name"]`. No FormState needed on web; Amber's params handling already covers it.

---

## Action results (web vs native)

| ActionResult | Native behavior | Web behavior |
|---|---|---|
| `Navigate(route_id, params)` | `coord.push(Route.new(route_id, params))` | controller calls `redirect_to(route_for(route_id, params))` |
| `Pop` | `coord.pop` | controller calls `redirect_back fallback: "/"` |
| `Rerender` | `coord.republish(current_route)` | controller calls `render_screen(current_screen_class)` |
| `ReplaceRoot(route_id, params)` | `coord.replace_root(...)` | controller calls `redirect_to(route_for(...))` |
| `RenderInline(view_tree)` | host swaps content | controller calls `render html: UI::Web::Renderer.render(view_tree)` |

The ActionResult IS the native side's contract. On web, Amber controllers don't return ActionResult — they call Amber's render/redirect helpers directly. Same conceptual outcomes, different idioms per platform.

---

## What's NOT in this design (intentionally)

- **No unified Controller class.** Web and native controllers are separate inheritance trees with overlapping naming conventions. This was Codex's call.
- **No convention routing.** Amber's routes file is the source of truth on web. UI::App's `screen` macros are the source of truth on native. Authors write routes/screens explicitly.
- **No UI::Response model.** On web, Amber's existing render/redirect/responder helpers are the response model. On native, `UI::ActionResult` is the contract.
- **No wrapping of HTTP::Server::Context.** Authors work with Amber's context directly on web. The screen context is a NARROW interface for the screen author, not a context wrapper.
- **No re-implementation of CSRF / schema params / multipart / file uploads.** Amber handles all of those; asset_pipeline just renders the views.

---

## Spike scope (Phase 8 spike — code, not design)

Before Phase 8A is briefed, the architect (me) runs a code spike:

1. Create `samples/phase-08-amber-spike/` with a real minimal Amber app:
   - `shard.yml` requires `amber` + path-includes `asset_pipeline`
   - `config/routes.cr` with one resource (sign-in)
   - `config/application.cr` standard Amber bootstrap
   - `src/views/layouts/application.ecr` (Amber's layout convention)
   - `src/controllers/sign_in_controller.cr` using `include UI::ScreenHelpers + render_screen SignInScreen`
   - `src/screens/sign_in_screen.cr` — `UI::Screen` subclass building the form
2. Compile + run: `crystal build src/server.cr -o bin/spike` (or `amber watch`)
3. Hit `http://localhost:3000/sign_in` in a browser
4. Submit the form → controller reads params → flashes error or redirects
5. Document at `phase-08-spike-findings.md`:
   - What worked
   - What broke
   - What the design's `render_screen` helper actually needed to do
   - Whether `UI::Web::Renderer` produces HTML that Amber's layout system accepts
   - What CSRF token handling looks like in practice
   - Any gotchas (path conflicts, asset pipeline interactions, etc.)

The spike findings drive Phase 8 brief authoring. If the spike succeeds: Phase 8A brief written from real evidence. If the spike surfaces deep blockers: design revises before any implementer dispatch.

---

## Phase split (revised)

Per Codex's "Amber spike first" directive:

| Sub-phase | Scope | Deliverable |
|---|---|---|
| **8-Spike (architect-only)** | Minimal Amber app using render_screen helper | Findings doc + viable spike repo |
| **8A — render_screen + Amber integration** | UI::ScreenHelpers mixin, UI::AmberConfig, UI::ScreenContext::Web, polish to UI::Web::Renderer if spike surfaces gaps. UI::FormState (web side — wraps params for screen authoring uniformity). | Shippable Amber integration. Tested by an Amber web demo. |
| **8B — UI::App + UI::Controller (native)** | UI::App with screen macros, UI::Controller with action methods, UI::ActionResult, ActionDispatcher, UI::FormState (native side — TextField on_change wiring). | Native demo app using new API on iOS + macOS. |
| **8C — UI::Screen authoring + FormState integration** | Pure UI::Screen class with the build() convention. Both web and native demos use the same screen classes. UI::FormState fully wired native-side. | Shared screen classes proven on both targets. |
| **8D — Voyager migration** | Migrate Voyager from screens-as-module-functions + bespoke bridges to UI::App + UI::Screen + UI::Controller. Drop static_site.cr. | Voyager as a real Amber app + native iOS/macOS hosts. |
| **8E — Docs + skill** | `building-ui-with-amber` skill, CLAUDE.md update, owner-facing tutorial. | Documented public API. |

Each sub-phase is 2-5 days. 8-Spike is 1 day of architect exploration.

---

## Open questions (much narrower than rev 1)

### Q1: Does Amber accept arbitrary HTML body from a controller, or does it expect a template path?

Per `home_controller.cr` line 28-32: `render("index.ecr")` is the common path. Need to verify `render(html: "<...>")` works as expected (it's listed in Amber's `Helpers::Render` per controller/base.cr line 11). The spike must prove this.

### Q2: How does the `<form>` POST cycle work with CSRF?

Amber's CSRF pipe injects a `_csrf` field requirement. Forms must include the CSRF token. The screen builder needs to know the current request's CSRF token to render the hidden input. Either:
- `UI::ScreenContext::Web#csrf_tag : String` returns the `<input type="hidden" name="_csrf" value="...">` markup
- OR `UI::Form` view widget automatically injects the CSRF tag on web (skipped on native)

Recommend option B — `UI::Form` knows the platform; on web it emits the CSRF tag from the context.

### Q3: How do we handle FormState on web?

On web, FormState isn't a "state" — it's just what the form posted. The `render_screen` helper translates the current `params` into a `Hash(String, String)` and that's what TextField views read for their `initial:` value (so error-redisplay works after a failed submit). This makes FormState a NATIVE-ONLY concept and the web side uses params directly.

### Q4: Does the spike use Voyager's existing screens or a fresh tiny app?

Fresh tiny app for the spike (one screen, one controller, two actions: GET + POST). Voyager migration happens in Phase 8D, after the integration is proven minimal.

---

## Architect's next concrete actions

1. **Run the spike** at `samples/phase-08-amber-spike/` (~2 hours of focused work).
2. **Document findings** at `samples/phase-08-amber-spike/findings.md`.
3. **Codex-critique findings** — does the salvage architecture survive contact with reality?
4. **If APPROVE:** author Phase 8A brief (`render_screen` integration), Codex-critique to APPROVE, dispatch.
5. **If REVISE:** iterate the design based on spike evidence before any implementer dispatch.

Phase 8 design v3 (if needed) comes from spike evidence, not speculation.
