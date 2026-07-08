# SafeHTML v1 — the auto-escape output contract (Front A)

> **Status:** Shipped, v1 (safe-html-v1 branch).
> **Scope:** `asset_pipeline` view components (`Components::Component`,
> `Components::Elements::*`). Does **not** touch the Amber v2 ECR compiler
> (Front B) or the cross-platform native UI renderer's own internal CSS
> construction (`src/ui/renderers/web_renderer.cr`) — both are explicitly
> out of scope for this v1; see "What's out of scope" below.
> **Source proposal:** `premium-agentc-app-template/docs/PLATFORM_AUTOESCAPE_PROPOSAL.md`
> (2026-07-07 platform-hardening session). Owner decisions locked 2026-07-08:
> E1=A (invest in the SafeHTML output contract), E3=A (full v1 scope — text +
> attribute auto-escape, immediate bans on `on*`/raw `style`/`<script>`
> interpolation, `SafeURL`, typed `Style`/color builders), E4=B (this front
> ships first; the Amber ECR compiler is a later front).

---

## 1. The problem this closes

Before this change, `Component#render` returned a plain `String`, and every
hand-built component (`String.build` + `html << "...#{value}..."`) had to
remember to call `escape_html(...)` at every interpolation site. Nothing in
the type system distinguished "markup I built" from "text a stranger typed" —
safety was a discipline applied *N* times, and the failure mode was "someone
missed sink N+1." (`drafting-room`'s Stage 5 stored-XSS bug — a signup email
rendered raw into every authenticated page — is the canonical example: 952
green examples, and only an adversarial pass caught it.)

The `Elements` DSL (`Div`, `A`, `Table`, ...) was **already** safe by
construction — `ContainerElement#render_children` escapes `String` children,
`HTMLElement#render_attributes` escapes every attribute value. The gap was
that real components bypassed it with `String.build`. This v1 closes that
gap at the type boundary: `Component#render` now returns `SafeHTML`, not
`String`, and a small number of additional context-specific bans and typed
builders close the sub-classes HTML-escaping alone can't touch (URL scheme
injection, CSS-context breakout, inline event handlers, `<script>`
interpolation).

---

## 2. The contract

### 2.1 `SafeHTML` — the output contract

`Components::SafeHTML` (`src/components/safe/safe_html.cr`) is a value type
meaning "these bytes are already safe to write into an HTML response as
markup." There is **no public `SafeHTML.new(String)`** — `initialize` is
`protected`, so the compiler-generated `.new` is protected too. The only ways
to obtain one:

| Constructor | When to use it |
|---|---|
| `SafeHTML.escape(text)` | Escape arbitrary text (the common, always-correct path) |
| `SafeHTML.join(*parts)` / `SafeHTML.join(enumerable)` | Concatenate already-safe fragments |
| the `Elements`/tag DSL | Build markup via `Div`, `A`, `Table`, ... — escaped by construction |
| `SafeHTML.unsafe(html, reason:)` / `raw(html, reason:)` | **The loud escape hatch** — see §4 |

`SafeHTML` carries a minimal, deliberately-narrow String-like surface
(`to_s`, `to_s(io)`, `includes?`, `starts_with?`, `ends_with?`, `=~`,
`empty?`, `size`, `==`, `to_json`) — just enough that the ~1700 pre-existing
specs asserting `rendered.should contain(...)` / `.should eq(...)` /
`.should start_with(...)` keep working unedited. It is **not** a `String`
subclass and does not delegate the whole String API — that would re-blur the
exact boundary this type exists to draw.

### 2.2 `Component#render : SafeHTML`

```crystal
abstract class Components::Component
  # THE OUTPUT CONTRACT.
  def render : SafeHTML
    render_safe_content
  end

  # Override this in a migrated component (see §5).
  def render_safe_content : SafeHTML
    SafeHTML.unsafe(
      render_content,
      reason: "legacy component #{self.class} has not migrated to render_safe_content — see docs/SAFE_HTML_V1.md"
    )
  end

  # UNCHANGED — every existing component still implements this.
  abstract def render_content : String
end
```

