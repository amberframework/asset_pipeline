require "../base/container_element"

module Components
  module Elements
    # Represents the <section> element - generic section of a document
    class Section < ContainerElement
      def initialize(**attrs)
        super("section", **attrs)
      end
    end
  end
end