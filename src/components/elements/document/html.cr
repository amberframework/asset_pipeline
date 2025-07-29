require "../base/container_element"

module Components
  module Elements
    # Represents the <html> element - the root element of an HTML document
    class Html < ContainerElement
      def initialize(**attrs)
        super("html", **attrs)
      end
      
      # Override render to include DOCTYPE
      def render : String
        "<!DOCTYPE html>#{super}"
      end
      
      # Validate HTML-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "lang"
          # Language tags should follow BCP 47 format (simplified validation)
          unless value.to_s.match(/^[a-zA-Z]{2,3}(-[a-zA-Z]{2,4})?(-[a-zA-Z0-9]{1,8})*$/)
            raise ArgumentError.new("Invalid language tag format: #{value}")
          end
        when "xmlns"
          # Should be the standard XHTML namespace if specified
          if value && value != "http://www.w3.org/1999/xhtml"
            raise ArgumentError.new("Invalid xmlns value. Use 'http://www.w3.org/1999/xhtml' for XHTML")
          end
        end
      end
    end
  end
end