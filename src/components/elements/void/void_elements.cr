require "../base/void_element"
require "../base/url_attribute_validation"

module Components
  module Elements
    # Represents the <br> element - line break
    class Br < VoidElement
      def initialize(**attrs)
        super("br", **attrs)
      end
    end
    
    # Represents the <hr> element - thematic break
    class Hr < VoidElement
      def initialize(**attrs)
        super("hr", **attrs)
      end
    end
    
    # Represents the <area> element - clickable area in image map
    class Area < VoidElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `href` is URL-bearing,
      # same sink as `<a href>`.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("area", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "href"
      end

      # Validate area-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "shape"
          valid_shapes = ["default", "rect", "circle", "poly"]
          if value && !valid_shapes.includes?(value)
            raise ArgumentError.new("Invalid shape value: #{value}")
          end
        when "coords"
          # Should be comma-separated numbers
        when "target"
          valid_targets = ["_blank", "_self", "_parent", "_top"]
          # Custom frame names also allowed
        end
      end
    end
    
    # Represents the <base> element - document base URL
    class Base < VoidElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `href` sets the document's
      # base URL that every relative URL on the page resolves against — a
      # `javascript:` base is nonsensical but still validated uniformly.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("base", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "href"
      end

      # Validate base-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "target"
          valid_targets = ["_blank", "_self", "_parent", "_top"]
          # Custom frame names also allowed
        end
      end
    end
    
    # Represents the <wbr> element - line break opportunity
    class Wbr < VoidElement
      def initialize(**attrs)
        super("wbr", **attrs)
      end
    end
  end
end