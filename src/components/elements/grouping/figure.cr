require "../base/container_element"

module Components
  module Elements
    # Represents the <figure> element - self-contained content with optional caption
    class Figure < ContainerElement
      def initialize(**attrs)
        super("figure", **attrs)
      end
    end
    
    # Represents the <figcaption> element - caption for a figure
    class Figcaption < ContainerElement
      def initialize(**attrs)
        super("figcaption", **attrs)
      end
    end
  end
end