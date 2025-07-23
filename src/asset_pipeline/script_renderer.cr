require "./dependency_analyzer"

module AssetPipeline
  # The `ScriptRenderer` handles framework-agnostic JavaScript script generation and rendering.
  # It provides advanced functionality for generating import statements, analyzing dependencies,
  # and wrapping custom JavaScript initialization blocks in proper module script tags.
  #
  # This class serves as the foundation for framework-specific renderers like StimulusRenderer.
  class ScriptRenderer
    @import_map : ImportMap
    @custom_javascript_block : String
    @dependency_analyzer : DependencyAnalyzer?
    @enable_dependency_analysis : Bool

    # Initialize the ScriptRenderer with an import map and optional custom JavaScript block
    #
    # ```
    # renderer = ScriptRenderer.new(import_map, "console.log('initialized');")
    # ```
    #
    # Set `enable_dependency_analysis` to `true` to automatically detect missing dependencies
    # from the custom JavaScript block.
    def initialize(@import_map : ImportMap, @custom_javascript_block : String = "", @enable_dependency_analysis : Bool = true)
      @dependency_analyzer = @enable_dependency_analysis ? DependencyAnalyzer.new(@custom_javascript_block) : nil
    end

    # Renders a complete script tag with imports and initialization code
    #
    # Returns a string containing the complete `<script type="module">` tag with:
    # - Generated import statements for detected dependencies
    # - Custom JavaScript initialization block
    #
    # ```
    # renderer.render_initialization_script
    # # => "<script type=\"module\">\nimport ...\nconsole.log('initialized');\n</script>"
    # ```
    def render_initialization_script : String
      script_content = generate_script_content
      wrap_in_script_tag(script_content)
    end

    # Generates the script content without wrapping it in script tags
    #
    # Useful for testing or when you need the raw JavaScript content
    def generate_script_content : String
      imports = generate_import_statements
      initialization = process_custom_javascript_block

      content_parts = [] of String
      content_parts << imports unless imports.empty?
      content_parts << initialization unless initialization.empty?

      content_parts.join("\n\n")
    end

    # Generates import statements based on the import map
    #
    # Creates ES6 import statements for all imports in the associated import map
    protected def generate_import_statements : String
      import_statements = [] of String

      @import_map.imports.each do |import_entry|
        import_name = import_entry.first_key
        import_path = import_entry.first_value.to_s

        # Generate import statement based on import name pattern
        if looks_like_default_import?(import_name)
          import_statements << "import #{import_name} from \"#{import_name}\";"
        else
          import_statements << "import \"#{import_name}\";"
        end
      end

      import_statements.join("\n")
    end

    # Processes the custom JavaScript block
    #
    # Override this method in subclasses to add framework-specific processing
    protected def process_custom_javascript_block : String
      @custom_javascript_block.strip
    end

    # Wraps content in a script module tag
    protected def wrap_in_script_tag(content : String) : String
      return "" if content.strip.empty?

      <<-HTML
      <script type="module">
      #{content}
      </script>
      HTML
    end

    # Analyzes the custom JavaScript block for dependencies
    #
    # Returns a hash containing detected external libraries, local modules, and import suggestions
    def analyze_dependencies : Hash(Symbol, Array(String))
      unless @dependency_analyzer
        empty_hash = Hash(Symbol, Array(String)).new
        empty_hash[:external] = [] of String
        empty_hash[:local] = [] of String
        empty_hash[:suggestions] = [] of String
        return empty_hash
      end
      
      @dependency_analyzer.not_nil!.analyze_dependencies
    end

    # Gets import suggestions for detected but missing dependencies
    #
    # Returns an array of human-readable suggestions for improving the import map
    def get_import_suggestions : Array(String)
      return [] of String unless @dependency_analyzer
      
      analysis = @dependency_analyzer.not_nil!.analyze_dependencies
      missing_suggestions = [] of String
      
      # Check if detected dependencies are already in import map
      analysis[:external].each do |dep|
        unless import_map_contains_dependency?(dep)
          missing_suggestions.concat(analysis[:suggestions].select(&.includes?(dep)))
        end
      end
      
      analysis[:local].each do |dep|
        unless import_map_contains_dependency?(dep)
          missing_suggestions.concat(analysis[:suggestions].select(&.includes?(dep)))
        end
      end
      
      missing_suggestions
    end

    # Generates enhanced script content that includes warnings about missing dependencies
    #
    # Similar to generate_script_content but includes comments about detected dependencies
    def generate_enhanced_script_content : String
      script_content = generate_script_content
      
      if @dependency_analyzer
        suggestions = get_import_suggestions
        unless suggestions.empty?
          warning_comments = suggestions.map { |s| "// WARNING: #{s}" }.join("\n")
          script_content = "#{warning_comments}\n\n#{script_content}"
        end
      end
      
      script_content
    end

    # Renders initialization script with dependency analysis warnings
    #
    # Includes comments about potentially missing dependencies for development assistance
    def render_initialization_script_with_analysis : String
      script_content = generate_enhanced_script_content
      wrap_in_script_tag(script_content)
    end

    # Analyzes code complexity and returns suggestions
    #
    # Provides insights about whether the JavaScript block should be refactored
    def analyze_code_complexity
      unless @dependency_analyzer
        return {
          lines: 0, 
          functions: 0, 
          classes: 0, 
          event_listeners: 0, 
          suggestions: [] of String
        }
      end
      
      @dependency_analyzer.not_nil!.analyze_code_complexity
    end

    # Checks if the custom JavaScript uses modern module syntax
    def uses_module_syntax? : Bool
      return false unless @dependency_analyzer
      
      @dependency_analyzer.not_nil!.uses_module_syntax?
    end

    # Extracts existing import statements from the custom JavaScript block
    def extract_existing_imports : Array(String)
      return [] of String unless @dependency_analyzer
      
      @dependency_analyzer.not_nil!.extract_existing_imports
    end

    # Generates a development report with analysis results
    #
    # Useful for debugging and development to understand what the analyzer detected
    def generate_development_report : String
      return "Dependency analysis disabled" unless @dependency_analyzer
      
      analysis = analyze_dependencies
      complexity = analyze_code_complexity
      existing_imports = extract_existing_imports
      
      report = [] of String
      report << "=== ScriptRenderer Development Report ==="
      report << ""
      report << "External dependencies detected: #{analysis[:external].join(", ")}"
      report << "Local modules detected: #{analysis[:local].join(", ")}"
      report << "Existing imports found: #{existing_imports.join(", ")}"
      report << ""
      report << "Code complexity:"
      report << "  - Lines: #{complexity[:lines]}"
      report << "  - Functions: #{complexity[:functions]}"
      report << "  - Classes: #{complexity[:classes]}"
      report << "  - Event listeners: #{complexity[:event_listeners]}"
      report << "  - Uses module syntax: #{uses_module_syntax?}"
      report << ""
      
      suggestions = get_import_suggestions
      unless suggestions.empty?
        report << "Import suggestions:"
        suggestions.each { |s| report << "  - #{s}" }
        report << ""
      end
      
      complexity_suggestions = complexity[:suggestions].as(Array(String))
      unless complexity_suggestions.empty?
        report << "Code organization suggestions:"
        complexity_suggestions.each { |s| report << "  - #{s}" }
        report << ""
      end
      
      report << "=== End Report ==="
      
      report.join("\n")
    end

    # Determines if an import name looks like it should be a default import
    # 
    # This heuristic checks for patterns that typically indicate classes/constructors/libraries
    private def looks_like_default_import?(import_name : String) : Bool
      # Names that start with a capital letter are typically classes/constructors
      return true if import_name.match(/^[A-Z][a-zA-Z0-9_]*$/)
      
      # Common library names that use PascalCase or camelCase with capital letters
      # These are typically imported as default imports (e.g., jQuery, lodash variants)
      return true if import_name.match(/^[a-z]*[A-Z][a-zA-Z0-9_]*$/)
      
      false
    end

    # Checks if a dependency is already present in the import map
    private def import_map_contains_dependency?(dependency : String) : Bool
      @import_map.imports.any? do |import_entry|
        import_entry.first_key == dependency
      end
    end
  end
end 