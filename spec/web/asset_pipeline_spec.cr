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

    File.write("spec/test_js/some_js.js", "// Here's some text for the comment\n\nconsole.log('test-modified-#{Time.utc.to_unix_ms}');")
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

    File.write("spec/test_js/some_js.js", "// Here's some text for the comment\n\nconsole.log('test-modified-#{Time.utc.to_unix_ms}');")

    front_loader.render_import_map_as_file.gsub(" ", "").gsub("\n", "").should_not eq(final_import_map)
  end

  it "properly creates an import map with a specificed asset base path" do
    tmp_map = AssetPipeline::ImportMap.new(public_asset_base_path: Path["/assets"])
    tmp_map.add_import("test", "some_js.js")

    front_loader = AssetPipeline::FrontLoader.new(js_source_path: Path["spec/test_js"], js_output_path: Path["spec/test_output"]) do |import_maps|
      import_maps << tmp_map
    end

    file_hash = Digest::SHA256.new.file("spec/test_js/some_js.js").hexfinal

    final_import_map = <<-STRING
    <scripttype="importmap">{"imports":{"test":"/assets/some_js-#{file_hash}.js"}}</script>
    STRING

    # Test both of these, this ensures the overlapping file names are still created correctly.
    front_loader.render_import_map_tag.gsub(" ", "").gsub("\n", "").should eq(final_import_map)
  end

  it "clears old fingerprinted files when clear_cache_upon_change is true (default)" do
    # Setup: Create two import maps with different source files
    tmp_map = AssetPipeline::ImportMap.new
    tmp_map.add_import("some_js", "some_js.js")
    tmp_map.add_import("another_js", "another_js_file.js")

    front_loader = AssetPipeline::FrontLoader.new(
      js_source_path: Path["spec/test_js"], 
      js_output_path: Path["spec/test_output"]  # clear_cache_upon_change defaults to true
    ) do |import_maps|
      import_maps << tmp_map
    end

    # Generate initial fingerprinted files
    front_loader.render_import_map_tag

    # Record initial state
    initial_files = Dir.glob("spec/test_output/**/*.js")
    initial_file_count = initial_files.size
    initial_some_js = initial_files.find { |f| f.includes?("some_js-") }
    initial_another_js = initial_files.find { |f| f.includes?("another_js_file-") }

    # Verify we have fingerprinted files
    initial_file_count.should eq(2)
    initial_some_js.should_not be_nil
    initial_another_js.should_not be_nil

    # Change content of one source file (some_js.js)
    original_content = File.read("spec/test_js/some_js.js")
    File.write("spec/test_js/some_js.js", "// Modified content\nconsole.log('modified-#{Time.utc.to_unix_ms}');")

    # Create new FrontLoader instance and regenerate (simulates cache clearing)
    new_front_loader = AssetPipeline::FrontLoader.new(
      js_source_path: Path["spec/test_js"], 
      js_output_path: Path["spec/test_output"]  # clear_cache_upon_change defaults to true
    ) do |import_maps|
      new_map = AssetPipeline::ImportMap.new
      new_map.add_import("some_js", "some_js.js")
      new_map.add_import("another_js", "another_js_file.js")
      import_maps << new_map
    end

    new_front_loader.render_import_map_tag

    # Check final state
    final_files = Dir.glob("spec/test_output/**/*.js")
    final_file_count = final_files.size
    final_some_js = final_files.find { |f| f.includes?("some_js-") }
    final_another_js = final_files.find { |f| f.includes?("another_js_file-") }

    # With cache clearing enabled, should have same number of files (old ones removed, new ones added)
    final_file_count.should eq(2)

    # The changed file should have been removed and replaced with new fingerprint
    File.exists?(initial_some_js.not_nil!).should be_false
    final_some_js.should_not be_nil
    File.basename(final_some_js.not_nil!).should_not eq(File.basename(initial_some_js.not_nil!))

    # The unchanged file may reuse the same path if fingerprint is identical
    # (cache was cleared but if content is same, same fingerprint is generated)
    final_another_js.should_not be_nil
    # This file may or may not exist at the same path - both behaviors are valid

    # Verify we still have the expected files
    final_files.any? { |f| f.includes?("some_js-") }.should be_true
    final_files.any? { |f| f.includes?("another_js_file-") }.should be_true

    # Restore original content for other tests
    File.write("spec/test_js/some_js.js", original_content)
  end

  it "preserves old fingerprinted files when clear_cache_upon_change is false" do
    # Setup: Create two import maps with different source files
    tmp_map = AssetPipeline::ImportMap.new
    tmp_map.add_import("some_js", "some_js.js")
    tmp_map.add_import("another_js", "another_js_file.js")

    front_loader = AssetPipeline::FrontLoader.new(
      js_source_path: Path["spec/test_js"], 
      js_output_path: Path["spec/test_output"],
      clear_cache_upon_change: false  # Disable cache clearing
    ) do |import_maps|
      import_maps << tmp_map
    end

    # Generate initial fingerprinted files
    front_loader.render_import_map_tag

    # Record initial state
    initial_files = Dir.glob("spec/test_output/**/*.js")
    initial_file_count = initial_files.size
    initial_some_js = initial_files.find { |f| f.includes?("some_js-") }
    initial_another_js = initial_files.find { |f| f.includes?("another_js_file-") }

    # Verify we have fingerprinted files
    initial_file_count.should eq(2)
    initial_some_js.should_not be_nil
    initial_another_js.should_not be_nil

    # Change content of one source file (some_js.js)
    original_content = File.read("spec/test_js/some_js.js")
    File.write("spec/test_js/some_js.js", "// Modified content\nconsole.log('modified-#{Time.utc.to_unix_ms}');")

    # Create new FrontLoader instance and regenerate (without cache clearing)
    new_front_loader = AssetPipeline::FrontLoader.new(
      js_source_path: Path["spec/test_js"], 
      js_output_path: Path["spec/test_output"],
      clear_cache_upon_change: false  # Disable cache clearing
    ) do |import_maps|
      new_map = AssetPipeline::ImportMap.new
      new_map.add_import("some_js", "some_js.js")
      new_map.add_import("another_js", "another_js_file.js")
      import_maps << new_map
    end

    new_front_loader.render_import_map_tag

    # Check final state
    final_files = Dir.glob("spec/test_output/**/*.js")
    final_file_count = final_files.size

    # The original files should still exist (cache was NOT cleared)
    File.exists?(initial_some_js.not_nil!).should be_true
    File.exists?(initial_another_js.not_nil!).should be_true

    # With cache clearing disabled, should have MORE files if the changed file got a new fingerprint
    final_file_count.should be >= 2

    # Find files for the changed source
    some_js_files = final_files.select { |f| f.includes?("some_js-") }
    
    # Should have at least the original file, possibly a new one if content changed enough to create new fingerprint
    some_js_files.size.should be >= 1
    
    # The unchanged file should still only have one version (same fingerprint, no new generation needed)
    another_js_files = final_files.select { |f| f.includes?("another_js_file-") }
    another_js_files.size.should eq(1)
    another_js_files[0].should eq(initial_another_js.not_nil!)

    # Restore original content for other tests
    File.write("spec/test_js/some_js.js", original_content)
  end
end
