# Phase 8A — Implementer Brief

**Date opened:** 2026-05-24
**Authored by:** Architect (Codex-critique before dispatch)
**Branch:** to be cut as `phase-08a-amber-render-screen-form` from feature branch after Phase 6.12 closes. Spike work + design docs already on feature.
**Codex protocol:** Per-iteration critique on every code-touching iteration. No self-assessment.

---

## Why this iteration exists

Phase 8 design v2 + spike at `samples/phase-08-amber-spike/` proved the parallel-controllers architecture is viable. Spike validation:

- Amber 1.4.1 + path-included asset_pipeline shards install + crystal build → PASS
- `Amber::Controller::Base` includes `UI::ScreenHelpers` mixin → screen renders, layout wraps, CSRF meta tag emits, session cookie sets
- GET + POST cycle through controller actions, params flow, flash persists across re-renders

Codex APPROVE-DIRECTIONALLY with 2 corrections (folded into spike findings.md) + scope narrowing to web-only:
> "Phase 8A should cover web-only Amber integration: helper/shim, ScreenContext::Web, web form rendering, names, submit type, params scalar/multi handling, and real browser POST proof. Native FormState collection and routes_for(UI::App) are orthogonal and belong in 8B/8C."

Phase 8A lifts the spike-quality prototypes into production code, ships the load-bearing `UI::Form` widget, and proves the integration in a browser (not just curl).

---

## Empirical findings driving this brief

From `samples/phase-08-amber-spike/findings.md` (full provenance there):

| # | Finding | 8A Action |
|---|---|---|
| 1 | `UI::VStack.new(...) do |stack| ... end` doesn't compile — block API absent | Add optional `&block : (VStack -> Nil)` constructor for ergonomics |
| 2 | `UI::TextField.new` has no `text:` kwarg for pre-population | Add `text:` kwarg to TextField + SecureField (matches existing `text` property name) |
| 3 (CRITICAL) | Amber's `render` is a macro requiring `template:`/`partial:` path — no `html:` overload | Per-controller static shim ECR + CLI generator (macro file-gen rejected by Codex — Kilt requires templates at compile time) |
| 4 | `<%# %>` ECR comments don't parse | Documentation note only; no code change |
| 5 (MAJOR) | `UI::Form` exists with section semantics but lacks web `<form>` POST wrapping | EXTEND `UI::Form` with action/method/csrf_token + flat-children support; native visit unchanged |
| 6 | TextField + SecureField need `name:` property for POST | Add `name : String?` property + web renderer emits `name="..."` |
| 7 | (STALE per Codex) value= IS emitted today | Regression spec only |
| 8 | CSRF via Amber's `csrf_token` / `csrf_tag` helper, NOT raw session read | Use Amber's helper API in the integration |
| 9 | params.to_h is `Hash(String, Array(String))` | ScreenContext exposes both scalar `params` and `params_multi` |
| 10 | Session iteration API needs investigation | Pin to confirmed Amber API; document |

---

## Scope — 5 items

### Item 1 — Lift integration helpers into `src/asset_pipeline/amber_integration.cr`

Move the spike prototype from `samples/phase-08-amber-spike/src/lib/asset_pipeline_amber_helpers.cr` into the canonical home at `src/asset_pipeline/amber_integration.cr`. Production-quality this time:

