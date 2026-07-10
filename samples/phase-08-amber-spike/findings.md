# Phase 8 Amber Spike — Findings

**Date:** 2026-05-24
**Spike location:** `samples/phase-08-amber-spike/`
**Spike duration:** ~1 hour focused implementation + curl validation
**Verdict:** **DESIGN v2 ARCHITECTURE WORKS** (with specific API gaps to address in Phase 8A).

---

## Spike harness

A minimal Amber 1.4.1 app with:

- `shard.yml` requires `amber` + `path: ../..` for asset_pipeline.
- `config/application.cr` requires application + controller + screen + routes.
- `config/routes.cr` with web pipeline (Error/Logger/Session/Flash/CSRF) and two routes (`GET /` + `POST /sign_in/submit`).
- `ApplicationController < Amber::Controller::Base` includes the prototype `UI::ScreenHelpers` mixin + sets `LAYOUT = "application.ecr"`.
- `SignInController < ApplicationController` with `index` + `submit` actions.
- `SignInScreen < UI::Screen` building a VStack with Label + TextField + SecureField + Button + conditional flash labels.
- `application.ecr` layout with `csrf_metatag` in `<head>`.
- `sign_in/index.ecr` shim template — single line `<%= @screen_html %>`.
- Prototype `lib/asset_pipeline_amber_helpers.cr` defining `UI::ScreenContext` + `UI::ScreenHelpers` + `UI::AmberConfig` + base `UI::Screen` class.

Spike was launched via `bin/spike` (Amber dev server on localhost:3000) and exercised via curl with session cookie + extracted CSRF token.

---

## Empirical proofs (PASS)

| Test | Result |
|---|---|
| `shards install` (amber + path-included asset_pipeline) | PASS — clean resolution |
| `crystal build src/spike_app.cr` | PASS — 7.9MB binary, only warnings (Crystal stdlib deprecation) |
| `bin/spike` server boot | PASS — Amber 1.4.1 listening on :3000 |
| `GET /` | PASS — HTTP 200, full layout-wrapped HTML, CSRF meta in head |
| Controller `compute_screen_html` + `render("index.ecr")` | PASS — shim template echoes the computed HTML, layout wraps it |
| `UI::Screen#build(context)` → `UI::View` tree | PASS — produces a proper view tree |
| `UI::Web::Renderer.new.render(view_tree)` → HTML | PASS — emits flex VStack, `<input type="text">`, `<input type="password">`, `<button>` |
| `POST /sign_in/submit` with `_csrf` + form fields | PASS — controller receives params, flashes error/notice |
| Flash persistence across re-render | PASS — flash[:error] / flash[:notice] visible in subsequent render |
| Amber session cookie + CSRF flow | PASS — session.amber cookie set, `csrf.token` stored in session, validated on POST |

The architecture in design v2 is **viable**. Amber stays Amber, asset_pipeline contributes a screen renderer and a thin helper.

---

## Spike findings to address in Phase 8A

### Finding #1 — `UI::VStack.new` doesn't take a block

The design v2 author code samples used `UI::VStack.new(...) do |stack| ... end`. The real API is `stack = UI::VStack.new(...)` + `stack << child`.

**Implication:** design v2 samples need to be rewritten to match real API. Phase 8A's brief should explicitly use the `var << child` pattern OR Phase 8A could add `.new(...) { |stack| ... }` block support as a usability enhancement.

### Finding #2 — `UI::TextField.new` has no `initial:` kwarg

API is `UI::TextField.new(placeholder = "")`. Pre-populating the field requires `tf = UI::TextField.new(...); tf.text = initial_value`.

**Implication:** for form re-display after failed submit (a common pattern), this is verbose. Phase 8A should add `initial:` kwarg to TextField + SecureField constructors so the pattern collapses to one line.

### Finding #3 (CRITICAL) — `render(html:)` does NOT exist in Amber

Codex flagged this as Q1 in the design v2 doc. The spike confirms: Amber's `render` is a MACRO that requires a `template:` or `partial:` parameter; there is no `html:` overload. The macro expands at compile time to an ECR template lookup.

**Workaround the spike used:** a shim `sign_in/index.ecr` template containing just `<%= @screen_html %>`, with the controller setting `@screen_html` via `compute_screen_html` before calling `render("index.ecr")`.

