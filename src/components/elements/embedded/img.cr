require "../base/void_element"

module Components
  module Elements
    # Represents the <img> element - image
    class Img < VoidElement
      def initialize(**attrs)
        super("img", **attrs)
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