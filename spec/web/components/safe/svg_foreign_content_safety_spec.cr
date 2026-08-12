require "../../spec_helper"
require "../../../../src/components/elements/embedded/media"
require "../../../../src/components/elements/document/title"

# SafeHTML v1 -- <svg> foreign-content text-node ban (docs/SAFE_HTML_V1.md
# §3.6). `<svg>` is HTML5 "foreign content": the tokenizer switches
# namespace inside it, but a <script> element inside that namespace is
# still recognized and STILL EXECUTES --
# `<svg><script>alert(1)</script></svg>` is a well-known, browser-verified
# XSS payload class, reachable inline in an ordinary HTML document (not
# just a standalone .svg file). Before this fix, `Svg#render_children`
# passed every String child through completely unescaped ("SVG content is
# not escaped like HTML") -- exactly as dangerous as `<script>` accepting a
# plain-String child.
describe "SafeHTML v1 -- <svg> foreign-content text-node ban" do
  describe "adversarial: a String child is HTML-escaped like any other element's text node" do
    it "a <script> breakout no longer survives as a live element" do
      svg = Components::Elements::Svg.new
      svg << "<script>alert(document.cookie)</script>"

      rendered = svg.render
      rendered.should_not contain("<script>alert(document.cookie)</script>")
      rendered.should contain("&lt;script&gt;alert(document.cookie)&lt;/script&gt;")
    end

    it "an <image> href-based breakout attempt is also neutralized as text" do
      svg = Components::Elements::Svg.new
      svg << %(<image href="x" onerror="alert(1)"/>)

      rendered = svg.render
      rendered.should_not contain(%(<image href="x" onerror="alert(1)"/>))
      rendered.should contain("&lt;image")
    end

    it "ordinary text content still round-trips correctly (not just breakout payloads)" do
      svg = Components::Elements::Svg.new
      svg << "just some text"
      svg.render.should eq("<svg>just some text</svg>")
    end
  end

  describe "legitimate hand-authored SVG markup still works, via the same documented raw door every other element uses" do
    it "a RawHTML-wrapped child renders unescaped, exactly like Script.static/RawHTML elsewhere in this shard" do
      svg = Components::Elements::Svg.new
      svg << Components::Elements::RawHTML.new(%(<path d="M0 0 L10 10" fill="red"/>))
      svg.render.should eq(%(<svg><path d="M0 0 L10 10" fill="red"/></svg>))
    end

    it "add_raw_html works the same way (the pre-existing, greppable raw door)" do
      svg = Components::Elements::Svg.new
      svg.add_raw_html(%(<circle cx="5" cy="5" r="4"/>))
      svg.render.should eq(%(<svg><circle cx="5" cy="5" r="4"/></svg>))
    end
  end

  describe "nested HTMLElement children (not raw strings) are unaffected -- they were never the bug" do
    it "a real element child still renders through its own safe render path" do
      svg = Components::Elements::Svg.new
      title = Components::Elements::Title.new
      title << "Accessible title"
      svg.add_child(title)
      svg.render.should eq("<svg><title>Accessible title</title></svg>")
    end
  end
end
