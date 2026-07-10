module Components
  module Assets
    # Describes a web font delivery strategy without forcing CDN or
    # self-hosting. CDN assets emit stylesheet/preconnect tags; self-hosted
    # assets emit preload tags plus @font-face CSS.
    class FontAsset
      getter family : String
      getter href : String
      getter weight : String
      getter style : String
      getter format : String
      getter display : String
      getter strategy : Symbol
      getter preload : Bool

      def initialize(
        @family : String,
        @href : String,
        @weight : String = "400",
        @style : String = "normal",
        @format : String = "woff2",
        @display : String = "swap",
        @strategy : Symbol = :self_hosted,
        @preload : Bool = true,
      )
      end

      def self.cdn(family : String, stylesheet_href : String) : FontAsset
        new(
          family: family,
          href: stylesheet_href,
          strategy: :cdn,
          preload: false,
        )
      end

      def self.self_hosted(
        family : String,
        href : String,
        weight : String = "400",
        style : String = "normal",
        format : String = "woff2",
        display : String = "swap",
        preload : Bool = true,
      ) : FontAsset
        new(
          family: family,
          href: href,
          weight: weight,
          style: style,
          format: format,
          display: display,
          strategy: :self_hosted,
          preload: preload,
        )
      end

      def link_tags : String
        case strategy
        when :cdn
          preconnect = cdn_origin.try do |origin|
            %(<link rel="preconnect" href="#{escape(origin)}" crossorigin>)
          end
          [preconnect, %(<link rel="stylesheet" href="#{escape(href)}">)].compact.join("\n")
        else
          return "" unless preload

          %(<link rel="preload" href="#{escape(href)}" as="font" type="font/#{escape(format)}" crossorigin>)
        end
      end

      def font_face_css : String
        return "" if strategy == :cdn

        <<-CSS
        @font-face {
          font-family: "#{escape_css_string(family)}";
          src: url("#{escape_css_string(href)}") format("#{escape_css_string(format)}");
          font-weight: #{weight};
          font-style: #{style};
          font-display: #{display};
        }
        CSS
      end

      private def escape(value : String) : String
        value.gsub('&', "&amp;")
          .gsub('"', "&quot;")
          .gsub('<', "&lt;")
          .gsub('>', "&gt;")
      end

      private def escape_css_string(value : String) : String
        value.gsub("\\", "\\\\").gsub("\"", "\\\"")
      end

      private def cdn_origin : String?
        match = href.match(/\A(https?:\/\/[^\/]+)/)
        match.try(&.[1])
      end
    end

    class FontManifest
      getter assets : Array(FontAsset)

      def initialize(@assets : Array(FontAsset) = [] of FontAsset)
      end

      def <<(asset : FontAsset) : self
        @assets << asset
        self
      end

      def link_tags : String
        @assets.map(&.link_tags).reject(&.empty?).join("\n")
      end

      def font_face_css : String
        @assets.map(&.font_face_css).reject(&.empty?).join("\n")
      end
    end
  end
end
