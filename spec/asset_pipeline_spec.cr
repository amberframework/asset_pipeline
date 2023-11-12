require "./spec_helper"
require "file_utils"

describe AssetPipeline::FrontLoader do
  Spec.after_each do
    FileUtils.rm_rf("spec/test_output")
    FileUtils.mkdir("spec/test_output") unless File.exists?("spec/test_output")
  end

  it "registers the default import map" do
    front_loader = AssetPipeline::FrontLoader.new
    front_loader.import_maps << AssetPipeline::ImportMap.new
    front_loader.get_import_map.name.should eq("application")
  end

  it "registers multiple import_maps" do
    front_loader = AssetPipeline::FrontLoader.new
    front_loader.import_maps << AssetPipeline::ImportMap.new
    front_loader.import_maps << AssetPipeline::ImportMap.new(name: "test")
    front_loader.get_import_map.name.should eq("application")
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

    file_1_hash = Digest::SHA256.new.file("spec/test_js/some_js.js").hexfinal

    final_import_map = <<-STRING
    <scripttype="importmap">{"imports":{"test":"/some_js-#{file_1_hash}.js"}}</script>
    STRING

    file_2_hash = Digest::SHA256.new.file("spec/test_js/sub_folder/second_sub_folder/second_nested_file.js").hexfinal

    final_import_map2 = <<-STRING
    <scripttype="importmap">{"imports":{"test":"/sub_folder/second_sub_folder/second_nested_file-#{file_2_hash}.js"}}</script>
    STRING

    # Test both of these, this ensures the overlapping file names are still created correctly.
    front_loader.render_import_map_tag.gsub(" ", "").gsub("\n", "").should eq(final_import_map2)
    front_loader.render_import_map_tag("test").gsub(" ", "").gsub("\n", "").should eq(final_import_map)
  end

  it "Properly rerenders the import map with a new hash fingerprint when the contents change" do
    tmp_map = AssetPipeline::ImportMap.new
    tmp_map.add_import("test", "some_js.js")

    front_loader = AssetPipeline::FrontLoader.new(js_source_path: Path["spec/test_js"], js_output_path: Path["spec/test_output"]) do |import_maps|
      import_maps << tmp_map
    end

    file_hash = Digest::SHA256.new.file("spec/test_js/some_js.js").hexfinal

    final_import_map = <<-STRING
    <scripttype="importmap">{"imports":{"test":"/some_js-#{file_hash}.js"}}</script>
    STRING

    # Test both of these, this ensures the overlapping file names are still created correctly.
    front_loader.render_import_map_tag.gsub(" ", "").gsub("\n", "").should eq(final_import_map)

    File.write("spec/test_js/some_js.js", "// Here's some text for the comment\n\nconsole.log('test-#{Random.rand(10)}-#{Random.rand(10)}');")
    front_loader.render_import_map_tag.gsub(" ", "").gsub("\n", "").should_not eq(final_import_map)
  end

  it "property rerenders the import map src url when a dependency fingerprint changes" do
    tmp_map = AssetPipeline::ImportMap.new
    tmp_map.add_import("test", "some_js.js")

    front_loader = AssetPipeline::FrontLoader.new(js_source_path: Path["spec/test_js"], js_output_path: Path["spec/test_output"]) do |import_maps|
      import_maps << tmp_map
    end

    digest = Digest::SHA256.new
    front_loader.generate_file_version_hash
    file_contents = front_loader.get_import_map.build_import_map_json
    digest << file_contents

    final_import_map = <<-STRING
      <scripttype="importmap"src="/application-#{digest.hexfinal}.json"></script>
      STRING

    front_loader.render_import_map_as_file.gsub(" ", "").gsub("\n", "").should eq(final_import_map)

    File.write("spec/test_js/some_js.js", "// Here's some text for the comment\n\nconsole.log('test-#{Random.rand(10)}-#{Random.rand(10)}');")

    front_loader.render_import_map_as_file.gsub(" ", "").gsub("\n", "").should_not eq(final_import_map)
  end
end
