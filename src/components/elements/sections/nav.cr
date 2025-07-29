require "../base/container_element"

module Components
  module Elements
    # Represents the <nav> element - section with navigation links
    class Nav < ContainerElement
      def initialize(**attrs)
        super("nav", **attrs)
      end
    end
  end
end