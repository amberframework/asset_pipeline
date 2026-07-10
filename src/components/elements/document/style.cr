require "../base/container_element"
require "../base/raw_html"

module Components
  module Elements
    # Represents the <style> element - contains style information for a document
    #
    # SafeHTML v1 ban (docs/SAFE_HTML_V1.md §3.8, reclassified from a
    # DOCUMENTED RESIDUAL to CLOSED on 2026-07-08): a plain `String` child is
    # **rejected**. The `<style>` element BODY is not merely a CSS-context
    # sink -- it is SCRIPT-EXECUTING, exactly like `<script>` body content
    # (§3.4): the browser's HTML tokenizer treats `</style>` as the element's
    # close tag regardless of where it appears in the text, so
    # `"</style><script>alert(document.cookie)</script>"` interpolated into a
    # `<style>` body closes the element early and runs the attacker's
    # `<script>` in the surrounding document -- full script execution, not a
    # CSS-context breakout. There is no way for the type system to
    # distinguish "static author-written CSS" from "a string built by
    # interpolating a runtime value" once both are just `String`, so both are
    # refused equally -- one typed door remains:
    #
    #   - `Style.css(css, reason:)` -- for genuinely static, author-controlled
    #     CSS with no interpolated untrusted data. Loud and greppable, the
    #     same shape as `Script.static`. (`Elements::RawHTML.new(css)`
    #     appended directly works too -- `Style.css` is the ergonomic,
    #     reason-enforcing wrapper around that.)
    class Style < ContainerElement
      def initialize(**attrs)
        super("style", **attrs)
      end

      # The typed, reasoned door for static CSS -- mirrors `Script.static(js,
      # reason:)`. `reason:` is mandatory, matching every other vouching
      # door in this shard. Any other constructor kwarg (`type`, `media`,
      # ...) is still accepted and still validated normally.
      def self.css(css : String, reason : String, **attrs) : Style
        raise ArgumentError.new("Style.css requires a non-empty `reason:` explaining why this CSS is trusted") if reason.strip.empty?
        instance = new(**attrs)
        instance << RawHTML.new(css)
        instance
      end

      # Style elements refuse plain-`String` children -- see the class
      # docstring. Use `Style.css(css, reason: "...")`.
      def <<(child : HTMLElement | String) : self
        case child
        when String
          raise style_string_ban_error
        else
          raise ArgumentError.new("Style element should only contain CSS text, not other HTML elements")
        end
      end

      # The one legitimate way to add content: an explicit `RawHTML` wrapper
      # (already-vouched, e.g. via `Style.css`, or a direct `RawHTML.new(...)`
      # call -- which is itself loud and greppable).
      def <<(child : RawHTML) : self
        @children << child
        self
      end

      # `ContainerElement#add_child`/`#add_children` are typed
      # `HTMLElement | String | RawHTML` and are NOT overridden by the `<<`
      # methods above (Crystal does not let a subtype narrow an inherited
      # method's parameter type via overload alone reaching every caller --
      # see the identical note on `Elements::Script`). Left un-overridden,
      # either would silently land a plain String in `@children`, bypassing
      # the `<<` ban entirely. Fail fast here, matching `<<`'s behavior --
      # this is defense-in-depth for DX; the authoritative backstop that
      # closes every path (including direct `children << "..."` mutation
      # through the public `getter`, which no method override can
      # intercept) is the render-time check in `render_children` below.
      def add_child(child : HTMLElement | String | RawHTML) : self
        case child
        when RawHTML
          @children << child
          self
        when String
          raise style_string_ban_error
        else
          raise ArgumentError.new("Style element should only contain CSS text, not other HTML elements")
        end
      end

      def add_children(*children : HTMLElement | String | RawHTML) : self
        children.each { |child| add_child(child) }
        self
      end

      private def style_string_ban_error : ArgumentError
        ArgumentError.new(
          "SafeHTML ban: <style> does not accept a plain String child (banned </style> breakout sink -- " \
          "a String containing \"</style>\" closes the element early and lets the following markup, " \
          "including a live <script>, execute in the surrounding document). " \
          "Use Style.css(css, reason: \"...\") for static author-written CSS."
        )
      end

      # Validate style-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super

        case name
        when "type"
          # Should be text/css if specified
          if value && value != "text/css"
            # Other types are technically valid but uncommon
          end
        when "media"
          # Media queries are complex to validate, so we accept any string
        end
      end

      # RENDER-TIME invariant enforcement — the actual backstop, matching
      # `Script#render_children` (docs/SAFE_HTML_V1.md §3.4/§3.8). `<<`/
      # `add_child`/`add_children` above reject a plain-`String` child at
      # call time, but `children` is a public, mutable `getter`
      # (`HTMLElement#children`) — `style.children << "some string"` or
      # `style.children.concat([...])` mutates the live `Array` directly and
      # bypasses every method override above. There is no way to intercept
      # that mutation when it happens, so this method re-checks the
      # invariant at the one point that can't be bypassed: immediately
      # before emitting bytes. Only `RawHTML` (already-vouched, via
      # `Style.css`/a direct `RawHTML.new(...)` push) is accepted.
      protected def render_children : String
        @children.map do |child|
          case child
          when RawHTML
            child.render
          when String
            raise style_string_ban_error
          else
            raise ArgumentError.new("Style element should only contain CSS text, not other HTML elements")
          end
        end.join
      end
    end
  end
end
