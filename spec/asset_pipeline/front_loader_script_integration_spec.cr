require "../spec_helper"

describe AssetPipeline::FrontLoader do
  describe "script rendering integration" do
    describe "#render_initialization_script" do
      it "renders general JavaScript initialization script" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("TestClass", "test_class.js")
        import_map.add_import("utility", "utility.js")
        
        custom_js = "console.log('Application initialized');"
        
        result = front_loader.render_initialization_script(custom_js)
        
        result.should contain("<script type=\"module\">")
        result.should contain("</script>")
        result.should contain("import TestClass from \"TestClass\";")
        result.should contain("import \"utility\";")
        result.should contain("console.log('Application initialized');")
      end

      it "renders empty script when no imports or custom JS" do
        front_loader = AssetPipeline::FrontLoader.new
        
        result = front_loader.render_initialization_script
        
        result.should eq("")
      end

      it "works with named import maps" do
        front_loader = AssetPipeline::FrontLoader.new do |import_maps|
          test_map = AssetPipeline::ImportMap.new("admin")
          test_map.add_import("AdminClass", "admin.js")
          import_maps << test_map
        end
        
        custom_js = "AdminClass.init();"
        
        result = front_loader.render_initialization_script(custom_js, "admin")
        
        result.should contain("import AdminClass from \"AdminClass\";")
        result.should contain("AdminClass.init();")
      end

      it "raises error for non-existent import map" do
        front_loader = AssetPipeline::FrontLoader.new
        
        expect_raises(Exception, "Import map with name nonexistent not found") do
          front_loader.render_initialization_script("", "nonexistent")
        end
      end
    end

    describe "#render_stimulus_initialization_script" do
      it "renders Stimulus initialization script with auto-detected controllers" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("HelloController", "hello_controller.js")
        import_map.add_import("ModalController", "modal_controller.js")
        import_map.add_import("utility", "utility.js")  # Should be ignored
        
        custom_js = "console.log('Stimulus app ready!');"
        
        result = front_loader.render_stimulus_initialization_script(custom_js)
        
        result.should contain("<script type=\"module\">")
        result.should contain("</script>")
        result.should contain("import { Application } from \"@hotwired/stimulus\";")
        result.should contain("import HelloController from \"HelloController\";")
        result.should contain("import ModalController from \"ModalController\";")
        result.should_not contain("import utility")  # Non-controller should not be imported
        result.should contain("const application = Application.start();")
        result.should contain("application.register(\"hello\", HelloController);")
        result.should contain("application.register(\"modal\", ModalController);")
        result.should contain("console.log('Stimulus app ready!');")
      end

      it "renders basic Stimulus script with no controllers" do
        front_loader = AssetPipeline::FrontLoader.new
        
        result = front_loader.render_stimulus_initialization_script
        
        result.should contain("import { Application } from \"@hotwired/stimulus\";")
        result.should contain("const application = Application.start();")
        result.should_not contain("register(")
      end

      it "filters duplicate code from custom JavaScript block" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("HelloController", "hello_controller.js")
        
        custom_js = <<-JS
          import HelloController from "hello_controller";
          Application.start();
          Stimulus.register("hello", HelloController);
          console.log('Custom initialization');
          HelloController.setup();
        JS
        
        result = front_loader.render_stimulus_initialization_script(custom_js)
        
        # Should only have one import for HelloController (from auto-generation)
        import_count = result.scan(/import HelloController/).size
        import_count.should eq(1)
        
        # Should only have one Application.start() (from auto-generation)
        start_count = result.scan(/Application\.start\(\)/).size
        start_count.should eq(1)
        
        # Should only have one register call (from auto-generation)
        register_count = result.scan(/register.*hello.*HelloController/).size
        register_count.should eq(1)
        
        # Should keep the custom code that's not duplicated
        result.should contain("console.log('Custom initialization');")
        result.should contain("HelloController.setup();")
      end

      it "works with named import maps" do
        front_loader = AssetPipeline::FrontLoader.new do |import_maps|
          admin_map = AssetPipeline::ImportMap.new("admin")
          admin_map.add_import("AdminController", "admin_controller.js")
          import_maps << admin_map
        end
        
        result = front_loader.render_stimulus_initialization_script("", "admin")
        
        result.should contain("import AdminController from \"AdminController\";")
        result.should contain("application.register(\"admin\", AdminController);")
      end

      it "detects controllers from custom JavaScript patterns" do
        front_loader = AssetPipeline::FrontLoader.new
        
        custom_js = <<-JS
          import CustomController from "custom_controller";
          Stimulus.register("manual", ManualController);
          console.log('Setup complete');
        JS
        
        result = front_loader.render_stimulus_initialization_script(custom_js)
        
        result.should contain("application.register(\"custom\", CustomController);")
        result.should contain("application.register(\"manual\", ManualController);")
        result.should contain("console.log('Setup complete');")
      end
    end

    describe "backwards compatibility" do
      it "existing FrontLoader functionality remains unchanged" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("test", "test.js")
        
        # Test existing methods still work
        result = front_loader.render_import_map_tag
        
        result.should contain("<script type=\"importmap\">")
        result.should contain("\"test\"")
        result.should contain("test.js")
      end

      it "can use both new and old functionality together" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("HelloController", "hello_controller.js")
        import_map.add_import("utility", "utility.js")
        
        # Use both old and new methods
        import_map_result = front_loader.render_import_map_tag
        script_result = front_loader.render_stimulus_initialization_script
        
        import_map_result.should contain("<script type=\"importmap\">")
        script_result.should contain("import { Application } from \"@hotwired/stimulus\";")
        
        # Both should reference the same imports
        import_map_result.should contain("HelloController")
        script_result.should contain("HelloController")
      end
    end

    describe "error handling" do
      it "handles empty import maps gracefully" do
        front_loader = AssetPipeline::FrontLoader.new
        
        general_result = front_loader.render_initialization_script("")
        stimulus_result = front_loader.render_stimulus_initialization_script("")
        
        general_result.should eq("")
        stimulus_result.should contain("Application.start();")
      end

      it "handles malformed custom JavaScript gracefully" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("HelloController", "hello_controller.js")
        
        malformed_js = "import { from 'bad'; console.log('still works');"
        
        result = front_loader.render_stimulus_initialization_script(malformed_js)
        
        # Should still generate proper Stimulus code
        result.should contain("import { Application } from \"@hotwired/stimulus\";")
        result.should contain("import HelloController from \"HelloController\";")
        result.should contain("application.register(\"hello\", HelloController);")
        
        # Should include the malformed JS as-is (not our job to validate)
        result.should contain("import { from 'bad'; console.log('still works');")
      end
    end
  end
end 