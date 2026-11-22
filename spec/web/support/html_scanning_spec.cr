require "spec"
require "./html_scanning"

private alias Scanning = SpecSupport::HtmlScanning

# The patterns this module replaced use lookahead and a backreference, which
# PCRE2 compiles and Mica does not. They are built at run time, so the file
# compiles on every engine: nil where the engine leaves the syntax out.
private def reference_pattern?(source : String, options : Regex::Options = Regex::Options::None) : Regex?
  Regex.new(source, options)
rescue ArgumentError
  nil
end

private def reference_attr_values(html : String, name : String, equals : String) : Array(String)?
  pattern = reference_pattern?(%q{(?:^|[\s<])} + Regex.escape(name) + "(?:" + equals + %q{(?:"([^"]*)"|'([^']*)'))?(?=[\s>])})
  return unless pattern
  html.scan(pattern).map { |match| match[1]? || match[2]? || "" }
end

private def reference_element_text(html : String, id : String, quoted_id : String) : String?
  pattern = reference_pattern?(%q{<([a-zA-Z][\w:-]*)\b[^>]*\sid=} + quoted_id + %q{[^>]*>(.*?)</\1>}, Regex::Options::MULTILINE)
  return unless pattern
  match = html.match(pattern)
  match ? match[2].gsub(/<[^>]+>/, "").strip : ""
end

# {markup, attribute name} => values, for `name="value"` with no spaces
# around the equals sign.
private ATTR_VALUE_EXAMPLES = {
  [%(<button aria-label="Close" data-x="1">), "aria-label"] => ["Close"],
  [%(<input disabled>), "disabled"]                         => [""],
  [%(<input disabled aria-label='Name'>), "aria-label"]     => ["Name"],
  [%(<a hidden><b hidden class="x"></b></a>), "hidden"]     => ["", ""],
  [%(<div data-a="1" data-a="2" data-a='3'>), "data-a"]     => ["1", "2", "3"],
  [%(data-a="1"\ndata-a="2" ), "data-a"]                    => ["1", "2"],
  [%(<div data-a="1"x data-a="2">), "data-a"]               => ["2"],
  [%(<div xdata-a="1" data-ab="2">), "data-a"]              => [] of String,
  [%(<div title="x data-a y" data-a="z">), "data-a"]        => ["", "z"],
  [%(<div data-a>), "data-a"]                               => [""],
  [%(<div data-a=>), "data-a"]                              => [] of String,
  [%(<div data-a = "1">), "data-a"]                         => [""],
  [%(<div data.a="1" dataXa="2">), "data.a"]                => ["1"],
  [%(<div data-a="é" data-a="">), "data-a"]                 => ["é", ""],
  ["", "data-a"]                                            => [] of String,
  ["data-a", "data-a"]                                      => [] of String,
  ["data-a ", "data-a"]                                     => [""],
}

# The same, where spaces may surround the equals sign.
private SPACED_ATTR_VALUE_EXAMPLES = {
  [%(<div data-a = "1" data-a= '2' data-a ="3">), "data-a"] => ["1", "2", "3"],
  [%(<div data-a ="1"x>), "data-a"]                         => [""],
  [%(<div data-a="1"x>), "data-a"]                          => [] of String,
  [%(<div data-a\n=\n"1">), "data-a"]                       => ["1"],
  [%(<input disabled >), "disabled"]                        => [""],
}

# {markup, id} => text of the element.
private ELEMENT_TEXT_EXAMPLES = {
  [%(<p id="a">Hello</p>), "a"]                                  => "Hello",
  [%(<p class="x" id="a" data-y>Hello <b>there</b></p>), "a"]    => "Hello there",
  [%(<div id="a">\n  line one\n  <span>two</span>\n</div>), "a"] => "line one\n  two",
  [%(<p id="b">no</p><p id="a">yes</p>), "a"]                    => "yes",
  [%(<my-tag id="a">custom</my-tag>), "a"]                       => "custom",
  [%(<my-tag id="a">prefix</my>), "a"]                           => "prefix",
  [%(<p id="a">never closed<div id="a">second</div>), "a"]       => "second",
  [%(<p id="a">first</p><p id="a">second</p>), "a"]              => "first",
  [%(<div id="a"><div>inner</div>outer</div>), "a"]              => "inner",
  [%(<p id="a.b">dotted</p><p id="axb">other</p>), "a.b"]        => "dotted",
  [%(<p id="a"></p>), "a"]                                       => "",
  [%(<p id='a'>single</p>), "a"]                                 => "",
  [%(<p xid="a">no</p>), "a"]                                    => "",
  [%(<P id="a">upper</p>), "a"]                                  => "",
  ["", "a"]                                                      => "",
}

describe SpecSupport::HtmlScanning do
  describe ".attr_values" do
    it "reads the value of every occurrence of an attribute" do
      ATTR_VALUE_EXAMPLES.each do |(html, name), list_of_values|
        Scanning.attr_values(html, name).should eq(list_of_values), "for #{name} in #{html.inspect}"
      end
    end

    it "reads values with spaces around the equals sign when asked to" do
      (ATTR_VALUE_EXAMPLES.reject { |(html, _), _| html.includes?(" = ") }.to_a + SPACED_ATTR_VALUE_EXAMPLES.to_a).each do |(html, name), list_of_values|
        Scanning.attr_values(html, name, spaces_around_equals: true).should eq(list_of_values), "for #{name} in #{html.inspect}"
      end
    end

    it "answers as the lookahead patterns it replaced" do
      count_of_compared_examples = 0
      ATTR_VALUE_EXAMPLES.each do |(html, name), list_of_values|
        reference = reference_attr_values(html, name, "=")
        next unless reference
        reference.should eq(list_of_values), "for #{name} in #{html.inspect}"
        count_of_compared_examples += 1
      end
      (ATTR_VALUE_EXAMPLES.to_a + SPACED_ATTR_VALUE_EXAMPLES.to_a).each do |(html, name), _|
        reference = reference_attr_values(html, name, %q{\s*=\s*})
        next unless reference
        Scanning.attr_values(html, name, spaces_around_equals: true).should eq(reference), "for #{name} in #{html.inspect}"
        count_of_compared_examples += 1
      end
      pending!("this Regex engine does not run lookahead; build with -Duse_pcre2") if count_of_compared_examples == 0
    end
  end

  describe ".element_text_by_id" do
    it "reads the text of the first element with the id and a closing tag of its name" do
      ELEMENT_TEXT_EXAMPLES.each do |(html, id), text|
        Scanning.element_text_by_id(html, id).should eq(text), "for #{id} in #{html.inspect}"
      end
    end

    it "reads an id in single quotes when asked to" do
      Scanning.element_text_by_id(%(<p id='a'>single</p>), "a", either_quote: true).should eq("single")
      Scanning.element_text_by_id(%(<p id="a">double</p>), "a", either_quote: true).should eq("double")
    end

    it "answers as the backreference patterns it replaced" do
      count_of_compared_examples = 0
      ELEMENT_TEXT_EXAMPLES.each do |(html, id), text|
        escaped_id = Regex.escape(id)
        reference = reference_element_text(html, id, %("#{escaped_id}"))
        next unless reference
        reference.should eq(text), "for #{id} in #{html.inspect}"
        reference_for_either_quote = reference_element_text(html, id, %((?:"#{escaped_id}"|'#{escaped_id}')))
        Scanning.element_text_by_id(html, id, either_quote: true).should eq(reference_for_either_quote), "for #{id} in #{html.inspect}"
        count_of_compared_examples += 1
      end
      pending!("this Regex engine does not run backreferences; build with -Duse_pcre2") if count_of_compared_examples == 0
    end
  end
end
