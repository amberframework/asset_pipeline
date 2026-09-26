require "../spec_helper"
require "../../../samples/theming/example_skin"

describe "AcmeSkin" do
  it "resolves brand colors into both appearance palettes" do
    tokens = UI::DesignTokens::Tokens.default.with_brand(AcmeSkin::Brand.new)

    tokens.colors_light.brand_primary.should eq(AcmeSkin::LIGHT_PRIMARY)
    tokens.colors_dark.brand_primary.should eq(AcmeSkin::DARK_PRIMARY)
  end

  it "builds a rounded Form section with token-backed surfaces" do
    form = UI::Form.new

    section = AcmeSkin.add_settings_section(form, "Appearance")

    form.sections.should contain(section)
    section.tab_shape.should eq(UI::TabShape::Rounded)
    section.tab_icon.should eq("slider.horizontal.3")
    section.panel_style.background_fill_color.should eq(UI::ColorRole::SurfacePanel)
  end

  it "builds an enabled Slide switch using semantic surface roles" do
    toggle = AcmeSkin.build_switch("Reduce motion", is_on: true)

    toggle.is_on.should be_true
    toggle.appearance.should eq(UI::ToggleAppearance::Slide)
    toggle.track_color.should eq(UI::ColorRole::SurfaceSunken)
    toggle.on_color.should eq(UI::ColorRole::BrandPrimary)
  end
end
