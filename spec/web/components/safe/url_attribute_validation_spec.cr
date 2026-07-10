require "../../spec_helper"
require "../../../../src/components/elements/text/a"
require "../../../../src/components/elements/document/link"
require "../../../../src/components/elements/embedded/img"
require "../../../../src/components/elements/document/script"
require "../../../../src/components/elements/embedded/media"
require "../../../../src/components/elements/void/void_elements"
require "../../../../src/components/elements/forms/form"
require "../../../../src/components/elements/forms/form_controls"
require "../../../../src/components/elements/forms/input"

# SafeHTML v1 — construction/#set_attribute-time SafeURL enforcement on
# link/src-bearing elements (docs/SAFE_HTML_V1.md §3.2). Before this fix,
# `href`/`src`/`action` reached these elements as a plain, unvalidated
# String through BOTH of the paths exercised below, and `render_attributes`
# escapes quotes/angle-brackets but does nothing to neutralize a
# `javascript:`/`vbscript:`/`data:` *scheme* -- HTML-escaping is the wrong
# tool for a URL-scheme sink.
describe "SafeHTML v1 — SafeURL enforcement on link/src-bearing elements" do
  describe Components::Elements::A do
    it "adversarial: rejects javascript: via the constructor kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::A.new(href: "javascript:alert(document.cookie)")
      end
    end

    it "adversarial: rejects javascript: via #set_attribute (the dynamic/runtime path)" do
      a = Components::Elements::A.new
      expect_raises(ArgumentError, /SafeHTML ban/) do
        a.set_attribute("href", "javascript:alert(document.cookie)")
      end
      # The attribute was never set -- no half-applied state.
      a["href"].should be_nil
    end

    it "adversarial: rejects vbscript: and data: the same way" do
      expect_raises(ArgumentError) { Components::Elements::A.new(href: "vbscript:msgbox(1)") }
      expect_raises(ArgumentError) { Components::Elements::A.new(href: "data:text/html,<script>alert(1)</script>") }
    end

    it "adversarial: defeats the java\\tscript: control-character bypass" do
      expect_raises(ArgumentError) do
        Components::Elements::A.new(href: "java\tscript:alert(1)")
      end
    end

    it "the classic breakout payload never reaches rendered output" do
      a = Components::Elements::A.new
      begin
        a.set_attribute("href", "javascript:alert(document.cookie)")
      rescue ArgumentError
      end
      a.render.should_not contain("javascript:")
    end

    it "allows an ordinary https URL through both paths, unchanged" do
      a1 = Components::Elements::A.new(href: "https://example.com/path")
      a1.render.should eq(%(<a href="https://example.com/path"></a>))

      a2 = Components::Elements::A.new
      a2.set_attribute("href", "/relative/path")
      a2.render.should eq(%(<a href="/relative/path"></a>))
    end

    it "other attributes on A are completely unaffected by the href check" do
      a = Components::Elements::A.new(target: "_blank", rel: "noopener")
      a["target"].should eq("_blank")
    end
  end

  describe Components::Elements::Link do
    it "adversarial: rejects a javascript: href on <link>" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Link.new(rel: "stylesheet", href: "javascript:alert(1)")
      end
    end

    it "allows a normal stylesheet href" do
      Components::Elements::Link.stylesheet("/assets/app.css").render
        .should eq(%(<link rel="stylesheet" href="/assets/app.css">))
    end
  end

  describe Components::Elements::Img do
    it "adversarial: rejects a javascript: src via constructor kwarg" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Img.new(src: "javascript:alert(1)")
      end
    end

    it "adversarial: rejects a javascript: src via #set_attribute" do
      img = Components::Elements::Img.new
      expect_raises(ArgumentError, /SafeHTML ban/) do
        img.set_attribute("src", "javascript:alert(1)")
      end
    end

    it "allows an ordinary relative image src" do
      img = Components::Elements::Img.new(src: "photo.jpg", alt: "a photo")
      img.render.should eq(%(<img src="photo.jpg" alt="a photo">))
    end
  end

  describe Components::Elements::Script do
    it "adversarial: rejects a javascript: src for an external script" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Script.new(src: "javascript:alert(1)")
      end
    end

    it "allows an ordinary external script src" do
      Components::Elements::Script.new(src: "/assets/app.js").render
        .should eq(%(<script src="/assets/app.js"></script>))
    end
  end

  describe Components::Elements::Iframe do
    it "adversarial: rejects a javascript: src (the highest-value src sink -- a whole nested browsing context)" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Iframe.new(src: "javascript:alert(document.domain)")
      end
    end

    it "allows an ordinary https src" do
      Components::Elements::Iframe.new(src: "https://example.com/embed").render
        .should eq(%(<iframe src="https://example.com/embed"></iframe>))
    end
  end

  describe Components::Elements::Video do
    it "adversarial: rejects a javascript: src" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Video.new(src: "javascript:alert(1)")
      end
    end

    it "adversarial: rejects a javascript: poster (the preview-frame image, a distinct sink from src)" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Video.new(poster: "javascript:alert(1)")
      end
    end
  end

  describe Components::Elements::Audio do
    it "adversarial: rejects a javascript: src" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Audio.new(src: "javascript:alert(1)")
      end
    end
  end

  describe Components::Elements::Source do
    it "adversarial: rejects a javascript: src" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Source.new(src: "javascript:alert(1)")
      end
    end
  end

  describe Components::Elements::Track do
    it "adversarial: rejects a javascript: src" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Track.new(src: "javascript:alert(1)")
      end
    end
  end

  describe Components::Elements::Embed do
    it "adversarial: rejects a javascript: src" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Embed.new(src: "javascript:alert(1)")
      end
    end
  end

  describe Components::Elements::Area do
    it "adversarial: rejects a javascript: href" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Area.new(href: "javascript:alert(1)")
      end
    end
  end

  describe Components::Elements::Base do
    it "adversarial: rejects a javascript: href" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Base.new(href: "javascript:alert(1)")
      end
    end
  end

  describe Components::Elements::Object do
    # SafeHTML v1 §8(d), closed 2026-07-08: `data` loads a resource into a
    # child navigable and renders it as an embedded HTML document,
    # executing any `<script>` inside — unconditionally, no user
    # interaction required (the same severity tier as `srcdoc`/`<svg>`/
    # `<style>` body, not the "requires a click" tier `href`/`action`/
    # `formaction` occupy). Confirmed by a Codex xhigh adversarial pass
    # during the render-time-authority re-gate.
    it "adversarial: rejects a javascript: data via constructor kwarg" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Object.new(data: "javascript:alert(1)")
      end
    end

    it "adversarial: rejects a data: URI carrying an inline HTML document with a <script>, via constructor kwarg" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Object.new(data: "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==")
      end
    end

    it "adversarial: rejects a data: URI via #set_attribute" do
      obj = Components::Elements::Object.new
      expect_raises(ArgumentError, /SafeHTML ban/) do
        obj.set_attribute("data", "data:text/html,<script>alert(1)</script>")
      end
      obj["data"].should be_nil
    end

    it "adversarial: rejects a case-varied DATA via the constructor-kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Object.new("DATA": "data:text/html,<script>alert(1)</script>")
      end
    end

    it "the breakout payload never appears in any rendered output" do
      obj = Components::Elements::Object.new
      begin
        obj.set_attribute("data", "data:text/html,<script>alert(document.cookie)</script>")
      rescue ArgumentError
      end
      obj.render.should_not contain("<script>alert(document.cookie)</script>")
    end

    it "allows an ordinary https data URL through both paths, unchanged" do
      obj1 = Components::Elements::Object.new(data: "https://example.com/embed.pdf", type: "application/pdf")
      obj1.render.should eq(%(<object data="https://example.com/embed.pdf" type="application/pdf"></object>))

      obj2 = Components::Elements::Object.new
      obj2.set_attribute("data", "/assets/embed.pdf")
      obj2["data"].should eq("/assets/embed.pdf")
    end
  end

  describe Components::Elements::Form do
    it "adversarial: rejects a javascript: action" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Form.new(action: "javascript:alert(document.cookie)")
      end
    end

    it "adversarial: rejects a javascript: action via #set_attribute" do
      form = Components::Elements::Form.new(method: "POST")
      expect_raises(ArgumentError, /SafeHTML ban/) do
        form.set_attribute("action", "javascript:alert(1)")
      end
    end

    it "allows an ordinary relative form action, matching every existing web_renderer.cr call site" do
      form = Components::Elements::Form.new(action: "/submit", method: "POST")
      form.render.should contain(%(action="/submit"))
    end
  end

  describe Components::Elements::Button do
    # SafeHTML v1 §3.10, closed 2026-07-08: `formaction` (on a
    # `type="submit"`/`type="image"` button) overrides the owning
    # `<form>`'s `action` for that one submitter -- a `javascript:`
    # `formaction` is evaluated as a classic script by the navigation
    # algorithm once the button submits its form, the exact same sink
    # `Form#action` already closed. `Button` previously did not `include
    # UrlAttributeValidation` at all, so `formaction` was reachable,
    # entirely unvalidated, through both paths exercised below.
    it "adversarial: rejects a javascript: formaction via the constructor kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Button.new(type: "submit", formaction: "javascript:alert(document.cookie)")
      end
    end

    it "adversarial: rejects a data: formaction via the constructor kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Button.new(type: "submit", formaction: "data:text/html,<script>alert(1)</script>")
      end
    end

    it "adversarial: rejects a vbscript: formaction via the constructor kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Button.new(type: "submit", formaction: "vbscript:msgbox(1)")
      end
    end

    it "adversarial: rejects a javascript: formaction via #set_attribute" do
      button = Components::Elements::Button.new(type: "submit")
      expect_raises(ArgumentError, /SafeHTML ban/) do
        button.set_attribute("formaction", "javascript:alert(document.cookie)")
      end
      button["formaction"].should be_nil
    end

    it "the breakout payload never appears in any rendered output" do
      button = Components::Elements::Button.new(type: "submit")
      begin
        button.set_attribute("formaction", "javascript:alert(document.cookie)")
      rescue ArgumentError
      end
      button.render.should_not contain("javascript:")
    end

    it "allows an ordinary https/relative formaction through both paths, unchanged" do
      button1 = Components::Elements::Button.new(type: "submit", formaction: "https://example.com/submit")
      button1.render.should eq(%(<button type="submit" formaction="https://example.com/submit"></button>))

      button2 = Components::Elements::Button.new(type: "submit")
      button2.set_attribute("formaction", "/alt-submit")
      button2["formaction"].should eq("/alt-submit")
    end

    it "other attributes on Button are completely unaffected by the formaction check" do
      button = Components::Elements::Button.new(type: "submit", name: "action", value: "save")
      button["value"].should eq("save")
    end
  end

  describe Components::Elements::Input do
    # SafeHTML v1 §3.10, closed 2026-07-08 -- see the Button block above
    # for the full rationale; `Input` (a `type="submit"`/`type="image"`
    # input) shares the exact same `formaction` sink.
    it "adversarial: rejects a javascript: formaction via the constructor kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Input.new(type: "submit", formaction: "javascript:alert(document.cookie)")
      end
    end

    it "adversarial: rejects a data: formaction via the constructor kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Input.new(type: "submit", formaction: "data:text/html,<script>alert(1)</script>")
      end
    end

    it "adversarial: rejects a vbscript: formaction via the constructor kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Input.new(type: "submit", formaction: "vbscript:msgbox(1)")
      end
    end

    it "adversarial: rejects a javascript: formaction via #set_attribute" do
      input = Components::Elements::Input.new(type: "submit")
      expect_raises(ArgumentError, /SafeHTML ban/) do
        input.set_attribute("formaction", "javascript:alert(document.cookie)")
      end
      input["formaction"].should be_nil
    end

    it "the breakout payload never appears in any rendered output" do
      input = Components::Elements::Input.new(type: "submit")
      begin
        input.set_attribute("formaction", "javascript:alert(document.cookie)")
      rescue ArgumentError
      end
      input.render.should_not contain("javascript:")
    end

    it "allows an ordinary https/relative formaction through both paths, unchanged" do
      input1 = Components::Elements::Input.new(type: "submit", formaction: "https://example.com/submit")
      input1.render.should eq(%(<input type="submit" formaction="https://example.com/submit">))

      input2 = Components::Elements::Input.new(type: "submit")
      input2.set_attribute("formaction", "/alt-submit")
      input2["formaction"].should eq("/alt-submit")
    end

    it "other attributes on Input are completely unaffected by the formaction check" do
      input = Components::Elements::Input.new(type: "submit", name: "action")
      input["name"].should eq("action")
    end
  end

  # Regression suite for the re-gate finding: HTML attribute names are
  # case-INSENSITIVE and may be whitespace-padded, but `url_bearing_attribute?`
  # was being called with the raw caller-supplied name and every per-element
  # override did an exact lowercase `==` comparison. That let
  # `A.new("HREF": "javascript:...")`, `A.new("Href": ...)`,
  # `a.set_attribute("HREF", ...)`, and `set_attribute(" href", ...)` /
  # `set_attribute("href ", ...)` all sail past `url_bearing_attribute?`
  # (it returned `false` for anything that wasn't byte-for-byte "href") and
  # render a live `javascript:` sink. Every example below is a payload that
  # a browser treats identically to the plain-lowercase form — HTML
  # attribute-name matching is ASCII-case-insensitive and tolerant of
  # surrounding whitespace in source markup/tooling — so a spec suite that
  # only ever exercised lowercase names (as this file did before this fix)
  # is a false green: it proves nothing about the actual attacker-controlled
  # input space. Each `it` below must independently fail (raise nothing) if
  # `set_attribute` regresses to comparing raw, un-normalized names again.
  describe "case-insensitive / whitespace-normalized enforcement (regression)" do
    describe Components::Elements::A do
      it "adversarial: rejects HREF (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::A.new("HREF": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects Href (mixed-case) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::A.new("Href": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects HREF (all-caps) via #set_attribute" do
        a = Components::Elements::A.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          a.set_attribute("HREF", "javascript:alert(1)")
        end
        a["HREF"].should be_nil
      end

      it "adversarial: rejects a leading-whitespace-padded name via #set_attribute" do
        a = Components::Elements::A.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          a.set_attribute(" href", "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a trailing-whitespace-padded name via #set_attribute" do
        a = Components::Elements::A.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          a.set_attribute("href ", "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded name via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::A.new(" href": "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Link do
      it "adversarial: rejects HREF via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Link.new("HREF": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded href via #set_attribute" do
        link = Components::Elements::Link.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          link.set_attribute(" href ", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Img do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Img.new("SRC": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects Src (mixed-case) via #set_attribute" do
        img = Components::Elements::Img.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          img.set_attribute("Src", "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded src via #set_attribute" do
        img = Components::Elements::Img.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          img.set_attribute("src ", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Script do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Script.new("SRC": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded src via #set_attribute" do
        script = Components::Elements::Script.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          script.set_attribute(" src", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Iframe do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Iframe.new("SRC": "javascript:alert(document.domain)")
        end
      end

      it "adversarial: rejects a whitespace-padded src via #set_attribute" do
        iframe = Components::Elements::Iframe.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          iframe.set_attribute("src ", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Video do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Video.new("SRC": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects POSTER (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Video.new("POSTER": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded poster via #set_attribute" do
        video = Components::Elements::Video.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          video.set_attribute(" poster", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Audio do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Audio.new("SRC": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded src via #set_attribute" do
        audio = Components::Elements::Audio.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          audio.set_attribute("src ", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Source do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Source.new("SRC": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded src via #set_attribute" do
        source = Components::Elements::Source.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          source.set_attribute(" src", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Track do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Track.new("SRC": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded src via #set_attribute" do
        track = Components::Elements::Track.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          track.set_attribute("src ", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Embed do
      it "adversarial: rejects SRC (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Embed.new("SRC": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded src via #set_attribute" do
        embed = Components::Elements::Embed.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          embed.set_attribute(" src", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Area do
      it "adversarial: rejects HREF (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Area.new("HREF": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded href via #set_attribute" do
        area = Components::Elements::Area.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          area.set_attribute("href ", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Base do
      it "adversarial: rejects HREF (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Base.new("HREF": "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded href via #set_attribute" do
        base = Components::Elements::Base.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          base.set_attribute(" href", "javascript:alert(1)")
        end
      end
    end

    describe Components::Elements::Form do
      it "adversarial: rejects ACTION (all-caps) via the constructor kwarg path" do
        expect_raises(ArgumentError, /SafeHTML ban/) do
          Components::Elements::Form.new("ACTION": "javascript:alert(document.cookie)")
        end
      end

      it "adversarial: rejects Action (mixed-case) via #set_attribute" do
        form = Components::Elements::Form.new(method: "POST")
        expect_raises(ArgumentError, /SafeHTML ban/) do
          form.set_attribute("Action", "javascript:alert(1)")
        end
      end

      it "adversarial: rejects a whitespace-padded action via #set_attribute" do
        form = Components::Elements::Form.new(method: "POST")
        expect_raises(ArgumentError, /SafeHTML ban/) do
          form.set_attribute(" action ", "javascript:alert(1)")
        end
      end
    end
  end
end