This is the **dual-method bridge**: `render_content : String` stays exactly
as it was (still `abstract`, still what every un-migrated component
implements), and `render` now always returns `SafeHTML`. A component that
does nothing gets this for free — its output is wrapped through the loud,
greppable `SafeHTML.unsafe(..., reason: "legacy component ... ")` call
**inside the base class**, not scattered across every component. Grep for
`reason: "legacy component` to get the exact list of components still on the
old path — that list is the migration progress bar.

**Important, and deliberate:** the legacy bridge does **not** retroactively
sanitize a bad `String.build`. If a legacy component forgets to escape a
sink, `render` still returns `SafeHTML`, and that `SafeHTML` still contains
the hole — `spec/web/components/safe/component_render_contract_spec.cr`
"is honest, not protective" proves this on purpose. The bridge's job is only
to make the **type boundary** real (so `render`'s return type is uniformly
`SafeHTML` and callers can stop guessing), not to be a runtime sanitizer.
Security still comes from migrating a component onto `render_safe_content`
and the `Elements` DSL, not from the bridge.

### 2.3 `SafeBuffer` — the construction mechanism

`Components::SafeBuffer` (`src/components/safe/safe_buffer.cr`) is the
buffer-shaped alternative to `String.build` for components that want to
assemble `SafeHTML` without going through the full `Elements` DSL for every
node. It has **one load-bearing rule**: appending a `String` always means
*text* and is always escaped — there is no overload that takes a raw
`String` and treats it as markup:

```crystal
buf = Components::SafeBuffer.new
buf << "hello "                    # text -> escaped
buf << SafeHTML.escape("<world>")  # already-safe -> passthrough, escaped once
buf << some_element                # Elements::HTMLElement -> passthrough (already safe)
buf << some_component              # Component -> passthrough (render : SafeHTML)
buf.to_safe_html                   # => SafeHTML
```

`buf << "<b>#{x}</b>"` escapes the **entire literal**, producing a visible
`&lt;b&gt;...` — a cosmetic bug the author sees and fixes, not a silent XSS
hole. This is intentional (proposal §3.2 point 3): the fix for
"`String.build` interpolation loses provenance" is not a cleverer buffer, it
is to stop building HTML skeletons out of interpolated strings and use the
DSL for structure instead.

---

## 3. The bans

| Sink | v1 rule | Where enforced |
|---|---|---|
| Text nodes | HTML-escaped by construction | `ContainerElement#render_children` / `Component#render_children` (pre-existing) |
| Normal attributes | HTML-escaped by construction | `HTMLElement#render_attributes` (pre-existing) |
| `on*` inline event handlers | **Banned unconditionally**, on every element, both construction paths | `HTMLElement#validate_attribute` |
| URL-bearing attributes (`href`, `src`, `action`, `formaction`, `poster`, `cite`, `ping`, meta-refresh `content`, SVG `href`/`xlink:href`) | Require a `SafeURL` via the new typed setter | `HTMLElement#set_safe_url_attribute` |
| `srcset` | Require a `SafeSrcSet` (own parser — a URL *list with descriptors*, not a single URL) | `Components::SafeSrcSet` |
| `style` | Require a `SafeStyleValue` via the new typed setter (never a raw string) | `HTMLElement#set_safe_style` / `Components::SafeStyle` |
| `<script>` body | Plain `String` children **rejected outright** | `Elements::Script#<<` |

### 3.1 `on*` — hard, unconditional ban

```crystal
Components::Elements::Div.new(onclick: "alert(1)")
# => ArgumentError: SafeHTML ban: inline event-handler attribute "onclick" is forbidden...
```

Enforced in the shared `HTMLElement#validate_attribute`, so it applies to
**every** element, old and new construction paths alike (constructor kwargs
*and* `#set_attribute`). This is the one ban that could be unconditional
with zero migration cost: an audit of the whole shard at implementation time
found **zero** existing `on*` attribute usages anywhere, so there was no
legacy call site to break.

### 3.2 URL-bearing attributes — `SafeURL`

```crystal
url = Components::SafeURL.parse!("https://example.com")   # ok
url = Components::SafeURL.parse!("javascript:alert(1)")   # raises SafeURL::UnsafeURLError
a = Components::Elements::A.new
a.set_safe_url_attribute("href", url)
```

