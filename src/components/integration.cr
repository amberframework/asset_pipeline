require "./reactive/reactive_handler"
require "./cache/configuration"
require "./elements/document/script"
require "./css/class_registry"
require "./css/class_builder"
require "./css/styleable"
require "./css/config/css_config"
require "./css/engine/css_generator"
require "./css/scanner/class_scanner"
require "./assets/css_asset"

module Components
  # Integration helpers for web frameworks
  module Integration
    # Create and configure a ReactiveHandler for the middleware pipeline
    def self.reactive_handler(
      websocket_path : String = "/components/ws",
      action_path : String = "/components/action",
      enable_fallback : Bool = true
    ) : Reactive::ReactiveHandler
      Reactive::ReactiveHandler.new(
        websocket_path: websocket_path,
        action_path_prefix: action_path,
        enable_http_fallback: enable_fallback
      )
    end
    
    # Configure caching
    def self.configure_cache(&block : Cache::Configuration -> Nil) : Nil
      Cache.configure(&block)
    end
    
    # Helper to include reactive JavaScript in layouts
    def self.reactive_script_tag(
      debug : Bool = false,
      auto_init : Bool = true,
      minified : Bool = true
    ) : String
      script_path = minified ? "/js/amber-reactive.min.js" : "/js/amber-reactive.js"
      
      Elements::Script.new(src: script_path, defer: "true").build do |script|
        if auto_init
          script << <<-JS
          document.addEventListener('DOMContentLoaded', function() {
            var reactive = new AmberReactive({debug: #{debug}});
            reactive.init();
            window.amberReactive = reactive;
          });
          JS
        end
      end.render
    end
    
    # Configure CSS system
    def self.configure_css(&block : CSS::Config -> Nil) : CSS::Config
      config = CSS::Config.new
      yield config
      config
    end
    
    # Generate CSS asset
    def self.css_asset(
      config : CSS::Config? = nil,
      mode : Symbol = :development,
      scan_paths : Array(String) = ["./src"]
    ) : Assets::CSSAsset
      # Scan for classes if paths provided
      unless scan_paths.empty?
        CSS::Scanner.scan_project(scan_paths)
      end
      
      # Create CSS asset
      config ||= CSS::Config.new
      Assets::CSS.create(config, mode)
    end
    
    # Helper to include CSS in layouts
    def self.css_tag(
      config : CSS::Config? = nil,
      mode : Symbol = :development,
      scan_paths : Array(String) = ["./src"]
    ) : String
      asset = css_asset(config, mode, scan_paths)
      asset.to_style_tag
    end
    
    # Helper to wrap a component for reactive updates
    def self.reactive_component(component : Component) : String
      # Register component if it's reactive
      if component.responds_to?(:register)
        component.register
      end
      
      # Render with reactive wrapper
      component.render
    end
    
    # Macro for Amber controllers to easily render components
    macro render_component(component_class, **params)
      component = {{component_class}}.new({{**params}})
      
      # Register reactive components
      if component.responds_to?(:register)
        component.register
      end
      
      # Render the component
      render html: component.render
    end
    
    # Macro for defining reactive actions in controllers
    macro reactive_action(name, &block)
      def {{name.id}}
        {{block.body}}
        
        # Return JSON response for AJAX requests
        if request.xhr?
          respond_with do
            json {
              success: true,
              componentId: params[:component_id]?,
              html: @component.try(&.render)
            }
          end
        end
      end
    end
  end
  
  # Example Amber integration module
  module AmberIntegration
    # Add reactive handler to Amber pipeline
    # 
    # Usage in config/routes.cr:
    #   pipeline :web do
    #     plug Components::Integration.reactive_handler
    #   end
    
    # View helper module
    module ViewHelpers
      # Render a component in a view
      def component(klass : Component.class, **params)
        comp = klass.new(**params)
        Components::Integration.reactive_component(comp)
      end
      
      # Include reactive JavaScript
      def reactive_scripts(debug = false)
        Components::Integration.reactive_script_tag(debug: debug)
      end
      
      # Include CSS styles
      def css_styles(config : CSS::Config? = nil, mode : Symbol = :development)
        Components::Integration.css_tag(config: config, mode: mode)
      end
      
      # CSS builder DSL
      def css(&block : CSS::ClassBuilder -> Nil) : String
        builder = Components::CSS::ClassBuilder.new
        yield builder
        builder.build
      end
    end
  end
end