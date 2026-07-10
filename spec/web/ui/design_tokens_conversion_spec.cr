require "spec"
require "../../../src/ui/design_tokens"

# Round-trip tolerance per phase-1 implementation.md §3.4.
ROUND_TRIP_L = 0.001
ROUND_TRIP_C = 0.001
ROUND_TRIP_H = 0.5

private def assert_round_trip(name : String, l : Float64, c : Float64, h : Float64)
  r, g, b = UI::DesignTokens::Conversion.oklch_to_srgb(l, c, h)
  l2, c2, h2 = UI::DesignTokens::Conversion.srgb_to_oklch(r, g, b)
  delta_l = (l2 - l).abs
  delta_c = (c2 - c).abs
  delta_h = (h2 - h).abs
  delta_h = (360.0 - delta_h).abs if delta_h > 180.0

  # Only assert tolerance when the original triple was in gamut. Out-of-gamut
  # triples are remapped (chroma reduced) so chroma will differ — that's by
  # design, not a round-trip violation. We detect in-gamut by checking that
  # raw conversion stayed within [0, 1].
  raw_r, raw_g, raw_b = UI::DesignTokens::Conversion.oklch_to_srgb_unchecked(l, c, h)
  in_gamut = (0.0..1.0).covers?(raw_r) && (0.0..1.0).covers?(raw_g) && (0.0..1.0).covers?(raw_b)

  if in_gamut
    delta_l.should be < ROUND_TRIP_L, "#{name}: ΔL=#{delta_l} exceeds #{ROUND_TRIP_L}"
    delta_c.should be < ROUND_TRIP_C, "#{name}: Δc=#{delta_c} exceeds #{ROUND_TRIP_C}"
    # Hue is meaningless when chroma is ~0 (achromatic colors). Skip the
    # hue tolerance check in that degenerate case.
    delta_h.should be < ROUND_TRIP_H, "#{name}: Δh=#{delta_h} exceeds #{ROUND_TRIP_H}" if c > 0.001
  end
end

describe UI::DesignTokens::Conversion do
  describe "OKLCH ↔ sRGB round-trip" do
    it "round-trips every default amber color (light palette)" do
      palette = UI::DesignTokens::Defaults.light_palette
      palette.to_h.each do |name, color|
        next unless (l = color.l) && (c = color.c) && (h = color.h)
        assert_round_trip("light/#{name}", l, c, h)
      end
    end

    it "round-trips every default amber color (dark palette)" do
      palette = UI::DesignTokens::Defaults.dark_palette
      palette.to_h.each do |name, color|
        next unless (l = color.l) && (c = color.c) && (h = color.h)
        assert_round_trip("dark/#{name}", l, c, h)
      end
    end

    it "round-trips pure black" do
      r, g, b = UI::DesignTokens::Conversion.oklch_to_srgb(0.0, 0.0, 0.0)
      r.should be_close(0.0, 0.001)
      g.should be_close(0.0, 0.001)
      b.should be_close(0.0, 0.001)
    end

    it "round-trips pure white" do
      l, _, _ = UI::DesignTokens::Conversion.srgb_to_oklch(1.0, 1.0, 1.0)
      l.should be_close(1.0, 0.001)
      r, g, b = UI::DesignTokens::Conversion.oklch_to_srgb(l, 0.0, 0.0)
      r.should be_close(1.0, 0.001)
      g.should be_close(1.0, 0.001)
      b.should be_close(1.0, 0.001)
    end

    it "clamps out-of-gamut OKLCH triples to a valid sRGB" do
      # Extreme chroma — definitely out of gamut.
      r, g, b = UI::DesignTokens::Conversion.oklch_to_srgb(0.5, 0.4, 50.0)
      (0.0..1.0).covers?(r).should be_true
      (0.0..1.0).covers?(g).should be_true
      (0.0..1.0).covers?(b).should be_true
    end
  end

  describe "alpha is independent of OKLCH→sRGB conversion" do
    it "alpha values are stored verbatim on Color" do
      c = UI::DesignTokens::Color.oklch(0.5, 0.1, 50.0, 0.42)
      c.alpha.should eq(0.42)
    end
  end

  describe "delta_e_2000" do
    it "is 0 for identical colors" do
      d = UI::DesignTokens::Conversion.delta_e_2000(0.5, 0.1, 50.0, 0.5, 0.1, 50.0)
      d.should be_close(0.0, 0.001)
    end

    it "is small for near-identical colors" do
      d = UI::DesignTokens::Conversion.delta_e_2000(0.5, 0.1, 50.0, 0.501, 0.1, 50.0)
      d.should be < 1.0
    end
  end
end
