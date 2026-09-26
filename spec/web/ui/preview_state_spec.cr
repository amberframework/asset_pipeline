require "../spec_helper"
require "../../../src/ui"

describe UI::View, "#preview_state" do
  it "defaults to None" do
    UI::Button.new("Preview").preview_state.should eq(UI::PreviewState::None)
  end
end

describe UI::SurfaceCraftPayload, "#to_json" do
  it "round-trips the explicit preview state through the typed payload" do
    button = UI::Button.new("Preview")
    button.preview_state = UI::PreviewState::Hover

    json = button.surface_craft_json
    raise "preview-state payload was not emitted" unless json

    payload = UI::SurfaceCraftPayload.from_json(json)
    payload.preview_state.should eq("hover")
    payload.to_json.should eq(json)
  end
end

describe UI::Web::Renderer, "preview states" do
  it "emits explicit hover, pressed, and focus hooks" do
    {
      {UI::PreviewState::Hover, "hover"},
      {UI::PreviewState::Pressed, "pressed"},
      {UI::PreviewState::Focus, "focus"},
    }.each do |state, expected|
      button = UI::Button.new("Preview")
      button.preview_state = state

      UI::Web::Renderer.new.render(button).should contain(%(data-ap-preview-state="#{expected}"))
    end
  end

  it "leaves the preview hook absent when the state is None" do
    html = UI::Web::Renderer.new.render(UI::Button.new("Default"))
    html.should_not contain("data-ap-preview-state")
  end

  it "maps preview hover, pressed, and focus to the feedback and focus styles" do
    css = UI::Web::Renderer.new.inject_theme_css

    css.should contain(%([data-ap-feedback="sink"][data-ap-preview-state="hover"]))
    css.should contain(%([data-ap-feedback="sink"][data-ap-preview-state="pressed"]))
    css.should contain(%([data-ap-preview-state="focus"]))
  end
end
