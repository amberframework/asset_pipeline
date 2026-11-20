require "http"
require "./stored_page"

module Components
  module Cache
    # Chooses the representation and status for one read of a stored page, and writes them.
    struct PageAnswer
      CACHE_CONTROL = "no-cache"

      enum Representation
        Identity
        Gzip
        Brotli
      end

      getter representation : Representation

      # The ETag of the chosen representation, or nil before the page has one.
      getter etag : String?

      def initialize(@page : StoredPage, accept_encoding : String?, @if_none_match : String?, @varies_by_encoding : Bool)
        @representation = representation_for(accept_encoding)
        etag_bytes = case @representation
                     in .brotli?   then @page.brotli_etag
                     in .gzip?     then @page.gzip_etag
                     in .identity? then @page.identity_etag
                     end
        @etag = etag_bytes ? String.new(etag_bytes) : nil
      end

      def not_modified? : Bool
        if_none_match = @if_none_match
        current_etag = @etag
        return false unless if_none_match && current_etag
        if_none_match.split(',').any? do |candidate|
          stripped_candidate = candidate.strip
          stripped_candidate == "*" || stripped_candidate.lchop("W/") == current_etag
        end
      end

      # The bytes of the chosen representation, without copying them.
      def body : Bytes
        case representation
        in .brotli?   then @page.brotli || @page.html
        in .gzip?     then @page.gzip || @page.html
        in .identity? then @page.html
        end
      end

      def write_to(context : HTTP::Server::Context) : Nil
        response = context.response
        response.headers["Cache-Control"] = CACHE_CONTROL
        response.headers["Vary"] = "Accept-Encoding" if @varies_by_encoding
        current_etag = @etag
        response.headers["ETag"] = current_etag if current_etag
        if not_modified?
          response.status = :not_modified
          return
        end

        response.content_type = @page.content_type
        case representation
        when .brotli? then response.headers["Content-Encoding"] = "br"
        when .gzip?   then response.headers["Content-Encoding"] = "gzip"
        end
        bytes = body
        response.content_length = bytes.size
        response.write(bytes) unless context.request.method == "HEAD"
      end

      # Brotli wins when the client allows both and the page holds both.
      private def representation_for(accept_encoding : String?) : Representation
        return Representation::Identity unless accept_encoding
        accepts_brotli = false
        accepts_gzip = false
        accept_encoding.split(',').each do |coding|
          coding_name, _, parameters = coding.partition(';')
          next if PageAnswer.refuses_coding?(parameters)
          stripped_name = coding_name.strip
          accepts_brotli ||= stripped_name.compare("br", case_insensitive: true) == 0
          accepts_gzip ||= stripped_name.compare("gzip", case_insensitive: true) == 0
        end
        return Representation::Brotli if accepts_brotli && @page.brotli
        return Representation::Gzip if accepts_gzip && @page.gzip
        Representation::Identity
      end

      # :nodoc:
      #
      # Returns whether one Accept-Encoding entry's parameters refuse its coding:
      # the last parameter is `q=0`, `q=0.` or `q=0.` followed by zeros, ignoring
      # spaces and case.
      #
      # Written by hand so that the page cache, which generated Amber apps load by
      # default, links no regular-expression engine. It answers exactly as the
      # pattern it replaced, `/(^|;)q=0(\.0*)?$/`, on the same normalized text.
      def self.refuses_coding?(parameters : String) : Bool
        return false if parameters.empty?
        normalized_parameters = parameters.delete(' ').downcase
        bytes = normalized_parameters.to_slice
        return true if zero_quality?(last_parameter(bytes))
        # The former pattern's `$` also matched just before one final newline.
        normalized_parameters.ends_with?('\n') && zero_quality?(last_parameter(bytes[0, bytes.size - 1]))
      end

      # The bytes after the last `;`, read in place.
      private def self.last_parameter(bytes : Bytes) : Bytes
        separator = bytes.rindex(';'.ord.to_u8)
        separator ? bytes[separator + 1..] : bytes
      end

      # `q=0`, optionally followed by a dot and any number of zeros.
      private def self.zero_quality?(parameter : Bytes) : Bool
        return false unless parameter.size >= 3 && parameter[0] == 'q'.ord && parameter[1] == '='.ord && parameter[2] == '0'.ord
        return true if parameter.size == 3
        parameter[3] == '.'.ord && parameter[4..].all?('0'.ord)
      end
    end
  end
end
