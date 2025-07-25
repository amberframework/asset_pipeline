require "./component"

module AssetPipeline
  module Components
    # Base class for stateful components that include JavaScript behavior
    abstract class StatefulComponent < Component
      # CSS classes organized by element/purpose for complex components
      property css_classes : Hash(String, Array(String))
      
      def initialize(**attrs)
        @css_classes = Hash(String, Array(String)).new
        super(**attrs)
      end
      
      # Override render to include component registration data
      def render : String
        # Register CSS classes with the registry when rendering
        CSSRegistry.instance.register_stateful_component(component_name, css_classes)
        # Add component data attributes for JavaScript initialization
        add_component_data_attributes
        render_content
      end
      
      # Abstract method for JavaScript content (must be implemented by subclasses)
      abstract def javascript_content : String
      
      # Optional CSS content (can be overridden by subclasses)
      def css_content : String
        ""
      end
      
      # Get all CSS classes from all elements
      def all_css_classes : Array(String)
        css_classes.values.flatten.uniq
      end
      
      # Generate CSS selectors for each element
      def css_selectors : Hash(String, String)
        css_classes.transform_values { |classes| ".#{classes.join(".")}" }
      end
      
      # Generate XPath selectors for each element
      def xpath_selectors : Hash(String, String)
        css_classes.transform_values do |classes|
          element = element_for_classes(classes)
          conditions = classes.map { |cls| "contains(@class, '#{cls}')" }.join(" and ")
          "//#{element}[#{conditions}]"
        end
      end
      
      # Add CSS classes for a specific element
      def add_css_classes(element_key : String, classes : Array(String))
        @css_classes[element_key] ||= Array(String).new
        classes.each do |cls|
          @css_classes[element_key] << cls unless @css_classes[element_key].includes?(cls)
        end
      end
      
      # Add a single CSS class for a specific element
      def add_css_class(element_key : String, class_name : String)
        @css_classes[element_key] ||= Array(String).new
        @css_classes[element_key] << class_name unless @css_classes[element_key].includes?(class_name)
      end
      
      # Remove CSS classes for a specific element
      def remove_css_class(element_key : String, class_name : String)
        return unless @css_classes.has_key?(element_key)
        @css_classes[element_key].delete(class_name)
      end
      
      # Check if element has a specific CSS class
      def has_css_class?(element_key : String, class_name : String) : Bool
        return false unless @css_classes.has_key?(element_key)
        @css_classes[element_key].includes?(class_name)
      end
      
      # Get CSS classes for a specific element
      def get_css_classes(element_key : String) : Array(String)
        @css_classes[element_key]? || Array(String).new
      end
      
      # Get CSS selector for a specific element
      def css_selector_for(element_key : String) : String
        classes = get_css_classes(element_key)
        return "" if classes.empty?
        ".#{classes.join(".")}"
      end
      
      # Get XPath selector for a specific element
      def xpath_selector_for(element_key : String) : String
        classes = get_css_classes(element_key)
        return "" if classes.empty?
        
        element = element_for_classes(classes)
        conditions = classes.map { |cls| "contains(@class, '#{cls}')" }.join(" and ")
        "//#{element}[#{conditions}]"
      end
      
      # Generate JavaScript class name based on component name
      def javascript_class_name : String
        component_name.gsub(/([a-z])([A-Z])/, "\\1\\2") # Keep PascalCase
      end
      
      # Check if this component has JavaScript behavior
      def has_javascript? : Bool
        !javascript_content.strip.empty?
      end
      
      # Check if this component has CSS content
      def has_css? : Bool
        !css_content.strip.empty?
      end
      
      private def add_component_data_attributes
        # Add data attributes that JavaScript will use to initialize the component
        @attributes["data-component"] = component_name.downcase
        @attributes["data-component-id"] = component_id
        
        # Add any additional data attributes that might be useful for JavaScript
        if has_javascript?
          @attributes["data-js-class"] = javascript_class_name
        end
      end
      
      private def element_for_classes(classes : Array(String)) : String
        # Map common class patterns to element types for more specific xpath
        return "button" if classes.any? { |cls| cls.includes?("btn") || cls.includes?("button") }
        return "input" if classes.any? { |cls| cls.includes?("input") || cls.includes?("field") }
        return "textarea" if classes.any? { |cls| cls.includes?("textarea") }
        return "select" if classes.any? { |cls| cls.includes?("select") || cls.includes?("dropdown") }
        return "form" if classes.any? { |cls| cls.includes?("form") }
        return "nav" if classes.any? { |cls| cls.includes?("nav") }
        return "header" if classes.any? { |cls| cls.includes?("header") }
        return "footer" if classes.any? { |cls| cls.includes?("footer") }
        return "main" if classes.any? { |cls| cls.includes?("main") }
        return "section" if classes.any? { |cls| cls.includes?("section") }
        return "article" if classes.any? { |cls| cls.includes?("article") }
        return "span" if classes.any? { |cls| cls.includes?("count") || cls.includes?("display") || cls.includes?("text") }
        return "ul" if classes.any? { |cls| cls.includes?("list") }
        return "li" if classes.any? { |cls| cls.includes?("item") }
        
        # Default to div for most components
        "div"
      end
    end
  end
end 