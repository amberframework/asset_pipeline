require "spec"
require "../../../../src/ui/design_tokens"
require "../../../../src/ui/design_tokens/generators/web_generator"
require "../../../../src/ui/theme"

# Phase 6.12A — Item 2 coverage. The four renderer paths must honour the
# `Color::SYSTEM_ACCENT` sentinel and resolve it to the platform-native
# accent token rather than the sentinel's zeroed sRGB bake.
#
# AppKit + UIKit renderers expose `brand_tint_action(color) : Symbol`
# (the pure decision split out from `ensure_swiftkit_runtime!`). Spec
# asserts `:clear` for sentinel, `:set` for any opinionated brand —
# without touching the real `LibSwiftKitBridge` C FFI. Asserting the
# decision is the same as asserting the bridge call because
# `apply_brand_tint` is a 1:1 dispatch on the decision value.
#
# Web renderer assertion runs through the WebGenerator pipeline that the
# renderer's `inject_theme_css` delegates to. UI::Theme integration is
# tested via `theme_color_from` honouring `css_override` for the
# sentinel-derived ThemeColor.
#
# Android renderer assertion is the `to_android_argb` raise — there is
# no Android brand-tint path; the sentinel is fail-loud at the
# serialization layer.

# Helper brand for the "opinionated brand" half of each assertion.
private class OpinionatedTealBrand < UI::DesignTokens::Brand
  TEAL = UI::DesignTokens::Color.oklch(0.56, 0.13, 195.0)

  protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    palette.copy_with(brand_primary: TEAL, brand_primary_hover: TEAL, brand_primary_active: TEAL)
  end

  protected def override_color_dark(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
    palette.copy_with(brand_primary: TEAL, brand_primary_hover: TEAL, brand_primary_active: TEAL)
  end
end

# Pure-decision test seam at the Color layer. The AppKit + UIKit
# renderers' `apply_brand_tint(brand)` methods translate this value to
# either `LibSwiftKitBridge.apsk_runtime_clear_brand_tint` or
# `apsk_runtime_set_brand_tint(r, g, b, a)` — a 1:1 dispatch. By placing
# the decision on `UI::DesignTokens::Color` we can prove the renderer
# branch coverage without linking the native bridge (which is
# necessary for any platform-gated build of this file).
describe "UI::DesignTokens::Color#brand_tint_action (renderer test seam)" do
  it "returns :clear for Color::SYSTEM_ACCENT" do
    UI::DesignTokens::Color::SYSTEM_ACCENT.brand_tint_action.should eq(:clear)
  end

  it "returns :set for an opinionated colour (deep teal)" do
    teal = UI::DesignTokens::Color.oklch(0.56, 0.13, 195.0)
    teal.brand_tint_action.should eq(:set)
  end

  it "returns :set for a hex literal opinionated colour" do
    magenta = UI::DesignTokens::Color.hex("#ff00ff")
    magenta.brand_tint_action.should eq(:set)
  end

  it "drives the Tokens.default → Tokens.default.with_brand transition" do
    default_brand = UI::DesignTokens::Tokens.default.colors_light.brand_primary
    default_brand.brand_tint_action.should eq(:clear)

    branded = UI::DesignTokens::Tokens.default.with_brand(OpinionatedTealBrand.new)
    branded.colors_light.brand_primary.brand_tint_action.should eq(:set)
  end
end

# The Web + UI::Theme + Android paths are platform-flag-independent and
# always run; they exercise the serialization layer that the renderers
# delegate to.
describe "UI::DesignTokens::WebGenerator system-accent integration" do
  it "emits --ap-color-brand-primary: AccentColor; for the default token bag" do
    output = UI::DesignTokens::WebGenerator.generate(UI::DesignTokens::Tokens.default)
    output.should contain("--ap-color-brand-primary: AccentColor;")
    output.should contain("--ap-color-brand-primary-hover: AccentColor;")
    output.should contain("--ap-color-brand-primary-active: AccentColor;")
  end

  it "emits the resolved brand colour when an opinionated brand is applied" do
    tokens = UI::DesignTokens::Tokens.default.with_brand(OpinionatedTealBrand.new)
    output = UI::DesignTokens::WebGenerator.generate(tokens)
    output.includes?("--ap-color-brand-primary: AccentColor;").should be_false
    # Teal OKLCH baked: includes the canonical oklch() literal.
    output.should contain("--ap-color-brand-primary: oklch(0.560 0.130 195.00)")
  end

  it "omits the --ap-color-brand-primary-rgb paired variant for the sentinel" do
    output = UI::DesignTokens::WebGenerator.generate(UI::DesignTokens::Tokens.default)
    output.includes?("--ap-color-brand-primary-rgb:").should be_false
  end
end

describe "UI::Theme system-accent integration (MD3 emitter)" do
  it "round-trips the AccentColor token through the MD3 alias when default tokens carry the sentinel" do
    theme = UI::Theme.design_system_default
    css = theme.to_css_custom_properties
    # The legacy --md-sys-color-primary alias must now emit AccentColor
    # (via the ThemeColor css_override field), not rgba(0, 0, 0, 0.0)
    # which would be the sentinel's zeroed RGB bake.
    css.should contain("--md-sys-color-primary: AccentColor;")
    css.includes?("--md-sys-color-primary: rgba(0, 0, 0, 0").should be_false
  end
end

describe "UI::DesignTokens::Color android integration" do
  it "raises AndroidRendererNotImplemented when SYSTEM_ACCENT reaches to_android_argb" do
    expect_raises(UI::DesignTokens::AndroidRendererNotImplemented) do
      UI::DesignTokens::Color::SYSTEM_ACCENT.to_android_argb
    end
  end

  it "lets an opinionated brand pass through to_android_argb unchanged" do
    teal = UI::DesignTokens::Color.oklch(0.56, 0.13, 195.0)
    # No raise; returns a packed ARGB int.
    argb = teal.to_android_argb
    argb.should_not eq(0)
  end
end

# Direct cover for the ThemeColor sentinel-detection contract. The
# Android renderer's `theme_color_to_argb` consults `css_override`
# before packing RGBA — when set, it raises `AndroidRendererNotImplemented`
# rather than emitting ARGB 0 (transparent black) for a sentinel-derived
# ThemeColor. Verifying that contract without `-Dandroid` requires
# proving the field shape; the Android-side raise is exercised by the
# Voyager / Cascade build paths that import the renderer.
describe UI::ThemeColor do
  it "carries css_override when constructed from a sentinel UI::DesignTokens::Color" do
    # Mirrors UI::Theme.theme_color_from(c) for the sentinel case.
    sentinel = UI::DesignTokens::Color::SYSTEM_ACCENT
    tc = UI::ThemeColor.new(
      r: sentinel.r, g: sentinel.g, b: sentinel.b, a: sentinel.alpha,
      css_override: sentinel.system_accent? ? sentinel.to_css : nil,
    )
    tc.css_override.should eq("AccentColor")
  end

  it "defaults css_override to nil for non-sentinel ThemeColor" do
    tc = UI::ThemeColor.new(r: 0.5, g: 0.5, b: 0.5)
    tc.css_override.should be_nil
  end
end
