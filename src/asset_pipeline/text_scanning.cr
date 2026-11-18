# Hand-written text checks for the default require path of the asset_pipeline shard.
# Part of the asset_pipeline shard.

require "./text_scanning/spacing_mark_ranges"

module AssetPipeline
  # :nodoc:
  #
  # Hand-written replacements for the regular expressions that the default
  # `require "asset_pipeline"` path used to run, so an application that loads
  # the shard links no PCRE2.
  #
  # Each method reproduces one former pattern exactly as Crystal compiled it
  # (PCRE2 with the UTF and UCP options): `\s` and `\w` are the Unicode-aware
  # classes, `$` also matches before one final newline, and a subject that is
  # not valid UTF-8 raises `ArgumentError`, as the PCRE2 match did. The specs
  # in `spec/web/asset_pipeline/text_scanning_spec.cr` compare every method
  # against the pattern it replaced.
  #
  # Every method runs in time linear in the length of its input.
  module TextScanning
    extend self

    # PCRE2 `\w` also accepts these connector punctuation (Pc) characters.
    CONNECTOR_PUNCTUATION = {'_', '‿', '⁀', '⁔', '︳', '︴', '﹍', '﹎', '﹏', '＿'}

    # Tangut ideograph blocks. Crystal's Unicode tables mark only the first
    # and last code point of each block as a letter; PCRE2 marks all of them.
    TANGUT_IDEOGRAPH_RANGES = {0x17000..0x187FF, 0x18D00..0x18D1E}

    # Raises `ArgumentError` when *text* is not valid UTF-8, matching the error
    # class a PCRE2 match raised for such a subject.
    def ensure_valid_utf8!(text : String) : Nil
      return if text.valid_encoding?
      raise ArgumentError.new("Text scan error: subject is not valid UTF-8")
    end

    # Returns `true` when *char* belongs to the PCRE2 `\s` class (UCP mode).
    def space?(char : Char) : Bool
      return char.ascii_whitespace? if char.ascii?
      char.whitespace? || char == '\u0085' || char == '᠎'
    end

    # Returns `true` when *char* belongs to the PCRE2 `\w` class (UCP mode):
    # letters, numbers, nonspacing marks, and connector punctuation.
    def word_char?(char : Char) : Bool
      return char.ascii_alphanumeric? || char == '_' if char.ascii?
      return true if char.letter? || char.number? || CONNECTOR_PUNCTUATION.includes?(char)
      return true if char.mark? && !spacing_mark?(char)
      codepoint = char.ord
      TANGUT_IDEOGRAPH_RANGES.any?(&.includes?(codepoint))
    end

    # Returns `true` when *byte* is in `[a-zA-Z0-9_]`.
    def ascii_identifier_byte?(byte : UInt8) : Bool
      byte.unsafe_chr.ascii_alphanumeric? || byte == '_'.ord
    end

    # Returns `true` when *byte* is in `[A-Z]`.
    def ascii_uppercase_byte?(byte : UInt8) : Bool
      byte.unsafe_chr.ascii_uppercase?
    end

    # Returns the byte index just past the run of `\s` characters that starts
    # at byte index *position* of *text*.
    def skip_spaces(text : String, position : Int32) : Int32
      skip_chars(text, position) { |char| space?(char) }
    end

    # Returns the byte index just past the run of `\w` characters that starts
    # at byte index *position* of *text*.
    def skip_word_chars(text : String, position : Int32) : Int32
      skip_chars(text, position) { |char| word_char?(char) }
    end

    # Returns the byte index just past the run of `[a-zA-Z0-9_]` bytes that
    # starts at byte index *position* of *text*.
    def skip_ascii_identifier(text : String, position : Int32) : Int32
      bytes = text.to_slice
      index = position
      while index < bytes.size && ascii_identifier_byte?(bytes[index])
        index += 1
      end
      index
    end

    # Returns the byte index just past the run of characters starting at byte
    # index *position* for which the block returns `true`.
    def skip_chars(text : String, position : Int32, & : Char -> Bool) : Int32
      return position if position >= text.bytesize
      reader = Char::Reader.new(text, position)
      while reader.has_next? && yield reader.current_char
        reader.next_char
      end
      reader.pos
    end

    # Returns the byte at byte index *position*, or `nil` past the end.
    def byte_at(text : String, position : Int32) : UInt8?
      text.to_slice[position]?
    end

    # Returns `true` when *text* holds *literal* starting at byte index *position*.
    def literal_at?(text : String, position : Int32, literal : String) : Bool
      return false if position < 0 || position + literal.bytesize > text.bytesize
      text.to_slice[position, literal.bytesize] == literal.to_slice
    end

    # Returns the byte index just past the first of *literals* found at byte
    # index *position*, or `nil` when none is there. Replaces `(?:a|b|c)`.
    def literal_alternative_end(text : String, position : Int32, literals : Enumerable(String)) : Int32?
      literals.each do |literal|
        return position + literal.bytesize if literal_at?(text, position, literal)
      end
      nil
    end

    # Replaces `/^[A-Z][a-zA-Z0-9_]*Controller$/`: an ASCII class name that
    # starts with an uppercase letter and ends in `Controller`.
    def stimulus_controller_class_name?(name : String) : Bool
      ensure_valid_utf8!(name)
      body = line_body(name)
      return false unless body.bytesize > "Controller".bytesize && body.ends_with?("Controller")
      ascii_class_name_body?(body)
    end

    # Replaces `/^[A-Z][a-zA-Z0-9_]*$/`: an ASCII identifier that starts with
    # an uppercase letter.
    def ascii_class_name?(name : String) : Bool
      ensure_valid_utf8!(name)
      ascii_class_name_body?(line_body(name))
    end

    # Replaces `/\A[a-f0-9]{64}\z/`: exactly 64 lowercase hexadecimal digits.
    def sha256_hex_digest?(value : String) : Bool
      ensure_valid_utf8!(value)
      return false unless value.bytesize == 64
      value.each_byte.all? { |byte| byte.unsafe_chr.ascii_number? || ('a'.ord..'f'.ord).includes?(byte) }
    end

    # Replaces `value.gsub(/\/{2,}/, "/")`: collapses each run of slashes into one.
    def collapse_slash_runs(value : String) : String
      ensure_valid_utf8!(value)
      return value unless value.includes?("//")
      String.build(value.bytesize) do |io|
        previous_was_slash = false
        value.each_char do |char|
          is_slash = char == '/'
          io << char unless is_slash && previous_was_slash
          previous_was_slash = is_slash
        end
      end
    end

    # Replaces `value.starts_with?(/(?i:data|https?|blob|mailto|tel):/)`.
    #
    # PCRE2 caseless matching in UTF mode also lets U+017F (LATIN SMALL LETTER
    # LONG S) stand for `s`, so this check does too.
    def starts_with_url_scheme?(value : String) : Bool
      ensure_valid_utf8!(value)
      {"data:", "https:", "http:", "blob:", "mailto:", "tel:"}.any? do |scheme|
        caseless_prefix?(value, scheme)
      end
    end

    # Replaces `reference.index(/[?#]/)`: the character index of the first
    # `?` or `#`, or `nil` when there is none.
    def query_or_fragment_index(reference : String) : Int32?
      ensure_valid_utf8!(reference)
      reference.each_char_with_index do |char, index|
        return index if char == '?' || char == '#'
      end
      nil
    end

    # Replaces `comment.match(/\A\/\/[#@]\s*sourceMappingURL=([^\s]+)/)` and
    # returns the byte range `{begin, end}` of the captured URL, or `nil`.
    def source_mapping_url_byte_range(comment : String) : {Int32, Int32}?
      ensure_valid_utf8!(comment)
      return nil unless comment.starts_with?("//")
      marker = byte_at(comment, 2)
      return nil unless marker == '#'.ord || marker == '@'.ord
      keyword_start = skip_spaces(comment, 3)
      return nil unless literal_at?(comment, keyword_start, "sourceMappingURL=")
      url_start = keyword_start + "sourceMappingURL=".bytesize
      url_end = skip_chars(comment, url_start) { |char| !space?(char) }
      url_end > url_start ? {url_start, url_end} : nil
    end

    # Replaces `name.gsub(/([A-Z])/, "-\\1")`: puts a hyphen before every ASCII
    # uppercase letter.
    def hyphenate_before_uppercase(name : String) : String
      ensure_valid_utf8!(name)
      String.build(name.bytesize + 8) do |io|
        name.each_char do |char|
          io << '-' if char.ascii_uppercase?
          io << char
        end
      end
    end

    # Returns *text* without one final `\n`; a PCRE2 `$` (without the
    # MULTILINE option) matches at the very end or just before that newline.
    private def line_body(text : String) : String
      text.ends_with?('\n') ? text.byte_slice(0, text.bytesize - 1) : text
    end

    private def ascii_class_name_body?(body : String) : Bool
      first_byte = byte_at(body, 0)
      return false unless first_byte && ascii_uppercase_byte?(first_byte)
      skip_ascii_identifier(body, 1) == body.bytesize
    end

    private def caseless_prefix?(value : String, prefix : String) : Bool
      reader = Char::Reader.new(value)
      prefix.each_char do |expected|
        return false unless reader.has_next?
        actual = reader.current_char
        return false unless caseless_ascii_equal?(actual, expected)
        reader.next_char
      end
      true
    end

    # *expected* is a lowercase ASCII letter or punctuation from a scheme.
    private def caseless_ascii_equal?(actual : Char, expected : Char) : Bool
      return true if actual.downcase == expected && actual.ascii?
      expected == 's' && actual == 'ſ'
    end

    # Strided ranges overlap one another, so they are checked one by one;
    # only non-ASCII marks get here.
    private def spacing_mark?(char : Char) : Bool
      codepoint = char.ord
      SPACING_MARK_RANGES.any? do |(first, last, stride)|
        first <= codepoint <= last && (codepoint - first).divisible_by?(stride)
      end
    end
  end
end
