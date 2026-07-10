---
name: build-ui
description: Build UI components using the Crystal component system — knows all 94 HTML elements, 3 component tiers, composition patterns, and the builder DSL
user-invocable: true
---

# Build UI with the Crystal Component System

You are a front-end developer who builds server-rendered UIs using the asset pipeline's type-safe Crystal component system. All HTML is generated from Crystal classes — no templates needed.

## Core Patterns

### Creating Elements

```crystal
# Every HTML tag is a Crystal class under Components::Elements
div = Components::Elements::Div.new(class: "container")
div << "Hello, World!"
div.render  # => <div class="container">Hello, World!</div>
```

### Builder DSL

```crystal
article = Components::Elements::Article.new(class: "post").build do |art|
  header = Components::Elements::Header.new
  h1 = Components::Elements::H1.new
  h1 << "Title"
  header << h1
  art << header

  p = Components::Elements::P.new
  p << "Content here."
  art << p
end
article.render
```

### Child Management

- `element << child` — append child (String, HTMLElement, Component, or RawHTML)
- `element.add_children(child1, child2)` — append multiple
- `element.build { |el| ... }` — block DSL for building content
- `Components::Elements::RawHTML.new(html_string)` — insert pre-rendered HTML without escaping

---

## Element Reference (94 Classes)

All classes live under `Components::Elements`. Constructor: `.new(**attrs)` unless noted.

### Document Elements

| Class | Tag | Factory Methods |
|-------|-----|-----------------|
| `Html` | `<html>` | — (render includes `<!DOCTYPE html>`) |
| `Head` | `<head>` | — |
| `Body` | `<body>` | — |
| `Title` | `<title>` | — (text children only) |
| `Meta` | `<meta>` | `.charset(charset?)`, `.viewport(content?)`, `.description(text)`, `.keywords(text)`, `.author(text)`, `.http_equiv(equiv, content)` |
| `Link` | `<link>` | `.stylesheet(href)`, `.icon(href, type?)`, `.favicon(href)`, `.apple_touch_icon(href, sizes?)`, `.manifest(href)`, `.preconnect(href)`, `.prefetch(href)`, `.preload(href, as_type)` |
| `Script` | `<script>` | `.new(js_string)` — content not escaped |
| `Style` | `<style>` | `.new(css_string)` — content not escaped |

### Section Elements

| Class | Tag | Notes |
|-------|-----|-------|
| `Header` | `<header>` | |
| `Footer` | `<footer>` | |
| `Nav` | `<nav>` | |
| `Main` | `<main>` | |
| `Article` | `<article>` | |
| `Section` | `<section>` | |
| `Aside` | `<aside>` | |
| `H1` - `H6` | `<h1>` - `<h6>` | All inherit from `Heading` |

### Grouping Elements

| Class | Tag | Notes |
|-------|-----|-------|
| `Div` | `<div>` | |
| `Span` | `<span>` | |
| `P` | `<p>` | |
| `Pre` | `<pre>` | Content not escaped (preserves whitespace) |
| `Blockquote` | `<blockquote>` | Validates `cite` URL |
| `Ol` | `<ol>` | Validates `type` (1/a/A/i/I), `start` |
| `Ul` | `<ul>` | |
| `Li` | `<li>` | Validates `value` (integer) |
| `Dl` | `<dl>` | |
| `Dt` | `<dt>` | |
| `Dd` | `<dd>` | |
| `Figure` | `<figure>` | |
| `Figcaption` | `<figcaption>` | |
| `Hr` | `<hr>` | Void element |

### Text Semantics

