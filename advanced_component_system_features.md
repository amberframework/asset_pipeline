# Amber Component System - Advanced Features Specification

## Overview

This document specifies the advanced features of the Amber Component System that build upon the foundational HTML Elements and Components architecture. These features transform the basic component system into a high-performance, real-time web application framework.

## Feature 1: Component Caching System

### Purpose

The caching system dramatically improves performance by storing rendered component output and reusing it when possible. Inspired by Rails' Russian doll caching, it provides intelligent cache invalidation and dependency tracking.

### Architecture

#### Cache Store Abstraction

```crystal
abstract class CacheStore
  abstract def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
  abstract def read(key : String) : String?
  abstract def write(key : String, value : String, expires_in : Time::Span? = nil)
  abstract def delete(key : String)
  abstract def clear
end
```

#### Memory Cache Store

```crystal
class MemoryCacheStore < CacheStore
  alias CacheEntry = NamedTuple(value: String, expires_at: Time?)
  
  @@cache = {} of String => CacheEntry
  @@mutex = Mutex.new
  
  def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
    if cached = read(key)
      cached
    else
      value = yield
      write(key, value, expires_in)
      value
    end
  end
  
  def read(key : String) : String?
    @@mutex.synchronize do
      if entry = @@cache[key]?
        if entry[:expires_at].nil? || entry[:expires_at].not_nil! > Time.utc
          entry[:value]
        else
          @@cache.delete(key)
          nil
        end
      end
    end
  end
  
  def write(key : String, value : String, expires_in : Time::Span? = nil)
    @@mutex.synchronize do
      expires_at = expires_in ? Time.utc + expires_in : nil
      @@cache[key] = {value: value, expires_at: expires_at}
    end
  end
end
```

#### Redis Cache Store

```crystal
class RedisCacheStore < CacheStore
  def initialize(@redis : Redis::Client)
  end
  
  def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
    if cached = read(key)
      cached
    else
      value = yield
      write(key, value, expires_in)
      value
    end
  end
  
  def read(key : String) : String?
    @redis.get(key)
  end
  
  def write(key : String, value : String, expires_in : Time::Span? = nil)
    if expires_in
      @redis.setex(key, expires_in.total_seconds.to_i, value)
    else
      @redis.set(key, value)
    end
  end
end
```

### Cache Key Generation

Components generate cache keys based on:
1. Component class name
2. Component attributes
3. Component version (for easy invalidation)
4. Component state (for stateful components)
5. Timestamps (for time-sensitive content)

```crystal
module Cacheable
  def cache_key_parts : Array(String)
    [self.class.name, attributes.hash.to_s]
  end
  
  def cache_key : String
    parts = cache_key_parts
    parts << cache_version.to_s if responds_to?(:cache_version)
    ComponentCache.cache_key(parts)
  end
  
  def cache_dependencies : Array(String)
    [] of String
  end
  
  def cacheable? : Bool
    true
  end
  
  def cache_expires_in : Time::Span?
    nil
  end
end
```

### Russian Doll Caching

Parent components track their child component dependencies:

```crystal
class ProductList < StatelessComponent
  property products : Array(Product)
  
  def cache_key_parts : Array(String)
    parts = super
    parts << products.size.to_s
    if latest = products.max_by?(&.updated_at)
      parts << latest.updated_at.to_unix.to_s
    end
    parts
  end
  
  def cache_dependencies : Array(String)
    products.map do |product|
      ProductCard.new(product).cache_key
    end
  end
  
  def render_content : String
    Div.new(class: "product-list").build do |list|
      products.each do |product|
        # Each ProductCard uses its own cache
        list << ProductCard.new(product).render
      end
    end.render
  end
end
```

### Cache Warming

Pre-render expensive components during deployment:

```crystal
class ComponentCacheWarmer
  def self.warm_component(component : Component)
    component.render # This will cache it
  end
  
  def self.warm_collection(components : Array(Component))
    components.each { |c| warm_component(c) }
  end
  
  def self.warm_common_components
    Product.all.each do |product|
      warm_component(ProductCard.new(product))
    end
  end
end
```

