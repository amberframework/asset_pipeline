require "../base/void_element"
require "../../safe/safe_url"

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

      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `<meta http-equiv="refresh"
      # content="N; url=...">` is a URL-bearing sink the proposal calls out
      # by name, but its `content` value is a *compound* format ("seconds;
      # url=..."), not a plain URL — so the generic
      # `HTMLElement#set_safe_url_attribute` (which sets an attribute
      # verbatim from a `SafeURL`) is the wrong shape for it. This is the
      # dedicated typed constructor: `url` is validated the same way any
      # other URL-bearing attribute is, and the compound value is assembled
      # only from a validated `SafeURL` plus a plain integer.
      def self.safe_refresh(seconds : Int32, url : SafeURL) : Meta
        raise ArgumentError.new("Meta.safe_refresh: seconds must be >= 0") if seconds < 0
        http_equiv("refresh", "#{seconds}; url=#{url}")
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