`SafeURL` allowlists `http`, `https`, `mailto`, `tel`; relative URLs
(absolute paths, protocol-relative `//host/...`, fragments, queries, bare
relative paths) are always allowed since the browser resolves them against
the current document and they cannot smuggle a script-executing scheme.
Anything else — `javascript:`, `vbscript:`, `data:`, `file:`, and any
scheme not on the allowlist — is rejected. Before checking the scheme,
`SafeURL` strips ASCII control characters (the classic `java\tscript:`
bypass some HTML/URL parsers are vulnerable to) and leading/trailing
whitespace. `SafeURL.unsafe(url, reason:)` is the loud opt-out for an
intentional non-allowlisted scheme (e.g. an app-custom URI scheme).

`srcset` gets its own type, `SafeSrcSet` — it's a comma-separated list of
`"<url> <descriptor>"` candidates, not a single URL, so `SafeURL` alone
can't validate it. `SafeSrcSet.parse!` validates every candidate's URL
through `SafeURL` and its descriptor against the width/density grammar
(`NNNw` / `N.Nx`), and rejects the **whole** value if any one candidate is
unsafe — fail closed, not "escape what we can."

### 3.3 `style` — typed `SafeStyle` / `SafeColor` / `SafeLength`

```crystal
style = Components::SafeStyle.new
  .keyword("display", "flex")
  .length("padding", Components::SafeLength.px(16))
  .color("color", Components::SafeStyle::Color.hex("#1d4ed8"))
  .build   # => SafeStyleValue

div.set_safe_style(style)
```

`SafeStyle` (`src/components/safe/safe_style.cr`) has **no method that
accepts a bare string** for a property value — only `Color`
(`UI::DesignTokens::Color`, reused as-is: it already has `.hex`, `.rgb`,
`.oklch` constructors and a safe `#to_css` serializer, so there was no
reason to build a second color type), `SafeLength` (`.px`/`.rem`/`.percent`/
`.zero`), and a closed per-property keyword allowlist (`display: flex`,
`position: relative`, ...). `url(...)`, `expression(...)`, `@import`, and
raw custom-property (`--x:`) passthrough are not filtered after the fact —
they are **unreachable**, because there is no constructor path that accepts
free-form CSS text. This is what would have caught the `brand_color`
CSS-context sink (Stage 5, commit `c6ec54f`): `HTML.escape` doesn't stop a
CSS-context breakout, but a typed `Color` can't express one in the first
place.

### 3.4 `<script>` — interpolation ban + two typed doors

```crystal
script = Components::Elements::Script.new
script << "some js"
# => ArgumentError: SafeHTML ban: <script> does not accept a plain String child...
```

Crystal's type system can't distinguish "a static JS literal the author
wrote" from "a string built by interpolating a runtime value" once both are
just `String` — so both are refused equally. Two doors remain:

- **`Script.static(js, reason:)`** — for genuinely static, author-controlled
  JS with no interpolated untrusted data. Loud and greppable, the same shape
  as `SafeHTML.unsafe`. (`Elements::RawHTML.new(js)` appended directly works
  too — `Script.static` is the ergonomic, reason-enforcing wrapper around
  that.)
