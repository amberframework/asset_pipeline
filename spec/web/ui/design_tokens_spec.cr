require "spec"
require "../../../src/ui/design_tokens"

describe UI::DesignTokens::Color do
  describe ".oklch" do
    it "stores OKLCH triple and computes sRGB bake" do
      c = UI::DesignTokens::Color.oklch(0.52, 0.16, 50.0)
      c.l.should eq(0.52)
      c.c.should eq(0.16)
      c.h.should eq(50.0)
      # The bake is in [0, 1].
      c.r.should be_close(0.645, 0.01)
      c.g.should be_close(0.297, 0.01)
      c.b.should be_close(0.004, 0.01)
    end

    it "honors alpha" do
      c = UI::DesignTokens::Color.oklch(0.66, 0.15, 50.0, 0.58)
      c.alpha.should eq(0.58)
    end
  end

  describe ".rgb" do
    it "stores sRGB verbatim and computes OKLCH" do
      c = UI::DesignTokens::Color.rgb(1.0, 0.0, 0.0)
      c.r.should eq(1.0)
      c.g.should eq(0.0)
      c.b.should eq(0.0)
      c.l.should_not be_nil
    end
  end

  describe ".hex" do
    it "parses 6-digit hex" do
      c = UI::DesignTokens::Color.hex("#7c9a92")
      (c.r * 255).round.to_i.should eq(124)
      (c.g * 255).round.to_i.should eq(154)
      (c.b * 255).round.to_i.should eq(146)
      c.alpha.should eq(1.0)
    end

    it "parses 8-digit hex with alpha" do
      c = UI::DesignTokens::Color.hex("#7c9a9280")
      c.alpha.should be_close(0.502, 0.01)
    end

    it "raises on invalid input" do
      expect_raises(ArgumentError) { UI::DesignTokens::Color.hex("#xyz") }
    end
  end

  describe ".parse_oklch" do
    it "parses oklch() literal with three components" do
      c = UI::DesignTokens::Color.parse_oklch("oklch(0.52 0.16 50)")
      c.l.should eq(0.52)
      c.c.should eq(0.16)
      c.h.should eq(50.0)
      c.alpha.should eq(1.0)
    end

    it "parses oklch() literal with alpha" do
      c = UI::DesignTokens::Color.parse_oklch("oklch(0.66 0.15 50 / 0.58)")
      c.alpha.should eq(0.58)
    end
  end

  describe "#to_oklch_css" do
    it "formats with 3-decimal L/C and 2-decimal H" do
      c = UI::DesignTokens::Color.oklch(0.52, 0.16, 50.0)
      c.to_oklch_css.should eq("oklch(0.520 0.160 50.00)")
    end

    it "includes alpha when < 1" do
      c = UI::DesignTokens::Color.oklch(0.66, 0.15, 50.0, 0.58)
      c.to_oklch_css.should eq("oklch(0.660 0.150 50.00 / 0.58)")
    end
  end

  describe "#to_rgba_css" do
    it "emits integer rgba" do
      c = UI::DesignTokens::Color.rgb(1.0, 0.5, 0.0)
      c.to_rgba_css.should eq("rgba(255, 128, 0, 1)")
    end
  end

  describe "#to_hex" do
    it "round-trips through hex" do
      c = UI::DesignTokens::Color.hex("#7c9a92")
      c.to_hex.should eq("#7c9a92")
    end
  end

  describe "#to_swift_color" do
    it "emits a SwiftUI literal" do
      c = UI::DesignTokens::Color.rgb(0.835, 0.431, 0.125)
      c.to_swift_color.should eq("Color(.sRGB, red: 0.835, green: 0.431, blue: 0.125, opacity: 1.000)")
    end
  end

  describe "#to_android_argb" do
    it "packs ARGB into a 32-bit int" do
      c = UI::DesignTokens::Color.rgb(1.0, 0.0, 0.0)
      # 0xFFFF0000
      c.to_android_argb.should eq(0xFFFF0000_u32.to_i32!)
    end

    it "honors alpha" do
      c = UI::DesignTokens::Color.rgb(1.0, 0.0, 0.0, 0.5)
      argb = c.to_android_argb.to_u32!
      ((argb >> 24) & 0xFF).should eq(128)
    end
  end
end

describe UI::DesignTokens::Tokens do
  describe ".default" do
    it "exposes a 23-role light palette" do
      t = UI::DesignTokens::Tokens.default
      t.colors_light.to_h.size.should eq(23)
    end

    it "exposes a 23-role dark palette" do
      t = UI::DesignTokens::Tokens.default
      t.colors_dark.to_h.size.should eq(23)
    end

    it "resolves brand_primary to the Color::SYSTEM_ACCENT sentinel (post Phase 6.12A)" do
      # Phase 6.12A library-identity pivot: the legacy amber OKLCH literal
      # (`oklch(0.52 0.16 50)`) is gone from `Tokens.default`. The brand
      # primary family resolves to `Color::SYSTEM_ACCENT` so the platform
      # paints the OS-native accent. Consumers who want an opinionated
      # brand colour subclass `UI::DesignTokens::Brand` and apply it via
      # `Tokens.default.with_brand(...)`. See `phase-06.12a-cascade-preflight.md`.
      t = UI::DesignTokens::Tokens.default
      t.colors_light.brand_primary.system_accent?.should be_true
      t.colors_dark.brand_primary.system_accent?.should be_true
    end

    it "exposes touch_target_minimum_px = 44.0 by default" do
      UI::DesignTokens::Tokens.default.touch_target_minimum_px.should eq(44.0)
    end
  end

  describe "#lookup" do
    it "resolves a color path" do
      t = UI::DesignTokens::Tokens.default
      result = t.lookup("colors.light.brand_primary")
      result.should be_a(UI::DesignTokens::Color)
    end

    it "resolves a spacing path" do
      t = UI::DesignTokens::Tokens.default
      t.lookup("spacing.x4").should eq(1.0)
    end

    it "resolves a radius path" do
      t = UI::DesignTokens::Tokens.default
      t.lookup("radius.md").should eq(0.375)
    end

    it "resolves a type-step field" do
      t = UI::DesignTokens::Tokens.default
      t.lookup("type.body.size").should eq(1.0)
    end

    it "returns nil for an unknown path" do
      UI::DesignTokens::Tokens.default.lookup("colors.light.not_a_role").should be_nil
      UI::DesignTokens::Tokens.default.lookup("does.not.exist").should be_nil
    end
  end

  describe "#copy_with" do
    it "produces a new Tokens with selected fields replaced" do
      base = UI::DesignTokens::Tokens.default
      modified = base.copy_with(touch_target_minimum_px: 48.0)
      modified.touch_target_minimum_px.should eq(48.0)
      base.touch_target_minimum_px.should eq(44.0)
      modified.colors_light.brand_primary.should eq(base.colors_light.brand_primary)
    end
  end
end
