require "./cache_store"
require "./test_cache_store"

module AssetPipeline
  module Components
    module Cache
      # Manages component caching operations and statistics
      # Provides a singleton interface to the configured cache store
      class ComponentCacheManager
        # Singleton instance
        @@instance : ComponentCacheManager?
        
        @cache_store : CacheStore
        @stats : Hash(String, Int32)
        @enabled : Bool
        
        def initialize(@cache_store : CacheStore)
          @stats = {
            "hits" => 0,
            "misses" => 0,
            "writes" => 0,
            "deletes" => 0,
            "invalidations" => 0,
            "cache_warmings" => 0
          }
          @enabled = true
        end
        
        # Configure the global cache manager with a cache store
        def self.configure(cache_store : CacheStore)
          @@instance = new(cache_store)
        end
        
        # Get the singleton instance (creates with TestCacheStore if not configured)
        def self.instance : ComponentCacheManager
          @@instance ||= new(TestCacheStore.new)
        end
        
        # Enable or disable caching globally
        def self.enabled=(value : Bool)
          instance.enabled = value
        end
        
        def self.enabled : Bool
          instance.enabled
        end
        
        property enabled : Bool
        
        # Fetch content from cache or generate it using the block
        def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
          return block.call unless @enabled
          
          result = @cache_store.fetch(key, expires_in) do
            @stats["misses"] += 1
            block.call
          end
          
          # Track hit if it was already in cache
          if @cache_store.exists?(key)
            @stats["hits"] += 1
          end
          
          result
        end
        
        # Read a value from cache
        def read(key : String) : String?
          return nil unless @enabled
          
          result = @cache_store.read(key)
          if result
            @stats["hits"] += 1
          else
            @stats["misses"] += 1
          end
          result
        end
        
        # Write a value to cache
        def write(key : String, value : String, expires_in : Time::Span? = nil) : Bool
          return false unless @enabled
          
          success = @cache_store.write(key, value, expires_in)
          @stats["writes"] += 1 if success
          success
        end
        
        # Delete a specific key from cache
        def delete(key : String) : Bool
          return false unless @enabled
          
          success = @cache_store.delete(key)
          if success
            @stats["deletes"] += 1
            @stats["invalidations"] += 1
          end
          success
        end
        
        # Check if a key exists in cache
        def exists?(key : String) : Bool
          return false unless @enabled
          @cache_store.exists?(key)
        end
        
        # Clear all cache entries
        def clear : Bool
          return false unless @enabled
          
          success = @cache_store.clear
          @stats["invalidations"] += 1 if success
          success
        end
        
        # Delete multiple keys matching a pattern
        def delete_matched(pattern : Regex) : Int32
          return 0 unless @enabled
          
          deleted_count = @cache_store.delete_matched(pattern)
          @stats["deletes"] += deleted_count
          @stats["invalidations"] += 1 if deleted_count > 0
          deleted_count
        end
        
        # Warm cache by pre-computing a value
        def warm(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
          return block.call unless @enabled
          
          value = block.call
          write(key, value, expires_in)
          @stats["cache_warmings"] += 1
          value
        end
        
        # Batch operations for efficiency
        def read_multi(keys : Array(String)) : Hash(String, String?)
          return Hash(String, String?).new unless @enabled
          
          result = @cache_store.read_multi(keys)
          
          # Update stats
          result.each do |_, value|
            if value
              @stats["hits"] += 1
            else
              @stats["misses"] += 1
            end
          end
          
          result
        end
        
        def write_multi(entries : Hash(String, String), expires_in : Time::Span? = nil) : Bool
          return false unless @enabled
          
          success = @cache_store.write_multi(entries, expires_in)
          @stats["writes"] += entries.size if success
          success
        end
        
        # Cache statistics
        def stats : Hash(String, Int32 | String | Bool | Float64)
          base_stats = @stats.transform_values { |v| v.as(Int32 | String | Bool | Float64) }
          store_stats = @cache_store.stats
          
          # Calculate derived statistics
          total_requests = @stats["hits"] + @stats["misses"]
          hit_ratio = total_requests > 0 ? (@stats["hits"].to_f / total_requests.to_f) * 100.0 : 0.0
          
          combined_stats = {
            "enabled" => @enabled,
            "hit_ratio_percent" => hit_ratio,
            "total_requests" => total_requests,
            "cache_store_type" => @cache_store.class.name,
            "cache_store_connected" => @cache_store.connected?
          }.merge(base_stats).merge(store_stats)
          
          combined_stats
        end
        
        # Reset statistics (useful for testing)
        def reset_stats
          @stats.each_key { |key| @stats[key] = 0 }
          
          # Reset cache store stats
          @cache_store.reset_stats
        end
        
        # Get cache size
        def size : Int32
          @cache_store.size
        end
        
        # Generate versioned cache key
        def versioned_key(base_key : String, version : String) : String
          "#{base_key}:v#{version}"
        end
        
        # Component-specific cache operations
        
        # Invalidate all cache entries for a specific component type
        def invalidate_component_type(component_name : String) : Int32
          pattern = /^component:#{component_name.downcase}:/
          delete_matched(pattern)
        end
        
        # Get cache keys for a specific component type
        def keys_for_component_type(component_name : String) : Array(String)
          prefix = "component:#{component_name.downcase}:"
          @cache_store.all_keys.select(&.starts_with?(prefix))
        end
        
        # Warm cache for common component variants
        def warm_component_variants(component_name : String, variants : Array(String), &block : String -> String)
          return unless @enabled
          
          variants.each do |variant|
            key = "component:#{component_name.downcase}:#{variant}"
            warm(key) { block.call(variant) }
          end
        end
        
        # Bulk invalidation by multiple patterns
        def invalidate_by_patterns(patterns : Array(Regex)) : Int32
          total_deleted = 0
          patterns.each do |pattern|
            total_deleted += delete_matched(pattern)
          end
          total_deleted
        end
        
        # Invalidate all component caches (nuclear option)
        def invalidate_all_components! : Int32
          pattern = /^component:/
          delete_matched(pattern)
        end
        
        # Warm cache for all known CSS classes from the registry
        def warm_css_optimized_cache!
          return unless @enabled
          
          css_registry = ::AssetPipeline::Components::CSSRegistry.instance
          used_classes = css_registry.all_used_classes
          
          used_classes.each do |css_class|
            key = "css_optimization:#{css_class}:#{Time.utc.to_unix}"
            warm(key) { "optimized_css_for_#{css_class}" }
          end
        end
        
        # Get detailed cache metrics for monitoring
        def detailed_stats : Hash(String, Int32 | String | Bool | Float64 | Array(String))
          # Start with basic stats
          base_stats = stats
          
          # Add component-specific metrics
          component_keys = @cache_store.all_keys.select(&.starts_with?("component:"))
          css_keys = @cache_store.all_keys.select(&.starts_with?("css"))
          
          # Create new hash with extended type support
          detailed = Hash(String, Int32 | String | Bool | Float64 | Array(String)).new
          
          # Copy base stats (these include Float64 for hit_ratio_percent)
          base_stats.each do |k, v|
            case v
            when Float64
              detailed[k] = v
            when Int32, String, Bool
              detailed[k] = v
            end
          end
          
          # Add detailed metrics
          detailed["component_cache_count"] = component_keys.size
          detailed["css_cache_count"] = css_keys.size
          detailed["total_cache_keys"] = @cache_store.all_keys.size
          detailed["component_types"] = component_keys.map { |key| 
            key.split(":")[1]? || "unknown" 
          }.uniq
          
          detailed
        end
        
        # Cache health check
        def healthy? : Bool
          @cache_store.connected?
        end
        
        # Get comprehensive cache report
        def cache_report : Hash(String, Int32 | String | Bool | Float64 | Array(String))
          report = stats
          report["all_keys_count"] = @cache_store.all_keys.size
          report["component_types"] = component_types_in_cache
          report["oldest_key"] = oldest_cache_key
          report["newest_key"] = newest_cache_key
          report
        end
        
        private def component_types_in_cache : Array(String)
          component_keys = @cache_store.all_keys.select(&.starts_with?("component:"))
          component_keys.map { |key| key.split(":")[1]? }.compact.uniq
        end
        
        private def oldest_cache_key : String
          # This is a simplified implementation - real cache stores might have better ways
          keys = @cache_store.all_keys
          keys.empty? ? "" : keys.first
        end
        
        private def newest_cache_key : String
          # This is a simplified implementation - real cache stores might have better ways
          keys = @cache_store.all_keys
          keys.empty? ? "" : keys.last
        end
      end
    end
  end
end 