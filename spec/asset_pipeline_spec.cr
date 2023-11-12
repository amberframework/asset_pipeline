require "./spec_helper"
require "file_utils"

describe AssetPipeline::FrontLoader do
  Spec.after_each do
    FileUtils.rm_r(Dir.glob("spec/test_output/**/*.js"))
  end

  it "registers the default import map" do
    front_loader = AssetPipeline::FrontLoader.new
    front_loader.import_maps << AssetPipeline::ImportMap.new
    front_loader.get_import_map().name.should eq("application")
  end

  it "registers multiple import_maps" do
    front_loader = AssetPipeline::FrontLoader.new
    front_loader.import_maps << AssetPipeline::ImportMap.new
    front_loader.import_maps << AssetPipeline::ImportMap.new(name: "test")
    front_loader.get_import_map().name.should eq("application")
    front_loader.get_import_map("test").name.should eq("test")
  end

  it "accepts a block and properly adds all ImportMaps from the block" do
    front_loader = AssetPipeline::FrontLoader.new do |import_maps|
      import_maps << AssetPipeline::ImportMap.new(name: "test")
      import_maps << AssetPipeline::ImportMap.new(name: "test2")
    end

    front_loader.get_import_map("test").name.should eq("test")
    front_loader.get_import_map("test2").name.should eq("test2")
  end

  it "properly renders an import map from the FrontLoader" do
    tmp_map = AssetPipeline::ImportMap.new(name: "test")
    tmp_map.add_import("test", "some_js.js")

    tmp_map2 = AssetPipeline::ImportMap.new
    tmp_map2.add_import("test", "subfolder/second_sub_folder/second_nested_file.js")

    front_loader = AssetPipeline::FrontLoader.new(js_source_path: Path["spec/test_js"], js_output_path: Path["spec/test_output"]) do |import_maps|
      import_maps << tmp_map
      import_maps << tmp_map2
    end

    final_import_map = <<-STRING
    <scripttype="importmap">{"imports":{"test":"./some_js.js"}}</script>
    STRING

    final_import_map2 = <<-STRING
    <scripttype="importmap">{"imports":{"test":"./subfolder/second_sub_folder/second_nested_file.js"}}</script>
    STRING

    front_loader.render_import_map_tag("test").gsub(" ", "").gsub("\n", "").should eq(final_import_map)
    front_loader.render_import_map_tag().gsub(" ", "").gsub("\n", "").should eq(final_import_map2)
  end
end
