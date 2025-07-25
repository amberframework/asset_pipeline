# Asset Pipeline Component System - Implementation Plan

## README - Asset Pipeline Component System

### Overview

The Asset Pipeline Component System is a server-side component framework for Crystal web applications. It provides a modern, component-based UI system that treats the entire UI as an asset that flows through the pipeline. This system enables building design systems with reusable components while maintaining optimal performance through intelligent caching and JavaScript state management.

### Core Features

#### 1. **Component-Based Design System**
- Build UIs using reusable components instead of templates
- Components are Crystal classes that render to HTML
- Type-safe component composition with compile-time checking
- Perfect for design systems and component libraries

#### 2. **Stateless vs Stateful Components**
- **Stateless Components**: Pure functions that render based on props (cached by default)
- **Stateful Components**: Maintain client-side state managed by vanilla JavaScript

#### 3. **Pluggable Caching System**
- Abstract caching interface that users implement with their preferred cache store
- Automatic caching for stateless components
- Russian doll caching for nested components
- Smart cache invalidation strategies

#### 4. **JavaScript State Management**
- Vanilla JavaScript client for stateful component management
- No framework dependencies
- DOM-based state persistence
- Event-driven updates

#### 5. **Asset Pipeline Integration**
- Components generate both HTML and associated JavaScript/CSS
- Automatic asset bundling and optimization
- Component-specific styling and behavior
- Progressive enhancement approach

#### 6. **CSS Optimization & Introspection**
- CSS classes tracked as instance variables for optimization
- Automatic CSS selector and XPath generation for testing
- CSS tree-shaking based on component usage
- Minimal stylesheet generation for production deployments

### Basic Usage

```crystal
# Define a stateless component
class Button < StatelessComponent
  property label : String
  property variant : String
  property css_classes : Array(String)
  
  def initialize(@label : String, @variant = "primary", **attrs)
    @css_classes = ["btn", "btn-#{@variant}"]
    super(**attrs)
  end
  
  def render_content : String
    tag("button", class: css_classes.join(" ")) { @label }
  end
  
  def css_selector : String
    ".#{css_classes.join(".")}"
  end
  
  def xpath_selector : String
    "//button[contains(@class, '#{css_classes.join("') and contains(@class, '")}')]"
  end
end

# Define a stateful component
class Counter < StatefulComponent
  property initial_count : Int32
  property css_classes : Hash(String, Array(String))
  
  def initialize(@initial_count = 0, **attrs)
    @css_classes = {
      "container" => ["counter", "counter-widget"],
      "display" => ["count", "count-display"],
      "increment" => ["btn", "btn-increment", "btn-small"],
      "decrement" => ["btn", "btn-decrement", "btn-small"]
    }
    super(**attrs)
  end
  
  def render_content : String
    tag("div", class: css_classes["container"].join(" "), data: {"component" => "counter", "count" => @initial_count.to_s}) do
      tag("span", class: css_classes["display"].join(" ")) { @initial_count.to_s } +
      tag("button", class: css_classes["increment"].join(" "), data: {"action" => "increment"}) { "+" } +
      tag("button", class: css_classes["decrement"].join(" "), data: {"action" => "decrement"}) { "-" }
    end
  end
  
  def all_css_classes : Array(String)
    css_classes.values.flatten.uniq
  end
  
  def css_selectors : Hash(String, String)
    css_classes.transform_values { |classes| ".#{classes.join(".")}" }
  end
  
  def xpath_selectors : Hash(String, String)
    css_classes.transform_values do |classes|
      "//#{element_for_classes(classes)}[contains(@class, '#{classes.join("') and contains(@class, '")}')]"
    end
  end
  
  private def element_for_classes(classes : Array(String)) : String
    # Map common class patterns to element types for more specific xpath
    return "button" if classes.includes?("btn")
    return "span" if classes.includes?("count")
    return "div" if classes.includes?("counter")
    "*" # fallback to any element
  end
  
  def javascript_content : String
    <<-JS
    class Counter {
      constructor(element) {
        this.element = element;
        this.countElement = element.querySelector('#{css_selectors["display"]}');
        this.count = parseInt(element.dataset.count);
        this.bindEvents();
      }
      
      bindEvents() {
        this.element.querySelector('#{css_selectors["increment"]}').addEventListener('click', () => this.increment());
        this.element.querySelector('#{css_selectors["decrement"]}').addEventListener('click', () => this.decrement());
      }
      
      increment() {
        this.count++;
        this.updateDisplay();
      }
      
      decrement() {
        this.count--;
        this.updateDisplay();
      }
      
      updateDisplay() {
        this.countElement.textContent = this.count;
      }
    }
    JS
  end
end

# Use in views
<%= Button.new("Click me!", variant: "danger").render %>
<%= Counter.new(initial_count: 5).render %>
```

