require "digest/sha256"
require "file_utils"
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
    @js_source_path : Path
    @js_output_path : Path

    # The default initializer for the `FrontLoader` class.
    def initialize(@js_source_path : Path = Path.new("src/app/javascript"), @js_output_path : Path = Path.new("public/assets"), @import_maps : Array(ImportMap) = [] of ImportMap)
      @import_maps << AssetPipeline::ImportMap.new("application") if @import_maps.empty?
    end

    def initialize(@js_source_path : Path = Path.new("src/app/javascript"), @js_output_path : Path = Path.new("public/assets"), import_map : ImportMap = ImportMap.new)
      
      @import_maps << import_map
    end

    # Initialize the asset pipeline with the given *block*.
    #
    # The block is the import maps that will be used by the asset pipeline.
    def initialize(@js_source_path : Path = Path.new("src/app/javascript"), @js_output_path : Path = Path.new("public/assets"), &block)
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

    # TODO: Make this a private def once done building
    # :nodoc:
    def generate_file_version_hash(import_map_name : String = "application")
      file_hashes = Hash(String, String).new
      target_import_map = get_import_map(import_map_name)

      Dir.glob("#{@js_source_path}/**/*.js").each do |file|
        file_hash = Digest::SHA256.new.file(file).hexfinal
        file_index = file.index('.') || next
        cached_file_name = file.insert(file_index, "-"+file_hash).gsub(@js_source_path.to_s, @js_output_path.to_s)
        puts "File basename: " + File.basename(file)
        found_index = target_import_map.imports.index { |r| r.first_value.to_s.includes?(File.basename(file)) }
        puts "Globbed a file named: " + file
        puts "found index: #{found_index}"

        if !found_index.nil? && !File.exists?(cached_file_name)
          puts "Cached file name: " + cached_file_name
          FileUtils.cp_r(file, cached_file_name)
          first_key = target_import_map.imports[found_index].first_key
          target_import_map.imports[found_index][first_key] = cached_file_name.gsub(@js_output_path.to_s, "./")
        end
      end
    end
  end
end
