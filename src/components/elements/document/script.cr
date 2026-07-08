require "json"
require "../base/container_element"
require "../base/raw_html"

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
      def initialize(**attrs)
        super("script", **attrs)
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
          raise ArgumentError.new(
            "SafeHTML ban: <script> does not accept a plain String child (banned interpolation sink). " \
            "Use Script.static(js, reason: \"...\") for static author-written JS, or Script.json_data(id:, data:) to pass data to the client."
          )
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

      # Override rendering to not escape JavaScript content
      protected def render_children : String
        @children.map do |child|
          case child
          when String
            # Don't escape JavaScript content
            child
          else
            child.to_s
          end
        end.join
      end
    end
  end
end
