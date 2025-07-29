require "../base/container_element"

module Components
  module Elements
    # Represents the <head> element - contains machine-readable information about the document
    class Head < ContainerElement
      def initialize(**attrs)
        super("head", **attrs)
      end
    end
  end
end