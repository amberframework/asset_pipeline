require "../../spec_helper"
require "log/spec"
require "compress/gzip"
require "../../../../src/components/cache/page_cache"
require "../../../../src/components/cache/page_cache_handler"
require "../../../../src/components/cache/configuration"

# Amber reopens the context with this property; the handler reads it when present.
class HTTP::Server::Context
  property content : String?
end

private PAGE_HTML = "<html>#{"page body " * 40}</html>"

private def new_cache(settings = Components::Cache::PageCache::Settings.new) : Components::Cache::PageCache
  Components::Cache::PageCache.new(Components::Cache::MemoryCacheStore.new(1_048_576_i64), settings)
end

private def context_for(path : String = "/", headers : HTTP::Headers = HTTP::Headers.new, method : String = "GET") : {HTTP::Server::Context, IO::Memory}
  output = IO::Memory.new
  request = HTTP::Request.new(method, path, headers)
  {HTTP::Server::Context.new(request, HTTP::Server::Response.new(output)), output}
end

# Sends one request through the page cache and returns the parsed response.
private def answer(cache, page_key : String, accept_encoding : String? = nil, if_none_match : String? = nil, method : String = "GET", &block : Components::Cache::PageCache::PageBuild -> String) : HTTP::Client::Response
  headers = HTTP::Headers.new
  headers["Accept-Encoding"] = accept_encoding if accept_encoding
  headers["If-None-Match"] = if_none_match if if_none_match
  context, output = context_for(headers: headers, method: method)
  cache.answer(context, page_key) { |build| block.call(build) }
  context.response.close
  output.rewind
  HTTP::Client::Response.from_io(output, ignore_body: method == "HEAD", decompress: false)
end

private def answer(cache, page_key : String, accept_encoding : String? = nil, if_none_match : String? = nil, method : String = "GET") : HTTP::Client::Response
  answer(cache, page_key, accept_encoding, if_none_match, method) { |_build| PAGE_HTML }
end

private def gunzip(body : String) : String
  Compress::Gzip::Reader.open(IO::Memory.new(body)) { |gzip| gzip.gets_to_end }
end

# Serves the page twice, so the third request sees compressed bytes and ETags.
private def warmed_cache : Components::Cache::PageCache
  cache = new_cache
  2.times { answer(cache, "pet:1") }
  cache
end

private def etag_for(cache, accept_encoding : String? = nil) : String
  answer(cache, "pet:1", accept_encoding).headers["ETag"]
end

