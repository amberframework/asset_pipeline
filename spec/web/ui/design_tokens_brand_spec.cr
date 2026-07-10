require "spec"
require "../../../src/ui/design_tokens"

# Sentinel-magenta — used across the cascade specs to confirm a brand
# override visibly cascades through every generator and every renderer.
SENTINEL_MAGENTA = UI::DesignTokens::Color.hex("#ff00ff")

private class SinglePrimaryBrand < UI::DesignTokens::Brand
  protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    palette.copy_with(brand_primary: SENTINEL_MAGENTA)
  end
end

private class TighterRadiusBrand < UI::DesignTokens::Brand
  protected def override_radius(scale : UI::DesignTokens::RadiusScale) : UI::DesignTokens::RadiusScale
    scale.copy_with(md: 0.25_f64, lg: 0.5_f64)
  end
end

private class NoOpBrand < UI::DesignTokens::Brand
end

private class FullPaletteBrand < UI::DesignTokens::Brand
  protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    sentinel = SENTINEL_MAGENTA
    palette.copy_with(
      brand_primary: sentinel,
      brand_primary_hover: sentinel,
      brand_primary_active: sentinel,
      brand_secondary: sentinel,
      brand_accent: sentinel,
    )
  end
end

private class TouchTargetBrand < UI::DesignTokens::Brand
  protected def override_touch_target_minimum_px(value : Float64) : Float64
    48.0
  end
end

describe UI::DesignTokens::Brand do
  describe "#apply" do
    it "returns a new Tokens with the overridden field replaced" do
      base = UI::DesignTokens::Tokens.default
      result = base.with_brand(SinglePrimaryBrand.new)
      result.colors_light.brand_primary.to_hex.should eq("#ff00ff")
    end

    it "leaves all other fields equal to base defaults" do
      base = UI::DesignTokens::Tokens.default
      result = base.with_brand(SinglePrimaryBrand.new)

      # Every NON-brand-primary color is identical.
      base_pl = base.colors_light
      res_pl = result.colors_light
      res_pl.brand_secondary.should eq(base_pl.brand_secondary)
      res_pl.surface_canvas.should eq(base_pl.surface_canvas)
      res_pl.text_primary.should eq(base_pl.text_primary)
      res_pl.danger.should eq(base_pl.danger)

      # The dark palette is untouched.
      result.colors_dark.should eq(base.colors_dark)

      # Spacing, type, radius, shadow, motion, breakpoints are untouched.
      result.spacing.should eq(base.spacing)
      result.type.should eq(base.type)
      result.radius.should eq(base.radius)
      result.shadow.should eq(base.shadow)
      result.motion.should eq(base.motion)
      result.breakpoints.should eq(base.breakpoints)
      result.touch_target_minimum_px.should eq(base.touch_target_minimum_px)
    end

    it "does not mutate the base Tokens" do
      base = UI::DesignTokens::Tokens.default
      base_primary_before = base.colors_light.brand_primary
      base.with_brand(SinglePrimaryBrand.new)
      base.colors_light.brand_primary.should eq(base_primary_before)
    end

    it "merges radius overrides" do
      base = UI::DesignTokens::Tokens.default
      result = base.with_brand(TighterRadiusBrand.new)
      result.radius.md.should eq(0.25)
      result.radius.lg.should eq(0.5)
      # Other radius fields unchanged.
      result.radius.sm.should eq(base.radius.sm)
      result.radius.pill.should eq(base.radius.pill)
    end

    it "is a no-op when no override hooks are defined" do
      base = UI::DesignTokens::Tokens.default
      result = base.with_brand(NoOpBrand.new)
      result.colors_light.should eq(base.colors_light)
      result.colors_dark.should eq(base.colors_dark)
      result.spacing.should eq(base.spacing)
    end

    it "supports multi-field brand-color overrides" do
      result = UI::DesignTokens::Tokens.default.with_brand(FullPaletteBrand.new)
      sentinel = SENTINEL_MAGENTA
      result.colors_light.brand_primary.to_hex.should eq(sentinel.to_hex)
      result.colors_light.brand_primary_hover.to_hex.should eq(sentinel.to_hex)
      result.colors_light.brand_accent.to_hex.should eq(sentinel.to_hex)
    end

    it "overrides touch_target_minimum_px through the dedicated hook" do
      result = UI::DesignTokens::Tokens.default.with_brand(TouchTargetBrand.new)
      result.touch_target_minimum_px.should eq(48.0)
    end

    it "chains: with_brand twice composes brands left-to-right" do
      base = UI::DesignTokens::Tokens.default
      intermediate = base.with_brand(SinglePrimaryBrand.new)
      final = intermediate.with_brand(TighterRadiusBrand.new)
      final.colors_light.brand_primary.to_hex.should eq(SENTINEL_MAGENTA.to_hex)
      final.radius.md.should eq(0.25)
    end
  end
end
