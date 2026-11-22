module SpecSupport
  # Reads attribute values and element text out of rendered markup.
  #
  # The patterns use no lookahead and no backreference, so every `Regex`
  # engine compiles them, Mica (the default engine of crystal-alpha from
  # 1.21.0-incremental-6) included. Each match is made on the wider text,
  # and the context the old patterns looked ahead for, or referred back to,
  # is checked in Crystal.
  module HtmlScanning
    # The value of every *name* attribute in *html*, `""` for an attribute
    # written without a value. An attribute counts when white space or `>`
    # follows it. With *spaces_around_equals*, `name = "value"` counts too.
    def self.attr_values(html : String, name : String, *, spaces_around_equals : Bool = false) : Array(String)
      escaped_name = Regex.escape(name)
      pattern = if spaces_around_equals
                  /(^|[\s<])#{escaped_name}(?:\s*=\s*(?:"([^"]*)"|'([^']*)'))?/
                else
                  /(^|[\s<])#{escaped_name}(?:=(?:"([^"]*)"|'([^']*)'))?/
                end

      list_of_values = [] of String
      position = 0
      while position <= html.size && (match = pattern.match(html, position))
        end_of_name = match.begin + match[1].size + name.size
        if ends_an_attribute?(html, match.end)
          list_of_values << (match[2]? || match[3]? || "")
          position = {match.end, position + 1}.max
        elsif match.end != end_of_name && ends_an_attribute?(html, end_of_name)
          # The value is followed by something else, and the name alone is
          # followed by white space: the attribute counts without the value.
          list_of_values << ""
          position = {end_of_name, position + 1}.max
        else
          position = match.begin + 1
        end
      end
      list_of_values
    end

    # The text, without tags, of the first element whose `id` is *id* and
    # that has a closing tag of the same name. `""` when there is none. With
    # *either_quote*, `id='...'` counts as well as `id="..."`.
    def self.element_text_by_id(html : String, id : String, *, either_quote : Bool = false) : String
      escaped_id = Regex.escape(id)
      opening_tag = if either_quote
                      /<([a-zA-Z][\w:-]*)\b[^>]*\sid=(?:"#{escaped_id}"|'#{escaped_id}')[^>]*>/
                    else
                      /<([a-zA-Z][\w:-]*)\b[^>]*\sid="#{escaped_id}"[^>]*>/
                    end

      position = 0
      while position <= html.size && (match = opening_tag.match(html, position))
        start_of_name = match.begin + 1
        list_of_tag_names(html, start_of_name, match[1].size).each do |tag_name|
          start_of_closing_tag = html.index("</#{tag_name}>", match.end)
          next unless start_of_closing_tag
          return html[match.end...start_of_closing_tag].gsub(/<[^>]+>/, "").strip
        end
        position = match.begin + 1
      end
      ""
    end

    private def self.ends_an_attribute?(html : String, index : Int32) : Bool
      char = html[index]?
      char ? char.to_s.matches?(/\A[\s>]\z/) : false
    end

    # The names the tag starting at *start_of_name* can be read as, longest
    # first: each prefix of its name that ends at a word boundary (`my-tag`
    # reads as `my-tag` and as `my`).
    private def self.list_of_tag_names(html : String, start_of_name : Int32, longest_size : Int32) : Array(String)
      longest_size.downto(1).compact_map do |size|
        last_char = html[start_of_name + size - 1]
        following_char = html[start_of_name + size]?
        next unless word_char?(last_char) != (following_char ? word_char?(following_char) : false)
        html[start_of_name, size]
      end.to_a
    end

    private def self.word_char?(char : Char) : Bool
      char.to_s.matches?(/\A\w\z/)
    end
  end
end
