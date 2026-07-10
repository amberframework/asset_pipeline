require "spec"
require "../../../../src/ui"
require "../../../../src/ui/renderers/web_renderer"

private def render(view : UI::View) : String
  renderer = UI::Web::Renderer.new
  view.accept(renderer)
  renderer.output
end

describe "UI::Web::Renderer GlassBackground (Phase 5 tokenization)" do
  it "emits per-step material custom property references for :regular" do
    html = render(UI::GlassBackground.new(material: :regular))
    html.should contain("class=\"ap-glass ap-glass--regular\"")
    html.should contain("var(--ap-material-blur-regular)")
    html.should contain("var(--ap-material-opacity-regular)")
    html.should contain("var(--ap-material-saturation-regular)")
    html.should_not contain("blur(30px)") # no longer hard-coded
  end

  it "emits per-step material references for each declared step" do
    {:ultra_thin => "ultra-thin", :thin => "thin", :regular => "regular",
     :thick => "thick", :chrome => "chrome"}.each do |sym, key|
      html = render(UI::GlassBackground.new(material: sym))
      html.should contain("ap-glass--#{key}")
      html.should contain("var(--ap-material-blur-#{key})")
    end
  end

  it "emits the @supports fallback block via theme CSS" do
    renderer = UI::Web::Renderer.new
    css = renderer.inject_theme_css
    css.should contain("@supports not ((backdrop-filter: blur(1px))")
    css.should contain(".ap-glass--regular")
    css.should contain(".ap-glass--ultra-thin")
  end

  it "emits --ap-material-intensity for diagnostic introspection and the per-step blur as the predefined constant" do
    # Phase 5 v2: web emits the per-step blur as the predefined constant
    # (NO calc() against intensity). Intensity now affects the rendered
    # output via the Crystal-side quantizer selecting WHICH step's vars
    # the renderer references, not via CSS multiplication.
    renderer = UI::Web::Renderer.new
    css = renderer.inject_theme_css
    css.should contain("--ap-material-intensity: 1")
    css.should contain("--ap-material-blur-regular: 30px")
    css.should_not contain("--ap-material-blur-regular: calc")
  end

  it "cascades brand override of intensity into the generated CSS" do
    renderer = UI::Web::Renderer.new
    renderer.design_tokens = UI::DesignTokens::Tokens.default.with_brand(BoostedGlassWebSpecBrand.new)
    css = renderer.inject_theme_css
    css.should contain("--ap-material-intensity: 1.3")
  end

  it "Phase 5 v2 quantizer: declared :thick at intensity 1.3 quantizes to chrome (effective step's CSS class)" do
    # baseline(:thick)=1.5; 1.5 * 1.3 = 1.95 -> >= 1.8 -> Chrome bucket.
    renderer = UI::Web::Renderer.new
    renderer.design_tokens = UI::DesignTokens::Tokens.default.with_brand(BoostedGlassWebSpecBrand.new)
    view = UI::GlassBackground.new(material: :thick)
    view.accept(renderer)
    html = renderer.output
    html.should contain("ap-glass ap-glass--chrome")
    html.should contain("var(--ap-material-blur-chrome)")
    html.should_not contain("ap-glass--thick")
  end

  it "Phase 5 v2 quantizer: declared :regular at default intensity stays :regular" do
    renderer = UI::Web::Renderer.new
    view = UI::GlassBackground.new(material: :regular)
    view.accept(renderer)
    html = renderer.output
    html.should contain("ap-glass ap-glass--regular")
  end
end

private class BoostedGlassWebSpecBrand < UI::DesignTokens::Brand
  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
    material.copy_with(intensity: 1.3)
  end
end
