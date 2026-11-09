require "./cache_store"
require "./memory_cache_store"

module Components
  module Cache
    # Mixin for components that support caching
    module Cacheable
      # Caching works with no setup: a byte-bounded memory store is the default.
      @@cache_store : CacheStore? = MemoryCacheStore.new
      @@cache_enabled : Bool = true
      # Nothing expires by default. Writes clear what they change, and the byte budget drops what
      # goes unused, so a time limit would only rebuild pages that are still correct.
      @@default_expires_in : Time::Span? = nil

      # The cache store to use for this component
      def self.cache_store=(value : CacheStore?)
        @@cache_store = value
      end

      def self.cache_store
        @@cache_store
      end

      # Whether caching is enabled globally
      def self.cache_enabled=(value : Bool)
        @@cache_enabled = value
      end

      def self.cache_enabled
        @@cache_enabled
      end

      # Default cache expiration time
      def self.default_expires_in=(value : Time::Span?)
        @@default_expires_in = value
      end

      def self.default_expires_in
        @@default_expires_in
      end

      # Cache the rendered output of this component
      def cache(expires_in : Time::Span? = nil, &block : -> String) : String
        return yield unless Cacheable.cache_enabled
        return yield unless cache_store = Cacheable.cache_store
        return yield unless cacheable?

        key = cache_key
        expires = expires_in || Cacheable.default_expires_in

        cache_store.fetch(key, expires) do
          yield
        end
      end

      # Russian doll caching support: the entry clears when any of *dependencies* is invalidated.
      def cache_with_dependencies(dependencies : Array(Cacheable), expires_in : Time::Span? = nil, &block : -> String) : String
        cache_with_dependency_keys(dependencies.map(&.cache_key), expires_in) { yield }
      end

      # Caches under *list_of_dependency_keys*, for records that are not components themselves.
      #
      # A write then calls `#invalidate_dependent_caches` on the owner or
      # `CacheStore#delete_dependents` with the record's key.
      def cache_with_dependency_keys(list_of_dependency_keys : Array(String), expires_in : Time::Span? = nil, &block : -> String) : String
        return yield unless Cacheable.cache_enabled
        return yield unless cache_store = Cacheable.cache_store
        return yield unless cacheable?

        key = cache_key
        full_key = "#{key}:deps:#{list_of_dependency_keys.join(":")}"
        expires = expires_in || Cacheable.default_expires_in

        cache_store.fetch_with_dependencies(full_key, list_of_dependency_keys + [key], key, expires) do
          yield
        end
      end

      # Invalidate this component's cache
      def invalidate_cache : Nil
        return unless cache_store = Cacheable.cache_store

        # Delete the main cache entry
        cache_store.delete(cache_key)

        # Also delete any dependency-based cache entries
        invalidate_dependent_caches
      end

      # Warm the cache for this component
      def warm_cache(expires_in : Time::Span? = nil) : String
        return render_content unless Cacheable.cache_enabled
        return render_content unless cache_store = Cacheable.cache_store
        return render_content unless cacheable?

        expires = expires_in || Cacheable.default_expires_in
        content = render_content

        cache_store.write(cache_key, content, expires)
        content
      end

      # Touch the cache to update timestamps (for dependency tracking)
      def touch_cache : Nil
        invalidate_cache
      end

      # Removes every entry that depends on this component, and nothing else.
      def invalidate_dependent_caches : Nil
        return unless cache_store = Cacheable.cache_store

        cache_store.delete_dependents(cache_key)
      end

      # Generate a cache fragment for a block of content
      macro cache_fragment(key, expires_in = nil)
        if ::Components::Cache::Cacheable.cache_enabled && (%cache_store = ::Components::Cache::Cacheable.cache_store)
          %cache_store.fetch({{key}}, {{expires_in}} || ::Components::Cache::Cacheable.default_expires_in) do
            String.build do |io|
              {{yield}}
            end
          end
        else
          String.build do |io|
            {{yield}}
          end
        end
      end
    end
  end
end
