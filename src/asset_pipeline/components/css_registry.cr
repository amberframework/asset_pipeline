require "json"

module AssetPipeline
  module Components
    # Global registry for tracking CSS classes used by components
    # This enables CSS tree-shaking and optimization
    class CSSRegistry
      # Singleton instance
      @@instance : CSSRegistry?
      
      # Storage for CSS class usage tracking
      property used_classes : Hash(String, Array(String))
      property component_classes : Hash(String, Set(String))
      property class_usage_count : Hash(String, Int32)
      
      def initialize
        @used_classes = Hash(String, Array(String)).new
        @component_classes = Hash(String, Set(String)).new
        @class_usage_count = Hash(String, Int32).new
      end
      
      def self.instance
        @@instance ||= new
      end
      
      # Register CSS classes used by a component
      def register_component(component_name : String, css_classes : Array(String))
        # Track which component uses which classes
        @used_classes[component_name] = css_classes.dup
        
        # Track all classes used by this component
        @component_classes[component_name] ||= Set(String).new
        css_classes.each { |css_class| @component_classes[component_name] << css_class }
        
        # Count usage of each class
        css_classes.each do |css_class|
          @class_usage_count[css_class] = (@class_usage_count[css_class]? || 0) + 1
        end
      end
      
      # Register CSS classes from a stateful component (Hash-based)
      def register_stateful_component(component_name : String, css_classes : Hash(String, Array(String)))
        all_classes = css_classes.values.flatten.uniq
        register_component(component_name, all_classes)
        
        # Also store the structured information
        css_classes.each do |element_key, classes|
          element_component_name = "#{component_name}:#{element_key}"
          register_component(element_component_name, classes)
        end
      end
      
      # Get all CSS classes used across all components
      def all_used_classes : Array(String)
        @class_usage_count.keys
      end
      
      # Get CSS classes used by a specific component
      def classes_for_component(component_name : String) : Array(String)
        @used_classes[component_name]? || Array(String).new
      end
      
      # Get components that use a specific CSS class
      def components_using_class(css_class : String) : Array(String)
        @used_classes.select { |_, classes| classes.includes?(css_class) }.keys
      end
      
      # Get usage count for a CSS class
      def usage_count(css_class : String) : Int32
        @class_usage_count[css_class]? || 0
      end
      
      # Get component classes mapping
      def component_classes : Hash(String, Set(String))
        @component_classes
      end
      
      # Get most commonly used CSS classes
      def most_used_classes(limit = 10) : Array(Tuple(String, Int32))
        @class_usage_count.to_a.sort_by { |_, count| -count }.first(limit)
      end
      
      # Get least commonly used CSS classes (candidates for removal)
      def least_used_classes(limit = 10) : Array(Tuple(String, Int32))
        @class_usage_count.to_a.sort_by { |_, count| count }.first(limit)
      end
      
      # Get unused CSS classes (if we have a reference stylesheet)
      def unused_classes(available_classes : Array(String)) : Array(String)
        used = all_used_classes.to_set
        available_classes.reject { |css_class| used.includes?(css_class) }
      end
      
      # Generate CSS optimization report
      def optimization_report : Hash(String, JSON::Any)
        {
          "total_components" => JSON::Any.new(@used_classes.size.to_i64),
          "total_classes_used" => JSON::Any.new(@class_usage_count.size.to_i64),
          "most_used_classes" => JSON::Any.new(most_used_classes(5).map { |name, count|
            JSON::Any.new({"class" => JSON::Any.new(name), "count" => JSON::Any.new(count.to_i64)})
          }),
          "least_used_classes" => JSON::Any.new(least_used_classes(5).map { |name, count|
            JSON::Any.new({"class" => JSON::Any.new(name), "count" => JSON::Any.new(count.to_i64)})
          }),
          "components_by_class_count" => JSON::Any.new(@used_classes.to_a.sort_by { |_, classes| -classes.size }.first(10).map { |name, classes|
            JSON::Any.new({"component" => JSON::Any.new(name), "class_count" => JSON::Any.new(classes.size.to_i64)})
          })
        }
      end
      
      # Clear all registered data (useful for testing)
      def clear!
        @used_classes.clear
        @component_classes.clear
        @class_usage_count.clear
      end
      
      # Export registry data for caching or analysis
      def export_data : Hash(String, JSON::Any)
        {
          "used_classes" => JSON::Any.new(@used_classes.transform_values { |classes|
            JSON::Any.new(classes.map { |c| JSON::Any.new(c) })
          }),
          "class_usage_count" => JSON::Any.new(@class_usage_count.transform_values { |count|
            JSON::Any.new(count.to_i64)
          })
        }
      end
      
      # Import registry data from exported data
      def import_data(data : Hash(String, JSON::Any))
        if used_classes_data = data["used_classes"]?
          used_classes_data.as_h.each do |component, classes|
            @used_classes[component] = classes.as_a.map(&.as_s)
          end
        end
        
        if usage_count_data = data["class_usage_count"]?
          usage_count_data.as_h.each do |css_class, count|
            @class_usage_count[css_class] = count.as_i.to_i32
          end
        end
        
        # Rebuild component_classes from used_classes
        @component_classes.clear
        @used_classes.each do |component, classes|
          @component_classes[component] = classes.to_set
        end
      end
      
      # Generate a minimal CSS selector list for tree-shaking
      def generate_selector_list : Array(String)
        all_used_classes.map { |css_class| ".#{css_class}" }
      end
      
      # Generate CSS purge whitelist (for PurgeCSS or similar tools)
      def generate_purge_whitelist : Array(String)
        all_used_classes
      end
      
      # Get statistics about component CSS usage
      def component_statistics : Hash(String, JSON::Any)
        component_stats = @used_classes.map do |component, classes|
          {
            "name" => component,
            "class_count" => classes.size,
            "classes" => classes,
            "unique_classes" => classes.to_set.size
          }
        end.sort_by { |stats| -stats["class_count"].as(Int32) }
        
        {
          "components" => JSON::Any.new(component_stats.map { |stats|
            JSON::Any.new({
              "name" => JSON::Any.new(stats["name"].as(String)),
              "class_count" => JSON::Any.new(stats["class_count"].as(Int32).to_i64),
              "classes" => JSON::Any.new(stats["classes"].as(Array(String)).map { |c| JSON::Any.new(c) })
            })
          })
        }
      end
    end
    
    # Convenience methods for registering components
    module CSSRegistryHelper
      # Auto-register a component's CSS classes
      def self.register(component : StatelessComponent)
        CSSRegistry.instance.register_component(
          component.component_name,
          component.all_css_classes
        )
      end
      
      def self.register(component : StatefulComponent)
        CSSRegistry.instance.register_stateful_component(
          component.component_name,
          component.css_classes
        )
      end
    end
  end
end 