### Configuration

```crystal
ComponentCache.configure do |config|
  config.enabled = Amber.env.production?
  config.cache_store = Amber.env.production? ? 
    RedisCacheStore.new(Redis::Client.new) : 
    MemoryCacheStore.new
  config.namespace = "myapp:components"
end
```

### Performance Impact

- First render: ~50ms for complex component
- Cached render: ~0.1ms
- 500x improvement for complex components
- Minimal memory overhead with TTL expiration

## Feature 2: Reactive UI System

### Purpose

Enable real-time UI updates without page refreshes, similar to Phoenix LiveView but with a lighter client-side footprint and framework-agnostic design.

### Architecture Overview

```
Browser (AmberReactive.js) ← WebSocket → Server (ReactiveSocket)
     ↓                                           ↓
DOM Updates                               Component State
     ↑                                           ↑
User Events  ─────── Actions ──────────→  Event Handlers
```

### Client-Side Implementation (Vanilla JavaScript)

#### Core Client Class

```javascript
class AmberReactive {
  constructor() {
    this.components = new Map();
    this.socket = null;
    this.eventBus = new EventTarget();
    this.updateQueue = [];
    this.isProcessingQueue = false;
  }

  init(config = {}) {
    this.wsUrl = config.wsUrl || this.buildWebSocketUrl();
    this.connectWebSocket();
    this.scanForComponents();
    this.setupMutationObserver();
    this.emit('amber:initialized');
  }

  // WebSocket connection management
  connectWebSocket() {
    this.socket = new WebSocket(this.wsUrl);
    
    this.socket.onopen = () => {
      this.emit('amber:connected');
      this.syncAllComponents();
    };
    
    this.socket.onmessage = (event) => {
      const message = JSON.parse(event.data);
      this.handleServerMessage(message);
    };
    
    this.socket.onclose = () => {
      this.emit('amber:disconnected');
      setTimeout(() => this.connectWebSocket(), 1000);
    };
  }

  // Component registration
  registerComponent(element) {
    const componentId = element.dataset.componentId;
    if (!componentId) return;
    
    const component = {
      id: componentId,
      element: element,
      type: element.dataset.reactive,
      state: this.parseState(element.dataset.state),
      checksum: element.dataset.checksum,
      handlers: new Map()
    };
    
    this.components.set(componentId, component);
    this.attachEventHandlers(component);
    this.emit('amber:component:registered', { component });
  }
}
```

#### DOM Morphing Algorithm

```javascript
morphElement(oldEl, newEl) {
  // Update attributes
  const oldAttrs = oldEl.attributes;
  const newAttrs = newEl.attributes;
  
  // Remove old attributes
  for (let i = oldAttrs.length - 1; i >= 0; i--) {
    const attr = oldAttrs[i];
    if (!newEl.hasAttribute(attr.name)) {
      oldEl.removeAttribute(attr.name);
    }
  }
  
  // Add/update new attributes
  for (let i = 0; i < newAttrs.length; i++) {
    const attr = newAttrs[i];
    if (oldEl.getAttribute(attr.name) !== attr.value) {
      oldEl.setAttribute(attr.name, attr.value);
    }
  }
  
  // Handle children recursively
  const oldChildren = Array.from(oldEl.children);
  const newChildren = Array.from(newEl.children);
  
  const maxLength = Math.max(oldChildren.length, newChildren.length);
  
  for (let i = 0; i < maxLength; i++) {
    if (i >= oldChildren.length) {
      oldEl.appendChild(newChildren[i].cloneNode(true));
    } else if (i >= newChildren.length) {
      oldEl.removeChild(oldChildren[i]);
    } else if (oldChildren[i].tagName !== newChildren[i].tagName) {
      oldEl.replaceChild(newChildren[i].cloneNode(true), oldChildren[i]);
    } else {
      this.morphElement(oldChildren[i], newChildren[i]);
    }
  }
}
```

