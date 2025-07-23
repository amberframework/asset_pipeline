module AssetPipeline
  # The `ScriptRenderer` handles framework-agnostic JavaScript script generation and rendering.
  # It provides basic functionality for generating import statements and wrapping custom JavaScript
  # initialization blocks in proper module script tags.
  #
  # This class serves as the foundation for framework-specific renderers like StimulusRenderer.
  class ScriptRenderer
    @import_map : ImportMap
    @custom_javascript_block : String

    # Initialize the ScriptRenderer with an import map and optional custom JavaScript block
    #
    # ```
    # renderer = ScriptRenderer.new(import_map, "console.log('initialized');")
    # ```
    def initialize(@import_map : ImportMap, @custom_javascript_block : String = "")
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
  end
end 