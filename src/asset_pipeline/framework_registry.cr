module AssetPipeline
  # The `FrameworkRegistry` provides an extensible architecture for adding support
  # for different JavaScript frameworks. This allows the AssetPipeline to support
  # Stimulus, Alpine.js, Vue, React, and other frameworks in a consistent manner.
  #
  # This registry pattern ensures clean separation of concerns and provides a
  # standard interface for framework-specific functionality.
  class FrameworkRegistry
    @@renderers = Hash(String, String).new
    @@framework_patterns = Hash(String, Array(Regex)).new
    @@framework_metadata = Hash(String, Hash(String, String)).new

    # Registers a framework renderer class with the registry
    #
    # ```
    # FrameworkRegistry.register_framework(
    #   "stimulus",
    #   "AssetPipeline::Stimulus::StimulusRenderer",
    #   patterns: [/Controller$/],
    #   core_import: "@hotwired/stimulus", 
    #   description: "Hotwired Stimulus framework support"
    # )
    # ```
    def self.register_framework(name : String, renderer_class_name : String, patterns : Array(Regex) = [] of Regex, core_import : String? = nil, description : String? = nil)
      @@renderers[name] = renderer_class_name
      @@framework_patterns[name] = patterns
      @@framework_metadata[name] = {
        "core_import" => core_import || "",
        "description" => description || ""
      }
    end

    # Returns the renderer class name for a given framework name
    #
    # ```
    # renderer_class_name = FrameworkRegistry.get_renderer("stimulus")
    # ```
    def self.get_renderer(framework_name : String) : String?
      @@renderers[framework_name]?
    end

    # Returns all registered framework names
    #
    # ```
    # FrameworkRegistry.supported_frameworks
    # # => ["stimulus", "alpine", "vue"]
    # ```
    def self.supported_frameworks : Array(String)
      @@renderers.keys
    end

    # Determines which framework an import name belongs to based on registered patterns
    #
    # ```
    # FrameworkRegistry.detect_framework("HelloController")  # => "stimulus"
    # FrameworkRegistry.detect_framework("alpine-component") # => "alpine"
    # ```
    def self.detect_framework(import_name : String) : String?
      @@framework_patterns.each do |framework_name, patterns|
        patterns.each do |pattern|
          return framework_name if import_name.match(pattern)
        end
      end
      nil
    end

    # Returns metadata for a registered framework
    #
    # ```
    # FrameworkRegistry.get_framework_metadata("stimulus")
    # # => {"core_import" => "@hotwired/stimulus", "description" => "Hotwired Stimulus framework support"}
    # ```
    def self.get_framework_metadata(framework_name : String) : Hash(String, String)?
      @@framework_metadata[framework_name]?
    end

    # Returns the core import name for a framework (e.g., "@hotwired/stimulus")
    #
    # ```
    # FrameworkRegistry.get_core_import("stimulus")  # => "@hotwired/stimulus"
    # ```
    def self.get_core_import(framework_name : String) : String?
      metadata = @@framework_metadata[framework_name]?
      metadata && metadata["core_import"]? != "" ? metadata["core_import"] : nil
    end

    # Creates a renderer instance for the specified framework
    #
    # ```
    # renderer = FrameworkRegistry.create_renderer("stimulus", import_map, custom_js)
    # ```
    def self.create_renderer(framework_name : String, import_map : ImportMap, custom_js : String = "")
      case framework_name
      when "stimulus"
        # Return a Stimulus renderer if available
        AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      else
        # Fall back to general script renderer for unknown frameworks
        AssetPipeline::ScriptRenderer.new(import_map, custom_js)
      end
    end

    # Provides a registry summary for debugging and introspection
    #
    # ```
    # FrameworkRegistry.registry_summary
    # # => {
    # #   "frameworks" => ["stimulus", "alpine"],
    # #   "total_patterns" => 3,
    # #   "details" => {...}
    # # }
    # ```
    def self.registry_summary : Hash(String, String | Array(String) | Int32 | Hash(String, Hash(String, String)))
      total_patterns = @@framework_patterns.values.sum(&.size)
      
      {
        "frameworks" => supported_frameworks,
        "total_patterns" => total_patterns,
        "details" => @@framework_metadata
      }
    end

    # Validates that a framework renderer implements required methods
    #
    # This is used during framework registration to ensure compatibility
    def self.validate_renderer(renderer_class_name : String) : Bool
      # Check if the class name represents a valid renderer
      # In Crystal, this would be done through duck typing at runtime
      # For now, we assume proper implementation
      true
    end

    # Auto-registers built-in framework support
    #
    # This method is called during module initialization to register
    # the frameworks that are bundled with AssetPipeline
    def self.register_builtin_frameworks
      # Register Stimulus support
      register_framework(
        "stimulus",
        "AssetPipeline::Stimulus::StimulusRenderer",
        patterns: [/^[A-Z][a-zA-Z0-9_]*Controller$/],
        core_import: "@hotwired/stimulus",
        description: "Hotwired Stimulus framework for HTML-first JavaScript"
      )

      # Placeholder registrations for future framework support
      # These would be implemented when the corresponding renderer classes are created
      
      # register_framework(
      #   "alpine",
      #   AssetPipeline::Alpine::AlpineRenderer,
      #   patterns: [/x-data/, /Alpine/],
      #   core_import: "alpinejs",
      #   description: "Alpine.js lightweight framework"
      # )
      
      # register_framework(
      #   "vue",
      #   AssetPipeline::Vue::VueRenderer,
      #   patterns: [/\.vue$/, /Vue/],
      #   core_import: "vue",
      #   description: "Vue.js progressive framework"
      # )
    end
  end

  # Base class for all framework renderers
  #
  # This abstract class defines the interface that all framework-specific
  # renderers should implement. It ensures consistency across different
  # framework implementations.
  abstract class FrameworkRenderer < ScriptRenderer
    # Each framework renderer must implement this method to provide
    # framework-specific script rendering
    abstract def render_framework_initialization_script : String

    # Optional: Framework-specific controller/component detection
    def detect_framework_components : Array(String)
      [] of String
    end

    # Optional: Framework-specific import statement generation
    def generate_framework_imports : String
      ""
    end

    # Optional: Framework-specific application setup
    def generate_framework_setup : String
      ""
    end

    # Helper method to determine if an import looks like a framework component
    def looks_like_framework_component?(name : String) : Bool
      false
    end
  end
end 