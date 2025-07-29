require "../../spec_helper"
require "../../../src/components/base/component"
require "../../../src/components/base/stateless_component"
require "../../../src/components/cache/cacheable"
require "../../../src/components/cache/memory_cache_store"
require "../../../src/components/cache/cache_warmer"

# Test components for cache warming
class WarmableComponent < Components::StatelessComponent
  getter warm_count = 0
  
  def warm_cache(expires_in : Time::Span? = nil) : String
    @warm_count += 1
    super
  end
  
  def render_content : String
    "<div>Warmable #{@attributes["id"]?}</div>"
  end
end

class NonCacheableComponent < Components::Component
  def render_content : String
    "<div>Not cacheable</div>"
  end
  
  def cacheable? : Bool
    false
  end
end

describe Components::Cache::CacheWarmer do
  before_each do
    Components::Cache::Cacheable.cache_store = Components::Cache::MemoryCacheStore.new
    Components::Cache::Cacheable.cache_enabled = true
  end
  
  describe "#register" do
    it "registers cacheable components" do
      warmer = Components::Cache::CacheWarmer.new(Components::Cache::Cacheable.cache_store.not_nil!)
      component = WarmableComponent.new(id: "test")
      
      warmer.register(component)
      warmer.stats["total_components"].should eq(1)
    end
    
    it "handles non-cacheable components gracefully" do
      warmer = Components::Cache::CacheWarmer.new(Components::Cache::Cacheable.cache_store.not_nil!)
      component = NonCacheableComponent.new
      
      warmer.register(component)
      warmer.stats["total_components"].should eq(1)
    end
  end
  
  describe "#warm_all" do
    it "warms all registered component caches" do
      cache_store = Components::Cache::Cacheable.cache_store.not_nil!
      warmer = Components::Cache::CacheWarmer.new(cache_store)
      
      comp1 = WarmableComponent.new(id: "1")
      comp2 = WarmableComponent.new(id: "2")
      
      warmer.register_all([comp1, comp2])
      warmer.warm_all
      
      # Verify caches were warmed
      cache_store.exists?(comp1.cache_key).should be_true
      cache_store.exists?(comp2.cache_key).should be_true
      
      comp1.warm_count.should eq(1)
      comp2.warm_count.should eq(1)
    end
    
    it "respects expiration time" do
      cache_store = Components::Cache::Cacheable.cache_store.not_nil!
      warmer = Components::Cache::CacheWarmer.new(cache_store)
      
      component = WarmableComponent.new(id: "expire")
      warmer.register(component)
      warmer.warm_all(10.milliseconds)
      
      cache_store.exists?(component.cache_key).should be_true
      sleep 20.milliseconds
      cache_store.exists?(component.cache_key).should be_false
    end
  end
  
  describe "#warm_by_type" do
    it "warms only specific component types" do
      cache_store = Components::Cache::Cacheable.cache_store.not_nil!
      warmer = Components::Cache::CacheWarmer.new(cache_store)
      
      warmable = WarmableComponent.new(id: "warm")
      non_cacheable = NonCacheableComponent.new
      
      warmer.register_all([warmable, non_cacheable])
      warmer.warm_by_type(WarmableComponent)
      
      cache_store.exists?(warmable.cache_key).should be_true
      warmable.warm_count.should eq(1)
    end
  end
  
  describe "#warm_all_concurrent" do
    it "warms caches in parallel" do
      cache_store = Components::Cache::Cacheable.cache_store.not_nil!
      warmer = Components::Cache::CacheWarmer.new(cache_store)
      
      components = (1..20).map { |i| WarmableComponent.new(id: i.to_s) }
      warmer.register_all(components)
      
      start_time = Time.monotonic
      warmer.warm_all_concurrent(batch_size: 5)
      duration = Time.monotonic - start_time
      
      # All components should be warmed
      components.all? { |c| cache_store.exists?(c.cache_key) }.should be_true
      components.all? { |c| c.warm_count == 1 }.should be_true
      
      # Should complete relatively quickly due to parallelism
      duration.should be < 100.milliseconds
    end
  end
  
  describe "#stats" do
    it "provides warming statistics" do
      cache_store = Components::Cache::Cacheable.cache_store.not_nil!
      warmer = Components::Cache::CacheWarmer.new(cache_store)
      
      warmer.register(WarmableComponent.new(id: "1"))
      warmer.register(WarmableComponent.new(id: "2"))
      warmer.register(NonCacheableComponent.new)
      
      stats = warmer.stats
      stats["total_components"].should eq(3)
      stats["types"].should eq(2)
      stats["type_WarmableComponent"].should eq(2)
      stats["type_NonCacheableComponent"].should eq(1)
    end
  end
end