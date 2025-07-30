module Components
  module Elements
    # Abstract base class for all HTML elements
    abstract class HTMLElement
      getter tag_name : String
      getter attributes : Hash(String, String)
      getter children : Array(HTMLElement | String | RawHTML)
      
      def initialize(@tag_name : String, **attrs)
        @attributes = {} of String => String
        @children = [] of HTMLElement | String | RawHTML
        
        # Process attributes
        attrs.each do |key, value|
          set_attribute(key.to_s, value.to_s)
        end
      end
      
      # Set an attribute with validation
      def set_attribute(name : String, value : String?) : self
        return self if value.nil?
        
        # Validate the attribute
        validate_attribute(name, value)
        
        # Handle special attributes
        case name
        when "class"
          add_class(value)
        when "style"
          add_style(value)
        else
          @attributes[name] = value
        end
        
        self
      end
      
      # Remove an attribute
      def remove_attribute(name : String) : self
        @attributes.delete(name)
        self
      end
      
      # Add CSS classes
      def add_class(class_names : String) : self
        existing = @attributes["class"]?.to_s.split(/\s+/).reject(&.empty?)
        new_classes = class_names.split(/\s+/).reject(&.empty?)
        
        combined = (existing + new_classes).uniq
        @attributes["class"] = combined.join(" ") unless combined.empty?
        
        # Register classes with the CSS system
        if defined?(Components::CSS::ClassRegistry)
          Components::CSS::ClassRegistry.instance.register_class(combined.join(" "))
        end
        
        self
      end
      
      # Remove CSS classes
      def remove_class(class_names : String) : self
        return self unless @attributes.has_key?("class")
        
        existing = @attributes["class"].split(/\s+/).reject(&.empty?)
        to_remove = class_names.split(/\s+/).reject(&.empty?)
        
        remaining = existing - to_remove
        
        if remaining.empty?
          @attributes.delete("class")
        else
          @attributes["class"] = remaining.join(" ")
        end
        
        self
      end
      
      # Add inline styles
      def add_style(styles : String) : self
        existing = @attributes["style"]?.to_s
        
        if existing.empty?
          @attributes["style"] = styles
        else
          # Ensure existing ends with semicolon
          existing = existing + ";" unless existing.ends_with?(";")
          @attributes["style"] = existing + " " + styles
        end
        
        self
      end
      
      # Get an attribute value
      def [](name : String) : String?
        @attributes[name]?
      end
      
      # Check if element has a specific class
      def has_class?(class_name : String) : Bool
        return false unless classes = @attributes["class"]?
        classes.split(/\s+/).includes?(class_name)
      end
      
      # Validate attributes (to be overridden by specific elements)
      protected def validate_attribute(name : String, value : String?)
        # Global attribute validation
        case name
        when "id"
          raise ArgumentError.new("ID cannot be empty") if value.to_s.empty?
          raise ArgumentError.new("ID cannot contain spaces") if value.to_s.includes?(" ")
        when "tabindex"
          unless value.to_s.match(/^-?\d+$/)
            raise ArgumentError.new("tabindex must be an integer")
          end
        end
      end
      
      # Render attributes as HTML string
      protected def render_attributes : String
        return "" if @attributes.empty?
        
        attrs = @attributes.map do |name, value|
          # Escape attribute values
          escaped_value = escape_attribute(value)
          %(#{name}="#{escaped_value}")
        end
        
        " " + attrs.join(" ")
      end
      
      # Escape attribute values
      protected def escape_attribute(value : String) : String
        value.gsub('&', "&amp;")
             .gsub('"', "&quot;")
             .gsub('\'', "&#39;")
             .gsub('<', "&lt;")
             .gsub('>', "&gt;")
      end
      
      # Escape HTML content
      protected def escape_html(content : String) : String
        content.gsub('&', "&amp;")
               .gsub('<', "&lt;")
               .gsub('>', "&gt;")
               .gsub('"', "&quot;")
               .gsub('\'', "&#39;")
      end
      
      # Abstract render method to be implemented by subclasses
      abstract def render : String
      
      # Check if this is a void element
      def void_element? : Bool
        false
      end
      
      # Check if this element can contain children
      def can_have_children? : Bool
        !void_element?
      end
      
      # Convert to string (alias for render)
      def to_s(io : IO) : Nil
        io << render
      end
    end
  end
end