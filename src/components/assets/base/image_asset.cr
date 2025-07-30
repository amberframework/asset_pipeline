require "./asset"
require "base64"

module Components
  module Assets
    # Image asset with optimization capabilities
    class ImageAsset < Asset
      # Supported image formats
      SUPPORTED_FORMATS = %w[jpg jpeg png gif webp svg ico]
      
      # Image-specific metadata
      property width : Int32?
      property height : Int32?
      property format : String?
      
      def initialize(source_path : String)
        super(source_path: source_path)
        
        @format = File.extname(source_path).downcase.lstrip(".")
        unless SUPPORTED_FORMATS.includes?(@format)
          raise ArgumentError.new("Unsupported image format: #{@format}")
        end
        
        # For binary files, we don't load content as string
        @content = ""
      end
      
      def content_type : String
        case @format
        when "jpg", "jpeg"
          "image/jpeg"
        when "png"
          "image/png"
        when "gif"
          "image/gif"
        when "webp"
          "image/webp"
        when "svg"
          "image/svg+xml"
        when "ico"
          "image/x-icon"
        else
          "application/octet-stream"
        end
      end
      
      # Process image (optimization would happen here)
      def process : String
        # In a real implementation, we'd use image processing libraries
        # For now, just return the path
        source_path || ""
      end
      
      # Get image dimensions (placeholder)
      def dimensions : {Int32, Int32}?
        return nil unless @width && @height
        {@width.not_nil!, @height.not_nil!}
      end
      
      # Generate responsive image set
      def responsive_set(sizes : Array(Int32)) : Hash(Int32, String)
        result = {} of Int32 => String
        
        sizes.each do |size|
          # In production, actually resize the image
          result[size] = "#{output_filename}?w=#{size}"
        end
        
        result
      end
      
      # Convert to base64 data URI
      def to_data_uri : String?
        return nil unless path = source_path
        return nil unless File.exists?(path)
        
        encoded = Base64.strict_encode(File.read(path))
        "data:#{content_type};base64,#{encoded}"
      end
      
      # Generate blur placeholder (simplified)
      def blur_placeholder : String
        # In production, generate actual blurred placeholder
        # For now, return a simple colored placeholder
        "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='#{@width || 100}' height='#{@height || 100}'%3E%3Crect width='100%25' height='100%25' fill='%23ddd'/%3E%3C/svg%3E"
      end
      
      # Check if image should be lazy loaded
      def lazy_load? : Bool
        # Could be based on size, position, etc.
        true
      end
      
      # Generate picture element for responsive images
      def picture_element(
        sizes : String = "100vw",
        loading : String = "lazy",
        alt : String = "",
        class_name : String? = nil
      ) : String
        <<-HTML
        <picture>
          <source type="image/webp" srcset="#{output_filename}?format=webp">
          <img 
            src="#{output_filename}" 
            alt="#{alt}"
            loading="#{loading}"
            #{@width ? "width=\"#{@width}\"" : ""}
            #{@height ? "height=\"#{@height}\"" : ""}
            #{class_name ? "class=\"#{class_name}\"" : ""}
          >
        </picture>
        HTML
      end
    end
  end
end