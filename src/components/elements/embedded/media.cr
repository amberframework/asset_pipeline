require "../base/container_element"
require "../base/void_element"
require "../base/url_attribute_validation"

module Components
  module Elements
    # Represents the <video> element - video content
    class Video < ContainerElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): both `src` (the video
      # resource) and `poster` (the preview-frame image) are URL-bearing.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("video", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src" || name == "poster"
      end

      # Validate video-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "controls", "autoplay", "loop", "muted", "playsinline"
          # Boolean attributes
        when "preload"
          valid_values = ["none", "metadata", "auto"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid preload value: #{value}")
          end
        when "crossorigin"
          valid_values = ["anonymous", "use-credentials"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid crossorigin value: #{value}")
          end
        end
      end
    end
    
    # Represents the <audio> element - audio content
    class Audio < ContainerElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `src` is URL-bearing.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("audio", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src"
      end

      # Validate audio-specific attributes (similar to video)
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "controls", "autoplay", "loop", "muted"
          # Boolean attributes
        when "preload"
          valid_values = ["none", "metadata", "auto"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid preload value: #{value}")
          end
        when "crossorigin"
          valid_values = ["anonymous", "use-credentials"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid crossorigin value: #{value}")
          end
        end
      end
    end
    
    # Represents the <source> element - media resource
    class Source < VoidElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `src` is URL-bearing.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("source", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src"
      end

      # Validate source-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Should be a valid MIME type
          unless value.to_s.match(/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*$/)
            raise ArgumentError.new("Invalid MIME type format: #{value}")
          end
        when "media"
          # Media queries are complex to validate
        end
      end
    end
    
    # Represents the <track> element - text track for media
    class Track < VoidElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `src` (the WebVTT file
      # URL) is URL-bearing.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("track", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src"
      end

      # Validate track-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "kind"
          valid_kinds = ["subtitles", "captions", "descriptions", "chapters", "metadata"]
          if value && !valid_kinds.includes?(value)
            raise ArgumentError.new("Invalid track kind: #{value}")
          end
        when "srclang"
          # Should be a valid language code
        end
      end
    end
    
    # Represents the <iframe> element - nested browsing context
    class Iframe < ContainerElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `src` loads an entire
      # nested browsing context — a `javascript:`/`data:` value here is one
      # of the highest-value URL sinks in the whole element set.
      include UrlAttributeValidation

      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.5): `srcdoc` is an
      # HTML-DOCUMENT-VALUED attribute, not a plain string one. The browser
      # HTML-entity-decodes the (correctly-escaped-for-the-*outer*-document)
      # attribute value and then feeds the decoded result to a *fresh HTML
      # parser* as the entire source document for the iframe's nested
      # browsing context. `HTMLElement#escape_attribute` protects the
      # *outer* document's parse (so the attribute stays well-formed) but
      # does nothing to stop a `<script>` inside that re-parsed nested
      # document from executing — value-escaping is the wrong tool for this
      # sink, exactly as it is for `javascript:` URLs, just one layer
      # removed. This makes `srcdoc` exactly as dangerous as `<script>`
      # body content (see `Elements::Script`), just carried in an attribute
      # instead of element children — so it gets the identical treatment:
      # a bare `String` is banned unconditionally, with a loud, reasoned,
      # typed door as the only way through.
      #
      # `@vouched_srcdoc` holds the exact `String` that was accepted through
      # that door. `@attributes` (the `Hash(String, String)` that backs
      # every other attribute) is a public, mutable `getter` on
      # `HTMLElement` — nothing stops `iframe.attributes["srcdoc"] = "..."`
      # from mutating it directly, the same public-mutable-getter bypass
      # `docs/SAFE_HTML_V1.md` §3.4 closes for `Script#children` via a
      # render-time backstop. `render_attributes` below re-checks, immediately
      # before emitting bytes, that whatever currently sits at
      # `@attributes["srcdoc"]` is identical to the exact value that was
      # vouched — closing that bypass too.
      @vouched_srcdoc : String? = nil

      def initialize(**attrs)
        super("iframe", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src"
      end

      # The typed, reasoned door for `srcdoc` — mirrors `Script.static(js,
      # reason:)` / `SafeURL.unsafe(url, reason:)`. Builds a fresh `Iframe`
      # with `srcdoc` set from the vouched HTML. Any other constructor kwarg
      # (`src`, `title`, `sandbox`, `loading`, ...) is still accepted and
      # still validated normally.
      def self.srcdoc(html : String, reason : String, **attrs) : Iframe
        raise ArgumentError.new("Iframe.srcdoc requires a non-empty `reason:` explaining why this HTML is trusted") if reason.strip.empty?
        instance = new(**attrs)
        instance.set_vouched_srcdoc(html)
        instance
      end

      # The typed, reasoned door for setting `srcdoc` on an already-built
      # `Iframe` — the shape most call sites need (an `Iframe` constructed
      # first via ordinary kwargs, `srcdoc` attached after), mirroring the
      # already-existing instance-level typed setters
      # `#set_safe_url_attribute` / `#set_safe_style`. `reason:` is
      # mandatory, matching every other vouching door in this shard.
      def set_srcdoc(html : String, reason : String) : self
        raise ArgumentError.new("Iframe#set_srcdoc requires a non-empty `reason:` explaining why this HTML is trusted") if reason.strip.empty?
        set_vouched_srcdoc(html)
        self
      end

      # :nodoc: the one place that is allowed to write `srcdoc` into
      # `@attributes` directly (bypassing the `#set_attribute` ban below) —
      # only reachable via the two reasoned doors above.
      protected def set_vouched_srcdoc(html : String) : Nil
        @vouched_srcdoc = html
        @attributes["srcdoc"] = html
      end

      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.5): reject a bare-`String`
      # `srcdoc` here — this is the chokepoint both the constructor-kwarg
      # path (`HTMLElement#initialize` calls `#set_attribute` once per
      # kwarg) and the direct `#set_attribute` path funnel through, so one
      # check closes both, matching how `UrlAttributeValidation` closes
      # `src`/`href` for the very same two paths. Name comparison is
      # normalized (`strip.downcase`) so `SRCDOC`, `Srcdoc`, and
      # `" srcdoc"` are all caught too — real HTML attribute names are
      # ASCII-case-insensitive and tolerant of incidental whitespace from
      # hand-built call sites, exactly like `UrlAttributeValidation`'s own
      # normalization.
      def set_attribute(name : String, value : String?) : self
        if value && name.strip.downcase == "srcdoc"
          raise srcdoc_string_ban_error(name, value)
        end
        super
      end

      private def srcdoc_string_ban_error(name : String, value : String) : ArgumentError
        ArgumentError.new(
          "SafeHTML ban: #{name.inspect}=... rejected. <iframe srcdoc> is an " \
          "HTML-DOCUMENT-valued attribute -- the browser re-parses the " \
          "decoded value as the iframe's entire nested document, so a bare " \
          "String is banned exactly like <script> body content. Use " \
          "Iframe.srcdoc(html, reason: \"...\") or " \
          "iframe.set_srcdoc(html, reason: \"...\") instead."
        )
      end

      # Validate iframe-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super

        case name
        when "sandbox"
          # Can be empty or space-separated list of allowed features
          valid_tokens = ["allow-downloads", "allow-forms", "allow-modals",
                         "allow-orientation-lock", "allow-pointer-lock",
                         "allow-popups", "allow-popups-to-escape-sandbox",
                         "allow-presentation", "allow-same-origin",
                         "allow-scripts", "allow-top-navigation"]
          # Validate tokens if needed
        when "loading"
          valid_values = ["lazy", "eager"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid loading value: #{value}")
          end
        end
      end

      # RENDER-TIME invariant enforcement — the actual backstop, matching
      # `Script#render_children` (docs/SAFE_HTML_V1.md §3.4/§3.5). `#set_attribute`
      # above rejects a bare-String `srcdoc` at call time, but `@attributes`
      # is reachable directly through the public, mutable `attributes`
      # getter (`HTMLElement#attributes`), completely bypassing
      # `#set_attribute`. This re-checks the invariant at the one point
      # that can't be bypassed: immediately before emitting bytes. The
      # current `@attributes["srcdoc"]` value must be `==` the exact
      # `String` that was vouched via `Iframe.srcdoc`/`#set_srcdoc` — any
      # other value (including a same-named but different string written
      # directly into the Hash) is rejected, fail-closed.
      protected def render_attributes : String
        if value = @attributes["srcdoc"]?
          unless value == @vouched_srcdoc
            raise srcdoc_string_ban_error("srcdoc", value)
          end
        end
        super
      end
    end
    
    # Represents the <embed> element - external content
    class Embed < VoidElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): `src` is URL-bearing.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("embed", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src"
      end

      # Validate embed-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Should be a valid MIME type
          unless value.to_s.match(/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*$/)
            raise ArgumentError.new("Invalid MIME type format: #{value}")
          end
        end
      end
    end
    
    # Represents the <object> element - external resource
    class Object < ContainerElement
      def initialize(**attrs)
        super("object", **attrs)
      end
      
      # Validate object-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Should be a valid MIME type
          unless value.to_s.match(/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*$/)
            raise ArgumentError.new("Invalid MIME type format: #{value}")
          end
        end
      end
    end
    
    # Represents the <param> element - parameter for object
    class Param < VoidElement
      def initialize(**attrs)
        super("param", **attrs)
      end
      
      # Validate param-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "name", "value"
          # Both are required for param element
          if value.nil? || value.empty?
            raise ArgumentError.new("param element requires both name and value attributes")
          end
        end
      end
    end
    
    # Represents the <canvas> element - graphics canvas
    class Canvas < ContainerElement
      def initialize(**attrs)
        super("canvas", **attrs)
      end
    end
    
    # Represents the <svg> element - scalable vector graphics
    class Svg < ContainerElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.6): `<svg>` is HTML5
      # foreign-content -- the tokenizer switches into the SVG namespace for
      # everything inside it, but a `<script>` element inside that
      # namespace is still recognized and STILL EXECUTES
      # (`<svg><script>alert(1)</script></svg>` is a well-known,
      # browser-verified XSS payload class, inline in an ordinary HTML
      # document, not just a standalone `.svg` file). A previous version of
      # this class overrode `render_children` to pass `String` children
      # through completely unescaped ("SVG content is not escaped like
      # HTML") -- that is exactly as dangerous as `<script>` accepting a
      # plain-String child, just reached through a different element. There
      # is no legitimate reason a String *child* of `Svg` needs to bypass
      # escaping: real hand-authored SVG markup (`<path d="...">` and
      # friends) is built the same way any other raw/vouched markup is in
      # this shard -- `RawHTML.new(...)` / `add_raw_html(...)` (already a
      # documented, greppable raw door, see docs/SAFE_HTML_V1.md §4) -- not
      # by relying on `Svg` silently treating every `String` as markup.
      # Removing the override restores the inherited, safe
      # `ContainerElement#render_children` behavior: `HTMLElement`/`RawHTML`
      # children render as before, and a `String` child is HTML-escaped
      # like a text node on every other element.
      def initialize(**attrs)
        super("svg", **attrs)
      end
    end
    
    # Represents the <picture> element - multiple image sources
    class Picture < ContainerElement
      def initialize(**attrs)
        super("picture", **attrs)
      end
    end
  end
end