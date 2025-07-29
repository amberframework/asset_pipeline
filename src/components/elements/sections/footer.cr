require "../base/container_element"

module Components
  module Elements
    # Represents the <footer> element - footer for its nearest sectioning content
    class Footer < ContainerElement
      def initialize(**attrs)
        super("footer", **attrs)
      end
    end
  end
end