| Class | Tag | Notes |
|-------|-----|-------|
| `A` | `<a>` | Validates `target`, `rel`, `download` |
| `Em` | `<em>` | |
| `Strong` | `<strong>` | |
| `Small` | `<small>` | |
| `S` | `<s>` | |
| `Cite` | `<cite>` | |
| `Code` | `<code>` | |
| `Sub` | `<sub>` | |
| `Sup` | `<sup>` | |
| `I` | `<i>` | |
| `B` | `<b>` | |
| `U` | `<u>` | |
| `Mark` | `<mark>` | |
| `Del` | `<del>` | Validates `cite`, `datetime` |
| `Ins` | `<ins>` | Validates `cite`, `datetime` |
| `Abbr` | `<abbr>` | |
| `Time` | `<time>` | Validates `datetime` |
| `Data` | `<data>` | Requires `value` attribute |
| `Var` | `<var>` | |
| `Kbd` | `<kbd>` | |
| `Samp` | `<samp>` | |

### Form Elements

| Class | Tag | Factory Methods / Notes |
|-------|-----|------------------------|
| `Form` | `<form>` | Validates `method` (GET/POST/dialog), `enctype`, `autocomplete` |
| `Input` | `<input>` | **18 factory methods** — see below |
| `Textarea` | `<textarea>` | `.new(name, value?)`, validates `rows`/`cols`/`wrap` |
| `Select` | `<select>` | Validates `size`, `multiple`, `required` |
| `Option` | `<option>` | `.new(text, value?)`, validates `selected`/`disabled` |
| `Optgroup` | `<optgroup>` | Validates `label` (required), `disabled` |
| `Button` | `<button>` | `.new(text, type?)` — defaults to `type="button"` |
| `Label` | `<label>` | `.new(text, for?)` |
| `Fieldset` | `<fieldset>` | Validates `disabled` |
| `Legend` | `<legend>` | |
| `Datalist` | `<datalist>` | |
| `Output` | `<output>` | Validates `for` (space-separated IDs) |
| `Progress` | `<progress>` | Validates `value`/`max` (non-negative) |
| `Meter` | `<meter>` | Validates `value`/`min`/`max`/`low`/`high`/`optimum` |

**Input Factory Methods** (all return `Input` with correct `type` set):

```crystal
Input.text("username")           Input.email("email")
Input.password("pass")           Input.number("qty")
Input.checkbox("agree", "yes")   Input.radio("plan", "pro")
Input.submit("Save")             Input.button("Click")
Input.hidden("token", "abc")     Input.file("upload")
Input.date("birthday")           Input.time("alarm")
Input.datetime_local("meeting")  Input.range("volume", "0", "100")
Input.color("theme")             Input.search("query")
Input.tel("phone")               Input.url("website")
```

### Table Elements

| Class | Tag | Notes |
|-------|-----|-------|
| `Table` | `<table>` | |
| `Thead` | `<thead>` | |
| `Tbody` | `<tbody>` | |
| `Tfoot` | `<tfoot>` | |
| `Tr` | `<tr>` | |
| `Th` | `<th>` | Validates `scope` (row/col/rowgroup/colgroup), `colspan`/`rowspan` |
| `Td` | `<td>` | Validates `colspan`/`rowspan` |
| `Caption` | `<caption>` | |
| `Colgroup` | `<colgroup>` | Validates `span` |
| `Col` | `<col>` | Void element, validates `span` |

### Embedded / Media

| Class | Tag | Notes |
|-------|-----|-------|
| `Img` | `<img>` | Void. Validates `loading` (lazy/eager), `decoding`, `crossorigin` |
| `Video` | `<video>` | Validates `controls`/`autoplay`/`loop`/`muted`/`playsinline`, `preload` |
| `Audio` | `<audio>` | Validates `controls`/`autoplay`/`loop`/`muted`, `preload` |
| `Source` | `<source>` | Void. Validates MIME type, media queries |
| `Track` | `<track>` | Void. Validates `kind`, `srclang` |
| `Iframe` | `<iframe>` | Validates `sandbox`, `loading` |
| `Embed` | `<embed>` | Void. Validates MIME type |
| `Object` | `<object>` | Validates MIME type |
| `Param` | `<param>` | Void. Requires `name`/`value` |
| `Canvas` | `<canvas>` | |
| `Svg` | `<svg>` | Content not escaped |
| `Picture` | `<picture>` | |

### Interactive Elements

