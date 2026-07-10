# Phase 4 R1 web demo — PathControlWithWebFallback CDP test page.
#
# The semantic structure (nav[aria-label="Breadcrumb"] > ol > li
# with aria-current="page" on the leaf) is exercised by the Crystal
# spec at spec/ui/views/path_control_with_web_fallback_spec.cr (already
# passing in iter 1). This page exists purely so the CDP harness can
# point axe-core and IBM Equal Access at a real rendered breadcrumb
# and capture clean reports — covering the two outstanding
# accessibility checks for PathControl in the rubric.
#
# Usage:
#   crystal run samples/cross_platform/web/phase04_path_control_demo.cr -- \
#     samples/cross_platform/web/dist/phase04_path_control_demo.html

require "../../../src/ui"
require "../../../src/ui/design_tokens"
require "../../../src/ui/design_tokens/generators/web_generator"

breadcrumb = UI::PathControlWithWebFallback.new
breadcrumb.add_component("Home", url: "#home")
breadcrumb.add_component("Projects", url: "#projects")
breadcrumb.add_component("Phase 4", url: "#phase4")
breadcrumb.add_component("Validation") # leaf, no URL -> aria-current="page"
breadcrumb.test_id = "path-control-host"

caption = UI::Label.new("PathControl web fallback")
caption.test_id = "path-control-caption"

root = UI::VStack.new(spacing: 12.0)
root << caption
root << breadcrumb

renderer = UI::Web::Renderer.new
body_html = renderer.render(root)
token_css = UI::DesignTokens::WebGenerator.generate(UI::DesignTokens::Tokens.default)

html = String.build do |io|
  io << "<!doctype html>\n"
  io << %(<html lang="en">\n<head>\n)
  io << %(<meta charset="utf-8">\n)
  io << %(<meta name="viewport" content="width=device-width,initial-scale=1">\n)
  io << "<title>Phase 4 — PathControlWithWebFallback CDP demo</title>\n"
  io << "<style>\n" << token_css
  io << <<-CSS

  html, body {
    margin: 0;
    font-family: var(--ap-font-sans);
    background: var(--ap-color-surface-canvas);
    color: var(--ap-color-text-primary);
    padding: 24px;
  }
  .visually-hidden {
    position: absolute; width: 1px; height: 1px;
    padding: 0; margin: -1px; overflow: hidden;
    clip: rect(0 0 0 0); white-space: nowrap; border: 0;
  }
  .visually-hidden:focus, .visually-hidden:focus-visible {
    position: static; width: auto; height: auto;
    margin: 0; clip: auto; white-space: normal;
  }
  CSS
  io << "\n</style>\n</head>\n<body>\n"
  io << %(<header><a href="#main" class="visually-hidden">Skip to main content</a></header>\n)
  io << %(<main id="main" aria-label="Phase 4 path control demo">\n)
  io << body_html
  io << "\n</main>\n</body>\n</html>\n"
end

output_path = ARGV[0]? || "samples/cross_platform/web/dist/phase04_path_control_demo.html"
File.write(output_path, html)
STDOUT.puts "wrote #{output_path} (#{html.bytesize} bytes)"
