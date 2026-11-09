require "./cache_store"
require "./memory_cache_store"
require "./redis_cache_store"
require "./cacheable"
require "./page_cache"

module Components
  module Cache
    # Cache configuration for the component system
    class Configuration
      # The active cache store. Defaults to the byte-bounded memory store caching starts with.
      property store : CacheStore?

      # Whether caching is enabled
      property enabled : Bool = true

      # Default expiration time. Nil keeps entries until a write clears them or the budget needs the room.
      property default_expires_in : Time::Span? = nil

      # Cache key prefix
      property key_prefix : String = "amber:components:"

      # Whether to log cache hits/misses
      property log_enabled : Bool = false

      # Cache statistics tracking
      property track_stats : Bool = true

      # What the page cache derives and stores.
      getter page_cache : PageCache::Settings = PageCache::Settings.new

      def initialize
        @store = Cacheable.cache_store
      end

      # Configure memory cache. *maximum_bytes* is the budget for everything it stores.
      def use_memory_cache(maximum_bytes : Int64 = MemoryCacheStore::DEFAULT_MAXIMUM_BYTES) : Nil
        @store = MemoryCacheStore.new(maximum_bytes)
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
        Components::Cache.reset_page_cache
      end
    end

    # Global cache configuration instance
    class_property config : Configuration = Configuration.new

    @@page_cache : PageCache? = nil
    @@page_cache_lock = Mutex.new(:unchecked)

    # Configure the cache system
    #
    # ```
    # Components::Cache.configure do |config|
    #   config.use_memory_cache(maximum_bytes: 64_i64 * 1024 * 1024)
    #   config.page_cache.rebuilds_after_write = true
    # end
    # ```
    def self.configure(&block : Configuration -> Nil) : Nil
      yield config
      config.apply!
    end

    # The page cache that shares the configured store.
    def self.page_cache : PageCache
      @@page_cache_lock.synchronize do
        @@page_cache ||= PageCache.new(config.store || MemoryCacheStore.new, config.page_cache)
      end
    end

    # :nodoc:
    def self.reset_page_cache : Nil
      @@page_cache_lock.synchronize { @@page_cache = nil }
    end
  end
end
