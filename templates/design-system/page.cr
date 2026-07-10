# Minimal design-system page skeleton for generated views.
#
# This template is intentionally conservative. It shows the page shell and
# behavior hooks agents should preserve until the reusable validation CLI is
# promoted.

# Repo-local path for this template. Consuming apps should use:
# require "asset_pipeline/design_system"
require "../../src/asset_pipeline/design_system"

module DesignSystemPageTemplate
  extend self

  def render : String
    <<-HTML
    <!doctype html>
    <html lang="en" data-ap-theme="light" data-amber-theme="light">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Design System Page</title>
      </head>
      <body>
        <a class="am-skip-link" href="#main">Skip to content</a>
        <nav aria-label="Primary">
          <a href="index.html" aria-current="page">Home</a>
        </nav>
        <main id="main" tabindex="-1">
          <h1>Design System Page</h1>
          <section aria-labelledby="actions-title">
            <h2 id="actions-title">Actions</h2>
            #{Components::DesignSystem::ThemeSwitcher.new(mode: "segmented").render}
            #{Components::DesignSystem::Button.new(label: "Save", tone: "brand", emphasis: "solid").render}
          </section>
        </main>
      </body>
    </html>
    HTML
  end
end

puts DesignSystemPageTemplate.render
