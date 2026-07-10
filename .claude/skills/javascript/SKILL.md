---
name: javascript
description: Add interactivity with Import Maps, Stimulus controllers, and reactive components — FrontLoader API, StimulusRenderer, WebSocket components
user-invocable: true
---

# JavaScript & Interactivity

You are a JavaScript integration specialist for the asset pipeline. The framework uses ESM import maps for dependency management, Stimulus for lightweight interactivity, and reactive components for real-time server-side updates via WebSocket. No heavy JS frameworks.

## Import Map System

The `FrontLoader` class manages JavaScript imports and script rendering.

### Setup

```crystal
# Initialize with import maps
FRONT_LOADER = AssetPipeline::FrontLoader.new do |import_maps|
  app = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # CDN dependencies
  app.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")

  # Local controllers (naming convention: *Controller)
  app.add_import("HelloController", "controllers/hello_controller.js")
  app.add_import("DropdownController", "controllers/dropdown_controller.js")
  app.add_import("FormValidationController", "controllers/form_validation_controller.js")

  import_maps << app
end
```

### Rendering in Views

```crystal
# In your layout (ECR)
<head>
  <%= FRONT_LOADER.render_import_map("application") %>
</head>
<body>
  <!-- content -->
  <script type="module">
    <%= FRONT_LOADER.render_stimulus_initialization_script %>
  </script>
</body>
```

`render_import_map` generates:
```html
<script type="importmap">
{
  "imports": {
    "@hotwired/stimulus": "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js",
    "HelloController": "/javascript/controllers/hello_controller.js",
    ...
  }
}
</script>
```

---

## Stimulus Integration

The `StimulusRenderer` automatically detects controllers from import maps and generates registration code.

### Controller Naming Convention

Import names ending in `Controller` are auto-detected and registered:

| Import Name | Stimulus Identifier | Registration |
|-------------|--------------------|----|
| `HelloController` | `hello` | `application.register("hello", HelloController)` |
| `DropdownController` | `dropdown` | `application.register("dropdown", DropdownController)` |
| `FormValidationController` | `form-validation` | `application.register("form-validation", FormValidationController)` |
| `UserProfileController` | `user-profile` | `application.register("user-profile", UserProfileController)` |

CamelCase is converted to kebab-case. The `Controller` suffix is stripped.

### Generated Initialization Script

`render_stimulus_initialization_script` produces:

```javascript
import { Application } from "@hotwired/stimulus"
import HelloController from "HelloController"
import DropdownController from "DropdownController"

const application = Application.start()
application.register("hello", HelloController)
application.register("dropdown", DropdownController)
```

### Custom JavaScript

Pass custom JS to be included after controller registration:

```crystal
custom_js = <<-JS
  // Custom initialization
  document.addEventListener("turbo:load", () => {
    console.log("Page loaded")
  })
JS

FRONT_LOADER.render_stimulus_initialization_script(custom_js)
```

### Using Stimulus in HTML

With Crystal element classes:

```crystal
div = Components::Elements::Div.new
div.set_attribute("data-controller", "dropdown")

button = Components::Elements::Button.new("Menu", type: "button")
button.set_attribute("data-action", "click->dropdown#toggle")
button.set_attribute("data-dropdown-target", "trigger")
div << button

menu = Components::Elements::Ul.new(class: "dropdown-menu")
menu.set_attribute("data-dropdown-target", "menu")
menu.set_attribute("hidden", "true")
div << menu
```

Renders:
```html
<div data-controller="dropdown">
  <button type="button" data-action="click->dropdown#toggle" data-dropdown-target="trigger">Menu</button>
  <ul class="dropdown-menu" data-dropdown-target="menu" hidden="true"></ul>
</div>
```

---

## ScriptRenderer

Framework-agnostic script rendering with dependency analysis.

```crystal
import_map = AssetPipeline::ImportMap.new("app", Path["/js"])
import_map.add_import("chart", "https://cdn.example.com/chart.js")

renderer = AssetPipeline::ScriptRenderer.new(import_map, custom_javascript_block: <<-JS
  import Chart from "chart"
  new Chart(document.getElementById("canvas"), { type: "bar" })
JS
)

renderer.render_initialization_script
# => <script type="module">import Chart from "chart"\nnew Chart(...)</script>
```

The `DependencyAnalyzer` auto-detects imports in your custom JS and includes them.

### Performance

- Script content cached by import map hash + custom JS hash
- Import statements memoized
- Controller detection results cached
- Duplicate imports/registrations removed automatically

