# Amber Component System - Complete Project Overview

## Executive Summary

The Amber Component System is a comprehensive view layer solution for the Crystal-based Amber web framework. It replaces traditional ERB-style templates with a type-safe, component-based architecture inspired by modern frameworks like React and Phoenix LiveView, while leveraging Crystal's compile-time guarantees and performance characteristics.

## Problem Statement

The current Amber framework faces several challenges in its view layer:

1. **Template Complexity**: ECR (Embedded Crystal) templates become unwieldy as applications grow, mixing logic and presentation in ways that are difficult to maintain
2. **Limited Reusability**: Partial templates lack proper scoping and parameter passing, making component reuse challenging
3. **No Built-in Reactivity**: Building interactive UIs requires hand-rolling JavaScript or adopting heavyweight frontend frameworks
4. **Type Safety**: String-based templates lose Crystal's type safety advantages
5. **Performance**: Re-rendering entire templates is inefficient for dynamic content

## Solution Overview

The Amber Component System addresses these challenges through a multi-layered architecture:

```
HTML Elements (Type-safe building blocks)
    ↓
Components (Reusable, composable units)
    ↓
Caching Layer (Performance optimization)
    ↓
Reactive System (Real-time updates)
    ↓
Application Views (Complete pages)
```

### What Makes This System Unique

**Every HTML tag becomes a Crystal class.** This is the fundamental innovation that enables everything else:

- `<div>` → `Div` class
- `<input>` → `Input` class  
- `<form>` → `Form` class
- ... and so on for all 100+ HTML5 elements

This isn't a wrapper or abstraction - it's a complete object-oriented representation of HTML itself. Components are then built by composing these element objects together, maintaining type safety throughout the entire view layer.

## Core Architecture

### 1. HTML Element Layer (Foundation)

**This is the foundational layer of the entire system.** Every single HTML5 element in the specification has its own dedicated Crystal class. This is not an abstraction or a wrapper - it's a complete object-oriented representation of HTML.

#### Element Class Hierarchy

```crystal
HTMLElement (base class)
├── VoidElement (self-closing elements)
│   ├── Area
│   ├── Base
│   ├── Br
│   ├── Col
│   ├── Embed
│   ├── Hr
│   ├── Img
│   ├── Input
│   ├── Link
│   ├── Meta
│   ├── Param
│   ├── Source
│   ├── Track
│   └── Wbr
└── ContainerElement (elements with children)
    ├── A
    ├── Abbr
    ├── Address
    ├── Article
    ├── Aside
    ├── Audio
    ├── B
    ├── Blockquote
    ├── Body
    ├── Button
    ├── Canvas
    ├── Caption
    ├── Code
    ├── Div
    ├── Form
    ├── H1, H2, H3, H4, H5, H6
    ├── Head
    ├── Html
    ├── Label
    ├── Li
    ├── Main
    ├── Nav
    ├── P
    ├── Script
    ├── Section
    ├── Select
    ├── Span
    ├── Table
    ├── Textarea
    ├── Video
#### Scope of HTML Element Classes

The complete implementation includes classes for:

- **Document**: `Html`, `Head`, `Body`, `Title`, `Meta`, `Link`, `Style`, `Script`
- **Sections**: `Header`, `Footer`, `Nav`, `Main`, `Section`, `Article`, `Aside`, `H1`-`H6`
- **Grouping**: `P`, `Div`, `Span`, `Pre`, `Blockquote`, `Ol`, `Ul`, `Li`, `Dl`, `Dt`, `Dd`
- **Text**: `A`, `Em`, `Strong`, `Small`, `Cite`, `Code`, `Kbd`, `Var`, `Samp`, `Sub`, `Sup`
- **Edits**: `Ins`, `Del`, `Mark`
- **Embedded**: `Img`, `Iframe`, `Embed`, `Object`, `Video`, `Audio`, `Canvas`, `Svg`
- **Tables**: `Table`, `Thead`, `Tbody`, `Tfoot`, `Tr`, `Th`, `Td`, `Caption`
- **Forms**: `Form`, `Input`, `Textarea`, `Select`, `Option`, `Button`, `Label`, `Fieldset`
- **Interactive**: `Details`, `Summary`, `Dialog`, `Menu`
- **Void Elements**: `Br`, `Hr`, `Area`, `Base`, `Col`, `Source`, `Track`, `Wbr`

Total: 100+ element classes, each with proper attribute validation

1. **One Class Per HTML Tag**: Every HTML5 tag has exactly one corresponding Crystal class
2. **Attribute Management**: Each element class manages its specific attributes
3. **Validation Built-In**: Elements validate their attributes according to HTML5 spec
4. **No String Templates**: Elements render themselves without template strings
5. **Composable Building Blocks**: Elements are designed to be composed into components

#### Element Implementation Example

```crystal
# Every HTML element is a full Crystal class
class Input < VoidElement
  def initialize(type : String = "text", name : String? = nil, value : String? = nil, **attrs)
    super("input", **attrs)
    set_attribute("type", type)
    set_attribute("name", name) if name
    set_attribute("value", value) if value
  end
  
  def validate_attribute(name : String, value : String?)
    case name
    when "type"
      valid_types = ["text", "password", "email", "number", "date", "checkbox", "radio", ...]
      unless valid_types.includes?(value)
        raise "Invalid input type: #{value}"
      end
    end
  end
