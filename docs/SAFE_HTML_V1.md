# SafeHTML v1 — the auto-escape output contract (Front A)

> **Status:** Shipped, v1 (safe-html-v1 branch). Re-gated 2026-07-08 to
> close the `<iframe srcdoc>` HTML-document-valued attribute sink and the
> `<svg>` foreign-content text-node sink, plus a systematic completeness
> sweep of every HTML-injection sink class in this shard — see §3.5, §3.6,
> and **§8 (the completeness sweep)**.
> **Re-gated again, same day, to close the GENERAL root cause behind all
> of the above:** every one of the five prior gates on this branch closed
> exactly one `set_attribute`-time bypass, but `attributes` (and
> `children`) are **public, mutable `getter`s** — a direct
> `element.attributes["SRCDOC"] = "..."` (or `"/href"`, `" onclick"`, any
> case/whitespace-varied key) mutates the live `Hash` and never touches
> `set_attribute` at all, so it skipped every check that used to live only
> there. The convergent fix makes `HTMLElement#render_attributes` — the one
> place every attribute is turned into bytes, regardless of how it entered
> `@attributes` — the **sole, complete, unbypassable validation authority**,
> re-run by normalized name against whatever is currently live. Also closes
> the `<style>` element body as a `</style>`-breakout **script-execution**
> sink (previously a documented CSS-severity residual) with the same
> ban-plus-typed-door treatment as `<script>`/`srcdoc`. A Codex xhigh
> adversarial pass commissioned as part of this re-gate additionally found
> `Object#data` misclassified as a low-severity residual when it is
> actually unconditional, on-parse script execution via a `data:` URI —
> closed the same session. See **§3.7** (the render-time authority),
> **§3.8** (`<style>` body closure), and **§3.9** (`Object#data` closure).
> **Same day, follow-up fix:** `Button`/`Input#formaction` — the one
> remaining URL-attribute-tail item that was a live gap in the render-time
> authority's own declared-element list rather than a genuinely open
> residual — closed via the identical `include UrlAttributeValidation`
> two-line pattern. See **§3.10**.
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
| URL-bearing attributes on link/src-bearing elements (`A`/`Link`#`href`, `Img`/`Script`/`Iframe`/`Source`/`Track`/`Embed`/`Audio`#`src`, `Video`#`src`+`poster`, `Area`/`Base`#`href`, `Form`#`action`, `Object`#`data`, `Button`/`Input`#`formaction`) | Validated through `SafeURL` on **every** construction/`#set_attribute` call for that attribute name on that element, matched case-insensitively and with surrounding whitespace ignored (`HREF`, `Href`, `" href"`, `"href "` all match `"href"`) — not just the typed setter — **and** re-checked at render regardless of entry path (§3.7) | `HTMLElement#set_safe_url_attribute` (typed path) **and** `Elements::UrlAttributeValidation` (included by each of the elements above; enforces the same `SafeURL` check on the ordinary `String`-typed `#set_attribute`/constructor-kwarg path too) **and** `HTMLElement#render_attributes` (render-time authority, §3.7) |
| URL-bearing attributes not on the list above (`cite` on `Blockquote`/`Ins`/`Del`, `ping` on `A`, SVG `href`/`xlink:href`, arbitrary `data-*`/custom attributes on any element) | Not enforced in v1 — only reachable via the typed `set_safe_url_attribute` setter or the fully-generic, unchecked `set_attribute`. **`data` on `Object` was in this row until 2026-07-08 — see §3.9 for why it was pulled out and closed separately, ahead of the rest of this tail. `formaction` on `Button`/`Input` was in this row until 2026-07-08 — see §3.10 for its closure, mirroring `Object#data`'s.** | *(no per-attribute enforcement; see §6 and §8(d))* |
| `<meta http-equiv="refresh" content="N; url=...">` | Dedicated typed constructor (the `content` value is a *compound* format, not a plain URL, so the generic URL setter is the wrong shape for it) | `Elements::Meta.safe_refresh(seconds, SafeURL)` |
| `srcset` | Require a `SafeSrcSet` (own parser — a URL *list with descriptors*, not a single URL) | `Components::SafeSrcSet` |
| SVG `href` / `xlink:href` | `set_safe_url_attribute` works by attribute *name*, so it covers this the moment it's called — `Elements::Svg` exists in this shard (see the `<svg>` foreign-content row below) but does not itself have an `href`/`xlink:href`-bearing child element class yet (no `Elements::Use`/`Elements::Image` SVG-specific class), so the *attribute* case remains untested/theoretical even though the *element* it would apply to is real. Corrects a stale claim in a prior revision of this doc that said "no SVG element classes in this shard yet." | *(no SVG `href`/`xlink:href`-bearing element class in this shard yet)* |
| `style` | Require a `SafeStyleValue` via the new typed setter (never a raw string) | `HTMLElement#set_safe_style` / `Components::SafeStyle` |
| `<script>` body | Plain `String` children **rejected outright** | `Elements::Script#<<` |
| `<iframe srcdoc>` | **HTML-document-valued** attribute — plain `String` **rejected unconditionally**, on the constructor-kwarg path, the `#set_attribute` path, *and* the render-time authority (matching the `<script>`-body ban's three-path closure) | `Elements::Iframe#set_attribute` (call-time) / `HTMLElement#render_attributes` via `Iframe#document_sink_attribute?` (render-time, authoritative — §3.7) — typed doors: `Iframe.srcdoc(html, reason:)` / `#set_srcdoc(html, reason:)` |
| `<svg>` foreign-content children | `String` children **HTML-escaped by construction**, same as every other element (previously rendered raw/unescaped — see §3.6) | `Elements::Svg` (no override; inherits `ContainerElement#render_children`) |
| Attribute name/`on*`/`SafeURL`/`srcdoc` enforcement when the attribute reached `@attributes` through something OTHER than `#set_attribute` (a direct `element.attributes["..."] = ...` mutation, any case/whitespace-varied key) | **Closed** — the full suite re-runs at render, by normalized name, against whatever is currently live, regardless of provenance | `HTMLElement#render_attributes` / `#validate_rendered_attribute!` (§3.7) |
| `<style>` body | **Plain `String` children rejected outright** (2026-07-08, reclassified from a documented CSS-severity residual — see §3.8: `</style>` is a script-execution breakout, not just a CSS-context one) | `Elements::Style#<<` / `#render_children` — typed door: `Style.css(css, reason:)` |

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
`href`, `Form`#`action`, `Object`#`data` (added 2026-07-08, §3.9),
`Button`/`Input`#`formaction` (added 2026-07-08, §3.10). Each
override declares which attribute name(s) on
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

### 3.7 The render-time validation authority — the GENERAL fix for public-mutable-getter bypasses (2026-07-08)

Every fix in §3.1–§3.6 shares a structural weakness a re-gate found by
stepping back from the individual sinks: `HTMLElement#attributes` is a
public, mutable `getter` (`Hash(String, String)`). Every check this
document describes up to this point — `validate_attribute_name!`, the
`on*` ban, `UrlAttributeValidation`'s `SafeURL` check, `Iframe`'s old
`srcdoc` ban — lived at `#set_attribute` time. None of them see a direct
mutation of the Hash:

```crystal
f = Components::Elements::A.new
f.attributes["/href"] = "javascript:alert(document.cookie)"   # bypasses set_attribute entirely
f.render   # before this fix: rendered the live payload, unchecked

iframe = Components::Elements::Iframe.new
iframe.attributes["SRCDOC"] = "<script>alert(1)</script>"     # a DIFFERENT Hash key than "srcdoc"
iframe.render   # before this fix: Iframe's old render-time recheck only looked at the exact key "srcdoc" — this sailed past it
```

Five prior gates on this branch each closed exactly one concrete
`set_attribute`-time bypass (a malformed name, a case-varied `href`, a
`<script>` child, a case-varied `srcdoc`). Point-fixing every future
case/whitespace/key variant of every sink is an unbounded list — the same
lesson §3.1b already drew for attribute *names* specifically, generalized
here to the whole validation story.

**The convergent fix:** `HTMLElement#render_attributes` — the one place
every attribute, however it entered `@attributes`, is turned into
bytes — is now the **sole, complete, unbypassable validation authority**.
Immediately before emitting each attribute, `#validate_rendered_attribute!`
re-runs the full suite, keyed by `name.strip.downcase`, against whatever is
*currently* sitting in `@attributes`:

```crystal
protected def validate_rendered_attribute!(name : String, value : String) : Nil
  validate_attribute_name!(name)                    # (a) name grammar, on the RAW name
  key = name.strip.downcase
  raise ... if event_handler_attribute_name?(key)   # (b) on* ban, normalized
  if url_bearing_attribute?(key)                    # (c) SafeURL, normalized
    SafeURL.parse!(value) rescue raise ...
  end
  if document_sink_attribute?(key)                  # (d) HTML-document-valued attrs, normalized
    raise ... unless @vouched_document_attributes[key]? == value
  end
end
```

- **(a) Attribute-name grammar** — unchanged from §3.1b, just now also
  invoked on the *render* path, so a malformed name written directly into
  `@attributes` (not just one passed to `#set_attribute`) is caught.
- **(b) The `on*` ban** — `event_handler_attribute_name?` is the same
  predicate `validate_attribute` already used, extracted so both the
  call-time and render-time checks share one implementation instead of two
  copies that could drift.
- **(c) `SafeURL` on url-bearing attributes** — reuses each element's
  existing `url_bearing_attribute?` override (declared once, by
  `include UrlAttributeValidation`, exactly as before) — no element needed
  to change to get this; the same per-element predicate that used to only
  gate `#set_attribute` now also gates render.
- **(d) HTML-document-valued attributes** — generalizes what `Iframe` used
  to do with its own `@vouched_srcdoc` ivar and one-off
  `render_attributes` override into a base-class mechanism:
  `document_sink_attribute?(name)` (default `false`, override per element)
  and `vouch_document_attribute(name, value)` (called only from a typed
  door) record the vouched value under the **normalized** name in
  `@vouched_document_attributes`. Because both the check and the storage
  key off `name.strip.downcase`, a case/whitespace-varied direct mutation
  (`attributes["SRCDOC"] = ...`) is a *different* entry in the
  `Hash(String, String)` than any legitimately-vouched `"srcdoc"` entry —
  but `render_attributes` iterates **every** live attribute, so that
  different entry is still individually checked and still fails closed.

**What did NOT change:** `set_attribute`-time enforcement
(`validate_attribute_name!`, `validate_attribute`,
`UrlAttributeValidation#set_attribute`, `Iframe#set_attribute`'s `srcdoc`
ban) is still there, unmodified — it is valuable as a **fail-fast** error
at the call site that caused the bad value, before any half-built state
exists. It is simply no longer what makes rendering safe; `render_attributes`
is, unconditionally, regardless of how a value reached `@attributes`.
`Elements::Script`'s `render_children` (§3.4) already anticipated this
exact shape for `children`; §3.7 is that same idea applied to `attributes`,
generalized across every check instead of one sink at a time.

Specs: `spec/web/components/safe/render_time_attribute_authority_spec.cr`
(the general authority, exercised via direct `attributes[...] = ...`
mutation for each of (a)–(d)); `iframe_srcdoc_safety_spec.cr`'s "path 3c"
(a case-varied `SRCDOC` key alongside an already-legitimately-vouched
`srcdoc` key — two distinct Hash entries, both checked).

### 3.8 `<style>` element body — `</style>` breakout ban (2026-07-08)

```crystal
Components::Elements::Style.new << "body{}</style><script>alert(1)</script>"
# => ArgumentError: SafeHTML ban: <style> does not accept a plain String child...
```

Before this fix, `Elements::Style#render_children` passed a `String` child
through **completely unescaped** ("Override rendering to not escape CSS
content") and was documented (§6, prior revision) as an accepted CSS-context
residual on the theory that a raw `<style>` body is "attribute-selector
data exfiltration / clickjacking / visual spoofing — not script execution."
That theory is wrong: `</style>` is a real, tokenizer-recognized close tag
regardless of what precedes it in the text — the HTML parser does not care
that it's "inside CSS", it is scanning for the literal byte sequence. A
`String` containing `</style><script>alert(document.cookie)</script>`
closes the `<style>` element early and lets the browser parse and **execute**
the injected `<script>` in the surrounding document. This is the identical
severity class as `<script>` body interpolation (§3.4) and `<iframe srcdoc>`
(§3.5) — full script execution — not the lower-severity CSS-context-breakout
tier the `style` **attribute** (`add_style`, §6) still occupies. It gets the
identical treatment:

- A bare `String` child is **rejected unconditionally** at every path a
  `String` could reach it: `<<`, `add_child`/`add_children`, *and* a
  render-time backstop in `render_children` that re-checks `@children`
  regardless of how a value entered it (closes the public, mutable
  `children` getter as a bypass, exactly like `Script`).
- One reasoned door remains, matching `Script.static`'s shape (`reason:`
  mandatory, raises if blank): **`Style.css(css, reason:, **attrs)`** — a
  typed constructor for genuinely static, author-controlled CSS with no
  interpolated untrusted data. (`Elements::RawHTML.new(css)` appended
  directly works too — `Style.css` is the ergonomic, reason-enforcing
  wrapper around that, identical to `Script.static`'s relationship with
  `RawHTML`.)
- The previous unreasoned convenience constructor `Style.new(css : String)`
  is **removed** — there is no unreasoned door for `<style>` body content,
  matching `Script` (which never had one either).

**The two call sites this closed:** `web_renderer.cr`'s
`CONTEXT_MENU_FALLBACK_CSS` and `ACTION_SHEET_FALLBACK_CSS` — both `HEREDOC`
constants with **zero** `#{...}` interpolation (the same static-constant
audit bar `Script.static`'s two call sites in this file passed, §3.4) —
migrated to `Style.css(CONSTANT, reason: "static framework-authored ...
CSS constant — no interpolated data")`.

Specs: `spec/web/components/safe/style_element_safety_spec.cr` (the
element-level ban/backstop/typed-door, mirroring
`script_element_safety_spec.cr` example-for-example).

### 3.9 `<object data>` — closed ahead of the rest of the URL-attribute tail (2026-07-08)

```crystal
Components::Elements::Object.new(data: "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==")
# => ArgumentError: SafeHTML ban: "data"="data:text/html;base64,..." rejected — SafeURL: scheme "data" is not allowed...
```

`Object#data` was one of §3.2's documented residuals — `formaction`,
`cite`, `ping`, `data`, and SVG `href`/`xlink:href` were all grouped
together as "narrow, low-traffic, no current call site." A Codex xhigh
adversarial pass commissioned by the render-time-authority re-gate (§3.7)
found that grouping conflated two different severity tiers. `href`/
`action`/`formaction`/`ping` all require the browser to *navigate* or
*fetch* — a user click, a form submission — before a `javascript:`/
non-allowlisted scheme could matter, and for `ping` specifically, browsers
never even fetch a non-HTTP(S) ping URL, so it's not exploitable there at
all. `data` on `<object>` is different in kind: `<object data="...">`
loads its resource into a **child navigable** and, for an HTML-typed
resource (including a `data:text/html,...` URI), renders it as an embedded
document and executes any `<script>` inside — **unconditionally, the
moment the browser parses the element**, no user interaction required.
That is the same on-parse severity as `srcdoc` (§3.5), `<svg>` foreign
content (§3.6), and `<style>` body (§3.8) — not the "requires a click"
tier the rest of the URL-attribute tail occupies.

Unlike those three sinks, `Object` had never even attempted validation —
it simply didn't `include Elements::UrlAttributeValidation`. The fix is
exactly the two-line pattern every other URL-bearing element already uses
(`Embed`/`Iframe`'s `src`, `Form`'s `action`, ...):

```crystal
class Object < ContainerElement
  include UrlAttributeValidation

  protected def url_bearing_attribute?(name : String) : Bool
    name == "data"
  end
  # ...
end
```

Because the render-time authority (§3.7) enforces `SafeURL` on **whatever**
an element declares via `url_bearing_attribute?` — not a hand-maintained
list duplicated at the render chokepoint — this one declaration closes
`data` on both the call-time path (`UrlAttributeValidation#set_attribute`)
and the render-time/direct-mutation path simultaneously, with zero changes
to `HTMLElement` itself. This is the render-time authority working exactly
as designed: extending coverage to a new element is a two-line, purely
additive declaration, not a new backstop.

Pulled out of the general URL-attribute-tail residual (§3.2/§8(d)) and
closed on its own because of this severity gap — `cite`/`ping`/SVG
`href`/`xlink:href` remain residual (§7), `data` on `Object` does not
(`formaction` on `Button`/`Input` was pulled out and closed the same day
too — see §3.10, immediately below — though for a different reason: not a
severity miscategorization, just a trivial known fix applying this same
pattern to the two elements that were missed). Specs:
`spec/web/components/safe/url_attribute_validation_spec.cr`'s
`Components::Elements::Object` block (adversarial `javascript:`/`data:`
rejection at both paths, case-varied name, legitimate `https`/relative
`data` unaffected) and
`spec/web/components/safe/render_time_attribute_authority_spec.cr` (a
case-varied `DATA` key written directly through the public `attributes`
getter, neutralized at render).

### 3.10 `Button`/`Input#formaction` — closed as the render-time authority's last URL-attribute residual (2026-07-08)

```crystal
Components::Elements::Button.new(type: "submit", formaction: "javascript:alert(document.cookie)")
# => ArgumentError: SafeHTML ban: "formaction"="javascript:alert(document.cookie)" rejected — SafeURL: scheme "javascript" is not allowed...
```

`formaction` (on a `type="submit"`/`type="image"` `Button` or `Input`)
overrides the owning `<form>`'s `action` for that one submitter — a
`javascript:` `formaction`, once that button/input submits its form, is
evaluated as a classic script by the navigation algorithm, exactly the same
sink `Form#action` (§3.2) already closes, and exactly the "requires
submitter activation" severity tier §3.9/§8(d) already reasoned about (not
the on-parse, no-click tier `data` on `Object` occupies). Unlike `data` on
`Object`, this was not a severity miscategorization found by an adversarial
pass — it was simply the one item on the render-time authority's (§3.7)
declared-URL-attribute list that was never widened to include these two
elements, even though their sibling `A#href`/`Form#action`/`Object#data`
all went through the identical closure. `Button` and `Input` previously did
not `include Elements::UrlAttributeValidation` at all, so `formaction`
reached them entirely unvalidated through the constructor-kwarg path, the
`#set_attribute` path, *and* the render-time/direct-mutation path alike.

The fix is the exact two-line pattern `Object#data` (§3.9) used:

```crystal
class Button < ContainerElement
  include UrlAttributeValidation

  protected def url_bearing_attribute?(name : String) : Bool
    name == "formaction"
  end
  # ...
end
```

(`Input` gets the identical two lines — it is a `VoidElement`, not a
`ContainerElement`, but `UrlAttributeValidation` is agnostic to that
distinction.) Because the render-time authority (§3.7) enforces `SafeURL`
on **whatever** an element declares via `url_bearing_attribute?`, these two
declarations close `formaction` on the call-time path
(`UrlAttributeValidation#set_attribute`) and the render-time/direct-mutation
path simultaneously, with zero changes to `HTMLElement` itself or to the
render chokepoint — the same "extending coverage is purely additive"
property §3.9 demonstrated.

This closes the render-time authority's URL-attribute tail down to `cite`
(`Blockquote`/`Ins`/`Del`, not independently script-executing — browsers
never fetch or render `cite`'s value) and `ping` (`A`, confirmed not
script-executing — a non-HTTP(S) `ping` URL is dropped before fetch) and
SVG `href`/`xlink:href` (no `href`/`xlink:href`-bearing SVG element class
exists in this shard yet, per §3.2). Specs:
`spec/web/components/safe/url_attribute_validation_spec.cr`'s
`Components::Elements::Button` and `Components::Elements::Input` blocks
(adversarial `javascript:`/`data:`/`vbscript:` rejection via both the
constructor-kwarg and `#set_attribute` paths, legitimate `https`/relative
`formaction` unaffected) and
`spec/web/components/safe/regate_direct_mutation_spec.cr` (every
case/whitespace-varied `formaction`/`FORMACTION`/`" formaction"` key
written directly through the public `attributes` getter, on both elements,
neutralized at render; a legitimate direct-mutation `formaction` still
renders).

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

**Third residual, found in the 2026-07-08 completeness sweep and CLOSED
later the same day (re-gate) — `Elements::Style` body content.** This was
originally documented here as a residual on the theory that a raw
`<style>` body is only a CSS-context-breakout sink (attribute-selector data
exfiltration, clickjacking, visual spoofing) — lower severity than
`srcdoc`/`<svg>`, which yield full script execution. **That theory was
wrong and has been corrected**: `</style>` is a real, tokenizer-recognized
close tag no matter what precedes it — `"</style><script>alert(1)</script>"`
closes the element early and executes the injected `<script>` in the
surrounding document, the same full-script-execution severity as `srcdoc`/
`<svg>`. `Style#<<`/`#render_children` now reject a bare `String`
unconditionally (constructor/`<<`/`add_child`/`add_children`, plus a
render-time backstop closing the public-mutable-`children`-getter bypass),
with `Style.css(css, reason:)` as the one typed door — see §3.8 for the
full closure and the migrated call sites. The `style` **attribute**
residual (`add_style`/`set_attribute("style", ...)`, immediately below) is
a **genuinely different, lower-severity, still-open** sink — CSS-context
only, not script-execution — and is unaffected by this closure.

**The v1 enforcement boundary, precisely (no "unconditional" claims that
aren't actually true):**

| Sink | Enforced unconditionally, on every element? | What's actually true |
|---|---|---|
| Attribute-*name* grammar (§3.1b, §3.7) | **Yes, at TWO points.** `HTMLElement#set_attribute` calls `validate_attribute_name!` first (fail-fast, call-time), for every element, both construction paths. `HTMLElement#render_attributes`/`#validate_rendered_attribute!` (§3.7) calls it AGAIN, on the raw name, for every attribute currently in `@attributes` — including one written directly through the public `attributes` getter, bypassing `#set_attribute` entirely. | Genuinely unconditional at the render-time point (the one that actually can't be bypassed), and the one check every other row in this table implicitly depends on: `on*`/`SafeURL`/`srcdoc`/etc. all reason about "the attribute named X," an assumption a malformed name (`/href`, `/onclick`, an embedded space/`=`/`>`/quote) could otherwise falsify. |
| `on*` inline handlers | **Yes, at TWO points.** `HTMLElement#validate_attribute` runs at call-time for every `#set_attribute` call. `#validate_rendered_attribute!` (§3.7) re-runs the same `event_handler_attribute_name?` predicate at render, keyed by `name.strip.downcase`, against whatever is currently in `@attributes`. | Genuinely unconditional at render — no element class, no attribute-setting path, and no direct `attributes[...] = ...` mutation skips it. |
| `<script>` body content | **Yes, for `Elements::Script` specifically.** A plain `String` child is rejected via `<<`, `add_child`/`add_children`, *and* a render-time backstop in `render_children` that re-checks `@children` regardless of how a value entered it (closes the public, mutable `children` getter as a bypass). | Unconditional *for the one element type this sink exists on* — there is no other element with executable-JS-context children (other than `<style>`'s body — a distinct sink, see below). |
| URL-bearing attributes | **No — conditional on element type; but where covered, checked at TWO points.** Only the elements listed in §3.2's table (`A`/`Link`#`href`, `Img`/`Script`/`Iframe`/`Source`/`Track`/`Embed`/`Audio`#`src`, `Video`#`src`+`poster`, `Area`/`Base`#`href`, `Form`#`action`, `Object`#`data`, `Button`/`Input`#`formaction`) declare `url_bearing_attribute?`. That predicate now gates BOTH `UrlAttributeValidation#set_attribute` (call-time) AND `HTMLElement#render_attributes`/`#validate_rendered_attribute!` (render-time, §3.7) — so a `javascript:` URL written directly into `@attributes` (bypassing `#set_attribute` altogether, any casing) is caught at render even though it never touched the call-time check. Every other element, and every other URL-shaped attribute name (`cite`, `ping`, SVG `href`/`xlink:href`, or a non-standard `data-href`-style attribute on any element), is **not** validated by anything except the fully opt-in `set_safe_url_attribute` typed setter. | Element-and-attribute-name-scoped, not global — but exhaustive across name casing/whitespace *and* entry path (constructor, `#set_attribute`, or direct Hash mutation) *within* that scope. `Div.new.set_attribute("href", "javascript:...")` is a no-op attribute (browsers ignore `href` on `<div>`), and is intentionally left unvalidated — extending the covered-element list is future work, not a hole in what v1 claims (except `Object`#`data`, elevated and closed — §3.9 — because it was the one item in that "future work" bucket that was actually unconditionally script-executing, and `Button`/`Input`#`formaction`, closed — §3.10 — as a trivial known fix applying the same declared-URL-attribute mechanism to the two elements that had been missed). |
| `style` attribute | **No — this is the one sink still fully open on the legacy path.** `set_safe_style` (typed, `SafeStyleValue`-only) enforces; `add_style(String)`/`set_attribute("style", "...")` (used ~180x by `web_renderer.cr`) accept and render a raw string completely unchecked, on every element, unconditionally. `url_bearing_attribute?`/`document_sink_attribute?` are both `false` for `"style"` on every element, so the §3.7 render-time authority intentionally does not touch it either — this sink is genuinely out of scope for this gate, not an oversight. | This is the genuinely-unclosed half of the "two-tier" story — not a documentation gap, an actual scope boundary. CSS-context severity, not script execution. |
| `<style>` element body | **Yes, for `Elements::Style` specifically (2026-07-08, §3.8 — reclassified from a documented residual to CLOSED).** A plain `String` child is rejected via `<<`, `add_child`/`add_children`, *and* a render-time backstop in `render_children`, matching `<script>`'s three-path closure exactly. | Unconditional *for the one element type this sink exists on* — corrected from a prior claim that this was merely a CSS-context sink: `</style>` is a real tokenizer close tag, so this is full script execution, the same severity as `<script>`/`srcdoc`, not the `style`-attribute tier above. |
| `<iframe srcdoc>` | **Yes, at TWO points.** `Iframe#set_attribute` rejects a bare `String` unconditionally at both construction paths (call-time, fail-fast). `HTMLElement#render_attributes`'s single authority (§3.7), via `Iframe#document_sink_attribute?`, re-checks EVERY live attribute by normalized name at render — closing not just the exact-key `"srcdoc"` direct-mutation bypass §3.5 originally closed, but also a case/whitespace-varied key (`"SRCDOC"`, `" srcdoc"`) written as a *different* Hash entry, which the original per-element `render_attributes` override (checking only the exact key) would have missed. | Genuinely unconditional at render, added 2026-07-08 (§3.5), generalized the same day (§3.7) — closed, not residual, because a `srcdoc` sink yields full script execution, same severity tier as `<script>`/`<style>` body content. |
| `<svg>` foreign-content children | **Yes.** `Elements::Svg` no longer overrides `render_children`; a `String` child is HTML-escaped like every other element's text node, unconditionally. | Genuinely unconditional, added 2026-07-08 (§3.6) — closed, not residual, for the same full-script-execution reason as `srcdoc`. |
| Any attribute reaching `@attributes` via a path OTHER than `#set_attribute` (direct `element.attributes["..."] = ...` mutation, any key casing/whitespace) | **Yes, for every check above that applies to that attribute's normalized name.** This is what §3.7 closes generally: `render_attributes` iterates every entry currently in `@attributes` and validates each one by normalized name, with no dependency on how that entry got there. | Genuinely unconditional, added 2026-07-08 (§3.7) — this is the row that makes every "Yes" above actually true regardless of entry path, not just the `#set_attribute`/constructor paths a caller is expected to use. |

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

- ~~`Object#data`~~ — **CLOSED, 2026-07-08, same session, immediately after
  being flagged.** A Codex xhigh adversarial pass commissioned by the
  render-time-authority re-gate found this item in the URL-attribute
  residual tail was misclassified — unlike the rest of that tail, `data`
  on `Elements::Object` is unconditionally script-executing (no user
  interaction required, same severity as `srcdoc`/`<svg>`/`<style>` body).
  Because the fix was a two-line, zero-risk, mechanically-obvious
  application of infrastructure this same re-gate had just built
  (`include UrlAttributeValidation` + `url_bearing_attribute?` returning
  `name == "data"` — the render-time authority, §3.7, picks up any
  element's declaration automatically), it was closed immediately rather
  than deferred. See §3.9 for the full writeup. Left in this list,
  struck through, so the "found via Codex, closed same-session" trail is
  visible rather than silently edited out.
- ~~`formaction` (`Button`/`Input`)~~ — **CLOSED, 2026-07-08, same day.**
  Not a severity miscategorization like `Object#data` above — `formaction`
  was always correctly reasoned as "script-executing but requires submitter
  activation," the same tier as `href`/`action`. It was simply the one
  declared-URL-attribute gap the render-time authority's own element list
  hadn't been widened to cover yet. Closed via the identical two-line
  `include UrlAttributeValidation` + `url_bearing_attribute?` pattern. See
  §3.10 for the full writeup. Left in this list, struck through, for the
  same reason as `Object#data` above.
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
- **Widening `Elements::UrlAttributeValidation` coverage for the rest of
  the tail** — `cite` (`Blockquote`/`Ins`/`Del`), `ping` (`A`), and SVG
  `href`/`xlink:href` (once this shard has an `href`/`xlink:href`-bearing
  SVG sub-element class, e.g. `Use`/`Image`) are still only reachable
  through the fully-generic, unvalidated `set_attribute`, or the opt-in
  `set_safe_url_attribute` typed setter. (`data` on `Object` — formerly
  the highest-severity item in this list — was closed the same session it
  was found; see §3.9. `formaction` on `Button`/`Input` was closed the
  same day too, as a trivial known fix, not a severity finding; see
  §3.10. `cite` and `ping` are confirmed NOT script-executing — see §8 row
  (d) — so widening those two is a data-integrity nicety, not a security
  fix.)
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

> **Table below is as of the first 2026-07-08 sweep; rows (a) and (e) were
> superseded a few hours later, same day, by the render-time-authority
> re-gate — see the correction note and new row (j) immediately after the
> table.** Left as originally written (rather than silently edited) so this
> section stays an honest record of what each pass actually found, matching
> how §6's residual note handles the same correction.

| # | Sink class | Verdict | One-line proof / rationale |
|---|---|---|---|
| (a) | HTML text context (element children) | **CLOSED**, shard-wide, with two now-fixed exceptions | `ContainerElement#render_children` HTML-escapes every `String` child by construction, for all ~94 element classes, with zero opt-out short of the documented `RawHTML`/`add_raw_html` raw door (§4/(i) below). Two elements previously carved themselves an *unescaped*-`String`-child exception outside that raw-door mechanism: `Elements::Script` (closed pre-existing, §3.4) and `Elements::Svg` (closed this session, §3.6). Grep proof: `grep -rn 'def render_children' src/components/elements/` returns exactly 4 overrides (`Script`, `Style`, `Svg`, `Pre`) plus the base `ContainerElement`/base `HTMLElement` definitions — `Style` is the one documented CSS-severity residual (§6), `Pre` still calls `escape_html` (only whitespace handling differs, not escaping — not a sink). |
| (b) | Attribute VALUE | **CLOSED**, unconditionally, shard-wide | `HTMLElement#render_attributes` runs every attribute value through `escape_attribute` (`&`/`"`/`'`/`<`/`>`), for every element, no opt-out — this is pre-v1 behavior, unchanged and re-verified this sweep. `srcdoc` (§3.5) is the one attribute where value-escaping alone is provably insufficient (because the *decoded* value is re-parsed as a nested document, not consumed as inert data) — that's a distinct sink class (g), not a hole in this one. |
| (c) | Attribute NAME | **CLOSED**, unconditionally, shard-wide (§3.1b) | `HTMLElement#set_attribute` calls `validate_attribute_name!` as the first thing it does, before any other check, for every element and both construction paths — re-verified this sweep: `grep -rn 'def set_attribute' src/components/elements/` returns exactly 2 definitions (`HTMLElement`, `UrlAttributeValidation`), and `UrlAttributeValidation#set_attribute` calls `super`, landing in the same chokepoint. No element overrides `set_attribute` in a way that skips it. |
| (d) | URL attributes (`href`/`src`/`action`/etc.) | **Element-scoped CLOSED + DOCUMENTED RESIDUAL for the (now genuinely lower-severity) rest, severity corrected, `Object#data` closed by the render-time-authority re-gate's Codex xhigh pass, AND `Button`/`Input#formaction` closed as a same-day trivial known fix** (§3.2/§6/§3.9/§3.10) | Closed, unconditionally within scope, for `A`/`Link`#`href`, `Img`/`Script`/`Iframe`/`Source`/`Track`/`Embed`/`Audio`#`src`, `Video`#`src`+`poster`, `Area`/`Base`#`href`, `Form`#`action`, — **closed 2026-07-08, §3.9** — `Object`#`data`, and — **closed 2026-07-08, §3.10** — `Button`/`Input`#`formaction` — verified via `grep -rn 'include UrlAttributeValidation' src/components/elements/`. Residual, documented, **NOT uniformly the same severity** (corrected — a prior revision of this row claimed none of the remaining tail is "silently full-script on every browser," which is true for what's left but was NOT true of `data`, which is why `data` no longer belongs in this row): `ping` (`A`) — confirmed NOT script-executing: compliant browsers only fetch an HTTP(S) ping URL, a non-HTTP(S) scheme (including `javascript:`) is dropped before fetch, never executed. `formaction` (`Button`/`Input`) was genuinely script-executing (a `javascript:` `formaction`, once that button submits its form, is evaluated as a classic script by the navigation algorithm) but **required submitter activation** (a real form submission), the same user-interaction gate `href`/`action` already have — that lower-than-`data` severity is exactly why it sat in this residual row as long as it did, but it was still a live gap in the render-time authority's own declared-element list, so it was closed anyway (§3.10) rather than left open on a severity technicality. `cite` (`Blockquote`/`Ins`/`Del`) — not independently script-executing; browsers do not fetch or render `cite`'s value at all, it is metadata only. **`data` on `Object` was the one item in this row that was genuinely, unconditionally script-executing with NO user interaction required** — `<object data="data:text/html;base64,...">` loads the `data:` URI into a child navigable and renders it as an HTML document, executing any `<script>` inside, same severity tier as `srcdoc`/`<svg>`/`<style>` body — and is **no longer in this residual row**: it was pulled out and closed the same session it was found (§3.9), via the exact two-line `include UrlAttributeValidation` + `url_bearing_attribute?` pattern every other closed item in this row already uses. `formaction` is **no longer in this residual row either** (§3.10), via the identical two-line pattern. What remains in this row (`cite`, `ping`, SVG `href`/`xlink:href`) is genuinely narrow, low-traffic, no live call site (verified via `grep -rn` for each name across `src/`), and none of it is unconditional/on-parse script execution. |
| (e) | CSS/style context | **DOCUMENTED RESIDUAL** (§6/§7, extended this sweep) | Two sub-sinks, same severity tier (CSS-context breakout, not script execution): the `style` **attribute** (`add_style`/`set_attribute("style", ...)`, ~180 call sites in `web_renderer.cr`, all framework-computed, pre-existing documented residual) and the `<style>` **element body** (`Elements::Style`, newly documented this sweep, exactly 2 call sites, both verified-static constants — see §6). Neither yields script execution; both are accepted, bounded risk, tracked as v1.x/v2 follow-up in §7. |
| (f) | JS / `<script>` body | **CLOSED**, unconditionally, three-path closure (§3.4, pre-existing, re-verified) | `Elements::Script` rejects a bare `String` at `<<`, `add_child`/`add_children`, and a render-time backstop in `render_children` that closes the public-mutable-`children`-getter bypass. Two typed doors (`Script.static`/`Script.json_data`) remain. Re-verified green this sweep: `spec/web/components/safe/script_element_safety_spec.cr`. |
| (g) | HTML-document-valued attributes (`srcdoc` and siblings) | **CLOSED this session** (§3.5) | `srcdoc` was the only HTML-document-valued attribute found on any of the ~94 element classes in this shard (the compound-but-URL-based `<meta refresh>` `content` attribute is a different, already-closed shape, §3.2). Swept every element file for a second HTML-valued (as opposed to URL-valued) attribute — none found. `Elements::Iframe#set_attribute`/`#render_attributes` now reject a bare `String` unconditionally, three-path closure matching (f); typed doors `Iframe.srcdoc`/`#set_srcdoc`. Spec: `spec/web/components/safe/iframe_srcdoc_safety_spec.cr`, plus the fixed `web_renderer.cr:2106` call site covered end-to-end in `spec/web/ui/renderers/web_renderer_spec.cr`. |
| (h) | `<template>`/SVG/MathML foreign-content or other exotic sinks | **CLOSED for the one foreign-content element this shard has** (§3.6) | No `Elements::Template` or MathML element class exists in this shard (`grep -rn 'class Template\|MathML' src/components/elements/` — no matches), so those are not-yet-applicable, not open sinks. `Elements::Svg` is the one foreign-content element class present; its raw/unescaped-`String`-child override is removed this session (§3.6), closing the one live exotic-sink shape that existed. If/when `Template`/MathML element classes are added, this row should be re-audited — `<template>` content in particular has its own HTML5 parsing quirks (inert `content` document fragment) that would need a fresh review, not an assumption that this sweep already covers it. |
| (i) | Raw doors (`RawHTML`/`add_raw_html`/`raw`/`unsafe`) | **DOCUMENTED RESIDUAL by design** (§4, unchanged, re-counted this sweep) | These are deliberately the escape hatch, not a bug. Two are gated with a mandatory, non-blank `reason:` (`SafeHTML.unsafe`/`raw`, `SafeURL.unsafe`) and are loud/greppable. Two are not reason-gated (`Elements::RawHTML.new`, `ContainerElement#add_raw_html`) — re-counted this sweep via `grep -rn 'RawHTML.new\|add_raw_html' src/` (excluding the base-class definitions themselves): 9 call sites (`components.cr`, `web_renderer.cr` ×2, `integration.cr`, `reactive_component.cr`, and four `src/components/examples/*.cr` files), consistent with §4's "roughly a dozen" — all pre-existing, none touched by this session, all already covered by §4's policy note that unifying these onto a mandatory-`reason:` API is bounded v1.x follow-up work, not a v1 gap. |
| (j) | Public-mutable-`getter` bypass of every check above (§3.7, found and CLOSED in the re-gate that superseded this table) | **CLOSED, unconditionally, shard-wide** | The GENERAL root cause underneath (c), (d), (g): `attributes` is a public, mutable `Hash(String, String)` `getter`, so a direct `element.attributes["SRCDOC"] = "..."` (or `"/href"`, `" onclick"`, any case/whitespace-varied key) bypasses `#set_attribute` — and therefore every check that lived only there — entirely. `HTMLElement#render_attributes`/`#validate_rendered_attribute!` (§3.7) now re-runs the full suite ((a)/(c)/(g) from this table, plus the `on*` ban) by normalized name against whatever is *currently* in `@attributes`, closing this for every element and every one of those checks in one place, not per-sink. Also folded into this same re-gate: `<style>` element body (part of (e) below) was found to be full-script-execution severity, not CSS-context, and closed to match (f)/(g)/(h) — see the row-(e) correction note and §3.8. Specs: `spec/web/components/safe/render_time_attribute_authority_spec.cr`, `spec/web/components/safe/style_element_safety_spec.cr`. |
| (k) | `Object#data` (§3.9, found by the re-gate's Codex xhigh pass and CLOSED the same session) | **CLOSED, unconditionally** | Was misclassified as part of row (d)'s "requires a click, low severity" residual tail; a Codex xhigh adversarial pass found `<object data="data:text/html,...">` is actually unconditional, on-parse script execution (same tier as (f)/(g)/(h)/`<style>` body), not click-gated like `href`/`action`/`formaction`. Closed via `Object.include Elements::UrlAttributeValidation` + `url_bearing_attribute?` returning `name == "data"` — the render-time authority (j) picks up the declaration automatically, so this one two-line change closes both the call-time and render-time/direct-mutation paths at once. Spec: `spec/web/components/safe/url_attribute_validation_spec.cr`'s `Object` block, plus a direct-mutation case in `render_time_attribute_authority_spec.cr`. |
| (l) | `Button`/`Input#formaction` (§3.10, the render-time authority's last live URL-attribute gap, CLOSED the same day as (k)) | **CLOSED, unconditionally** | Unlike (k), not a severity miscategorization — `formaction`'s "requires submitter activation" tier in row (d)'s text was and remains accurate. It was simply the one item in the render-time authority's own declared-element list (§3.7/§3.2) that `Button`/`Input` had never been widened to cover, even though the sibling `A#href`/`Form#action`/`Object#data` closures used the identical mechanism. Closed via `Button.include Elements::UrlAttributeValidation` + `Input.include Elements::UrlAttributeValidation`, each declaring `url_bearing_attribute?` returning `name == "formaction"` — the render-time authority (j) picks up both declarations automatically, closing the call-time and render-time/direct-mutation paths on both elements at once. Spec: `spec/web/components/safe/url_attribute_validation_spec.cr`'s `Button` and `Input` blocks, plus case/whitespace-varied direct-mutation cases in `regate_direct_mutation_spec.cr`. |

**Correction to row (a):** `Style` is no longer the CSS-severity residual
that row's "4 overrides" note describes — `Elements::Style#render_children`
now rejects a plain-`String` child exactly like `Script`, so the accurate
count is "4 overrides, of which `Script` and `Style` both reject bare
`String` children and `Svg` inherits the base escaping behavior — only
`Pre` is a non-escaping-relevant whitespace-only override." See §3.8.

**Correction to row (e):** the `<style>` **element body** half of this row
is **no longer a documented residual — it is CLOSED** (§3.8, same-day
re-gate). The theory that a raw `<style>` body was merely a CSS-context
sink was wrong: `</style>` is a real tokenizer close tag regardless of
context, so it is full-script-execution severity, matching (f)/(g)/(h), not
the CSS-context tier. The `style` **attribute** half of this row
(`add_style`/`set_attribute("style", ...)`) is unaffected and remains the
one genuinely open, lower-severity residual — see the row-(e) text above
and §6.

**Net effect of this sweep, as amended by the same-day re-gate:** three
sink classes were found genuinely open and **closed** across the two
passes on 2026-07-08 — `srcdoc` (g), `<svg>` foreign content (h), and
`<style>` element body (part of (e), corrected from residual to closed) —
all three full-script-execution severity, all three now gated by a typed,
`reason:`-carrying door. A fourth, structural issue was found and
**closed** by the re-gate: the public-mutable-`getter` bypass (j) that let
a direct `Hash` mutation with a case/whitespace-varied key route around
every one of the above checks, regardless of which one. A fifth item —
`Object#data` (k) — was found by the Codex xhigh adversarial pass this
re-gate commissioned specifically to hunt for anything the first four
missed, and was **closed in the same session**, immediately, rather than
deferred: it had been sitting in row (d)'s "low severity, requires a
click" residual bucket, but is actually unconditional, on-parse script
execution — the same tier as (f)/(g)/(h). Every other category was
already closed by a prior gate on this branch and is re-verified, not
re-litigated, here.

**The residual list this gate's mandate is scoped against — every item on
it non-script-executing, and every item explicitly reasoned or explicitly
out of scope — is exactly two items:** the `style` **attribute**
CSS-context residual (`add_style`/`set_attribute("style", ...)`, ~180
framework-computed call sites in `web_renderer.cr`, explicitly out of
scope — the generic native-renderer `add_style` ATTRIBUTE path, as opposed
to the `<style>` ELEMENT body closed in §3.8), and the explicit, by-design,
reason-carrying raw doors (`SafeHTML.unsafe`/`raw`/`SafeURL.unsafe`, each
individually loud, greppable, and mandatory-`reason:`-gated).

Two more items exist in the codebase and are **unchanged, pre-existing, and
out of scope for this gate specifically** (this gate reuses each element's
already-declared `url_bearing_attribute?`/raw-door set at the render
chokepoint — per its own mandate it does not widen which attributes/doors
are covered, with the one deliberate exception immediately below): the two
NOT-reason-gated raw doors from row (i) (`RawHTML.new`/`add_raw_html` —
accepted, unreasoned-by-design escape hatches per §4, not touched by this
gate), and what's left of the narrow-and-currently-unused URL-attribute
tail from row (d) (`cite`/`ping`/SVG `href`/`xlink:href` — not covered by
ANY check, call-time or render-time, because the elements that carry them
never declared `url_bearing_attribute?` in the first place; widening that
declared set further is future work per §7, not this gate's mandate —
none of what's left in this tail is unconditional/on-parse script
execution, see row (d)'s corrected text).

**Update, same day, following gate — `formaction` (`Button`/`Input`)
closed, §3.10/row (l):** the paragraph above (and the two before it) is
left as this gate's own contemporaneous record and originally listed
`formaction` alongside `cite`/`ping`/SVG `href`/`xlink:href` in the
narrow, out-of-scope URL-attribute tail. A follow-up gate the same day
found that `formaction` was the one item in that tail that was actually a
trivial, in-scope, known fix — `Button`/`Input` simply hadn't been
widened onto the exact `include UrlAttributeValidation` mechanism this
same re-gate had just generalized — and closed it via §3.10's two-line
pattern. `cite`/`ping`/SVG `href`/`xlink:href` remain the residual tail;
`formaction` no longer does.

**Correction from the Codex xhigh adversarial pass this same re-gate
commissioned — and the one deliberate scope exception above:** an earlier
draft of this section claimed all of row (d) is "not script-executing on
its own... requires a user navigation/click to execute." **That claim was
only true for `ping`/`formaction`/`cite`, not for `data` on `Object`.**
`Object#data` was confirmed genuinely, UNCONDITIONALLY script-executing —
`<object data="data:text/html;base64,...">` loads the `data:` URI into a
child navigable and executes any `<script>` inside it with **no user
interaction required**, the same on-parse severity as `srcdoc`/`<svg>`/
`<style>`-body, not the "requires a click" tier `formaction`/`href`/
`action` occupy. Because this failed the "residual list is exactly two
items, both non-script-executing" bar the paragraph above holds itself to,
it was **not** left as a documented residual — it was pulled out of row
(d) and **closed in this same session**, via the exact
`include UrlAttributeValidation` + `url_bearing_attribute?` pattern this
gate's own render-time authority was built to make trivial to apply. See
§3.9 for the full writeup and §8 row (k). This is the one place this
gate's stated scope ("reuse the declared set, don't widen it") was
deliberately overridden — because the alternative was knowingly leaving a
gate's own residual list mischaracterized as non-script-executing when it
wasn't, which the gate's own acceptance criterion does not allow.