---

## Implementation Plan

### Phase 1: Core Component System ✅ **COMPLETED**

**Goal**: ✅ Implement the basic component architecture with HTML generation.

- [x] Create base `Component` abstract class
  - Add `attributes` property for HTML attributes (`Hash(String, String)`)
  - Add `children` property for nested components (`Array(Component)`)
  - Implement `tag` and `self_closing_tag` helper methods
  - Create abstract `render_content` method
  - Add `render` method that combines content with attributes
  - Add `component_id` property with auto-generation

- [x] Create `StatelessComponent` class
  - Inherit from `Component`
  - Add `cache_key_parts` method for caching
  - Add `cache_expires_in` method (default 1 hour)
  - CSS classes property and automatic registry integration

- [x] Create `StatefulComponent` class
  - Inherit from `Component`
  - Add abstract `javascript_content` method
  - Add `css_content` method (optional, empty by default)
  - Include component registration in rendered HTML
  - Complex CSS classes with Hash-based organization

- [x] Create `HTMLElement` wrapper class
  - Generic component for any HTML tag
  - Accept tag name and attributes in initializer
  - Support both self-closing and container tags

- [x] Create `HTML` module with convenience methods
  - Add methods: `div`, `span`, `p`, `h1`, `h2`, `h3`, `h4`, `h5`, `h6`
  - Add form elements: `input`, `textarea`, `select`, `option`, `button`
  - Add semantic elements: `header`, `footer`, `nav`, `main`, `section`, `article`

- [x] Create CSS Registry system
  - Track all CSS classes used by components
  - Generate optimization reports for CSS tree-shaking
  - Support both simple and complex component CSS tracking

- [x] Create example components
  - Button component (stateless) with variants and factory methods
  - Counter component (stateful) with JavaScript integration
  - CSS class introspection with `css_selector` and `xpath_selector` methods

**✅ Test Results**: All tests passing - 20 examples, 0 failures, 0 errors
  - Each method creates an `HTMLElement` instance

- [ ] Create example components
  - `Button` component with variants (primary, secondary, danger, success)
  - `Card` component with header, body, and footer slots
  - `Alert` component with different severity levels

- [ ] Add component rendering utilities
  - Create `ComponentRenderer` class
  - Handle HTML escaping and attribute serialization
  - Support nested component rendering

- [ ] Add CSS introspection capabilities
  - Add `css_classes` property to components (Array for simple, Hash for complex)
  - Implement `css_selector` and `xpath_selector` helper methods
  - Add `all_css_classes` method for stateful components
  - Include CSS classes in cache keys for proper invalidation

- [ ] Create component CSS registry
  - Track all CSS classes used across components
  - Generate CSS usage reports for optimization
  - Support CSS tree-shaking based on component usage
  - Enable cache warming by pre-loading required stylesheets

**Test**: Create components and verify HTML output is correct, CSS selectors work, and CSS classes are properly tracked.

### Phase 2: Abstract Caching System ✅ **COMPLETED**

**Goal**: Create a pluggable caching system without adding dependencies.

- [x] Create cache store abstraction
  - Define `CacheStore` abstract class
  - Add methods: `fetch(key, expires_in = nil, &block)`, `read(key)`, `write(key, value, expires_in = nil)`, `delete(key)`, `clear`
  - Add `exists?(key)` method

- [x] Create `ComponentCacheManager` class
  - Manage cache store instance
  - Generate cache keys for components
  - Handle cache key versioning
  - Provide cache statistics

- [x] Add `Cacheable` module
  - Define `cache_key_parts` method (to be implemented by components)
  - Define `cache_key` method that combines parts with component class name
  - Add `cacheable?` method (default true for StatelessComponent)
  - Add `cache_expires_in` method (default nil = no expiration)
  - Add `cache_version` class method for cache busting

- [x] Update `StatelessComponent` for caching
  - Include `Cacheable` module
  - Modify `render` to check cache first
  - Add `render_with_cache` and `render_without_cache` methods
  - Cache the final HTML output

