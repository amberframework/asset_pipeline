require "../base/container_element"

module Components
  module Elements
    # Represents the <div> element - generic container for flow content
    class Div < ContainerElement
      def initialize(**attrs)
        super("div", **attrs)
      end
    end
  end
end