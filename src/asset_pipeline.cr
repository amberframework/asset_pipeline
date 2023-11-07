require "./import_map/import_map"

# TODO: Write documentation for `AssetPipeline`
module AssetPipeline
  VERSION = "0.34.0"

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
  # import_map.add_import("someClass", "./your_file.js")
  # front_loader.render_import_map_tag # Generates the import map tag and any module preload directives
  # ```
  #
  # You can also specify the name of your import map by initializing the with an import map
  #
  # ```
  # front_loader = AssetPipeline::FrontLoader.new(import_map: AssetPipeline::ImportMap.new(name: "my_import_map"))
  # import_map = front_loader.get_import_map("my_import_map") # You must specify the import map by the name you created
  # import_map.add_import("someClass", "./your_file.js")
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
  # front_loader.render_import_map_tag # Renders the import_map1 using the default "application" name
  # front_loader.render_import_map_tag("admin_area") # Renders the import_map2. Tip: only 1 import map should be on a page
  # ```
  #
  # Read more about the `ImportMap` class to know all of your options, including the 'preload' and 'scope' feature.
  #
  class FrontLoader

    property import_maps : Array(ImportMap) = [] of ImportMap
    @javascript_source_path : Path = Path.new("src/app/javascript")

    # The default initializer for the `FrontLoader` class.
    def initialize(@javascript_source_path : Path = Path.new("src/app/javascript"), @import_maps : Array(ImportMap) = [] of ImportMap)
      @import_maps << AssetPipeline::ImportMap.new("application") if @import_maps.empty?
    end

    def initialize(@javascript_source_path : Path = Path.new("src/app/javascript"), import_map : ImportMap = ImportMap.new)
      @import_maps << import_map
    end

    # Initialize the asset pipeline with the given *block*.
    #
    # The block is the import maps that will be used by the asset pipeline.
    def initialize(@javascript_source_path : Path = Path.new("src/app/javascript"), &block)
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
      get_import_map(name).build_import_map_tag
    end

  end
end
