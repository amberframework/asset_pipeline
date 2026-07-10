require "spec"
require "../../../../src/ui"
require "../../../../src/ui/renderers/web_renderer"

describe UI::Web::Renderer do
  describe "#render_document" do
    it "emits a valid HTML5 doctype and html shell" do
      renderer = UI::Web::Renderer.new
      doc = renderer.render_document(UI::Label.new("hi"), title: "Demo")
      doc.should contain("<!doctype html>")
      doc.should contain(%(<html lang="en">))
      doc.should contain("</html>")
      doc.should contain("<body>")
      doc.should contain("</body>")
    end

    it "emits the responsive viewport meta tag" do
      renderer = UI::Web::Renderer.new
      doc = renderer.render_document(UI::Label.new("hi"), title: "Demo")
      doc.should contain(%(<meta name="viewport" content="width=device-width, initial-scale=1">))
    end

    it "emits the supplied <title>" do
      renderer = UI::Web::Renderer.new
      doc = renderer.render_document(UI::Label.new("hi"), title: "Phase 2 Demo")
      doc.should contain("<title>Phase 2 Demo</title>")
    end

    it "emits the utf-8 charset declaration" do
      renderer = UI::Web::Renderer.new
      doc = renderer.render_document(UI::Label.new("hi"), title: "Demo")
      doc.should contain(%(<meta charset="utf-8">))
    end

    it "injects the design-token <style> block" do
      renderer = UI::Web::Renderer.new
      doc = renderer.render_document(UI::Label.new("hi"), title: "Demo")
      doc.should contain("<style>")
      doc.should contain("--ap-color-brand-primary:")
    end

    it "renders the supplied view inside <body>" do
      renderer = UI::Web::Renderer.new
      doc = renderer.render_document(UI::Label.new("Hello body"), title: "Demo")
      doc.should contain("Hello body")
      body_index = doc.index("<body>").not_nil!
      hello_index = doc.index("Hello body").not_nil!
      hello_index.should be > body_index
    end

    it "respects an overridden lang attribute" do
      renderer = UI::Web::Renderer.new
      doc = renderer.render_document(UI::Label.new("Bonjour"), title: "Demo", lang: "fr")
      doc.should contain(%(<html lang="fr">))
    end
  end
end
