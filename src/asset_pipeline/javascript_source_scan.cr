# Hand-written JavaScript source scanners for the dependency analyzer and the Stimulus renderer.
# Part of the asset_pipeline shard.

require "./text_scanning"

module AssetPipeline
  # :nodoc:
  #
  # Scans JavaScript source text for the usage signals that `DependencyAnalyzer`
  # and `Stimulus::StimulusRenderer` report. Each method replaces one regular
  # expression (shown in its comment) and returns exactly what the former
  # `String#match` / `String#scan` call returned, in the same order: matches are
  # leftmost-first and do not overlap, as with `String#scan`.
  #
  # The scanners run in time linear in the length of the source.
  #
  # Each scanner raises `ArgumentError` for a source that is not valid UTF-8,
  # as the PCRE2 match did. A caller that has already checked its source
  # passes `source_is_valid_utf8: true`, so a text scanned by several
  # scanners is validated once.
  module JavascriptSourceScan
    extend self

    # How the text after a library signal's prefix must continue.
    enum Continuation
      # `\s*\(`
      OpenParenthesis
      # `\s*=`
      EqualsSign
      # One of the signal's member names, e.g. `(map|filter)`.
      MemberName
      # Nothing more: the prefix alone is the signal.
      PrefixOnly
      # `[\.\s]*[\(\w]` (the jQuery call or chain).
      JqueryChain
      # `\s+Chart\s*\(` (after the `new` prefix).
      NewChart
    end

    # One usage signal for an external library: the former
    # `DependencyAnalyzer::EXTERNAL_LIBRARY_PATTERNS` entry it replaces is in
    # the comment beside each constant entry.
    record LibrarySignal,
      library : String,
      prefix : String,
      continuation : Continuation,
      list_of_member_names : Array(String) = [] of String

    LIST_OF_LODASH_MEMBERS = %w[map filter forEach reduce find includes isEmpty isArray get set has clone]

    # The signals in the order the former pattern hash listed them, so the
    # detected library names come out in the same order.
    LIST_OF_LIBRARY_SIGNALS = [
      LibrarySignal.new("jquery", "$", :open_parenthesis),                                      # /\$\s*\(/
      LibrarySignal.new("jQuery", "jQuery", :jquery_chain),                                     # /jQuery[\.\s]*[\(\w]/
      LibrarySignal.new("lodash", "_.", :member_name, LIST_OF_LODASH_MEMBERS),                  # /_\.(map|...|clone)/
      LibrarySignal.new("lodash", "lodash.", :member_name, LIST_OF_LODASH_MEMBERS),             # /lodash\.(map|...|clone)/
      LibrarySignal.new("moment", "moment", :open_parenthesis),                                 # /moment\s*\(/
      LibrarySignal.new("moment", "moment.", :member_name, %w[now utc unix]),                   # /moment\.(now|utc|unix)/
      LibrarySignal.new("chartjs", "new", :new_chart),                                          # /new\s+Chart\s*\(/
      LibrarySignal.new("chartjs", "Chart.", :member_name, %w[register defaults]),              # /Chart\.(register|defaults)/
      LibrarySignal.new("alpinejs", "Alpine.", :member_name, %w[start data store]),             # /Alpine\.(start|data|store)/
      LibrarySignal.new("alpinejs", "x-data", :equals_sign),                                    # /x-data\s*=/
      LibrarySignal.new("vue", "Vue.", :member_name, %w[createApp ref reactive computed]),      # /Vue\.(createApp|ref|reactive|computed)/
      LibrarySignal.new("vue", "createApp", :open_parenthesis),                                 # /createApp\s*\(/
      LibrarySignal.new("react", "React.", :member_name, %w[useState useEffect createElement]), # /React\.(useState|useEffect|createElement)/
      LibrarySignal.new("react-dom", "ReactDOM.render", :prefix_only),                          # /ReactDOM\.render/
      LibrarySignal.new("axios", "axios.", :member_name, %w[get post put delete]),              # /axios\.(get|post|put|delete)/
      LibrarySignal.new("unfetch", "fetch", :open_parenthesis),                                 # /fetch\s*\(/
    ]

    # Returns the external library names whose usage signal appears in
    # *source*, each once, in signal order.
    def external_library_names(source : String, *, source_is_valid_utf8 : Bool = false) : Array(String)
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      detected = Set(String).new
      LIST_OF_LIBRARY_SIGNALS.each do |signal|
        detected.add(signal.library) if signal_present?(source, signal)
      end
      detected.to_a
    end

    # Yields every class name the three former `LOCAL_MODULE_PATTERNS` captured,
    # pattern by pattern and in source order within each pattern.
    def each_local_class_reference(source : String, *, source_is_valid_utf8 : Bool = false, & : String ->) : Nil
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      each_constructed_class_name(source, source_is_valid_utf8: true) { |class_name| yield class_name }
      each_class_with_method_call(source, source_is_valid_utf8: true) { |class_name| yield class_name }
      each_class_with_constant_reference(source, source_is_valid_utf8: true) { |class_name| yield class_name }
    end

    # Yields each capture of `/new\s+([A-Z][a-zA-Z0-9_]*)\s*\(/` in *source*.
    def each_constructed_class_name(source : String, *, source_is_valid_utf8 : Bool = false, & : String ->) : Nil
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      offset = 0
      while start = TextScanning.literal_index(source, "new", offset)
        name_start = TextScanning.skip_spaces(source, start + 3)
        first_byte = TextScanning.byte_at(source, name_start)
        if name_start > start + 3 && first_byte && TextScanning.ascii_uppercase_byte?(first_byte)
          name_end = TextScanning.skip_ascii_identifier(source, name_start + 1)
          parenthesis = TextScanning.skip_spaces(source, name_end)
          if TextScanning.byte_at(source, parenthesis) == '('.ord
            yield source.byte_slice(name_start, name_end - name_start)
            offset = parenthesis + 1
            next
          end
        end
        offset = start + 1
      end
    end

    # Yields each first capture of
    # `/([A-Z][a-zA-Z0-9_]*)\.[a-zA-Z_][a-zA-Z0-9_]*\s*\(/` in *source*.
    def each_class_with_method_call(source : String, *, source_is_valid_utf8 : Bool = false, & : String ->) : Nil
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      each_class_member_reference(source, constant_member: false) { |name| yield name }
    end

    # Yields each first capture of
    # `/([A-Z][a-zA-Z0-9_]*)\.[A-Z_][A-Z0-9_]*\s*[=\(]/` in *source*.
    def each_class_with_constant_reference(source : String, *, source_is_valid_utf8 : Bool = false, & : String ->) : Nil
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      each_class_member_reference(source, constant_member: true) { |name| yield name }
    end

    # Returns the module specifiers captured by the static-import pattern
    # `/import\s+(?:(?:\{[^}]+\}|\*\s+as\s+\w+|\w+)(?:\s*,\s*(?:\{[^}]+\}|\*\s+as\s+\w+|\w+))*\s+from\s+)?["']([^"']+)["']/`,
    # in source order.
    def static_import_specifiers(source : String, *, source_is_valid_utf8 : Bool = false) : Array(String)
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      StaticImportScan.new(source).specifiers
    end

    # Returns the module specifiers captured by
    # `/import\s*\(\s*["']([^"']+)["']\s*\)/`, in source order.
    def dynamic_import_specifiers(source : String, *, source_is_valid_utf8 : Bool = false) : Array(String)
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      specifiers = [] of String
      offset = 0
      while start = TextScanning.literal_index(source, "import", offset)
        parenthesis = TextScanning.skip_spaces(source, start + 6)
        if TextScanning.byte_at(source, parenthesis) == '('.ord
          opening_quote = TextScanning.skip_spaces(source, parenthesis + 1)
          if quoted = quoted_text_range(source, opening_quote)
            text_start, closing_quote = quoted
            close = TextScanning.skip_spaces(source, closing_quote + 1)
            if TextScanning.byte_at(source, close) == ')'.ord
              specifiers << source.byte_slice(text_start, closing_quote - text_start)
              offset = close + 1
              next
            end
          end
        end
        offset = start + 1
      end
      specifiers
    end

    # Counts the matches of `/function\s+\w+/` in *source*.
    def function_declaration_count(source : String, *, source_is_valid_utf8 : Bool = false) : Int32
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      keyword_then_word_count(source, "function")
    end

    # Counts the matches of `/class\s+\w+/` in *source*.
    def class_declaration_count(source : String, *, source_is_valid_utf8 : Bool = false) : Int32
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      keyword_then_word_count(source, "class")
    end

    # Counts the matches of
    # `/(?:const|let|var)\s+\w+\s*=\s*(?:function|\()/` in *source*.
    def function_assignment_count(source : String, *, source_is_valid_utf8 : Bool = false) : Int32
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      bytes = source.to_slice
      count = 0
      position = 0
      while position < bytes.size
        # Only `c`, `l` and `v` can start `const`, `let` or `var`.
        unless function_assignment_start_byte?(bytes[position])
          position += 1
          next
        end
        if match_end = function_assignment_end(source, position)
          count += 1
          position = match_end
        else
          position += 1
        end
      end
      count
    end

    # Counts the matches of
    # `/^\s*(?:constructor|[a-zA-Z_][a-zA-Z0-9_]*)\s*\(/m` in *source*.
    #
    # `constructor` is itself an identifier, so the pattern matches exactly
    # where `^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\(` does.
    def method_definition_count(source : String, *, source_is_valid_utf8 : Bool = false) : Int32
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      bytes = source.to_slice
      count = 0
      line_start = 0
      while line_start < source.bytesize
        name_start = TextScanning.skip_spaces(source, line_start)
        first_byte = TextScanning.byte_at(source, name_start)
        resume_at = name_start
        if first_byte && identifier_start_byte?(first_byte)
          name_end = TextScanning.skip_ascii_identifier(source, name_start + 1)
          parenthesis = TextScanning.skip_spaces(source, name_end)
          if TextScanning.byte_at(source, parenthesis) == '('.ord
            count += 1
            resume_at = parenthesis + 1
          end
        end
        # Every later line start inside the skipped spaces reaches the same
        # first non-space character, so the scan resumes at the next line
        # start past this attempt.
        break if resume_at >= bytes.size
        next_newline = bytes.index('\n'.ord.to_u8, resume_at)
        break unless next_newline
        line_start = next_newline + 1
      end
      count
    end

    # Counts the matches of `/addEventListener|on\w+\s*=/` in *source*.
    def event_listener_count(source : String, *, source_is_valid_utf8 : Bool = false) : Int32
      TextScanning.ensure_valid_utf8!(source) unless source_is_valid_utf8
      count = 0
      position = 0
      # Attempts at `on` before this byte index are known to fail.
      on_attempts_fail_before = 0
      bytes = source.to_slice
      while position < bytes.size
        # Only `a` and `o` can start `addEventListener` or `on`.
        byte = bytes[position]
        if byte == 'a'.ord && TextScanning.literal_at?(source, position, "addEventListener")
          count += 1
          position += "addEventListener".bytesize
          next
        end
        if byte == 'o'.ord && position >= on_attempts_fail_before && TextScanning.byte_at(source, position + 1) == 'n'.ord
          word_end = TextScanning.skip_word_chars(source, position + 2)
          if word_end > position + 2
            equals = TextScanning.skip_spaces(source, word_end)
            if TextScanning.byte_at(source, equals) == '='.ord
              count += 1
              position = equals + 1
              next
            end
          end
          # Any `on` that starts inside this word run reaches the same end
          # and fails the same way.
          on_attempts_fail_before = word_end
        end
        position += 1
      end
      count
    end

    # Yields each controller class captured (second group) by
    # `/Stimulus\.register\s*\(\s*["']([^"']+)["']\s*,\s*([A-Za-z][A-Za-z0-9_]*)\s*\)/`.
    def each_stimulus_registered_class(source : String, & : String ->) : Nil
      TextScanning.ensure_valid_utf8!(source)
      offset = 0
      while start = TextScanning.literal_index(source, "Stimulus.register", offset)
        if match = stimulus_registration_class_range(source, start + "Stimulus.register".bytesize)
          class_start, class_end, match_end = match
          yield source.byte_slice(class_start, class_end - class_start)
          offset = match_end
        else
          offset = start + 1
        end
      end
    end

    # Yields each default-import binding captured (first group) by
    # `/import\s+([A-Za-z][A-Za-z0-9_]*)\s+from\s+["']([^"']+)["']/`.
    def each_default_import_name(source : String, & : String ->) : Nil
      TextScanning.ensure_valid_utf8!(source)
      offset = 0
      while start = TextScanning.literal_index(source, "import", offset)
        name_start = TextScanning.skip_spaces(source, start + 6)
        first_byte = TextScanning.byte_at(source, name_start)
        if name_start > start + 6 && first_byte && first_byte.unsafe_chr.ascii_letter?
          name_end = TextScanning.skip_ascii_identifier(source, name_start + 1)
          if quote_end = from_clause_end(source, name_end)
            yield source.byte_slice(name_start, name_end - name_start)
            offset = quote_end
            next
          end
        end
        offset = start + 1
      end
    end

    private def signal_present?(source : String, signal : LibrarySignal) : Bool
      offset = 0
      while start = TextScanning.literal_index(source, signal.prefix, offset)
        return true if continues_signal?(source, start + signal.prefix.bytesize, signal)
        offset = start + 1
      end
      false
    end

    private def continues_signal?(source : String, position : Int32, signal : LibrarySignal) : Bool
      case signal.continuation
      in .open_parenthesis?
        TextScanning.byte_at(source, TextScanning.skip_spaces(source, position)) == '('.ord
      in .equals_sign?
        TextScanning.byte_at(source, TextScanning.skip_spaces(source, position)) == '='.ord
      in .member_name?
        signal.list_of_member_names.any? { |member| TextScanning.literal_at?(source, position, member) }
      in .prefix_only?
        true
      in .jquery_chain?
        after_chain = TextScanning.skip_chars(source, position) { |char| char == '.' || TextScanning.space?(char) }
        return false if after_chain >= source.bytesize
        char = Char::Reader.new(source, after_chain).current_char
        char == '(' || TextScanning.word_char?(char)
      in .new_chart?
        chart_start = TextScanning.skip_spaces(source, position)
        chart_start > position && TextScanning.literal_at?(source, chart_start, "Chart") &&
          TextScanning.byte_at(source, TextScanning.skip_spaces(source, chart_start + 5)) == '('.ord
      end
    end

    # The caller has validated *source*.
    private def each_class_member_reference(source : String, constant_member : Bool, & : String ->) : Nil
      bytes = source.to_slice
      position = 0
      while position < bytes.size
        unless TextScanning.ascii_uppercase_byte?(bytes[position])
          position += 1
          next
        end
        name_end = TextScanning.skip_ascii_identifier(source, position + 1)
        if match_end = class_member_end(source, name_end, constant_member)
          yield source.byte_slice(position, name_end - position)
          position = match_end
        else
          # Every uppercase start inside this identifier reaches the same
          # end and fails the same way.
          position = name_end
        end
      end
    end

    # Matches `\.[a-zA-Z_][a-zA-Z0-9_]*\s*\(` (or, for a constant member,
    # `\.[A-Z_][A-Z0-9_]*\s*[=\(]`) at *position* and returns the match end.
    private def class_member_end(source : String, position : Int32, constant_member : Bool) : Int32?
      return nil unless TextScanning.byte_at(source, position) == '.'.ord
      first_byte = TextScanning.byte_at(source, position + 1)
      return nil unless first_byte
      if constant_member
        return nil unless TextScanning.ascii_uppercase_byte?(first_byte) || first_byte == '_'.ord
        member_end = skip_constant_identifier(source, position + 2)
        terminator = TextScanning.skip_spaces(source, member_end)
        terminator_byte = TextScanning.byte_at(source, terminator)
        return terminator + 1 if terminator_byte == '='.ord || terminator_byte == '('.ord
      else
        return nil unless identifier_start_byte?(first_byte)
        member_end = TextScanning.skip_ascii_identifier(source, position + 2)
        parenthesis = TextScanning.skip_spaces(source, member_end)
        return parenthesis + 1 if TextScanning.byte_at(source, parenthesis) == '('.ord
      end
      nil
    end

    # Skips `[A-Z0-9_]*`.
    private def skip_constant_identifier(source : String, position : Int32) : Int32
      bytes = source.to_slice
      index = position
      while index < bytes.size
        byte = bytes[index]
        break unless TextScanning.ascii_uppercase_byte?(byte) || byte.unsafe_chr.ascii_number? || byte == '_'.ord
        index += 1
      end
      index
    end

    # `c`, `l` or `v`, the first bytes of `const`, `let` and `var`.
    private def function_assignment_start_byte?(byte : UInt8) : Bool
      byte == 'c'.ord || byte == 'l'.ord || byte == 'v'.ord
    end

    # `[a-zA-Z_]`
    private def identifier_start_byte?(byte : UInt8) : Bool
      byte.unsafe_chr.ascii_letter? || byte == '_'.ord
    end

    # The caller has validated *source*.
    private def keyword_then_word_count(source : String, keyword : String) : Int32
      count = 0
      offset = 0
      while start = TextScanning.literal_index(source, keyword, offset)
        word_start = TextScanning.skip_spaces(source, start + keyword.bytesize)
        if word_start > start + keyword.bytesize
          word_end = TextScanning.skip_word_chars(source, word_start)
          if word_end > word_start
            count += 1
            offset = word_end
            next
          end
        end
        offset = start + 1
      end
      count
    end

    private def function_assignment_end(source : String, position : Int32) : Int32?
      keyword_end = TextScanning.literal_alternative_end(source, position, {"const", "let", "var"})
      return nil unless keyword_end
      word_start = TextScanning.skip_spaces(source, keyword_end)
      return nil unless word_start > keyword_end
      word_end = TextScanning.skip_word_chars(source, word_start)
      return nil unless word_end > word_start
      equals = TextScanning.skip_spaces(source, word_end)
      return nil unless TextScanning.byte_at(source, equals) == '='.ord
      value_start = TextScanning.skip_spaces(source, equals + 1)
      TextScanning.literal_alternative_end(source, value_start, {"function", "("})
    end

    # Matches `\s*\(\s*["']([^"']+)["']\s*,\s*([A-Za-z][A-Za-z0-9_]*)\s*\)`
    # at *position*; returns the class name range and the match end.
    private def stimulus_registration_class_range(source : String, position : Int32) : {Int32, Int32, Int32}?
      parenthesis = TextScanning.skip_spaces(source, position)
      return nil unless TextScanning.byte_at(source, parenthesis) == '('.ord
      quoted = quoted_text_range(source, TextScanning.skip_spaces(source, parenthesis + 1))
      return nil unless quoted
      comma = TextScanning.skip_spaces(source, quoted[1] + 1)
      return nil unless TextScanning.byte_at(source, comma) == ','.ord
      class_start = TextScanning.skip_spaces(source, comma + 1)
      first_byte = TextScanning.byte_at(source, class_start)
      return nil unless first_byte && first_byte.unsafe_chr.ascii_letter?
      class_end = TextScanning.skip_ascii_identifier(source, class_start + 1)
      close = TextScanning.skip_spaces(source, class_end)
      return nil unless TextScanning.byte_at(source, close) == ')'.ord
      {class_start, class_end, close + 1}
    end

    # Matches `\s+from\s+["']([^"']+)["']` at *position*; returns the match end.
    private def from_clause_end(source : String, position : Int32) : Int32?
      keyword_start = TextScanning.skip_spaces(source, position)
      return nil unless keyword_start > position && TextScanning.literal_at?(source, keyword_start, "from")
      quote_start = TextScanning.skip_spaces(source, keyword_start + 4)
      return nil unless quote_start > keyword_start + 4
      quoted = quoted_text_range(source, quote_start)
      quoted ? quoted[1] + 1 : nil
    end

    # Matches `["']([^"']+)["']` at *position*; returns the captured text's
    # start and the closing quote's byte index. Either quote closes either.
    protected def quoted_text_range(source : String, position : Int32) : {Int32, Int32}?
      opening = TextScanning.byte_at(source, position)
      return nil unless opening && quote_byte?(opening)
      bytes = source.to_slice
      index = position + 1
      while index < bytes.size && !quote_byte?(bytes[index])
        index += 1
      end
      return nil if index >= bytes.size || index == position + 1
      {position + 1, index}
    end

    protected def quote_byte?(byte : UInt8) : Bool
      byte == '"'.ord || byte == '\''.ord
    end

    # Scans for the static-import pattern documented on
    # `JavascriptSourceScan.static_import_specifiers`.
    #
    # The pattern never needs to backtrack: every alternative and repetition
    # is decided by the next character. Attempts that start at different
    # `import` keywords can still converge on the same position (several `{`
    # closing at one `}`), so the outcome after each import binding is
    # memoized and the scan stays linear.
    private struct StaticImportScan
      @outcome_after_binding = {} of Int32 => {Int32, Int32, Int32}?
      @closing_brace_search_from = -1
      @closing_brace_at : Int32? = nil

      def initialize(@source : String)
      end

      def specifiers : Array(String)
        list_of_specifiers = [] of String
        offset = 0
        while start = TextScanning.literal_index(@source, "import", offset)
          if match = match_at(start)
            text_start, text_end, match_end = match
            list_of_specifiers << @source.byte_slice(text_start, text_end - text_start)
            offset = match_end
          else
            offset = start + 1
          end
        end
        list_of_specifiers
      end

      # Returns {capture start, capture end, match end} for a match that
      # starts with the `import` keyword at *start*.
      private def match_at(start : Int32) : {Int32, Int32, Int32}?
        clause_start = TextScanning.skip_spaces(@source, start + 6)
        return nil unless clause_start > start + 6
        if quoted = JavascriptSourceScan.quoted_text_range(@source, clause_start)
          return {quoted[0], quoted[1], quoted[1] + 1}
        end
        binding_end = import_binding_end(clause_start)
        binding_end ? outcome_after_binding(binding_end) : nil
      end

      # Continues `(?:\s*,\s*BINDING)*\s+from\s+["']([^"']+)["']` from
      # *position*, the end of an import binding.
      private def outcome_after_binding(position : Int32) : {Int32, Int32, Int32}?
        list_of_visited = [] of Int32
        outcome = nil
        current = position
        loop do
          if @outcome_after_binding.has_key?(current)
            outcome = @outcome_after_binding[current]
            break
          end
          list_of_visited << current
          after_spaces = TextScanning.skip_spaces(@source, current)
          if TextScanning.byte_at(@source, after_spaces) == ','.ord
            next_binding_end = import_binding_end(TextScanning.skip_spaces(@source, after_spaces + 1))
            if next_binding_end
              current = next_binding_end
              next
            end
          end
          outcome = from_clause(current)
          break
        end
        list_of_visited.each { |visited| @outcome_after_binding[visited] = outcome }
        outcome
      end

      # Matches `\s+from\s+["']([^"']+)["']` at *position*.
      private def from_clause(position : Int32) : {Int32, Int32, Int32}?
        keyword_start = TextScanning.skip_spaces(@source, position)
        return nil unless keyword_start > position && TextScanning.literal_at?(@source, keyword_start, "from")
        quote_start = TextScanning.skip_spaces(@source, keyword_start + 4)
        return nil unless quote_start > keyword_start + 4
        quoted = JavascriptSourceScan.quoted_text_range(@source, quote_start)
        quoted ? {quoted[0], quoted[1], quoted[1] + 1} : nil
      end

      # Matches one binding, `\{[^}]+\}|\*\s+as\s+\w+|\w+`, at *position* and
      # returns its end. The first character picks the alternative.
      private def import_binding_end(position : Int32) : Int32?
        return nil if position >= @source.bytesize
        first_char = Char::Reader.new(@source, position).current_char
        case first_char
        when '{'
          closing = closing_brace_from(position + 1)
          closing && closing > position + 1 ? closing + 1 : nil
        when '*'
          as_start = TextScanning.skip_spaces(@source, position + 1)
          return nil unless as_start > position + 1 && TextScanning.literal_at?(@source, as_start, "as")
          name_start = TextScanning.skip_spaces(@source, as_start + 2)
          return nil unless name_start > as_start + 2
          name_end = TextScanning.skip_word_chars(@source, name_start)
          name_end > name_start ? name_end : nil
        else
          return nil unless TextScanning.word_char?(first_char)
          TextScanning.skip_word_chars(@source, position)
        end
      end

      # Returns the byte index of the first `}` at or after *position*. The
      # last answer is remembered, so attempts that search inside the same
      # stretch of text do not rescan it.
      private def closing_brace_from(position : Int32) : Int32?
        if @closing_brace_search_from >= 0 && position >= @closing_brace_search_from
          closing = @closing_brace_at
          return closing if closing.nil? || position <= closing
        end
        @closing_brace_search_from = position
        @closing_brace_at = @source.to_slice.index('}'.ord.to_u8, position)
      end
    end
  end
end
