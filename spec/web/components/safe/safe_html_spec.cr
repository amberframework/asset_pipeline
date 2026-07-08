require "../../spec_helper"
require "../../../../src/components/safe/safe_html"

describe Components::SafeHTML do
  describe ".escape" do
    it "HTML-escapes text and wraps it as safe" do
      safe = Components::SafeHTML.escape(%(<script>alert(1)</script>))
      safe.to_s.should eq("&lt;script&gt;alert(1)&lt;/script&gt;")
    end

    it "escapes the five standard HTML metacharacters" do
      safe = Components::SafeHTML.escape(%(& < > " '))
      safe.to_s.should eq("&amp; &lt; &gt; &quot; &#39;")
    end

    it "round-trips ordinary text unchanged" do
      Components::SafeHTML.escape("hello world").to_s.should eq("hello world")
    end
  end

  describe ".join" do
    it "concatenates SafeHTML values without re-escaping" do
      a = Components::SafeHTML.escape("<b>")
      b = Components::SafeHTML.escape("</b>")
      Components::SafeHTML.join(a, b).to_s.should eq("&lt;b&gt;&lt;/b&gt;")
    end

    it "accepts an Enumerable of SafeHTML" do
      parts = [Components::SafeHTML.escape("a"), Components::SafeHTML.escape("b")]
      Components::SafeHTML.join(parts).to_s.should eq("ab")
    end
  end

  describe ".unsafe / raw" do
    it "wraps a string verbatim (no escaping) when a reason is given" do
      safe = Components::SafeHTML.unsafe("<b>trusted</b>", reason: "spec: literal trusted markup")
      safe.to_s.should eq("<b>trusted</b>")
    end

    it "requires a non-empty reason (falsifiability: the loud door demands a reason)" do
      expect_raises(ArgumentError, "requires a non-empty") do
        Components::SafeHTML.unsafe("<b>x</b>", reason: "")
      end
    end

    it "requires a non-blank (whitespace-only) reason" do
      expect_raises(ArgumentError, "requires a non-empty") do
        Components::SafeHTML.unsafe("<b>x</b>", reason: "   ")
      end
    end

    it "the top-level Components.raw is identical to SafeHTML.unsafe" do
      safe = Components.raw("<b>x</b>", reason: "spec: raw() alias")
      safe.to_s.should eq("<b>x</b>")
    end
  end

  describe "falsifiability: there is no public SafeHTML.new" do
    it "documents the compile-time guarantee (see comment) — cannot be expressed as a runtime spec" do
      # The following does NOT compile if uncommented, and that is the point:
      #
      #   Components::SafeHTML.new("<script>alert(1)</script>")
      #   # => Error: protected method 'new' called for Components::SafeHTML.class
      #
      # `initialize` is `protected` (safe_html.cr), so the compiler-generated
      # `.new` is protected too. There is no way, from outside the
      # `Components` namespace, to mint a `SafeHTML` from an arbitrary
      # String without going through `.escape`, `.join`, or the loud,
      # reason-requiring `.unsafe` / `raw(...)`. This spec exists so the
      # guarantee has a named, greppable anchor even though Crystal specs
      # cannot assert "this fails to compile" at runtime.
      true.should be_true
    end
  end

  describe "String-like spec-compatibility surface" do
    it "supports contain/eq/start_with/end_with matchers" do
      safe = Components::SafeHTML.escape("hello <b>world</b>")
      safe.should contain("hello")
      safe.should eq("hello &lt;b&gt;world&lt;/b&gt;")
      safe.should start_with("hello")
      safe.should end_with("&gt;")
    end

    it "supports empty? and size" do
      Components::SafeHTML::EMPTY.empty?.should be_true
      Components::SafeHTML.escape("abc").size.should eq(3)
    end
  end

  describe "#to_raw_html" do
    it "converts to an Elements::RawHTML carrying the same bytes" do
      safe = Components::SafeHTML.escape("<b>")
      safe.to_raw_html.render.should eq("&lt;b&gt;")
    end
  end

  describe "#to_json" do
    it "serializes as a plain JSON string of the safe bytes" do
      safe = Components::SafeHTML.unsafe(%(<script>x</script>), reason: "spec: json embedding")
      safe.to_json.should eq(%("<script>x</script>"))
    end
  end
end
