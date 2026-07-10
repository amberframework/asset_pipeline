require "spec"
require "../../../src/ui/design_tokens"
require "../../../src/ui/design_tokens/generators/web_generator"
require "../../../src/ui/design_tokens/generators/apple_generator"

# Phase 1 cascade spec — sentinel-magenta override on `brand_primary` must
# visibly reach each generator's emitted output. The web validator's cascade
# check #18 mechanizes this via the brand_cascade_demo sample; this spec
# guards the same contract at the unit-test level.
SENTINEL = UI::DesignTokens::Color.hex("#ff00ff")

private class CascadeSentinelBrand < UI::DesignTokens::Brand
  protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    palette.copy_with(brand_primary: SENTINEL)
  end

  protected def override_color_dark(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    palette.copy_with(brand_primary: SENTINEL)
  end
end

describe "design-token cascade" do
  it "WebGenerator emits the sentinel in --ap-color-brand-primary-rgb" do
    tokens = UI::DesignTokens::Tokens.default.with_brand(CascadeSentinelBrand.new)
    output = UI::DesignTokens::WebGenerator.generate(tokens)
    output.should contain("--ap-color-brand-primary-rgb: 255 0 255;")
  end

  it "WebGenerator emits the sentinel in the dark block too" do
    tokens = UI::DesignTokens::Tokens.default.with_brand(CascadeSentinelBrand.new)
    output = UI::DesignTokens::WebGenerator.generate(tokens)
    # The dark block sits inside @media (prefers-color-scheme: dark).
    dark_block_start = output.index("@media (prefers-color-scheme: dark)")
    dark_block_start.should_not be_nil
    dark_section = output[dark_block_start.not_nil!..]
    dark_section.should contain("--ap-color-brand-primary-rgb: 255 0 255;")
  end

  it "AppleGenerator emits the sentinel as a SwiftUI.Color literal" do
    tokens = UI::DesignTokens::Tokens.default.with_brand(CascadeSentinelBrand.new)
    output = UI::DesignTokens::AppleGenerator.generate(tokens)
    output.should contain("brandPrimary = SwiftUI.Color(.sRGB, red: 1.000, green: 0.000, blue: 1.000, opacity: 1.000)")
  end

  it "AppleGenerator emits the sentinel in the Dark inner enum too" do
    tokens = UI::DesignTokens::Tokens.default.with_brand(CascadeSentinelBrand.new)
    output = UI::DesignTokens::AppleGenerator.generate(tokens)
    dark_block_start = output.index("public enum Dark {")
    dark_block_start.should_not be_nil
    dark_section = output[dark_block_start.not_nil!..]
    dark_section.should contain("brandPrimary = SwiftUI.Color(.sRGB, red: 1.000, green: 0.000, blue: 1.000, opacity: 1.000)")
  end

  it "the base Tokens.default is never mutated by a brand override" do
    # Post Phase 6.12A: `Tokens.default.colors_light.brand_primary` is the
    # `Color::SYSTEM_ACCENT` sentinel. The mutation-safety contract is
    # identical regardless of representation: applying `.with_brand(...)`
    # must NOT change the identity of the base palette's brand_primary.
    base = UI::DesignTokens::Tokens.default
    pre = base.colors_light.brand_primary
    _ = base.with_brand(CascadeSentinelBrand.new)
    base.colors_light.brand_primary.should eq(pre)
    base.colors_light.brand_primary.system_accent?.should be_true
  end

  describe "brand_cascade_demo sample" do
    it "exists in the canonical path the validator consumes" do
      sample = File.expand_path("../../../../samples/cross_platform/web/brand_cascade_demo.cr", __FILE__)
      File.exists?(sample).should be_true
    end

    it "references UI::DesignTokens::Tokens.default.with_brand and a sentinel constant" do
      sample = File.expand_path("../../../../samples/cross_platform/web/brand_cascade_demo.cr", __FILE__)
      contents = File.read(sample)
      contents.should contain("UI::DesignTokens::Tokens.default")
      contents.should contain("BRAND_PRIMARY_HEX")
      contents.should contain("with_brand")
    end
  end
end
