require "./safe_url"

module Components
  # `srcset` is a comma-separated list of `"<url> <descriptor>?"` candidates
  # — a URL *list with descriptors*, not a single URL — so `SafeURL` alone
  # cannot validate it (proposal §3.3 external-examiner caveat: "srcset ...
  # needs its own parser, not plain SafeURL").
  #
  # This parses each candidate, validates its URL component through
  # `SafeURL`, and validates its descriptor against the width (`NNNw`) or
  # pixel-density (`N.Nx`) grammar. The whole value is rejected if ANY
  # candidate is unsafe or malformed — fail closed, not "escape what we can."
  struct SafeSrcSet
    class UnsafeSrcSetError < ArgumentError
    end

    DESCRIPTOR_PATTERN = /\A\d+(\.\d+)?[wx]\z/

    protected def initialize(@value : String)
    end

    def self.parse(srcset : String) : SafeSrcSet?
      parse!(srcset)
    rescue UnsafeSrcSetError | SafeURL::UnsafeURLError
      nil
    end

    def self.parse!(srcset : String) : SafeSrcSet
      candidates = srcset.split(',').map(&.strip).reject(&.empty?)
      raise UnsafeSrcSetError.new("SafeSrcSet: empty srcset") if candidates.empty?

      validated = candidates.map do |candidate|
        parts = candidate.split(/\s+/, 2)
        url_part = parts[0]
        descriptor = parts[1]?

        safe_url = SafeURL.parse!(url_part)

        if descriptor
          unless descriptor.matches?(DESCRIPTOR_PATTERN)
            raise UnsafeSrcSetError.new("SafeSrcSet: invalid descriptor #{descriptor.inspect} on candidate #{candidate.inspect} (expected e.g. \"2x\" or \"480w\")")
          end
          "#{safe_url} #{descriptor}"
        else
          safe_url.to_s
        end
      end

      new(validated.join(", "))
    end

    def to_s : String
      @value
    end

    def to_s(io : IO) : Nil
      io << @value
    end
  end
end
