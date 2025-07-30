module Components
  module CSS
    # Registry for tracking used CSS classes across all components
    class ClassRegistry
      # Singleton instance
      @@instance : ClassRegistry?
      
      def self.instance : ClassRegistry
        @@instance ||= new
      end
      
      # Used class names
      getter used_classes : Set(String)
      
      # Component class usage tracking
      getter component_classes : Hash(String, Set(String))
      
      # Dynamic classes (generated at runtime)
      getter dynamic_classes : Set(String)
      
      # Class name patterns to always include
      getter safelist : Array(Regex | String)
      
      def initialize
        @used_classes = Set(String).new
        @component_classes = {} of String => Set(String)
        @dynamic_classes = Set(String).new
        @safelist = [] of Regex | String
      end
      
      # Register classes used by a component
      def register_component_classes(component_id : String, classes : String)
        component_set = @component_classes[component_id] ||= Set(String).new
        
        # Parse and register each class
        classes.split(/\s+/).each do |class_name|
          next if class_name.empty?
          
          @used_classes << class_name
          component_set << class_name
          
          # Track dynamic classes (with arbitrary values)
          if class_name.includes?("[") && class_name.includes?("]")
            @dynamic_classes << class_name
          end
        end
      end
      
      # Register a single class
      def register_class(class_name : String)
        @used_classes << class_name unless class_name.empty?
      end
      
      # Add patterns to safelist
      def add_to_safelist(pattern : Regex | String)
        @safelist << pattern
      end
      
      # Check if a class should be included
      def should_include?(class_name : String) : Bool
        # Check if explicitly used
        return true if @used_classes.includes?(class_name)
        
        # Check safelist patterns
        @safelist.any? do |pattern|
          case pattern
          when String
            pattern == class_name
          when Regex
            pattern.matches?(class_name)
          end
        end
      end
      
      # Get all classes for a component
      def get_component_classes(component_id : String) : Set(String)
        @component_classes[component_id]? || Set(String).new
      end
      
      # Clear registry
      def clear
        @used_classes.clear
        @component_classes.clear
        @dynamic_classes.clear
      end
      
      # Export usage data
      def export_usage : Hash(String, JSON::Any)
        {
          "total_classes" => JSON::Any.new(@used_classes.size),
          "dynamic_classes" => JSON::Any.new(@dynamic_classes.size),
          "components" => JSON::Any.new(
            @component_classes.transform_values { |v| JSON::Any.new(v.size) }
          ),
          "classes" => JSON::Any.new(@used_classes.to_a.map { |c| JSON::Any.new(c) })
        }
      end
    end
  end
end