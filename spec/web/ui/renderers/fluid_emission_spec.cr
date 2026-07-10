require "spec"
require "../../../../src/ui"
require "../../../../src/ui/renderers/web_renderer"

private def render(view : UI::View) : String
  renderer = UI::Web::Renderer.new
  view.accept(renderer)
  renderer.output
end

describe UI::Web::Renderer do
  describe "fluid_width / fluid_height emission" do
    it "emits a width: clamp(...) declaration when fluid_width is set" do
      view = UI::Label.new("Hero")
      view.fluid_width(min: 200, ideal: "60vw", max: 600)
      html = render(view)
      html.should contain("width: clamp(200px, 60vw, 600px)")
    end

    it "emits a height: clamp(...) declaration when fluid_height is set" do
      view = UI::Label.new("Banner")
      view.fluid_height(min: "2rem", ideal: "8vh", max: "6rem")
      html = render(view)
      html.should contain("height: clamp(2rem, 8vh, 6rem)")
    end

    it "fluid_width takes precedence over minimum_width / maximum_width" do
      view = UI::Label.new("Mixed")
      view.minimum_width = 100.0
      view.maximum_width = 1000.0
      view.fluid_width(min: 280, ideal: "90vw", max: 480)
      html = render(view)
      html.should contain("width: clamp(280px, 90vw, 480px)")
      html.should_not match(/min-width:\s*100px/)
      html.should_not match(/max-width:\s*1000px/)
    end

    it "falls through to minimum_width / maximum_width when fluid_width is unset" do
      view = UI::Label.new("Legacy")
      view.minimum_width = 120.0
      view.maximum_width = 480.0
      html = render(view)
      html.should contain("min-width: 120.0px")
      html.should contain("max-width: 480.0px")
    end

    it "fluid_height is independent of fluid_width" do
      view = UI::Label.new("Mixed axis")
      view.minimum_width = 200.0
      view.fluid_height(min: 100, ideal: "20vh", max: 240)
      html = render(view)
      html.should contain("min-width: 200.0px")
      html.should contain("height: clamp(100px, 20vh, 240px)")
    end
  end

  describe "container query root emission" do
    it "emits container-type and container-name when container_query is set" do
      view = UI::Label.new("Card root")
      view.container_query("card")
      html = render(view)
      html.should contain("container-type: inline-size")
      html.should contain("container-name: card")
    end

    it "omits container-* declarations when container_query is unset" do
      view = UI::Label.new("Plain")
      html = render(view)
      html.should_not contain("container-type:")
      html.should_not contain("container-name:")
    end
  end
end
