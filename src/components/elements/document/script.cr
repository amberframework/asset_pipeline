require "../base/container_element"

module Components
  module Elements
    # Represents the <script> element - embeds executable code or data
    class Script < ContainerElement
      def initialize(**attrs)
        super("script", **attrs)
      end
      
      # Convenience constructor with JavaScript content
      def self.new(js : String)
        instance = new
        instance << js
        instance
      end
      
      # Script elements should typically only contain text (JavaScript)
      def <<(child : HTMLElement | String) : self
        case child
        when String
          super
        else
          raise ArgumentError.new("Script element should only contain JavaScript text, not other HTML elements")
        end
      end
      
      # Validate script-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Common script types
          valid_types = ["text/javascript", "module", "application/json", "application/ld+json"]
          # Don't strictly enforce as new types may be added
        when "async", "defer"
          # These are boolean attributes
          unless value.nil? || value == "true" || value == "false" || value == ""
            raise ArgumentError.new("#{name} is a boolean attribute")
          end
        when "crossorigin"
          valid_values = ["anonymous", "use-credentials"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid crossorigin value: #{value}")
          end
        end
      end
      
      # Override rendering to not escape JavaScript content
      protected def render_children : String
        @children.map do |child|
          case child
          when String
            # Don't escape JavaScript content
            child
          else
            child.to_s
          end
        end.join
      end
    end
  end
end