require "log"

module Components
  module Cache
    # Warms the caches of `Component` instances an application registers by hand.
    #
    # Views without runtime state need none of this: `StatelessView.warm_all` finds them itself.
    class CacheWarmer
      Log = ::Log.for("asset_pipeline.cache.warmer")

      @components : Array(Component)
      @cache_store : CacheStore

      def initialize(@cache_store : CacheStore)
        @components = [] of Component
      end

      # Register a component for cache warming
      def register(component : Component) : Nil
        @components << component
      end

      # Register multiple components
      def register_all(components : Array(Component)) : Nil
        components.each { |c| register(c) }
      end

      # Warm all registered component caches
      def warm_all(expires_in : Time::Span? = nil) : Nil
        @components.each do |component|
          warm_component(component, expires_in)
        end
      end

      # Warm specific component types
      def warm_by_type(component_class : Component.class, expires_in : Time::Span? = nil) : Nil
        @components.each do |component|
          if component.class == component_class
            warm_component(component, expires_in)
          end
        end
      end

      # Warm caches in parallel using fibers
      def warm_all_concurrent(expires_in : Time::Span? = nil, batch_size : Int32 = 10) : Nil
        @components.each_slice(batch_size) do |batch|
          channel = Channel(Nil).new(batch.size)

          batch.each do |component|
            spawn do
              warm_component(component, expires_in)
              channel.send(nil)
            end
          end

          # Wait for batch to complete
          batch.size.times { channel.receive }
        end
      end

      # Get warming statistics
      def stats : Hash(String, Int32 | Int64)
        total_components = @components.size
        by_type = Hash(String, Int32).new(0)

        @components.each do |component|
          type_name = component.class.name
          by_type[type_name] = by_type[type_name] + 1
        end

        result = {} of String => Int32 | Int64
        result["total_components"] = total_components
        result["types"] = by_type.size
        by_type.each do |k, v|
          result["type_#{k}"] = v
        end
        result
      end

      private def warm_component(component : Component, expires_in : Time::Span? = nil) : Nil
        if component.responds_to?(:warm_cache) && component.responds_to?(:cacheable?) && component.cacheable?
          component.warm_cache(expires_in)
        end
      rescue ex : Exception
        # One component that cannot render must not stop the application starting.
        Log.warn(exception: ex) { "cache warming failed for #{component.class.name}" }
      end
    end
  end
end
