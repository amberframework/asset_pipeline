require "../base/container_element"

module Components
  module Elements
    # Represents the <aside> element - content tangentially related to main content
    class Aside < ContainerElement
      def initialize(**attrs)
        super("aside", **attrs)
      end
    end
  end
end