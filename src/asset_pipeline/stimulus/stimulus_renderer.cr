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
  class StimulusRenderer < AssetPipeline::ScriptRenderer
    @stimulus_controllers : Array(String) = [] of String
    @stimulus_application_name : String

    # Initialize the StimulusRenderer with an import map, custom JavaScript block, and application name
    #
    # ```
    # renderer = StimulusRenderer.new(import_map, "Stimulus.register('hello', HelloController);", "application")
    # ```
    def initialize(import_map : ImportMap, custom_javascript_block : String = "", @stimulus_application_name : String = "application")
      super(import_map, custom_javascript_block)
      @stimulus_controllers = extract_controller_names_from_javascript_block
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
      script_content = generate_stimulus_script_content
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

      # Get controller imports from import map entries that look like controllers
      @import_map.imports.each do |import_entry|
        import_name = import_entry.first_key
        
        if looks_like_stimulus_controller?(import_name)
          import_statements << "import #{import_name} from \"#{import_name}\";"
          @stimulus_controllers << import_name unless @stimulus_controllers.includes?(import_name)
        end
      end

      import_statements.join("\n")
    end

    # Generates Stimulus application setup
    private def generate_stimulus_application_setup : String
      "const #{@stimulus_application_name} = Application.start();"
    end

    # Generates controller registrations for all detected controllers
    private def generate_controller_registrations : String
      registrations = [] of String

      @stimulus_controllers.each do |controller_name|
        # Convert controller class name to stimulus identifier
        # e.g., "HelloController" becomes "hello"
        stimulus_id = controller_class_to_stimulus_id(controller_name)
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

    # Converts a controller class name to a Stimulus identifier
    # e.g., "HelloController" -> "hello", "MySpecialController" -> "my-special"
    private def controller_class_to_stimulus_id(controller_class : String) : String
      # Remove "Controller" suffix
      base_name = controller_class.chomp("Controller")
      
      # Convert from PascalCase to kebab-case
      base_name.gsub(/([A-Z])/, "-\\1").downcase.lstrip("-")
    end
  end
end 