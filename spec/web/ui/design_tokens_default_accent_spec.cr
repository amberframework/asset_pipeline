require "spec"
require "../../../src/ui/design_tokens"

# Phase 6.12A — Item 1 coverage for the library-identity pivot.
#
# `Tokens.default` no longer carries an opinionated amber brand colour;
# instead, the `brand_primary` / `brand_primary_hover` / `brand_primary_active`
# family resolves to `Color::SYSTEM_ACCENT`, a sentinel each renderer maps
# to the platform-native accent (system blue on iOS, controlAccentColor on
# macOS, `AccentColor` keyword on web, `?attr/colorPrimary` on Android).
#
# Consumers who want an opinionated brand colour subclass
# `UI::DesignTokens::Brand` and call `Tokens.default.with_brand(...)` — this
# is the path the Cascade demo (`samples/initiative-cross-platform-ui-demo`)
# takes. This spec covers both halves.

describe UI::DesignTokens::Color do
  describe "::SYSTEM_ACCENT" do
    it "answers system_accent? true" do
      UI::DesignTokens::Color::SYSTEM_ACCENT.system_accent?.should be_true
    end

    it "is the only Color that answers system_accent? true" do
      red = UI::DesignTokens::Color.rgb(1.0, 0.0, 0.0)
      red.system_accent?.should be_false

      black_with_alpha_zero = UI::DesignTokens::Color.rgb(0.0, 0.0, 0.0, 0.0)
      black_with_alpha_zero.system_accent?.should be_false
    end

    it "serialises to_css as the CSS Color 4 'AccentColor' keyword" do
      UI::DesignTokens::Color::SYSTEM_ACCENT.to_css.should eq("AccentColor")
    end

    it "serialises to_swift as 'Color.accentColor'" do
      UI::DesignTokens::Color::SYSTEM_ACCENT.to_swift.should eq("Color.accentColor")
    end

    it "lowers to AccentColor through every CSS emitter" do
      sentinel = UI::DesignTokens::Color::SYSTEM_ACCENT
      sentinel.to_oklch_css.should eq("AccentColor")
      sentinel.to_rgba_css.should eq("AccentColor")
    end

    it "lowers to Color.accentColor through the swift emitter" do
      UI::DesignTokens::Color::SYSTEM_ACCENT.to_swift_color.should eq("Color.accentColor")
    end

    it "raises AndroidRendererNotImplemented from to_android_argb" do
      expect_raises(UI::DesignTokens::AndroidRendererNotImplemented, /SYSTEM_ACCENT/) do
        UI::DesignTokens::Color::SYSTEM_ACCENT.to_android_argb
      end
    end

    it "raises ArgumentError from to_hex (no honest hex literal exists)" do
      expect_raises(ArgumentError, /SYSTEM_ACCENT/) do
        UI::DesignTokens::Color::SYSTEM_ACCENT.to_hex
      end
    end

    it "raises ArgumentError from to_rgb_triple_css" do
      expect_raises(ArgumentError, /SYSTEM_ACCENT/) do
        UI::DesignTokens::Color::SYSTEM_ACCENT.to_rgb_triple_css
      end
    end

    it "is equal to itself (sentinel equality independent of bake)" do
      UI::DesignTokens::Color::SYSTEM_ACCENT.should eq(UI::DesignTokens::Color::SYSTEM_ACCENT)
    end

    it "is not equal to an unrelated black-with-zero-alpha colour" do
      black_zero = UI::DesignTokens::Color.rgb(0.0, 0.0, 0.0, 0.0)
      UI::DesignTokens::Color::SYSTEM_ACCENT.should_not eq(black_zero)
      black_zero.should_not eq(UI::DesignTokens::Color::SYSTEM_ACCENT)
    end

    it "renders to_s as 'Color::SYSTEM_ACCENT'" do
      UI::DesignTokens::Color::SYSTEM_ACCENT.to_s.should eq("Color::SYSTEM_ACCENT")
    end

    it "propagates the sentinel kind through copy_with by default" do
      copy = UI::DesignTokens::Color::SYSTEM_ACCENT.copy_with
      copy.system_accent?.should be_true
    end

    it "drops the sentinel when copy_with(sentinel: nil) is explicit" do
      materialised = UI::DesignTokens::Color::SYSTEM_ACCENT.copy_with(
        r: 0.1, g: 0.2, b: 0.3, alpha: 1.0, sentinel: nil,
      )
      materialised.system_accent?.should be_false
    end
  end
end

describe UI::DesignTokens::Tokens do
  describe ".default" do
    it "uses Color::SYSTEM_ACCENT for the light brand_primary family" do
      t = UI::DesignTokens::Tokens.default
      t.colors_light.brand_primary.system_accent?.should be_true
      t.colors_light.brand_primary_hover.system_accent?.should be_true
      t.colors_light.brand_primary_active.system_accent?.should be_true
    end

    it "uses Color::SYSTEM_ACCENT for the dark brand_primary family" do
      t = UI::DesignTokens::Tokens.default
      t.colors_dark.brand_primary.system_accent?.should be_true
      t.colors_dark.brand_primary_hover.system_accent?.should be_true
      t.colors_dark.brand_primary_active.system_accent?.should be_true
    end

    it "keeps brand_secondary as an opinionated library colour (not a sentinel)" do
      t = UI::DesignTokens::Tokens.default
      t.colors_light.brand_secondary.system_accent?.should be_false
      t.colors_dark.brand_secondary.system_accent?.should be_false
    end

    it "preserves an opinionated brand override applied via with_brand" do
      teal = UI::DesignTokens::Color.oklch(0.56, 0.13, 195.0)

      brand = TealBrand.new(teal)
      t = UI::DesignTokens::Tokens.default.with_brand(brand)

      t.colors_light.brand_primary.system_accent?.should be_false
      t.colors_light.brand_primary.l.should eq(0.56)
      t.colors_light.brand_primary.c.should eq(0.13)
      t.colors_light.brand_primary.h.should eq(195.0)

      # Symmetry: dark palette also overrides.
      t.colors_dark.brand_primary.system_accent?.should be_false
      t.colors_dark.brand_primary.l.should eq(0.56)
    end
  end
end

# Minimal Brand subclass for the with_brand cascade test above. Lives in the
# spec file (not in src/) because it's only useful for proving the sentinel
# does not leak through an explicit override.
class TealBrand < UI::DesignTokens::Brand
  def initialize(@teal : UI::DesignTokens::Color)
  end

  protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    palette.copy_with(
      brand_primary: @teal,
      brand_primary_hover: @teal,
      brand_primary_active: @teal,
    )
  end

  protected def override_color_dark(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    palette.copy_with(
      brand_primary: @teal,
      brand_primary_hover: @teal,
      brand_primary_active: @teal,
    )
  end
end
