require "import_map/import_map"

# TODO: Write documentation for `AssetPipeline`
class AssetPipeline
  VERSION = "0.1.0"

  @import_maps : Array(AssetPipeline::ImportMap) = [] of AssetPipeline::ImportMap

  def initialize(@import_maps : Array(AssetPipeline::ImportMap))
  end

  # Initialize the asset pipeline with the given *block*.
  #
  # The block is the import maps that will be used by the asset pipeline.
  def initialize(&block)
    yield @import_maps
  end

  # Gets the import map with the given *name*.
  #
  # Default name is "application".
  def get_import_map(name : String = "application")
    @import_maps.find { |import_map| import_map.name == name }
  end
end
