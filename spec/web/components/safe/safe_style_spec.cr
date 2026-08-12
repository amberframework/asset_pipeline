require "../../spec_helper"
require "../../../../src/components/safe/safe_style"

describe Components::SafeStyle do
  describe "typed color builder" do
    it "builds a color declaration from a hex color" do
      style = Components::SafeStyle.new.color("color", Components::SafeStyle::Color.hex("#1d4ed8")).build
      style.to_s.should contain("color: oklch(")
    end

    it "rejects a color property not on the allowlist" do
      expect_raises(ArgumentError, "not a color property") do
        Components::SafeStyle.new.color("background-image", Components::SafeStyle::Color.hex("#1d4ed8"))
      end
    end
  end

  describe "typed length builder" do
    it "builds a length declaration" do
      style = Components::SafeStyle.new.length("padding", Components::SafeLength.px(16)).build
      style.to_s.should eq("padding: 16px")
    end

    it "rejects a length property not on the allowlist" do
      expect_raises(ArgumentError, "not a length property") do
        Components::SafeStyle.new.length("animation-duration", Components::SafeLength.px(1))
      end
    end
  end

  describe "typed keyword builder" do
    it "builds a keyword declaration" do
      style = Components::SafeStyle.new.keyword("display", "flex").build
      style.to_s.should eq("display: flex")
    end

    it "rejects a keyword property not on the allowlist" do
      expect_raises(ArgumentError, "not a keyword property") do
        Components::SafeStyle.new.keyword("cursor", "pointer")
      end
    end

    it "rejects a value not in the property's own keyword allowlist" do
      expect_raises(ArgumentError, "not an allowlisted value") do
        Components::SafeStyle.new.keyword("display", "not-a-real-display-value")
      end
    end
  end

  describe "adversarial: the brand_color-class CSS-context sink" do
    it "the mailer brand_color bug payload cannot reach SafeStyle at all — there is no free-form string entry point" do
      # Stage-5 CSS-context bug (docs/SAFE_HTML_V1.md background): a raw
      # `brand_color` string reached a `style`/CSS sink. `SafeStyle` has NO
      # method that accepts a bare `String` for a color/length value — only
      # `Color` and `SafeLength`, both independently validated at
      # construction. The attack payload below isn't rejected by a runtime
      # check; it's structurally impossible to pass to `SafeStyle#color` at
      # all (a compile error), which is the strongest v1 guarantee. This
      # spec instead proves the *typed* color constructor itself rejects a
      # non-hex, CSS-breakout-shaped string when used the only way it can be:
      expect_raises(ArgumentError) do
        Components::SafeStyle::Color.hex("red; } body { display: none")
      end
    end
  end

  describe "chaining and combined output" do
    it "combines multiple declarations in order, semicolon-separated" do
      style = Components::SafeStyle.new
        .keyword("display", "flex")
        .length("padding", Components::SafeLength.px(8))
        .color("color", Components::SafeStyle::Color.hex("#000000"))
        .build

      style.to_s.should eq("display: flex; padding: 8px; color: oklch(0.000 0.000 0.00)")
    end
  end
end

describe Components::SafeLength do
  it "builds px/rem/percent/zero lengths" do
    Components::SafeLength.px(12).to_s.should eq("12px")
    Components::SafeLength.rem(1.5).to_s.should eq("1.5rem")
    Components::SafeLength.percent(100).to_s.should eq("100%")
    Components::SafeLength.zero.to_s.should eq("0")
  end
end