#### Event System

```javascript
// Emit events for extensibility
emit(eventName, detail = {}) {
  const event = new CustomEvent(eventName, { detail });
  this.eventBus.dispatchEvent(event);
  window.dispatchEvent(event);
}

// Available events:
// - amber:initialized
// - amber:connected / amber:disconnected  
// - amber:component:registered
// - amber:component:beforeUpdate / amber:component:updated
// - amber:action:sent
// - amber:error
```

### Server-Side Implementation

#### WebSocket Handler

```crystal
class ReactiveSocket < HTTP::WebSocketHandler
  class_property connections = {} of String => HTTP::WebSocket
  
  def call(context)
    ws = HTTP::WebSocket.new(context.request.path)
    session_id = context.session.id.to_s
    
    ws.on_message do |message|
      handle_message(session_id, message)
    end
    
    ws.on_close do
      ReactiveSocket.connections.delete(session_id)
      ReactiveSession.remove(session_id)
    end
    
    ReactiveSocket.connections[session_id] = ws
    ReactiveSession.create(session_id)
    
    ws
  end
  
  private def handle_message(session_id : String, message : String)
    data = JSON.parse(message)
    
    case data["type"].as_s
    when "action"
      handle_action(session_id, data)
    when "sync"
      handle_sync(session_id, data)
    end
  end
end
```

#### Reactive Session Management

```crystal
class ReactiveSession
  @@sessions = {} of String => ReactiveSession
  
  getter session_id : String
  getter components : Hash(String, ReactiveComponent)
  
  def register_component(id : String, type : String, state : JSON::Any, checksum : String?)
    component_class = find_component_class(type)
    return unless component_class
    
    component = component_class.new
    component.component_id = id
    component.restore_state(state)
    
    @components[id] = ReactiveComponent.new(
      id: id,
      type: type,
      instance: component,
      checksum: checksum
    )
  end
  
  def dispatch_action(component_id : String, method : String, data : JSON::Any)
    component_info = @components[component_id]?
    return unless component_info
    
    instance = component_info.instance
    
    if instance.responds_to?(method)
      instance.call(method, data)
      
      if instance.changed?
        send_update(component_id, instance)
        instance.reset_changed!
      end
    end
  end
  
  private def send_update(component_id : String, instance : Component)
    ws = ReactiveSocket.connections[@session_id]?
    return unless ws
    
    new_html = instance.render
    new_checksum = Digest::MD5.hexdigest(new_html)
    
    update = UpdateMessage.new(
      component_id: component_id,
      strategy: determine_update_strategy(instance),
      html: new_html,
      state: instance.state,
      checksum: new_checksum
    )
    
    ws.send(update.to_json)
  end
end
```

#### Making Components Reactive

```crystal
abstract class ReactiveStatefulComponent < StatefulComponent
  def set_state(key : String, value : JSON::Any)
    super
    mark_changed!
  end
  
  def restore_state(state_json : JSON::Any)
    @state = state_json.as_h? || {} of String => JSON::Any
  end
  
  def broadcast_update
    ReactiveSocket.connections.each do |session_id, ws|
      if session = ReactiveSession.get(session_id)
        if component = session.components[@component_id]?
          new_html = render
          update = UpdateMessage.new(
            component_id: @component_id,
            strategy: update_strategy,
            html: new_html,
            state: @state,
            checksum: Digest::MD5.hexdigest(new_html)
          )
          ws.send(update.to_json)
        end
      end
    end
  end
end
```

### Reactive Component Example

