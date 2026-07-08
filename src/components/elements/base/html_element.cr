require "../../css/class_registry"
require "../../safe/safe_url"
require "../../safe/safe_style"

module Components
  module Elements
    # Abstract base class for all HTML elements
    abstract class HTMLElement
      getter tag_name : String
      getter attributes : Hash(String, String)
      getter children : Array(HTMLElement | String | RawHTML)

      def initialize(@tag_name : String, **attrs)
        @attributes = {} of String => String
        @children = [] of HTMLElement | String | RawHTML

        # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.7): the exact `String` values
        # vouched into an HTML-DOCUMENT-valued attribute (currently only
        # `<iframe srcdoc>`) through a typed door, keyed by the
        # `name.strip.downcase`-normalized attribute name. `render_attributes`
        # (below) is the sole authority that checks against this map — see
        # `document_sink_attribute?`/`vouch_document_attribute`.
        @vouched_document_attributes = {} of String => String

        # Process attributes
        attrs.each do |key, value|
          set_attribute(key.to_s, value.to_s)
        end
      end

      # Set an attribute with validation
      def set_attribute(name : String, value : String?) : self
        return self if value.nil?

        # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.1b): reject a malformed
        # attribute NAME before anything else. This is the single
        # chokepoint every attribute flows through — see
        # `validate_attribute_name!` below for why.
        validate_attribute_name!(name)

        # Validate the attribute
        validate_attribute(name, value)

        # Handle special attributes
        case name
        when "class"
          add_class(value)
        when "style"
          add_style(value)
        else
          @attributes[name] = value
        end

        self
      end

      # Remove an attribute
      def remove_attribute(name : String) : self
        @attributes.delete(name)
        self
      end

      # Add CSS classes
      def add_class(class_names : String) : self
        existing = @attributes["class"]?.to_s.split(/\s+/).reject(&.empty?)
        new_classes = class_names.split(/\s+/).reject(&.empty?)

        combined = (existing + new_classes).uniq
        @attributes["class"] = combined.join(" ") unless combined.empty?

        # Register classes with the CSS system
        Components::CSS::ClassRegistry.instance.register_class(combined.join(" "))

        self
      end

      # Remove CSS classes
      def remove_class(class_names : String) : self
        return self unless @attributes.has_key?("class")

        existing = @attributes["class"].split(/\s+/).reject(&.empty?)
        to_remove = class_names.split(/\s+/).reject(&.empty?)

        remaining = existing - to_remove

        if remaining.empty?
          @attributes.delete("class")
        else
          @attributes["class"] = remaining.join(" ")
        end

        self
      end

      # Add inline styles
      def add_style(styles : String) : self
        existing = @attributes["style"]?.to_s

        if existing.empty?
          @attributes["style"] = styles
        else
          # Ensure existing ends with semicolon
          existing = existing + ";" unless existing.ends_with?(";")
          @attributes["style"] = existing + " " + styles
        end

        self
      end

      # Get an attribute value
      def [](name : String) : String?
        @attributes[name]?
      end

      # Check if element has a specific class
      def has_class?(class_name : String) : Bool
        return false unless classes = @attributes["class"]?
        classes.split(/\s+/).includes?(class_name)
      end

      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.1b): the GENERAL fix for the
      # re-gate finding that closed the case/whitespace point-fixes above.
      # `render_attributes` (below) emits the attribute NAME verbatim —
      # only the *value* is escaped. That means any caller-supplied name
      # containing a tokenizer-significant byte changes what the browser
      # parses, no matter what the value is or how well it's escaped:
      #
      #   - A leading solidus bypasses `UrlAttributeValidation`'s
      #     `name.strip.downcase` check (`.strip` doesn't remove a `/`) —
      #     `A.new("/href": "javascript:...")` reaches `render_attributes`
      #     as `/href="javascript:..."`. In the tokenizer, `/` in the
      #     "before attribute name" state switches to the "self-closing
      #     start tag" state; the very next byte (not `>`) is a parse
      #     error that reconsumes in "before attribute name" state — i.e.
      #     the `/` is silently dropped and `href` starts a brand-new,
      #     live attribute. Same story for `/onclick` and the `on*` ban.
      #   - An embedded space/equals/greater-than/quote
      #     (`set_attribute(%(x onload=alert(1)), "y")`) ends the current
      #     attribute name mid-stream and starts an adjacent,
      #     attacker-controlled attribute the caller never asked for.
      #
      # Rejecting these at the name itself — once, here, for every element
      # and every attribute — closes the SafeURL-gate bypass, the on*-ban
      # bypass, and adjacent-attribute injection simultaneously, instead of
      # chasing each concrete payload shape as its own point-fix.
      #
      # Forbidden set (WHATWG HTML §13.1.2.3 "Attributes" + the Infra
      # "controls" definition, confirmed against the tokenizer's
      # before-attribute-name/attribute-name states):
      #   - ASCII whitespace: space, tab, LF, FF, CR.
      #   - Controls: C0 (U+0000–U+001F) and DEL/C1 (U+007F–U+009F).
      #   - `/ > = " '` — spec-mandated: these are the actual
      #     tokenizer-state transitions (self-closing/tag-end/value-start)
      #     or syntax-forbidden bytes.
      #   - `\` and `<` — not individually tokenizer-breaking inside an
      #     already-started attribute name, but banned too as
      #     defense-in-depth: no legitimate HTML/ARIA/`data-*`/SVG
      #     attribute name ever contains either, and `<` is always a
      #     parse error per the spec even though it doesn't structurally
      #     break out.
      #
      # This intentionally does NOT touch the *value* side (that's
      # `escape_attribute`'s job, unchanged) and does NOT restrict
      # legitimate names: letters, digits, hyphen, colon, and underscore
      # are all still allowed, so `href`, `data-x`, `aria-label`,
      # `viewBox`, `xml:lang`, and `xlink:href` are unaffected.
      protected def validate_attribute_name!(name : String) : Nil
        if name.empty?
          raise ArgumentError.new("SafeHTML ban: attribute name cannot be empty.")
        end

        name.each_char do |char|
          next unless forbidden_attribute_name_char?(char)

          raise ArgumentError.new(
            "SafeHTML ban: malformed attribute name #{name.inspect} rejected " \
            "(offending character #{char.inspect}). Attribute names must not " \
            "contain ASCII whitespace, control characters, or any of " \
            "/ \\ > < \" ' = -- a name containing one of these can change " \
            "what the browser parses as the attribute or tag boundary, " \
            "independent of how well the *value* is escaped."
          )
        end
      end

      private def forbidden_attribute_name_char?(char : Char) : Bool
        return true if char == ' '
        return true if char.ord <= 0x1F                     # C0 controls (incl. TAB/LF/FF/CR)
        return true if char.ord >= 0x7F && char.ord <= 0x9F # DEL + C1 controls

        case char
        when '/', '\\', '>', '<', '"', '\'', '='
          true
        else
          false
        end
      end

      # Validate attributes (to be overridden by specific elements)
      protected def validate_attribute(name : String, value : String?)
        # SafeHTML v1 hard ban (docs/SAFE_HTML_V1.md): inline event-handler
        # attributes are never allowed, on any element, through any
        # construction path. This is unconditional (not staged behind an
        # opt-in) because nothing in this shard sets one today — see the
        # v1 audit in SAFE_HTML_V1.md — so there is zero legacy call site
        # this can break. Attach behavior with a `data-*` hook + external JS
        # instead. (Shared with the render-time authority below via
        # `event_handler_attribute_name?` — one predicate, two enforcement
        # points: this one is fail-fast at call time, `render_attributes`'s
        # is the unbypassable one.)
        if event_handler_attribute_name?(name)
          raise ArgumentError.new(
            "SafeHTML ban: inline event-handler attribute #{name.inspect} is forbidden. " \
            "Attach behavior with a data-* attribute + an external script, not on#{name[2..]}=\"...\"."
          )
        end

        # Global attribute validation
        case name
        when "id"
          raise ArgumentError.new("ID cannot be empty") if value.to_s.empty?
          raise ArgumentError.new("ID cannot contain spaces") if value.to_s.includes?(" ")
        when "tabindex"
          unless value.to_s.match(/^-?\d+$/)
            raise ArgumentError.new("tabindex must be an integer")
          end
        end
      end

      # Shared by `validate_attribute` (call-time) and
      # `validate_rendered_attribute!` (render-time, the authority) — see
      # docs/SAFE_HTML_V1.md §3.7. `name` may be raw (call-time caller) or
      # `strip.downcase`-normalized (render-time caller, matching how
      # `UrlAttributeValidation` and `document_sink_attribute?` are keyed);
      # downcasing an already-lowercase string is a no-op, so one predicate
      # serves both.
      private def event_handler_attribute_name?(name : String) : Bool
        name.size > 2 && name[0..1].downcase == "on" && name[2].ascii_letter?
      end

      # ---- SafeHTML v1 typed setters (docs/SAFE_HTML_V1.md) --------------
      #
      # These are the NEW, additive, construction-time-safe entry points for
      # the two sink classes plain-`String` attributes cannot safely cover:
      # URL-bearing attributes and the `style` attribute. They sit beside the
      # existing `set_attribute(String, String)` / `add_style(String)` methods
      # rather than replacing them — see SAFE_HTML_V1.md "the legacy
      # boundary" for why the pre-existing String-typed path stays available
      # (it is still used by the cross-platform native UI renderer, which is
      # out of this v1's scope) while new and migrated component code should
      # use these instead. Because the parameter type is `SafeURL` /
      # `SafeStyleValue`, not `String`, passing a raw string through either
      # of these is a **compile error**, not a runtime check.

      # Sets a URL-bearing attribute (`href`, `src`, `action`, `formaction`,
      # `poster`, `cite`, `ping`, `xlink:href`, meta-refresh `content`, ...)
      # from a validated `SafeURL`. Scheme validation happened when the
      # `SafeURL` was constructed (`SafeURL.parse!`); the value still passes
      # through the normal attribute-escaping path when rendered.
      def set_safe_url_attribute(name : String, url : SafeURL) : self
        set_attribute(name, url.to_s)
      end

      # Sets the `style` attribute from a validated `SafeStyleValue` (the
      # output of `SafeStyle#build`). There is no overload that accepts a
      # bare `String` for this — that is the "raw style attribute" ban from
      # docs/SAFE_HTML_V1.md.
      def set_safe_style(style : SafeStyleValue) : self
        set_attribute("style", style.to_s)
      end

      # ---- SafeHTML v1 §3.7: the render-time validation authority --------
      #
      # A re-gate finding proved that `set_attribute`-time checks (grammar,
      # `on*`, `SafeURL`, `srcdoc`) are all bypassable the same way: `
      # attributes` is a public, mutable `getter` (`Hash(String, String)`),
      # so `element.attributes["SRCDOC"] = "<script>...</script>"` — or
      # `"/href"`, `" onclick"`, any case/whitespace-varied key — mutates the
      # live Hash directly and never touches `set_attribute` at all. Chasing
      # each concrete key-casing/sink combination as its own point-fix is an
      # unbounded list (five prior gates on this branch each closed exactly
      # one). The convergent fix: `render_attributes` — the one place every
      # attribute, however it entered `@attributes`, is turned into bytes —
      # is now the SOLE, COMPLETE, unbypassable validation authority. It
      # re-runs the FULL suite, by NORMALIZED name, against whatever
      # currently sits in `@attributes`, regardless of provenance:
      #
      #   (a) attribute-name grammar on the RAW name (`validate_attribute_name!`)
      #   (b) the `on*` ban, keyed by `name.strip.downcase`
      #   (c) `SafeURL` on url-bearing attributes (`url_bearing_attribute?`,
      #       keyed by `name.strip.downcase` — the same predicate
      #       `UrlAttributeValidation` already declares per element)
      #   (d) HTML-document-valued attributes (`document_sink_attribute?`,
      #       e.g. `srcdoc`) — the current value must be `==` the exact
      #       `String` a typed door vouched for that normalized name
      #
      # `set_attribute`-time enforcement (`validate_attribute_name!`,
      # `validate_attribute`, `UrlAttributeValidation#set_attribute`,
      # `Iframe#set_attribute`) stays exactly as it was — it is still useful
      # as a fail-FAST error at the call site that caused the bad value —
      # but it is no longer what makes this safe. `render_attributes` is.

      # Is `name` (already `strip.downcase`-normalized by the caller) a
      # URL-bearing attribute on *this* element? Default `false`; overridden
      # per element by `include Elements::UrlAttributeValidation` (see
      # `url_attribute_validation.cr`) exactly as before — this default just
      # makes the method universally callable from the base class so
      # `render_attributes` doesn't need a `responds_to?` check.
      protected def url_bearing_attribute?(name : String) : Bool
        false
      end

      # Is `name` (already normalized) an HTML-DOCUMENT-valued attribute on
      # *this* element (fed to a fresh HTML parser as an entire document,
      # e.g. `<iframe srcdoc>`) — as opposed to an ordinary data-valued one?
      # Default `false`; override alongside `vouch_document_attribute` calls
      # from the element's own typed door(s).
      protected def document_sink_attribute?(name : String) : Bool
        false
      end

      # The one legitimate way to populate a `document_sink_attribute?`
      # attribute: called from a typed, `reason:`-carrying door (e.g.
      # `Iframe.srcdoc`/`#set_srcdoc`). Records the vouched value under the
      # *normalized* name (so a case/whitespace-varied direct mutation of
      # `@attributes` can never coincidentally match it) and writes the
      # canonical-cased attribute into `@attributes` for rendering.
      protected def vouch_document_attribute(name : String, value : String) : Nil
        @vouched_document_attributes[name.strip.downcase] = value
        @attributes[name] = value
      end

      # The error raised when a `document_sink_attribute?` attribute's
      # current `@attributes` value doesn't match what was vouched (or
      # nothing was ever vouched at all). Override per element for a more
      # specific message pointing at that element's typed door(s) — see
      # `Iframe#document_sink_ban_error`.
      protected def document_sink_ban_error(name : String, value : String) : ArgumentError
        ArgumentError.new(
          "SafeHTML ban: #{name.inspect}=... rejected. This is an " \
          "HTML-DOCUMENT-valued attribute — the browser re-parses the " \
          "decoded value as an entire nested document, so a bare String is " \
          "banned exactly like <script> body content, regardless of how it " \
          "reached @attributes. Use this element's typed vouching door " \
          "instead of #set_attribute or direct `attributes[...]` mutation."
        )
      end

      # THE authority: every check §3.7 above describes, run once per
      # currently-live attribute, immediately before it is turned into
      # bytes. Raises fail-closed on the first violation found.
      protected def validate_rendered_attribute!(name : String, value : String) : Nil
        # (a) name grammar, on the RAW name — independent of case/whitespace
        # normalization, this is what closes `/href`, `" onclick"`, an
        # embedded `=`/`>`/quote, etc., no matter how the name reached
        # `@attributes` (constructor, `#set_attribute`, or a direct
        # `attributes["..."] = ...` mutation through the public getter).
        validate_attribute_name!(name)

        key = name.strip.downcase

        # (b) on* ban, keyed by normalized name.
        if event_handler_attribute_name?(key)
          raise ArgumentError.new(
            "SafeHTML ban: inline event-handler attribute #{name.inspect} is forbidden. " \
            "Attach behavior with a data-* attribute + an external script, not on#{key[2..]}=\"...\"."
          )
        end

        # (c) SafeURL on url-bearing attributes, keyed by normalized name,
        # reusing whatever this element already declared via
        # `url_bearing_attribute?` (the same predicate
        # `UrlAttributeValidation` uses at set-time).
        if url_bearing_attribute?(key)
          begin
            Components::SafeURL.parse!(value)
          rescue ex : Components::SafeURL::UnsafeURLError
            raise ArgumentError.new(
              "SafeHTML ban: #{name.inspect}=#{value.inspect} rejected — #{ex.message} " \
              "For an intentional non-allowlisted scheme, build the value with " \
              "SafeURL.unsafe(url, reason: \"...\") and pass it via " \
              "\#set_safe_url_attribute(#{name.inspect}, ...) instead of \#set_attribute."
            )
          end
        end

        # (d) HTML-document-valued attributes — the live value must be
        # exactly what a typed door vouched for, under the normalized name.
        # A case/whitespace-varied key (`SRCDOC`, `" srcdoc"`) written
        # directly into `@attributes` normalizes to the same `key` here and
        # is caught even though it is a *different* Hash entry than the
        # legitimately-vouched one.
        if document_sink_attribute?(key)
          vouched = @vouched_document_attributes[key]?
          if vouched.nil? || value != vouched
            raise document_sink_ban_error(name, value)
          end
        end
      end

      # Render attributes as HTML string
      protected def render_attributes : String
        return "" if @attributes.empty?

        attrs = @attributes.map do |name, value|
          validate_rendered_attribute!(name, value)
          # Escape attribute values
          escaped_value = escape_attribute(value)
          %(#{name}="#{escaped_value}")
        end

        " " + attrs.join(" ")
      end

      # Escape attribute values
      protected def escape_attribute(value : String) : String
        value.gsub('&', "&amp;")
          .gsub('"', "&quot;")
          .gsub('\'', "&#39;")
          .gsub('<', "&lt;")
          .gsub('>', "&gt;")
      end

      # Escape HTML content
      protected def escape_html(content : String) : String
        content.gsub('&', "&amp;")
          .gsub('<', "&lt;")
          .gsub('>', "&gt;")
          .gsub('"', "&quot;")
          .gsub('\'', "&#39;")
      end

      # Abstract render method to be implemented by subclasses
      abstract def render : String

      # Check if this is a void element
      def void_element? : Bool
        false
      end

      # Check if this element can contain children
      def can_have_children? : Bool
        !void_element?
      end

      # Convert to string (alias for render)
      def to_s(io : IO) : Nil
        io << render
      end
    end
  end
end
