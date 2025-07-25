require "../base/stateless_component"

module AssetPipeline
  module Components
    module Examples
      # Button component with variants and CSS class management
      class Button < StatelessComponent
        property label : String
        property variant : String
        property size : String
        property disabled : Bool
        
        def initialize(@label : String, @variant = "primary", @size = "medium", @disabled = false, **attrs)
          super(**attrs)
          # Initialize CSS classes based on component properties
          @css_classes = build_css_classes
        end
        
        # Implement cache_key_parts for caching
        def cache_key_parts : Array(String)
          [@label, @variant, @size, @disabled.to_s]
        end
        
        def render_content : String
          button_attrs = {
            "class" => css_classes.join(" "),
            "type" => "button"
          }
          
          if disabled?
            button_attrs["disabled"] = "disabled"
          end
          
          build_tag("button", @label, button_attrs)
        end
        
        private def build_tag(name : String, content : String, attrs : Hash(String, String)) : String
          attr_string = serialize_tag_attributes(attrs)
          "<#{name}#{attr_string}>#{escape_html(content)}</#{name}>"
        end
        
        private def serialize_tag_attributes(attrs : Hash(String, String)) : String
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
        
        def cache_key_parts : Array(String)
          [@label, @variant, @size, @disabled.to_s, css_classes.join("-")]
        end
        
        # Check if button is disabled
        def disabled? : Bool
          @disabled
        end
        
        # Get button type for styling purposes
        def button_type : String
          @variant
        end
        
        # Get button size for styling purposes
        def button_size : String
          @size
        end
        
        # Static method to create common button variants
        def self.primary(label : String, **attrs)
          new(label, "primary", **attrs)
        end
        
        def self.secondary(label : String, **attrs)
          new(label, "secondary", **attrs)
        end
        
        def self.danger(label : String, **attrs)
          new(label, "danger", **attrs)
        end
        
        def self.success(label : String, **attrs)
          new(label, "success", **attrs)
        end
        
        def self.warning(label : String, **attrs)
          new(label, "warning", **attrs)
        end
        
        def self.link(label : String, **attrs)
          new(label, "link", **attrs)
        end
        
        # Size variants
        def self.small(label : String, variant = "primary", **attrs)
          new(label, variant, "small", **attrs)
        end
        
        def self.large(label : String, variant = "primary", **attrs)
          new(label, variant, "large", **attrs)
        end
        
        private def build_css_classes : Array(String)
          classes = ["btn"]
          
          # Add variant class
          classes << "btn-#{@variant}"
          
          # Add size class if not medium (default)
          classes << "btn-#{@size}" unless @size == "medium"
          
          # Add disabled class if disabled
          classes << "btn-disabled" if @disabled
          
          classes
        end
        
        # Override infer_element_type since we know this is a button
        private def infer_element_type : String
          "button"
        end
      end
    end
  end
end 