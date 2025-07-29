require "../base/container_element"

module Components
  module Elements
    # Base class for heading elements
    abstract class Heading < ContainerElement
      def initialize(tag_name : String, **attrs)
        super(tag_name, **attrs)
      end
    end
    
    # Represents the <h1> element - top level heading
    class H1 < Heading
      def initialize(**attrs)
        super("h1", **attrs)
      end
    end
    
    # Represents the <h2> element - second level heading
    class H2 < Heading
      def initialize(**attrs)
        super("h2", **attrs)
      end
    end
    
    # Represents the <h3> element - third level heading
    class H3 < Heading
      def initialize(**attrs)
        super("h3", **attrs)
      end
    end
    
    # Represents the <h4> element - fourth level heading
    class H4 < Heading
      def initialize(**attrs)
        super("h4", **attrs)
      end
    end
    
    # Represents the <h5> element - fifth level heading
    class H5 < Heading
      def initialize(**attrs)
        super("h5", **attrs)
      end
    end
    
    # Represents the <h6> element - sixth level heading
    class H6 < Heading
      def initialize(**attrs)
        super("h6", **attrs)
      end
    end
  end
end