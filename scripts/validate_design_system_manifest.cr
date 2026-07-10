require "file_utils"
require "json"
require "yaml"

ROOT             = File.expand_path("..", __DIR__)
DEFAULT_MANIFEST = File.join(ROOT, "docs/web-design-system/web-demo.routes.yml")

def assert(name : String, condition : Bool, failures : Array(String))
  failures << name unless condition
end

def resolve_path(path : String, base : String = ROOT) : String
  Path[path].absolute? ? path : File.expand_path(path, base)
end

def yaml_string(node : YAML::Any?, fallback = "") : String
  node.try(&.as_s?) || fallback
end

def yaml_bool(node : YAML::Any?, fallback = false) : Bool
  return fallback unless node
  value = node.as_bool?
  value.nil? ? fallback : value
end

def yaml_strings(node : YAML::Any?) : Array(String)
  node.try(&.as_a?).try(&.map(&.as_s)) || [] of String
end

def strip_runtime(html : String) : String
  html
    .gsub(/<script\b.*?<\/script>/mi, "")
    .gsub(/<style\b.*?<\/style>/mi, "")
end

def attrs(tag : String) : Hash(String, String)
  parsed = {} of String => String
  tag.scan(/([a-zA-Z0-9_\-:]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'))?/).each do |match|
    key = match[1]
    next if key == tag.split(/\s+/, 2)[0].gsub(/[<>\/]/, "")
    parsed[key] = match[2]? || match[3]? || ""
  end
  parsed
end

def control_has_label?(html : String, tag : String, index : Int32) : Bool
  attributes = attrs(tag)
  return true if attributes.has_key?("aria-label") || attributes.has_key?("aria-labelledby")
  if id = attributes["id"]?
    return true if html.includes?(%Q(for="#{id}")) || html.includes?(%Q(for='#{id}'))
  end

  before = html[0, index]
  after = html[index, html.size - index]
  last_open = before.rindex(/<label\b/i)
  last_close = before.rindex(/<\/label>/i)
  next_close = after.index(/<\/label>/i)
  !!(last_open && (!last_close || last_open > last_close) && next_close)
end

def ids_for(html : String) : Array(String)
  html.scan(/\sid=(?:"([^"]+)"|'([^']+)')/).map { |match| match[1]? || match[2] }
end

def text_for_id(html : String, id : String) : String
  if match = html.match(/<([a-zA-Z][\w:-]*)\b[^>]*\sid=(?:"#{Regex.escape(id)}"|'#{Regex.escape(id)}')[^>]*>(.*?)<\/\1>/m)
    match[2].gsub(/<[^>]+>/, "").strip
  else
    ""
  end
end

def attr_values(html : String, name : String) : Array(String)
  html.scan(/(?:^|[\s<])#{Regex.escape(name)}(?:\s*=\s*(?:"([^"]*)"|'([^']*)'))?(?=[\s>])/).map do |match|
    match[1]? || match[2]? || ""
  end
end

manifest_path = resolve_path(ARGV[0]? || DEFAULT_MANIFEST)
manifest = YAML.parse(File.read(manifest_path))
manifest_dir = File.dirname(manifest_path)

site = manifest["site"]?
root = resolve_path(yaml_string(site.try(&.["root"]?), "output"), manifest_dir)
artifacts = resolve_path(yaml_string(site.try(&.["artifacts"]?), "test-results/design-system"), manifest_dir)
runtime_files = yaml_strings(site.try(&.["runtime_files"]?)).map { |path| resolve_path(path, manifest_dir) }
checks = manifest["defaults"]?.try(&.["checks"]?)
static_enabled = yaml_bool(checks.try(&.["static"]?), true)
forbidden = manifest["forbidden"]?
forbidden_classes = yaml_strings(forbidden.try(&.["classes"]?))
forbidden_terms = yaml_strings(forbidden.try(&.["runtime_terms"]?))
forbid_inline_handlers = yaml_bool(forbidden.try(&.["inline_handlers"]?), true)

failures = [] of String
page_results = [] of NamedTuple(name: String, path: String, required_components: Array(String), required_hooks: Array(String))
pages = manifest["pages"]?.try(&.as_a?)

if pages.nil? || pages.not_nil!.empty?
  failures << "pages must contain at least one page"
end

runtime_text = String.build do |io|
  runtime_files.each do |path|
    if File.file?(path)
      io << "\n"
      io << File.read(path)
    else
      failures << "runtime file exists at #{path}"
    end
  end
end

pages.try &.each do |page|
  name = yaml_string(page["name"]?, "unnamed")
  relative_page_path = yaml_string(page["path"]?)
  if relative_page_path.empty?
    failures << "#{name} page path is required"
    next
  end
  page_path = resolve_path(relative_page_path, root)
  title = yaml_string(page["title"]?)
  required_components = yaml_strings(page["required_components"]?)
  required_hooks = yaml_strings(page["required_hooks"]?)
  required_text = yaml_strings(page["required_text"]?)

  page_results << {
    name:                name,
    path:                page_path,
    required_components: required_components,
    required_hooks:      required_hooks,
  }

  assert("#{name} page exists at #{page_path}", File.file?(page_path), failures)
  next unless File.file?(page_path)

  page_html = File.read(page_path)
  clean = strip_runtime(page_html)
  full_scan = "#{page_html}\n#{runtime_text}"

  if static_enabled
    assert("#{name} has html lang", page_html.match(/<html\b[^>]*\slang=/i).try { true } || false, failures)
    assert("#{name} has title", page_html.match(/<title>[^<]+<\/title>/i).try { true } || false, failures)
    assert("#{name} title includes #{title}", title.empty? || page_html.includes?(%(<title>#{title}</title>)), failures)
    assert("#{name} has viewport meta", page_html.includes?(%(<meta name="viewport")), failures)
    assert("#{name} has main landmark", clean.match(/<main\b/i).try { true } || false, failures)

    h1_count = clean.scan(/<h1\b/i).size
    assert("#{name} has exactly one h1, found #{h1_count}", h1_count == 1, failures)

    ids = ids_for(clean)
    duplicates = ids.group_by(&.itself).select { |_, values| values.size > 1 }.keys
    assert("#{name} has unique ids: #{duplicates.join(", ")}", duplicates.empty?, failures)

    controls = [] of {String, Int32}
    clean.scan(/<(input|select|textarea)\b[^>]*>/i) do |match|
      controls << {match[0], match.begin(0)}
    end
    unlabeled = controls.reject { |tag, index| control_has_label?(clean, tag, index) }
    assert("#{name} controls have accessible labels: #{unlabeled.map(&.[0]).join(", ")}", unlabeled.empty?, failures)

    %w[aria-describedby aria-labelledby aria-controls].each do |attr_name|
      attr_values(clean, attr_name).each do |value|
        value.split(/\s+/).each do |target_id|
          assert("#{name} #{attr_name} target #{target_id} exists", ids.includes?(target_id), failures)
          next if attr_name == "aria-controls"
          assert("#{name} #{attr_name} target #{target_id} has text", !text_for_id(clean, target_id).empty?, failures)
        end
      end
    end

    positive_tabindex = clean.scan(/\stabindex="([^"]+)"/).map { |match| match[1] }.select { |value| value.to_i? ? value.to_i > 0 : true }
    assert("#{name} has no positive or invalid tabindex: #{positive_tabindex.join(", ")}", positive_tabindex.empty?, failures)
  end

  required_components.each do |component|
    assert("#{name} includes component #{component}", attr_values(clean, "data-component").includes?(component), failures)
  end

  required_hooks.each do |hook|
    assert("#{name} includes hook #{hook}", !attr_values(clean, hook).empty?, failures)
  end

  required_text.each do |text|
    assert("#{name} includes required text #{text.inspect}", clean.includes?(text), failures)
  end

  forbidden_classes.each do |klass|
    assert("#{name} does not use forbidden class #{klass}", !clean.match(/class=(?:"[^"]*\b#{Regex.escape(klass)}\b[^"]*"|'[^']*\b#{Regex.escape(klass)}\b[^']*')/), failures)
  end

  forbidden_terms.each do |term|
    assert("#{name} does not include forbidden runtime term #{term.inspect}", !full_scan.includes?(term), failures)
  end

  if forbid_inline_handlers
    assert("#{name} has no inline event handlers", !clean.match(/\son[a-zA-Z]+\s*=/), failures)
  end
end

FileUtils.mkdir_p(artifacts)
result_file = File.join(artifacts, "static-manifest-audit.json")
audit = {
  manifest:      manifest_path,
  root:          root,
  artifacts:     artifacts,
  runtime_files: runtime_files,
  pages:         page_results,
  checks:        {
    static:                  static_enabled,
    forbidden_classes:       forbidden_classes,
    forbidden_runtime_terms: forbidden_terms,
    inline_handlers:         forbid_inline_handlers,
  },
  failures: failures,
  passed:   failures.empty?,
}
File.write(result_file, audit.to_pretty_json)

if failures.empty?
  puts "Design-system manifest static audit passed: #{result_file}"
else
  STDERR.puts "Design-system manifest static audit failed:"
  failures.each { |failure| STDERR.puts "- #{failure}" }
  exit 1
end
