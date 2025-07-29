require "./cache_store"
require "./memory_cache_store"
require "./redis_cache_store"

module Components
  module Cache
    # Cache configuration for the component system
    class Configuration
      # The active cache store
      property store : CacheStore?
      
      # Whether caching is enabled
      property enabled : Bool = true
      
      # Default expiration time
      property default_expires_in : Time::Span = 1.hour
      
      # Cache key prefix
      property key_prefix : String = "amber:components:"
      
      # Whether to log cache hits/misses
      property log_enabled : Bool = false
      
      # Cache statistics tracking
      property track_stats : Bool = true
      
      def initialize
        @store = nil
      end
      
      # Configure memory cache
      def use_memory_cache : Nil
        @store = MemoryCacheStore.new
      end
      
      # Configure Redis cache
      # NOTE: Redis parameter will be added when Redis shard is installed
      def use_redis_cache(prefix : String = @key_prefix) : Nil
        @store = RedisCacheStore.new(prefix)
      end
      
      # Configure custom cache store
      def use_custom_cache(store : CacheStore) : Nil
        @store = store
      end
      
      # Disable caching
      def disable! : Nil
        @enabled = false
      end
      
      # Enable caching
      def enable! : Nil
        @enabled = true
      end
      
      # Apply configuration to all components
      def apply! : Nil
        Components::Cache::Cacheable.cache_store = @store
        Components::Cache::Cacheable.cache_enabled = @enabled
        Components::Cache::Cacheable.default_expires_in = @default_expires_in
      end
    end
    
    # Global cache configuration instance
    class_property config : Configuration = Configuration.new
    
    # Configure the cache system
    def self.configure(&block : Configuration -> Nil) : Nil
      yield config
      config.apply!
    end
  end
end