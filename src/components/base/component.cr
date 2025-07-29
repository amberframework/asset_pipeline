module Components
  # Base class for all components
  # Components are reusable, composable units built from HTML elements
  abstract class Component
    # Unique identifier for this component instance
    getter component_id : String
    
    # Component attributes (props)
    getter attributes : Hash(String, String)
    
    # Component children
    getter children : Array(Component | Elements::HTMLElement | String)
    
    def initialize(**attrs)
      @component_id = generate_component_id
      @attributes = {} of String => String
      @children = [] of Component | Elements::HTMLElement | String
      
      # Process attributes
      attrs.each do |key, value|
        @attributes[key.to_s] = value.to_s
      end
    end
    
    # Add a child to the component
    def <<(child : Component | Elements::HTMLElement | String) : self
      @children << child
      self
    end
    
    # Add multiple children
    def add_children(*children : Component | Elements::HTMLElement | String) : self
      children.each { |child| self << child }
      self
    end
    
    # Build content using a block
    def build(&block : self -> Nil) : self
      yield self
      self
    end
    
    # Get an attribute value
    def [](name : String) : String?
      @attributes[name]?
    end
    
    # Set an attribute value
    def []=(name : String, value : String) : String
      @attributes[name] = value
    end
    
    # Render the component to HTML string
    def render : String
      render_content
    end
    
    # Abstract method to be implemented by subclasses
    abstract def render_content : String
    
    # Generate a unique component ID
    private def generate_component_id : String
      "component-#{Time.utc.to_unix_ms}-#{Random.rand(10000)}"
    end
    
    # Render children components/elements
    protected def render_children : String
      @children.map do |child|
        case child
        when Component
          child.render
        when Elements::HTMLElement
          child.render
        when String
          escape_html(child)
        else
          child.to_s
        end
      end.join
    end
    
    # Escape HTML content
    protected def escape_html(content : String) : String
      content.gsub('&', "&amp;")
             .gsub('<', "&lt;")
             .gsub('>', "&gt;")
             .gsub('"', "&quot;")
             .gsub('\'', "&#39;")
    end
    
    # Convert to string (alias for render)
    def to_s(io : IO) : Nil
      io << render
    end
  end
end