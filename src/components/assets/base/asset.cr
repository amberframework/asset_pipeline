module Components
  module Assets
    # Base class for all assets in the pipeline
    abstract class Asset
      # Unique identifier for this asset
      getter id : String
      
      # Source file path (if file-based)
      getter? source_path : String?
      
      # Asset content
      property content : String
      
      # Asset metadata
      getter metadata : Hash(String, String)
      
      # Dependencies on other assets
      getter dependencies : Array(String)
      
      # Timestamp for cache invalidation
      getter updated_at : Time
      
      def initialize(@source_path : String? = nil, @content : String = "")
        @id = generate_id
        @metadata = {} of String => String
        @dependencies = [] of String
        @updated_at = Time.utc
        
        # Load content from file if path provided
        if path = @source_path
          @content = File.read(path) if File.exists?(path)
        end
      end
      
      # Abstract method - must be implemented by subclasses
      abstract def content_type : String
      
      # Process the asset (compile, optimize, etc.)
      abstract def process : String
      
      # Get the output filename for this asset
      def output_filename : String
        if source = source_path
          basename = File.basename(source)
          "#{File.basename(basename, File.extname(basename))}-#{fingerprint}#{File.extname(basename)}"
        else
          "#{@id}-#{fingerprint}"
        end
      end
      
      # Generate a fingerprint for cache busting
      def fingerprint : String
        digest = OpenSSL::Digest.new("SHA256")
        digest.update(processed_content)
        digest.final.hexstring[0..7]
      end
      
      # Get processed content (cached)
      @processed_content : String?
      def processed_content : String
        @processed_content ||= process
      end
      
      # Check if asset has been modified
      def modified? : Bool
        return false unless path = source_path
        return true unless File.exists?(path)
        
        File.info(path).modification_time > @updated_at
      end
      
      # Reload content from source
      def reload : Nil
        return unless path = source_path
        return unless File.exists?(path)
        
        @content = File.read(path)
        @updated_at = Time.utc
        @processed_content = nil
      end
      
      # Add a dependency
      def add_dependency(asset_id : String) : Nil
        @dependencies << asset_id unless @dependencies.includes?(asset_id)
      end
      
      # Remove a dependency
      def remove_dependency(asset_id : String) : Nil
        @dependencies.delete(asset_id)
      end
      
      # Set metadata
      def set_metadata(key : String, value : String) : Nil
        @metadata[key] = value
      end
      
      # Get metadata
      def get_metadata(key : String) : String?
        @metadata[key]?
      end
      
      # Generate a unique ID
      private def generate_id : String
        "asset-#{Time.utc.to_unix_ms}-#{Random.rand(10000)}"
      end
      
      # Convert to hash for serialization
      def to_h : Hash(String, JSON::Any)
        {
          "id" => JSON::Any.new(@id),
          "type" => JSON::Any.new(self.class.name),
          "content_type" => JSON::Any.new(content_type),
          "source_path" => JSON::Any.new(@source_path),
          "fingerprint" => JSON::Any.new(fingerprint),
          "output_filename" => JSON::Any.new(output_filename),
          "dependencies" => JSON::Any.new(@dependencies.map { |d| JSON::Any.new(d) }),
          "metadata" => JSON::Any.new(@metadata.transform_values { |v| JSON::Any.new(v) }),
          "updated_at" => JSON::Any.new(@updated_at.to_unix)
        }
      end
    end
  end
end