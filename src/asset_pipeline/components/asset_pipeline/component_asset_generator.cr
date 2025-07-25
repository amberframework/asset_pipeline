require "uuid"
require "json"
require "digest/sha256"

module AssetPipeline
  module Components
    module AssetPipeline
      # ComponentAssetGenerator extracts JavaScript and CSS from components
      # and prepares them for inclusion in the asset pipeline
      class ComponentAssetGenerator
        property output_dir : String
        property js_output_path : String
        property css_output_path : String
        property component_registry : CSSRegistry
        
        def initialize(@output_dir : String = "public/assets")
          @js_output_path = File.join(@output_dir, "components.js")
          @css_output_path = File.join(@output_dir, "components.css")
          @component_registry = CSSRegistry.instance
        end

        # Generate JavaScript bundle for all stateful components
        def generate_javascript_bundle(components : Array(Class)) : String
          js_content = String.build do |str|
            # Add header comment
            str << "// Asset Pipeline Component System - Generated JavaScript Bundle\n"
            str << "// Generated at: #{Time.utc.to_rfc3339}\n\n"
            
            # Add core JavaScript files
            add_core_javascript_files(str)
            
            # Add component-specific JavaScript
            components.each do |component_class|
              if javascript = extract_javascript_from_component(component_class)
                str << "\n// #{component_class.name} JavaScript\n"
                str << javascript
                str << "\n"
              end
            end
            
            # Add initialization code
            add_initialization_code(str, components)
          end
          
          js_content
        end

        # Generate CSS bundle for all components
        def generate_css_bundle(components : Array(Class)) : String
          css_content = String.build do |str|
            # Add header comment
            str << "/* Asset Pipeline Component System - Generated CSS Bundle */\n"
            str << "/* Generated at: #{Time.utc.to_rfc3339} */\n\n"
            
            # Add component-specific CSS
            components.each do |component_class|
              if css = extract_css_from_component(component_class)
                str << "\n/* #{component_class.name} CSS */\n"
                str << css
                str << "\n"
              end
            end
            
            # Add CSS for used classes only (tree-shaking)
            if optimized_css = generate_optimized_css
              str << "\n/* Optimized CSS (used classes only) */\n"
              str << optimized_css
              str << "\n"
            end
          end
          
          css_content
        end

        # Write JavaScript bundle to file
        def write_javascript_bundle(components : Array(Class), minify : Bool = false) : String
          ensure_output_directory_exists
          
          js_content = generate_javascript_bundle(components)
          
          if minify
            js_content = minify_javascript(js_content)
          end
          
          File.write(@js_output_path, js_content)
          @js_output_path
        end

        # Write CSS bundle to file
        def write_css_bundle(components : Array(Class), minify : Bool = false) : String
          ensure_output_directory_exists
          
          css_content = generate_css_bundle(components)
          
          if minify
            css_content = minify_css(css_content)
          end
          
          File.write(@css_output_path, css_content)
          @css_output_path
        end

        # Generate both JavaScript and CSS bundles
        def generate_bundles(components : Array(Class), minify : Bool = false) : Hash(String, String)
          {
            "javascript" => write_javascript_bundle(components, minify),
            "css" => write_css_bundle(components, minify)
          }
        end

        # Extract JavaScript content from a stateful component
        private def extract_javascript_from_component(component_class : Class) : String?
          return nil unless component_class.responds_to?(:javascript_content)
          
          # Create a dummy instance to get the JavaScript content
          begin
            instance = component_class.new
            if instance.responds_to?(:javascript_content)
              instance.javascript_content
            end
          rescue
            # If we can't instantiate the component, try class method
            if component_class.responds_to?(:javascript_content)
              component_class.javascript_content
            end
          end
        end

        # Extract CSS content from a component
        private def extract_css_from_component(component_class : Class) : String?
          return nil unless component_class.responds_to?(:css_content)
          
          # Create a dummy instance to get the CSS content
          begin
            instance = component_class.new
            if instance.responds_to?(:css_content)
              instance.css_content
            end
          rescue
            # If we can't instantiate the component, try class method
            if component_class.responds_to?(:css_content)
              component_class.css_content
            end
          end
        end

        # Add core JavaScript files to the bundle
        private def add_core_javascript_files(str : String::Builder)
          core_files = [
            "dom_utilities.js",
            "component_registry.js", 
            "component_manager.js",
            "stateful_component_js.js",
            "examples/counter.js",
            "examples/toggle.js",
            "examples/dropdown.js",
            "component_system.js"
          ]
          
          core_files.each do |file|
            js_file_path = File.join(__DIR__, "..", "javascript", file)
            if File.exists?(js_file_path)
              str << "// --- #{file} ---\n"
              str << File.read(js_file_path)
              str << "\n\n"
            end
          end
        end

        # Add initialization code to the JavaScript bundle
        private def add_initialization_code(str : String::Builder, components : Array(Class))
          str << "// Initialize component system\n"
          str << "document.addEventListener('DOMContentLoaded', function() {\n"
          str << "  if (window.componentSystem) {\n"
          str << "    window.componentSystem.start();\n"
          str << "  }\n"
          str << "});\n"
        end

        # Generate optimized CSS based on component usage
        private def generate_optimized_css : String?
          used_classes = @component_registry.all_used_classes
          return nil if used_classes.empty?
          
          # This is a simplified version - in a real implementation,
          # you would parse existing stylesheets and extract only used classes
          css_rules = [] of String
          
          used_classes.each do |css_class|
            # Generate basic styling rules for common classes
            case css_class
            when .starts_with?("btn")
              if rule = generate_button_css(css_class)
                css_rules << rule
              end
            when .starts_with?("counter")
              if rule = generate_counter_css(css_class)
                css_rules << rule
              end
            when .starts_with?("toggle")
              if rule = generate_toggle_css(css_class)
                css_rules << rule
              end
            when .starts_with?("dropdown")
              if rule = generate_dropdown_css(css_class)
                css_rules << rule
              end
            end
          end
          
          css_rules.join("\n")
        end

        # Generate CSS for button classes
        private def generate_button_css(css_class : String) : String?
          case css_class
          when "btn"
            ".btn { display: inline-block; padding: 0.375rem 0.75rem; margin-bottom: 0; font-size: 1rem; line-height: 1.5; text-align: center; text-decoration: none; vertical-align: middle; cursor: pointer; border: 1px solid transparent; border-radius: 0.25rem; }"
          when "btn-primary"
            ".btn-primary { color: #fff; background-color: #007bff; border-color: #007bff; }"
          when "btn-secondary"
            ".btn-secondary { color: #fff; background-color: #6c757d; border-color: #6c757d; }"
          when "btn-sm"
            ".btn-sm { padding: 0.25rem 0.5rem; font-size: 0.875rem; border-radius: 0.2rem; }"
          when "btn-lg"
            ".btn-lg { padding: 0.5rem 1rem; font-size: 1.25rem; border-radius: 0.3rem; }"
          end
        end

        # Generate CSS for counter classes
        private def generate_counter_css(css_class : String) : String?
          case css_class
          when "counter"
            ".counter { display: inline-flex; align-items: center; gap: 0.5rem; }"
          when "count-display"
            ".count-display { min-width: 2rem; text-align: center; font-weight: bold; }"
          when "counter-interactive"
            ".counter-interactive:focus { outline: 2px solid #007bff; outline-offset: 2px; }"
          end
        end

        # Generate CSS for toggle classes
        private def generate_toggle_css(css_class : String) : String?
          case css_class
          when "toggle"
            ".toggle { display: inline-block; }"
          when "toggle-button"
            ".toggle-button { appearance: none; width: 3rem; height: 1.5rem; background: #ccc; border-radius: 1rem; border: none; cursor: pointer; position: relative; transition: background 0.2s; }"
          when "toggle-on"
            ".toggle-on { background: #007bff; }"
          when "toggle-interactive"
            ".toggle-interactive:focus { outline: 2px solid #007bff; outline-offset: 2px; }"
          end
        end

        # Generate CSS for dropdown classes  
        private def generate_dropdown_css(css_class : String) : String?
          case css_class
          when "dropdown"
            ".dropdown { position: relative; display: inline-block; }"
          when "dropdown-menu"
            ".dropdown-menu { position: absolute; top: 100%; left: 0; z-index: 1000; min-width: 10rem; padding: 0.5rem 0; background: #fff; border: 1px solid #ccc; border-radius: 0.25rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075); display: none; }"
          when "dropdown-menu-open"
            ".dropdown-menu-open { display: block; }"
          when "dropdown-item"
            ".dropdown-item { display: block; width: 100%; padding: 0.25rem 1rem; color: #212529; text-decoration: none; background: transparent; border: 0; cursor: pointer; }"
          when "dropdown-item-focused"
            ".dropdown-item-focused { background: #f8f9fa; }"
          end
        end

        # Simple JavaScript minification (remove comments and extra whitespace)
        def minify_javascript(js : String) : String
          # Remove single-line comments (// style)
          js = js.gsub(/\/\/.*$/m, "")
          # Remove multi-line comments (/* style */)
          js = js.gsub(/\/\*.*?\*\//m, "")
          # Remove extra whitespace and newlines
          js = js.gsub(/\s+/, " ")
          # Remove leading/trailing whitespace
          js.strip
        end

        # Simple CSS minification (remove comments and extra whitespace)
        private def minify_css(css : String) : String
          # Remove comments
          css = css.gsub(/\/\*.*?\*\//m, "")
          # Remove extra whitespace
          css = css.gsub(/\s+/, " ")
          # Remove whitespace around specific characters
          css = css.gsub(/\s*([{}:;,])\s*/, "\\1")
          # Remove leading/trailing whitespace
          css.strip
        end

        # Ensure output directory exists
        private def ensure_output_directory_exists
          Dir.mkdir_p(@output_dir) unless Dir.exists?(@output_dir)
        end

        # Get statistics about generated assets
        def get_stats : Hash(String, Int32 | String)
          js_size = File.exists?(@js_output_path) ? File.size(@js_output_path) : 0
          css_size = File.exists?(@css_output_path) ? File.size(@css_output_path) : 0
          
          {
            "total_js_size" => js_size.to_i,
            "total_css_size" => css_size.to_i,
            "total_size" => (js_size + css_size).to_i,
            "javascript_path" => @js_output_path,
            "css_path" => @css_output_path,
            "used_css_classes" => @component_registry.all_used_classes.size,
            "component_types" => @component_registry.component_classes.size
          }
        end

        # Generate manifest file for asset fingerprinting
        def generate_manifest(fingerprint : Bool = true) : Hash(String, String)
          manifest = {} of String => String
          
          # Check for JavaScript files (components.js or similar)
          if File.exists?(@js_output_path)
            js_filename = fingerprint ? add_fingerprint(@js_output_path) : File.basename(@js_output_path)
            manifest["js_bundle"] = js_filename
          end
          
          # Check for CSS files - look for any component CSS files
          css_candidates = [
            @css_output_path,  # components.css
            File.join(File.dirname(@css_output_path), "components-optimized.css"),  # from optimizer
            File.join(File.dirname(@css_output_path), "components.min.css")  # minified version
          ]
          
          css_candidates.each do |css_path|
            if File.exists?(css_path)
              css_filename = fingerprint ? add_fingerprint(css_path) : File.basename(css_path)
              manifest["css_bundle"] = css_filename
              break
            end
          end
          
          manifest
        end

        # Add fingerprint to filename based on content hash
        private def add_fingerprint(file_path : String) : String
          content = File.read(file_path)
          hash = Digest::SHA256.hexdigest(content)[0..7]
          
          dir = File.dirname(file_path)
          basename = File.basename(file_path, File.extname(file_path))
          extension = File.extname(file_path)
          
          fingerprinted_filename = "#{basename}-#{hash}#{extension}"
          fingerprinted_path = File.join(dir, fingerprinted_filename)
          
          # Copy file with fingerprinted name
          File.copy(file_path, fingerprinted_path)
          
          fingerprinted_filename
        end
      end
    end
  end
end 