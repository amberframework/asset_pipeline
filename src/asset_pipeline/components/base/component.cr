require "uuid"

module AssetPipeline
  module Components
    # Base abstract class for all components
    abstract class Component
      # HTML attributes for the component's root element
      property attributes : Hash(String, String)
      
      # Child components that can be nested
      property children : Array(Component)
      
      # Unique identifier for this component instance
      property component_id : String
      
      def initialize(**attrs)
        @attributes = Hash(String, String).new
        @children = Array(Component).new
        @component_id = generate_component_id
        
        # Convert any symbol keys to strings and store attributes
        attrs.each do |key, value|
          @attributes[key.to_s] = value.to_s
        end
      end
      
      # Abstract method that must be implemented by subclasses
      abstract def render_content : String
      
      # Main render method that combines content with attributes
      def render : String
        rendered_content = render_content
        
        # If the content already includes the root element with attributes,
        # return it as-is. Otherwise, we might need to wrap it.
        rendered_content
      end
      
      # Generate an HTML tag with content
      def tag(name : String, content : String? = nil, **tag_attrs) : String
        all_attrs = merge_attributes(tag_attrs)
        attr_string = serialize_attributes(all_attrs)
        
        if content
          "<#{name}#{attr_string}>#{escape_html(content)}</#{name}>"
        else
          yield_content = yield
          "<#{name}#{attr_string}>#{yield_content}</#{name}>"
        end
      end
      
      # Generate an HTML tag with content (block version)
      def tag(name : String, **tag_attrs, &block) : String
        all_attrs = merge_attributes(tag_attrs)
        attr_string = serialize_attributes(all_attrs)
        content = yield
        "<#{name}#{attr_string}>#{content}</#{name}>"
      end
      
      # Generate a self-closing HTML tag
      def self_closing_tag(name : String, **tag_attrs) : String
        all_attrs = merge_attributes(tag_attrs)
        attr_string = serialize_attributes(all_attrs)
        "<#{name}#{attr_string} />"
      end
      
      # Add a child component
      def add_child(child : Component)
        @children << child
      end
      
      # Render all child components
      def render_children : String
        @children.map(&.render).join
      end
      
      # Get the component's class name for identification
      def component_name : String
        self.class.name.split("::").last || "Component"
      end
      
      private def generate_component_id : String
        "#{component_name.downcase}-#{UUID.random.to_s.split("-").first}"
      end
      
      private def merge_attributes(new_attrs) : Hash(String, String)
        merged = @attributes.dup
        new_attrs.each do |key, value|
          key_str = key.to_s
          if key_str == "class" && merged.has_key?("class")
            # Merge CSS classes
            merged["class"] = "#{merged["class"]} #{value}"
          else
            merged[key_str] = value.to_s
          end
        end
        merged
      end
      
      private def serialize_attributes(attrs : Hash(String, String)) : String
        return "" if attrs.empty?
        
        attr_pairs = attrs.map do |key, value|
          escaped_value = escape_html_attribute(value)
          %(#{key}="#{escaped_value}")
        end
        
        " #{attr_pairs.join(" ")}"
      end
      
      private def escape_html(content : String) : String
        content
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub("\"", "&quot;")
          .gsub("'", "&#39;")
      end
      
      private def escape_html_attribute(value : String) : String
        value
          .gsub("&", "&amp;")
          .gsub("\"", "&quot;")
          .gsub("'", "&#39;")
      end
    end
  end
end 