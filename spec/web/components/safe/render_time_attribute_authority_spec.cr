require "../../spec_helper"
require "../../../../src/components/elements/grouping/div"
require "../../../../src/components/elements/text/a"
require "../../../../src/components/elements/embedded/media"
require "../../../../src/components/elements/forms/form"

# SafeHTML v1 — the render-time validation authority (docs/SAFE_HTML_V1.md
# §3.7). Five prior gates on this branch each closed exactly the one
# `set_attribute`-time bypass an adversarial pass happened to find that
# round (a malformed name, a case-varied `href`, a `<script>` child, a
# case-varied `srcdoc`). Every one of those was a *point*-fix at
# `set_attribute`. The GENERAL root cause a later gate found: `attributes`
# is a PUBLIC, MUTABLE `getter` (`Hash(String, String)`) — nothing stops
# `element.attributes["SRCDOC"] = "<script>...</script>"`, or any other
# case/whitespace-varied key, from mutating the live Hash directly,
# completely bypassing `set_attribute` and therefore every check that used
# to live only there.
#
# `HTMLElement#render_attributes` is the one place every attribute,
# regardless of how it entered `@attributes`, is turned into bytes. This
# suite proves that a DIRECT mutation of the public `attributes` Hash —
# not `set_attribute`, not a constructor kwarg — is still neutralized,
# because the full validation suite ((a) name grammar, (b) `on*` ban, (c)
# `SafeURL`, (d) HTML-document-valued attributes) now runs there too, keyed
# by `name.strip.downcase`, against whatever is CURRENTLY in the Hash.
describe "SafeHTML v1 — render-time attribute validation authority (docs/SAFE_HTML_V1.md §3.7)" do
  describe "adversarial: direct @attributes mutation bypassing set_attribute entirely" do
    it "(a) a forbidden-character name (leading solidus) written directly is neutralized at render, even though set_attribute was never called" do
      a = Components::Elements::A.new
      # Bypasses `set_attribute` -> `validate_attribute_name!` completely.
      a.attributes["/href"] = "javascript:alert(document.cookie)"

      expect_raises(ArgumentError, /SafeHTML ban/) do
        a.render
      end
    end

    it "(b) an on*-shaped name, case-varied, written directly is neutralized at render" do
      div = Components::Elements::Div.new
      div.attributes["OnClick"] = "alert(document.cookie)"

      expect_raises(ArgumentError, "inline event-handler attribute") do
        div.render
      end
    end

    it "(b) an on*-shaped name, whitespace inside it, is caught by the name-grammar check first (still neutralized)" do
      div = Components::Elements::Div.new
      div.attributes["x onload"] = "alert(1)"

      expect_raises(ArgumentError, /SafeHTML ban/) do
        div.render
      end
    end

    it "(c) a javascript: href written directly (any casing) is neutralized at render, even though it never touched SafeURL via set_attribute" do
      a = Components::Elements::A.new
      a.attributes["HREF"] = "javascript:alert(document.cookie)"

      expect_raises(ArgumentError, /SafeHTML ban/) do
        a.render
      end
    end

    it "(c) a javascript: href written directly with the plain-lowercase key is neutralized at render too" do
      a = Components::Elements::A.new
      a.attributes["href"] = "javascript:alert(document.cookie)"

      expect_raises(ArgumentError, /SafeHTML ban/) do
        a.render
      end
    end

    it "(c) a javascript: action written directly on Form is neutralized at render" do
      form = Components::Elements::Form.new
      form.attributes["ACTION"] = "javascript:alert(document.cookie)"

      expect_raises(ArgumentError, /SafeHTML ban/) do
        form.render
      end
    end

    it "(c) a data: URI written directly into Object#data (case-varied key) is neutralized at render — Object#data is unconditionally script-executing, no user interaction required, unlike href/action/formaction" do
      obj = Components::Elements::Object.new
      obj.attributes["DATA"] = "data:text/html,<script>alert(document.cookie)</script>"

      expect_raises(ArgumentError, /SafeHTML ban/) do
        obj.render
      end
    end

    it "(d) a case-varied srcdoc key written directly on Iframe is neutralized at render, independent of any legitimately-vouched srcdoc key" do
      iframe = Components::Elements::Iframe.new
      iframe.attributes["SRCDOC"] = "<script>alert(document.cookie)</script>"

      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        iframe.render
      end
    end

    it "(d) a whitespace-padded srcdoc key written directly on Iframe is neutralized at render (caught even earlier, by the (a) name-grammar check — whitespace is forbidden in any attribute name, so this never even reaches the document-sink check)" do
      iframe = Components::Elements::Iframe.new
      iframe.attributes[" srcdoc"] = "<script>alert(document.cookie)</script>"

      expect_raises(ArgumentError, /SafeHTML ban/) do
        iframe.render
      end
    end

    it "(d) a case-varied srcdoc key written directly ALONGSIDE an already-legitimately-vouched srcdoc is still caught (two distinct Hash entries, both checked)" do
      iframe = Components::Elements::Iframe.srcdoc("<p>legit</p>", reason: "spec: legitimate static content")
      # A different-CASED key is a *different* entry in the Hash(String,
      # String) — this does not overwrite the legitimately-vouched
      # "srcdoc" entry, it adds a second, attacker-controlled one. Both are
      # checked at render; the attacker's must still raise.
      iframe.attributes["SRCDOC"] = "<script>alert(document.cookie)</script>"

      expect_raises(ArgumentError, /HTML-DOCUMENT-valued attribute/) do
        iframe.render
      end
    end

    it "none of the above payloads ever appear in rendered output" do
      a = Components::Elements::A.new
      a.attributes["HREF"] = "javascript:alert(document.cookie)"
      rendered = begin
        a.render
      rescue ArgumentError
        "<a></a>"
      end
      rendered.should_not contain("javascript:")

      iframe = Components::Elements::Iframe.new
      iframe.attributes["SRCDOC"] = "<script>alert(document.cookie)</script>"
      rendered_iframe = begin
        iframe.render
      rescue ArgumentError
        "<iframe></iframe>"
      end
      rendered_iframe.should_not contain("<script>alert(document.cookie)</script>")
    end
  end

  describe "legit attributes and URLs still render, unaffected by the render-time authority" do
    it "an ordinary Div with plain attributes renders exactly as before" do
      div = Components::Elements::Div.new(id: "panel", class: "card", "data-x": "1")
      div.render.should eq(%(<div id="panel" class="card" data-x="1"></div>))
    end

    it "an ordinary https href on A renders unchanged, whether set via kwarg or direct mutation" do
      a1 = Components::Elements::A.new(href: "https://example.com/path")
      a1.render.should eq(%(<a href="https://example.com/path"></a>))

      a2 = Components::Elements::A.new
      a2.attributes["href"] = "https://example.com/other"
      a2.render.should eq(%(<a href="https://example.com/other"></a>))
    end

    it "a legitimately-vouched srcdoc renders unchanged" do
      iframe = Components::Elements::Iframe.srcdoc("<p>Hello</p>", reason: "spec: static content")
      iframe.render.should eq(%(<iframe srcdoc="&lt;p&gt;Hello&lt;/p&gt;"></iframe>))
    end

    it "a normal relative form action renders unchanged" do
      form = Components::Elements::Form.new(action: "/submit", method: "POST")
      form.render.should contain(%(action="/submit"))
    end
  end
end
