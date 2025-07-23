require "../spec_helper"

describe AssetPipeline::FrontLoader do
  describe "Phase 2 Enhanced Methods" do
    describe "#render_initialization_script_with_analysis" do
      it "renders script with dependency analysis warnings" do
        front_loader = AssetPipeline::FrontLoader.new
        
        custom_js = <<-JS
          $('.modal').show();
          const chart = new Chart(ctx, {});
          console.log('App initialized');
        JS
        
        result = front_loader.render_initialization_script_with_analysis(custom_js)
        
        result.should contain("<script type=\"module\">")
        result.should contain("// WARNING:")
        result.should contain("jquery")
        result.should contain("chartjs")
        result.should contain("console.log('App initialized');")
        result.should contain("</script>")
      end

      it "works with named import maps" do
        front_loader = AssetPipeline::FrontLoader.new do |import_maps|
          admin_map = AssetPipeline::ImportMap.new("admin")
          admin_map.add_import("AdminClass", "admin.js")
          import_maps << admin_map
        end
        
        custom_js = "AdminClass.init(); $('.data-table').show();"
        
        result = front_loader.render_initialization_script_with_analysis(custom_js, "admin")
        
        result.should contain("import AdminClass from \"AdminClass\";")
        result.should contain("// WARNING:")
        result.should contain("jquery")
      end
    end

    describe "#analyze_javascript_dependencies" do
      it "analyzes dependencies in JavaScript code" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("ExistingLib", "existing.js")
        
        custom_js = <<-JS
          const chart = new Chart(document.getElementById('chart'), {});
          $('.modal').show();
          const helper = new MyHelper();
          ExistingLib.setup();
        JS
        
        analysis = front_loader.analyze_javascript_dependencies(custom_js)
        
        analysis[:external].should contain("chartjs")
        analysis[:external].should contain("jquery")
        analysis[:local].should contain("MyHelper")
        analysis[:suggestions].should_not be_empty
      end

      it "returns empty analysis for simple code" do
        front_loader = AssetPipeline::FrontLoader.new
        
        simple_js = "console.log('Hello world');"
        
        analysis = front_loader.analyze_javascript_dependencies(simple_js)
        
        analysis[:external].should be_empty
        analysis[:local].should be_empty
        analysis[:suggestions].should be_empty
      end

      it "works with named import maps" do
        front_loader = AssetPipeline::FrontLoader.new do |import_maps|
          test_map = AssetPipeline::ImportMap.new("test")
          test_map.add_import("TestLib", "test.js")
          import_maps << test_map
        end
        
        js_code = "TestLib.method(); $('.element').hide();"
        
        analysis = front_loader.analyze_javascript_dependencies(js_code, "test")
        
                 analysis[:external].should contain("jquery")
         # TestLib might be detected as a local dependency but shouldn't be in external
         analysis[:external].should_not contain("TestLib")
      end
    end

    describe "#get_dependency_suggestions" do
      it "provides suggestions for missing dependencies" do
        front_loader = AssetPipeline::FrontLoader.new
        
        js_with_missing_deps = <<-JS
          moment().format('YYYY-MM-DD');
          axios.get('/api/data');
          const chart = new Chart(ctx, {});
        JS
        
        suggestions = front_loader.get_dependency_suggestions(js_with_missing_deps)
        
        suggestions.should_not be_empty
        suggestions.any?(&.includes?("moment")).should be_true
        suggestions.any?(&.includes?("axios")).should be_true
        suggestions.any?(&.includes?("chartjs")).should be_true
        suggestions.any?(&.includes?("cdn.jsdelivr.net")).should be_true
      end

      it "doesn't suggest dependencies that are already in import map" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("moment", "https://cdn.jsdelivr.net/npm/moment@2.29.4/+esm")
        
        js_code = "moment().format('YYYY-MM-DD');"
        
        suggestions = front_loader.get_dependency_suggestions(js_code)
        
        suggestions.should be_empty
      end

      it "suggests local modules for custom classes" do
        front_loader = AssetPipeline::FrontLoader.new
        
        js_code = <<-JS
          const validator = new FormValidator(form);
          DataProcessor.process(data);
        JS
        
        suggestions = front_loader.get_dependency_suggestions(js_code)
        
        suggestions.any?(&.includes?("FormValidator")).should be_true
        suggestions.any?(&.includes?("DataProcessor")).should be_true
        suggestions.any?(&.includes?("path/to/")).should be_true
      end
    end

    describe "#generate_dependency_report" do
      it "generates comprehensive development report" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("ExistingLib", "existing.js")
        
        complex_js = <<-JS
          import ExistingLib from './existing.js';
          
          const chart = new Chart(ctx, {});
          $('.modal').show();
          const helper = new MissingHelper();
          
          function setupApp() {
            console.log('App ready');
          }
          
          function initializeModules() {
            console.log('Modules ready');
          }
          
          document.addEventListener('DOMContentLoaded', setupApp);
          window.addEventListener('load', initializeModules);
        JS
        
        report = front_loader.generate_dependency_report(complex_js)
        
        report.should contain("=== ScriptRenderer Development Report ===")
                 report.should contain("External dependencies detected:")
         # Order might vary, check for both dependencies individually
         report.should contain("chartjs")
         report.should contain("jquery")
        report.should contain("Local modules detected:")
        report.should contain("MissingHelper")
        report.should contain("Existing imports found:")
        report.should contain("./existing.js")
        report.should contain("Code complexity:")
        report.should contain("Lines:")
        report.should contain("Functions:")
        report.should contain("Event listeners:")
        report.should contain("Import suggestions:")
        report.should contain("=== End Report ===")
      end

      it "handles empty JavaScript gracefully" do
        front_loader = AssetPipeline::FrontLoader.new
        
        report = front_loader.generate_dependency_report("")
        
        report.should contain("=== ScriptRenderer Development Report ===")
        report.should contain("External dependencies detected:")
        report.should contain("Local modules detected:")
      end

      it "works with named import maps" do
        front_loader = AssetPipeline::FrontLoader.new do |import_maps|
          admin_map = AssetPipeline::ImportMap.new("admin")
          admin_map.add_import("AdminHelper", "admin_helper.js")
          import_maps << admin_map
        end
        
        js_code = "AdminHelper.setup(); $('.admin-panel').show();"
        
                 report = front_loader.generate_dependency_report(js_code, "admin")
         
         report.should contain("External dependencies detected: jquery")
         # AdminHelper might be detected as a local dependency, but shouldn't be in import suggestions for missing deps
         # Check that it's not suggested as missing since it's in the import map
         import_suggestions = report.split("Import suggestions:")[1]? || ""
         import_suggestions.should_not contain("AdminHelper")
      end
    end

    describe "#analyze_code_complexity" do
      it "analyzes simple code" do
        front_loader = AssetPipeline::FrontLoader.new
        
        simple_js = <<-JS
          console.log('Hello');
          function greet() {
            return 'Hi';
          }
        JS
        
        complexity = front_loader.analyze_code_complexity(simple_js)
        
        complexity[:lines].should eq(4)
        complexity[:functions].should eq(1)
        complexity[:classes].should eq(0)
        complexity[:event_listeners].should eq(0)
        complexity[:suggestions].should be_empty
      end

      it "provides suggestions for complex code" do
        front_loader = AssetPipeline::FrontLoader.new
        
        complex_js = <<-JS
          #{(1..60).map { |i| "console.log('Line #{i}');" }.join("\n")}
          
          function func1() {}
          function func2() {}
          function func3() {}
          function func4() {}
          function func5() {}
          function func6() {}
          
          document.addEventListener('click', handler);
          element.onclick = handler2;
          window.addEventListener('load', handler3);
          button.addEventListener('submit', handler4);
        JS
        
        complexity = front_loader.analyze_code_complexity(complex_js)
        
        complexity[:lines].should be > 50
        complexity[:functions].should be > 5
        complexity[:event_listeners].should be > 3
        
        suggestions = complexity[:suggestions]
        suggestions.any?(&.includes?("splitting large JavaScript")).should be_true
        suggestions.any?(&.includes?("organizing functions")).should be_true
        suggestions.any?(&.includes?("Stimulus")).should be_true
      end

      it "detects classes and provides appropriate metrics" do
        front_loader = AssetPipeline::FrontLoader.new
        
        js_with_classes = <<-JS
          class MyComponent {
            constructor() {
              this.initialized = false;
            }
            
            init() {
              this.initialized = true;
            }
          }
          
          class AnotherComponent extends BaseComponent {
            render() {
              return '<div>Component</div>';
            }
          }
        JS
        
        complexity = front_loader.analyze_code_complexity(js_with_classes)
        
        complexity[:classes].should eq(2)
        complexity[:functions].should be > 0 # constructor, methods
      end
    end

    describe "integration with existing functionality" do
      it "works alongside existing FrontLoader methods" do
        front_loader = AssetPipeline::FrontLoader.new
        import_map = front_loader.get_import_map
        import_map.add_import("HelloController", "hello_controller.js")
        import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
        
        custom_js = "$('#app').fadeIn(); HelloController.setup();"
        
        # Test that all methods work together
        import_map_tag = front_loader.render_import_map_tag
        basic_script = front_loader.render_initialization_script(custom_js)
        enhanced_script = front_loader.render_initialization_script_with_analysis(custom_js)
        stimulus_script = front_loader.render_stimulus_initialization_script(custom_js)
        
        # All should work without errors
        import_map_tag.should contain("<script type=\"importmap\">")
        basic_script.should contain("$('#app').fadeIn();")
        enhanced_script.should contain("$('#app').fadeIn();")
        stimulus_script.should contain("application.register(\"hello\", HelloController);")
        
        # Enhanced script should not have warnings since dependencies are present
        enhanced_script.should_not contain("// WARNING:")
      end

      it "maintains backwards compatibility" do
        front_loader = AssetPipeline::FrontLoader.new
        
        # Old methods should still work exactly as before
        old_script = front_loader.render_initialization_script("console.log('test');")
        old_stimulus = front_loader.render_stimulus_initialization_script("console.log('stimulus');")
        
        old_script.should contain("console.log('test');")
        old_stimulus.should contain("console.log('stimulus');")
        old_stimulus.should contain("Application.start();")
      end
    end

    describe "error handling" do
      it "handles non-existent import maps gracefully" do
        front_loader = AssetPipeline::FrontLoader.new
        
        expect_raises(Exception, "Import map with name nonexistent not found") do
          front_loader.analyze_javascript_dependencies("console.log('test');", "nonexistent")
        end
      end

      it "handles malformed JavaScript gracefully" do
        front_loader = AssetPipeline::FrontLoader.new
        
        malformed_js = "import { from 'bad syntax'; console.log('still works');"
        
        # Should not crash, just include the malformed code
        analysis = front_loader.analyze_javascript_dependencies(malformed_js)
        report = front_loader.generate_dependency_report(malformed_js)
        
        analysis.should be_a(Hash(Symbol, Array(String)))
        report.should contain("=== ScriptRenderer Development Report ===")
      end
    end
  end
end 