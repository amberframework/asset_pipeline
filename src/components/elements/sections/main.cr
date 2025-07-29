require "../base/container_element"

module Components
  module Elements
    # Represents the <main> element - dominant content of the document
    class Main < ContainerElement
      def initialize(**attrs)
        super("main", **attrs)
      end
    end
  end
end