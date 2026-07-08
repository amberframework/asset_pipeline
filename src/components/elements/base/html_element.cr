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

        # Process attributes
        attrs.each do |key, value|
          set_attribute(key.to_s, value.to_s)
        end
      end

      # Set an attribute with validation
      def set_attribute(name : String, value : String?) : self
        return self if value.nil?

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

      # Validate attributes (to be overridden by specific elements)
      protected def validate_attribute(name : String, value : String?)
        # SafeHTML v1 hard ban (docs/SAFE_HTML_V1.md): inline event-handler
        # attributes are never allowed, on any element, through any
        # construction path. This is unconditional (not staged behind an
        # opt-in) because nothing in this shard sets one today — see the
        # v1 audit in SAFE_HTML_V1.md — so there is zero legacy call site
        # this can break. Attach behavior with a `data-*` hook + external JS
        # instead.
        if name.size > 2 && name[0..1].downcase == "on" && name[2].ascii_letter?
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

      # Render attributes as HTML string
      protected def render_attributes : String
        return "" if @attributes.empty?

        attrs = @attributes.map do |name, value|
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
