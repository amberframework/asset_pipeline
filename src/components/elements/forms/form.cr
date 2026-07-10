require "../base/container_element"
require "../base/url_attribute_validation"

module Components
  module Elements
    # Represents the <form> element - interactive form
    class Form < ContainerElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `action` is URL-bearing —
      # a `javascript:` action submits the form to an inline script instead
      # of a server endpoint.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("form", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "action"
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