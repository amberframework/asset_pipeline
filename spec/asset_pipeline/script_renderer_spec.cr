require "../spec_helper"
require "../../src/asset_pipeline/script_renderer"

describe AssetPipeline::ScriptRenderer do
  describe "#initialize" do
    it "initializes with import map and custom JavaScript block" do
      import_map = AssetPipeline::ImportMap.new
      custom_js = "console.log('test');"
      
      renderer = AssetPipeline::ScriptRenderer.new(import_map, custom_js)
      
      renderer.should be_a(AssetPipeline::ScriptRenderer)
    end

    it "initializes with empty custom JavaScript block by default" do
      import_map = AssetPipeline::ImportMap.new
      
      renderer = AssetPipeline::ScriptRenderer.new(import_map)
      
      renderer.should be_a(AssetPipeline::ScriptRenderer)
    end
  end

  describe "#render_initialization_script" do
    it "renders empty script tag for empty import map and no custom JS" do
      import_map = AssetPipeline::ImportMap.new
      renderer = AssetPipeline::ScriptRenderer.new(import_map)
      
      result = renderer.render_initialization_script
      
      result.should eq("")
    end

    it "renders script tag with only custom JavaScript when no imports" do
      import_map = AssetPipeline::ImportMap.new
      custom_js = "console.log('Hello World');"
      renderer = AssetPipeline::ScriptRenderer.new(import_map, custom_js)
      
      result = renderer.render_initialization_script
      
      expected = <<-HTML
      <script type="module">
      console.log('Hello World');
      </script>
      HTML
      
      result.strip.should eq(expected.strip)
    end

    it "renders script tag with imports and custom JavaScript" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("TestClass", "test-class.js")
      import_map.add_import("utility", "utility.js")
      
      custom_js = "console.log('Initialized');"
      renderer = AssetPipeline::ScriptRenderer.new(import_map, custom_js)
      
      result = renderer.render_initialization_script
      
      result.should contain("import TestClass from \"TestClass\";")
      result.should contain("import \"utility\";")
      result.should contain("console.log('Initialized');")
      result.should contain("<script type=\"module\">")
      result.should contain("</script>")
    end
  end

  describe "#generate_script_content" do
    it "generates import statements for default imports (capitalized names)" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      import_map.add_import("TestClass", "test_class.js")
      
      renderer = AssetPipeline::ScriptRenderer.new(import_map)
      
      result = renderer.generate_script_content
      
      result.should contain("import HelloController from \"HelloController\";")
      result.should contain("import TestClass from \"TestClass\";")
    end

    it "generates bare imports for non-capitalized names" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("lodash", "lodash.js")
      import_map.add_import("utility", "utility.js")
      
      renderer = AssetPipeline::ScriptRenderer.new(import_map)
      
      result = renderer.generate_script_content
      
      result.should contain("import \"lodash\";")
      result.should contain("import \"utility\";")
    end

    it "combines imports and custom JavaScript with proper spacing" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("TestClass", "test.js")
      
      custom_js = "TestClass.init();"
      renderer = AssetPipeline::ScriptRenderer.new(import_map, custom_js)
      
      result = renderer.generate_script_content
      
      # Should have import, double newline, then custom JS
      expected_parts = [
        "import TestClass from \"TestClass\";",
        "TestClass.init();"
      ]
      
      result.should contain(expected_parts[0])
      result.should contain(expected_parts[1])
      result.split("\n\n").size.should eq(2)
    end
  end

  describe "#process_custom_javascript_block" do
    it "strips whitespace from custom JavaScript block" do
      import_map = AssetPipeline::ImportMap.new
      custom_js = "  \n  console.log('test');  \n  "
      renderer = AssetPipeline::ScriptRenderer.new(import_map, custom_js)
      
      # Access protected method via generate_script_content
      result = renderer.generate_script_content
      
      result.should eq("console.log('test');")
    end

    it "handles empty custom JavaScript block" do
      import_map = AssetPipeline::ImportMap.new
      renderer = AssetPipeline::ScriptRenderer.new(import_map, "")
      
      result = renderer.generate_script_content
      
      result.should eq("")
    end
  end

  describe "import name detection" do
    it "detects capitalized names as default imports" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello.js")
      import_map.add_import("MyClass", "my-class.js")
      import_map.add_import("Component", "component.js")
      
      renderer = AssetPipeline::ScriptRenderer.new(import_map)
      result = renderer.generate_script_content
      
      result.should contain("import HelloController from \"HelloController\";")
      result.should contain("import MyClass from \"MyClass\";")
      result.should contain("import Component from \"Component\";")
    end

    it "detects lowercase names as bare imports" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("lodash", "lodash.js")
      import_map.add_import("stimulus", "stimulus.js")
      import_map.add_import("my-utility", "my-utility.js")
      
      renderer = AssetPipeline::ScriptRenderer.new(import_map)
      result = renderer.generate_script_content
      
      result.should contain("import \"lodash\";")
      result.should contain("import \"stimulus\";")
      result.should contain("import \"my-utility\";")
    end

    it "handles mixed case names correctly" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("jQuery", "jquery.js")      # Default import
      import_map.add_import("jquery", "jquery-alt.js")  # Bare import
      import_map.add_import("Vue", "vue.js")            # Default import
      import_map.add_import("vue-router", "vue-router.js") # Bare import
      
      renderer = AssetPipeline::ScriptRenderer.new(import_map)
      result = renderer.generate_script_content
      
      result.should contain("import jQuery from \"jQuery\";")
      result.should contain("import \"jquery\";")
      result.should contain("import Vue from \"Vue\";")
      result.should contain("import \"vue-router\";")
    end
  end
end 