require "../base/container_element"

module Components
  module Elements
    # Represents the <title> element - defines the document's title shown in browser tab
    class Title < ContainerElement
      def initialize(**attrs)
        super("title", **attrs)
      end
      
      # Title elements should only contain text
      def <<(child : HTMLElement | String) : self
        case child
        when String
          super
        else
          raise ArgumentError.new("Title element can only contain text content, not other HTML elements")
        end
      end
    end
  end
end