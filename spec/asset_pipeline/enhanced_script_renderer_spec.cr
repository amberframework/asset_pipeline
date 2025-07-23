require "../spec_helper"
require "../../src/asset_pipeline/script_renderer"

describe AssetPipeline::ScriptRenderer do
  describe "Phase 2 Enhanced Functionality" do
    describe "dependency analysis" do
      it "analyzes JavaScript dependencies and returns comprehensive results" do
        import_map = AssetPipeline::ImportMap.new
        import_map.add_import("ExistingClass", "existing.js")
        
        js_code = <<-JS
          const chart = new Chart(ctx, {});
          $('.modal').show();
          const helper = new MissingHelper();
          ExistingClass.method();
        JS
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code, enable_dependency_analysis: true)
        analysis = renderer.analyze_dependencies
        
        analysis[:external].should contain("chartjs")
        analysis[:external].should contain("jquery")
        analysis[:local].should contain("MissingHelper")
        analysis[:suggestions].should_not be_empty
      end

      it "provides import suggestions for missing dependencies" do
        import_map = AssetPipeline::ImportMap.new
        # Don't add jquery to the import map
        
        js_code = "$('#app').fadeIn();"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code, enable_dependency_analysis: true)
        suggestions = renderer.get_import_suggestions
        
        suggestions.should_not be_empty
        suggestions.any?(&.includes?("jquery")).should be_true
        suggestions.any?(&.includes?("cdn.jsdelivr.net")).should be_true
      end

      it "doesn't suggest dependencies that are already in import map" do
        import_map = AssetPipeline::ImportMap.new
        import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
        
        js_code = "$('#app').fadeIn();"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code, enable_dependency_analysis: true)
        suggestions = renderer.get_import_suggestions
        
        suggestions.should be_empty
      end

      it "works with dependency analysis disabled" do
        import_map = AssetPipeline::ImportMap.new
        js_code = "$('#app').fadeIn();"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code, enable_dependency_analysis: false)
        analysis = renderer.analyze_dependencies
        
        analysis[:external].should be_empty
        analysis[:local].should be_empty
        analysis[:suggestions].should be_empty
      end
    end

    describe "enhanced script generation" do
      it "generates script with dependency warnings" do
        import_map = AssetPipeline::ImportMap.new
        # Missing jQuery dependency
        
        js_code = <<-JS
          $('.modal').show();
          console.log('App ready');
        JS
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code)
        enhanced_script = renderer.generate_enhanced_script_content
        
        enhanced_script.should contain("// WARNING:")
        enhanced_script.should contain("jquery")
        enhanced_script.should contain("console.log('App ready');")
      end

      it "generates script without warnings when all dependencies are present" do
        import_map = AssetPipeline::ImportMap.new
        import_map.add_import("jquery", "jquery.js")
        
        js_code = "$('.modal').show();"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code)
        enhanced_script = renderer.generate_enhanced_script_content
        
        enhanced_script.should_not contain("// WARNING:")
        enhanced_script.should contain("import \"jquery\";")
        enhanced_script.should contain("$('.modal').show();")
      end

      it "renders initialization script with analysis warnings" do
        import_map = AssetPipeline::ImportMap.new
        js_code = "moment().format('YYYY-MM-DD');"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code)
        script = renderer.render_initialization_script_with_analysis
        
        script.should contain("<script type=\"module\">")
        script.should contain("// WARNING:")
        script.should contain("moment")
        script.should contain("moment().format('YYYY-MM-DD');")
        script.should contain("</script>")
      end
    end

    describe "code complexity analysis" do
      it "analyzes simple code without suggestions" do
        import_map = AssetPipeline::ImportMap.new
        simple_js = "console.log('Hello');"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, simple_js)
        complexity = renderer.analyze_code_complexity
        
        complexity[:lines].should eq(1)
        complexity[:functions].should eq(0)
        complexity[:classes].should eq(0)
        complexity[:event_listeners].should eq(0)
        complexity[:suggestions].should be_empty
      end

      it "provides suggestions for complex code" do
        import_map = AssetPipeline::ImportMap.new
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
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, complex_js)
        complexity = renderer.analyze_code_complexity
        
        complexity[:lines].should be > 50
        complexity[:functions].should be > 5
        complexity[:event_listeners].should be > 3
        
        suggestions = complexity[:suggestions]
        suggestions.any?(&.includes?("splitting large JavaScript")).should be_true
        suggestions.any?(&.includes?("organizing functions")).should be_true
        suggestions.any?(&.includes?("Stimulus")).should be_true
      end
    end

    describe "module syntax detection" do
      it "detects modern module syntax" do
        import_map = AssetPipeline::ImportMap.new
        module_js = "import { helper } from './helper.js'; export const util = {};"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, module_js)
        
        renderer.uses_module_syntax?.should be_true
      end

      it "detects lack of module syntax" do
        import_map = AssetPipeline::ImportMap.new
        legacy_js = "console.log('Hello'); function test() {}"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, legacy_js)
        
        renderer.uses_module_syntax?.should be_false
      end

      it "extracts existing import statements" do
        import_map = AssetPipeline::ImportMap.new
        js_with_imports = <<-JS
          import { helper } from './utils/helper.js';
          import MyClass from './classes/MyClass.js';
          const module = await import('./dynamic.js');
        JS
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_with_imports)
        imports = renderer.extract_existing_imports
        
        imports.should contain("./utils/helper.js")
        imports.should contain("./classes/MyClass.js")
        imports.should contain("./dynamic.js")
      end
    end

    describe "development report generation" do
      it "generates comprehensive development report" do
        import_map = AssetPipeline::ImportMap.new
        import_map.add_import("ExistingLib", "existing.js")
        
        js_code = <<-JS
          import ExistingLib from './existing.js';
          
          const chart = new Chart(ctx, {});
          $('.modal').show();
          const helper = new MissingHelper();
          
          function setupApp() {
            console.log('App ready');
          }
          
          document.addEventListener('DOMContentLoaded', setupApp);
        JS
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code)
        report = renderer.generate_development_report
        
        report.should contain("=== ScriptRenderer Development Report ===")
        report.should contain("External dependencies detected:")
        report.should contain("Local modules detected:")
        report.should contain("Existing imports found:")
        report.should contain("Code complexity:")
        report.should contain("Import suggestions:")
        report.should contain("=== End Report ===")
        
        # Should contain detected dependencies
        report.should contain("chartjs")
        report.should contain("jquery")
        report.should contain("MissingHelper")
      end

      it "handles empty code gracefully" do
        import_map = AssetPipeline::ImportMap.new
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, "")
        report = renderer.generate_development_report
        
        report.should contain("=== ScriptRenderer Development Report ===")
        report.should contain("External dependencies detected:")
        report.should contain("Local modules detected:")
      end

      it "returns message when analysis is disabled" do
        import_map = AssetPipeline::ImportMap.new
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, "console.log('test');", enable_dependency_analysis: false)
        report = renderer.generate_development_report
        
        report.should eq("Dependency analysis disabled")
      end
    end

    describe "integration with existing functionality" do
      it "maintains backwards compatibility with basic script rendering" do
        import_map = AssetPipeline::ImportMap.new
        import_map.add_import("TestClass", "test.js")
        
        js_code = "TestClass.init();"
        
        # Both old and new methods should work
        basic_renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code, enable_dependency_analysis: false)
        enhanced_renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code, enable_dependency_analysis: true)
        
        basic_script = basic_renderer.render_initialization_script
        enhanced_script = enhanced_renderer.render_initialization_script
        
        # Both should generate valid scripts
        basic_script.should contain("<script type=\"module\">")
        enhanced_script.should contain("<script type=\"module\">")
        basic_script.should contain("TestClass.init();")
        enhanced_script.should contain("TestClass.init();")
      end

      it "enhanced features don't break existing script generation" do
        import_map = AssetPipeline::ImportMap.new
        import_map.add_import("MyClass", "my_class.js")
        
        js_code = "MyClass.setup();"
        
        renderer = AssetPipeline::ScriptRenderer.new(import_map, js_code)
        
        # All methods should work together
        basic_content = renderer.generate_script_content
        enhanced_content = renderer.generate_enhanced_script_content
        basic_script = renderer.render_initialization_script
        enhanced_script = renderer.render_initialization_script_with_analysis
        
        # All should contain the core functionality
        [basic_content, enhanced_content, basic_script, enhanced_script].each do |output|
          output.should contain("MyClass.setup();")
        end
      end
    end
  end
end 