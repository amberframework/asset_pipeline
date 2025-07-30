require "./class_builder"
require "./class_registry"

module Components
  module CSS
    # Mixin for components to add CSS functionality
    module Styleable
      # Build CSS classes using the DSL
      def css(&block : ClassBuilder -> Nil) : String
        builder = ClassBuilder.new
        yield builder
        
        # Track classes for this component
        if responds_to?(:component_id)
          ClassRegistry.instance.register_component_classes(
            component_id,
            builder.build
          )
        end
        
        builder.build
      end
      
      # Quick helper for conditional classes
      def class_names(**options) : String
        classes = [] of String
        
        options.each do |key, value|
          case value
          when String
            # Direct class names
            classes << value
          when Bool
            # Conditional class names (key is the class)
            classes << key.to_s if value
          when Array(String)
            # Array of classes
            classes.concat(value)
          end
        end
        
        result = classes.join(" ")
        
        # Track classes
        if responds_to?(:component_id)
          ClassRegistry.instance.register_component_classes(component_id, result)
        else
          ClassRegistry.instance.register_class(result)
        end
        
        result
      end
      
      # Helper to merge multiple class strings
      def merge_classes(*class_strings : String?) : String
        result = class_strings.compact.join(" ").split(/\s+/).uniq.join(" ")
        ClassRegistry.instance.register_class(result)
        result
      end
      
      # Variant helper for component design systems
      def variant_classes(
        base : String,
        variant : String? = nil,
        size : String? = nil,
        state : String? = nil
      ) : String
        classes = [base]
        
        # Add variant classes
        classes << "#{base}-#{variant}" if variant
        classes << "#{base}-#{size}" if size
        classes << "#{base}-#{state}" if state
        
        result = classes.join(" ")
        ClassRegistry.instance.register_class(result)
        result
      end
    end
  end
end