```crystal
class ReactiveCounter < ReactiveStatefulComponent
  def initialize(**attrs)
    super
    set_state("count", JSON::Any.new(0_i64))
  end
  
  def increment(data : JSON::Any)
    current = get_state("count").as_i? || 0
    set_state("count", JSON::Any.new(current + 1))
  end
  
  def decrement(data : JSON::Any)
    current = get_state("count").as_i? || 0
    set_state("count", JSON::Any.new(current - 1))
  end
  
  def render_content : String
    current_count = get_state("count").as_i? || 0
    
    Div.new(**reactive_attributes).build do |div|
      div << Span.new("Count: #{current_count}", class: "counter-display")
      div << " "
      div << Button.new("+", 
        class: "btn btn-primary",
        "data-action": "click->increment"
      )
      div << " "
      div << Button.new("-",
        class: "btn btn-secondary", 
        "data-action": "click->decrement"
      )
    end.render
  end
  
  private def reactive_attributes
    attributes.merge({
      "data-reactive" => "Counter",
      "data-component-id" => component_id,
      "data-state" => state.to_json,
      "data-checksum" => Digest::MD5.hexdigest(render_content)
    })
  end
end
```

### Update Strategies

The reactive system supports different update strategies:

1. **morph**: Smart DOM diffing (default)
2. **inner**: Replace inner HTML only
3. **attributes**: Update attributes only
4. **state**: Update component state without DOM changes
5. **replace**: Replace entire component

```crystal
def update_strategy : String
  case
  when only_attributes_changed?
    "attributes"
  when only_content_changed?
    "inner"
  else
    "morph"
  end
end
```

### Integration with Stimulus

The reactive system emits events that Stimulus controllers can hook into:

```javascript
// Stimulus controller
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    window.addEventListener('amber:component:updated', this.handleUpdate)
  }
  
  disconnect() {
    window.removeEventListener('amber:component:updated', this.handleUpdate)
  }
  
  handleUpdate = (event) => {
    if (event.detail.component.element === this.element) {
      // Add custom behavior on updates
      this.element.classList.add('updating')
      setTimeout(() => {
        this.element.classList.remove('updating')
      }, 300)
    }
  }
}
```

## Feature 3: Integration Patterns

### Caching + Reactivity

Reactive components can leverage caching for initial renders:

```crystal
class CachedReactiveComponent < ReactiveStatefulComponent
  include Cacheable
  
  def cache_key_parts : Array(String)
    # Include component ID but not volatile state
    [self.class.name, component_id, stable_attributes.hash.to_s]
  end
  
  def render : String
    if initial_render?
      # Use cache for initial render
      super # This goes through caching
    else
      # Skip cache for reactive updates
      render_without_cache
    end
  end
end
```

### Progressive Enhancement

Components work without JavaScript, with reactivity as enhancement:

```crystal
class EnhancedForm < Form
  def render_content : String
    form_attrs = attributes.merge({
      "data-reactive": "Form",
      "data-component-id": component_id,
      "data-enhance": "true"
    })
    
    Form.new(**form_attrs).build do |f|
      # Form works normally without JS
      # With JS, gets real-time validation
      f << Input.new(
        type: "email",
        name: "email",
        "data-action": "blur->validate"
      )
    end.render
  end
end
```

### Server-Initiated Updates

Push updates from server without user interaction:

```crystal
# In a background job or event handler
def notify_users_of_change(product_id : Int32)
  ReactiveSession.each do |session|
    session.components.each do |id, component|
      if component.instance.responds_to?(:product_id)
        if component.instance.product_id == product_id
          component.instance.mark_changed!
          session.send_update(id, component.instance)
        end
      end
    end
  end
end
```

## Performance Considerations

### Caching Performance

- Cache keys are generated once per render
- Memory cache: ~0.01ms lookup time
- Redis cache: ~1ms lookup time
- Cache warming prevents cold starts
- TTL prevents unbounded memory growth

### Reactive Performance

- WebSocket overhead: ~2ms per message
- DOM morphing: ~5ms for moderate changes
- Update batching prevents animation frame drops
- Compression reduces message size by ~70%

### Combined Performance

