# Brand-cascade demonstration for Phase 1 on macOS (AppKit).
#
# Renders a single UI::VStack containing a brand-tinted UI::Button onto a
# native AppKit window via UI::AppKit::Renderer. The button's tint pulls from
# `Tokens.default.with_brand(SentinelBrand.new)` — flipping `BRAND_PRIMARY_HEX`
# below regenerates the entire scene with the new identity. This is the
# load-bearing proof for Phase 1's Definition of Done #5:
#
#   "Defining a 5-line subclass of `Brand` that overrides `brand_primary` to a
#    sentinel and rendering a sample view on web AND at least one Apple target
#    (macOS or iOS) shows the sentinel color."
#
# The web half ships in `samples/cross_platform/web/brand_cascade_demo.cr`.
# This sample mirrors that file's `BRAND_PRIMARY_HEX` constant so the Validator
# can flip the same sentinel across both targets.
#
# Build (requires crystal-alpha on darwin):
#   cd samples/cross_platform/macos_host
#   make -f BrandCascade.Makefile build
#
# Run (saves a PNG to HIG_SCREENSHOT_PATH and exits):
#   HIG_SCREENSHOT_PATH=/tmp/brand_cascade_macos.png ./bin/brand_cascade_demo
#
# Validator workflow: capture the PNG with the default magenta sentinel, then
# flip `BRAND_PRIMARY_HEX` to e.g. "#00ff66", rebuild + recapture, and confirm
# the rendered button background is the flipped color (within ΔE 3.0 of the
# sentinel hex value, matching the web cascade tolerance).

require "json"
require "../../../src/ui"
require "../../../src/ui/design_tokens"

{% if flag?(:macos) %}
  # SENTINEL — flip this to verify the cascade reaches the rendered AppKit pixel.
  BRAND_PRIMARY_HEX = "#ff00ff"

  # ---------------------------------------------------------------------------
  # Brand override
  # ---------------------------------------------------------------------------
  #
  # 5-line Brand subclass demonstrating the Phase 1 cascade contract: a single
  # `override_color_light` / `override_color_dark` pair flips brand_primary,
  # brand_primary_hover, and brand_primary_active to a sentinel. The renderer's
  # `token_nscolor(:brand_primary)` shim reads the overridden value, which then
  # flows into every visit method that paints the brand fill (UI::Button's
  # prominent bezel, ActivityView accent, etc.).

  class SentinelBrand < UI::DesignTokens::Brand
    protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      sentinel = UI::DesignTokens::Color.hex(BRAND_PRIMARY_HEX)
      palette.copy_with(
        brand_primary: sentinel,
        brand_primary_hover: sentinel,
        brand_primary_active: sentinel,
      )
    end

    protected def override_color_dark(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      sentinel = UI::DesignTokens::Color.hex(BRAND_PRIMARY_HEX)
      palette.copy_with(
        brand_primary: sentinel,
        brand_primary_hover: sentinel,
        brand_primary_active: sentinel,
      )
    end
  end

  # ---------------------------------------------------------------------------
  # Bridge into window_helper.m (shared with hig_showcase).
  # ---------------------------------------------------------------------------

  lib LibWindowHelper
    fun objc_create_capture_window(width : Float64, height : Float64, appearance : UInt8*) : Void*
    fun objc_install_content_view_centered(window : Void*, content_view : Void*, max_width : Float64, max_height : Float64) : Void
    fun objc_capture_window_to_png(window : Void*, output_path : UInt8*) : Int32
    fun objc_capture_view_offscreen(window : Void*, output_path : UInt8*, width : Float64, height : Float64) : Int32
    fun objc_close_capture_window(window : Void*) : Void
    fun objc_run_loop_for(seconds : Float64) : Void
  end

  # ---------------------------------------------------------------------------
  # Build the scene
  # ---------------------------------------------------------------------------
  #
  # A 480 × 320 VStack carries a label and a prominent brand button. The button's
  # background is painted by AppKit using token_nscolor(:brand_primary), which
  # resolves through the renderer's design_tokens. Setting that property to
  # `Tokens.default.with_brand(SentinelBrand.new)` is the entire cascade.

  view = UI::VStack.new(spacing: 16.0)
  view << UI::Label.new("Brand cascade demo")
  primary_btn = UI::Button.new("Brand action") { }
  primary_btn.style = UI::ButtonStyle::Prominent
  view << primary_btn
  view << UI::Label.new("brand_primary = #{BRAND_PRIMARY_HEX}")

  renderer = UI::AppKit::Renderer.new
  renderer.design_tokens = UI::DesignTokens::Tokens.default.with_brand(SentinelBrand.new)
  native = renderer.render(view)

  appearance = ENV["HIG_APPEARANCE"]? || "light"
  output_path = ENV["HIG_SCREENSHOT_PATH"]? || "/tmp/brand_cascade_macos.png"

  cap_window = LibWindowHelper.objc_create_capture_window(480.0, 320.0, appearance.to_unsafe)
  if cap_window.null?
    STDERR.puts "[brand_cascade_demo] ERROR: objc_create_capture_window returned NULL"
    exit(1)
  end

  LibWindowHelper.objc_install_content_view_centered(cap_window, native.handle.ptr!, 400.0, 0.0)
  LibWindowHelper.objc_run_loop_for(0.6)

  # Try live compositor capture first (requires Screen Recording permission).
  # Fall back to offscreen rasterization, which works without TCC.
  ok = LibWindowHelper.objc_capture_window_to_png(cap_window, output_path.to_unsafe)
  if ok == 0
    STDOUT.puts "[brand_cascade_demo] live capture failed; falling back to offscreen path"
    ok = LibWindowHelper.objc_capture_view_offscreen(cap_window, output_path.to_unsafe, 480.0, 320.0)
  end

  LibWindowHelper.objc_close_capture_window(cap_window)

  STDOUT.puts "[brand_cascade_demo] brand_primary=#{BRAND_PRIMARY_HEX} appearance=#{appearance} output=#{output_path} ok=#{ok}"
  exit(ok == 1 ? 0 : 1)
{% else %}
  STDERR.puts "[brand_cascade_demo] this sample requires -Dmacos"
  exit(1)
{% end %}
