require "./base/asset"
require "../css/engine/css_generator"
require "../css/class_registry"
require "../css/config/css_config"

module Components
  module Assets
    # CSS asset that generates styles based on used classes
    class CSSAsset < Asset
      @generator : Components::CSS::Engine::Generator
      @config : Components::CSS::Config
      @mode : Symbol # :development or :production
      
      def initialize(id : String, @config : Components::CSS::Config, @mode : Symbol = :development)
        super(id)
        @generator = Components::CSS::Engine::Generator.new(@config)
      end
      
      # Process the CSS
      def process : String
        # Generate CSS based on used classes
        css = @generator.generate
        
        # In production, minify the CSS
        if @mode == :production
          minify_css(css)
        else
          css
        end
      end
      
      # Content type for CSS
      def content_type : String
        "text/css"
      end
      
      # Path for this asset
      def path : String
        if @mode == :production
          "/assets/app-#{fingerprint}.css"
        else
          "/assets/app.css"
        end
      end
      
      # Minify CSS (basic implementation)
      private def minify_css(css : String) : String
        css
          # Remove comments
          .gsub(/\/\*[\s\S]*?\*\//, "")
          # Remove unnecessary whitespace
          .gsub(/\s+/, " ")
          # Remove space around selectors
          .gsub(/\s*([{}:;,])\s*/, "\\1")
          # Remove trailing semicolon
          .gsub(/;}/, "}")
          .strip
      end
      
      # Generate a style tag for this asset
      def to_style_tag : String
        if @mode == :production
          %(<link rel="stylesheet" href="#{path}">)
        else
          # In development, inline the CSS for faster updates
          %(<style>#{process}</style>)
        end
      end
      
      # Export the CSS to a file
      def export(output_path : String)
        File.write(output_path, process)
      end
    end
    
    # Convenience factory for CSS assets
    module CSS
      def self.create(config : Components::CSS::Config? = nil, mode : Symbol = :development) : CSSAsset
        config ||= Components::CSS::Config.new
        CSSAsset.new("main-css", config, mode)
      end
    end
  end
end