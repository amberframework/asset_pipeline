require "../../spec_helper"
require "../../../../src/components/safe/safe_buffer"
require "../../../../src/components/elements/grouping/div"
require "../../../../src/components/base/stateless_component"

describe Components::SafeBuffer do
  describe "the load-bearing rule: String always means text" do
    it "escapes a plain String append" do
      buf = Components::SafeBuffer.new
      buf << "<script>alert(1)</script>"
      buf.to_safe_html.to_s.should eq("&lt;script&gt;alert(1)&lt;/script&gt;")
    end

    it "escapes a String that merely LOOKS like markup — the intended cosmetic-bug failure mode" do
      buf = Components::SafeBuffer.new
      buf << "<b>bold</b>"
      # The whole literal is escaped — a visible bug, not a silent hole
      # (proposal §3.2 point 3 / docs/SAFE_HTML_V1.md).
      buf.to_safe_html.to_s.should eq("&lt;b&gt;bold&lt;/b&gt;")
    end
  end

  describe "structure comes from already-safe values, passed through verbatim" do
    it "passes through a SafeHTML value without re-escaping" do
      buf = Components::SafeBuffer.new
      buf << Components::SafeHTML.escape("<b>")
      buf.to_safe_html.to_s.should eq("&lt;b&gt;")
    end

    it "passes through an Elements::HTMLElement's own (already-escaped) render" do
      div = Components::Elements::Div.new(class: "x")
      div << "<script>evil</script>"

      buf = Components::SafeBuffer.new
      buf << div
      buf.to_safe_html.to_s.should eq(%(<div class="x">&lt;script&gt;evil&lt;/script&gt;</div>))
    end

    it "passes through an Elements::RawHTML wrapper verbatim" do
      buf = Components::SafeBuffer.new
      buf << Components::Elements::RawHTML.new("<em>trusted</em>")
      buf.to_safe_html.to_s.should eq("<em>trusted</em>")
    end
  end

  describe "mixed construction" do
    it "escapes text and passes through markup in the same buffer" do
      buf = Components::SafeBuffer.new
      buf << "Hello, "
      buf << Components::SafeHTML.escape("<stranger>")
      buf << "!"
      buf.to_safe_html.to_s.should eq("Hello, &lt;stranger&gt;!")
    end
  end
end