| Class | Tag | Notes |
|-------|-----|-------|
| `Details` | `<details>` | Validates `open` (boolean) |
| `Summary` | `<summary>` | |
| `Dialog` | `<dialog>` | Validates `open` (boolean) |
| `Menu` | `<menu>` | |

### Void Elements

| Class | Tag |
|-------|-----|
| `Br` | `<br>` |
| `Hr` | `<hr>` |
| `Area` | `<area>` — validates `shape`, `coords`, `target` |
| `Base` | `<base>` — validates `target` |
| `Wbr` | `<wbr>` |

---

## Component Tiers

### StatelessComponent

Pure render function. Cached by default. Use for presentational components.

```crystal
class AlertComponent < Components::StatelessComponent
  def render_content : String
    div = Components::Elements::Div.new(class: "alert alert-#{@attributes["variant"]? || "info"}")
    div << (@attributes["message"]? || "")
    div.render
  end
end

AlertComponent.new(variant: "success", message: "Saved!").render
```

### StatefulComponent

Maintains internal JSON state with change tracking. Use for forms and interactive server-side components.

```crystal
class TodoComponent < Components::StatefulComponent
  protected def initialize_state
    set_state("items", JSON::Any.new([] of JSON::Any))
    set_state("draft", "")
  end

  def render_content : String
    # Access state with get_state("key")
    # Update state with set_state("key", value)
    # Check if changed with changed?
  end
end
```

State methods:
- `initialize_state` — override to set initial values
- `get_state(key) : JSON::Any?` — read state
- `set_state(key, value)` — write state (accepts String, Int32, Int64, Float64, Bool, Array, Hash, JSON::Any)
- `changed? : Bool` — true if state modified since last render
- `state_changed(key, old_value, new_value)` — callback hook

### ReactiveComponent

Extends StatefulComponent with WebSocket broadcasting. Use for real-time features.

```crystal
class NotificationComponent < Components::Reactive::ReactiveComponent
  protected def initialize_state
    set_state("count", 0)
  end

  def render_content : String
    # Renders wrapped in div with data-component-id and data-component-type
  end

  on_action(:mark_read) { |data|
    set_state("count", 0)
    # auto-broadcasts to connected clients
  }
end
```

Reactive methods:
- `register` / `unregister` — lifecycle with ReactiveHandler
- `push_update` — manually broadcast current state
- `update_state { |s| ... }` — batch state changes
- `on_event(name, &block)` — macro for server events
- `on_action(name, &block)` — macro for client-triggered actions
- `auto_update` property — set to false to disable auto-broadcasting on set_state

---

## Component CSS

Register CSS scoped to a component class:

```crystal
class CardComponent < Components::StatelessComponent
  component_css <<-CSS
    .card { border: 1px solid var(--color-gray-200); border-radius: 0.5rem; }
    .card-header { padding: 1rem; font-weight: 600; }
    .card-body { padding: 1rem; }
  CSS

  def render_content : String
    # ...
  end
end
```

Component CSS is collected by `ComponentCSSRegistry` and emitted in the `@layer components` block, below tokens/base but above utilities — so utility classes always win.

---

## Common Recipes

### Page Layout

```crystal
page = Components::Elements::Html.new(lang: "en").build do |html|
  head = Components::Elements::Head.new
  head << Components::Elements::Meta.charset
  head << Components::Elements::Meta.viewport
  head << Components::Elements::Title.new.build { |t| t << "My App" }
  head << Components::Elements::Link.stylesheet("/css/app.css")
  html << head

  body = Components::Elements::Body.new
  body << Components::Elements::Header.new.build { |h|
    nav = Components::Elements::Nav.new(class: "main-nav")
    # ... build nav items
    h << nav
  }
  body << Components::Elements::Main.new.build { |m|
    m << Components::Elements::H1.new.build { |h1| h1 << "Welcome" }
  }
  body << Components::Elements::Footer.new.build { |f| f << "2026 My App" }
  html << body
end
page.render
```

### Navigation Bar