describe Components::Cache::PageCache do
  describe "the second-request compression policy" do
    it "sends the first request plain, with no ETag" do
      cache = new_cache
      response = answer(cache, "pet:1", "gzip")
      response.status_code.should eq(200)
      response.headers["Content-Encoding"]?.should be_nil
      response.headers["ETag"]?.should be_nil
      response.body.should eq(PAGE_HTML)
      cache.upgrade_count.should eq(0)
      cache.miss_count.should eq(1)
    end

    it "compresses and hashes on the second request, once" do
      cache = new_cache
      answer(cache, "pet:1", "gzip")
      second = answer(cache, "pet:1", "gzip") { |_build| raise "the page must not rebuild" }
      second.headers["Content-Encoding"].should eq("gzip")
      second.headers["ETag"]?.should_not be_nil
      gunzip(second.body).should eq(PAGE_HTML)
      cache.upgrade_count.should eq(1)
      answer(cache, "pet:1", "gzip")
      cache.upgrade_count.should eq(1)
      cache.hit_count.should eq(2)
    end

    it "charges the budget for the compressed bytes the upgrade adds" do
      store = Components::Cache::MemoryCacheStore.new(1_048_576_i64)
      cache = Components::Cache::PageCache.new(store)
      answer(cache, "pet:1")
      before_upgrade = store.stored_bytes
      answer(cache, "pet:1")
      store.stored_bytes.should be > before_upgrade
    end

    it "serves identity from the same page to a client without gzip" do
      cache = warmed_cache
      response = answer(cache, "pet:1")
      response.headers["Content-Encoding"]?.should be_nil
      response.body.should eq(PAGE_HTML)
    end
  end

  describe "response headers" do
    it "sends Vary and no-cache on every answer" do
      cache = new_cache
      first = answer(cache, "pet:1")
      first.headers["Vary"].should eq("Accept-Encoding")
      first.headers["Cache-Control"].should eq("no-cache")
      second = answer(cache, "pet:1", "gzip")
      second.headers["Vary"].should eq("Accept-Encoding")
      second.headers["Cache-Control"].should eq("no-cache")
    end

    it "sends a body-less HEAD with the page's length" do
      cache = warmed_cache
      response = answer(cache, "pet:1", method: "HEAD")
      response.status_code.should eq(200)
      response.headers["Content-Length"].should eq(PAGE_HTML.bytesize.to_s)
    end

    it "keeps gzip of the same input stable" do
      Components::Cache::StoredPage.gzip(PAGE_HTML.to_slice).should eq(Components::Cache::StoredPage.gzip(PAGE_HTML.to_slice))
    end
  end

  describe "ETag handling" do
    it "gives each representation its own strong ETag" do
      cache = warmed_cache
      identity = etag_for(cache)
      gzip = etag_for(cache, "gzip")
      identity.should_not eq(gzip)
      identity.should start_with('"')
      identity.should_not start_with("W/")
    end

    it "answers 304 with an empty body for a matching ETag" do
      cache = warmed_cache
      etag = etag_for(cache)
      response = answer(cache, "pet:1", if_none_match: etag)
      response.status_code.should eq(304)
      response.body.should eq("")
      response.headers["ETag"].should eq(etag)
      response.headers["Content-Encoding"]?.should be_nil
    end

    it "matches a value inside a list" do
      cache = warmed_cache
      answer(cache, "pet:1", if_none_match: %("other", #{etag_for(cache)}, "more")).status_code.should eq(304)
    end

    it "matches the weak form" do
      cache = warmed_cache
      answer(cache, "pet:1", if_none_match: "W/#{etag_for(cache)}").status_code.should eq(304)
    end

    it "matches the star form" do
      cache = warmed_cache
      answer(cache, "pet:1", if_none_match: "*").status_code.should eq(304)
    end

    it "does not match an unrelated value or another representation's ETag" do
      cache = warmed_cache
      answer(cache, "pet:1", if_none_match: %("other")).status_code.should eq(200)
      answer(cache, "pet:1", "gzip", if_none_match: etag_for(cache)).status_code.should eq(200)
    end

    it "never answers 304 to the star form for a page with no ETag" do
      cache = new_cache
      answer(cache, "pet:1", if_none_match: "*").status_code.should eq(200)
    end
  end

  describe "Accept-Encoding" do
    it "honors a q of zero and a list in any case" do
      cache = warmed_cache
      answer(cache, "pet:1", "gzip;q=0").headers["Content-Encoding"]?.should be_nil
      answer(cache, "pet:1", "deflate, GZip").headers["Content-Encoding"].should eq("gzip")
    end
  end

  describe "settings" do
    it "stores no gzip when gzip is off" do
      settings = Components::Cache::PageCache::Settings.new
      settings.stores_gzip = false
      cache = new_cache(settings)
      2.times { answer(cache, "pet:1", "gzip") }
      response = answer(cache, "pet:1", "gzip")
      response.headers["Content-Encoding"]?.should be_nil
      response.headers["ETag"]?.should_not be_nil
    end

    it "sends no ETag when ETags are off" do
      settings = Components::Cache::PageCache::Settings.new
      settings.sends_etag = false
      cache = new_cache(settings)
      2.times { answer(cache, "pet:1") }
      answer(cache, "pet:1").headers["ETag"]?.should be_nil
    end

    {% if flag?(:asset_pipeline_brotli) %}
      it "stores Brotli when compiled in and prefers it over gzip" do
        cache = warmed_cache
        response = answer(cache, "pet:1", "gzip, br")
        response.headers["Content-Encoding"].should eq("br")
        decoded = IO::Memory.new
        Process.run("brotli", {"-d", "-c"}, input: IO::Memory.new(response.body), output: decoded).success?.should be_true
        decoded.to_s.should eq(PAGE_HTML)
      end
    {% else %}
      it "refuses Brotli without the compile-time flag" do
        settings = Components::Cache::PageCache::Settings.new
        settings.stores_brotli?.should be_false
        expect_raises(Components::Cache::Error, /asset_pipeline_brotli/) { settings.stores_brotli = true }
      end
    {% end %}
  end

  describe "the stale-write guard" do
    it "does not store a page a newer write cleared while it was rendering" do
      cache = new_cache
      answer(cache, "pet:1") do |_build|
        cache.clear_page("pet:1")
        "stale render"
      end.body.should eq("stale render")
      answer(cache, "pet:1") { |_build| "fresh render" }.body.should eq("fresh render")
    end
  end

  describe "fragments for cleared pages" do
    it "stores no fragments for a page no write has cleared" do
      store = Components::Cache::MemoryCacheStore.new(1_048_576_i64)
      cache = Components::Cache::PageCache.new(store)
      answer(cache, "pet:1") do |build|
        build.stores_fragments?.should be_false
        build.fragment("row:1") { "row" }
      end
      store.exists?("row:1").should be_false
      cache.fragment_build_count.should eq(0)
    end

    it "stores fragments on the first build after a write clears the page" do
      store = Components::Cache::MemoryCacheStore.new(1_048_576_i64)
      cache = Components::Cache::PageCache.new(store)
      answer(cache, "pet:1")
      cache.clear_page("pet:1")
      answer(cache, "pet:1") { |build| build.fragment("row:1") { "row" } }.body.should eq("row")
      store.exists?("row:1").should be_true
      cache.fragment_build_count.should eq(1)
    end

    it "does not mark a page a write did not actually remove" do
      store = Components::Cache::MemoryCacheStore.new(1_048_576_i64)
      cache = Components::Cache::PageCache.new(store)
      cache.clear_page("never_stored")
      answer(cache, "never_stored") do |build|
        build.stores_fragments?.should be_false
        "page"
      end
    end

    it "stores no fragments when turned off" do
      settings = Components::Cache::PageCache::Settings.new
      settings.stores_fragments_after_write = false
      cache = new_cache(settings)
      answer(cache, "pet:1")
      cache.clear_page("pet:1")
      answer(cache, "pet:1") do |build|
        build.stores_fragments?.should be_false
        "page"
      end
    end

    it "marks numbered pages it clears" do
      cache = new_cache
      answer(cache, "pet_index:2")
      cache.clear_pages_numbered_from("pet_index:", 1)
      answer(cache, "pet_index:2") do |build|
        build.stores_fragments?.should be_true
        "page"
      end
    end

    it "clears fragments a write made wrong" do
      store = Components::Cache::MemoryCacheStore.new(1_048_576_i64)
      cache = Components::Cache::PageCache.new(store)
      store.write("row:1", "row")
      cache.clear_fragments(["row:1"])
      store.exists?("row:1").should be_false
    end
  end

  describe "#rebuild_after_write" do
    it "does nothing by default" do
      cache = new_cache
      cache.clear_page("pet:1")
      cache.rebuild_after_write("pet:1") { |_build| raise "must not build" }
      cache.rebuild_count.should eq(0)
    end

    it "rebuilds when turned on, so the next request is a hit" do
      settings = Components::Cache::PageCache::Settings.new
      settings.rebuilds_after_write = true
      cache = new_cache(settings)
      cache.rebuild_after_write("pet:1") { |_build| PAGE_HTML }
      cache.rebuild_count.should eq(1)
      answer(cache, "pet:1") { |_build| raise "must not rebuild" }.body.should eq(PAGE_HTML)
    end

    it "logs a failed rebuild, because the write has already committed" do
      settings = Components::Cache::PageCache::Settings.new
      settings.rebuilds_after_write = true
      cache = new_cache(settings)
      Log.capture("asset_pipeline.page_cache") do |logs|
        cache.rebuild_after_write("pet:1") { |_build| raise "database gone" }
        logs.check(:warn, /could not rebuild pet:1/)
      end
    end
  end

  describe "configuration" do
    it "shares the configured store and settings" do
      store = Components::Cache::MemoryCacheStore.new(4096_i64)
      Components::Cache.configure do |config|
        config.use_custom_cache(store)
        config.page_cache.rebuilds_after_write = true
      end
      Components::Cache.page_cache.store.should be(store)
      Components::Cache.page_cache.settings.rebuilds_after_write?.should be_true
      Components::Cache.configure do |config|
        config.use_memory_cache
        config.page_cache.rebuilds_after_write = false
      end
    end
  end
end

private def run_handler(handler : Components::Cache::PageCacheHandler, path : String = "/page", headers = HTTP::Headers.new, &downstream : HTTP::Server::Context ->) : HTTP::Client::Response
  context, output = context_for(path, headers)
  handler.next = downstream
  handler.call(context)
  context.response.close
  output.rewind
  HTTP::Client::Response.from_io(output, decompress: false)
end

describe Components::Cache::PageCacheHandler do
  it "stores a captured response and answers the next request from memory" do
    cache = new_cache
    handler = Components::Cache::PageCacheHandler.new(cache) { |context| context.request.path }
    downstream_calls = 0
    response = run_handler(handler) do |context|
      downstream_calls += 1
      context.response.content_type = "text/html"
      context.response.print PAGE_HTML
    end
    response.body.should eq(PAGE_HTML)
    response.headers["Cache-Control"].should eq("no-cache")

    second = run_handler(handler) { |_context| raise "must not reach the application" }
    second.body.should eq(PAGE_HTML)
    downstream_calls.should eq(1)
  end

  it "reads Amber's context content when the body is not written yet" do
    cache = new_cache
    handler = Components::Cache::PageCacheHandler.new(cache) { |context| context.request.path }
    run_handler(handler) { |context| context.content = PAGE_HTML }
    second = run_handler(handler) { |_context| raise "must not reach the application" }
    second.body.should eq(PAGE_HTML)
  end

  it "leaves a request alone when the block names no page" do
    handler = Components::Cache::PageCacheHandler.new(new_cache) { |_context| nil }
    calls = 0
    2.times { run_handler(handler) { |_context| calls += 1 } }
    calls.should eq(2)
  end

  it "does not store a response that sets a cookie" do
    cache = new_cache
    handler = Components::Cache::PageCacheHandler.new(cache) { |context| context.request.path }
    calls = 0
    2.times do
      run_handler(handler) do |context|
        calls += 1
        context.response.headers["Set-Cookie"] = "a=1"
        context.response.print PAGE_HTML
      end
    end
    calls.should eq(2)
  end

  it "does not store an empty response" do
    cache = new_cache
    handler = Components::Cache::PageCacheHandler.new(cache) { |context| context.request.path }
    calls = 0
    2.times { run_handler(handler) { |_context| calls += 1 } }
    calls.should eq(2)
  end

  it "does not store a failed response" do
    cache = new_cache
    handler = Components::Cache::PageCacheHandler.new(cache) { |context| context.request.path }
    calls = 0
    2.times do
      run_handler(handler) do |context|
        calls += 1
        context.response.status_code = 500
        context.response.print "oops"
      end
    end
    calls.should eq(2)
  end

  it "does not store a page a write cleared while it was rendering" do
    cache = new_cache
    handler = Components::Cache::PageCacheHandler.new(cache) { |context| context.request.path }
    run_handler(handler) do |context|
      cache.clear_page("/page")
      context.response.print "stale"
    end
    second = run_handler(handler) { |context| context.response.print "fresh" }
    second.body.should eq("fresh")
  end

  it "passes through when an upstream handler already compresses" do
    cache = new_cache
    handler = Components::Cache::PageCacheHandler.new(cache) { |context| context.request.path }
    context, _output = context_for("/page")
    context.response.headers["Content-Encoding"] = "gzip"
    calls = 0
    handler.next = ->(_context : HTTP::Server::Context) { calls += 1; nil }
    handler.call(context)
    calls.should eq(1)
    cache.miss_count.should eq(0)
  end
end