- **`Script.json_data(id:, data:)`** — for handing *data* to client-side JS.
  Serializes via `JSON` and additionally escapes `</` sequences, so a
  payload containing `</script><script>...` cannot prematurely close the
  element and smuggle markup (JSON string-escaping alone does not cover
  `/`, since it isn't a JSON metacharacter).

Two pre-existing shard-internal call sites (`web_renderer.cr`'s context-menu
and action-sheet fallback JS, `integration.cr`'s `reactive_script_tag`) hit
this ban — all three were genuinely static/framework-authored JS (constants
or a boolean-flag interpolation), and were migrated to `Script.static(...)`
as part of this change; see the commit history on this branch for the exact
diffs.

---

## 4. The `raw()` policy

`raw(html, reason:)` (top-level `Components.raw`, aliased as a protected
instance method on `Component`) and `SafeHTML.unsafe(html, reason:)` are the
**same function** — two spellings of the one door that turns an arbitrary
`String` into `SafeHTML` without going through `.escape`/`.join`/the DSL.

- `reason:` is **mandatory**, not defaulted — a blank or whitespace-only
  reason raises `ArgumentError`. Every call site is forced to say, in
  writing, why the string is trusted.
- It is **loud and greppable by design**:
  `grep -rn 'SafeHTML.unsafe\|SafeURL.unsafe\|\.raw(' src/` finds every one.
  `Component`'s own legacy bridge uses the fixed prefix
  `reason: "legacy component ..."`, so `grep -rn 'reason: "legacy component'`
  specifically finds every component still on the un-migrated path.
- There is deliberately **no** easy `SafeHTML.new(String)` — see §2.1. The
  raw door is the *only* hole, which is what makes it auditable instead of a
  second `html_safe`-style label anyone can slap on any string.

**Policy going forward:** every new `raw(...)` / `SafeHTML.unsafe(...)` /
`SafeURL.unsafe(...)` call site added to this shard should be reviewed the
same way a new `unsafe`/`unchecked` block would be in any other language —
the `reason:` string is the audit record, and it should say *why* the value
is trusted (static literal, already-validated upstream, etc.), not just
restate that it's being marked safe.

---

## 5. Migration guide for components

Migrating a component from the legacy `render_content : String` path onto
`render_safe_content : SafeHTML` is mechanical. Worked example:
`Components::Examples::DataTableComponent`
(`src/components/examples/data_table_component.cr`) — chosen as the v1
exemplar because it was the gnarliest hand-built component in this shard:
`String.build` + **nine** individually-placed `escape_html(...)` calls (one
per interpolated sink — the id attribute, the caption, and each row's
id/title/owner/status/amount plus the composed aria-label), exactly the
"someone will eventually miss sink N+1" shape the hardening proposal
describes.

**Steps:**

1. Rename `render_content` to `render_safe_content`, and change its return
   type from `String` to `SafeHTML`.
2. Replace `String.build` + `html << "...#{x}..."` with the `Elements` DSL:
   construct `Div`/`Table`/`Tr`/`Td`/... instances, add text via `<<` (a
   plain `String` — it gets escaped by `render_children`), set attributes
   via constructor kwargs or `#set_attribute` (escaped by
   `render_attributes`). There is no sink left to individually remember —
   every text child and attribute value on the tree is escaped by the same
   mechanism.
3. Wrap the final tree's `.render` (a `String`, since `Elements::HTMLElement`
   itself still returns `String` — see "what v2 adds" below) in
   `SafeHTML.unsafe(tree.render, reason: "built entirely via the Elements
   DSL — text children and attribute values are escaped by construction")`.
   This is a single, top-level, well-justified `unsafe` call per migrated
   component (not per-field) — it's honest about *why* it's legitimate
   (the DSL's own escaping, not hand-built markup) and shows up once in the
   `grep -rn 'SafeHTML.unsafe'` audit per component, instead of nine times
   as nine individual `escape_html` calls that could each independently be
   forgotten.
4. Keep a `render_content : String` method that just delegates:
   `render_safe_content.to_s` — `Component#render_content` is still
   `abstract` (kept that way deliberately; see "why `render_content` stays
   abstract" below), so every subclass must implement *something* there.
   This one-liner satisfies the contract without duplicating logic.
5. Add adversarial specs: for every sink the component builds, assert that
   an XSS-shaped payload (`<script>...</script>`, `"><script>...`, etc.)
   comes back escaped and never produces a live tag/attribute-breakout. See
   `spec/web/components/safe/component_render_contract_spec.cr`'s
   `DataTableComponent` block for the pattern (one spec per sink category:
   text nodes, an attribute built by string composition, the empty-state
   branch, the conditionally-set `id` attribute).

**Why `render_content` stays `abstract` instead of being removed:** changing
it to non-abstract-with-a-raising-default, or removing it, would force every
one of the ~18 other example components in this shard to be touched in this
same change — exactly the "mass migration" this v1 explicitly does not do
(per the owner's instruction: migrate one exemplar as proof-of-pattern, not
the whole library — the drafting-room UI redesign will rebuild views onto
this contract separately). Keeping `render_content : String` abstract and
unchanged means every existing component compiles and behaves identically,
with zero edits, while still getting `Component#render : SafeHTML` for free
via the legacy bridge.

**Not migrated in this v1 (by design):** the other ~18 example components in
`src/components/examples/`. They continue to work exactly as before, riding
the legacy bridge (§2.2). Migrating them — and the premium template's own,
separate component library, which pins this shard — is future work.

---

## 6. What's out of scope for v1 (and why)

Two subsystems in this shard reuse the same `HTMLElement`/`ContainerElement`
base classes but are **not** touched by this hardening pass:

- **`src/ui/renderers/web_renderer.cr`** (the cross-platform native UI web
  renderer) calls `HTMLElement#add_style(String)` roughly 180 times and
  `#set_attribute("href"/"src"/"action", value)` a handful of times. Every
  one of those strings is framework-computed (design tokens, `Color`
  fields already converted to RGB integers, layout enums) — not
  attacker-controlled text forwarded from a component. Retrofitting the
  `style`/URL bans onto the shared `set_attribute`/`add_style` methods
  would either break this ~2800-line, already-tested, unrelated subsystem
  wholesale, or require rewriting all ~185 call sites in this change — both
  disproportionate to what this task authorizes ("do not mass-migrate app
  components"). The two `<script>` call sites in this file (both genuinely
  static JS constants) **were** migrated to `Script.static(...)`, since that
  was a 2-line, zero-risk fix that directly demonstrates the correct pattern.
- **The Amber v2 ECR compiler** (Front B of the hardening proposal) is
  explicitly a separate, later front (owner decision E4=B) and is untouched
  by this branch.

The v1 enforcement boundary is therefore two-tier by design, and documented
as such rather than pretended away:

| Path | `on*` | URL attrs | `style` | `<script>` |
|---|---|---|---|---|
| **New**: `set_safe_url_attribute` / `set_safe_style` / `Script.static`/`.json_data` | banned (shared) | `SafeURL`-typed, compile error for `String` | `SafeStyleValue`-typed, compile error for `String` | banned, typed doors only |
| **Legacy**: `set_attribute("href", "...")` / `add_style("...")` — still used internally by the native UI renderer | banned (shared) | unchanged — still accepts a raw `String` | unchanged — still accepts a raw `String` | banned (unconditional — zero legacy usage) |

Extending `SafeURL`/`SafeStyle` enforcement onto the legacy path (and thereby
onto the native UI renderer) is a natural, bounded follow-up, but is not part
of this v1.

---

## 7. What v2 adds later (Front B + the rest of §3.3)

Per the source proposal:

- **Front B — the Amber v2 ECR compiler.** `<%= expr %>` currently emits
  `expr.to_s` unescaped (stdlib ECR has no escaping switch). v2 replaces
  this with an ECR-syntax-compatible translator: `<%= expr %>` auto-escapes
  unless `expr` is `SafeHTML` (which emits raw), with `<%= raw(expr) %>` as
  the explicit opt-out — the same contract as this document, extended to
  the template layer. This requires the compiler to track HTML context
  around each `<%= %>` (inside a quoted attribute? which attribute? inside
  `<script>`/`style`?) to apply the same §3 rules there.
- **Extending the bans onto the legacy `HTMLElement` path** (§6) — a
  `strict_attributes!`-style opt-in flag (default off) that, once every
  caller of `add_style`/`set_attribute` for URL-bearing names has migrated,
  flips to make the ban unconditional everywhere, matching the proposal's
  "additive first, flip once migrated" rollout shape.
- **Migrating the remaining ~18 example components** onto
  `render_safe_content`, retiring `String.build` from this shard's own
  component library entirely (not just the one exemplar).
- **Grep-gate retirement** (`escaping_gate.sh`, per proposal §7): once (a)
  no component defines the legacy `render_content` path, (b) HTML response
  sinks accept only `SafeHTML`, (c) `unsafe`/`raw` calls exist only in an
  audited allowlist, and (d) a structural CI gate replaces the grep gate,
  the grep gate can be deleted. None of those four conditions hold yet after
  this v1 — it ships the types and the exemplar, not the full migration.
