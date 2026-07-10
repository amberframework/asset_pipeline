require "spec"
require "../../../../src/ui"
require "../../../../src/ui/renderers/web_renderer"
require "../../../../src/components"

private def render(view : UI::View) : String
  renderer = UI::Web::Renderer.new
  view.accept(renderer)
  renderer.output
end

describe UI::Web::Renderer do
  describe "container query roots on shipped components" do
    it "renders Card with the am-card hook and data-layout opt-in" do
      card = UI::Card.new
      html = render(card)
      html.should contain(%(class="am-card))
      html.should contain(%(data-layout="auto"))
    end

    it "renders Form with the am-form hook and data-layout opt-in" do
      form = UI::Form.new
      html = render(form)
      html.should contain(%(class="am-form"))
      html.should contain(%(data-layout="auto"))
    end

    it "renders NavigationSplitView with the am-split-view hook" do
      split = UI::NavigationSplitView.new
      html = render(split)
      html.should contain(%(class="am-split-view))
      html.should contain(%(data-layout="auto"))
    end

    it "wraps the split-view sidebar width in a clamp() floor + ceiling" do
      split = UI::NavigationSplitView.new
      # sidebar_width default is in views/navigation_split_view.cr; we only
      # need to verify the format of the emitted width literal.
      sidebar = UI::Label.new("Sidebar")
      split.sidebar = sidebar
      html = render(split)
      html.should match(/width:\s*clamp\(220px,\s*30vw,\s*[\d.]+px\)/)
    end
  end

  describe "@container CSS blocks ship in the components layer" do
    it "registers @container card (...) rules" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.entries.has_key?("UI::Card").should be_true
      card_css = registry.entries["UI::Card"]
      card_css.should contain("container-type: inline-size")
      card_css.should contain("container-name: card")
      card_css.should contain("@container card (min-width: 480px)")
    end

    it "registers @container form (...) rules" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.entries.has_key?("UI::Form").should be_true
      form_css = registry.entries["UI::Form"]
      form_css.should contain("container-name: form")
      form_css.should contain("@container form (")
    end

    it "registers @container split-view (...) rules" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.entries.has_key?("UI::NavigationSplitView").should be_true
      split_css = registry.entries["UI::NavigationSplitView"]
      split_css.should contain("container-name: split-view")
      split_css.should contain("@container split-view (")
    end
  end
end
