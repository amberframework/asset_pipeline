require "../base/container_element"

module Components
  module Elements
    # Represents the <em> element - emphasis
    class Em < ContainerElement
      def initialize(**attrs)
        super("em", **attrs)
      end
    end
    
    # Represents the <strong> element - strong importance
    class Strong < ContainerElement
      def initialize(**attrs)
        super("strong", **attrs)
      end
    end
    
    # Represents the <small> element - side comments
    class Small < ContainerElement
      def initialize(**attrs)
        super("small", **attrs)
      end
    end
    
    # Represents the <cite> element - citation
    class Cite < ContainerElement
      def initialize(**attrs)
        super("cite", **attrs)
      end
    end
    
    # Represents the <code> element - computer code
    class Code < ContainerElement
      def initialize(**attrs)
        super("code", **attrs)
      end
    end
    
    # Represents the <kbd> element - keyboard input
    class Kbd < ContainerElement
      def initialize(**attrs)
        super("kbd", **attrs)
      end
    end
    
    # Represents the <var> element - variable
    class Var < ContainerElement
      def initialize(**attrs)
        super("var", **attrs)
      end
    end
    
    # Represents the <samp> element - sample output
    class Samp < ContainerElement
      def initialize(**attrs)
        super("samp", **attrs)
      end
    end
    
    # Represents the <sub> element - subscript
    class Sub < ContainerElement
      def initialize(**attrs)
        super("sub", **attrs)
      end
    end
    
    # Represents the <sup> element - superscript
    class Sup < ContainerElement
      def initialize(**attrs)
        super("sup", **attrs)
      end
    end
    
    # Represents the <abbr> element - abbreviation
    class Abbr < ContainerElement
      def initialize(**attrs)
        super("abbr", **attrs)
      end
    end
    
    # Represents the <time> element - time
    class Time < ContainerElement
      def initialize(**attrs)
        super("time", **attrs)
      end
      
      # Validate time-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "datetime"
          # Should be a valid date/time format
          # Basic validation - could be enhanced
        end
      end
    end
    
    # Represents the <data> element - machine-readable data
    class Data < ContainerElement
      def initialize(**attrs)
        super("data", **attrs)
      end
      
      # Validate data-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "value"
          # Required attribute for data element
          if value.nil? || value.empty?
            raise ArgumentError.new("data element requires a value attribute")
          end
        end
      end
    end
    
    # Represents the <b> element - bring attention
    class B < ContainerElement
      def initialize(**attrs)
        super("b", **attrs)
      end
    end
    
    # Represents the <i> element - idiomatic text
    class I < ContainerElement
      def initialize(**attrs)
        super("i", **attrs)
      end
    end
    
    # Represents the <u> element - unarticulated annotation
    class U < ContainerElement
      def initialize(**attrs)
        super("u", **attrs)
      end
    end
    
    # Represents the <s> element - strikethrough
    class S < ContainerElement
      def initialize(**attrs)
        super("s", **attrs)
      end
    end
    
    # Edit elements
    
    # Represents the <ins> element - inserted text
    class Ins < ContainerElement
      def initialize(**attrs)
        super("ins", **attrs)
      end
      
      # Validate ins-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "cite"
          # URL to citation
        when "datetime"
          # Date/time of insertion
        end
      end
    end
    
    # Represents the <del> element - deleted text
    class Del < ContainerElement
      def initialize(**attrs)
        super("del", **attrs)
      end
      
      # Validate del-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "cite"
          # URL to citation
        when "datetime"
          # Date/time of deletion
        end
      end
    end
    
    # Represents the <mark> element - marked/highlighted text
    class Mark < ContainerElement
      def initialize(**attrs)
        super("mark", **attrs)
      end
    end
  end
end