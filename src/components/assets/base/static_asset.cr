require "./asset"

module Components
  module Assets
    # Generic static asset (fonts, videos, etc.)
    class StaticAsset < Asset
      def content_type : String
        return @metadata["content_type"] if @metadata.has_key?("content_type")
        
        # Guess content type from extension
        if path = source_path
          case File.extname(path).downcase
          when ".woff", ".woff2"
            "font/woff2"
          when ".ttf"
            "font/ttf"
          when ".otf"
            "font/otf"
          when ".eot"
            "application/vnd.ms-fontobject"
          when ".mp4"
            "video/mp4"
          when ".webm"
            "video/webm"
          when ".mp3"
            "audio/mpeg"
          when ".ogg"
            "audio/ogg"
          when ".pdf"
            "application/pdf"
          when ".json"
            "application/json"
          when ".xml"
            "application/xml"
          when ".txt"
            "text/plain"
          else
            "application/octet-stream"
          end
        else
          "application/octet-stream"
        end
      end
      
      # No processing for static assets
      def process : String
        @content
      end
      
      # Override fingerprint for binary files
      def fingerprint : String
        if path = source_path
          # For binary files, use file checksum
          digest = OpenSSL::Digest.new("SHA256")
          File.open(path, "rb") do |file|
            buffer = Bytes.new(8192)
            while (bytes_read = file.read(buffer)) > 0
              digest.update(buffer[0, bytes_read])
            end
          end
          digest.final.hexstring[0..7]
        else
          super
        end
      end
    end
  end
end