require "compress/gzip"
require "digest/sha256"
require "./cache_store"
require "./brotli_encoder"

module Components
  module Cache
    # A finished page as one byte payload, so a page and its compressed forms arrive and leave the
    # store together, and a hit writes out slices of the stored memory without copying them.
    #
    # A page starts as plain HTML. Its compressed bytes and ETags arrive together, on its second
    # request, because most pages are never read twice before a write clears them.
    struct StoredPage
      FORMAT_MARKER = 0xA7_u8
      FIELD_COUNT   =       7
      HEADER_BYTES  = 2 + FIELD_COUNT * 4

      getter content_type : String
      getter html : Bytes
      getter gzip : Bytes?
      getter brotli : Bytes?
      getter identity_etag : Bytes?
      getter gzip_etag : Bytes?
      getter brotli_etag : Bytes?
      getter? holds_derived_bytes : Bool

      def initialize(@content_type : String, @html : Bytes, @gzip : Bytes? = nil, @brotli : Bytes? = nil,
                     @identity_etag : Bytes? = nil, @gzip_etag : Bytes? = nil, @brotli_etag : Bytes? = nil,
                     @holds_derived_bytes : Bool = false)
      end

      def self.plain(html : String, content_type : String) : StoredPage
        new(content_type, html.to_slice)
      end

      # A page whose compressed forms and ETags have been computed, according to *settings*.
      def with_derived_bytes(settings : PageCache::Settings) : StoredPage
        gzip_bytes = settings.stores_gzip? ? StoredPage.gzip(html) : nil
        brotli_bytes = settings.stores_brotli? ? StoredPage.brotli(html) : nil
        sends_etag = settings.sends_etag?
        StoredPage.new(content_type, html, gzip_bytes, brotli_bytes,
          identity_etag: sends_etag ? StoredPage.strong_etag(html) : nil,
          gzip_etag: (sends_etag && gzip_bytes) ? StoredPage.strong_etag(gzip_bytes) : nil,
          brotli_etag: (sends_etag && brotli_bytes) ? StoredPage.strong_etag(brotli_bytes) : nil,
          holds_derived_bytes: true)
      end

      # A fixed modification time keeps the gzip bytes, and so the strong ETag, the same on every rebuild.
      def self.gzip(html : Bytes) : Bytes
        compressed = IO::Memory.new(html.size // 2 + 64)
        Compress::Gzip::Writer.open(compressed) do |gzip_writer|
          gzip_writer.header.modification_time = Time.unix(0)
          gzip_writer.write(html)
        end
        compressed.to_slice
      end

      def self.brotli(html : Bytes) : Bytes?
        {% if flag?(:asset_pipeline_brotli) %}
          BrotliEncoder.compress(html)
        {% else %}
          nil
        {% end %}
      end

      def self.strong_etag(representation : Bytes) : Bytes
        digest = Digest::SHA256.hexdigest { |context| context.update(representation) }
        %("#{digest[0, 32]}").to_slice
      end

      def to_bytes : Bytes
        list_of_fields = {content_type.to_slice, html, gzip, brotli, identity_etag, gzip_etag, brotli_etag}
        payload_size = list_of_fields.sum(0) { |field| field ? field.size : 0 }
        encoded = Bytes.new(HEADER_BYTES + payload_size)
        encoded[0] = FORMAT_MARKER
        encoded[1] = holds_derived_bytes? ? 1_u8 : 0_u8
        offset = HEADER_BYTES
        list_of_fields.each_with_index do |field, field_index|
          field_size = field ? field.size : 0
          IO::ByteFormat::LittleEndian.encode(field_size.to_u32, encoded[2 + field_index * 4, 4])
          if field
            field.copy_to(encoded + offset)
            offset += field_size
          end
        end
        encoded
      end

      # Reads a payload made by `#to_bytes`, or returns nil for anything else.
      def self.from_bytes(encoded : Bytes) : StoredPage?
        return nil if encoded.size < HEADER_BYTES || encoded[0] != FORMAT_MARKER
        offset = HEADER_BYTES
        total_size = offset + (0...FIELD_COUNT).sum { |field_index| field_size_at(encoded, field_index) }
        return nil if total_size != encoded.size

        fields = StaticArray(Bytes, FIELD_COUNT).new(Bytes.empty)
        FIELD_COUNT.times do |field_index|
          field_size = field_size_at(encoded, field_index)
          fields[field_index] = encoded[offset, field_size]
          offset += field_size
        end
        new(String.new(fields[0]), fields[1], optional(fields[2]), optional(fields[3]), optional(fields[4]), optional(fields[5]), optional(fields[6]), holds_derived_bytes: encoded[1] == 1_u8)
      end

      # An empty field means the page does not have that form.
      private def self.optional(field : Bytes) : Bytes?
        field.empty? ? nil : field
      end

      private def self.field_size_at(encoded : Bytes, field_index : Int32) : Int32
        IO::ByteFormat::LittleEndian.decode(UInt32, encoded[2 + field_index * 4, 4]).to_i32
      end
    end
  end
end
