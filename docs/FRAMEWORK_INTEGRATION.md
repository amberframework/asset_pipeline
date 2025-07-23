# Framework Integration Guide

This guide covers how to integrate AssetPipeline with various JavaScript frameworks. AssetPipeline is designed to be framework-agnostic while providing specialized support for specific frameworks.

## Table of Contents

- [Framework Architecture](#framework-architecture)
- [Stimulus Framework Integration](#stimulus-framework-integration)
- [General Framework Support](#general-framework-support)
- [Future Framework Support](#future-framework-support)
- [Custom Framework Integration](#custom-framework-integration)
- [Framework Best Practices](#framework-best-practices)

---

## Framework Architecture

### Framework Registry System

AssetPipeline uses an extensible framework registry that allows for clean integration with different JavaScript frameworks:

```crystal
# Framework registration pattern
FrameworkRegistry.register_framework(
  "framework_name",
  "FrameworkRendererClassName",
  patterns: [/detection_pattern/],
  core_import: "@framework/core",
  description: "Framework description"
)
```

### Current Supported Frameworks

1. **Stimulus** - Full built-in support with automatic controller detection
2. **General JavaScript** - Framework-agnostic support for any library
3. **Extensible Registry** - Ready for future framework additions

---

## Stimulus Framework Integration

### Automatic Controller Detection

AssetPipeline provides comprehensive Stimulus support with intelligent controller detection:

```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add Stimulus framework
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Add controllers - automatically detected by naming pattern
import_map.add_import("HelloController", "hello_controller.js")
import_map.add_import("DropdownController", "dropdown_controller.js") 
import_map.add_import("UserProfileController", "user_profile_controller.js")

# AssetPipeline automatically:
# 1. Detects controller naming pattern (*Controller)
# 2. Imports the Stimulus Application class
# 3. Creates application instance
# 4. Registers controllers with kebab-case names
stimulus_html = front_loader.render_stimulus_initialization_script
```

### Controller Name Conversion

AssetPipeline automatically converts PascalCase controller names to kebab-case registration names:

| Import Name | Registered As |
|-------------|---------------|
| `HelloController` | `hello` |
| `DropdownController` | `dropdown` |
| `UserProfileController` | `user-profile` |
| `AdminDashboardController` | `admin-dashboard` |

### Stimulus Application Configuration

#### Basic Setup
```crystal
# Simple Stimulus setup
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("HelloController", "hello_controller.js")

basic_js = <<-JS
  console.log('Stimulus application ready');
JS

result = front_loader.render_stimulus_initialization_script(basic_js)
```

#### Custom Application Name
```crystal
# Custom application instance name
result = front_loader.render_stimulus_initialization_script(
  "console.log('Custom app ready');",
  "application", # import map name
  "myApp"       # custom application variable name
)
```

#### Multiple Stimulus Applications
```crystal
front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Main application
  main_map = AssetPipeline::ImportMap.new("main")
  main_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  main_map.add_import("UserController", "user_controller.js")
  import_maps << main_map
  
  # Admin application
  admin_map = AssetPipeline::ImportMap.new("admin")
  admin_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  admin_map.add_import("AdminController", "admin_controller.js")
  import_maps << admin_map
end

# Render separate applications
main_html = front_loader.render_stimulus_initialization_script("console.log('Main app');", "main", "mainApp")
admin_html = front_loader.render_stimulus_initialization_script("console.log('Admin app');", "admin", "adminApp")
```

### Advanced Stimulus Features

#### Duplicate Import Removal
AssetPipeline automatically removes duplicate imports and registrations:

```crystal
# Custom JavaScript with duplicate imports (common during migration)
duplicate_js = <<-JS
  import { Application } from "@hotwired/stimulus"; // Will be removed
  import HelloController from "HelloController";   // Will be removed
  
  const application = Application.start();          // Will be removed
  application.register("hello", HelloController);  // Will be removed
  
  // Only this custom code will be kept
  console.log('Custom initialization logic');
  
  document.addEventListener('stimulus:ready', () => {
    console.log('All controllers loaded');
  });
JS

# AssetPipeline removes duplicates and keeps custom logic
clean_result = front_loader.render_stimulus_initialization_script(duplicate_js)
```

#### Stimulus with External Libraries
```crystal
# Combine Stimulus with other libraries
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")

# Controllers that use external libraries
import_map.add_import("ChartController", "chart_controller.js")
import_map.add_import("DataTableController", "data_table_controller.js")

mixed_js = <<-JS
  // Global utilities available to all controllers
  window.chartDefaults = {
    responsive: true,
    plugins: {
      legend: { position: 'top' }
    }
  };
  
  // Lodash utilities
  window.debounce = debounce;
  window.throttle = throttle;
  
  console.log('Stimulus + libraries ready');
JS

result = front_loader.render_stimulus_initialization_script(mixed_js)
```

---

## General Framework Support

### Framework-Agnostic Usage

AssetPipeline works with any JavaScript framework through its general script rendering capabilities:

#### React Integration
```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# React setup
import_map.add_import("react", "https://esm.sh/react@18", preload: true)
import_map.add_import("react-dom", "https://esm.sh/react-dom@18", preload: true)

react_js = <<-JS
  // React application setup
  const { createRoot } = ReactDOM;
  const { useState, useEffect } = React;
  
  function App() {
    const [count, setCount] = useState(0);
    
    return React.createElement('div', null,
      React.createElement('h1', null, `Count: ${count}`),
      React.createElement('button', {
        onClick: () => setCount(count + 1)
      }, 'Increment')
    );
  }
  
  // Mount React app
  const container = document.getElementById('react-root');
  const root = createRoot(container);
  root.render(React.createElement(App));
JS

puts front_loader.render_initialization_script(react_js)
```

#### Vue.js Integration
```crystal
# Vue.js setup
import_map.add_import("vue", "https://unpkg.com/vue@3/dist/vue.esm-browser.js", preload: true)

vue_js = <<-JS
  // Vue application setup
  const { createApp, ref } = Vue;
  
  const app = createApp({
    setup() {
      const count = ref(0);
      const increment = () => count.value++;
      
      return { count, increment };
    },
    template: `
      <div>
        <h1>Count: {{ count }}</h1>
        <button @click="increment">Increment</button>
      </div>
    `
  });
  
  app.mount('#vue-app');
JS

puts front_loader.render_initialization_script(vue_js)
```

#### Alpine.js Integration
```crystal
# Alpine.js setup
import_map.add_import("alpinejs", "https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js", preload: true)

alpine_js = <<-JS
  // Alpine.js setup
  document.addEventListener('alpine:init', () => {
    Alpine.data('counter', () => ({
      count: 0,
      increment() {
        this.count++;
      }
    }));
  });
  
  // Start Alpine
  Alpine.start();
JS

puts front_loader.render_initialization_script(alpine_js)
```

### Framework Detection Patterns

AssetPipeline can be extended to detect framework-specific patterns:

```crystal
# Custom detection for future framework support
framework_js = <<-JS
  // React component pattern
  function MyComponent() { return null; }
  
  // Vue component pattern  
  const MyVueComponent = { template: '...' };
  
  // Alpine directive pattern
  Alpine.directive('my-directive', ...);
  
  // Stimulus controller pattern (automatically detected)
  class MyController extends Controller { }
JS

# Use dependency analysis to identify framework usage
result = front_loader.render_initialization_script_with_analysis(framework_js)
```

---

## Future Framework Support

### Planned Framework Integrations

AssetPipeline is designed to easily support additional frameworks:

#### Svelte Support (Future)
```crystal
# Future Svelte integration example
import_map.add_import("svelte", "https://unpkg.com/svelte@4/index.mjs", preload: true)
import_map.add_import("MyComponent", "my_component.svelte")

# Would automatically:
# 1. Detect .svelte files
# 2. Handle component imports
# 3. Setup Svelte runtime
```

#### LitElement Support (Future)
```crystal
# Future LitElement integration example
import_map.add_import("lit", "https://cdn.jsdelivr.net/npm/lit@3/index.js", preload: true)
import_map.add_import("MyElement", "my_element.js")

# Would automatically:
# 1. Detect LitElement patterns
# 2. Handle custom element registration
# 3. Setup lit-html runtime
```

### Extensible Architecture

The framework registry allows for easy addition of new frameworks:

```crystal
# Future framework registration
FrameworkRegistry.register_framework(
  "alpine",
  "AssetPipeline::Alpine::AlpineRenderer",
  patterns: [/Alpine\.directive/, /Alpine\.data/],
  core_import: "alpinejs",
  description: "Alpine.js framework support"
)

# Framework capabilities inquiry
capabilities = front_loader.framework_capabilities
puts capabilities["supported_frameworks"] # ["stimulus", "alpine", ...]
```

---

## Custom Framework Integration

### Creating Custom Framework Renderers

You can extend AssetPipeline to support your own frameworks:

```crystal
# Example: Custom framework renderer
module AssetPipeline::MyFramework
  class MyFrameworkRenderer < AssetPipeline::ScriptRenderer
    def initialize(@import_map : ImportMap, @custom_js_block : String = "")
      super(@import_map, @custom_js_block, enable_dependency_analysis: true)
    end
    
    def generate_script_content : String
      framework_imports = detect_framework_components
      framework_setup = generate_framework_setup
      
      <<-JS
      #{framework_imports}
      
      #{framework_setup}
      
      #{@custom_js_block}
      JS
    end
    
    private def detect_framework_components
      # Custom detection logic
      components = [] of String
      
      @import_map.imports.each do |import_entry|
        if import_entry.first_key.ends_with?("Component")
          components << "import #{import_entry.first_key} from \"#{import_entry.first_key}\";"
        end
      end
      
      components.join("\n")
    end
    
    private def generate_framework_setup
      <<-JS
      // Custom framework initialization
      const myFramework = new MyFramework();
      myFramework.start();
      JS
    end
  end
end

# Register the custom framework
FrameworkRegistry.register_framework(
  "myframework",
  "AssetPipeline::MyFramework::MyFrameworkRenderer",
  patterns: [/Component$/],
  core_import: "my-framework",
  description: "Custom framework support"
)
```

### Using Custom Renderers

```crystal
# Use custom framework renderer
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

import_map.add_import("my-framework", "https://cdn.example.com/my-framework.js", preload: true)
import_map.add_import("HeaderComponent", "header_component.js")
import_map.add_import("FooterComponent", "footer_component.js")

# Custom framework rendering
renderer = AssetPipeline::MyFramework::MyFrameworkRenderer.new(import_map, "console.log('Custom ready');")
custom_result = renderer.wrap_in_script_tag
```

---

## Framework Best Practices

### 1. Framework Selection Guidelines

**Choose Stimulus when:**
- Building server-rendered applications
- Need lightweight JavaScript enhancement
- Want HTML-first approach
- Using Rails, Django, or similar backends

**Choose React/Vue when:**
- Building single-page applications
- Need complex state management
- Have dedicated frontend team
- Building highly interactive UIs

**Choose Alpine.js when:**
- Want Vue-like syntax without build step
- Need minimal JavaScript framework
- Prefer declarative HTML approach
- Building mostly static sites with interactivity

### 2. Import Organization by Framework

```crystal
# ✅ Good: Framework-specific organization
import_map = front_loader.get_import_map

# Core framework first
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Framework utilities
import_map.add_import("@stimulus/use", "https://unpkg.com/@stimulus/use@1.2.0/dist/index.js")

# Application controllers (organized by feature)
import_map.add_import("NavigationController", "controllers/navigation_controller.js")
import_map.add_import("FormController", "controllers/form_controller.js")
import_map.add_import("ModalController", "controllers/modal_controller.js")

# External libraries (compatible with framework)
import_map.add_import("axios", "https://cdn.jsdelivr.net/npm/axios@1.6.0/+esm")
```

### 3. Framework Migration Strategies

#### Gradual Migration Pattern
```crystal
# Phase 1: Add new framework alongside existing
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)

transition_js = <<-JS
  // Legacy jQuery for existing features
  $('.legacy-component').legacyPlugin();
  
  // New Stimulus controllers for new features
  // Automatically registered by AssetPipeline
  
  console.log('Gradual migration in progress');
JS

# Both frameworks work together during transition
result = front_loader.render_stimulus_initialization_script(transition_js)
```

#### Progressive Enhancement Pattern
```crystal
# Use feature detection for progressive enhancement
progressive_js = <<-JS
  // Check for framework support
  if ('customElements' in window && 'Stimulus' in window) {
    // Use modern Stimulus controllers
    console.log('Using Stimulus enhanced features');
  } else {
    // Fallback to vanilla JavaScript
    console.log('Using fallback functionality');
    
    // Implement basic functionality without framework
    document.querySelectorAll('[data-action]').forEach(element => {
      element.addEventListener('click', (e) => {
        // Basic event handling
      });
    });
  }
JS

result = front_loader.render_stimulus_initialization_script(progressive_js)
```

### 4. Performance Considerations

#### Preloading Strategy
```crystal
# Critical framework resources
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Essential controllers
import_map.add_import("ApplicationController", "application_controller.js", preload: true)

# Feature-specific controllers (load on demand)
import_map.add_import("ChartController", "chart_controller.js") # No preload for optional features
```

#### Bundle Size Optimization
```crystal
# Use tree-shakeable imports
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm") # ES modules
# Instead of: lodash (CommonJS bundle)

# Feature-specific imports
import_map.add_import("chart.js/auto", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/auto/+esm") # Auto bundle
# Instead of: full chart.js for simple charts
```

---

This framework integration guide demonstrates AssetPipeline's flexibility and extensibility. For specific implementation details, see the [API Reference](API_REFERENCE.md) and [Usage Examples](USAGE_EXAMPLES.md). 