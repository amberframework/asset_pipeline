# Crystal Component System Usage Guide

## Overview

The Crystal Component System provides a type-safe, template-free way to generate HTML and build web applications. Every HTML element is a Crystal class, providing compile-time validation and excellent IDE support.

## Basic HTML Generation

### Creating Elements

```crystal
# Create a div element
div = Components::Elements::Div.new(class: "container")
div << "Hello, World!"
puts div.render
# Output: <div class="container">Hello, World!</div>

# Create a link
link = Components::Elements::A.new(href: "https://example.com", target: "_blank")
link << "Visit Example"
puts link.render
# Output: <a href="https://example.com" target="_blank">Visit Example</a>
```

### Building Complex Structures

```crystal
# Use the builder pattern for nested elements
article = Components::Elements::Article.new(class: "blog-post").build do |art|
  # Add header
  header = Components::Elements::Header.new
  h1 = Components::Elements::H1.new
  h1 << "My Blog Post"
  header << h1
  art << header
  
  # Add content
  p = Components::Elements::P.new
  p << "This is the content of my blog post."
  art << p
  
  # Add footer
  footer = Components::Elements::Footer.new
  footer << "Posted on #{Time.utc}"
  art << footer
end

puts article.render
```

## Creating Components

### Stateless Components

Stateless components are pure functions of their inputs:

```crystal
class ButtonComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Button.new(
      class: button_classes,
      type: @attributes["type"]? || "button",
      disabled: @attributes["disabled"]?
    ).build do |button|
      # Add icon if specified
      if icon = @attributes["icon"]?
        icon_span = Components::Elements::Span.new(class: "icon")
        icon_span << icon
        button << icon_span
        button << " "
      end
      
      # Add label
      button << (@attributes["label"]? || "Click me")
    end.render
  end
  
  private def button_classes : String
    classes = ["btn"]
    classes << "btn-#{@attributes["variant"]? || "primary"}"
    classes << "btn-#{@attributes["size"]? || "medium"}"
    classes << "disabled" if @attributes["disabled"]?
    classes.join(" ")
  end
end

# Usage
button = ButtonComponent.new(
  label: "Save Changes",
  variant: "success",
  icon: "💾"
)
puts button.render
```

### Stateful Components

Stateful components maintain internal state:

```crystal
class CounterComponent < Components::StatefulComponent
  protected def initialize_state
    set_state("count", 0)
  end
  
  def render_content : String
    Components::Elements::Div.new(class: "counter").build do |div|
      # Display count
      display = Components::Elements::Div.new(class: "count-display")
      display << "Count: #{get_state("count").try(&.as_i?) || 0}"
      div << display
      
      # Buttons
      buttons = Components::Elements::Div.new(class: "buttons")
      
      inc_btn = Components::Elements::Button.new(onclick: "increment()")
      inc_btn << "+"
      buttons << inc_btn
      
      dec_btn = Components::Elements::Button.new(onclick: "decrement()")
      dec_btn << "-"
      buttons << dec_btn
      
      div << buttons
    end.render
  end
  
  def increment
    count = get_state("count").try(&.as_i?) || 0
    set_state("count", count + 1)
  end
  
  def decrement
    count = get_state("count").try(&.as_i?) || 0
    set_state("count", count - 1)
  end
end
```

## Generating Complete Pages

### Basic Page Structure

```crystal
def generate_page(title : String, content : String) : String
  Components::Elements::Html.new(lang: "en").build do |html|
    # Head section
    head = Components::Elements::Head.new
    
    # Meta tags
    head << Components::Elements::Meta.new(charset: "UTF-8")
    head << Components::Elements::Meta.new(
      name: "viewport",
      content: "width=device-width, initial-scale=1.0"
    )
    
    # Title
    title_elem = Components::Elements::Title.new
    title_elem << title
    head << title_elem
    
    html << head
    
    # Body section
    body = Components::Elements::Body.new
    body << content
    html << body
  end.render
end

# Generate and save to file
html_content = generate_page("My Page", "<h1>Welcome!</h1>")
File.write("output.html", html_content)
```

### Using Layout Components