With both caching and reactivity:
- Initial page load: Fully cached, <10ms render time
- Interactive updates: Only changed components update
- Network usage: Only deltas transmitted
- Memory usage: Bounded by cache TTL and active sessions

## Configuration Examples

### Development Configuration

```crystal
# config/initializers/components.cr
ComponentCache.configure do |config|
  config.enabled = false  # Disable caching for development
  config.cache_store = MemoryCacheStore.new
end

# Enable reactive system debugging
ENV["REACTIVE_DEBUG"] = "true"
```

### Production Configuration

```crystal
# config/initializers/components.cr
ComponentCache.configure do |config|
  config.enabled = true
  config.cache_store = RedisCacheStore.new(
    Redis::Client.new(url: ENV["REDIS_URL"])
  )
  config.namespace = "myapp:#{Amber.env}:components"
end

# Warm cache on deployment
after_deploy do
  ComponentCacheWarmer.warm_common_components
end
```

### WebSocket Configuration

```crystal
# config/routes.cr
routes :web do
  # Regular routes...
  
  ws "/reactive", ReactiveSocket.new
end
```

## Testing Strategies

### Testing Cached Components

```crystal
describe ProductCard do
  it "uses cache on second render" do
    card = ProductCard.new(product)
    
    first_render = card.render
    second_render = card.render
    
    # Should hit cache
    expect(ComponentCache.cache_store).to have_received(:read)
  end
  
  it "invalidates cache when product updates" do
    card = ProductCard.new(product)
    card.render
    
    product.update(price: 99.99)
    new_render = card.render
    
    expect(new_render).to include("99.99")
  end
end
```

### Testing Reactive Components

```crystal
describe ReactiveCounter do
  it "updates state on increment" do
    counter = ReactiveCounter.new
    counter.increment(JSON.parse('{"value": "1"}'))
    
    expect(counter.get_state("count")).to eq(1)
    expect(counter.changed?).to be_true
  end
  
  it "sends update message after state change" do
    session = ReactiveSession.create("test")
    session.register_component("c1", "Counter", JSON.any({}), nil)
    
    session.dispatch_action("c1", "increment", JSON.any({}))
    
    # Verify update was sent
    expect(ReactiveSocket.connections["test"]).to have_sent_message
  end
end
```

## Migration Guide

### Adding Caching to Existing Components

```crystal
# Before
class ProductList < Component
  def render
    # Complex rendering logic
  end
end

# After
class ProductList < Component
  include Cacheable
  
  def cache_key_parts
    [self.class.name, products.map(&.id).join("-")]
  end
  
  def render_content
    # Same rendering logic, now cached
  end
end
```

### Making Components Reactive

```crystal
# Before
class SearchForm < Component
  def render
    # Static form
  end
end

# After  
class SearchForm < ReactiveStatefulComponent
  def search(data : JSON::Any)
    query = data["value"].as_s
    results = perform_search(query)
    set_state("results", results.to_json)
  end
  
  def render_content
    # Form with reactive results
  end
end
```

## Troubleshooting

### Common Caching Issues

1. **Cache not invalidating**: Check cache key includes all volatile data
2. **Memory growth**: Ensure TTL is set for cache entries
3. **Stale content**: Verify cache dependencies are correct

### Common Reactive Issues

1. **Components not updating**: Ensure `data-reactive` attributes are present
2. **WebSocket disconnections**: Check for proxy/firewall issues
3. **State sync problems**: Verify state serialization is correct

## Future Enhancements

### Planned Features

1. **Partial Component Updates**: Update specific parts of large components
2. **Offline Support**: Queue actions when disconnected
3. **Component Streaming**: Send components as they render
4. **State Persistence**: Save component state across sessions
5. **Dev Tools**: Browser extension for debugging components

### Experimental Features

1. **Edge Caching**: Cache components at CDN level
2. **WebRTC Data Channels**: Lower latency for updates
3. **Service Worker Integration**: Better offline experience
4. **Differential State Sync**: Only send state deltas