end

class Div < HTMLElement
  def initialize(**attrs)
    super("div", **attrs)
  end
end

class Form < HTMLElement
  def initialize(action : String? = nil, method : String = "GET", **attrs)
    super("form", **attrs)
    set_attribute("action", action) if action
    set_attribute("method", method)
  end
  
  def validate_attribute(name : String, value : String?)
    case name
    when "method"
      unless ["GET", "POST", "dialog"].includes?(value.upcase)
        raise "Invalid form method: #{value}"
      end
    end
  end
end
```

#### Why This Matters

This element layer is NOT just a implementation detail - it's the fundamental building block that enables:

1. **Type-Safe HTML**: Can't create invalid HTML structures
2. **IDE Support**: Full autocomplete for every HTML element and attribute  
3. **Compile-Time Validation**: Invalid attributes are caught before runtime
4. **No XSS**: Automatic escaping is built into the element rendering
5. **Extensibility**: New HTML elements can be added as classes

Example of building with elements:
```crystal
# Traditional template approach (error-prone)
# <div class="<%= @class %>"><%= @content %></div>

# Element approach (type-safe)
Div.new(class: @class) << @content

# Complex structure with full type safety
form = Form.new(action: "/submit", method: "POST").build do |f|
  f << Label.new("Email", for: "email")
  f << Input.new(type: "email", name: "email", required: true)
  f << Button.new("Submit", type: "submit")
end
```

### 2. Component System (Built on Elements)

Components are NOT a separate rendering system - they are compositions of HTML Element classes. Every component is built by combining one or more element instances into reusable units.

#### Component Types

**Stateless Components**: Pure functions of their inputs
- No internal state
- Highly cacheable
- Used for presentation

**Stateful Components**: Maintain internal state
- Track their own data
- Can respond to user interactions
- Support real-time updates

Example:
```crystal
class ButtonComponent < StatelessComponent
  def render_content : String
    # Components use element classes, not string templates
    Button.new(@label, class: button_classes).render
  end
end

class CardComponent < StatelessComponent
  def render_content : String
    # Composing multiple elements into a component
    Div.new(class: "card").build do |card|
      card << Img.new(src: @image_url, alt: @title, class: "card-img-top")
      card << Div.new(class: "card-body").build do |body|
        body << H5.new(@title, class: "card-title")
        body << P.new(@description, class: "card-text")
        body << Button.new("Read More", class: "btn btn-primary")
      end
    end.render
  end
end

class CounterComponent < StatefulComponent
  def initialize
    set_state("count", 0)
  end
  
  def increment
    set_state("count", get_state("count") + 1)
  end
  
  def render_content : String
    # Even reactive components are built from element classes
    Div.new(class: "counter").build do |div|
      div << Span.new("Count: #{get_state("count")}")
      div << Button.new("+", "data-action": "click->increment")
    end.render
  end
end
```

#### The Element → Component Relationship

```
HTML Element Classes (Foundation)
    ↓ (composed into)
Components (Reusable Units)  
    ↓ (cached and made reactive)
