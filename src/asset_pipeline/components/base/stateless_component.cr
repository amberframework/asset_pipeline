require "./component"
require "../cache/cacheable"

module AssetPipeline
  module Components
    # Base class for stateless components that can be cached
    abstract class StatelessComponent < Component
      include Cache::Cacheable
      
      # CSS classes used by this component (for CSS optimization)
      property css_classes : Array(String)
      
      def initialize(**attrs)
        @css_classes = Array(String).new
        super(**attrs)
      end
      
      # Override render to use caching when enabled
      def render : String
        # Register CSS classes with the registry when rendering
        CSSRegistry.instance.register_component(component_name, css_classes)
        
        if cacheable?
          render_with_cache
        else
          render_without_cache
        end
      end
      
      # Render with caching enabled
      def render_with_cache : String
        Cache::ComponentCacheManager.instance.fetch(cache_key, cache_expires_in) do
          render_without_cache
        end
      end
      
      # Render without using cache
      def render_without_cache : String
        render_content
      end
      
      # Cache key parts that should be included in the cache key
      # Subclasses should override this to include relevant data
      def cache_key_parts : Array(String)
        [component_name, css_classes.join("-")]
      end
      
      # How long this component should be cached (default 1 hour)
      def cache_expires_in : Time::Span
        1.hour
      end
      

      

      
      # Generate CSS selector for this component
      def css_selector : String
        return "" if css_classes.empty?
        ".#{css_classes.join(".")}"
      end
      
      # Generate XPath selector for this component
      def xpath_selector : String
        return "" if css_classes.empty?
        
        # Try to infer the element type from class names or use a generic approach
        element = infer_element_type
        conditions = css_classes.map { |cls| "contains(@class, '#{cls}')" }.join(" and ")
        "//#{element}[#{conditions}]"
      end
      
      # Get all CSS classes used by this component
      def all_css_classes : Array(String)
        css_classes.dup
      end
      
      # Add a CSS class to this component
      def add_css_class(class_name : String)
        @css_classes << class_name unless @css_classes.includes?(class_name)
      end
      
      # Remove a CSS class from this component
      def remove_css_class(class_name : String)
        @css_classes.delete(class_name)
      end
      
      # Check if component has a specific CSS class
      def has_css_class?(class_name : String) : Bool
        @css_classes.includes?(class_name)
      end
      
      private def infer_element_type : String
        # Common patterns to infer element type from CSS classes
        return "button" if css_classes.any? { |cls| cls.includes?("btn") || cls.includes?("button") }
        return "input" if css_classes.any? { |cls| cls.includes?("input") || cls.includes?("field") }
        return "form" if css_classes.any? { |cls| cls.includes?("form") }
        return "nav" if css_classes.any? { |cls| cls.includes?("nav") }
        return "header" if css_classes.any? { |cls| cls.includes?("header") }
        return "footer" if css_classes.any? { |cls| cls.includes?("footer") }
        return "main" if css_classes.any? { |cls| cls.includes?("main") }
        return "section" if css_classes.any? { |cls| cls.includes?("section") }
        return "article" if css_classes.any? { |cls| cls.includes?("article") }
        
        # Default to div for most components
        "div"
      end
    end
  end
end 