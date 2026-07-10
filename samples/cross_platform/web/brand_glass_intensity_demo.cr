require "../../../src/ui"
require "../../../src/ui/renderers/web_renderer"

# Phase 5 — brand glass intensity demo.
#
# Demonstrates that a single brand declaration of `material.intensity = 1.3`
# cascades to every renderer via the `UI::DesignTokens::Tokens` token tree,
# without touching any individual renderer or component. The intensity scalar
# is brand-declaration-time (NOT runtime-mutable) per the Phase 5 brief I-2
# `preserves` contract — consumers re-render the view tree to observe
# changes.
#
# Run with:
#   crystal run samples/cross_platform/web/brand_glass_intensity_demo.cr
#
# The script prints:
#   1. The five-step glass ladder as HTML (web renderer output).
#   2. The generated `--ap-material-*` CSS so the cascade is visually
#      inspectable (`--ap-material-intensity: 1.3` and the `calc()`
#      expressions on the per-step blur properties).
#   3. The Apple-quantized step each Crystal step resolves to at the
#      brand intensity — useful for understanding the SwiftUI Material
#      enum quantization documented in brief.yml adapter_cardinality
#      row 1 ("intensity 1.3 quantizes to .regularMaterial").

class BoostedGlassBrand < UI::DesignTokens::Brand
  protected def override_material(material : UI::DesignTokens::Material) : UI::DesignTokens::Material
    material.copy_with(intensity: 1.3)
  end
end

# Original Tokens.default has intensity=1.0; the with_brand cascade
# returns a NEW Tokens instance — the original is unchanged (I-2 / I-9
# preserves).
tokens = UI::DesignTokens::Tokens.default.with_brand(BoostedGlassBrand.new)

ladder = UI::VStack.new(spacing: 12.0)
[:ultra_thin, :thin, :regular, :thick, :chrome].each do |step|
  ladder << UI::GlassBackground.new(material: step)
end

renderer = UI::Web::Renderer.new
renderer.design_tokens = tokens

puts "================================================================"
puts "Phase 5 brand glass intensity demo (intensity=1.3 cascade proof)"
puts "================================================================"
puts
puts "--- Rendered HTML (web) ---"
puts renderer.render(ladder)
puts
puts "--- Generated material CSS custom properties ---"
css = renderer.inject_theme_css
css.each_line do |line|
  puts line if line.includes?("--ap-material-") || line.includes?("ap-glass--")
end
puts
puts "--- Apple-quantized step per declared step at intensity=1.3 ---"
[:ultra_thin, :thin, :regular, :thick, :chrome].each do |step|
  apple = tokens.material.apple_step(step)
  resolved = tokens.material.resolve(step)
  printf("  %-11s -> apple=%s  blur=%.2fpx  opacity=%.2f\n",
    step.to_s, apple.to_s, resolved.blur_radius, resolved.opacity)
end
