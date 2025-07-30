# Crystal Component System - Styling Approaches

## Current Approach: Inline CSS

Currently, CSS is embedded directly in each HTML page using `<style>` tags:

```crystal
class LayoutComponent < Components::StatelessComponent
  def render_content : String
    # ...
    style = Components::Elements::Style.new
    style << css_content
    head << style
    # ...
  end
  
  private def css_content : String
    <<-CSS
    body { font-family: sans-serif; }
    /* ... more CSS ... */
    CSS
  end
end
```

## Recommended Production Approaches

### 1. External Stylesheets with Asset Pipeline

Create a proper asset pipeline that:
- Compiles CSS/SCSS files
- Generates versioned filenames for cache busting
- Minifies for production
- Serves via CDN

```crystal
# In your layout component
link = Components::Elements::Link.new(
  rel: "stylesheet",
  href: "/assets/application-#{asset_hash}.css"
)
head << link
```

### 2. Component-Scoped Styles

Each component could define its own styles with automatic scoping:

```crystal
class ButtonComponent < Components::StatelessComponent
  def self.styles : String
    <<-CSS
    .btn {
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 4px;
    }
    .btn-primary {
      background: #007bff;
      color: white;
    }
    CSS
  end
  
  def render_content : String
    # Component automatically gets scoped classes
  end
end

# StyleSheet collector
class StyleSheet
  def self.collect_component_styles
    # Automatically collect all component styles
    # Generate scoped CSS with unique prefixes
    # Output single stylesheet
  end
end
```

### 3. CSS-in-Crystal (Styled Components Pattern)

```crystal
class StyledButton < Components::StatelessComponent
  def render_content : String
    Components::Elements::Button.new(
      class: styled_class,
      style: inline_styles
    ).build do |btn|
      btn << @attributes["label"]
    end.render
  end
  
  private def styled_class : String
    # Generate unique class name
    "btn-#{component_id}"
  end
  
  private def inline_styles : String
    # Or use inline styles for dynamic values
    "background-color: #{@attributes["color"]? || "#007bff"};"
  end
end
```

### 4. Utility-First CSS (Tailwind-like)

```crystal
Components::Elements::Button.new(
  class: "px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
)
```

### 5. CSS Modules Pattern

```crystal
# styles/button.module.css
# .button { ... }
# .primary { ... }

class ButtonComponent < Components::StatelessComponent
  CSS_MODULE = CSSModule.load("styles/button.module.css")
  
  def render_content : String
    Components::Elements::Button.new(
      class: CSS_MODULE["button primary"]
    )
  end
end
```

## Implementing a Basic Asset Pipeline

Here's a simple approach to get started:

```crystal
module Components
  class AssetPipeline
    @@styles = {} of String => String
    
    # Register component styles
    def self.register_styles(component_name : String, styles : String)
      @@styles[component_name] = styles
    end
    
    # Generate combined stylesheet
    def self.generate_stylesheet : String
      @@styles.values.join("\n")
    end
    
    # Generate link tag
    def self.stylesheet_link_tag : Elements::Link
      # In development, could use inline styles
      # In production, write to file and serve
      
      if ENV["CRYSTAL_ENV"] == "production"
        # Write to public/assets/application.css
        File.write("public/assets/application.css", generate_stylesheet)
        
        Elements::Link.new(
          rel: "stylesheet",
          href: "/assets/application.css"
        )
      else
        # Return style tag for development
        style = Elements::Style.new
        style << generate_stylesheet
        style
      end
    end
  end
end
```

## Next Steps

1. **Phase 1**: Extract common styles into a shared CSS file
2. **Phase 2**: Implement component-level style registration
3. **Phase 3**: Add CSS preprocessing (variables, nesting)
4. **Phase 4**: Implement proper asset pipeline with:
   - Fingerprinting for cache busting
   - Minification
   - Source maps
   - Hot reloading in development

## Example Implementation

To start, you could modify the LayoutComponent:

```crystal
class LayoutComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Html.new(lang: "en").build do |html|
      head = Components::Elements::Head.new
      
      # Add external stylesheet
      if production?
        head << Components::Elements::Link.new(
          rel: "stylesheet",
          href: "/css/application.min.css"
        )
      else
        # Keep inline for development
        style = Components::Elements::Style.new
        style << css_content
        head << style
      end
      
      # ... rest of component
    end.render
  end
end
```

This would be a good foundation for a more sophisticated styling system that scales better for larger applications.