---

## Reactive Components

Server-side components that push updates to connected clients via WebSocket.

### Creating a Reactive Component

```crystal
class LiveCounterComponent < Components::Reactive::ReactiveComponent
  protected def initialize_state
    set_state("count", 0)
  end

  def render_content : String
    count = get_state("count").try(&.as_i?) || 0

    Components::Elements::Div.new(class: "counter").build do |div|
      display = Components::Elements::Span.new(class: "count")
      display << count.to_s
      div << display

      inc = Components::Elements::Button.new("+", type: "button")
      inc.set_attribute("data-action", "click->reactive#action")
      inc.set_attribute("data-action-name", "increment")
      div << inc
    end.render
  end

  on_action(:increment) { |data|
    count = get_state("count").try(&.as_i?) || 0
    set_state("count", count + 1)
    # auto-broadcasts updated HTML to all connected clients
  }
end
```

### Component Rendering

ReactiveComponent wraps output in a div with tracking attributes:

```html
<div data-component-id="abc123" data-component-type="LiveCounterComponent">
  <!-- render_content output -->
</div>
```

### State Management

```crystal
# Read state
value = get_state("key")           # => JSON::Any?
count = get_state("count").try(&.as_i?) || 0

# Write state (triggers broadcast if auto_update is true)
set_state("count", 42)             # Int32
set_state("name", "Alice")         # String
set_state("active", true)          # Bool
set_state("scores", [1, 2, 3])     # Array
set_state("meta", {"k" => "v"})    # Hash

# Batch updates (single broadcast at end)
update_state do |s|
  set_state("count", 0)
  set_state("status", "reset")
end

# Manual broadcast
push_update

# Disable auto-broadcasting
self.auto_update = false
```

### Event & Action Macros

```crystal
class ChatComponent < Components::Reactive::ReactiveComponent
  # Server-side events (called from Crystal code)
  on_event(:new_message) { |data|
    messages = get_state("messages")
    # ... append message
    set_state("messages", updated_messages)
  }

  # Client-side actions (triggered by browser via WebSocket)
  on_action(:send) { |data|
    draft = data["text"]?.try(&.as_s?) || ""
    # ... process and broadcast
  }
end
```

### Lifecycle

```crystal
component = LiveCounterComponent.new
component.register     # Register with ReactiveHandler
component.unregister   # Remove from ReactiveHandler
```

### Amber Integration

```crystal
# In your pipeline configuration
pipeline :web do
  plug Components::Integration.reactive_handler(
    websocket_path: "/ws/components",
    action_path: "/components/action",
    enable_fallback: true  # HTTP POST fallback for non-WebSocket browsers
  )
end

# In layout — include client-side JavaScript
<%= Components::Integration.reactive_script_tag(debug: false, auto_init: true) %>

# In controller
class DashboardController < Amber::Controller::Base
  def index
    counter = LiveCounterComponent.new
    counter.register
    render html: counter.render
  end
end

# Or use the macro
render_component(LiveCounterComponent)
```

### View Helpers

Include `Components::AmberIntegration::ViewHelpers` for template convenience:

```crystal
# Render any component
<%= component(LiveCounterComponent) %>

# Include reactive client JS
<%= reactive_scripts(debug: false) %>

# Include generated CSS
<%= css_styles(config: my_config, mode: :production) %>

# Build CSS inline
<%= css { |c| c.base("flex").hover("shadow-lg").build } %>
```

---

## Complete Page Example

```crystal
# Layout with import maps, Stimulus, and reactive components
page = Components::Elements::Html.new(lang: "en").build do |html|
  head = Components::Elements::Head.new
  head << Components::Elements::Meta.charset
  head << Components::Elements::Meta.viewport
  head << Components::Elements::Title.new.build { |t| t << "Dashboard" }
  head << Components::Elements::Link.stylesheet("/css/app.css")
  head << Components::Elements::RawHTML.new(FRONT_LOADER.render_import_map("application"))
  html << head

  body = Components::Elements::Body.new

  main = Components::Elements::Main.new(class: "container")
  # Add reactive component
  counter = LiveCounterComponent.new
  counter.register
  main << Components::Elements::RawHTML.new(counter.render)
  body << main

  # Stimulus init + reactive client JS
  body << Components::Elements::RawHTML.new(
    Components::Integration.reactive_script_tag(auto_init: true)
  )
  body << Components::Elements::Script.new(
    FRONT_LOADER.render_stimulus_initialization_script
  )

  html << body
end
```