```crystal
nav = Components::Elements::Nav.new(class: "navbar", role: "navigation").build do |n|
  ul = Components::Elements::Ul.new(class: "nav-list")
  [{"Home", "/"}, {"About", "/about"}, {"Contact", "/contact"}].each do |label, href|
    li = Components::Elements::Li.new(class: "nav-item")
    a = Components::Elements::A.new(href: href, class: "nav-link")
    a << label
    li << a
    ul << li
  end
  n << ul
end
```

### Data Table

```crystal
table = Components::Elements::Table.new(class: "data-table")
thead = Components::Elements::Thead.new
header_row = Components::Elements::Tr.new
["Name", "Email", "Role"].each do |col|
  th = Components::Elements::Th.new(scope: "col")
  th << col
  header_row << th
end
thead << header_row
table << thead

tbody = Components::Elements::Tbody.new
users.each do |user|
  tr = Components::Elements::Tr.new
  [user.name, user.email, user.role].each do |val|
    td = Components::Elements::Td.new
    td << val
    tr << td
  end
  tbody << tr
end
table << tbody
```

### Form with Labels

```crystal
form = Components::Elements::Form.new(method: "POST", action: "/login")
fieldset = Components::Elements::Fieldset.new

email_label = Components::Elements::Label.new("Email", for: "email")
email_input = Components::Elements::Input.email("email")
email_input.set_attribute("id", "email")
email_input.set_attribute("required", "true")

pass_label = Components::Elements::Label.new("Password", for: "password")
pass_input = Components::Elements::Input.password("password")
pass_input.set_attribute("id", "password")

submit = Components::Elements::Input.submit("Sign In")

fieldset.add_children(email_label, email_input, pass_label, pass_input, submit)
form << fieldset
```

### Modal Dialog

```crystal
# Trigger button
btn = Components::Elements::Button.new("Open Settings", type: "button")
btn.set_attribute("popovertarget", "settings-dialog")

# Dialog
dialog = Components::Elements::Dialog.new(id: "settings-dialog", class: "modal")
dialog.set_attribute("popover", "auto")
dialog.build do |d|
  d << Components::Elements::H2.new.build { |h| h << "Settings" }
  d << Components::Elements::P.new.build { |p| p << "Configure your preferences." }
  close = Components::Elements::Button.new("Close", type: "button")
  close.set_attribute("popovertarget", "settings-dialog")
  close.set_attribute("popovertargetaction", "hide")
  d << close
end
```

### Accordion

```crystal
faq = Components::Elements::Div.new(class: "accordion")
[{"What is this?", "A component system."}, {"How does it work?", "Crystal classes."}].each do |q, a|
  details = Components::Elements::Details.new(class: "accordion-item")
  summary = Components::Elements::Summary.new
  summary << q
  details << summary
  content = Components::Elements::P.new(class: "accordion-content")
  content << a
  details << content
  faq << details
end
```

### Embedding Components

```crystal
class PageComponent < Components::StatelessComponent
  def render_content : String
    main = Components::Elements::Main.new

    # Embed another component's output
    card = CardComponent.new(title: "Welcome", subtitle: "Get started")
    main << card.to_raw_html

    # Or use RawHTML directly
    main << Components::Elements::RawHTML.new(ButtonComponent.new(label: "Click").render)

    main.render
  end
end
```

---

## Rendering in Amber

```crystal
# In a controller
class PostsController < Amber::Controller::Base
  def show
    component = PostComponent.new(title: @post.title, body: @post.body)
    render html: component.render
  end
end

# Using view helpers (include Components::AmberIntegration::ViewHelpers)
<%= component(CardComponent, title: "Hello") %>
<%= css_styles %>
<%= reactive_scripts %>
```

## Key Rules

- All attributes are validated at construction time — invalid values raise `ArgumentError`
- String children are HTML-escaped automatically; use `RawHTML` for pre-rendered content
- `Script`, `Style`, `Svg`, and `Pre` elements do NOT escape their children
- `VoidElement` subclasses (Img, Input, Br, etc.) raise if you try to add children
- `add_class` automatically registers with `ClassRegistry` for CSS generation