**Implication for Phase 8A:** the integration helper signature `render_screen` cannot be a thin alias for Amber's `render(html:)`. Options:
- **A:** Ship one shim ECR per controller. Boilerplate per controller, but explicit.
- **B:** Auto-generate the shim template via a macro that the controller mixes in.
- **C:** Bypass `render` entirely and write to `response.print(html)` + manually wrap layout via a separate helper. Loses Amber's layout convention.

Recommend **B** (macro auto-generates a shim) — minimal boilerplate, preserves Amber's layout system, single source of truth for the shim path.

### Finding #4 — `<%# %>` ECR comments don't work

Crystal's ECR doesn't support `<%# ... %>` comment syntax (or the spike's instance of it broke the parser). Use HTML comments (`<!-- -->`) inside ECR or strip comments entirely.

**Implication for Phase 8A:** docs + templates the framework ships should avoid `<%# %>`. Use `<!-- -->` for visible comments or no comment at all.

### Finding #5 (MAJOR ARCHITECTURAL GAP) — UI::Form widget is load-bearing

The spike's `<form>` is MISSING from the rendered output. The screen author wrote a sequence of TextField + SecureField + Button but the web renderer didn't wrap them in a `<form>`. For the POST test to work via curl, I had to construct the form-encoded body manually with `_csrf=...` + `email=...` + `password=...`. A browser submit from the rendered page would FAIL because:

1. There's no `<form action="/sign_in/submit" method="POST">` wrapper.
2. There's no `<input type="hidden" name="_csrf" value="...">` injection.
3. The TextField + SecureField inputs have no `name="email"` / `name="password"` attributes (so even if there were a form, the POST body would be empty).
4. The Button has `type="button"` not `type="submit"` (so even if everything else were correct, clicking it wouldn't submit the form).

**Implication for Phase 8A:** ship a `UI::Form` view widget that:
- Takes an `action:` (matching the controller method name OR an explicit URL path) and `method:` (default POST).
- Wraps its children in `<form action="..." method="...">` on web.
- On web: auto-injects `<input type="hidden" name="_csrf" value="...">` using `context.csrf_token`.
- Marks its trailing Button child as `type="submit"` (or accepts a `submit_button` arg explicitly).
- Wires each TextField / SecureField / Toggle child to a `name="..."` derived from a `field_name:` constructor arg.
- On native: collects child input values into a `UI::FormState` on submit and dispatches to the controller's named action.

This widget is the bridge between "screen author writes shared code" and "platform-specific form mechanics happen for free." Without it, the design v2 doesn't deliver the owner directive.

### Finding #6 — TextField/SecureField need `name:` for web POST

Even with a `<form>` wrapper, inputs need `name="..."` attributes for the browser to include them in the POST body. The current `UI::TextField` has no `name` property.

**Implication for Phase 8A:** add `name : String?` property to TextField + SecureField. Web renderer emits `name="..."` when set. UI::Form's child handling reads this property to know what to dispatch as the action's params.

### Finding #7 — STALE (per Codex critique on this doc)

Initial observation was that the rendered HTML lacked `value="..."` after `tf.text = email_value`. Codex corrected: the current `UI::Web::Renderer` DOES emit `value=` for TextField + SecureField. The spike's empty observation was because on first GET (no params), `email_value` was the empty string, so no `value=` was emitted (correct behavior).

**Implication for Phase 8A:** no implementation gap. Ship a regression spec covering value-emission with a non-empty TextField text property, but do NOT brief this as an open gap.

### Finding #8 — CSRF token threading via Amber's helper, NOT raw session

The spike prototype's `ScreenHelpers#csrf_token_value` reads `session["csrf.token"]?` directly. **Codex critique on this doc corrected: this is insufficient.** Amber's CSRF pipe uses a persistent masked-token strategy where the raw session value isn't what should be sent as the form's `_csrf` field. Instead, the form should use Amber's own `csrf_token` / `csrf_tag` helpers (available on `Amber::Controller::Base` via `Helpers::CSRF`).

**Implication for Phase 8A:** the `UI::Form` widget's CSRF injection on web should call into Amber's CSRF helper API — likely by passing the helper output INTO the `UI::ScreenContext` rather than reading the raw session key. Phase 8A's brief must explicitly verify the spike's CSRF flow against Amber's masked-token strategy and use the framework's idiomatic API.

### Finding #9 — `params.to_h` returns Hash(String, Array(String))

Amber's params object exposes `to_h` returning `Hash(String, Array(String))`, not `Hash(String, String)`. The spike's `params_hash` flattens by taking `.first` of each Array, which is the right default for form scalars. Future support for multi-select fields (e.g. checkbox groups) needs to preserve the Array form.

**Implication for Phase 8A:** `UI::ScreenContext` should expose `params_multi : Hash(String, Array(String))` in addition to scalar `params : Hash(String, String)`. Or expose a single typed object that handles both.

### Finding #10 — Session iteration

The spike's `session_hash` checks `session.responds_to?(:to_h)` but Amber's session may not implement `to_h` directly. The spike worked because the session_hash path was unused in this specific flow (only csrf_token was read). Future use of `context.session_data` on the screen needs a confirmed iteration API.

**Implication for Phase 8A:** investigate the actual Amber session API. Likely Amber's session is iterable via `each` or has a `.keys` method; the integration helper should adapt.

---

## What the spike does NOT prove (carryover into Phase 8A)

- **UI::Form widget actually wraps + emits CSRF + name attrs** — design only; not yet implemented.
- **TextField/SecureField name+value attributes flow through web renderer** — not yet implemented.
- **Native side of UI::App / UI::Controller / ActionDispatcher / FormState** — entire native parallel structure untouched by the spike. Phase 8B.
- **Multipart/file-upload params** — spike used `application/x-www-form-urlencoded` only.
- **JSON / AJAX endpoints** — not covered.
- **Layout switching per controller / action** — only one layout used; per-action layout overrides untested.
- **Cross-platform Voyager migration** — Phase 8D.

---

## Codex critique verdict on this doc

```
Verdict: APPROVE-DIRECTIONALLY-WITH-CORRECTIONS (functionally equivalent
to REVISE-NARROWLY).

#1, #2, #3, #5, #6, #9, #10 are grounded and appropriately narrow.
#5/#6 are the core 8A blockers — without real form semantics, field
names, submit behavior, and CSRF injection, the Amber demo only proves
manual curl POST, not browser workflow.

#7 is STALE — current UI::Web::Renderer already emits value=. Ship a
regression spec, not an implementation gap.

#8 is underspecified — reading raw session["csrf.token"] is not enough
under Amber's persistent masked-token strategy. Use Amber's csrf_token
/ csrf_tag helpers.

Phase 8A should be web-only. Native FormState collection +
routes_for(UI::App) are orthogonal — belong in 8B/8C.
```

Findings #7 + #8 corrected above. Phase 8A scope narrowed to web-only
per Codex's recommendation.

## Recommended Phase 8A scope (post-spike, Codex-corrected — WEB ONLY)

Phase 8A's brief should now be much more concrete than design v2 suggested:

1. **Move spike-quality `UI::ScreenHelpers` + `UI::ScreenContext` + `UI::AmberConfig` + `UI::Screen` base into `src/asset_pipeline/amber_integration.cr`.** Drop the spike's stub.
2. **Ship `UI::Form` widget** with web + native render paths (web: `<form>` + CSRF + name-attr handling; native: `FormState` collection via children's on_change).
3. **Add `name:` property to TextField + SecureField.** Web renderer emits `name=` when set.
4. **Add `initial:` kwarg + correct `value=` emission to TextField + SecureField.** One-shot ergonomic improvement.
5. **Mark Button as `submit_button` when child of `UI::Form`** OR add `type: :submit / :button / :reset` property to UI::Button.
6. **Compile-time shim ECR generation** (per Codex finding #3 option B). The integration ships a macro that controllers mix in; the macro auto-generates the shim per action.
7. **MOVED TO 8B/8C per Codex:** `UI::AmberIntegration.routes_for(UI::App)` is orthogonal to the web-only Amber integration and belongs in 8B or 8C alongside the native side's screen registry.

The spike is now a forcing function for Phase 8A: every item above is grounded in an empirical gap, not speculation.

---

## Codex review of these findings

Run before drafting Phase 8A brief:

```bash
codex exec --skip-git-repo-check "Review the Phase 8 spike findings at samples/phase-08-amber-spike/findings.md. The architect ran a minimal Amber app exercising render_screen + CSRF + form POST and surfaced 10 specific gaps. Critique: are the gaps real and well-scoped? Is the recommended Phase 8A scope (items 1-7) sufficient to close them, or are there hidden dependencies? Are any of the gaps actually orthogonal to Phase 8 and belong in a different phase? Verdict: APPROVE-FOR-8A-BRIEF / REVISE / REJECT. Max 200 words."
```
