require "../base/container_element"

module Components
  module Elements
    # Represents the <ol> element - ordered list
    class Ol < ContainerElement
      def initialize(**attrs)
        super("ol", **attrs)
      end
      
      # Validate ol-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          valid_types = ["1", "a", "A", "i", "I"]
          unless valid_types.includes?(value)
            raise ArgumentError.new("Invalid ol type: #{value}")
          end
        when "start"
          unless value.to_s.match(/^-?\d+$/)
            raise ArgumentError.new("start attribute must be an integer")
          end
        end
      end
    end
    
    # Represents the <ul> element - unordered list
    class Ul < ContainerElement
      def initialize(**attrs)
        super("ul", **attrs)
      end
    end
    
    # Represents the <li> element - list item
    class Li < ContainerElement
      def initialize(**attrs)
        super("li", **attrs)
      end
      
      # Validate li-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "value"
          unless value.to_s.match(/^-?\d+$/)
            raise ArgumentError.new("value attribute must be an integer")
          end
        end
      end
    end
    
    # Represents the <dl> element - description list
    class Dl < ContainerElement
      def initialize(**attrs)
        super("dl", **attrs)
      end
    end
    
    # Represents the <dt> element - description term
    class Dt < ContainerElement
      def initialize(**attrs)
        super("dt", **attrs)
      end
    end
    
    # Represents the <dd> element - description details
    class Dd < ContainerElement
      def initialize(**attrs)
        super("dd", **attrs)
      end
    end
  end
end