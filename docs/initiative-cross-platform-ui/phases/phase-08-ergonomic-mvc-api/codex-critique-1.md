# Phase 8 Design — Codex Antagonist Critique Pass 1

**Date:** 2026-05-24
**Reviewer:** `codex exec` (codex-cli 0.130.0)
**Subject:** `docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/design.md` revision 1

## Verdict: REJECT

> "The top-level API is directionally useful, but the Amber adapter, routing contract, and native form model are not coherent enough to build against."

## Findings (verbatim, organized)

### Critical architectural defects

1. **Amber integration leaks (OPEN).** `UI::Context::Web` exposes only params/session/flash/request/CSRF. Amber's real `Controller::Base` has 13 helper modules (CSRF, Redirect, Render, Responders, Route, I18n, TagHelpers, TextHelpers, NumberHelpers, FormHelpers, URLHelpers, AssetHelpers, MarkdownHelper) + 17 delegated methods (cookies, format, halt!, route, response, websocket?, etc.). The wrapper is a sample, not a translation layer.

2. **Schema params claim false (OPEN).** Amber schema integration lives on the controller instance and swaps `params` only after request validation state exists; raw `HTTP::Server::Context` params are not that surface.

3. **CSRF wrong (OPEN).** `session["csrf_token"]?` does not match Amber's CSRF model: `_csrf` field, `csrf.token`, masked tokens via `Amber::Pipe::CSRF`. Real POST flows would fail.

4. **Routing convention too narrow (OPEN).** `index/show → GET, others → POST` breaks REST, nested resources (`/users/:user_id/todos`), named routes, route constraints, PUT/PATCH/DELETE, route helper generation. Amber's DSL has explicit verbs, resources, constraints, names, namespace, REST macros.

5. **Uploads / multipart missing (OPEN).** `UI::ParamsHash` modeled as scalar `String`. Amber supports multipart bodies + uploaded files via `Amber::Router::Parsers::Multipart`. File upload cannot be an afterthought.

6. **JSON / AJAX endpoints not modeled (OPEN).** `ActionResult` is navigate / pop / rerender / redirect / render_inline. Missing: status codes, headers, content type, 204 No Content, JSON body, validation errors, content negotiation, `halt!`, response close.

7. **Native form dispatch incoherent (OPEN).** Draft says child input values are collected at tap-time. Reality: SwiftUI text fields store live values in `TextStorage` / `Binding`; Crystal receives values through `on_change`, not by walking children later. Needs controlled form state / field registry, not DOM-style scraping.

### Process / scoping defects

8. **Q1-Q7 all load-bearing (OPEN).** Treated as "open questions" but actually architectural decisions that change the spec when answered differently.

9. **Phase split hides dependencies (OPEN).** 8A "native only" bakes controller / action / context API before Amber proves the constraints. 8B will force API churn.

10. **Migration order risky (OPEN).** Adding Amber at Step 6 is too late — Voyager built on assumptions Amber will invalidate.

### Missing load-bearing surface

Explicit route DSL / metadata; request / response abstraction; cookies / headers / status / content negotiation; files; CSRF tag/metatag; named route helpers; layout / head / assets contract; form state registry; validation / error model; controller filters; per-request state isolation; thread-safety rules.

## Codex's minimal salvage path

> "Redesign Phase 8 around explicit route declarations plus optional conventions, an Amber-controller-backed adapter, a real `UI::Response` model, and controlled form state. Then split implementation."

## Architect actions taken

1. Acknowledge REJECT honestly to owner.
2. Propose salvage approach centered on Codex's path.
3. Get owner approval on direction before iterating design.
4. Defer Phase 8 dispatch until design APPROVE.

## Salvage architecture sketch (for owner review)

| Original (rejected) | Salvage |
|---|---|
| `UI::Controller` is a new class, wrapped to Amber | `UI::Controller` INHERITS from `Amber::Controller::Base` on web; provides the native action shim on native targets. Authors get Amber's full surface. |
| `UI::Context::Web` re-implements params/flash/etc. | `UI::Context::Web` IS the Amber controller's context (delegation, not wrapping). |
| Convention-derived routes | Explicit Rails-style route DSL: `routes do; get "/todos", to: "todos#index"; resources :todos; end`. Conventions exist as helpers. |
| ActionResult is navigate/pop/rerender/redirect/render_inline | `UI::Response` is the primary return type (status, headers, body, content type). Navigate/etc. are helpers that produce a Response. |
| Form values collected at tap time (DOM-scrape style) | `UI::FormState` lives in screen context. Inputs update FormState via `on_change` (proven Phase 6.11 reactive pattern). Actions read from FormState. |
| Phase 8A native first, 8B Amber later | **Amber integration spike FIRST** (Phase 8A'), prove the surface against a real Amber app, THEN design native to conform. Voyager migration happens last. |

## Lesson saved to memory

`[[design-amber-first-not-after]]` — when designing an integration with an existing framework, prove the integration on a minimal spike BEFORE designing the abstractions that will sit on top. Designing native-first then bridging to Amber would have baked assumptions Amber invalidates.
