require "../../spec_helper"
require "../../../../src/ui/design_tokens"

describe UI::DesignTokens::Material do
  # ---------------------------------------------------------------
  # v2 two-axis surface: AppleSemantic + ThicknessStep + quantizer
  # ---------------------------------------------------------------

  describe "#apple_semantic" do
    it "returns the declared semantic unchanged at default intensity" do
      m = UI::DesignTokens::Defaults.material
      m.apple_semantic.should eq(UI::DesignTokens::AppleSemantic::SystemResolved)
    end

    it "does NOT alter the declared semantic when intensity changes" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        intensity: 2.0,
        semantic: UI::DesignTokens::AppleSemantic::Sidebar,
      )
      m.apple_semantic.should eq(UI::DesignTokens::AppleSemantic::Sidebar)

      m_low = m.copy_with(intensity: 0.1)
      m_low.apple_semantic.should eq(UI::DesignTokens::AppleSemantic::Sidebar)
    end

    it "honors each of the 9 AppleSemantic enum values" do
      base = UI::DesignTokens::Defaults.material
      UI::DesignTokens::AppleSemantic.values.each do |sem|
        base.copy_with(semantic: sem).apple_semantic.should eq(sem)
      end
    end
  end

  describe "AppleSemantic#from_key / #to_key" do
    it "round-trips every enum value through its canonical key" do
      UI::DesignTokens::AppleSemantic.values.each do |sem|
        UI::DesignTokens::AppleSemantic.from_key(sem.to_key).should eq(sem)
      end
    end

    it "returns SystemResolved for nil or unknown keys" do
      UI::DesignTokens::AppleSemantic.from_key(nil)
        .should eq(UI::DesignTokens::AppleSemantic::SystemResolved)
      UI::DesignTokens::AppleSemantic.from_key("bogus_role")
        .should eq(UI::DesignTokens::AppleSemantic::SystemResolved)
    end

    it "accepts camelCase aliases" do
      UI::DesignTokens::AppleSemantic.from_key("headerView")
        .should eq(UI::DesignTokens::AppleSemantic::HeaderView)
      UI::DesignTokens::AppleSemantic.from_key("hudWindow")
        .should eq(UI::DesignTokens::AppleSemantic::HUDWindow)
    end
  end

  describe "ThicknessStep helpers" do
    it "round-trips every step through to_symbol/from_symbol" do
      UI::DesignTokens::ThicknessStep.values.each do |s|
        UI::DesignTokens::ThicknessStep.from_symbol(s.to_symbol).should eq(s)
      end
    end

    it "to_key returns canonical snake_case" do
      UI::DesignTokens::ThicknessStep::UltraThin.to_key.should eq("ultra_thin")
      UI::DesignTokens::ThicknessStep::Chrome.to_key.should eq("chrome")
    end

    it "from_symbol falls back to Regular on unknown" do
      UI::DesignTokens::ThicknessStep.from_symbol(:bogus)
        .should eq(UI::DesignTokens::ThicknessStep::Regular)
    end
  end

  describe "step_baseline" do
    it "matches the architecture doc's per-step baseline table" do
      UI::DesignTokens::Material.step_baseline(
        UI::DesignTokens::ThicknessStep::UltraThin).should eq(0.2)
      UI::DesignTokens::Material.step_baseline(
        UI::DesignTokens::ThicknessStep::Thin).should eq(0.5)
      UI::DesignTokens::Material.step_baseline(
        UI::DesignTokens::ThicknessStep::Regular).should eq(1.0)
      UI::DesignTokens::Material.step_baseline(
        UI::DesignTokens::ThicknessStep::Thick).should eq(1.5)
      UI::DesignTokens::Material.step_baseline(
        UI::DesignTokens::ThicknessStep::Chrome).should eq(1.9)
    end
  end

  describe "#thickness_for_brand quantizer" do
    # Per architecture doc lines 65-77:
    #   baseline = step_baseline(step)
    #   i = baseline * intensity
    #   <= 0.3 -> UltraThin
    #   <= 0.7 -> Thin
    #   <= 1.3 -> Regular
    #   >= 1.8 -> Chrome
    #   else    -> Thick

    it "at intensity=1.0, declared Regular quantizes to Regular" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Regular,
        intensity: 1.0,
      )
      m.thickness_for_brand.should eq(UI::DesignTokens::ThicknessStep::Regular)
    end

    it "at intensity=1.0, declared UltraThin quantizes to UltraThin (0.2 * 1.0 <= 0.3)" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::UltraThin, intensity: 1.0)
      m.thickness_for_brand.should eq(UI::DesignTokens::ThicknessStep::UltraThin)
    end

    it "at intensity=1.0, declared Thin quantizes to Thin (0.5 * 1.0 <= 0.7)" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Thin, intensity: 1.0)
      m.thickness_for_brand.should eq(UI::DesignTokens::ThicknessStep::Thin)
    end

    it "at intensity=1.0, declared Thick quantizes to Thick (1.5 * 1.0 = 1.5 -> Thick bucket)" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Thick, intensity: 1.0)
      m.thickness_for_brand.should eq(UI::DesignTokens::ThicknessStep::Thick)
    end

    it "at intensity=1.0, declared Chrome quantizes to Chrome (1.9 * 1.0 >= 1.8)" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Chrome, intensity: 1.0)
      m.thickness_for_brand.should eq(UI::DesignTokens::ThicknessStep::Chrome)
    end

    it "honors the <= 0.3 -> UltraThin boundary" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Regular)
      m.copy_with(intensity: 0.3).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::UltraThin)
      m.copy_with(intensity: 0.30001).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Thin)
    end

    it "honors the <= 0.7 -> Thin boundary" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Regular)
      m.copy_with(intensity: 0.7).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Thin)
      m.copy_with(intensity: 0.70001).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Regular)
    end

    it "honors the <= 1.3 -> Regular boundary (worked example)" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Regular)
      m.copy_with(intensity: 1.3).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Regular)
      m.copy_with(intensity: 1.30001).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Thick)
    end

    it "honors the >= 1.8 -> Chrome boundary" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Regular)
      m.copy_with(intensity: 1.8).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Chrome)
      m.copy_with(intensity: 1.79999).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Thick)
      m.copy_with(intensity: 2.0).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Chrome)
    end

    it "the middle (else) bucket maps to Thick" do
      m = UI::DesignTokens::Defaults.material.copy_with(
        step: UI::DesignTokens::ThicknessStep::Regular)
      # baseline 1.0 * 1.5 = 1.5 → not <= 1.3, not >= 1.8 → Thick
      m.copy_with(intensity: 1.5).thickness_for_brand
        .should eq(UI::DesignTokens::ThicknessStep::Thick)
    end
  end

  # ---------------------------------------------------------------
  # Backwards-compat shims (Symbol-in / Symbol-out)
  # ---------------------------------------------------------------

  describe "#step (Symbol-in legacy shim)" do
    it "returns the matching MaterialStep for each declared symbol" do
      m = UI::DesignTokens::Defaults.material
      m.step(:ultra_thin).blur_radius.should eq(10.0)
      m.step(:thin).blur_radius.should eq(20.0)
      m.step(:regular).blur_radius.should eq(30.0)
      m.step(:thick).blur_radius.should eq(40.0)
      m.step(:chrome).blur_radius.should eq(50.0)
    end

    it "falls back to :regular for unknown symbols" do
      m = UI::DesignTokens::Defaults.material
      m.step(:nonexistent_step).should eq(m.step(:regular))
    end
  end

  describe "#apple_step (Symbol-in legacy shim, quantizer-routed in v2)" do
    it "at intensity=1.0, every declared step quantizes back to itself except Chrome ceiling" do
      m = UI::DesignTokens::Defaults.material
      m.apple_step(:ultra_thin).should eq(:ultra_thin) # 0.2 * 1.0 = 0.2 <= 0.3
      m.apple_step(:thin).should eq(:thin)             # 0.5 * 1.0 = 0.5 <= 0.7
      m.apple_step(:regular).should eq(:regular)       # 1.0 * 1.0 = 1.0 <= 1.3
      m.apple_step(:thick).should eq(:thick)           # 1.5 * 1.0 = 1.5 -> Thick bucket
      m.apple_step(:chrome).should eq(:chrome)         # 1.9 * 1.0 = 1.9 >= 1.8 -> Chrome
    end

    it "intensity 1.3 keeps :regular as :regular (worked example)" do
      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.3)
      m.apple_step(:regular).should eq(:regular)
    end

    it "intensity 1.5 quantizes :regular to :thick (1.0 * 1.5 = 1.5 -> Thick bucket)" do
      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.5)
      m.apple_step(:regular).should eq(:thick)
    end

    it "intensity 1.8 quantizes :regular to :chrome" do
      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.8)
      m.apple_step(:regular).should eq(:chrome)
    end

    it "intensity 0.5 quantizes :regular to :thin (1.0 * 0.5 = 0.5 <= 0.7)" do
      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 0.5)
      m.apple_step(:regular).should eq(:thin)
    end
  end

  describe "#resolve (Symbol-in legacy shim returning quantized step's predefined values)" do
    it "at default intensity returns the declared step's predefined blur_radius (no proportional scaling)" do
      m = UI::DesignTokens::Defaults.material
      m.resolve(:regular).blur_radius.should eq(30.0)
      m.resolve(:regular).opacity.should eq(0.60)
      m.resolve(:regular).name.should eq(:regular)
    end

    it "the resolved name reflects the EFFECTIVE (quantized) step, not the declared step" do
      # intensity 0.5 with declared :regular -> 1.0 * 0.5 = 0.5 <= 0.7 -> :thin bucket
      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 0.5)
      r = m.resolve(:regular)
      r.name.should eq(:thin)
      r.blur_radius.should eq(20.0) # predefined :thin blur, not 30 * 0.5
      r.opacity.should eq(0.40)     # predefined :thin opacity
    end

    it "high intensity quantizes up the ladder rather than scaling" do
      m = UI::DesignTokens::Defaults.material.copy_with(intensity: 1.5)
      r = m.resolve(:regular)
      r.name.should eq(:thick)
      r.blur_radius.should eq(40.0) # predefined :thick blur
    end
  end

  describe "brand override cascade" do
    it "exposes intensity via Tokens.with_brand without runtime mutation" do
      brand = TestGlassBrand.new
      tokens = UI::DesignTokens::Tokens.default.with_brand(brand)
      tokens.material.intensity.should eq(1.3)
      # Original Tokens.default is unchanged — copy_with returns a new instance.
      UI::DesignTokens::Tokens.default.material.intensity.should eq(1.0)
    end
  end
end

private class TestGlassBrand < UI::DesignTokens::Brand
  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
    material.copy_with(intensity: 1.3)
  end
end
