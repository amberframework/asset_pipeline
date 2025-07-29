require "../../spec_helper"
require "../../../src/components/cache/memory_cache_store"

describe Components::Cache::MemoryCacheStore do
  describe "#fetch" do
    it "returns cached value if present" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key", "cached value")
      
      result = cache.fetch("key") { "new value" }
      result.should eq("cached value")
    end
    
    it "computes and caches value if not present" do
      cache = Components::Cache::MemoryCacheStore.new
      
      result = cache.fetch("key") { "computed value" }
      result.should eq("computed value")
      
      # Verify it was cached
      cache.read("key").should eq("computed value")
    end
    
    it "respects expiration time" do
      cache = Components::Cache::MemoryCacheStore.new
      
      cache.fetch("key", 10.milliseconds) { "value" }
      cache.read("key").should eq("value")
      
      sleep 20.milliseconds
      cache.read("key").should be_nil
    end
  end
  
  describe "#read" do
    it "returns nil for missing keys" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.read("missing").should be_nil
    end
    
    it "returns value for existing keys" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key", "value")
      cache.read("key").should eq("value")
    end
  end
  
  describe "#write" do
    it "stores values" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key", "value")
      cache.read("key").should eq("value")
    end
    
    it "overwrites existing values" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key", "value1")
      cache.write("key", "value2")
      cache.read("key").should eq("value2")
    end
  end
  
  describe "#delete" do
    it "removes cached values" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key", "value")
      cache.delete("key")
      cache.read("key").should be_nil
    end
  end
  
  describe "#clear" do
    it "removes all cached values" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key1", "value1")
      cache.write("key2", "value2")
      
      cache.clear
      
      cache.read("key1").should be_nil
      cache.read("key2").should be_nil
    end
  end
  
  describe "#exists?" do
    it "returns true for existing keys" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key", "value")
      cache.exists?("key").should be_true
    end
    
    it "returns false for missing keys" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.exists?("missing").should be_false
    end
    
    it "returns false for expired keys" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key", "value", 10.milliseconds)
      sleep 20.milliseconds
      cache.exists?("key").should be_false
    end
  end
  
  describe "#stats" do
    it "returns cache statistics" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key1", "value1")
      cache.write("key2", "longer value2")
      
      stats = cache.stats
      stats["entries"].should eq(2)
      stats["size"].should eq("value1".bytesize + "longer value2".bytesize)
    end
    
    it "excludes expired entries from stats" do
      cache = Components::Cache::MemoryCacheStore.new
      cache.write("key1", "value1")
      cache.write("key2", "value2", 10.milliseconds)
      
      sleep 20.milliseconds
      
      stats = cache.stats
      stats["entries"].should eq(1)
    end
  end
  
  describe "thread safety" do
    it "handles concurrent access" do
      cache = Components::Cache::MemoryCacheStore.new
      channel = Channel(Nil).new(10)
      
      10.times do |i|
        spawn do
          cache.write("key#{i}", "value#{i}")
          cache.read("key#{i}").should eq("value#{i}")
          channel.send(nil)
        end
      end
      
      10.times { channel.receive }
      
      cache.stats["entries"].should eq(10)
    end
  end
end