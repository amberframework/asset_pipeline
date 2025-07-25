require "../../spec_helper"
require "../../../src/asset_pipeline/components"

describe "Asset Pipeline Components - Phase 1" do
  # Reset CSS registry before each test
  before_each do
    AssetPipeline::Components::CSSRegistry.instance.clear!
  end
  
  describe "Base Component System" do
    it "creates HTML elements with proper attributes" do
      button = AssetPipeline::Components::Examples::Button.new("Click Me", variant: "primary")
      html = button.render
      
      html.should contain("button")
      html.should contain("Click Me")
      html.should contain("btn")
      html.should contain("btn-primary")
    end
    
    it "generates proper CSS selectors" do
      button = AssetPipeline::Components::Examples::Button.new("Test", variant: "danger")
      
      button.css_selector.should eq(".btn.btn-danger")
      button.xpath_selector.should contain("button")
      button.xpath_selector.should contain("btn")
      button.xpath_selector.should contain("btn-danger")
    end
    
    it "tracks CSS classes correctly" do
      button = AssetPipeline::Components::Examples::Button.new("Test", variant: "success")
      
      button.css_classes.should contain("btn")
      button.css_classes.should contain("btn-success")
      button.all_css_classes.size.should eq(2)
    end
  end
  
  describe "HTML Element Wrapper" do
    it "creates div elements" do
      div_element = AssetPipeline::Components::Html::HTMLElement.container("div", "Hello World", {:class => "test-class"})
      html = div_element.render
      
      html.should contain("<div")
      html.should contain("Hello World")
      html.should contain("test-class")
      html.should contain("</div>")
    end
    
    it "creates self-closing elements" do
      img_element = AssetPipeline::Components::Html::HTMLElement.self_closing("img", {:src => "test.jpg", :alt => "Test"})
      html = img_element.render
      
      html.should contain("<img")
      html.should contain("src=\"test.jpg\"")
      html.should contain("alt=\"Test\"")
      html.should contain("/>")
    end
  end
  
  describe "HTML Helpers" do
    it "creates div helper" do
      html = div("Content", class: "wrapper").render
      html.should contain("<div")
      html.should contain("Content")
      html.should contain("wrapper")
    end
    
    it "creates button helper" do
      html = button("Submit", type: "submit", class: "btn").render
      html.should contain("<button")
      html.should contain("Submit")
      html.should contain("type=\"submit\"")
    end
    
    it "creates input helper" do
      html = input(type: "text", name: "username").render
      html.should contain("<input")
      html.should contain("type=\"text\"")
      html.should contain("name=\"username\"")
      html.should contain("/>")
    end
  end
  
  describe "Stateful Components" do
    it "renders counter component with data attributes" do
      counter = AssetPipeline::Components::Examples::Counter.new(initial_count: 5)
      html = counter.render
      
      html.should contain("data-component=\"counter\"")
      html.should contain("data-count=\"5\"")
      html.should contain("counter")
      html.should contain("count")
    end
    
    it "generates JavaScript content" do
      counter = AssetPipeline::Components::Examples::Counter.new
      js = counter.javascript_content
      
      js.should contain("class Counter")
      js.should contain("initialize()")
      js.should contain("increment")
      js.should contain("decrement")
    end
    
    it "generates CSS content" do
      counter = AssetPipeline::Components::Examples::Counter.new
      css = counter.css_content
      
      css.should contain(".counter")
      css.should contain(".count-display")
      css.should contain(".btn-increment")
    end
    
    it "manages complex CSS classes" do
      counter = AssetPipeline::Components::Examples::Counter.new
      
      counter.all_css_classes.should contain("counter")
      counter.all_css_classes.should contain("count")
      counter.all_css_classes.should contain("btn")
      
      counter.css_selector_for("display").should eq(".count.count-display")
      counter.css_selector_for("increment").should eq(".btn.btn-increment.btn-small")
    end
  end
  
  describe "CSS Registry" do
    it "tracks component CSS usage" do
      registry = AssetPipeline::Components::CSSRegistry.instance
      
      # Register a button component
      button = AssetPipeline::Components::Examples::Button.new("Test", variant: "primary")
      AssetPipeline::Components::CSSRegistryHelper.register(button)
      
      registry.all_used_classes.should contain("btn")
      registry.all_used_classes.should contain("btn-primary")
      registry.usage_count("btn").should eq(1)
    end
    
    it "tracks stateful component CSS usage" do
      registry = AssetPipeline::Components::CSSRegistry.instance
      
      # Register a counter component
      counter = AssetPipeline::Components::Examples::Counter.new
      AssetPipeline::Components::CSSRegistryHelper.register(counter)
      
      registry.all_used_classes.should contain("counter")
      registry.all_used_classes.should contain("count")
      registry.all_used_classes.should contain("btn")
      
      # Should track multiple uses of 'btn' class
      registry.usage_count("btn").should be > 1
    end
    
    it "generates optimization reports" do
      registry = AssetPipeline::Components::CSSRegistry.instance
      
      # Register some components
      button = AssetPipeline::Components::Examples::Button.new("Test")
      counter = AssetPipeline::Components::Examples::Counter.new
      
      AssetPipeline::Components::CSSRegistryHelper.register(button)
      AssetPipeline::Components::CSSRegistryHelper.register(counter)
      
      report = registry.optimization_report
      
      report.has_key?("total_components").should be_true
      report.has_key?("total_classes_used").should be_true
      report.has_key?("most_used_classes").should be_true
    end
    
    it "generates CSS purge whitelist" do
      registry = AssetPipeline::Components::CSSRegistry.instance
      
      button = AssetPipeline::Components::Examples::Button.new("Test", variant: "danger")
      AssetPipeline::Components::CSSRegistryHelper.register(button)
      
      whitelist = registry.generate_purge_whitelist
      whitelist.should contain("btn")
      whitelist.should contain("btn-danger")
    end
  end
  
  describe "Component Renderer" do
    it "renders components with automatic CSS registration" do
      # Enable auto-registration
      AssetPipeline::Components::Config.auto_register_css = true
      
      button = AssetPipeline::Components::Examples::Button.new("Auto Register")
      html = AssetPipeline::Components::ComponentRenderer.render(button)
      
      html.should contain("Auto Register")
      
      # Check that CSS was auto-registered
      registry = AssetPipeline::Components::CSSRegistry.instance
      registry.all_used_classes.should contain("btn")
    end
    
    it "renders stateful components with assets" do
      counter = AssetPipeline::Components::Examples::Counter.new(initial_count: 10)
      assets = AssetPipeline::Components::ComponentRenderer.render_with_assets(counter)
      
      assets.has_key?("html").should be_true
      assets.has_key?("javascript").should be_true
      assets.has_key?("css").should be_true
      
      assets["html"].should contain("data-count=\"10\"")
      assets["javascript"].should contain("class Counter")
      assets["css"].should contain(".counter")
    end
  end
  
  describe "Component Helpers" do
    it "provides convenient component rendering" do
      button = AssetPipeline::Components::Examples::Button.new("Helper Test")
      html = AssetPipeline::Components.component(button)
      
      html.should contain("Helper Test")
      html.should contain("btn")
    end
    
    it "provides CSS optimization helpers" do
      # Clear and add some test components
      AssetPipeline::Components.clear_css_registry!
      
      button = AssetPipeline::Components::Examples::Button.new("Test")
      AssetPipeline::Components.component(button)
      
      used_classes = AssetPipeline::Components.used_css_classes
      used_classes.should contain("btn")
      
      whitelist = AssetPipeline::Components.css_purge_whitelist
      whitelist.should contain("btn")
    end
  end
end 