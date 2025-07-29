require "../base/container_element"

module Components
  module Elements
    # Represents the <textarea> element - multiline text input
    class Textarea < ContainerElement
      def initialize(**attrs)
        super("textarea", **attrs)
      end
      
      # Convenience constructor with initial value
      def self.new(name : String, value : String? = nil)
        instance = new(name: name)
        instance << value if value
        instance
      end
      
      # Validate textarea-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "rows", "cols"
          unless value.to_s.match(/^\d+$/)
            raise ArgumentError.new("#{name} must be a positive integer")
          end
          if value.to_i < 1
            raise ArgumentError.new("#{name} must be at least 1")
          end
        when "wrap"
          valid_values = ["soft", "hard"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid wrap value: #{value}")
          end
        when "required", "disabled", "readonly"
          # Boolean attributes
        end
      end
    end
    
    # Represents the <select> element - dropdown selection
    class Select < ContainerElement
      def initialize(**attrs)
        super("select", **attrs)
      end
      
      # Validate select-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "size"
          unless value.to_s.match(/^\d+$/)
            raise ArgumentError.new("size must be a positive integer")
          end
        when "multiple", "required", "disabled"
          # Boolean attributes
        end
      end
    end
    
    # Represents the <option> element - option in select
    class Option < ContainerElement
      def initialize(**attrs)
        super("option", **attrs)
      end
      
      # Convenience constructor
      def self.new(text : String, value : String? = nil)
        instance = new(value: value || text)
        instance << text
        instance
      end
      
      # Validate option-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "selected", "disabled"
          # Boolean attributes
        end
      end
    end
    
    # Represents the <optgroup> element - group of options
    class Optgroup < ContainerElement
      def initialize(**attrs)
        super("optgroup", **attrs)
      end
      
      # Validate optgroup-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "label"
          if value.nil? || value.empty?
            raise ArgumentError.new("optgroup requires a label attribute")
          end
        when "disabled"
          # Boolean attribute
        end
      end
    end
    
    # Represents the <button> element - clickable button
    class Button < ContainerElement
      def initialize(**attrs)
        super("button", **attrs)
      end
      
      # Convenience constructor
      def self.new(text : String, type : String = "button")
        instance = new(type: type)
        instance << text
        instance
      end
      
      # Validate button-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          valid_types = ["submit", "reset", "button"]
          unless valid_types.includes?(value.to_s)
            raise ArgumentError.new("Invalid button type: #{value}")
          end
        when "disabled"
          # Boolean attribute
        end
      end
    end
    
    # Represents the <label> element - caption for form control
    class Label < ContainerElement
      def initialize(**attrs)
        super("label", **attrs)
      end
      
      # Convenience constructor
      def self.new(text : String, for : String? = nil)
        instance = for ? new(for: for) : new
        instance << text
        instance
      end
    end
    
    # Represents the <fieldset> element - group of form controls
    class Fieldset < ContainerElement
      def initialize(**attrs)
        super("fieldset", **attrs)
      end
      
      # Validate fieldset-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "disabled"
          # Boolean attribute
        end
      end
    end
    
    # Represents the <legend> element - caption for fieldset
    class Legend < ContainerElement
      def initialize(**attrs)
        super("legend", **attrs)
      end
    end
    
    # Represents the <datalist> element - predefined options for input
    class Datalist < ContainerElement
      def initialize(**attrs)
        super("datalist", **attrs)
      end
    end
    
    # Represents the <output> element - result of calculation
    class Output < ContainerElement
      def initialize(**attrs)
        super("output", **attrs)
      end
      
      # Validate output-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "for"
          # Space-separated list of IDs
        end
      end
    end
    
    # Represents the <progress> element - task progress
    class Progress < ContainerElement
      def initialize(**attrs)
        super("progress", **attrs)
      end
      
      # Validate progress-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "value", "max"
          # Should be numeric
          unless value.to_s.match(/^\d*\.?\d+$/)
            raise ArgumentError.new("#{name} must be a number")
          end
          if value.to_f < 0
            raise ArgumentError.new("#{name} must be non-negative")
          end
        end
      end
    end
    
    # Represents the <meter> element - gauge
    class Meter < ContainerElement
      def initialize(**attrs)
        super("meter", **attrs)
      end
      
      # Validate meter-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "value", "min", "max", "low", "high", "optimum"
          # Should be numeric
          unless value.to_s.match(/^-?\d*\.?\d+$/)
            raise ArgumentError.new("#{name} must be a number")
          end
        end
      end
    end
  end
end