require "../../spec_helper"
require "../../../../src/components/elements/grouping/div"
require "../../../../src/components/elements/text/a"
require "../../../../src/components/elements/embedded/img"
require "../../../../src/components/elements/forms/form"

# SafeHTML v1 — attribute-NAME grammar enforcement (docs/SAFE_HTML_V1.md
# §3.1b). This is the re-gate's GENERAL root-cause fix, not another
# per-variant point-fix: `HTMLElement#render_attributes` emits the
# attribute NAME verbatim (only the *value* is escaped), so any
# caller-supplied name containing a tokenizer-significant byte changes
# what the browser parses, independent of the SafeURL / on*-ban checks
# entirely.
#
# The two headline adversarial cases this closes:
#   - `A.new("/href": "javascript:...")` — the leading solidus survives
#     `UrlAttributeValidation`'s `name.strip.downcase` normalization
#     (`.strip` does not remove a `/`), so the SafeURL gate never fires;
#     the browser tokenizer then silently drops the `/` and renders a
#     live `href="javascript:..."` attribute.
#   - `Div.new("/onclick": "...")` — same leading-solidus trick, this time
#     bypassing the `on*` hard ban the exact same way.
#
# Every example below independently proves the fix by construction: if
# `validate_attribute_name!` regresses to a no-op (or is bypassed on some
# path), the corresponding `it` fails to raise.
describe "SafeHTML v1 — attribute-name grammar (docs/SAFE_HTML_V1.md)" do
  # ---- the two headline manual-repro cases from the re-gate -------------

  describe "adversarial: the leading-solidus SafeURL-gate bypass" do
    it "A.new(\"/href\": \"javascript:...\") now RAISES via the constructor-kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::A.new("/href": "javascript:alert(document.cookie)")
      end
    end

    it "a.set_attribute(\"/href\", \"javascript:...\") now RAISES via the dynamic path" do
      a = Components::Elements::A.new
      expect_raises(ArgumentError, /SafeHTML ban/) do
        a.set_attribute("/href", "javascript:alert(document.cookie)")
      end
      a["/href"].should be_nil
      a.render.should_not contain("javascript:")
    end
  end

  describe "adversarial: the leading-solidus on*-ban bypass" do
    it "Div.new(\"/onclick\": \"...\") now RAISES via the constructor-kwarg path" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Div.new("/onclick": "alert(document.cookie)")
      end
    end

    it "div.set_attribute(\"/onclick\", \"...\") now RAISES via the dynamic path" do
      div = Components::Elements::Div.new
      expect_raises(ArgumentError, /SafeHTML ban/) do
        div.set_attribute("/onclick", "alert(document.cookie)")
      end
      div["/onclick"].should be_nil
      div.render.should_not contain("onclick")
    end
  end

  # ---- systematic coverage across representative elements ---------------
  #
  # `Div` has no `UrlAttributeValidation`/`on*`-specific override at all —
  # it only ever reaches `HTMLElement#set_attribute` directly, so it is the
  # cleanest proof that the grammar check lives at the true base chokepoint
  # and is not piggybacking on some other element's URL/on* logic. `A`/
  # `Img`/`Form` additionally exercise the `include UrlAttributeValidation`
  # override-then-`super` path.

  {
    {"leading solidus", "/href"},
    {"embedded space", "x onload"},
    {"embedded equals", "x=y"},
    {"embedded greater-than", "x>y"},
    {"embedded double-quote", %(x"y)},
    {"embedded single-quote", "x'y"},
    {"embedded control char (tab)", "x\ty"},
    {"embedded control char (NUL)", "x\u0000y"},
    {"embedded backslash", "x\\y"},
  }.each do |(label, malformed_name)|
    describe "adversarial: #{label} (#{malformed_name.inspect})" do
      it "rejects it on Div via #set_attribute" do
        div = Components::Elements::Div.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          div.set_attribute(malformed_name, "value")
        end
        div[malformed_name].should be_nil
      end

      it "rejects it on A via #set_attribute (the UrlAttributeValidation override-then-super path)" do
        a = Components::Elements::A.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          a.set_attribute(malformed_name, "value")
        end
      end

      it "rejects it on Img via #set_attribute" do
        img = Components::Elements::Img.new
        expect_raises(ArgumentError, /SafeHTML ban/) do
          img.set_attribute(malformed_name, "value")
        end
      end
    end
  end

  # Constructor-kwarg path, checked separately (Crystal double-splat keys
  # accept arbitrary quoted-string spellings, same as the existing
  # case/whitespace regression suite in url_attribute_validation_spec.cr).
  it "rejects a leading-solidus name via the constructor-kwarg path on Div" do
    expect_raises(ArgumentError, /SafeHTML ban/) do
      Components::Elements::Div.new("/data-x": "value")
    end
  end

  it "rejects an embedded-space name via the constructor-kwarg path on A" do
    expect_raises(ArgumentError, /SafeHTML ban/) do
      Components::Elements::A.new("x onload": "value")
    end
  end

  it "rejects an embedded-quote name via the constructor-kwarg path on Img" do
    expect_raises(ArgumentError, /SafeHTML ban/) do
      Components::Elements::Img.new(%(x"y): "value")
    end
  end

  it "rejects an embedded-equals name via the constructor-kwarg path on Form" do
    expect_raises(ArgumentError, /SafeHTML ban/) do
      Components::Elements::Form.new("x=y": "value")
    end
  end

  it "rejects an empty attribute name via #set_attribute" do
    div = Components::Elements::Div.new
    expect_raises(ArgumentError, /SafeHTML ban/) do
      div.set_attribute("", "value")
    end
  end

  # ---- legitimate names are completely unaffected ------------------------

  describe "legitimate attribute names still work, unaffected by the grammar check" do
    it "href (plain, url-bearing) still works on A" do
      a = Components::Elements::A.new(href: "/relative/path")
      a.render.should eq(%(<a href="/relative/path"></a>))
    end

    it "data-x (hyphenated data attribute) still works" do
      div = Components::Elements::Div.new
      div.set_attribute("data-x", "1")
      div["data-x"].should eq("1")
    end

    it "aria-label (hyphenated ARIA attribute) still works" do
      div = Components::Elements::Div.new
      div.set_attribute("aria-label", "close")
      div["aria-label"].should eq("close")
    end

    it "viewBox (SVG-style camelCase attribute) still works" do
      div = Components::Elements::Div.new
      div.set_attribute("viewBox", "0 0 100 100")
      div["viewBox"].should eq("0 0 100 100")
    end

    it "xml:lang (colon-namespaced attribute) still works" do
      div = Components::Elements::Div.new
      div.set_attribute("xml:lang", "en")
      div["xml:lang"].should eq("en")
    end

    it "underscore- and digit-bearing names still work" do
      div = Components::Elements::Div.new
      div.set_attribute("data_x1", "1")
      div["data_x1"].should eq("1")
    end
  end
end