- `UI::ScreenContext` (the narrow abstract base with params/session/flash/design_tokens/csrf_token getters).
- `UI::ScreenContext::Web` concrete impl — wraps Amber's params/session/flash via delegation, exposes both scalar `params : Hash(String, String)` AND `params_multi : Hash(String, Array(String))` per spike finding #9.
- `UI::ScreenHelpers` mixin — provides `compute_screen_html(ScreenClass) : String`. **NOTE (Codex-revised per finding #1):** the macro-auto-generated shim ECR template approach is NOT SOUND. Amber's `render` macro expands to `Kilt.render("path/template")` at compile time, requiring the template file to exist on disk before Crystal compiles. Crystal macros cannot reliably write files to disk for the Kilt path lookup. Therefore Phase 8A ships a **per-controller static shim** at `src/views/{controller_name}/{action_name}.ecr` containing just `<%= @screen_html %>`. Authors check these in. The integration ships a `bin/asset_pipeline_amber` generator script that creates the shim file for a new controller-action pair via a CLI command — boilerplate-reducing, but not magical.
- `UI::AmberConfig` module — `design_tokens : Tokens` class-property settable at boot.
- `UI::Screen` abstract base class with `build(ctx : UI::ScreenContext) : UI::View`.

**Acceptance:** `crystal build samples/phase-08-amber-spike/src/spike_app.cr` succeeds AFTER swapping `require "../src/lib/asset_pipeline_amber_helpers"` for `require "asset_pipeline/amber_integration"`. The spike's controllers + screens unchanged. The shim ECR templates remain in `samples/phase-08-amber-spike/src/views/sign_in/`.

**Risk note (Codex-revised per finding #4):** this item is NOT low-risk. It introduces public API surface (`UI::ScreenContext`, `UI::ScreenHelpers`, `UI::AmberConfig`, `UI::Screen` base class) that downstream apps will couple to. Codex review of Item 1's commit must specifically check the API surface for unintended exposure / coupling, NOT just compile correctness.

### Item 2 — EXTEND `UI::Form` for web POST semantics (not invent a new type)

**Important context Codex surfaced:** `UI::Form` ALREADY EXISTS at `src/ui/views/form.cr` with sectioned-list semantics (matching SwiftUI's `Form { Section { ... } }` primitive). It has `sections : Array(FormSection)`, each with `header`, `fields : Array(Field)`, and `footer`. Native renderers use this for grouped form rendering (iOS Form { Section { ... } }, macOS NSBox-grouped fields).

Phase 8A EXTENDS this existing class — does NOT introduce a conflicting type with the same name.

Add to `UI::Form`:

```crystal
property action : String? = nil       # nil = no <form> wrapper on web
property method : String = "POST"
property csrf_token : String? = nil   # explicit constructor arg, NOT mutated post-build
property children : Array(View) = [] of View  # NEW — non-sectioned children for simple forms

# Updated constructor — explicit kwargs only, no auto-magic:
def initialize(
  @action : String? = nil,
  @method : String = "POST",
  @csrf_token : String? = nil,
)
  @container_query_name = "form"
end

def <<(child : View) : Nil
  @children << child
end
```

The author chooses either:
- **Sectioned form (existing):** `form.add_section(header: "Account") { |s| s.fields << Field.new(...) }`. Used for grouped iOS-style settings/forms.
- **Flat form (new):** `form << UI::TextField.new(name: "email"); form << UI::Button.new("Sign in", type: :submit)`. Used for simple sign-in / contact forms.

Both can coexist — sections render as `<fieldset><legend>...</legend>...</fieldset>` chrome on web; children render inline; the wrapper `<form action="..." method="..."><input type="hidden" name="_csrf" value="..."> ... </form>` only emits when `@action` is non-nil.

**Web renderer's `visit(UI::Form)` updates:**

If `view.action` is non-nil:
```html
<form action="{{view.action}}" method="{{view.method}}">
  <input type="hidden" name="_csrf" value="{{view.csrf_token}}">
  {{existing section rendering, fieldset/legend chrome}}
  {{children rendered inline (flex-column)}}
</form>
```

If `view.action` is nil: existing behavior unchanged (no `<form>` wrapper; section/field rendering only).

**TextField + SecureField children** inside a UI::Form: emit their `name=` attribute (from Item 3).

**Submit button detection (Codex-revised per finding #3):**
- The author MUST explicitly set `UI::Button.new("Sign in", type: :submit)` (see Item 5).
- Auto-promotion only happens when EXACTLY ONE button child exists in the entire form tree. Multi-button forms must use explicit `type: :submit` on the intended submitter.
- Implementer documents the convention in the type's Crystal doc comment.

**CSRF token threading (Codex-revised per finding #2):**
- `UI::ScreenHelpers#compute_screen_html` reads `context.csrf_token` (which the integration helper pulls from Amber's CSRF helper API, not raw session).
- Threading: the helper constructs a `UI::RenderContext` (a renderer-scoped value passed alongside the view tree to `UI::Web::Renderer.new.render(view_tree, render_context: ...)`). The renderer threads it into the Form visit. Form's `csrf_token` property is only read if `@csrf_token.nil? && render_context.csrf_token` — explicit constructor arg wins, otherwise the threaded context.
- This avoids mutating Form#csrf_token on shared-tree references (Codex's concern).

**Native renderer's `visit(UI::Form)`:** UNCHANGED for Phase 8A. The existing section/field rendering keeps working on iOS/macOS. Native FormState + action dispatching is Phase 8B scope.

**Acceptance:** 
- `crystal spec` baseline preserved.
- Existing sectioned-Form rendering on iOS/macOS unchanged (no native regression).
- Spike `SignInScreen` rewritten to use `UI::Form.new(action: "/sign_in/submit", csrf_token: context.csrf_token)` + `<<` for fields + button. Browser submit returns 200 OK with populated params (proven in browser POST gate below).

### Item 3 — Name property on TextField + SecureField + Web renderer name= emission

In `src/ui/views/text_field.cr` and `src/ui/views/secure_field.cr`:

```crystal
property name : String? = nil
```

In `src/ui/renderers/web_renderer.cr`:

- `visit(UI::TextField)` emits `name="#{view.name}"` when `view.name` is non-empty.
- Same for `visit(UI::SecureField)`.
- Idempotent — repeated visits don't double-emit.

Confirm finding #7 is stale by reading the web renderer's existing `value=` emission for TextField/SecureField. If `value=` is NOT actually emitted, this item expands to include it (and ship a regression spec covering both).

**Acceptance:** rendered HTML for `UI::TextField.new(placeholder: "Email").tap { |t| t.name = "email"; t.text = "seth@example.com" }` includes BOTH `name="email"` AND `value="seth@example.com"`.

### Item 4 — `text:` kwarg + `name:` kwarg on TextField + SecureField

Constructors become:

```crystal
def initialize(@placeholder : String = "", @name : String? = nil, @text : String = "")
def initialize(@placeholder : String = "", @name : String? = nil, @text : String = "", &block : String -> Nil)
```

(rename `text` arg to `text:` not `initial:` — the existing `text` property is the storage; the kwarg matches the property name for consistency.)

**Acceptance:** `UI::TextField.new(placeholder: "Email", name: "email", text: "seth@example.com")` compiles + behaves correctly.

### Item 5 — `UI::Button.type` property + submit-button detection

In `src/ui/views/button.cr`:

```crystal
enum Type
  Button
  Submit
  Reset
end

property type : Type = Type::Button
```

Web renderer's `visit(UI::Button)` emits `type="submit"` / `type="reset"` based on the property; defaults to `type="button"` (existing behavior).

The `UI::Form` web visit walks its children:
- Honors any explicit `type:` set by the author (per Codex finding #3).
- Auto-promotes to `Type::Submit` ONLY when the form has exactly one Button child AND that button's type is the default `Type::Button`.
- Multi-button forms MUST use explicit `UI::Button.new("Sign in", type: :submit)`. No surprising "last button wins" behavior.

**Acceptance:** `UI::Form.new(action: "/sign_in/submit") << UI::TextField.new(...) << UI::Button.new("Sign in", type: :submit)` renders the button with `type="submit"`. Without explicit `type: :submit`, a single-button form still auto-promotes; a multi-button form does NOT.

---

## Browser POST proof (the closing gate)

After Items 1-5 land, update the spike app at `samples/phase-08-amber-spike/`:

1. Rewrite `src/screens/sign_in_screen.cr` to use `UI::Form` instead of bare VStack-of-fields.
2. Rebuild + run spike.
3. **Open `http://localhost:3000/` in a real browser.** Submit the form. Verify:
   - POST request goes to `/sign_in/submit`.
   - Server receives `email`, `password`, `_csrf` params.
   - Controller's submit action processes them.
   - Re-render with flash message visible.
4. Capture browser screenshot at `phase-08-amber-spike/findings-browser-submit.png`.

This is the empirical proof that the web target works for a HUMAN, not just curl.

---

## Codex protocol

Every code-touching iteration gets a Codex review at `handoff/phase-08a-codex-N.md`. Self-assessment NOT acceptable.

Logical iteration boundaries (Codex-revised, finding #4):
- iter 1: Item 1 (lift helpers) — HIGHER RISK than I originally claimed; introduces public API surface. Codex review must check API exposure not just compile correctness.
- iter 2: Item 4 (TextField/SecureField kwargs) + Item 3 (name= web emission) — small, focused.
- iter 3: Item 5 (Button.type property + Form auto-promote-when-single-button convention) — small.
- iter 4: Item 2 (extend UI::Form for web action/method/csrf + render context threading) — biggest single change, gets dedicated iteration.
- iter 5: Spike migration + browser POST proof.

Per Codex's note: removed all native-stub work from Phase 8A. UI::Form's NATIVE visit stays unchanged. Native FormState + action dispatching is Phase 8B/8C.

If Codex times out twice: STOP, write `handoff/phase-08a-codex-blocker.md`, escalate.

---

## Build + verification

```bash
crystal spec

# Build the spike against the lifted helpers
cd samples/phase-08-amber-spike
crystal build src/spike_app.cr -o bin/spike

# Run + browser-test
AMBER_ENV=development ./bin/spike &
# Open http://localhost:3000/ in Safari / Chrome
# Submit the form. Check the response.

# Curl-test as before (still useful for regression checks)
curl -c /tmp/spike-cookies.txt http://localhost:3000/ > /tmp/spike-get.html
CSRF=$(grep -oE 'meta name="_csrf" content="[^"]+"' /tmp/spike-get.html | sed -E 's/.*content="([^"]+)".*/\1/')
curl -b /tmp/spike-cookies.txt -X POST http://localhost:3000/sign_in/submit \
  -d "email=seth@example.com&password=secret&_csrf=$CSRF" -w "HTTP %{http_code}\n" -o /dev/null
```

---

## Acceptance you must meet

- `crystal spec` baseline preserved (whatever the current baseline is when 6.12 closes).
- Spike app builds + runs after migrating to lifted helpers + UI::Form.
- Browser POST proof captured.
- All 5 items shipped with per-iteration Codex review.
- `grep -rE "voyager-(save-chain|interaction-proof)"` returns 0.

## Reporting

Write `handoff/phase-08a-implementer-report.md`. Return to architect with: branch HEAD SHA, commit count + SHAs, Codex verdicts, evidence paths, hand-test commands.

## Hard rules

- Forward commits only on `phase-08a-amber-render-screen-form` branch (cut from feature post-6.12).
- NO native side changes — `UI::Form` native visit is UNCHANGED (existing section-list rendering keeps working on iOS/macOS). Native FormState + action dispatching is Phase 8B/8C scope.
- NO routes_for(UI::App) — that's 8C.
- Do NOT touch macOS or iOS renderers.
- Standard Claude co-author footer.
- If Item 2 (UI::Form) turns out to need a deeper redesign during Codex review, STOP and escalate.
