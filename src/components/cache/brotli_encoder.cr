# Mica needs Crystal 1.21 or newer; older compilers store no Brotli copy.
{% if compare_versions(Crystal::VERSION, "1.21.0") >= 0 %}
  require "../../asset_pipeline/vendor/mica/brotli"

  module Components
    module Cache
      # The one-shot Brotli encoder that compresses stored pages: the pinned copy of Mica under
      # `src/asset_pipeline/vendor`, written in Crystal, so an app links no libbrotlienc.
      module BrotliEncoder
        # Quality 5 is the store-time setting: a page is compressed once, on its second request.
        STORE_TIME_QUALITY =  5
        WINDOW_BITS        = 22

        def self.compress(input : Bytes, quality : Int32 = STORE_TIME_QUALITY) : Bytes
          AssetPipeline::Mica::Brotli.encode(input, quality: quality, window_bits: WINDOW_BITS)
        end
      end
    end
  end
{% end %}
