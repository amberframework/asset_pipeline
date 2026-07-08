require "../../spec_helper"
require "../../../../src/components/elements/embedded/media"

# SafeHTML v1 -- <iframe srcdoc> HTML-document-valued attribute ban
# (docs/SAFE_HTML_V1.md §3.5). `srcdoc` is not a plain attribute value: the
# browser HTML-entity-decodes it and re-parses the decoded result as the
# entire source document of the iframe's nested browsing context, so
# ordinary attribute-value escaping (which protects the *outer* document's
# parse) does nothing to stop a <script> inside the decoded value from
# executing. This mirrors the <script>-body ban (script_element_safety_spec)
# but on an attribute instead of element children.
describe "SafeHTML v1 -- <iframe srcdoc> HTML-document-valued attribute ban" do
  breakout = %(<script>alert(document.cookie)</script>)

  describe "adversarial: a bare String srcdoc is rejected, regardless of content" do
    it "path 1 (constructor kwarg): rejected at construction time" do
      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        Components::Elements::Iframe.new(srcdoc: breakout)
      end
    end

    it "path 1b: rejected even for content that looks harmless" do
      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        Components::Elements::Iframe.new(srcdoc: "<p>hi</p>")
      end
    end

    it "path 2 (#set_attribute, the dynamic/runtime path): rejected at call time" do
      iframe = Components::Elements::Iframe.new
      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        iframe.set_attribute("srcdoc", breakout)
      end
      # The attribute was never set -- no half-applied state.
      iframe["srcdoc"].should be_nil
      iframe.render.should eq("<iframe></iframe>")
    end

    it "adversarial: case/whitespace variants of the name are caught too (matching UrlAttributeValidation's own normalization)" do
      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        Components::Elements::Iframe.new("SRCDOC": breakout)
      end

      iframe = Components::Elements::Iframe.new
      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        iframe.set_attribute(" srcdoc ", breakout)
      end
    end

    it "the breakout payload never appears in any rendered output" do
      iframe = Components::Elements::Iframe.new
      begin
        iframe.set_attribute("srcdoc", breakout)
      rescue ArgumentError
      end
      iframe.render.should_not contain("alert(document.cookie)")
    end

    it "path 3 (direct `attributes[...] = ...` mutation via the public getter): closed at RENDER time" do
      iframe = Components::Elements::Iframe.new
      # `attributes` is a public, mutable `getter` -- nothing stops this at
      # call time, which is exactly why the render-time backstop exists.
      iframe.attributes["srcdoc"] = breakout

      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        iframe.render
      end
    end

    it "path 3b: a direct mutation that overwrites an already-vouched srcdoc is also caught at render time" do
      iframe = Components::Elements::Iframe.srcdoc("<p>legit</p>", reason: "spec: legitimate static content")
      # Swap the vouched value out for attacker content directly through
      # the Hash, after vouching already happened once.
      iframe.attributes["srcdoc"] = breakout

      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        iframe.render
      end
    end
  end

  describe "the two legitimate doors" do
    it "Iframe.srcdoc (class-level, matches Script.static) requires a reason and renders the HTML, escaped for the outer document like any other attribute value" do
      # The vouched HTML still goes through the ordinary attribute-value
      # escaping every attribute gets -- that's what keeps the *outer*
      # document well-formed. The browser HTML-entity-DEcodes the value
      # back before using it as the nested document's source, so this is a
      # lossless round-trip, not double-escaping content into the nested
      # document.
      iframe = Components::Elements::Iframe.srcdoc("<p>Hello</p>", reason: "spec: static author-authored HTML")
      iframe.render.should eq(%(<iframe srcdoc="&lt;p&gt;Hello&lt;/p&gt;"></iframe>))
    end

    it "Iframe.srcdoc requires a non-empty reason" do
      expect_raises(ArgumentError, "requires a non-empty") do
        Components::Elements::Iframe.srcdoc("<p>Hello</p>", reason: "")
      end
    end

    it "Iframe.srcdoc still accepts and validates other constructor kwargs" do
      iframe = Components::Elements::Iframe.srcdoc("<p>Hi</p>", reason: "spec", title: "preview", loading: "lazy")
      rendered = iframe.render
      rendered.should contain(%(title="preview"))
      rendered.should contain(%(loading="lazy"))
    end

    it "#set_srcdoc (instance-level, for an already-constructed Iframe -- the shape the live web_renderer.cr call site needs) requires a reason and renders the HTML, escaped for the outer document" do
      iframe = Components::Elements::Iframe.new
      iframe.set_attribute("loading", "lazy")
      iframe.set_srcdoc("<p>Hello</p>", reason: "spec: static author-authored HTML")
      rendered = iframe.render
      rendered.should contain(%(loading="lazy"))
      rendered.should contain(%(srcdoc="&lt;p&gt;Hello&lt;/p&gt;"))
    end

    it "#set_srcdoc requires a non-empty reason" do
      iframe = Components::Elements::Iframe.new
      expect_raises(ArgumentError, "requires a non-empty") do
        iframe.set_srcdoc("<p>Hello</p>", reason: "")
      end
    end

    it "#set_srcdoc round-trips through the outer document's attribute escaping (quotes/angle-brackets in the vouched HTML are escaped, not dropped or double-escaped)" do
      iframe = Components::Elements::Iframe.new
      iframe.set_srcdoc(%(<p class="x">Hi</p>), reason: "spec")
      iframe.render.should contain(%(srcdoc="&lt;p class=&quot;x&quot;&gt;Hi&lt;/p&gt;"))
    end
  end

  describe "src (the other Iframe URL sink) is unaffected by the srcdoc ban" do
    it "src and srcdoc can both be set on the same element via their respective typed/validated paths" do
      iframe = Components::Elements::Iframe.new(src: "https://example.com/fallback")
      iframe.set_srcdoc("<p>Hi</p>", reason: "spec")
      rendered = iframe.render
      rendered.should contain(%(src="https://example.com/fallback"))
      rendered.should contain(%(srcdoc="&lt;p&gt;Hi&lt;/p&gt;"))
    end

    it "a javascript: src is still rejected independently of srcdoc" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Iframe.new(src: "javascript:alert(1)")
      end
    end
  end
end
