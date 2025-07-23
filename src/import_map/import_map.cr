module AssetPipeline
  # The `ImportMap` is the main way that javascript is handled. This is a no-bundle approach using the "import map" browser standard.
  #
  # The `ImportMap` supports several features that are provided by the import map specification:
  #   - imports: this is a url that can be relative to your application, or a full CDN path to an esm module
  #   - scopes: this is a feature that can help rescrict which librarys are loaded. The keys here are relative paths in your application.
  #   - preloading: any import that's added with `preload: true` will also render a <link> tag to have the module preloaded
  #
  # Enhanced in Phase 4 with metadata support for categorizing imports by type and framework.
  class ImportMap
    # The name of your import map. Updatable with the `name=` method.
    property name : String
    @imports : Array(Hash(String, String | Bool)) = [] of Hash(String, String | Bool)
    @preload_module_links : String = ""
    @scopes : Hash(String, Array(Hash(String, String))) = Hash(String, Array(Hash(String, String))).new { |hash, key| hash[key] = [] of Hash(String, String) }
    @import_tag = ""
    @public_asset_base_path : Path

    # Set the name of the import map during initialization. The default is `application`
    # Set the base path for your assets. This is used to make sure that relative paths are correct.
    #
    # For example, if you're serving your javascript files from `/assets/js` then you would set `public_asset_bate_path` to `/assets/js`
    #
    def initialize(@name = "application", @public_asset_base_path : Path = Path["/"])
      @public_asset_base_path = @public_asset_base_path.join(Path[""])
    end

    # This renders the complete HTML tag for the import map, including the modulepreload tags required.
    #
    # Use this method to render the full import map into an HTML view.
    def build_import_map_tag : String
      <<-STRING
      <script type="importmap">#{build_import_map_json}</script>
      #{@preload_module_links}
      STRING
    end

    # Generates the valid import json. This can be used in a .json file or a `<script type="importmap">` tag.
    def build_import_map_json : String
      import_map_string = create_map_list_as_string
      import_json = <<-STRING
          { 
            "imports": 
            {
        STRING

      import_json += import_map_string + " }"

      if @scopes.any?
        import_json += ",\n \"scopes\": {" + create_scope_list_as_string + " }"
      end

      import_json += "}"
      import_json
    end

    # Name the library you want to incude in the import map.
    #
    # ```
    # import("lodash", "https://cdn.jsdelivr.net/npm/lodash/lodash.min.js")
    # ```
    #
    # Adding `preload` will mark the module to be eager loaded by the browser.
    # ```
    # import("lodash", "https://cdn.jsdelivr.net/npm/lodash/lodash.min.js", preload: true)
    # ```
    #
    # The `name` should match the way you import a class in your JS code.
    #
    # The `to` parameter is the full path and name of file or the full CDN url to an ESM module.
    #
    # Think of it like this: you are importing the class `name` associated `to` a library file path.
    def add_import(name : String, to : String, preload : Bool = false)
      @imports << {name => to, "preload" => preload}
    end

    # Enhanced import method with metadata support for categorizing imports by type and framework
    #
    # ```
    # import_map.add_import_with_metadata("HelloController", "hello_controller.js", 
    #                                     type: "controller", framework: "stimulus")
    # ```
    #
    # Supported types: "controller", "library", "utility", "framework", "component"
    # Supported frameworks: "stimulus", "alpine", "vue", "react", nil (for framework-agnostic)
    def add_import_with_metadata(name : String, to : String, preload : Bool = false, type : String? = nil, framework : String? = nil)
      import_entry = {name => to, "preload" => preload}
      import_entry["type"] = type if type
      import_entry["framework"] = framework if framework
      @imports << import_entry
    end

    # Add a scope to your import map. Scopes are paths relative to your application.
    #
    # To learn how to use scopes, <a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script/type/importmap" target="_blank">read about import maps and scopes here</a>
    def add_scope(scope : String, name : String, to : String)
      raise "Scope key must start with `/`, `./`, or `../`" unless scope.starts_with?(/\/|\.\/|\.\.\//)
      @scopes[scope] << {name => to}
    end

    # Returns imports filtered by type (e.g., "controller", "library", "utility")
    #
    # ```
    # import_map.imports_by_type("controller")  # Returns only controller imports
    # ```
    def imports_by_type(type : String) : Array(Hash(String, String | Bool))
      @imports.select { |import_entry| import_entry["type"]? == type }
    end

    # Returns imports filtered by framework (e.g., "stimulus", "alpine", "vue")
    #
    # ```
    # import_map.imports_by_framework("stimulus")  # Returns only Stimulus-related imports
    # ```
    def imports_by_framework(framework : String) : Array(Hash(String, String | Bool))
      @imports.select { |import_entry| import_entry["framework"]? == framework }
    end

    # Returns imports that have no framework specified (framework-agnostic)
    #
    # ```
    # import_map.framework_agnostic_imports  # Returns general/utility imports
    # ```
    def framework_agnostic_imports : Array(Hash(String, String | Bool))
      @imports.select { |import_entry| import_entry["framework"]?.nil? }
    end

    # Returns stimulus controller imports specifically
    #
    # Convenience method that combines type="controller" and framework="stimulus" filtering
    def stimulus_controller_imports : Array(Hash(String, String | Bool))
      @imports.select do |import_entry|
        import_entry["type"]? == "controller" && import_entry["framework"]? == "stimulus"
      end
    end

    # Auto-detects and categorizes imports based on naming patterns
    #
    # This method analyzes existing imports and adds metadata based on common patterns:
    # - Names ending in "Controller" → type: "controller", framework: "stimulus"
    # - Framework names (@hotwired/stimulus, alpinejs, etc.) → type: "framework"
    # - Known utility libraries → type: "library"
    #
    # ```
    # import_map.auto_categorize_imports!
    # ```
    def auto_categorize_imports!
      @imports.each do |import_entry|
        import_name = import_entry.first_key
        
        # Skip if already categorized
        next if import_entry.has_key?("type") || import_entry.has_key?("framework")
        
        # Auto-detect Stimulus controllers
        if import_name.match(/^[A-Z][a-zA-Z0-9_]*Controller$/)
          import_entry["type"] = "controller"
          import_entry["framework"] = "stimulus"
        # Auto-detect framework imports
        elsif import_name.match(/@hotwired\/stimulus|stimulus/)
          import_entry["type"] = "framework"
          import_entry["framework"] = "stimulus"
        elsif import_name.match(/alpinejs|alpine/)
          import_entry["type"] = "framework"
          import_entry["framework"] = "alpine"
        elsif import_name.match(/vue/)
          import_entry["type"] = "framework"
          import_entry["framework"] = "vue"
        elsif import_name.match(/react/)
          import_entry["type"] = "framework"
          import_entry["framework"] = "react"
        # Auto-detect common libraries
        elsif import_name.match(/lodash|underscore|jquery|axios|fetch/)
          import_entry["type"] = "library"
        # Default to utility for unrecognized patterns
        else
          import_entry["type"] = "utility"
        end
      end
    end

    # Returns a summary of import types and frameworks in the import map
    #
    # ```
    # import_map.import_summary
    # # => {
    # #   types: {"controller" => 3, "library" => 2, "framework" => 1},
    # #   frameworks: {"stimulus" => 4, "alpine" => 1}
    # # }
    # ```
    def import_summary : Hash(String, Hash(String, Int32))
      type_counts = Hash(String, Int32).new(0)
      framework_counts = Hash(String, Int32).new(0)
      
      @imports.each do |import_entry|
        if type = import_entry["type"]?.as?(String)
          type_counts[type] += 1
        end
        
        if framework = import_entry["framework"]?.as?(String)
          framework_counts[framework] += 1
        end
      end
      
      {
        "types" => type_counts,
        "frameworks" => framework_counts
      }
    end

    # :nodoc:
    def imports
      @imports
    end

    # :nodoc:
    def preload_module_links
      @preload_module_links
    end

    # :nodoc:
    def public_asset_base_path
      @public_asset_base_path
    end

    # :nodoc:
    private def create_map_list_as_string : String
      final_string = ""

      @imports.each_with_index do |import, index|
        if import["preload"]
          @preload_module_links += %(<link rel="modulepreload" href="#{import.first_value}">\n)
        end

        if !import.first_value.to_s.starts_with?(/http|\.\//)
          first_value = import[import.first_key].to_s

          if !first_value.starts_with?(/\/|\.\//)
            import[import.first_key] = @public_asset_base_path.join(first_value).to_s
          end
        end

        final_string += "\"#{import.first_key}\": \"#{import.first_value}\""
        final_string += ",\n" unless index + 1 == @imports.size
      end

      final_string
    end

    # :nodoc:
    private def create_scope_list_as_string
      final_string = ""

      @scopes.each_with_index do |(scope, imports), index|
        final_string += "\"#{scope}\": {"
        imports.each_with_index do |import, index|
          final_string += "\"#{import.first_key}\": \"#{import.first_value}\""
          final_string += ",\n" unless index + 1 == imports.size
        end
        final_string += "}"
        final_string += ",\n" unless index + 1 == @scopes.size
      end

      final_string
    end
  end
end
