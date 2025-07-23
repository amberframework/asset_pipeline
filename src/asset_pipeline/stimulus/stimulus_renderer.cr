require "../script_renderer"

module AssetPipeline::Stimulus
  # The `StimulusRenderer` extends `ScriptRenderer` to provide Stimulus-specific functionality.
  # It automatically detects Stimulus controller imports, generates proper controller registration,
  # and handles Stimulus application initialization.
  #
  # This renderer can parse custom JavaScript blocks to:
  # - Detect `Stimulus.register("name", ControllerClass)` patterns
  # - Identify controller import statements 
  # - Generate proper Stimulus application setup
  # - Handle Stimulus-specific initialization code
  #
  # Performance optimizations:
  # - Caches controller detection results to avoid re-parsing import maps
  # - Caches generated script content for identical configurations
  # - Memoizes controller-to-stimulus-id conversions
  class StimulusRenderer < AssetPipeline::ScriptRenderer
    @stimulus_controllers : Array(String) = [] of String
    @stimulus_application_name : String
    
    # Performance caches
    @controller_detection_cache : Hash(UInt64, Array(String)) = {} of UInt64 => Array(String)
    @script_content_cache : Hash(UInt64, String) = {} of UInt64 => String
    @controller_id_cache : Hash(String, String) = {} of String => String
    @import_map_hash : UInt64 = 0_u64
    @custom_js_hash : UInt64 = 0_u64

    # Initialize the StimulusRenderer with an import map, custom JavaScript block, and application name
    #
    # ```
    # renderer = StimulusRenderer.new(import_map, "Stimulus.register('hello', HelloController);", "application")
    # ```
    def initialize(import_map : ImportMap, custom_javascript_block : String = "", @stimulus_application_name : String = "application")
      super(import_map, custom_javascript_block)
      
      # Calculate hashes for caching
      @import_map_hash = calculate_import_map_hash(import_map)
      @custom_js_hash = custom_javascript_block.hash.to_u64
      
      @stimulus_controllers = extract_controller_names_with_cache
    end

    # Renders a complete Stimulus initialization script
    #
    # Returns a script tag containing:
    # - Stimulus core imports
    # - Controller imports (automatically detected)
    # - Stimulus application initialization
    # - Controller registrations
    # - Custom JavaScript initialization block
    def render_stimulus_initialization_script : String
      script_content = generate_stimulus_script_content_with_cache
      wrap_in_script_tag(script_content)
    end

    # Generates the complete Stimulus script content without wrapping tags
    def generate_stimulus_script_content : String
      content_parts = [] of String

      # Add Stimulus core import
      content_parts << generate_stimulus_imports

      # Add controller imports (auto-detected from import map and custom JS)
      controller_imports = generate_controller_imports
      content_parts << controller_imports unless controller_imports.empty?

      # Add Stimulus application setup
      content_parts << generate_stimulus_application_setup

      # Add custom JavaScript processing (which may include additional registrations)
      custom_js = process_custom_javascript_block
      content_parts << custom_js unless custom_js.empty?

      # Add application start
      content_parts << generate_stimulus_application_start

      content_parts.join("\n\n")
    end

    # Cache-enabled version of script content generation
    private def generate_stimulus_script_content_with_cache : String
      # Create cache key from import map hash, custom JS hash, and application name
      cache_key = calculate_script_cache_key
      
      # Return cached content if available
      if cached_content = @script_content_cache[cache_key]?
        return cached_content
      end
      
      # Generate and cache new content
      content = generate_stimulus_script_content
      @script_content_cache[cache_key] = content
      
      # Limit cache size to prevent memory growth
      if @script_content_cache.size > 100
        # Remove oldest entries (simple FIFO eviction)
        @script_content_cache.delete(@script_content_cache.first_key)
      end
      
      content
    end

    # Calculates cache key for script content
    private def calculate_script_cache_key : UInt64
      # Combine import map hash, custom JS hash, and application name hash
      base_hash = @import_map_hash &+ @custom_js_hash &+ @stimulus_application_name.hash.to_u64
      
      # Include controller list hash for additional uniqueness
      controller_hash = @stimulus_controllers.sort.join(",").hash.to_u64
      
      base_hash &+ controller_hash
    end

    # Calculates hash for import map state
    private def calculate_import_map_hash(import_map : ImportMap) : UInt64
      # Create hash based on import map entries
      import_entries = import_map.imports.map do |entry|
        "#{entry.first_key}:#{entry.first_value}"
      end.sort.join("|")
      
      import_entries.hash.to_u64
    end

    # Cache-enabled controller name extraction
    private def extract_controller_names_with_cache : Array(String)
      # Create cache key from both import map and custom JS
      cache_key = @import_map_hash &+ @custom_js_hash
      
      # Return cached controllers if available
      if cached_controllers = @controller_detection_cache[cache_key]?
        return cached_controllers
      end
      
      # Extract controllers and cache the result
      controllers = extract_controller_names_from_javascript_block
      controllers.concat(extract_controller_names_from_import_map)
      controllers.uniq!
      
      @controller_detection_cache[cache_key] = controllers
      
      # Limit cache size to prevent memory growth
      if @controller_detection_cache.size > 50
        # Remove oldest entries (simple FIFO eviction)
        @controller_detection_cache.delete(@controller_detection_cache.first_key)
      end
      
      controllers
    end

    # Extracts controller names from import map
    private def extract_controller_names_from_import_map : Array(String)
      controllers = [] of String
      
      @import_map.imports.each do |import_entry|
        import_name = import_entry.first_key
        
        if looks_like_stimulus_controller?(import_name)
          controllers << import_name unless controllers.includes?(import_name)
        end
      end
      
      controllers
    end

    # Processes custom JavaScript block with Stimulus-specific parsing
    #
    # Removes already-handled controller registrations and imports to avoid duplication
    protected def process_custom_javascript_block : String
      processed_js = @custom_javascript_block.strip
      return processed_js if processed_js.empty?

      # Remove lines that we're handling automatically to avoid duplication
      lines = processed_js.split("\n")
      filtered_lines = lines.reject do |line|
        line.strip.starts_with?("import") && contains_controller_reference?(line) ||
        line.strip.includes?("Stimulus.register") ||
        line.strip.includes?("Application.start") ||
        line.strip.includes?("application.start")
      end

      filtered_lines.join("\n").strip
    end

    # Generates Stimulus core imports
    private def generate_stimulus_imports : String
      "import { Application } from \"@hotwired/stimulus\";"
    end

    # Generates imports for detected Stimulus controllers
    private def generate_controller_imports : String
      import_statements = [] of String

      # Use cached controllers for consistent results
      @stimulus_controllers.each do |controller_name|
        import_statements << "import #{controller_name} from \"#{controller_name}\";"
      end

      import_statements.join("\n")
    end

    # Generates Stimulus application setup
    private def generate_stimulus_application_setup : String
      "const #{@stimulus_application_name} = Application.start();"
    end

    # Generates controller registrations for all detected controllers (cached)
    private def generate_controller_registrations : String
      registrations = [] of String

      @stimulus_controllers.each do |controller_name|
        # Convert controller class name to stimulus identifier (with caching)
        stimulus_id = controller_class_to_stimulus_id_cached(controller_name)
        registrations << "#{@stimulus_application_name}.register(\"#{stimulus_id}\", #{controller_name});"
      end

      registrations.join("\n")
    end

    # Generates the application start call
    private def generate_stimulus_application_start : String
      registrations = generate_controller_registrations
      return "" if registrations.empty?
      
      registrations
    end

    # Extracts controller names from the custom JavaScript block
    private def extract_controller_names_from_javascript_block : Array(String)
      controllers = [] of String
      return controllers if @custom_javascript_block.empty?

      # Look for Stimulus.register patterns
      stimulus_register_matches = @custom_javascript_block.scan(/Stimulus\.register\s*\(\s*["']([^"']+)["']\s*,\s*([A-Za-z][A-Za-z0-9_]*)\s*\)/)
      stimulus_register_matches.each do |match|
        controller_class = match[2]
        controllers << controller_class unless controllers.includes?(controller_class)
      end

      # Look for import statements that reference controller classes
      import_matches = @custom_javascript_block.scan(/import\s+([A-Za-z][A-Za-z0-9_]*)\s+from\s+["']([^"']+)["']/)
      import_matches.each do |match|
        controller_class = match[1]
        if looks_like_stimulus_controller?(controller_class)
          controllers << controller_class unless controllers.includes?(controller_class)
        end
      end

      controllers
    end

    # Determines if an import name looks like a Stimulus controller
    private def looks_like_stimulus_controller?(name : String) : Bool
      # Stimulus controllers typically end with "Controller" and are capitalized
      name.match(/^[A-Z][a-zA-Z0-9_]*Controller$/) != nil
    end

    # Checks if a line contains a controller reference
    private def contains_controller_reference?(line : String) : Bool
      @stimulus_controllers.any? do |controller|
        line.includes?(controller)
      end
    end

    # Converts a controller class name to a Stimulus identifier with caching
    # e.g., "HelloController" -> "hello", "MySpecialController" -> "my-special"
    private def controller_class_to_stimulus_id_cached(controller_class : String) : String
      # Check cache first
      if cached_id = @controller_id_cache[controller_class]?
        return cached_id
      end
      
      # Generate and cache the result
      stimulus_id = controller_class_to_stimulus_id(controller_class)
      @controller_id_cache[controller_class] = stimulus_id
      
      stimulus_id
    end

    # Converts a controller class name to a Stimulus identifier
    # e.g., "HelloController" -> "hello", "MySpecialController" -> "my-special"
    private def controller_class_to_stimulus_id(controller_class : String) : String
      # Remove "Controller" suffix
      base_name = controller_class.chomp("Controller")
      
      # Convert from PascalCase to kebab-case
      base_name.gsub(/([A-Z])/, "-\\1").downcase.lstrip("-")
    end

    # Performance monitoring methods
    
    # Returns cache statistics for monitoring performance
    def cache_stats : Hash(String, Int32)
      {
        "controller_detection_cache_size" => @controller_detection_cache.size,
        "script_content_cache_size" => @script_content_cache.size,
        "controller_id_cache_size" => @controller_id_cache.size
      }
    end

    # Clears all performance caches (useful for testing or memory management)
    def clear_caches
      @controller_detection_cache.clear
      @script_content_cache.clear
      @controller_id_cache.clear
    end

    # Returns the current cache hit ratio for performance monitoring
    def cache_efficiency : Hash(String, Float64)
      # This would need actual hit/miss tracking for real implementation
      # For now, return placeholder data
      {
        "controller_detection_hit_ratio" => 0.0,
        "script_content_hit_ratio" => 0.0,
        "controller_id_hit_ratio" => 0.0
      }
    end
  end
end 