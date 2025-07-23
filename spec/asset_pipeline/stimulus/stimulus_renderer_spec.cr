require "../../spec_helper"
require "../../../src/asset_pipeline/stimulus/stimulus_renderer"

describe AssetPipeline::Stimulus::StimulusRenderer do
  describe "#initialize" do
    it "initializes with import map, custom JavaScript, and application name" do
      import_map = AssetPipeline::ImportMap.new
      custom_js = "console.log('test');"
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js, "myapp")
      
      renderer.should be_a(AssetPipeline::Stimulus::StimulusRenderer)
    end

    it "defaults to 'application' as application name" do
      import_map = AssetPipeline::ImportMap.new
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      
      renderer.should be_a(AssetPipeline::Stimulus::StimulusRenderer)
    end

    it "extracts controller names from custom JavaScript block during initialization" do
      import_map = AssetPipeline::ImportMap.new
      custom_js = <<-JS
        import HelloController from "hello_controller";
        Stimulus.register("hello", HelloController);
      JS
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      
      # Controller detection should happen during initialization
      renderer.should be_a(AssetPipeline::Stimulus::StimulusRenderer)
    end
  end

  describe "#render_stimulus_initialization_script" do
    it "renders basic Stimulus script with no controllers" do
      import_map = AssetPipeline::ImportMap.new
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      
      result = renderer.render_stimulus_initialization_script
      
      result.should contain("import { Application } from \"@hotwired/stimulus\";")
      result.should contain("const application = Application.start();")
      result.should contain("<script type=\"module\">")
      result.should contain("</script>")
    end

    it "renders Stimulus script with controller from import map" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      
      result = renderer.render_stimulus_initialization_script
      
      result.should contain("import { Application } from \"@hotwired/stimulus\";")
      result.should contain("import HelloController from \"HelloController\";")
      result.should contain("const application = Application.start();")
      result.should contain("application.register(\"hello\", HelloController);")
    end

    it "renders Stimulus script with multiple controllers" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      import_map.add_import("ModalController", "modal_controller.js")
      import_map.add_import("ToggleController", "toggle_controller.js")
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      
      result = renderer.render_stimulus_initialization_script
      
      result.should contain("import HelloController from \"HelloController\";")
      result.should contain("import ModalController from \"ModalController\";")
      result.should contain("import ToggleController from \"ToggleController\";")
      result.should contain("application.register(\"hello\", HelloController);")
      result.should contain("application.register(\"modal\", ModalController);")
      result.should contain("application.register(\"toggle\", ToggleController);")
    end

    it "renders Stimulus script with custom application name" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, "", "myapp")
      
      result = renderer.render_stimulus_initialization_script
      
      result.should contain("const myapp = Application.start();")
      result.should contain("myapp.register(\"hello\", HelloController);")
    end

    it "renders Stimulus script with custom JavaScript block" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      custom_js = "console.log('Custom initialization code');"
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      
      result = renderer.render_stimulus_initialization_script
      
      result.should contain("console.log('Custom initialization code');")
      result.should contain("application.register(\"hello\", HelloController);")
    end
  end

  describe "#generate_stimulus_script_content" do
    it "generates complete Stimulus script content in correct order" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      custom_js = "console.log('Ready!');"
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      
      result = renderer.generate_stimulus_script_content
      parts = result.split("\n\n")
      
      # Should have 4 parts: stimulus import, controller import, app setup, custom js, registrations
      parts.size.should be >= 3
      parts[0].should contain("import { Application } from \"@hotwired/stimulus\";")
      result.should contain("import HelloController from \"HelloController\";")
      result.should contain("const application = Application.start();")
      result.should contain("console.log('Ready!');")
      result.should contain("application.register(\"hello\", HelloController);")
    end
  end

  describe "#process_custom_javascript_block" do
    it "removes duplicate import statements" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      
      custom_js = <<-JS
        import HelloController from "hello_controller";
        console.log('Custom code');
        HelloController.doSomething();
      JS
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      result = renderer.generate_stimulus_script_content
      
      # Should only have one import statement for HelloController
      import_count = result.scan(/import HelloController/).size
      import_count.should eq(1)
      result.should contain("console.log('Custom code');")
      result.should contain("HelloController.doSomething();")
    end

    it "removes duplicate Stimulus.register statements" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      
      custom_js = <<-JS
        Stimulus.register("hello", HelloController);
        console.log('Custom code');
      JS
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      result = renderer.generate_stimulus_script_content
      
      # Should only have one registration
      register_count = result.scan(/register.*hello.*HelloController/).size
      register_count.should eq(1)
      result.should contain("console.log('Custom code');")
    end

    it "removes Application.start() statements" do
      import_map = AssetPipeline::ImportMap.new
      
      custom_js = <<-JS
        Application.start();
        application.start();
        console.log('Custom code');
      JS
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      result = renderer.generate_stimulus_script_content
      
      # Should only have one Application.start() from our renderer
      start_count = result.scan(/Application\.start\(\)/).size
      start_count.should eq(1)
      result.should contain("console.log('Custom code');")
    end
  end

  describe "controller detection" do
    it "detects controllers from import map entries ending in 'Controller'" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      import_map.add_import("ModalController", "modal_controller.js")
      import_map.add_import("UtilityClass", "utility.js")  # Should not be detected as controller
      import_map.add_import("helper", "helper.js")
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      result = renderer.generate_stimulus_script_content
      
      result.should contain("import HelloController from \"HelloController\";")
      result.should contain("import ModalController from \"ModalController\";")
      result.should_not contain("import UtilityClass from")  # Not a controller
      result.should_not contain("import helper from")
    end

    it "detects controllers from Stimulus.register patterns in custom JS" do
      import_map = AssetPipeline::ImportMap.new
      
      custom_js = <<-JS
        Stimulus.register("custom", CustomController);
        Stimulus.register("another", AnotherController);
        console.log('test');
      JS
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      result = renderer.generate_stimulus_script_content
      
      result.should contain("application.register(\"custom\", CustomController);")
      result.should contain("application.register(\"another\", AnotherController);")
    end

    it "detects controllers from import statements in custom JS" do
      import_map = AssetPipeline::ImportMap.new
      
      custom_js = <<-JS
        import MyController from "my_controller";
        import AnotherController from "another_controller";
        import someUtility from "utility";
      JS
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, custom_js)
      result = renderer.generate_stimulus_script_content
      
      result.should contain("application.register(\"my\", MyController);")
      result.should contain("application.register(\"another\", AnotherController);")
      result.should_not contain("register.*someUtility")
    end
  end

  describe "controller name conversion" do
    it "converts PascalCase controller names to kebab-case identifiers" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      import_map.add_import("MySpecialController", "my_special_controller.js")
      import_map.add_import("HTMLElementController", "html_element_controller.js")
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      result = renderer.generate_stimulus_script_content
      
      result.should contain("application.register(\"hello\", HelloController);")
      result.should contain("application.register(\"my-special\", MySpecialController);")
      result.should contain("application.register(\"h-t-m-l-element\", HTMLElementController);")
    end

    it "handles single word controllers" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("ModalController", "modal_controller.js")
      import_map.add_import("ToggleController", "toggle_controller.js")
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      result = renderer.generate_stimulus_script_content
      
      result.should contain("application.register(\"modal\", ModalController);")
      result.should contain("application.register(\"toggle\", ToggleController);")
    end
  end

  describe "mixed imports and controllers" do
    it "handles controllers alongside regular imports" do
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("HelloController", "hello_controller.js")
      import_map.add_import("lodash", "lodash.js")
      import_map.add_import("stimulus", "@hotwired/stimulus")
      import_map.add_import("ModalController", "modal_controller.js")
      
      renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map)
      result = renderer.generate_stimulus_script_content
      
      # Should have Stimulus core import
      result.should contain("import { Application } from \"@hotwired/stimulus\";")
      
      # Should have controller imports
      result.should contain("import HelloController from \"HelloController\";")
      result.should contain("import ModalController from \"ModalController\";")
      
      # Should NOT have regular imports in controller section (they're not controllers)
      controller_section = result.split("const application = Application.start();")[0]
      controller_section.should_not contain("import lodash")
      controller_section.should_not contain("import stimulus")
      
      # Should have controller registrations
      result.should contain("application.register(\"hello\", HelloController);")
      result.should contain("application.register(\"modal\", ModalController);")
    end
  end
end 