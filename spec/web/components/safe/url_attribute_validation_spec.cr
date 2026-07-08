require "../../spec_helper"
require "../../../../src/components/elements/text/a"
require "../../../../src/components/elements/document/link"
require "../../../../src/components/elements/embedded/img"
require "../../../../src/components/elements/document/script"
require "../../../../src/components/elements/embedded/media"
require "../../../../src/components/elements/void/void_elements"
require "../../../../src/components/elements/forms/form"

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
end