Interactive Application Views
```

This is a critical distinction:
- **Elements** = Direct 1:1 mapping to HTML tags
- **Components** = Compositions of elements with behavior
- **No string templates anywhere** = Everything is type-safe Crystal objects

### 3. Caching System

Inspired by Rails' Russian doll caching:
- **Automatic Cache Key Generation**: Based on component class, attributes, and state
- **Dependency Tracking**: Parent components know when children are updated
- **Multiple Cache Stores**: In-memory for development, Redis for production
- **Smart Invalidation**: Only affected components are re-rendered

Performance impact:
- First render: ~50ms
- Cached render: ~0.1ms
- 500x improvement for complex components

### 4. Reactive System

Real-time UI updates without page refreshes:

#### Client-Side (Vanilla JavaScript)
- **No Framework Dependency**: ~4KB vanilla JS library
- **WebSocket Connection**: Persistent connection for real-time updates
- **Smart DOM Diffing**: Minimal DOM updates using morphing algorithm
- **Event System**: Extensible through custom events

#### Server-Side (Crystal)
- **WebSocket Handler**: Manages client connections
- **Action Dispatch**: Routes client events to component methods
- **Automatic State Sync**: Components update clients when state changes
- **Selective Updates**: Only changed components are sent to client

Example interaction flow:
1. User clicks button → 
2. Client sends action via WebSocket → 
3. Server updates component state → 
4. Server sends DOM diff → 
5. Client updates only changed elements

### 5. Form System

Forms are first-class citizens with special handling:
- **Form Context**: Propagates styling and validation rules
- **Field Dependencies**: Changing one field can update others
- **Built-in Validation**: Client and server-side validation
- **State Management**: Every form element tracks value, touched, dirty, and errors

## Key Design Principles

### 1. Progressive Enhancement
- Components work without JavaScript
- Reactivity enhances but doesn't require client-side code
- SEO-friendly server-side rendering

### 2. Type Safety Throughout
- HTML elements enforce valid attributes
- Component props are typed
- No runtime template errors

### 3. Performance First
- Aggressive caching for stateless components
- Minimal data transfer for updates
- Efficient DOM diffing

### 4. Developer Experience
- Familiar component model
- Clear separation of concerns
- Excellent IDE support

## Implementation Strategy

### Critical Implementation Note: Elements First

**The HTML Element classes MUST be implemented before any component work begins.** This is not optional - the entire system depends on having a complete, type-safe representation of HTML as Crystal classes.

Implementation order:
1. Create base `HTMLElement` and `VoidElement` classes
2. Implement ALL HTML5 element classes (100+ classes)
3. Add attribute validation for each element
4. Only THEN begin component implementation

This ensures:
- Components have a solid foundation to build on
- No temptation to fall back to string templates
- Type safety from the ground up
- Consistent API across the entire system

### Phase Structure

The system is implemented in 5 phases, each building on the previous:

1. **HTML Element Classes**: Create Crystal classes for ALL HTML5 elements
2. **Core Component System**: Basic component architecture built on elements
3. **Caching System**: Performance optimization layer
4. **Reactive Client**: JavaScript client for real-time updates
5. **Reactive Server**: WebSocket handling and state management

**Phase 1 is the foundation and must be complete before moving to Phase 2.**

### File Organization

```
src/
  components/
    base/          # Core component classes
    elements/      # HTML element classes
    reactive/      # Reactive system
    cache/         # Caching infrastructure
    
public/
  js/
    amber-reactive.js  # Client-side reactive system
    
config/
  initializers/
    components.cr  # System configuration
```

## Benefits Over Traditional Approaches

### The Fundamental Shift: From Templates to Objects

#### Traditional ECR/ERB Approach
```erb
<!-- String-based, no compile-time checking -->
<div class="<%= card_class %>">
  <img src="<%= image_url %>" alt="<%= title %>">
  <div class="card-body">
    <h5><%= title %></h5>
    <p><%= description %></p>
    <button class="btn" type="<%= button_type %>">Click</button>
  </div>
</div>
```

Problems:
- No validation of HTML structure
- XSS vulnerabilities from interpolation
- Runtime errors from typos
- No IDE support
- Mixing logic and presentation

#### Element-Based Approach
```crystal
# Every piece is a typed Crystal object
Div.new(class: card_class).build do |card|
  card << Img.new(src: image_url, alt: title)
  card << Div.new(class: "card-body").build do |body|
    body << H5.new(title)
    body << P.new(description)
    body << Button.new("Click", type: button_type, class: "btn")
  end
