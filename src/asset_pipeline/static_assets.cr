require "base64"
require "compress/gzip"
require "digest/sha256"
require "file_utils"
require "json"
require "random/secure"
require "uri"

module AssetPipeline
  # A deterministic, content-addressed compiler for application-owned web assets.
  #
  # Files are addressed by their normalized path relative to `source_root`.
  # Builds preserve that directory structure, fingerprint every emitted file, and
  # write a manifest suitable for runtime URL lookup. Text assets remain byte-for-
  # byte identical except for local dependency URLs, which are rewritten to the
  # dependency's fingerprinted public URL.
  module StaticAssets
    MANIFEST_SCHEMA_VERSION = 1
    DEFAULT_MANIFEST_NAME   = "manifest.json"
    FINGERPRINT_LENGTH      = 32

    class Error < Exception
    end

    class ConfigurationError < Error
    end

    class MissingAssetError < Error
      getter logical_path : String

      def initialize(@logical_path : String, detail : String? = nil)
        message = "Static asset '#{@logical_path}' was not found"
        message += ": #{detail}" if detail
        super(message)
      end
    end

    class InvalidReferenceError < Error
      getter source_path : String
      getter reference : String

      def initialize(@source_path : String, @reference : String, detail : String)
        super("Invalid static asset reference '#{@reference}' in '#{@source_path}': #{detail}")
      end
    end

    class VerificationError < Error
    end

    struct ManifestEntry
      include JSON::Serializable

      getter path : String
      getter digest : String
      getter integrity : String
      getter content_type : String
      getter bytes : Int64

      def initialize(
        @path : String,
        @digest : String,
        @integrity : String,
        @content_type : String,
        @bytes : Int64,
      )
      end
    end

    class Manifest
      include JSON::Serializable

      getter schema_version : Int32
      getter public_path : String
      getter assets : Hash(String, ManifestEntry)

      def initialize(
        @schema_version : Int32 = MANIFEST_SCHEMA_VERSION,
        @public_path : String = "/assets",
        @assets : Hash(String, ManifestEntry) = {} of String => ManifestEntry,
      )
      end

      def self.load(file : Path | String) : self
        path = file.to_s
        raise ConfigurationError.new("Static asset manifest does not exist: #{path}") unless File.file?(path)

        manifest = from_json(File.read(path))
        unless manifest.schema_version == MANIFEST_SCHEMA_VERSION
          raise ConfigurationError.new(
            "Unsupported static asset manifest schema #{manifest.schema_version}; expected #{MANIFEST_SCHEMA_VERSION}"
          )
        end
        manifest
      rescue ex : JSON::SerializableError
        raise ConfigurationError.new("Static asset manifest does not match schema (#{path}): #{ex.message}")
      rescue ex : JSON::ParseException
        raise ConfigurationError.new("Static asset manifest is invalid JSON (#{path}): #{ex.message}")
      end

      def entry(logical_path : Path | String) : ManifestEntry
        logical = LogicalPath.normalize(logical_path.to_s)
        @assets[logical]? || raise MissingAssetError.new(logical, "not present in the compiled manifest")
      end

      def path(logical_path : Path | String) : String
        entry(logical_path).path
      end

      def integrity(logical_path : Path | String) : String
        entry(logical_path).integrity
      end

      # Verifies that every manifest entry exists beneath *output_root* and
      # still matches its byte count, SHA-256 digest, SRI value, MIME type, and
      # expected precompressed representation.
      def verify(output_root : Path | String) : Nil
        root = Path[output_root.to_s].expand.normalize
        @assets.keys.sort.each do |logical|
          asset = @assets[logical]
          normalized_logical = LogicalPath.normalize(logical)
          unless asset.digest.matches?(/\A[a-f0-9]{64}\z/)
            raise VerificationError.new("Static asset '#{normalized_logical}' has an invalid SHA-256 digest")
          end
          expected_path = expected_public_url(normalized_logical, asset.digest)
          unless asset.path == expected_path
            raise VerificationError.new(
              "Static asset '#{normalized_logical}' has non-canonical path '#{asset.path}', expected '#{expected_path}'"
            )
          end
          expected_type = MimeTypes.for(normalized_logical)
          unless asset.content_type == expected_type
            raise VerificationError.new(
              "Static asset '#{normalized_logical}' has content type '#{asset.content_type}', expected '#{expected_type}'"
            )
          end

          relative = relative_output_path(asset.path)
          file = root.join(relative).normalize
          unless within_root?(file, root)
            raise VerificationError.new("Static asset '#{normalized_logical}' resolves outside output root")
          end
          unless File.file?(file)
            raise VerificationError.new("Compiled static asset is missing: #{file}")
          end

          bytes = File.read(file).to_slice
          digest = Digest::SHA256.hexdigest(bytes)
          integrity = "sha256-#{Base64.strict_encode(Digest::SHA256.digest(bytes))}"
          unless asset.bytes == bytes.size
            raise VerificationError.new("Compiled static asset byte count changed: #{normalized_logical}")
          end
          unless asset.digest == digest
            raise VerificationError.new("Compiled static asset digest changed: #{normalized_logical}")
          end
          unless asset.integrity == integrity
            raise VerificationError.new("Compiled static asset integrity changed: #{normalized_logical}")
          end
          if MimeTypes.compressible?(asset.content_type)
            gzip_file = "#{file}.gz"
            unless File.file?(gzip_file)
              raise VerificationError.new("Precompressed static asset is missing: #{gzip_file}")
            end
            begin
              expanded = Compress::Gzip::Reader.open(gzip_file, &.gets_to_end)
              unless expanded.to_slice == bytes
                raise VerificationError.new("Precompressed static asset content changed: #{normalized_logical}")
              end
            rescue ex : Compress::Gzip::Error | Compress::Deflate::Error | IO::Error
              raise VerificationError.new("Precompressed static asset is invalid: #{normalized_logical}: #{ex.message}")
            end
          end
        end
      end

      def to_deterministic_json : String
        String.build do |io|
          JSON.build(io, indent: "  ") do |json|
            json.object do
              json.field "schema_version", @schema_version
              json.field "public_path", @public_path
              json.field "assets" do
                json.object do
                  @assets.keys.sort.each do |logical|
                    asset = @assets[logical]
                    json.field logical do
                      json.object do
                        json.field "path", asset.path
                        json.field "digest", asset.digest
                        json.field "integrity", asset.integrity
                        json.field "content_type", asset.content_type
                        json.field "bytes", asset.bytes
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      private def relative_output_path(public_url : String) : String
        normalized_public_path = normalized_public_path()
        prefix = normalized_public_path == "/" ? "/" : "#{normalized_public_path}/"
        unless public_url.starts_with?(prefix)
          raise VerificationError.new("Manifest path is outside public path: #{public_url}")
        end
        LogicalPath.normalize(URI.decode(public_url[prefix.size..]))
      rescue ex : URI::Error
        raise VerificationError.new("Manifest path has invalid URL encoding: #{public_url}")
      end

      private def expected_public_url(logical : String, digest : String) : String
        extension = File.extname(logical)
        stem = extension.empty? ? logical : logical[0, logical.bytesize - extension.bytesize]
        fingerprinted = "#{stem}-#{digest[0, FINGERPRINT_LENGTH]}#{extension}"
        encoded = fingerprinted.split('/').map { |part| URI.encode_path_segment(part) }.join('/')
        base = normalized_public_path()
        base == "/" ? "/#{encoded}" : "#{base}/#{encoded}"
      end

      private def normalized_public_path : String
        value = @public_path.strip
        unless value.starts_with?('/') && !value.starts_with?("//") && !value.includes?('?') && !value.includes?('#')
          raise VerificationError.new("Manifest public path must be a root-relative URL path")
        end
        value = value.gsub(/\/{2,}/, "/")
        value = value.rstrip('/') unless value == "/"
        value
      end

      private def within_root?(path : Path, root : Path) : Bool
        relative = path.relative_to?(root)
        return false unless relative
        value = relative.to_s.gsub('\\', '/')
        value != ".." && !value.starts_with?("../")
      end
    end

    private module LogicalPath
      extend self

      def normalize(value : String) : String
        normalized = value.gsub('\\', '/').strip
        while normalized.starts_with?("./")
          normalized = normalized[2..]
        end

        if normalized.empty? || normalized.starts_with?('/') || normalized.includes?('\0')
          raise ConfigurationError.new("Invalid static asset logical path: #{value.inspect}")
        end

        parts = normalized.split('/')
        if parts.any? { |part| part.empty? || part == "." || part == ".." }
          raise ConfigurationError.new("Static asset logical path must not traverse directories: #{value.inspect}")
        end
        parts.join('/')
      end

      def from_path(path : Path, source_root : Path) : String
        relative = path.relative_to?(source_root)
        raise ConfigurationError.new("Static asset escaped source root: #{path}") unless relative
        normalize(relative.to_s)
      end
    end

    private struct SourceAsset
      getter logical_path : String
      getter path : Path

      def initialize(@logical_path : String, @path : Path)
      end
    end

    class Compiler
      getter source_root : Path
      getter output_root : Path
      getter public_path : String
      getter manifest_name : String
      getter manifest : Manifest?

      def initialize(
        source_root : Path | String,
        output_root : Path | String,
        public_path : String = "/assets",
        manifest_name : String = DEFAULT_MANIFEST_NAME,
      )
        @source_root = Path[source_root.to_s].expand.normalize
        @output_root = Path[output_root.to_s].expand.normalize
        @public_path = normalize_public_path(public_path)
        @manifest_name = LogicalPath.normalize(manifest_name)
        @manifest = nil
        validate_configuration!
      end

      def self.load_manifest(
        output_root : Path | String,
        manifest_name : String = DEFAULT_MANIFEST_NAME,
      ) : Manifest
        Manifest.load(Path[output_root.to_s].join(LogicalPath.normalize(manifest_name)))
      end

      def self.check(
        output_root : Path | String,
        manifest_name : String = DEFAULT_MANIFEST_NAME,
      ) : Manifest
        manifest = load_manifest(output_root: output_root, manifest_name: manifest_name)
        manifest.verify(output_root)
        manifest
      end

      def build : Manifest
        sources = discover_sources
        emitted = compile_all(sources)
        entries = {} of String => ManifestEntry

        emitted.keys.sort.each do |logical|
          bytes = emitted[logical]
          digest = Digest::SHA256.hexdigest(bytes)
          fingerprinted = fingerprinted_path(logical, digest)
          entries[logical] = ManifestEntry.new(
            path: public_url(fingerprinted),
            digest: digest,
            integrity: "sha256-#{Base64.strict_encode(Digest::SHA256.digest(bytes))}",
            content_type: MimeTypes.for(logical),
            bytes: bytes.size.to_i64,
          )
        end

        new_manifest = Manifest.new(public_path: @public_path, assets: entries)
        previous_manifest = load_previous_manifest
        write_build(emitted, new_manifest)
        prune_previous_build(previous_manifest, new_manifest)
        @manifest = new_manifest
        new_manifest
      end

      def entry(logical_path : Path | String) : ManifestEntry
        current_manifest.entry(logical_path)
      end

      def asset_path(logical_path : Path | String) : String
        current_manifest.path(logical_path)
      end

      def integrity(logical_path : Path | String) : String
        current_manifest.integrity(logical_path)
      end

      def check : Manifest
        checked = self.class.check(output_root: @output_root, manifest_name: @manifest_name)
        @manifest = checked
        checked
      end

      private def current_manifest : Manifest
        @manifest || raise ConfigurationError.new("Static assets have not been built; call #build first")
      end

      private def validate_configuration! : Nil
        unless Dir.exists?(@source_root)
          raise ConfigurationError.new("Static asset source root does not exist: #{@source_root}")
        end

        source_real = Path[File.realpath(@source_root)]
        output_parent = nearest_existing_parent(@output_root)
        output_real = Path[File.realpath(output_parent)].join(@output_root.relative_to(output_parent)).normalize

        if within?(output_real, source_real)
          raise ConfigurationError.new("Static asset output root must not be inside source root")
        end
        if within?(source_real, output_real)
          raise ConfigurationError.new("Static asset source root must not be inside output root")
        end
      end

      private def discover_sources : Hash(String, SourceAsset)
        source_real = Path[File.realpath(@source_root)]
        result = {} of String => SourceAsset

        Dir.glob(glob_pattern(@source_root.join("**", "*"))).sort.each do |file_name|
          next if File.directory?(file_name)

          file_path = Path[file_name].expand.normalize
          logical = LogicalPath.from_path(file_path, @source_root)
          next if hidden_logical_path?(logical)

          real_path = Path[File.realpath(file_path)]
          unless within?(real_path, source_real)
            raise ConfigurationError.new("Static asset symlink escapes source root: #{logical}")
          end

          if result.has_key?(logical)
            raise ConfigurationError.new("Duplicate static asset logical path: #{logical}")
          end
          result[logical] = SourceAsset.new(logical, real_path)
        end
        result
      end

      private def hidden_logical_path?(logical : String) : Bool
        logical.split('/').any?(&.starts_with?('.'))
      end

      private def compile_all(sources : Hash(String, SourceAsset)) : Hash(String, Bytes)
        emitted = {} of String => Bytes
        states = {} of String => Symbol

        sources.keys.sort.each do |logical|
          compile_asset(logical, sources, emitted, states)
        end
        emitted
      end

      private def compile_asset(
        logical : String,
        sources : Hash(String, SourceAsset),
        emitted : Hash(String, Bytes),
        states : Hash(String, Symbol),
      ) : Bytes
        return emitted[logical] if emitted.has_key?(logical)
        if states[logical]? == :visiting
          raise InvalidReferenceError.new(logical, logical, "dependency cycle detected")
        end

        source = sources[logical]? || raise MissingAssetError.new(logical)
        states[logical] = :visiting
        original = File.read(source.path).to_slice.dup
        extension = File.extname(logical).downcase

        compiled = case extension
                   when ".css"
                     rewrite_css(String.new(original), logical, sources, emitted, states).to_slice.dup
                   when ".js", ".mjs", ".cjs"
                     rewrite_javascript(String.new(original), logical, sources, emitted, states).to_slice.dup
                   else
                     original
                   end

        states[logical] = :done
        emitted[logical] = compiled
      rescue ex : ArgumentError
        raise Error.new("Text asset '#{logical}' is not valid UTF-8: #{ex.message}")
      end

      private def rewrite_css(
        contents : String,
        source_logical : String,
        sources : Hash(String, SourceAsset),
        emitted : Hash(String, Bytes),
        states : Hash(String, Symbol),
      ) : String
        bytes = contents.to_slice
        replacements = [] of Tuple(Int32, Int32, String)
        index = 0

        while index < bytes.size
          byte = bytes[index]
          if byte == '/'.ord && bytes[index + 1]? == '*'.ord
            index = skip_block_comment(bytes, index)
          elsif quote_byte?(byte)
            index = skip_quoted(bytes, index)
          elsif css_word_at?(bytes, index, "url")
            if range = css_url_reference_range(bytes, index)
              start_index, end_index, after_index = range
              reference = contents.byte_slice(start_index, end_index - start_index)
              target = rewrite_reference(reference, source_logical, sources, emitted, states)
              replacements << {start_index, end_index, target} unless target == reference
              index = after_index
            else
              index += 1
            end
          elsif css_word_at?(bytes, index, "@import")
            if range = css_import_reference_range(bytes, index)
              start_index, end_index, after_index = range
              reference = contents.byte_slice(start_index, end_index - start_index)
              target = rewrite_reference(reference, source_logical, sources, emitted, states)
              replacements << {start_index, end_index, target} unless target == reference
              index = after_index
            else
              index += 1
            end
          else
            index += 1
          end
        end

        apply_replacements(contents, replacements)
      end

      private def rewrite_javascript_import_reference(
        reference : String,
        source_logical : String,
        sources : Hash(String, SourceAsset),
        emitted : Hash(String, Bytes),
        states : Hash(String, Symbol),
      ) : String
        return reference unless reference.starts_with?("./") || reference.starts_with?("../")
        rewrite_reference(reference, source_logical, sources, emitted, states)
      end

      private def rewrite_javascript(
        contents : String,
        source_logical : String,
        sources : Hash(String, SourceAsset),
        emitted : Hash(String, Bytes),
        states : Hash(String, Symbol),
      ) : String
        bytes = contents.to_slice
        replacements = [] of Tuple(Int32, Int32, String)
        index = 0

        while index < bytes.size
          byte = bytes[index]
          if byte == '/'.ord && bytes[index + 1]? == '/'.ord
            line_end = index + 2
            while line_end < bytes.size && bytes[line_end] != '\n'.ord
              line_end += 1
            end
            comment = contents.byte_slice(index, line_end - index)
            if match = comment.match(/\A\/\/[#@]\s*sourceMappingURL=([^\s]+)/)
              start_index = index + match.byte_begin(1)
              end_index = index + match.byte_end(1)
              reference = match[1]
              target = rewrite_reference(reference, source_logical, sources, emitted, states)
              replacements << {start_index, end_index, target} unless target == reference
            end
            index = line_end
          elsif byte == '/'.ord && bytes[index + 1]? == '*'.ord
            index = skip_block_comment(bytes, index)
          elsif quote_byte?(byte) || byte == '`'.ord
            index = skip_quoted(bytes, index)
          elsif js_keyword_at?(bytes, index, "import")
            if range = javascript_module_reference_range(bytes, index, "import")
              start_index, end_index, after_index = range
              reference = contents.byte_slice(start_index, end_index - start_index)
              target = rewrite_javascript_import_reference(reference, source_logical, sources, emitted, states)
              replacements << {start_index, end_index, target} unless target == reference
              index = after_index
            else
              index += "import".bytesize
            end
          elsif js_keyword_at?(bytes, index, "export")
            if range = javascript_module_reference_range(bytes, index, "export")
              start_index, end_index, after_index = range
              reference = contents.byte_slice(start_index, end_index - start_index)
              target = rewrite_javascript_import_reference(reference, source_logical, sources, emitted, states)
              replacements << {start_index, end_index, target} unless target == reference
              index = after_index
            else
              index += "export".bytesize
            end
          else
            index += 1
          end
        end

        apply_replacements(contents, replacements)
      end

      private def css_url_reference_range(bytes : Bytes, word_start : Int32) : Tuple(Int32, Int32, Int32)?
        index = skip_ascii_space(bytes, word_start + 3)
        return unless bytes[index]? == '('.ord
        index = skip_ascii_space(bytes, index + 1)

        if quote = bytes[index]?
          if quote_byte?(quote)
            end_index = quoted_content_end(bytes, index)
            return unless end_index
            after_index = skip_ascii_space(bytes, end_index + 1)
            return unless bytes[after_index]? == ')'.ord
            return {index + 1, end_index, after_index + 1}
          end
        end

        start_index = index
        while index < bytes.size && bytes[index] != ')'.ord
          index += bytes[index] == '\\'.ord && index + 1 < bytes.size ? 2 : 1
        end
        return if index >= bytes.size

        end_index = index
        while start_index < end_index && ascii_space?(bytes[start_index])
          start_index += 1
        end
        while end_index > start_index && ascii_space?(bytes[end_index - 1])
          end_index -= 1
        end
        {start_index, end_index, index + 1}
      end

      private def css_import_reference_range(bytes : Bytes, word_start : Int32) : Tuple(Int32, Int32, Int32)?
        index = skip_ascii_space(bytes, word_start + "@import".bytesize)
        quote = bytes[index]?
        return unless quote && quote_byte?(quote)
        end_index = quoted_content_end(bytes, index)
        return unless end_index
        {index + 1, end_index, end_index + 1}
      end

      private def javascript_module_reference_range(
        bytes : Bytes,
        keyword_start : Int32,
        keyword : String,
      ) : Tuple(Int32, Int32, Int32)?
        index = skip_ascii_space(bytes, keyword_start + keyword.bytesize)

        if keyword == "import" && bytes[index]? == '('.ord
          index = skip_ascii_space(bytes, index + 1)
          return quoted_reference_range(bytes, index)
        end

        if keyword == "import" && (quote = bytes[index]?) && quote_byte?(quote)
          return quoted_reference_range(bytes, index)
        end

        while index < bytes.size
          byte = bytes[index]
          if byte == ';'.ord
            return
          elsif byte == '/'.ord && bytes[index + 1]? == '/'.ord
            index += 2
            while index < bytes.size && bytes[index] != '\n'.ord
              index += 1
            end
          elsif byte == '/'.ord && bytes[index + 1]? == '*'.ord
            index = skip_block_comment(bytes, index)
          elsif quote_byte?(byte) || byte == '`'.ord
            index = skip_quoted(bytes, index)
          elsif js_keyword_at?(bytes, index, "from")
            reference_start = skip_ascii_space(bytes, index + "from".bytesize)
            return quoted_reference_range(bytes, reference_start)
          else
            index += 1
          end
        end
        nil
      end

      private def quoted_reference_range(bytes : Bytes, quote_index : Int32) : Tuple(Int32, Int32, Int32)?
        quote = bytes[quote_index]?
        return unless quote && quote_byte?(quote)
        end_index = quoted_content_end(bytes, quote_index)
        return unless end_index
        {quote_index + 1, end_index, end_index + 1}
      end

      private def quoted_content_end(bytes : Bytes, quote_index : Int32) : Int32?
        quote = bytes[quote_index]
        index = quote_index + 1
        while index < bytes.size
          if bytes[index] == '\\'.ord
            index += 2
          elsif bytes[index] == quote
            return index
          else
            index += 1
          end
        end
        nil
      end

      private def skip_quoted(bytes : Bytes, quote_index : Int32) : Int32
        end_index = quoted_content_end(bytes, quote_index)
        end_index ? end_index + 1 : bytes.size
      end

      private def skip_block_comment(bytes : Bytes, comment_start : Int32) : Int32
        index = comment_start + 2
        while index + 1 < bytes.size
          return index + 2 if bytes[index] == '*'.ord && bytes[index + 1] == '/'.ord
          index += 1
        end
        bytes.size
      end

      private def skip_ascii_space(bytes : Bytes, start_index : Int32) : Int32
        index = start_index
        while index < bytes.size && ascii_space?(bytes[index])
          index += 1
        end
        index
      end

      private def ascii_space?(byte : UInt8) : Bool
        byte == ' '.ord || byte == '\t'.ord || byte == '\n'.ord || byte == '\r'.ord || byte == '\f'.ord
      end

      private def quote_byte?(byte : UInt8) : Bool
        byte == '\''.ord || byte == '"'.ord
      end

      private def identifier_byte?(byte : UInt8) : Bool
        (byte >= 'a'.ord && byte <= 'z'.ord) ||
          (byte >= 'A'.ord && byte <= 'Z'.ord) ||
          (byte >= '0'.ord && byte <= '9'.ord) ||
          byte == '_'.ord || byte == '-'.ord || byte == '$'.ord
      end

      private def css_word_at?(bytes : Bytes, index : Int32, word : String) : Bool
        return false if index > 0 && identifier_byte?(bytes[index - 1])
        return false if index + word.bytesize > bytes.size
        word.to_slice.each_with_index do |expected, offset|
          actual = bytes[index + offset]
          return false unless ascii_downcase(actual) == ascii_downcase(expected)
        end
        after = bytes[index + word.bytesize]?
        !after || !identifier_byte?(after)
      end

      private def js_keyword_at?(bytes : Bytes, index : Int32, keyword : String) : Bool
        return false if index > 0 && (identifier_byte?(bytes[index - 1]) || bytes[index - 1] == '.'.ord)
        return false if index + keyword.bytesize > bytes.size
        keyword.to_slice.each_with_index do |expected, offset|
          return false unless bytes[index + offset] == expected
        end
        after = bytes[index + keyword.bytesize]?
        !after || !identifier_byte?(after)
      end

      private def ascii_downcase(byte : UInt8) : UInt8
        byte >= 'A'.ord && byte <= 'Z'.ord ? byte + 32 : byte
      end

      private def apply_replacements(
        contents : String,
        replacements : Array(Tuple(Int32, Int32, String)),
      ) : String
        return contents if replacements.empty?
        String.build do |io|
          cursor = 0
          replacements.sort_by(&.[0]).each do |start_index, end_index, replacement|
            io << contents.byte_slice(cursor, start_index - cursor)
            io << replacement
            cursor = end_index
          end
          io << contents.byte_slice(cursor, contents.bytesize - cursor)
        end
      end

      private def rewrite_reference(
        raw_reference : String,
        source_logical : String,
        sources : Hash(String, SourceAsset),
        emitted : Hash(String, Bytes),
        states : Hash(String, Symbol),
      ) : String
        return raw_reference if external_reference?(raw_reference)

        path_part, suffix = split_reference(raw_reference)
        return raw_reference if path_part.empty?

        target_logical = resolve_reference(source_logical, path_part)
        unless sources.has_key?(target_logical)
          raise InvalidReferenceError.new(source_logical, raw_reference, "target '#{target_logical}' does not exist")
        end

        dependency_bytes = compile_asset(target_logical, sources, emitted, states)
        digest = Digest::SHA256.hexdigest(dependency_bytes)
        public_url(fingerprinted_path(target_logical, digest)) + suffix
      end

      private def resolve_reference(source_logical : String, reference_path : String) : String
        decoded = URI.decode(reference_path)
        candidate = Path[source_logical].parent.join(decoded).normalize
        candidate_string = candidate.to_s.gsub('\\', '/')
        if candidate.absolute? || candidate_string == ".." || candidate_string.starts_with?("../")
          raise InvalidReferenceError.new(source_logical, reference_path, "reference escapes source root")
        end
        LogicalPath.normalize(candidate_string)
      rescue ex : URI::Error
        raise InvalidReferenceError.new(source_logical, reference_path, "invalid URL encoding")
      end

      private def external_reference?(reference : String) : Bool
        value = reference.strip
        value.empty? ||
          value.starts_with?('#') ||
          value.starts_with?('/') ||
          value.starts_with?("//") ||
          value.starts_with?(/(?i:data|https?|blob|mailto|tel):/)
      end

      private def split_reference(reference : String) : {String, String}
        if index = reference.index(/[?#]/)
          {reference[0, index], reference[index..]}
        else
          {reference, ""}
        end
      end

      private def write_build(emitted : Hash(String, Bytes), manifest : Manifest) : Nil
        Dir.mkdir_p(@output_root)

        emitted.keys.sort.each do |logical|
          entry = manifest.assets[logical]
          output_file = output_path_for_public_url(entry.path)
          atomic_write(output_file, emitted[logical])
          write_gzip(output_file, emitted[logical]) if MimeTypes.compressible?(entry.content_type)
        end

        atomic_write(@output_root.join(@manifest_name), manifest.to_deterministic_json.to_slice)
      end

      private def load_previous_manifest : Manifest?
        path = @output_root.join(@manifest_name)
        return nil unless File.file?(path)
        Manifest.load(path)
      end

      private def prune_previous_build(previous : Manifest?, current : Manifest) : Nil
        return unless previous
        # A changed public mount cannot be mapped back to this output root safely.
        # Leave those old files alone rather than guessing what the application owns.
        return unless previous.public_path == @public_path
        current_paths = current.assets.values.map(&.path).to_set

        previous.assets.each do |logical, entry|
          next if current_paths.includes?(entry.path)
          next unless compiler_owned_entry?(logical, entry)
          remove_owned_file(entry.path)
        end
        remove_empty_directories(@output_root)
      end

      private def compiler_owned_entry?(logical : String, entry : ManifestEntry) : Bool
        return false unless entry.digest.matches?(/\A[a-f0-9]{64}\z/)
        normalized = LogicalPath.normalize(logical)
        entry.path == public_url(fingerprinted_path(normalized, entry.digest))
      rescue ConfigurationError
        false
      end

      private def remove_owned_file(public_url : String) : Nil
        path = output_path_for_public_url(public_url)
        File.delete(path) if File.file?(path)
        gzip_path = Path["#{path}.gz"]
        File.delete(gzip_path) if File.file?(gzip_path)
      end

      private def output_path_for_public_url(public_url : String) : Path
        prefix = @public_path == "/" ? "/" : "#{@public_path}/"
        unless public_url.starts_with?(prefix)
          raise ConfigurationError.new("Manifest path is outside configured public path: #{public_url}")
        end
        logical = URI.decode(public_url[prefix.size..])
        @output_root.join(LogicalPath.normalize(logical)).normalize
      rescue ex : URI::Error
        raise ConfigurationError.new("Manifest path has invalid URL encoding: #{public_url}")
      end

      private def atomic_write(path : Path, bytes : Bytes) : Nil
        Dir.mkdir_p(path.parent)
        temporary = path.parent.join(".#{path.basename}.tmp-#{Process.pid}-#{Random::Secure.hex(8)}")
        begin
          File.open(temporary, "wb") do |file|
            file.write(bytes)
            file.flush
          end
          File.rename(temporary, path)
        ensure
          File.delete(temporary) if File.exists?(temporary)
        end
      end

      private def write_gzip(path : Path, bytes : Bytes) : Nil
        temporary = path.parent.join(".#{path.basename}.gz.tmp-#{Process.pid}-#{Random::Secure.hex(8)}")
        begin
          File.open(temporary, "wb") do |file|
            writer = Compress::Gzip::Writer.new(file)
            writer.header.modification_time = Time.unix(0)
            writer.write(bytes)
            writer.close
          end
          File.rename(temporary, "#{path}.gz")
        ensure
          File.delete(temporary) if File.exists?(temporary)
        end
      end

      private def fingerprinted_path(logical : String, digest : String) : String
        extension = File.extname(logical)
        stem = extension.empty? ? logical : logical[0, logical.bytesize - extension.bytesize]
        "#{stem}-#{digest[0, FINGERPRINT_LENGTH]}#{extension}"
      end

      private def public_url(logical : String) : String
        encoded = logical.split('/').map { |part| URI.encode_path_segment(part) }.join('/')
        @public_path == "/" ? "/#{encoded}" : "#{@public_path}/#{encoded}"
      end

      private def normalize_public_path(path : String) : String
        value = path.strip
        unless value.starts_with?('/') && !value.starts_with?("//") && !value.includes?('?') && !value.includes?('#')
          raise ConfigurationError.new("Static asset public path must be a root-relative URL path")
        end
        value = value.gsub(/\/{2,}/, "/")
        value = value.rstrip('/') unless value == "/"
        value
      end

      private def nearest_existing_parent(path : Path) : Path
        current = path
        until File.exists?(current)
          parent = current.parent
          raise ConfigurationError.new("Could not resolve output root: #{path}") if parent == current
          current = parent
        end
        current
      end

      private def within?(path : Path, root : Path) : Bool
        relative = path.relative_to?(root)
        return false unless relative
        relative_string = relative.to_s.gsub('\\', '/')
        relative_string != ".." && !relative_string.starts_with?("../")
      end

      private def remove_empty_directories(root : Path) : Nil
        return unless Dir.exists?(root)
        directories = Dir.glob(glob_pattern(root.join("**", "*"))).select { |path| File.directory?(path) }
        directories.sort_by(&.size).reverse_each do |directory|
          Dir.delete(directory) if Dir.empty?(directory)
        end
      end

      # Crystal's `Path#to_s` uses backslashes on Windows, while `Dir.glob`
      # expects forward-slash separators in its pattern on every platform.
      # Normalizing only the glob expression keeps filesystem paths native and
      # lets generated applications discover their authored assets on Windows.
      private def glob_pattern(path : Path) : String
        path.to_s.gsub('\\', '/')
      end
    end

    private module MimeTypes
      extend self

      TYPES = {
        ".css"         => "text/css; charset=utf-8",
        ".js"          => "text/javascript; charset=utf-8",
        ".mjs"         => "text/javascript; charset=utf-8",
        ".cjs"         => "text/javascript; charset=utf-8",
        ".map"         => "application/json; charset=utf-8",
        ".json"        => "application/json; charset=utf-8",
        ".webmanifest" => "application/manifest+json; charset=utf-8",
        ".xml"         => "application/xml; charset=utf-8",
        ".txt"         => "text/plain; charset=utf-8",
        ".html"        => "text/html; charset=utf-8",
        ".htm"         => "text/html; charset=utf-8",
        ".csv"         => "text/csv; charset=utf-8",
        ".svg"         => "image/svg+xml",
        ".png"         => "image/png",
        ".jpg"         => "image/jpeg",
        ".jpeg"        => "image/jpeg",
        ".gif"         => "image/gif",
        ".webp"        => "image/webp",
        ".avif"        => "image/avif",
        ".ico"         => "image/x-icon",
        ".woff"        => "font/woff",
        ".woff2"       => "font/woff2",
        ".ttf"         => "font/ttf",
        ".otf"         => "font/otf",
        ".eot"         => "application/vnd.ms-fontobject",
        ".pdf"         => "application/pdf",
        ".zip"         => "application/zip",
        ".wasm"        => "application/wasm",
        ".mp3"         => "audio/mpeg",
        ".ogg"         => "audio/ogg",
        ".wav"         => "audio/wav",
        ".mp4"         => "video/mp4",
        ".webm"        => "video/webm",
      }

      def for(path : String) : String
        TYPES[File.extname(path).downcase]? || "application/octet-stream"
      end

      def compressible?(content_type : String) : Bool
        media_type = content_type.split(';', 2).first
        media_type.starts_with?("text/") ||
          media_type == "application/json" ||
          media_type.ends_with?("+json") ||
          media_type == "application/xml" ||
          media_type == "image/svg+xml" ||
          media_type == "application/wasm"
      end
    end
  end
end
