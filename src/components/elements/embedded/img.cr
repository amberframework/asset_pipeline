require "../base/void_element"
require "../base/url_attribute_validation"

module Components
  module Elements
    # Represents the <img> element - image
    class Img < VoidElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `src` is a URL-bearing sink.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("img", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src"
      end

      # Validate img-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "alt"
          # Alt is technically required for accessibility
        when "loading"
          valid_values = ["lazy", "eager"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid loading value: #{value}")
          end
        when "decoding"
          valid_values = ["sync", "async", "auto"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid decoding value: #{value}")
          end
        when "crossorigin"
          valid_values = ["anonymous", "use-credentials"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid crossorigin value: #{value}")
          end
        end
      end
    end
  end
end