require "../base/container_element"

module Components
  module Elements
    # Represents the <style> element - contains style information for a document
    class Style < ContainerElement
      def initialize(**attrs)
        super("style", **attrs)
      end
      
      # Convenience constructor with CSS content
      def self.new(css : String)
        instance = new
        instance << css
        instance
      end
      
      # Style elements should typically only contain text (CSS)
      def <<(child : HTMLElement | String) : self
        case child
        when String
          super
        else
          raise ArgumentError.new("Style element should only contain CSS text, not other HTML elements")
        end
      end
      
      # Validate style-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Should be text/css if specified
          if value && value != "text/css"
            # Other types are technically valid but uncommon
          end
        when "media"
          # Media queries are complex to validate, so we accept any string
        end
      end
      
      # Override rendering to not escape CSS content
      protected def render_children : String
        @children.map do |child|
          case child
          when String
            # Don't escape CSS content
            child
          else
            child.to_s
          end
        end.join
      end
    end
  end
end