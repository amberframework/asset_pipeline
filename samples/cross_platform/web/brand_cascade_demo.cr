require "../../../src/ui/design_tokens"
require "../../../src/ui/design_tokens/generators/web_generator"

# Brand-cascade demonstration for Phase 1 of the cross-platform UI initiative.
#
# Emits a single HTML document whose colors are sourced ENTIRELY through the
# `UI::DesignTokens` model — no inline hex literals, no per-element color
# props. The colors that ship are pulled from `Tokens.default.with_brand(...)`
# at write time; flipping `BRAND_PRIMARY_HEX` below regenerates the entire
# page with the new identity.
#
# This file is the path the Phase 1 validator's cascade checks (Phase 1
# implementation.md §12, validation checks #18 — "web changes on brand
# override") consume: the validator edits `BRAND_PRIMARY_HEX`, regenerates
# the static HTML, and screenshots before/after to confirm the cascade.
#
# Usage:
#   crystal run samples/cross_platform/web/brand_cascade_demo.cr -- /tmp/out.html
#
# The sentinel hex chosen by default is the magenta the spec uses; flipping
# it to e.g. `#1d4ed8` (Acme blue) should change every brand-tinted surface
# in the rendered page.

BRAND_PRIMARY_HEX = "#ff00ff" # SENTINEL — flip this to verify cascade.

class DemoBrand < UI::DesignTokens::Brand
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

tokens = UI::DesignTokens::Tokens.default.with_brand(DemoBrand.new)
css = UI::DesignTokens::WebGenerator.generate(tokens)

html = <<-HTML
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Brand cascade demo</title>
    <style>
    #{css}
    body {
      margin: 0;
      font-family: var(--ap-font-sans);
      background: var(--ap-color-surface-canvas);
      color: var(--ap-color-text-primary);
      padding: var(--ap-space-8);
    }
    .panel {
      background: var(--ap-color-surface-panel);
      border: 1px solid var(--ap-color-border-default);
      border-radius: var(--ap-radius-lg);
      padding: var(--ap-space-6);
      box-shadow: var(--ap-shadow-raised);
      max-width: 28rem;
    }
    .panel + .panel { margin-top: var(--ap-space-4); }
    h1 { font-size: var(--ap-type-headline-size); margin: 0 0 var(--ap-space-4); }
    button.primary {
      background: var(--ap-color-brand-primary);
      color: var(--ap-color-text-inverse);
      border: none;
      border-radius: var(--ap-radius-md);
      padding: var(--ap-space-3) var(--ap-space-5);
      font-size: var(--ap-type-body-size);
      font-weight: var(--ap-type-body-emph-weight);
      cursor: pointer;
      min-height: var(--ap-touch-target-min);
    }
    button.primary:hover { background: var(--ap-color-brand-primary-hover); }
    a {
      color: var(--ap-color-text-link);
      text-decoration: underline;
    }
    </style>
  </head>
  <body>
    <div class="panel" data-testid="cascade-panel">
      <h1>Brand cascade demo</h1>
      <p>This page renders entirely from <code>UI::DesignTokens::Tokens</code>.</p>
      <button class="primary" data-testid="cascade-primary-button">Brand action</button>
      <p><a href="#" data-testid="cascade-link">Inline link</a></p>
    </div>
  </body>
</html>
HTML

output_path = ARGV[0]? || "samples/cross_platform/web/brand_cascade_demo.html"
File.write(output_path, html)
STDOUT.puts "wrote #{output_path} with brand_primary=#{BRAND_PRIMARY_HEX}"
