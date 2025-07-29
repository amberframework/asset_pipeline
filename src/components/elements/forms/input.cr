require "../base/void_element"

module Components
  module Elements
    # Represents the <input> element - form input
    class Input < VoidElement
      def initialize(**attrs)
        super("input", **attrs)
      end
      
      # Convenience constructors for common input types
      def self.text(name : String)
        new(type: "text", name: name)
      end
      
      def self.email(name : String)
        new(type: "email", name: name)
      end
      
      def self.password(name : String)
        new(type: "password", name: name)
      end
      
      def self.number(name : String)
        new(type: "number", name: name)
      end
      
      def self.checkbox(name : String, value : String? = nil)
        if value
          new(type: "checkbox", name: name, value: value)
        else
          new(type: "checkbox", name: name)
        end
      end
      
      def self.radio(name : String, value : String)
        new(type: "radio", name: name, value: value)
      end
      
      def self.submit(value : String = "Submit")
        new(type: "submit", value: value)
      end
      
      def self.button(value : String)
        new(type: "button", value: value)
      end
      
      def self.hidden(name : String, value : String)
        new(type: "hidden", name: name, value: value)
      end
      
      def self.file(name : String)
        new(type: "file", name: name)
      end
      
      def self.date(name : String)
        new(type: "date", name: name)
      end
      
      def self.time(name : String)
        new(type: "time", name: name)
      end
      
      def self.datetime_local(name : String)
        new(type: "datetime-local", name: name)
      end
      
      def self.range(name : String, min : String? = nil, max : String? = nil)
        case {min, max}
        when {nil, nil}
          new(type: "range", name: name)
        when {String, nil}
          new(type: "range", name: name, min: min.not_nil!)
        when {nil, String}
          new(type: "range", name: name, max: max.not_nil!)
        else
          new(type: "range", name: name, min: min.not_nil!, max: max.not_nil!)
        end
      end
      
      def self.color(name : String)
        new(type: "color", name: name)
      end
      
      def self.search(name : String)
        new(type: "search", name: name)
      end
      
      def self.tel(name : String)
        new(type: "tel", name: name)
      end
      
      def self.url(name : String)
        new(type: "url", name: name)
      end
      
      # Validate input-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          valid_types = ["text", "password", "email", "number", "tel", "url", "search",
                        "date", "time", "datetime-local", "month", "week", "color",
                        "checkbox", "radio", "file", "submit", "reset", "button",
                        "hidden", "image", "range"]
          unless valid_types.includes?(value.to_s)
            raise ArgumentError.new("Invalid input type: #{value}")
          end
        when "autocomplete"
          # Complex validation - many valid values
        when "min", "max", "step"
          # Validate based on input type
          if @attributes["type"]? == "number" || @attributes["type"]? == "range"
            # Should be numeric
          elsif @attributes["type"]? == "date" || @attributes["type"]? == "time"
            # Should be date/time format
          end
        when "pattern"
          # Should be valid regex
        when "required", "disabled", "readonly", "multiple", "checked"
          # Boolean attributes
        end
      end
    end
  end
end