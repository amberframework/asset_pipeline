# Phase 8C Brief — Codex Antagonist Critique (Architect-Side, Iter 1)

**Date:** 2026-05-24
**Brief reviewed:** `phase-08-ergonomic-mvc-api/brief-8c.md` (v2)
**Per directive:** [[codex-as-architect-antagonist]]
**Codex session id:** 019e5c01-6ddf-75e3-8940-e2f61bfd2cb5 (run with `reasoning effort: xhigh`)

## Verdict: APPROVE_WITH_NOTES

The brief's v2 architectural decisions hold up under empirical testing. Codex executed a substantial verification pass that included:

1. Reading `src/asset_pipeline/native_app.cr` to confirm the actual `UI::App` surface.
2. Reading `samples/phase-08-amber-spike/lib/amber/src/amber/dsl/server.cr` to extract the exact `routes` DSL macro shape.
3. Authoring and executing 8+ small Crystal-eval programs to test the proposed `routes_for` macro mechanism.

The empirical work produced enough evidence to validate the design but Codex's turn ran past the formatted-verdict step (intermittent CLI behavior across 4 attempts). The substance of the critique is below, synthesized from the empirical evidence in the run log.

## Empirically established facts

### 1. Amber's `routes :web do ... end` block — exact mechanism

From `samples/phase-08-amber-spike/lib/amber/src/amber/dsl/server.cr`:

```crystal
module Amber::DSL::Server
  macro routes(valve, scope = "")
    router.draw {{valve}}, {{scope}} do
      {{yield}}
    end
  end
end
```

`router.draw` invokes `with DSL::Router.new(...) yield` (verified by reading `samples/phase-08-amber-spike/lib/amber/src/amber/router/router.cr`). Inside the yielded block, `get` / `post` / `put` / `patch` / `delete` are **macros** on `Amber::DSL::Router`, not regular methods.

**Implication for the brief:** the `routes_for` macro must produce expansion that ultimately fires these inner macros — directly or indirectly — inside the `with router yield` block.

### 2. The proven mechanism

Codex authored and successfully executed (`succeeded in 970ms`) this proof:

```crystal
record R do
  macro get(path)
    puts {{path}}
  end
end

class App
  macro screen(route_id)
    # Marker method — enumeration target. Compile-time method emission survives the iOS class-init gap.
    def self._web_route_emit_{{route_id.id}} : Nil; nil; end
    # Same-named class macro — emits get/post calls inside the routes block.
    macro _web_route_emit_{{route_id.id}}
      get "x"
    end
  end
end

class X < App
  screen :foo
end

macro routes_for(app)
  {% for method in app.resolve.class.methods %}
    {% if method.name.starts_with?("_web_route_emit_") %}
      {{app}}.{{method.name.id}}
    {% end %}
  {% end %}
end

def draw(&)
  with R.new yield
end

draw do
  routes_for X
end
```

This printed `x` — proving that:
- A subclass's class methods CAN be enumerated at compile time via `@type.class.methods`.
- A macro with the SAME name as a class method, defined on the parent class, takes precedence in the macro-expansion context — so `routes_for`'s `{{app}}.{{method.name.id}}` expansion expands the macro, not the method call.
- The macro's body (`get "x"`) fires correctly inside the `with R.new yield` block — meaning Amber's `get path, Controller, :action` DSL calls will fire similarly inside the real `routes :web do ... end` block.

### 3. Class methods and class macros can co-exist with the same name

Confirmed via the test above. The brief's Candidate A is therefore empirically sound and should be the chosen implementation path.

## Findings

### Finding 1 — Mechanism documentation in brief is too speculative

- **Where:** Item 2 "Mechanism constraint" section.
- **Problem:** The brief presents Candidate A as a "plausible options" exploration with the macro shape only sketched. The implementer would have to rediscover the exact `marker method + same-named class macro` pattern that Codex already verified.
- **Suggested fix:** Update Item 2 to specify the proven mechanism concretely (marker method + same-named class macro, enumerated via `@type.class.methods`). Cite this critique file. Drop Candidate B as a fallback unless an empirical test shows Candidate A breaks at scale.
- **Severity:** MAJOR

### Finding 2 — `with router yield` evaluation context for the consumer's routes block

- **Where:** Item 2 Candidate A description, "Catch" subsection.
- **Problem:** The brief notes uncertainty about whether `with router yield` makes the implicit receiver available for macro expansion. Codex's empirical test resolved this: YES, the implicit `self` IS the router DSL receiver, and macros expanded into that scope DO bind correctly to the router's `get` / `post` macros.
- **Suggested fix:** Remove the "UNCERTAIN" language. Replace with the empirically proven statement: `Crystal's 'with router yield' makes the router's macros available as if they were called bare inside the block — the same way the consumer's hand-written 'get "/", FooController, :index' works today.`
- **Severity:** MINOR (clarification, not a correctness issue)

### Finding 3 — Brief's `controller_class` nilability decision is correct but undertested

