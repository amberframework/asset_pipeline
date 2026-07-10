# Phase 6 web target — emits a static HTML site to
# output/initiative-demo/. One page per screen slug, plus an index.html.
#
# Usage:
#   crystal run samples/initiative-cross-platform-ui-demo/web/static_site.cr
#
# Renders each screen via UI::Web::Renderer (which delegates to the
# Components::Elements system) and pins InitiativeDemo.brand_tokens
# on the renderer so every emitted page wears the deep-teal brand.

require "../app"
require "../../../src/ui/renderers/web_renderer"

OUTPUT_DIR = ARGV[0]? || File.expand_path("../../../output/initiative-demo", __DIR__)
Dir.mkdir_p(OUTPUT_DIR)

# Per-slug appearance variants (each rendered twice — light + dark).
APPEARANCES = ["light", "dark"]

# Build one static page per screen × appearance.
InitiativeDemo::SLUGS.each do |slug|
  APPEARANCES.each do |appearance|
    state = InitiativeDemo::State.new
    view = InitiativeDemo.build_screen(slug, state)

    renderer = UI::Web::Renderer.new
    renderer.design_tokens = InitiativeDemo.brand_tokens
    title = "Cascade · #{slug}"

    body_html = renderer.render(view)
    css = renderer.inject_theme_css

    # Light/dark via a data-appearance attribute on <body>. Renderers
    # emit `color-scheme` + light/dark token variants; the data attr
    # lets the quad-comparison harness force a specific render at
    # capture time without depending on the OS preference.
    html = String.build do |io|
      io << "<!doctype html>\n"
      io << %(<html lang="en" data-appearance="#{appearance}">) << '\n'
      io << "<head>\n"
      io << %(<meta charset="utf-8">) << '\n'
      io << %(<meta name="viewport" content="width=device-width, initial-scale=1">) << '\n'
      io << "<title>#{title} (#{appearance})</title>\n"
      io << css
      io << "<style>\n"
      io << "body { margin: 0; min-height: 100vh; "
      io << "background: var(--ap-color-surface-canvas); "
      io << "color: var(--ap-color-text-primary); "
      io << "font-family: var(--ap-font-sans); }\n"
      io << "[data-appearance=\"dark\"] { color-scheme: dark; }\n"
      io << "[data-appearance=\"light\"] { color-scheme: light; }\n"
      io << "</style>\n"
      io << "</head>\n"
      io << %(<body data-appearance="#{appearance}" data-slug="#{slug}">) << '\n'
      io << body_html
      io << "\n</body>\n</html>\n"
    end

    out_path = File.join(OUTPUT_DIR, "#{slug}-#{appearance}.html")
    File.write(out_path, html)
    puts "wrote #{out_path}"
  end
end

# Index page links to every per-slug page.
index_html = String.build do |io|
  io << "<!doctype html>\n<html lang=\"en\">\n<head>\n"
  io << %(<meta charset="utf-8">) << '\n'
  io << %(<meta name="viewport" content="width=device-width, initial-scale=1">) << '\n'
  io << "<title>Cascade · index</title>\n"
  io << "<style>\n"
  io << "body { font-family: -apple-system, system-ui, sans-serif; max-width: 720px; "
  io << "margin: 40px auto; padding: 24px; line-height: 1.5; }\n"
  io << "table { width: 100%; border-collapse: collapse; }\n"
  io << "th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid #ccc; }\n"
  io << "a { color: #2c6e7d; text-decoration: none; }\n"
  io << "a:hover { text-decoration: underline; }\n"
  io << "</style>\n"
  io << "</head>\n<body>\n"
  io << "<h1>Cascade demo — static web build</h1>\n"
  io << "<p>Phase 6 of the cross-platform UI initiative. Each row is one demo screen rendered in light and dark mode.</p>\n"
  io << "<table>\n<thead><tr><th>Slug</th><th>Light</th><th>Dark</th></tr></thead>\n<tbody>\n"
  InitiativeDemo::SLUGS.each do |slug|
    io << "<tr>"
    io << "<td>#{slug}</td>"
    io << %Q(<td><a href="#{slug}-light.html">light</a></td>)
    io << %Q(<td><a href="#{slug}-dark.html">dark</a></td>)
    io << "</tr>\n"
  end
  io << "</tbody>\n</table>\n"
  io << %Q(<p><a href="quad-comparison.html">→ Quad-comparison page (post-capture)</a></p>) << '\n'
  io << "</body>\n</html>\n"
end

File.write(File.join(OUTPUT_DIR, "index.html"), index_html)
puts "wrote #{File.join(OUTPUT_DIR, "index.html")}"
puts "Static web build done — #{InitiativeDemo::SLUGS.size * APPEARANCES.size + 1} files."
