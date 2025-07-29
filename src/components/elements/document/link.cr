require "../base/void_element"

module Components
  module Elements
    # Represents the <link> element - specifies relationships between current document and external resource
    class Link < VoidElement
      def initialize(**attrs)
        super("link", **attrs)
      end
      
      # Convenience constructors for common link types
      def self.stylesheet(href : String)
        new(rel: "stylesheet", href: href)
      end
      
      def self.icon(href : String, type : String = "image/x-icon")
        new(rel: "icon", href: href, type: type)
      end
      
      def self.favicon(href : String)
        icon(href)
      end
      
      def self.apple_touch_icon(href : String, sizes : String? = nil)
        if sizes
          new(rel: "apple-touch-icon", href: href, sizes: sizes)
        else
          new(rel: "apple-touch-icon", href: href)
        end
      end
      
      def self.manifest(href : String)
        new(rel: "manifest", href: href)
      end
      
      def self.preconnect(href : String)
        new(rel: "preconnect", href: href)
      end
      
      def self.prefetch(href : String)
        new(rel: "prefetch", href: href)
      end
      
      def self.preload(href : String, as_type : String)
        new(rel: "preload", href: href, as: as_type)
      end
      
      # Validate link-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "rel"
          # Common rel values
          valid_rels = ["stylesheet", "icon", "manifest", "preconnect", "prefetch", 
                       "preload", "apple-touch-icon", "canonical", "alternate"]
          # Note: Many other rel values are valid, so we don't strictly enforce
        when "as"
          # Valid values for preload
          valid_as = ["audio", "document", "embed", "fetch", "font", "image", 
                     "object", "script", "style", "track", "video", "worker"]
          if @attributes["rel"]? == "preload" && !valid_as.includes?(value.to_s)
            raise ArgumentError.new("Invalid 'as' value for preload: #{value}")
          end
        when "type"
          # Validate MIME type format
          unless value.to_s.match(/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*$/)
            raise ArgumentError.new("Invalid MIME type format: #{value}")
          end
        end
      end
    end
  end
end