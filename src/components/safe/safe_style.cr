require "../../ui/design_tokens"

module Components
  # A validated CSS length. Rejects the string-passthrough hole entirely by
  # only ever being constructed from a number + a fixed unit — there is no
  # constructor that takes an arbitrary CSS length string.
  struct SafeLength
    protected def initialize(@value : String)
    end

    def self.px(n : Number) : SafeLength
      new("#{n}px")
    end

    def self.rem(n : Number) : SafeLength
      new("#{n}rem")
    end

    def self.percent(n : Number) : SafeLength
      new("#{n}%")
    end

    def self.zero : SafeLength
      new("0")
    end

    def to_s : String
      @value
    end

    def to_s(io : IO) : Nil
      io << @value
    end
  end

  # `SafeStyle` is the typed `style`-attribute builder the hardening proposal
  # §3.3 requires: "Ban raw strings; require a typed Style/color builder."
  # This is what closes the CSS-context sink class the plain `brand_color`
  # mailer bug (Stage 5, commit `c6ec54f`) fell into — `HTML.escape` alone
  # would not have caught a CSS-context breakout, because the attack lives in
  # a different parser (the CSS value parser), not the HTML parser.
  #
  # Design: a **narrow property allowlist**, each property either typed
  # (`SafeColor`/`SafeLength`) or checked against a denylist of dangerous CSS
  # constructs (`url(...)`, `expression(...)`, `@import`, embedded
  # `javascript:`, statement separators). "Ban until typed" is the default —
  # adding a property means adding it to the allowlist deliberately, not
  # opening a general string hole.
  class SafeStyle
    # Reuses the shard's existing typed color (`UI::DesignTokens::Color`) —
    # OKLCH-sourced, `#to_css` renders a safe `oklch(...)`/`AccentColor` CSS
    # value with no string-interpolation surface. This *is* the typed color
    # the `brand_color`-class sink needs; no need to reinvent one.
    alias Color = UI::DesignTokens::Color

    COLOR_PROPERTIES = %w[color background-color border-color outline-color]

    LENGTH_PROPERTIES = %w[
      width height min-width min-height max-width max-height
      padding padding-top padding-bottom padding-left padding-right
      margin margin-top margin-bottom margin-left margin-right
      gap border-radius font-size line-height
    ]

    KEYWORD_PROPERTIES = {
      "display"         => %w[none block inline inline-block flex inline-flex grid inline-grid contents],
      "position"        => %w[static relative absolute fixed sticky],
      "text-align"      => %w[left right center justify start end],
      "font-weight"     => %w[normal bold lighter bolder 100 200 300 400 500 600 700 800 900],
      "flex-direction"  => %w[row row-reverse column column-reverse],
      "align-items"     => %w[stretch flex-start flex-end center baseline],
      "justify-content" => %w[flex-start flex-end center space-between space-around space-evenly],
      "overflow"        => %w[visible hidden scroll auto clip],
      "overflow-x"      => %w[visible hidden scroll auto clip],
      "overflow-y"      => %w[visible hidden scroll auto clip],
      "white-space"     => %w[normal nowrap pre pre-line pre-wrap],
      "text-transform"  => %w[none capitalize uppercase lowercase],
    }

    def initialize
      @declarations = [] of String
    end

    # A color-bearing property. Only `COLOR_PROPERTIES` are accepted; the
    # value must be a `Color`, never a string.
    def color(property : String, value : Color) : self
      unless COLOR_PROPERTIES.includes?(property)
        raise ArgumentError.new("SafeStyle#color: #{property.inspect} is not a color property on the v1 allowlist (#{COLOR_PROPERTIES.join(", ")})")
      end
      @declarations << "#{property}: #{value.to_css}"
      self
    end

    # A length-bearing property. Only `LENGTH_PROPERTIES` are accepted; the
    # value must be a `SafeLength`, never a string — so `expression(...)`,
    # `url(...)`, and `--custom-property:` passthrough are unreachable here.
    def length(property : String, value : SafeLength) : self
      unless LENGTH_PROPERTIES.includes?(property)
        raise ArgumentError.new("SafeStyle#length: #{property.inspect} is not a length property on the v1 allowlist (#{LENGTH_PROPERTIES.join(", ")})")
      end
      @declarations << "#{property}: #{value}"
      self
    end

    # A keyword-bearing property (e.g. `display: flex`). The value must be
    # one of the property's own allowlisted keywords — this is how
    # `KEYWORD_PROPERTIES` stays a closed set rather than a string hole.
    def keyword(property : String, value : String) : self
      allowed = KEYWORD_PROPERTIES[property]?
      raise ArgumentError.new("SafeStyle#keyword: #{property.inspect} is not a keyword property on the v1 allowlist") unless allowed
      raise ArgumentError.new("SafeStyle#keyword: #{value.inspect} is not an allowlisted value for #{property.inspect} (allowed: #{allowed.join(", ")})") unless allowed.includes?(value)
      @declarations << "#{property}: #{value}"
      self
    end

    def build : SafeStyleValue
      SafeStyleValue.new(@declarations.join("; "))
    end
  end

  # The validated output of `SafeStyle#build` — the only way to obtain a
  # `style`-attribute value through the safe path. Every character in it
  # came from `#to_css` on a `Color`, a `SafeLength`, or an allowlisted
  # keyword literal — there is no free-form string input anywhere in
  # `SafeStyle`, so `url(...)`/`expression(...)`/`@import`/statement
  # injection are unreachable by construction, not filtered after the fact.
  struct SafeStyleValue
    protected def initialize(@value : String)
    end

    def to_s : String
      @value
    end

    def to_s(io : IO) : Nil
      io << @value
    end
  end
end