```crystal
class LayoutComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Html.new(lang: "en").build do |html|
      html << render_head
      html << render_body
    end.render
  end
  
  private def render_head : String
    Components::Elements::Head.new.build do |head|
      head << Components::Elements::Meta.new(charset: "UTF-8")
      
      title = Components::Elements::Title.new
      title << (@attributes["title"]? || "My Site")
      head << title
      
      # Add stylesheets
      if stylesheets = @attributes["stylesheets"]?
        stylesheets.split(",").each do |href|
          head << Components::Elements::Link.new(
            rel: "stylesheet",
            href: href.strip
          )
        end
      end
    end.render
  end
  
  private def render_body : String
    Components::Elements::Body.new.build do |body|
      # Header
      body << render_header
      
      # Main content
      main = Components::Elements::Main.new(class: "main-content")
      main << @children.map(&.to_s).join
      body << main
      
      # Footer
      body << render_footer
    end.render
  end
  
  private def render_header : String
    Components::Elements::Header.new(class: "site-header").build do |header|
      nav = Components::Elements::Nav.new
      # Add navigation items...
      header << nav
    end.render
  end
  
  private def render_footer : String
    Components::Elements::Footer.new(class: "site-footer").build do |footer|
      footer << "© #{Time.utc.year} My Site"
    end.render
  end
end

# Usage
layout = LayoutComponent.new(
  title: "Home Page",
  stylesheets: "/css/main.css,/css/home.css"
)

# Add page content
content = Components::Elements::Div.new(class: "content").build do |div|
  h1 = Components::Elements::H1.new
  h1 << "Welcome to My Site"
  div << h1
  
  p = Components::Elements::P.new
  p << "This is a paragraph of content."
  div << p
end

layout << content.render
File.write("home.html", layout.render)
```

## Caching

### Enable Caching

```crystal
# Configure caching
Components::Cache.configure do |config|
  config.use_memory_cache  # or config.use_redis_cache
  config.enabled = true
  config.default_expires_in = 1.hour
  config.apply!
end
```

### Cache Component Renders

```crystal
class ExpensiveComponent < Components::StatelessComponent
  def render_content : String
    # This will be cached
    cache do
      # Expensive computation...
      sleep 1.second  # Simulate expensive work
      
      Components::Elements::Div.new(class: "expensive").build do |div|
        div << "Expensive content generated at #{Time.utc}"
      end.render
    end
  end
end

# First render takes 1 second
component = ExpensiveComponent.new
component.render

# Subsequent renders are instant (from cache)
component.render
```

## Reactive Components

### Creating Reactive Components

```crystal
class TodoListComponent < Components::Reactive::ReactiveComponent
  protected def initialize_state
    set_state("todos", [] of JSON::Any)
    set_state("input", "")
  end
  
  def render_content : String
    Components::Elements::Div.new(class: "todo-list").build do |div|
      # Input form
      form = Components::Elements::Form.new("data-action": "submit->addTodo")
      
      input = Components::Elements::Input.new(
        type: "text",
        value: get_state("input").try(&.as_s?) || "",
        "data-action": "input->updateInput"
      )
      form << input
      
      add_btn = Components::Elements::Button.new(type: "submit")
      add_btn << "Add Todo"
      form << add_btn
      
      div << form
      
      # Todo list
      list = Components::Elements::Ul.new
      todos = get_state("todos").try(&.as_a?) || [] of JSON::Any
      
      todos.each_with_index do |todo, index|
        li = Components::Elements::Li.new
        li << todo["text"].as_s
        
        del_btn = Components::Elements::Button.new(
          "data-action": "click->deleteTodo",
          "data-index": index.to_s
        )
        del_btn << "Delete"
        li << del_btn
        
        list << li
      end
      
      div << list
    end.render
  end
  
  def update_input(event : JSON::Any)
    set_state("input", event["value"].as_s)
  end
  
  def add_todo(event : JSON::Any)
    input = get_state("input").try(&.as_s?) || ""
    return if input.empty?
    
    todos = get_state("todos").try(&.as_a?) || [] of JSON::Any
    todos << JSON::Any.new({"text" => JSON::Any.new(input)})
    
    set_state("todos", todos)
    set_state("input", "")
  end
  
  def delete_todo(event : JSON::Any)
    index = event["index"]?.try(&.as_s?).try(&.to_i?)
    return unless index
    
    todos = get_state("todos").try(&.as_a?) || [] of JSON::Any
    todos.delete_at(index)
    set_state("todos", todos)
  end
end
```

### Setting Up WebSocket Handler

