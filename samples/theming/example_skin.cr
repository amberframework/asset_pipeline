require "../../src/ui"

module ExampleSkin
  LIGHT_PRIMARY = UI::DesignTokens::Color.hex("#316C73")
  DARK_PRIMARY  = UI::DesignTokens::Color.hex("#A5D4CF")

  # Supplies the skin's light and dark accent colors while retaining the
  # default values for palette roles the example does not override.
  class Brand < UI::DesignTokens::Brand
    protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      palette.copy_with(
        brand_primary: LIGHT_PRIMARY,
        brand_primary_hover: UI::DesignTokens::Color.hex("#285B63"),
        brand_primary_active: UI::DesignTokens::Color.hex("#214E56"),
      )
    end

    protected def override_color_dark(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      palette.copy_with(
        brand_primary: DARK_PRIMARY,
        brand_primary_hover: UI::DesignTokens::Color.hex("#B5E1DC"),
        brand_primary_active: UI::DesignTokens::Color.hex("#C3EAE5"),
      )
    end
  end

  # Appends a rounded settings section with semantic panel and tab fills.
  def self.add_settings_section(form : UI::Form, header : String) : UI::Form::FormSection
    form.add_section(
      header,
      tab_shape: UI::TabShape::Rounded,
      tab_icon: "slider.horizontal.3",
      panel_style: UI::SurfaceStyle.new(
        background_fill_color: UI::ColorRole::SurfacePanel,
      ),
      tab_style: UI::SurfaceStyle.new(
        background_fill_color: UI::ColorRole::SurfaceElevated,
      ),
    )
  end

  # Builds a Slide switch with semantic track, knob, and on colors.
  def self.build_switch(label : String, is_on : Bool = false) : UI::Toggle
    toggle = UI::Toggle.new(label, is_on)
    toggle.appearance = UI::ToggleAppearance::Slide
    toggle.track_color = UI::ColorRole::SurfaceSunken
    toggle.knob_color = UI::ColorRole::SurfaceElevated
    toggle.on_color = UI::ColorRole::BrandPrimary
    toggle
  end
end
