require "../../safe/safe_url"

module Components
  module Elements
    # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): a construction/render-time
    # backstop for the handful of concrete elements whose whole reason for
    # existing is a URL-bearing attribute — `A#href`, `Img#src`, and
    # similar. Before this module, `href`/`src` reached these elements as a
    # plain, unvalidated `String` through two paths: the constructor kwargs
    # (`A.new(href: "javascript:...")`) and the ordinary
    # `#set_attribute("href", "javascript:...")` call — both of which
    # `HTML.escape`-based attribute escaping does **nothing** to neutralize,
    # since `javascript:`/`vbscript:`/`data:` survive attribute-value
    # escaping unchanged (escaping quotes/`<`/`>` doesn't touch the scheme).
    #
    # `include`-ing this module and overriding `url_bearing_attribute?` for
    # the one or two attribute names a tag actually has closes both paths at
    # once: the constructor kwargs path already funnels through
    # `HTMLElement#set_attribute` (see `HTMLElement#initialize`), so
    # overriding `#set_attribute` here covers it for free.
    #
    # This deliberately does **not** touch `HTMLElement#set_attribute`
    # itself — the shared, generic, `String`-typed setter every one of the
    # ~94 element classes has, including the ~185 call sites in
    # `src/ui/renderers/web_renderer.cr` that set `data-*`/`style`/ARIA
    # attributes on elements that have nothing to do with URLs. Only
    # classes that `include UrlAttributeValidation` (the actual
    # link/src-bearing tags) get the extra check; every other element and
    # every other attribute name is unaffected, matching
    # `docs/SAFE_HTML_V1.md`'s documented two-tier scope.
    #
    # The already-typed `HTMLElement#set_safe_url_attribute(name, SafeURL)`
    # path is unaffected by (and redundant with, in a good way) this
    # module: it calls `#set_attribute(name, url.to_s)` with a `String`
    # that has already passed `SafeURL.parse!`, so it passes this check
    # trivially.
    module UrlAttributeValidation
      # Override in the including class: is `name` a URL-bearing attribute
      # on *this* tag? (e.g. `A`/`Link` -> `"href"`; `Img`/`Script`/`Iframe`
      # -> `"src"`; `Video` -> `"src"` or `"poster"`.) Default `false` so
      # including this module and forgetting to override is a no-op, not a
      # silent over-broad ban.
      protected def url_bearing_attribute?(name : String) : Bool
        false
      end

      def set_attribute(name : String, value : String?) : self
        if value && url_bearing_attribute?(name)
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

        super
      end
    end
  end
end