```crystal
# In your web framework (e.g., Amber)
pipeline :web do
  plug Components::Reactive::ReactiveHandler.new(
    websocket_path: "/ws",
    action_path_prefix: "/components/action"
  )
end

# In your layout, include the reactive JavaScript
body << Components::Integration.reactive_script_tag(debug: false)
```

## Forms and Validation

```crystal
class ContactFormComponent < Components::StatefulComponent
  protected def initialize_state
    set_state("name", "")
    set_state("email", "")
    set_state("message", "")
    set_state("errors", {} of String => JSON::Any)
    set_state("submitted", false)
  end
  
  def render_content : String
    if get_state("submitted").try(&.as_bool?)
      render_success
    else
      render_form
    end
  end
  
  private def render_form : String
    Components::Elements::Form.new(
      method: "post",
      action: "/contact"
    ).build do |form|
      # Name field
      form << render_field("name", "text", "Your Name", required: true)
      
      # Email field  
      form << render_field("email", "email", "Email", required: true)
      
      # Message field
      form << render_textarea("message", "Message", required: true)
      
      # Submit button
      submit = Components::Elements::Button.new(type: "submit")
      submit << "Send Message"
      form << submit
    end.render
  end
  
  private def render_field(name : String, type : String, label : String, required = false) : String
    Components::Elements::Div.new(class: "field").build do |div|
      label_elem = Components::Elements::Label.new(for: name)
      label_elem << label
      label_elem << " *" if required
      div << label_elem
      
      input = Components::Elements::Input.new(
        type: type,
        name: name,
        id: name,
        value: get_state(name).try(&.as_s?) || "",
        required: required ? "required" : nil
      )
      div << input
      
      # Show error if any
      errors = get_state("errors").try(&.as_h?)
      if errors && (error = errors[name]?)
        error_div = Components::Elements::Div.new(class: "error")
        error_div << error.as_s
        div << error_div
      end
    end.render
  end
  
  def validate_and_submit
    errors = {} of String => JSON::Any
    
    # Validate fields
    if get_state("name").try(&.as_s?).try(&.empty?)
      errors["name"] = JSON::Any.new("Name is required")
    end
    
    email = get_state("email").try(&.as_s?) || ""
    if !email.includes?("@")
      errors["email"] = JSON::Any.new("Invalid email address")
    end
    
    if get_state("message").try(&.as_s?).try(&.empty?)
      errors["message"] = JSON::Any.new("Message is required")
    end
    
    if errors.empty?
      # Submit form
      set_state("submitted", true)
    else
      set_state("errors", errors)
    end
  end
end
```

## Writing to Files

```crystal
# Generate static site
def generate_static_site
  pages = {
    "index.html" => generate_home_page,
    "about.html" => generate_about_page,
    "contact.html" => generate_contact_page
  }
  
  # Ensure output directory exists
  Dir.mkdir_p("dist")
  
  # Write each page
  pages.each do |filename, content|
    path = File.join("dist", filename)
    File.write(path, content)
    puts "Generated: #{path} (#{content.bytesize} bytes)"
  end
  
  # Copy assets
  copy_assets
end

def generate_home_page : String
  layout = LayoutComponent.new(title: "Home")
  
  # Add home page content
  home_content = Components::Elements::Div.new.build do |div|
    hero = Components::Elements::Section.new(class: "hero")
    h1 = Components::Elements::H1.new
    h1 << "Welcome to Crystal Components"
    hero << h1
    div << hero
    
    # Add more sections...
  end
  
  layout << home_content.render
  layout.render
end

# Run the generator
generate_static_site
```

## Best Practices

1. **Use Components for Reusability**: Create components for any UI element you use more than once.

2. **Type Safety**: Leverage Crystal's type system. Define clear attribute types in your components.

3. **Composition over Inheritance**: Build complex components by composing simpler ones.

4. **Cache Expensive Operations**: Use the caching system for components that are expensive to render.

5. **Separate Concerns**: Keep your HTML structure (elements) separate from your business logic (components).

6. **Use Builder Pattern**: For complex nested structures, use the builder pattern with blocks.

7. **Validate Inputs**: HTML elements automatically validate attributes, but add your own validation in components.

## Example: Complete Blog

See the `examples/` directory for complete examples including:
- `generate_static_site.cr` - Static blog generator
- `interactive_app.cr` - E-commerce site with reactive components

Run them with:
```bash
crystal run examples/generate_static_site.cr
crystal run examples/interactive_app.cr
```

The generated HTML files will be in the `output/` directory.