require "html"
require "./safe_html"

module Components
  # `SafeBuffer` is the **construction mechanism** paired with `SafeHTML` the
  # **output contract**. It is an accumulator with one load-bearing rule
  # (proposal §3.2 point 3): appending a `String` always means *text* and is
  # always HTML-escaped. There is no overload that takes a raw `String` and
  # treats it as markup — that is exactly the "buffer that's sometimes raw"
  # design the hardening proposal rejects, because it recreates the hole.
  #
  # Structure comes from appending `SafeHTML` / `Elements::HTMLElement` /
  # `Elements::RawHTML` values (already-safe markup, passed through
  # verbatim), never from interpolating a `String` that happens to contain
  # tags — `buf << "<b>#{x}</b>"` escapes the *entire* literal, producing a
  # visible `&lt;b&gt;...` cosmetic bug the author sees and fixes. That is
  # the intended failure mode (see `docs/SAFE_HTML_V1.md`).
  class SafeBuffer
    def initialize
      @io = String::Builder.new
    end

    # A plain String is TEXT. Always escaped. Deliberately the only overload
    # that accepts `String`.
    def <<(text : String) : self
      HTML.escape(text, @io)
      self
    end

    # Already-safe markup — passthrough, no re-escaping.
    def <<(safe : SafeHTML) : self
      safe.to_s(@io)
      self
    end

    # `HTMLElement#render` already escapes its own text children and
    # attribute values internally (§3.1 of the proposal — this DSL is
    # already safe-by-default), so its serialized form is trusted verbatim.
    def <<(el : Elements::HTMLElement) : self
      @io << el.render
      self
    end

    # The explicit, existing "I mean it" raw wrapper — passthrough.
    def <<(raw_html : Elements::RawHTML) : self
      @io << raw_html.render
      self
    end

    # A nested `Component` renders through the same `SafeHTML` contract, so
    # its output is trusted verbatim.
    def <<(component : Component) : self
      component.render.to_s(@io)
      self
    end

    # Scalars: escape their `to_s` form. Harmless for numbers/bools, and
    # future-proofs against a scalar type whose `to_s` could ever contain
    # markup-shaped characters.
    def <<(other : Int | Float | Bool | Char) : self
      HTML.escape(other.to_s, @io)
      self
    end

    def to_safe_html : SafeHTML
      # Every byte that reached `@io` went through `HTML.escape` (String
      # overload) or was already a `SafeHTML`/`HTMLElement`/`RawHTML`/
      # `Component#render` value (each independently safe by construction/
      # contract). This is the single, audited, non-arbitrary point where a
      # `SafeBuffer`'s accumulated bytes become a `SafeHTML` — it is not an
      # admission of an unreviewed string, it is the buffer's own documented
      # invariant.
      SafeHTML.unsafe(@io.to_s, reason: "SafeBuffer#to_safe_html — every append went through HTML-escaping (String), or was already-safe markup (SafeHTML/HTMLElement/RawHTML/Component#render)")
    end
  end
end
