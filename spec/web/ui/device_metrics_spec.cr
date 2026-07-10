require "../spec_helper"
require "../../../src/ui"

describe UI::DesignTokens::DeviceMetrics do
  before_each do
    UI::DesignTokens::Device.reset_provider
  end

  after_each do
    UI::DesignTokens::Device.reset_provider
  end

  it "exposes spec-time fallback dimensions before any renderer installs a provider" do
    # Fallback returns iPhone-portrait-ish bounds but ZERO safe-area
    # insets (Phase 6.10 Rem 4 cont.): iPhone safe-area values leak into
    # web output and non-iOS specs otherwise. Live iOS metrics come from
    # the UIKit renderer's installed provider, not this fallback.
    metrics = UI::DesignTokens::Device.current
    metrics.screen_width_pt.should eq(390.0)
    metrics.screen_height_pt.should eq(844.0)
    metrics.safe_area_top_pt.should eq(0.0)
    metrics.safe_area_bottom_pt.should eq(0.0)
  end

  it "computes content rect by subtracting safe-area insets from screen bounds" do
    metrics = UI::DesignTokens::DeviceMetrics.new(
      screen_width_pt: 402.0,
      screen_height_pt: 874.0,
      safe_area_top_pt: 59.0,
      safe_area_bottom_pt: 34.0,
      safe_area_leading_pt: 0.0,
      safe_area_trailing_pt: 0.0,
      horizontal_size_class: UI::DesignTokens::SizeClass::Compact,
      vertical_size_class: UI::DesignTokens::SizeClass::Regular,
    )
    metrics.content_width_pt.should eq(402.0)
    metrics.content_height_pt.should eq(781.0)
  end

  it "branches on size class via the compact?/regular? predicates" do
    compact = UI::DesignTokens::DeviceMetrics.new(
      screen_width_pt: 390.0, screen_height_pt: 844.0,
      safe_area_top_pt: 0.0, safe_area_bottom_pt: 0.0,
      safe_area_leading_pt: 0.0, safe_area_trailing_pt: 0.0,
      horizontal_size_class: UI::DesignTokens::SizeClass::Compact,
      vertical_size_class: UI::DesignTokens::SizeClass::Regular,
    )
    compact.compact_horizontal?.should be_true
    compact.regular_horizontal?.should be_false
    compact.regular_vertical?.should be_true
  end

  it "supports custom provider installation (renderer hook)" do
    UI::DesignTokens::Device.install_provider do
      UI::DesignTokens::DeviceMetrics.new(
        screen_width_pt: 1280.0,
        screen_height_pt: 800.0,
        safe_area_top_pt: 0.0,
        safe_area_bottom_pt: 0.0,
        safe_area_leading_pt: 0.0,
        safe_area_trailing_pt: 0.0,
        horizontal_size_class: UI::DesignTokens::SizeClass::Regular,
        vertical_size_class: UI::DesignTokens::SizeClass::Regular,
      )
    end
    metrics = UI::DesignTokens::Device.current
    metrics.screen_width_pt.should eq(1280.0)
    metrics.compact_horizontal?.should be_false
    metrics.regular_horizontal?.should be_true
  end

  it "exposes a convenience class method DeviceMetrics.current" do
    UI::DesignTokens::Device.install_provider do
      UI::DesignTokens::DeviceMetrics.new(
        screen_width_pt: 768.0,
        screen_height_pt: 1024.0,
        safe_area_top_pt: 20.0,
        safe_area_bottom_pt: 0.0,
        safe_area_leading_pt: 0.0,
        safe_area_trailing_pt: 0.0,
        horizontal_size_class: UI::DesignTokens::SizeClass::Regular,
        vertical_size_class: UI::DesignTokens::SizeClass::Regular,
      )
    end
    snapshot = UI::DesignTokens::DeviceMetrics.current
    snapshot.screen_width_pt.should eq(768.0)
  end
end

describe "UI::View root_fill" do
  it "carries the root_fill flag with a default of false" do
    v = UI::VStack.new
    v.root_fill.should be_false
  end

  it "supports the fill_screen! chainable shortcut" do
    v = UI::VStack.new
    returned = v.fill_screen!
    returned.should be(v)
    v.root_fill.should be_true
  end
end
