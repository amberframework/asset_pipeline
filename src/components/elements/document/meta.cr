require "../base/void_element"

module Components
  module Elements
    # Represents the <meta> element - provides metadata about the HTML document
    class Meta < VoidElement
      def initialize(**attrs)
        super("meta", **attrs)
      end
      
      # Convenience constructors for common meta tags
      def self.charset(charset : String = "UTF-8")
        new(charset: charset)
      end
      
      def self.viewport(content : String = "width=device-width, initial-scale=1.0")
        new(name: "viewport", content: content)
      end
      
      def self.description(description : String)
        new(name: "description", content: description)
      end
      
      def self.keywords(keywords : String)
        new(name: "keywords", content: keywords)
      end
      
      def self.author(author : String)
        new(name: "author", content: author)
      end
      
      def self.http_equiv(http_equiv : String, content : String)
        new("http-equiv": http_equiv, content: content)
      end
      
      # Validate meta-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "charset"
          # Common charsets
          valid_charsets = ["UTF-8", "ISO-8859-1", "Windows-1252", "ASCII"]
          unless valid_charsets.includes?(value.to_s.upcase)
            # Don't error, just warn in development
          end
        when "http-equiv"
          valid_values = ["content-type", "refresh", "content-security-policy", "x-ua-compatible"]
          unless valid_values.includes?(value.to_s.downcase)
            # Additional http-equiv values are allowed
          end
        end
      end
    end
  end
end