require "../base/container_element"

module Components
  module Elements
    # Represents the <form> element - interactive form
    class Form < ContainerElement
      def initialize(**attrs)
        super("form", **attrs)
      end
      
      
      # Validate form-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "method"
          valid_methods = ["GET", "POST", "dialog"]
          unless valid_methods.includes?(value.to_s.upcase)
            raise ArgumentError.new("Invalid form method: #{value}")
          end
        when "enctype"
          valid_types = ["application/x-www-form-urlencoded", "multipart/form-data", "text/plain"]
          if value && !valid_types.includes?(value)
            raise ArgumentError.new("Invalid enctype: #{value}")
          end
        when "autocomplete"
          valid_values = ["on", "off"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid autocomplete value: #{value}")
          end
        when "target"
          valid_targets = ["_blank", "_self", "_parent", "_top"]
          # Custom frame names also allowed
        end
      end
    end
  end
end