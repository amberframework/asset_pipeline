require "./component_asset_handler"

module AssetPipeline
  # Extensions to FrontLoader for component asset integration
  module FrontLoaderComponentExtensions
    # Include component assets in the asset pipeline
    #
    # This method should be called to set up component asset processing
    # within the existing FrontLoader workflow
    #
    # ```
    # front_loader = AssetPipeline::FrontLoader.new
    # front_loader.add_component_support(
    #   components: [Button, Counter],
    #   development_mode: true
    # )
    # ```
    def add_component_support(components : Array(Class) = [] of Class, 
                             development_mode : Bool = false,
                             minify : Bool = false)
      @component_handler = AssetPipeline::Components::AssetPipeline::ComponentAssetHandler.new(
        js_source_path: @js_source_path.to_s,
        js_output_path: @js_output_path.to_s,
        development_mode: development_mode,
        minify: minify
      )
      
      # Set the import map for integration
      @component_handler.try &.set_import_map(get_import_map)
      
      # Process component assets
      @component_handler.try &.process_component_assets(components)
    end
    
    # Render component initialization script alongside regular import map
    #
    # This generates a complete script that includes both the import map
    # and component system initialization
    #
    # ```
    # front_loader.render_component_initialization_script(
    #   custom_js: "console.log('App ready!')",
    #   import_map_name: "application"
    # )
    # ```
    def render_component_initialization_script(custom_js : String = "", 
                                             import_map_name : String = "application") : String
      # First render the import map
      import_map_tag = render_import_map_tag(import_map_name)
      
      # Then render component initialization if handler exists
      component_script = ""
      if @component_handler
        component_script = @component_handler.generate_component_initialization_script(custom_js)
      end
      
      # Combine both
      <<-HTML
        #{import_map_tag}
        #{component_script}
      HTML
    end
    
    # Generate component assets for production deployment
    #
    # This method optimizes component assets for production use,
    # including minification and CSS optimization
    #
    # ```
    # front_loader.generate_production_component_assets([Button, Counter])
    # ```
    def generate_production_component_assets(components : Array(Class)) : Hash(String, String)
      return {} of String => String unless @component_handler
      
      @component_handler.optimize_for_production(components)
    end
    
    # Get component asset processing statistics
    #
    # Returns detailed information about component asset processing,
    # useful for debugging and optimization
    def get_component_asset_stats : Hash(String, Int32 | String)
      return {} of String => (Int32 | String) unless @component_handler
      
      @component_handler.get_processing_stats
    end
    
    # Clear all generated component assets
    #
    # Useful for development when you want to force regeneration
    # of all component assets
    def clear_component_assets
      return unless @component_handler
      
      @component_handler.clear_generated_assets
    end
    
    # Add component JavaScript files to the import map
    #
    # This method scans for component JavaScript files and adds them
    # to the import map for development mode hot reloading
    #
    # ```
    # front_loader.add_component_javascript_imports(import_map_name: "application")
    # ```
    def add_component_javascript_imports(import_map_name : String = "application")
      import_map = get_import_map(import_map_name)
      
      # Add core component system files
      component_js_files = [
        {"component-registry", "components/javascript/component_registry.js"},
        {"component-manager", "components/javascript/component_manager.js"},
        {"dom-utilities", "components/javascript/dom_utilities.js"},
        {"stateful-component", "components/javascript/stateful_component_js.js"},
        {"component-system", "components/javascript/component_system.js"}
      ]
      
      component_js_files.each do |name, path|
        import_map.add_import(name, path)
      end
      
      # Add example components
      example_components = [
        {"counter-component", "components/javascript/examples/counter.js"},
        {"toggle-component", "components/javascript/examples/toggle.js"},
        {"dropdown-component", "components/javascript/examples/dropdown.js"}
      ]
      
      example_components.each do |name, path|
        import_map.add_import(name, path)
      end
    end
    
    # Render a complete component-enabled application script
    #
    # This combines import map, component system, and custom initialization
    # into a single convenient method
    #
    # ```
    # script_tag = front_loader.render_component_application_script(
    #   components: [Button, Counter],
    #   custom_js: "MyApp.init();",
    #   development_mode: true
    # )
    # ```
    def render_component_application_script(components : Array(Class) = [] of Class,
                                          custom_js : String = "",
                                          import_map_name : String = "application",
                                          development_mode : Bool = false) : String
      # Ensure component support is added
      add_component_support(components, development_mode: development_mode)
      
      # Add component imports to the import map
      add_component_javascript_imports(import_map_name)
      
      # Render the complete application script
      render_component_initialization_script(custom_js, import_map_name)
    end
    
    # Helper method to create a component-optimized FrontLoader
    #
    # This is a convenience method for setting up a FrontLoader
    # specifically configured for component development
    #
    # ```
    # front_loader = AssetPipeline::FrontLoader.create_with_components(
    #   components: [Button, Counter],
    #   js_source_path: Path["src/javascript"],
    #   js_output_path: Path["public/assets"]
    # )
    # ```
    def self.create_with_components(components : Array(Class),
                                  js_source_path : Path = Path.new("src/app/javascript"),
                                  js_output_path : Path = Path.new("public/assets"),
                                  development_mode : Bool = false) : AssetPipeline::FrontLoader
      front_loader = AssetPipeline::FrontLoader.new(
        js_source_path: js_source_path,
        js_output_path: js_output_path
      )
      
      # Add component support (the include is already in the class)
      front_loader.add_component_support(
        components: components,
        development_mode: development_mode
      )
      
      front_loader
    end
  end
end

# Extend the real FrontLoader class with component functionality
module AssetPipeline
  class FrontLoader
    include FrontLoaderComponentExtensions
    
    property component_handler : AssetPipeline::Components::AssetPipeline::ComponentAssetHandler?
  end
end 