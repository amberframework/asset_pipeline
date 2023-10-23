module AssetPipeline
  class ImportMap
    property name : String
    @import_map : Array(Hash(String, String | Bool)) = [] of Hash(String, String | Bool)
    @scopes : Hash(String, Array(Hash(String, String))) = Hash(String, Array(Hash(String, String))).new { |hash, key| hash[key] = [] of Hash(String, String) }
    @import_tag = ""

    # Give your importmap a *name*.
    #
    # Default: application
    def initialize(@name = "application")
    end

    # This renders the complete HTML tag for the import map.
    def build_import_map : String
      @import_tag = <<-STRING
            <script type="importmap">
              { 
                "imports": 
                {
        STRING

      @import_tag += create_map_list_as_string + " }"

      if @scopes.any?
        @import_tag += ",\n \"scopes\": {" + create_scope_list_as_string + " }"
      end

      @import_tag += "} \n</script>"
      @import_tag
    end

    # Name the library you want to incude in the import map.
    #
    # ```
    # import("lodash", "https://cdn.jsdelivr.net/npm/lodash/lodash.min.js")
    # ```
    #
    # `preload` will mark the module to be eager loaded by the browser.
    #
    # The *name* should match the way you import a library in your JS code.
    #
    def add_import(name : String, to : String, preload : Bool = false)
      @import_map << {name => to, "preload" => preload}
    end

    def add_scope(scope : String, name : String, to : String)
      raise "Scope key must start with `/`, `./`, or `../`" unless scope.starts_with?(/\/|\.\/|\.\.\//)
      @scopes[scope] << {name => to}
    end

    # Import all of the js files from a directory.
    #
    # The path to the directory must be relative to the project root.
    #
    # ```
    #  import_all_from("./src/js", "https://cdn.jsdelivr.net/npm/lodash/lodash.min.js")
    # ```
    def import_all_from(directory : String, to : String, preload : Bool = false)
    end

    # :nodoc:
    private def create_map_list_as_string
      final_string = ""

      @import_map.each_with_index do |import, index|
        if import["preload"]
          final_string += "\"#{import.first_key}\": { \"from\": \"#{import.first_value}\", \"preload\": true }"
        else
          final_string += "\"#{import.first_key}\": \"#{import.first_value}\""
        end

        final_string += ",\n" unless index + 1 == @import_map.size
      end

      final_string
    end

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
