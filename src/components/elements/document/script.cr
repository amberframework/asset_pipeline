require "json"
require "../base/container_element"
require "../base/raw_html"
require "../base/url_attribute_validation"

module Components
  module Elements
    # Represents the <script> element - embeds executable code or data
    #
    # SafeHTML v1 ban (docs/SAFE_HTML_V1.md): a plain `String` child is
    # **rejected**. `<script>` interpolation is exactly the sink the
    # hardening proposal §3.3 calls out to ban by default — there is no way
    # for the type system to distinguish "static author-written JS literal"
    # from "a string built by interpolating a runtime value" once both are
    # just `String`, so both are refused equally. Two doors remain:
    #
    #   - `Script.new << RawHTML.new(STATIC_JS)` / `Script.static(js, reason:)`
    #     — for genuinely static, author-controlled JS with no interpolated
    #     data. Loud and greppable, same shape as `SafeHTML.unsafe`.
    #   - `Script.json_data(id: ..., data: ...)` — for passing *data* to the
    #     client. Serializes via `JSON` (which escapes `"`, `\`, control
    #     characters) and additionally escapes `</` sequences so the payload
    #     cannot prematurely close the `<script>` tag and smuggle markup.
    class Script < ContainerElement
      # SafeHTML v1 (docs/SAFE_HTML_V1.md §3.2): an external `src="..."`
      # is a URL-bearing sink exactly like `<a href>` — a `javascript:`/
      # `data:` value there is nonsensical for `src` specifically, but the
      # scheme allowlist closes the sink uniformly regardless.
      include UrlAttributeValidation

      def initialize(**attrs)
        super("script", **attrs)
      end

      protected def url_bearing_attribute?(name : String) : Bool
        name == "src"
      end

      # Convenience constructor for the loud, explicit "this is static
      # author-written JS, not interpolated data" path. `reason:` is
      # mandatory, matching `SafeHTML.unsafe`.
      def self.static(js : String, reason : String) : Script
        raise ArgumentError.new("Script.static requires a non-empty `reason:`") if reason.strip.empty?
        instance = new
        instance << RawHTML.new(js)
        instance
      end

      # Emits `<script type="application/json" id="...">{...}</script>` —
      # the typed path for handing data to client-side JS. `data` is
      # anything `JSON.build`/`.to_json` can serialize (Hash, NamedTuple,
      # Array, JSON::Any, ...).
      def self.json_data(id : String, data) : Script
        json = data.to_json
        # `</script>` (or `</` of ANY tag) inside a JSON string literal would
        # close the element early in the HTML parser — JSON-escaping alone
        # does not protect against this because `/` is not a JSON metacharacter.
        escaped = json.gsub("</", "<\\/")
        instance = new(id: id, type: "application/json")
        instance << RawHTML.new(escaped)
        instance
      end

      # Script elements refuse plain-`String` children — see the class
      # docstring. Use `Script.static(js, reason:)` or `Script.json_data`.
      def <<(child : HTMLElement | String) : self
        case child
        when String
          raise script_string_ban_error
        else
          raise ArgumentError.new("Script element should only contain JavaScript text, not other HTML elements")
        end
      end

      # The one legitimate way to add content: an explicit `RawHTML` wrapper
      # (already-vouched, e.g. via `Script.static`/`Script.json_data`, or a
      # direct `RawHTML.new(...)` call — which is itself loud and greppable).
      def <<(child : RawHTML) : self
        @children << child
        self
      end

      # `ContainerElement#add_child`/`#add_children` are typed
      # `HTMLElement | String | RawHTML` and are NOT overridden by the `<<`
      # methods above (Crystal does not let a subtype narrow an inherited
      # method's parameter type via overload alone reaching every caller —
      # `add_child`/`add_children` call sites bind directly to the inherited
      # method unless we shadow them here too). Left un-overridden, either
      # would silently land a plain String in `@children`, bypassing the
      # `<<` ban entirely. Fail fast here, matching `<<`'s behavior — this
      # is defense-in-depth for DX; the authoritative backstop that closes
      # every path (including direct `children << "..."` mutation through
      # the public `getter`, which no method override can intercept) is the
      # render-time check in `render_children` below.
      def add_child(child : HTMLElement | String | RawHTML) : self
        case child
        when RawHTML
          @children << child
          self
        when String
          raise script_string_ban_error
        else
          raise ArgumentError.new("Script element should only contain JavaScript text, not other HTML elements")
        end
      end

      def add_children(*children : HTMLElement | String | RawHTML) : self
        children.each { |child| add_child(child) }
        self
      end

      private def script_string_ban_error : ArgumentError
        ArgumentError.new(
          "SafeHTML ban: <script> does not accept a plain String child (banned interpolation sink). " \
          "Use Script.static(js, reason: \"...\") for static author-written JS, or Script.json_data(id:, data:) to pass data to the client."
        )
      end

      # Validate script-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super

        case name
        when "type"
          # Common script types
          valid_types = ["text/javascript", "module", "application/json", "application/ld+json"]
          # Don't strictly enforce as new types may be added
        when "async", "defer"
          # These are boolean attributes
          unless value.nil? || value == "true" || value == "false" || value == ""
            raise ArgumentError.new("#{name} is a boolean attribute")
          end
        when "crossorigin"
          valid_values = ["anonymous", "use-credentials"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid crossorigin value: #{value}")
          end
        end
      end

      # RENDER-TIME invariant enforcement (the actual backstop — see
      # `docs/SAFE_HTML_V1.md` §3.4). `<<`/`add_child`/`add_children` above
      # reject a plain-`String` child at call time, but `children` is a
      # public, mutable `getter` (`HTMLElement#children`) — `script.children
      # << "some string"` or `script.children.concat([...])` mutates the
      # live `Array` directly and bypasses every method override above.
      # There is no way to intercept that mutation when it happens, so this
      # method re-checks the invariant at the one point that can't be
      # bypassed: immediately before emitting bytes. A plain `String` here
      # is unescapable-and-unexecutable-safely in `<script>` context (no
      # HTML-escaping neutralizes a `</script>` breakout), so — matching
      # this shard's fail-loud philosophy (the `on*` ban, the `<<` ban) —
      # it raises rather than silently escaping or dropping the content.
      # Only `RawHTML` (already-vouched, via `Script.static`/`.json_data`/a
      # direct `RawHTML.new(...)` push) is accepted.
      protected def render_children : String
        @children.map do |child|
          case child
          when RawHTML
            child.render
          when String
            raise script_string_ban_error
          else
            raise ArgumentError.new("Script element should only contain JavaScript text, not other HTML elements")
          end
        end.join
      end
    end
  end
end
