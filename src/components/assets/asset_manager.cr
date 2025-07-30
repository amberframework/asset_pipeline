require "./base/*"
require "./css/*"

module Components
  module Assets
    # Manages all assets in the pipeline
    class AssetManager
      # Singleton instance
      @@instance : AssetManager?
      
      def self.instance : AssetManager
        @@instance ||= new
      end
      
      # Registered assets
      getter assets : Hash(String, Asset)
      
      # Asset paths to watch
      getter watch_paths : Array(String)
      
      # Output directory
      property output_dir : String
      
      # Development mode flag
      property development : Bool
      
      # Asset manifest for production
      getter manifest : Hash(String, String)
      
      def initialize(
        @output_dir : String = "public/assets",
        @development : Bool = false
      )
        @assets = {} of String => Asset
        @watch_paths = [] of String
        @manifest = {} of String => String
      end
      
      # Register an asset
      def register(asset : Asset) : String
        @assets[asset.id] = asset
        
        # Add to manifest
        if asset.source_path
          @manifest[asset.source_path.not_nil!] = asset.output_filename
        end
        
        asset.id
      end
      
      # Register an asset from file
      def register_file(path : String) : String?
        return nil unless File.exists?(path)
        
        asset = case File.extname(path).downcase
        when ".css"
          CSSAsset.new(source_path: path)
        when ".js"
          JSAsset.new(source_path: path)
        when ".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".ico"
          ImageAsset.new(source_path: path)
        else
          # Generic static asset
          StaticAsset.new(source_path: path)
        end
        
        register(asset)
      end
      
      # Get an asset by ID
      def get(id : String) : Asset?
        @assets[id]?
      end
      
      # Get asset by source path
      def get_by_path(path : String) : Asset?
        @assets.values.find { |a| a.source_path == path }
      end
      
      # Process all assets
      def process_all : Nil
        @assets.each_value(&.process)
      end
      
      # Build all assets to output directory
      def build : Nil
        # Ensure output directory exists
        Dir.mkdir_p(@output_dir)
        
        # Process and write each asset
        @assets.each_value do |asset|
          output_path = File.join(@output_dir, asset.output_filename)
          
          case asset
          when ImageAsset
            # Copy image files
            if source = asset.source_path
              File.copy(source, output_path) if File.exists?(source)
            end
          else
            # Write processed content
            File.write(output_path, asset.processed_content)
            
            # Write source map if applicable
            if asset.responds_to?(:generate_source_map)
              if map = asset.generate_source_map
                File.write("#{output_path}.map", map)
              end
            end
          end
        end
        
        # Write manifest
        write_manifest
      end
      
      # Write asset manifest
      private def write_manifest : Nil
        manifest_path = File.join(@output_dir, "manifest.json")
        File.write(manifest_path, @manifest.to_pretty_json)
      end
      
      # Watch for file changes
      def watch : Nil
        # This would integrate with a file watcher
        # For now, just reload modified assets
        @assets.each_value do |asset|
          asset.reload if asset.modified?
        end
      end
      
      # Clear all assets
      def clear : Nil
        @assets.clear
        @manifest.clear
      end
      
      # Get asset URL for templates
      def asset_url(path : String) : String
        if @development
          # In development, use original path
          "/assets/#{path}"
        else
          # In production, use fingerprinted path from manifest
          filename = @manifest[path]? || path
          "/assets/#{filename}"
        end
      end
      
      # Precompile assets from directory
      def precompile(directory : String, pattern : String = "**/*") : Nil
        Dir.glob(File.join(directory, pattern)) do |file|
          next if File.directory?(file)
          register_file(file)
        end
      end
      
      # Get all CSS assets
      def css_assets : Array(CSSAsset)
        @assets.values.select { |a| a.is_a?(CSSAsset) }.map(&.as(CSSAsset))
      end
      
      # Get all JS assets
      def js_assets : Array(JSAsset)
        @assets.values.select { |a| a.is_a?(JSAsset) }.map(&.as(JSAsset))
      end
      
      # Get all image assets
      def image_assets : Array(ImageAsset)
        @assets.values.select { |a| a.is_a?(ImageAsset) }.map(&.as(ImageAsset))
      end
      
      # Generate asset tags for HTML
      def stylesheet_link_tags : String
        css_assets.map do |asset|
          url = asset_url(asset.source_path || asset.id)
          %(<link rel="stylesheet" href="#{url}">)
        end.join("\n")
      end
      
      def javascript_include_tags : String
        js_assets.map do |asset|
          url = asset_url(asset.source_path || asset.id)
          %(<script src="#{url}"></script>)
        end.join("\n")
      end
    end
    
    # Convenience methods
    def self.register(asset : Asset) : String
      AssetManager.instance.register(asset)
    end
    
    def self.register_file(path : String) : String?
      AssetManager.instance.register_file(path)
    end
    
    def self.asset_url(path : String) : String
      AssetManager.instance.asset_url(path)
    end
    
    def self.build : Nil
      AssetManager.instance.build
    end
  end
end