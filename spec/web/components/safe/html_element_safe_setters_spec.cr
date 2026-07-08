require "../../spec_helper"
require "../../../../src/components/elements/grouping/div"
require "../../../../src/components/elements/text/a"
require "../../../../src/components/elements/document/meta"
require "../../../../src/components/safe/safe_url"
require "../../../../src/components/safe/safe_style"

describe "SafeHTML v1 — on* ban (docs/SAFE_HTML_V1.md)" do
  it "bans onclick on Div (construction-time, from the constructor kwargs path)" do
    expect_raises(ArgumentError, "inline event-handler attribute") do
      Components::Elements::Div.new(onclick: "alert(1)")
    end
  end

  it "bans onerror on A (construction-time)" do
    expect_raises(ArgumentError, "inline event-handler attribute") do
      Components::Elements::A.new(onerror: "alert(1)")
    end
  end

  it "bans onmouseover set via #set_attribute (the dynamic/runtime path)" do
    div = Components::Elements::Div.new
    expect_raises(ArgumentError, "inline event-handler attribute") do
      div.set_attribute("onmouseover", "alert(1)")
    end
  end

  it "is case-insensitive (OnLoad, ONLOAD)" do
    expect_raises(ArgumentError) { Components::Elements::Div.new(OnLoad: "x") }
    expect_raises(ArgumentError) { Components::Elements::Div.new(ONCLICK: "x") }
  end

  it "does not false-positive on ordinary attributes that merely contain 'on'" do
    # "contenteditable" and "data-on-time" both contain the letters "on" but
    # do not START with "on" — must not be banned.
    div = Components::Elements::Div.new(contenteditable: "true")
    div["contenteditable"].should eq("true")

    div2 = Components::Elements::Div.new
    div2.set_attribute("data-on-time", "true")
    div2["data-on-time"].should eq("true")
  end
end

describe "SafeHTML v1 — typed URL/style setters (docs/SAFE_HTML_V1.md)" do
  it "#set_safe_url_attribute sets a validated href" do
    a = Components::Elements::A.new
    a.set_safe_url_attribute("href", Components::SafeURL.parse!("https://example.com"))
    a.render.should eq(%(<a href="https://example.com"></a>))
  end

  it "#set_safe_url_attribute cannot be reached with an unsafe URL — construction of the SafeURL itself raises first" do
    a = Components::Elements::A.new
    expect_raises(Components::SafeURL::UnsafeURLError) do
      a.set_safe_url_attribute("href", Components::SafeURL.parse!("javascript:alert(document.cookie)"))
    end
    # The attribute was never set — the element carries no href at all.
    a["href"].should be_nil
  end

  it "#set_safe_style sets a validated style attribute" do
    div = Components::Elements::Div.new
    style = Components::SafeStyle.new.keyword("display", "flex").build
    div.set_safe_style(style)
    div.render.should eq(%(<div style="display: flex"></div>))
  end

  describe "Meta.safe_refresh — the meta-refresh compound-content sink" do
    it "assembles a validated content=\"N; url=...\" value" do
      meta = Components::Elements::Meta.safe_refresh(5, Components::SafeURL.parse!("/dashboard"))
      meta.render.should eq(%(<meta http-equiv="refresh" content="5; url=/dashboard">))
    end

    it "adversarial: a javascript: refresh target is rejected before it can reach content=" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::Elements::Meta.safe_refresh(0, Components::SafeURL.parse!("javascript:alert(1)"))
      end
    end

    it "rejects a negative seconds value" do
      expect_raises(ArgumentError, "seconds must be >= 0") do
        Components::Elements::Meta.safe_refresh(-1, Components::SafeURL.parse!("/x"))
      end
    end
  end

  describe "falsifiability: the typed setters reject plain strings at compile time" do
    it "documents the compile-time guarantee (see comment) — cannot be expressed as a runtime spec" do
      # Neither of the following compiles if uncommented:
      #
      #   Components::Elements::Div.new.set_safe_style("color: red; } body { display: none")
      #   # => Error: no overload matches 'set_safe_style' with type String
      #
      #   Components::Elements::A.new.set_safe_url_attribute("href", "javascript:alert(1)")
      #   # => Error: no overload matches 'set_safe_url_attribute' with types String, String
      #
      # `set_safe_style` takes a `SafeStyleValue` and `set_safe_url_attribute`
      # takes a `SafeURL` — not `String` — so a raw string can only reach an
      # element through the legacy `set_attribute`/`add_style` String path,
      # never through these typed entry points. That is the "compile-time
      # BAN" half of docs/SAFE_HTML_V1.md's dual enforcement story (the on*
      # ban above is the "construction-time raise" half).
      true.should be_true
    end
  end
end
