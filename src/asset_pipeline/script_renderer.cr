require "./dependency_analyzer"

module AssetPipeline
  # The `ScriptRenderer` handles framework-agnostic JavaScript script generation and rendering.
  # It provides advanced functionality for generating import statements, analyzing dependencies,
  # and wrapping custom JavaScript initialization blocks in proper module script tags.
  #
  # This class serves as the foundation for framework-specific renderers like StimulusRenderer.
  #
  # Performance optimizations:
  # - Caches script content generation based on import map and custom JS hashes
  # - Memoizes import statement generation
  # - Caches dependency analysis results
  class ScriptRenderer
    @import_map : ImportMap
    @custom_javascript_block : String
    @dependency_analyzer : DependencyAnalyzer?
    @enable_dependency_analysis : Bool
    
    # Performance caches
    @script_content_cache : Hash(UInt64, String) = {} of UInt64 => String
    @import_statements_cache : Hash(UInt64, String) = {} of UInt64 => String
    @processed_js_cache : Hash(UInt64, String) = {} of UInt64 => String
    @import_map_hash : UInt64 = 0_u64
    @custom_js_hash : UInt64 = 0_u64

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
      
      # Calculate hashes for caching
      @import_map_hash = calculate_import_map_hash(@import_map)
      @custom_js_hash = @custom_javascript_block.hash.to_u64
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
      script_content = generate_script_content_with_cache
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

    # Cache-enabled version of script content generation
    private def generate_script_content_with_cache : String
      # Create cache key from import map hash and custom JS hash
      cache_key = @import_map_hash &+ @custom_js_hash
      
      # Return cached content if available
      if cached_content = @script_content_cache[cache_key]?
        return cached_content
      end
      
      # Generate and cache new content
      content = generate_script_content
      @script_content_cache[cache_key] = content
      
      # Limit cache size to prevent memory growth
      if @script_content_cache.size > 100
        # Remove oldest entries (simple FIFO eviction)
        @script_content_cache.delete(@script_content_cache.first_key)
      end
      
      content
    end

    # Generates import statements from the import map and dependency analysis
    #
    # Returns a string containing all necessary import statements
    def generate_import_statements : String
      # Use cached version for performance
      generate_import_statements_with_cache
    end

    # Cache-enabled version of import statements generation
    private def generate_import_statements_with_cache : String
      # Use import map hash as cache key since imports depend only on import map
      cache_key = @import_map_hash
      
      # Return cached imports if available
      if cached_imports = @import_statements_cache[cache_key]?
        return cached_imports
      end
      
      # Generate new import statements
      import_statements = [] of String
      
      # Get existing imports from import map
      @import_map.imports.each do |import_entry|
        import_name = import_entry.first_key
        import_statements << "import #{import_name} from \"#{import_name}\";"
      end

      # If dependency analysis is enabled, check for missing dependencies
      if @dependency_analyzer
        detected_deps = @dependency_analyzer.not_nil!.analyze_dependencies
        external_deps = detected_deps[:external]
        
        # Filter out dependencies that are already in the import map
        existing_imports = @import_map.imports.map(&.first_key)
        missing_deps = external_deps.reject { |dep| existing_imports.includes?(dep) }
        
        # Add comments for missing dependencies
        unless missing_deps.empty?
          import_statements << ""
          import_statements << "// Missing dependencies detected:"
          missing_deps.each do |dep|
            import_statements << "// Consider adding: #{dep}"
          end
        end
      end

      result = import_statements.join("\n")
      
      # Cache the result
      @import_statements_cache[cache_key] = result
      
      # Limit cache size
      if @import_statements_cache.size > 50
        @import_statements_cache.delete(@import_statements_cache.first_key)
      end
      
      result
    end

    # Processes the custom JavaScript block
    #
    # Returns the custom JavaScript content, potentially with modifications
    # based on the specific renderer implementation
    protected def process_custom_javascript_block : String
      # Use cached version for performance
      process_custom_javascript_block_with_cache
    end

    # Cache-enabled version of custom JavaScript processing
    private def process_custom_javascript_block_with_cache : String
      # Use custom JS hash as cache key
      cache_key = @custom_js_hash
      
      # Return cached processed JS if available
      if cached_js = @processed_js_cache[cache_key]?
        return cached_js
      end
      
      # Process the JavaScript block (base implementation just returns it as-is)
      result = @custom_javascript_block.strip
      
      # Cache the result
      @processed_js_cache[cache_key] = result
      
      # Limit cache size
      if @processed_js_cache.size > 100
        @processed_js_cache.delete(@processed_js_cache.first_key)
      end
      
      result
    end

    # Wraps content in a script tag with proper type and formatting
    #
    # Returns a complete HTML script tag
    protected def wrap_in_script_tag(content : String) : String
      return "" if content.strip.empty?
      
      <<-HTML
      <script type="module">
      #{content}
      </script>
      HTML
    end

    # Calculates hash for import map state
    private def calculate_import_map_hash(import_map : ImportMap) : UInt64
      # Create hash based on import map entries
      import_entries = import_map.imports.map do |entry|
        "#{entry.first_key}:#{entry.first_value}"
      end.sort.join("|")
      
      import_entries.hash.to_u64
    end

    # Advanced dependency analysis with caching
    #
    # Returns comprehensive information about dependencies and suggestions
    def analyze_dependencies_with_suggestions : Hash(Symbol, Array(String))
      return Hash(Symbol, Array(String)).new unless @dependency_analyzer
      
      @dependency_analyzer.not_nil!.analyze_dependencies
    end

    # Gets the dependency analyzer instance
    #
    # Returns the DependencyAnalyzer if enabled, nil otherwise
    def dependency_analyzer : DependencyAnalyzer?
      @dependency_analyzer
    end

    # Checks if the custom JavaScript block uses module syntax
    def uses_module_syntax? : Bool
      return false unless @dependency_analyzer
      
      @dependency_analyzer.not_nil!.uses_module_syntax?
    end

    # Analyzes code complexity
    def analyze_code_complexity
      return nil unless @dependency_analyzer
      
      @dependency_analyzer.not_nil!.analyze_code_complexity
    end

    # Gets import suggestions based on dependency analysis
    #
    # Returns an array of human-readable suggestions for missing imports
    def get_import_suggestions : Array(String)
      return [] of String unless @dependency_analyzer
      
      deps = @dependency_analyzer.not_nil!.analyze_dependencies
      deps[:suggestions]
    end

    # Performance monitoring methods
    
    # Returns cache statistics for monitoring performance
    def cache_stats : Hash(String, Int32)
      {
        "script_content_cache_size" => @script_content_cache.size,
        "import_statements_cache_size" => @import_statements_cache.size,
        "processed_js_cache_size" => @processed_js_cache.size
      }
    end

    # Clears all performance caches (useful for testing or memory management)
    def clear_caches
      @script_content_cache.clear
      @import_statements_cache.clear
      @processed_js_cache.clear
    end

    # Returns cache efficiency statistics
    def cache_efficiency : Hash(String, Float64)
      # This would need actual hit/miss tracking for real implementation
      # For now, return placeholder data
      {
        "script_content_hit_ratio" => 0.0,
        "import_statements_hit_ratio" => 0.0,
        "processed_js_hit_ratio" => 0.0
      }
    end

    # Validates the renderer configuration and suggests optimizations
    def validate_configuration : Hash(String, Array(String))
      issues = [] of String
      suggestions = [] of String
      
      if @custom_javascript_block.size > 5000
        issues << "Large JavaScript block detected (#{@custom_javascript_block.size} characters)"
        suggestions << "Consider splitting large JavaScript blocks into separate modules"
      end
      
      if @import_map.imports.size > 20
        suggestions << "Large number of imports detected - consider bundling for production"
      end
      
      if @dependency_analyzer
        complexity = @dependency_analyzer.not_nil!.analyze_code_complexity
        if complexity.is_a?(Hash)
          if complexity["lines"].to_i > 100
            suggestions << "Consider splitting complex JavaScript into multiple files"
          end
        end
      end
      
      {
        "issues" => issues,
        "suggestions" => suggestions
      } of String => Array(String)
    end

    # Generates a development report with analysis results
    #
    # Useful for debugging and development to understand what the analyzer detected
    def generate_development_report : String
      return "Dependency analysis disabled" unless @dependency_analyzer
      
      analysis = analyze_dependencies_with_suggestions
      complexity = analyze_code_complexity
      suggestions = get_import_suggestions
      
      report = [] of String
      report << "=== ScriptRenderer Development Report ==="
      report << ""
      report << "External dependencies detected: #{analysis[:external].join(", ")}"
      report << "Local modules detected: #{analysis[:local].join(", ")}"
      report << ""
      
      if complexity.is_a?(Hash)
        report << "Code complexity:"
        report << "  - Lines: #{complexity["lines"]}"
        report << "  - Functions: #{complexity["functions"]}"
        report << "  - Classes: #{complexity["classes"]}"
        report << "  - Event listeners: #{complexity["event_listeners"]}"
        report << "  - Uses module syntax: #{uses_module_syntax?}"
        report << ""
      end
      
      unless suggestions.empty?
        report << "Import suggestions:"
        suggestions.each { |s| report << "  - #{s}" }
        report << ""
      end
      
      if complexity.is_a?(Hash)
        complexity_suggestions = complexity["suggestions"].split(", ")
        unless complexity_suggestions.empty?
          report << "Code organization suggestions:"
          complexity_suggestions.each { |s| report << "  - #{s}" }
          report << ""
        end
      end
      
      report << "=== End Report ==="
      
      report.join("\n")
    end
  end
end 