end
```

Benefits:
- Compile-time validation of structure
- Automatic XSS protection
- Type errors caught immediately
- Full IDE autocomplete
- Clear separation of structure and logic

### Compared to ERB/ECR Templates
- **Type Safety**: Errors caught at compile time
- **Reusability**: True component composition
- **Performance**: Intelligent caching
- **Maintainability**: Clear separation of concerns

### Compared to JavaScript Frameworks
- **Server Authority**: State lives on server
- **Minimal JavaScript**: ~4KB vs 100KB+ for React
- **SEO Friendly**: Full server-side rendering
- **Progressive**: Works without JavaScript

### Compared to Phoenix LiveView
- **Language Integration**: Native Crystal implementation
- **Flexible Client**: Not tied to specific JS framework
- **Component Caching**: Better performance for static content
- **Gradual Adoption**: Can mix with existing templates

## Real-World Example

Here's how a dynamic form with dependent fields would be implemented:

```crystal
class BookingForm < ReactiveStatefulComponent
  def initialize
    set_state("date", "")
    set_state("available_times", [])
  end
  
  def date_changed(data)
    date = data["value"]
    times = fetch_available_times(date)
    set_state("available_times", times)
  end
  
  def render_content
    # Everything starts with HTML element classes
    Form.new(action: "/book", method: "POST").build do |f|
      # Compose elements to build the form
      f << Div.new(class: "form-group").build do |group|
        group << Label.new("Select Date", for: "date")
        group << Input.new(
          type: "date",
          name: "date",
          id: "date",
          value: get_state("date"),
          class: "form-control",
          "data-action": "change->date_changed"
        )
      end
      
      f << Div.new(class: "form-group").build do |group|
        group << Label.new("Available Times", for: "time")
        group << Select.new(
          name: "time",
          id: "time",
          class: "form-control",
          disabled: get_state("available_times").empty?
        ).build do |select|
          get_state("available_times").each do |time|
            select << Option.new(time["label"], value: time["value"])
          end
        end
      end
      
      f << Button.new("Book Appointment", type: "submit", class: "btn btn-primary")
    end.render
  end
end
```

Notice how every piece of HTML is represented by a Crystal class:
- `Form` class for the form element
- `Div` class for grouping
- `Label` class for labels
- `Input` class for the date picker
- `Select` and `Option` classes for the dropdown
- `Button` class for submission

This is not using templates or strings - it's pure Crystal objects all the way down.

When the user selects a date:
1. The `date_changed` action is triggered
2. Server fetches available times for that date
3. Component state is updated
4. Only the select dropdown is re-rendered and sent to client
5. DOM is updated without page refresh

## Success Metrics

The system is successful when:
- Entire pages can be built using only components (no templates)
- Stateless components render from cache after first load
- Reactive components update without page refresh
- Forms handle complex interactions elegantly
- Performance exceeds traditional template rendering
- Developers find it easier to build and maintain views

## Migration Path

Existing Amber applications can adopt the system gradually:
1. Start by creating components for new features
2. Replace complex partials with components
3. Add caching to expensive views
4. Enable reactivity for interactive elements
5. Eventually replace all templates

## Future Enhancements

The architecture supports future additions:
- **Streaming SSR**: Send HTML as components render
- **Component Marketplace**: Share components between projects
- **Visual Component Editor**: Drag-and-drop interface building
- **Advanced Diffing**: More efficient update algorithms
- **WebAssembly Integration**: High-performance client operations

## Conclusion

The Amber Component System transforms how views are built in Crystal web applications. By starting with a complete object-oriented representation of HTML itself - where every tag is a Crystal class - we create a foundation that enables true type safety throughout the entire view layer.

Components become simple compositions of these element classes, caching provides automatic performance optimization, and the reactive system adds real-time capabilities - all while maintaining the simplicity and performance benefits of server-side rendering.

The system is designed to be implemented incrementally, with each phase providing immediate value. However, the HTML Element layer must be implemented first and completely, as it forms the foundation upon which everything else is built.

The ultimate goal is to make building complex, interactive web applications in Crystal as productive as modern JavaScript frameworks, while maintaining superior performance and type safety - starting from the very atoms of HTML itself.