- [x] Create test cache store
  - Implement `TestCacheStore < CacheStore`
  - Use in-memory Hash for storage
  - Support expiration via timestamps
  - Thread-safe implementation using Mutex

- [x] Add cache invalidation utilities
  - Create `invalidate_cache!` method on components
  - Support pattern-based cache clearing
  - Add cache warming helpers

- [x] Create cache configuration
  - Global cache enable/disable setting
  - Per-component cache control
  - Development vs production cache behavior

**Test**: Verify stateless components are cached and cache invalidation works correctly.

### Phase 3: JavaScript State Management System

**Goal**: Implement vanilla JavaScript for managing stateful components.

- [ ] Create `ComponentRegistry` JavaScript class
  - Component registration system (`Map<string, ComponentClass>`)
  - Automatic component discovery via DOM scanning
  - Component lifecycle management (mount, unmount)

- [ ] Create `ComponentManager` JavaScript class
  - Initialize and manage component instances
  - Handle component cleanup
  - Provide debugging utilities

- [ ] Implement component scanning
  - Find elements with `data-component` attribute
  - Extract component type and initial data
  - Instantiate and mount components
  - Support dynamic component addition

- [ ] Add DOM utilities
  - Simple event delegation system
  - Element creation and manipulation helpers
  - Data attribute management
  - CSS class utilities

- [ ] Create base `StatefulComponentJS` class
  - Standard lifecycle methods: `constructor`, `mount`, `unmount`
  - Event binding utilities
  - State persistence to DOM
  - Update triggering system

- [ ] Add development tools
  - Component inspector (console commands)
  - State debugging utilities
  - Performance monitoring hooks

- [ ] Create example JavaScript components
  - `Counter` component
  - `Toggle` component
  - `Dropdown` component
  - `Tabs` component

**Test**: Create stateful components and verify JavaScript initialization and state management work.

### Phase 4: Asset Pipeline Integration

**Goal**: Integrate components with the existing asset pipeline system.

- [x] Create `ComponentAssetGenerator` class ✅
  - Extract JavaScript from stateful components
  - Extract CSS from components with styling
  - Generate combined asset files
  - Handle asset fingerprinting

- [x] Update `AssetPipeline::FrontLoader` integration ✅
  - Add component asset discovery
  - Include component JavaScript in main bundle
  - Handle component CSS bundling
  - Support component-specific assets

- [x] Create `ComponentAssetHandler` ✅
  - Process component assets during build
  - Minify and optimize component JavaScript
  - Handle CSS preprocessing for components
  - Generate asset manifests

- [x] Add component asset helpers ✅
  - `component_javascript_assets` helper
  - `component_css_assets` helper
  - Automatic inclusion in asset pipeline

- [x] Create component development mode ✅
  - Hot reloading for component changes
  - Separate asset compilation for faster development
  - Component-specific error handling

- [x] Add CSS optimization integration ✅
  - Generate minimal stylesheets based on used components
  - CSS tree-shaking using component CSS class registry
  - Automatic purging of unused CSS classes
  - Component-specific CSS bundling for lazy loading

- [x] Add production optimizations ✅
  - Component tree shaking
  - Unused component elimination
  - Asset compression and bundling
  - CDN support for component assets
  - CSS minification with component-aware optimizations

**Test**: ✅ **PASSED** - Components integrate properly with asset pipeline, assets are built correctly, and CSS optimization reduces stylesheet size.

### Phase 5: Advanced Component Features

**Goal**: Add advanced features for building complex design systems.

- [ ] Create component composition system
  - `Slot` system for component content areas
  - `Layout` components for page structure
  - Component inheritance and mixins
  - Dynamic component rendering

- [ ] Add component styling system
  - Component-scoped CSS generation
  - CSS custom properties support
  - Theme system integration
  - Responsive design utilities

- [ ] Create form component library
  - `Form` wrapper component
  - `Input`, `Textarea`, `Select` components
  - `FormField` with label and validation
  - Form validation and error display

- [ ] Add data binding utilities
  - Simple two-way data binding
  - Form data serialization
  - State synchronization between components
  - Event bubbling system

- [ ] Create component testing utilities
  - Component unit testing helpers
  - Mock rendering for tests
  - JavaScript component testing
  - Integration test utilities

