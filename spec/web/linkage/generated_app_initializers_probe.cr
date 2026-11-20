# Linkage probe: exactly what a generated Amber app's
# config/initializers/page_cache.cr requires from asset_pipeline, exercised the
# way the generated app uses it (amber_cli's `amber new` web template):
#
#   require "asset_pipeline/components/base/stateless_view"
#   require "asset_pipeline/components/cache/configuration"
#
# scripts/check_default_require_linkage.rb builds this program and checks that
# the binary links no libpcre2.

require "../../../src/components/base/stateless_view"
require "../../../src/components/cache/configuration"

# Like the generated SiteFooter: a stateless view rendered once at boot.
# `__io__` is the parameter name `ECR.def_to_s` gives the generated views.
struct ProbeFooter < Components::StatelessView
  def to_s(__io__ : IO) : Nil
    __io__ << "<footer>"
    __io__ << escape_text("Probe & footer")
    __io__ << "</footer>"
  end
end

# The generated initializer.
Components::Cache.configure do |config|
  config.use_memory_cache(32_i64 * 1_048_576)
end

# The generated main file warms every stateless view before serving.
warm_report = Components::StatelessView.warm_all
puts "warmed #{warm_report.list_of_warmed_view_names.size} stateless views (#{warm_report.held_bytes} bytes)"

# The generated HomeController answers its page from the page cache. The
# request headers walk the Accept-Encoding refusal check and the ETag check.
private def answer_home_page(accept_encoding : String, if_none_match : String? = nil) : String
  headers = HTTP::Headers{"Accept-Encoding" => accept_encoding}
  headers["If-None-Match"] = if_none_match if if_none_match
  output = IO::Memory.new
  response = HTTP::Server::Response.new(output)
  context = HTTP::Server::Context.new(HTTP::Request.new("GET", "/", headers), response)
  Components::Cache.page_cache.answer(context, "home") do
    "<main>Home</main>#{ProbeFooter.new.render}"
  end
  response.close
  output.to_s
end

private def header_line(answer : String, header_name : String) : String?
  answer.lines.find(&.downcase.starts_with?("#{header_name}:"))
end

list_of_answers = {"gzip;q=0, identity", "gzip", "gzip", "br;q=0.000, gzip;q=1", "gzip; Q = 0.0"}.map do |accept_encoding|
  answer = answer_home_page(accept_encoding)
  content_encoding = header_line(answer, "content-encoding") || "Content-Encoding: identity"
  puts "#{accept_encoding.inspect}: #{answer.lines.first?.to_s.strip}, #{content_encoding.strip}"
  answer
end

etag_line = header_line(list_of_answers.last, "etag")
if etag_line
  revalidation = answer_home_page("identity", etag_line.partition(':').last.strip)
  puts "If-None-Match: #{revalidation.lines.first?.to_s.strip}"
end
