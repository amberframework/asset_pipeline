{% if flag?(:without_zlib) %}
  require "./vendor/mica/deflate"
{% else %}
  require "compress/gzip"
{% end %}

module AssetPipeline
  # The gzip coding that precompresses static assets (`app.css.gz`) and the
  # page cache's stored pages.
  #
  # Crystal's `Compress::Gzip` calls libz. An app built with `-Dwithout_zlib`
  # uses the pinned copy of Mica under `src/asset_pipeline/vendor` instead
  # (DEFLATE written in Crystal, which needs Crystal 1.21 or newer), so that
  # the app links no libz. Either one writes a single gzip member at level 6
  # with no modification time, so the same bytes in give the same bytes out
  # on every build, and each expands what the other wrote.
  module GzipCoding
    # Raised by `decode` for bytes that are not one complete gzip stream.
    class InvalidStreamError < Exception
    end

    # The compression level: zlib's default.
    LEVEL = 6

    # Returns *bytes* as a gzip stream.
    #
    # ```
    # AssetPipeline::GzipCoding.encode("body { margin: 0 }".to_slice)
    # ```
    def self.encode(bytes : Bytes) : Bytes
      {% if flag?(:without_zlib) %}
        AssetPipeline::Mica::Gzip.encode(bytes, level: LEVEL)
      {% else %}
        compressed = IO::Memory.new(bytes.size // 2 + 64)
        Compress::Gzip::Writer.open(compressed, LEVEL) do |gzip_writer|
          gzip_writer.header.modification_time = Time.unix(0)
          gzip_writer.write(bytes)
        end
        compressed.to_slice
      {% end %}
    end

    # Returns the bytes the gzip stream *compressed* holds. The stream is one
    # this program or its build wrote, so it may expand to 1 GiB.
    #
    # Raises `InvalidStreamError` when *compressed* is cut short, damaged or
    # not gzip.
    def self.decode(compressed : Bytes) : Bytes
      {% if flag?(:without_zlib) %}
        begin
          limits = AssetPipeline::Mica::Deflate::DecodeLimits::TRUSTED_ASSET
          AssetPipeline::Mica::Gzip.decode(compressed, limits: limits, timeout: nil)
        rescue error : AssetPipeline::Mica::Error
          raise InvalidStreamError.new(error.message)
        end
      {% else %}
        begin
          Compress::Gzip::Reader.open(IO::Memory.new(compressed), &.getb_to_end)
        rescue error : Compress::Gzip::Error | Compress::Deflate::Error | IO::Error
          raise InvalidStreamError.new(error.message)
        end
      {% end %}
    end
  end
end
