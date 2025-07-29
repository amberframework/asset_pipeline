require "./cache_store"

module Components
  module Cache
    # Mixin for components that support caching
    module Cacheable
      # Module-level cache configuration
      @@cache_store : CacheStore? = nil
      @@cache_enabled : Bool = true
      @@default_expires_in : Time::Span? = 1.hour
      
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
      
      # Russian doll caching support
      def cache_with_dependencies(dependencies : Array(Cacheable), expires_in : Time::Span? = nil, &block : -> String) : String
        return yield unless Cacheable.cache_enabled
        return yield unless cache_store = Cacheable.cache_store
        return yield unless cacheable?
        
        # Generate cache key including dependencies
        dep_keys = dependencies.map(&.cache_key).join(":")
        full_key = "#{cache_key}:deps:#{dep_keys}"
        
        expires = expires_in || Cacheable.default_expires_in
        
        cache_store.fetch(full_key, expires) do
          yield
        end
      end
      
      # Invalidate this component's cache
      def invalidate_cache : Nil
        return unless cache_store = Cacheable.cache_store
        
        # Delete the main cache entry
        cache_store.delete(cache_key)
        
        # Also delete any dependency-based cache entries
        # This requires scanning for keys that include this component's cache key
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
      
      private def invalidate_dependent_caches : Nil
        # This is a simplified implementation
        # In production, you might want to maintain a dependency graph
        # For now, we'll rely on cache expiration
      end
      
      # Generate a cache fragment for a block of content
      macro cache_fragment(key, expires_in = nil)
        if cache_store = Cacheable.cache_store
          cache_store.fetch({{key}}, {{expires_in}}) do
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