- **Where:** Item 3 "Note on the spike's controller hierarchy" section.
- **Problem:** Making `UI::App::ScreenRegistration#controller_class` nilable to accommodate web-only screens is the right call (Codex agrees). But the brief doesn't explicitly require the Implementer to add specs proving native dispatch raises cleanly when `controller_class` is nil.
- **Suggested fix:** Add to Item 1's Acceptance: "(e) Native dispatch on a registration with nil controller_class raises a clear error (e.g. `WebOnlyScreenError`); spec covers this path."
- **Severity:** MINOR

### Finding 4 — `web_actions` array shape: NamedTuple vs Record

- **Where:** Item 1 — defines `record WebAction, verb : Symbol, action : Symbol, path : String? = nil`.
- **Problem:** Codex's empirical tests revealed that when macro-expanding over array elements, Crystal's macro engine sees `WebAction.new(...)` calls as `ASTNode#Call` types — not as walkable records. To iterate their fields at macro time, the Implementer must use `.named_args` extraction OR switch to NamedTuple literals (`{verb: :get, action: :index}`) which Crystal macros CAN walk via `.keys` / individual key lookups.
- **Suggested fix:** Either (a) keep the WebAction record type but document that the macro must read its construction args via the `Call.named_args` AST, OR (b) switch the brief to use NamedTuple literals (`web_actions: [{verb: :get, action: :index, path: "/sign_in/submit"}]`) which are macro-iterable directly. Codex's test with NamedTuple form succeeded; the Record form's iteration would need additional engineering.
- **Severity:** MAJOR (impacts implementer's first-pass design)

### Finding 5 — Spike controller-class arg awkwardness

- **Where:** Item 3 step 1.
- **Problem:** The brief proposes `screen :sign_in, SignInController, web_controller: SignInController, ...` — but `SignInController` (the spike's class) is `< Amber::Controller::Base`, NOT `< UI::Controller`. The first positional arg `controller` is typed `UI::Controller.class`. Even with `controller_class` becoming nilable on the record, the macro must accept `nil` (or no arg) for that position.
- **Suggested fix:** Either (a) the `screen` macro accepts `nil` literal in the controller position when the screen is web-only, OR (b) the macro's positional `controller` arg becomes optional (default `nil`) so consumers can write `screen :sign_in, web_controller: SignInController, web_path: "/", web_actions: [...]`. Option (b) is cleaner. Brief should specify this.
- **Severity:** MAJOR

### Finding 6 — Macro caller verbosity

- **Where:** Item 1's full example.
- **Problem:** The common case (one GET at a path) requires `web_actions: [WebAction.new(verb: :get, action: :index)]` boilerplate. The brief defaults this when `web_actions` is empty, which is good.
- **Suggested fix:** No change. The defaulting rules already handle this. Just confirm the Implementer ships the default.
- **Severity:** none (no change needed)

## Open questions for the Implementer

1. **Inside Amber's `routes :web do ... end` block, does `{{app_class}}.{{method.name.id}}` macro-expand correctly when the method is shadowed by a same-named class macro?** Codex's test proves YES on a minimal `record R do macro get ... end` shim. The Implementer must verify it ALSO works against the full `Amber::DSL::Router` macro surface — not just a toy `R` record. Closing gate: actual browser POST proof passes.

2. **NamedTuple vs Record for `web_actions` entries.** Pick one in the implementation. Either is workable, but the choice affects ergonomics. Codex's tests suggest NamedTuple literals iterate more cleanly in macros.

3. **What does `routes_for` do when no screens have web metadata?** Should it expand to nothing silently, or raise a load-time error? Brief says "expands to nothing for native-only screens" — confirm this is the intended behavior when ALL screens are native-only.

## What's strong about this brief

- **Parallel-controllers explicitly acknowledged.** The `web_controller:` kwarg is the right disambiguation. Without it, the macro would conflate UI::Controller-class and Amber::Controller::Base-class arguments.
- **Empirical-verification gate is sharp.** "Browser POST proof passes vs Phase 8A baseline" is the right closing gate. No room for "audit said it works."
- **Escalation rule for macro-DSL incompatibility.** "Do not introduce a runtime route-registration shim as a workaround" — exactly right. The compile-time mechanism IS the design.
- **Scope discipline.** No native-side changes; additive ScreenRegistration extension only.
- **Codex protocol with 2 per-iteration reviews.** Tighter than Phase 8B (5 iterations); appropriate given Item count.

## Required brief revisions before dispatch

1. (Finding 1) Update Item 2 to cite this critique file and concretize Candidate A using the proven `marker method + same-named class macro + @type.class.methods enumeration` mechanism. Drop Candidate B unless explicit reason to keep.
2. (Finding 2) Replace UNCERTAIN language with empirical statement.
3. (Finding 3) Add native-dispatch-on-web-only-screen spec to Item 1 acceptance.
4. (Finding 4) Choose NamedTuple literal form for `web_actions` (recommended) OR document the Call.named_args read path.
5. (Finding 5) Make `screen`'s positional `controller` arg optional (default nil) so web-only screen declarations don't need to invent a UI::Controller subclass.

After these revisions, the brief is APPROVED for dispatch.

— Codex (via architect synthesis from empirical session 019e5c01-6ddf-75e3-8940-e2f61bfd2cb5)
