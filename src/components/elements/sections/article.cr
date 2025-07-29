require "../base/container_element"

module Components
  module Elements
    # Represents the <article> element - self-contained composition
    class Article < ContainerElement
      def initialize(**attrs)
        super("article", **attrs)
      end
    end
  end
end