- [ ] Add performance optimization
  - Component memoization
  - Lazy loading for heavy components
  - Virtual rendering for large lists
  - Performance profiling tools

**Test**: Build a complete design system with forms, layouts, and interactions.

---

## Implementation Guidelines

### Code Organization:

```
src/
  asset_pipeline/
    components/
      base/
        component.cr
        stateless_component.cr
        stateful_component.cr
        cacheable.cr
        html_element.cr
      cache/
        cache_store.cr
        component_cache_manager.cr
        test_cache_store.cr
      javascript/
        component_registry.js
        component_manager.js
        stateful_component_js.js
        dom_utilities.js
      examples/
        button.cr
        counter.cr
        card.cr
        alert.cr
      html/
        html_helpers.cr
      assets/
        component_asset_generator.cr
        component_asset_handler.cr

spec/
  asset_pipeline/
    components/
      component_spec.cr
      caching_spec.cr
      javascript_integration_spec.cr
```

### Key Patterns:

 1. **Stateless Component**:
 ```crystal
 class MyComponent < StatelessComponent
   property title : String
   property css_classes : Array(String)
   
   def initialize(@title : String, **attrs)
     @css_classes = ["my-component", "component-card"]
     super(**attrs)
   end
   
   def cache_key_parts : Array(String)
     [@title, css_classes.join("-")]
   end
   
   def render_content : String
     tag("div", class: css_classes.join(" ")) { @title }
   end
   
   def css_selector : String
     ".#{css_classes.join(".")}"
   end
   
   def xpath_selector : String
     "//div[contains(@class, '#{css_classes.join("') and contains(@class, '")}')]"
   end
 end
 ```
 
 2. **Stateful Component**:
 ```crystal
 class MyStatefulComponent < StatefulComponent
   property initial_data : String
   property css_classes : Hash(String, Array(String))
   
   def initialize(@initial_data = "", **attrs)
     @css_classes = {
       "container" => ["my-stateful", "stateful-component"],
       "content" => ["content", "component-body"]
     }
     super(**attrs)
   end
   
   def render_content : String
     tag("div", class: css_classes["container"].join(" "), data: {
       "component" => "my-stateful",
       "initial-data" => @initial_data
     }) do
       tag("div", class: css_classes["content"].join(" ")) { "Content here" }
     end
   end
   
   def all_css_classes : Array(String)
     css_classes.values.flatten.uniq
   end
   
   def css_selectors : Hash(String, String)
     css_classes.transform_values { |classes| ".#{classes.join(".")}" }
   end
   
   def javascript_content : String
     <<-JS
     class MyStatefulComponent {
       constructor(element) {
         this.element = element;
         this.contentElement = element.querySelector('#{css_selectors["content"]}');
         this.data = element.dataset.initialData;
         this.initialize();
       }
       
       initialize() {
         // Component logic using CSS selectors for reliable element targeting
       }
     }
     JS
   end
 end
 ```

3. **Cache Store Implementation**:
```crystal
class MyCacheStore < CacheStore
  def initialize
    @store = Hash(String, {value: String, expires_at: Time?}).new
  end
  
  def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
    if value = read(key)
      value
    else
      result = yield
      write(key, result, expires_in)
      result
    end
  end
  
  # Implement other required methods...
end
```

### Integration Points:

1. **With Asset Pipeline**:
   - Components register their JavaScript/CSS assets
   - Assets are processed through existing pipeline
   - Import maps include component modules

2. **With Web Frameworks**:
   - Framework-agnostic component rendering
   - View helper integration
   - Template system compatibility

3. **With Caching Systems**:
   - Redis, Memcached, or custom cache stores
   - User provides cache store implementation
   - Framework handles cache key generation and invalidation

### Success Criteria:

- [ ] Can build complete design systems using only components
- [ ] Stateless components automatically cache for performance
- [ ] Stateful components work seamlessly with vanilla JavaScript
- [ ] Component assets integrate with existing asset pipeline
- [ ] System works without external dependencies
- [ ] Components are testable and maintainable
- [ ] Performance is better than traditional template rendering
- [ ] JavaScript state management works without page refresh

### Testing Strategy:

1. **Unit Tests**: Test individual component rendering and caching
2. **Integration Tests**: Test component assets with pipeline
3. **JavaScript Tests**: Test client-side component behavior
4. **Performance Tests**: Verify caching improves performance
5. **End-to-End Tests**: Test complete component systems