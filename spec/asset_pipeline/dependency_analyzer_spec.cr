require "../spec_helper"
require "../../src/asset_pipeline/dependency_analyzer"

describe AssetPipeline::DependencyAnalyzer do
  describe "#detect_external_dependencies" do
    it "detects jQuery usage patterns" do
      js_code = <<-JS
        $(document).ready(function() {
          $('#modal').show();
        });
        
        jQuery.ajax('/api/data');
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_external_dependencies
      
      dependencies.should contain("jquery")
      dependencies.should contain("jQuery")
    end

    it "detects Lodash usage patterns" do
      js_code = <<-JS
        const users = _.map(data, user => user.name);
        const isEmpty = lodash.isEmpty(result);
        const filtered = _.filter(items, item => item.active);
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_external_dependencies
      
      dependencies.should contain("lodash")
    end

    it "detects multiple library patterns" do
      js_code = <<-JS
        const chart = new Chart(ctx, config);
        moment().format('YYYY-MM-DD');
        Vue.createApp(config);
        axios.get('/api/data');
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_external_dependencies
      
      dependencies.should contain("chartjs")
      dependencies.should contain("moment")
      dependencies.should contain("vue")
      dependencies.should contain("axios")
    end

    it "doesn't detect libraries when not used" do
      js_code = <<-JS
        console.log('Hello world');
        document.getElementById('app').innerHTML = 'content';
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_external_dependencies
      
      dependencies.should be_empty
    end
  end

  describe "#detect_local_dependencies" do
    it "detects class constructor usage" do
      js_code = <<-JS
        const modal = new ModalHelper();
        const validator = new FormValidator(form);
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_local_dependencies
      
      dependencies.should contain("ModalHelper")
      dependencies.should contain("FormValidator")
    end

    it "detects static method calls" do
      js_code = <<-JS
        const result = UtilityClass.formatDate(date);
        APIHelper.sendRequest(data);
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_local_dependencies
      
      dependencies.should contain("UtilityClass")
      dependencies.should contain("APIHelper")
    end

    it "excludes built-in browser APIs" do
      js_code = <<-JS
        const date = new Date();
        console.log('test');
        Document.createElement('div');
        XMLHttpRequest.open('GET', '/api');
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_local_dependencies
      
      dependencies.should_not contain("Date")
      dependencies.should_not contain("Document")
      dependencies.should_not contain("XMLHttpRequest")
    end

    it "handles mixed case and complex patterns" do
      js_code = <<-JS
        MyCustomClass.CONSTANT_VALUE = 'test';
        new HTMLParser();
        DataProcessor.process(data);
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      dependencies = analyzer.detect_local_dependencies
      
      dependencies.should contain("MyCustomClass")
      dependencies.should contain("HTMLParser")
      dependencies.should contain("DataProcessor")
    end
  end

  describe "#analyze_dependencies" do
    it "returns comprehensive dependency analysis" do
      js_code = <<-JS
        const chart = new Chart(ctx, {});
        const helper = new MyHelper();
        $('.modal').show();
        UtilityClass.format(data);
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      analysis = analyzer.analyze_dependencies
      
      analysis[:external].should contain("chartjs")
      analysis[:external].should contain("jquery")
      analysis[:local].should contain("MyHelper")
      analysis[:local].should contain("UtilityClass")
      analysis[:suggestions].should_not be_empty
    end
  end

  describe "#generate_import_suggestions" do
    it "generates CDN suggestions for external libraries" do
      external_deps = ["jquery", "lodash", "moment"]
      local_deps = [] of String
      
      analyzer = AssetPipeline::DependencyAnalyzer.new("")
      suggestions = analyzer.generate_import_suggestions(external_deps, local_deps)
      
      suggestions.any?(&.includes?("jquery")).should be_true
      suggestions.any?(&.includes?("lodash")).should be_true
      suggestions.any?(&.includes?("moment")).should be_true
      suggestions.any?(&.includes?("cdn.jsdelivr.net")).should be_true
    end

    it "generates local module suggestions" do
      external_deps = [] of String
      local_deps = ["MyClass", "UtilityHelper"]
      
      analyzer = AssetPipeline::DependencyAnalyzer.new("")
      suggestions = analyzer.generate_import_suggestions(external_deps, local_deps)
      
      suggestions.any?(&.includes?("MyClass")).should be_true
      suggestions.any?(&.includes?("UtilityHelper")).should be_true
      suggestions.any?(&.includes?("path/to/")).should be_true
    end
  end

  describe "#extract_existing_imports" do
    it "extracts ES6 import statements" do
      js_code = <<-JS
        import { helper } from './utils/helper.js';
        import MyClass from './classes/MyClass.js';
        import * as lodash from 'lodash';
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      imports = analyzer.extract_existing_imports
      
      imports.should contain("./utils/helper.js")
      imports.should contain("./classes/MyClass.js")
      imports.should contain("lodash")
    end

    it "extracts dynamic imports" do
      js_code = <<-JS
        const module = await import('./dynamic-module.js');
        import('https://cdn.example.com/library.js');
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_code)
      imports = analyzer.extract_existing_imports
      
      imports.should contain("./dynamic-module.js")
      imports.should contain("https://cdn.example.com/library.js")
    end
  end

  describe "#uses_module_syntax?" do
    it "detects module syntax usage" do
      js_with_modules = "import { helper } from './helper.js'; export const util = {};"
      js_without_modules = "console.log('Hello world'); function test() {}"
      
      analyzer_with = AssetPipeline::DependencyAnalyzer.new(js_with_modules)
      analyzer_without = AssetPipeline::DependencyAnalyzer.new(js_without_modules)
      
      analyzer_with.uses_module_syntax?.should be_true
      analyzer_without.uses_module_syntax?.should be_false
    end
  end

  describe "#analyze_code_complexity" do
    it "analyzes simple code correctly" do
      simple_js = <<-JS
        console.log('Hello');
        function greet() {
          return 'Hi';
        }
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(simple_js)
      complexity = analyzer.analyze_code_complexity
      
      complexity["lines"].should eq("4")
      complexity["functions"].should eq("1")
      complexity["classes"].should eq("0")
      complexity["event_listeners"].should eq("0")
      complexity["suggestions"].should be_empty
    end

    it "provides suggestions for complex code" do
      complex_js = <<-JS
        // #{(1..60).map { |i| "console.log('Line #{i}');" }.join("\n")}
        
        function func1() {}
        function func2() {}
        function func3() {}
        function func4() {}
        function func5() {}
        function func6() {}
        
        document.addEventListener('click', handler1);
        element.onclick = handler2;
        window.addEventListener('load', handler3);
        button.addEventListener('submit', handler4);
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(complex_js)
      complexity = analyzer.analyze_code_complexity
      
      complexity["lines"].to_i.should be > 50
      complexity["functions"].to_i.should be > 5
      complexity["event_listeners"].to_i.should be > 3
      
              suggestions = complexity["suggestions"]
      suggestions.includes?("splitting large JavaScript").should be_true
      suggestions.includes?("organizing functions").should be_true
      suggestions.includes?("Stimulus").should be_true
    end

    it "detects classes in code" do
      js_with_classes = <<-JS
        class MyClass {
          constructor() {}
        }
        
        class AnotherClass extends BaseClass {
          method() {}
        }
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(js_with_classes)
      complexity = analyzer.analyze_code_complexity
      
      complexity["classes"].should eq("2")
    end
  end

  describe "integration scenarios" do
    it "handles real-world jQuery code" do
      jquery_code = <<-JS
        $(document).ready(function() {
          $('.modal-trigger').on('click', function(e) {
            e.preventDefault();
            const target = $(this).data('target');
            $(target).fadeIn();
          });
          
          $('.close-modal').click(function() {
            $(this).closest('.modal').fadeOut();
          });
        });
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(jquery_code)
      analysis = analyzer.analyze_dependencies
      
      analysis[:external].should contain("jquery")
      analysis[:suggestions].any?(&.includes?("jquery")).should be_true
    end

    it "handles mixed framework code" do
      mixed_code = <<-JS
        import MyController from './controllers/my_controller.js';
        
        const app = Vue.createApp({
          data() {
            return { message: 'Hello' };
          }
        });
        
        const chart = new Chart(document.getElementById('chart'), {
          type: 'bar',
          data: _.map(apiData, 'value')
        });
        
        MyController.initialize();
      JS
      
      analyzer = AssetPipeline::DependencyAnalyzer.new(mixed_code)
      analysis = analyzer.analyze_dependencies
      
      analysis[:external].should contain("vue")
      analysis[:external].should contain("chartjs")
      analysis[:external].should contain("lodash")
      analysis[:local].should contain("MyController")
      
      imports = analyzer.extract_existing_imports
      imports.should contain("./controllers/my_controller.js")
    end
  end
end 