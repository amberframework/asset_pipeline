module AssetPipeline
  module Components
    module Cache
      # Global configuration for component caching
      class CacheConfig
        # Singleton instance
        @@instance : CacheConfig?
        
        # Global cache settings
        @enabled : Bool
        @default_expires_in : Time::Span?
        @development_mode : Bool
        @cache_on_development : Bool
        @cache_on_production : Bool
        @namespace : String
        @component_specific_config : Hash(String, ComponentCacheConfig)
        
        def initialize
          @enabled = true
          @default_expires_in = nil # No expiration by default
          @development_mode = false
          @cache_on_development = false # Disabled by default in development
          @cache_on_production = true   # Enabled by default in production
          @namespace = "components"
          @component_specific_config = Hash(String, ComponentCacheConfig).new
        end
        
        def self.instance : CacheConfig
          @@instance ||= new
        end
        
        # Global cache control
        property enabled : Bool
        property default_expires_in : Time::Span?
        property development_mode : Bool
        property cache_on_development : Bool
        property cache_on_production : Bool
        property namespace : String
        
        # Check if caching should be enabled based on environment
        def cache_enabled? : Bool
          return false unless @enabled
          
          if @development_mode
            @cache_on_development
          else
            @cache_on_production
          end
        end
        
        # Configure global cache settings
        def configure
          yield self
          update_cache_manager_state
        end
        
        # Set development mode
        def set_development_mode!(enabled : Bool = true)
          @development_mode = enabled
          update_cache_manager_state
        end
        
        # Set production mode
        def set_production_mode!
          @development_mode = false
          update_cache_manager_state
        end
        
        # Enable caching globally
        def enable_cache!
          @enabled = true
          update_cache_manager_state
        end
        
        # Disable caching globally
        def disable_cache!
          @enabled = false
          update_cache_manager_state
        end
        
        # Component-specific configuration
        def configure_component(component_name : String, &block : ComponentCacheConfig -> Nil)
          config = @component_specific_config[component_name] ||= ComponentCacheConfig.new(component_name)
          yield config
        end
        
        def get_component_config(component_name : String) : ComponentCacheConfig
          @component_specific_config[component_name] ||= ComponentCacheConfig.new(component_name)
        end
        
        # Check if a specific component should be cached
        def component_cacheable?(component_name : String) : Bool
          return false unless cache_enabled?
          
          component_config = @component_specific_config[component_name]?
          return true unless component_config # Default to enabled if no specific config
          
          component_config.enabled?
        end
        
        # Get cache expiration for a specific component
        def component_expires_in(component_name : String) : Time::Span?
          component_config = @component_specific_config[component_name]?
          component_config.try(&.expires_in) || @default_expires_in
        end
        
        # Bulk operations
        def disable_components(component_names : Array(String))
          component_names.each do |name|
            configure_component(name) { |config| config.disable! }
          end
        end
        
        def enable_components(component_names : Array(String))
          component_names.each do |name|
            configure_component(name) { |config| config.enable! }
          end
        end
        
        # Cache warming configuration
        def enable_cache_warming_for(component_names : Array(String))
          component_names.each do |name|
            configure_component(name) { |config| config.enable_cache_warming! }
          end
        end
        
        # Statistics and monitoring
        def cache_statistics : Hash(String, Int32 | String | Bool | Float64)
          stats = ComponentCacheManager.instance.stats
          stats["global_enabled"] = @enabled
          stats["environment_enabled"] = cache_enabled?
          stats["development_mode"] = @development_mode
          stats["namespace"] = @namespace
          stats["configured_components"] = @component_specific_config.size
          stats
        end
        
        # Reset all configuration to defaults
        def reset_to_defaults!
          @enabled = true
          @default_expires_in = nil
          @development_mode = false
          @cache_on_development = false
          @cache_on_production = true
          @namespace = "components"
          @component_specific_config.clear
          update_cache_manager_state
        end
        
        # Load configuration from environment variables
        def load_from_env
          @enabled = ENV["COMPONENT_CACHE_ENABLED"]? != "false"
          @cache_on_development = ENV["COMPONENT_CACHE_DEVELOPMENT"]? == "true"
          @cache_on_production = ENV["COMPONENT_CACHE_PRODUCTION"]? != "false"
          @namespace = ENV["COMPONENT_CACHE_NAMESPACE"]? || "components"
          
          if expires_str = ENV["COMPONENT_CACHE_DEFAULT_EXPIRES"]?
            if seconds = expires_str.to_i?
              @default_expires_in = seconds.seconds
            end
          end
          
          update_cache_manager_state
        end
        
        # Export configuration for debugging
        def to_hash : Hash(String, Bool | String | Int32 | Float64 | Nil)
          {
            "enabled" => @enabled,
            "cache_enabled" => cache_enabled?,
            "development_mode" => @development_mode,
            "cache_on_development" => @cache_on_development,
            "cache_on_production" => @cache_on_production,
            "namespace" => @namespace,
            "default_expires_in_seconds" => @default_expires_in.try(&.total_seconds.to_i),
            "configured_components_count" => @component_specific_config.size
          }
        end
        
        private def update_cache_manager_state
          ComponentCacheManager.enabled = cache_enabled?
        end
      end
      
      # Component-specific cache configuration
      class ComponentCacheConfig
        property component_name : String
        @enabled : Bool
        @expires_in : Time::Span?
        @cache_warming_enabled : Bool
        @version : String
        
        def initialize(@component_name : String)
          @enabled = true
          @expires_in = nil
          @cache_warming_enabled = false
          @version = "1"
        end
        
        property expires_in : Time::Span?
        property cache_warming_enabled : Bool
        property version : String
        
        def enabled? : Bool
          @enabled
        end
        
        def enable!
          @enabled = true
        end
        
        def disable!
          @enabled = false
        end
        
        def enable_cache_warming!
          @cache_warming_enabled = true
        end
        
        def disable_cache_warming!
          @cache_warming_enabled = false
        end
        
        # Set cache expiration
        def expires_in=(duration : Time::Span?)
          @expires_in = duration
        end
        
        def expires_in_seconds=(seconds : Int32)
          @expires_in = seconds.seconds
        end
        
        def expires_in_minutes=(minutes : Int32)
          @expires_in = minutes.minutes
        end
        
        def expires_in_hours=(hours : Int32)
          @expires_in = hours.hours
        end
        
        # Version management for cache busting
        def increment_version!
          current = @version.to_i? || 1
          @version = (current + 1).to_s
        end
        
        def set_version(version : String)
          @version = version
        end
        
        # Configuration summary
        def to_hash : Hash(String, Bool | String | Int32 | Nil)
          {
            "component_name" => @component_name,
            "enabled" => @enabled,
            "expires_in_seconds" => @expires_in.try(&.total_seconds.to_i),
            "cache_warming_enabled" => @cache_warming_enabled,
            "version" => @version
          }
        end
      end
    end
  end
end 