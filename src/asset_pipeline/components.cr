# Asset Pipeline Component System
# Main entry point for the component system

# Cache system (load first as base classes depend on it)
require "./components/cache/cache_store"
require "./components/cache/test_cache_store"
require "./components/cache/cacheable"
require "./components/cache/component_cache_manager"
require "./components/cache/cache_config"

# Base classes
require "./components/base/component"
require "./components/base/stateless_component"
require "./components/base/stateful_component"

# HTML utilities
require "./components/html/html_element"
require "./components/html/html_helpers"

# CSS registry and optimization
require "./components/css_registry"

# Asset Pipeline Integration
require "./components/asset_pipeline/component_asset_generator"
require "./components/asset_pipeline/component_asset_handler"
require "./components/asset_pipeline/css_optimizer"
require "./components/asset_pipeline/front_loader_extensions"

# Example components
require "./components/examples/button"
require "./components/examples/counter"

module AssetPipeline
  module Components
    # Version of the component system
    VERSION = "0.1.0"
    
    # Configuration for the component system
    class Config
      # Global settings
      @@auto_register_css : Bool = true
      @@development_mode : Bool = true
      @@enable_css_optimization : Bool = true
      
      def self.auto_register_css=(value : Bool)
        @@auto_register_css = value
      end
      
      def self.auto_register_css
        @@auto_register_css
      end
      
      def self.development_mode=(value : Bool)
        @@development_mode = value
      end
      
      def self.development_mode
        @@development_mode
      end
      
      def self.enable_css_optimization=(value : Bool)
        @@enable_css_optimization = value
      end
      
      def self.enable_css_optimization
        @@enable_css_optimization
      end
    end
    
    # Component renderer with automatic CSS registration
    class ComponentRenderer
      def self.render(component : Component) : String
        # Auto-register CSS classes if enabled
        if Config.auto_register_css
          case component
          when StatelessComponent
            CSSRegistryHelper.register(component)
          when StatefulComponent
            CSSRegistryHelper.register(component)
          end
        end
        
        component.render
      end
      
      def self.render_with_assets(component : StatefulComponent) : Hash(String, String)
        rendered_html = render(component)
        
        assets = {
          "html" => rendered_html,
          "javascript" => component.has_javascript? ? component.javascript_content : "",
          "css" => component.has_css? ? component.css_content : ""
        }
        
        assets
      end
    end
    
    # Utility methods for working with components
    module ComponentHelpers
      # Render a component and return HTML
      def component(comp : Component) : String
        ComponentRenderer.render(comp)
      end
      
      # Render a stateful component with all its assets
      def component_with_assets(comp : StatefulComponent) : Hash(String, String)
        ComponentRenderer.render_with_assets(comp)
      end
      
      # Get CSS optimization report
      def css_optimization_report
        CSSRegistry.instance.optimization_report
      end
      
      # Get all CSS classes used by components
      def used_css_classes
        CSSRegistry.instance.all_used_classes
      end
      
      # Clear CSS registry (useful for testing)
      def clear_css_registry!
        CSSRegistry.instance.clear!
      end
      
      # Generate CSS purge whitelist
      def css_purge_whitelist
        CSSRegistry.instance.generate_purge_whitelist
      end
    end
    
    # Include HTML helpers for easy access
    include Html::HTMLHelpers
    
    # Extend the module to make helpers available at module level
    extend ComponentHelpers
  end
end

# Make the HTML helpers available at the top level for convenience
include AssetPipeline::Components::Html::HTMLHelpers 