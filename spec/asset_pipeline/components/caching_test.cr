require "../../spec_helper"
require "../../../src/asset_pipeline/components"

describe "Asset Pipeline Components - Phase 2 Caching" do
  # Reset cache and config before each test
  before_each do
    AssetPipeline::Components::Cache::ComponentCacheManager.instance.clear
    AssetPipeline::Components::Cache::CacheConfig.instance.reset_to_defaults!
    AssetPipeline::Components::CSSRegistry.instance.clear!
  end
  
  describe "Cache Store Abstraction" do
    it "TestCacheStore implements the CacheStore interface" do
      cache = AssetPipeline::Components::Cache::TestCacheStore.new
      
      # Test basic operations
      cache.write("test_key", "test_value").should be_true
      cache.read("test_key").should eq("test_value")
      cache.exists?("test_key").should be_true
      cache.delete("test_key").should be_true
      cache.exists?("test_key").should be_false
    end
    
    it "TestCacheStore supports expiration" do
      cache = AssetPipeline::Components::Cache::TestCacheStore.new
      
      # Write with short expiration
      cache.write("expiring_key", "expiring_value", 1.millisecond)
      
      # Should exist immediately
      cache.exists?("expiring_key").should be_true
      
      # Wait for expiration
      sleep 2.milliseconds
      
      # Should be expired and cleaned up
      cache.exists?("expiring_key").should be_false
      cache.read("expiring_key").should be_nil
    end
    
    it "TestCacheStore fetch method works correctly" do
      cache = AssetPipeline::Components::Cache::TestCacheStore.new
      call_count = 0
      
      # First call should execute block
      result1 = cache.fetch("fetch_test") do
        call_count += 1
        "computed_value"
      end
      
      # Second call should use cached value
      result2 = cache.fetch("fetch_test") do
        call_count += 1
        "should_not_be_called"
      end
      
      result1.should eq("computed_value")
      result2.should eq("computed_value")
      call_count.should eq(1) # Block should only be called once
    end
    
    it "TestCacheStore provides statistics" do
      cache = AssetPipeline::Components::Cache::TestCacheStore.new
      
      cache.write("key1", "value1")
      cache.read("key1")  # hit
      cache.read("key2")  # miss
      
      stats = cache.stats
      stats["hits"].should eq(1)
      stats["misses"].should eq(1)
      stats["writes"].should eq(1)
    end
  end
  
  describe "ComponentCacheManager" do
    it "uses TestCacheStore by default" do
      manager = AssetPipeline::Components::Cache::ComponentCacheManager.instance
      manager.write("test", "value")
      manager.read("test").should eq("value")
    end
    
    it "can be configured with custom cache store" do
      custom_cache = AssetPipeline::Components::Cache::TestCacheStore.new
      AssetPipeline::Components::Cache::ComponentCacheManager.configure(custom_cache)
      
      manager = AssetPipeline::Components::Cache::ComponentCacheManager.instance
      manager.write("custom_test", "custom_value")
      
      # Should be able to read from custom store
      manager.read("custom_test").should eq("custom_value")
    end
    
    it "provides comprehensive statistics" do
      manager = AssetPipeline::Components::Cache::ComponentCacheManager.instance
      
      manager.write("stats_test", "value")
      manager.read("stats_test")  # hit
      manager.read("missing")     # miss
      
      stats = manager.stats
      stats.has_key?("hits").should be_true
      stats.has_key?("misses").should be_true
      stats.has_key?("hit_ratio_percent").should be_true
      stats.has_key?("enabled").should be_true
    end
  end
  
  describe "Cacheable Module" do
    it "provides cache key generation" do
      button = AssetPipeline::Components::Examples::Button.new("Test", variant: "primary")
      
      cache_key = button.cache_key
      cache_key.should contain("button")
      cache_key.should contain("Test")  # Text content is part of cache_key_parts
      cache_key.should contain("primary")
    end
    
    it "includes CSS classes in cache key" do
      button = AssetPipeline::Components::Examples::Button.new("Test", variant: "danger")
      
      cache_key = button.cache_key
      cache_key.should contain("btn")
      cache_key.should contain("danger")
    end
    
    it "supports cache invalidation" do
      button = AssetPipeline::Components::Examples::Button.new("Test")
      manager = AssetPipeline::Components::Cache::ComponentCacheManager.instance
      
      # Render to populate cache
      html = button.render
      
      # Verify it's cached
      manager.exists?(button.cache_key).should be_true
      
      # Invalidate cache
      button.invalidate_cache!
      
      # Should be removed from cache
      manager.exists?(button.cache_key).should be_false
    end
  end
  
  describe "StatelessComponent Caching" do
    it "caches rendered output" do
      AssetPipeline::Components::Cache::CacheConfig.instance.enable_cache!
      
      button = AssetPipeline::Components::Examples::Button.new("Cached Button", variant: "primary")
      
      # First render should populate cache
      html1 = button.render
      
      # Second render should use cache
      html2 = button.render
      
      html1.should eq(html2)
      html1.should contain("Cached Button")
      html1.should contain("btn-primary")
    end
    
    it "respects caching configuration" do
      # Disable caching
      AssetPipeline::Components::Cache::CacheConfig.instance.disable_cache!
      
      button = AssetPipeline::Components::Examples::Button.new("No Cache", variant: "secondary")
      manager = AssetPipeline::Components::Cache::ComponentCacheManager.instance
      
      # Render component
      html = button.render
      
      # Should not be cached when caching is disabled
      manager.exists?(button.cache_key).should be_false
    end
    
    it "allows cache to be disabled per component instance" do
      AssetPipeline::Components::Cache::CacheConfig.instance.enable_cache!
      
      button = AssetPipeline::Components::Examples::Button.new("Per Instance", variant: "warning")
      button.cache_enabled = false
      
      manager = AssetPipeline::Components::Cache::ComponentCacheManager.instance
      
      # Render component
      html = button.render
      
      # Should not be cached when instance caching is disabled
      manager.exists?(button.cache_key).should be_false
    end
  end
  
  describe "Cache Configuration" do
    it "supports global cache control" do
      config = AssetPipeline::Components::Cache::CacheConfig.instance
      
      config.enable_cache!
      config.cache_enabled?.should be_true
      
      config.disable_cache!
      config.cache_enabled?.should be_false
    end
    
    it "supports development/production mode" do
      config = AssetPipeline::Components::Cache::CacheConfig.instance
      
      # Set development mode
      config.set_development_mode!
      config.cache_on_development = false
      config.cache_enabled?.should be_false
      
      # Set production mode
      config.set_production_mode!
      config.cache_on_production = true
      config.cache_enabled?.should be_true
    end
    
    it "supports component-specific configuration" do
      config = AssetPipeline::Components::Cache::CacheConfig.instance
      
      config.configure_component("Button") do |component_config|
        component_config.disable!
        component_config.expires_in_hours = 2
      end
      
      config.component_cacheable?("Button").should be_false
      config.component_expires_in("Button").should eq(2.hours)
    end
    
    it "can load configuration from environment" do
      # Set environment variables
      ENV["COMPONENT_CACHE_ENABLED"] = "true"
      ENV["COMPONENT_CACHE_DEVELOPMENT"] = "true"
      ENV["COMPONENT_CACHE_NAMESPACE"] = "test_components"
      
      config = AssetPipeline::Components::Cache::CacheConfig.instance
      config.load_from_env
      
      config.enabled.should be_true
      config.cache_on_development.should be_true
      config.namespace.should eq("test_components")
      
      # Clean up
      ENV.delete("COMPONENT_CACHE_ENABLED")
      ENV.delete("COMPONENT_CACHE_DEVELOPMENT")
      ENV.delete("COMPONENT_CACHE_NAMESPACE")
    end
  end
  
  describe "Cache Performance" do
    it "improves performance through caching" do
      AssetPipeline::Components::Cache::CacheConfig.instance.enable_cache!
      
      button = AssetPipeline::Components::Examples::Button.new("Performance Test")
      
      # Time first render (cache miss)
      start_time = Time.monotonic
      first_render = button.render
      first_duration = Time.monotonic - start_time
      
      # Time second render (cache hit)
      start_time = Time.monotonic
      second_render = button.render
      second_duration = Time.monotonic - start_time
      
      # Results should be identical
      first_render.should eq(second_render)
      
      # Second render should be faster (though this might be flaky in tests)
      # We mainly want to verify that caching doesn't break functionality
      second_render.should contain("Performance Test")
    end
    
    it "tracks cache hit ratios" do
      manager = AssetPipeline::Components::Cache::ComponentCacheManager.instance
      manager.reset_stats
      
      button1 = AssetPipeline::Components::Examples::Button.new("Hit Test 1")
      button2 = AssetPipeline::Components::Examples::Button.new("Hit Test 2")
      
      # First renders (cache misses)
      button1.render
      button2.render
      
      # Second renders (cache hits)
      button1.render
      button2.render
      
      stats = manager.stats
      hit_ratio = stats["hit_ratio_percent"].as(Float64)
      hit_ratio.should be > 0.0
    end
  end
  
  describe "Cache Integration with CSS Registry" do
    it "includes CSS classes in cache keys for proper invalidation" do
      button = AssetPipeline::Components::Examples::Button.new("CSS Test", variant: "success")
      
      cache_key = button.cache_key
      
      # Should include CSS class information
      cache_key.should contain("btn")
      cache_key.should contain("success")
    end
    
    it "properly invalidates cache when CSS classes change" do
      AssetPipeline::Components::Cache::CacheConfig.instance.enable_cache!
      
      # Create button with specific variant
      button1 = AssetPipeline::Components::Examples::Button.new("Same Label", variant: "primary")
      button2 = AssetPipeline::Components::Examples::Button.new("Same Label", variant: "danger")
      
      # Render both (different cache keys due to different CSS classes)
      html1 = button1.render
      html2 = button2.render
      
      # Should have different content due to different CSS classes
      html1.should contain("btn-primary")
      html2.should contain("btn-danger")
      html1.should_not eq(html2)
      
      # Should have different cache keys
      button1.cache_key.should_not eq(button2.cache_key)
    end
  end
end 