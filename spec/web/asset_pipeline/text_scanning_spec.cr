require "../spec_helper"
require "../../../src/asset_pipeline"

# Equivalence specs for the hand-written scanners that replaced the regular
# expressions on the default `require "asset_pipeline"` path.
#
# Every scanner is compared with the exact pattern it replaced (kept here, in
# the spec, as `FormerPattern`), over a table of edge cases and over seeded
# random inputs, and both must agree on every input: the same answer, or the
# same ArgumentError for text that is not valid UTF-8.

# PCRE2 10.43 added nonspacing marks (Mn) and connector punctuation (Pc) to
# the UCP `\w` class, and the scanners follow that rule. The former patterns
# below spell `\w` with this class so they mean the same on every PCRE2
# version; on 10.43 and later it is exactly `\w`.
private WORD_CLASS = %q(\w\p{Mn}\p{Pc})

private module FormerPattern
  EXTERNAL_LIBRARY_PATTERNS = {
    /\$\s*\(/                                                                             => "jquery",
    /jQuery[\.\s]*[\(#{WORD_CLASS}]/                                                      => "jQuery",
    /_\.(map|filter|forEach|reduce|find|includes|isEmpty|isArray|get|set|has|clone)/      => "lodash",
    /lodash\.(map|filter|forEach|reduce|find|includes|isEmpty|isArray|get|set|has|clone)/ => "lodash",
    /moment\s*\(/                                                                         => "moment",
    /moment\.(now|utc|unix)/                                                              => "moment",
    /new\s+Chart\s*\(/                                                                    => "chartjs",
    /Chart\.(register|defaults)/                                                          => "chartjs",
    /Alpine\.(start|data|store)/                                                          => "alpinejs",
    /x-data\s*=/                                                                          => "alpinejs",
    /Vue\.(createApp|ref|reactive|computed)/                                              => "vue",
    /createApp\s*\(/                                                                      => "vue",
    /React\.(useState|useEffect|createElement)/                                           => "react",
    /ReactDOM\.render/                                                                    => "react-dom",
    /axios\.(get|post|put|delete)/                                                        => "axios",
    /fetch\s*\(/                                                                          => "unfetch",
  }

  LOCAL_MODULE_PATTERNS = [
    /new\s+([A-Z][a-zA-Z0-9_]*)\s*\(/,
    /([A-Z][a-zA-Z0-9_]*)\.[a-zA-Z_][a-zA-Z0-9_]*\s*\(/,
    /([A-Z][a-zA-Z0-9_]*)\.[A-Z_][A-Z0-9_]*\s*[=\(]/,
  ]

  STATIC_IMPORT  = /import\s+(?:(?:\{[^}]+\}|\*\s+as\s+[#{WORD_CLASS}]+|[#{WORD_CLASS}]+)(?:\s*,\s*(?:\{[^}]+\}|\*\s+as\s+[#{WORD_CLASS}]+|[#{WORD_CLASS}]+))*\s+from\s+)?["']([^"']+)["']/
  DYNAMIC_IMPORT = /import\s*\(\s*["']([^"']+)["']\s*\)/

  def self.external_library_names(source : String) : Array(String)
    detected = Set(String).new
    EXTERNAL_LIBRARY_PATTERNS.each { |pattern, library| detected.add(library) if source.match(pattern) }
    detected.to_a
  end

  def self.local_class_references(source : String) : Array(String)
    LOCAL_MODULE_PATTERNS.flat_map { |pattern| source.scan(pattern).map { |match| match[1] } }
  end

  def self.static_import_specifiers(source : String) : Array(String)
    source.scan(STATIC_IMPORT).map { |match| match[1] }
  end

  def self.dynamic_import_specifiers(source : String) : Array(String)
    source.scan(DYNAMIC_IMPORT).map { |match| match[1] }
  end

  def self.counts(source : String) : Array(Int32)
    [
      source.scan(/function\s+[#{WORD_CLASS}]+/).size,
      source.scan(/(?:const|let|var)\s+[#{WORD_CLASS}]+\s*=\s*(?:function|\()/).size,
      source.scan(/^\s*(?:constructor|[a-zA-Z_][a-zA-Z0-9_]*)\s*\(/m).size,
      source.scan(/class\s+[#{WORD_CLASS}]+/).size,
      source.scan(/addEventListener|on[#{WORD_CLASS}]+\s*=/).size,
    ]
  end

  def self.stimulus_registered_classes(source : String) : Array(String)
    source.scan(/Stimulus\.register\s*\(\s*["']([^"']+)["']\s*,\s*([A-Za-z][A-Za-z0-9_]*)\s*\)/).map { |match| match[2] }
  end

  def self.default_import_names(source : String) : Array(String)
    source.scan(/import\s+([A-Za-z][A-Za-z0-9_]*)\s+from\s+["']([^"']+)["']/).map { |match| match[1] }
  end

  def self.stimulus_controller_class_name?(name : String) : Bool
    !name.match(/^[A-Z][a-zA-Z0-9_]*Controller$/).nil?
  end

  def self.ascii_class_name?(name : String) : Bool
    !name.match(/^[A-Z][a-zA-Z0-9_]*$/).nil?
  end

  def self.sha256_hex_digest?(value : String) : Bool
    value.matches?(/\A[a-f0-9]{64}\z/)
  end

  def self.collapse_slash_runs(value : String) : String
    value.gsub(/\/{2,}/, "/")
  end

  def self.starts_with_url_scheme?(value : String) : Bool
    value.starts_with?(/(?i:data|https?|blob|mailto|tel):/)
  end

  def self.query_or_fragment_index(reference : String) : Int32?
    reference.index(/[?#]/)
  end

  def self.source_mapping_url_byte_range(comment : String) : {Int32, Int32}?
    if match = comment.match(/\A\/\/[#@]\s*sourceMappingURL=([^\s]+)/)
      {match.byte_begin(1), match.byte_end(1)}
    end
  end

  def self.hyphenate_before_uppercase(name : String) : String
    name.gsub(/([A-Z])/, "-\\1")
  end

  def self.valid_scope?(scope : String) : Bool
    scope.starts_with?(/\/|\.\/|\.\.\//)
  end

  def self.auto_category(import_name : String) : {String, String?}
    if import_name.match(/^[A-Z][a-zA-Z0-9_]*Controller$/)
      {"controller", "stimulus"}
    elsif import_name.match(/@hotwired\/stimulus|stimulus/)
      {"framework", "stimulus"}
    elsif import_name.match(/alpinejs|alpine/)
      {"framework", "alpine"}
    elsif import_name.match(/vue/)
      {"framework", "vue"}
    elsif import_name.match(/react/)
      {"framework", "react"}
    elsif import_name.match(/lodash|underscore|jquery|axios|fetch/)
      {"library", nil}
    else
      {"utility", nil}
    end
  end

  # The former `create_map_list_as_string` rule: a value gets the public
  # asset base path unless it starts with `http`, `./`, or `/`.
  def self.gets_asset_base_path?(value : String) : Bool
    !value.starts_with?(/http|\.\//) && !value.starts_with?(/\/|\.\//)
  end
end

# Runs *block* and returns its value, or the exception class it raised.
private def outcome(&)
  yield
rescue ex : ArgumentError
  ArgumentError
end

# Returns, in hex, every Unicode scalar value where the block and *pattern*
# disagree. Code points that the linked PCRE2 treats as unassigned are left
# out: there the answer depends on which Unicode version each side ships.
private def mismatches_against(pattern : Regex, & : Char -> Bool) : Array(String)
  unassigned = /\A\p{Cn}\z/
  list_of_mismatches = [] of String
  (0..0x10FFFF).each do |codepoint|
    next if 0xD800 <= codepoint <= 0xDFFF
    char = codepoint.unsafe_chr
    text = char.to_s
    next if (yield char) == pattern.matches?(text) || unassigned.matches?(text)
    list_of_mismatches << codepoint.to_s(16)
  end
  list_of_mismatches
end

private def scan_text(tokens : Array(String), random : Random, max_tokens : Int32 = 24) : String
  String.build do |io|
    random.rand(0..max_tokens).times { io << tokens.sample(random) }
  end
end

private def invalid_utf8(prefix : String) : String
  prefix + String.new(Bytes[0xff]) + "x"
end

private JS_TOKENS = [
  "import", "export", "from", "as", "*", "{", "}", "(", ")", "\"", "'", ",", ";", ".", "=", "/",
  " ", "  ", "\t", "\n", "\r", "\r\n", "\v", "\f", " ", "\u0085", "᠎", " ", "　",
  "x", "y", "Foo", "BAR", "Bar", "_", "$", "é", "̀", "ः", "‿", "\u{17001}", "٣", "1", "-",
  "new", "Chart", "Controller", "HelloController", "Stimulus.register", "Stimulus", "register",
  "function", "class", "const", "let", "var", "constructor", "on", "onclick", "addEventListener",
  "jQuery", "_.", "map", "isEmpty", "lodash.", "moment", "now", "x-data", "Vue.", "createApp",
  "React.", "useState", "ReactDOM.render", "axios.", "get", "fetch", "Alpine.", "start", "A.B", "X.Y_Z",
]

private PATH_TOKENS = [
  "/", "//", "./", "../", ".", "?", "#", "@", ":", "a", "b", "f", "0", "9", "A", "F", "g", " ", "\t", "\n",
  " ", "\u0085", "᠎", "é", "ſ", "K", "data", "DATA", "http", "HTTPS", "https", "httpſ", "blob",
  "mailto", "tel", "TeL", "sourceMappingURL=", "//#", "//@", "map.js", "Controller", "X", "_", "̀",
]

# Returns *seed* after one to four random edits: a character deleted,
# replaced by a token, or a token inserted, or the text joined to another
# seed. Mutating inputs that match yields many near misses.
private def mutate(seed : String, seeds : Array(String), tokens : Array(String), random : Random) : String
  text = seed
  random.rand(1..4).times do
    position = text.empty? ? 0 : random.rand(0..text.size)
    case random.rand(4)
    when 0 then text = text.empty? ? text : text.sub(position.clamp(0, text.size - 1), "")
    when 1 then text = text.empty? ? tokens.sample(random) : text.sub(position.clamp(0, text.size - 1), tokens.sample(random))
    when 2 then text = text.insert(position, tokens.sample(random))
    else        text = text + tokens.sample(random) + seeds.sample(random)
    end
  end
  text
end

private def assert_same_on_table_and_fuzz(label : String, extra_inputs : Array(String), tokens : Array(String), &check : String -> Nil)
  inputs = ["", " ", "\n", "\u00A0", "é", invalid_utf8("a")] + extra_inputs
  inputs.each { |input| check.call(input) }
  random = Random.new(label.hash)
  seeds = extra_inputs.select { |input| input.size < 200 }
  3_000.times { check.call(scan_text(tokens, random)) }
  5_000.times { check.call(mutate(seeds.sample(random), seeds, tokens, random)) } unless seeds.empty?
end

# The scanners' character classes come from Unicode 17.0.0 data and were
# verified against PCRE2 10.49. An older libpcre2 ships older Unicode data in
# which some code points carry another category, so there the exhaustive
# class checks are reported as pending rather than failed.
private def linked_pcre2_version : String
  {% if Regex.has_constant?(:PCRE2) %}
    Regex::PCRE2.version
  {% else %}
    "PCRE1"
  {% end %}
end

private def pcre2_shares_scanner_unicode_data? : Bool
  numbers = linked_pcre2_version.split(' ').first.split('.')
  major = numbers[0]?.try(&.to_i?) || 0
  minor = numbers[1]?.try(&.to_i?) || 0
  major > 10 || (major == 10 && minor >= 49)
end

describe AssetPipeline::TextScanning do
  if pcre2_shares_scanner_unicode_data?
    describe ".space?" do
      it "matches the PCRE2 \\s class for every Unicode scalar value" do
        mismatches_against(/\A\s\z/) { |char| AssetPipeline::TextScanning.space?(char) }.should eq([] of String)
      end
    end

    describe ".word_char?" do
      it "matches the PCRE2 10.43+ \\w class for every Unicode scalar value" do
        mismatches_against(/\A[#{WORD_CLASS}]\z/) { |char| AssetPipeline::TextScanning.word_char?(char) }.should eq([] of String)
      end
    end
  else
    pending "matches PCRE2 \\s and \\w for every Unicode scalar value (linked PCRE2 #{linked_pcre2_version} predates the Unicode 17 data the scanners use)"
  end

  describe ".stimulus_controller_class_name?" do
    it "agrees with /^[A-Z][a-zA-Z0-9_]*Controller$/" do
      table = ["Controller", "CController", "HelloController", "HelloController\n", "HelloController\n\n",
               "HelloController ", "helloController", "Hello_World9Controller", "HelloÉController",
               "\nHelloController", "HelloControllerX", "A" * 10_000 + "Controller"]
      assert_same_on_table_and_fuzz("controller", table, PATH_TOKENS) do |input|
        outcome { AssetPipeline::TextScanning.stimulus_controller_class_name?(input) }
          .should eq(outcome { FormerPattern.stimulus_controller_class_name?(input) })
      end
    end
  end

  describe ".ascii_class_name?" do
    it "agrees with /^[A-Z][a-zA-Z0-9_]*$/" do
      table = ["A", "A\n", "A\n\n", "Ab_9", "a", "Aé", "A b", "A" * 50_000]
      assert_same_on_table_and_fuzz("class_name", table, PATH_TOKENS) do |input|
        outcome { AssetPipeline::TextScanning.ascii_class_name?(input) }
          .should eq(outcome { FormerPattern.ascii_class_name?(input) })
      end
    end
  end

  describe ".sha256_hex_digest?" do
    it "agrees with /\\A[a-f0-9]{64}\\z/" do
      table = ["a" * 64, "f0" * 32, "A" * 64, "a" * 63, "a" * 65, "a" * 64 + "\n", "g" * 64, "é" * 32, "0" * 64]
      assert_same_on_table_and_fuzz("sha256", table, ["a", "f", "0", "9", "A", "g", "\n", "a" * 32, "0" * 16]) do |input|
        outcome { AssetPipeline::TextScanning.sha256_hex_digest?(input) }
          .should eq(outcome { FormerPattern.sha256_hex_digest?(input) })
      end
    end
  end

  describe ".collapse_slash_runs" do
    it "agrees with gsub(/\\/{2,}/, \"/\")" do
      table = ["/", "//", "///a//b/", "a/b", "/é//ü///", "/" * 100_000]
      assert_same_on_table_and_fuzz("slashes", table, PATH_TOKENS) do |input|
        outcome { AssetPipeline::TextScanning.collapse_slash_runs(input) }
          .should eq(outcome { FormerPattern.collapse_slash_runs(input) })
      end
    end
  end

  describe ".starts_with_url_scheme?" do
    it "agrees with starts_with?(/(?i:data|https?|blob|mailto|tel):/)" do
      table = ["data:", "DATA:x", "http:", "https:", "HTTPS://", "httpſ:", "HTTPſ:", "blob:", "mailto:", "tel:",
               "TEL:", "tel", "ftp:", " http:", "httpss:", "hTtP:", "dataſ:", "K:", "ﬆ:"]
      assert_same_on_table_and_fuzz("scheme", table, PATH_TOKENS) do |input|
        outcome { AssetPipeline::TextScanning.starts_with_url_scheme?(input) }
          .should eq(outcome { FormerPattern.starts_with_url_scheme?(input) })
      end
    end

    it "accepts exactly the characters PCRE2 folds onto each scheme letter" do
      folding = /\A(?i:[abdehilmopst])\z/
      list_of_folding_chars = [] of Char
      (0..0x10FFFF).each do |codepoint|
        next if 0xD800 <= codepoint <= 0xDFFF
        char = codepoint.unsafe_chr
        list_of_folding_chars << char if folding.matches?(char.to_s)
      end
      {"data:", "http:", "https:", "blob:", "mailto:", "tel:"}.each do |scheme|
        scheme.size.times do |index|
          list_of_folding_chars.each do |char|
            candidate = scheme.sub(index, char)
            AssetPipeline::TextScanning.starts_with_url_scheme?(candidate)
              .should eq(FormerPattern.starts_with_url_scheme?(candidate))
          end
        end
      end
    end
  end

  describe ".query_or_fragment_index" do
    it "agrees with index(/[?#]/) (a character index)" do
      table = ["a?b", "a#b", "é?", "ü#?", "plain", "?", "#"]
      assert_same_on_table_and_fuzz("query", table, PATH_TOKENS) do |input|
        outcome { AssetPipeline::TextScanning.query_or_fragment_index(input) }
          .should eq(outcome { FormerPattern.query_or_fragment_index(input) })
      end
    end
  end

  describe ".source_mapping_url_byte_range" do
    it "agrees with the former sourceMappingURL pattern" do
      table = ["//# sourceMappingURL=app.js.map", "//@sourceMappingURL=a", "//# ᠎sourceMappingURL=é.map rest",
               "//# sourceMappingURL=", "//# sourceMappingURL= x", "/# sourceMappingURL=x", "//! sourceMappingURL=x",
               "//#\n sourceMappingURL=x", "//# sourceMappingURL=a\u0085b", "//# sourceMappingURL=" + "m" * 50_000]
      assert_same_on_table_and_fuzz("source_map", table, PATH_TOKENS) do |input|
        outcome { AssetPipeline::TextScanning.source_mapping_url_byte_range(input) }
          .should eq(outcome { FormerPattern.source_mapping_url_byte_range(input) })
      end
    end
  end

  describe ".hyphenate_before_uppercase" do
    it "agrees with gsub(/([A-Z])/, \"-\\\\1\")" do
      table = ["MySpecial", "ÉcoleX", "ABC", "abc", "a_B-C"]
      assert_same_on_table_and_fuzz("hyphenate", table, PATH_TOKENS) do |input|
        outcome { AssetPipeline::TextScanning.hyphenate_before_uppercase(input) }
          .should eq(outcome { FormerPattern.hyphenate_before_uppercase(input) })
      end
    end
  end
end

describe AssetPipeline::JavascriptSourceScan do
  js_table = [
    "$(document)", "$  (x)", "$\n\n(", "jQuery.ajax(", "jQuery . . x", "jQuery..", "jQuerỳ", "jQueryé",
    "_.map(x)", "_.mapper", "_. map", "lodash.isEmpty", "moment ()", "moment.utc", "new  Chart(", "newChart(",
    "new\u0085Chart (", "Chart.defaults", "Alpine.store", "x-data =", "Vue.ref", "createApp(", "React.useEffect",
    "ReactDOM.render", "axios.delete", "fetch\t(", "fetch",
    "new Foo()", "new Foo\n(", "new foo()", "fooBar.baz()", "X.yZ.w(", "Foo.BAR = 1", "Foo.BARx(", "Foo._X(",
    "A.B.C.D()", "new Foo.Bar()",
    "import x from 'y'", "import {a, b} from \"c\"", "import * as ns from 'm'", "import x, {y} from 'z'",
    "import 'side-effect'", "import ''", "import from 'x'", "import {} from 'x'", "import {a}from 'x'",
    "import x , * as y from 'z\"", "import {a import {b} from 'c'", "import é from 'ü'", "import x from　'y'",
    "import('dyn')", "import ( \"dyn\" )", "import('')", "import('a' )x", "importimport('x')",
    "function a() {}", "function\ǹ", "functionfunction x", "class Foo {}", "class\t_",
    "const f = function", "let g = (", "var h=function", "const x = y", "constlet x = (",
    "constructor() {}", "  method (arg) {\n  }\n", "\n\n  foo(", "\r\nfoo(", "a\rfoo(", " 1foo(",
    "el.addEventListener('x')", "onclick = f", "onX=", "on =", "onxaddEventListener y", "ononon x",
    "Stimulus.register(\"hello\", HelloController)", "Stimulus.register ( 'a' , B_1 )", "Stimulus.register('', X)",
    "Stimulus.register('a\"b', X)", "import HelloController from './hello.js'", "import H from\"x\"", "import 9 from 'x'",
    "on" * 20_000 + " x", "A" * 40_000, "import {" * 5_000 + "} , y" * 2_000, "\n " * 20_000, "new " * 10_000,
  ]

  it "detects the same external libraries, in the same order" do
    assert_same_on_table_and_fuzz("external", js_table, JS_TOKENS) do |input|
      outcome { AssetPipeline::JavascriptSourceScan.external_library_names(input) }
        .should eq(outcome { FormerPattern.external_library_names(input) })
    end
  end

  it "finds the same local class references, in the same order" do
    assert_same_on_table_and_fuzz("local", js_table, JS_TOKENS) do |input|
      found = outcome do
        list_of_names = [] of String
        AssetPipeline::JavascriptSourceScan.each_local_class_reference(input) { |name| list_of_names << name }
        list_of_names
      end
      found.should eq(outcome { FormerPattern.local_class_references(input) })
    end
  end

  it "finds the same static and dynamic import specifiers" do
    assert_same_on_table_and_fuzz("imports", js_table, JS_TOKENS) do |input|
      outcome { AssetPipeline::JavascriptSourceScan.static_import_specifiers(input) }
        .should eq(outcome { FormerPattern.static_import_specifiers(input) })
      outcome { AssetPipeline::JavascriptSourceScan.dynamic_import_specifiers(input) }
        .should eq(outcome { FormerPattern.dynamic_import_specifiers(input) })
    end
  end

  it "counts the same functions, assignments, methods, classes, and event listeners" do
    assert_same_on_table_and_fuzz("counts", js_table, JS_TOKENS) do |input|
      counts = outcome do
        [
          AssetPipeline::JavascriptSourceScan.function_declaration_count(input),
          AssetPipeline::JavascriptSourceScan.function_assignment_count(input),
          AssetPipeline::JavascriptSourceScan.method_definition_count(input),
          AssetPipeline::JavascriptSourceScan.class_declaration_count(input),
          AssetPipeline::JavascriptSourceScan.event_listener_count(input),
        ]
      end
      counts.should eq(outcome { FormerPattern.counts(input) })
    end
  end

  it "finds the same Stimulus registrations and default imports" do
    assert_same_on_table_and_fuzz("stimulus", js_table, JS_TOKENS) do |input|
      registered = outcome do
        list_of_classes = [] of String
        AssetPipeline::JavascriptSourceScan.each_stimulus_registered_class(input) { |name| list_of_classes << name }
        list_of_classes
      end
      registered.should eq(outcome { FormerPattern.stimulus_registered_classes(input) })

      imported = outcome do
        list_of_names = [] of String
        AssetPipeline::JavascriptSourceScan.each_default_import_name(input) { |name| list_of_names << name }
        list_of_names
      end
      imported.should eq(outcome { FormerPattern.default_import_names(input) })
    end
  end

  it "scans adversarial input in linear time" do
    size = 400_000
    list_of_inputs = [
      "on" * (size // 2), "A" * size, "A." * (size // 2), "import {" * (size // 8) + "}" + " , x" * (size // 4),
      "\n " * (size // 2), "new " * (size // 4), "import " * (size // 7), "$" * size, "jQuery." * (size // 7),
      "const " * (size // 6), "Stimulus.register('" * (size // 19),
    ]
    list_of_inputs.each do |input|
      elapsed = Time.measure do
        AssetPipeline::JavascriptSourceScan.external_library_names(input)
        AssetPipeline::JavascriptSourceScan.each_local_class_reference(input) { }
        AssetPipeline::JavascriptSourceScan.static_import_specifiers(input)
        AssetPipeline::JavascriptSourceScan.dynamic_import_specifiers(input)
        AssetPipeline::JavascriptSourceScan.function_declaration_count(input)
        AssetPipeline::JavascriptSourceScan.function_assignment_count(input)
        AssetPipeline::JavascriptSourceScan.method_definition_count(input)
        AssetPipeline::JavascriptSourceScan.class_declaration_count(input)
        AssetPipeline::JavascriptSourceScan.event_listener_count(input)
        AssetPipeline::JavascriptSourceScan.each_stimulus_registered_class(input) { }
        AssetPipeline::JavascriptSourceScan.each_default_import_name(input) { }
        # A quadratic scan of 400,000 characters takes minutes; a linear one
        # takes milliseconds.
      end
      elapsed.should be < 2.seconds
    end
  end
end

describe "default require path call sites" do
  it "auto-categorizes imports as the former patterns did" do
    names = ["HelloController", "HelloController\n", "@hotwired/stimulus", "stimulus-use", "alpinejs", "my-alpine",
             "vue", "preact", "lodash-es", "underscore", "jquery", "axios", "node-fetch", "app", "", "ÉController"]
    random = Random.new(7)
    names.concat(Array.new(500) { scan_text(PATH_TOKENS + ["stimulus", "alpine", "vue", "react", "fetch", "jquery"], random, 6) })
    names.each do |name|
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import(name, "x.js")
      import_map.auto_categorize_imports!
      entry = import_map.imports.first
      {entry["type"]?, entry["framework"]?}.should eq(FormerPattern.auto_category(name))
    end
  end

  it "raises ArgumentError for an import name that is not valid UTF-8, as before" do
    import_map = AssetPipeline::ImportMap.new
    import_map.add_import(invalid_utf8("Hello"), "x.js")
    expect_raises(ArgumentError) { import_map.auto_categorize_imports! }
  end

  it "accepts and rejects the same scope keys" do
    ["/", "./", "../", "/admin", ".", "..", "admin/", "", "é/", ".../", "//"].each do |scope|
      accepted = begin
        AssetPipeline::ImportMap.new.add_scope(scope, "a", "b.js")
        true
      rescue ex
        false
      end
      accepted.should eq(FormerPattern.valid_scope?(scope))
    end
    expect_raises(ArgumentError) { AssetPipeline::ImportMap.new.add_scope(invalid_utf8("/"), "a", "b.js") }
  end

  it "prefixes the same import values with the public asset base path" do
    ["app.js", "/app.js", "./app.js", "../app.js", "http://x/a.js", "https://x/a.js", "httpx.js", "é.js", ".app.js"].each do |value|
      import_map = AssetPipeline::ImportMap.new
      import_map.add_import("a", value)
      import_map.build_import_map_tag
      rewritten = import_map.imports.first["a"].to_s
      (rewritten != value).should eq(FormerPattern.gets_asset_base_path?(value))
    end
  end

  it "registers frameworks from import-name checks and, through the opt-in overload, from regular expressions" do
    AssetPipeline::FrameworkRegistry.register_framework(
      "matcher-probe", "AssetPipeline::ScriptRenderer",
      patterns: [AssetPipeline::FrameworkRegistry::ImportNameMatcher.new { |import_name| import_name.starts_with?("matcher-probe-") }]
    )
    AssetPipeline::FrameworkRegistry.register_framework("regex-probe", "AssetPipeline::ScriptRenderer", patterns: [/\Aregex-probe-/])

    AssetPipeline::FrameworkRegistry.detect_framework("matcher-probe-widget").should eq("matcher-probe")
    AssetPipeline::FrameworkRegistry.detect_framework("regex-probe-widget").should eq("regex-probe")
    AssetPipeline::FrameworkRegistry.detect_framework("plain-widget").should be_nil
  end

  it "detects the Stimulus framework for the same import names" do
    ["HelloController", "HelloController\n", "Controller", "helloController", "Hello", "ÉController"].each do |name|
      detected = AssetPipeline::FrameworkRegistry.detect_framework(name) == "stimulus"
      detected.should eq(FormerPattern.stimulus_controller_class_name?(name))
    end
  end
end
