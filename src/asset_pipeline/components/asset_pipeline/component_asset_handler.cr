require "../base/stateful_component"
require "../cache/component_cache_manager"
require "../css_registry"
require "./component_asset_generator"

# Alias for easier reference
alias StatefulComponent = AssetPipeline::Components::StatefulComponent
alias CSSRegistry = AssetPipeline::Components::CSSRegistry

module AssetPipeline
  module Components
    module AssetPipeline
      # ComponentAssetHandler processes component assets during build phase
      # and integrates with the existing asset pipeline system
      class ComponentAssetHandler
        property js_source_path : String
        property js_output_path : String
        property css_output_path : String
        property import_map : Hash(String, String)?
        property minify : Bool
        property development_mode : Bool
        property processed_components_count : Int32
        
        def initialize(@js_source_path : String = "src/app/javascript", 
                       @js_output_path : String = "public/assets", 
                       @css_output_path : String = "public/assets",
                       @minify : Bool = false, 
                       @development_mode : Bool = false)
          @asset_generator = ComponentAssetGenerator.new(@js_output_path)
          @import_map = nil
          @processed_components_count = 0
        end
        
        # Set the import map for component asset integration
        def set_import_map(import_map)
          # Store as hash for flexibility
          if import_map.responds_to?(:get_imports)
            @import_map = import_map.get_imports
          elsif import_map.is_a?(Hash)
            @import_map = import_map
          end
        end
        
        # Process all component assets and integrate with asset pipeline
        def process_component_assets(components : Array(Class) = [] of Class) : Hash(String, String)
          # Track the number of components being processed
          @processed_components_count = components.size
          
          results = {} of String => String
          
          # Generate JavaScript bundle for stateful components
          if js_path = process_javascript_assets(components)
            results["javascript"] = js_path
            integrate_with_import_map(js_path) if @import_map
          end
          
          # Generate CSS bundle for component styles
          if css_path = process_css_assets(components)
            results["css"] = css_path
          end
          
          # Generate manifest for asset tracking
          if manifest_path = generate_asset_manifest(results)
            results["manifest"] = manifest_path
          end
          
          results
        end
        
        # Process JavaScript assets for stateful components
        def process_javascript_assets(components : Array(Class)) : String?
          stateful_components = components.select { |comp| comp < StatefulComponent }
          return nil if stateful_components.empty?
          
          bundle_content = @asset_generator.generate_javascript_bundle(stateful_components)
          return nil if bundle_content.empty?
          
          # Minify if requested
          if @minify && !@development_mode
            bundle_content = @asset_generator.minify_javascript(bundle_content)
          end
          
          # Write to output path
          output_path = @asset_generator.write_javascript_bundle(stateful_components, minify: @minify)
          File.basename(output_path)
        end
        
        # Process CSS assets for component styles
        def process_css_assets(components : Array(Class)) : String?
          # Generate CSS based on used components
          css_content = @asset_generator.generate_css_bundle(components)
          return nil if css_content.empty?
          
          # Write to output path
          output_path = @asset_generator.write_css_bundle(components)
          File.basename(output_path)
        end
        
        # Generate asset manifest for tracking and cache busting
        def generate_asset_manifest(asset_paths : Hash(String, String)) : String?
          return nil if asset_paths.empty?
          
          manifest = @asset_generator.generate_manifest(fingerprint: !@development_mode)
          manifest_path = File.join(@js_output_path, "component-manifest.json")
          
          Dir.mkdir_p(File.dirname(manifest_path))
          File.write(manifest_path, manifest.to_json)
          
          File.basename(manifest_path)
        end
        
        # Integrate component JavaScript with existing import map
        private def integrate_with_import_map(js_filename : String)
          return unless @import_map
          
          # Add component system bundle to import map
          if import_map = @import_map
            import_map["component-system"] = File.join("/assets", js_filename)
          end
          
          # Add individual component modules if in development mode
          if @development_mode
            add_development_component_imports
          end
        end
        
        # Add individual component imports for development mode
        private def add_development_component_imports
          return unless @import_map && @development_mode
          
          # Scan for individual JavaScript files in component directories
          js_files = Dir.glob(File.join(@js_source_path, "components/**/*.js"))
          js_files.each do |file|
            relative_path = file.gsub(@js_source_path + "/", "")
            module_name = File.basename(file, ".js").underscore.camelcase
            if import_map = @import_map
              import_map[module_name] = relative_path
            end
          end
        end
        
        # Generate component initialization script for integration
        def generate_component_initialization_script(custom_js : String = "") : String
          # Generate simple initialization script without dependencies
          
          <<-HTML
            <script type="module">
              // Component System Initialization
              try {
                // Dynamically import component system
                const { ComponentSystem } = await import('/assets/component-system.js');
                
                // Initialize the component system
                const componentSystem = new ComponentSystem();
                componentSystem.initialize({
                  autoStart: true,
                  debugMode: #{@development_mode}
                });
                
                #{custom_js}
                
                // Auto-scan and mount components when DOM is ready
                if (document.readyState === 'loading') {
                  document.addEventListener('DOMContentLoaded', () => {
                    componentSystem.scanAndMount();
                  });
                } else {
                  componentSystem.scanAndMount();
                }
              } catch (error) {
                console.error('Failed to initialize component system:', error);
              }
            </script>
          HTML
        end
        
        # Optimize component assets for production
        def optimize_for_production(components : Array(Class)) : Hash(String, String)
          # Enable minification for production
          @minify = true
          @development_mode = false
          
          # Process assets with optimization
          results = process_component_assets(components)
          
          # Generate optimized CSS based on actual component usage
          if css_registry = CSSRegistry.instance
            used_classes = css_registry.all_used_classes
            if !used_classes.empty?
              optimized_css = generate_optimized_css(used_classes)
              css_path = File.join(@css_output_path, "components-optimized.css")
              File.write(css_path, optimized_css)
              results["optimized_css"] = File.basename(css_path)
            end
          end
          
          results
        end
        
        # Generate optimized CSS containing only used classes
        private def generate_optimized_css(used_classes : Array(String)) : String
          css_rules = [] of String
          
          # Generate CSS rules only for used classes
          used_classes.each do |css_class|
            if rule = generate_css_rule_for_class(css_class)
              css_rules << rule
            end
          end
          
          # Add base component styles
          css_rules << generate_base_component_styles
          
          css_rules.join("\n")
        end
        
        # Generate CSS rule for a specific class
        private def generate_css_rule_for_class(css_class : String) : String?
          case css_class
          when .starts_with?("btn")
            generate_button_css_rule(css_class)
          when .starts_with?("counter")
            generate_counter_css_rule(css_class)
          when .starts_with?("toggle")
            generate_toggle_css_rule(css_class)
          when .starts_with?("dropdown")
            generate_dropdown_css_rule(css_class)
          else
            nil
          end
        end
        
        # Generate base component styles that all components need
        private def generate_base_component_styles : String
          <<-CSS
            /* Base Component Styles */
            [data-component] {
              position: relative;
            }
            
            [data-component].component-loading {
              opacity: 0.7;
              pointer-events: none;
            }
            
            [data-component].component-error {
              border: 1px solid #ef4444;
              background-color: #fef2f2;
            }
          CSS
        end
        
        # Generate CSS for button classes
        private def generate_button_css_rule(css_class : String) : String
          case css_class
          when "btn"
            ".btn { padding: 0.5rem 1rem; border: 1px solid #d1d5db; border-radius: 0.375rem; background-color: #f9fafb; cursor: pointer; }"
          when "btn-primary"
            ".btn-primary { background-color: #3b82f6; color: white; border-color: #2563eb; }"
          when "btn-secondary"
            ".btn-secondary { background-color: #6b7280; color: white; border-color: #4b5563; }"
          when "btn-danger"
            ".btn-danger { background-color: #ef4444; color: white; border-color: #dc2626; }"
          when "btn-small"
            ".btn-small { padding: 0.25rem 0.5rem; font-size: 0.875rem; }"
          when "btn-large"
            ".btn-large { padding: 0.75rem 1.5rem; font-size: 1.125rem; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        # Generate CSS for counter classes
        private def generate_counter_css_rule(css_class : String) : String
          case css_class
          when "counter"
            ".counter { display: inline-flex; align-items: center; gap: 0.5rem; }"
          when "count-display"
            ".count-display { min-width: 2rem; text-align: center; font-weight: bold; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        # Generate CSS for toggle classes
        private def generate_toggle_css_rule(css_class : String) : String
          case css_class
          when "toggle"
            ".toggle { display: inline-flex; align-items: center; }"
          when "toggle-button"
            ".toggle-button { width: 3rem; height: 1.5rem; border-radius: 9999px; background-color: #d1d5db; position: relative; cursor: pointer; }"
          when "toggle-on"
            ".toggle-on { background-color: #3b82f6; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        # Generate CSS for dropdown classes
        private def generate_dropdown_css_rule(css_class : String) : String
          case css_class
          when "dropdown"
            ".dropdown { position: relative; display: inline-block; }"
          when "dropdown-menu"
            ".dropdown-menu { position: absolute; background-color: white; border: 1px solid #d1d5db; border-radius: 0.375rem; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); display: none; }"
          when "dropdown-item"
            ".dropdown-item { padding: 0.5rem 1rem; cursor: pointer; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        # Get processing statistics
        def get_processing_stats : Hash(String, Int32 | String)
          stats = @asset_generator.get_stats
          stats["handler_mode"] = @development_mode ? "development" : "production"
          stats["minification_enabled"] = @minify ? "yes" : "no"
          stats
        end
        
        # Clear all generated assets
        def clear_generated_assets
          Dir.glob(File.join(@js_output_path, "components*")).each do |file|
            File.delete(file) if File.file?(file)
          end
          Dir.glob(File.join(@css_output_path, "components*")).each do |file|
            File.delete(file) if File.file?(file)
          end
        end
        
        # Optimize component assets for production deployment
        def optimize_for_production(components : Array(Class)) : Hash(String, String)
          # Store previous settings
          original_minify = @minify
          original_dev_mode = @development_mode
          
          # Enable production optimizations
          @minify = true
          @development_mode = false
          
          begin
            # Process assets with production settings
            process_component_assets(components)
            
            # Generate production manifest
            js_bundle = @asset_generator.write_javascript_bundle(components, @minify)
            css_bundle = @asset_generator.write_css_bundle(components, @minify)
            
            result = {} of String => String
            result["js_bundle"] = js_bundle if js_bundle
            result["css_bundle"] = css_bundle if css_bundle
            
            result
          ensure
            # Restore original settings
            @minify = original_minify
            @development_mode = original_dev_mode
          end
        end
        
        # Get comprehensive processing statistics
        def get_processing_stats : Hash(String, Int32 | String)
          stats = {} of String => (Int32 | String)
          
          # Get generator stats
          if generator_stats = @asset_generator.get_stats
            stats.merge!(generator_stats)
          end
          
          # Add handler-specific stats
          stats["total_components"] = @processed_components_count
          stats["handler_mode"] = @development_mode ? "development" : "production"
          stats["minification_enabled"] = @minify ? "yes" : "no"
          
          stats
        end
        
        # Generate optimization report
        def generate_optimization_report : Hash(String, String | Int32 | Float64)
          report = {} of String => (String | Int32 | Float64)
          
          # Basic optimization metrics
          report["optimization_ratio"] = 0.85 # Example ratio
          report["components_processed"] = 0
          report["total_js_size"] = 0
          report["total_css_size"] = 0
          report["minified_js_size"] = 0
          report["minified_css_size"] = 0
          
          report
        end
      end
    end
  end
end 