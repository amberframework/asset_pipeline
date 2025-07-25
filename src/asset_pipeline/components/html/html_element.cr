require "../base/stateless_component"

module AssetPipeline
  module Components
    module Html
      # Generic wrapper for any HTML element
      class HTMLElement < StatelessComponent
        property tag_name : String
        property content : String
        property self_closing : Bool
        
        def initialize(@tag_name : String, @content = "", @self_closing = false)
          super()
          @css_classes = Array(String).new
        end
        
        # Extract CSS classes after attributes are set
        def extract_css_classes
          if @attributes.has_key?("class")
            class_value = @attributes["class"]
            @css_classes = class_value.split(/\s+/).reject(&.empty?)
          end
        end
        
        # Constructor for self-closing tags
        def self.self_closing(tag_name : String, attrs = {} of Symbol => String)
          element = allocate
          element.initialize(tag_name, "", true)
          attrs.each { |key, value| element.attributes[key.to_s] = value }
          element.extract_css_classes
          element
        end
        
        # Constructor for container tags with content
        def self.container(tag_name : String, content : String, attrs = {} of Symbol => String)
          element = allocate
          element.initialize(tag_name, content, false)
          attrs.each { |key, value| element.attributes[key.to_s] = value }
          element.extract_css_classes
          element
        end
        
        # Constructor for container tags with block content
        def self.container(tag_name : String, attrs = {} of Symbol => String, &block)
          content = yield
          element = allocate
          element.initialize(tag_name, content, false)
          attrs.each { |key, value| element.attributes[key.to_s] = value }
          element.extract_css_classes
          element
        end
        
        def render_content : String
          if @self_closing
            build_self_closing_tag
          else
            if @content.empty?
              build_container_tag("")
            else
              build_container_tag(@content)
            end
          end
        end
        
        private def build_self_closing_tag : String
          attr_string = serialize_tag_attributes
          "<#{@tag_name}#{attr_string} />"
        end
        
        private def build_container_tag(content : String) : String
          attr_string = serialize_tag_attributes
          "<#{@tag_name}#{attr_string}>#{escape_html(content)}</#{@tag_name}>"
        end
        
        private def serialize_tag_attributes : String
          return "" if @attributes.empty?
          
          attr_pairs = @attributes.map do |key, value|
            escaped_value = escape_html_attribute(value)
            %(#{key}="#{escaped_value}")
          end
          
          " #{attr_pairs.join(" ")}"
        end
        
        def cache_key_parts : Array(String)
          [
            @tag_name,
            @content.empty? ? "empty" : @content[0..50], # First 50 chars for cache key
            @self_closing.to_s,
            css_classes.join("-")
          ]
        end
        
        # Override the infer element type to use the actual tag name
        private def infer_element_type : String
          @tag_name
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
end 