module Components
  module Cache
    # Base class for cache invalidation strategies
    abstract class InvalidationStrategy
      abstract def should_invalidate?(component : Component, event : InvalidationEvent) : Bool
      abstract def invalidate(component : Component, cache_store : CacheStore) : Nil
    end
    
    # Event that triggers cache invalidation
    struct InvalidationEvent
      getter type : Symbol
      getter data : Hash(String, JSON::Any)
      getter timestamp : Time
      
      def initialize(@type : Symbol, @data : Hash(String, JSON::Any) = {} of String => JSON::Any)
        @timestamp = Time.utc
      end
    end
    
    # Invalidate cache based on time
    class TimeBasedInvalidation < InvalidationStrategy
      @ttl : Time::Span
      
      def initialize(@ttl : Time::Span)
      end
      
      def should_invalidate?(component : Component, event : InvalidationEvent) : Bool
        # Time-based invalidation is handled by the cache store itself
        false
      end
      
      def invalidate(component : Component, cache_store : CacheStore) : Nil
        # No-op - handled by cache store
      end
    end
    
    # Invalidate cache when component state changes
    class StateChangeInvalidation < InvalidationStrategy
      def should_invalidate?(component : Component, event : InvalidationEvent) : Bool
        return false unless event.type == :state_change
        return false unless component.is_a?(StatefulComponent)
        
        component.changed?
      end
      
      def invalidate(component : Component, cache_store : CacheStore) : Nil
        cache_store.delete(component.cache_key) if component.responds_to?(:cache_key)
      end
    end
    
    # Invalidate cache based on data changes
    class DataChangeInvalidation < InvalidationStrategy
      @tracked_models : Array(String)
      
      def initialize(@tracked_models : Array(String) = [] of String)
      end
      
      def should_invalidate?(component : Component, event : InvalidationEvent) : Bool
        return false unless event.type == :model_change
        
        model_name = event.data["model"]?.try(&.as_s?)
        return false unless model_name
        
        @tracked_models.empty? || @tracked_models.includes?(model_name)
      end
      
      def invalidate(component : Component, cache_store : CacheStore) : Nil
        cache_store.delete(component.cache_key) if component.responds_to?(:cache_key)
      end
    end
    
    # Cascade invalidation to dependent components
    class CascadeInvalidation < InvalidationStrategy
      @dependencies : Hash(String, Array(String))
      
      def initialize
        @dependencies = {} of String => Array(String)
      end
      
      def add_dependency(parent : String, child : String) : Nil
        @dependencies[parent] ||= [] of String
        @dependencies[parent] << child unless @dependencies[parent].includes?(child)
      end
      
      def should_invalidate?(component : Component, event : InvalidationEvent) : Bool
        return false unless event.type == :cascade
        
        parent_key = event.data["parent_key"]?.try(&.as_s?)
        return false unless parent_key
        
        component_key = component.cache_key if component.responds_to?(:cache_key)
        return false unless component_key
        
        @dependencies[parent_key]?.try(&.includes?(component_key)) || false
      end
      
      def invalidate(component : Component, cache_store : CacheStore) : Nil
        return unless component.responds_to?(:cache_key)
        
        key = component.cache_key
        cache_store.delete(key)
        
        # Trigger cascade for children
        if children = @dependencies[key]?
          children.each do |child_key|
            cache_store.delete(child_key)
          end
        end
      end
    end
    
    # Composite strategy that combines multiple strategies
    class CompositeInvalidation < InvalidationStrategy
      @strategies : Array(InvalidationStrategy)
      
      def initialize(@strategies : Array(InvalidationStrategy))
      end
      
      def should_invalidate?(component : Component, event : InvalidationEvent) : Bool
        @strategies.any? { |strategy| strategy.should_invalidate?(component, event) }
      end
      
      def invalidate(component : Component, cache_store : CacheStore) : Nil
        @strategies.each { |strategy| strategy.invalidate(component, cache_store) }
      end
    end
  end
end