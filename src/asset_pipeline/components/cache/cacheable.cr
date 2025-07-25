module AssetPipeline
  module Components
    module Cache
      # Module to add caching capabilities to components
      # Provides cache key generation and cache control methods
      module Cacheable
        # Class-level cache configuration
        module ClassMethods
          # Cache version for cache busting (increment when component logic changes)
          @@cache_version : String = "1"
          
          def cache_version : String
            @@cache_version
          end
          
          def cache_version=(version : String)
            @@cache_version = version
          end
          
          # Increment cache version to bust all caches for this component type
          def increment_cache_version!
            current = @@cache_version.to_i? || 1
            @@cache_version = (current + 1).to_s
          end
          
          # Global cache control
          @@cacheable : Bool = true
          
          def cacheable : Bool
            @@cacheable
          end
          
          def cacheable=(value : Bool)
            @@cacheable = value
          end
          
          # Disable caching for this component class
          def disable_cache!
            @@cacheable = false
          end
          
          # Enable caching for this component class
          def enable_cache!
            @@cacheable = true
          end
        end
        
        # Instance-level cache configuration
        property cache_enabled : Bool = true
        
        # Abstract method - components should implement this
        # Returns array of values that should be included in cache key
        abstract def cache_key_parts : Array(String)
        
        # Default cache expiration (nil = no expiration)
        def cache_expires_in : Time::Span?
          nil
        end
        
        # Generate the complete cache key for this component instance
        def cache_key : String
          parts = [
            "component",
            component_name.downcase,
            self.class.cache_version,
            cache_key_parts.join("|")
          ]
          
          # Include CSS classes in cache key for proper invalidation
          if responds_to?(:css_classes)
            if css_classes.is_a?(Array(String))
              parts << css_classes.as(Array(String)).join(",")
            elsif css_classes.is_a?(Hash(String, Array(String)))
              flattened = css_classes.as(Hash(String, Array(String))).values.flatten.join(",")
              parts << flattened
            end
          end
          
          parts.join(":")
        end
        
        # Check if this component instance should be cached
        def cacheable? : Bool
          return false unless @cache_enabled
          return false unless self.class.cacheable
          true
        end
        
        # Generate a cache key for a specific variant or state
        def cache_key_for(variant : String) : String
          "#{cache_key}:#{variant}"
        end
        
        # Invalidate cache for this specific component instance
        def invalidate_cache!
          ComponentCacheManager.instance.delete(cache_key)
        end
        
        # Invalidate cache for this component class (all instances)
        def invalidate_class_cache!
          pattern = /^component:#{component_name.downcase}:/
          ComponentCacheManager.instance.delete_matched(pattern)
        end
        
        # Warm cache by pre-rendering this component
        def warm_cache!
          return unless cacheable?
          ComponentCacheManager.instance.warm(cache_key) do
            render_without_cache
          end
        end
        
        # Get cache statistics for this component
        def cache_stats : Hash(String, Int32 | String | Bool)
          {
            "cache_key" => cache_key,
            "cacheable" => cacheable?,
            "cache_enabled" => @cache_enabled,
            "class_cacheable" => self.class.cacheable,
            "cache_version" => self.class.cache_version,
            "cache_expires_in" => cache_expires_in.try(&.total_seconds.to_i) || 0,
            "cache_hit" => ComponentCacheManager.instance.exists?(cache_key)
          }
        end
        
        # Cache warming helpers
        def self.warm_cache_for_variants(component_instances : Array(Cacheable))
          component_instances.each(&.warm_cache!)
        end
        
        # Warm cache for a specific component type with common variants
        def self.warm_component_type(component_class : Class, variants : Hash(String, Array(String)))
          return unless ComponentCacheManager.instance.enabled
          
          variants.each do |variant_name, variant_values|
            variant_values.each do |value|
              key = "component:#{component_class.name.split("::").last.downcase}:#{variant_name}:#{value}"
              ComponentCacheManager.instance.warm(key) do
                # This is a placeholder - in practice, the component would need to be instantiated
                # with the specific variant values to generate the correct cache content
                "cached_content_for_#{variant_name}_#{value}"
              end
            end
          end
        end
        
        # Batch invalidation for multiple component instances
        def self.invalidate_cache_for_components(component_instances : Array(Cacheable))
          component_instances.each(&.invalidate_cache!)
        end
        
        # Invalidate cache entries containing specific CSS classes
        def self.invalidate_by_css_class(css_class : String)
          pattern = /#{Regex.escape(css_class)}/
          ComponentCacheManager.instance.delete_matched(pattern)
        end
        
        # Invalidate cache entries for multiple CSS classes
        def self.invalidate_by_css_classes(css_classes : Array(String))
          css_classes.each { |css_class| invalidate_by_css_class(css_class) }
        end
        
        # Warm cache for components with specific CSS classes
        def self.warm_by_css_classes(css_classes : Array(String), &block : String -> String)
          return unless ComponentCacheManager.instance.enabled
          
          css_classes.each do |css_class|
            key = "css_warmup:#{css_class}:#{Time.utc.to_unix}"
            ComponentCacheManager.instance.warm(key) { block.call(css_class) }
          end
        end
        
        # Extended macro to include ClassMethods when module is included
        macro included
          extend ::AssetPipeline::Components::Cache::Cacheable::ClassMethods
          
          # Initialize class variables for this class
          @@cache_version : String = "v1"
          @@cacheable : Bool = true
        end
      end
    end
  end
end 