require "../base/container_element"
require "../base/void_element"

module Components
  module Elements
    # Represents the <table> element - table
    class Table < ContainerElement
      def initialize(**attrs)
        super("table", **attrs)
      end
    end
    
    # Represents the <thead> element - table header
    class Thead < ContainerElement
      def initialize(**attrs)
        super("thead", **attrs)
      end
    end
    
    # Represents the <tbody> element - table body
    class Tbody < ContainerElement
      def initialize(**attrs)
        super("tbody", **attrs)
      end
    end
    
    # Represents the <tfoot> element - table footer
    class Tfoot < ContainerElement
      def initialize(**attrs)
        super("tfoot", **attrs)
      end
    end
    
    # Represents the <tr> element - table row
    class Tr < ContainerElement
      def initialize(**attrs)
        super("tr", **attrs)
      end
    end
    
    # Represents the <th> element - table header cell
    class Th < ContainerElement
      def initialize(**attrs)
        super("th", **attrs)
      end
      
      # Validate th-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "scope"
          valid_scopes = ["row", "col", "rowgroup", "colgroup"]
          if value && !valid_scopes.includes?(value)
            raise ArgumentError.new("Invalid scope value: #{value}")
          end
        when "colspan", "rowspan"
          unless value.to_s.match(/^\d+$/)
            raise ArgumentError.new("#{name} must be a positive integer")
          end
          if value.to_i < 1
            raise ArgumentError.new("#{name} must be at least 1")
          end
        end
      end
    end
    
    # Represents the <td> element - table data cell
    class Td < ContainerElement
      def initialize(**attrs)
        super("td", **attrs)
      end
      
      # Validate td-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "colspan", "rowspan"
          unless value.to_s.match(/^\d+$/)
            raise ArgumentError.new("#{name} must be a positive integer")
          end
          if value.to_i < 1
            raise ArgumentError.new("#{name} must be at least 1")
          end
        end
      end
    end
    
    # Represents the <caption> element - table caption
    class Caption < ContainerElement
      def initialize(**attrs)
        super("caption", **attrs)
      end
    end
    
    # Represents the <colgroup> element - column group
    class Colgroup < ContainerElement
      def initialize(**attrs)
        super("colgroup", **attrs)
      end
      
      # Validate colgroup-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "span"
          unless value.to_s.match(/^\d+$/)
            raise ArgumentError.new("span must be a positive integer")
          end
          if value.to_i < 1
            raise ArgumentError.new("span must be at least 1")
          end
        end
      end
    end
    
    # Represents the <col> element - column
    class Col < VoidElement
      def initialize(**attrs)
        super("col", **attrs)
      end
      
      # Validate col-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "span"
          unless value.to_s.match(/^\d+$/)
            raise ArgumentError.new("span must be a positive integer")
          end
          if value.to_i < 1
            raise ArgumentError.new("span must be at least 1")
          end
        end
      end
    end
  end
end