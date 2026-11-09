require "http"
require "log"
require "./cacheable"
require "./stored_page"
require "./page_answer"

module Components
  module Cache
    # Answers whole pages from memory.
    #
    # The first request stores plain HTML. The second compresses and hashes the page, once, and
    # every later hit writes those stored bytes, so a hit spends no CPU. Each representation has
    # its own strong ETag, and `If-None-Match` is answered with an empty 304.
    #
    # A write clears what it changed. The next build of a cleared page stores its row and section
    # fragments too, so the rebuild after a write gets cheaper without a page no write has touched
    # paying for fragments it will never reuse.
    #
    # ```
    # # In a controller action; a write calls `clear_pages`.
    # Components::Cache.page_cache.answer(context, "pet:#{id}") do |build|
    #   details = build.fragment("section:pet_details:#{id}") { PetDetails.new(id, pet).to_s }
    #   PetPage.new(id, details).to_s
    # end
    # ```
    class PageCache
      Log = ::Log.for("asset_pipeline.page_cache")

      KEY_PREFIX = "page:"

      # How many cleared pages are remembered until their next build; each mark is one key.
      CLEARED_MARK_LIMIT = 8192

      # What the page cache derives and stores. Set through `Components::Cache.configure`.
      class Settings
        BROTLI_IS_COMPILED_IN = {{ flag?(:asset_pipeline_brotli) }}

        # Stores a gzip copy beside the HTML, so a hit spends no CPU compressing.
        property? stores_gzip : Bool = true

        # Sends a strong ETag per representation and answers `If-None-Match`.
        property? sends_etag : Bool = true

        # Stores row and section fragments for a page a write has cleared.
        property? stores_fragments_after_write : Bool = true

        # Rebuilds a page right after a write clears it. This measured slower than letting the next
        # request rebuild it, so it stays off unless an application asks for it.
        property? rebuilds_after_write : Bool = false

        getter? stores_brotli : Bool = BROTLI_IS_COMPILED_IN

        # Brotli needs libbrotlienc linked, so turning it on needs `-Dasset_pipeline_brotli`.
        def stores_brotli=(value : Bool) : Bool
          if value && !BROTLI_IS_COMPILED_IN
            raise Error.new("Brotli needs the -Dasset_pipeline_brotli compile-time flag")
          end
          @stores_brotli = value
        end

        def compresses? : Bool
          stores_gzip? || stores_brotli?
        end

        def derives_page_bytes? : Bool
          compresses? || sends_etag?
        end
      end

      # Handed to the block that builds a page.
      struct PageBuild
        def initialize(@store : CacheStore, @stores_fragments : Bool)
        end

        # True for the first build after a write cleared this page.
        def stores_fragments? : Bool
          @stores_fragments
        end

        # The stored fragment under *fragment_key*, or the block's result, which is stored only
        # when this build stores fragments. Other builds render straight through.
        def fragment(fragment_key : String, expires_in : Time::Span? = nil, & : -> String) : String
          return yield unless @stores_fragments
          @store.fetch(fragment_key, expires_in) { yield }
        end
      end

      getter store : CacheStore
      getter settings : Settings

      def initialize(@store : CacheStore, @settings : Settings = Settings.new)
        @lock = Mutex.new(:unchecked)
        @cleared_page_keys = {} of String => Bool
        @hit_count = Atomic(Int64).new(0_i64)
        @miss_count = Atomic(Int64).new(0_i64)
        @upgrade_count = Atomic(Int64).new(0_i64)
        @fragment_build_count = Atomic(Int64).new(0_i64)
        @rebuild_count = Atomic(Int64).new(0_i64)
      end

      def hit_count : Int64
        @hit_count.get
      end

      def miss_count : Int64
        @miss_count.get
      end

      # Pages that have had their compressed bytes and ETags computed.
      def upgrade_count : Int64
        @upgrade_count.get
      end

      # Builds that stored fragments because a write had cleared the page.
      def fragment_build_count : Int64
        @fragment_build_count.get
      end

      def rebuild_count : Int64
        @rebuild_count.get
      end

      # Writes *page_key*'s page to the response, from memory or from the block.
      #
      # The block returns the page's HTML and may store fragments through its `PageBuild`. In an
      # Amber controller the action ends here; its return value is empty, so nothing else is sent.
      def answer(context : HTTP::Server::Context, page_key : String, expires_in : Time::Span? = nil, content_type : String = "text/html", & : PageBuild -> String) : Nil
        if page = read_stored_page(page_key)
          answer_from(context, page)
          return
        end

        html = build_and_store(page_key, content_type, expires_in) { |build| yield build }
        answer_from(context, StoredPage.plain(html, content_type))
      end

      # The stored page for *page_key*, counted as a hit or miss, with its compressed bytes and ETags
      # added the first time it is read again.
      def read_stored_page(page_key : String) : StoredPage?
        store_key = store_key_of(page_key)
        # Read before the page, so a clear that lands while it compresses refuses the upgrade.
        generation = @store.current_generation
        encoded = @store.read_bytes(store_key)
        page = encoded ? StoredPage.from_bytes(encoded) : nil
        unless page
          @miss_count.add(1_i64)
          return nil
        end

        @hit_count.add(1_i64)
        return page if page.holds_derived_bytes? || !@settings.derives_page_bytes?
        upgraded_page = page.with_derived_bytes(@settings)
        @upgrade_count.add(1_i64) if @store.replace_bytes_unless_cleared(store_key, upgraded_page.to_bytes, generation)
        upgraded_page
      end

      # Writes *page* for this request, including its 304 and its compression choice.
      def answer_from(context : HTTP::Server::Context, page : StoredPage) : Nil
        request_headers = context.request.headers
        PageAnswer.new(page, request_headers["Accept-Encoding"]?, request_headers["If-None-Match"]?, @settings.compresses?).write_to(context)
      end

      # Builds a page and stores it unless a write cleared it while it was rendering.
      def build_and_store(page_key : String, content_type : String = "text/html", expires_in : Time::Span? = nil, & : PageBuild -> String) : String
        store_key = store_key_of(page_key)
        generation = @store.current_generation
        stores_fragments = take_cleared_mark(store_key)
        html = yield PageBuild.new(@store, stores_fragments)
        store_page(store_key, html, content_type, generation, expires_in)
        html
      end

      # :nodoc:
      def store_page_unless_cleared(page_key : String, html : String, content_type : String, generation : Int64, expires_in : Time::Span? = nil) : Nil
        store_page(store_key_of(page_key), html, content_type, generation, expires_in)
      end

      def clear_page(page_key : String) : Nil
        clear_pages([page_key])
      end

      # Clears finished pages. Each one that was present is rebuilt with fragments next time.
      def clear_pages(list_of_page_keys : Array(String)) : Nil
        mark_cleared(@store.delete_all(list_of_page_keys.map { |page_key| store_key_of(page_key) }))
      end

      # Clears row and section fragments a write made wrong.
      def clear_fragments(list_of_fragment_keys : Array(String)) : Nil
        @store.delete_all(list_of_fragment_keys)
      end

      # Clears the pages under *page_key_prefix* numbered *first_number* and up.
      def clear_pages_numbered_from(page_key_prefix : String, first_number : Int32) : Nil
        mark_cleared(@store.delete_numbered_from(store_key_of(page_key_prefix), first_number))
      end

      # Rebuilds a page after a write when `Settings#rebuilds_after_write?` is on, and otherwise
      # does nothing. A failure is logged: the write has already committed.
      def rebuild_after_write(page_key : String, content_type : String = "text/html", expires_in : Time::Span? = nil, & : PageBuild -> String) : Nil
        return unless @settings.rebuilds_after_write?
        build_and_store(page_key, content_type, expires_in) { |build| yield build }
        @rebuild_count.add(1_i64)
      rescue ex : Exception
        Log.warn(exception: ex) { "could not rebuild #{page_key} after a write" }
      end

      private def store_key_of(page_key : String) : String
        "#{KEY_PREFIX}#{page_key}"
      end

      private def store_page(store_key : String, html : String, content_type : String, generation : Int64, expires_in : Time::Span?) : Nil
        @store.write_bytes_unless_cleared(store_key, StoredPage.plain(html, content_type).to_bytes, generation, expires_in)
      end

      # Only a page a write actually removed earns a fragment build.
      private def mark_cleared(list_of_store_keys : Array(String)) : Nil
        return unless @settings.stores_fragments_after_write?
        @lock.synchronize do
          list_of_store_keys.each do |store_key|
            @cleared_page_keys[store_key] = true
            if @cleared_page_keys.size > CLEARED_MARK_LIMIT
              @cleared_page_keys.delete(@cleared_page_keys.first_key)
            end
          end
        end
      end

      private def take_cleared_mark(store_key : String) : Bool
        return false unless @settings.stores_fragments_after_write?
        was_cleared = @lock.synchronize { !@cleared_page_keys.delete(store_key).nil? }
        @fragment_build_count.add(1_i64) if was_cleared
        was_cleared
      end
    end
  end
end
