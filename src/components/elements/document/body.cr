require "../base/container_element"

module Components
  module Elements
    # Represents the <body> element - contains the content of an HTML document
    class Body < ContainerElement
      def initialize(**attrs)
        super("body", **attrs)
      end
      
      # Validate body-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "onload", "onunload", "onbeforeunload"
          # These are valid event handlers for body
        end
      end
    end
  end
end