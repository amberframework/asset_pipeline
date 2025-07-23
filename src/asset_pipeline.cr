require "digest/sha256"
require "file_utils"
require "./import_map/import_map"
require "./asset_pipeline/dependency_analyzer"
require "./asset_pipeline/script_renderer"
require "./asset_pipeline/framework_registry"
require "./asset_pipeline/stimulus/stimulus_renderer"

# TODO: Write documentation for `AssetPipeline`
module AssetPipeline
  VERSION = "0.36.0"

  # Initialize the framework registry with built-in framework support
  FrameworkRegistry.register_builtin_frameworks

  # The asset pipeline is responsible for loading assets from the import maps, asset loader and compiling styling.
  #
  # Use the `FrontLoader` class to initialize and manage your asset pipeline as a whole.
  #
  # # How to use Import Maps
  #
  # Using import maps is simple. A default "application" import map is created when a `AssetPipeline::FrontLoader` is initialized:
  #
  # ```
  # front_loader = AssetPipeline::FrontLoader.new
  # import_map = front_loader.get_import_map
  # import_map.add_import("someClass", "your_file.js")
  # front_loader.render_import_map_tag # Generates the import map tag and any module preload directives
  # ```
  #
  # You can also specify the name of your import map by initializing the with an import map
  #
  # ```
  # front_loader = AssetPipeline::FrontLoader.new(import_map: AssetPipeline::ImportMap.new(name: "my_import_map"))
  # import_map = front_loader.get_import_map("my_import_map") # You must specify the import map by the name you created
  # import_map.add_import("someClass", "your_file.js")
  # front_loader.render_import_map_tag("my_import_map") # You must specify the name of the import map by the name you created
  # ```
  #
  # If you need to create multiple import maps, the initializer can take a block:
  # ```
  # front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  #   import_map1 = AssetPipeline::ImportMap.new
  #   import_map1.add_import("stimulus", "https://cdn.jsdelivr.net/npm/stimulus@3.2.2/+esm", preload: true)
  #
  #   import_map2 = AssetPipeline::ImportMap.new("admin_area")
  #   import_map2.add_import("alpine", "https://cdn.jsdelivr.net/npm/alpinejs@3.13.2/+esm")
  #
  #   import_maps << import_map1
  #   import_maps << import_map2
  # end
  #
  # front_loader.render_import_map_tag               # Renders the import_map1 using the default "application" name
  # front_loader.render_import_map_tag("admin_area") # Renders the import_map2. Tip: only 1 import map should be on a page
  # ```
  #
  # Read more about the `ImportMap` class to know all of your options, including the 'preload' and 'scope' feature.
  #
  class FrontLoader
    property import_maps : Array(ImportMap) = [] of ImportMap
    @js_source_path : Path
    @js_output_path : Path
    @clear_cache_upon_change : Bool
    @cache_cleared : Bool = false

    # The default initializer for the `FrontLoader` class.
    def initialize(@js_source_path : Path = Path.new("src/app/javascript"), @js_output_path : Path = Path.new("public/assets/"), @import_maps : Array(ImportMap) = [] of ImportMap, @clear_cache_upon_change : Bool = true)
      @js_output_path = @js_output_path.join(Path[""])
      @js_source_path = @js_source_path.join(Path[""])
      @import_maps << AssetPipeline::ImportMap.new("application") if @import_maps.empty?
    end

    def initialize(@js_source_path : Path = Path.new("src/app/javascript"), @js_output_path : Path = Path.new("public/assets/"), import_map : ImportMap = ImportMap.new, @clear_cache_upon_change : Bool = true)
      @js_output_path = @js_output_path.join(Path[""])
      @js_source_path = @js_source_path.join(Path[""])
      @import_maps << import_map
    end

    # Initialize the asset pipeline with the given *block*.
    #
    # The block is the import maps that will be used by the asset pipeline.
    #
    # Set `clear_cache_upon_change` to `false` to disable automatic clearing of the output path before generating new cached files.
    # By default, cache clearing is enabled to prevent accumulation of old cached files.
    def initialize(@js_source_path : Path = Path.new("src/app/javascript/"), @js_output_path : Path = Path.new("public/assets"), @clear_cache_upon_change : Bool = true, &block)
      @js_output_path = @js_output_path.join(Path[""])
      @js_source_path = @js_source_path.join(Path[""])
      yield @import_maps
    end

    # Gets the import map with the given *name*.
    #
    # Default name is "application".
    def get_import_map(name : String = "application") : AssetPipeline::ImportMap
      @import_maps.find { |import_map| import_map.name == name } || raise "Import map with name #{name} not found"
    end

    # Returns the named import map JSON as a rendered, non-minified, string.
    def render_import_map_tag(name : String = "application") : String
      generate_file_version_hash(name)
      get_import_map(name).build_import_map_tag
    end

    # Returns the url to the import_map.json file that has been generated
    #
    # Warning: currently there is minimal browser support for this part of the spec. Please test thoroughly before using this approach.
    def render_import_map_as_file(name : String = "application") : String
      generate_file_version_hash(name)
      import_map = get_import_map(name)
      file_contents = import_map.build_import_map_json

      digest = Digest::SHA256.new
      digest << file_contents

      file_name = Path[name + "-" + digest.hexfinal + ".json"]

      File.write(@js_output_path.join(file_name), file_contents)

      <<-STRING
        <script type="importmap" src="/#{file_name}"></script>
        #{import_map.preload_module_links}
      STRING
    end

    # Generates the file hash and appends it to the file name.
    # :nodoc:
    def generate_file_version_hash(import_map_name : String = "application")
      clear_cache_if_needed

      file_hashes = Hash(String, String).new
      target_import_map = get_import_map(import_map_name)

      Dir.glob("#{@js_source_path}/**/*.js").each do |file|
        file_hash = Digest::SHA256.new.file(file).hexfinal
        file_index = file.index('.') || next
        cached_file_name = file.insert(file_index, "-" + file_hash).gsub(@js_source_path.to_s, @js_output_path.to_s)

        found_index = target_import_map.imports.index { |r| File.basename(r.first_value.to_s, ".js").includes?(File.basename(file, ".js")) }

        if !found_index.nil?
          if !File.exists?(cached_file_name)
            Dir.mkdir_p(File.dirname(cached_file_name))
            FileUtils.cp_r(file, cached_file_name)
          end

          first_key = target_import_map.imports[found_index].first_key
          target_import_map.imports[found_index][first_key] = cached_file_name.gsub(@js_output_path.to_s, target_import_map.public_asset_base_path.join(Path[""]).to_s)
        end
      end
    end

    # Renders a general JavaScript initialization script with imports and custom code
    #
    # This method generates a complete `<script type="module">` tag containing:
    # - Import statements based on the specified import map
    # - Custom JavaScript initialization code
    #
    # ```
    # front_loader.render_initialization_script("console.log('App initialized');", "application")
    # ```
    #
    # The *custom_js_block* parameter contains any custom JavaScript code to include in the script.
    # The *import_map_name* specifies which import map to use for generating imports (defaults to "application").
    def render_initialization_script(custom_js_block : String = "", import_map_name : String = "application") : String
      import_map = get_import_map(import_map_name)
      renderer = ScriptRenderer.new(import_map, custom_js_block)
      renderer.render_initialization_script
    end

    # Renders a Stimulus-specific initialization script with automatic controller detection
    #
    # This method generates a complete `<script type="module">` tag containing:
    # - Stimulus core imports (@hotwired/stimulus)
    # - Automatic controller imports based on import map entries
    # - Stimulus application initialization and controller registration
    # - Custom JavaScript initialization code (with automatic filtering of redundant code)
    #
    # ```
    # front_loader.render_stimulus_initialization_script("// Custom initialization code", "application")
    # ```
    #
    # The renderer automatically:
    # - Detects controller classes from import map entries ending in "Controller"
    # - Generates proper controller registrations with kebab-case identifiers
    # - Filters out duplicate import and registration statements from custom code
    # - Sets up the Stimulus application with proper startup sequence
    #
    # The *custom_js_block* parameter contains any custom JavaScript code to include.
    # The *import_map_name* specifies which import map to use (defaults to "application").
    def render_stimulus_initialization_script(custom_js_block : String = "", import_map_name : String = "application") : String
      import_map = get_import_map(import_map_name)
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js_block)
      renderer.render_stimulus_initialization_script
    end

    # Renders a JavaScript initialization script with dependency analysis and warnings
    #
    # This enhanced version includes comments about potentially missing dependencies to assist
    # with development. It analyzes the custom JavaScript block and provides warnings about
    # external libraries or local modules that may need to be added to the import map.
    #
    # ```
    # front_loader.render_initialization_script_with_analysis("$('#app').fadeIn();", "application")
    # # Includes comment: "// WARNING: Add to import map: import_map.add_import("jquery", "...")"
    # ```
    #
    # The *custom_js_block* parameter contains any custom JavaScript code to analyze and include.
    def render_initialization_script_with_analysis(custom_js_block : String = "", import_map_name : String = "application") : String
      import_map = get_import_map(import_map_name)
      renderer = ScriptRenderer.new(import_map, custom_js_block, enable_dependency_analysis: true)
      
      script_content = renderer.generate_script_content
      analysis = renderer.analyze_dependencies
      
      # Add dependency analysis comments if warnings exist, but only for dependencies not already in import map
      warning_comments = [] of String
      
      if external_libs = analysis[:external]?
        external_libs.each do |library|
          # Check if dependency is already in import map before adding warning
          unless import_map.imports.any? { |import_entry| import_entry.first_key == library }
            warning_comments << "// WARNING: Add to import map: import_map.add_import(\"#{library}\", \"...\")"
          end
        end
      end
      
      if local_modules = analysis[:local]?
        local_modules.each do |module_name|
          # Check if dependency is already in import map before adding warning
          unless import_map.imports.any? { |import_entry| import_entry.first_key == module_name }
            warning_comments << "// INFO: Consider adding local module: import_map.add_import(\"#{module_name}\", \"#{module_name}.js\")"
          end
        end
      end
      
      final_content = warning_comments.empty? ? script_content : ([warning_comments.join("\n"), script_content].join("\n\n"))
      
      # Wrap content in script tag manually since wrap_in_script_tag is protected
      return "" if final_content.strip.empty?
      
      <<-HTML
      <script type="module">
      #{final_content}
      </script>
      HTML
    end

    # Renders a framework-specific initialization script using the framework registry
    #
    # This method provides a generic interface for rendering framework-specific scripts
    # based on the registered framework renderers. It automatically detects and uses
    # the appropriate renderer for the specified framework.
    #
    # ```
    # front_loader.render_framework_script("stimulus", "// Custom code", "application")
    # front_loader.render_framework_script("alpine", "// Alpine setup", "application")
    # ```
    #
    # The *framework_name* specifies which framework renderer to use (e.g., "stimulus", "alpine").
    # The *custom_js_block* parameter contains any custom JavaScript code to include.
    # The *import_map_name* specifies which import map to use (defaults to "application").
    #
    # Returns an empty string if the framework is not registered.
    def render_framework_script(framework_name : String, custom_js_block : String = "", import_map_name : String = "application") : String
      import_map = get_import_map(import_map_name)
      renderer = FrameworkRegistry.create_renderer(framework_name, import_map, custom_js_block)
      
      if renderer.responds_to?(:render_framework_initialization_script)
        renderer.render_framework_initialization_script
      elsif renderer.responds_to?(:render_stimulus_initialization_script)
        # Backward compatibility for StimulusRenderer
        renderer.render_stimulus_initialization_script
      else
        ""
      end
    end

    # Returns information about supported frameworks and their capabilities
    #
    # ```
    # front_loader.framework_capabilities
    # # => {
    # #   "supported_frameworks" => ["stimulus"],
    # #   "registry_summary" => {...}
    # # }
    # ```
    def framework_capabilities : Hash(String, Array(String) | Hash(String, String | Array(String) | Int32 | Hash(String, Hash(String, String))))
      {
        "supported_frameworks" => FrameworkRegistry.supported_frameworks,
        "registry_summary" => FrameworkRegistry.registry_summary
      }
    end

    # Analyzes JavaScript dependencies in a custom code block
    #
    # Returns a hash containing:
    # - :external - Array of detected external library names (e.g., ["jquery", "lodash"])
    # - :local - Array of detected local module names (e.g., ["MyClass", "UtilityHelper"])
    # - :suggestions - Array of human-readable import suggestions
    #
    # ```
    # analysis = front_loader.analyze_javascript_dependencies("$('.modal').show(); MyClass.init();")
    # puts analysis[:external]    # => ["jquery"]
    # puts analysis[:local]       # => ["MyClass"]
    # puts analysis[:suggestions] # => ["Add to import map: import_map.add_import(...)"]
    # ```
    def analyze_javascript_dependencies(custom_js_block : String, import_map_name : String = "application") : Hash(Symbol, Array(String))
      import_map = get_import_map(import_map_name)
      renderer = ScriptRenderer.new(import_map, custom_js_block, enable_dependency_analysis: true)
      renderer.analyze_dependencies
    end

    # Gets import suggestions for detected but missing dependencies
    #
    # Analyzes the JavaScript block and returns suggestions for dependencies that are used
    # in the code but not present in the import map.
    #
    # ```
    # suggestions = front_loader.get_dependency_suggestions("moment().format('YYYY-MM-DD')")
    # puts suggestions # => ["Add to import map: import_map.add_import("moment", "https://...")"]
    # ```
    def get_dependency_suggestions(custom_js_block : String, import_map_name : String = "application") : Array(String)
      import_map = get_import_map(import_map_name)
      renderer = ScriptRenderer.new(import_map, custom_js_block, enable_dependency_analysis: true)
      renderer.get_import_suggestions
    end

    # Generates a comprehensive development report for JavaScript analysis
    #
    # This method provides detailed information about:
    # - Detected dependencies (external and local)
    # - Code complexity metrics
    # - Import suggestions
    # - Code organization recommendations
    #
    # Useful for development and debugging to understand what the dependency analyzer detected.
    #
    # ```
    # report = front_loader.generate_dependency_report(my_javascript_code)
    # puts report
    # ```
    def generate_dependency_report(custom_js_block : String, import_map_name : String = "application") : String
      import_map = get_import_map(import_map_name)
      renderer = ScriptRenderer.new(import_map, custom_js_block, enable_dependency_analysis: true)
      renderer.generate_development_report
    end

    # Analyzes code complexity and provides organization suggestions
    #
    # Returns metrics about the JavaScript code including:
    # - lines: Number of non-empty lines
    # - functions: Number of function definitions
    # - classes: Number of class definitions  
    # - event_listeners: Number of event listener registrations
    # - suggestions: Array of code organization recommendations
    #
    # ```
    # complexity = front_loader.analyze_code_complexity(large_javascript_block)
    # puts "Lines: #{complexity[:lines]}"
    # puts "Suggestions: #{complexity[:suggestions]}"
    # ```
    def analyze_code_complexity(custom_js_block : String)
      # Don't need import map for complexity analysis
      import_map = AssetPipeline::ImportMap.new("temp")
      renderer = ScriptRenderer.new(import_map, custom_js_block, enable_dependency_analysis: true)
      renderer.analyze_code_complexity
    end

    # Clears the cache if the clear_cache_upon_change option is enabled.
    # This method is called automatically before generating file version hashes.
    # :nodoc:
    private def clear_cache_if_needed
      if @clear_cache_upon_change && !@cache_cleared
        if Dir.exists?(@js_output_path.to_s)
          FileUtils.rm_rf(@js_output_path.to_s)
        end
        @cache_cleared = true
      end
    end
  end
end
