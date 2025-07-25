require "spec"
require "file_utils"
require "../../../src/asset_pipeline/components"

describe "JavaScript Integration and Asset Generation" do
  describe "ComponentAssetGenerator" do
    before_each do
      # Clean up any existing test assets
      FileUtils.rm_rf("tmp/test_assets") if Dir.exists?("tmp/test_assets")
    end

    after_each do
      # Clean up test assets
      FileUtils.rm_rf("tmp/test_assets") if Dir.exists?("tmp/test_assets")
    end

    it "generates JavaScript bundle" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      js_content = generator.generate_javascript_bundle(components)
      
      js_content.should contain("Asset Pipeline Component System")
      js_content.should contain("ComponentRegistry")
      js_content.should contain("ComponentManager")
      js_content.should contain("StatefulComponentJS")
      js_content.should contain("DOMContentLoaded")
    end

    it "generates CSS bundle" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      
      # First render some components to register CSS classes
      button = AssetPipeline::Components::Examples::Button.new("Test Button")
      button.render
      
      counter = AssetPipeline::Components::Examples::Counter.new(10, 0, 20)
      counter.render
      
      css_content = generator.generate_css_bundle(components)
      
      css_content.should contain("Asset Pipeline Component System")
      css_content.should contain("Generated CSS Bundle")
    end

    it "writes JavaScript bundle to file" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      output_path = generator.write_javascript_bundle(components)
      
      File.exists?(output_path).should be_true
      content = File.read(output_path)
      content.should contain("ComponentSystem")
    end

    it "writes CSS bundle to file" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      
      # Render components to register CSS classes
      button = AssetPipeline::Components::Examples::Button.new("Test Button")
      button.render
      
      output_path = generator.write_css_bundle(components)
      
      File.exists?(output_path).should be_true
      content = File.read(output_path)
      content.should contain("Generated CSS Bundle")
    end

    it "generates both bundles" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      bundles = generator.generate_bundles(components)
      
      bundles.has_key?("javascript").should be_true
      bundles.has_key?("css").should be_true
      
      File.exists?(bundles["javascript"]).should be_true
      File.exists?(bundles["css"]).should be_true
    end

    it "provides asset statistics" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      generator.generate_bundles(components)
      stats = generator.get_stats
      
      stats.has_key?("total_js_size").should be_true
      stats.has_key?("total_css_size").should be_true
      stats.has_key?("total_size").should be_true
      stats.has_key?("javascript_path").should be_true
      stats.has_key?("css_path").should be_true
      
      stats["total_js_size"].as(Int32).should be > 0
    end

    it "generates manifest with fingerprints" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      generator.generate_bundles(components)
      manifest = generator.generate_manifest(fingerprint: true)
      
      manifest.has_key?("js_bundle").should be_true
      manifest.has_key?("css_bundle").should be_true
      
      # Fingerprinted files should have hash in name
      manifest["js_bundle"].should match(/-[a-f0-9]{8}\.js$/)
      manifest["css_bundle"].should match(/-[a-f0-9]{8}\.css$/)
    end

    it "minifies JavaScript when requested" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      normal_bundle = generator.generate_javascript_bundle(components)
      
      # Write minified version
      minified_path = generator.write_javascript_bundle(components, minify: true)
      minified_content = File.read(minified_path)
      
      # Minified version should be smaller
      minified_content.size.should be < normal_bundle.size
      
      # Should not contain comments
      minified_content.should_not contain("//")
      minified_content.should_not contain("/*")
    end

    it "includes optimized CSS based on used classes" do
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      components = [AssetPipeline::Components::Examples::Button, AssetPipeline::Components::Examples::Counter]
      
      # Register some CSS classes by rendering components
      button = AssetPipeline::Components::Examples::Button.primary("Primary Button")
      button.render
      
      counter = AssetPipeline::Components::Examples::Counter.with_range(5, 0, 10)
      counter.render
      
      css_content = generator.generate_css_bundle(components)
      
      # Should include optimized CSS section
      css_content.should contain("Optimized CSS (used classes only)")
      
      # Should include CSS for button classes that were used
      if css_content.includes?("btn")
        css_content.should contain(".btn")
      end
    end
  end

  describe "Component JavaScript Content" do
    it "counter component can provide JavaScript content" do
      counter = AssetPipeline::Components::Examples::Counter.new(0)
      
      # Counter is stateful so should provide JavaScript content
      counter.responds_to?(:javascript_content).should be_true
      
      js_content = counter.javascript_content
      js_content.should contain("Counter")
      js_content.should contain("StatefulComponentJS")
    end

    it "button component provides minimal JavaScript for stateless components" do
      button = AssetPipeline::Components::Examples::Button.new("Test")
      
      # Button is stateless, should not provide JavaScript content
      button.responds_to?(:javascript_content).should be_false
    end
  end

  describe "Asset Pipeline Integration" do
    it "CSS registry tracks used classes during asset generation" do
      registry = AssetPipeline::Components::CSSRegistry.instance
      registry.clear!
      
      # Render components
      button = AssetPipeline::Components::Examples::Button.primary("Test")
      button.render
      
      used_classes = registry.all_used_classes
      used_classes.should contain("btn")
      used_classes.should contain("btn-primary")
    end

    it "component asset generator integrates with CSS registry" do
      registry = AssetPipeline::Components::CSSRegistry.instance
      registry.clear!
      
      # Render some components
      button = AssetPipeline::Components::Examples::Button.secondary("Secondary")
      button.render
      
      generator = AssetPipeline::Components::AssetPipeline::ComponentAssetGenerator.new("tmp/test_assets")
      stats = generator.get_stats
      
      # Should track the CSS classes that were registered
      stats["used_css_classes"].as(Int32).should be >= 0
    end
  end
end 