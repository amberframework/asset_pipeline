require "http"
require "./page_cache"
require "./configuration"

module Components
  module Cache
    # An `HTTP::Handler`, so it plugs into an Amber pipeline, that answers GET pages from a `PageCache`.
    #
    # The block names the page a request reads, or returns nil to leave the request alone. Name
    # only pages that are the same for every visitor: anything built from a session, a flash
    # message or a CSRF token must return nil. Keep it out of pipelines with
    # `HTTP::CompressHandler`; a response that arrives already encoded is passed through unstored.
    #
    # ```
    # plug Components::Cache::PageCacheHandler.new { |context|
    #   context.request.path.starts_with?("/docs/") ? context.request.path : nil
    # }
    # ```
    class PageCacheHandler
      include HTTP::Handler

      # A response longer than this is passed through unstored.
      MAXIMUM_CAPTURED_BYTES = 8_388_608

      # Passes writes through and keeps a copy until the limit is passed.
      private class CapturingOutput < IO
        getter? overflowed : Bool = false

        def initialize(@downstream : IO)
          @captured = IO::Memory.new
        end

        def captured_html : String
          @captured.to_s
        end

        def read(slice : Bytes) : Int32
          raise IO::Error.new("CapturingOutput is write-only")
        end

        def write(slice : Bytes) : Nil
          if @captured.size + slice.size > MAXIMUM_CAPTURED_BYTES
            @overflowed = true
            @captured = IO::Memory.new
          elsif !overflowed?
            @captured.write(slice)
          end
          @downstream.write(slice)
        end

        def flush : Nil
          @downstream.flush
        end
      end

      def initialize(@page_cache : PageCache = Cache.page_cache, &@page_key_for : HTTP::Server::Context -> String?)
      end

      def call(context : HTTP::Server::Context) : Nil
        page_key = @page_key_for.call(context)
        return call_next(context) unless page_key && context.request.method == "GET"
        # An upstream handler is already compressing; our bytes would be compressed twice.
        return call_next(context) if context.response.headers.has_key?("Content-Encoding")

        if page = @page_cache.read_stored_page(page_key)
          @page_cache.answer_from(context, page)
          return
        end

        generation = @page_cache.store.current_generation
        context.response.headers["Cache-Control"] = PageAnswer::CACHE_CONTROL
        context.response.headers["Vary"] = "Accept-Encoding" if @page_cache.settings.compresses?
        original_output = context.response.output
        capturing_output = CapturingOutput.new(original_output)
        context.response.output = capturing_output
        begin
          call_next(context)
        ensure
          context.response.output = original_output
        end
        store_response(context, page_key, capturing_output, generation)
      end

      private def store_response(context : HTTP::Server::Context, page_key : String, capturing_output : CapturingOutput, generation : Int64) : Nil
        response = context.response
        return unless response.status_code == 200
        return if response.headers.has_key?("Content-Encoding") || response.headers.has_key?("Set-Cookie")
        return if capturing_output.overflowed?
        content_type = response.headers["Content-Type"]? || "text/html"
        return unless content_type.starts_with?("text/html")
        html = response_html(context, capturing_output)
        return if html.empty?
        @page_cache.store_page_unless_cleared(page_key, html, content_type, generation)
      end

      # Amber writes the controller's return value after the pipeline returns, from `context.content`.
      private def response_html(context : HTTP::Server::Context, capturing_output : CapturingOutput) : String
        if context.responds_to?(:content)
          content = context.content
          return content if content.is_a?(String) && !content.empty?
        end
        capturing_output.captured_html
      end
    end
  end
end
