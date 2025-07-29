require "../../spec_helper"
require "../../../src/components/base/component"
require "../../../src/components/base/stateless_component"
require "../../../src/components/cache/cacheable"
require "../../../src/components/cache/memory_cache_store"
require "../../../src/components/elements/grouping/div"

# Test component that includes Cacheable
class CacheableTestComponent < Components::StatelessComponent
  def render_content : String
    "<div>Rendered at #{Time.utc}</div>"
  end
end

# Component with custom cache key
class CustomCacheKeyComponent < Components::StatelessComponent
  def cache_key : String
    "custom:#{@attributes["id"]?}:#{@attributes["version"]?}"
  end
  
  def render_content : String
    "<div>Component #{@attributes["id"]?}</div>"
  end
end

describe Components::Cache::Cacheable do
  before_each do
    # Reset cache configuration
    Components::Cache::Cacheable.cache_store = nil
    Components::Cache::Cacheable.cache_enabled = true
  end
  
  describe "#cache" do
    it "caches rendered output when cache is enabled" do
      cache_store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = cache_store
      
      component = CacheableTestComponent.new
      
      # First render
      result1 = component.cache { component.render_content }
      
      # Second render should return cached value
      result2 = component.cache { "This should not be called" }
      
      result2.should eq(result1)
    end
    
    it "bypasses cache when disabled" do
      cache_store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = cache_store
      Components::Cache::Cacheable.cache_enabled = false
      
      component = CacheableTestComponent.new
      
      result1 = component.cache { "first" }
      result2 = component.cache { "second" }
      
      result1.should eq("first")
      result2.should eq("second")
    end
    
    it "bypasses cache when no cache store is configured" do
      component = CacheableTestComponent.new
      
      result = component.cache { "direct render" }
      result.should eq("direct render")
    end
    
    it "respects custom expiration time" do
      cache_store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = cache_store
      
      component = CacheableTestComponent.new
      
      component.cache(10.milliseconds) { "cached value" }
      sleep 20.milliseconds
      
      result = component.cache { "new value" }
      result.should eq("new value")
    end
  end
  
  describe "#cache_with_dependencies" do
    it "caches with dependency tracking" do
      cache_store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = cache_store
      
      parent = CacheableTestComponent.new
      child1 = CustomCacheKeyComponent.new(id: "1", version: "v1")
      child2 = CustomCacheKeyComponent.new(id: "2", version: "v1")
      
      # Cache with dependencies
      result = parent.cache_with_dependencies([child1, child2]) do
        parent.render_content
      end
      
      # Verify it's cached with dependency key
      cache_store.exists?("#{parent.cache_key}:deps:#{child1.cache_key}:#{child2.cache_key}").should be_true
    end
  end
  
  describe "#invalidate_cache" do
    it "removes cached content" do
      cache_store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = cache_store
      
      component = CacheableTestComponent.new
      
      # Cache some content
      component.cache { "cached" }
      cache_store.exists?(component.cache_key).should be_true
      
      # Invalidate
      component.invalidate_cache
      cache_store.exists?(component.cache_key).should be_false
    end
  end
  
  describe "#warm_cache" do
    it "pre-populates the cache" do
      cache_store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = cache_store
      
      component = CustomCacheKeyComponent.new(id: "warm", version: "v1")
      
      # Warm the cache
      result = component.warm_cache
      result.should eq("<div>Component warm</div>")
      
      # Verify it's cached
      cache_store.read(component.cache_key).should eq(result)
    end
    
    it "respects expiration time when warming" do
      cache_store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = cache_store
      
      component = CacheableTestComponent.new
      
      component.warm_cache(10.milliseconds)
      sleep 20.milliseconds
      
      cache_store.exists?(component.cache_key).should be_false
    end
  end
  
  describe "#cache_key" do
    it "generates consistent cache keys for same attributes" do
      comp1 = CustomCacheKeyComponent.new(id: "test", version: "v1")
      comp2 = CustomCacheKeyComponent.new(id: "test", version: "v1")
      
      comp1.cache_key.should eq(comp2.cache_key)
    end
    
    it "generates different cache keys for different attributes" do
      comp1 = CustomCacheKeyComponent.new(id: "test", version: "v1")
      comp2 = CustomCacheKeyComponent.new(id: "test", version: "v2")
      
      comp1.cache_key.should_not eq(comp2.cache_key)
    end
  end
end