require "../spec_helper"
require "../../src/import_map/import_map"

describe AssetPipeline::ImportMap do
  it "generates an import map correctly" do
    import_map = AssetPipeline::ImportMap.new

    import_map.add_import("test", "test.js")

    expected_response = <<-STRING
    <scripttype="importmap">{"imports":{"test":"/test.js"}}</script>
    STRING
    import_map.build_import_map_tag.gsub(" ", "").gsub("\n", "").should eq(expected_response)
  end

  it "generates an import map with multiple imports correctly" do
    import_map = AssetPipeline::ImportMap.new

    import_map.add_import("test", "test.js")
    import_map.add_import("test2", "test2.js")

    expected_response = <<-STRING
    <scripttype="importmap">{"imports":{"test":"/test.js","test2":"/test2.js"}}</script>
    STRING
    import_map.build_import_map_tag.gsub(" ", "").gsub("\n", "").should eq(expected_response)
  end

  it "generates an import map with a mix of preload and regular imports correctly" do
    import_map = AssetPipeline::ImportMap.new

    import_map.add_import("test", "test.js", preload: true)
    import_map.add_import("test2", "test2.js")

    expected_response = <<-STRING
    <scripttype="importmap">{"imports":{"test":"/test.js","test2":"/test2.js"}}</script><linkrel="modulepreload"href="test.js">
    STRING
    import_map.build_import_map_tag.gsub(" ", "").gsub("\n", "").should eq(expected_response)
  end

  it "generates scopes correctly" do
    import_map = AssetPipeline::ImportMap.new

    import_map.add_scope("/test", "blah", "test.js")

    expected_response = <<-STRING
    <scripttype="importmap">{"imports":{},"scopes":{"/test":{"blah":"test.js"}}}</script>
    STRING
    import_map.build_import_map_tag.gsub(" ", "").gsub("\n", "").should eq(expected_response)
  end

  it "raises an error when an invalid scope is added" do
    import_map = AssetPipeline::ImportMap.new
    expect_raises(Exception, "Scope key must start with `/`, `./`, or `../`") do
      import_map.add_scope("test", "blah", "test.js")
    end
  end
end
