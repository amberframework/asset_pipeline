require "../base/container_element"

module Components
  module Elements
    # Represents the <p> element - paragraph
    class P < ContainerElement
      def initialize(**attrs)
        super("p", **attrs)
      end
    end
  end
end