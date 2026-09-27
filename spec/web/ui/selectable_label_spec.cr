require "spec"
require "../../../src/ui"
require "../../../src/ui/renderers/web_renderer"

private def render_selectable_label(view : UI::View) : String
  renderer = UI::Web::Renderer.new
  view.accept(renderer)
  renderer.output
end

describe "UI::Label selectable text" do
  it "defaults to non-selectable" do
    UI::Label.new("Copyable value").selectable.should be_false
  end

  it "emits a text selection style when selectable" do
    label = UI::Label.new("Copyable value")
    label.selectable = true

    render_selectable_label(label).should contain("user-select: text")
  end

  it "keeps the default label selection style unchanged" do
    html = render_selectable_label(UI::Label.new("Read-only value"))

    html.should_not contain("user-select: text")
  end
end
