require "html"
require "json"
require "../elements/base/raw_html"

module Components
  # `SafeHTML` is the **output contract**: a value that means "these bytes are
  # already safe to write into an HTML response as markup." It is the
  # type-level boundary Front A of the platform hardening proposal introduces
  # (`docs/SAFE_HTML_V1.md`) — a plain `String` at a sink means *text* and
  # gets escaped; a `SafeHTML` means *markup* and is trusted.
  #
  # There is deliberately **no public `SafeHTML.new(String)`**. `initialize`
  # is `protected`, so the compiler-generated `.new` is protected too —
  # nothing outside the `Components` namespace can mint a `SafeHTML` by
  # construction. The only ways to get one are:
  #
  #   - `SafeHTML.escape(text)`   — HTML-escapes text and wraps it (safe, always)
  #   - `SafeHTML.join(parts)`    — concatenates other `SafeHTML` values (safe,
  #     because every part already carries the invariant)
  #   - the `Elements`/tag DSL (`Components::Elements::*`), which escapes text
  #     children and attribute values by construction and hands back
  #     `SafeHTML` at the `Component` boundary
  #   - `SafeHTML.unsafe(str, reason:)` / the top-level `raw(str, reason:)` —
  #     the loud, greppable escape hatch. `reason:` is mandatory. Every call
  #     site is a visible admission "I built this HTML by hand and I am
  #     vouching for it" — `grep -rn 'SafeHTML.unsafe\|raw(' src/` finds every
  #     one, which is exactly what makes this auditable instead of a second
  #     `html_safe`-style silent-trust label.
  struct SafeHTML
    # :nodoc: internal constructor — do not call directly. Use `.escape`,
    # `.join`, `.unsafe`, or `raw(...)`.
    protected def initialize(@html : String)
    end

    EMPTY = new("")

    # Escapes plain text for the HTML text-node context and wraps the result
    # as safe. The common, always-correct path for untrusted strings.
    def self.escape(text : String) : SafeHTML
      new(HTML.escape(text))
    end

    # Concatenates already-safe fragments. No re-escaping happens — each
    # fragment is trusted because it already carries the `SafeHTML` invariant.
    def self.join(parts : Enumerable(SafeHTML)) : SafeHTML
      new(parts.join { |p| p.to_s })
    end

    def self.join(*parts : SafeHTML) : SafeHTML
      join(parts.to_a)
    end

    # THE escape hatch. Loud and greppable by design: `reason:` is mandatory,
    # not defaulted, so every call site documents *why* the string is
    # trusted. Prefer `.escape` or the `Elements`/tag DSL over this.
    #
    # This is also the mechanism `Component#render` uses internally to
    # bridge un-migrated components (those that still implement the legacy
    # `render_content : String` and have not overridden `render_safe_content`)
    # — see `docs/SAFE_HTML_V1.md` "migration guide". Grep for
    # `reason: "legacy component` to find every component still on the old
    # path.
    def self.unsafe(html : String, reason : String) : SafeHTML
      raise ArgumentError.new("SafeHTML.unsafe requires a non-empty `reason:` explaining why this string is trusted") if reason.strip.empty?
      new(html)
    end

    # Concatenation — both operands already carry the invariant, so the
    # result does too.
    def +(other : SafeHTML) : SafeHTML
      SafeHTML.new(@html + other.@html)
    end

    def to_s : String
      @html
    end

    def to_s(io : IO) : Nil
      io << @html
    end

    # Interop with the existing `Elements` children union — a `SafeHTML` is,
    # by construction, exactly a vouched-safe `RawHTML`.
    def to_raw_html : Elements::RawHTML
      Elements::RawHTML.new(@html)
    end

    # JSON embedding (e.g. reactive-component WebSocket/HTTP payloads):
    # serialize as a plain JSON string of the safe HTML bytes.
    def to_json(json : JSON::Builder) : Nil
      json.string(@html)
    end

    # ---- Minimal, read-only String-like surface -----------------------
    # Deliberately NOT the whole String API (that would re-blur the type
    # boundary this struct exists to draw). Just enough for existing specs
    # (`rendered.should contain(...)`) and common call sites to keep working
    # without every caller having to say `.to_s` first.
    def includes?(needle : String) : Bool
      @html.includes?(needle)
    end

    def starts_with?(prefix : String) : Bool
      @html.starts_with?(prefix)
    end

    def ends_with?(suffix : String) : Bool
      @html.ends_with?(suffix)
    end

    def =~(other) : Int32?
      @html =~ other
    end

    def empty? : Bool
      @html.empty?
    end

    def size : Int32
      @html.size
    end

    def inspect(io : IO) : Nil
      io << "SafeHTML("
      @html.inspect(io)
      io << ")"
    end

    def ==(other : SafeHTML) : Bool
      @html == other.@html
    end

    def ==(other : String) : Bool
      @html == other
    end

    def hash(hasher)
      @html.hash(hasher)
    end
  end

  # Top-level, loud, greppable escape hatch — the `raw(...)` spelling the
  # hardening proposal calls for alongside `SafeHTML.unsafe`. `reason:` is
  # mandatory. Identical to `SafeHTML.unsafe`, just terser at call sites:
  #
  #   raw(static_svg_markup, reason: "first-party static SVG, no interpolation")
  #
  def self.raw(html : String, reason : String) : SafeHTML
    SafeHTML.unsafe(html, reason: reason)
  end
end
