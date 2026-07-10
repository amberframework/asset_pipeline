require "../../src/ui/design_tokens"

# Phase 6 demo brand override.
#
# Per brief.yml decision #6, this brand MUST be notably distinct from the
# default amber palette so the "brand override works" claim is visually
# demonstrated, not just numerically asserted. Amber's brand_primary hue
# sits in the warm yellow / orange / gold OKLCH family (h ~ 60-80 deg
# range). We pick a deep teal — h ~ 195 deg, OKLCH(0.56, 0.13, 195) — a
# notably different hue family that flips every brand-tinted surface.
#
# Light + dark palette overrides apply to:
#   - brand_primary / hover / active (button fills, link tint)
#   - brand_secondary (selected segmented controls, tab bar tint)
#
# Surface tokens are intentionally NOT overridden — the contrast story
# stays inside the existing semantic-foreground contract that Phase 1
# established. The brand override is the chromatic accent layer.

module InitiativeDemo
  # Deep teal primary — OKLCH(0.56, 0.13, 195). Distinct hue family
  # from amber's gold (~65 deg). Picked to be Apple-friendly: enough
  # chroma to feel branded, but lightness aligned with iOS Liquid Glass
  # tint expectations so glass surfaces still read correctly.
  BRAND_PRIMARY_LIGHT  = UI::DesignTokens::Color.oklch(0.56, 0.13, 195.0)
  BRAND_PRIMARY_HOVER  = UI::DesignTokens::Color.oklch(0.50, 0.13, 195.0)
  BRAND_PRIMARY_ACTIVE = UI::DesignTokens::Color.oklch(0.44, 0.13, 195.0)

  # Slightly lifted lightness for dark mode so the tint reads as primary
  # against the dark surface canvas.
  BRAND_PRIMARY_DARK   = UI::DesignTokens::Color.oklch(0.68, 0.14, 195.0)
  BRAND_PRIMARY_DARK_HOVER  = UI::DesignTokens::Color.oklch(0.74, 0.14, 195.0)
  BRAND_PRIMARY_DARK_ACTIVE = UI::DesignTokens::Color.oklch(0.62, 0.14, 195.0)

  # Brand secondary — a coordinated cyan-teal one notch toward cyan for
  # selected-state contrast (segmented controls, tab bar).
  BRAND_SECONDARY_LIGHT = UI::DesignTokens::Color.oklch(0.62, 0.12, 215.0)
  BRAND_SECONDARY_DARK  = UI::DesignTokens::Color.oklch(0.72, 0.13, 215.0)

  class DemoBrand < UI::DesignTokens::Brand
    protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      palette.copy_with(
        brand_primary: BRAND_PRIMARY_LIGHT,
        brand_primary_hover: BRAND_PRIMARY_HOVER,
        brand_primary_active: BRAND_PRIMARY_ACTIVE,
        brand_secondary: BRAND_SECONDARY_LIGHT,
      )
    end

    protected def override_color_dark(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      palette.copy_with(
        brand_primary: BRAND_PRIMARY_DARK,
        brand_primary_hover: BRAND_PRIMARY_DARK_HOVER,
        brand_primary_active: BRAND_PRIMARY_DARK_ACTIVE,
        brand_secondary: BRAND_SECONDARY_DARK,
      )
    end
  end

  # Single shared Tokens with the demo brand baked in. Exposed as a
  # method (not a constant) because module-level constant initializers
  # don't fire under iOS embedding (the `ld -r -unexported_symbol _main`
  # step in ios/build_crystal_lib.sh hides Crystal's `__crystal_main`,
  # which is what triggers module constant initialization). The method
  # builds fresh on each call; the cost is negligible (one struct
  # allocation per render). See `samples/cross_platform/ios_host/hig_bridge.cr:25-50`
  # for the canonical class-init gap workaround. Codex-confirmed
  # root cause for the Phase 6 Rem 1 iOS crash investigation.
  def self.brand_tokens : UI::DesignTokens::Tokens
    UI::DesignTokens::Tokens.default.with_brand(DemoBrand.new)
  end
end
