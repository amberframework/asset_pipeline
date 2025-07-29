require "../base/container_element"

module Components
  module Elements
    # Represents the <span> element - generic inline container
    class Span < ContainerElement
      def initialize(**attrs)
        super("span", **attrs)
      end
    end
  end
end