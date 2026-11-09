# Links libbrotlienc, so it is built only with `-Dasset_pipeline_brotli`.
{% if flag?(:asset_pipeline_brotli) %}
  @[Link("brotlienc")]
  lib LibBrotliEncoder
    fun encoder_max_compressed_size = BrotliEncoderMaxCompressedSize(input_size : LibC::SizeT) : LibC::SizeT
    fun encoder_compress = BrotliEncoderCompress(quality : LibC::Int, lgwin : LibC::Int, mode : LibC::Int, input_size : LibC::SizeT, input_buffer : UInt8*, encoded_size : LibC::SizeT*, encoded_buffer : UInt8*) : LibC::Int
  end

  module Components
    module Cache
      # The one-shot encoder from the system's libbrotlienc.
      module BrotliEncoder
        # Quality 5 is the store-time setting: a page is compressed once, on its second request.
        STORE_TIME_QUALITY =  5
        WINDOW_BITS        = 22
        TEXT_MODE          =  1

        def self.compress(input : Bytes, quality : Int32 = STORE_TIME_QUALITY) : Bytes
          encoded_size = LibBrotliEncoder.encoder_max_compressed_size(input.size)
          encoded = Bytes.new(encoded_size)
          succeeded = LibBrotliEncoder.encoder_compress(quality, WINDOW_BITS, TEXT_MODE, input.size, input.to_unsafe, pointerof(encoded_size), encoded.to_unsafe)
          raise Error.new("BrotliEncoderCompress failed on #{input.size} bytes") if succeeded == 0
          encoded[0, encoded_size]
        end
      end
    end
  end
{% end %}
