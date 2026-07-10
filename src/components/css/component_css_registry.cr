module Components
  module CSS
    # Global registry for component-level CSS.
    # Components register their CSS via the `component_css` macro.
    # The Generator collects all registered CSS for the @layer components block.
    class ComponentCSSRegistry
      @@instance : ComponentCSSRegistry?

      def self.instance : ComponentCSSRegistry
        @@instance ||= new
      end

      # Each entry: {component_class_name => css_string}
      getter entries : Hash(String, String)

      def initialize
        @entries = {} of String => String
      end

      # Register CSS for a component class.
      # If the same class name registers twice, the later registration wins
      # (last-writer-wins). This allows subclass overrides.
      def register(component_name : String, css : String)
        @entries[component_name] = css
      end

      # Return all registered CSS concatenated, separated by newlines.
      # Component CSS is emitted in registration order.
      def all_css : String
        @entries.values.join("\n\n")
      end

      # Clear registry (useful for testing)
      def clear
        @entries.clear
      end
    end
  end
end
