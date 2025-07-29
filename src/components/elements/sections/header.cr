require "../base/container_element"

module Components
  module Elements
    # Represents the <header> element - introductory content or navigational aids
    class Header < ContainerElement
      def initialize(**attrs)
        super("header", **attrs)
      end
    end
  end
end