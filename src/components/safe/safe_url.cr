module Components
  # `SafeURL` is a typed, validated URL for the representative URL-bearing
  # attribute sinks the hardening proposal §3.3 calls out: `href`, `src`,
  # `action`, `formaction`, `poster`, `cite`, `ping`, SVG `href`/`xlink:href`,
  # and `<meta http-equiv="refresh" content>`.
  #
  # HTML-escaping does **not** neutralize this class of sink — `javascript:`,
  # `vbscript:`, and similar script-executing schemes survive HTML-escaping
  # unchanged. `SafeURL` closes that gap with an explicit scheme allowlist.
  #
  # `srcset` is NOT covered by `SafeURL` — it is a URL *list with descriptors*
  # (`"a.jpg 1x, b.jpg 2x"`), not a single URL, and needs its own parser. See
  # `SafeSrcSet`.
  struct SafeURL
    class UnsafeURLError < ArgumentError
    end

    # Schemes permitted in a URL-bearing attribute. Everything else
    # (`javascript:`, `data:`, `vbscript:`, `file:`, `blob:`, ...) is
    # rejected. Relative URLs (no scheme — paths, fragments, queries,
    # protocol-relative `//host/...`) are always allowed: the browser
    # resolves them against the current document/scheme, so they cannot
    # smuggle a script-executing scheme.
    ALLOWED_SCHEMES = {"http", "https", "mailto", "tel"}

    # :nodoc:
    protected def initialize(@value : String)
    end

    # Validates and returns a `SafeURL`, or `nil` if the URL is unsafe.
    def self.parse(url : String) : SafeURL?
      parse!(url)
    rescue UnsafeURLError
      nil
    end

    # Validates and returns a `SafeURL`, or raises `UnsafeURLError` explaining
    # why. This is the construction-time ban: passing
    # `SafeURL.parse!("javascript:alert(1)")` raises instead of silently
    # producing a value that would render into an `href`.
    def self.parse!(url : String) : SafeURL
      # Defend against the classic `java\tscript:`-style bypass: browsers
      # strip ASCII control characters from a URL before parsing its scheme,
      # so a naive scheme check on the raw string can be fooled by inserting
      # a tab/newline/null byte into the scheme name. Strip them first, then
      # validate what the browser will actually see.
      candidate = strip_control_characters(url).strip
      raise UnsafeURLError.new("SafeURL: empty URL") if candidate.empty?

      if scheme = extract_scheme(candidate)
        unless ALLOWED_SCHEMES.includes?(scheme.downcase)
          raise UnsafeURLError.new("SafeURL: scheme #{scheme.inspect} is not allowed in #{url.inspect} (allowed: #{ALLOWED_SCHEMES.join(", ")}); relative URLs need no scheme")
        end
      end

      new(url)
    end

    # Explicit, loud opt-out for an intended-but-not-yet-allowlisted scheme
    # (e.g. an app-specific custom URI scheme). Mirrors `SafeHTML.unsafe` —
    # `reason:` is mandatory and this is the one auditable hole in `SafeURL`.
    def self.unsafe(url : String, reason : String) : SafeURL
      raise ArgumentError.new("SafeURL.unsafe requires a non-empty `reason:`") if reason.strip.empty?
      new(url)
    end

    def to_s : String
      @value
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def ==(other : SafeURL) : Bool
      @value == other.@value
    end

    private def self.strip_control_characters(url : String) : String
      String.build do |io|
        url.each_char do |c|
          io << c unless c.ord < 0x20 || c.ord == 0x7f
        end
      end
    end

    # A URL "has a scheme" iff there is a `:` that appears before the first
    # `/`, `?`, or `#` (so a scheme cannot be hiding inside a path/query/
    # fragment), the candidate scheme starts with a letter, and every
    # character in it is `[a-zA-Z0-9+.-]` (RFC 3986 `scheme` grammar). If no
    # such prefix exists, the URL is relative — always allowed.
    private def self.extract_scheme(url : String) : String?
      colon = url.index(':')
      return nil unless colon

      slash = url.index('/')
      ques = url.index('?')
      hash = url.index('#')
      [slash, ques, hash].each do |mark|
        return nil if mark && mark < colon
      end

      candidate = url[0...colon]
      return nil if candidate.empty?
      return nil unless candidate[0].ascii_letter?
      return nil unless candidate.each_char.all? { |ch| ch.ascii_alphanumeric? || "+.-".includes?(ch) }

      candidate
    end
  end
end
