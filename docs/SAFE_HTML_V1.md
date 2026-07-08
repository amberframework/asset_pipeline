# SafeHTML v1 — the auto-escape output contract (Front A)

> **Status:** Shipped, v1 (safe-html-v1 branch). Re-gated 2026-07-08 to
> close the `<iframe srcdoc>` HTML-document-valued attribute sink and the
> `<svg>` foreign-content text-node sink, plus a systematic completeness
> sweep of every HTML-injection sink class in this shard — see §3.5, §3.6,
> and **§8 (the completeness sweep)**.
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
| Attribute *names* (not values) | **Rejected unconditionally**, on every element, both construction paths, if the name contains ASCII whitespace, a control character, or any of `/ \ > < " ' =` | `HTMLElement#set_attribute` → `HTMLElement#validate_attribute_name!` |
| `on*` inline event handlers | **Banned unconditionally**, on every element, both construction paths | `HTMLElement#validate_attribute` |
| URL-bearing attributes on link/src-bearing elements (`A`/`Link`#`href`, `Img`/`Script`/`Iframe`/`Source`/`Track`/`Embed`/`Audio`#`src`, `Video`#`src`+`poster`, `Area`/`Base`#`href`, `Form`#`action`) | Validated through `SafeURL` on **every** construction/`#set_attribute` call for that attribute name on that element, matched case-insensitively and with surrounding whitespace ignored (`HREF`, `Href`, `" href"`, `"href "` all match `"href"`) — not just the typed setter | `HTMLElement#set_safe_url_attribute` (typed path) **and** `Elements::UrlAttributeValidation` (included by each of the elements above; enforces the same `SafeURL` check on the ordinary `String`-typed `#set_attribute`/constructor-kwarg path too) |
| URL-bearing attributes not on the list above (`formaction` on `Button`/`Input`, `cite` on `Blockquote`/`Ins`/`Del`, `ping` on `A`, `data` on `Object`, SVG `href`/`xlink:href`, arbitrary `data-*`/custom attributes on any element) | Not enforced in v1 — only reachable via the typed `set_safe_url_attribute` setter or the fully-generic, unchecked `set_attribute` | *(no per-attribute enforcement; see §6 and §8(d))* |
| `<meta http-equiv="refresh" content="N; url=...">` | Dedicated typed constructor (the `content` value is a *compound* format, not a plain URL, so the generic URL setter is the wrong shape for it) | `Elements::Meta.safe_refresh(seconds, SafeURL)` |
| `srcset` | Require a `SafeSrcSet` (own parser — a URL *list with descriptors*, not a single URL) | `Components::SafeSrcSet` |
| SVG `href` / `xlink:href` | `set_safe_url_attribute` works by attribute *name*, so it covers this the moment it's called — `Elements::Svg` exists in this shard (see the `<svg>` foreign-content row below) but does not itself have an `href`/`xlink:href`-bearing child element class yet (no `Elements::Use`/`Elements::Image` SVG-specific class), so the *attribute* case remains untested/theoretical even though the *element* it would apply to is real. Corrects a stale claim in a prior revision of this doc that said "no SVG element classes in this shard yet." | *(no SVG `href`/`xlink:href`-bearing element class in this shard yet)* |
| `style` | Require a `SafeStyleValue` via the new typed setter (never a raw string) | `HTMLElement#set_safe_style` / `Components::SafeStyle` |
| `<script>` body | Plain `String` children **rejected outright** | `Elements::Script#<<` |
| `<iframe srcdoc>` | **HTML-document-valued** attribute — plain `String` **rejected unconditionally**, on the constructor-kwarg path, the `#set_attribute` path, *and* a render-time backstop (matching the `<script>`-body ban's three-path closure) | `Elements::Iframe#set_attribute` / `#render_attributes` — typed doors: `Iframe.srcdoc(html, reason:)` / `#set_srcdoc(html, reason:)` |
| `<svg>` foreign-content children | `String` children **HTML-escaped by construction**, same as every other element (previously rendered raw/unescaped — see §3.6) | `Elements::Svg` (no override; inherits `ContainerElement#render_children`) |

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

### 3.1b Attribute-*name* grammar — the general fix for name-based bypasses

Every check described in this document — `on*`, `SafeURL`, everything —
assumes it is being asked "is *this* attribute (`href`, `onclick`, ...)
safe?" That assumption silently depends on the attribute's *name* meaning
what it looks like it means once rendered. `HTMLElement#render_attributes`
emits the attribute name **verbatim** — only the *value* is HTML-escaped:

```crystal
protected def render_attributes : String
  attrs.map { |name, value| %(#{name}="#{escape_attribute(value)}") }
  # ^ name is never escaped or validated here — only `value` is
end
```

A re-gate audit found that this makes the name itself a sink: a
caller-supplied name containing a byte the HTML tokenizer treats specially
changes what the *browser* parses, independent of anything the `on*`/
`SafeURL` checks do with the value:

```crystal
Components::Elements::A.new("/href": "javascript:alert(document.cookie)")
# Before this fix: rendered as `<a /href="javascript:alert(document.cookie)">`.
# The leading `/` survives `UrlAttributeValidation`'s `name.strip.downcase`
# normalization (`.strip` does not remove a `/`), so `url_bearing_attribute?`
# never matches "href" and the SafeURL check never fires. In the browser
# tokenizer, `/` in the "before attribute name" state starts a
# self-closing-start-tag attempt; the very next byte (not `>`) is a parse
# error that reconsumes in "before attribute name" state — the `/` is
# silently dropped and `href` starts a brand-new, live attribute. Net
# effect: a real, clickable `javascript:` href, with the SafeURL gate never
# having run.

Components::Elements::Div.new("/onclick": "alert(document.cookie)")
# Same trick, this time bypassing the on*-ban in `HTMLElement#validate_attribute`
# (name[0..1].downcase == "on" tests "/on", not "on" — never matches).
```

A second shape of the same root cause: an embedded space, `=`, `>`, or
quote in the name ends the current attribute mid-stream and starts an
adjacent, attacker-controlled attribute the caller never asked for —
`set_attribute(%(x onload=alert(1)), "y")` renders a live `onload=`
attribute next to `x`.

**The fix is not another per-variant patch.** Point-fixing `/href`,
`/onclick`, and every other case/whitespace/punctuation variant
individually is an unbounded list. Instead, `HTMLElement#set_attribute`
now validates the *name*'s grammar, once, as the first thing it does,
before `validate_attribute`/`UrlAttributeValidation`/anything
element-specific ever sees it:

```crystal
def set_attribute(name : String, value : String?) : self
  return self if value.nil?
  validate_attribute_name!(name)   # <- raises before anything else runs
  validate_attribute(name, value)
  ...
end
```

`validate_attribute_name!` (`src/components/elements/base/html_element.cr`)
raises `ArgumentError` unless `name` is non-empty and free of:

- **ASCII whitespace** — space, tab, LF, FF, CR.
- **Control characters** — C0 controls (`U+0000`–`U+001F`) and DEL/C1
  controls (`U+007F`–`U+009F`).
- **`/ > = " '`** — spec-mandated per WHATWG HTML §13.1.2.3 "Attributes":
  these are the actual bytes the tokenizer's before-attribute-name /
  attribute-name states treat as state transitions (self-closing attempt,
  tag end, value start) or as syntax-forbidden.
- **`\` and `<`** — not individually tokenizer-breaking *inside* an
  already-started name, but banned too as defense-in-depth: no legitimate
  HTML/ARIA/`data-*`/SVG attribute name ever contains either, and `<` is
  always a parse error per spec even when it doesn't structurally break
  out.

Because this lives in the one method every attribute-setting path funnels
through — constructor kwargs (`HTMLElement#initialize` calls
`#set_attribute` once per kwarg) and every direct `#set_attribute` call,
on **every** element, including the ones that `include
UrlAttributeValidation` (their override runs its own logic and then calls
`super`, landing here) — it closes the SafeURL-gate bypass, the on*-ban
bypass, and adjacent-attribute injection **simultaneously**, for all ~94
element classes, in one place. It does **not** restrict ordinary names:
letters, digits, hyphen, colon, and underscore are all still allowed, so
`href`, `data-x`, `aria-label`, `viewBox` (SVG camelCase), `xml:lang`
(colon-namespaced), and `xlink:href` are unaffected. It also does not
touch the *value* side — `escape_attribute` still does that job, unchanged.

Specs: `spec/web/components/safe/attribute_name_grammar_spec.cr`.

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

**Construction/`#set_attribute`-time enforcement on link/src-bearing
elements.** The typed `set_safe_url_attribute` setter above is opt-in — it
only closes the hole for call sites that already chose to use it. The far
more common way `href`/`src` reach an element is the ordinary, pre-existing
path everyone already uses without thinking about it:

```crystal
Components::Elements::A.new(href: "javascript:alert(document.cookie)")
# => ArgumentError: SafeHTML ban: "href"="javascript:alert(document.cookie)" rejected...

a = Components::Elements::A.new
a.set_attribute("href", "javascript:alert(document.cookie)")
# => ArgumentError, same as above
```

`Components::Elements::UrlAttributeValidation` (`src/components/elements/base/url_attribute_validation.cr`)
is a module included by each concrete element whose defining feature *is* a
URL-bearing attribute: `A`/`Link`#`href`, `Img`/`Script`/`Iframe`/`Source`/
`Track`/`Embed`/`Audio`#`src`, `Video`#`src` and `poster`, `Area`/`Base`#
`href`, `Form`#`action`. Each override declares which attribute name(s) on
*that* tag are URL-bearing; the module then intercepts `#set_attribute` for
just that name and runs it through `SafeURL.parse!` before delegating to the
normal `HTMLElement#set_attribute`. Because `HTMLElement#initialize` calls
`#set_attribute` once per constructor kwarg, this closes the constructor-kwarg
path and the explicit `#set_attribute` path with one mechanism.

The name comparison inside `UrlAttributeValidation#set_attribute` normalizes
the caller-supplied name (`name.strip.downcase`) **only for the
`url_bearing_attribute?` check** — real HTML attribute names are ASCII-case-
insensitive and tolerant of incidental whitespace from hand-built call sites,
so `A.new("HREF": "javascript:...")`, `A.new("Href": ...)`,
`a.set_attribute("HREF", ...)`, and `a.set_attribute(" href", ...)` all match
`"href"` and go through `SafeURL.parse!` exactly like the plain-lowercase
form. The *rendered* attribute name is left exactly as the caller passed it
(`super` still receives the original, un-normalized `name`) — normalization
only ever widens which calls get checked, never changes what gets written to
the DOM string.

**`name.strip.downcase` only strips ASCII whitespace and folds case — it
does not remove punctuation**, so a name like `/href` normalizes to `/href`
(not `href`) and `url_bearing_attribute?` correctly does **not** match it.
That used to be a silent SafeURL-gate bypass (the malformed name reached
`render_attributes` unchecked and the browser tokenizer parsed it as a live
`href`); it no longer is, because `/href` is now rejected two lines later
by `HTMLElement#set_attribute`'s call to `validate_attribute_name!` (§3.1b)
the moment `super` is reached — a name-grammar backstop this module doesn't
need to know about or duplicate.

This is deliberately narrower than "ban `href`/`src` everywhere": it does
**not** modify `HTMLElement#set_attribute` itself (the shared, generic,
`String`-typed setter every element class has), so every other attribute
name, on every element, is completely unaffected — including the ~185
`add_style`/generic-attribute calls the cross-platform native UI renderer
(`src/ui/renderers/web_renderer.cr`) makes (see §6). It also means an
element *outside* this list (e.g. a `Div` with a non-standard `href`
attribute someone set by hand) is not covered — `href`/`src`/`action` are
only meaningful, browser-actioned URLs on the specific tags above, so that
is exactly the set that needed closing.

`srcset` gets its own type, `SafeSrcSet` — it's a comma-separated list of
`"<url> <descriptor>"` candidates, not a single URL, so `SafeURL` alone
can't validate it. `SafeSrcSet.parse!` validates every candidate's URL
through `SafeURL` and its descriptor against the width/density grammar
(`NNNw` / `N.Nx`), and rejects the **whole** value if any one candidate is
unsafe — fail closed, not "escape what we can."

`<meta http-equiv="refresh" content="...">` also gets its own constructor,
`Elements::Meta.safe_refresh(seconds, url : SafeURL)`, because its `content`
value is `"<seconds>; url=<URL>"` — a compound format, not a bare URL — so
handing it a `SafeURL` directly through the generic setter would produce the
wrong attribute value (missing the timing prefix), not just a validation
gap. `safe_refresh` validates the URL the same way any other URL-bearing
attribute is and assembles the compound string only from that validated
`SafeURL` plus a plain, checked-non-negative integer.

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

### 3.5 `<iframe srcdoc>` — HTML-document-valued attribute ban (2026-07-08)

```crystal
Components::Elements::Iframe.new(srcdoc: "<script>alert(1)</script>")
# => ArgumentError: SafeHTML ban: "srcdoc"=... rejected. <iframe srcdoc> is
#    an HTML-DOCUMENT-valued attribute ...
```

`srcdoc` looks like an ordinary attribute — a `String` — but it isn't one
semantically. Every other attribute value this shard escapes
(`escape_attribute`: `&`/`"`/`'`/`<`/`>`) is consumed by the browser as
*data* (a URL, a class name, an ARIA label, ...): entity-decoding it back
to the literal bytes never causes those bytes to be re-parsed as markup.
`srcdoc` breaks that assumption. The browser HTML-entity-decodes the
(correctly-escaped-for-the-*outer*-document) attribute value and then feeds
the **decoded result to a fresh HTML parser** as the entire source document
of the iframe's nested browsing context. A `<script>` inside that decoded
value executes — value-escaping is the right tool for keeping the *outer*
document well-formed, and does nothing at all for the *nested* one. This
makes `srcdoc` exactly as dangerous as `<script>` body content (§3.4), just
carried in an attribute instead of element children, and it gets the
identical treatment:

- A bare `String` is **rejected unconditionally** at every path a `String`
  could reach it: the constructor-kwarg path (`Iframe.new(srcdoc: ...)`,
  since `HTMLElement#initialize` calls `#set_attribute` once per kwarg),
  the direct `#set_attribute("srcdoc", ...)` path, and a **render-time
  backstop** in `Iframe#render_attributes` — because `@attributes` is a
  public, mutable `Hash` `getter` on `HTMLElement` (exactly like
  `Script#children` was, see §3.4's "path 3" closure), nothing stops
  `iframe.attributes["srcdoc"] = "..."` from mutating it directly,
  bypassing `#set_attribute` entirely. The render-time check re-verifies,
  immediately before emitting bytes, that whatever currently sits at
  `@attributes["srcdoc"]` is `==` the exact `String` that was vouched
  through one of the two doors below — a different value written into the
  Hash by any other means, even after a legitimate vouch already happened
  once, is rejected, fail-closed.
- Two reasoned doors remain, matching `Script.static`/`SafeURL.unsafe`'s
  shape (`reason:` mandatory, raises if blank):
  - **`Iframe.srcdoc(html, reason:, **attrs)`** — a typed constructor for a
    fresh `Iframe`, for the shape `Script.static` uses.
  - **`iframe.set_srcdoc(html, reason:)`** — a typed instance-level setter
    for an already-constructed `Iframe`, matching the shape
    `#set_safe_url_attribute`/`#set_safe_style` already use elsewhere in
    `HTMLElement`. This is the door the live call site below needed, since
    it builds the `Iframe` first (setting `loading`/`src`/`title`/
    `sandbox`) and only conditionally attaches `srcdoc` after.

Both doors still route the value through the ordinary attribute-value
escaping every attribute gets when rendered — that is correct, not a gap:
it is what keeps the *outer* document well-formed, and the browser decodes
it back losslessly before using it as the nested document's source.
`Iframe.srcdoc("<p>Hello</p>", reason: "...").render` is
`<iframe srcdoc="&lt;p&gt;Hello&lt;/p&gt;"></iframe>` — the round-trip is
intentional; the vouching gate is what's new, not a change to how the
byte-for-byte rendering works.

**The live call site this closed:** `web_renderer.cr:2106`
(`UI::Web::Renderer#visit(view : UI::WebViewComponent)`) called
`el.set_attribute("srcdoc", html)` with `html` sourced from
`UI::WebViewComponent#html` — an app-author-set `property` on the
cross-platform view (the same trust tier as `WebViewComponent#url`, not
interpolated end-user/request data flowing through the renderer). Migrated
to `el.set_srcdoc(html, reason: "UI::WebViewComponent#html is
app-author-supplied embedded web content, forwarded verbatim by the
platform-visitor bridge")`. Specs:
`spec/web/components/safe/iframe_srcdoc_safety_spec.cr` (the element-level
ban/backstop/doors) and the `UI::WebViewComponent#html` block in
`spec/web/ui/renderers/web_renderer_spec.cr` (the fixed call site,
end-to-end).

### 3.6 `<svg>` foreign content — text-node ban (2026-07-08)

`<svg>` is HTML5 "foreign content": the tokenizer switches namespace for
everything inside it, but a `<script>` element inside that namespace is
still recognized and **still executes** —
`<svg><script>alert(1)</script></svg>` is a well-known, browser-verified
XSS payload class, reachable inline in an ordinary HTML document (it does
not require a standalone `.svg` file or an `<img src="data:image/svg+xml,...">`
detour). Before this fix, `Elements::Svg` overrode `render_children` to
pass every `String` child through **completely unescaped** ("SVG content is
not escaped like HTML") — exactly as dangerous as `<script>` accepting a
plain-`String` child (§3.4), just reached through a different, public,
always-available element class. `Elements::Svg` had zero call sites
anywhere in this shard's `src/`, so nothing shipped was exploiting it —
but it is public API any downstream consumer of this shard could reach
directly (`Components::Elements::Svg.new << some_string`), which is a
worse residual-risk shape than dead code: a live, ungated, unused-so-far
foreign-content sink waiting on its first caller, not a defended one.

The fix is a **deletion**, not a new mechanism: the custom
`render_children` override is removed entirely, restoring the inherited
`ContainerElement#render_children` — the same safe-by-default behavior
every other container element already has. `HTMLElement`/`RawHTML`
children render exactly as before (element structure was never the
vulnerable part); a `String` child is now HTML-escaped like a text node
anywhere else. Legitimate hand-authored SVG markup (`<path d="...">` and
friends) uses the same pre-existing, documented, greppable raw door every
other element in this shard already has available —
`RawHTML.new(...)`/`#add_raw_html(...)` (§4) — no new escape hatch was
introduced for this. Specs:
`spec/web/components/safe/svg_foreign_content_safety_spec.cr`.

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
- There is deliberately **no** easy `SafeHTML.new(String)` — see §2.1.

**`raw()`/`SafeHTML.unsafe` is not the *only* raw door — it is the only
*reasoned* one.** Two more ways to inject unescaped markup exist and are
**not** gated by a mandatory `reason:`:

| Door | Reason required? | Where |
|---|---|---|
| `SafeHTML.unsafe(html, reason:)` / `raw(html, reason:)` | **Yes** — raises if blank | `src/components/safe/safe_html.cr` |
| `SafeURL.unsafe(url, reason:)` | **Yes** — raises if blank | `src/components/safe/safe_url.cr` |
| `Elements::RawHTML.new(html)` | **No** | `src/components/elements/base/raw_html.cr` |
| `ContainerElement#add_raw_html(html)` (thin wrapper over the above) | **No** | `src/components/elements/base/container_element.cr` |

`RawHTML.new`/`add_raw_html` are used throughout this shard today —
`Script.static`/`.json_data` build on `RawHTML.new` internally,
`SafeHTML#to_raw_html` uses it to bridge an *already-validated* `SafeHTML`
into the `Elements` children union (not a fresh hole — the bytes were
already vouched for), and roughly a dozen call sites in
`src/components/examples/*.cr` and `src/ui/renderers/web_renderer.cr` push
hand-built markup through `add_raw_html`/`RawHTML.new` directly, with no
`reason:` and no compiler-enforced justification.
`grep -rn 'RawHTML.new\|add_raw_html' src/` finds all of them — that grep,
not `grep -rn 'SafeHTML.unsafe\|\.raw('` alone, is the complete raw-door
audit for this shard as of v1. Unifying these onto a mandatory-`reason:`
API (matching `SafeHTML.unsafe`/`SafeURL.unsafe`) is a natural, bounded v1.x
follow-up — not done in this pass, to keep this hardening change scoped to
the sinks it was asked to close rather than a mechanical touch of ~20
existing call sites across `src/` and `spec/`.

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
  renderer) calls `HTMLElement#add_style(String)` roughly 180 times, plus a
  handful of `#set_attribute("href"/"src"/"action", value)` calls on `A`/
  `Img`/`Form`/`Iframe` instances. The `add_style` calls are genuinely
  untouched and unenforced by this v1 (see "the style gap" below) — every
  one of those ~180 strings is framework-computed (design tokens, `Color`
  fields already converted to RGB integers, layout enums), not
  attacker-controlled text forwarded from a component, so leaving `style`
  fully open here is a deliberate, bounded risk acceptance, not an oversight.
  The `href`/`src`/`action` calls are a **different case**: as of this v1
  they route through `Elements::UrlAttributeValidation` (§3.2) like any
  other caller of `A#set_attribute("href", ...)` etc. — that module is
  attached to the *element class*, not to a "new vs. legacy" call path, so
  there is no way for `web_renderer.cr`'s calls into these same classes to
  opt out of it. This required **zero code changes** in `web_renderer.cr`
  itself: every existing `href`/`src`/`action` value it passes today is
  already an `http(s)://` URL or a relative path (verified by grepping every
  URL-attribute literal and view value in `src/` and `spec/` at
  implementation time — none used a non-allowlisted scheme), so none of
  those call sites were ever at risk of the `SafeURL` check firing. The two
  `<script>` call sites in this file (both genuinely static JS constants)
  **were** migrated to `Script.static(...)`, since that was a 2-line,
  zero-risk fix that directly demonstrates the correct pattern.
- **The Amber v2 ECR compiler** (Front B of the hardening proposal) is
  explicitly a separate, later front (owner decision E4=B) and is untouched
  by this branch.

**Third residual, found and documented (not fixed) in the 2026-07-08
completeness sweep — `Elements::Style` body content.** `Style#<<`/
`#render_children` (`src/components/elements/document/style.cr`) accept and
render a `String` child **completely unescaped** ("Override rendering to
not escape CSS content") — the `<style>...</style>` **element** analog of
the `add_style` **attribute** residual above, same severity class, same
"framework-computed, not attacker-controlled" audit bar. Verified by
`grep -rn 'Elements::Style' src/`: exactly two call sites in this shard,
`web_renderer.cr`'s `CONTEXT_MENU_FALLBACK_CSS` and
`ACTION_SHEET_FALLBACK_CSS` — both `HEREDOC` constants with **zero**
`#{...}` interpolation (grepped and confirmed at audit time), i.e. genuinely
static, framework-authored CSS, not attacker-reachable text. **Severity,
explicitly, in contrast to `srcdoc` (§3.5) and `<svg>` (§3.6):** a raw
`<style>` body is a CSS-context-breakout sink (attribute-selector-based
data exfiltration, clickjacking-via-`position:fixed`, visual spoofing) —
**not** a script-execution sink. `srcdoc`/`<svg>` were closed in this same
session precisely *because* they yield full, unqualified script execution
and CSS-context sinks do not; that severity gap is the actual reason this
one stays a documented residual instead of also being closed. Extending
`Elements::Style` to require a typed `SafeStyle`-built body (or at minimum
an unconditional ban + a reasoned `Style.static(css, reason:)` door
mirroring `Script.static`) is the natural v1.x follow-up, tracked alongside
the `add_style` extension in §7.

**The v1 enforcement boundary, precisely (no "unconditional" claims that
aren't actually true):**

| Sink | Enforced unconditionally, on every element? | What's actually true |
|---|---|---|
| Attribute-*name* grammar (§3.1b) | **Yes.** `HTMLElement#set_attribute` calls `validate_attribute_name!` as the first thing it does, for every element, both construction paths — including elements that `include UrlAttributeValidation`, whose override calls `super` and lands here. | Genuinely unconditional, and the one check every other row in this table implicitly depends on: `on*`/`SafeURL`/etc. all reason about "the attribute named X," an assumption a malformed name (`/href`, `/onclick`, an embedded space/`=`/`>`/quote) could otherwise falsify. |
| `on*` inline handlers | **Yes.** `HTMLElement#validate_attribute` runs for every `#set_attribute` call on every element, both construction paths. | Genuinely unconditional — there is no element class and no attribute-setting path that skips it. |
| `<script>` body content | **Yes, for `Elements::Script` specifically.** A plain `String` child is rejected via `<<`, `add_child`/`add_children`, *and* a render-time backstop in `render_children` that re-checks `@children` regardless of how a value entered it (closes the public, mutable `children` getter as a bypass). | Unconditional *for the one element type this sink exists on* — there is no other element with executable-JS-context children. |
| URL-bearing attributes | **No — conditional on element type.** Only the elements listed in §3.2's table (`A`/`Link`#`href`, `Img`/`Script`/`Iframe`/`Source`/`Track`/`Embed`/`Audio`#`src`, `Video`#`src`+`poster`, `Area`/`Base`#`href`, `Form`#`action`) validate that attribute name through `SafeURL`, on both the constructor-kwarg and `#set_attribute` paths, no matter who the caller is (component code or `web_renderer.cr`) and no matter what casing or surrounding whitespace the caller spells the attribute name with (`href`/`HREF`/`Href`/`" href"`/`"href "` are all the same check to `UrlAttributeValidation`, matching HTML's own case-insensitive attribute-name matching). Every other element, and every other URL-shaped attribute name (`formaction`, `cite`, `ping`, SVG `href`/`xlink:href`, or a non-standard `data-href`-style attribute on any element), is **not** validated by anything except the fully opt-in `set_safe_url_attribute` typed setter. | Element-and-attribute-name-scoped, not global — but exhaustive across name casing/whitespace *within* that scope. `Div.new.set_attribute("href", "javascript:...")` is a no-op attribute (browsers ignore `href` on `<div>`), and is intentionally left unvalidated — extending the covered-element list is future work, not a hole in what v1 claims. |
| `style` attribute | **No — this is the one sink still fully open on the legacy path.** `set_safe_style` (typed, `SafeStyleValue`-only) enforces; `add_style(String)`/`set_attribute("style", "...")` (used ~180x by `web_renderer.cr`) accept and render a raw string completely unchecked, on every element, unconditionally. | This is the genuinely-unclosed half of the "two-tier" story — not a documentation gap, an actual scope boundary. CSS-context severity, not script execution — see the residual note above. |
| `<style>` element body | **No — same shape as the `style` attribute, on `Elements::Style` specifically.** No ban, no typed door; a `String` child renders raw. | Undocumented until the 2026-07-08 sweep; documented now as a residual (not closed) — CSS-context severity only, and both of the shard's two call sites are verified-static constants. See the residual note above. |
| `<iframe srcdoc>` | **Yes.** `Iframe#set_attribute` rejects a bare `String` unconditionally at both construction paths, plus a render-time backstop in `#render_attributes` that closes the public-mutable-`@attributes`-getter bypass. | Genuinely unconditional, added 2026-07-08 (§3.5) — closed, not residual, because a `srcdoc` sink yields full script execution, same severity tier as `<script>` body content. |
| `<svg>` foreign-content children | **Yes.** `Elements::Svg` no longer overrides `render_children`; a `String` child is HTML-escaped like every other element's text node, unconditionally. | Genuinely unconditional, added 2026-07-08 (§3.6) — closed, not residual, for the same full-script-execution reason as `srcdoc`. |

Extending `SafeStyle` enforcement onto the legacy `add_style`/`set_attribute`
path (and thereby onto the native UI renderer's ~180 calls) — mirroring what
this v1 already did for the URL-bearing element list — is the natural,
bounded follow-up left for v1.x/v2. It was not done in this pass because,
unlike the URL case, `web_renderer.cr`'s style strings were not individually
audited call-by-call against `SafeStyle`'s closed keyword/color/length
grammar (that grammar is intentionally much narrower than arbitrary CSS, and
~180 call sites is a large enough surface that doing so responsibly is its
own task, not a same-pass follow-on to the URL fix).

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
- **Extending `SafeStyle` enforcement onto the legacy `add_style`/
  `set_attribute("style", ...)` path** (§6) — the one sink this v1 leaves
  fully open. Same shape as the URL-attribute fix this v1 already shipped:
  either a `strict_attributes!`-style opt-in flag (default off) that flips
  once every `add_style` call site is audited against `SafeStyle`'s
  keyword/color/length grammar, or per-element enforcement the way
  `Elements::UrlAttributeValidation` closed the URL sink.
- **Widening `Elements::UrlAttributeValidation` coverage** — `formaction`
  (`Button`/`Input`), `cite` (`Blockquote`/`Ins`/`Del`), `ping` (`A`), `data`
  (`Object`), and SVG `href`/`xlink:href` (once this shard has an
  `href`/`xlink:href`-bearing SVG sub-element class, e.g. `Use`/`Image`) are
  still only reachable through the fully-generic, unvalidated
  `set_attribute`, or the opt-in `set_safe_url_attribute` typed setter.
- **Migrating the remaining ~18 example components** onto
  `render_safe_content`, retiring `String.build` from this shard's own
  component library entirely (not just the one exemplar).
- **Grep-gate retirement** (`escaping_gate.sh`, per proposal §7): once (a)
  no component defines the legacy `render_content` path, (b) HTML response
  sinks accept only `SafeHTML`, (c) `unsafe`/`raw` calls exist only in an
  audited allowlist, and (d) a structural CI gate replaces the grep gate,
  the grep gate can be deleted. None of those four conditions hold yet after
  this v1 — it ships the types and the exemplar, not the full migration.

---

## 8. Sink-class completeness sweep (2026-07-08)

Every prior gate on this branch closed exactly the one sink class the
adversarial pass happened to find that round (attribute *name* grammar,
then `SafeURL` case/whitespace bypasses, then `<script>` interpolation,
then `srcdoc`). This section is the answer to "what else is out there" —
the complete taxonomy of HTML-injection sink *classes* reachable through
`Components::Elements::*`, each one walked to a **CLOSED** (with a spec) or
an explicitly **DOCUMENTED RESIDUAL** verdict, so the next gate isn't
another single point-fix.

| # | Sink class | Verdict | One-line proof / rationale |
|---|---|---|---|
| (a) | HTML text context (element children) | **CLOSED**, shard-wide, with two now-fixed exceptions | `ContainerElement#render_children` HTML-escapes every `String` child by construction, for all ~94 element classes, with zero opt-out short of the documented `RawHTML`/`add_raw_html` raw door (§4/(i) below). Two elements previously carved themselves an *unescaped*-`String`-child exception outside that raw-door mechanism: `Elements::Script` (closed pre-existing, §3.4) and `Elements::Svg` (closed this session, §3.6). Grep proof: `grep -rn 'def render_children' src/components/elements/` returns exactly 4 overrides (`Script`, `Style`, `Svg`, `Pre`) plus the base `ContainerElement`/base `HTMLElement` definitions — `Style` is the one documented CSS-severity residual (§6), `Pre` still calls `escape_html` (only whitespace handling differs, not escaping — not a sink). |
| (b) | Attribute VALUE | **CLOSED**, unconditionally, shard-wide | `HTMLElement#render_attributes` runs every attribute value through `escape_attribute` (`&`/`"`/`'`/`<`/`>`), for every element, no opt-out — this is pre-v1 behavior, unchanged and re-verified this sweep. `srcdoc` (§3.5) is the one attribute where value-escaping alone is provably insufficient (because the *decoded* value is re-parsed as a nested document, not consumed as inert data) — that's a distinct sink class (g), not a hole in this one. |
| (c) | Attribute NAME | **CLOSED**, unconditionally, shard-wide (§3.1b) | `HTMLElement#set_attribute` calls `validate_attribute_name!` as the first thing it does, before any other check, for every element and both construction paths — re-verified this sweep: `grep -rn 'def set_attribute' src/components/elements/` returns exactly 2 definitions (`HTMLElement`, `UrlAttributeValidation`), and `UrlAttributeValidation#set_attribute` calls `super`, landing in the same chokepoint. No element overrides `set_attribute` in a way that skips it. |
| (d) | URL attributes (`href`/`src`/`action`/etc.) | **Element-scoped CLOSED + DOCUMENTED RESIDUAL for the rest** (§3.2/§6, unchanged this sweep except documentation accuracy) | Closed, unconditionally within scope, for `A`/`Link`#`href`, `Img`/`Script`/`Iframe`/`Source`/`Track`/`Embed`/`Audio`#`src`, `Video`#`src`+`poster`, `Area`/`Base`#`href`, `Form`#`action` — verified via `grep -rn 'include UrlAttributeValidation' src/components/elements/`. Residual, documented: `formaction` (`Button`/`Input`), `cite` (`Blockquote`/`Ins`/`Del`), `ping` (`A`), **`data` (`Object`, confirmed via this sweep — `Object` does not `include UrlAttributeValidation`)**, and SVG `href`/`xlink:href` (no `href`-bearing SVG sub-element class exists in this shard yet, corrected from a prior doc claim that no SVG element class existed at all — `Elements::Svg` itself does exist). Severity: URL-scheme injection (`javascript:`), not neutralized by escaping alone but also not silently full-script on every browser the way `srcdoc`/`<svg>` are — residual acceptable because these are all narrow, low-traffic attributes with no current call site (verified via `grep -rn` for each name across `src/`), unlike `srcdoc` which had a live call site. |
| (e) | CSS/style context | **DOCUMENTED RESIDUAL** (§6/§7, extended this sweep) | Two sub-sinks, same severity tier (CSS-context breakout, not script execution): the `style` **attribute** (`add_style`/`set_attribute("style", ...)`, ~180 call sites in `web_renderer.cr`, all framework-computed, pre-existing documented residual) and the `<style>` **element body** (`Elements::Style`, newly documented this sweep, exactly 2 call sites, both verified-static constants — see §6). Neither yields script execution; both are accepted, bounded risk, tracked as v1.x/v2 follow-up in §7. |
| (f) | JS / `<script>` body | **CLOSED**, unconditionally, three-path closure (§3.4, pre-existing, re-verified) | `Elements::Script` rejects a bare `String` at `<<`, `add_child`/`add_children`, and a render-time backstop in `render_children` that closes the public-mutable-`children`-getter bypass. Two typed doors (`Script.static`/`Script.json_data`) remain. Re-verified green this sweep: `spec/web/components/safe/script_element_safety_spec.cr`. |
| (g) | HTML-document-valued attributes (`srcdoc` and siblings) | **CLOSED this session** (§3.5) | `srcdoc` was the only HTML-document-valued attribute found on any of the ~94 element classes in this shard (the compound-but-URL-based `<meta refresh>` `content` attribute is a different, already-closed shape, §3.2). Swept every element file for a second HTML-valued (as opposed to URL-valued) attribute — none found. `Elements::Iframe#set_attribute`/`#render_attributes` now reject a bare `String` unconditionally, three-path closure matching (f); typed doors `Iframe.srcdoc`/`#set_srcdoc`. Spec: `spec/web/components/safe/iframe_srcdoc_safety_spec.cr`, plus the fixed `web_renderer.cr:2106` call site covered end-to-end in `spec/web/ui/renderers/web_renderer_spec.cr`. |
| (h) | `<template>`/SVG/MathML foreign-content or other exotic sinks | **CLOSED for the one foreign-content element this shard has** (§3.6) | No `Elements::Template` or MathML element class exists in this shard (`grep -rn 'class Template\|MathML' src/components/elements/` — no matches), so those are not-yet-applicable, not open sinks. `Elements::Svg` is the one foreign-content element class present; its raw/unescaped-`String`-child override is removed this session (§3.6), closing the one live exotic-sink shape that existed. If/when `Template`/MathML element classes are added, this row should be re-audited — `<template>` content in particular has its own HTML5 parsing quirks (inert `content` document fragment) that would need a fresh review, not an assumption that this sweep already covers it. |
| (i) | Raw doors (`RawHTML`/`add_raw_html`/`raw`/`unsafe`) | **DOCUMENTED RESIDUAL by design** (§4, unchanged, re-counted this sweep) | These are deliberately the escape hatch, not a bug. Two are gated with a mandatory, non-blank `reason:` (`SafeHTML.unsafe`/`raw`, `SafeURL.unsafe`) and are loud/greppable. Two are not reason-gated (`Elements::RawHTML.new`, `ContainerElement#add_raw_html`) — re-counted this sweep via `grep -rn 'RawHTML.new\|add_raw_html' src/` (excluding the base-class definitions themselves): 9 call sites (`components.cr`, `web_renderer.cr` ×2, `integration.cr`, `reactive_component.cr`, and four `src/components/examples/*.cr` files), consistent with §4's "roughly a dozen" — all pre-existing, none touched by this session, all already covered by §4's policy note that unifying these onto a mandatory-`reason:` API is bounded v1.x follow-up work, not a v1 gap. |

**Net effect of this sweep:** two sink classes were found genuinely open
and **closed** in this session — `srcdoc` (g) and `<svg>` foreign content
(h), both full-script-execution severity, both now gated exactly like
`<script>` body content. One sink class was found open, undocumented, and
**left open but now documented** — `<style>` element body (part of (e)) —
because its severity (CSS-context, not script execution) matches the
already-accepted `add_style` residual bar, not the srcdoc bar. Every other
category was already closed by a prior gate on this branch and is
re-verified, not re-litigated, here. The residual list going into v1.x/v2
is therefore: the `style`-attribute/`<style>`-element CSS-context pair (e),
the narrow-and-currently-unused URL-attribute tail (d), and the explicit,
by-design raw doors (i) — short, and each one individually a lower-severity
or lower-reachability shape than the two that got closed.
